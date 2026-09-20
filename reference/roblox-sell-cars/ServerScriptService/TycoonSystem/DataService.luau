--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local VehicleNeon = require(ReplicatedStorage.VehicleNeon)
local PersonalGarageCustomizationConfig = require(ReplicatedStorage.PersonalGarageCustomizationConfig)
local LuckConfig = require(ReplicatedStorage.LuckConfig)

export type OwnerServiceStage = "repairing" | "washing" | "tuningDyno" | "tuningBody" | "tuningPaint"
export type OwnerPipelineState = "idle" | "queued" | "servicing" | "complete"
export type OwnerRoutingV2Save = {
	service: boolean,
	usedParking: boolean,
	tow: boolean,
}

export type OwnerPipelineSave = {
	revision: number,
	state: OwnerPipelineState,
	plan: { OwnerServiceStage },
	nextIndex: number,
	completed: { [string]: boolean },
	skipped: { [string]: string },
	currentStage: OwnerServiceStage?,
	currentSlot: string?,
	queuedAt: number?,
	lastQueuedWarningAt: number?,
	escortId: (string | number)?,
	routingV2: OwnerRoutingV2Save,
}

export type VehicleConditionSave = {
	dirty: boolean,
	oilLeak: boolean,
}

export type ProcessingCarStatus = "Pipeline" | "AwaitingDisplay"

export type ActiveCarSave = {
	templateId: string,
	state: string,
	parts: { [string]: boolean },
	haggleUsed: boolean,
	offered: number,
	ask: number,
	cost: number,
	-- Total owned-stock operating cost and the portion already paid from cash.
	-- Any unpaid balance is withheld atomically when the car is sold.
	serviceCost: number,
	serviceCostPaid: number,
	-- Legacy lot-service aliases mirror the persisted multi-stage owner pipeline.
	serviced: boolean,
	atBay: boolean,
	serviceRollDone: boolean,
	serviceQueuedAt: number,
	sellerId: string?,
	customerId: string?,
	tradeId: string,
	tutorialDealIndex: number,
	tutorialWildcard: boolean,
	listedPrice: number,
	pipeline: OwnerPipelineSave,
	condition: VehicleConditionSave,
	-- Factory palette entry chosen when this exact incoming proxy first appeared. It survives
	-- W -> owner service -> display even though those later stages reconstruct visual proxies.
	factoryPaintId: string?,
	-- Persisted repaint result. Nil means the selected factory texture/color remains intact.
	paintHue: number?,
	-- Owner-approved underglow palette id, installed by the Body Atelier stage.
	neonColorId: string?,
	-- Last completed physical service location, used to continue the same visible road journey.
	lastServiceStage: string?,
	lastServiceSlot: string?,
	-- Present only while the exact owned trade lives outside W/P in processingCars.
	processingStatus: ProcessingCarStatus?,
	sourceWorkingIndex: number?,
}

export type IncomingQueueSave = {
	queueId: string,
	templateId: string,
	ask: number,
	sellerId: string?,
	-- Optional provenance for server-authored supply loops (currently "tow").
	source: string?,
	paintHue: number?,
	bodyKit: boolean?,
	neonColorId: string?,
	-- Rolled before the proxy appears so its visible condition cannot change on promotion.
	dirty: boolean?,
	oilLeak: boolean?,
}

export type AnalyticsSave = {
	firstRepairAt: number?,
	firstSaleAt: number?,
	firstServiceAt: number?,
	personalCarEnteredAt: number?,
	personalCarDriven60At: number?,
	personalCarNeonPurchasedAt: number?,
	personalCarFunnelStep: number,
	-- Nil means the profile has not yet been assigned to the v2 onboarding cohort.
	onboardingV2Eligible: boolean?,
	onboardingV2Step: number,
	repairCount: number,
	saleCount: number,
}

export type TutorialSave = {
	eligible: boolean,
	dealIndex: number,
	completed: boolean,
	rushAvailable: boolean,
	rushCompleted: boolean,
}

export type PersonalCarCustomizationSave = {
	neonInstalled: boolean,
	neonColorId: string?,
	neonEnabled: boolean,
	nitroInstalled: boolean,
	accelerationLevel: number,
	topSpeedLevel: number,
	handlingLevel: number,
	stanceInstalled: boolean,
	stanceEnabled: boolean,
	bodyColorId: string?,
	ownedBodyColorIds: { [string]: boolean },
	tintLevelId: string,
	ownedTintLevelIds: { [string]: boolean },
	tintColorId: string,
	ownedTintColorIds: { [string]: boolean },
	headlightColorId: string,
	ownedHeadlightColorIds: { [string]: boolean },
	headlightBrightnessId: string,
	ownedHeadlightBrightnessIds: { [string]: boolean },
	headlightEffectId: string,
	platesRemoved: boolean,
	-- Exact cash actually spent from V3.09 onward. Legacy saves leave these nil so
	-- PersonalGarageService can reconstruct the strongest provable baseline once.
	acquisitionPaid: number?,
	customizationPaid: number?,
}

export type PersonalGarageSave = {
	starterChosen: boolean,
	-- Tracks which owned Rusty/Wronkler was granted for free. That exact car can be
	-- released for $0 only after another personal car is owned; onboarding never reopens.
	freeStarterCarId: string?,
	-- One-shot migration marker. Version 1 restored Rusty to profiles stranded by the
	-- legacy same-coordinate release bug and is written for every profile exactly once.
	starterRecoveryVersion: number,
	owned: { [string]: boolean },
	activeCarId: string?,
	-- The left-hand second bay is a permanent Personal Garage upgrade. activeCarId
	-- remains slot 1/current; secondaryCarId is the distinct car parked in slot 2.
	expanded: boolean,
	secondaryCarId: string?,
	-- Unix timestamp. A run reserves the window at start and refreshes it after lap two,
	-- preventing leave/rejoin from resetting a partially collected attempt.
	trackCooldownUntil: number,
	-- Optional first-drive activity is durable and never replaces the business objective.
	trackIntroCompleted: boolean,
	racingUnlocked: boolean,
	-- Permanent internal grant used only by authorized admins to QA Custom FX without buying the public pass.
	customFxAdminClaimed: boolean,
	customizations: { [string]: PersonalCarCustomizationSave },
}

export type RacingSave = {
	first: number,
	second: number,
	third: number,
	finishes: number,
}

export type ProgressionSave = {
	chapter: number,
	objectiveStep: string,
	tutorialComplete: boolean,
	revision: number,
}

export type SaveData = {
	cash: number,
	luck: number,
	pads: { [string]: boolean },
	stationLevels: { [string]: number },
	activeCar: ActiveCarSave?,
	activeCar2: ActiveCarSave?,
	-- Owned cars in transit, service FIFO/slots, or waiting for a free display pad.
	processingCars: { ActiveCarSave },
	incomingQueue: { IncomingQueueSave },
	-- Generalized Used Cars stock. Numeric runtime keys are 1..6.
	displayCars: { [number]: ActiveCarSave },
	-- Deprecated P1/P2 aliases retained for rolling-server and old-caller compatibility.
	displayCar: ActiveCarSave?,
	displayCar2: ActiveCarSave?,
	analytics: AnalyticsSave,
	tutorial: TutorialSave,
	personalGarage: PersonalGarageSave,
	racing: RacingSave,
	progression: ProgressionSave,
	resolvedTrades: { [string]: boolean },
	carIndex: number,
	carIndexSeen: { [string]: boolean },
	served: { [string]: number },
	contentRevision: number,
	lastSeenAt: number,
}

local RETRY_ATTEMPTS = 4
local RETRY_DELAY = 2
local OFFLINE_MIN_SECONDS = 90
local OFFLINE_MAX_SECONDS = 8 * 60 * 60
local OFFLINE_RATE_BY_PAD: { [string]: number } = {
	CashRegister = 0.12,
	FirstSalesman = 0.35,
	RB_CarLift = 0.85,
	RB2_Foundation = 0.55,
	CW_BrushMachine = 1.35,
	CW2_BrushMachine = 1.35,
	TA_DynoRollers = 2.25,
	TA_BodyKitStation = 2.75,
	TA_PaintControl = 3.15,
}

local function offlineRateForPads(pads: { [string]: boolean }): number
	local rate = 0
	for padId, amount in OFFLINE_RATE_BY_PAD do
		if pads[padId] == true then
			rate += amount
		end
	end
	return rate
end

-- New profiles start normally, except the requested development account grant.
-- Dev account uses the same starting cash as everyone else after a season wipe.
local STARTING_CASH_BY_USER_ID: { [number]: number } = {
	-- intentionally empty: soak / fresh seasons start at TycoonConfig.STARTING_CASH ($3,300)
}

local store = DataStoreService:GetDataStore(TycoonConfig.DATASTORE_NAME)
local cache: { [number]: SaveData } = {}
local loaded: { [number]: boolean } = {}

-- Roblox queues a second write to the same key inside about six seconds and starts
-- dropping requests once that queue fills. One flip touches the profile three times
-- (list, settle, post-sale), so every write goes through a gate that collapses a burst
-- into a single request instead of racing the per-key cooldown.
local MIN_WRITE_INTERVAL = 7
local dirty: { [number]: boolean } = {}
local lastWrite: { [number]: number } = {}
local writing: { [number]: boolean } = {}
local pendingWrite: { [number]: boolean } = {}
-- Every save request advances a local generation. A write only clears dirty when no newer
-- mutation arrived while UpdateAsync yielded. Critical operations additionally hold a
-- per-profile lock so a routine autosave cannot overtake a sale or pad purchase.
local changeVersion: { [number]: number } = {}
local persistedVersion: { [number]: number } = {}
local criticalLock: { [number]: boolean } = {}
local mutationLock: { [number]: boolean } = {}

local DataService = {}

local function nonnegativeWholeOrNil(value: unknown): number?
	if typeof(value) ~= "number" then return nil end
	local numberValue = value :: number
	if numberValue ~= numberValue or numberValue <= -math.huge or numberValue >= math.huge then return nil end
	return math.max(0, math.floor(numberValue))
end

local function blankAnalytics(): AnalyticsSave
	return {
		firstRepairAt = nil,
		firstSaleAt = nil,
		firstServiceAt = nil,
		personalCarEnteredAt = nil,
		personalCarDriven60At = nil,
		personalCarNeonPurchasedAt = nil,
		personalCarFunnelStep = 0,
		onboardingV2Eligible = nil,
		onboardingV2Step = 0,
		repairCount = 0,
		saleCount = 0,
	}
end

local function blankData(userId: number?): SaveData
	return {
		cash = STARTING_CASH_BY_USER_ID[userId or 0] or TycoonConfig.STARTING_CASH,
		luck = LuckConfig.DEFAULT,
		pads = {},
		stationLevels = {},
		activeCar = nil,
		activeCar2 = nil,
		processingCars = {},
		incomingQueue = {},
		displayCars = {},
		displayCar = nil,
		displayCar2 = nil,
		analytics = blankAnalytics(),
		tutorial = {
			eligible = true,
			dealIndex = 1,
			completed = false,
			rushAvailable = false,
			rushCompleted = false,
		},
		personalGarage = {
			starterChosen = false,
			freeStarterCarId = nil,
			starterRecoveryVersion = 1,
			owned = {},
			activeCarId = nil,
			expanded = false,
			secondaryCarId = nil,
			trackCooldownUntil = 0,
			trackIntroCompleted = false,
			racingUnlocked = false,
			customFxAdminClaimed = false,
			customizations = {},
		},
		racing = {
			first = 0,
			second = 0,
			third = 0,
			finishes = 0,
		},
		progression = {
			chapter = 1,
			objectiveStep = "buy_cash_register",
			tutorialComplete = false,
			revision = 1,
		},
		resolvedTrades = {},
		carIndex = 1,
		carIndexSeen = {},
		served = {},
		contentRevision = 2,
		lastSeenAt = os.time(),
	}
end

local MAX_WORKING_SLOTS = 2
local MAX_PROCESSING_CARS = 4
local MAX_DISPLAY_SLOTS = 6
local MAX_CHAPTER = 6
local CONTENT_REVISION = 2

local function deriveChapterFromPads(pads: { [string]: boolean }, tutorialComplete: boolean): number
	local configAny = TycoonConfig :: any
	if typeof(configAny.deriveChapter) == "function" then
		local ok, chapter = pcall(configAny.deriveChapter, pads, tutorialComplete)
		if ok and typeof(chapter) == "number" then
			return math.clamp(math.floor(chapter), 1, MAX_CHAPTER)
		end
	end
	-- Rolling-server fallback while the chapter-aware TycoonConfig propagates.
	if pads.CW2_WaterTank == true then
		return 6
	end
	for padId, bought in pads do
		if bought and string.sub(padId, 1, 3) == "TA_" then
			return 6
		end
	end
	if pads.CW_WaterTank == true then
		return 5
	elseif pads.CO_CheckoutAutomation == true then
		return 4
	elseif tutorialComplete and pads.FirstMechanic == true then
		return 3
	elseif tutorialComplete then
		return 2
	end
	return 1
end

local EARLY_PURCHASE_OBJECTIVES = {
	{ pad = "FirstSalesman", step = "hire_first_salesman" },
	{ pad = "CarJack", step = "buy_car_jack" },
	{ pad = "AirCompressor", step = "buy_air_compressor" },
	{ pad = "FirstMechanic", step = "hire_first_mechanic" },
}

local function deriveObjectiveStep(pads: { [string]: boolean }, tutorialComplete: boolean): string
	if pads.CashRegister ~= true then
		return "buy_cash_register"
	end
	if not tutorialComplete then
		return "buy_car"
	end
	for _, objective in EARLY_PURCHASE_OBJECTIVES do
		if pads[objective.pad] ~= true then
			return objective.step
		end
	end

	local configAny = TycoonConfig :: any
	if typeof(configAny.nextMandatoryPad) == "function" then
		local ok, definition = pcall(configAny.nextMandatoryPad, pads, true, nil)
		if ok and typeof(definition) == "table" and typeof(definition.id) == "string" then
			return "buy_pad:" .. definition.id
		end
	end
	return "business_complete"
end

local function syncProgressionData(data: SaveData): boolean
	local progression = data.progression
	local tutorialComplete = data.tutorial.completed == true
	local chapter = math.max(
		math.clamp(math.floor(progression.chapter), 1, MAX_CHAPTER),
		deriveChapterFromPads(data.pads, tutorialComplete)
	)
	local objectiveStep = deriveObjectiveStep(data.pads, tutorialComplete)
	local changed = progression.chapter ~= chapter
		or progression.tutorialComplete ~= tutorialComplete
		or progression.objectiveStep ~= objectiveStep
	if changed then
		local previousChapter = progression.chapter
		local previousStep = progression.objectiveStep
		progression.chapter = chapter
		progression.tutorialComplete = tutorialComplete
		progression.objectiveStep = objectiveStep
		progression.revision = math.max(1, progression.revision + 1)
		print(`[Progression] chapter {previousChapter}->{chapter} objective {previousStep}->{objectiveStep}`)
	end
	return changed
end

function DataService.workingCapacityForPads(pads: { [string]: boolean }): number
	return if pads.RepairPad2 == true then MAX_WORKING_SLOTS else 1
end

function DataService.displayCapacityForPads(pads: { [string]: boolean }): number
	local capacity = 1
	for index = 2, MAX_DISPLAY_SLOTS do
		if pads["Parking" .. index] ~= true then
			break
		end
		capacity = index
	end
	return capacity
end

function DataService.getWorking(data: SaveData, index: number?): ActiveCarSave?
	local resolved = index or 1
	if resolved == 1 then
		return data.activeCar
	elseif resolved == 2 then
		return data.activeCar2
	end
	return nil
end

function DataService.setWorking(data: SaveData, index: number?, car: ActiveCarSave?)
	local resolved = index or 1
	if resolved == 1 then
		data.activeCar = car
	elseif resolved == 2 then
		data.activeCar2 = car
	end
end

function DataService.processingCapacity(): number
	return MAX_PROCESSING_CARS
end

function DataService.processingIndexForTrade(data: SaveData, tradeId: string): number?
	if tradeId == "" then
		return nil
	end
	for index, car in data.processingCars do
		if car.tradeId == tradeId then
			return index
		end
	end
	return nil
end

function DataService.getProcessing(data: SaveData, tradeId: string): (ActiveCarSave?, number?)
	local index = DataService.processingIndexForTrade(data, tradeId)
	if index == nil then
		return nil, nil
	end
	return data.processingCars[index], index
end

function DataService.addProcessing(data: SaveData, car: ActiveCarSave): boolean
	if car.tradeId == ""
		or #data.processingCars >= MAX_PROCESSING_CARS
		or DataService.processingIndexForTrade(data, car.tradeId) ~= nil
	then
		return false
	end
	table.insert(data.processingCars, car)
	return true
end

function DataService.removeProcessing(data: SaveData, tradeId: string): (ActiveCarSave?, number?)
	local index = DataService.processingIndexForTrade(data, tradeId)
	if index == nil then
		return nil, nil
	end
	return table.remove(data.processingCars, index), index
end

function DataService.getDisplay(data: SaveData, index: number?): ActiveCarSave?
	local resolved = index or 1
	if resolved < 1 or resolved > MAX_DISPLAY_SLOTS then
		return nil
	end
	-- P1/P2 aliases remain authoritative while old live servers can still write them.
	if resolved == 1 then
		return data.displayCar
	elseif resolved == 2 then
		return data.displayCar2
	end
	return data.displayCars[resolved]
end

function DataService.setDisplay(data: SaveData, index: number?, car: ActiveCarSave?)
	local resolved = index or 1
	if resolved < 1 or resolved > MAX_DISPLAY_SLOTS then
		return
	end
	data.displayCars[resolved] = car
	if resolved == 1 then
		data.displayCar = car
	elseif resolved == 2 then
		data.displayCar2 = car
	end
end

local WORKING_STATES: { [string]: boolean } = {
	Incoming = true,
	Offered = true,
	Junk = true,
	Repairing = true,
	Ready = true,
}
local DISPLAY_STATES: { [string]: boolean } = {
	Listed = true,
	Offer = true,
	Sold = true,
}

local PIPELINE_STAGE_ORDER: { OwnerServiceStage } = {
	"repairing",
	"washing",
	"tuningDyno",
	"tuningBody",
	"tuningPaint",
}

local PIPELINE_STATES: { OwnerPipelineState } = { "idle", "queued", "servicing", "complete" }

local function readPipelineStage(value: unknown): OwnerServiceStage?
	if typeof(value) == "string" and table.find(PIPELINE_STAGE_ORDER, value :: OwnerServiceStage) then
		return value :: OwnerServiceStage
	end
	return nil
end

local function readPipelineState(value: unknown): OwnerPipelineState?
	if typeof(value) == "string" and table.find(PIPELINE_STATES, value :: OwnerPipelineState) then
		return value :: OwnerPipelineState
	end
	return nil
end

local function readPipeline(
	car: { [string]: unknown },
	isDisplay: boolean
): (OwnerPipelineSave, VehicleConditionSave)
	local legacyServiced = car.serviced == true
	local legacyAtBay = car.atBay == true
	local legacyRollDone = car.serviceRollDone == true
	local legacyQueuedAt = if typeof(car.serviceQueuedAt) == "number"
		then math.max(0, car.serviceQueuedAt :: number)
		else nil

	local hasPipeline = typeof(car.pipeline) == "table"
	local rawPipeline = if hasPipeline
		then car.pipeline :: { [string]: unknown }
		else {}

	local requested: { [string]: boolean } = {}
	if typeof(rawPipeline.plan) == "table" then
		for _, rawStage in rawPipeline.plan :: { unknown } do
			local stage = readPipelineStage(rawStage)
			if stage ~= nil then
				requested[stage] = true
			end
		end
	end

	local completed: { [string]: boolean } = {}
	if typeof(rawPipeline.completed) == "table" then
		for rawStage, done in rawPipeline.completed :: { [string]: unknown } do
			local stage = readPipelineStage(rawStage)
			if stage ~= nil and done == true then
				completed[stage] = true
				requested[stage] = true
			end
		end
	end
	local skipped: { [string]: string } = {}
	if typeof(rawPipeline.skipped) == "table" then
		for rawStage, rawReason in rawPipeline.skipped :: { [string]: unknown } do
			local stage = readPipelineStage(rawStage)
			if stage ~= nil and typeof(rawReason) == "string" and rawReason ~= "" then
				skipped[stage] = rawReason :: string
				requested[stage] = true
			end
		end
	end
	if legacyServiced then
		completed.repairing = true
		requested.repairing = true
	end
	if legacyAtBay then
		requested.repairing = true
	end

	local plan: { OwnerServiceStage } = {}
	for _, stage in PIPELINE_STAGE_ORDER do
		if requested[stage] == true then
			table.insert(plan, stage)
		end
	end

	local state: OwnerPipelineState
	local savedState = readPipelineState(rawPipeline.state)
	if savedState ~= nil then
		state = savedState
	elseif legacyAtBay then
		state = "queued"
	elseif isDisplay or legacyServiced or (legacyRollDone and not legacyAtBay) then
		state = "complete"
	else
		-- A working car without the new schema has not entered the owner pipeline yet.
		state = "idle"
	end

	-- Rolling migration: aliases may have been written after a car received its empty
	-- revision-1 defaults but before all service orchestration code was live.
	if state == "idle" and legacyAtBay then
		state = "queued"
	elseif state == "idle" and (isDisplay or legacyServiced or (legacyRollDone and not legacyAtBay)) then
		state = "complete"
	end

	local nextIndex = if typeof(rawPipeline.nextIndex) == "number"
		then math.clamp(math.floor(rawPipeline.nextIndex :: number), 1, #plan + 1)
		else 1
	while nextIndex <= #plan and (completed[plan[nextIndex]] == true or skipped[plan[nextIndex]] ~= nil) do
		nextIndex += 1
	end

	local currentStage: OwnerServiceStage? = nil
	local currentSlot: string? = nil
	local queuedAt: number? = nil
	if state == "complete" then
		nextIndex = #plan + 1
	elseif state == "queued" or state == "servicing" then
		currentStage = plan[nextIndex]
		if currentStage == nil then
			state = "complete"
			nextIndex = #plan + 1
		else
			if state == "servicing"
				and typeof(rawPipeline.currentSlot) == "string"
				and rawPipeline.currentSlot ~= ""
			then
				currentSlot = rawPipeline.currentSlot :: string
			elseif state == "servicing" then
				-- A lease without a slot cannot be resumed safely; put it back in FIFO.
				state = "queued"
			end
			if typeof(rawPipeline.queuedAt) == "number" then
				queuedAt = math.max(0, rawPipeline.queuedAt :: number)
			else
				queuedAt = legacyQueuedAt
			end
		end
	else
		nextIndex = 1
	end

	local escortId: (string | number)? = nil
	if typeof(rawPipeline.escortId) == "string" and rawPipeline.escortId ~= "" then
		escortId = rawPipeline.escortId :: string
	elseif typeof(rawPipeline.escortId) == "number" then
		escortId = rawPipeline.escortId :: number
	end

	local lastQueuedWarningAt = if typeof(rawPipeline.lastQueuedWarningAt) == "number"
		then math.max(0, rawPipeline.lastQueuedWarningAt :: number)
		else nil

	local revision = if typeof(rawPipeline.revision) == "number"
		then math.max(1, math.floor(rawPipeline.revision :: number))
		else 1
	local rawRoutingV2 = if typeof(rawPipeline.routingV2) == "table"
		then rawPipeline.routingV2 :: { [string]: unknown }
		else {}
	local pipeline: OwnerPipelineSave = {
		revision = revision,
		state = state,
		plan = plan,
		nextIndex = nextIndex,
		completed = completed,
		skipped = skipped,
		currentStage = currentStage,
		currentSlot = currentSlot,
		queuedAt = queuedAt,
		lastQueuedWarningAt = lastQueuedWarningAt,
		escortId = escortId,
		routingV2 = {
			service = rawRoutingV2.service == true,
			usedParking = rawRoutingV2.usedParking == true,
			tow = rawRoutingV2.tow == true,
		},
	}

	local legacyDisplay = isDisplay and not hasPipeline
	local rawCondition = if typeof(car.condition) == "table"
		then car.condition :: { [string]: unknown }
		else {}
	local dirty = if not legacyDisplay and typeof(rawCondition.dirty) == "boolean"
		then rawCondition.dirty == true
		else not legacyDisplay and completed.washing ~= true
	local oilLeak = if not legacyDisplay and typeof(rawCondition.oilLeak) == "boolean"
		then rawCondition.oilLeak == true
		else not legacyDisplay and completed.repairing ~= true
	if completed.washing == true then
		dirty = false
	end
	if completed.repairing == true or legacyServiced then
		oilLeak = false
	end

	return pipeline, {
		dirty = dirty,
		oilLeak = oilLeak,
	}
end

local function readCar(raw: unknown, allowedStates: { [string]: boolean }, fallbackState: string): ActiveCarSave?
	if typeof(raw) ~= "table" then
		return nil
	end
	local car = raw :: { [string]: unknown }
	local rawState = if typeof(car.state) == "string" then car.state :: string else fallbackState
	local state = if allowedStates[rawState] == true then rawState else fallbackState
	local partsTable: { [string]: boolean } = { Body = false, Wheels = false, Engine = false }
	if typeof(car.parts) == "table" then
		for partName, repaired in car.parts :: { [string]: unknown } do
			if typeof(partName) == "string" and repaired == true then
				partsTable[partName] = true
			end
		end
	end
	local pipeline, condition = readPipeline(car, allowedStates == DISPLAY_STATES)
	local inService = pipeline.state == "queued" or pipeline.state == "servicing"
	local serviceCost = if typeof(car.serviceCost) == "number"
		then math.max(0, math.floor(car.serviceCost :: number))
		else 0
	local serviceCostPaid = if typeof(car.serviceCostPaid) == "number"
		then math.clamp(math.floor(car.serviceCostPaid :: number), 0, serviceCost)
		else 0
	return {
		templateId = if typeof(car.templateId) == "string" then car.templateId :: string else "Rusty",
		state = state,
		parts = partsTable,
		haggleUsed = car.haggleUsed == true,
		offered = if typeof(car.offered) == "number" then math.max(0, math.floor(car.offered :: number)) else 0,
		ask = if typeof(car.ask) == "number" then math.max(0, math.floor(car.ask :: number)) else 0,
		cost = if typeof(car.cost) == "number" then math.max(0, math.floor(car.cost :: number)) else 25,
		serviceCost = serviceCost,
		serviceCostPaid = serviceCostPaid,
		serviced = pipeline.completed.repairing == true,
		atBay = inService,
		serviceRollDone = pipeline.state ~= "idle",
		serviceQueuedAt = if pipeline.queuedAt ~= nil then pipeline.queuedAt else 0,
		sellerId = if typeof(car.sellerId) == "string" then car.sellerId :: string else nil,
		customerId = if typeof(car.customerId) == "string" then car.customerId :: string else nil,
		tradeId = if typeof(car.tradeId) == "string" then car.tradeId :: string else "",
		tutorialDealIndex = if typeof(car.tutorialDealIndex) == "number" then math.clamp(math.floor(car.tutorialDealIndex :: number), 0, 3) else 0,
		tutorialWildcard = car.tutorialWildcard == true,
		listedPrice = if typeof(car.listedPrice) == "number" then math.max(0, math.floor(car.listedPrice :: number)) else 0,
		pipeline = pipeline,
		condition = condition,
		factoryPaintId = if typeof(car.factoryPaintId) == "string" and car.factoryPaintId ~= ""
			then car.factoryPaintId :: string
			else nil,
		paintHue = if typeof(car.paintHue) == "number" then math.clamp(car.paintHue :: number, 0, 1) else nil,
		neonColorId = if VehicleNeon.isColorId(car.neonColorId) then car.neonColorId :: string else nil,
		lastServiceStage = if typeof(car.lastServiceStage) == "string" then car.lastServiceStage :: string else nil,
		lastServiceSlot = if typeof(car.lastServiceSlot) == "string" then car.lastServiceSlot :: string else nil,
		processingStatus = if car.processingStatus == "AwaitingDisplay" then "AwaitingDisplay" elseif car.processingStatus == "Pipeline" then "Pipeline" else nil,
		sourceWorkingIndex = if typeof(car.sourceWorkingIndex) == "number"
			then math.clamp(math.floor(car.sourceWorkingIndex :: number), 1, MAX_WORKING_SLOTS)
			else nil,
	}
end

local function sanitize(raw: unknown, userId: number): SaveData
	if typeof(raw) ~= "table" then
		return blankData(userId)
	end
	local source = raw :: { [string]: unknown }
	local sourceContentRevision = if typeof(source.contentRevision) == "number"
		then math.max(0, math.floor(source.contentRevision :: number))
		else 0
	local result = blankData(userId)
	result.contentRevision = CONTENT_REVISION
	result.lastSeenAt = if typeof(source.lastSeenAt) == "number"
		then math.max(0, math.floor(source.lastSeenAt :: number))
		else os.time()
	if typeof(source.cash) == "number" then
		result.cash = math.max(math.floor(source.cash :: number), 0)
	end
	result.luck = LuckConfig.normalize(source.luck)
	if typeof(source.stationLevel) == "number" then
		local station = TycoonConfig.getStation("junk")
		if station ~= nil then
			result.stationLevels.junk = math.clamp(math.floor(source.stationLevel :: number), 1, station.maxLevel)
		end
	end
	if typeof(source.stationLevels) == "table" then
		for key, value in source.stationLevels :: { [string]: unknown } do
			local station = if typeof(key) == "string" then TycoonConfig.getStation(key) else nil
			if station ~= nil and typeof(value) == "number" then
				result.stationLevels[key] = math.clamp(math.floor(value :: number), 1, station.maxLevel)
			end
		end
	end
	if typeof(source.pads) == "table" then
		local sourcePads = source.pads :: { [string]: unknown }
		for key, value in sourcePads do
			local padId = key
			if padId == "DisplayPad" then
				padId = "RepairPad"
			end
			if typeof(padId) == "string" and value == true and TycoonConfig.getPad(padId) ~= nil then
				result.pads[padId] = true
			end
		end

		-- One-shot additive migration. Revision 2 removes every visible construction bundle;
		-- profiles that paid old bundle leaders keep all of those models without another charge.
		if sourceContentRevision < CONTENT_REVISION then
			local function grantMigrated(ids: { string })
				for _, id in ids do
					if TycoonConfig.getPad(id) ~= nil then
						result.pads[id] = true
					end
				end
			end
			if sourcePads.OpenRepairBay == true or sourcePads.RB_Foundation == true then
				grantMigrated({ "OpenRepairBay", "RB_Foundation" })
			end
			if sourcePads.RB_CarLift == true then
				grantMigrated({ "RB_ApproachRamp", "RB_ServiceRamp" })
			end
			if sourcePads.RB_RepairBaySign == true then
				grantMigrated({
					"RB_BackWall", "RB_SideWall1", "RB_SideWall2", "RB_FrontWall", "RB_Ceiling",
					"RB_Lights", "RB_GarageDoor", "RB_ToolCabinet", "RB_PartsRack",
					"RB_ModernAirCompressor", "RB_TireStack", "RB_TowTruckDropOff", "RB_TowTruck",
				})
			end
			if sourcePads.RB_Walls == true then
				grantMigrated({ "RB_BackWall", "RB_SideWall1", "RB_SideWall2", "RB_FrontWall" })
			end
			if sourcePads.RB_ServiceRamp == true then
				grantMigrated({ "RB_ApproachRamp" })
			end
			if sourcePads.RB_TowTruckDropOff == true then
				grantMigrated({ "RB_TowTruck" })
			end
			if sourcePads.CW_Foundation == true then
				grantMigrated({ "CW_EntryRamp", "CW_ExitRamp" })
			end
			if sourcePads.CW_Walls == true or sourcePads.CW_Ceiling == true then
				grantMigrated({ "CW_LeftSide", "CW_RightSide", "CW_FrontEntranceFrame", "CW_BackExitFrame", "CW_SideDoor" })
			end
			if sourcePads.CW_FanDryer == true then
				grantMigrated({ "CW_WaterTank" })
			end
			if sourcePads.CW2_Foundation == true then
				grantMigrated({ "CW2_EntryRamp", "CW2_ExitRamp" })
			end
			if sourcePads.CW2_Ceiling == true then
				grantMigrated({ "CW2_LeftSide", "CW2_RightSide", "CW2_FrontEntranceFrame", "CW2_BackExitFrame", "CW2_SideDoor" })
			end
			if sourcePads.TA_Foundation == true then
				grantMigrated({ "TA_Approach", "TA_FrontArches", "TA_LeftWall", "TA_RightWall", "TA_BackWall", "TA_Ceiling", "TA_Lights", "TA_Door1" })
			end
			if sourcePads.TA_BodyKitStation == true then
				grantMigrated({ "TA_Door2" })
			end
			if sourcePads.TA_PaintControl == true then
				grantMigrated({ "TA_Door3", "TA_PaintFoundation", "TA_PaintWalls", "TA_PaintCeiling" })
			end
			if sourcePads.TA_Compressor == true then
				grantMigrated({
					"TA_Neon", "TA_ToolChest", "TA_SideDoor", "TA_WheelRack", "TA_Staircase",
					"TA_RoofVents", "TA_ACUnit", "TA_AdminFoundation", "TA_AdminWalls", "TA_AdminFurniture",
				})
			end
			for highest = 6, 2, -1 do
				if sourcePads["Parking" .. highest] == true then
					for index = 2, highest do
						grantMigrated({ "Parking" .. index })
					end
					break
				end
			end
		end
	end
	if typeof(source.carIndex) == "number" then
		result.carIndex = math.max(1, math.floor(source.carIndex :: number))
	end
	result.carIndexSeen = {}
	if typeof(source.carIndexSeen) == "table" then
		for carId, seen in source.carIndexSeen :: { [string]: unknown } do
			if typeof(carId) == "string" and seen == true then
				result.carIndexSeen[carId] = true
			end
		end
	end
	result.activeCar = readCar(source.activeCar, WORKING_STATES, "Junk")
	-- RepairPad2 independently unlocks the second working lane; Parking2 is display-only.
	result.activeCar2 = if DataService.workingCapacityForPads(result.pads) >= 2
		then readCar(source.activeCar2, WORKING_STATES, "Junk")
		else nil

	local processingTradeIds: { [string]: boolean } = {}
	if typeof(source.processingCars) == "table" then
		for _, rawProcessing in source.processingCars :: { unknown } do
			if #result.processingCars >= MAX_PROCESSING_CARS then
				break
			end
			local car = readCar(rawProcessing, WORKING_STATES, "Ready")
			if car ~= nil and car.tradeId ~= "" and processingTradeIds[car.tradeId] ~= true then
				local pipeline = car.pipeline
				car.processingStatus = if pipeline.state == "complete" then "AwaitingDisplay" else "Pipeline"
				car.sourceWorkingIndex = car.sourceWorkingIndex or 1
				processingTradeIds[car.tradeId] = true
				table.insert(result.processingCars, car)
			end
		end
	end

	-- Rolling migration from the W-reservation implementation. Once an escorted pipeline
	-- began, its exact trade belongs to processing even if the old save still stored it in W.
	for workingIndex = 1, MAX_WORKING_SLOTS do
		local car = DataService.getWorking(result, workingIndex)
		if car == nil or car.tradeId == "" then
			continue
		end
		local pipeline = car.pipeline
		local belongsInProcessing = pipeline.state == "queued"
			or pipeline.state == "servicing"
			or (pipeline.state == "complete" and pipeline.escortId ~= nil)
		if belongsInProcessing
			and processingTradeIds[car.tradeId] ~= true
			and #result.processingCars < MAX_PROCESSING_CARS
		then
			car.sourceWorkingIndex = workingIndex
			car.processingStatus = if pipeline.state == "complete" then "AwaitingDisplay" else "Pipeline"
			processingTradeIds[car.tradeId] = true
			table.insert(result.processingCars, car)
			DataService.setWorking(result, workingIndex, nil)
		end
	end

	if result.pads.FirstSalesman == true and typeof(source.incomingQueue) == "table" then
		for _, rawItem in source.incomingQueue :: { unknown } do
			if #result.incomingQueue >= 3 then
				break
			end
			if typeof(rawItem) == "table" then
				local item = rawItem :: { [string]: unknown }
				if typeof(item.queueId) == "string"
					and item.queueId ~= ""
					and typeof(item.templateId) == "string"
					and item.templateId ~= ""
					and typeof(item.ask) == "number"
				then
					table.insert(result.incomingQueue, {
						queueId = item.queueId :: string,
						templateId = item.templateId :: string,
						ask = math.max(0, math.floor(item.ask :: number)),
						sellerId = if typeof(item.sellerId) == "string" then item.sellerId :: string else nil,
						source = if item.source == "tow" then "tow" else nil,
						paintHue = if typeof(item.paintHue) == "number" then math.clamp(item.paintHue :: number, 0, 1) else nil,
						bodyKit = item.bodyKit == true,
						neonColorId = if VehicleNeon.isColorId(item.neonColorId) then item.neonColorId :: string else nil,
						dirty = if typeof(item.dirty) == "boolean" then item.dirty == true else true,
						oilLeak = if typeof(item.oilLeak) == "boolean" then item.oilLeak == true else true,
					})
				end
			end
		end
	end

	-- New saves use displayCars; P1/P2 fall back to their legacy fields. Capacity is the
	-- highest consecutively-owned Parking pad, so corrupted sparse unlocks cannot expose P6.
	local displayCapacity = DataService.displayCapacityForPads(result.pads)
	local sourceDisplays = if typeof(source.displayCars) == "table"
		then source.displayCars :: { [any]: unknown }
		else {}
	for index = 1, displayCapacity do
		local rawDisplay = sourceDisplays[index]
		if rawDisplay == nil then
			rawDisplay = sourceDisplays[tostring(index)]
		end
		if rawDisplay == nil and index == 1 then
			rawDisplay = source.displayCar
		elseif rawDisplay == nil and index == 2 then
			rawDisplay = source.displayCar2
		end
		DataService.setDisplay(result, index, readCar(rawDisplay, DISPLAY_STATES, "Listed"))
	end

	-- One exact trade may occupy only one persisted inventory. A listed P contract wins,
	-- then processing, then W. Empty legacy trade ids are left untouched for compatibility.
	local occupiedTrades: { [string]: boolean } = {}
	for index = 1, displayCapacity do
		local car = DataService.getDisplay(result, index)
		if car ~= nil and car.tradeId ~= "" then
			if occupiedTrades[car.tradeId] == true then
				DataService.setDisplay(result, index, nil)
			else
				occupiedTrades[car.tradeId] = true
			end
		end
	end
	local uniqueProcessing: { ActiveCarSave } = {}
	for _, car in result.processingCars do
		if occupiedTrades[car.tradeId] ~= true then
			occupiedTrades[car.tradeId] = true
			table.insert(uniqueProcessing, car)
		end
	end
	result.processingCars = uniqueProcessing
	for workingIndex = 1, MAX_WORKING_SLOTS do
		local car = DataService.getWorking(result, workingIndex)
		if car ~= nil and car.tradeId ~= "" then
			if occupiedTrades[car.tradeId] == true then
				DataService.setWorking(result, workingIndex, nil)
			else
				occupiedTrades[car.tradeId] = true
			end
		end
	end

	-- Migration rule: only GetAsync == nil gets blankData's tutorial. Any stored profile
	-- lacking this schema predates the MVP and must not replay onboarding.
	if typeof(source.tutorial) == "table" then
		local tutorial = source.tutorial :: { [string]: unknown }
		result.tutorial = {
			eligible = tutorial.eligible == true,
			dealIndex = if typeof(tutorial.dealIndex) == "number"
				then math.clamp(
					math.floor(tutorial.dealIndex :: number),
					1,
					DealerCarConfig.TUTORIAL_DEAL_COUNT + 1
				)
				else 1,
			completed = tutorial.completed == true,
			rushAvailable = tutorial.rushAvailable == true,
			rushCompleted = tutorial.rushCompleted == true,
		}
	else
		result.tutorial = {
			eligible = false,
			dealIndex = DealerCarConfig.TUTORIAL_DEAL_COUNT + 1,
			completed = true,
			rushAvailable = false,
			rushCompleted = true,
		}
	end

	-- The old FTUE had three cars. Anyone already beyond Rusty has completed more work than
	-- the new one-car contract requires, so graduate them and convert any remaining deal-2/3
	-- stock into ordinary owned stock instead of replaying or deleting it.
	if result.tutorial.dealIndex > DealerCarConfig.TUTORIAL_DEAL_COUNT then
		result.tutorial.completed = true
		result.tutorial.dealIndex = DealerCarConfig.TUTORIAL_DEAL_COUNT + 1
	end
	if result.tutorial.completed then
		result.tutorial.dealIndex = DealerCarConfig.TUTORIAL_DEAL_COUNT + 1
		local function retireLegacyTutorialCar(car: ActiveCarSave?)
			if car ~= nil and car.tutorialDealIndex > DealerCarConfig.TUTORIAL_DEAL_COUNT then
				car.tutorialDealIndex = 0
				car.tutorialWildcard = false
			end
		end
		for index = 1, MAX_WORKING_SLOTS do
			retireLegacyTutorialCar(DataService.getWorking(result, index))
		end
		for _, car in result.processingCars do
			retireLegacyTutorialCar(car)
		end
		for index = 1, MAX_DISPLAY_SLOTS do
			retireLegacyTutorialCar(DataService.getDisplay(result, index))
		end
	end

	-- Personal Garage is additive. Legacy profiles receive the post-tutorial starter offer
	-- without inheriting dealer inventory; only the two authored full driving rigs are valid.
	if typeof(source.personalGarage) == "table" then
		local rawGarage = source.personalGarage :: { [string]: unknown }
		local validPersonalCars: { [string]: boolean } = {}
		for _, template in DealerCarConfig.catalogCars() do
			validPersonalCars[template.id] = true
		end
		local owned: { [string]: boolean } = {}
		if typeof(rawGarage.owned) == "table" then
			for carId, value in rawGarage.owned :: { [string]: unknown } do
				if value == true and validPersonalCars[carId] == true then
					owned[carId] = true
				end
			end
		end
		local activeCarId = if typeof(rawGarage.activeCarId) == "string"
			and owned[rawGarage.activeCarId :: string] == true
			then rawGarage.activeCarId :: string
			else nil
		if activeCarId == nil then
			for _, template in DealerCarConfig.catalogCars() do
				if owned[template.id] == true then
					activeCarId = template.id
					break
				end
			end
		end
		local expanded = rawGarage.expanded == true
		local secondaryCarId = if expanded and typeof(rawGarage.secondaryCarId) == "string"
			and rawGarage.secondaryCarId ~= activeCarId
			and owned[rawGarage.secondaryCarId :: string] == true
			then rawGarage.secondaryCarId :: string
			else nil
		local customizations: { [string]: PersonalCarCustomizationSave } = {}
		local rawCustomizations = if typeof(rawGarage.customizations) == "table"
			then rawGarage.customizations :: { [string]: unknown }
			else {}
		for _, template in DealerCarConfig.catalogCars() do
			local carId = template.id
			local rawCustomization = rawCustomizations[carId]
			if typeof(rawCustomization) == "table" then
				local sourceCustomization = rawCustomization :: { [string]: unknown }
				local neonInstalled = sourceCustomization.neonInstalled == true
				local colorId = if VehicleNeon.isColorId(sourceCustomization.neonColorId)
					then sourceCustomization.neonColorId :: string
					else nil

				local ownedBodyColorIds: { [string]: boolean } = {}
				if typeof(sourceCustomization.ownedBodyColorIds) == "table" then
					for id, value in sourceCustomization.ownedBodyColorIds :: { [string]: unknown } do
						if value == true and PersonalGarageCustomizationConfig.isBodySelectionIdForModel(id, template.model) then
							ownedBodyColorIds[id] = true
						end
					end
				end
				-- The car's authored first factory paint ships with the car. Always preserve it
				-- as a free owned option so Customize can return to the exact original color.
				local includedBodyColorId = PersonalGarageCustomizationConfig.defaultBodyColorIdForModel(template.model)
				if includedBodyColorId ~= nil then ownedBodyColorIds[includedBodyColorId] = true end
				local savedBodyColorId = sourceCustomization.bodyColorId
				local validFactoryBody = PersonalGarageCustomizationConfig.isFactoryBodyColorIdForModel(
					savedBodyColorId,
					template.model
				) and ownedBodyColorIds[savedBodyColorId :: string] == true
				local validOwnedBody = PersonalGarageCustomizationConfig.isBodyColorId(savedBodyColorId)
					and ownedBodyColorIds[savedBodyColorId :: string] == true
				local bodyColorId = if validFactoryBody or validOwnedBody
					then savedBodyColorId :: string else nil

				local ownedTintLevelIds: { [string]: boolean } = { ["0"] = true }
				if typeof(sourceCustomization.ownedTintLevelIds) == "table" then
					for id, value in sourceCustomization.ownedTintLevelIds :: { [string]: unknown } do
						if value == true and PersonalGarageCustomizationConfig.isTintLevelId(id) then
							ownedTintLevelIds[id] = true
						end
					end
				end
				local tintLevelId = if PersonalGarageCustomizationConfig.isTintLevelId(sourceCustomization.tintLevelId)
					and ownedTintLevelIds[sourceCustomization.tintLevelId :: string] == true
					then sourceCustomization.tintLevelId :: string else "0"

				local ownedTintColorIds: { [string]: boolean } = { black = true }
				if typeof(sourceCustomization.ownedTintColorIds) == "table" then
					for id, value in sourceCustomization.ownedTintColorIds :: { [string]: unknown } do
						if value == true and PersonalGarageCustomizationConfig.isTintColorId(id) then
							ownedTintColorIds[id] = true
						end
					end
				end
				local tintColorId = if PersonalGarageCustomizationConfig.isTintColorId(sourceCustomization.tintColorId)
					and ownedTintColorIds[sourceCustomization.tintColorId :: string] == true
					then sourceCustomization.tintColorId :: string else "black"

				local ownedHeadlightColorIds: { [string]: boolean } = { white = true }
				if typeof(sourceCustomization.ownedHeadlightColorIds) == "table" then
					for id, value in sourceCustomization.ownedHeadlightColorIds :: { [string]: unknown } do
						if value == true and PersonalGarageCustomizationConfig.isHeadlightColorId(id) then
							ownedHeadlightColorIds[id] = true
						end
					end
				end
				local headlightColorId = if PersonalGarageCustomizationConfig.isHeadlightColorId(sourceCustomization.headlightColorId)
					and ownedHeadlightColorIds[sourceCustomization.headlightColorId :: string] == true
					then sourceCustomization.headlightColorId :: string else "white"

				local ownedHeadlightBrightnessIds: { [string]: boolean } = { standard = true }
				if typeof(sourceCustomization.ownedHeadlightBrightnessIds) == "table" then
					for id, value in sourceCustomization.ownedHeadlightBrightnessIds :: { [string]: unknown } do
						if value == true and PersonalGarageCustomizationConfig.isHeadlightBrightnessId(id) then
							ownedHeadlightBrightnessIds[id] = true
						end
					end
				end
				local headlightBrightnessId = if PersonalGarageCustomizationConfig.isHeadlightBrightnessId(sourceCustomization.headlightBrightnessId)
					and ownedHeadlightBrightnessIds[sourceCustomization.headlightBrightnessId :: string] == true
					then sourceCustomization.headlightBrightnessId :: string else "standard"
				local headlightEffectId = if PersonalGarageCustomizationConfig.isHeadlightEffectId(sourceCustomization.headlightEffectId)
					then sourceCustomization.headlightEffectId :: string else "steady"
				headlightColorId = PersonalGarageCustomizationConfig.canonicalHeadlightColorId(headlightColorId, headlightEffectId)
				local acquisitionPaid = nonnegativeWholeOrNil(sourceCustomization.acquisitionPaid)
				local customizationPaid = nonnegativeWholeOrNil(sourceCustomization.customizationPaid)

				customizations[carId] = {
					neonInstalled = neonInstalled,
					neonColorId = if neonInstalled then colorId else nil,
					neonEnabled = neonInstalled and colorId ~= nil and sourceCustomization.neonEnabled == true,
					nitroInstalled = sourceCustomization.nitroInstalled == true,
					accelerationLevel = PersonalGarageCustomizationConfig.performanceLevel(sourceCustomization.accelerationLevel),
					topSpeedLevel = PersonalGarageCustomizationConfig.performanceLevel(sourceCustomization.topSpeedLevel),
					handlingLevel = PersonalGarageCustomizationConfig.performanceLevel(sourceCustomization.handlingLevel),
					stanceInstalled = sourceCustomization.stanceInstalled == true,
					stanceEnabled = sourceCustomization.stanceInstalled == true and sourceCustomization.stanceEnabled == true,
					bodyColorId = bodyColorId,
					ownedBodyColorIds = ownedBodyColorIds,
					tintLevelId = tintLevelId,
					ownedTintLevelIds = ownedTintLevelIds,
					tintColorId = tintColorId,
					ownedTintColorIds = ownedTintColorIds,
					headlightColorId = headlightColorId,
					ownedHeadlightColorIds = ownedHeadlightColorIds,
					headlightBrightnessId = headlightBrightnessId,
					ownedHeadlightBrightnessIds = ownedHeadlightBrightnessIds,
					headlightEffectId = headlightEffectId,
					platesRemoved = sourceCustomization.platesRemoved == true,
					acquisitionPaid = acquisitionPaid,
					customizationPaid = customizationPaid,
				}
			end
		end
		-- The starter choice is one-time onboarding. It remains complete after the free
		-- grant is released; freeStarterCarId only remembers whether that grant is still owned.
		local freeStarterCarId: string? = nil
		if typeof(rawGarage.freeStarterCarId) == "string" then
			local candidate = rawGarage.freeStarterCarId :: string
			if (candidate == "Rusty" or candidate == "Wronkler") and owned[candidate] == true then
				freeStarterCarId = candidate
			end
		end
		if freeStarterCarId == nil and rawGarage.starterChosen == true then
			local activeStarter = if activeCarId ~= nil and (activeCarId == "Rusty" or activeCarId == "Wronkler")
				then activeCarId else nil
			if activeStarter ~= nil then
				freeStarterCarId = activeStarter
			elseif owned.Rusty == true then
				freeStarterCarId = "Rusty"
			elseif owned.Wronkler == true then
				freeStarterCarId = "Wronkler"
			end
		end
		-- Any owned personal car proves the one-time starter gate was completed.
		local starterChosen = rawGarage.starterChosen == true or freeStarterCarId ~= nil
		local hasOwnedCar = false
		for _, ownedFlag in owned do
			if ownedFlag == true then
				hasOwnedCar = true
				starterChosen = true
				break
			end
		end

		-- Version 1 repairs only profiles that predate this migration. Every profile is
		-- stamped even when no repair is needed, so later legitimate collection changes
		-- can never grant another free car.
		local starterRecoveryVersion = if typeof(rawGarage.starterRecoveryVersion) == "number"
			then math.max(0, math.floor(rawGarage.starterRecoveryVersion :: number))
			else 0
		if starterRecoveryVersion < 1 then
			if starterChosen and not hasOwnedCar and freeStarterCarId == nil then
				owned.Rusty = true
				activeCarId = "Rusty"
				secondaryCarId = nil
				freeStarterCarId = "Rusty"
			end
			starterRecoveryVersion = 1
		end

		local trackCooldownUntil = 0
		if typeof(rawGarage.trackCooldownUntil) == "number" then
			local candidate = rawGarage.trackCooldownUntil :: number
			if candidate == candidate and candidate > -math.huge and candidate < math.huge then
				trackCooldownUntil = math.max(0, math.floor(candidate))
			end
		end
		local trackIntroCompleted = if typeof(rawGarage.trackIntroCompleted) == "boolean"
			then rawGarage.trackIntroCompleted == true
			else trackCooldownUntil > 0
		local racingUnlocked = if typeof(rawGarage.racingUnlocked) == "boolean"
			then rawGarage.racingUnlocked == true
			else trackIntroCompleted
		local customFxAdminClaimed = rawGarage.customFxAdminClaimed == true
		result.personalGarage = {
			starterChosen = starterChosen,
			freeStarterCarId = freeStarterCarId,
			starterRecoveryVersion = starterRecoveryVersion,
			owned = owned,
			activeCarId = activeCarId,
			expanded = expanded,
			secondaryCarId = secondaryCarId,
			trackCooldownUntil = trackCooldownUntil,
			trackIntroCompleted = trackIntroCompleted,
			racingUnlocked = racingUnlocked,
			customFxAdminClaimed = customFxAdminClaimed,
			customizations = customizations,
		}
	end

	-- Racing podium counters are additive and deliberately isolated from personal-car state.
	-- Legacy profiles receive zeros; malformed/negative values can never enter the live cache.
	if typeof(source.racing) == "table" then
		local rawRacing = source.racing :: { [string]: unknown }
		result.racing = {
			first = nonnegativeWholeOrNil(rawRacing.first) or 0,
			second = nonnegativeWholeOrNil(rawRacing.second) or 0,
			third = nonnegativeWholeOrNil(rawRacing.third) or 0,
			finishes = nonnegativeWholeOrNil(rawRacing.finishes) or 0,
		}
	end

	-- Progression is additive. Existing profiles derive their minimum chapter from paid
	-- pads, so a schema migration can never send an established player backwards.
	local derivedChapter = deriveChapterFromPads(result.pads, result.tutorial.completed)
	local storedProgression = if typeof(source.progression) == "table"
		then source.progression :: { [string]: unknown }
		else nil
	if storedProgression ~= nil then
		local storedChapter = if typeof(storedProgression.chapter) == "number"
			then math.clamp(math.floor(storedProgression.chapter :: number), 1, MAX_CHAPTER)
			else derivedChapter
		result.progression = {
			chapter = math.max(storedChapter, derivedChapter),
			-- Objective order is canonical and pad-driven; never preserve a stale legacy step.
			objectiveStep = deriveObjectiveStep(result.pads, result.tutorial.completed),
			tutorialComplete = result.tutorial.completed or storedProgression.tutorialComplete == true,
			revision = if typeof(storedProgression.revision) == "number"
				then math.max(1, math.floor(storedProgression.revision :: number))
				else 1,
		}
	else
		result.progression = {
			chapter = derivedChapter,
			objectiveStep = deriveObjectiveStep(result.pads, result.tutorial.completed),
			tutorialComplete = result.tutorial.completed,
			revision = 1,
		}
	end
	syncProgressionData(result)

	if typeof(source.resolvedTrades) == "table" then
		for tradeId, resolved in source.resolvedTrades :: { [string]: unknown } do
			if typeof(tradeId) == "string" and resolved == true then
				result.resolvedTrades[tradeId] = true
			end
		end
	end
	if typeof(source.served) == "table" then
		for key, value in source.served :: { [string]: unknown } do
			if typeof(key) == "string" and typeof(value) == "number" then
				result.served[key] = math.max(0, math.floor(value :: number))
			end
		end
	end
	if typeof(source.analytics) == "table" then
		local analytics = source.analytics :: { [string]: unknown }
		result.analytics = {
			firstRepairAt = if typeof(analytics.firstRepairAt) == "number" then analytics.firstRepairAt :: number else nil,
			firstSaleAt = if typeof(analytics.firstSaleAt) == "number" then analytics.firstSaleAt :: number else nil,
			firstServiceAt = if typeof(analytics.firstServiceAt) == "number" then analytics.firstServiceAt :: number else nil,
			personalCarEnteredAt = if typeof(analytics.personalCarEnteredAt) == "number" then analytics.personalCarEnteredAt :: number else nil,
			personalCarDriven60At = if typeof(analytics.personalCarDriven60At) == "number" then analytics.personalCarDriven60At :: number else nil,
			personalCarNeonPurchasedAt = if typeof(analytics.personalCarNeonPurchasedAt) == "number" then analytics.personalCarNeonPurchasedAt :: number else nil,
			personalCarFunnelStep = if typeof(analytics.personalCarFunnelStep) == "number" then math.clamp(math.floor(analytics.personalCarFunnelStep :: number), 0, 3) else 0,
			onboardingV2Eligible = if typeof(analytics.onboardingV2Eligible) == "boolean" then analytics.onboardingV2Eligible :: boolean else nil,
			onboardingV2Step = if typeof(analytics.onboardingV2Step) == "number" then math.clamp(math.floor(analytics.onboardingV2Step :: number), 0, 14) else 0,
			repairCount = if typeof(analytics.repairCount) == "number" then math.max(0, math.floor(analytics.repairCount :: number)) else 0,
			saleCount = if typeof(analytics.saleCount) == "number" then math.max(0, math.floor(analytics.saleCount :: number)) else 0,
		}
	end
	return result
end

local function keyFor(userId: number): string
	return `player_{userId}`
end

function DataService.load(player: Player): SaveData
	local userId = player.UserId
	if cache[userId] ~= nil then
		return cache[userId]
	end

	local result: SaveData? = nil
	-- Offline income is valid only when a previously saved profile already contains the
	-- timestamp anchor. A brand-new player and a legacy profile without the field start the
	-- clock now and never receive a misleading WELCOME BACK popup on their first session.
	local hadOfflineAnchor = false
	local personalGarageUpdateOffer = false
	local personalGarageMigrationNeeded = false
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, response = pcall(function()
			return store:GetAsync(keyFor(userId))
		end)
		if ok then
			hadOfflineAnchor = typeof(response) == "table"
				and typeof((response :: { [string]: unknown }).lastSeenAt) == "number"
			personalGarageUpdateOffer = typeof(response) == "table"
				and typeof((response :: { [string]: unknown }).personalGarage) ~= "table"
			if typeof(response) == "table" then
				local rawPersonalGarage = (response :: { [string]: unknown }).personalGarage
				if typeof(rawPersonalGarage) == "table" then
					local version = (rawPersonalGarage :: { [string]: unknown }).starterRecoveryVersion
					personalGarageMigrationNeeded = typeof(version) ~= "number" or (version :: number) < 1
				end
			end
			result = sanitize(response, userId)
			loaded[userId] = true
			break
		end
		warn(`[DataService] load failed for {player.Name} (attempt {attempt}): {response}`)
		if attempt < RETRY_ATTEMPTS then
			task.wait(RETRY_DELAY * attempt)
		end
	end

	if result == nil then
		warn(`[DataService] giving {player.Name} a session-only profile; saving is disabled for them`)
		loaded[userId] = false
		result = blankData(userId)
	end

	local now = os.time()
	local elapsed = math.max(0, now - result.lastSeenAt)
	local creditedSeconds = math.min(elapsed, OFFLINE_MAX_SECONDS)
	local rate = offlineRateForPads(result.pads)
	-- "Your business kept working" becomes truthful only after onboarding is over
	-- and the first automated worker has actually been hired.
	local offlineAutomationUnlocked = result.tutorial.completed == true
		and result.pads.FirstMechanic == true
	local offlineEligible = hadOfflineAnchor and offlineAutomationUnlocked
	local offlineEarnings = if offlineEligible and creditedSeconds >= OFFLINE_MIN_SECONDS
		then math.max(0, math.floor(creditedSeconds * rate))
		else 0
	if offlineEarnings > 0 then
		result.cash += offlineEarnings
	end
	result.lastSeenAt = now
	player:SetAttribute("OfflineAutomationUnlocked", offlineAutomationUnlocked)
	player:SetAttribute("OfflineEarningsEligible", offlineEligible)
	player:SetAttribute("OfflineSeconds", if offlineEligible then creditedSeconds else 0)
	player:SetAttribute("OfflineEarnings", offlineEarnings)
	player:SetAttribute("OfflineEarningsRate", rate)
	player:SetAttribute("PersonalGarageUpdateOffer", personalGarageUpdateOffer
		and result.tutorial.completed == true
		and result.personalGarage.starterChosen ~= true)

	cache[userId] = result
	-- The first save of a session should not sit behind a cooldown that never happened.
	lastWrite[userId] = os.clock() - MIN_WRITE_INTERVAL
	changeVersion[userId] = 0
	persistedVersion[userId] = 0
	dirty[userId] = false
	if offlineEarnings > 0 or personalGarageMigrationNeeded then
		task.defer(function()
			if player.Parent ~= nil and cache[userId] == result and loaded[userId] == true then
				DataService.commitCritical(
					player,
					if offlineEarnings > 0 then "offline_earnings" else "personal_garage_recovery_v1"
				)
			end
		end)
	end
	return result
end

function DataService.get(player: Player): SaveData?
	return cache[player.UserId]
end

local function snapshot(data: SaveData)
	-- String keys avoid sparse-array serialization ambiguity in DataStore. Mirror P1/P2
	-- from their compatibility aliases before writing so rolling old servers cannot revive
	-- stale generalized entries.
	DataService.setDisplay(data, 1, data.displayCar)
	DataService.setDisplay(data, 2, data.displayCar2)
	local savedDisplays: { [string]: ActiveCarSave } = {}
	for index = 1, MAX_DISPLAY_SLOTS do
		local car = DataService.getDisplay(data, index)
		if car ~= nil then
			savedDisplays[tostring(index)] = car
		end
	end
	return {
		cash = data.cash,
		luck = data.luck,
		pads = data.pads,
		stationLevels = data.stationLevels,
		activeCar = data.activeCar,
		activeCar2 = data.activeCar2,
		processingCars = data.processingCars,
		incomingQueue = data.incomingQueue,
		displayCars = savedDisplays,
		-- Keep the old fields for one rolling compatibility window.
		displayCar = data.displayCar,
		displayCar2 = data.displayCar2,
		analytics = data.analytics,
		tutorial = data.tutorial,
		personalGarage = data.personalGarage,
		progression = data.progression,
		resolvedTrades = data.resolvedTrades,
		carIndex = data.carIndex,
		carIndexSeen = data.carIndexSeen,
		served = data.served,
		contentRevision = data.contentRevision,
		lastSeenAt = os.time(),
	}
end

local function copySerializable(value: any): any
	if typeof(value) ~= "table" then
		return value
	end
	local copied: { [any]: any } = {}
	for key, child in value :: { [any]: any } do
		copied[copySerializable(key)] = copySerializable(child)
	end
	return copied
end

local function commitOnce(player: Player): boolean
	local userId = player.UserId
	local data = cache[userId]
	if data == nil or loaded[userId] ~= true or writing[userId] == true then
		return false
	end

	local version = changeVersion[userId] or 0
	-- Freeze this generation before UpdateAsync yields; later routine mutations must not
	-- leak into a write whose version marker predates them.
	local payload = copySerializable(snapshot(data))
	writing[userId] = true
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(userId), function()
			return payload
		end)
	end)
	writing[userId] = false
	lastWrite[userId] = os.clock()
	if ok then
		persistedVersion[userId] = math.max(persistedVersion[userId] or 0, version)
		-- A later mutation may have arrived while the DataStore request yielded.
		dirty[userId] = (changeVersion[userId] or 0) > version
	else
		dirty[userId] = true
		warn(`[DataService] save failed for {player.Name}: {err}`)
	end
	return ok
end

local scheduleRoutineWrite: (Player, number) -> ()
scheduleRoutineWrite = function(player: Player, delaySeconds: number)
	local userId = player.UserId
	if pendingWrite[userId] == true then
		return
	end
	pendingWrite[userId] = true
	task.delay(math.max(0, delaySeconds), function()
		pendingWrite[userId] = nil
		if dirty[userId] ~= true or cache[userId] == nil then
			return
		end
		if writing[userId] == true or criticalLock[userId] == true then
			scheduleRoutineWrite(player, 0.25)
			return
		end
		commitOnce(player)
		if dirty[userId] == true and cache[userId] ~= nil then
			scheduleRoutineWrite(player, MIN_WRITE_INTERVAL)
		end
	end)
end

-- Records that the profile changed and writes it as soon as the key is writable. A true
-- result means the mutation was accepted into the server cache; only commitCritical means
-- the exact snapshot has reached DataStore before the call returns.
function DataService.save(player: Player): boolean
	local userId = player.UserId
	if cache[userId] == nil or loaded[userId] ~= true then
		return false
	end

	changeVersion[userId] = (changeVersion[userId] or 0) + 1
	dirty[userId] = true
	local since = os.clock() - (lastWrite[userId] or 0)
	if writing[userId] ~= true and criticalLock[userId] ~= true and since >= MIN_WRITE_INTERVAL then
		local ok = commitOnce(player)
		if not ok then
			scheduleRoutineWrite(player, MIN_WRITE_INTERVAL)
		end
		return true
	end

	scheduleRoutineWrite(player, math.max(0, MIN_WRITE_INTERVAL - since))
	return true
end

-- Synchronously persists a critical state transition. This deliberately bypasses the
-- coalescing cooldown and serializes with routine autosaves. Sales and purchases must not
-- release their physical world object until this returns true.
function DataService.commitCritical(player: Player, reason: string?): boolean
	local userId = player.UserId
	if cache[userId] == nil or loaded[userId] ~= true then
		return false
	end

	local deadline = os.clock() + 20
	while criticalLock[userId] == true or writing[userId] == true do
		if cache[userId] == nil or os.clock() >= deadline then
			warn(`[DataService] critical commit timed out for {player.Name} ({reason or "unspecified"})`)
			return false
		end
		task.wait(0.05)
	end
	criticalLock[userId] = true
	changeVersion[userId] = (changeVersion[userId] or 0) + 1
	dirty[userId] = true

	local committed = false
	for attempt = 1, 3 do
		if commitOnce(player) then
			committed = true
			break
		end
		if attempt < 3 then
			task.wait(0.75 * attempt)
		end
	end
	criticalLock[userId] = nil
	if dirty[userId] == true and cache[userId] ~= nil then
		scheduleRoutineWrite(player, MIN_WRITE_INTERVAL)
	end
	if not committed then
		warn(`[Analytics] CriticalCommitFailed user={player.UserId} reason={reason or "unspecified"}`)
	end
	return committed
end

-- Writes right now for leaving and shutdown.
function DataService.flush(player: Player): boolean
	return DataService.commitCritical(player, "flush")
end

function DataService.isDirty(player: Player): boolean
	return dirty[player.UserId] == true
end

function DataService.getProgression(player: Player): ProgressionSave?
	local data = cache[player.UserId]
	return if data ~= nil then data.progression else nil
end

-- The optional step is retained for existing callers; saved progression is derived from owned pads.
function DataService.setProgression(player: Player, _objectiveStep: string?): boolean
	local data = cache[player.UserId]
	if data == nil then
		return false
	end
	local changed = syncProgressionData(data)
	if changed then
		DataService.save(player)
	end
	return changed
end

-- Compatibility name used by event-driven publishers.
DataService.refreshProgression = DataService.setProgression

-- A pad and every member of its config bundle are one irreversible purchase. Cash and
-- ownership reach DataStore together before PadService reveals models or fires automation.
function DataService.tryPurchasePad(player: Player, padId: string, cost: number): (boolean, string)
	local userId = player.UserId
	local data = cache[userId]
	if data == nil or padId == "" or cost ~= cost or cost == math.huge or cost < 0 then
		return false, "invalid"
	end
	local deadline = os.clock() + 20
	while mutationLock[userId] == true do
		if cache[userId] == nil or os.clock() >= deadline then
			return false, "busy"
		end
		task.wait(0.05)
	end
	mutationLock[userId] = true
	data = cache[userId]
	if data == nil then
		mutationLock[userId] = nil
		return false, "invalid"
	end
	if data.pads[padId] == true then
		mutationLock[userId] = nil
		return false, "duplicate"
	end
	local resolvedCost = math.floor(cost)
	if data.cash < resolvedCost then
		mutationLock[userId] = nil
		return false, "funds"
	end

	local members: { string } = { padId }
	local configAny = TycoonConfig :: any
	if typeof(configAny.bundleMembers) == "function" then
		local ok, configured = pcall(configAny.bundleMembers, padId)
		if ok and typeof(configured) == "table" then
			members = { padId }
			local seen: { [string]: boolean } = { [padId] = true }
			for _, member in configured :: { unknown } do
				if typeof(member) == "string"
					and not seen[member :: string]
					and TycoonConfig.getPad(member :: string) ~= nil
				then
					seen[member :: string] = true
					table.insert(members, member :: string)
				end
			end
		end
	end

	local oldCash = data.cash
	local oldPads: { [string]: boolean } = {}
	for _, member in members do
		oldPads[member] = data.pads[member] == true
		data.pads[member] = true
	end
	data.cash = math.max(0, math.floor(data.cash - resolvedCost))
	local oldProgression = table.clone(data.progression)
	syncProgressionData(data)

	if not DataService.commitCritical(player, `pad:{padId}`) then
		data.cash = oldCash
		for _, member in members do
			data.pads[member] = if oldPads[member] then true else nil
		end
		data.progression = oldProgression
		mutationLock[userId] = nil
		return false, "save_failed"
	end
	mutationLock[userId] = nil
	return true, "purchased"
end

-- Atomically-with-respect-to-this server settles one authoritative trade. The sold state,
-- tutorial advance, ledger and cash are all present in the critical snapshot before the
-- caller may remove the physical car.
function DataService.trySettleTrade(player: Player, tradeId: string, payout: number): (boolean, string)
	local userId = player.UserId
	local data = cache[userId]
	if data == nil or tradeId == "" or payout < 0 or payout ~= payout or payout == math.huge then
		return false, "invalid"
	end
	local deadline = os.clock() + 20
	while mutationLock[userId] == true do
		if cache[userId] == nil or os.clock() >= deadline then
			return false, "busy"
		end
		task.wait(0.05)
	end
	mutationLock[userId] = true
	data = cache[userId]
	if data == nil then
		mutationLock[userId] = nil
		return false, "invalid"
	end
	if data.resolvedTrades[tradeId] == true then
		mutationLock[userId] = nil
		return false, "duplicate"
	end
	local oldCash = data.cash
	local oldProgression = table.clone(data.progression)
	data.resolvedTrades[tradeId] = true
	data.cash = math.max(0, math.floor(data.cash + payout))
	syncProgressionData(data)
	if not DataService.commitCritical(player, `trade:{tradeId}`) then
		data.cash = oldCash
		data.resolvedTrades[tradeId] = nil
		data.progression = oldProgression
		mutationLock[userId] = nil
		return false, "save_failed"
	end
	mutationLock[userId] = nil
	return true, "paid"
end

-- Owner debug reset: replace the in-memory profile only after a persistent write can
-- be attempted, and roll it back on failure. The caller reconnects the player so every
-- runtime system rebuilds from this exact snapshot instead of retaining old cars/staff.
function DataService.debugReset(player: Player): boolean
	local userId = player.UserId
	if loaded[userId] ~= true then
		return false
	end

	local previous = cache[userId]
	local reset = blankData(userId)
	reset.cash = math.max(150, TycoonConfig.STARTING_CASH)
	cache[userId] = reset
	if not DataService.commitCritical(player, "debug_reset") then
		cache[userId] = previous
		return false
	end
	return true
end

function DataService.release(player: Player)
	local userId = player.UserId
	DataService.flush(player)
	cache[userId] = nil
	loaded[userId] = nil
	dirty[userId] = nil
	lastWrite[userId] = nil
	writing[userId] = nil
	pendingWrite[userId] = nil
	changeVersion[userId] = nil
	persistedVersion[userId] = nil
	criticalLock[userId] = nil
	mutationLock[userId] = nil
end

-- Deterministic Studio-only coverage for the destructive starter recovery migration.
-- It operates on isolated tables through the production sanitizer and never touches live profiles.
function DataService.runPersonalGarageMigrationSelfTest(): { string }
	if not RunService:IsStudio() then
		error("personal garage migration self-test is Studio-only")
	end

	local function ownedCount(data: SaveData): number
		local total = 0
		for _, owned in data.personalGarage.owned do
			if owned == true then
				total += 1
			end
		end
		return total
	end

	local recovered = sanitize({
		personalGarage = {
			starterChosen = true,
			starterRecoveryVersion = 0,
			owned = {},
		},
	}, -910001)
	assert(recovered.personalGarage.starterRecoveryVersion == 1, "migration must stamp version 1")
	assert(recovered.personalGarage.owned.Rusty == true, "empty affected profile must recover Rusty")
	assert(recovered.personalGarage.activeCarId == "Rusty", "recovered Rusty must become active")
	assert(recovered.personalGarage.freeStarterCarId == "Rusty", "recovered Rusty must retain free-starter identity")
	assert(ownedCount(recovered) == 1, "migration must recover exactly one car")

	local replayed = sanitize(recovered, -910001)
	assert(replayed.personalGarage.starterRecoveryVersion == 1, "migration stamp must survive a second sanitize")
	assert(ownedCount(replayed) == 1, "migration must be idempotent")

	local alreadyStamped = sanitize({
		personalGarage = {
			starterChosen = true,
			starterRecoveryVersion = 1,
			owned = {},
		},
	}, -910002)
	assert(ownedCount(alreadyStamped) == 0, "a stamped empty profile must not receive another free car")
	assert(alreadyStamped.personalGarage.activeCarId == nil, "a stamped empty profile must remain without an active car")

	local repairedActive = sanitize({
		personalGarage = {
			starterChosen = true,
			starterRecoveryVersion = 1,
			owned = { Rusty = true },
			activeCarId = "MissingCar",
		},
	}, -910003)
	assert(repairedActive.personalGarage.activeCarId == "Rusty", "invalid active car must fall back to an owned car")

	local veteran = sanitize({
		personalGarage = {
			starterRecoveryVersion = 1,
			owned = {},
			trackCooldownUntil = 1,
		},
	}, -910004)
	assert(veteran.personalGarage.trackIntroCompleted == true, "legacy track cooldown must complete veteran intro")

	return {
		"starter recovery grants Rusty once",
		"starter recovery is idempotent",
		"versioned empty profile is not re-granted",
		"invalid active car is repaired",
		"legacy track cooldown completes intro",
	}
end

local AUTOSAVE_INTERVAL = 30

function DataService.init()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				-- An idle profile has nothing new to persist; writing it anyway just burns
				-- budget the active players need.
				if dirty[player.UserId] == true then
					task.spawn(DataService.save, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		-- Studio playtests must save too, otherwise stopping a test loses the session.
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				DataService.flush(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + (if RunService:IsStudio() then 5 else 3)
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
