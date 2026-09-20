--!strict

-- Both halves of the flip. Before FirstSalesman, buying uses one channel per deal:
-- either a live driveway seller or a phone-fence list, never both for the same car.
-- Hiring FirstSalesman retires phone sourcing entirely and leaves only the physical queue.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local WorldUI = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("WorldUI")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TownsfolkConfig = require(ReplicatedStorage.TownsfolkConfig)
local LuckConfig = require(ReplicatedStorage.LuckConfig)
local DataService = require(script.Parent.Parent.DataService)
local TycoonService = require(script.Parent.Parent.TycoonService)
local GameplayEvents = require(script.Parent.Parent.GameplayEvents)
local TradeContract = require(script.Parent.Parent.TradeContract)
local LotSlots = require(script.Parent.LotSlots)
local IncomingSellerQueue = require(script.Parent.IncomingSellerQueue)
local CarVisuals = require(script.Parent.CarVisuals)
local LotNpc = require(script.Parent.LotNpc)
local DealerCar = require(script.Parent.DealerCar)
local ListingTransport = require(script.Parent.ListingTransport)
local StaffDirector = require(script.Parent.StaffDirector)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord
type ActiveCarSave = DataService.ActiveCarSave

export type FenceOffer = {
	templateId: string,
	ask: number,
	pitch: string,
	haggleUsed: boolean,
	paintHue: number?,
	bodyKit: boolean?,
	neonColorId: string?,
}

local TradeService = {}

local ASK_MORE_REFUSAL = "nope, that's my price"
local CUSTOMER_PURCHASE_CELEBRATION_TIME = 5.1
local SELLER_REMINDER_DELAY = 30

-- Fires (player) whenever the fence list changes, so automation can shop without polling.
TradeService.offersChanged = Instance.new("BindableEvent")

local sellers: { [Player]: Model } = {}
-- Exactly one source/seller session is serialized, but it may target either W1 or W2.
local sellerWorkingIndex: { [Player]: number } = {}
local sellerTradeId: { [Player]: string } = {}
local fenceTradeId: { [Player]: string } = {}
local fenceWorkingIndex: { [Player]: number } = {}
local sourcePending: { [Player]: boolean } = {}
local reservedWorking: { [Player]: number } = {}
local listPrompts: { [Record]: ProximityPrompt } = {}
local patienceToken: { [Player]: number } = {}
local incomingToken: { [Player]: number } = {}
local offers: { [Player]: { FenceOffer } } = {}
local picked: { [Player]: number } = {}
local lastNote: { [Player]: string } = {}
local playerCoveredDeal: { [Player]: boolean } = {}
local buyers: { [Player]: { [number]: Model } } = {}
local buyerToken: { [Player]: { [number]: number } } = {}
local buyerTradeId: { [Player]: { [number]: string } } = {}
local buyerLaneStartedAt: { [Player]: { [number]: number } } = {}
local buyerCursor: { [Player]: number } = {}
local buyerWatchdogStarted = false
local BUYER_LANE_STALL_TIMEOUT = math.max(30, DealerCarConfig.OFFER_DELAY_MAX + 15)

local function rollIncomingVariant(data: DataService.SaveData, template: DealerCarConfig.CarTemplate): LuckConfig.IncomingVariant
	local odds = DealerCarConfig.arrivalOdds(template.id, data.pads, data.luck)
	local rarity = DealerCarConfig.rarityTier(odds.oneInN)
	return LuckConfig.rollIncomingVariant(rarity.id, data.luck)
end

local function savedVariant(source: any): LuckConfig.IncomingVariant
	local modCount = 0
	if source.paintHue ~= nil then modCount += 1 end
	if source.bodyKit == true then modCount += 1 end
	if source.neonColorId ~= nil then modCount += 1 end
	return {
		paintHue = source.paintHue,
		bodyKit = source.bodyKit == true or source.neonColorId ~= nil,
		neonColorId = source.neonColorId,
		modCount = modCount,
		askMultiplier = 1,
	}
end

local function savedCondition(source: any): DataService.VehicleConditionSave
	return {
		dirty = source.dirty == true,
		oilLeak = source.oilLeak == true,
		wheelsPresent = source.wheelsPresent ~= false,
		missingWheels = if typeof(source.missingWheels) == "table" then table.clone(source.missingWheels) else nil,
		towStock = source.source == "tow" or source.towStock == true,
	}
end

local function variantLabel(source: any): string
	local labels = {}
	if source.paintHue ~= nil then table.insert(labels, "CUSTOM PAINT") end
	if source.bodyKit == true or source.neonColorId ~= nil then table.insert(labels, "BODY KIT + TINT") end
	if source.neonColorId ~= nil then table.insert(labels, "NEON") end
	return table.concat(labels, " · ")
end

local function playerLuck(player: Player): number
	local data = DataService.get(player)
	return if data ~= nil then data.luck else LuckConfig.DEFAULT
end

local function buyerRig(player: Player, displayIndex: number): Model?
	local map = buyers[player]
	return if map ~= nil then map[displayIndex] else nil
end

local function setBuyerRig(player: Player, displayIndex: number, rig: Model?)
	local map = buyers[player]
	if map == nil and rig ~= nil then
		map = {}
		buyers[player] = map
	end
	if map ~= nil then
		map[displayIndex] = rig
		if rig == nil and next(map) == nil then buyers[player] = nil end
	end
end

local function laneTrade(player: Player, displayIndex: number): string?
	local map = buyerTradeId[player]
	return if map ~= nil then map[displayIndex] else nil
end

local function laneToken(player: Player, displayIndex: number): number?
	local map = buyerToken[player]
	return if map ~= nil then map[displayIndex] else nil
end
local queuePumpGeneration: { [Player]: number } = {}
local queuePumpRunning: { [Player]: boolean } = {}
local queueSerial: { [Player]: number } = {}
local queueNextAt: { [Player]: number } = {}
local queueRecord: { [Player]: Record } = {}

local function sameRecord(a: Record?, b: Record?): boolean
	return a ~= nil and b ~= nil and a.folder == b.folder
end

local BUYER_ARRIVAL_LINES = {
	"Whoa, this %s looks even better up close.",
	"Now that's a %s I could see myself driving.",
	"Okay... this %s has serious character.",
	"That %s has seen things. I kind of love it.",
	"Not bad at all. Let me look at this %s.",
	"This %s looks ready for another life.",
	"I wasn't planning to buy a %s today...",
	"A %s? Oh, now we're talking.",
	"This %s would look great in my driveway.",
	"I bet this %s has some stories.",
	"Clean wheels, solid stance... nice %s.",
	"You fixed this %s up pretty well.",
	"I can already picture myself driving this %s.",
	"Honestly? This %s is cooler than I expected.",
	"That %s better sound as good as it looks.",
	"This %s definitely caught my eye.",
	"Hmm... I might have to offer on this %s.",
	"A %s at a junk lot? That's tempting.",
	"This %s has exactly the weird charm I like.",
	"All right, this %s has my attention.",
}

local BUYER_DECLINE_LINES = {
	"Eh, I didn't need it that badly.",
	"Guess I'll find something else.",
	"No deal? All right, your loss.",
	"I'll keep shopping.",
	"Fine, I'll take my cash somewhere else.",
	"Maybe the next lot wants my money.",
	"Not today, then.",
	"I liked it... just not that much.",
	"All right, I'll walk.",
	"Call me when you're feeling generous.",
}

local BUYER_SUCCESS_LINES = {
	"Deal! Thanks, this is awesome!",
	"Yes! I can't wait to drive it!",
	"Perfect. It's coming home with me.",
	"Thanks! This made my day.",
	"Great deal. Let's get rolling!",
	"Awesome, I love it already.",
	"Sold! Hand me the keys.",
	"That's mine now? Best day ever!",
	"Thanks! I'll take good care of it.",
	"Finally, a car with personality!",
}

local function randomLine(lines: { string }): string
	return lines[math.random(1, #lines)]
end

local function clearBuyer(player: Player, displayIndex: number?)
	if displayIndex ~= nil then
		local rig = buyerRig(player, displayIndex)
		setBuyerRig(player, displayIndex, nil)
		if rig ~= nil then LotNpc.destroy(rig) end
		return
	end
	local map = buyers[player]
	buyers[player] = nil
	if map ~= nil then
		for _, rig in pairs(map) do LotNpc.destroy(rig) end
	end
end

local function takeBuyer(player: Player, displayIndex: number): Model?
	local rig = buyerRig(player, displayIndex)
	setBuyerRig(player, displayIndex, nil)
	return rig
end

local function claimBuyerLane(player: Player, car: ActiveCarSave, displayIndex: number): number
	local tokens = buyerToken[player] or {}
	buyerToken[player] = tokens
	tokens[displayIndex] = (tokens[displayIndex] or 0) + 1
	local trades = buyerTradeId[player] or {}
	buyerTradeId[player] = trades
	trades[displayIndex] = car.tradeId
	local started = buyerLaneStartedAt[player] or {}
	buyerLaneStartedAt[player] = started
	started[displayIndex] = workspace:GetServerTimeNow()
	buyerCursor[player] = displayIndex
	return tokens[displayIndex]
end

local function releaseBuyerLane(player: Player, tradeId: string?, displayIndex: number?): boolean
	local resolvedIndex = displayIndex
	local trades = buyerTradeId[player]
	if resolvedIndex == nil and tradeId ~= nil and trades ~= nil then
		for index, activeTradeId in pairs(trades) do
			if activeTradeId == tradeId then resolvedIndex = index break end
		end
	end
	if resolvedIndex == nil then return false end
	local activeTradeId = if trades ~= nil then trades[resolvedIndex] else nil
	if tradeId ~= nil and activeTradeId ~= tradeId then return false end
	local tokens = buyerToken[player] or {}
	buyerToken[player] = tokens
	tokens[resolvedIndex] = (tokens[resolvedIndex] or 0) + 1
	if trades ~= nil then
		trades[resolvedIndex] = nil
		if next(trades) == nil then buyerTradeId[player] = nil end
	end
	local started = buyerLaneStartedAt[player]
	if started ~= nil then
		started[resolvedIndex] = nil
		if next(started) == nil then buyerLaneStartedAt[player] = nil end
	end
	return true
end

local function buyerStillValid(
	player: Player,
	car: ActiveCarSave,
	displayIndex: number,
	token: number
): boolean
	local current = DealerCar.display(player, displayIndex)
	return laneToken(player, displayIndex) == token
		and laneTrade(player, displayIndex) == car.tradeId
		and current ~= nil
		and current.tradeId == car.tradeId
		and current.state == "Listed"
end

local function buyerRoute(record: Record, model: Model, displayIndex: number): (Vector3, Vector3, { Vector3 })
	local sale = LotSlots.saleCFrame(record, displayIndex)
	local targetRaw = (sale * CFrame.new(-6.5, 0, 1.5)).Position
	local gate = LotSlots.usedLotEntrance(record)
	local startRaw = if gate ~= nil then gate.Position else targetRaw - sale.LookVector * 18
	local ignore: { Instance } = { model }
	local start = Vector3.new(startRaw.X, LotNpc.groundY(startRaw, ignore), startRaw.Z)
	local target = Vector3.new(targetRaw.X, LotNpc.groundY(targetRaw, ignore), targetRaw.Z)
	local span = target - start
	local distance = math.max(0.1, span.Magnitude)
	local steps = math.max(2, math.ceil(distance / 2.5))
	return start, target, LotNpc.walkPoints(start, span, steps, distance / steps, ignore)
end

local function spawnBuyerAtCar(
	player: Player,
	record: Record,
	car: ActiveCarSave,
	displayIndex: number,
	token: number
): Model?
	clearBuyer(player, displayIndex)
	local model = DealerCar.displayModel(player, displayIndex)
	if model == nil or not buyerStillValid(player, car, displayIndex, token) then
		return nil
	end
	local breakdown = DealerCar.valueBreakdown(player, car)
	local data = DataService.get(player)
	local person = TownsfolkConfig.get(car.customerId)
		or TownsfolkConfig.pickBuyer(breakdown.listedPrice, if data ~= nil then data.luck else nil)
	car.customerId = person.id
	local start, target, points = buyerRoute(record, model, displayIndex)
	local rig = LotNpc.spawnBuyer(person.name, LotSlots.carFolder(record), start, target - start, person.id)
	if rig == nil then
		return nil
	end
	rig:SetAttribute("DealerBuyerOwnerUserId", player.UserId)
	rig:SetAttribute("DealerBuyerTradeId", car.tradeId)
	rig:SetAttribute("DealerBuyerDisplayIndex", displayIndex)
	rig:SetAttribute("TutorialDealIndex", car.tutorialDealIndex)
	setBuyerRig(player, displayIndex, rig)
	local walked = LotNpc.walk(rig, points, DealerCarConfig.STAFF_WALK_SPEED or 11, function()
		return rig.Parent ~= nil and buyerStillValid(player, car, displayIndex, token)
	end)
	if not walked or not buyerStillValid(player, car, displayIndex, token) or rig.Parent == nil then
		if buyerRig(player, displayIndex) == rig then
			setBuyerRig(player, displayIndex, nil)
		end
		LotNpc.destroy(rig)
		return nil
	end
	LotNpc.place(rig, target, model:GetPivot().Position - target)
	LotNpc.play(rig, "idle")
	return rig
end

local function sayBuyer(player: Player, rig: Model, text: string)
	local adornee = rig:FindFirstChild("Head", true) or rig:FindFirstChildWhichIsA("BasePart", true)
	if adornee ~= nil then
		Remotes.ListingNotice:FireClient(player, {
			mode = "bubble",
			adornee = adornee,
			text = text,
		})
	end
end

local function buyerBubble(player: Player, rig: Model, carName: string)
	sayBuyer(player, rig, randomLine(BUYER_ARRIVAL_LINES):format(carName))
end

local function sendBuyerAway(player: Player, record: Record, displayIndex: number)
	local rig = takeBuyer(player, displayIndex)
	if rig == nil or rig.Parent == nil then
		return
	end
	task.spawn(function()
		local gate = LotSlots.usedLotEntrance(record)
		if gate ~= nil and rig.Parent ~= nil then
			local from = rig:GetPivot().Position - Vector3.new(0, LotNpc.rootHeight(rig), 0)
			local raw = gate.Position
			local ignore: { Instance } = { rig }
			local target = Vector3.new(raw.X, LotNpc.groundY(raw, ignore), raw.Z)
			local span = target - from
			local distance = math.max(0.1, span.Magnitude)
			local steps = math.max(2, math.ceil(distance / 2.5))
			LotNpc.walk(rig, LotNpc.walkPoints(from, span, steps, distance / steps, ignore), DealerCarConfig.STAFF_WALK_SPEED or 11)
		end
		LotNpc.destroy(rig)
	end)
end

-- Every deal is with a named townsperson now, so the wealth chip the player reads on the
-- card is the same record the offer maths is driven from.
local function servedCount(player: Player, id: string?): number
	local data = DataService.get(player)
	if data == nil or id == nil then
		return 0
	end
	return data.served[id] or 0
end

local function recordDeal(player: Player, id: string?)
	local data = DataService.get(player)
	if data == nil or id == nil then
		return
	end
	data.served[id] = (data.served[id] or 0) + 1
end

-- Channels --------------------------------------------------------------------

local function usePhone(player: Player): boolean
	-- Phone sourcing is the manual early-game channel. Once FirstSalesman is hired,
	-- all new stock must arrive through his physical world queue instead.
	return DealerCar.hasPad(player, DealerCarConfig.PHONE_TRADE_PAD)
		and not DealerCar.hasPad(player, DealerCarConfig.AUTO_ACCEPT_PAD)
end

local function listingAutomated(player: Player): boolean
	return DealerCar.hasPad(player, DealerCarConfig.AUTO_LIST_PAD)
end

local function buyerAutomated(player: Player): boolean
	local data = DataService.get(player)
	return DealerCar.hasPad(player, DealerCarConfig.AUTO_ACCEPT_PAD)
		and data ~= nil
		and data.tutorial.completed == true
end

local function clearFenceSession(player: Player)
	offers[player] = nil
	picked[player] = nil
	fenceTradeId[player] = nil
	fenceWorkingIndex[player] = nil
	lastNote[player] = nil
end

local function sourceSessionBusy(player: Player): boolean
	if sellerTradeId[player] ~= nil or fenceTradeId[player] ~= nil or offers[player] ~= nil then
		return true
	end
	for index = 1, DealerCar.workingCapacity(player) do
		local car = DealerCar.active(player, index)
		if car ~= nil and (car.state == "Incoming" or car.state == "Offered") then
			return true
		end
	end
	return false
end

local function sourceBusy(player: Player): boolean
	return sourcePending[player] == true or sourceSessionBusy(player)
end

local function tutorialSourceActive(player: Player): boolean
	local data = DataService.get(player)
	local tutorial = data and data.tutorial
	return tutorial ~= nil and tutorial.eligible == true and tutorial.completed ~= true
end

local function waitingQueueUnlocked(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.pads.FirstSalesman == true
end

local HELPER_PAD_IDS = { "ServiceHelper", "ServiceHelper2", "ServiceHelper3" }

local function incomingThroughput(player: Player): number
	local data: any = DataService.get(player)
	if data == nil then return 1 end
	local pads = data.pads or {}
	local laneCapacity = math.max(1, math.min(
		DealerCar.workingCapacity(player),
		DealerCar.displayCapacity(player)
	))
	local mechanicCount = (if pads.FirstMechanic == true then 1 else 0)
		+ (if pads.SecondMechanic == true then 1 else 0)
	local helperCount = 0
	for _, padId in HELPER_PAD_IDS do
		if pads[padId] == true then helperCount += 1 end
	end
	-- Only owned W/P lanes and staff who can actually move work increase deal cadence.
	return math.clamp(1 + (laneCapacity - 1) * 0.35 + mechanicCount * 0.12 + helperCount * 0.1, 1, 2.25)
end

local function randomSourceGap(player: Player): number
	local base = DealerCarConfig.SELLER_GAP_MIN
		+ math.random() * (DealerCarConfig.SELLER_GAP_MAX - DealerCarConfig.SELLER_GAP_MIN)
	return base / incomingThroughput(player)
end

local function helperUsedByService(player: Player, record: Record, helperId: string): boolean
	for _, car in DealerCar.processingCars(player) do
		local pipeline = (car :: any).pipeline
		if type(pipeline) == "table"
			and (pipeline.state == "queued" or pipeline.state == "servicing")
			and pipeline.escortId == helperId
		then
			return true
		end
	end
	for _, rootName in { "ServiceSlots", "ServiceParkingJourneys" } do
		local root = record.folder:FindFirstChild(rootName)
		if root ~= nil then
			for _, slot in root:GetChildren() do
				if slot:GetAttribute("ServiceEscortId") == helperId then return true end
			end
		end
	end
	local rig = record.folder:FindFirstChild(helperId, true)
	return rig ~= nil and rig:IsA("Model") and rig:GetAttribute("StaffJob") ~= nil
end

local function reserveListingHelper(player: Player, record: Record, tradeId: string): string?
	for _, helperId in HELPER_PAD_IDS do
		local attribute = "HelperListingTrade_" .. helperId
		if DealerCar.hasPad(player, helperId)
			and record.folder:GetAttribute(attribute) == nil
			and not helperUsedByService(player, record, helperId)
		then
			record.folder:SetAttribute(attribute, tradeId)
			if record.folder:GetAttribute(attribute) == tradeId then return helperId end
		end
	end
	return nil
end

local function releaseListingHelper(record: Record, helperId: string?, tradeId: string)
	if helperId == nil then return end
	local attribute = "HelperListingTrade_" .. helperId
	if record.folder:GetAttribute(attribute) == tradeId then
		record.folder:SetAttribute(attribute, nil)
	end
end

local function stopQueuePump(player: Player)
	queuePumpGeneration[player] = (queuePumpGeneration[player] or 0) + 1
	queuePumpRunning[player] = nil
end

local function ensureQueuePump(player: Player)
	if queuePumpRunning[player] == true then
		return
	end
	queuePumpGeneration[player] = (queuePumpGeneration[player] or 0) + 1
	local generation = queuePumpGeneration[player]
	queuePumpRunning[player] = true
	task.spawn(function()
		while player.Parent ~= nil
			and queuePumpRunning[player] == true
			and queuePumpGeneration[player] == generation
		do
			-- A fresh tutorial source can lose its first one-shot request to startup ordering.
			-- Retry that deterministic delivery quickly; the normal post-tutorial queue keeps
			-- its authored 7-14 second cadence and startIncoming still prevents queue prefill.
			local tutorialRetry = tutorialSourceActive(player)
			task.wait(if tutorialRetry then 1 else randomSourceGap(player))
			if player.Parent == nil
				or queuePumpRunning[player] ~= true
				or queuePumpGeneration[player] ~= generation
			then
				break
			end
			local record = TycoonService.getForPlayer(player)
			if record == nil
				or not sameRecord(queueRecord[player], record)
				or sourceBusy(player)
			then
				continue
			end
			local canPromote = DealerCar.availableWorkingIndex(player) ~= nil
			local canWait = waitingQueueUnlocked(player)
				and IncomingSellerQueue.canEnqueue(player)
			if canPromote or canWait then
				TradeService.startIncoming(player, record, 0)
			end
		end
		if queuePumpGeneration[player] == generation then
			queuePumpRunning[player] = nil
		end
	end)
end

local function enqueueWaitingSeller(player: Player, record: Record): boolean
	if (queueNextAt[player] or 0) > os.clock() then
		return false
	end
	if tutorialSourceActive(player)
		or not waitingQueueUnlocked(player)
		or DealerCar.availableWorkingIndex(player) ~= nil
		or not IncomingSellerQueue.canEnqueue(player)
	then
		return false
	end
	for workingIndex = 1, DealerCar.workingCapacity(player) do
		if DealerCar.active(player, workingIndex) == nil then
			return false
		end
	end
	local data = DataService.get(player)
	if data == nil then
		return false
	end
	queueSerial[player] = (queueSerial[player] or 0) + 1
	local template = DealerCarConfig.selectArrival(data.pads, data.luck)
	local variant = rollIncomingVariant(data, template)
	local condition = DealerCar.rollIncomingCondition()
	local person = TownsfolkConfig.pickSeller()
	local queued = IncomingSellerQueue.enqueue(player, record, {
		queueId = HttpService:GenerateGUID(false),
		templateId = template.id,
		ask = math.max(1, math.floor(DealerCarConfig.askingPrice(template) * variant.askMultiplier)),
		sellerId = person.id,
		paintHue = variant.paintHue,
		bodyKit = variant.bodyKit,
		neonColorId = variant.neonColorId,
		dirty = condition.dirty,
		oilLeak = condition.oilLeak,
		wheelsPresent = condition.wheelsPresent,
	})
	if queued then
		queueNextAt[player] = os.clock() + randomSourceGap(player)
		print(("[JunkQueue] enqueued user=%d Q=%d car=%s"):format(
			player.UserId,
			IncomingSellerQueue.count(player),
			template.id
		))
	end
	return queued
end

-- A tow delivery is a normal paid offer, but it should not be followed by an immediate
-- ordinary source burst. Reuse the authored seller cadence and promote it immediately only
-- when a working pad is already free.
function TradeService.noteTowDelivery(player: Player, record: Record)
	if not sameRecord(queueRecord[player], record) then
		TradeService.ensureIncomingQueue(player, record)
	end
	queueNextAt[player] = os.clock() + randomSourceGap(player)
	if DealerCar.availableWorkingIndex(player) ~= nil then
		task.defer(function()
			local current = TycoonService.getForPlayer(player)
			if current ~= nil and sameRecord(current, record) then
				TradeService.startIncoming(player, record, 0)
			end
		end)
	end
end

function TradeService.ensureIncomingQueue(player: Player, record: Record)
	local previous = queueRecord[player]
	if previous ~= nil and not sameRecord(previous, record) then
		stopQueuePump(player)
		IncomingSellerQueue.clear(player)
	end
	queueRecord[player] = record
	IncomingSellerQueue.ensure(player, record)
	ensureQueuePump(player)
end

function TradeService.releaseIncomingQueue(record: Record)
	local released: { Player } = {}
	for player, queuedRecord in queueRecord do
		if sameRecord(queuedRecord, record) then
			table.insert(released, player)
		end
	end
	for _, player in released do
		stopQueuePump(player)
		IncomingSellerQueue.clear(player)
		queueRecord[player] = nil
		queueSerial[player] = nil
		queueNextAt[player] = nil
	end
	IncomingSellerQueue.release(record)
end

TradeService.usesPhone = usePhone
-- Compatibility: automation now means Ready-car listing only.
TradeService.isAutomated = listingAutomated
TradeService.isListingAutomated = listingAutomated
TradeService.isBuyerAutomated = buyerAutomated

local function fencePerson(player: Player): TownsfolkConfig.Person
	return TownsfolkConfig.pickFence(player.UserId)
end

-- A car saved before the cast existed has no seller on record; give it one rather than
-- letting the chip fall back to a class the person does not actually have.
local function sellerPerson(car: ActiveCarSave): TownsfolkConfig.Person?
	if car.sellerId == nil then
		car.sellerId = TownsfolkConfig.pickSeller().id
	end
	return TownsfolkConfig.get(car.sellerId)
end

local function fenceName(player: Player): string
	return fencePerson(player).name
end

local function sellerName(car: ActiveCarSave): string
	local person = sellerPerson(car)
	return if person ~= nil then person.name else "Seller"
end

-- Feedback --------------------------------------------------------------------

local function anchorPosition(
	player: Player,
	record: Record,
	slot: DealerCar.CarSlot?,
	slotIndex: number?
): Vector3
	local resolvedSlot: DealerCar.CarSlot = slot or "working"
	local model = DealerCar.model(player, resolvedSlot, slotIndex)
	if model ~= nil then
		local box, size = model:GetBoundingBox()
		return box.Position + Vector3.new(0, size.Y * 0.5 + 1.5, 0)
	end
	local fallback = if resolvedSlot == "display"
		then LotSlots.saleCFrame(record, slotIndex)
		else LotSlots.parkedCFrame(record, slotIndex)
	return fallback.Position + Vector3.new(0, 4, 0)
end

local function popCash(
	player: Player,
	record: Record,
	amount: number,
	slot: DealerCar.CarSlot?,
	slotIndex: number?
)
	Remotes.CashPopup:FireClient(player, {
		amount = amount,
		position = anchorPosition(player, record, slot, slotIndex),
	})
end

TradeService.popCash = popCash

local function hideBuyCard(player: Player, car: ActiveCarSave?, workingIndex: number?)
	lastNote[player] = nil
	local resolvedIndex = workingIndex
		or (if car ~= nil then DealerCar.workingIndexForTrade(player, car.tradeId) else nil)
		or sellerWorkingIndex[player]
		or fenceWorkingIndex[player]
	local resolvedTradeId = if car ~= nil then car.tradeId
		else sellerTradeId[player] or fenceTradeId[player]
	Remotes.BuyUpdate:FireClient(player, {
		visible = false,
		slot = "working",
		slotIndex = resolvedIndex,
		workingIndex = resolvedIndex,
		tradeId = resolvedTradeId,
	})
end

local function activeBuyerDisplay(player: Player): (ActiveCarSave?, number?)
	-- UI compatibility chooses one visible offer, but physical/timer authority remains per P.
	for index = 1, DealerCar.displayCapacity(player) do
		local car = DealerCar.display(player, index)
		if car ~= nil and car.state == "Offer" and car.tradeId ~= "" then
			return car, index
		end
	end
	local trades = buyerTradeId[player]
	if trades ~= nil then
		for index, tradeId in pairs(trades) do
			local car = DealerCar.display(player, index)
			if car ~= nil and car.tradeId == tradeId then return car, index end
		end
	end
	return nil, nil
end

local function hideSellCard(player: Player, car: ActiveCarSave?, displayIndex: number?)
	local targetCar = car
	local targetIndex = displayIndex
	if targetCar ~= nil and targetIndex == nil then
		targetIndex = DealerCar.displayIndexForTrade(player, targetCar.tradeId)
	elseif targetCar == nil then
		targetCar, targetIndex = activeBuyerDisplay(player)
	end
	if targetCar == nil or targetIndex == nil or targetCar.tradeId == "" then
		return
	end
	Remotes.OfferUpdate:FireClient(player, {
		visible = false,
		slot = "display",
		slotIndex = targetIndex,
		tradeId = targetCar.tradeId,
	})
end

local function sendBuyCard(
	player: Player,
	car: ActiveCarSave,
	channel: string,
	note: string?,
	workingIndex: number?
)
	-- FirstSalesman owns live incoming deals. Suppress the visible packet at its only
	-- source so UI restore, prompt races, and delayed seller replies cannot flash a card
	-- that automation is about to close.
	if channel == "world"
		and listingAutomated(player)
		and playerCoveredDeal[player] ~= true
	then
		hideBuyCard(player, car, workingIndex)
		return
	end
	local resolvedIndex = workingIndex or DealerCar.workingIndexForTrade(player, car.tradeId)
	if resolvedIndex == nil
		or DealerCar.active(player, resolvedIndex) ~= car
		or sellerTradeId[player] ~= car.tradeId
	then
		return
	end
	-- Repeating the same line every time a button is pressed reads as a broken NPC.
	local fresh = note
	if note ~= nil and lastNote[player] == note then
		fresh = nil
	end
	if note ~= nil then
		lastNote[player] = note
	end
	local person = if channel == "fence" then fencePerson(player) else sellerPerson(car)
	local data = DataService.get(player)
	local odds = DealerCarConfig.arrivalOdds(car.templateId, DealerCar.pads(player), if data ~= nil then data.luck else nil)
	local oneInN = if odds.probability > 0
		then odds.oneInN
		else select(1, DealerCarConfig.rarityOf(car.templateId))
	local rarity = DealerCarConfig.rarityTier(oneInN)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local currentValue = DealerCar.value(player, car)
	Remotes.BuyUpdate:FireClient(player, {
		visible = true,
		slot = "working",
		slotIndex = resolvedIndex,
		workingIndex = resolvedIndex,
		tradeId = car.tradeId,
		channel = channel,
		ask = car.ask,
		carName = DealerCarConfig.displayName(car.templateId),
		sellerName = if person ~= nil then person.name else "Seller",
		personId = if person ~= nil then person.id else nil,
		served = servedCount(player, if person ~= nil then person.id else nil),
		rarityOneInN = oneInN,
		rarityTier = rarity.id,
		arrivalTier = odds.tier,
		arrivalClassWeight = odds.classWeight,
		arrivalProbability = odds.probability,
		arrivalPercent = odds.percent,
		haggleUsed = car.haggleUsed,
		value = currentValue,
		currentValue = currentValue,
		valueAfterRepairs = DealerCar.valueAfterRepairs(player, car),
		tutorialDealIndex = car.tutorialDealIndex,
		tutorialWildcard = car.tutorialWildcard == true,
		tutorialBeat = if tutorialDeal ~= nil then tutorialDeal.beat else nil,
		diagnosis = if tutorialDeal ~= nil then tutorialDeal.diagnosis else nil,
		variantLabel = DealerCar.variantLabel(car),
		affordable = TycoonService.getCash(player) >= car.ask,
		note = fresh,
	})
end

local function sendFenceCard(player: Player, offer: FenceOffer, note: string?)
	local sessionTradeId = fenceTradeId[player]
	local workingIndex = fenceWorkingIndex[player]
	if sessionTradeId == nil or workingIndex == nil then
		return
	end
	local fresh = note
	if note ~= nil and lastNote[player] == note then
		fresh = nil
	end
	if note ~= nil then
		lastNote[player] = note
	end
	local template = CarVisuals.template(offer.templateId)
	local person = fencePerson(player)
	local odds = DealerCarConfig.arrivalOdds(offer.templateId, DealerCar.pads(player), playerLuck(player))
	local oneInN = if odds.probability > 0
		then odds.oneInN
		else select(1, DealerCarConfig.rarityOf(offer.templateId))
	local rarity = DealerCarConfig.rarityTier(oneInN)
	local fenceValueMultiplier = TycoonConfig.valueMultiplier(DealerCar.pads(player))
	-- A fence car is worth the deal price until the player actually restores it.
	local fenceCurrentValue = math.max(1, math.floor(offer.ask))
	local fenceRepairedValue = math.max(1, math.floor((template.baseValue
		+ DealerCarConfig.partValue("Body")
		+ DealerCarConfig.partValue("Wheels")
		+ DealerCarConfig.partValue("Engine")) * fenceValueMultiplier))
	Remotes.BuyUpdate:FireClient(player, {
		visible = true,
		slot = "working",
		slotIndex = workingIndex,
		workingIndex = workingIndex,
		tradeId = sessionTradeId,
		channel = "fence",
		ask = offer.ask,
		carName = DealerCarConfig.displayName(offer.templateId),
		pitch = offer.pitch,
		variantLabel = variantLabel(offer),
		sellerName = person.name,
		personId = person.id,
		served = servedCount(player, person.id),
		rarityOneInN = oneInN,
		rarityTier = rarity.id,
		arrivalTier = odds.tier,
		arrivalClassWeight = odds.classWeight,
		arrivalProbability = odds.probability,
		arrivalPercent = odds.percent,
		haggleUsed = offer.haggleUsed,
		value = fenceCurrentValue,
		currentValue = fenceCurrentValue,
		valueAfterRepairs = fenceRepairedValue,
		affordable = TycoonService.getCash(player) >= offer.ask,
		note = fresh,
	})
end

-- Fence list ------------------------------------------------------------------

local function buildOffers(player: Player): { FenceOffer }
	local data = DataService.get(player)
	local list: { FenceOffer } = {}
	for _ = 1, DealerCarConfig.FENCE_OFFER_COUNT do
		local template = DealerCarConfig.selectArrival(if data ~= nil then data.pads else nil, if data ~= nil then data.luck else nil)
		local variant = if data ~= nil then rollIncomingVariant(data, template) else LuckConfig.rollIncomingVariant("common", LuckConfig.DEFAULT)
		table.insert(list, {
			templateId = template.id,
			ask = math.max(1, math.floor(DealerCarConfig.askingPrice(template) * variant.askMultiplier)),
			pitch = DealerCarConfig.FENCE_PITCHES[math.random(1, #DealerCarConfig.FENCE_PITCHES)],
			-- A listing the player has never opened cannot have been haggled yet.
			haggleUsed = false,
			paintHue = variant.paintHue,
			bodyKit = variant.bodyKit,
			neonColorId = variant.neonColorId,
		})
	end
	if data ~= nil then
		data.carIndex += DealerCarConfig.FENCE_OFFER_COUNT
	end
	return list
end

local function sendOfferList(player: Player)
	local list = offers[player]
	local sessionTradeId = fenceTradeId[player]
	local workingIndex = fenceWorkingIndex[player]
	if list == nil or sessionTradeId == nil or workingIndex == nil then
		return
	end
	local payload = {}
	local cash = TycoonService.getCash(player)
	for _, offer in list do
		local odds = DealerCarConfig.arrivalOdds(offer.templateId, DealerCar.pads(player), playerLuck(player))
		local oneInN = if odds.probability > 0
			then odds.oneInN
			else select(1, DealerCarConfig.rarityOf(offer.templateId))
		local rarity = DealerCarConfig.rarityTier(oneInN)
		table.insert(payload, {
			carName = DealerCarConfig.displayName(offer.templateId),
			ask = offer.ask,
			pitch = offer.pitch,
			variantLabel = variantLabel(offer),
			rarityOneInN = oneInN,
			rarityTier = rarity.id,
			arrivalTier = odds.tier,
			arrivalClassWeight = odds.classWeight,
			arrivalProbability = odds.probability,
			arrivalPercent = odds.percent,
			affordable = cash >= offer.ask,
		})
	end
	local person = fencePerson(player)
	Remotes.BuyUpdate:FireClient(player, {
		visible = true,
		slot = "working",
		slotIndex = workingIndex,
		workingIndex = workingIndex,
		tradeId = sessionTradeId,
		channel = "fence",
		sellerName = person.name,
		personId = person.id,
		served = servedCount(player, person.id),
		offers = payload,
	})
end

function TradeService.openFence(player: Player, delay: number?)
	if not usePhone(player) or sourceBusy(player) then
		return
	end
	sourcePending[player] = true
	incomingToken[player] = (incomingToken[player] or 0) + 1
	local token = incomingToken[player]
	local function releasePending()
		if incomingToken[player] == token then
			sourcePending[player] = nil
		end
	end
	task.spawn(function()
		if delay ~= nil and delay > 0 then
			task.wait(delay)
		end
		local workingIndex = DealerCar.availableWorkingIndex(player)
		if incomingToken[player] ~= token
			or not usePhone(player)
			or workingIndex == nil
			or sourceSessionBusy(player)
		then
			releasePending()
			return
		end
		fenceTradeId[player] = TradeContract.newTradeId(player, "Fence")
		fenceWorkingIndex[player] = workingIndex
		offers[player] = buildOffers(player)
		picked[player] = nil
		lastNote[player] = nil
		sourcePending[player] = nil
		sendOfferList(player)
		TradeService.offersChanged:Fire(player)
	end)
end

function TradeService.offers(player: Player): { FenceOffer }?
	return offers[player]
end

-- Live seller -----------------------------------------------------------------

local function clearSeller(player: Player, clearSession: boolean?)
	LotNpc.destroy(sellers[player])
	sellers[player] = nil
	if clearSession ~= false then
		sellerWorkingIndex[player] = nil
		sellerTradeId[player] = nil
		playerCoveredDeal[player] = nil
	end
end

local function decorateSeller(
	player: Player,
	rig: Model,
	car: ActiveCarSave,
	workingIndex: number,
	interactive: boolean?
)
	local host = rig:FindFirstChild("HumanoidRootPart")
	if host == nil or not host:IsA("BasePart") then
		return
	end

	local billboard = WorldUI.SellerTag:Clone()
	billboard.MaxDistance = 60
	-- Seller identity, rarity odds and asking price are private business information.
	-- The client uses this owner id to suppress the tag on every other player's lot.
	billboard:SetAttribute("PrivateOwnerUserId", player.UserId)
	billboard.Parent = host
	local label = billboard:FindFirstChild("Label") :: TextLabel
	-- The wealth chip is legible from across the lot, before the player ever opens a deal.
	local person = sellerPerson(car)
	local info = TownsfolkConfig.classInfo(if person ~= nil then person.class else nil)
	local odds = DealerCarConfig.arrivalOdds(car.templateId, DealerCar.pads(player), playerLuck(player))
	local oneInN = if odds.probability > 0
		then odds.oneInN
		else select(1, DealerCarConfig.rarityOf(car.templateId))
	local rarity = DealerCarConfig.rarityTier(oneInN)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local rarityText = if tutorialDeal ~= nil and tutorialDeal.wildcard == true
		then `<font color="#{rarity.colour:ToHex()}">WILDCARD DEAL</font>`
		elseif tutorialDeal ~= nil then ""
		else `<font color="#{rarity.colour:ToHex()}">{DealerCarConfig.formatArrivalPercent(odds.probability)} ARRIVAL</font>`
	local raritySuffix = if rarityText == "" then "" else " " .. rarityText
	label.RichText = true
	label.Text = `{sellerName(car)}  <font color="#{info.chip:ToHex()}">[{info.label}]</font>`
		.. `\n{DealerCarConfig.displayName(car.templateId)}{raritySuffix} - ${car.ask}`

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = DealerCarConfig.SELLER_PROMPT_NAME
	prompt.ActionText = "Talk to seller"
	prompt.ObjectText = `${car.ask}`
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("PrivateOwnerUserId", player.UserId)
	prompt.Parent = host
	prompt.Triggered:Connect(function(triggerPlayer: Player)
		if triggerPlayer ~= player then
			return
		end
		local current = DealerCar.active(player, workingIndex)
		if current ~= nil
			and current.tradeId == car.tradeId
			and sellerTradeId[player] == car.tradeId
			and sellerWorkingIndex[player] == workingIndex
			and current.state == "Offered"
		then
			-- Talking to the seller is an explicit manual takeover of this exact deal.
			-- Cancel any salesman attempt already in flight and keep every subsequent
			-- response (including the haggle result) on the player's world dialog.
			patienceToken[player] = (patienceToken[player] or 0) + 1
			playerCoveredDeal[player] = true
			sendBuyCard(player, current, "world", nil, workingIndex)
		end
	end)
end

local function stripSellerTags(rig: Model)
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("ProximityPrompt") or descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
end

-- The driver of the car that just parked is the seller: he steps out rather than being
-- replaced by a second body appearing out of thin air.
local function spawnSeller(
	player: Player,
	record: Record,
	car: ActiveCarSave,
	workingIndex: number,
	interactive: boolean?
)
	clearSeller(player, false)
	sellerWorkingIndex[player] = workingIndex
	sellerTradeId[player] = car.tradeId
	local stand = LotSlots.sellerStandCFrame(record, workingIndex)
	local rig = DealerCar.driver(DealerCar.model(player, "working", workingIndex))
	if rig ~= nil then
		LotNpc.unseat(rig, LotSlots.carFolder(record), stand.Position, stand.LookVector)
		rig.Name = DealerCarConfig.SELLER_MODEL_NAME
	else
		rig = LotNpc.spawn(
			DealerCarConfig.SELLER_MODEL_NAME,
			LotSlots.carFolder(record),
			stand.Position,
			stand.LookVector,
			car.sellerId
		)
	end
	if rig == nil then
		return
	end
	rig:SetAttribute("DealerSellerOwnerUserId", player.UserId)
	rig:SetAttribute("DealerSellerTradeId", car.tradeId)
	rig:SetAttribute("DealerSellerWorkingIndex", workingIndex)
	rig:SetAttribute("TutorialDealIndex", car.tutorialDealIndex)
	sellers[player] = rig
	if interactive ~= false then
		decorateSeller(player, rig, car, workingIndex)
	end
end

-- Five to seven steps off the lot and he is out of the picture; he is a pedestrian, not
-- something that belongs on the main road.
local function walkOff(record: Record, rig: Model)
	stripSellerTags(rig)
	task.spawn(function()
		local foot = LotNpc.footPosition(rig)
		local away = LotSlots.roadEntryPosition(record, foot) - foot
		local steps = math.random(DealerCarConfig.SELLER_WALK_STEPS_MIN, DealerCarConfig.SELLER_WALK_STEPS_MAX)
		local points = LotNpc.walkPoints(foot, away, steps, DealerCarConfig.SELLER_STEP_LENGTH, {
			LotSlots.carFolder(record),
		})
		LotNpc.walk(rig, points, DealerCarConfig.WALK_SPEED)
		if rig.Parent ~= nil then
			LotNpc.fadeOut(rig, DealerCarConfig.SELLER_FADE_TIME)
		end
	end)
end

local function sellerWalksOff(player: Player, record: Record)
	local rig = sellers[player]
	sellers[player] = nil
	sellerWorkingIndex[player] = nil
	sellerTradeId[player] = nil
	playerCoveredDeal[player] = nil
	if rig ~= nil then
		walkOff(record, rig)
	end
end

-- Turned down: he gets back behind the wheel of the car he brought and drives it away.
local function sellerDrivesOff(
	player: Player,
	record: Record,
	workingIndex: number,
	expectedTradeId: string
)
	local rig = sellers[player]
	sellers[player] = nil
	sellerWorkingIndex[player] = nil
	sellerTradeId[player] = nil
	playerCoveredDeal[player] = nil
	local _, model = DealerCar.removeWorking(player, workingIndex, expectedTradeId)
	task.spawn(function()
		if rig ~= nil then
			stripSellerTags(rig)
			if model ~= nil then
				rig.Name = "CarDriver"
				LotNpc.seat(rig, model, DealerCar.driverSeat(model))
				task.wait(DealerCarConfig.SELLER_LEAVE_DELAY)
			else
				LotNpc.destroy(rig)
			end
		end
		DealerCar.driveModelAway(record, model)
	end)
end

-- Buy side --------------------------------------------------------------------

function TradeService.startIncoming(
	player: Player,
	record: Record,
	delay: number?,
	preferredWorkingIndex: number?
)
	TradeService.ensureIncomingQueue(player, record)
	if sourceBusy(player) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local tutorialActive = tutorialSourceActive(player)
	-- The Cash Register is the first tutorial action. Do not even reserve W1 until its
	-- critical purchase commit succeeds; this also makes reloads deterministic.
	if tutorialActive and data.pads.CashRegister ~= true then
		return
	end
	-- Tutorial deals remain deterministic and never prefill the runtime waiting queue.
	if tutorialActive then
		for index = 1, DealerCar.workingCapacity(player) do
			if DealerCar.active(player, index) ~= nil then
				return
			end
		end
		for index = 1, DealerCar.displayCapacity(player) do
			if DealerCar.display(player, index) ~= nil then
				return
			end
		end
	end

	local waiting = if tutorialActive then nil else IncomingSellerQueue.peek(player)
	local freeNow = DealerCar.availableWorkingIndex(player)
	local phoneDeal = not tutorialActive
		and waiting == nil
		and freeNow ~= nil
		and usePhone(player)
		and math.random() < DealerCarConfig.PHONE_DEAL_CHANCE
	if phoneDeal then
		TradeService.openFence(player, delay)
		return
	end

	sourcePending[player] = true
	incomingToken[player] = (incomingToken[player] or 0) + 1
	local token = incomingToken[player]
	local function releasePending()
		if incomingToken[player] == token then
			sourcePending[player] = nil
		end
	end
	task.spawn(function()
		if delay ~= nil and delay > 0 then
			task.wait(delay)
		end
		local currentRecord = TycoonService.getForPlayer(player)
		if incomingToken[player] ~= token
			or currentRecord == nil
			or not sameRecord(queueRecord[player], currentRecord)
			or sourceSessionBusy(player)
		then
			releasePending()
			return
		end
		record = currentRecord

		local activeTutorial = tutorialSourceActive(player)
		if activeTutorial then
			for index = 1, DealerCar.workingCapacity(player) do
				if DealerCar.active(player, index) ~= nil then
					releasePending()
					return
				end
			end
			for index = 1, DealerCar.displayCapacity(player) do
				if DealerCar.display(player, index) ~= nil then
					releasePending()
					return
				end
			end
		end

		local queuedHead = if activeTutorial then nil else IncomingSellerQueue.peek(player)
		if queuedHead ~= nil then
			-- Do not steal Q1 while its previous queue-shift drive still owns the model.
			-- Hold this serialized source reservation briefly and hand off only after Q1
			-- reports its exact parked state, so no old coroutine can write CFrame afterward.
			local readyDeadline = os.clock() + 4
			while not IncomingSellerQueue.headReady(player, queuedHead.queueId)
				and os.clock() < readyDeadline
				and incomingToken[player] == token
			do
				task.wait(0.05)
			end
			if not IncomingSellerQueue.headReady(player, queuedHead.queueId) then
				releasePending()
				return
			end
		end
		local workingIndex: number?
		if queuedHead ~= nil then
			-- FIFO always claims the first exact free W; preferred restore hints never skip it.
			workingIndex = DealerCar.availableWorkingIndex(player)
		else
			workingIndex = preferredWorkingIndex
			if workingIndex == nil
				or workingIndex < 1
				or workingIndex > DealerCar.workingCapacity(player)
				or DealerCar.active(player, workingIndex) ~= nil
			then
				workingIndex = DealerCar.availableWorkingIndex(player)
			end
		end
		if workingIndex == nil then
			releasePending()
			if not activeTutorial then
				enqueueWaitingSeller(player, record)
			end
			return
		end

		-- Reserve the exact W before creating or detaching anything. Every source lane is
		-- serialized through sourcePending, and the explicit index documents the ownership
		-- until DataService.setWorking makes the slot authoritative.
		reservedWorking[player] = workingIndex
		clearFenceSession(player)
		hideBuyCard(player, nil, workingIndex)
		local car = if queuedHead ~= nil
			then DealerCar.createIncoming(
				player,
				queuedHead.templateId,
				queuedHead.ask,
				workingIndex,
				savedVariant(queuedHead),
				savedCondition(queuedHead)
			)
			else DealerCar.createIncoming(player, nil, nil, workingIndex)
		if car == nil then
			releasePending()
			warn(("[TradeService] create incoming failed user=%s W=%d"):format(player.Name, workingIndex))
			return
		end

		local queuedModel: Model? = nil
		local towHandoff = queuedHead ~= nil
			and (queuedHead.source == "tow" or queuedHead.sellerId == "TowTruckTony")
		if queuedHead ~= nil then
			car.sellerId = queuedHead.sellerId
			if towHandoff then
				-- Stamp provenance again at the authoritative queue -> inventory boundary.
				-- This protects active saves even if an older queue snapshot lacked the new
				-- condition fields while still using TowTruckTony/source="tow".
				car.condition.towStock = true
				car.condition.wheelsPresent = false
				car.condition.missingWheels = if queuedHead.missingWheels ~= nil
					then table.clone(queuedHead.missingWheels)
					else { "WheelFL", "WheelFR" }
				car.parts.Wheels = false
			end
			local promoted, promotedModel = IncomingSellerQueue.take(player, queuedHead.queueId, workingIndex)
			if promoted == nil or promotedModel == nil then
				DealerCar.removeWorking(player, workingIndex, car.tradeId)
				releasePending()
				warn(("[JunkQueue] exact model dequeue failed user=%d id=%s"):format(
					player.UserId,
					queuedHead.queueId
				))
				return
			end
			queuedModel = promotedModel
			print(("[JunkQueue] promoted same model user=%d W=%d id=%s"):format(
				player.UserId,
				workingIndex,
				queuedHead.queueId
			))
		end

		clearSeller(player, false)
		sellerWorkingIndex[player] = workingIndex
		sellerTradeId[player] = car.tradeId
		releasePending()
		-- A live Tow carrier already performed the visible Q -> W drive and unloaded this exact
		-- cargo. Reusing it in place avoids a second fake self-driving arrival.
		local spawned = DealerCar.spawn(player, record, not towHandoff, "working", workingIndex, queuedModel)
		if spawned == nil then
			if queuedModel ~= nil and queuedModel.Parent ~= nil then
				queuedModel:Destroy()
			end
			DealerCar.removeWorking(player, workingIndex, car.tradeId)
			warn(("[JunkQueue] queued model handoff failed user=%d W=%d"):format(
				player.UserId,
				workingIndex
			))
			return
		end
		DealerCar.publish(player)
		if towHandoff then
			TradeService.presentIncoming(player, record, workingIndex)
		end
	end)
end

-- Called once a junk car the seller brought has finished driving in.
local function salesmanCanBuy(data: any, askingPrice: number): boolean
	local tutorialComplete = data.tutorial ~= nil and data.tutorial.completed == true
	local chapter = TycoonConfig.deriveChapter(data.pads, tutorialComplete)
	if data.progression ~= nil and typeof(data.progression.chapter) == "number" then
		chapter = math.max(chapter, math.floor(data.progression.chapter))
	end
	return TycoonConfig.salesmanCanBuy(data.cash, askingPrice, data.pads, tutorialComplete, chapter)
end

function TradeService.presentIncoming(
	player: Player,
	record: Record,
	workingIndex: number?
)
	local resolvedIndex = workingIndex or sellerWorkingIndex[player]
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if resolvedIndex == nil
		or car == nil
		or car.state ~= "Incoming"
		or sellerTradeId[player] ~= car.tradeId
	then
		return
	end
	car.state = "Offered"
	local staffHandlesDeal = listingAutomated(player)
	-- The driver always steps out and remains actionable. Automation may be physically busy
	-- listing another car, so the owner must be able to cover this exact incoming deal.
	spawnSeller(player, record, car, resolvedIndex, true)
	GameplayEvents.emit("TradeOpened", player, {
		tradeId = car.tradeId,
		tradeType = "DealerPurchase",
		workingIndex = resolvedIndex,
		carId = car.templateId,
		templateId = car.templateId,
		tutorialDealIndex = car.tutorialDealIndex,
		ask = car.ask,
	})
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "Offered", "working", resolvedIndex)
	print(`[Analytics] car_offered user={player.UserId} W={resolvedIndex} car={car.templateId} ask={car.ask}`)

	if staffHandlesDeal then
		patienceToken[player] = (patienceToken[player] or 0) + 1
		local staffToken = patienceToken[player]
		playerCoveredDeal[player] = StaffDirector.isSalesmanBusy(record)
		task.spawn(function()
			while patienceToken[player] == staffToken do
				local current = DealerCar.active(player, resolvedIndex)
				if current ~= car
					or car.state ~= "Offered"
					or sellerTradeId[player] ~= car.tradeId
				then
					return
				end
				local completed = StaffDirector.closeIncomingDeal(
					record,
					resolvedIndex,
					function(): boolean
						return patienceToken[player] == staffToken
							and DealerCar.active(player, resolvedIndex) == car
							and car.state == "Offered"
							and sellerTradeId[player] == car.tradeId
					end,
					function()
						local currentData = DataService.get(player)
						if currentData == nil then
							return
						end
						-- This was handled by staff after all; suppress the owner-coverage reaction.
						playerCoveredDeal[player] = nil
						local action = if salesmanCanBuy(currentData, car.ask) then "buy" else "refuse"
						TradeService.handleBuy(player, action, car.tradeId, resolvedIndex)
					end
				)
				if completed then
					return
				end
				playerCoveredDeal[player] = true
				task.wait(0.5)
			end
		end)
		return
	end

	-- The first tutorial seller is the player's only first-flip path and never expires.
	if car.tutorialDealIndex == 1 then
		return
	end
	patienceToken[player] = (patienceToken[player] or 0) + 1
	local token = patienceToken[player]
	task.delay(DealerCarConfig.SELLER_PATIENCE, function()
		if patienceToken[player] ~= token then
			return
		end
		local current = DealerCar.active(player, resolvedIndex)
		if current == car
			and car.state == "Offered"
			and sellerTradeId[player] == car.tradeId
		then
			TradeService.handleBuy(player, "refuse", car.tradeId, resolvedIndex)
		end
	end)
end

-- Called once a car bought from the fence has been delivered.
local function acceptDelivery(player: Player, record: Record, workingIndex: number?)
	local resolvedIndex = workingIndex or sellerWorkingIndex[player]
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if resolvedIndex == nil
		or car == nil
		or car.state ~= "Incoming"
		or sellerTradeId[player] ~= car.tradeId
	then
		return
	end
	local rig = DealerCar.driver(DealerCar.model(player, "working", resolvedIndex))
	if rig ~= nil then
		local stand = LotSlots.sellerStandCFrame(record, resolvedIndex)
		LotNpc.unseat(rig, LotSlots.carFolder(record), stand.Position, stand.LookVector, "walk")
		walkOff(record, rig)
	end
	sellerWorkingIndex[player] = nil
	sellerTradeId[player] = nil
	-- Purchase changes ownership, not the physical proxy or its condition treatment.
	DealerCar.setState(player, "Junk", resolvedIndex, false)
	TradeService.startIncoming(player, record, DealerCarConfig.SELLER_GAP_MIN)
end

TradeService.acceptDelivery = acceptDelivery

-- Fence purchase: pay first, the car is delivered afterwards.
local function buyFromFence(
	player: Player,
	record: Record,
	offer: FenceOffer,
	workingIndex: number,
	expectedSessionTradeId: string
): boolean
	if fenceTradeId[player] ~= expectedSessionTradeId
		or fenceWorkingIndex[player] ~= workingIndex
		or DealerCar.active(player, workingIndex) ~= nil
	then
		return false
	end
	if not TycoonService.trySpend(player, offer.ask) then
		sendFenceCard(player, offer, "come back when you have the cash")
		return false
	end
	local usedAskForLower = offer.haggleUsed == true
	hideBuyCard(player, nil, workingIndex)
	clearFenceSession(player)
	local car = DealerCar.createIncoming(player, offer.templateId, offer.ask, workingIndex, savedVariant(offer))
	if car == nil then
		TycoonService.addCash(player, offer.ask)
		TradeService.startIncoming(player, record, 0)
		return false
	end
	car.cost = offer.ask
	sellerWorkingIndex[player] = workingIndex
	sellerTradeId[player] = car.tradeId
	GameplayEvents.emit("CarBought", player, {
		tradeId = car.tradeId,
		workingIndex = workingIndex,
		carId = car.templateId,
		templateId = car.templateId,
		tutorialDealIndex = car.tutorialDealIndex,
		purchaseCost = car.cost,
		channel = "fence",
		askForLowerUsed = usedAskForLower,
		action = if usedAskForLower then "ask_for_lower" else "buy",
		cashAfter = TycoonService.getCash(player),
	})
	DealerCar.spawn(player, record, true, "working", workingIndex)
	DealerCar.publish(player)
	DataService.save(player)
	popCash(player, record, -offer.ask, "working", workingIndex)
	return true
end

TradeService.buyFromFence = buyFromFence

local function handleFenceAction(
	player: Player,
	record: Record,
	action: string,
	expectedTradeId: string?,
	expectedWorkingIndex: number?
)
	local sessionTradeId = fenceTradeId[player]
	local workingIndex = fenceWorkingIndex[player]
	if sessionTradeId == nil or workingIndex == nil then
		TradeService.openFence(player, 0)
		return
	end
	if (expectedTradeId ~= nil and expectedTradeId ~= "" and expectedTradeId ~= sessionTradeId)
		or (expectedWorkingIndex ~= nil and expectedWorkingIndex ~= workingIndex)
		or DealerCar.active(player, workingIndex) ~= nil
	then
		return
	end
	local list = offers[player]
	if list == nil then
		clearFenceSession(player)
		TradeService.openFence(player, 0)
		return
	end

	local index = string.match(action, "^pick(%d+)$")
	if index ~= nil then
		local slot = tonumber(index)
		if slot ~= nil and list[slot] ~= nil then
			picked[player] = slot
			lastNote[player] = nil
			sendFenceCard(player, list[slot])
		end
		return
	end

	local slot = picked[player]
	local offer = if slot ~= nil then list[slot] else nil
	if offer == nil then
		if action == "refuse" then
			hideBuyCard(player, nil, workingIndex)
			clearFenceSession(player)
			TradeService.openFence(player, DealerCarConfig.FENCE_REFRESH_DELAY)
		else
			sendOfferList(player)
		end
		return
	end

	if action == "haggle" then
		if offer.haggleUsed then
			sendFenceCard(player, offer, "that's already my best price")
			return
		end
		offer.haggleUsed = true
		if math.random() <= fencePerson(player).haggleChance then
			offer.ask = math.max(1, math.floor(offer.ask * (1 - DealerCarConfig.BUY_HAGGLE_DISCOUNT)))
			sendFenceCard(player, offer, "fine, " .. offer.ask .. " and it's yours")
		else
			sendFenceCard(player, offer, "no, the price is the price")
		end
		return
	end

	if action == "refuse" then
		-- Back to the list rather than out of the conversation: the fence has more cars.
		picked[player] = nil
		lastNote[player] = nil
		sendOfferList(player)
		return
	end

	if action == "buy" then
		buyFromFence(player, record, offer, workingIndex, sessionTradeId)
	end
end

function TradeService.handleBuy(
	player: Player,
	action: string,
	tradeId: string?,
	workingIndex: number?
)
	local record = TycoonService.getForPlayer(player)
	local data = DataService.get(player)
	if record == nil or data == nil then
		return
	end
	local expectedTradeId = tradeId or ""

	-- Fence cards carry a synthetic session trade id; live cars carry their saved trade id.
	local activeFenceTradeId = fenceTradeId[player]
	if activeFenceTradeId ~= nil
		and (expectedTradeId == activeFenceTradeId
			or (expectedTradeId == "" and sellerTradeId[player] == nil))
	then
		handleFenceAction(player, record, action, expectedTradeId, workingIndex)
		return
	end

	local resolvedIndex = workingIndex
		or (if expectedTradeId ~= "" then DealerCar.workingIndexForTrade(player, expectedTradeId) else nil)
		or sellerWorkingIndex[player]
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if resolvedIndex ~= nil
		and car ~= nil
		and car.state == "Offered"
		and sellerWorkingIndex[player] == resolvedIndex
		and sellerTradeId[player] == car.tradeId
	then
		if expectedTradeId ~= "" and expectedTradeId ~= car.tradeId then
			return
		end
		if action == "haggle" then
			if car.haggleUsed then
				sendBuyCard(player, car, "world", "that's already my best price", resolvedIndex)
				return
			end
			car.haggleUsed = true
			local person = sellerPerson(car)
			local chance = if person ~= nil then person.haggleChance else DealerCarConfig.BUY_HAGGLE_CHANCE
			if math.random() <= chance then
				car.ask = math.max(1, math.floor(car.ask * (1 - DealerCarConfig.BUY_HAGGLE_DISCOUNT)))
				sendBuyCard(player, car, "world", "fine, " .. car.ask .. " and it's yours", resolvedIndex)
			else
				sendBuyCard(player, car, "world", "no, the price is the price", resolvedIndex)
			end
			GameplayEvents.emit("TradeResolved", player, {
				status = "Negotiating",
				action = "ask_for_lower",
				carId = car.templateId,
				templateId = car.templateId,
				tutorialDealIndex = car.tutorialDealIndex,
				askForLowerUsed = true,
				askingPrice = car.ask,
			})
			DealerCar.publish(player)
			return
		end

		if action == "refuse" then
			-- The authored tutorial purchase is a mandatory progression beat. Keep
			-- the server authoritative even if a stale client still submits the hidden action.
			if DealerCarConfig.tutorialDeal(car.tutorialDealIndex) ~= nil then
				return
			end
			local usedAskForLower = car.haggleUsed == true
			GameplayEvents.emit("TradeResolved", player, {
				status = "Declined",
				action = if usedAskForLower then "refuse_after_ask_for_lower" else "refuse",
				carId = car.templateId,
				templateId = car.templateId,
				tutorialDealIndex = car.tutorialDealIndex,
				askForLowerUsed = usedAskForLower,
				askingPrice = car.ask,
			})
			patienceToken[player] = (patienceToken[player] or 0) + 1
			hideBuyCard(player, car, resolvedIndex)
			print(`[Analytics] car_refused user={player.UserId} W={resolvedIndex} car={car.templateId} ask={car.ask}`)
			sellerDrivesOff(player, record, resolvedIndex, car.tradeId)
			local gap = DealerCarConfig.SELLER_GAP_MIN
				+ math.random() * (DealerCarConfig.SELLER_GAP_MAX - DealerCarConfig.SELLER_GAP_MIN)
			TradeService.startIncoming(player, record, gap)
			return
		end

		if action ~= "buy" then
			return
		end
		if not TycoonService.trySpend(player, car.ask) then
			sendBuyCard(player, car, "world", "come back when you have the cash", resolvedIndex)
			return
		end

		patienceToken[player] = (patienceToken[player] or 0) + 1
		local usedAskForLower = car.haggleUsed == true
		car.cost = car.ask
		car.haggleUsed = false
		hideBuyCard(player, car, resolvedIndex)
		recordDeal(player, car.sellerId)
		GameplayEvents.emit("CarBought", player, {
			tradeId = car.tradeId,
			workingIndex = resolvedIndex,
			carId = car.templateId,
			templateId = car.templateId,
			tutorialDealIndex = car.tutorialDealIndex,
			purchaseCost = car.cost,
			channel = "world",
			askForLowerUsed = usedAskForLower,
			action = if usedAskForLower then "ask_for_lower" else "buy",
			cashAfter = TycoonService.getCash(player),
		})
		local coveredStaff = playerCoveredDeal[player] == true
		playerCoveredDeal[player] = nil
		sellerWalksOff(player, record)
		if coveredStaff then
			StaffDirector.acknowledgePlayerDeal(record, car.cost)
		end
		popCash(player, record, -car.cost, "working", resolvedIndex)
		-- The exact arriving model is already conditioned. Do not rebuild it at the buy edge.
		DealerCar.setState(player, "Junk", resolvedIndex, false)
		DataService.save(player)
		local gap = DealerCarConfig.SELLER_GAP_MIN
			+ math.random() * (DealerCarConfig.SELLER_GAP_MAX - DealerCarConfig.SELLER_GAP_MIN)
		TradeService.startIncoming(player, record, gap)
		return
	end

	if activeFenceTradeId ~= nil then
		handleFenceAction(player, record, action, expectedTradeId, workingIndex)
	end
end

-- Sell side ------------------------------------------------------------------

local function clearListPromptsOnPlatform(record: Record)
	for workingIndex = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		local anchor = LotSlots.platform(record, workingIndex)
		if anchor ~= nil then
			for _, descendant in anchor:GetDescendants() do
				if descendant:IsA("ProximityPrompt")
					and descendant.Name == DealerCarConfig.LIST_PROMPT_NAME
				then
					descendant:Destroy()
				end
			end
			local attach = anchor:FindFirstChild("ListPromptAttach")
			if attach ~= nil and #attach:GetChildren() == 0 then
				attach:Destroy()
			end
		end
	end
	listPrompts[record] = nil
end

local function carReadyOnLot(player: Player, workingIndex: number?): boolean
	local resolvedIndex = workingIndex or 1
	local car = DealerCar.active(player, resolvedIndex)
	local model = DealerCar.model(player, "working", resolvedIndex)
	if car == nil or model == nil then
		return false
	end
	local reservedDisplayIndex = tonumber(model:GetAttribute("ListingDisplayIndex"))
	local ownsReservedDestination = reservedDisplayIndex ~= nil
		and DealerCar.displayReservation(player, reservedDisplayIndex) == car.tradeId
	return (DealerCar.availableDisplayIndex(player) ~= nil or ownsReservedDestination)
		and car.state == "Ready"
		and DealerCar.isReadyForListing(car)
		and model.Parent ~= nil
		and model:GetAttribute("WorkingSlotIndex") == resolvedIndex
		and model:GetAttribute("Arriving") ~= true
end

function TradeService.refreshListPrompt(
	player: Player,
	record: Record,
	preferredWorkingIndex: number?
)
	clearListPromptsOnPlatform(record)
	ListingTransport.sync(player, record, preferredWorkingIndex)
end

function TradeService.disableListPrompt(record: Record)
	clearListPromptsOnPlatform(record)
	ListingTransport.cancelRecord(record)
end

local function sendSellCard(player: Player, car: ActiveCarSave, note: string?, displayIndex: number?)
	if buyerAutomated(player) then
		return
	end
	local resolvedIndex = displayIndex or DealerCar.displayIndexForTrade(player, car.tradeId)
	local current = if resolvedIndex ~= nil then DealerCar.display(player, resolvedIndex) else nil
	if resolvedIndex == nil or current == nil or current.tradeId ~= car.tradeId then
		return
	end
	local breakdown = DealerCar.valueBreakdown(player, car)
	local person = TownsfolkConfig.get(car.customerId)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local askMoreBonus = if person ~= nil then person.askMore else DealerCarConfig.ASK_MORE_BONUS
	local data = DataService.get(player)
	local odds = DealerCarConfig.arrivalOdds(car.templateId, DealerCar.pads(player), if data ~= nil then data.luck else nil)
	local rarity = DealerCarConfig.rarityTier(odds.oneInN)
	local wealthMultiplier = if tutorialDeal == nil then TownsfolkConfig.offerMultiplier(person) else 1
	local rarityBonus = if tutorialDeal == nil then rarity.offerBonus else 0
	Remotes.OfferUpdate:FireClient(player, {
		visible = true,
		slot = "display",
		slotIndex = resolvedIndex,
		tradeId = car.tradeId,
		note = note,
		amount = car.offered,
		currentOffer = car.offered,
		value = breakdown.listedPrice,
		listedPrice = breakdown.listedPrice,
		calculatedValue = breakdown.calculatedValue,
		baseValue = breakdown.baseValue,
		partsValue = breakdown.partsValue,
		listingMarkup = breakdown.listingMarkup,
		purchaseCost = car.cost,
		finalProfit = if car.offered > 0 then car.offered - car.cost else 0,
		cost = car.cost,
		haggleUsed = car.haggleUsed,
		carName = DealerCarConfig.displayName(car.templateId),
		tutorialDealIndex = car.tutorialDealIndex,
		tutorialWildcard = car.tutorialWildcard == true,
		tutorialBeat = if tutorialDeal ~= nil then tutorialDeal.beat else nil,
		personId = car.customerId,
		served = servedCount(player, car.customerId),
		rarityOneInN = odds.oneInN,
		rarityTier = rarity.id,
		breakdown = {
			base = breakdown.baseValue,
			parts = breakdown.partsValue,
			signPct = breakdown.listingMarkup,
			servicePct = 0,
			wealthPct = wealthMultiplier - 1,
			rarityPct = rarityBonus,
			askMorePct = if car.haggleUsed then askMoreBonus else 0,
		},
	})
end

TradeService.sendSellCard = sendSellCard

local function tradePayload(player: Player, car: ActiveCarSave, displayIndex: number?)
	if car.tradeId == "" then
		car.tradeId = TradeContract.newTradeId(player, car.templateId)
	end
	local breakdown = DealerCar.valueBreakdown(player, car)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local listedPrice = if tutorialDeal ~= nil and tutorialDeal.fixedValue ~= nil
		then math.max(1, math.floor(tutorialDeal.fixedValue))
		elseif car.listedPrice > 0 then car.listedPrice
		else breakdown.listedPrice
	car.listedPrice = listedPrice
	local markup = math.max(0, listedPrice / math.max(1, breakdown.calculatedValue) - 1)
	local data = DataService.get(player)
	local odds = DealerCarConfig.arrivalOdds(car.templateId, DealerCar.pads(player), if data ~= nil then data.luck else nil)
	return {
		tradeId = car.tradeId,
		tradeType = "DealerSale",
		slotIndex = displayIndex or DealerCar.displayIndexForTrade(player, car.tradeId),
		personId = car.customerId,
		carId = car.templateId,
		rarityOneInN = odds.oneInN,
		tutorialDealIndex = car.tutorialDealIndex,
		tutorialWildcard = car.tutorialWildcard,
		fixedOffer = if tutorialDeal ~= nil then tutorialDeal.fixedOffer else nil,
		baseValue = breakdown.baseValue,
		partsValue = breakdown.partsValue,
		calculatedValue = breakdown.calculatedValue,
		listingMarkup = markup,
		listedPrice = listedPrice,
		purchaseCost = car.cost,
		serviceCost = car.serviceCost,
		totalInvestment = car.cost + car.serviceCost,
	}
end

local function restoreTutorial(tutorial, snapshot)
	tutorial.eligible = snapshot.eligible
	tutorial.dealIndex = snapshot.dealIndex
	tutorial.completed = snapshot.completed
end

local function nextListedDisplay(player: Player): (ActiveCarSave?, number?)
	local capacity = DealerCar.displayCapacity(player)
	if capacity <= 0 then
		return nil, nil
	end
	local cursor = buyerCursor[player] or 0
	for offset = 1, capacity do
		local displayIndex = ((cursor + offset - 1) % capacity) + 1
		local car = DealerCar.display(player, displayIndex)
		if car ~= nil and car.state == "Listed" and car.tradeId ~= "" then
			return car, displayIndex
		end
	end
	return nil, nil
end

local function applyTradeResult(
	player: Player,
	car: ActiveCarSave,
	result: any,
	displayIndex: number?
)
	local data = DataService.get(player)
	local record = TycoonService.getForPlayer(player)
	local resolvedIndex = displayIndex or DealerCar.displayIndexForTrade(player, car.tradeId)
	local current = if resolvedIndex ~= nil then DealerCar.display(player, resolvedIndex) else nil
	if data == nil
		or record == nil
		or resolvedIndex == nil
		or current == nil
		or current.tradeId ~= car.tradeId
		or result.tradeId ~= car.tradeId
	then
		return
	end
	local laneTradeId = laneTrade(player, resolvedIndex)
	if laneTradeId ~= nil and laneTradeId ~= car.tradeId then
		return
	end

	local outcome = result.result or result.status
	if outcome == "Walked" or outcome == "Declined" then
		car.offered = 0
		car.haggleUsed = false
		hideSellCard(player, car, resolvedIndex)
		local leavingBuyer = buyerRig(player, resolvedIndex)
		if leavingBuyer ~= nil and leavingBuyer.Parent ~= nil then
			sayBuyer(player, leavingBuyer, randomLine(BUYER_DECLINE_LINES))
			task.wait(1.6)
		end
		sendBuyerAway(player, record, resolvedIndex)
		DealerCar.setDisplayState(player, "Listed", resolvedIndex)
		releaseBuyerLane(player, car.tradeId, resolvedIndex)
		TradeService.armBuyerTimer(player, car, resolvedIndex)
		return
	end
	if outcome ~= "Accepted" or (car.state ~= "Listed" and car.state ~= "Offer") then
		return
	end

	local paid = math.max(1, math.floor(result.finalOffer))
	local breakdown = DealerCar.valueBreakdown(player, car)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local serviceCost = math.max(0, math.floor(car.serviceCost))
	local serviceCostPaid = math.clamp(math.floor(car.serviceCostPaid), 0, serviceCost)
	local outstandingServiceCost = serviceCost - serviceCostPaid
	local cashPayout = math.max(0, paid - outstandingServiceCost)
	local profit = paid - car.cost - serviceCost
	local cashBefore = data.cash
	local previousState = car.state
	local previousOffer = car.offered
	local tutorial = data.tutorial
	local tutorialSnapshot = {
		eligible = tutorial.eligible,
		dealIndex = tutorial.dealIndex,
		completed = tutorial.completed,
	}

	car.offered = paid
	car.customerId = if typeof(result.customerId) == "string" then result.customerId else car.customerId
	car.state = "Sold"
	if tutorial.eligible == true
		and tutorial.completed ~= true
		and car.tutorialDealIndex >= 1
		and car.tutorialDealIndex == tutorial.dealIndex
	then
		tutorial.dealIndex = car.tutorialDealIndex + 1
		if car.tutorialDealIndex >= DealerCarConfig.TUTORIAL_DEAL_COUNT then
			tutorial.dealIndex = DealerCarConfig.TUTORIAL_DEAL_COUNT + 1
			tutorial.completed = true
		end
	end

	local settled, reason = DataService.trySettleTrade(player, car.tradeId, cashPayout)
	if not settled and reason ~= "duplicate" then
		car.state = previousState
		car.offered = previousOffer
		restoreTutorial(tutorial, tutorialSnapshot)
		DealerCar.publish(player)
		return
	end
	if reason == "duplicate" then
		DataService.save(player)
	end
	TycoonService.syncCash(player)

	recordDeal(player, car.customerId)
	hideSellCard(player, car, resolvedIndex)
	popCash(player, record, cashPayout, "display", resolvedIndex)
	data.analytics.saleCount += 1
	if data.analytics.firstSaleAt == nil then
		data.analytics.firstSaleAt = os.time()
	end
	if not buyerAutomated(player) then
		Remotes.ProfitCard:FireClient(player, {
			tradeId = car.tradeId,
			paid = paid,
			cashPayout = cashPayout,
			value = breakdown.listedPrice,
			listedPrice = breakdown.listedPrice,
			calculatedValue = breakdown.calculatedValue,
			profit = profit,
			cost = car.cost,
			serviceCost = serviceCost,
			totalInvestment = car.cost + serviceCost,
			carName = DealerCarConfig.displayName(car.templateId),
			slotIndex = resolvedIndex,
			tutorialDealIndex = car.tutorialDealIndex,
			tutorialWildcard = car.tutorialWildcard == true,
			tutorialBeat = if tutorialDeal ~= nil then tutorialDeal.beat else nil,
		})
	end

	DealerCar.setDisplayState(player, "Sold", resolvedIndex)
	local soldPresentation = DealerCar.displayModel(player, resolvedIndex)
	if soldPresentation ~= nil then
		soldPresentation:SetAttribute("SoldPrice", paid)
		CarVisuals.setSoldBillboard(soldPresentation, DealerCarConfig.displayName(car.templateId), paid)
	end
	-- Progression and unlocks are gameplay state, so publish the completed sale now.
	-- The buyer's celebration below is cosmetic and must not hold Chapter 2 back.
	GameplayEvents.emit("CarSold", player, {
		tradeId = car.tradeId,
		slotIndex = resolvedIndex,
		carId = car.templateId,
		templateId = car.templateId,
		tutorialDealIndex = car.tutorialDealIndex,
		calculatedValue = breakdown.calculatedValue,
		listedPrice = car.listedPrice,
		finalOffer = paid,
		cashPayout = cashPayout,
		serviceCost = serviceCost,
		serviceCostPaidBeforeSale = serviceCostPaid,
		serviceCostWithheld = outstandingServiceCost,
		finalProfit = profit,
		askForMoreUsed = car.haggleUsed == true,
		cashBefore = cashBefore,
		cashAfter = data.cash,
	})
	local happyBuyer = buyerRig(player, resolvedIndex)
	if happyBuyer ~= nil and happyBuyer.Parent ~= nil then
		LotNpc.play(happyBuyer, "customerEnergized")
		sayBuyer(player, happyBuyer, randomLine(BUYER_SUCCESS_LINES))
		-- customer_energized is a five-second one-shot. Let the buyer finish celebrating
		-- before the existing seat/drive-away handoff replaces it with the drive pose.
		task.wait(CUSTOMER_PURCHASE_CELEBRATION_TIME)
	end
	-- Release only the exact sold P slot through the core authority. Another sale
	-- continuation may already have removed the save row; that is an idempotent success,
	-- not a reason to abandon the buyer lane and the rest of the cleanup.
	local _, soldModel = DealerCar.removeDisplayStock(player, resolvedIndex, car.tradeId)
	if soldModel == nil
		and soldPresentation ~= nil
		and soldPresentation.Parent ~= nil
		and soldPresentation:GetAttribute("TradeId") == car.tradeId
	then
		soldModel = soldPresentation
	end
	local buyer = takeBuyer(player, resolvedIndex)
	if buyer ~= nil and soldModel ~= nil and buyer.Parent ~= nil then
		LotNpc.seat(buyer, soldModel, CarVisuals.driverSeat(soldModel))
	elseif buyer ~= nil and buyer.Parent ~= nil then
		buyer:Destroy()
	end
	if soldModel ~= nil then
		soldModel:SetAttribute("SoldPrice", paid)
		CarVisuals.setSoldBillboard(soldModel, DealerCarConfig.displayName(car.templateId), paid)
		task.spawn(function()
			DealerCar.driveModelAway(record, soldModel)
		end)
	end
	releaseBuyerLane(player, car.tradeId, resolvedIndex)
	DataService.save(player)
	TradeService.refreshListPrompt(player, record)
	TradeService.armBuyerTimer(player)
	if DealerCar.availableWorkingIndex(player) ~= nil then
		TradeService.startIncoming(player, record, 0)
	end
end

local function beginBuyerOffer(
	player: Player,
	car: ActiveCarSave,
	displayIndex: number,
	token: number
)
	local record = TycoonService.getForPlayer(player)
	if record == nil or not buyerStillValid(player, car, displayIndex, token) then
		if releaseBuyerLane(player, car.tradeId, displayIndex) then
			TradeService.armBuyerTimer(player)
		end
		return
	end

	local rig = spawnBuyerAtCar(player, record, car, displayIndex, token)
	if rig == nil or not buyerStillValid(player, car, displayIndex, token) then
		if releaseBuyerLane(player, car.tradeId, displayIndex) then
			TradeService.armBuyerTimer(player)
		end
		return
	end
	buyerBubble(player, rig, DealerCarConfig.displayName(car.templateId))
	task.wait(2.4)
	if not buyerStillValid(player, car, displayIndex, token) then
		if buyers[player] == rig then
			buyers[player] = nil
			LotNpc.destroy(rig)
		end
		if releaseBuyerLane(player, car.tradeId, displayIndex) then
			TradeService.armBuyerTimer(player)
		end
		return
	end

	local existing = TradeContract.pendingFor(player, car.tradeId)
	if existing ~= nil then
		if buyers[player] == rig then
			buyers[player] = nil
			LotNpc.destroy(rig)
		end
		if releaseBuyerLane(player, car.tradeId, displayIndex) then
			TradeService.armBuyerTimer(player)
		end
		return
	end

	local payload = tradePayload(player, car, displayIndex)
	TradeContract.request(player, payload, function(offer: number)
		local current = DealerCar.display(player, displayIndex)
		if current == nil
			or current.tradeId ~= car.tradeId
			or car.state ~= "Listed"
			or car.tradeId ~= payload.tradeId
			or laneToken(player, displayIndex) ~= token
			or laneTrade(player, displayIndex) ~= car.tradeId
		then
			TradeContract.cancel(player, payload.tradeId)
			if buyerRig(player, displayIndex) == rig then
				setBuyerRig(player, displayIndex, nil)
				LotNpc.destroy(rig)
			end
			if releaseBuyerLane(player, car.tradeId, displayIndex) then
				TradeService.armBuyerTimer(player)
			end
			return
		end
		car.offered = math.max(1, math.floor(offer))
		car.haggleUsed = false
		DealerCar.setDisplayState(player, "Offer", displayIndex)
		sendSellCard(player, car, nil, displayIndex)
	end, function(result)
		applyTradeResult(player, car, result, displayIndex)
	end)
end

local function armBuyerLane(player: Player, displayIndex: number)
	local car = DealerCar.display(player, displayIndex)
	local activeTradeId = laneTrade(player, displayIndex)
	if activeTradeId ~= nil then
		if car ~= nil and car.tradeId == activeTradeId then
			if car.state == "Offer" or car.state == "Sold" then
				return
			end
			if car.state == "Listed" then
				local started = buyerLaneStartedAt[player]
				local startedAt = if started ~= nil then started[displayIndex] else nil
				local age = if typeof(startedAt) == "number"
					then workspace:GetServerTimeNow() - startedAt
					else math.huge
				local hasLiveBuyer = buyerRig(player, displayIndex) ~= nil
				local hasPendingOffer = TradeContract.pendingFor(player, activeTradeId) ~= nil
				if hasLiveBuyer or hasPendingOffer or age <= BUYER_LANE_STALL_TIMEOUT then
					return
				end
				warn(string.format(
					"[TradeService] recovering stalled buyer lane P%d trade=%s age=%.1f",
					displayIndex,
					activeTradeId,
					age
				))
			end
		end
		TradeContract.cancel(player, activeTradeId)
		clearBuyer(player, displayIndex)
		releaseBuyerLane(player, activeTradeId, displayIndex)
	end
	if car == nil or car.tradeId == "" then return end

	if car.state == "Offer" and car.offered > 0 then
		claimBuyerLane(player, car, displayIndex)
		if TradeContract.pendingFor(player, car.tradeId) == nil then
			local restored, restoredOffer = TradeContract.restoreFallback(
				player,
				tradePayload(player, car, displayIndex),
				car.offered,
				function(result)
					applyTradeResult(player, car, result, displayIndex)
				end
			)
			if restored and typeof(restoredOffer) == "number" and car.offered ~= restoredOffer then
				car.offered = restoredOffer
				DataService.save(player)
			end
		end
		sendSellCard(player, car, nil, displayIndex)
		return
	elseif car.state ~= "Listed" then
		return
	end

	local token = claimBuyerLane(player, car, displayIndex)
	local data = DataService.get(player)
	local tutorialBuyer = data ~= nil
		and data.tutorial.completed ~= true
		and car.tutorialDealIndex >= 1
		and car.tutorialDealIndex <= DealerCarConfig.TUTORIAL_DEAL_COUNT
	local waitFor = if tutorialBuyer
		then 1 + math.random()
		else DealerCarConfig.OFFER_DELAY_MIN
			+ math.random() * (DealerCarConfig.OFFER_DELAY_MAX - DealerCarConfig.OFFER_DELAY_MIN)
	task.delay(waitFor, function()
		if buyerStillValid(player, car, displayIndex, token) then
			beginBuyerOffer(player, car, displayIndex, token)
		elseif releaseBuyerLane(player, car.tradeId, displayIndex) then
			TradeService.armBuyerTimer(player, nil, displayIndex)
		end
	end)
end

function TradeService.armBuyerTimer(player: Player, _car: ActiveCarSave?, displayIndex: number?)
	if displayIndex ~= nil then
		armBuyerLane(player, displayIndex)
		return
	end
	for index = 1, DealerCar.displayCapacity(player) do
		armBuyerLane(player, index)
	end
end

local function commitListing(
	player: Player,
	record: Record,
	listingModel: Model,
	displayIndex: number?,
	workingIndex: number?
)
	local resolvedWorkingIndex = workingIndex
		or tonumber(listingModel:GetAttribute("WorkingSlotIndex"))
	local current = if resolvedWorkingIndex ~= nil
		then DealerCar.active(player, resolvedWorkingIndex)
		else nil
	local sameModel = resolvedWorkingIndex ~= nil
		and DealerCar.model(player, "working", resolvedWorkingIndex) == listingModel
	local hasListingPad = DealerCar.hasPad(player, TycoonConfig.LISTING_PAD_ID)
	local readyOnLot = resolvedWorkingIndex ~= nil
		and carReadyOnLot(player, resolvedWorkingIndex)
	local prepared = false
	local preparedIndex: number? = nil
	local preparedWorkingIndex: number? = nil
	if current ~= nil and sameModel and hasListingPad and readyOnLot then
		prepared, preparedIndex, preparedWorkingIndex =
			ListingTransport.prepareCommit(player, record, current, listingModel)
	end
	if current == nil
		or resolvedWorkingIndex == nil
		or not sameModel
		or not hasListingPad
		or not readyOnLot
		or not prepared
		or preparedIndex == nil
		or preparedWorkingIndex ~= resolvedWorkingIndex
		or (displayIndex ~= nil and preparedIndex ~= displayIndex)
		or DealerCar.display(player, preparedIndex) ~= nil
	then
		TradeService.refreshListPrompt(player, record, resolvedWorkingIndex)
		return
	end

	local breakdown = DealerCar.valueBreakdown(player, current)
	current.listedPrice = breakdown.listedPrice
	current.offered = 0
	TradeContract.cancel(player, current.tradeId)
	local committed, committedIndex, committedWorkingIndex = DealerCar.finishListing(
		player,
		record,
		listingModel,
		preparedIndex,
		resolvedWorkingIndex
	)
	if not committed
		or committedIndex ~= preparedIndex
		or committedWorkingIndex ~= resolvedWorkingIndex
	then
		TradeService.refreshListPrompt(player, record, resolvedWorkingIndex)
		return
	end
	GameplayEvents.emit("CarListed", player, {
		tradeId = current.tradeId,
		workingIndex = resolvedWorkingIndex,
		slotIndex = preparedIndex,
		carId = current.templateId,
		templateId = current.templateId,
		tutorialDealIndex = current.tutorialDealIndex,
		calculatedValue = breakdown.calculatedValue,
		listingMarkup = breakdown.listingMarkup,
		listedPrice = breakdown.listedPrice,
	})
	DataService.save(player)
	TradeService.refreshListPrompt(player, record)
	TradeService.armBuyerTimer(player, current, preparedIndex)
	TradeService.startIncoming(player, record, 0)
end

function TradeService.startAutomatedListing(player: Player, workingIndex: number?)
	local record = TycoonService.getForPlayer(player)
	local resolvedIndex = workingIndex
	if resolvedIndex == nil then
		for index = 1, DealerCar.workingCapacity(player) do
			if carReadyOnLot(player, index) then
				resolvedIndex = index
				break
			end
		end
	end
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	local model = if resolvedIndex ~= nil
		then DealerCar.model(player, "working", resolvedIndex)
		else nil
	if record == nil
		or resolvedIndex == nil
		or car == nil
		or model == nil
		or not DealerCar.hasPad(player, DealerCarConfig.AUTO_LIST_PAD)
		or not DealerCar.hasPad(player, TycoonConfig.LISTING_PAD_ID)
		or not carReadyOnLot(player, resolvedIndex)
	then
		return
	end
	local listing = car
	local listingModel = model
	local autopilotStarted, usedParkingV2 = ListingTransport.beginAutopilot(
		player,
		record,
		listing,
		listingModel,
		resolvedIndex
	)
	if not autopilotStarted then
		return
	end

	local StaffDirector = require(script.Parent.StaffDirector)
	local prestagedQueueId: string? = nil
	local function cancelPrestage()
		if prestagedQueueId ~= nil then
			IncomingSellerQueue.cancelPrestage(player, prestagedQueueId)
			prestagedQueueId = nil
		end
	end
	local function runListing(listingStaffId: string?): boolean
		return StaffDirector.listJob(record, listingModel, function()
			local targetDisplayIndex = tonumber(listingModel:GetAttribute("ListingDisplayIndex"))
			ListingTransport.completeAutopilot(player, record, listing, listingModel)
			-- SignalBehavior may defer the BindableEvent handler fired by completeAutopilot.
			-- Commit this exact W -> P transfer now, before deciding whether prestage failed;
			-- the later event callback is harmless because the old W trade is already gone.
			commitListing(player, record, listingModel, targetDisplayIndex, resolvedIndex)
			local current = DealerCar.active(player, resolvedIndex)
			if current ~= nil and current.tradeId == listing.tradeId then
				cancelPrestage()
			end
		end, function()
			return ListingTransport.isAutopilot(player, listing, listingModel)
		end, function()
			return ListingTransport.lockAutopilot(player, listing, listingModel)
		end, function()
			local prestaged, queueId = IncomingSellerQueue.prestageHead(player, record, resolvedIndex)
			if prestaged and queueId ~= nil then
				prestagedQueueId = queueId
			end
		end, usedParkingV2, listingStaffId)
	end

	local completed = runListing(nil)
	if not completed and StaffDirector.isSalesmanBusy(record) then
		local helperId = reserveListingHelper(player, record, listing.tradeId)
		if helperId ~= nil then
			local ok, result = pcall(runListing, helperId)
			releaseListingHelper(record, helperId, listing.tradeId)
			if not ok then
				warn(string.format("[TradeService] helper listing failed trade=%s helper=%s: %s", listing.tradeId, helperId, tostring(result)))
			else
				completed = result == true
			end
		end
	end
	if not completed then
		cancelPrestage()
		ListingTransport.endAutopilot(player, listing, listingModel)
		TradeService.refreshListPrompt(player, record)
	end
end

-- Compatibility API for old callers: refreshing is harmless, but cannot list remotely.
function TradeService.listCar(player: Player)
	local record = TycoonService.getForPlayer(player)
	if record ~= nil then
		TradeService.refreshListPrompt(player, record)
	end
end

function TradeService.handleSell(player: Player, action: string, tradeId: string?)
	local data = DataService.get(player)
	local record = TycoonService.getForPlayer(player)
	if data == nil or record == nil then
		return
	end

	local resolvedTradeId = if tradeId ~= nil then tradeId else ""
	if resolvedTradeId == "" then
		local activeCar = activeBuyerDisplay(player)
		resolvedTradeId = if activeCar ~= nil then activeCar.tradeId else ""
	end
	if resolvedTradeId == "" then
		return
	end

	local displayIndex = DealerCar.displayIndexForTrade(player, resolvedTradeId)
	local car = if displayIndex ~= nil then DealerCar.display(player, displayIndex) else nil
	if displayIndex == nil
		or car == nil
		or car.tradeId ~= resolvedTradeId
		or car.state ~= "Offer"
		or car.offered <= 0
	then
		return
	end

	local laneTradeId = laneTrade(player, displayIndex)
	if laneTradeId ~= nil and laneTradeId ~= car.tradeId then
		return
	end

	local pending = TradeContract.pendingFor(player, car.tradeId)
	if pending ~= nil then
		local pendingTradeId = tostring(pending.tradeId or "")
		local pendingIndex = tonumber(pending.slotIndex)
		if pendingTradeId ~= car.tradeId or (pendingIndex ~= nil and pendingIndex ~= displayIndex) then
			return
		end
		if laneTradeId == nil then
			claimBuyerLane(player, car, displayIndex)
		end
	else
		if laneTradeId == nil then
			claimBuyerLane(player, car, displayIndex)
		end
		local restored, restoredOffer = TradeContract.restoreFallback(
			player,
			tradePayload(player, car, displayIndex),
			car.offered,
			function(result)
				applyTradeResult(player, car, result, displayIndex)
			end
		)
		if not restored then
			return
		end
		if typeof(restoredOffer) == "number" and car.offered ~= restoredOffer then
			car.offered = restoredOffer
			DataService.save(player)
		end
	end

	if action == "askmore" then
		if car.haggleUsed then
			return
		end
		local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
		if tutorialDeal ~= nil and tutorialDeal.fixedOffer ~= nil then
			car.haggleUsed = true
			sendSellCard(
				player,
				car,
				string.format("No, $%d is all I've got.", math.floor(tutorialDeal.fixedOffer)),
				displayIndex
			)
			DealerCar.publish(player)
			return
		end
		local person = TownsfolkConfig.get(car.customerId)
		local bonus = if person ~= nil then person.askMore else DealerCarConfig.ASK_MORE_BONUS
		-- The same buttons serve every buyer; their authored character controls the result.
		if bonus <= 0 then
			car.haggleUsed = true
			sendSellCard(player, car, ASK_MORE_REFUSAL, displayIndex)
			DealerCar.publish(player)
			return
		end
		local raisedOffer = math.max(car.offered + 1, math.floor(car.offered * (1 + bonus)))
		if not TradeContract.raiseFallback(player, car.tradeId, raisedOffer) then
			return
		end
		car.haggleUsed = true
		car.offered = raisedOffer
		sendSellCard(player, car, nil, displayIndex)
		DealerCar.publish(player)
		return
	end
	if action == "refuse" then
		-- Tutorial sales are mandatory progression beats. The client hides KEEP THE CAR,
		-- and the server rejects stale or forged refuse requests for the tutorial deal.
		if DealerCarConfig.tutorialDeal(car.tutorialDealIndex) ~= nil then
			return
		end
		TradeContract.walkFallback(player, car.tradeId)
	elseif action == "accept" then
		TradeContract.acceptFallback(player, car.tradeId)
	end
end

-- Session restore ------------------------------------------------------------

function TradeService.resume(
	player: Player,
	record: Record,
	car: ActiveCarSave,
	slot: DealerCar.CarSlot?,
	slotIndex: number?
)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	-- Rolling tutorial saves may carry the previous deal-2/deal-3 model or an old deal-3
	-- offer. Normalize before any ticket/card/model restore so every surface sees one car.
	local normalizedTutorialCar = DealerCar.normalizeTutorialCar(car)
	if car.tradeId == "" then
		car.tradeId = TradeContract.newTradeId(player, car.templateId)
	end
	-- Snapshot only after a legacy empty trade id has also been rebuilt, so migration cannot
	-- accidentally persist the replacement content with an empty identity.
	if normalizedTutorialCar then
		DataService.save(player)
	end

	local inferredDisplayIndex = if slot == "working"
		then nil
		else slotIndex or DealerCar.displayIndexForTrade(player, car.tradeId)
	local resolvedSlot: DealerCar.CarSlot = if slot ~= nil
		then slot
		elseif inferredDisplayIndex ~= nil then "display"
		else "working"
	local inferredWorkingIndex = if resolvedSlot == "working"
		then slotIndex or DealerCar.workingIndexForTrade(player, car.tradeId)
		else nil

	if resolvedSlot == "display" then
		local resolvedIndex = inferredDisplayIndex
		local current = if resolvedIndex ~= nil then DealerCar.display(player, resolvedIndex) else nil
		if resolvedIndex == nil or current == nil or current.tradeId ~= car.tradeId then
			return
		end

		-- The payout ledger wins the only dangerous crash window. Release only its exact
		-- paid slot, leaving the other display and the working lane untouched.
		if data.resolvedTrades[car.tradeId] == true then
			hideSellCard(player, car, resolvedIndex)
			TradeContract.cancel(player, car.tradeId)
			if laneTrade(player, resolvedIndex) == car.tradeId then
				clearBuyer(player, resolvedIndex)
				releaseBuyerLane(player, car.tradeId, resolvedIndex)
			end
			local _, staleModel = DealerCar.removeDisplayStock(player, resolvedIndex, car.tradeId)
			if staleModel ~= nil then
				staleModel:Destroy()
			end
			DataService.save(player)
			TradeService.armBuyerTimer(player)
			return
		end

		if car.state == "Sold" then
			-- An unresolved Sold record was never committed. Make it negotiable again.
			car.state = if car.offered > 0 then "Offer" else "Listed"
		end

		local function queueAsListed()
			hideSellCard(player, car, resolvedIndex)
			car.state = "Listed"
			car.offered = 0
			car.haggleUsed = false
			DataService.save(player)
			TradeService.armBuyerTimer(player, car, resolvedIndex)
		end

		if car.state == "Listed" then
			TradeService.armBuyerTimer(player, car, resolvedIndex)
		elseif car.state == "Offer" then
			if car.offered <= 0 then
				queueAsListed()
			else
				TradeService.armBuyerTimer(player, car, resolvedIndex)
				sendSellCard(player, car, nil, resolvedIndex)
			end
		end
		print(string.format(
			"[TradeService] resume display %s slot=%d car=%s state=%s offered=%d",
			player.Name,
			resolvedIndex,
			car.templateId,
			car.state,
			car.offered
		))
		return
	end

	local resolvedWorkingIndex = inferredWorkingIndex
	if resolvedWorkingIndex == nil
		or DealerCar.active(player, resolvedWorkingIndex) ~= car
	then
		return
	end
	if car.state == "Incoming" then
		if sellerTradeId[player] == nil or sellerTradeId[player] == car.tradeId then
			sellerWorkingIndex[player] = resolvedWorkingIndex
			sellerTradeId[player] = car.tradeId
			DealerCar.spawn(player, record, true, "working", resolvedWorkingIndex)
		elseif car.cost > 0 then
			-- A paid legacy delivery must never be discarded; restore it as owned stock.
			car.state = "Junk"
			DealerCar.spawn(player, record, false, "working", resolvedWorkingIndex)
		else
			local _, staleModel = DealerCar.removeWorking(player, resolvedWorkingIndex, car.tradeId)
			if staleModel ~= nil then
				staleModel:Destroy()
			end
			return
		end
	elseif car.state == "Offered" then
		if sellerTradeId[player] == nil or sellerTradeId[player] == car.tradeId then
			sellerWorkingIndex[player] = resolvedWorkingIndex
			sellerTradeId[player] = car.tradeId
			local staffHandlesDeal = listingAutomated(player)
			spawnSeller(player, record, car, resolvedWorkingIndex, not staffHandlesDeal)
			if staffHandlesDeal then
				patienceToken[player] = (patienceToken[player] or 0) + 1
				local staffToken = patienceToken[player]
				task.delay(1.25, function()
					local current = DealerCar.active(player, resolvedWorkingIndex)
					local currentData = DataService.get(player)
					if patienceToken[player] == staffToken
						and current == car
						and car.state == "Offered"
						and sellerTradeId[player] == car.tradeId
						and currentData ~= nil
					then
						local action = if currentData.cash >= car.ask then "buy" else "refuse"
						TradeService.handleBuy(player, action, car.tradeId, resolvedWorkingIndex)
					end
				end)
			end
		else
			local _, staleModel = DealerCar.removeWorking(player, resolvedWorkingIndex, car.tradeId)
			if staleModel ~= nil then
				staleModel:Destroy()
			end
			return
		end
	elseif car.state == "Repairing" and CarVisuals.allPartsRepaired(car.parts) then
		car.state = "Ready"
	end
	print(string.format(
		"[TradeService] resume working %s W=%d car=%s state=%s ask=%d",
		player.Name,
		resolvedWorkingIndex,
		car.templateId,
		car.state,
		car.ask
	))
end

function TradeService.resendOpenCard(player: Player)
	local display, displayIndex = activeBuyerDisplay(player)
	if display == nil or display.state ~= "Offer" or display.offered <= 0 then
		display = nil
		displayIndex = nil
		for index = 1, DealerCar.displayCapacity(player) do
			local candidate = DealerCar.display(player, index)
			if candidate ~= nil and candidate.state == "Offer" and candidate.offered > 0 then
				display = candidate
				displayIndex = index
				break
			end
		end
	end
	if display ~= nil and displayIndex ~= nil then
		if buyerAutomated(player) then
			hideSellCard(player, display, displayIndex)
		else
			sendSellCard(player, display, nil, displayIndex)
		end
	end

	local workingIndex = sellerWorkingIndex[player]
	local working = if workingIndex ~= nil then DealerCar.active(player, workingIndex) else nil
	if working ~= nil
		and working.state == "Offered"
		and sellerTradeId[player] == working.tradeId
	then
		-- A live seller is always entered through SellerDealPrompt. Re-sending the
		-- world card during PlayerAdded races the prompt, opens Dialogue before the
		-- first tap, and leaves the arrival interaction suppressed. Clear any stale
		-- client card; decorateSeller remains the single explicit entry point.
		hideBuyCard(player, working, workingIndex)
	else
		local list = offers[player]
		if usePhone(player) and list ~= nil then
			local slot = picked[player]
			local offer = if slot ~= nil then list[slot] else nil
			if offer ~= nil then
				sendFenceCard(player, offer)
			else
				sendOfferList(player)
			end
		end
	end
end

-- Called when a pad purchase may have unlocked the phone mix.
function TradeService.channelChanged(player: Player, record: Record)
	if buyerAutomated(player) then
		local display, displayIndex = activeBuyerDisplay(player)
		if display ~= nil and displayIndex ~= nil then
			hideSellCard(player, display, displayIndex)
		end
	end
	if not usePhone(player) and fenceTradeId[player] ~= nil then
		hideBuyCard(player, nil, fenceWorkingIndex[player])
		clearFenceSession(player)
	end
	if not sourceBusy(player) and DealerCar.availableWorkingIndex(player) ~= nil then
		TradeService.startIncoming(player, record, 0)
	end
end

function TradeService.forget(player: Player)
	stopQueuePump(player)
	IncomingSellerQueue.clear(player)
	queueRecord[player] = nil
	queueSerial[player] = nil
	queueNextAt[player] = nil
	clearSeller(player)
	clearBuyer(player)
	TradeContract.cancel(player)
	buyerToken[player] = nil
	buyerTradeId[player] = nil
	buyerLaneStartedAt[player] = nil
	buyerCursor[player] = nil
	ListingTransport.forget(player)
	patienceToken[player] = nil
	incomingToken[player] = nil
	sourcePending[player] = nil
	reservedWorking[player] = nil
	sellerWorkingIndex[player] = nil
	sellerTradeId[player] = nil
	clearFenceSession(player)
end

function TradeService.init()
	if not buyerWatchdogStarted then
		buyerWatchdogStarted = true
		task.spawn(function()
			while buyerWatchdogStarted do
				task.wait(3)
				for _, player in Players:GetPlayers() do
					TradeService.armBuyerTimer(player)
				end
			end
		end)
	end
	ListingTransport.arrived.Event:Connect(function(
		player: Player,
		model: Model,
		displayIndex: number?,
		workingIndex: number?
	)
		local record = TycoonService.getForPlayer(player)
		if record ~= nil then
			commitListing(player, record, model, displayIndex, workingIndex)
		end
	end)

	DealerCar.arrived.Event:Connect(function(
		player: Player,
		record: Record,
		workingIndex: number?
	)
		local car = if workingIndex ~= nil then DealerCar.active(player, workingIndex) else nil
		if workingIndex == nil or car == nil or car.state ~= "Incoming" then
			return
		end
		if car.cost > 0 then
			acceptDelivery(player, record, workingIndex)
		else
			local reminderTradeId = car.tradeId
			local reminderCarName = DealerCarConfig.displayName(car.templateId)
			local reminderSellerName = sellerName(car)
			TradeService.presentIncoming(player, record, workingIndex)
			task.delay(SELLER_REMINDER_DELAY, function()
				local current = DealerCar.active(player, workingIndex)
				local model = DealerCar.model(player, "working", workingIndex)
				if player.Parent == Players
					and not listingAutomated(player)
					and current ~= nil
					and current.tradeId == reminderTradeId
					and current.state == "Offered"
					and sellerTradeId[player] == reminderTradeId
					and playerCoveredDeal[player] ~= true
					and model ~= nil
					and model:GetAttribute("Arriving") ~= true
				then
					Remotes.SellerArrivalNotice:FireClient(player, {
						eventId = string.format("seller-waiting:%s:%d", reminderTradeId, workingIndex),
						tradeId = reminderTradeId,
						workingIndex = workingIndex,
						carName = reminderCarName,
						sellerName = reminderSellerName,
					})
				end
			end)
		end
	end)
end

return TradeService
