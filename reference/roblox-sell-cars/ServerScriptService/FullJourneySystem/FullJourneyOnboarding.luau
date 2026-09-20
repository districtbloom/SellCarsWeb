-- FullJourney adapter for the original Sell Cars onboarding contract.
-- Reuses ObjectiveClient, RexVoiceClient, the original subtitle GUI and gameplay
-- events. No new HUD, narration renderer or replacement tutorial loop is created.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(script.Parent.FullJourneyCatalog)
local RexVoiceConfig = require(ReplicatedStorage:WaitForChild("RexVoiceConfig"))
local Onboarding = {}
local getRecords, getForPlayer
local initialized = false
local stateByRecord, signatures, revisions, cues, requestAt, clientReady = {}, {}, {}, {}, {}, {}
local progressionRemote, requestRemote, rexRemote
local CHAPTERS = {BIRTH=1, WORKING=2, DEDICATED=3, PROFESSIONAL=4, INSTITUTION=5}
local EVENT_NAMES = {"CarArrived","TradeOpened","CarBought","PartFixed","RepairCompleted","CarListed","OfferRequested","OfferReceived","CarSold","PadPurchased","SessionStarted"}

local function ensure(parent, name)
	local object = parent:FindFirstChild(name)
	assert(not object or object:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
	if not object then object = Instance.new("RemoteEvent"); object.Name = name; object.Parent = parent end
	return object
end
local function valid(record)
	return record and record.owner and record.owner.Parent == Players and record.data ~= nil
end
local function normalize(record)
	local data = record.data
	if data.tutorialComplete == nil then data.tutorialComplete = (tonumber(data.carsSold) or 0) > 0 end
	if type(data.tutorialParts) ~= "table" then data.tutorialParts = {Body=true,Engine=false,Wheels=false} end
	data.tutorialParts.Body = true
	data.tutorialParts.Engine = data.tutorialParts.Engine == true
	data.tutorialParts.Wheels = data.tutorialParts.Wheels == true
	if type(data.tutorialStage) ~= "string" or data.tutorialStage == "" then
		data.tutorialStage = data.tutorialComplete and "complete" or "build_seller_corner"
	end
	if data.tutorialComplete then data.tutorialStage = "complete" end
	return data
end
-- Call once after loading a claimed plot, before starting Operations. Runtime
-- cars are intentionally not saved, and Operations.stop refunds any unfinished
-- purchase. Restart the unfinished first deal to match the new Rusty car's
-- condition; keep the purchased building steps, balance and completed tutorial.
function Onboarding.resume(record)
	if not record or not record.data then return false end
	local data = normalize(record)
	stateByRecord[record] = nil
	if record.owner then
		signatures[record.owner] = nil
		cues[record.owner] = nil
	end
	if data.tutorialComplete then return false end
	data.tutorialParts = {Body=true,Engine=false,Wheels=false}
	data.tutorialTradeId = nil
	data.tutorialStage = (tonumber(data.step) or 0) < 2 and "build_seller_corner" or "awaiting_seller"
	return true
end
function Onboarding.isTutorial(record)
	return valid(record) and normalize(record).tutorialComplete ~= true
end
function Onboarding.getDeal(record)
	if not Onboarding.isTutorial(record) then return nil end
	local data = normalize(record)
	return {
		index=1,tutorialDealIndex=1,carId="Rusty",model="RustyCar",ask=25,
		fixedValue=1000,fixedOffer=1000,preRepaired={Body=true},
		parts={Body=true,Engine=data.tutorialParts.Engine==true,Wheels=data.tutorialParts.Wheels==true},
		manualParts={"Engine","Wheels"},diagnosis="ENGINE IS DEAD · FRONT-LEFT WHEEL IS MISSING",
		repairObjective="RESTORE RUSTY",sellObjective="SELL RUSTY",beat="TRANSFORMATION",
		sellerNeverExpires=true,salesmanStep=6,manualFirstSale=true,skipDepartments=true,
	}
end
-- Optional purchase gate for the server purchase handler. These are original
-- first-deal beats: do not buy beyond the first handover until Rusty is sold.
function Onboarding.canPurchase(record, entry)
	if not Onboarding.isTutorial(record) then return true end
	local data = normalize(record)
	if entry.step <= 2 then return true end
	if entry.step == 3 then
		if data.tutorialStage == "repair_engine" or data.tutorialStage == "repair_wheels"
			or data.tutorialParts.Engine or data.tutorialParts.Wheels then return true end
		return false, "Meet the seller and buy Rusty first"
	end
	if entry.step <= 6 then
		if data.tutorialParts.Engine == true and data.tutorialParts.Wheels == true then return true end
		return false, "Restore Rusty's engine and front-left wheel first"
	end
	return false, "Close Rusty's first sale before expanding"
end
local function objective(id,text,target,current,total,reward)
	return {id=id,text=text,current=current or 0,total=total or 1,reward=reward,targetTag=target}
end
local function padObjective(record, stepId, text, cue)
	local entry = Catalog.Next(record.data.step)
	if not entry then return "Complete",nil,nil end
	return stepId or "buy_pad:"..entry.id, objective(stepId or "buy_pad:"..entry.id,text or string.upper(entry.title),entry.id),cue
end
local function repaired(data)
	return data.tutorialParts.Engine == true and data.tutorialParts.Wheels == true
end
local function resolve(record, state)
	local data = normalize(record)
	local n = data.step or 0
	if data.tutorialComplete then
		if n >= Catalog.Count then return "Complete",nil,nil end
		return padObjective(record)
	end
	local stage = data.tutorialStage
	if n == 0 then return padObjective(record,"claim_workyard","CLAIM THE WORKYARD","TUTORIAL_00") end
	if n < 2 then return padObjective(record,"buy_cash_register","BUILD THE SELLER CORNER","TUTORIAL_00") end
	if stage == "build_seller_corner" or stage == "awaiting_seller" then
		return "wait_for_seller",objective("wait_for_seller","SELLER IS PULLING IN"),"TUTORIAL_01"
	end
	if stage == "meet_seller" then
		return "meet_seller",objective("meet_seller","MEET THE SELLER","TutorialSeller"),"TUTORIAL_02"
	end
	if stage == "repair_engine" or stage == "repair_wheels" then
		if n < 3 then return padObjective(record,"buy_car_jack","INSTALL THE REPAIR KIT","FJ_REPAIR_KIT") end
		local current = (data.tutorialParts.Engine and 1 or 0) + (data.tutorialParts.Wheels and 1 or 0)
		local part = data.tutorialParts.Engine and "Wheels" or "Engine"
		return "fix_car",objective("fix_car","RESTORE RUSTY","TutorialRepair",current,2),part=="Engine" and "TUTORIAL_03" or "FJ_REPAIR_WHEEL"
	end
	if stage == "prepare_sales" or stage == "hire_manny" or repaired(data) and n < 6 then
		if n < 4 then return padObjective(record,nil,"ADD THE WASH AND FINISH CADDY","FJ_FINISH_CADDY") end
		if n < 5 then return padObjective(record,nil,"ADD PHONE-PHOTO LISTING","FJ_PHONE_LISTING") end
		if n < 6 then return padObjective(record,"hire_first_salesman","BUILD THE SALES DESK & HIRE MANNY","TUTORIAL_04") end
		return "salesman_transporting",objective("salesman_transporting","MANNY IS PARKING RUSTY"),"TUTORIAL_05"
	end
	if stage == "transporting" then
		return "salesman_transporting",objective("salesman_transporting","MANNY IS PARKING RUSTY"),"TUTORIAL_05"
	end
	if stage == "wait_for_buyer" then
		return "wait_for_buyer",objective("wait_for_buyer","BUYER IS WALKING OVER"),"TUTORIAL_06"
	end
	if stage == "sell_car" then
		return "sell_car",objective("sell_car","SELL RUSTY","TutorialBuyer",0,1,1000),"TUTORIAL_07"
	end
	return "wait_for_seller",objective("wait_for_seller","SELLER IS PULLING IN"),"TUTORIAL_01"
end
Onboarding.resolve = resolve

local function cue(record, lineId, force)
	if not lineId or not RexVoiceConfig.Lines[lineId] then return end
	local player = record.owner
	if not clientReady[player] then return end
	local bucket = cues[player]
	if not bucket then bucket = {}; cues[player] = bucket end
	local key = "fulljourney:rusty:" .. lineId
	if bucket[key] and not force then return end
	bucket[key] = true
	rexRemote:FireClient(player,{lineId=lineId,dedupeKey=key,priority=100})
end
function Onboarding.refresh(record, state, force)
	if not initialized or not valid(record) then return end
	if type(state) == "table" then stateByRecord[record] = state end
	state = stateByRecord[record] or {}
	local data = normalize(record)
	local player = record.owner
	local stepId, task, lineId = resolve(record,state)
	local entry = Catalog.Next(data.step)
	local chapter = CHAPTERS[entry and entry.chapter or "INSTITUTION"] or 1
	player:SetAttribute("ProgressionChapter",chapter)
	player:SetAttribute("ProgressionObjectiveStep",stepId)
	player:SetAttribute("TutorialComplete",data.tutorialComplete)
	player:SetAttribute("TutorialDealIndex",data.tutorialComplete and 2 or 1)
	player:SetAttribute("FullJourneyTutorialStage",data.tutorialStage)
	local signature = table.concat({tostring(chapter),stepId,tostring(data.tutorialComplete),
		task and task.text or "",task and tostring(task.current) or "",task and tostring(task.total) or "",
		task and tostring(task.reward) or "",task and task.targetTag or ""},"|")
	if force or signatures[player] ~= signature then
		signatures[player] = signature
		revisions[player] = (revisions[player] or 0) + 1
		progressionRemote:FireClient(player,{chapter=chapter,objectiveStep=stepId,
			tutorialComplete=data.tutorialComplete,revision=revisions[player],objective=task})
	end
	-- The original client owns portrait animation, cue ordering and deduplication.
	-- Audio is globally disabled in RexVoiceConfig; these cues retain their subtitles.
	cue(record,lineId)
end
function Onboarding.onEvent(record, eventName, payload)
	if not valid(record) then return end
	payload = type(payload) == "table" and payload or {}
	local data = normalize(record)
	local index = tonumber(payload.tutorialDealIndex)
	local isFirst = not data.tutorialComplete and (index == nil or index == 1)
	if isFirst then
		if type(payload.tradeId) == "string" and payload.tradeId ~= "" then
			data.tutorialTradeId = payload.tradeId
		end
		if eventName == "SellerSourced" then data.tutorialStage = "awaiting_seller"
		elseif eventName == "CarArrived" or eventName == "TradeOpened" then data.tutorialStage = "meet_seller"
		elseif eventName == "CarBought" then data.tutorialStage = data.tutorialParts.Engine and "repair_wheels" or "repair_engine"
		elseif eventName == "PartFixed" then
			local part = payload.partId or payload.part or payload.id
			if part == "Engine" or part == "Wheels" then data.tutorialParts[part] = true end
			data.tutorialStage = repaired(data) and "prepare_sales" or data.tutorialParts.Engine and "repair_wheels" or "repair_engine"
		elseif eventName == "RepairCompleted" then
			data.tutorialParts.Engine = true; data.tutorialParts.Wheels = true; data.tutorialStage = "prepare_sales"
		elseif eventName == "CarListed" or eventName == "OfferRequested" then data.tutorialStage = "wait_for_buyer"
		elseif eventName == "OfferReceived" then data.tutorialStage = "sell_car"
		elseif eventName == "CarSold" then
			data.tutorialComplete = true; data.tutorialStage = "complete"
		elseif eventName == "PadPurchased" then
			local step = tonumber(payload.step) or data.step
			if step >= 6 and repaired(data) then data.tutorialStage = "transporting"
			elseif step >= 5 and repaired(data) then data.tutorialStage = "hire_manny"
			elseif step >= 2 and data.tutorialStage == "build_seller_corner" then data.tutorialStage = "awaiting_seller" end
		end
	end
	Onboarding.refresh(record,payload.operations)
	if eventName == "CarSold" and (index == 1 or isFirst) then cue(record,"TUTORIAL_08") end
end
function Onboarding.release(record)
	if not record then return end
	stateByRecord[record] = nil
	local player = record.owner
	if player then signatures[player]=nil; revisions[player]=nil; cues[player]=nil; requestAt[player]=nil end
end
function Onboarding.init(recordsGetter, playerGetter)
	if initialized then return end
	assert(type(recordsGetter)=="function" and type(playerGetter)=="function","Onboarding needs plot getter functions")
	getRecords,getForPlayer = recordsGetter,playerGetter
	local folder = ReplicatedStorage:FindFirstChild("TycoonRemotes")
	if not folder then folder=Instance.new("Folder");folder.Name="TycoonRemotes";folder.Parent=ReplicatedStorage end
	progressionRemote = ensure(folder,"ProgressionState")
	requestRemote = ensure(folder,"RequestProgressionState")
	rexRemote = ensure(ReplicatedStorage,RexVoiceConfig.RemoteName)
	initialized = true
	rexRemote.OnServerEvent:Connect(function(player, kind)
		if kind ~= "Ready" or clientReady[player] then return end
		clientReady[player] = true
		local record = getForPlayer(player)
		if record then Onboarding.refresh(record,nil,true) end
	end)
	requestRemote.OnServerEvent:Connect(function(player)
		if requestAt[player] and os.clock()-requestAt[player]<0.5 then return end
		requestAt[player]=os.clock()
		local record = getForPlayer(player)
		if record then Onboarding.refresh(record,nil,true) end
	end)
	-- Also accept the original event bus, for unchanged original trade/repair callers.
	-- Direct onEvent calls and bus receipts are idempotent; the adapter never re-emits them.
	local tycoonSystem = script.Parent.Parent:FindFirstChild("TycoonSystem")
	local busModule = tycoonSystem and tycoonSystem:FindFirstChild("GameplayEvents")
	if busModule then
		local bus = require(busModule)
		for _,name in EVENT_NAMES do
			local eventName = name
			bus.connect(eventName,function(player,payload)
				local record = getForPlayer(player)
				if record then Onboarding.onEvent(record,eventName,payload) end
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		signatures[player]=nil;revisions[player]=nil;cues[player]=nil;requestAt[player]=nil;clientReady[player]=nil
	end)
	for _,record in getRecords() do if valid(record) then Onboarding.refresh(record,nil,true) end end
end
return Onboarding

