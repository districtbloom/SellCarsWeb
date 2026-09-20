-- New profile namespace for the FullJourney progression. Legacy saves are not interpreted.
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Profiles={}
local active={}
local memory={}
local store=DataStoreService:GetDataStore("SellCarsFullJourney_v1")
local session=game.JobId~="" and game.JobId or HttpService:GenerateGUID(false)
local closing=false
local closeDeadline=0
local function number(value,fallback,maximum)
	local n=tonumber(value)
	if not n or n~=n then n=fallback end
	return math.clamp(math.floor(n),0,maximum)
end
local function normalize(value)
	value=type(value)=="table" and value or {}
	local complete=value.tutorialComplete
	if complete==nil then complete=number(value.carsSold,0,1e12)>0 or number(value.step,0,240)>6 end
	local parts=type(value.tutorialParts)=="table" and value.tutorialParts or {}
	return {version=2,step=number(value.step,0,240),cash=number(value.cash,400,1e12),carsSold=number(value.carsSold,0,1e12),
		tutorialComplete=complete==true,tutorialStage=type(value.tutorialStage)=="string" and value.tutorialStage or "build_seller_corner",
		tutorialParts={Body=true,Engine=parts.Engine==true,Wheels=parts.Wheels==true},
		tutorialTradeId=type(value.tutorialTradeId)=="string" and value.tutorialTradeId or nil}
end
function Profiles.load(player)
	if active[player] then return active[player].data end
	local enabled=not RunService:IsStudio() or workspace:GetAttribute("FullJourneyStudioPersistence")==true
	local data=normalize(memory[player.UserId])
	local writable=false
	local status="Studio session"
	if enabled then
		local lockedData
		local ok,value=pcall(function()
			return store:UpdateAsync(tostring(player.UserId),function(old)
				old=type(old)=="table" and old or {}
				if old.session and old.session~=session and (tonumber(old.lease) or 0)>os.time() then
					lockedData=normalize(old.data)
					return nil -- Read-only session; never overwrite another server's lease.
				end
				return {data=normalize(old.data),session=session,lease=os.time()+180}
			end)
		end)
		if ok and value and value.session==session then data=normalize(value.data);writable=true;status="Connected"
		elseif lockedData then data=lockedData;status="Session only (active elsewhere)"
		else status="Session only (load failed)" end
	end
	player:SetAttribute("FullJourneySaveStatus",status)
	active[player]={data=data,writable=writable,saving=false}
	return data
end
function Profiles.save(player,release)
	local entry=active[player]
	if not entry then return true end
	release=release==true or entry.releaseRequested==true or closing
	if entry.saving then
		if release then entry.releaseRequested=true end
		return false
	end
	memory[player.UserId]=normalize(entry.data)
	if not entry.writable then
		if release then active[player]=nil end
		return true
	end
	entry.saving=true
	local saved=false
	local ownershipLost=false
	for attempt=1,(release and 3 or 1) do
		-- Take the latest state after any prior in-flight save or retry, so an
		-- Operations.stop refund is included in the final snapshot.
		local snapshot=normalize(entry.data)
		local ok,value=pcall(function()
			return store:UpdateAsync(tostring(player.UserId),function(old)
				if type(old)~="table" or old.session~=session then ownershipLost=true;return nil end
				return {data=snapshot,session=not release and session or nil,lease=not release and os.time()+180 or 0}
			end)
		end)
		saved=ok and value~=nil
		if saved or ownershipLost then break end
		if attempt<3 and release then
			if closing and os.clock()+attempt>=closeDeadline then break end
			task.wait(attempt)
		end
	end
	entry.saving=false
	if ownershipLost then
		entry.writable=false
		player:SetAttribute("FullJourneySaveStatus","Session only (ownership changed)")
		if release or entry.releaseRequested then active[player]=nil end
		return false
	end
	player:SetAttribute("FullJourneySaveStatus",saved and "Saved" or release and "Save failed; retrying" or "Retrying")
	if release then
		if saved then active[player]=nil else entry.releaseRequested=true end
	elseif entry.releaseRequested then
		return Profiles.save(player,true)
	end
	return saved
end
function Profiles.release(player) Profiles.save(player,true) end
task.spawn(function()
	while not closing do
		task.wait(60)
		if closing then break end
		for player in active do task.spawn(Profiles.save,player,false) end
	end
end)
-- The main service calls close only after stopping/refunding every operation.
function Profiles.close()
	if not closing then
		closing=true;closeDeadline=os.clock()+22
		for player in active do task.spawn(Profiles.save,player,true) end
	end
	while next(active)~=nil and os.clock()<closeDeadline do task.wait(.1) end
	return next(active)==nil
end
return Profiles
