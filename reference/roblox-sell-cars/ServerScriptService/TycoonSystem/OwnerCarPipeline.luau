--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceConfig = require(ReplicatedStorage:WaitForChild("ServiceConfig"))
local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))

export type StageId = "repairing" | "washing" | "tuningDyno" | "tuningBody" | "tuningPaint"
export type EscortId = string | number
export type StageDefinition = {
	id: StageId,
	label: string,
	multiplier: number,
	zones: { string },
	baseChance: number,
	capChance: number,
}
export type RoutingV2Flags = {
	service: boolean,
	usedParking: boolean,
	tow: boolean,
}
export type PipelineState = {
	revision: number,
	state: string,
	plan: { StageId },
	nextIndex: number,
	completed: { [string]: boolean },
	skipped: { [string]: string },
	currentStage: StageId?,
	currentSlot: string?,
	queuedAt: number?,
	lastQueuedWarningAt: number?,
	escortId: EscortId?,
	routingV2: RoutingV2Flags,
}
export type CarCondition = {
	dirty: boolean,
	oilLeak: boolean,
}
export type StageBreakdown = {
	stage: StageId,
	label: string,
	multiplier: number,
}
export type MutableCar = { [string]: any }
export type PurchasedPads = { [string]: boolean }
export type AvailableKinds = { [string]: boolean }
export type RandomSource = () -> number

local OwnerCarPipeline = {}

OwnerCarPipeline.REVISION = 4
-- Owned-stock service is an investment, not station revenue. Charge a small share
-- of the value created by each completed stage; the remainder becomes resale upside.
OwnerCarPipeline.SERVICE_COST_RATE = 0.10

local STAGES: { StageDefinition } = {
	{
		id = "repairing",
		label = "REPAIR BAY",
		multiplier = 1.5,
		zones = { "repair" },
		baseChance = 1,
		capChance = 1,
	},
	{
		id = "washing",
		label = "CAR WASH",
		multiplier = 1.15,
		zones = { "wash", "wash2" },
		baseChance = 1,
		capChance = 1,
	},
	{
		id = "tuningDyno",
		label = "DYNO TUNE",
		multiplier = 1.35,
		zones = { "tuningDyno" },
		baseChance = 1,
		capChance = 1,
	},
	{
		id = "tuningBody",
		label = "BODY KIT",
		multiplier = 1.30,
		zones = { "tuningBody" },
		baseChance = 1,
		capChance = 1,
	},
	{
		id = "tuningPaint",
		label = "PAINT + FINISH",
		multiplier = 1.20,
		zones = { "tuningPaint" },
		baseChance = 1,
		capChance = 1,
	},
}

OwnerCarPipeline.STAGES = STAGES

local STAGE_BY_ID: { [string]: StageDefinition } = {}
for _, definition in ipairs(STAGES) do
	STAGE_BY_ID[definition.id] = definition
end

local CONFIGURED_SLOTS_BY_KIND: { [string]: { string } } = {}
for _, slot in ipairs(ServiceConfig.SLOTS) do
	local slots = CONFIGURED_SLOTS_BY_KIND[slot.kind]
	if slots == nil then
		slots = {}
		CONFIGURED_SLOTS_BY_KIND[slot.kind] = slots
	end
	table.insert(slots, slot.id)
end

local FUNCTIONAL_KINDS: { [string]: boolean } = {
	cash = true,
	speed = true,
	repair = true,
	value = true,
	npc = true,
}

local COMPLETION_FIELD: { [string]: string } = {
	repairing = "serviced",
	washing = "washed",
	tuningDyno = "tunedDyno",
	tuningBody = "tunedBody",
	tuningPaint = "tunedPaint",
}

local CONDITION_FIELD: { [string]: string } = {
	repairing = "oilLeak",
	washing = "dirty",
}

local VALID_STATES: { [string]: boolean } = {
	idle = true,
	queued = true,
	servicing = true,
	complete = true,
}

local function timestamp(value: number?): number
	return if type(value) == "number" then value else os.time()
end

local function isStageId(value: any): boolean
	return type(value) == "string" and STAGE_BY_ID[value] ~= nil
end

local function normalizePlan(rawPlan: any): { StageId }
	local requested: { [string]: boolean } = {}
	if type(rawPlan) == "table" then
		for _, value in ipairs(rawPlan) do
			if isStageId(value) then
				requested[value] = true
			end
		end
	end

	local ordered: { StageId } = {}
	for _, definition in ipairs(STAGES) do
		if requested[definition.id] == true then
			table.insert(ordered, definition.id)
		end
	end
	return ordered
end

local function normalizeCompleted(rawCompleted: any): { [string]: boolean }
	local completed: { [string]: boolean } = {}
	if type(rawCompleted) == "table" then
		for _, definition in ipairs(STAGES) do
			if rawCompleted[definition.id] == true then
				completed[definition.id] = true
			end
		end
	end
	return completed
end

local function normalizeSkipped(rawSkipped: any): { [string]: string }
	local skipped: { [string]: string } = {}
	if type(rawSkipped) == "table" then
		for _, definition in ipairs(STAGES) do
			local reason = rawSkipped[definition.id]
			if type(reason) == "string" and reason ~= "" then
				skipped[definition.id] = reason
			end
		end
	end
	return skipped
end

local function normalizeRoutingV2(rawFlags: any): RoutingV2Flags
	if type(rawFlags) ~= "table" then
		-- Existing in-flight saves must finish on V1. A journey latches the rollout
		-- flags only in begin(), so a deploy cannot switch routing underneath a car.
		return {
			service = false,
			usedParking = false,
			tow = false,
		}
	end
	return {
		service = rawFlags.service == true,
		usedParking = rawFlags.usedParking == true,
		tow = rawFlags.tow == true,
	}
end

local function zoneMatches(definition: StageDefinition, zoneId: string): boolean
	for _, candidate in ipairs(definition.zones) do
		if candidate == zoneId then
			return true
		end
	end
	return false
end

local function functionalPadRatio(definition: StageDefinition, pads: PurchasedPads): number
	local purchased = 0
	local total = 0
	for _, pad in ipairs(TycoonConfig.PADS) do
		if TycoonConfig.isPadEnabled(pad)
			and FUNCTIONAL_KINDS[pad.kind] == true
			and zoneMatches(definition, pad.zone)
		then
			total += 1
			if pads[pad.id] == true then
				purchased += 1
			end
		end
	end
	if total <= 0 then
		return 0
	end
	return math.clamp(purchased / total, 0, 1)
end

local function configuredAndAvailable(definition: StageDefinition, availableKinds: AvailableKinds): boolean
	local configuredSlots = CONFIGURED_SLOTS_BY_KIND[definition.id]
	if configuredSlots == nil or #configuredSlots == 0 then
		return false
	end
	if availableKinds[definition.id] == true then
		return true
	end
	for _, slotId in ipairs(configuredSlots) do
		if availableKinds[slotId] == true then
			return true
		end
	end
	return false
end

local function syncLegacy(car: MutableCar, pipeline: PipelineState)
	local inService = pipeline.state == "queued" or pipeline.state == "servicing"
	car.atBay = inService
	car.serviceRollDone = pipeline.state ~= "idle"
	car.serviceQueuedAt = if inService then (pipeline.queuedAt or 0) else 0
	if pipeline.completed.repairing == true then
		car.serviced = true
	end
end

function OwnerCarPipeline.ensure(car: MutableCar): PipelineState
	local rawPipeline = car.pipeline
	if type(rawPipeline) ~= "table" then
		rawPipeline = {}
	end

	local plan = normalizePlan(rawPipeline.plan)
	local completed = normalizeCompleted(rawPipeline.completed)
	local skipped = normalizeSkipped(rawPipeline.skipped)
	if car.serviced == true then
		completed.repairing = true
	end
	if car.washed == true then
		completed.washing = true
	end
	-- Repair and wash are condition jobs, not automatic resale bonuses. Old saved
	-- plans can still contain either stage, so mark an ineligible queued stage as
	-- skipped without pretending that the service completed (completed stages add
	-- value and operating cost). Never interrupt a stage that is already servicing.
	local rawCondition = car.condition
	if type(rawCondition) ~= "table" then
		rawCondition = {}
	end
	local alreadyServiced = car.serviced == true or completed.repairing == true
	local alreadyWashed = car.washed == true or completed.washing == true
	local hasOilLeak = if type(rawCondition.oilLeak) == "boolean"
		then rawCondition.oilLeak
		else not alreadyServiced
	local isDirty = if type(rawCondition.dirty) == "boolean"
		then rawCondition.dirty
		else not alreadyWashed
	local plannedIndex = if type(rawPipeline.nextIndex) == "number"
		then math.clamp(math.floor(rawPipeline.nextIndex), 1, #plan + 1)
		else 1
	local inRepairService = rawPipeline.state == "servicing" and plan[plannedIndex] == "repairing"
	local inWashService = rawPipeline.state == "servicing" and plan[plannedIndex] == "washing"
	if hasOilLeak == true then
		if skipped.repairing == "condition_clear" then skipped.repairing = nil end
	elseif completed.repairing ~= true and not inRepairService then
		skipped.repairing = "condition_clear"
	end
	if isDirty == true then
		if skipped.washing == "condition_clean" then skipped.washing = nil end
	elseif completed.washing ~= true and not inWashService then
		skipped.washing = "condition_clean"
	end
	if car.tunedDyno == true then
		completed.tuningDyno = true
	end
	if car.tunedBody == true then
		completed.tuningBody = true
	end
	if car.tunedPaint == true then
		completed.tuningPaint = true
	end

	local nextIndex = if type(rawPipeline.nextIndex) == "number"
		then math.clamp(math.floor(rawPipeline.nextIndex), 1, #plan + 1)
		else 1
	while nextIndex <= #plan and (completed[plan[nextIndex]] == true or skipped[plan[nextIndex]] ~= nil) do
		nextIndex += 1
	end

	local state = if type(rawPipeline.state) == "string" and VALID_STATES[rawPipeline.state] == true
		then rawPipeline.state
		else "idle"
	if #plan > 0 and nextIndex > #plan then
		state = "complete"
	elseif state == "complete" and nextIndex <= #plan then
		state = "queued"
	end

	local current: StageId? = nil
	if state == "queued" or state == "servicing" then
		current = plan[nextIndex]
		if current == nil then
			state = "complete"
		end
	end

	local currentSlot: string? = nil
	if state == "servicing" and type(rawPipeline.currentSlot) == "string" then
		currentSlot = rawPipeline.currentSlot
	elseif state == "servicing" then
		state = "queued"
	end

	local queuedAt: number? = nil
	if state == "queued" or state == "servicing" then
		if type(rawPipeline.queuedAt) == "number" then
			queuedAt = rawPipeline.queuedAt
		elseif type(car.serviceQueuedAt) == "number" then
			queuedAt = car.serviceQueuedAt
		end
	end
	local lastQueuedWarningAt = if type(rawPipeline.lastQueuedWarningAt) == "number"
		then rawPipeline.lastQueuedWarningAt
		else nil

	local escortId: EscortId? = nil
	if type(rawPipeline.escortId) == "string" or type(rawPipeline.escortId) == "number" then
		escortId = rawPipeline.escortId
	end

	local pipeline: PipelineState = {
		revision = OwnerCarPipeline.REVISION,
		state = state,
		plan = plan,
		nextIndex = nextIndex,
		completed = completed,
		skipped = skipped,
		currentStage = current,
		currentSlot = currentSlot,
		queuedAt = queuedAt,
		lastQueuedWarningAt = lastQueuedWarningAt,
		escortId = escortId,
		routingV2 = normalizeRoutingV2(rawPipeline.routingV2),
	}
	car.pipeline = pipeline

	local condition: CarCondition = {
		dirty = if type(rawCondition.dirty) == "boolean"
			then rawCondition.dirty
			else car.washed ~= true and completed.washing ~= true,
		oilLeak = if type(rawCondition.oilLeak) == "boolean"
			then rawCondition.oilLeak
			else car.serviced ~= true and completed.repairing ~= true,
	}
	car.condition = condition

	return pipeline
end

function OwnerCarPipeline.chanceFor(stage: StageId, pads: PurchasedPads): number
	local definition = STAGE_BY_ID[stage]
	if definition == nil then
		return 0
	end
	local ratio = functionalPadRatio(definition, pads)
	return math.clamp(
		definition.baseChance + (definition.capChance - definition.baseChance) * ratio,
		0,
		definition.capChance
	)
end

-- These arguments remain positional for older callers; stage selection is deterministic.
function OwnerCarPipeline.rollPlan(
	_pads: PurchasedPads,
	availableKinds: AvailableKinds,
	_rng: RandomSource?,
	condition: CarCondition?
): { StageId }
	local plan: { StageId } = {}
	-- Missing condition data keeps the legacy repair default. Washing requires known dirt.
	local needed: { [string]: boolean } = {
		repairing = condition == nil or condition.oilLeak == true,
		washing = condition ~= nil and condition.dirty == true,
		tuningDyno = true,
		tuningBody = true,
		tuningPaint = true,
	}
	for _, definition in ipairs(STAGES) do
		if configuredAndAvailable(definition, availableKinds) and needed[definition.id] then
			table.insert(plan, definition.id)
		end
	end

	return plan
end

function OwnerCarPipeline.begin(
	car: MutableCar,
	plan: { StageId },
	escortId: EscortId?,
	now: number?
): PipelineState
	local previous = OwnerCarPipeline.ensure(car)
	local completed = table.clone(previous.completed)
	local normalized = {}
	for _, stage in normalizePlan(plan) do
		if completed[stage] ~= true then
			table.insert(normalized, stage)
		end
	end
	local queuedAt = timestamp(now)
	local state = if #normalized > 0 then "queued" else "complete"
	local pipeline: PipelineState = {
		revision = OwnerCarPipeline.REVISION,
		state = state,
		plan = normalized,
		nextIndex = 1,
		completed = completed,
		skipped = {},
		currentStage = normalized[1],
		currentSlot = nil,
		queuedAt = if #normalized > 0 then queuedAt else nil,
		lastQueuedWarningAt = nil,
		escortId = escortId,
		routingV2 = {
			service = TycoonConfig.ROUTING_V2_SERVICE == true,
			usedParking = TycoonConfig.ROUTING_V2_USED_PARKING == true,
			tow = TycoonConfig.ROUTING_V2_TOW == true,
		},
	}
	car.pipeline = pipeline
	syncLegacy(car, pipeline)
	return pipeline
end

function OwnerCarPipeline.journeyId(car: MutableCar): string
	return "owner:" .. tostring(car.tradeId or "unknown")
end

function OwnerCarPipeline.routingFlags(car: MutableCar): RoutingV2Flags
	return OwnerCarPipeline.ensure(car).routingV2
end

function OwnerCarPipeline.currentStage(car: MutableCar): StageId?
	local pipeline = OwnerCarPipeline.ensure(car)
	if pipeline.state ~= "queued" and pipeline.state ~= "servicing" then
		return nil
	end
	return pipeline.plan[pipeline.nextIndex]
end

function OwnerCarPipeline.claim(car: MutableCar, stage: StageId, slotId: string): boolean
	local pipeline = OwnerCarPipeline.ensure(car)
	if pipeline.state ~= "queued"
		or pipeline.plan[pipeline.nextIndex] ~= stage
		or type(slotId) ~= "string"
		or slotId == ""
	then
		return false
	end
	pipeline.state = "servicing"
	pipeline.currentStage = stage
	pipeline.currentSlot = slotId
	syncLegacy(car, pipeline)
	return true
end

function OwnerCarPipeline.releaseLease(car: MutableCar, now: number?): boolean
	local pipeline = OwnerCarPipeline.ensure(car)
	if pipeline.state ~= "servicing" and pipeline.state ~= "queued" then
		return false
	end
	pipeline.state = "queued"
	pipeline.currentStage = pipeline.plan[pipeline.nextIndex]
	pipeline.currentSlot = nil
	pipeline.queuedAt = timestamp(now)
	pipeline.lastQueuedWarningAt = nil
	syncLegacy(car, pipeline)
	return pipeline.currentStage ~= nil
end

function OwnerCarPipeline.markComplete(car: MutableCar): PipelineState
	local pipeline = OwnerCarPipeline.ensure(car)
	pipeline.state = "complete"
	pipeline.nextIndex = #pipeline.plan + 1
	pipeline.currentStage = nil
	pipeline.currentSlot = nil
	pipeline.queuedAt = nil
	pipeline.lastQueuedWarningAt = nil
	syncLegacy(car, pipeline)
	return pipeline
end

local function advanceStage(car: MutableCar, pipeline: PipelineState, now: number?)
	pipeline.nextIndex += 1
	while pipeline.nextIndex <= #pipeline.plan do
		local stage = pipeline.plan[pipeline.nextIndex]
		if pipeline.completed[stage] ~= true and pipeline.skipped[stage] == nil then
			break
		end
		pipeline.nextIndex += 1
	end
	pipeline.currentSlot = nil

	local nextStage = pipeline.plan[pipeline.nextIndex]
	if nextStage == nil then
		OwnerCarPipeline.markComplete(car)
		return
	end
	pipeline.state = "queued"
	pipeline.currentStage = nextStage
	pipeline.queuedAt = timestamp(now)
	pipeline.lastQueuedWarningAt = nil
	syncLegacy(car, pipeline)
end

function OwnerCarPipeline.completeStage(car: MutableCar, stage: StageId, now: number?): boolean
	local pipeline = OwnerCarPipeline.ensure(car)
	if (pipeline.state ~= "queued" and pipeline.state ~= "servicing")
		or pipeline.plan[pipeline.nextIndex] ~= stage
	then
		return false
	end

	pipeline.completed[stage] = true
	local completionField = COMPLETION_FIELD[stage]
	if completionField then
		car[completionField] = true
	end
	local conditionField = CONDITION_FIELD[stage]
	if conditionField then
		car.condition[conditionField] = false
	end

	advanceStage(car, pipeline, now)
	return true
end

function OwnerCarPipeline.skipStage(car: MutableCar, stage: StageId, reason: string, now: number?): boolean
	local pipeline = OwnerCarPipeline.ensure(car)
	if (pipeline.state ~= "queued" and pipeline.state ~= "servicing")
		or pipeline.plan[pipeline.nextIndex] ~= stage
		or type(reason) ~= "string" or reason == ""
	then
		return false
	end
	pipeline.skipped[stage] = reason
	advanceStage(car, pipeline, now)
	return true
end

function OwnerCarPipeline.isComplete(car: MutableCar): boolean
	return OwnerCarPipeline.ensure(car).state == "complete"
end

function OwnerCarPipeline.stageMultiplier(stage: StageId): number
	local definition = STAGE_BY_ID[stage]
	return if definition ~= nil then definition.multiplier else 1
end

function OwnerCarPipeline.costForValueGain(valueGain: number): number
	if valueGain ~= valueGain or valueGain <= 0 then
		return 0
	end
	local rounded = math.floor(valueGain * OwnerCarPipeline.SERVICE_COST_RATE + 0.5)
	return math.max(1, rounded)
end

function OwnerCarPipeline.stageCost(stage: StageId, valueBefore: number): number
	local definition = STAGE_BY_ID[stage]
	if definition == nil or valueBefore ~= valueBefore or valueBefore <= 0 then
		return 0
	end
	local createdValue = math.max(0, valueBefore) * math.max(0, definition.multiplier - 1)
	return OwnerCarPipeline.costForValueGain(createdValue)
end

function OwnerCarPipeline.valueMultiplier(car: MutableCar): number
	local pipeline = OwnerCarPipeline.ensure(car)
	local multiplier = 1
	for _, definition in ipairs(STAGES) do
		if pipeline.completed[definition.id] == true then
			multiplier *= definition.multiplier
		end
	end
	return multiplier
end

function OwnerCarPipeline.stageBreakdown(car: MutableCar): { StageBreakdown }
	local pipeline = OwnerCarPipeline.ensure(car)
	local breakdown: { StageBreakdown } = {}
	for _, definition in ipairs(STAGES) do
		if pipeline.completed[definition.id] == true then
			table.insert(breakdown, {
				stage = definition.id,
				label = definition.label,
				multiplier = definition.multiplier,
			})
		end
	end
	return breakdown
end

function OwnerCarPipeline.skipReason(car: MutableCar, stage: string): string?
	return OwnerCarPipeline.ensure(car).skipped[stage]
end

function OwnerCarPipeline.label(stage: string): string
	local definition = STAGE_BY_ID[stage]
	return if definition ~= nil then definition.label else string.upper(stage)
end

return OwnerCarPipeline

