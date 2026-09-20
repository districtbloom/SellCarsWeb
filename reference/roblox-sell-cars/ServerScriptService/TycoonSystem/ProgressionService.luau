--!strict

-- Single server authority for the retention-first progression contract. The save owns the
-- durable chapter/step; this service derives moment-to-moment tutorial objectives and
-- publishes one compact DTO for every client surface.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local DataService = require(script.Parent.DataService)
local GameplayEvents = require(script.Parent.GameplayEvents)
local TycoonService = require(script.Parent.TycoonService)
local DealerCar = require(script.Parent.JunkLot.DealerCar)

local remotesFolder = ReplicatedStorage:FindFirstChild("TycoonRemotes")
if remotesFolder == nil then
	local created = Instance.new("Folder")
	created.Name = "TycoonRemotes"
	created.Parent = ReplicatedStorage
	remotesFolder = created
end

local progressionRemote = remotesFolder:FindFirstChild("ProgressionState")
if progressionRemote == nil or not progressionRemote:IsA("RemoteEvent") then
	if progressionRemote ~= nil then
		progressionRemote:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = "ProgressionState"
	created.Parent = remotesFolder
	progressionRemote = created
end
local ProgressionState = progressionRemote :: RemoteEvent

local requestRemote = remotesFolder:FindFirstChild("RequestProgressionState")
if requestRemote == nil or not requestRemote:IsA("RemoteEvent") then
	if requestRemote ~= nil then
		requestRemote:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = "RequestProgressionState"
	created.Parent = remotesFolder
	requestRemote = created
end
local RequestProgressionState = requestRemote :: RemoteEvent

export type ObjectiveDTO = {
	id: string,
	text: string,
	current: number,
	total: number,
	reward: number?,
	targetTag: string?,
}
export type ProgressionDTO = {
	chapter: number,
	objectiveStep: string,
	tutorialComplete: boolean,
	revision: number,
	objective: ObjectiveDTO?,
}

local ProgressionService = {}
local lastPublishedSignature: { [Player]: string } = {}

type ObjectiveHint = {
	name: string,
	payload: any,
}

local function padTarget(padId: string): string?
	local definition = TycoonConfig.getPad(padId)
	return if definition ~= nil then definition.id else nil
end

-- Purchase objectives target the physical purchase pad through its unique PadId, never through
-- a reused part name such as CeilingBuyPad or SideDoorBuyPad. The client resolves that ID back
-- to the hidden purchase pad, so guides remain exact across every zone and rotated tycoon.
local STEP_OBJECTIVES: { [string]: ObjectiveDTO } = {
	buy_cash_register = { id = "buy_cash_register", text = "BUY CASH REGISTER", current = 0, total = 1, targetTag = padTarget("CashRegister") },
	buy_car_jack = { id = "buy_car_jack", text = "BUY CAR JACK", current = 0, total = 1, targetTag = padTarget("CarJack") },
	buy_air_compressor = { id = "buy_air_compressor", text = "BUY AIR COMPRESSOR", current = 0, total = 1, targetTag = padTarget("AirCompressor") },
	hire_first_mechanic = { id = "hire_first_mechanic", text = "HIRE A MECHANIC", current = 0, total = 1, targetTag = padTarget("FirstMechanic") },
	hire_first_salesman = { id = "hire_first_salesman", text = "HIRE A SALESMAN", current = 0, total = 1, targetTag = padTarget("FirstSalesman") },
	open_repair_bay = { id = "open_repair_bay", text = "OPEN THE REPAIR BAY", current = 0, total = 1, targetTag = padTarget("OpenRepairBay") },
	install_car_lift = { id = "install_car_lift", text = "INSTALL THE CAR LIFT", current = 0, total = 1, targetTag = padTarget("RB_CarLift") },
	hire_bay_mechanic = { id = "hire_bay_mechanic", text = "HIRE A BAY MECHANIC", current = 0, total = 1, targetTag = padTarget("RB_MechanicNPC") },
	upgrade_repair_bay = { id = "upgrade_repair_bay", text = "UPGRADE REPAIR BAY", current = 0, total = 1, targetTag = padTarget("RB_RepairBaySign") },
	build_car_wash = { id = "build_car_wash", text = "BUILD THE CAR WASH", current = 0, total = 1, targetTag = padTarget("CW_Foundation") },
	install_wash_brush = { id = "install_wash_brush", text = "INSTALL BRUSH MACHINE", current = 0, total = 1, targetTag = padTarget("CW_BrushMachine") },
	build_wash_shell = { id = "build_wash_shell", text = "BUILD CAR WASH SHELL", current = 0, total = 1, targetTag = padTarget("CW_Ceiling") },
	install_wash_dryer = { id = "install_wash_dryer", text = "INSTALL FAN DRYER", current = 0, total = 1, targetTag = padTarget("CW_FanDryer") },
	install_wash_polish = { id = "install_wash_polish", text = "INSTALL POLISH STATION", current = 0, total = 1, targetTag = padTarget("CW_PolishStation") },
	install_wash_tank = { id = "install_wash_tank", text = "INSTALL WATER TANK", current = 0, total = 1, targetTag = padTarget("CW_WaterTank") },
	build_second_wash = { id = "build_second_wash", text = "BUILD THE SECOND WASH LANE", current = 0, total = 1, targetTag = padTarget("CW2_Foundation") },
	install_second_brush = { id = "install_second_brush", text = "INSTALL SECOND BRUSH", current = 0, total = 1, targetTag = padTarget("CW2_BrushMachine") },
	build_second_shell = { id = "build_second_shell", text = "BUILD SECOND WASH SHELL", current = 0, total = 1, targetTag = padTarget("CW2_Ceiling") },
	install_second_dryer = { id = "install_second_dryer", text = "INSTALL SECOND DRYER", current = 0, total = 1, targetTag = padTarget("CW2_FanDryer") },
	install_second_polish = { id = "install_second_polish", text = "INSTALL SECOND POLISHER", current = 0, total = 1, targetTag = padTarget("CW2_PolishStation") },
	install_second_tank = { id = "install_second_tank", text = "INSTALL SECOND WATER TANK", current = 0, total = 1, targetTag = padTarget("CW2_WaterTank") },
	build_tuning_atelier = { id = "build_tuning_atelier", text = "BUILD THE TUNING ATELIER", current = 0, total = 1, targetTag = padTarget("TA_Foundation") },
	install_dyno = { id = "install_dyno", text = "INSTALL DYNO", current = 0, total = 1, targetTag = padTarget("TA_DynoRollers") },
	hire_dyno_specialist = { id = "hire_dyno_specialist", text = "HIRE A DYNO SPECIALIST", current = 0, total = 1, targetTag = padTarget("TA_DynoSpecialist") },
	install_body_station = { id = "install_body_station", text = "INSTALL BODY KIT STATION", current = 0, total = 1, targetTag = padTarget("TA_BodyKitStation") },
	hire_body_specialist = { id = "hire_body_specialist", text = "HIRE A BODY SPECIALIST", current = 0, total = 1, targetTag = padTarget("TA_BodySpecialist") },
	install_paint_booth = { id = "install_paint_booth", text = "INSTALL PAINT BOOTH", current = 0, total = 1, targetTag = padTarget("TA_PaintControl") },
	hire_paint_specialist = { id = "hire_paint_specialist", text = "HIRE A PAINT SPECIALIST", current = 0, total = 1, targetTag = padTarget("TA_PaintSpecialist") },
	finish_tuning_atelier = { id = "finish_tuning_atelier", text = "FINISH TUNING ATELIER", current = 0, total = 1, targetTag = padTarget("TA_Compressor") },
	business_complete = { id = "business_complete", text = "YOUR BUSINESS IS RUNNING!", current = 1, total = 1 },
}

-- Durable progression stores purchase-pad ids. Map milestone pads back to the concise,
-- action-specific chapter copy above instead of composing contradictions such as
-- BUILD OPEN REPAIR BAY or BUILD INSTALL CAR LIFT.
local PAD_OBJECTIVE_STEP: { [string]: string } = {
	CashRegister = "buy_cash_register",
	CarJack = "buy_car_jack",
	AirCompressor = "buy_air_compressor",
	FirstMechanic = "hire_first_mechanic",
	FirstSalesman = "hire_first_salesman",
	OpenRepairBay = "open_repair_bay",
	RB_CarLift = "install_car_lift",
	RB_MechanicNPC = "hire_bay_mechanic",
	RB_RepairBaySign = "upgrade_repair_bay",
	CW_Foundation = "build_car_wash",
	CW_BrushMachine = "install_wash_brush",
	CW_Ceiling = "build_wash_shell",
	CW_FanDryer = "install_wash_dryer",
	CW_PolishStation = "install_wash_polish",
	CW_WaterTank = "install_wash_tank",
	CW2_Foundation = "build_second_wash",
	CW2_BrushMachine = "install_second_brush",
	CW2_Ceiling = "build_second_shell",
	CW2_FanDryer = "install_second_dryer",
	CW2_PolishStation = "install_second_polish",
	CW2_WaterTank = "install_second_tank",
	TA_Foundation = "build_tuning_atelier",
	TA_DynoRollers = "install_dyno",
	TA_DynoSpecialist = "hire_dyno_specialist",
	TA_BodyKitStation = "install_body_station",
	TA_BodySpecialist = "hire_body_specialist",
	TA_PaintControl = "install_paint_booth",
	TA_PaintSpecialist = "hire_paint_specialist",
	TA_Compressor = "finish_tuning_atelier",
}

local function cloneObjective(source: ObjectiveDTO?): ObjectiveDTO?
	if source == nil then
		return nil
	end
	return table.clone(source)
end

local function allPartsRepaired(car: DataService.ActiveCarSave): boolean
	for _, part in DealerCarConfig.PARTS do
		if car.parts[part.id] ~= true then
			return false
		end
	end
	return true
end

local function waitObjective(step: string, text: string, targetTag: string?): (string, ObjectiveDTO)
	return step, {
		id = step,
		text = text,
		current = 0,
		total = 1,
		targetTag = targetTag,
	}
end

local function waitForBuyerObjective(): (string, ObjectiveDTO)
	-- Passive travel is information, not an action. Do not point at the car while the buyer
	-- is unavailable; the exact NPC becomes the target only when the offer can be accepted.
	return waitObjective("wait_for_buyer", "BUYER IS WALKING OVER", nil)
end

local function sellObjective(car: DataService.ActiveCarSave?, minimumOffer: number): (string, ObjectiveDTO)
	local minimum = math.max(1, math.floor(minimumOffer))
	local tutorialDeal = if car ~= nil then DealerCarConfig.tutorialDeal(car.tutorialDealIndex) else nil
	return "sell_car", {
		id = "sell_car",
		text = if tutorialDeal ~= nil then tutorialDeal.sellObjective else `SELL FOR ${minimum} OR MORE`,
		current = 0,
		total = 1,
		reward = minimum,
		targetTag = "TutorialBuyer",
	}
end

local function workingObjective(player: Player, car: DataService.ActiveCarSave): (string?, ObjectiveDTO?)
	-- Dealer stock is staff-only. Once Rusty is roadworthy, the exact Salesman purchase pad
	-- becomes the next action. Transport itself is passive, so it deliberately has no arrow.
	if car.state == "Ready" or allPartsRepaired(car) then
		local data = DataService.get(player)
		if data ~= nil and data.pads.FirstSalesman ~= true then
			return "hire_first_salesman", cloneObjective(STEP_OBJECTIVES.hire_first_salesman)
		end
		return waitObjective("salesman_transporting", "SALESMAN IS PARKING RUSTY", nil)
	elseif car.cost > 0 or car.state == "Junk" or car.state == "Repairing" then
		local current, total = DealerCarConfig.tutorialManualProgress(car.tutorialDealIndex, car.parts)
		local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
		return "fix_car", {
			id = "fix_car",
			text = if tutorialDeal ~= nil then tutorialDeal.repairObjective else "REPAIR THE CAR",
			current = current,
			total = total,
			targetTag = "TutorialRepair",
		}
	elseif car.state == "Incoming" then
		return waitObjective("seller_pulling_in", "SELLER IS PULLING IN", "TutorialIncomingCar")
	elseif car.state == "Offered" then
		return "meet_seller", {
			id = "meet_seller",
			text = "MEET THE SELLER",
			current = 0,
			total = 1,
			targetTag = "TutorialSeller",
		}
	end
	return nil, nil
end

local function displayObjective(car: DataService.ActiveCarSave): (string?, ObjectiveDTO?)
	if car.state == "Offer" then
		local minimum = if car.offered > 0 then car.offered else car.listedPrice
		return sellObjective(car, minimum)
	elseif car.state == "Listed" then
		return waitForBuyerObjective()
	end
	return nil, nil
end

local function currentTutorialDeal(data: DataService.SaveData): number
	return math.floor(data.tutorial.dealIndex)
end

local function hintMatchesCurrentDeal(data: DataService.SaveData, payload: any): boolean
	if typeof(payload) ~= "table" then
		return false
	end
	local hintedDeal = tonumber(payload.tutorialDealIndex)
	local currentDeal = currentTutorialDeal(data)
	return hintedDeal == nil
		or currentDeal < 1
		or currentDeal > DealerCarConfig.TUTORIAL_DEAL_COUNT
		or math.floor(hintedDeal) == currentDeal
end

local function hintedTutorialObjective(
	player: Player,
	data: DataService.SaveData,
	hint: ObjectiveHint?
): (string?, ObjectiveDTO?)
	if hint == nil or not hintMatchesCurrentDeal(data, hint.payload) then
		return nil, nil
	end
	local payload = hint.payload
	if hint.name == "CarBought" or hint.name == "RepairCompleted" then
		local index = tonumber(payload.workingIndex)
		local car = if index ~= nil then DataService.getWorking(data, math.floor(index)) else nil
		if car ~= nil then
			return workingObjective(player, car)
		end
	elseif hint.name == "CarListed" then
		return waitForBuyerObjective()
	elseif hint.name == "OfferRequested" then
		return waitObjective("get_ready_to_deal", "BUYER IS WALKING OVER", nil)
	elseif hint.name == "OfferReceived" then
		local tradeId = tostring(payload.tradeId or "")
		local matched: DataService.ActiveCarSave? = nil
		for index = 1, DataService.displayCapacityForPads(data.pads) do
			local candidate = DataService.getDisplay(data, index)
			if candidate ~= nil and candidate.tradeId == tradeId then
				matched = candidate
				break
			end
		end
		return sellObjective(matched, tonumber(payload.currentOffer) or 1)
	end
	return nil, nil
end

local function tutorialObjective(player: Player, data: DataService.SaveData, hint: ObjectiveHint?): (string, ObjectiveDTO)
	-- Existing saves may already be in the middle of a tutorial deal from before the
	-- Cash Register-first sequence. Let that exact car finish; otherwise Register is the
	-- first paid action and no seller is sourced before it exists.
	local hasTutorialStock = false
	for index = 1, DataService.displayCapacityForPads(data.pads) do
		local car = DataService.getDisplay(data, index)
		if car ~= nil
			and car.tutorialDealIndex >= 1
			and car.tutorialDealIndex <= DealerCarConfig.TUTORIAL_DEAL_COUNT
		then
			hasTutorialStock = true
			break
		end
	end
	if not hasTutorialStock then
		for index = 1, DataService.workingCapacityForPads(data.pads) do
			local car = DataService.getWorking(data, index)
			if car ~= nil
				and car.tutorialDealIndex >= 1
				and car.tutorialDealIndex <= DealerCarConfig.TUTORIAL_DEAL_COUNT
			then
				hasTutorialStock = true
				break
			end
		end
	end
	if data.pads.CashRegister ~= true and not hasTutorialStock then
		return "buy_cash_register", cloneObjective(STEP_OBJECTIVES.buy_cash_register) :: ObjectiveDTO
	end

	-- Event payloads are authoritative transition receipts. They bridge the tiny interval
	-- before the matching DealerCar state mutation without becoming persistent state.
	local hintedStep, hintedObjective = hintedTutorialObjective(player, data, hint)
	if hintedStep ~= nil and hintedObjective ~= nil then
		return hintedStep, hintedObjective
	end

	local dealIndex = currentTutorialDeal(data)
	local matchExactDeal = dealIndex >= 1 and dealIndex <= DealerCarConfig.TUTORIAL_DEAL_COUNT

	-- Display wins over working. During the W -> P commit the same car can briefly be
	-- observable from both systems; once P is Listed, DRIVE must disappear immediately.
	for index = 1, DataService.displayCapacityForPads(data.pads) do
		local car = DataService.getDisplay(data, index)
		if car ~= nil and (not matchExactDeal or car.tutorialDealIndex == dealIndex) then
			local step, objective = displayObjective(car)
			if step ~= nil and objective ~= nil then
				return step, objective
			end
		end
	end

	for index = 1, DataService.workingCapacityForPads(data.pads) do
		local car = DataService.getWorking(data, index)
		if car ~= nil and (not matchExactDeal or car.tutorialDealIndex == dealIndex) then
			local step, objective = workingObjective(player, car)
			if step ~= nil and objective ~= nil then
				return step, objective
			end
		end
	end

	-- Cash Register is built and the next deterministic seller has not yet reserved W1.
	-- This is a real waiting state, not an instruction to buy a car that does not exist.
	return waitObjective("wait_for_seller", "SELLER IS PULLING IN", nil)
end

local function padPurchaseObjective(step: string): ObjectiveDTO?
	local padId = string.match(step, "^buy_pad:(.+)$")
	if padId == nil then
		return nil
	end
	local definition = TycoonConfig.getPad(padId)
	if definition == nil then
		return nil
	end

	local milestoneStep = PAD_OBJECTIVE_STEP[padId]
	local milestone = if milestoneStep ~= nil then cloneObjective(STEP_OBJECTIVES[milestoneStep]) else nil
	if milestone ~= nil then
		milestone.id = step
		milestone.targetTag = definition.id
		return milestone
	end

	local title = string.upper(definition.title)
	local firstWord = string.match(title, "^(%S+)")
	local hasAuthoredAction = firstWord == "BUY"
		or firstWord == "BUILD"
		or firstWord == "OPEN"
		or firstWord == "INSTALL"
		or firstWord == "HIRE"
		or firstWord == "UPGRADE"
		or firstWord == "FINISH"
	local verb = "BUY"
	if definition.category == "AUTOMATION" or definition.kind == "npc" then
		verb = "HIRE"
	elseif definition.category == "EQUIPMENT" then
		verb = "INSTALL"
	elseif definition.category == "BUILD" or definition.kind == "structure" then
		verb = "BUILD"
	end
	return {
		id = step,
		text = if hasAuthoredAction then title else verb .. " " .. title,
		current = 0,
		total = 1,
		targetTag = definition.id,
	}
end

local function resolve(player: Player, hint: ObjectiveHint?): (string, ObjectiveDTO?)
	local data = DataService.get(player)
	if data == nil then
		return "loading", nil
	end
	if data.tutorial.completed ~= true then
		return tutorialObjective(player, data, hint)
	end
	local step = data.progression.objectiveStep
	-- Completion is terminal state, not a permanently completed HUD task.
	if step == "business_complete" then
		return "Complete", nil
	end
	local objective = cloneObjective(STEP_OBJECTIVES[step])
	if objective == nil then
		objective = padPurchaseObjective(step)
	end
	return step, objective
end

local function objectiveSignature(dto: ProgressionDTO): string
	local objective = dto.objective
	return table.concat({
		tostring(dto.chapter),
		dto.objectiveStep,
		tostring(dto.tutorialComplete),
		tostring(dto.revision),
		if objective ~= nil then objective.id else "",
		if objective ~= nil then objective.text else "",
		if objective ~= nil then tostring(objective.current) else "",
		if objective ~= nil then tostring(objective.total) else "",
		if objective ~= nil then tostring(objective.reward) else "",
		if objective ~= nil then tostring(objective.targetTag) else "",
	}, "|")
end

function ProgressionService.publish(player: Player, force: boolean?, hint: ObjectiveHint?)
	local data = DataService.get(player)
	if data == nil then
		return
	end

	-- Refresh the durable chapter/next-pad step first. On the third sale this makes the
	-- first post-tutorial DTO contain BUY CASH REGISTER instead of a nil stale objective.
	DataService.refreshProgression(player)
	local objectiveStep, objective = resolve(player, hint)
	local progression = data.progression
	-- A progression reorder can send an old save back to an earlier mandatory build
	-- without deleting owned pads. Show the chapter of that current pad objective while
	-- keeping the durable saved chapter monotonic for compatibility and unlock checks.
	local displayChapter = progression.chapter
	local objectivePadId = string.match(objectiveStep, "^buy_pad:(.+)$")
	if objectivePadId ~= nil then
		local objectivePad = TycoonConfig.getPad(objectivePadId)
		if objectivePad ~= nil then
			displayChapter = objectivePad.chapter or displayChapter
		end
	end
	player:SetAttribute("ProgressionChapter", displayChapter)
	player:SetAttribute("ProgressionObjectiveStep", objectiveStep)
	player:SetAttribute("TutorialComplete", progression.tutorialComplete)

	local dto: ProgressionDTO = {
		chapter = displayChapter,
		objectiveStep = objectiveStep,
		tutorialComplete = progression.tutorialComplete,
		revision = progression.revision,
		objective = objective,
	}
	local signature = objectiveSignature(dto)
	if force == true or lastPublishedSignature[player] ~= signature then
		lastPublishedSignature[player] = signature
		ProgressionState:FireClient(player, dto)
	end
end

function ProgressionService.init()
	local function deferPublish(player: Player, hint: ObjectiveHint?)
		task.defer(function()
			if player.Parent ~= nil then
				-- Gameplay changes are dynamic and do not always increment the saved revision.
				ProgressionService.publish(player, true, hint)
			end
		end)
	end

	for _, eventName in {
		"CarArrived",
		"TradeOpened",
		"CarBought",
		"PartFixed",
		"RepairCompleted",
		"CarListed",
		"OfferRequested",
		"OfferReceived",
		"CarSold",
		"PadPurchased",
	} do
		local boundEventName = eventName
		GameplayEvents.connect(boundEventName, function(player: Player, payload: any)
			deferPublish(player, {
				name = boundEventName,
				payload = payload,
			})
		end)
	end
	-- This fires only after DealerCar has committed the exact state into SaveData, so it is
	-- the final authority that supersedes any event receipt from the transition.
	DealerCar.stateChanged.Event:Connect(function(player: Player)
		deferPublish(player)
	end)
	TycoonService.tycoonClaimed.Event:Connect(function(_record, player: Player)
		deferPublish(player)
	end)
	local requestAt: { [Player]: number } = {}
	RequestProgressionState.OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (requestAt[player] or 0) < 0.5 then
			return
		end
		requestAt[player] = now
		ProgressionService.publish(player, true)
	end)
	local function bindCharacter(player: Player, character: Model)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid ~= nil and humanoid:IsA("Humanoid") then
				humanoid.Seated:Connect(function()
					deferPublish(player)
				end)
			end
		end)
	end
	local function bindPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			bindCharacter(player, character)
		end)
		if player.Character ~= nil then
			bindCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastPublishedSignature[player] = nil
		requestAt[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		bindPlayer(player)
		deferPublish(player)
	end
end

return ProgressionService
