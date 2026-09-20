--!strict

-- Wires the junk lot together: owns remote validation and exact-slot restore, while
-- DealerCar, TradeService and LotAutomation own all stock mutations and workflows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local DataService = require(script.Parent.Parent.DataService)
local TycoonService = require(script.Parent.Parent.TycoonService)
local PadService = require(script.Parent.Parent.PadService)
local GameplayEvents = require(script.Parent.Parent.GameplayEvents)
local LotSlots = require(script.Parent.LotSlots)
local DealerCar = require(script.Parent.DealerCar)
local TradeService = require(script.Parent.TradeService)
local TowTruckService = require(script.Parent.TowTruckService)
local StaffDirector = require(script.Parent.StaffDirector)
local LotAutomation = require(script.Parent.LotAutomation)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord

local JunkLotService = {}

-- TycoonService claims existing players asynchronously during bootstrap. JunkLotService
-- starts later, so its claim listener can otherwise miss that one-time event entirely.
local configuredFor: { [Player]: Record } = {}
local remoteLastAt: { [Player]: { [string]: number } } = {}

local REMOTE_COOLDOWN = {
	ListCar = 0.5,
	OfferAction = 0.2,
	BuyAction = 0.2,
	RequestCarState = 1,
}

local function remoteAllowed(player: Player, remoteName: string): boolean
	local now = os.clock()
	local perPlayer = remoteLastAt[player]
	if perPlayer == nil then
		perPlayer = {}
		remoteLastAt[player] = perPlayer
	end
	local lastAt = perPlayer[remoteName] or 0
	local cooldown = REMOTE_COOLDOWN[remoteName] or 0.25
	if now - lastAt < cooldown then
		return false
	end
	perPlayer[remoteName] = now
	return true
end

local function validTradeId(value: unknown): boolean
	return typeof(value) == "string" and #value > 0 and #value <= 96
end

local function grantFreeStarterPads(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	for _, definition in TycoonConfig.PADS do
		if definition.starter == true then
			data.pads[definition.id] = true
		end
	end
end

local function restoreDisplaySlots(record: Record, player: Player)
	local capacity = math.min(DealerCar.displayCapacity(player), DealerCarConfig.MAX_DISPLAY_SLOTS)
	for displayIndex = 1, capacity do
		local display = DealerCar.display(player, displayIndex)
		if display ~= nil then
			TradeService.resume(player, record, display, "display", displayIndex)
			local current = DealerCar.display(player, displayIndex)
			if current ~= nil and current.tradeId == display.tradeId and current.state ~= "Sold" then
				DealerCar.spawn(player, record, false, "display", displayIndex)
			end
		else
			DealerCar.clearModel(player, "display", displayIndex)
			LotSlots.setDisplayStatus(record, false, 0, displayIndex)
		end
	end
end

local function sourceEmptyWorking(record: Record, player: Player, workingIndex: number): boolean
	if workingIndex > DealerCar.workingCapacity(player) or DealerCar.active(player, workingIndex) ~= nil then
		return false
	end
	DealerCar.clearModel(player, "working", workingIndex)
	TradeService.startIncoming(player, record, 0, workingIndex)
	return true
end

local function restoreWorkingSlots(record: Record, player: Player)
	local capacity = math.min(DealerCar.workingCapacity(player), DealerCarConfig.MAX_WORKING_SLOTS)
	-- Seller/fence sourcing is one serialized conversation. Request at most one missing W
	-- during restore; every resolved buy/refusal/listing schedules the next free W itself.
	local sourceRequested = false
	for workingIndex = 1, capacity do
		local working = DealerCar.active(player, workingIndex)
		if working == nil then
			if not sourceRequested then
				sourceRequested = sourceEmptyWorking(record, player, workingIndex)
			end
		elseif working.state == "Sold" then
			local _, staleModel = DealerCar.removeWorking(player, workingIndex, working.tradeId)
			if staleModel ~= nil then
				staleModel:Destroy()
			end
			if not sourceRequested then
				sourceRequested = sourceEmptyWorking(record, player, workingIndex)
			end
		else
			TradeService.resume(player, record, working, "working", workingIndex)
			local current = DealerCar.active(player, workingIndex)
			if current ~= nil
				and current.tradeId == working.tradeId
				and current.state ~= "Incoming"
				and current.state ~= "Sold"
				and current.atBay ~= true
			then
				DealerCar.spawn(player, record, false, "working", workingIndex)
			end
		end
	end
end

local function setupPlayer(record: Record, player: Player)
	local data = DataService.get(player)
	if data == nil or configuredFor[player] == record then
		return
	end
	configuredFor[player] = record
	GameplayEvents.emit("SessionStarted", player, {
		device = player:GetAttribute("DeviceClass") or "unknown",
		tutorialDealIndex = data.tutorial.dealIndex,
		cashAfter = data.cash,
	})
	grantFreeStarterPads(player)
	PadService.refresh(record)
	StaffDirector.refresh(record)
	TradeService.ensureIncomingQueue(player, record)

	restoreDisplaySlots(record, player)
	restoreWorkingSlots(record, player)

	TradeService.refreshListPrompt(player, record)
	DealerCar.publish(player)
	LotAutomation.step(player)
	LotAutomation.stepDisplay(player)
end

local function setupWhenClaimed(player: Player)
	local deadline = os.clock() + 15
	while player.Parent ~= nil and os.clock() < deadline do
		local record = TycoonService.getForPlayer(player)
		if record ~= nil then
			setupPlayer(record, player)
			return
		end
		task.wait(0.1)
	end
end

local function forget(player: Player)
	remoteLastAt[player] = nil
	configuredFor[player] = nil
	DealerCar.forget(player)
	TradeService.forget(player)
	LotAutomation.forget(player)
end

local function refreshWorkingStock(player: Player, record: Record)
	local capacity = math.min(DealerCar.workingCapacity(player), DealerCarConfig.MAX_WORKING_SLOTS)
	for workingIndex = 1, capacity do
		if DealerCar.active(player, workingIndex) ~= nil and not DealerCar.isArriving(player, workingIndex) then
			DealerCar.refresh(player, record, "working", workingIndex)
		end
	end
end

function JunkLotService.init()
	TradeService.init()
	TowTruckService.init()
	LotAutomation.init()

	-- FIFO promotion is event-driven: the instant a working car leaves for Used Cars,
	-- reserve that exact free W and move Q1 in. The periodic queue pump remains only as
	-- recovery, never as the normal delay between an empty pad and its waiting seller.
	DealerCar.stateChanged.Event:Connect(function(
		player: Player,
		state: string,
		slot: string,
		slotIndex: number
	)
		if slot ~= "working" or state ~= "None" then
			return
		end
		task.defer(function()
			local record = TycoonService.getForPlayer(player)
			if record ~= nil and DealerCar.active(player, slotIndex) == nil then
				sourceEmptyWorking(record, player, slotIndex)
			end
		end)
	end)

	TycoonService.tycoonClaimed.Event:Connect(function(record: Record, player: Player)
		setupPlayer(record, player)
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: Record)
		TradeService.releaseIncomingQueue(record)
		local folder = record.folder:FindFirstChild(DealerCarConfig.FOLDER_NAME)
		if folder ~= nil then
			folder:ClearAllChildren()
		end
		StaffDirector.release(record)
		TradeService.disableListPrompt(record)
	end)
	TycoonService.padPurchased.Event:Connect(function(
		record: Record,
		definition: TycoonConfig.PadDefinition,
		player: Player
	)
		if player == nil or record == nil then
			return
		end
		local cashAfter = TycoonService.getCash(player)
		local payload = {
			padId = definition.id,
			cost = definition.cost,
			cashBefore = cashAfter + definition.cost,
			cashAfter = cashAfter,
		}
		GameplayEvents.emit("PadPurchased", player, payload)
		if definition.id == "FirstMechanic" then
			GameplayEvents.emit("MechanicHired", player, payload)
		elseif definition.id == "FirstSalesman" then
			GameplayEvents.emit("SalesmanHired", player, payload)
		elseif definition.id == "OpenRepairBay" then
			GameplayEvents.emit("RepairBayOpened", player, payload)
		end

		-- Repair/listing/value purchases can change every W model independently.
		if definition.id == TycoonConfig.LISTING_PAD_ID
			or definition.kind == "repair"
			or definition.kind == "value"
		then
			refreshWorkingStock(player, record)
		end

		TradeService.refreshListPrompt(player, record)
		StaffDirector.refresh(record)
		if definition.id == "FirstMechanic" or definition.id == "FirstSalesman" then
			StaffDirector.beginHireArrival(record, definition.id)
		end
		TradeService.channelChanged(player, record)

		-- RepairPad2 unlocks the independent second working/repair lane. Parking2 only
		-- unlocks P2, so it must never source a W2 car.
		if definition.id == "RepairPad2" and DealerCar.workingCapacity(player) >= 2 then
			sourceEmptyWorking(record, player, 2)
		end
		DealerCar.publish(player)
	end)

	-- Manual ProximityPrompts and the server mechanic own repair calls. Legacy ListCar only
	-- refreshes prompts; an exact Ready W -> free P commit must come through transport.
	Remotes.ListCar.OnServerEvent:Connect(function(player: Player)
		if not remoteAllowed(player, "ListCar") then
			return
		end
		local record = TycoonService.getForPlayer(player)
		if record ~= nil then
			TradeService.refreshListPrompt(player, record)
		end
	end)
	Remotes.OfferAction.OnServerEvent:Connect(function(player: Player, action: unknown, tradeId: unknown)
		if not remoteAllowed(player, "OfferAction")
			or typeof(action) ~= "string"
			or not table.find({ "accept", "askmore", "refuse" }, action)
			or (tradeId ~= nil and not validTradeId(tradeId))
		then
			return
		end
		TradeService.handleSell(player, action, if typeof(tradeId) == "string" then tradeId else nil)
	end)
	Remotes.BuyAction.OnServerEvent:Connect(function(
		player: Player,
		action: unknown,
		tradeId: unknown,
		workingIndex: unknown
	)
		local validAction = false
		if typeof(action) == "string" then
			validAction = table.find({ "buy", "haggle", "refuse" }, action) ~= nil
			local pickedIndex = string.match(action, "^pick(%d+)$")
			if pickedIndex ~= nil then
				local numericIndex = tonumber(pickedIndex)
				validAction = numericIndex ~= nil
					and numericIndex >= 1
					and numericIndex <= DealerCarConfig.FENCE_OFFER_COUNT
			end
		end
		if not remoteAllowed(player, "BuyAction") or not validAction then
			return
		end
		if tradeId ~= nil and not validTradeId(tradeId) then
			return
		end

		local resolvedTradeId: string? = if typeof(tradeId) == "string" then tradeId else nil
		local resolvedWorkingIndex: number? = nil
		if workingIndex ~= nil then
			if typeof(workingIndex) ~= "number"
				or workingIndex ~= workingIndex
				or workingIndex % 1 ~= 0
				or workingIndex < 1
				or workingIndex > DealerCarConfig.MAX_WORKING_SLOTS
				or workingIndex > DealerCar.workingCapacity(player)
			then
				return
			end
			resolvedWorkingIndex = workingIndex
		end

		-- A world seller action is always an exact pair; fence actions intentionally carry neither.
		if (resolvedTradeId == nil) ~= (resolvedWorkingIndex == nil) then
			return
		end
		if resolvedTradeId ~= nil and resolvedTradeId == "" then
			return
		end
		TradeService.handleBuy(player, action, resolvedTradeId, resolvedWorkingIndex)
	end)

	-- The client asks once listeners are live. Rebuild every unlocked P and W independently.
	Remotes.RequestCarState.OnServerEvent:Connect(function(player: Player)
		if not remoteAllowed(player, "RequestCarState") then
			return
		end
		local record = TycoonService.getForPlayer(player)
		if record == nil then
			return
		end
		local displayCapacity = math.min(
			DealerCar.displayCapacity(player),
			DealerCarConfig.MAX_DISPLAY_SLOTS
		)
		for displayIndex = 1, displayCapacity do
			local display = DealerCar.display(player, displayIndex)
			if display ~= nil
				and display.state ~= "Sold"
				and DealerCar.displayModel(player, displayIndex) == nil
			then
				DealerCar.spawn(player, record, false, "display", displayIndex)
			end
		end

		local workingCapacity = math.min(
			DealerCar.workingCapacity(player),
			DealerCarConfig.MAX_WORKING_SLOTS
		)
		for workingIndex = 1, workingCapacity do
			local working = DealerCar.active(player, workingIndex)
			if working ~= nil
				and working.state ~= "Sold"
				and working.atBay ~= true
				and DealerCar.model(player, "working", workingIndex) == nil
			then
				DealerCar.spawn(
					player,
					record,
					working.state == "Incoming",
					"working",
					workingIndex
				)
			end
		end
		TradeService.refreshListPrompt(player, record)
		DealerCar.publish(player)
		TradeService.resendOpenCard(player)
	end)

	Players.PlayerRemoving:Connect(forget)

	for _, player in Players:GetPlayers() do
		task.spawn(setupWhenClaimed, player)
	end

	print("[JunkLot] online")
end

return JunkLotService

