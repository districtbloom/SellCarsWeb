--!strict

-- Server authority for client-rendered dealer vehicle journeys. A journey advances only
-- when the exact authorized client acknowledges the exact current phase and revision.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RouteMath = require(ReplicatedStorage.DealerVehicleRouteMath)
local RouteTypes = require(ReplicatedStorage.DealerVehicleRouteTypes)
local TycoonConfig = require(ReplicatedStorage.TycoonConfig)

type RouteFeature = RouteTypes.RouteFeature
type RoutePhase = RouteTypes.RoutePhase
type RoutePlan = RouteTypes.RoutePlan
type FeatureFlags = RouteTypes.FeatureFlags
type PhaseAck = RouteTypes.PhaseAck
type JourneyStatus = RouteTypes.JourneyStatus
type JourneySnapshot = RouteTypes.JourneySnapshot

export type BeginParams = {
	feature: RouteFeature,
	plan: RoutePlan,
	journeyId: string?,
	flags: FeatureFlags?,
	authorizedPlayer: Player?,
	replicationTarget: Instance?,
	targetSlot: string?,
	displayIndex: number?,
	validateAck: ((Player?, PhaseAck, JourneySnapshot, RoutePhase) -> (boolean, string?))?,
	onPhaseChanged: ((JourneySnapshot) -> ())?,
	onTerminal: ((JourneySnapshot) -> ())?,
}

type Journey = {
	id: string,
	revision: number,
	feature: RouteFeature,
	flags: FeatureFlags,
	plan: RoutePlan,
	status: JourneyStatus,
	phaseIndex: number,
	phaseStartedAt: number,
	expiresAt: number,
	startedAt: number,
	reason: string?,
	authorizedPlayer: Player?,
	replicationTarget: Instance?,
	targetSlot: string?,
	displayIndex: number?,
	validateAck: ((Player?, PhaseAck, JourneySnapshot, RoutePhase) -> (boolean, string?))?,
	onPhaseChanged: ((JourneySnapshot) -> ())?,
	onTerminal: ((JourneySnapshot) -> ())?,
}

local DealerVehicleJourneyService = {}

local DEFAULT_PHASE_TIMEOUT = 15
local MOVEMENT_TIMEOUT_MULTIPLIER = 2
local MOVEMENT_TIMEOUT_GRACE = 5
local MIN_PHASE_TIMEOUT = 2
local MAX_PHASE_TIMEOUT = 300
local WATCHDOG_INTERVAL = 0.25
local TERMINAL_PUBLISH_SECONDS = 2

local journeysById: { [string]: Journey } = {}
local journeyByTarget: { [Instance]: string } = {}
local initialized = false
local watchdogAccumulator = 0
local changedRemote: RemoteEvent? = nil
local reachedRemote: RemoteEvent? = nil
local snapshotRequestRemote: RemoteEvent? = nil
local lastSnapshotRequest: { [Player]: number } = {}

local ATTRIBUTES = RouteTypes.Attributes
local REMOTES = RouteTypes.Remotes

local function now(): number
	return workspace:GetServerTimeNow()
end

local function cloneFlags(flags: FeatureFlags): FeatureFlags
	return {
		service = flags.service,
		usedParking = flags.usedParking,
		tow = flags.tow,
	}
end

local function clonePhase(phase: RoutePhase): RoutePhase
	return {
		id = phase.id,
		kind = phase.kind,
		motion = phase.motion,
		points = RouteMath.copyPoints(phase.points),
		speed = phase.speed,
		turnRate = phase.turnRate,
		timeoutSeconds = phase.timeoutSeconds,
		arrivalTolerance = phase.arrivalTolerance,
		targetCFrame = phase.targetCFrame,
	}
end

local function currentPhase(journey: Journey): RoutePhase?
	return journey.plan.phases[journey.phaseIndex]
end

local function snapshot(journey: Journey): JourneySnapshot
	local phase = currentPhase(journey)
	local phases: { RoutePhase } = table.create(#journey.plan.phases)
	for _, plannedPhase in journey.plan.phases do
		table.insert(phases, clonePhase(plannedPhase))
	end
	return {
		journeyId = journey.id,
		revision = journey.revision,
		routeId = journey.plan.routeId,
		feature = journey.feature,
		status = journey.status,
		phaseId = if phase ~= nil then phase.id else nil,
		phaseIndex = journey.phaseIndex,
		phaseCount = #journey.plan.phases,
		phase = if phase ~= nil then clonePhase(phase) else nil,
		phases = phases,
		targetSlot = journey.targetSlot,
		displayIndex = journey.displayIndex,
		expiresAt = journey.expiresAt,
		startedAt = journey.startedAt,
		reason = journey.reason,
		flags = cloneFlags(journey.flags),
	}
end

local function safeCallback(label: string, callback: ((JourneySnapshot) -> ())?, state: JourneySnapshot)
	if callback == nil then
		return
	end
	local ok, err = pcall(callback, state)
	if not ok then
		warn(string.format("[DealerVehicleJourney] %s callback failed: %s", label, tostring(err)))
	end
end

local function targetAlive(target: Instance?): boolean
	return target ~= nil and target.Parent ~= nil
end

local function publishAttributes(journey: Journey)
	local target = journey.replicationTarget
	if not targetAlive(target) then
		return
	end
	local phase = currentPhase(journey)
	local liveTarget = target :: Instance
	liveTarget:SetAttribute(ATTRIBUTES.JourneyId, journey.id)
	liveTarget:SetAttribute(ATTRIBUTES.Revision, journey.revision)
	liveTarget:SetAttribute(ATTRIBUTES.RouteId, journey.plan.routeId)
	liveTarget:SetAttribute(ATTRIBUTES.PhaseId, if phase ~= nil then phase.id else nil)
	liveTarget:SetAttribute(ATTRIBUTES.Status, journey.status)
	liveTarget:SetAttribute(ATTRIBUTES.TargetSlot, journey.targetSlot)
	liveTarget:SetAttribute(ATTRIBUTES.DisplayIndex, journey.displayIndex)
	liveTarget:SetAttribute(ATTRIBUTES.ExpiresAt, journey.expiresAt)
end

local function clearAttributesWhenStillCurrent(journey: Journey)
	local target = journey.replicationTarget
	if not targetAlive(target) or (target :: Instance):GetAttribute(ATTRIBUTES.JourneyId) ~= journey.id then
		return
	end
	local liveTarget = target :: Instance
	liveTarget:SetAttribute(ATTRIBUTES.JourneyId, nil)
	liveTarget:SetAttribute(ATTRIBUTES.Revision, nil)
	liveTarget:SetAttribute(ATTRIBUTES.RouteId, nil)
	liveTarget:SetAttribute(ATTRIBUTES.PhaseId, nil)
	liveTarget:SetAttribute(ATTRIBUTES.Status, nil)
	liveTarget:SetAttribute(ATTRIBUTES.TargetSlot, nil)
	liveTarget:SetAttribute(ATTRIBUTES.DisplayIndex, nil)
	liveTarget:SetAttribute(ATTRIBUTES.ExpiresAt, nil)
end

local function fireSnapshot(journey: Journey, state: JourneySnapshot)
	local remote = changedRemote
	if remote == nil then
		return
	end
	local player = journey.authorizedPlayer
	if player ~= nil then
		-- The owner remains the only client allowed to acknowledge the journey, but every
		-- observer must render the same physical proxy. This also broadcasts cancellation
		-- after an owner disconnect, so spectators do not retain an orphaned car.
		remote:FireAllClients(state)
	else
		-- Server-only journeys may still have a visible proxy rendered by every client.
		remote:FireAllClients(state)
	end
end

local function publish(journey: Journey): JourneySnapshot
	local state = snapshot(journey)
	publishAttributes(journey)
	fireSnapshot(journey, state)
	return state
end

local function phaseTimeout(phase: RoutePhase): number
	if phase.timeoutSeconds ~= nil then
		return math.clamp(phase.timeoutSeconds, MIN_PHASE_TIMEOUT, MAX_PHASE_TIMEOUT)
	end
	if phase.motion == "hold" then
		return DEFAULT_PHASE_TIMEOUT
	end
	local travel = RouteMath.estimatedTravelSeconds(phase.points, phase.speed)
	return math.clamp(
		travel * MOVEMENT_TIMEOUT_MULTIPLIER + MOVEMENT_TIMEOUT_GRACE,
		MIN_PHASE_TIMEOUT,
		MAX_PHASE_TIMEOUT
	)
end

local function setPhaseDeadline(journey: Journey, timestamp: number)
	journey.phaseStartedAt = timestamp
	local phase = currentPhase(journey)
	journey.expiresAt = timestamp + (if phase ~= nil then phaseTimeout(phase) else TERMINAL_PUBLISH_SECONDS)
end

local function finishJourney(journey: Journey, status: JourneyStatus, reason: string?): JourneySnapshot
	if journey.status ~= "active" then
		return snapshot(journey)
	end

	journey.status = status
	journey.reason = reason
	journey.revision += 1
	journey.expiresAt = now() + TERMINAL_PUBLISH_SECONDS
	local state = publish(journey)

	local target = journey.replicationTarget
	if target ~= nil and journeyByTarget[target] == journey.id then
		journeyByTarget[target] = nil
	end

	safeCallback("terminal", journey.onTerminal, state)
	task.delay(TERMINAL_PUBLISH_SECONDS, function()
		clearAttributesWhenStillCurrent(journey)
		if journeysById[journey.id] == journey then
			journeysById[journey.id] = nil
		end
	end)
	return state
end

local function finiteNumber(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function finiteCFrame(value: any): boolean
	return typeof(value) == "CFrame"
		and RouteMath.isFiniteVector(value.Position)
		and RouteMath.isFiniteVector(value.LookVector)
		and RouteMath.isFiniteVector(value.RightVector)
		and RouteMath.isFiniteVector(value.UpVector)
end

local function validateAndCloneFlags(rawFlags: any): (FeatureFlags?, string?)
	if type(rawFlags) ~= "table"
		or type(rawFlags.service) ~= "boolean"
		or type(rawFlags.usedParking) ~= "boolean"
		or type(rawFlags.tow) ~= "boolean"
	then
		return nil, "invalid_flags"
	end
	return table.freeze({
		service = rawFlags.service,
		usedParking = rawFlags.usedParking,
		tow = rawFlags.tow,
	}) :: FeatureFlags, nil
end

local function validateAndClonePlan(rawPlan: any): (RoutePlan?, string?)
	if type(rawPlan) ~= "table" then
		return nil, "invalid_plan"
	end
	if rawPlan.version ~= RouteTypes.VERSION then
		return nil, "unsupported_plan_version"
	end
	if type(rawPlan.routeId) ~= "string" or rawPlan.routeId == "" or #rawPlan.routeId > 128 then
		return nil, "invalid_route_id"
	end
	if type(rawPlan.phases) ~= "table" or #rawPlan.phases == 0 or #rawPlan.phases > 32 then
		return nil, "invalid_phases"
	end

	local seenPhaseIds: { [string]: boolean } = {}
	local phases: { RoutePhase } = table.create(#rawPlan.phases)
	for _, rawPhase in ipairs(rawPlan.phases) do
		if type(rawPhase) ~= "table"
			or type(rawPhase.id) ~= "string"
			or rawPhase.id == ""
			or #rawPhase.id > 96
			or seenPhaseIds[rawPhase.id] == true
		then
			return nil, "invalid_phase_id"
		end
		seenPhaseIds[rawPhase.id] = true

		if type(rawPhase.kind) ~= "string" or rawPhase.kind == "" or #rawPhase.kind > 96 then
			return nil, "invalid_phase_kind"
		end
		if not RouteTypes.isMotion(rawPhase.motion) then
			return nil, "invalid_phase_motion"
		end
		if type(rawPhase.points) ~= "table" then
			return nil, "invalid_phase_points"
		end
		local minimumPoints = if rawPhase.motion == "hold" then 1 else 2
		if #rawPhase.points < minimumPoints or #rawPhase.points > 2048 then
			return nil, "invalid_phase_points"
		end
		local points: { Vector3 } = table.create(#rawPhase.points)
		for _, point in ipairs(rawPhase.points) do
			if not RouteMath.isFiniteVector(point) then
				return nil, "invalid_phase_point"
			end
			table.insert(points, point)
		end

		if not finiteNumber(rawPhase.speed)
			or (rawPhase.motion == "hold" and rawPhase.speed < 0)
			or (rawPhase.motion ~= "hold" and rawPhase.speed <= 0)
		then
			return nil, "invalid_phase_speed"
		end
		if rawPhase.turnRate ~= nil and (not finiteNumber(rawPhase.turnRate) or rawPhase.turnRate <= 0) then
			return nil, "invalid_phase_turn_rate"
		end
		if rawPhase.timeoutSeconds ~= nil
			and (not finiteNumber(rawPhase.timeoutSeconds) or rawPhase.timeoutSeconds <= 0)
		then
			return nil, "invalid_phase_timeout"
		end
		if rawPhase.arrivalTolerance ~= nil
			and (not finiteNumber(rawPhase.arrivalTolerance) or rawPhase.arrivalTolerance <= 0)
		then
			return nil, "invalid_arrival_tolerance"
		end
		if rawPhase.targetCFrame ~= nil and not finiteCFrame(rawPhase.targetCFrame) then
			return nil, "invalid_target_cframe"
		end

		table.insert(phases, {
			id = rawPhase.id,
			kind = rawPhase.kind,
			motion = rawPhase.motion,
			points = points,
			speed = rawPhase.speed,
			turnRate = rawPhase.turnRate,
			timeoutSeconds = rawPhase.timeoutSeconds,
			arrivalTolerance = rawPhase.arrivalTolerance,
			targetCFrame = rawPhase.targetCFrame,
		})
	end

	local targetSlot = rawPlan.targetSlot
	if targetSlot ~= nil and (type(targetSlot) ~= "string" or targetSlot == "" or #targetSlot > 96) then
		return nil, "invalid_target_slot"
	end
	local displayIndex = rawPlan.displayIndex
	if displayIndex ~= nil
		and (not finiteNumber(displayIndex) or displayIndex < 1 or displayIndex % 1 ~= 0)
	then
		return nil, "invalid_display_index"
	end

	return {
		version = RouteTypes.VERSION,
		routeId = rawPlan.routeId,
		phases = phases,
		targetSlot = targetSlot,
		displayIndex = displayIndex,
	}, nil
end

local function ensureRemote(folder: Instance, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing ~= nil then
		assert(existing:IsA("RemoteEvent"), string.format("TycoonRemotes.%s must be a RemoteEvent", name))
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function DealerVehicleJourneyService.latchFlags(): FeatureFlags
	return table.freeze({
		service = TycoonConfig.ROUTING_V2_SERVICE == true,
		usedParking = TycoonConfig.ROUTING_V2_USED_PARKING == true,
		tow = TycoonConfig.ROUTING_V2_TOW == true,
	}) :: FeatureFlags
end

function DealerVehicleJourneyService.isFeatureEnabled(feature: RouteFeature, flags: FeatureFlags?): boolean
	local latched = flags or DealerVehicleJourneyService.latchFlags()
	if feature == "service" or feature == "usedParking" or feature == "tow" then
		return latched[feature]
	end
	return false
end

function DealerVehicleJourneyService.init()
	if initialized then
		return
	end
	initialized = true

	local folder = ReplicatedStorage:FindFirstChild("TycoonRemotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "TycoonRemotes"
		folder.Parent = ReplicatedStorage
	end
	changedRemote = ensureRemote(folder, REMOTES.JourneyChanged)
	reachedRemote = ensureRemote(folder, REMOTES.PhaseReached)
	snapshotRequestRemote = ensureRemote(folder, REMOTES.SnapshotRequest)
	local liveChangedRemote = changedRemote :: RemoteEvent
	local liveReachedRemote = reachedRemote :: RemoteEvent
	local liveSnapshotRequestRemote = snapshotRequestRemote :: RemoteEvent

	liveReachedRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "table" then
			DealerVehicleJourneyService.acknowledge(player, payload)
		end
	end)
	liveSnapshotRequestRemote.OnServerEvent:Connect(function(player: Player)
		local timestamp = now()
		if timestamp - (lastSnapshotRequest[player] or -math.huge) < 1 then
			return
		end
		lastSnapshotRequest[player] = timestamp
		for _, journey in pairs(journeysById) do
			-- Journey plans describe visible dealership traffic, so spectators receive the
			-- same read-only state. Only PhaseReached remains owner-authorized above.
			liveChangedRemote:FireClient(player, snapshot(journey))
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		watchdogAccumulator += deltaTime
		if watchdogAccumulator < WATCHDOG_INTERVAL then
			return
		end
		watchdogAccumulator = 0
		local timestamp = now()
		local expired: { Journey } = {}
		for _, journey in pairs(journeysById) do
			if journey.status == "active" and timestamp >= journey.expiresAt then
				table.insert(expired, journey)
			end
		end
		for _, journey in ipairs(expired) do
			finishJourney(journey, "timedOut", "phase_timeout")
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastSnapshotRequest[player] = nil
		local owned: { Journey } = {}
		for _, journey in pairs(journeysById) do
			if journey.status == "active" and journey.authorizedPlayer == player then
				table.insert(owned, journey)
			end
		end
		for _, journey in ipairs(owned) do
			finishJourney(journey, "cancelled", "player_left")
		end
	end)
end

function DealerVehicleJourneyService.begin(params: BeginParams): (JourneySnapshot?, string?)
	DealerVehicleJourneyService.init()
	if type(params) ~= "table" or not RouteTypes.isFeature(params.feature) then
		return nil, "invalid_feature"
	end

	local flags: FeatureFlags
	if params.flags ~= nil then
		local clonedFlags, flagsError = validateAndCloneFlags(params.flags)
		if clonedFlags == nil then
			return nil, flagsError
		end
		flags = clonedFlags
	else
		flags = DealerVehicleJourneyService.latchFlags()
	end
	if not DealerVehicleJourneyService.isFeatureEnabled(params.feature, flags) then
		return nil, "feature_disabled"
	end
	local plan, planError = validateAndClonePlan(params.plan)
	if plan == nil then
		return nil, planError
	end
	if params.authorizedPlayer ~= nil and params.authorizedPlayer.Parent ~= Players then
		return nil, "invalid_authorized_player"
	end
	if params.replicationTarget ~= nil and params.replicationTarget.Parent == nil then
		return nil, "invalid_replication_target"
	end
	if params.replicationTarget ~= nil then
		local existingId = journeyByTarget[params.replicationTarget]
		local existing = if existingId ~= nil then journeysById[existingId] else nil
		if existing ~= nil and existing.status == "active" then
			return nil, "replication_target_busy"
		end
	end
	if params.journeyId ~= nil
		and (type(params.journeyId) ~= "string" or params.journeyId == "" or #params.journeyId > 128)
	then
		return nil, "invalid_journey_id"
	end
	local journeyId = params.journeyId or HttpService:GenerateGUID(false)
	if journeysById[journeyId] ~= nil then
		return nil, "journey_id_busy"
	end

	local targetSlot = params.targetSlot or plan.targetSlot
	if targetSlot ~= nil and (type(targetSlot) ~= "string" or targetSlot == "" or #targetSlot > 96) then
		return nil, "invalid_target_slot"
	end
	local displayIndex = params.displayIndex or plan.displayIndex
	if displayIndex ~= nil
		and (not finiteNumber(displayIndex) or displayIndex < 1 or displayIndex % 1 ~= 0)
	then
		return nil, "invalid_display_index"
	end

	local timestamp = now()
	local journey: Journey = {
		id = journeyId,
		revision = 1,
		feature = params.feature,
		flags = flags,
		plan = plan,
		status = "active",
		phaseIndex = 1,
		phaseStartedAt = timestamp,
		expiresAt = timestamp,
		startedAt = timestamp,
		reason = nil,
		authorizedPlayer = params.authorizedPlayer,
		replicationTarget = params.replicationTarget,
		targetSlot = targetSlot,
		displayIndex = displayIndex,
		validateAck = params.validateAck,
		onPhaseChanged = params.onPhaseChanged,
		onTerminal = params.onTerminal,
	}
	setPhaseDeadline(journey, timestamp)
	journeysById[journey.id] = journey
	if journey.replicationTarget ~= nil then
		journeyByTarget[journey.replicationTarget] = journey.id
	end

	local state = publish(journey)
	safeCallback("phase", journey.onPhaseChanged, state)
	return state, nil
end

local function validateAckShape(rawAck: any): (PhaseAck?, string?)
	if type(rawAck) ~= "table"
		or type(rawAck.journeyId) ~= "string"
		or rawAck.journeyId == ""
		or #rawAck.journeyId > 128
		or not finiteNumber(rawAck.revision)
		or rawAck.revision < 1
		or rawAck.revision % 1 ~= 0
		or type(rawAck.phaseId) ~= "string"
		or rawAck.phaseId == ""
		or #rawAck.phaseId > 96
		or not finiteNumber(rawAck.phaseIndex)
		or rawAck.phaseIndex < 1
		or rawAck.phaseIndex % 1 ~= 0
		or (rawAck.finalCFrame ~= nil and not finiteCFrame(rawAck.finalCFrame))
	then
		return nil, "invalid_ack"
	end
	return {
		journeyId = rawAck.journeyId,
		revision = rawAck.revision,
		phaseId = rawAck.phaseId,
		phaseIndex = rawAck.phaseIndex,
		finalCFrame = rawAck.finalCFrame,
	}, nil
end

local function acknowledgeInternal(
	player: Player?,
	rawAck: any,
	serverTrusted: boolean
): (boolean, string, JourneySnapshot?)
	local ack, ackError = validateAckShape(rawAck)
	if ack == nil then
		return false, ackError or "invalid_ack", nil
	end
	local journey = journeysById[ack.journeyId]
	if journey == nil then
		return false, "unknown_journey", nil
	end
	if journey.status ~= "active" then
		return false, "journey_terminal", snapshot(journey)
	end
	if not serverTrusted then
		if journey.authorizedPlayer == nil then
			return false, "server_only", nil
		end
		if player ~= journey.authorizedPlayer then
			return false, "unauthorized_player", nil
		end
	end
	if ack.revision ~= journey.revision then
		return false, "stale_revision", snapshot(journey)
	end
	if ack.phaseIndex ~= journey.phaseIndex then
		return false, "wrong_phase_index", snapshot(journey)
	end
	local phase = currentPhase(journey)
	if phase == nil or ack.phaseId ~= phase.id then
		return false, "wrong_phase_id", snapshot(journey)
	end
	if now() >= journey.expiresAt then
		return false, "phase_timeout", finishJourney(journey, "timedOut", "phase_timeout")
	end
	if phase.targetCFrame ~= nil then
		if ack.finalCFrame == nil then
			return false, "missing_final_cframe", snapshot(journey)
		end
		local tolerance = phase.arrivalTolerance or 6
		if (ack.finalCFrame.Position - phase.targetCFrame.Position).Magnitude > tolerance then
			return false, "outside_arrival_tolerance", snapshot(journey)
		end
	end
	local validator = journey.validateAck
	if validator ~= nil then
		local ok, accepted, reason = pcall(
			validator,
			player,
			ack,
			snapshot(journey),
			clonePhase(phase)
		)
		if not ok then
			warn(string.format("[DealerVehicleJourney] ACK validator failed: %s", tostring(accepted)))
			return false, "validator_failed", nil
		end
		if accepted ~= true then
			return false, if type(reason) == "string" and reason ~= "" then reason else "arrival_rejected", nil
		end
	end

	if journey.phaseIndex >= #journey.plan.phases then
		return true, "completed", finishJourney(journey, "completed", nil)
	end

	journey.phaseIndex += 1
	journey.revision += 1
	setPhaseDeadline(journey, now())
	local state = publish(journey)
	safeCallback("phase", journey.onPhaseChanged, state)
	return true, "advanced", state
end

function DealerVehicleJourneyService.acknowledge(
	player: Player,
	ack: PhaseAck
): (boolean, string, JourneySnapshot?)
	return acknowledgeInternal(player, ack, false)
end

function DealerVehicleJourneyService.acknowledgeServer(
	ack: PhaseAck
): (boolean, string, JourneySnapshot?)
	return acknowledgeInternal(nil, ack, true)
end

function DealerVehicleJourneyService.cancel(journeyId: string, reason: string?): (boolean, JourneySnapshot?)
	local journey = journeysById[journeyId]
	if journey == nil or journey.status ~= "active" then
		return false, if journey ~= nil then snapshot(journey) else nil
	end
	return true, finishJourney(journey, "cancelled", reason or "cancelled")
end

function DealerVehicleJourneyService.cancelByTarget(target: Instance, reason: string?): boolean
	local journeyId = journeyByTarget[target]
	if journeyId == nil then
		return false
	end
	local cancelled = DealerVehicleJourneyService.cancel(journeyId, reason)
	return cancelled
end

function DealerVehicleJourneyService.getSnapshot(journeyId: string): JourneySnapshot?
	local journey = journeysById[journeyId]
	return if journey ~= nil then snapshot(journey) else nil
end

function DealerVehicleJourneyService.getCurrentPhase(journeyId: string): RoutePhase?
	local journey = journeysById[journeyId]
	local phase = if journey ~= nil then currentPhase(journey) else nil
	return if phase ~= nil then clonePhase(phase) else nil
end

function DealerVehicleJourneyService.getLatchedFlags(journeyId: string): FeatureFlags?
	local journey = journeysById[journeyId]
	return if journey ~= nil then cloneFlags(journey.flags) else nil
end

function DealerVehicleJourneyService.activeCount(): number
	local count = 0
	for _, journey in pairs(journeysById) do
		if journey.status == "active" then
			count += 1
		end
	end
	return count
end

return DealerVehicleJourneyService
