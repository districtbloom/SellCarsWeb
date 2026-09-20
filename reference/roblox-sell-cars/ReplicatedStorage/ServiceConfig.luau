--!strict

export type Phase = { name: string, duration: number }
export type SlotDefinition = {
	id: string,
	kind: string,
	zone: string,
	requires: { string },
	mechanicPad: string?,
	workerPad: string?,
	serviceLabel: string?,
	geometryPath: { string }?,
	driveSurface: string?,
	exitRamp: string?,
	brushMachine: string?,
	roadApproach: string?,
	roadEntry: string?,
	roadExit: string?,
	roadDeparture: string?,
	exitRouteLocal: { Vector3 }?,
	exitRouteLocalEven: { Vector3 }?,
	chapter: number?,
}

local ServiceConfig = {}

-- Repair Bay New uses independent server-authoritative job slots for both lifts.
ServiceConfig.ENABLED = true
ServiceConfig.GAP_MIN = 14
ServiceConfig.GAP_MAX = 30
-- Repair Bay customers keep a tighter, readable cadence than the other businesses.
ServiceConfig.REPAIR_GAP_MIN = 5
ServiceConfig.REPAIR_GAP_MAX = 10
ServiceConfig.LIFT_HEIGHT = 5
ServiceConfig.APPROACH_TIME = 11
ServiceConfig.DIAGNOSIS_HOLD_TIME = 1
ServiceConfig.DIAGNOSIS_TIME = 0.8
ServiceConfig.RAISE_TIME = 2.2
ServiceConfig.HOOD_SERVICE_HOLD_TIME = 4
ServiceConfig.HOOD_SERVICE_TIME = 0.8
ServiceConfig.ENGINE_TEST_HOLD_TIME = 1.5
ServiceConfig.ENGINE_TEST_TIME = 1
ServiceConfig.CHECKOUT_HOLD_TIME = 1.5
ServiceConfig.AUTO_REPAIR_TIME = 8
ServiceConfig.MANUAL_FINISH_TIME = 0.8
ServiceConfig.LOWER_TIME = 2.2
ServiceConfig.REVERSE_TIME = 4.5
ServiceConfig.DEPART_TIME = 9
ServiceConfig.CHECKOUT_TIME = 2.5
ServiceConfig.CHECKOUT_DESK_PAD = "CO_ComputerDesk"
ServiceConfig.CHECKOUT_CLERK_PAD = "CO_CheckoutAutomation"
ServiceConfig.TUNING_SERVICE_ADVISOR_PAD = "TA_ServiceAdvisor"
ServiceConfig.TUNING_OPERATIONS_MANAGER_PAD = "TA_OperationsManager"
ServiceConfig.TUNING_APPROACH_TIME = 14
ServiceConfig.TUNING_AUTO_WORK_TIME = 10
ServiceConfig.TUNING_MANUAL_HOLD_TIME = 4
ServiceConfig.TUNING_MANUAL_FINISH_TIME = 0.8
ServiceConfig.TUNING_PLAYER_IDLE_RESUME_TIME = 8
ServiceConfig.TUNING_CHECKOUT_TIME = 2.5
ServiceConfig.TUNING_CHECKOUT_HOLD_TIME = 1.5
ServiceConfig.TUNING_DEPART_TIME = 12
ServiceConfig.PLAY_RADIUS = 900
-- Never dispatch two wash customers onto the shared road entrance in the same moment.
ServiceConfig.WASH_START_STAGGER = 4

-- Speed pads in the repair zone used to be dead money: fillTime is never consulted for a
-- jobDriven station, so the whole cycle ran on the constants above no matter what was
-- bought. NPCService now divides every phase and the between-jobs gap by the zone speed
-- multiplier, floored so a fully upgraded bay still reads as a repair rather than a blink.
ServiceConfig.MIN_PHASE_TIME = 0.6
ServiceConfig.MIN_GAP = 3

-- Owned dealer stock now uses OwnerCarPipeline for one persisted multi-stage plan. These
-- two legacy values remain only for rolling compatibility; new scheduling/value code does
-- not read them. At most four owned cars may be queued/active, and NPCService applies a
-- hard two-owner burst limit whenever a street customer is also eligible.
ServiceConfig.LOT_JOB_CHANCE = 0
ServiceConfig.LOT_SERVICE_BONUS = 1.5
ServiceConfig.LOT_QUEUE_CAPACITY = 4
ServiceConfig.OWNER_BURST_LIMIT = 2
-- A street customer waiting for a physical service slot is a real queue customer. Thirty
-- seconds is long enough to see the line move, but short enough that an unstaffed bay
-- cannot freeze street traffic. Owned dealer stock no longer uses this occupancy abort:
-- a busy Repair Bay keeps the helper waiting in line instead of dumping the car through
-- Used Cars fences onto listing. Timed-out owned stock still keeps completed value and
-- takes this listing penalty only from the 90s active-service stall path.
ServiceConfig.QUEUE_WAIT_TIMEOUT = 30
-- Owner junk → Repair Bay is a physical drive, not a speed-padded phase. NPCService
-- holds the job until this travel has elapsed so the queue clone can arrive before
-- Approaching/Raising start. Must match TycoonServiceClient QUEUE_DRIVE_SPEED.
ServiceConfig.OWNER_QUEUE_DRIVE_SPEED = 22
ServiceConfig.OWNER_REPAIR_DRIVE_IN_MIN = 8
ServiceConfig.OWNER_REPAIR_DRIVE_IN_MAX = 20
ServiceConfig.ACTIVE_SERVICE_STALL_TIMEOUT = 90
ServiceConfig.OWNER_TIMEOUT_VALUE_MULTIPLIER = 0.75
-- Queued owner stock emits an operational warning/metric before the hard escape. The
-- emergency path preserves every completed stage and returns the exact car to listing.
ServiceConfig.OWNER_QUEUE_WARNING_AGE = 60
ServiceConfig.OWNER_QUEUE_WARNING_INTERVAL = 60
ServiceConfig.OWNER_QUEUE_EMERGENCY_AGE = 180

ServiceConfig.SLOTS = {
	-- Stage B keeps Bay 1 intact and activates the authored second customer slot.
	-- Each bay can run manually once its geometry exists; its mechanic automates the work.
	{ id = "RepairBay1", kind = "repairing", zone = "repair", requires = { "RB_CarLift" }, mechanicPad = "RB_MechanicNPC", chapter = 3 },
	{ id = "RepairBay2", kind = "repairing", zone = "repair", requires = { "RB2_CarLift" }, mechanicPad = "RB2_MechanicNPC", chapter = 3 },
	-- Brush Machine alone starts each automated business; the shells are optional.
	{
		id = "CarWash1",
		kind = "washing",
		zone = "wash",
		requires = { "CO_CheckoutAutomation", "CW_BrushMachine" },
		geometryPath = { "Buildings", "CarWash" },
		driveSurface = "CarWash_DriveSurface",
		exitRamp = "CarWash_ExitRamp",
		brushMachine = "BrushMachine",
		chapter = 4,
		roadApproach = "CarWash_RoadApproach",
		roadEntry = "CarWash_RoadEntry",
		roadExit = "CarWash_RoadExit",
		roadDeparture = "CarWash_RoadDeparture",
		-- Vehicle-route control points authored on the redesigned Tycoon1 U-exit. Runtime
		-- preserves X/Z and projects Y onto the built ramps/exit ways for every rotated plot.
		exitRouteLocal = {
			Vector3.new(-0.355408, 2.033001, -33.475647),
			Vector3.new(-0.742401, 2.066001, -87.823669),
			Vector3.new(84.070602, 2.066001, -87.749634),
			Vector3.new(83.872620, 2.003001, 29.758362),
		},
	},
	{
		id = "CarWash2",
		kind = "washing",
		zone = "wash2",
		requires = { "CO_CheckoutAutomation", "CW2_BrushMachine" },
		geometryPath = { "Buildings", "CarWash", "CarWash", "CarWash2" },
		driveSurface = "CarWash2_DriveSurface",
		exitRamp = "CarWash2_ExitRamp",
		brushMachine = "CarWash2_BrushMachine",
		chapter = 5,
		roadApproach = "CarWash2_RoadApproach",
		roadEntry = "CarWash2_RoadEntry",
		roadExit = "CarWash2_RoadExit",
		roadDeparture = "CarWash2_RoadDeparture",
		exitRouteLocal = {
			Vector3.new(0.544617, 2.066001, -38.295654),
			Vector3.new(0.873611, 2.066001, -88.335632),
			Vector3.new(45.070602, 2.066001, -87.749634),
			Vector3.new(44.872620, 2.003001, 29.758362),
		},
	},
	-- Three fully independent Tuning Atelier queues. A station accepts manual work as soon
	-- as its core machine is built; buying the matching specialist automates that one queue.
	{
		id = "TuningDyno",
		kind = "tuningDyno",
		zone = "tuningDyno",
		requires = { "TA_DynoRollers" },
		workerPad = "TA_DynoSpecialist",
		serviceLabel = "DYNO + ENGINE TUNE",
		chapter = 6,
		geometryPath = { "Buildings", "TuningAtelier", "ServiceMarkers", "TuningDyno" },
	},
	{
		id = "TuningBody",
		kind = "tuningBody",
		zone = "tuningBody",
		requires = { "TA_BodyKitStation" },
		workerPad = "TA_BodySpecialist",
		serviceLabel = "BODY KIT INSTALL",
		chapter = 6,
		geometryPath = { "Buildings", "TuningAtelier", "ServiceMarkers", "TuningBody" },
	},
	{
		id = "TuningPaint",
		kind = "tuningPaint",
		zone = "tuningPaint",
		requires = { "TA_PaintControl" },
		workerPad = "TA_PaintSpecialist",
		serviceLabel = "PAINT + FINISH",
		chapter = 6,
		geometryPath = { "Buildings", "TuningAtelier", "ServiceMarkers", "TuningPaint" },
	},
} :: { SlotDefinition }

-- Both plot orientations use the same authored wash exit.
for _, slot in ServiceConfig.SLOTS do
	if slot.exitRouteLocal then
		slot.exitRouteLocalEven = table.clone(slot.exitRouteLocal)
	end
end

-- Kept for code outside the slot orchestrator.
ServiceConfig.REPAIR_PAD = "RB_CarLift"
ServiceConfig.WASH_PAD = "CW_Foundation"
ServiceConfig.BRUSH_PAD = "CW_BrushMachine"

function ServiceConfig.getSlot(id: string): SlotDefinition?
	for _, slot in ServiceConfig.SLOTS do
		if slot.id == id then
			return slot
		end
	end
	return nil
end

function ServiceConfig.isTuningKind(kind: any): boolean
	return kind == "tuningDyno" or kind == "tuningBody" or kind == "tuningPaint"
end

ServiceConfig.PHASES = {
	repairing = {
		{ name = "approach", duration = 4 },
		{ name = "enter", duration = 3 },
		{ name = "raise", duration = 2.2 },
		{ name = "work", duration = 8 },
		{ name = "lower", duration = 2.2 },
		{ name = "reverse", duration = 4.5 },
		{ name = "depart", duration = 12 },
	},
	washing = {
		{ name = "approach", duration = 9 },
		{ name = "enter", duration = 3 },
		{ name = "through", duration = 12 },
		{ name = "exit", duration = 4 },
		{ name = "depart", duration = 12 },
	},
}

function ServiceConfig.totalTime(kind: string): number
	local phases = ServiceConfig.PHASES[kind]
	if phases == nil then
		return 0
	end
	local total = 0
	for _, phase in phases do
		total += phase.duration
	end
	return total
end

function ServiceConfig.phaseAt(kind: string, elapsed: number): (string, number)
	local phases = ServiceConfig.PHASES[kind]
	if phases == nil then
		return "idle", 0
	end
	local cursor = 0
	for _, phase in phases do
		if elapsed < cursor + phase.duration then
			return phase.name, (elapsed - cursor) / phase.duration
		end
		cursor += phase.duration
	end
	return "done", 1
end

return ServiceConfig

