--!strict

-- The dealer owns two indexed working lanes and up to six Used Cars display lanes.
-- Negotiations live in TradeService; this module owns slot state and presentation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TownsfolkConfig = require(ReplicatedStorage.TownsfolkConfig)
local LuckConfig = require(ReplicatedStorage.LuckConfig)
local DataService = require(script.Parent.Parent.DataService)
local OwnerCarPipeline = require(script.Parent.Parent.OwnerCarPipeline)
local GameplayEvents = require(script.Parent.Parent.GameplayEvents)
local TradeContract = require(script.Parent.Parent.TradeContract)
local TycoonService = require(script.Parent.Parent.TycoonService)
local LotSlots = require(script.Parent.LotSlots)
local RoadTraffic = require(script.Parent.RoadTraffic)
local CarVisuals = require(script.Parent.CarVisuals)
local LotNpc = require(script.Parent.LotNpc)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord
type ActiveCarSave = DataService.ActiveCarSave
type IncomingVariant = LuckConfig.IncomingVariant

local DealerCar = {}

local BODY_DAMAGE_TEMPLATES: { [string]: boolean } = {
	Rusty = true,
	Nissho = true,
	Wronkler = true,
}

local function bodyDamageTemplate(templateId: string): boolean
	return BODY_DAMAGE_TEMPLATES[templateId] == true
end

local DRIVER_NAME = "CarDriver"

-- Fires (player, state, slot, slotIndex) so automation can react without polling.
DealerCar.stateChanged = Instance.new("BindableEvent")
-- Fires (player, record, workingIndex) once a car has finished driving in and parked.
DealerCar.arrived = Instance.new("BindableEvent")
-- Fires (player, workingIndex) when a player takes a repair job from automation.
DealerCar.manualRepairStarted = Instance.new("BindableEvent")

export type CarSlot = "working" | "display"
type PayloadSlot = CarSlot | "processing"

local workingModels: { [number]: { [Player]: Model } } = {}
local displayModels: { [number]: { [Player]: Model } } = {}
-- A W -> P drive owns its destination before the save transfer happens. Without this
-- runtime lease, another trade can see the still-empty save slot and park on top of it.
local displayReservations: { [number]: { [Player]: string } } = {}
local awaitingDisplayModels: { [number]: { [Player]: Model } } = { [1] = {}, [2] = {} }
-- One completed trade may have exactly one physical drive from the Used Cars queue/service
-- handoff to a display pad. The lease is runtime-only: after a restart AwaitingDisplay in
-- the save remains the recovery source of truth and may be planned again safely.
local awaitingParking: { [Player]: { [string]: boolean } } = {}
local driveToken: { [number]: { [Player]: number } } = {}
local repairing: { [number]: { [Player]: boolean } } = {}
local manualRepairUntil: { [number]: { [Player]: number } } = {}
-- While W->processing is awaiting its critical write, the save slot is nil but must not be
-- offered to another seller. The guard is released only after commit success or deep rollback.
local workingTransition: { [number]: { [Player]: boolean } } = {}
for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
	workingModels[index] = {}
	driveToken[index] = {}
	repairing[index] = {}
	manualRepairUntil[index] = {}
	workingTransition[index] = {}
end
for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
	displayModels[index] = {}
	displayReservations[index] = {}
end
local MANUAL_REPAIR_IDLE_SECONDS = 15
-- Dirt is a per-arrival condition, not a property shared by every stock car. The chance
-- itself wanders so consecutive arrivals do not settle into a visibly fixed cadence.
local DIRTY_CHANCE_MIN = 0.35
local DIRTY_CHANCE_MAX = 0.80
local OIL_LEAK_CHANCE_MIN = 0.30
local OIL_LEAK_CHANCE_MAX = 0.70
-- A Wheels repair represents one physically absent wheel, never generic tyre wear.
-- The wandering 35-65% roll averages to an even split while avoiding a fixed cadence.
local MISSING_WHEEL_CHANCE_MIN = 0.35
local MISSING_WHEEL_CHANCE_MAX = 0.65

function DealerCar.hasParkingLease(player: Player, tradeId: string): boolean
	local active = awaitingParking[player]
	return active ~= nil and active[tradeId] == true
end

function DealerCar.acquireParkingLease(player: Player, tradeId: string): boolean
	if tradeId == "" or DealerCar.hasParkingLease(player, tradeId) then
		return false
	end
	local active = awaitingParking[player]
	if active == nil then
		active = {}
		awaitingParking[player] = active
	end
	active[tradeId] = true
	return true
end

function DealerCar.releaseParkingLease(player: Player, tradeId: string)
	local active = awaitingParking[player]
	if active == nil then
		return
	end
	active[tradeId] = nil
	if next(active) == nil then
		awaitingParking[player] = nil
	end
end

local function rollFloatingChance(minimum: number, maximum: number): boolean
	local chance = minimum + math.random() * (maximum - minimum)
	return math.random() < chance
end

local function rollDirtyCondition(): boolean
	return rollFloatingChance(DIRTY_CHANCE_MIN, DIRTY_CHANCE_MAX)
end

local function rollOilLeakCondition(): boolean
	return rollFloatingChance(OIL_LEAK_CHANCE_MIN, OIL_LEAK_CHANCE_MAX)
end

local function rollMissingWheelCondition(): boolean
	return rollFloatingChance(MISSING_WHEEL_CHANCE_MIN, MISSING_WHEEL_CHANCE_MAX)
end

function DealerCar.rollIncomingCondition(): DataService.VehicleConditionSave
	return {
		dirty = rollDirtyCondition(),
		oilLeak = rollOilLeakCondition(),
		wheelsPresent = not rollMissingWheelCondition(),
	}
end

local function resolveWorkingIndex(index: number?): number?
	local resolved = index or 1
	return if resolved >= 1 and resolved <= DealerCarConfig.MAX_WORKING_SLOTS then resolved else nil
end

local function resolveDisplayIndex(index: number?): number?
	local resolved = index or 1
	return if resolved >= 1 and resolved <= DealerCarConfig.MAX_DISPLAY_SLOTS then resolved else nil
end

local function resolveSlotIndex(slot: CarSlot, index: number?): number?
	return if slot == "display" then resolveDisplayIndex(index) else resolveWorkingIndex(index)
end

local function displayModelMap(index: number): { [Player]: Model }
	return displayModels[index]
end

local function modelMap(slot: CarSlot, index: number): { [Player]: Model }
	return if slot == "display" then displayModels[index] else workingModels[index]
end

function DealerCar.pads(player: Player): { [string]: boolean }
	local data = DataService.get(player)
	return if data ~= nil then data.pads else {}
end

function DealerCar.hasPad(player: Player, padId: string): boolean
	return DealerCar.pads(player)[padId] == true
end

function DealerCar.workingCapacity(player: Player): number
	local data = DataService.get(player)
	return if data ~= nil then DataService.workingCapacityForPads(data.pads) else 1
end

function DealerCar.displayCapacity(player: Player): number
	local data = DataService.get(player)
	return if data ~= nil then DataService.displayCapacityForPads(data.pads) else 1
end

function DealerCar.repairAutomated(player: Player, workingIndex: number?): boolean
	local padId = DealerCarConfig.autoRepairPad(workingIndex)
	return padId ~= nil and DealerCar.hasPad(player, padId)
end

function DealerCar.mechanicPaused(player: Player, workingIndex: number?): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	return resolvedIndex ~= nil and (manualRepairUntil[resolvedIndex][player] or 0) > os.clock()
end

function DealerCar.active(player: Player, workingIndex: number?): ActiveCarSave?
	local data = DataService.get(player)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	return if data ~= nil and resolvedIndex ~= nil then DataService.getWorking(data, resolvedIndex) else nil
end

function DealerCar.processing(player: Player, tradeId: string): ActiveCarSave?
	local data = DataService.get(player)
	return if data ~= nil then (select(1, DataService.getProcessing(data, tradeId))) else nil
end

function DealerCar.processingCars(player: Player): { ActiveCarSave }
	local data = DataService.get(player)
	return if data ~= nil then data.processingCars else {}
end

function DealerCar.processingCount(player: Player): number
	return #DealerCar.processingCars(player)
end

function DealerCar.availableProcessing(player: Player): boolean
	return DealerCar.processingCount(player) < DataService.processingCapacity()
end

function DealerCar.availableWorkingIndex(player: Player): number?
	if DataService.get(player) == nil then
		return nil
	end
	for index = 1, DealerCar.workingCapacity(player) do
		if DealerCar.active(player, index) == nil and workingTransition[index][player] ~= true then
			return index
		end
	end
	return nil
end

function DealerCar.hasAnyWorking(player: Player): boolean
	for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		if DealerCar.active(player, index) ~= nil then
			return true
		end
	end
	return false
end

function DealerCar.workingIndexForTrade(player: Player, tradeId: string): number?
	if tradeId == "" then
		return nil
	end
	for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		local car = DealerCar.active(player, index)
		if car ~= nil and car.tradeId == tradeId then
			return index
		end
	end
	return nil
end

function DealerCar.display(player: Player, displayIndex: number?): ActiveCarSave?
	local data = DataService.get(player)
	local resolvedIndex = resolveDisplayIndex(displayIndex)
	return if data ~= nil and resolvedIndex ~= nil then DataService.getDisplay(data, resolvedIndex) else nil
end

function DealerCar.displayReservation(player: Player, displayIndex: number?): string?
	local resolvedIndex = resolveDisplayIndex(displayIndex)
	return if resolvedIndex ~= nil then displayReservations[resolvedIndex][player] else nil
end

function DealerCar.reserveDisplay(player: Player, displayIndex: number?, tradeId: string): boolean
	local resolvedIndex = resolveDisplayIndex(displayIndex)
	if resolvedIndex == nil
		or tradeId == ""
		or resolvedIndex > DealerCar.displayCapacity(player)
		or DealerCar.display(player, resolvedIndex) ~= nil
	then
		return false
	end
	local current = displayReservations[resolvedIndex][player]
	if current ~= nil and current ~= tradeId then
		return false
	end
	displayReservations[resolvedIndex][player] = tradeId
	return true
end

function DealerCar.releaseDisplay(player: Player, displayIndex: number?, tradeId: string?)
	local resolvedIndex = resolveDisplayIndex(displayIndex)
	if resolvedIndex == nil then
		return
	end
	local current = displayReservations[resolvedIndex][player]
	if tradeId == nil or current == tradeId then
		displayReservations[resolvedIndex][player] = nil
	end
end

function DealerCar.availableDisplayIndex(player: Player): number?
	if DataService.get(player) == nil then
		return nil
	end
	for index = 1, DealerCar.displayCapacity(player) do
		if DealerCar.display(player, index) == nil and displayReservations[index][player] == nil then
			return index
		end
	end
	return nil
end

function DealerCar.hasAnyDisplay(player: Player): boolean
	for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
		if DealerCar.display(player, index) ~= nil then
			return true
		end
	end
	return false
end

function DealerCar.displayIndexForTrade(player: Player, tradeId: string): number?
	if tradeId == "" then
		return nil
	end
	for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
		local car = DealerCar.display(player, index)
		if car ~= nil and car.tradeId == tradeId then
			return index
		end
	end
	return nil
end

local function carForSlot(player: Player, slot: CarSlot, slotIndex: number): ActiveCarSave?
	return if slot == "display" then DealerCar.display(player, slotIndex) else DealerCar.active(player, slotIndex)
end

function DealerCar.model(player: Player, slot: CarSlot?, slotIndex: number?): Model?
	local resolvedSlot: CarSlot = slot or "working"
	local resolvedIndex = resolveSlotIndex(resolvedSlot, slotIndex)
	if resolvedIndex == nil then
		return nil
	end
	local map = modelMap(resolvedSlot, resolvedIndex)
	local model = map[player]
	if model ~= nil and model.Parent == nil then
		map[player] = nil
		return nil
	end
	return model
end

function DealerCar.displayModel(player: Player, index: number?): Model?
	return DealerCar.model(player, "display", index)
end

function DealerCar.isArriving(player: Player, workingIndex: number?): boolean
	local model = DealerCar.model(player, "working", workingIndex)
	return model ~= nil and model:GetAttribute("Arriving") == true
end

export type ValueBreakdown = {
	baseValue: number,
	partsValue: number,
	acquisitionValue: number,
	restoredValue: number,
	repairValue: number,
	repairProgress: number,
	repairGains: { [string]: number },
	valueAfterRepairs: number,
	calculatedValue: number,
	listingMarkup: number,
	listedPrice: number,
	-- Compatibility aliases for the current client while Gio replaces its card.
	base: number,
	parts: number,
	signMultiplier: number,
	serviceMultiplier: number,
	serviceStages: { OwnerCarPipeline.StageBreakdown },
	value: number,
}

local function ensureTowCondition(car: ActiveCarSave, sourceModel: Model?): boolean
	local sourceSeller = if sourceModel ~= nil then sourceModel:GetAttribute("SellerId") else nil
	local towStock = car.condition.towStock == true
		or car.sellerId == "TowTruckTony"
		or (sourceModel ~= nil and sourceModel:GetAttribute("TowStock") == true)
		or sourceSeller == "TowTruckTony"
	if not towStock then
		return false
	end
	car.condition.towStock = true
	if sourceSeller == "TowTruckTony" then
		car.sellerId = "TowTruckTony"
	end
	car.condition.wheelsPresent = false
	if car.parts.Wheels ~= true then
		local recovered: { string } = {}
		local encoded = if sourceModel ~= nil then sourceModel:GetAttribute("DealerMissingWheelCorners") else nil
		if typeof(encoded) == "string" then
			for corner in string.gmatch(encoded :: string, "[^,]+") do
				if corner == "WheelFL" or corner == "WheelFR" or corner == "WheelRL" or corner == "WheelRR" then
					table.insert(recovered, corner)
				end
			end
		end
		if #recovered > 0 then
			car.condition.missingWheels = recovered
		elseif car.condition.missingWheels == nil then
			car.condition.missingWheels = { "WheelFL", "WheelFR" }
		end
	end
	return true
end

local function repairWeight(car: ActiveCarSave, partId: string, baseWeight: number): number
	if not ensureTowCondition(car, nil) then
		return baseWeight
	end
	if partId == "Wheels" then
		local missingCount = if car.condition.missingWheels ~= nil then #car.condition.missingWheels else 2
		return math.floor(baseWeight * (if missingCount >= 3 then 2.75 else 2.0) + 0.5)
	elseif partId == "Engine" then
		return math.floor(baseWeight * 2.25 + 0.5)
	elseif partId == "Body" then
		return math.floor(baseWeight * 1.5 + 0.5)
	end
	return baseWeight
end

-- The price paid is the honest starting value. The old fully-repaired economy remains the
-- ceiling, but the whole spread between purchase and ceiling is earned by fixing defects.
-- Tow recovery is deliberately extreme stock: more missing hardware creates a larger repair
-- bill and a larger resale-value gain while still travelling through the normal deal contract.
function DealerCar.valueBreakdown(player: Player, car: ActiveCarSave): ValueBreakdown
	ensureTowCondition(car, nil)
	local template = CarVisuals.template(car.templateId)
	local tutorialDeal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	local fullPartsValue = 0
	local manualPartSet: { [string]: boolean } = {}
	if tutorialDeal ~= nil then
		for _, partId in tutorialDeal.manualParts do
			manualPartSet[partId] = true
		end
	end

	local repairParts: { { config: any, weight: number } } = {}
	local totalRepairWeight = 0
	local completedRepairWeight = 0
	for _, part in DealerCarConfig.PARTS do
		local weight = repairWeight(car, part.id, part.valueBonus)
		fullPartsValue += weight
		if tutorialDeal == nil or manualPartSet[part.id] == true then
			table.insert(repairParts, { config = part, weight = weight })
			totalRepairWeight += weight
			if car.parts[part.id] == true then
				completedRepairWeight += weight
			end
		end
	end

	local acquisitionValue = if car.cost > 0
		then math.max(1, math.floor(car.cost))
		elseif car.ask > 0
		then math.max(1, math.floor(car.ask))
		else math.max(1, math.floor(template.baseCost))
	local serviceMultiplier = if tutorialDeal ~= nil then 1 else OwnerCarPipeline.valueMultiplier(car)
	local serviceStages = if tutorialDeal ~= nil then {} else OwnerCarPipeline.stageBreakdown(car)
	local signMultiplier = if tutorialDeal ~= nil then 1 else TycoonConfig.valueMultiplier(DealerCar.pads(player))
	local listingMarkup = math.max(0, signMultiplier - 1)
	local rawRepairTarget = if tutorialDeal ~= nil and tutorialDeal.fixedValue ~= nil
		then math.max(1, tutorialDeal.fixedValue)
		else math.max(1, template.baseValue + fullPartsValue)
	local repairCeiling = math.max(acquisitionValue, math.floor(rawRepairTarget * signMultiplier))
	local repairProgress = if totalRepairWeight > 0
		then math.clamp(completedRepairWeight / totalRepairWeight, 0, 1)
		else 1

	local repairGains: { [string]: number } = {}
	local repairPool = math.max(0, repairCeiling - acquisitionValue)
	local cumulativeWeight = 0
	local allocatedGain = 0
	local completedRepairGain = 0
	for _, repairPart in repairParts do
		local part = repairPart.config
		cumulativeWeight += repairPart.weight
		local cumulativeGain = if totalRepairWeight > 0
			then math.floor(repairPool * cumulativeWeight / totalRepairWeight + 0.5)
			else 0
		local partGain = math.max(0, cumulativeGain - allocatedGain)
		repairGains[part.id] = partGain
		if car.parts[part.id] == true then
			completedRepairGain += partGain
		end
		allocatedGain = cumulativeGain
	end

	local restoredValue = acquisitionValue + completedRepairGain
	local calculatedValue = restoredValue * serviceMultiplier
	local listedPrice = math.max(1, math.floor(calculatedValue))
	local valueAfterRepairs = math.max(1, math.floor(repairCeiling * serviceMultiplier))

	-- A listing is a contract: later value-pad purchases must not reprice a car that is
	-- already standing on P1/P2. The saved listing price drives the billboard, cards and payout.
	if (tutorialDeal == nil or tutorialDeal.fixedValue == nil)
		and (car.state == "Listed" or car.state == "Offer" or car.state == "Sold")
		and car.listedPrice > 0
	then
		listedPrice = math.max(1, math.floor(car.listedPrice))
	end

	local partsValue = math.max(0, restoredValue - acquisitionValue)
	return {
		baseValue = acquisitionValue,
		partsValue = partsValue,
		acquisitionValue = acquisitionValue,
		restoredValue = restoredValue,
		repairValue = completedRepairGain,
		repairProgress = repairProgress,
		repairGains = repairGains,
		valueAfterRepairs = valueAfterRepairs,
		calculatedValue = calculatedValue,
		listingMarkup = listingMarkup,
		listedPrice = listedPrice,
		base = acquisitionValue,
		parts = partsValue,
		signMultiplier = signMultiplier,
		serviceMultiplier = serviceMultiplier,
		serviceStages = serviceStages,
		value = listedPrice,
	}
end

function DealerCar.value(player: Player, car: ActiveCarSave): number
	return DealerCar.valueBreakdown(player, car).value
end

function DealerCar.variantLabel(car: ActiveCarSave): string
	local pipeline = OwnerCarPipeline.ensure(car)
	local mods = {}
	if car.paintHue ~= nil then
		table.insert(mods, "CUSTOM PAINT")
	end
	if pipeline.completed.tuningBody == true then
		table.insert(mods, "BODY KIT + TINT")
	end
	if car.neonColorId ~= nil then
		table.insert(mods, "NEON")
	end
	return table.concat(mods, " · ")
end

-- Seller cards use the same authoritative ceiling as the owned-car value breakdown.
function DealerCar.valueAfterRepairs(player: Player, car: ActiveCarSave): number
	return DealerCar.valueBreakdown(player, car).valueAfterRepairs
end

-- One rolling window used Wronkler for deal 2 and Nissho for deal 3. There is no schema
-- bit to migrate, so the legacy template id is the durable discriminator. Preserve how many
-- authored manual repairs the player completed, then project that count onto the new deal's
-- manual order. This avoids treating an old pre-repaired part as new player progress.
local LEGACY_TUTORIAL_MANUAL_PARTS: { [number]: { [string]: { string } } } = {
	[2] = {
		Wronkler = { "Body", "Wheels" },
	},
	[3] = {
		Nissho = { "Engine" },
	},
}

local function completedLegacyTutorialRepairs(car: ActiveCarSave, manualParts: { string }): number
	if car.state == "Ready"
		or car.state == "Listed"
		or car.state == "Offer"
		or car.state == "Sold"
	then
		return #manualParts
	end
	-- Seller-side states and a newly purchased Junk car have no completed hands-on work.
	-- In particular, their authored pre-repaired bits must not count as repairs.
	if car.state == "Incoming" or car.state == "Offered" or car.state == "Junk" then
		return 0
	end
	local completed = 0
	for _, partId in manualParts do
		if car.parts[partId] == true then
			completed += 1
		end
	end
	return math.clamp(completed, 0, #manualParts)
end

local function tutorialListedPrice(car: ActiveCarSave, deal: DealerCarConfig.TutorialDeal): number
	if deal.fixedValue ~= nil then
		return math.max(1, math.floor(deal.fixedValue))
	end
	local template = DealerCarConfig.templateById(deal.carId)
	local value = if template ~= nil then template.baseValue else 1
	for _, part in DealerCarConfig.PARTS do
		if car.parts[part.id] == true then
			value += part.valueBonus
		end
	end
	return math.max(1, math.floor(value))
end

local function migratedTutorialOffer(dealIndex: number, listedPrice: number): number
	if dealIndex == 1 then
		return 210
	elseif dealIndex == 2 then
		return math.max(259, math.floor(listedPrice * 0.95))
	end
	return math.max(1, math.floor(listedPrice * 0.92))
end

-- Idempotently normalizes a saved tutorial car. Trade identity, acquisition cost, seller and
-- buyer stay untouched; only authored car/content fields are migrated. Returning true lets
-- restore callers persist the rolling conversion without adding a save-schema field.
function DealerCar.normalizeTutorialCar(car: ActiveCarSave): boolean
	local deal = DealerCarConfig.tutorialDeal(car.tutorialDealIndex)
	if deal == nil then
		return false
	end
	local changed = false
	local templateChanged = car.templateId ~= deal.carId
	if templateChanged then
		local legacyByTemplate = LEGACY_TUTORIAL_MANUAL_PARTS[car.tutorialDealIndex]
		local legacyManual = if legacyByTemplate ~= nil then legacyByTemplate[car.templateId] else nil
		-- Unknown rolling variants fall back to the new manual list; the known Wronkler/Nissho
		-- window always takes the explicit old authored lists above.
		local sourceManual: { string } = legacyManual or (deal.manualParts :: any)
		local completed = completedLegacyTutorialRepairs(car, sourceManual)
		local rebuilt = DealerCarConfig.tutorialParts(car.tutorialDealIndex)
		for index = 1, math.min(completed, #deal.manualParts) do
			rebuilt[deal.manualParts[index]] = true
		end
		car.templateId = deal.carId
		car.parts = rebuilt
		car.tutorialWildcard = deal.wildcard == true
		changed = true
	else
		for partId, repaired in deal.preRepaired do
			if repaired == true and car.parts[partId] ~= true then
				car.parts[partId] = true
				changed = true
			end
		end
		if car.tutorialWildcard ~= (deal.wildcard == true) then
			car.tutorialWildcard = deal.wildcard == true
			changed = true
		end
	end

	-- Tutorial defects are exactly the authored Body/Wheels/Engine work. Old condition rolls
	-- must not survive onto the replacement model and contradict Rex/the objective card.
	if car.condition.dirty == true then
		car.condition.dirty = false
		changed = true
	end
	if car.condition.oilLeak == true then
		car.condition.oilLeak = false
		changed = true
	end

	if car.state == "Repairing" and CarVisuals.allPartsRepaired(car.parts) then
		car.state = "Ready"
		changed = true
	end

	local displayState = car.state == "Listed" or car.state == "Offer" or car.state == "Sold"
	if displayState then
		local listedPrice = tutorialListedPrice(car, deal)
		if car.listedPrice ~= listedPrice then
			car.listedPrice = listedPrice
			changed = true
		end
		if deal.fixedOffer ~= nil and (car.state == "Offer" or car.state == "Sold") then
			local fixedOffer = math.max(1, math.floor(deal.fixedOffer))
			if car.offered ~= fixedOffer then
				car.offered = fixedOffer
				changed = true
			end
		elseif templateChanged and car.state == "Offer" then
			-- The saved buyer was pricing the legacy model. Keep the exact buyer/trade lane, but
			-- replace its amount with the normal authoritative offer for the authored car.
			local offer = migratedTutorialOffer(car.tutorialDealIndex, listedPrice)
			if car.offered ~= offer then
				car.offered = offer
				changed = true
			end
		end
	elseif car.listedPrice ~= 0 then
		car.listedPrice = 0
		changed = true
	end
	return changed
end

-- One authoritative gate is shared by every staff-controlled listing path.
-- Idle means NPCService has not yet made the authoritative service decision. It must never
-- be listable: otherwise a second W car can bypass a busy helper and sell dirty/untuned.
-- Early-game/no-service cars are promptly promoted to an empty complete plan by
-- markServiceRollDone; queued/servicing cars remain reserved until every required stage ends.
function DealerCar.isReadyForListing(car: ActiveCarSave?): boolean
	if car == nil or car.state ~= "Ready" or car.atBay == true then
		return false
	end
	local state = OwnerCarPipeline.ensure(car).state
	return state == "complete"
end

-- Bay trips -------------------------------------------------------------------

-- Snapshot only the pipeline-owned fields so a failed critical write can roll this
-- transition back without touching price, parts, listing or other concurrent car state.
local function snapshotPipelineMutation(car: ActiveCarSave): any
	local pipeline = OwnerCarPipeline.ensure(car)
	local completed: { [string]: boolean } = {}
	for stage, done in pipeline.completed do
		completed[stage] = done
	end
	local skipped: { [string]: string } = {}
	for stage, reason in pipeline.skipped do
		skipped[stage] = reason
	end
	local rawCar = car :: any
	return {
		pipeline = {
			revision = pipeline.revision,
			state = pipeline.state,
			plan = table.clone(pipeline.plan),
			nextIndex = pipeline.nextIndex,
			completed = completed,
			skipped = skipped,
			currentStage = pipeline.currentStage,
			currentSlot = pipeline.currentSlot,
			queuedAt = pipeline.queuedAt,
			lastQueuedWarningAt = pipeline.lastQueuedWarningAt,
			escortId = pipeline.escortId,
			routingV2 = {
				service = pipeline.routingV2.service,
				usedParking = pipeline.routingV2.usedParking,
				tow = pipeline.routingV2.tow,
			},
		},
		condition = {
			dirty = car.condition.dirty == true,
			oilLeak = car.condition.oilLeak == true,
		},
		serviced = car.serviced,
		atBay = car.atBay,
		serviceRollDone = car.serviceRollDone,
		serviceQueuedAt = car.serviceQueuedAt,
		serviceCost = car.serviceCost,
		serviceCostPaid = car.serviceCostPaid,
		washed = rawCar.washed,
		tunedDyno = rawCar.tunedDyno,
		tunedBody = rawCar.tunedBody,
		tunedPaint = rawCar.tunedPaint,
		processingStatus = car.processingStatus,
		sourceWorkingIndex = car.sourceWorkingIndex,
	}
end

local function restorePipelineMutation(car: ActiveCarSave, snapshot: any)
	local rawCar = car :: any
	rawCar.pipeline = snapshot.pipeline
	rawCar.condition = snapshot.condition
	rawCar.serviced = snapshot.serviced
	rawCar.atBay = snapshot.atBay
	rawCar.serviceRollDone = snapshot.serviceRollDone
	rawCar.serviceQueuedAt = snapshot.serviceQueuedAt
	rawCar.serviceCost = snapshot.serviceCost
	rawCar.serviceCostPaid = snapshot.serviceCostPaid
	rawCar.washed = snapshot.washed
	rawCar.tunedDyno = snapshot.tunedDyno
	rawCar.tunedBody = snapshot.tunedBody
	rawCar.tunedPaint = snapshot.tunedPaint
	rawCar.processingStatus = snapshot.processingStatus
	rawCar.sourceWorkingIndex = snapshot.sourceWorkingIndex
end

-- Marks a one-per-trade empty plan when owner service is unavailable. The decision is
-- critical-persisted so polling, rejoin and rolling-server handoff cannot reroll it.
function DealerCar.markServiceRollDone(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if car == nil
		or (expectedTradeId ~= nil and expectedTradeId ~= "" and car.tradeId ~= expectedTradeId)
	then
		return false
	end
	local pipeline = OwnerCarPipeline.ensure(car)
	if pipeline.state == "complete" then
		return true
	end
	if pipeline.state ~= "idle" then
		return false
	end
	local before = snapshotPipelineMutation(car)
	OwnerCarPipeline.begin(car, {}, pipeline.escortId, workspace:GetServerTimeNow())
	if not DataService.commitCritical(player, `owner_pipeline_empty:{car.tradeId}`) then
		restorePipelineMutation(car, before)
		DataService.save(player)
		DealerCar.publish(player)
		return false
	end
	DealerCar.publish(player)
	return true
end

-- A repaired car is eligible for a lift the moment it is sitting finished on the pad and
-- has not already been through. Exact trade guards stop a stale queue item touching reused W.
function DealerCar.canVisitBay(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if car == nil
		or car.state ~= "Ready"
		or car.atBay == true
		or OwnerCarPipeline.ensure(car).state ~= "idle"
		or (expectedTradeId ~= nil and expectedTradeId ~= "" and car.tradeId ~= expectedTradeId)
	then
		return false
	end
	local model = DealerCar.model(player, "working", resolvedIndex)
	if model == nil or model.Parent == nil or model:GetAttribute("Arriving") == true then
		return false
	end
	-- A parked Ready listing session may be superseded by pipeline planning; never snatch a car
	-- once its owner or salesman has actually begun transporting it to a display pad.
	local listingTransport = model:GetAttribute("ListingTransport")
	return listingTransport == nil or listingTransport == "Ready"
end

-- Atomically hands the exact W car to persisted processing inventory. W remains guarded
-- while the critical write yields; failed persistence restores the full car to the same W and
-- never starts a proxy. After success no pipeline path is allowed to reserve W again.
function DealerCar.sendToPipeline(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?,
	plan: { OwnerCarPipeline.StageId },
	escortId: (string | number)?
): boolean
	local data = DataService.get(player)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	if data == nil
		or resolvedIndex == nil
		or workingTransition[resolvedIndex][player] == true
		or not DealerCar.availableProcessing(player)
		or not DealerCar.canVisitBay(player, resolvedIndex, expectedTradeId)
	then
		return false
	end
	local car = DealerCar.active(player, resolvedIndex)
	if car == nil or car.tradeId == "" or #plan == 0
		or DataService.processingIndexForTrade(data, car.tradeId) ~= nil
	then
		return false
	end

	-- W is the last server-owned physical proxy before the client service renderer takes over.
	-- Capture its already-visible factory swatch before the critical processing snapshot so the
	-- reconstructed queue/station proxy cannot fall back to a different palette entry.
	local liveModel = DealerCar.model(player, "working", resolvedIndex)
	local liveFactoryPaintId = if liveModel ~= nil then liveModel:GetAttribute("FactoryPaintId") else nil
	if typeof(liveFactoryPaintId) == "string" and liveFactoryPaintId ~= "" then
		car.factoryPaintId = liveFactoryPaintId
	end

	workingTransition[resolvedIndex][player] = true
	local before = snapshotPipelineMutation(car)
	local pipeline = OwnerCarPipeline.begin(car, plan, escortId, workspace:GetServerTimeNow())
	if pipeline.currentStage == nil then
		restorePipelineMutation(car, before)
		workingTransition[resolvedIndex][player] = nil
		return false
	end
	car.processingStatus = "Pipeline"
	car.sourceWorkingIndex = resolvedIndex
	DataService.setWorking(data, resolvedIndex, nil)
	if not DataService.addProcessing(data, car) then
		DataService.setWorking(data, resolvedIndex, car)
		restorePipelineMutation(car, before)
		workingTransition[resolvedIndex][player] = nil
		return false
	end

	-- This snapshot contains the car only in processingCars. Failure performs a deep rollback
	-- before releasing the W guard; success frees W permanently for incoming stock.
	if not DataService.commitCritical(player, `owner_pipeline_begin:{car.tradeId}`) then
		DataService.removeProcessing(data, car.tradeId)
		restorePipelineMutation(car, before)
		DataService.setWorking(data, resolvedIndex, car)
		workingTransition[resolvedIndex][player] = nil
		DataService.save(player)
		DealerCar.publish(player)
		return false
	end
	workingTransition[resolvedIndex][player] = nil

	local model = DealerCar.detachModel(player, "working", resolvedIndex)
	if model ~= nil then
		-- The committed owner car is rendered next from its exact Repair Bay queue record.
		-- Do not run the generic sold-car/public-road departure here: that made the helper
		-- visibly drive away from the destination before a second proxy appeared at the bay.
		model:Destroy()
	end
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "None", "working", resolvedIndex)
	return true
end

-- Compatibility entry point for old repair-only callers.
function DealerCar.sendToBay(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	return DealerCar.sendToPipeline(player, workingIndex, expectedTradeId, { "repairing" }, nil)
end

function DealerCar.claimPipelineStage(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?,
	stage: OwnerCarPipeline.StageId,
	slotId: string
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local car = DealerCar.processing(player, tradeId)
	if resolvedIndex == nil
		or car == nil
		or car.sourceWorkingIndex ~= resolvedIndex
		or car.atBay ~= true
		or car.tradeId ~= tradeId
		or not OwnerCarPipeline.claim(car, stage, slotId)
	then
		return false
	end
	car.processingStatus = "Pipeline"
	DataService.save(player)
	DealerCar.publish(player)
	return true
end

local AWAITING_DISPLAY_LINES = {
	"Boss, the sales row is full — we need another parking space.",
	"Still waiting, Boss. Open another display spot and I'll pull in.",
	"Every parking space is occupied. This car is ready to sell.",
	"Boss, customers can't see this one until we add more parking.",
	"We've got stock backed up — another sales space would help.",
	"No room on the lot yet, Boss. I'll hold here.",
	"This one's ready for a price tag. We just need a free parking space.",
}

local function clearAwaitingDisplayModel(player: Player, queueIndex: number)
	local model = awaitingDisplayModels[queueIndex][player]
	awaitingDisplayModels[queueIndex][player] = nil
	if model ~= nil then model:Destroy() end
end

local function queueDialogue(player: Player, model: Model, queueIndex: number)
	task.spawn(function()
		task.wait(2 + math.random() * 3)
		while player.Parent ~= nil
			and model.Parent ~= nil
			and awaitingDisplayModels[queueIndex][player] == model
		do
			local driver = DealerCar.driver(model)
			local adornee = if driver ~= nil
				then driver:FindFirstChild("Head", true) or driver:FindFirstChildWhichIsA("BasePart", true)
				else nil
			if adornee ~= nil then
				Remotes.ListingNotice:FireClient(player, {
					mode = "bubble",
					adornee = adornee,
					text = AWAITING_DISPLAY_LINES[math.random(1, #AWAITING_DISPLAY_LINES)],
				})
			end
			task.wait(14 + math.random() * 10)
		end
	end)
end

function DealerCar.awaitingDisplayCapacity(player: Player): number
	-- W1/W2 represent the one/two available lot helpers that can hold finished stock.
	return math.min(2, DealerCar.workingCapacity(player))
end

function DealerCar.syncAwaitingDisplayQueue(player: Player)
	local data = DataService.get(player)
	local record = TycoonService.getForPlayer(player)
	if data == nil or record == nil or record.owner ~= player then
		for index = 1, 2 do clearAwaitingDisplayModel(player, index) end
		return
	end
	local waiting: { ActiveCarSave } = {}
	for _, car in data.processingCars do
		if car.processingStatus == "AwaitingDisplay"
			and car.state == "Ready"
			and car.atBay ~= true
			and not DealerCar.hasParkingLease(player, car.tradeId)
		then
			table.insert(waiting, car)
		end
	end
	local capacity = DealerCar.awaitingDisplayCapacity(player)
	for queueIndex = 1, 2 do
		local car = if queueIndex <= capacity then waiting[queueIndex] else nil
		local existing = awaitingDisplayModels[queueIndex][player]
		if existing ~= nil
			and (car == nil or existing:GetAttribute("TradeId") ~= car.tradeId)
		then
			clearAwaitingDisplayModel(player, queueIndex)
			existing = nil
		end
		if car == nil or existing ~= nil then continue end
		local marker = LotSlots.awaitingDisplayPlatform(record, queueIndex)
		if marker == nil then continue end
		local model = CarVisuals.spawn(car.templateId, marker.CFrame, LotSlots.carFolder(record))
		if model == nil then continue end
		model.Name = ("AwaitingDisplayCar_%02d"):format(queueIndex)
		model:SetAttribute("TradeId", car.tradeId)
		model:SetAttribute("AwaitingDisplayQueueIndex", queueIndex)
		model:SetAttribute("SourceWorkingIndex", car.sourceWorkingIndex)
		CarVisuals.applyCondition(
			model,
			car.parts,
			true,
			car.condition.oilLeak ~= true,
			car.condition.dirty ~= true,
			car.condition.missingWheels
		)
		CarVisuals.applyPaintHue(model, (car :: any).paintHue)
		CarVisuals.applyNeon(model, CarVisuals.template(car.templateId).model, (car :: any).neonColorId)
		CarVisuals.applyWindowTint(model, OwnerCarPipeline.ensure(car).completed.tuningBody == true)
		model:SetAttribute("DealerJourneyId", OwnerCarPipeline.journeyId(car))
		model:SetAttribute("DealerJourneyStatus", "holding")
		model:SetAttribute("AutomatedDealerVehicleProxy", true)
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				-- Condition shells stay unanchored and follow their welded body/wheel source.
				descendant.Anchored = descendant:GetAttribute("ConditionSurface") == nil
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
				if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
					descendant.Disabled = true
				end
			end
		end
		CarVisuals.setRunningLights(model, false)
		CarVisuals.settleOnVisibleTires(model, marker.Position.Y + marker.Size.Y * 0.5, 0.03)
		local driver = DealerCar.addDriver(model, nil)
		if driver ~= nil then
			driver.Name = ("ParkingHelper_%d"):format(car.sourceWorkingIndex or queueIndex)
			driver:SetAttribute("AwaitingDisplayHelper", true)
		end
		awaitingDisplayModels[queueIndex][player] = model
		queueDialogue(player, model, queueIndex)
	end
end

local function clearAwaitingTradeModel(player: Player, tradeId: string)
	for index = 1, 2 do
		local model = awaitingDisplayModels[index][player]
		if model ~= nil and model:GetAttribute("TradeId") == tradeId then
			clearAwaitingDisplayModel(player, index)
		end
	end
end

local function awaitingTradeModel(player: Player, tradeId: string): (Model?, number?)
	for index = 1, 2 do
		local model = awaitingDisplayModels[index][player]
		if model ~= nil and model.Parent ~= nil and model:GetAttribute("TradeId") == tradeId then
			return model, index
		end
	end
	return nil, nil
end

local function detachAwaitingTradeModel(player: Player, tradeId: string): Model?
	local model, index = awaitingTradeModel(player, tradeId)
	if index ~= nil then
		awaitingDisplayModels[index][player] = nil
	end
	return model
end

-- Moves a finished/abandoned exact processing trade straight into the first free P. If all
-- display pads are occupied, AwaitingDisplay remains persisted and is represented by the
-- two-position physical queue in front of Used Cars. Every rollback returns here, never W.
function DealerCar.routeCompletedPipeline(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?,
	preferredDisplayIndex: number?,
	sourceModel: Model?,
	skipDisplayArrival: boolean?
): (boolean, number?)
	local data = DataService.get(player)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local car: ActiveCarSave? = nil
	local processingIndex: number? = nil
	if data ~= nil then
		car, processingIndex = DataService.getProcessing(data, tradeId)
	end
	local record = TycoonService.getForPlayer(player)
	if data == nil
		or resolvedIndex == nil
		or car == nil
		or processingIndex == nil
		or car.sourceWorkingIndex ~= resolvedIndex
		or record == nil
		or record.owner ~= player
		or car.state ~= "Ready"
		or car.atBay == true
		or not OwnerCarPipeline.isComplete(car)
		or car.tradeId ~= tradeId
	then
		return false, nil
	end

	local displayIndex = if preferredDisplayIndex ~= nil
		then resolveDisplayIndex(preferredDisplayIndex)
		else DealerCar.availableDisplayIndex(player)
	if displayIndex ~= nil and preferredDisplayIndex ~= nil then
		local reservation = DealerCar.displayReservation(player, displayIndex)
		if displayIndex > DealerCar.displayCapacity(player)
			or DealerCar.display(player, displayIndex) ~= nil
			or (reservation ~= nil and reservation ~= tradeId)
		then
			return false, displayIndex
		end
	end
	if displayIndex == nil then
		if car.processingStatus ~= "AwaitingDisplay" then
			car.processingStatus = "AwaitingDisplay"
			DataService.save(player)
		end
		DealerCar.syncAwaitingDisplayQueue(player)
		DealerCar.publish(player)
		return false, nil
	end

	local oldState = car.state
	local oldListedPrice = car.listedPrice
	local oldProcessingStatus = car.processingStatus
	local oldSourceWorkingIndex = car.sourceWorkingIndex
	car.state = "Listed"
	if car.listedPrice <= 0 then
		car.listedPrice = DealerCar.valueBreakdown(player, car).listedPrice
	end
	car.processingStatus = nil
	car.sourceWorkingIndex = nil
	DataService.removeProcessing(data, tradeId)
	DataService.setDisplay(data, displayIndex, car)
	if not DataService.commitCritical(player, `owner_pipeline_list:{car.tradeId}:P{displayIndex}`) then
		DataService.setDisplay(data, displayIndex, nil)
		car.state = oldState
		car.listedPrice = oldListedPrice
		car.processingStatus = oldProcessingStatus
		car.sourceWorkingIndex = oldSourceWorkingIndex
		table.insert(data.processingCars, math.min(processingIndex, #data.processingCars + 1), car)
		DataService.save(player)
		DealerCar.syncAwaitingDisplayQueue(player)
		DealerCar.publish(player)
		DealerCar.releaseDisplay(player, displayIndex, tradeId)
		return false, displayIndex
	end

	if sourceModel ~= nil then
		detachAwaitingTradeModel(player, car.tradeId)
	else
		clearAwaitingTradeModel(player, car.tradeId)
	end
	DealerCar.spawn(
		player,
		record,
		sourceModel == nil and skipDisplayArrival ~= true,
		"display",
		displayIndex,
		sourceModel
	)
	local displayed = DealerCar.displayModel(player, displayIndex)
	if displayed == nil or displayed.Parent == nil then
		-- The critical listing save is already durable. A missing visual must never roll that
		-- business transition back in memory while a failed rollback write leaves it Listed on
		-- disk. Rebuild the presentation independently; RequestCarState is an additional retry.
		warn(string.format("[DealerCar] listed visual missing %s P%d; scheduling rebuild", tradeId, displayIndex))
		if sourceModel ~= nil and sourceModel.Parent ~= nil then
			sourceModel:Destroy()
		end
		DealerCar.releaseDisplay(player, displayIndex, tradeId)
		DealerCar.publish(player)
		DealerCar.stateChanged:Fire(player, "Listed", "display", displayIndex)
		task.spawn(function()
			for _ = 1, 3 do
				task.wait(0.5)
				if player.Parent == nil or record.owner ~= player then
					return
				end
				local saved = DealerCar.display(player, displayIndex)
				if saved == nil or saved.tradeId ~= tradeId then
					return
				end
				if DealerCar.displayModel(player, displayIndex) ~= nil then
					return
				end
				DealerCar.spawn(player, record, false, "display", displayIndex)
			end
		end)
		return true, displayIndex
	end

	DealerCar.releaseDisplay(player, displayIndex, tradeId)
	DealerCar.syncAwaitingDisplayQueue(player)
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "Listed", "display", displayIndex)
	return true, displayIndex
end

-- A V2 car that finished while every P was occupied waits as an authoritative model in
-- front of Used Cars. Once a slot opens, drive that exact Instance through the shared
-- aisle/setup/reverse route instead of deleting it and spawning a replacement on P.
function DealerCar.routeAwaitingDisplayPipeline(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	local tradeId = expectedTradeId or ""
	local resolvedWorkingIndex = resolveWorkingIndex(workingIndex)
	local car = DealerCar.processing(player, tradeId)
	local record = TycoonService.getForPlayer(player)
	if resolvedWorkingIndex == nil
		or car == nil
		or record == nil
		or record.owner ~= player
		or car.sourceWorkingIndex ~= resolvedWorkingIndex
		or not OwnerCarPipeline.isComplete(car)
		or car.atBay == true
		or not OwnerCarPipeline.routingFlags(car).usedParking
	then
		return false
	end
	if DealerCar.hasParkingLease(player, tradeId) then
		return true
	end

	DealerCar.syncAwaitingDisplayQueue(player)
	local model = select(1, awaitingTradeModel(player, tradeId))
	local displayIndex = DealerCar.availableDisplayIndex(player)
	if model == nil
		or displayIndex == nil
		or not DealerCar.reserveDisplay(player, displayIndex, tradeId)
	then
		return false
	end
	if not DealerCar.acquireParkingLease(player, tradeId) then
		DealerCar.releaseDisplay(player, displayIndex, tradeId)
		return false
	end
	-- The moving model is now owned by this task, not by the two-place waiting queue.
	-- Detaching it lets sync compact that queue without destroying the in-flight Instance.
	detachAwaitingTradeModel(player, tradeId)
	task.spawn(function()
		local routeSucceeded = false
		local routeOk, routeError = xpcall(function()
			local surfaceTarget = LotSlots.saleCFrame(record, displayIndex)
			local target = surfaceTarget
				+ Vector3.new(0, CarVisuals.visibleTirePivotClearance(model), 0)
			local parking = RoadTraffic.displayParkingPlan(record, target, true)
			local forward: { Vector3 } = { model:GetPivot().Position }
			for _, point in parking.forward do
				if (point - forward[#forward]).Magnitude > 0.05 then
					table.insert(forward, point)
				end
			end
			local function valid(): boolean
				local current = DealerCar.processing(player, tradeId)
				return player.Parent ~= nil
					and record.owner == player
					and model.Parent ~= nil
					and current == car
					and DealerCar.displayReservation(player, displayIndex) == tradeId
			end
			model:SetAttribute("DealerJourneyId", OwnerCarPipeline.journeyId(car))
			model:SetAttribute("DealerJourneyRouteId", string.format("owner:%s:used:P%d", tradeId, displayIndex))
			model:SetAttribute("DealerJourneyStatus", "active")
			CarVisuals.setRunningLights(model, true)
			routeSucceeded = RoadTraffic.drive(model, forward, 15, valid, {
				steer = true,
				initialLook = model:GetPivot().LookVector,
			})
			if routeSucceeded and #parking.reversePark >= 2 then
				routeSucceeded = RoadTraffic.drive(model, parking.reversePark, 8, valid, {
					reverse = true,
					steer = true,
				})
			end
			local arrived = routeSucceeded
				and valid()
				and (model:GetPivot().Position - target.Position).Magnitude <= 0.15
			routeSucceeded = false
			if arrived then
				model:PivotTo(target)
				routeSucceeded = select(1, DealerCar.routeCompletedPipeline(
					player,
					resolvedWorkingIndex,
					tradeId,
					displayIndex,
					model
				))
			end
		end, debug.traceback)
		DealerCar.releaseParkingLease(player, tradeId)
		DealerCar.releaseDisplay(player, displayIndex, tradeId)
		if not routeOk then
			warn(string.format("[DealerCar] awaiting parking failed %s: %s", tradeId, tostring(routeError)))
		end
		if (not routeOk or not routeSucceeded) and model.Parent ~= nil then
			-- A failed route is rebuilt from the exact persisted car at the queue marker. Do
			-- not leave this detached copy beside the freshly recovered queue model.
			model:Destroy()
			local synced, syncError = pcall(DealerCar.syncAwaitingDisplayQueue, player)
			if not synced then
				warn(string.format("[DealerCar] awaiting parking recovery failed %s: %s", tradeId, tostring(syncError)))
			end
		end
	end)
	return true
end

-- Ends an exact queued/servicing owner pipeline without granting the unfinished stage.
-- Completed stages keep their multipliers; the final listing price is frozen with a
-- configurable penalty before the critical write.
function DealerCar.abortPipeline(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?,
	valueMultiplier: number
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local car = DealerCar.processing(player, tradeId)
	if resolvedIndex == nil
		or car == nil
		or car.sourceWorkingIndex ~= resolvedIndex
		or car.state ~= "Ready"
		or car.atBay ~= true
		or car.tradeId ~= tradeId
	then
		return false
	end
	local pipeline = OwnerCarPipeline.ensure(car)
	if pipeline.state ~= "queued" and pipeline.state ~= "servicing" then
		return false
	end

	local before = snapshotPipelineMutation(car)
	local oldListedPrice = car.listedPrice
	local fullListingValue = DealerCar.valueBreakdown(player, car).listedPrice
	OwnerCarPipeline.markComplete(car)
	car.atBay = false
	car.serviceQueuedAt = 0
	car.processingStatus = "AwaitingDisplay"
	car.listedPrice = math.max(1, math.floor(fullListingValue * math.clamp(valueMultiplier, 0.1, 1)))
	if not DataService.commitCritical(player, `owner_pipeline_abort:{car.tradeId}`) then
		restorePipelineMutation(car, before)
		car.listedPrice = oldListedPrice
		DataService.save(player)
		DealerCar.publish(player)
		return false
	end
	DealerCar.publish(player)
	return true
end

function DealerCar.finishPipelineStage(
	player: Player,
	successful: boolean,
	stage: OwnerCarPipeline.StageId,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local car = DealerCar.processing(player, tradeId)
	if resolvedIndex == nil
		or car == nil
		or car.sourceWorkingIndex ~= resolvedIndex
		or car.atBay ~= true
		or car.tradeId ~= tradeId
	then
		return false
	end
	local now = workspace:GetServerTimeNow()
	local data = if successful then DataService.get(player) else nil
	if successful and data == nil then
		return false
	end
	local before = if successful then snapshotPipelineMutation(car) else nil
	local cashBefore = if data ~= nil then data.cash else 0
	local valueBefore = if successful then DealerCar.valueBreakdown(player, car).calculatedValue else 0
	local changed = if successful
		then OwnerCarPipeline.completeStage(car, stage, now)
		else OwnerCarPipeline.releaseLease(car, now)
	if not changed then
		return false
	end
	local serviceCostIncurred = 0
	local serviceCostPaidNow = 0
	if successful and data ~= nil then
		serviceCostIncurred = OwnerCarPipeline.stageCost(stage, valueBefore)
		serviceCostPaidNow = math.min(serviceCostIncurred, math.max(0, math.floor(data.cash)))
		car.serviceCost = math.max(0, math.floor(car.serviceCost)) + serviceCostIncurred
		car.serviceCostPaid = math.max(0, math.floor(car.serviceCostPaid)) + serviceCostPaidNow
		data.cash = math.max(0, math.floor(data.cash - serviceCostPaidNow))
	end
	local complete = OwnerCarPipeline.isComplete(car)
	car.processingStatus = if complete then "AwaitingDisplay" else "Pipeline"
	if complete then
		car.atBay = false
		car.serviceQueuedAt = 0
	end
	if successful and not DataService.commitCritical(player, `owner_pipeline_stage:{car.tradeId}:{stage}`) then
		restorePipelineMutation(car, before)
		if data ~= nil then
			data.cash = cashBefore
			TycoonService.syncCash(player)
		end
		-- The physical proxy is clearing; a failed stage commit goes back to processing FIFO.
		OwnerCarPipeline.releaseLease(car, now)
		car.processingStatus = "Pipeline"
		DataService.save(player)
		DealerCar.publish(player)
		return false
	elseif not successful then
		DataService.save(player)
	elseif serviceCostPaidNow > 0 then
		TycoonService.syncCash(player)
	end
	if complete and not OwnerCarPipeline.routingFlags(car).usedParking then
		DealerCar.routeCompletedPipeline(player, resolvedIndex, car.tradeId)
	end
	DealerCar.publish(player)
	return true
end

-- Permanently records a capacity-driven skip without applying that stage's perk.
function DealerCar.skipPipelineStage(
	player: Player,
	stage: OwnerCarPipeline.StageId,
	workingIndex: number?,
	expectedTradeId: string?,
	reason: string
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local car = DealerCar.processing(player, tradeId)
	if resolvedIndex == nil or car == nil or car.sourceWorkingIndex ~= resolvedIndex
		or car.atBay ~= true or car.tradeId ~= tradeId then
		return false
	end
	local before = snapshotPipelineMutation(car)
	if not OwnerCarPipeline.skipStage(car, stage, reason, workspace:GetServerTimeNow()) then
		return false
	end
	local complete = OwnerCarPipeline.isComplete(car)
	car.processingStatus = if complete then "AwaitingDisplay" else "Pipeline"
	if complete then
		car.atBay = false
		car.serviceQueuedAt = 0
	end
	if not DataService.commitCritical(player, `owner_pipeline_skip:{car.tradeId}:{stage}:{reason}`) then
		restorePipelineMutation(car, before)
		DataService.save(player)
		DealerCar.publish(player)
		return false
	end
	if complete and not OwnerCarPipeline.routingFlags(car).usedParking then
		DealerCar.routeCompletedPipeline(player, resolvedIndex, car.tradeId)
	end
	DealerCar.publish(player)
	return true
end

-- Compatibility wrapper: current owner jobs resolve the exact processing trade; only a
-- pre-migration caller with no persisted stage can still use the legacy W fallback below.
function DealerCar.returnFromBay(
	player: Player,
	serviced: boolean,
	workingIndex: number?,
	expectedTradeId: string?
): boolean
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local tradeId = expectedTradeId or ""
	local processingCar = DealerCar.processing(player, tradeId)
	if resolvedIndex ~= nil and processingCar ~= nil and processingCar.sourceWorkingIndex == resolvedIndex then
		local processingStage = OwnerCarPipeline.currentStage(processingCar)
		if processingCar.atBay == true and processingStage ~= nil then
			return DealerCar.finishPipelineStage(player, serviced, processingStage, resolvedIndex, tradeId)
		end
	end

	-- Rolling compatibility for an old live caller whose car has not migrated yet.
	local car = if resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if car == nil or (tradeId ~= "" and car.tradeId ~= tradeId) then
		return false
	end
	local stage = OwnerCarPipeline.currentStage(car)
	if car.atBay == true and stage ~= nil then
		return DealerCar.finishPipelineStage(player, serviced, stage, resolvedIndex, tradeId)
	end
	-- Rolling compatibility for an old save/caller with no stage lease.
	local plan: { OwnerCarPipeline.StageId } = if serviced then { "repairing" } else {}
	OwnerCarPipeline.begin(car, plan, nil, workspace:GetServerTimeNow())
	if serviced then
		OwnerCarPipeline.completeStage(car, "repairing", workspace:GetServerTimeNow())
	end
	car.atBay = false
	car.serviceQueuedAt = 0
	DataService.save(player)
	local record = TycoonService.getForPlayer(player)
	if record ~= nil then
		DealerCar.spawn(player, record, true, "working", resolvedIndex)
	end
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, car.state, "working", resolvedIndex)
	return true
end

local function slotPayload(player: Player, car: ActiveCarSave?, model: Model?, slot: PayloadSlot, slotIndex: number)
	local breakdown = if car ~= nil then DealerCar.valueBreakdown(player, car) else nil
	local tutorialDeal = if car ~= nil then DealerCarConfig.tutorialDeal(car.tutorialDealIndex) else nil
	local data = DataService.get(player)
	local arrivalOdds = if car ~= nil and tutorialDeal == nil
		then DealerCarConfig.arrivalOdds(car.templateId, DealerCar.pads(player), if data ~= nil then data.luck else nil)
		else nil
	local rarityOneInN = if arrivalOdds ~= nil and arrivalOdds.probability > 0
		then arrivalOdds.oneInN
		elseif car ~= nil then (select(1, DealerCarConfig.rarityOf(car.templateId)))
		else 0
	local rarity = if rarityOneInN > 0
		then DealerCarConfig.rarityTier(rarityOneInN)
		else DealerCarConfig.RARITY_TIERS[1]
	local manualCurrent, manualTotal = 0, 0
	if car ~= nil then
		manualCurrent, manualTotal = DealerCarConfig.tutorialManualProgress(car.tutorialDealIndex, car.parts)
	end
	local onLot = model ~= nil
		and model.Parent ~= nil
		and model:GetAttribute("Arriving") ~= true
	return {
		tradeId = if car ~= nil then car.tradeId else "",
		state = if car ~= nil then car.state else "None",
		value = if breakdown ~= nil then breakdown.value else 0,
		valueAfterRepairs = if car ~= nil then DealerCar.valueAfterRepairs(player, car) else 0,
		baseValue = if breakdown ~= nil then breakdown.baseValue else 0,
		partsValue = if breakdown ~= nil then breakdown.partsValue else 0,
		acquisitionValue = if breakdown ~= nil then breakdown.acquisitionValue else 0,
		restoredValue = if breakdown ~= nil then breakdown.restoredValue else 0,
		repairValue = if breakdown ~= nil then breakdown.repairValue else 0,
		repairProgress = if breakdown ~= nil then breakdown.repairProgress else 0,
		repairGains = if breakdown ~= nil then breakdown.repairGains else {},
		calculatedValue = if breakdown ~= nil then breakdown.calculatedValue else 0,
		serviceMultiplier = if breakdown ~= nil then breakdown.serviceMultiplier else 1,
		serviceStages = if breakdown ~= nil then breakdown.serviceStages else {},
		listingMarkup = if breakdown ~= nil then breakdown.listingMarkup else 0,
		listedPrice = if breakdown ~= nil then breakdown.listedPrice else 0,
		currentOffer = if car ~= nil then car.offered else 0,
		purchaseCost = if car ~= nil then car.cost else 0,
		serviceCost = if car ~= nil then car.serviceCost else 0,
		serviceCostPaid = if car ~= nil then car.serviceCostPaid else 0,
		totalInvestment = if car ~= nil then car.cost + car.serviceCost else 0,
		finalProfit = if car ~= nil and car.offered > 0 then car.offered - car.cost - car.serviceCost else 0,
		cost = if car ~= nil then car.cost else 0,
		ask = if car ~= nil then car.ask else 0,
		parts = if car ~= nil then car.parts else {},
		templateId = if car ~= nil then car.templateId else "",
		serviced = if car ~= nil then car.serviced == true else false,
		atBay = if car ~= nil then car.atBay == true else false,
		serviceRollDone = if car ~= nil then car.serviceRollDone == true else false,
		serviceQueuedAt = if car ~= nil then car.serviceQueuedAt else 0,
		pipelineState = if car ~= nil then OwnerCarPipeline.ensure(car).state else "complete",
		pipelineStage = if car ~= nil then OwnerCarPipeline.currentStage(car) else nil,
		pipelinePlan = if car ~= nil then OwnerCarPipeline.ensure(car).plan else {},
		completedServices = if car ~= nil then OwnerCarPipeline.ensure(car).completed else {},
		skippedServices = if car ~= nil then OwnerCarPipeline.ensure(car).skipped else {},
		processingStatus = if car ~= nil then car.processingStatus else nil,
		sourceWorkingIndex = if car ~= nil then car.sourceWorkingIndex else nil,
		dirty = if car ~= nil then car.condition.dirty == true else false,
		oilLeak = if car ~= nil then car.condition.oilLeak == true else false,
		offered = if car ~= nil then car.offered else 0,
		haggleUsed = if car ~= nil then car.haggleUsed else false,
		rarityOneInN = rarityOneInN,
		rarityTier = if car ~= nil then rarity.id else "",
		arrivalTier = if arrivalOdds ~= nil then arrivalOdds.tier else nil,
		arrivalClassWeight = if arrivalOdds ~= nil then arrivalOdds.classWeight else 0,
		arrivalProbability = if arrivalOdds ~= nil then arrivalOdds.probability else 0,
		arrivalPercent = if arrivalOdds ~= nil then arrivalOdds.percent else 0,
		sellerId = if car ~= nil then car.sellerId else nil,
		customerId = if car ~= nil then car.customerId else nil,
		tutorialDealIndex = if car ~= nil then car.tutorialDealIndex else 0,
		tutorialWildcard = if car ~= nil then car.tutorialWildcard == true else false,
		tutorialBeat = if tutorialDeal ~= nil then tutorialDeal.beat else nil,
		diagnosis = if tutorialDeal ~= nil then tutorialDeal.diagnosis else nil,
		manualRepairCurrent = manualCurrent,
		manualRepairTotal = manualTotal,
		onLot = onLot,
		listingTransport = if model ~= nil then model:GetAttribute("ListingTransport") else nil,
		repairAutomated = slot == "working" and DealerCar.repairAutomated(player, slotIndex),
		slot = slot,
		slotIndex = slotIndex,
		workingIndex = if slot == "working" then slotIndex elseif car ~= nil then car.sourceWorkingIndex else nil,
		displayIndex = if slot == "display" then slotIndex else nil,
		processingIndex = if slot == "processing" then slotIndex else nil,
	}
end

function DealerCar.publish(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local workings = {}
	for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		workings[index] = slotPayload(
			player,
			DealerCar.active(player, index),
			DealerCar.model(player, "working", index),
			"working",
			index
		)
	end
	local displays = {}
	for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
		displays[index] = slotPayload(
			player,
			DealerCar.display(player, index),
			DealerCar.displayModel(player, index),
			"display",
			index
		)
	end
	local processings = {}
	for index, car in data.processingCars do
		processings[index] = slotPayload(player, car, nil, "processing", index)
	end
	local working = workings[1]
	local display1 = displays[1]
	local listingAutomated = data.pads[DealerCarConfig.AUTO_LIST_PAD] == true
	local buyerAutomated = data.pads[DealerCarConfig.AUTO_ACCEPT_PAD] == true
	Remotes.CarState:FireClient(player, {
		version = 5,
		workings = workings,
		working = working,
		workingCapacity = DealerCar.workingCapacity(player),
		hasFreeWorking = DealerCar.availableWorkingIndex(player) ~= nil,
		processings = processings,
		processingCapacity = DataService.processingCapacity(),
		hasFreeProcessing = DealerCar.availableProcessing(player),
		displays = displays,
		-- Compatibility: display always aliases P1.
		display = display1,
		displayCapacity = DealerCar.displayCapacity(player),
		hasFreeDisplay = DealerCar.availableDisplayIndex(player) ~= nil,
		-- One-release compatibility aliases intentionally mean W1.
		state = working.state,
		value = working.value,
		baseValue = working.baseValue,
		partsValue = working.partsValue,
		calculatedValue = working.calculatedValue,
		serviceMultiplier = working.serviceMultiplier,
		serviceStages = working.serviceStages,
		listingMarkup = working.listingMarkup,
		listedPrice = working.listedPrice,
		currentOffer = working.currentOffer,
		purchaseCost = working.purchaseCost,
		serviceCost = working.serviceCost,
		serviceCostPaid = working.serviceCostPaid,
		totalInvestment = working.totalInvestment,
		finalProfit = working.finalProfit,
		cost = working.cost,
		ask = working.ask,
		parts = working.parts,
		templateId = working.templateId,
		serviced = working.serviced,
		atBay = working.atBay,
		serviceRollDone = working.serviceRollDone,
		serviceQueuedAt = working.serviceQueuedAt,
		pipelineState = working.pipelineState,
		pipelineStage = working.pipelineStage,
		pipelinePlan = working.pipelinePlan,
		completedServices = working.completedServices,
		skippedServices = working.skippedServices,
		dirty = working.dirty,
		oilLeak = working.oilLeak,
		offered = working.offered,
		haggleUsed = working.haggleUsed,
		rarityOneInN = working.rarityOneInN,
		rarityTier = working.rarityTier,
		arrivalTier = working.arrivalTier,
		arrivalClassWeight = working.arrivalClassWeight,
		arrivalProbability = working.arrivalProbability,
		arrivalPercent = working.arrivalPercent,
		sellerId = working.sellerId,
		customerId = working.customerId,
		onLot = working.onLot,
		listingTransport = working.listingTransport,
		displayOccupied = DealerCar.hasAnyDisplay(player),
		hasListing = data.pads[TycoonConfig.LISTING_PAD_ID] == true,
		phoneTrade = data.pads[DealerCarConfig.PHONE_TRADE_PAD] == true,
		-- Rolling compatibility: the flat flag is authoritative for W1 only.
		repairAutomated = working.repairAutomated,
		listingAutomated = listingAutomated,
		transportAutomated = listingAutomated,
		buyerAutomated = buyerAutomated,
		displaySaleAutomated = buyerAutomated,
		-- Legacy automated now means listing transport only; it never suppresses buyer UI.
		automated = listingAutomated,
		bayChapter = data.pads["OpenRepairBay"] == true,
		hasLift = data.pads["RB_CarLift"] == true,
		bayMechanic = data.pads["RB_MechanicNPC"] == true,
	})
	local record = TycoonService.getForPlayer(player)
	if record ~= nil then
		local TradeService = require(script.Parent.TradeService)
		TradeService.refreshListPrompt(player, record)
	end
end

-- Drivers ---------------------------------------------------------------------

-- Nobody drives an empty car onto a lot, so every arrival and departure carries a rig.
-- It lives inside the car model, which means PivotTo moves the pair together.
function DealerCar.driver(model: Model?): Model?
	if model == nil then
		return nil
	end
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") ~= nil then
			return child
		end
	end
	return nil
end

function DealerCar.addDriver(model: Model, personId: string?): Model?
	local existing = DealerCar.driver(model)
	if existing ~= nil then
		return existing
	end
	local seat = CarVisuals.driverSeat(model)
	local pivot = model:GetPivot()
	-- Spawn beside the car on the ground; seat() immediately pulls him into the cabin.
	local foot = Vector3.new(pivot.Position.X, pivot.Position.Y - 2, pivot.Position.Z)
	-- The person behind the wheel is the one who steps out to sell, so they have to arrive
	-- already wearing the face the deal card is going to show.
	local rig = LotNpc.spawn(DRIVER_NAME, model, foot, pivot.LookVector, personId)
	if rig == nil then
		return nil
	end
	LotNpc.seat(rig, model, seat)
	return rig
end

local function applyEscortAppearance(record: Record, driver: Model, escortId: (string | number)?)
	if escortId == nil then
		return
	end
	local helperName = tostring(escortId)
	local helper = record.folder:FindFirstChild(helperName, true)
	local helperHumanoid = if helper ~= nil and helper:IsA("Model")
		then helper:FindFirstChildOfClass("Humanoid")
		else nil
	local driverHumanoid = driver:FindFirstChildOfClass("Humanoid")
	if helperHumanoid == nil
		or not helperHumanoid:IsA("Humanoid")
		or driverHumanoid == nil
		or not driverHumanoid:IsA("Humanoid")
	then
		return
	end
	local okDescription, description = pcall(function()
		return helperHumanoid:GetAppliedDescription()
	end)
	if not okDescription or description == nil then
		return
	end
	local pivot = driver:GetPivot()
	local applied = pcall(function()
		driverHumanoid:ApplyDescription(description)
	end)
	if applied and driver.Parent ~= nil then
		driver:PivotTo(pivot)
		driver:SetAttribute("ServiceEscortId", helperName)
	end
end

function DealerCar.driverSeat(model: Model): CFrame
	return CarVisuals.driverSeat(model)
end

function DealerCar.clearModel(player: Player, slot: CarSlot?, slotIndex: number?)
	local resolvedSlot: CarSlot = slot or "working"
	local resolvedIndex = resolveSlotIndex(resolvedSlot, slotIndex)
	if resolvedIndex == nil then
		return
	end
	local map = modelMap(resolvedSlot, resolvedIndex)
	local model = map[player]
	if model ~= nil then
		model:Destroy()
	end
	map[player] = nil
end

local function bumpToken(player: Player, workingIndex: number): number
	local tokens = driveToken[workingIndex]
	tokens[player] = (tokens[player] or 0) + 1
	return tokens[player]
end

function DealerCar.forget(player: Player)
	awaitingParking[player] = nil
	for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		DealerCar.clearModel(player, "working", index)
		driveToken[index][player] = nil
		repairing[index][player] = nil
		manualRepairUntil[index][player] = nil
		workingTransition[index][player] = nil
	end
	for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
		DealerCar.clearModel(player, "display", index)
		displayReservations[index][player] = nil
	end
	for index = 1, 2 do
		clearAwaitingDisplayModel(player, index)
	end
end

-- A car counts as visually finished once every part is done; the later trade states keep
-- that look even though the parts table no longer changes.
local function looksRepaired(car: ActiveCarSave): boolean
	if CarVisuals.allPartsRepaired(car.parts) then
		return true
	end
	return car.state == "Ready" or car.state == "Listed" or car.state == "Offer"
end

-- A player can stand on an empty W/P target while an arriving car is still on the road.
-- Move every real player (owner or visitor) to a grounded, unoccupied edge candidate before
-- the chassis enters that footprint. The final call remains as a last authoritative guard.
local function projectedParkingFootprint(model: Model, finalPivot: CFrame): (CFrame, Vector3, Vector3)
	local modelPivot = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local finalBox = finalPivot * modelPivot:ToObjectSpace(boxCFrame)
	local detectionHalf = boxSize * 0.5 + Vector3.new(2.25, 3.5, 2.25)
	return finalBox, boxSize, detectionHalf
end

local function pointInsideParkingFootprint(position: Vector3, finalBox: CFrame, detectionHalf: Vector3): boolean
	local localPosition = finalBox:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= detectionHalf.X
		and math.abs(localPosition.Y) <= detectionHalf.Y
		and math.abs(localPosition.Z) <= detectionHalf.Z
end

local function parkingFootprintOccupied(model: Model, finalPivot: CFrame): boolean
	local finalBox, _, detectionHalf = projectedParkingFootprint(model, finalPivot)
	for _, otherPlayer in Players:GetPlayers() do
		local character = otherPlayer.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid ~= nil
			and humanoid.Health > 0
			and root ~= nil
			and root:IsA("BasePart")
			and pointInsideParkingFootprint(root.Position, finalBox, detectionHalf)
		then
			return true
		end
	end
	return false
end

type ReservedCharacterExit = {
	position: Vector3,
	size: Vector3,
}

local function verticalHalfExtent(part: BasePart): number
	local half = part.Size * 0.5
	local frame = part.CFrame
	return math.abs(frame.RightVector.Y) * half.X
		+ math.abs(frame.UpVector.Y) * half.Y
		+ math.abs(frame.LookVector.Y) * half.Z
end

local function worldAxisHalfExtents(frame: CFrame, size: Vector3): Vector3
	local half = size * 0.5
	local right = frame.RightVector
	local up = frame.UpVector
	local look = frame.LookVector
	return Vector3.new(
		math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
		math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
		math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
	)
end

local function axisAlignedBoxesOverlap(
	firstPosition: Vector3,
	firstHalf: Vector3,
	secondPosition: Vector3,
	secondHalf: Vector3,
	padding: number?
): boolean
	local extra = padding or 0
	local delta = firstPosition - secondPosition
	return math.abs(delta.X) <= firstHalf.X + secondHalf.X + extra
		and math.abs(delta.Y) <= firstHalf.Y + secondHalf.Y + extra
		and math.abs(delta.Z) <= firstHalf.Z + secondHalf.Z + extra
end

local function clearCharactersFromParkingFootprint(model: Model, finalPivot: CFrame)
	local finalBox, boxSize, detectionHalf = projectedParkingFootprint(model, finalPivot)
	local playerCharacters: { Model } = {}
	local playerCharacterSet: { [Model]: boolean } = {}
	local raycastExclusions: { Instance } = { model }
	for _, otherPlayer in Players:GetPlayers() do
		local character = otherPlayer.Character
		if character ~= nil and character.Parent ~= nil then
			table.insert(playerCharacters, character)
			playerCharacterSet[character] = true
			table.insert(raycastExclusions, character)
		end
	end
	local reservedExits: { ReservedCharacterExit } = {}

	local function playerCharacterOf(instance: Instance): Model?
		local current: Instance? = instance
		while current ~= nil and current ~= Workspace do
			if current:IsA("Model") and playerCharacterSet[current] == true then
				return current
			end
			current = current.Parent
		end
		return nil
	end

	local function belongsToOtherVehicle(instance: Instance): boolean
		local current: Instance? = instance
		while current ~= nil and current ~= Workspace do
			if current:IsA("Model")
				and current ~= model
				and (current:GetAttribute("DealerSlot") ~= nil
					or current:GetAttribute("TemplateId") ~= nil
					or current:GetAttribute("IncomingSellerQueue") == true
					or current:GetAttribute("ServiceTradeId") ~= nil)
			then
				return true
			end
			current = current.Parent
		end
		return false
	end

	for _, otherPlayer in Players:GetPlayers() do
		local character = otherPlayer.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if character == nil
			or humanoid == nil
			or root == nil
			or not root:IsA("BasePart")
			or humanoid.Health <= 0
		then
			continue
		end

		if not pointInsideParkingFootprint(root.Position, finalBox, detectionHalf) then
			continue
		end

		local localPosition = finalBox:PointToObjectSpace(root.Position)
		local bodyHalfX = boxSize.X * 0.5
		local bodyHalfZ = boxSize.Z * 0.5
		local clearanceSize = Vector3.new(
			math.max(3.5, root.Size.X + 1.5),
			math.max(5, root.Size.Y + humanoid.HipHeight + 1),
			math.max(3.5, root.Size.Z + 1.5)
		)
		local clearanceHalf = clearanceSize * 0.5

		local function groundedExit(localCandidate: Vector3): Vector3?
			local edge = finalBox:PointToWorldSpace(localCandidate)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = raycastExclusions
			raycastParams.IgnoreWater = true
			local originY = math.max(edge.Y, finalPivot.Position.Y) + 14
			local hit = Workspace:Raycast(
				Vector3.new(edge.X, originY, edge.Z),
				Vector3.new(0, -40, 0),
				raycastParams
			)
			if hit == nil
				or hit.Normal.Y < 0.6
				or math.abs(hit.Position.Y - finalPivot.Position.Y) > 6
				or belongsToOtherVehicle(hit.Instance)
			then
				return nil
			end
			if hit.Instance:IsA("BasePart") then
				local support = hit.Instance
				local supportHalf = support.Size * 0.5
				local supportPoint = support.CFrame:PointToObjectSpace(hit.Position)
				local supportMargin = math.min(1.25, math.min(clearanceHalf.X, clearanceHalf.Z) * 0.5)
				if not support.CanCollide
					or math.abs(support.CFrame.UpVector:Dot(hit.Normal)) < 0.55
					or supportHalf.X <= supportMargin
					or supportHalf.Z <= supportMargin
					or math.abs(supportPoint.X) > supportHalf.X - supportMargin
					or math.abs(supportPoint.Z) > supportHalf.Z - supportMargin
				then
					return nil
				end
			end
			local height = humanoid.HipHeight + root.Size.Y * 0.5 + 0.35
			local position = Vector3.new(edge.X, hit.Position.Y + height, edge.Z)

			for _, reserved in reservedExits do
				if axisAlignedBoxesOverlap(
					position,
					clearanceHalf,
					reserved.position,
					reserved.size * 0.5,
					0.5
				) then
					return nil
				end
			end
			for _, otherCharacter in playerCharacters do
				if otherCharacter ~= character and otherCharacter.Parent ~= nil then
					local otherFrame, otherSize = otherCharacter:GetBoundingBox()
					if axisAlignedBoxesOverlap(
						position,
						clearanceHalf,
						otherFrame.Position,
						worldAxisHalfExtents(otherFrame, otherSize),
						0.35
					) then
						return nil
					end
				end
			end

			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude
			overlapParams.FilterDescendantsInstances = { model, character, hit.Instance }
			for _, part in Workspace:GetPartBoundsInBox(CFrame.new(position), clearanceSize, overlapParams) do
				if playerCharacterOf(part) ~= nil then
					return nil
				end
				if part.CanCollide then
					local top = part.Position.Y + verticalHalfExtent(part)
					local supportFloor = not belongsToOtherVehicle(part)
						and top <= hit.Position.Y + 0.35
					if not supportFloor then
						return nil
					end
				end
			end
			if pointInsideParkingFootprint(position, finalBox, detectionHalf) then
				return nil
			end
			return position
		end

		local exitPosition: Vector3? = nil
		for _, edgePadding in { 3.25, 6.5, 10, 15, 22 } do
			local positiveX = bodyHalfX + edgePadding
			local positiveZ = bodyHalfZ + edgePadding
			local clampedX = math.clamp(localPosition.X, -bodyHalfX, bodyHalfX)
			local clampedZ = math.clamp(localPosition.Z, -bodyHalfZ, bodyHalfZ)
			local candidates = {
				Vector3.new(positiveX, 0, clampedZ),
				Vector3.new(-positiveX, 0, clampedZ),
				Vector3.new(clampedX, 0, positiveZ),
				Vector3.new(clampedX, 0, -positiveZ),
				Vector3.new(positiveX, 0, positiveZ),
				Vector3.new(positiveX, 0, -positiveZ),
				Vector3.new(-positiveX, 0, positiveZ),
				Vector3.new(-positiveX, 0, -positiveZ),
			}
			table.sort(candidates, function(a: Vector3, b: Vector3): boolean
				return (a - localPosition).Magnitude < (b - localPosition).Magnitude
			end)
			for _, candidate in candidates do
				exitPosition = groundedExit(candidate)
				if exitPosition ~= nil then
					break
				end
			end
			if exitPosition ~= nil then
				break
			end
		end
		if exitPosition == nil then
			-- Every fallback ring failed ground, vehicle, obstacle or character clearance.
			-- Leaving the avatar in place is safer than teleporting into unvalidated geometry;
			-- the active arrival monitor retries on the next Heartbeat while the car approaches.
			continue
		end
		table.insert(reservedExits, { position = exitPosition, size = clearanceSize })
		local facePosition = Vector3.new(finalBox.Position.X, exitPosition.Y, finalBox.Position.Z)
		local exitFrame = if (facePosition - exitPosition).Magnitude > 0.01
			then CFrame.lookAt(exitPosition, facePosition, finalPivot.UpVector)
			else CFrame.new(exitPosition) * finalPivot.Rotation

		local function forceExit(force: boolean)
			if otherPlayer.Character ~= character or character.Parent == nil then
				return
			end
			local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
			local currentRoot = character:FindFirstChild("HumanoidRootPart")
			if currentHumanoid == nil or currentRoot == nil or not currentRoot:IsA("BasePart") then
				return
			end
			local seatPart = currentHumanoid.SeatPart
			local attachedToIncoming = seatPart ~= nil and seatPart:IsDescendantOf(model)
			if not force
				and not attachedToIncoming
				and not pointInsideParkingFootprint(currentRoot.Position, finalBox, detectionHalf)
			then
				return
			end
			currentHumanoid.Sit = false
			if seatPart ~= nil then
				local seatWeld = seatPart:FindFirstChild("SeatWeld")
				if seatWeld ~= nil then
					seatWeld:Destroy()
				end
			end
			currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
			character:PivotTo(exitFrame)
		end

		forceExit(true)
		for _, delaySeconds in { 0.05, 0.15, 0.35 } do
			task.delay(delaySeconds, function()
				forceExit(false)
			end)
		end
	end
end

-- RoadTraffic moves a collidable model every Heartbeat. Arm the clearance far enough from
-- the destination that the avatar is already safe before the first chassis step enters it.
local function armParkingFootprintClearance(
	model: Model,
	finalPivot: CFrame,
	isValid: () -> boolean
)
	local _, size = model:GetBoundingBox()
	local triggerDistance = math.max(size.X, size.Z) * 0.5 + 10
	task.spawn(function()
		while model.Parent ~= nil
			and model:GetAttribute("Arriving") == true
			and isValid()
		do
			local delta = model:GetPivot().Position - finalPivot.Position
			if Vector2.new(delta.X, delta.Z).Magnitude <= triggerDistance
				and parkingFootprintOccupied(model, finalPivot)
			then
				clearCharactersFromParkingFootprint(model, finalPivot)
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

local function attachRepairPromptIfNeeded(
	player: Player,
	model: Model,
	car: ActiveCarSave,
	workingIndex: number
)
	if car.state ~= "Junk" and car.state ~= "Repairing" then
		return
	end
	local partId = DealerCarConfig.nextRepairPart(car.tutorialDealIndex, car.parts)
	if partId == nil then
		return
	end
	local hold = DealerCarConfig.PART_REPAIR_SECONDS
		/ TycoonConfig.repairMultiplierFor(DealerCar.pads(player), partId)
	local bodyPreviewActive = false
	CarVisuals.attachRepairPrompt(model, partId, DealerCarConfig.displayName(car.templateId), hold, function(triggerPlayer: Player)
		if triggerPlayer == player then
			bodyPreviewActive = false
			DealerCar.repairPart(player, partId, nil, workingIndex)
			if model.Parent ~= nil then
				model:SetAttribute("BrokenRepairInProgress", false)
				model:SetAttribute("BrokenRepairDuration", nil)
				if partId == "Body"
					and bodyDamageTemplate(car.templateId)
					and model:GetAttribute("DealerConditionBody") ~= true
				then
					model:SetAttribute("BrokenAmount", 1)
				end
			end
		end
	end, function(holdingPlayer: Player)
		if holdingPlayer == player
			and partId == "Body"
			and bodyDamageTemplate(car.templateId)
			and model.Parent ~= nil
			and model:GetAttribute("DealerConditionBody") ~= true
		then
			bodyPreviewActive = true
			model:SetAttribute("BrokenRepairDuration", hold)
			model:SetAttribute("BrokenRepairInProgress", true)
			-- The client interpolates the whole 1 -> 0 range over this exact hold duration.
			model:SetAttribute("BrokenAmount", 0)
		end
	end, function(holdingPlayer: Player)
		if holdingPlayer ~= player or not bodyPreviewActive then
			return
		end
		bodyPreviewActive = false
		-- Triggered and HoldEnded can be delivered in the same frame. Give the successful
		-- repair time to stamp DealerConditionBody before restoring a cancelled preview.
		task.delay(0.15, function()
			if model.Parent ~= nil and model:GetAttribute("DealerConditionBody") ~= true then
				model:SetAttribute("BrokenRepairInProgress", false)
				model:SetAttribute("BrokenRepairDuration", nil)
				model:SetAttribute("BrokenAmount", 1)
			end
		end)
	end)
end

local function conditionMatches(model: Model, car: ActiveCarSave): boolean
	local expectedMissing = if car.parts.Wheels == true or car.condition.missingWheels == nil
		then nil
		else table.concat(car.condition.missingWheels, ",")
	return model:GetAttribute("DealerConditionBody") == (car.parts.Body == true)
		and model:GetAttribute("DealerConditionWheels") == (car.parts.Wheels == true)
		and model:GetAttribute("DealerConditionEngine") == (car.parts.Engine == true)
		and model:GetAttribute("DealerConditionRepaired") == looksRepaired(car)
		and model:GetAttribute("DealerConditionServiced") == (car.condition.oilLeak ~= true)
		and model:GetAttribute("DealerConditionWashed") == (car.condition.dirty ~= true)
		and (car.condition.missingWheels == nil
			or model:GetAttribute("DealerMissingWheelCorners") == expectedMissing)
end

-- Rebuilds one exact W/P model. Animated working arrivals use the road/queue path;
-- animated display arrivals use the shared Used Cars final-leg parking planner.
function DealerCar.spawn(
	player: Player,
	record: Record,
	animateArrival: boolean?,
	slot: CarSlot?,
	slotIndex: number?,
	sourceModel: Model?
): Model?
	local resolvedSlot: CarSlot = slot or "working"
	local resolvedIndex = resolveSlotIndex(resolvedSlot, slotIndex)
	if resolvedIndex == nil then
		return nil
	end
	local map = modelMap(resolvedSlot, resolvedIndex)
	local oldModel = DealerCar.model(player, resolvedSlot, resolvedIndex)
	local previousValue = if oldModel ~= nil then oldModel:GetAttribute("Value") else nil
	local sourceStart = if sourceModel ~= nil
		and animateArrival == true
		and resolvedSlot == "working"
		then sourceModel:GetPivot()
		else nil
	-- A continuous listing/parking handoff may already have registered sourceModel in
	-- the destination map. Do not destroy the exact model we are about to adopt.
	if oldModel ~= nil and oldModel ~= sourceModel then
		oldModel:Destroy()
	end
	map[player] = nil
	local car = carForSlot(player, resolvedSlot, resolvedIndex)
	if car == nil or car.state == "Sold" then
		if resolvedSlot == "display" then
			LotSlots.setDisplayStatus(record, false, 0, resolvedIndex)
		end
		return nil
	end
	ensureTowCondition(car, sourceModel)
	-- Rolling saves may carry the former deal-2/deal-3 template and its old pre-repaired
	-- layout. tutorialDealIndex + templateId + parts are enough to normalize them in place.
	local normalizedTutorialCar = DealerCar.normalizeTutorialCar(car)
	if normalizedTutorialCar then
		-- A rolling save can become complete solely because the new tutorial contract
		-- marks parts as pre-repaired. Promote it now so Repairing cannot deadlock with
		-- no remaining prompt; Ready still requires all three real part bits.
		if (car.state == "Junk" or car.state == "Repairing")
			and CarVisuals.allPartsRepaired(car.parts)
		then
			car.state = "Ready"
		end
		DataService.save(player)
	end
	if resolvedSlot == "working" then
		local pipeline = OwnerCarPipeline.ensure(car)
		if car.atBay == true
			or (pipeline.state == "complete" and pipeline.escortId ~= nil)
		then
			-- Owned pipeline cars reserve their exact W save slot while physically away.
			-- A completed escort waits model-free for a dealership P slot after rejoin.
			return nil
		end
	end

	local displayIndex = if resolvedSlot == "display" then resolvedIndex else nil
	local workingIndex = if resolvedSlot == "working" then resolvedIndex else nil
	local target = LotSlots.targetCFrame(record, car.state, displayIndex, workingIndex)
	local shouldAnimateWorking = animateArrival == true and resolvedSlot == "working"
	local shouldAnimateDisplay = animateArrival == true and resolvedSlot == "display" and sourceModel == nil
	local shouldAnimate = shouldAnimateWorking or shouldAnimateDisplay
	if sourceModel ~= nil then
		local queuedTemplate = sourceModel:GetAttribute("TemplateId")
		if queuedTemplate ~= nil and queuedTemplate ~= car.templateId then
			return nil
		end
	end
	local spawnParent = if shouldAnimateDisplay then ServerStorage else LotSlots.carFolder(record)
	local model = sourceModel or CarVisuals.spawn(car.templateId, target, spawnParent)
	if model == nil then
		return nil
	end
	-- The adopted queue proxy is the last indisputable provenance boundary. Normalize once
	-- more from its live attributes before stamping inventory/debug state and before saving.
	ensureTowCondition(car, model)
	-- Queue clones keep IncomingQueueCar_01 through FIFO. Owned stock, inspection and
	-- DealerCarClient all require this name once the car is on a working pad.
	model.Name = "DealerCar"
	if model:GetAttribute("DealerProxyId") == nil then
		model:SetAttribute("DealerProxyId", car.tradeId)
	end
	-- Condition visuals need these identities before the first applyCondition call.
	model:SetAttribute("TradeId", car.tradeId)
	-- A queue-adopted model already owns the swatch selected from queueId. Fresh/restored
	-- W/P clones receive the persisted id before applyCondition so its base-color reset is stable.
	local liveFactoryPaintId = model:GetAttribute("FactoryPaintId")
	if typeof(car.factoryPaintId) == "string" and car.factoryPaintId ~= "" then
		model:SetAttribute("FactoryPaintId", car.factoryPaintId)
	elseif typeof(liveFactoryPaintId) == "string" and liveFactoryPaintId ~= "" then
		car.factoryPaintId = liveFactoryPaintId
	end
	model:SetAttribute("TutorialDealIndex", car.tutorialDealIndex)
	model:SetAttribute("TowStock", car.condition.towStock == true or car.sellerId == "TowTruckTony")
	model:SetAttribute("DealerTowStockCondition", car.condition.towStock == true)
	model:SetAttribute(
		"DealerSavedMissingWheels",
		if car.condition.missingWheels ~= nil then table.concat(car.condition.missingWheels, ",") else nil
	)
	if not shouldAnimateDisplay then
		model.Parent = LotSlots.carFolder(record)
	end
	-- Queue promotion can restore an authored DrivePrompt/VehicleSeat. Dealer inventory is
	-- staff-only in every state, including this source-model handoff.
	CarVisuals.lockDealerDriving(model)
	if resolvedSlot == "display" and sourceModel ~= nil then
		-- Queue-only identity and its helper must not survive the authoritative P handoff.
		model:SetAttribute("AwaitingDisplayQueueIndex", nil)
		model:SetAttribute("AutomatedDealerVehicleProxy", nil)
		model:SetAttribute("DealerJourneyHolding", nil)
		local queueHelper = DealerCar.driver(model)
		if queueHelper ~= nil
			and (queueHelper:GetAttribute("AwaitingDisplayHelper") == true
				or string.find(queueHelper.Name, "ParkingHelper", 1, true) ~= nil)
		then
			queueHelper:Destroy()
		end
	end
	-- Apply the missing-wheel state before measuring clearance. Settling first measures all four
	-- tyres, then hiding one and rotating the chassis produces a hovering or level-looking car.
	if sourceModel == nil or not conditionMatches(model, car) then
		CarVisuals.applyCondition(model, car.parts, looksRepaired(car), car.condition.oilLeak ~= true, car.condition.dirty ~= true, car.condition.missingWheels)
	end
	local appliedFactoryPaintId = model:GetAttribute("FactoryPaintId")
	if typeof(appliedFactoryPaintId) == "string" and appliedFactoryPaintId ~= "" then
		car.factoryPaintId = appliedFactoryPaintId
	end
	-- Never move the live queued model merely to calculate its final grounded W frame.
	-- Those temporary CFrames replicate and appear as backtrack/air/teleport glitches.
	local settleModel = if sourceStart ~= nil then model:Clone() else model
	if settleModel ~= model then
		settleModel.Parent = nil
		-- The clone starts at Q1. Move only this unreplicated probe to the authoritative W
		-- target before settling it; otherwise its XZ remains Q1 and P5 routes back to queue.
		CarVisuals.pivotToUprightFrame(settleModel, target)
	elseif not shouldAnimate and (oldModel == nil or sourceModel ~= nil) then
		-- Restore/direct handoff settles the live model immediately instead of using a road
		-- approach. Clear the projected W/P footprint before settleOnVisibleTires pivots it.
		clearCharactersFromParkingFootprint(model, target)
	end
	local parked = if resolvedSlot == "display"
		then CarVisuals.settleOnVisibleTires(
			settleModel,
			LotSlots.targetTop(record, car.state, displayIndex, nil),
			0.01
		)
		else CarVisuals.settleOnVisibleTires(
			settleModel,
			LotSlots.targetTop(record, car.state, nil, workingIndex),
			DealerCarConfig.PARK_CLEARANCE
		)
	if settleModel ~= model then
		settleModel:Destroy()
	end
	local breakdown = DealerCar.valueBreakdown(player, car)
	if resolvedSlot == "display" then
		LotSlots.setDisplayStatus(record, true, breakdown.listedPrice, resolvedIndex)
	end
	CarVisuals.applyPaintHue(model, (car :: any).paintHue)
	CarVisuals.applyNeon(model, CarVisuals.template(car.templateId).model, (car :: any).neonColorId)
	local pipeline = OwnerCarPipeline.ensure(car)
	CarVisuals.applyWindowTint(model, pipeline.completed.tuningBody == true)
	model:SetAttribute("PipelineState", pipeline.state)
	model:SetAttribute("PipelineStage", OwnerCarPipeline.currentStage(car))
	model:SetAttribute("ConditionDirty", car.condition.dirty == true)
	model:SetAttribute("ConditionOilLeak", car.condition.oilLeak == true)
	CarVisuals.setRunningLights(model, shouldAnimate)
	map[player] = model

	model:SetAttribute("DealerSlot", resolvedSlot)
	if resolvedSlot == "display" then
		model:SetAttribute("DisplaySlotIndex", resolvedIndex)
	else
		model:SetAttribute("WorkingSlotIndex", resolvedIndex)
	end
	model:SetAttribute("TradeId", car.tradeId)
	model:SetAttribute("TutorialDealIndex", car.tutorialDealIndex)
	model:SetAttribute("DealerJourneyId", OwnerCarPipeline.journeyId(car))
	model:SetAttribute("DealerJourneyStatus", if resolvedSlot == "display" then "completed" else pipeline.state)
	model:SetAttribute("State", car.state)
	model:SetAttribute("Value", breakdown.listedPrice)
	model:SetAttribute("CalculatedValue", breakdown.calculatedValue)
	model:SetAttribute("ServiceMultiplier", breakdown.serviceMultiplier)
	model:SetAttribute("ListedPrice", breakdown.listedPrice)
	model:SetAttribute("Cost", car.cost)
	CarVisuals.setValueBillboard(
		model,
		DealerCarConfig.displayName(car.templateId),
		breakdown.listedPrice,
		DealerCarConfig.manualRepairValue(car.tutorialDealIndex, car.parts),
		not shouldAnimate,
		if typeof(previousValue) == "number" then previousValue :: number else nil
	)

	local token = if resolvedSlot == "working" then bumpToken(player, resolvedIndex) else 0
	if shouldAnimateWorking then
		model:SetAttribute("Arriving", true)
		if sourceStart ~= nil then
			model:SetAttribute("QueueState", "EnteringW")
		end
		local sourceDelta = if sourceStart ~= nil then sourceStart.Position - parked.Position else nil
		local alreadyAtWorkingPad = sourceDelta ~= nil
			and Vector2.new(sourceDelta.X, sourceDelta.Z).Magnitude <= 0.75
		local points = if alreadyAtWorkingPad
			then { (sourceStart :: CFrame).Position }
			elseif sourceStart ~= nil
			then LotSlots.queuePromotionPoints(record, sourceStart, parked)
			else RoadTraffic.arrivalPoints(record, parked)
		if #points >= 2 and sourceStart == nil then
			-- Route heights may differ, but a car must receive yaw only.
			local delta = points[2] - points[1]
			local heading = Vector3.new(delta.X, 0, delta.Z)
			if heading.Magnitude > 0.01 then
				model:PivotTo(CFrame.lookAt(points[1], points[1] + heading.Unit))
			else
				model:PivotTo(CFrame.new(points[1]) * parked.Rotation)
			end
		end
		DealerCar.addDriver(model, car.sellerId)
		task.spawn(function()
			local function validWorkingArrival(): boolean
				return driveToken[resolvedIndex][player] == token
					and workingModels[resolvedIndex][player] == model
			end
			armParkingFootprintClearance(model, parked, validWorkingArrival)
			local finished = RoadTraffic.drive(model, points, DealerCarConfig.ARRIVE_SPEED, validWorkingArrival, {
				steer = sourceStart == nil,
				initialLook = if sourceStart ~= nil then sourceStart.LookVector else nil,
			})
			if not finished
				or model.Parent == nil
				or workingModels[resolvedIndex][player] ~= model
			then
				return
			end
			-- P5 already equals parked.Position for a queue promotion. Preserve its reached
			-- position and apply only authored yaw; a road arrival uses the exact parked frame.
			local finalParked = if sourceStart ~= nil
				then CFrame.new(model:GetPivot().Position) * parked.Rotation
				else parked
			clearCharactersFromParkingFootprint(model, finalParked)
			model:PivotTo(finalParked)
			CarVisuals.resetWheels(model)
			CarVisuals.setRunningLights(model, false)
			-- RoadTraffic.drive already finalizes the driver with its ride generation.
			-- Repeating endRide here used to PivotTo a still-welded rig and tip the chassis.
			model:SetAttribute("Arriving", false)
			model:SetAttribute("QueueState", nil)
			model:SetAttribute("QueueTarget", nil)
			CarVisuals.setValueBillboardEnabled(model, true)
			local current = DealerCar.active(player, resolvedIndex)
			if current ~= nil and current.tradeId == car.tradeId then
				attachRepairPromptIfNeeded(player, model, current, resolvedIndex)
			end
			DealerCar.publish(player)
			GameplayEvents.emit("CarArrived", player, {
				tradeId = current and current.tradeId or car.tradeId,
				carId = current and current.templateId or car.templateId,
				templateId = current and current.templateId or car.templateId,
				tutorialDealIndex = current and current.tutorialDealIndex or car.tutorialDealIndex,
				ask = current and current.ask or car.ask,
				workingIndex = resolvedIndex,
			})
			DealerCar.arrived:Fire(player, record, resolvedIndex)
			DealerCar.stateChanged:Fire(
				player,
				current and current.state or "None",
				"working",
				resolvedIndex
			)
		end)
	elseif shouldAnimateDisplay then
		-- The client-owned Service Helper proxy finishes at the Used Cars entrance. Continue
		-- with a server-visible clone from that exact seam so every observer sees the same P.
		model:SetAttribute("Arriving", true)
		model:SetAttribute("ParkingForDisplay", true)
		-- This is the compatibility arrival for a persisted owner pipeline, so use that
		-- exact car's rollout decision. Reading the global flag here would switch an old V1
		-- car to V2 after a deploy, despite its saved routing latch.
		local plan = RoadTraffic.displayParkingPlan(record, parked, pipeline.routingV2.usedParking)
		if #plan.forward >= 2 then
			local heading = plan.forward[2] - plan.forward[1]
			if Vector3.new(heading.X, 0, heading.Z).Magnitude > 0.01 then
				model:PivotTo(CFrame.lookAt(plan.forward[1], plan.forward[1] + Vector3.new(heading.X, 0, heading.Z).Unit))
			else
				model:PivotTo(CFrame.new(plan.forward[1]) * parked.Rotation)
			end
		else
			clearCharactersFromParkingFootprint(model, parked)
			model:PivotTo(parked)
		end
		local parkingDriver = DealerCar.addDriver(model)
		if parkingDriver ~= nil then
			applyEscortAppearance(record, parkingDriver, pipeline.escortId)
		end
		model.Parent = LotSlots.carFolder(record)
		task.spawn(function()
			local function validDisplay(): boolean
				return model.Parent ~= nil and displayModels[resolvedIndex][player] == model
			end
			armParkingFootprintClearance(model, parked, validDisplay)
			local finished = true
			if #plan.forward >= 2 then
				finished = RoadTraffic.drive(model, plan.forward, DealerCarConfig.ARRIVE_SPEED, validDisplay, {
					steer = true,
					initialLook = model:GetPivot().LookVector,
				})
			end
			if finished and #plan.reversePark >= 2 then
				finished = RoadTraffic.drive(model, plan.reversePark, math.min(DealerCarConfig.ARRIVE_SPEED, 10), validDisplay, {
					steer = true,
					reverse = true,
				})
			end
			if not finished or not validDisplay() then
				return
			end
			clearCharactersFromParkingFootprint(model, parked)
			model:PivotTo(parked)
			CarVisuals.resetWheels(model)
			CarVisuals.setRunningLights(model, false)
			if parkingDriver ~= nil and parkingDriver.Parent ~= nil then
				parkingDriver:Destroy()
			end
			model:SetAttribute("Arriving", false)
			model:SetAttribute("ParkingForDisplay", nil)
			CarVisuals.setValueBillboardEnabled(model, true)
			DealerCar.publish(player)
			DealerCar.stateChanged:Fire(player, car.state, "display", resolvedIndex)
		end)
	elseif resolvedSlot == "working" then
		attachRepairPromptIfNeeded(player, model, car, resolvedIndex)
	end
	return model
end

function DealerCar.refresh(player: Player, record: Record, slot: CarSlot?, slotIndex: number?)
	DealerCar.spawn(player, record, false, slot or "working", slotIndex)
end

local function setSlotState(
	player: Player,
	state: string,
	slot: CarSlot,
	slotIndex: number?,
	refreshCondition: boolean?
)
	local resolvedIndex = resolveSlotIndex(slot, slotIndex)
	if resolvedIndex == nil then
		return
	end
	local car = carForSlot(player, slot, resolvedIndex)
	if car == nil then
		return
	end
	local previousState = car.state
	car.state = state
	local record = TycoonService.getForPlayer(player)
	local model = DealerCar.model(player, slot, resolvedIndex)
	local keepExistingModel = model ~= nil and model.Parent ~= nil and state ~= "Sold"
	-- State/part changes do not move a car to another slot. Keep the exact physical model and
	-- update its visuals/prompts in place; destroying it before cloning the same template caused
	-- a visible one-frame blink whenever the mechanic completed a Junk Spot repair.
	if record ~= nil and state ~= "Sold" and not keepExistingModel then
		DealerCar.refresh(player, record, slot, resolvedIndex)
	elseif model ~= nil then
		model:SetAttribute("State", state)
		if keepExistingModel then
			local breakdown = DealerCar.valueBreakdown(player, car)
			model:SetAttribute("Value", breakdown.listedPrice)
			model:SetAttribute("CalculatedValue", breakdown.calculatedValue)
			model:SetAttribute("ServiceMultiplier", breakdown.serviceMultiplier)
			model:SetAttribute("ListedPrice", breakdown.listedPrice)
			model:SetAttribute("Cost", car.cost)
			if refreshCondition ~= false then
				CarVisuals.applyCondition(model, car.parts, looksRepaired(car), car.condition.oilLeak ~= true, car.condition.dirty ~= true, car.condition.missingWheels)
				if record ~= nil
					and slot == "working"
					and model:GetAttribute("Arriving") ~= true
				then
					-- Repairing a wheel changes both rotation and contact geometry. Rebuild the
					-- pose from the authored upright W frame, then settle the current visible tyres.
					local targetFrame = LotSlots.targetCFrame(record, car.state, nil, resolvedIndex)
					local current = model:GetPivot()
					CarVisuals.pivotToUprightFrame(
						model,
						CFrame.new(current.Position) * targetFrame.Rotation
					)
					CarVisuals.settleOnVisibleTires(
						model,
						LotSlots.targetTop(record, car.state, nil, resolvedIndex),
						DealerCarConfig.PARK_CLEARANCE
					)
				end
			end
			CarVisuals.setValueBillboard(
				model,
				DealerCarConfig.displayName(car.templateId),
				breakdown.listedPrice,
				DealerCarConfig.manualRepairValue(car.tutorialDealIndex, car.parts),
				true,
				previousState == state and breakdown.listedPrice or nil
			)
			local oldAnchor = model:FindFirstChild("RepairPromptAnchor", true)
			if oldAnchor ~= nil then oldAnchor:Destroy() end
			local oldMarker = model:FindFirstChild("RepairEngineMarker", true)
			if oldMarker ~= nil then oldMarker:Destroy() end
			if slot == "working" then
				attachRepairPromptIfNeeded(player, model, car, resolvedIndex)
			end
		end
	end
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, state, slot, resolvedIndex)
	if record ~= nil then
		local TradeService = require(script.Parent.TradeService)
		TradeService.refreshListPrompt(player, record)
	end
end

function DealerCar.setState(player: Player, state: string, workingIndex: number?, refreshCondition: boolean?)
	setSlotState(player, state, "working", workingIndex, refreshCondition)
end

function DealerCar.setDisplayState(player: Player, state: string, displayIndex: number?)
	setSlotState(player, state, "display", displayIndex)
end

-- Places source-agnostic stock into the first (or preferred) free Used Cars slot.
function DealerCar.placeDisplayStock(
	player: Player,
	record: Record,
	car: ActiveCarSave,
	preferredDisplayIndex: number?,
	sourceModel: Model?
): (boolean, number?)
	local data = DataService.get(player)
	local resolvedIndex = if preferredDisplayIndex ~= nil
		then resolveDisplayIndex(preferredDisplayIndex)
		else DealerCar.availableDisplayIndex(player)
	if data == nil
		or resolvedIndex == nil
		or resolvedIndex > DealerCar.displayCapacity(player)
		or DealerCar.display(player, resolvedIndex) ~= nil
		or (DealerCar.displayReservation(player, resolvedIndex) ~= nil
			and DealerCar.displayReservation(player, resolvedIndex) ~= car.tradeId)
		or record.owner ~= player
	then
		return false, resolvedIndex
	end

	local oldState = car.state
	local oldListedPrice = car.listedPrice
	car.state = "Listed"
	if car.listedPrice <= 0 then
		car.listedPrice = DealerCar.valueBreakdown(player, car).listedPrice
	end
	DataService.setDisplay(data, resolvedIndex, car)

	local map = displayModelMap(resolvedIndex)
	local stale = map[player]
	if stale ~= nil and stale ~= sourceModel then
		stale:Destroy()
	end
	if sourceModel ~= nil then
		map[player] = sourceModel
	end
	DealerCar.spawn(player, record, false, "display", resolvedIndex)
	local displayed = DealerCar.displayModel(player, resolvedIndex)
	if displayed == nil or displayed.Parent == nil then
		DataService.setDisplay(data, resolvedIndex, nil)
		car.state = oldState
		car.listedPrice = oldListedPrice
		map[player] = nil
		LotSlots.setDisplayStatus(record, false, 0, resolvedIndex)
		return false, resolvedIndex
	end

	DealerCar.releaseDisplay(player, resolvedIndex, car.tradeId)
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "Listed", "display", resolvedIndex)
	return true, resolvedIndex
end

-- Authoritative exact-slot removal for a completed/cancelled display trade.
function DealerCar.removeDisplayStock(
	player: Player,
	displayIndex: number?,
	expectedTradeId: string?
): (ActiveCarSave?, Model?)
	local data = DataService.get(player)
	local resolvedIndex = resolveDisplayIndex(displayIndex)
	local car = if data ~= nil and resolvedIndex ~= nil then DealerCar.display(player, resolvedIndex) else nil
	if data == nil
		or resolvedIndex == nil
		or car == nil
		or (expectedTradeId ~= nil and expectedTradeId ~= "" and car.tradeId ~= expectedTradeId)
	then
		return nil, nil
	end
	local model = DealerCar.detachModel(player, "display", resolvedIndex)
	DataService.setDisplay(data, resolvedIndex, nil)
	local record = TycoonService.getForPlayer(player)
	if record ~= nil then
		LotSlots.setDisplayStatus(record, false, 0, resolvedIndex)
	end
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "None", "display", resolvedIndex)
	return car, model
end

-- Authoritative exact-slot removal for seller refusal, rollback, or departure.
function DealerCar.removeWorking(
	player: Player,
	workingIndex: number?,
	expectedTradeId: string?
): (ActiveCarSave?, Model?)
	local data = DataService.get(player)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	local car = if data ~= nil and resolvedIndex ~= nil then DealerCar.active(player, resolvedIndex) else nil
	if data == nil
		or resolvedIndex == nil
		or car == nil
		or (expectedTradeId ~= nil and expectedTradeId ~= "" and car.tradeId ~= expectedTradeId)
	then
		return nil, nil
	end
	local model = DealerCar.detachModel(player, "working", resolvedIndex)
	DataService.setWorking(data, resolvedIndex, nil)
	DealerCar.publish(player)
	DealerCar.stateChanged:Fire(player, "None", "working", resolvedIndex)
	return car, model
end

-- The driven model and exact W/P identities are the atomic listing commit guard.
function DealerCar.finishListing(
	player: Player,
	record: Record,
	expectedModel: Model,
	displayIndex: number?,
	workingIndex: number?
): (boolean, number?, number?)
	local data = DataService.get(player)
	local modelWorkingIndex = tonumber(expectedModel:GetAttribute("WorkingSlotIndex"))
	local resolvedWorkingIndex = resolveWorkingIndex(workingIndex or modelWorkingIndex or 1)
	local resolvedDisplayIndex = if displayIndex ~= nil
		then resolveDisplayIndex(displayIndex)
		else DealerCar.availableDisplayIndex(player)
	if data == nil
		or resolvedWorkingIndex == nil
		or resolvedDisplayIndex == nil
		or resolvedDisplayIndex > DealerCar.displayCapacity(player)
	then
		return false, resolvedDisplayIndex, resolvedWorkingIndex
	end

	local car = DealerCar.active(player, resolvedWorkingIndex)
	local model = DealerCar.model(player, "working", resolvedWorkingIndex)
	if car == nil
		or DataService.getWorking(data, resolvedWorkingIndex) ~= car
		or DealerCar.display(player, resolvedDisplayIndex) ~= nil
		or not DealerCar.isReadyForListing(car)
		or model ~= expectedModel
		or model == nil
		or model.Parent == nil
		or model:GetAttribute("TradeId") ~= car.tradeId
		or record.owner ~= player
	then
		return false, resolvedDisplayIndex, resolvedWorkingIndex
	end

	workingModels[resolvedWorkingIndex][player] = nil
	bumpToken(player, resolvedWorkingIndex)
	DataService.setWorking(data, resolvedWorkingIndex, nil)
	local ok = DealerCar.placeDisplayStock(
		player,
		record,
		car,
		resolvedDisplayIndex,
		model
	)
	if not ok then
		DataService.setWorking(data, resolvedWorkingIndex, car)
		car.state = "Ready"
		DealerCar.spawn(player, record, false, "working", resolvedWorkingIndex)
		DealerCar.publish(player)
		return false, resolvedDisplayIndex, resolvedWorkingIndex
	end

	DealerCar.stateChanged:Fire(player, "None", "working", resolvedWorkingIndex)
	return true, resolvedDisplayIndex, resolvedWorkingIndex
end

-- Creates the next junk car on offer, priced but not yet owned.
function DealerCar.createIncoming(
	player: Player,
	templateId: string?,
	ask: number?,
	workingIndex: number?,
	incomingVariant: IncomingVariant?,
	incomingCondition: DataService.VehicleConditionSave?
): ActiveCarSave?
	local data = DataService.get(player)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	if data == nil
		or resolvedIndex == nil
		or resolvedIndex > DealerCar.workingCapacity(player)
		or DataService.getWorking(data, resolvedIndex) ~= nil
		or workingTransition[resolvedIndex][player] == true
	then
		return nil
	end

	local resolvedTemplateId = templateId
	local resolvedAsk = ask
	local tutorialDealIndex = 0
	local tutorialWildcard = false
	local tutorial = data.tutorial
	if templateId == nil
		and tutorial.eligible == true
		and tutorial.completed ~= true
		and tutorial.dealIndex >= 1
		and tutorial.dealIndex <= DealerCarConfig.TUTORIAL_DEAL_COUNT
	then
		tutorialDealIndex = tutorial.dealIndex
		local tutorialDeal = DealerCarConfig.tutorialDeal(tutorialDealIndex)
		assert(tutorialDeal ~= nil, `Missing tutorial deal {tutorialDealIndex}`)
		resolvedTemplateId = tutorialDeal.carId
		resolvedAsk = 25
		-- Authored tutorial cars may bypass their ordinary selector gate.
		tutorialWildcard = tutorialDeal.wildcard == true
	end

	local template = if resolvedTemplateId ~= nil
		then CarVisuals.template(resolvedTemplateId)
		else DealerCarConfig.selectArrival(data.pads, data.luck)
	local variant = incomingVariant
	if tutorialDealIndex == 0 and variant == nil then
		local odds = DealerCarConfig.arrivalOdds(template.id, data.pads, data.luck)
		local rarity = DealerCarConfig.rarityTier(odds.oneInN)
		variant = LuckConfig.rollIncomingVariant(rarity.id, data.luck)
	end
	if variant == nil then
		variant = LuckConfig.rollIncomingVariant("common", LuckConfig.DEFAULT, function() return 0.999 end)
	end
	if tutorialDealIndex == 0 then
		data.carIndex += 1
	end
	local tradeId = TradeContract.newTradeId(player, template.id)
	local initialParts = if tutorialDealIndex > 0
		then DealerCarConfig.tutorialParts(tutorialDealIndex)
		else {
			Body = false,
			-- The condition is rolled before a queued proxy appears and carried into W.
			-- Direct arrivals roll here once. A present wheel set skips the Wheels task.
			Wheels = if incomingCondition ~= nil
				then incomingCondition.wheelsPresent == true
				else not rollMissingWheelCondition(),
			Engine = false,
		}
	local car: ActiveCarSave = {
		templateId = template.id,
		state = "Incoming",
		parts = initialParts,
		haggleUsed = false,
		offered = 0,
		ask = resolvedAsk or math.max(1, math.floor(DealerCarConfig.askingPrice(template) * variant.askMultiplier)),
		cost = 0,
		serviceCost = 0,
		serviceCostPaid = 0,
		serviced = false,
		atBay = false,
		serviceRollDone = false,
		serviceQueuedAt = 0,
		sellerId = TownsfolkConfig.pickSeller().id,
		customerId = nil,
		tradeId = tradeId,
		tutorialDealIndex = tutorialDealIndex,
		tutorialWildcard = tutorialWildcard,
		listedPrice = 0,
		pipeline = {
			revision = OwnerCarPipeline.REVISION,
			state = "idle",
			plan = {},
			nextIndex = 1,
			completed = {
				tuningBody = variant.bodyKit == true,
				tuningPaint = variant.paintHue ~= nil,
			},
			skipped = {},
			currentStage = nil,
			currentSlot = nil,
			queuedAt = nil,
			lastQueuedWarningAt = nil,
			escortId = nil,
			routingV2 = {
				service = false,
				usedParking = false,
				tow = false,
			},
		},
		condition = {
			-- Tutorial defects map one-to-one to Body/Wheels/Engine. Independent grime or
			-- oil would survive those repairs and contradict the authored diagnosis.
			dirty = if tutorialDealIndex > 0
				then false
				else if incomingCondition ~= nil then incomingCondition.dirty == true else rollDirtyCondition(),
			oilLeak = if tutorialDealIndex > 0
				then false
				else if incomingCondition ~= nil then incomingCondition.oilLeak == true else rollOilLeakCondition(),
			wheelsPresent = initialParts.Wheels == true,
			missingWheels = if incomingCondition ~= nil and incomingCondition.missingWheels ~= nil
				then table.clone(incomingCondition.missingWheels)
				else nil,
			towStock = incomingCondition ~= nil and incomingCondition.towStock == true,
		},
		factoryPaintId = nil,
		paintHue = variant.paintHue,
		neonColorId = variant.neonColorId,
	}
	DataService.setWorking(data, resolvedIndex, car)
	return car
end

function DealerCar.repairPart(
	player: Player,
	partId: string,
	source: string?,
	workingIndex: number?
)
	local resolvedIndex = resolveWorkingIndex(workingIndex)
	if resolvedIndex == nil or repairing[resolvedIndex][player] then
		return
	end
	local data = DataService.get(player)
	local record = TycoonService.getForPlayer(player)
	local car = if data ~= nil then DataService.getWorking(data, resolvedIndex) else nil
	if data == nil or record == nil or car == nil then
		return
	end
	if car.state ~= "Junk" and car.state ~= "Repairing" then
		return
	end
	if DealerCar.isArriving(player, resolvedIndex) then
		return
	end
	local known = false
	for _, part in DealerCarConfig.PARTS do
		if part.id == partId then
			known = true
			break
		end
	end
	local expectedPart = DealerCarConfig.nextRepairPart(car.tutorialDealIndex, car.parts)
	if not known or expectedPart ~= partId or car.parts[partId] == true then
		return
	end

	if source ~= "mechanic" and DealerCar.repairAutomated(player, resolvedIndex) then
		local alreadyPaused = DealerCar.mechanicPaused(player, resolvedIndex)
		manualRepairUntil[resolvedIndex][player] = os.clock() + MANUAL_REPAIR_IDLE_SECONDS
		if not alreadyPaused then
			DealerCar.manualRepairStarted:Fire(player, resolvedIndex)
		end
	end

	repairing[resolvedIndex][player] = true
	local effectPosition: Vector3? = nil
	local repairModel = DealerCar.model(player, "working", resolvedIndex)
	if repairModel ~= nil then
		local anchor = repairModel:FindFirstChild("RepairPromptAnchor", true)
		if anchor ~= nil and anchor:IsA("Attachment") then
			effectPosition = anchor.WorldPosition
		else
			effectPosition = repairModel:GetPivot().Position
		end
	end
	local beforeRepair = DealerCar.valueBreakdown(player, car)
	car.parts[partId] = true
	local afterRepair = DealerCar.valueBreakdown(player, car)
	local repairSource = source or "player"
	local valueGain = afterRepair.repairGains[partId]
		or math.max(0, afterRepair.listedPrice - beforeRepair.listedPrice)
	-- Extreme Tow stock consumes proportionally more workshop value as well as creating it.
	local serviceCostIncurred = OwnerCarPipeline.costForValueGain(
		repairWeight(car, partId, DealerCarConfig.partValue(partId))
	)
	local serviceCostPaidNow = math.min(serviceCostIncurred, math.max(0, math.floor(data.cash)))
	car.serviceCost += serviceCostIncurred
	car.serviceCostPaid += serviceCostPaidNow
	data.cash = math.max(0, math.floor(data.cash - serviceCostPaidNow))
	if serviceCostPaidNow > 0 then
		TycoonService.syncCash(player)
	end
	local manualCurrent, manualTotal = DealerCarConfig.tutorialManualProgress(car.tutorialDealIndex, car.parts)
	data.analytics.repairCount += 1
	if data.analytics.firstRepairAt == nil then
		data.analytics.firstRepairAt = os.time()
		print(`[Analytics] first_repair user={player.UserId}`)
	end
	repairing[resolvedIndex][player] = nil

	GameplayEvents.emit("PartFixed", player, {
		tradeId = car.tradeId,
		carId = car.templateId,
		templateId = car.templateId,
		partId = partId,
		tutorialDealIndex = car.tutorialDealIndex,
		workingIndex = resolvedIndex,
		repairSource = repairSource,
		manual = repairSource ~= "mechanic",
		valueGain = valueGain,
		serviceCost = serviceCostIncurred,
		serviceCostPaidNow = serviceCostPaidNow,
		manualRepairCurrent = manualCurrent,
		manualRepairTotal = manualTotal,
	})
	local completed = CarVisuals.allPartsRepaired(car.parts)
	Remotes.RepairVFX:FireClient(player, {
		tradeId = car.tradeId,
		workingIndex = resolvedIndex,
		partId = partId,
		position = effectPosition,
		source = repairSource,
		valueGain = valueGain,
		serviceCost = serviceCostIncurred,
		tutorialDealIndex = car.tutorialDealIndex,
		tutorialWildcard = car.tutorialWildcard == true,
	})
	if completed then
		local breakdown = DealerCar.valueBreakdown(player, car)
		GameplayEvents.emit("RepairCompleted", player, {
			tradeId = car.tradeId,
			carId = car.templateId,
			templateId = car.templateId,
			tutorialDealIndex = car.tutorialDealIndex,
			workingIndex = resolvedIndex,
			calculatedValue = breakdown.calculatedValue,
			manualRepairCount = manualCurrent,
			manualRepairTotal = manualTotal,
		})
	end
	DealerCar.setState(player, if completed then "Ready" else "Repairing", resolvedIndex)
	-- Mark every part mutation dirty; routine writes coalesce, while leave/rejoin flushes the
	-- exact partial tutorial state without a schema migration.
	DataService.save(player)
end

-- Hands the model over to whoever drives it away, so the next car can arrive while this
-- one is still leaving.
function DealerCar.detachModel(player: Player, slot: CarSlot?, slotIndex: number?): Model?
	local resolvedSlot: CarSlot = slot or "working"
	local resolvedIndex = resolveSlotIndex(resolvedSlot, slotIndex)
	if resolvedIndex == nil then
		return nil
	end
	local map = modelMap(resolvedSlot, resolvedIndex)
	local model = DealerCar.model(player, resolvedSlot, resolvedIndex)
	map[player] = nil
	if resolvedSlot == "working" then
		bumpToken(player, resolvedIndex)
	end
	return model
end

-- Sends a detached car off the lot and along the road, then drops it. A driver is added if
-- the car does not already have one, because cars do not leave by themselves.
function DealerCar.driveModelAway(
	record: Record,
	model: Model?,
	escortId: (string | number)?
)
	if model == nil then
		return
	end
	CarVisuals.clearPrompts(model)
	local driver = DealerCar.addDriver(model)
	-- The first W -> service departure is server-driven (later bay legs are client
	-- renderers), so copy the purchased helper's authored appearance here as well.
	if driver ~= nil then
		applyEscortAppearance(record, driver, escortId)
	end
	CarVisuals.setRunningLights(model, true)
	local displayIndex = tonumber(model:GetAttribute("DisplaySlotIndex"))
	local plan = RoadTraffic.departurePlan(record, model:GetPivot(), displayIndex)
	local function valid(): boolean
		return model.Parent ~= nil
	end
	if #plan.reverseOut >= 2 then
		if not RoadTraffic.drive(model, plan.reverseOut, math.min(DealerCarConfig.DEPART_SPEED, 10), valid, {
			steer = true,
			reverse = true,
		}) then
			model:Destroy()
			return
		end
	end
	if #plan.forward >= 2 then
		if not RoadTraffic.drive(model, plan.forward, DealerCarConfig.DEPART_SPEED, valid, { steer = true }) then
			model:Destroy()
			return
		end
	end
	if #plan.reversePark >= 2 then
		RoadTraffic.drive(model, plan.reversePark, math.min(DealerCarConfig.DEPART_SPEED, 10), valid, {
			steer = true,
			reverse = true,
		})
	end
	model:Destroy()
end

return DealerCar
