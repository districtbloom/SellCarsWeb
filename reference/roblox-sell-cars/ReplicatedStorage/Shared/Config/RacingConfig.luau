--!strict
-- Shared contract for the server-authoritative phone racing mode.
local RacingConfig = {}

RacingConfig.MAX_PLAYERS = 8
RacingConfig.MIN_PLAYERS = 2
RacingConfig.LOBBY_SECONDS = 15
RacingConfig.COUNTDOWN_SECONDS = 10
RacingConfig.RESULTS_SECONDS = 12
RacingConfig.CHECK_INTERVAL = 0.08

-- Server safety: track-specific hard limits, progress watchdogs and a short
-- grace period after the first finisher prevent abandoned races from hanging.
RacingConfig.TRACK_SAFETY = {
	main = {
		noProgressSeconds = 45,
		finishGraceSeconds = 60,
		hardLimitByLaps = { [1] = 3 * 60, [2] = 5 * 60, [3] = 7 * 60 },
		corridorRadius = 115,
	},
	outer = {
		noProgressSeconds = 60,
		finishGraceSeconds = 90,
		hardLimitByLaps = { [1] = 4 * 60, [2] = 7 * 60, [3] = 10 * 60 },
		corridorRadius = 125,
	},
	drag = {
		noProgressSeconds = 15,
		finishGraceSeconds = 30,
		hardLimitByLaps = { [1] = 45 },
		corridorRadius = 75,
	},
}
RacingConfig.OFF_ROUTE_GRACE_SECONDS = 4
RacingConfig.OUT_OF_CAR_GRACE_SECONDS = 5
RacingConfig.FLIPPED_GRACE_SECONDS = 5
RacingConfig.RESET_PENALTY_SECONDS = 5
RacingConfig.MAX_STALL_RESETS = 1
RacingConfig.MAX_ROUTE_RESETS = 2
RacingConfig.TELEPORT_BASE_ALLOWANCE = 70
RacingConfig.MAX_PLAUSIBLE_SPEED = 520
-- Checkpoints are oriented drive-through gates. The authored 52x24x5 volume is
-- expanded slightly so grazing an arch still counts without allowing route skips.
RacingConfig.CHECKPOINT_EXTRA_WIDTH = 8
RacingConfig.CHECKPOINT_EXTRA_HEIGHT = 6
RacingConfig.CHECKPOINT_EXTRA_DEPTH = 10
RacingConfig.GRID_LANE_OFFSET = 5.5
RacingConfig.GRID_ROW_SPACING = 16
RacingConfig.SERVER_COOLDOWN_SECONDS = 20
RacingConfig.REWARD_COOLDOWN_SECONDS = 2 * 60
RacingConfig.REPEAT_ROSTER_WINDOW_SECONDS = 10 * 60
RacingConfig.REPEAT_ROSTER_MULTIPLIERS = { 1, 0.5, 0.25, 0 }
RacingConfig.TRACK_REWARD_MULTIPLIERS = {
	main = { [1] = 1, [2] = 1.5, [3] = 2 },
	outer = { [1] = 1.4, [2] = 2.1, [3] = 2.8 },
	drag = { [1] = 0.45 },
}
RacingConfig.ICON = "rbxassetid://112516608041361"

RacingConfig.PODIUM_REWARDS = {
	[1] = 25000,
	[2] = 15000,
	[3] = 8000,
}

RacingConfig.TRACK_ORDER = { "main", "outer", "drag" }
RacingConfig.TRACKS = {
	main = {
		id = "main",
		label = "MAIN CIRCUIT",
		description = "24 checkpoints through the complete Main Track",
		kind = "circuit",
		lapOptions = { 1, 2, 3 },
	},
	outer = {
		id = "outer",
		label = "OUTER RING",
		description = "26 checkpoints around the full outer perimeter",
		kind = "circuit",
		lapOptions = { 1, 2, 3 },
	},
	drag = {
		id = "drag",
		label = "NEON DRAG",
		description = "Four checkpoint straight sprint to the finish",
		kind = "sprint",
		lapOptions = { 1 },
	},
}

RacingConfig.CAR_ORDER = { "HondoCivixEK", "Gblock", "Porschka911", "FierroRossa", "ZentauriR" }
RacingConfig.CARS = {
	Gblock = { id = "Gblock", model = "Gblock", label = "G-BLOCK" },
	HondoCivixEK = { id = "HondoCivixEK", model = "HondoCivixEK", label = "HONDO CIVIX EK" },
	Porschka911 = { id = "Porschka911", model = "Porschka911", label = "PORSCHKA 911" },
	FierroRossa = { id = "FierroRossa", model = "FierroRossa", label = "FIERRO ROSSA" },
	ZentauriR = { id = "ZentauriR", model = "ZentauriR", label = "ZENTAURI R" },
}

RacingConfig.RACER_COLORS = {
	{ body = Color3.fromHex("00CFFF"), neon = "cyan" },
	{ body = Color3.fromHex("FF3B68"), neon = "red" },
	{ body = Color3.fromHex("D34BFF"), neon = "magenta" },
	{ body = Color3.fromHex("7CFF4A"), neon = "lime" },
	{ body = Color3.fromHex("FF8A2B"), neon = "orange" },
	{ body = Color3.fromHex("F7F7F4"), neon = "cyan" },
	{ body = Color3.fromHex("FFD84A"), neon = "orange" },
	{ body = Color3.fromHex("5E79FF"), neon = "magenta" },
}

function RacingConfig.rewardMultiplier(trackId: string, laps: number): number
	local byLaps = RacingConfig.TRACK_REWARD_MULTIPLIERS[trackId]
	return if byLaps ~= nil then byLaps[laps] or byLaps[1] or 1 else 1
end

function RacingConfig.safety(trackId: string, laps: number): { [string]: any }
	local definition = RacingConfig.TRACK_SAFETY[trackId] or RacingConfig.TRACK_SAFETY.main
	return {
		noProgressSeconds = definition.noProgressSeconds,
		finishGraceSeconds = definition.finishGraceSeconds,
		hardLimitSeconds = definition.hardLimitByLaps[laps] or definition.hardLimitByLaps[1],
		corridorRadius = definition.corridorRadius,
	}
end

function RacingConfig.validTrack(id: unknown): boolean
	return typeof(id) == "string" and RacingConfig.TRACKS[id :: string] ~= nil
end

function RacingConfig.validCar(id: unknown): boolean
	return typeof(id) == "string" and RacingConfig.CARS[id :: string] ~= nil
end

function RacingConfig.validLaps(trackId: string, laps: unknown): boolean
	local track = RacingConfig.TRACKS[trackId]
	if track == nil or typeof(laps) ~= "number" then return false end
	local whole = math.floor(laps :: number)
	for _, option in track.lapOptions do
		if option == whole then return true end
	end
	return false
end

return table.freeze(RacingConfig)
