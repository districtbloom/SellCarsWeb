-- Owns the FullJourney mode. Purchases, money and progression are server authoritative.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local Catalog=require(script.Parent.FullJourneyCatalog)
local Renderer=require(script.Parent.FullJourneyRenderer)
local Profiles=require(script.Parent.FullJourneyProfiles)
local Operations=require(script.Parent.FullJourneyOperations)
local Bridge=require(script.Parent.FullJourneyLegacyBridge)
local Onboarding=require(script.Parent.FullJourneyOnboarding)
local Service={}
local records,assigned,loading={},{},{}
local initialized=false
local remotes
local function ensure(parent,name,class)
	local value=parent:FindFirstChild(name)
	if value then assert(value:IsA(class),name.." has wrong class") return value end
	value=Instance.new(class);value.Name=name;value.Parent=parent;return value
end
local function push(record)
	local player=record.owner
	if not player or not player.Parent or not record.data then return end
	local data=record.data
	local stats=ensure(player,"leaderstats","Folder")
	ensure(stats,"Cash","IntValue").Value=data.cash
	ensure(stats,"Builds","IntValue").Value=data.step
	player:SetAttribute("FullJourneyStep",data.step)
	player:SetAttribute("Cash",data.cash)
	local entry=Catalog.Next(data.step)
	remotes.State:FireClient(player,{
		owned=true,plot=record.folder,plotName=record.folder.Name,step=data.step,cash=data.cash,totalSteps=Catalog.Count,
		next=entry and {id=entry.id,title=entry.title,cost=entry.cost,step=entry.step,benefit=entry.benefit,part=record.pad} or nil,
		operations=Operations.getState(record),
	})
	Bridge.publish(record)
	Onboarding.refresh(record,Operations.getState(record))
end
local function padCFrame(record,entry)
	local delta=record.origin*record.sourceOrigin:Inverse()
	local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances={record.renderer.root,record.ground};ray.RespectCanCollide=true
	local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances={record.renderer.root};overlap.RespectCanCollide=true
	local candidates={entry.padPosition}
	for _,radius in {8,16,24} do
		for _,offset in {Vector3.new(radius,0,0),Vector3.new(-radius,0,0),Vector3.new(0,0,radius),Vector3.new(0,0,-radius)} do
			table.insert(candidates,entry.padPosition+offset)
		end
	end
	-- Permanent entrance apron is a reachable fallback when the new building occupies its suggested pad.
	table.insert(candidates,Vector3.new(3035,1.9,58))
	for _,source in candidates do
		local at=delta:PointToWorldSpace(source)
		local hit=workspace:Raycast(Vector3.new(at.X,7,at.Z),Vector3.new(0,-12,0),ray)
		if hit and hit.Normal.Y>.8 and hit.Position.Y<4.5 then
			local center=Vector3.new(at.X,hit.Position.Y+.13,at.Z)
			local room=CFrame.new(center+Vector3.new(0,3.25,0))*record.origin.Rotation
			if #workspace:GetPartBoundsInBox(room,Vector3.new(6,6,6),overlap)==0 then
				return CFrame.new(center)*record.origin.Rotation
			end
		end
	end
	return delta*CFrame.new(3035,1.75,48)
end
function Service.refresh(record,animate)
	local step=record.data and record.data.step or 0
	if record.renderer.step~=step then Renderer.apply(record.renderer,step,animate==true) end
	if record.pad then record.pad:Destroy();record.pad=nil end
	local entry=record.owner and Catalog.Next(step)
	if entry then
		local unlocked=Onboarding.canPurchase(record,entry)
		local pad=Instance.new("Part");pad.Name="NextPurchase"
		pad.Size=Vector3.new(6,.2,6);pad.Anchored=true;pad.CanCollide=false;pad.CanTouch=unlocked;pad.CanQuery=unlocked
		pad.Transparency=unlocked and 0 or 1
		pad.CFrame=padCFrame(record,entry);pad.Material=Enum.Material.Neon;pad.Color=Color3.fromRGB(86,210,155)
		pad:SetAttribute("PurchasePadId",entry.id);pad:SetAttribute("PurchasePadOpen",unlocked)
		pad:SetAttribute("PurchasePadCost",entry.cost);pad:SetAttribute("Title",entry.title);pad:SetAttribute("Benefit",entry.benefit)
		pad:SetAttribute("FullJourneyStep",entry.step);pad.Parent=record.folder;record.pad=pad
		pad:AddTag(entry.id)
	end
	record.folder:SetAttribute("FullJourneyStep",step)
	record.folder:SetAttribute("OwnerUserId",record.owner and record.owner.UserId or 0)
	record.folder:SetAttribute("OwnerName",record.owner and record.owner.DisplayName or "Available")
	record.folder:SetAttribute("NextPadId",entry and entry.id or nil)
	Operations.refresh(record)
	push(record)
end
function Service.purchase(player,payload)
	local record=assigned[player]
	local function result(ok,reason,entry,target)
		local value={ok=ok,reason=reason,purchaseId=type(payload)=="table" and payload.purchaseId or "",balance=record and record.data and record.data.cash or 0,
			cost=entry and entry.cost or 0,shortfall=entry and math.max(0,entry.cost-(record and record.data and record.data.cash or 0)) or 0,target=target}
		if player.Parent then remotes.PurchaseResult:FireClient(player,value) end
		return value
	end
	if not record or record.owner~=player or not record.data then return result(false,"No plot") end
	if record.busy then return result(false,"Busy") end
	local entry=Catalog.Next(record.data.step)
	if not entry then return result(false,"Complete") end
	if type(payload)~="table" or payload.purchaseId~=entry.id then return result(false,"This purchase is no longer available",entry) end
	local unlocked,lockedReason=Onboarding.canPurchase(record,entry)
	if not unlocked then return result(false,lockedReason,entry) end
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local human=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not human or human.Health<=0 or human.SeatPart or not record.pad then return result(false,"Step onto your pad",entry) end
	local localPos=record.pad.CFrame:PointToObjectSpace(root.Position)
	if math.abs(localPos.X)>5 or math.abs(localPos.Z)>5 or math.abs(localPos.Y)>7 then return result(false,"Step onto your pad",entry) end
	if record.data.cash<entry.cost then return result(false,"Not enough cash",entry) end
	record.busy=true
	local target=record.renderer.delta:PointToWorldSpace(entry.geometryFocus)
	record.data.cash-=entry.cost;record.data.step=entry.step
	Onboarding.onEvent(record,"PadPurchased",{step=entry.step,padId=entry.id})
	Service.refresh(record,true)
	record.busy=false
	-- The periodic save coalesces purchases; leaving also flushes the most recent state.
	return result(true,"Purchased",entry,target)
end
local function teleport(record,character)
	local root=character:WaitForChild("HumanoidRootPart",15)
	if not root or not record.owner or record.owner.Character~=character then return end
	local spawn=record.renderer.delta*CFrame.new(3035,5.4,96)
	character:PivotTo(spawn);root.AssemblyLinearVelocity=Vector3.zero
	task.delay(1,function() if record.owner and record.owner.Character==character then push(record) end end)
end
local function startOperations(record)
	record.hooks={
		getStep=function() return record.data and record.data.step or 0 end,
		getCash=function() return record.data and record.data.cash or 0 end,
		getTutorialDeal=function() return Onboarding.getDeal(record) end,
		openBuy=function(player) return Bridge.openBuy(record,player) end,
		openOffer=function(player)
			if Operations.canAct(record,player,"Sell") then Bridge.showOffer(record) end
		end,
		closed=function() Bridge.close(record) end,
		event=function(name,payload)
			Onboarding.onEvent(record,name,payload)
			Bridge.onEvent(record,name,payload)
			Service.refresh(record,false)
		end,
		spend=function(amount)
			if not record.owner or not record.data or amount<0 or record.data.cash<amount then return false end
			record.data.cash-=math.floor(amount);push(record);return true
		end,
		credit=function(amount)
			if record.data then record.data.cash=math.clamp(record.data.cash+math.floor(amount),0,1e12);push(record) end
		end,
		changed=function()
			if record.data then record.data.carsSold=(record.soldBefore or 0)+(record.folder:GetAttribute("CarsSold") or 0) end
			push(record)
		end,
		speedMultiplier=RunService:IsStudio() and (record.operationSpeed or 1) or 1,
	}
	Operations.start(record,record.hooks)
end
local function claim(player)
	if assigned[player] or loading[player] then return end
	loading[player]=true
	local record
	for _,candidate in records do if not candidate.owner then record=candidate;break end end
	if not record then
		loading[player]=nil;player:SetAttribute("FullJourneyPlotStatus","Waiting for a plot")
		return
	end
	record.owner=player;assigned[player]=record
	record.data=Profiles.load(player)
	if not player.Parent then
		Profiles.release(player);assigned[player]=nil;record.owner=nil;record.data=nil;loading[player]=nil;return
	end
	record.soldBefore=record.data.carsSold
	Onboarding.resume(record)
	player:SetAttribute("TycoonName",record.folder.Name)
	player:SetAttribute("FullJourneyPlotStatus","Ready")
	Service.refresh(record,false);startOperations(record)
	record.characterConnection=player.CharacterAdded:Connect(function(character) teleport(record,character) end)
	if player.Character then task.spawn(teleport,record,player.Character) end
	loading[player]=nil
end
local function release(player)
	local record=assigned[player]
	if not record then return end
	if record.characterConnection then record.characterConnection:Disconnect();record.characterConnection=nil end
	Operations.stop(record)
	Onboarding.release(record)
	Profiles.release(player)
	assigned[player]=nil;record.owner=nil;record.data=nil;record.busy=false
	Service.refresh(record,false)
	for _,waiting in Players:GetPlayers() do if not assigned[waiting] then task.spawn(claim,waiting) end end
end
function Service.getForPlayer(player) return assigned[player] end
function Service.getRecords() return records end
function Service.setProgress(record,step,cash)
	assert(RunService:IsStudio(),"Studio QA only")
	assert(record.data,"Plot has no owner")
	Operations.stop(record)
	record.data.step=math.clamp(math.floor(step),0,240);record.data.cash=math.max(0,math.floor(cash))
	Service.refresh(record,false);startOperations(record)
end
function Service.init()
	if initialized then return records end
	initialized=true
	remotes=ensure(RS,"FullJourneyRemotes","Folder")
	for _,name in {"State","Purchase","PurchaseResult"} do ensure(remotes,name,"RemoteEvent") end
	local assets=ensure(SS,"FullJourneyAssets","Folder")
	local template=workspace:FindFirstChild("TycoonTemplate") or assets:FindFirstChild("TycoonTemplate")
	assert(template and template:IsA("Model"),"Workspace.TycoonTemplate must be the FullJourney Model")
	template.Parent=assets
	local sourceParts=Renderer.init(template)
	local spawns=workspace:WaitForChild("TycoonSpawns")
	local markers=spawns:GetChildren();table.sort(markers,function(a,b)return a.Name<b.Name end)
	for _,marker in markers do
		if marker:IsA("BasePart") and marker.Name:match("^Tycoon%d+$") then
			assert(not workspace:FindFirstChild(marker.Name),"Conflicting legacy plot "..marker.Name)
			local folder=Instance.new("Folder");folder.Name=marker.Name;folder.Parent=workspace
			local record={folder=folder,origin=marker.CFrame,sourceOrigin=Catalog.SourceOrigin}
			record.renderer=Renderer.create(folder,record.origin,record.sourceOrigin)
			local ground=Instance.new("Part");ground.Name="PermanentPlotGround";ground.Anchored=true
			ground.Size=Vector3.new(300,1,690);ground.CFrame=record.origin*CFrame.new(0,.65,192)
			ground.Material=Enum.Material.Ground;ground.Color=Color3.fromRGB(133,115,86);ground.CanTouch=false
			ground.Parent=folder;record.ground=ground
			table.insert(records,record);Service.refresh(record,false)
		end
	end
	assert(#records==8,"Expected eight FullJourney spawn markers")
	Bridge.init(Service)
	Onboarding.init(Service.getRecords,Service.getForPlayer)
	remotes.Purchase.OnServerEvent:Connect(Service.purchase)
	local requested={}
	remotes.State.OnServerEvent:Connect(function(player)
		if requested[player] and os.clock()-requested[player]<.5 then return end
		requested[player]=os.clock()
		local record=assigned[player];if record then push(record) end
	end)
	Players.PlayerAdded:Connect(function(player) task.spawn(claim,player) end)
	Players.PlayerRemoving:Connect(function(player) requested[player]=nil;release(player) end)
	for _,player in Players:GetPlayers() do task.spawn(claim,player) end
	game:BindToClose(function()
		for player in assigned do Operations.stop(assigned[player]) end
		Profiles.close()
	end)
	workspace:SetAttribute("FullJourneyReady",true)
	workspace:SetAttribute("FullJourneySourceParts",sourceParts)
	print(string.format("[FullJourney] Ready: %d plots, %d purchases, %d source parts",#records,Catalog.Count,sourceParts))
	return records
end
return Service
