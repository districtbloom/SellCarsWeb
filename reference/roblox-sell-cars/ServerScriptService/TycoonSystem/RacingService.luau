--!strict
-- Server-authoritative, one-race-at-a-time matchmaking for up to eight players.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local RacingConfig = require(ReplicatedStorage.Shared.Config.RacingConfig)
local VehicleNeon = require(ReplicatedStorage.VehicleNeon)
local VehiclePaint = require(ReplicatedStorage.VehiclePaint)
local DataService = require(script.Parent.DataService)
local TycoonService = require(script.Parent.TycoonService)
local PersonalGarageService = require(script.Parent.PersonalGarageService)
local AdminAccess = require(script.Parent.AdminAccess)
local CarVisuals = require(script.Parent.JunkLot.CarVisuals)

type Lobby = {
	id: string,
	host: Player,
	trackId: string,
	laps: number,
	carId: string,
	participants: { [Player]: boolean },
	responses: { [Player]: boolean },
	expiresAt: number,
}

type Gate = {
	position: Vector3,
	cframe: CFrame,
	size: Vector3,
}

type Racer = {
	player: Player,
	car: Model,
	seat: VehicleSeat,
	chassis: BasePart,
	returnCFrame: CFrame?,
	startCFrame: CFrame,
	lastSafeCFrame: CFrame,
	previousPosition: Vector3,
	lastSampleAt: number,
	lastProgressAt: number,
	stallResets: number,
	routeResets: number,
	penaltySeconds: number,
	offRouteSince: number?,
	offRouteWarned: boolean,
	outOfCarSince: number?,
	recoveringUntil: number,
	flippedSince: number?,
	terminalReason: string?,
	nextIndex: number,
	lap: number,
	finishedAt: number?,
	placement: number?,
	dnf: boolean,
	reward: number,
	countdownAnchors: { [BasePart]: boolean },
	seatConnection: RBXScriptConnection?,
	seatRecoveryPending: boolean,
	released: boolean,
}

type Race = {
	id: string,
	trackId: string,
	laps: number,
	carId: string,
	phase: string,
	points: { Vector3 },
	gateCFrames: { CFrame },
	gateSizes: { Vector3 },
	racers: { Racer },
	finishers: { Racer },
	startedAt: number,
	deadline: number,
	finishGraceDeadline: number?,
	safety: { [string]: any },
	folder: Folder,
	lastPositionsAt: number,
	updateErrors: number,
	rewardsEnabled: boolean,
	spectatorGroups: { [BasePart]: string },
	finishCFrame: CFrame,
}

local RacingService = {}
local actionEvent: RemoteEvent
local stateEvent: RemoteEvent
local lobby: Lobby? = nil
local race: Race? = nil
local nextRaceAllowedAt = 0
local lastActionAt: { [Player]: number } = {}
local phoneSessions: { [Player]: { token: string, expiresAt: number } } = {}
local rewardHistory: { [Player]: { lastPaidAt: number, signature: string, signatureAt: number, repeatCount: number } } = {}
local PHONE_SESSION_SECONDS = 600
local generation = 0
local shuffleRandom = Random.new()

local function whole(value: unknown): number
	return if typeof(value) == "number" then math.floor(value :: number) else 0
end

local function medalStats(player: Player): { [string]: number }
	local data = DataService.get(player)
	local stats = if data ~= nil then data.racing else nil
	return {
		first = if stats ~= nil then stats.first else 0,
		second = if stats ~= nil then stats.second else 0,
		third = if stats ~= nil then stats.third else 0,
		finishes = if stats ~= nil then stats.finishes else 0,
	}
end

local function send(player: Player, payload: { [string]: any })
	if player.Parent ~= Players then return end
	local copy = table.clone(payload)
	copy.medals = medalStats(player)
	stateEvent:FireClient(player, copy)
end

local function broadcast(payload: { [string]: any })
	for _, player in Players:GetPlayers() do
		send(player, payload)
	end
end

local function eligibility(player: Player): (boolean, string)
	local data = DataService.get(player)
	if data == nil then
		player:SetAttribute("RacingUnlocked", false)
		return false, "RACING IS LOADING."
	end
	if not data.progression.tutorialComplete then
		player:SetAttribute("RacingUnlocked", false)
		return false, "COMPLETE THE TUTORIAL TO UNLOCK RACING."
	end
	if not data.personalGarage.starterChosen then
		player:SetAttribute("RacingUnlocked", false)
		return false, "CLAIM YOUR FIRST PERSONAL CAR TO UNLOCK RACING."
	end
	if not data.personalGarage.racingUnlocked then
		player:SetAttribute("RacingUnlocked", false)
		return false, "RIDE YOUR FIRST PERSONAL CAR TO UNLOCK RACING."
	end
	player:SetAttribute("RacingUnlocked", true)
	return true, ""
end

local function broadcastEligible(payload: { [string]: any })
	for _, player in Players:GetPlayers() do
		local allowed = eligibility(player)
		if allowed then send(player, payload) end
	end
end

local function broadcastRace(activeRace: Race, payload: { [string]: any })
	for _, racer in activeRace.racers do
		if not racer.released then send(racer.player, payload) end
	end
end

local function eligibleServerCount(): number
	local count = 0
	for _, player in Players:GetPlayers() do
		local allowed = eligibility(player)
		if allowed then count += 1 end
	end
	return count
end

local function configureGhostCollisions()
	pcall(function() PhysicsService:RegisterCollisionGroup("RaceVehicles") end)
	pcall(function() PhysicsService:RegisterCollisionGroup("RaceSpectators") end)
	PhysicsService:CollisionGroupSetCollidable("RaceVehicles", "RaceSpectators", false)
	-- Current race contract: racers are full ghosts to one another; only the road/world remains solid.
	PhysicsService:CollisionGroupSetCollidable("RaceVehicles", "RaceVehicles", false)
	PhysicsService:CollisionGroupSetCollidable("RaceVehicles", "Default", true)
end

local function setRaceVehicleGroup(car: Model)
	for _, descendant in car:GetDescendants() do
		if descendant:IsA("BasePart") then descendant.CollisionGroup = "RaceVehicles" end
	end
end

local function setSpectatorGroup(activeRace: Race, root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") and activeRace.spectatorGroups[descendant] == nil then
			activeRace.spectatorGroups[descendant] = descendant.CollisionGroup
			descendant.CollisionGroup = "RaceSpectators"
		end
	end
end

local function refreshSpectatorGhosts(activeRace: Race)
	-- The shared vehicle runtime can reapply its normal Car group after tagging.
	-- Reassert the race group every refresh so racer/spectator ghosting stays deterministic.
	for _, racer in activeRace.racers do
		if racer.car.Parent ~= nil then setRaceVehicleGroup(racer.car) end
	end
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("RacingActive") ~= true and player.Character ~= nil then
			setSpectatorGroup(activeRace, player.Character)
		end
	end
	for _, car in CollectionService:GetTagged("Car") do
		if car:IsA("Model") and car:GetAttribute("RacingVehicle") ~= true then
			setSpectatorGroup(activeRace, car)
		end
	end
end

local function participantArray(activeLobby: Lobby): { Player }
	local result = {}
	for player in activeLobby.participants do
		local allowed = eligibility(player)
		if player.Parent == Players and allowed then table.insert(result, player) end
	end
	table.sort(result, function(a, b) return a.UserId < b.UserId end)
	return result
end

local function canLobbyStart(activeLobby: Lobby): boolean
	local participants = participantArray(activeLobby)
	return #participants >= RacingConfig.MIN_PLAYERS
		or (#participants == 1 and participants[1] == activeLobby.host and AdminAccess.isDebugAuthorized(activeLobby.host))
end

local function allResponded(activeLobby: Lobby): boolean
	for _, player in Players:GetPlayers() do
		local allowed = eligibility(player)
		if allowed and activeLobby.responses[player] ~= true then return false end
	end
	return true
end

local function participantDtos(activeLobby: Lobby): { { [string]: any } }
	local result = {}
	for _, player in participantArray(activeLobby) do
		table.insert(result, {
			userId = player.UserId,
			name = player.DisplayName,
			username = player.Name,
			host = player == activeLobby.host,
		})
	end
	return result
end

local function lobbyPayload(activeLobby: Lobby, kind: string?): { [string]: any }
	return {
		kind = kind or "lobby",
		id = activeLobby.id,
		hostUserId = activeLobby.host.UserId,
		hostName = activeLobby.host.DisplayName,
		trackId = activeLobby.trackId,
		laps = activeLobby.laps,
		carId = activeLobby.carId,
		expiresAt = activeLobby.expiresAt,
		participants = participantDtos(activeLobby),
		maxPlayers = RacingConfig.MAX_PLAYERS,
		canStart = canLobbyStart(activeLobby) and allResponded(activeLobby),
	}
end

local function publishLobby(kind: string?)
	local activeLobby = lobby
	if activeLobby == nil then return end
	for _, player in Players:GetPlayers() do
		local allowed = eligibility(player)
		if allowed then
			local payload = lobbyPayload(activeLobby, kind)
			payload.joined = activeLobby.participants[player] == true
			payload.isHost = activeLobby.host == player
			send(player, payload)
		end
	end
end

local function reject(player: Player, message: string)
	send(player, { kind = "error", message = message })
end

local function clearLobby(reason: string)
	local activeLobby = lobby
	if activeLobby == nil then return end
	lobby = nil
	broadcastEligible({
		kind = "lobby_closed",
		id = activeLobby.id,
		reason = reason,
	})
end

local function ensureRemotes()
	local folder = ReplicatedStorage:FindFirstChild("RacingRemotes")
	if folder ~= nil and not folder:IsA("Folder") then folder:Destroy(); folder = nil end
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "RacingRemotes"
		folder.Parent = ReplicatedStorage
	end
	local action = folder:FindFirstChild("Action")
	if action ~= nil and not action:IsA("RemoteEvent") then action:Destroy(); action = nil end
	if action == nil then
		action = Instance.new("RemoteEvent")
		action.Name = "Action"
		action.Parent = folder
	end
	local state = folder:FindFirstChild("State")
	if state ~= nil and not state:IsA("RemoteEvent") then state:Destroy(); state = nil end
	if state == nil then
		state = Instance.new("RemoteEvent")
		state.Name = "State"
		state.Parent = folder
	end
	actionEvent = action :: RemoteEvent
	stateEvent = state :: RemoteEvent
end

local function routeFolder(trackId: string): Folder?
	local root = Workspace:FindFirstChild("RacingTracks")
	local track = if root ~= nil then root:FindFirstChild(trackId) else nil
	return if track ~= nil and track:IsA("Folder") then track else nil
end

local function routeGates(trackId: string): { Gate }
	local track = routeFolder(trackId)
	local checkpoints = if track ~= nil then track:FindFirstChild("Checkpoints") else nil
	local gates: { Gate } = {}
	if checkpoints == nil then return gates end
	local parts: { BasePart } = {}
	for _, child in checkpoints:GetChildren() do
		if child:IsA("BasePart") then table.insert(parts, child) end
	end
	table.sort(parts, function(a, b) return a.Name < b.Name end)
	local startPart = track:FindFirstChild("Start")
	for index, child in parts do
		local previous = parts[math.max(1, index - 1)].Position
		local following = parts[math.min(#parts, index + 1)].Position
		local tangent = if index == 1 and startPart ~= nil and startPart:IsA("BasePart")
			then child.Position - startPart.Position
			elseif index == 1 then following - child.Position
			else child.Position - previous
		tangent = Vector3.new(tangent.X, 0, tangent.Z)
		if tangent.Magnitude < 0.01 then
			tangent = Vector3.new(child.CFrame.LookVector.X, 0, child.CFrame.LookVector.Z)
		end
		if tangent.Magnitude < 0.01 then tangent = Vector3.new(0, 0, -1) end
		local gateCFrame = CFrame.lookAt(child.Position, child.Position + tangent.Unit, Vector3.yAxis)
		table.insert(gates, {
			position = child.Position,
			cframe = gateCFrame,
			size = child.Size,
		})
	end
	return gates
end

local function gridCFrames(trackId: string): { CFrame }
	local track = routeFolder(trackId)
	local grid = if track ~= nil then track:FindFirstChild("Grid") else nil
	local result = {}
	if grid == nil then return result end
	local children = grid:GetChildren()
	table.sort(children, function(a, b) return a.Name < b.Name end)
	for _, child in children do
		if child:IsA("BasePart") then table.insert(result, child.CFrame) end
	end
	return result
end

local function rootPart(car: Model): BasePart?
	local chassis = car:FindFirstChild("Chassis", true)
	if chassis ~= nil and chassis:IsA("BasePart") then return chassis end
	if car.PrimaryPart ~= nil then return car.PrimaryPart end
	return car:FindFirstChildWhichIsA("BasePart", true)
end

local function driverSeat(car: Model): VehicleSeat?
	local found = car:FindFirstChild("DriverSeat", true)
	if found ~= nil and found:IsA("VehicleSeat") then return found end
	return car:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function forceReleaseSeat(character: Model, humanoid: Humanoid)
	-- A character can enter matchmaking while still welded to a personal car. Roblox
	-- will ignore VehicleSeat:Sit on the race car until that old SeatWeld is gone.
	humanoid.Sit = false
	-- Clear an exit/jump request before assigning the race seat; leaving Jump true
	-- would immediately eject the Humanoid again after VehicleSeat:Sit.
	humanoid.Jump = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		for _, joint in root:GetJoints() do
			if joint.Name == "SeatWeld" then joint:Destroy() end
		end
	end
end

local function groundCar(car: Model, grid: CFrame, ignoreFolder: Folder)
	local sourcePivot = car:GetPivot()
	local boxCFrame, boxSize = car:GetBoundingBox()
	local pivotToBox = sourcePivot:ToObjectSpace(boxCFrame)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { car, ignoreFolder }
	params.IgnoreWater = false
	local ray = Workspace:Raycast(grid.Position + Vector3.new(0, 80, 0), Vector3.new(0, -160, 0), params)
	local groundY = if ray ~= nil then ray.Position.Y else grid.Position.Y
	local center = Vector3.new(grid.Position.X, groundY + boxSize.Y * 0.5 + 0.12, grid.Position.Z)
	local look = Vector3.new(grid.LookVector.X, 0, grid.LookVector.Z)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) else look = look.Unit end
	local wantedBox = CFrame.lookAt(center, center + look, Vector3.yAxis)
	car:PivotTo(wantedBox * pivotToBox:Inverse())
end

local function spawnRaceCar(player: Player, carId: string, grid: CFrame, index: number, folder: Folder): (Model?, VehicleSeat?, BasePart?)
	local definition = RacingConfig.CARS[carId]
	if definition == nil then return nil, nil, nil end
	local source = ServerStorage:WaitForChild("CarModels"):FindFirstChild(definition.model)
	if source == nil or not source:IsA("Model") then
		warn("[Racing] missing CarModels." .. definition.model)
		return nil, nil, nil
	end
	local clone = source:Clone()
	clone.Name = string.format("Racer_%02d_%s", index, player.Name)
	clone:SetAttribute("TemplateId", definition.model)
	clone:SetAttribute("RacingVehicle", true)
	clone:SetAttribute("RaceOwnerUserId", player.UserId)
	clone:SetAttribute("RaceGridIndex", index)
	clone:SetAttribute("VehicleRuntimeActive", true)
	clone:SetAttribute("DealerDriveLocked", false)
	clone:SetAttribute("owner", player.UserId)
	clone:SetAttribute("customPlate", string.upper(string.sub(player.Name, 1, 8)))
	clone:SetAttribute("RaceSpecVersion", 1)
	if not CollectionService:HasTag(clone, "Car") then CollectionService:AddTag(clone, "Car") end
	if not CollectionService:HasTag(clone, "ManagedVehicle") then CollectionService:AddTag(clone, "ManagedVehicle") end
	CarVisuals.applyCondition(clone, { Body = true, Wheels = true, Engine = true }, true, true, true)
	clone:SetAttribute("BrokenAmount", 0)
	clone:SetAttribute("DealerConditionRepaired", true)
	clone:SetAttribute("PersonalDamageVisualsDisabled", true)
	local palette = RacingConfig.RACER_COLORS[((index - 1) % #RacingConfig.RACER_COLORS) + 1]
	VehiclePaint.setColor(clone, palette.body)
	VehicleNeon.applyFinal(clone, definition.model, palette.neon)
	clone.Parent = folder
	setRaceVehicleGroup(clone)
	groundCar(clone, grid, folder)
	local seat = driverSeat(clone)
	local chassis = rootPart(clone)
	if seat == nil or chassis == nil then
		clone:Destroy()
		return nil, nil, nil
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("VehicleSeat") then
			descendant.Transparency = 1
			descendant.CastShadow = false
			descendant.Disabled = false
			descendant.CanTouch = true
		elseif descendant:IsA("ProximityPrompt") and descendant.Name == "DrivePrompt" then
			-- Race seats are assigned by the server. Never expose a re-entry prompt.
			descendant.Enabled = false
		end
	end
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant == nil then return end
		local driver = Players:GetPlayerFromCharacter(occupant.Parent)
		if driver ~= player then
			occupant.Sit = false
			occupant:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
	return clone, seat, chassis
end

local function currentPosition(racer: Racer): Vector3
	return racer.chassis.Position
end

local function totalProgress(activeRace: Race, racer: Racer): number
	if racer.placement ~= nil then return activeRace.laps * #activeRace.points + 1000 - racer.placement end
	if racer.dnf then return -1000 end
	return (racer.lap - 1) * #activeRace.points + racer.nextIndex - 1
end

local function positionPayload(activeRace: Race): { { [string]: any } }
	local ordered = table.clone(activeRace.racers)
	table.sort(ordered, function(a, b)
		local ap = totalProgress(activeRace, a)
		local bp = totalProgress(activeRace, b)
		if ap ~= bp then return ap > bp end
		local nextPoint = activeRace.points[a.nextIndex]
		local aDistance = if nextPoint ~= nil then (Vector2.new(a.chassis.Position.X, a.chassis.Position.Z) - Vector2.new(nextPoint.X, nextPoint.Z)).Magnitude else 0
		nextPoint = activeRace.points[b.nextIndex]
		local bDistance = if nextPoint ~= nil then (Vector2.new(b.chassis.Position.X, b.chassis.Position.Z) - Vector2.new(nextPoint.X, nextPoint.Z)).Magnitude else 0
		return aDistance < bDistance
	end)
	local result = {}
	for position, racer in ordered do
		table.insert(result, {
			userId = racer.player.UserId,
			name = racer.player.DisplayName,
			position = position,
			lap = racer.lap,
			nextIndex = racer.nextIndex,
			finished = racer.placement ~= nil,
			dnf = racer.dnf,
			terminalReason = racer.terminalReason,
			penaltySeconds = racer.penaltySeconds,
			finishTimeSeconds = if racer.finishedAt ~= nil and activeRace.startedAt > 0 then math.max(0, racer.finishedAt - activeRace.startedAt) else nil,
		})
	end
	return result
end

local function racePayload(activeRace: Race, kind: string): { [string]: any }
	return {
		kind = kind,
		id = activeRace.id,
		trackId = activeRace.trackId,
		laps = activeRace.laps,
		carId = activeRace.carId,
		phase = activeRace.phase,
		startedAt = activeRace.startedAt,
		deadline = if activeRace.finishGraceDeadline ~= nil then math.min(activeRace.deadline, activeRace.finishGraceDeadline) else activeRace.deadline,
		checkpointCount = #activeRace.points,
		points = activeRace.points,
		gateCFrames = activeRace.gateCFrames,
		gateSizes = activeRace.gateSizes,
		positions = positionPayload(activeRace),
		noContest = not activeRace.rewardsEnabled,
	}
end

local function allTerminal(activeRace: Race): boolean
	for _, racer in activeRace.racers do
		if racer.placement == nil and not racer.dnf then return false end
	end
	return true
end

local function lockTerminalVehicle(racer: Racer)
	if racer.car.Parent == nil then return end
	for _, descendant in racer.car:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			descendant.Anchored = true
		end
		if descendant:IsA("VehicleSeat") then descendant.Disabled = true end
	end
	pcall(function() racer.chassis:SetNetworkOwner(nil) end)
end

local function markDnf(activeRace: Race, racer: Racer, reason: string)
	if racer.placement ~= nil or racer.dnf then return end
	racer.dnf = true
	racer.terminalReason = reason
	lockTerminalVehicle(racer)
	send(racer.player, {
		kind = "dnf",
		id = activeRace.id,
		reason = reason,
		reward = 0,
		positions = positionPayload(activeRace),
	})
end

local function planarSegmentDistance(point: Vector3, a: Vector3, b: Vector3): number
	local p = Vector2.new(point.X, point.Z)
	local av = Vector2.new(a.X, a.Z)
	local bv = Vector2.new(b.X, b.Z)
	local segment = bv - av
	local lengthSquared = segment:Dot(segment)
	if lengthSquared <= 0.001 then return (p - av).Magnitude end
	local alpha = math.clamp((p - av):Dot(segment) / lengthSquared, 0, 1)
	return (p - (av + segment * alpha)).Magnitude
end

local function distanceFromRoute(activeRace: Race, position: Vector3): number
	local best = math.huge
	for index = 1, #activeRace.points - 1 do
		best = math.min(best, planarSegmentDistance(position, activeRace.points[index], activeRace.points[index + 1]))
	end
	return best
end

local function resetRacer(activeRace: Race, racer: Racer, reason: string)
	if racer.car.Parent == nil or racer.placement ~= nil or racer.dnf then return end
	local now = Workspace:GetServerTimeNow()
	local recoveryEndsAt = now + RacingConfig.RESET_PENALTY_SECONDS
	racer.recoveringUntil = recoveryEndsAt
	racer.penaltySeconds += RacingConfig.RESET_PENALTY_SECONDS
	racer.lastProgressAt = now
	racer.offRouteSince = nil
	racer.offRouteWarned = false
	racer.outOfCarSince = nil
	racer.flippedSince = nil
	local anchors: { [BasePart]: boolean } = {}
	for _, descendant in racer.car:GetDescendants() do
		if descendant:IsA("BasePart") then
			anchors[descendant] = descendant.Anchored
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			descendant.Anchored = true
		end
	end
	groundCar(racer.car, racer.lastSafeCFrame, activeRace.folder)
	racer.previousPosition = racer.chassis.Position
	racer.lastSampleAt = now
	local character = racer.player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if character ~= nil and humanoid ~= nil and humanoid.Health > 0 and racer.seat.Parent ~= nil then
		racer.seat.Disabled = false
		if racer.seat.Occupant ~= humanoid then
			character:PivotTo(racer.seat.CFrame + Vector3.new(0, 3, 0))
			racer.seat:Sit(humanoid)
		end
	end
	local payload = racePayload(activeRace, "recovery")
	payload.reason = reason
	payload.penaltySeconds = RacingConfig.RESET_PENALTY_SECONDS
	send(racer.player, payload)
	task.delay(RacingConfig.RESET_PENALTY_SECONDS, function()
		if race ~= activeRace or racer.car.Parent == nil or racer.placement ~= nil or racer.dnf then return end
		for part in anchors do
			if part.Parent ~= nil then part.Anchored = false end
		end
		pcall(function() racer.chassis:SetNetworkOwner(racer.player) end)
		local delayedCharacter = racer.player.Character
		local delayedHumanoid = if delayedCharacter ~= nil then delayedCharacter:FindFirstChildOfClass("Humanoid") else nil
		if delayedHumanoid ~= nil and delayedHumanoid.Health > 0 then racer.seat.Disabled = false; racer.seat:Sit(delayedHumanoid) end
		if racer.recoveringUntil == recoveryEndsAt then racer.recoveringUntil = 0 end
	end)
end

local function forceSeatRacer(activeRace: Race, racer: Racer): boolean
	if race ~= activeRace or racer.released or racer.placement ~= nil or racer.dnf
		or racer.car.Parent == nil or racer.seat.Parent == nil
	then
		return false
	end
	local character = racer.player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if character == nil or humanoid == nil or humanoid.Health <= 0 then return false end
	if racer.seat.Occupant == humanoid and humanoid.SeatPart == racer.seat then return true end
	if racer.seatRecoveryPending then return true end

	-- SeatPart can remain stale for a frame after Occupant becomes nil. Reset the
	-- VehicleSeat first, wait for Roblox to remove the old weld, then assign it.
	racer.seatRecoveryPending = true
	racer.seat.Disabled = true
	forceReleaseSeat(character, humanoid)
	RunService.Heartbeat:Wait()
	if race ~= activeRace or racer.released or racer.placement ~= nil or racer.dnf
		or racer.car.Parent == nil or racer.seat.Parent == nil or character.Parent == nil
	then
		racer.seatRecoveryPending = false
		return false
	end
	character:PivotTo(racer.seat.CFrame + Vector3.new(0, 3, 0))
	humanoid.Jump = false
	racer.seat.Disabled = false
	racer.seat:Sit(humanoid)
	RunService.Heartbeat:Wait()
	if racer.seat.Occupant ~= humanoid then
		humanoid.Jump = false
		racer.seat:Sit(humanoid)
	end
	racer.seatRecoveryPending = false
	return true
end

local function bindRaceSeatLock(activeRace: Race, racer: Racer)
	local pending = false
	racer.seatConnection = racer.seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if pending or race ~= activeRace or racer.released or racer.placement ~= nil or racer.dnf then return end
		local character = racer.player.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local occupant = racer.seat.Occupant
		if occupant ~= nil and occupant ~= humanoid then
			occupant.Sit = false
			occupant:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if humanoid ~= nil and humanoid.Health > 0 and occupant ~= humanoid then
			pending = true
			task.defer(function()
				forceSeatRacer(activeRace, racer)
				pending = false
			end)
		end
	end)
end

local function rawProgress(activeRace: Race, racer: Racer): number
	return (racer.lap - 1) * #activeRace.points + racer.nextIndex - 1
end

local function hasMeaningfulOpponent(activeRace: Race, racer: Racer): boolean
	for _, other in activeRace.racers do
		if other ~= racer and (other.placement ~= nil or rawProgress(activeRace, other) >= 1) then return true end
	end
	return false
end

local function rosterSignature(activeRace: Race): string
	local ids = {}
	for _, racer in activeRace.racers do table.insert(ids, racer.player.UserId) end
	table.sort(ids)
	local strings = {}
	for _, id in ids do table.insert(strings, tostring(id)) end
	return table.concat(strings, ":")
end

local function award(racer: Racer, placement: number): number
	local activeRace = race
	if activeRace == nil or not activeRace.rewardsEnabled then return 0 end
	local baseReward = RacingConfig.PODIUM_REWARDS[placement] or 0
	if baseReward <= 0 then return 0 end
	local now = os.clock()
	local signature = rosterSignature(activeRace)
	local history = rewardHistory[racer.player]
	if history ~= nil and now - history.lastPaidAt < RacingConfig.REWARD_COOLDOWN_SECONDS then return 0 end
	local repeatCount = 1
	if history ~= nil and history.signature == signature and now - history.signatureAt <= RacingConfig.REPEAT_ROSTER_WINDOW_SECONDS then
		repeatCount = history.repeatCount + 1
	end
	local repeatMultiplier = RacingConfig.REPEAT_ROSTER_MULTIPLIERS[math.min(repeatCount, #RacingConfig.REPEAT_ROSTER_MULTIPLIERS)] or 0
	rewardHistory[racer.player] = {
		lastPaidAt = if repeatMultiplier > 0 then now else if history ~= nil then history.lastPaidAt else 0,
		signature = signature,
		signatureAt = now,
		repeatCount = repeatCount,
	}
	if repeatMultiplier <= 0 then return 0 end
	local data = DataService.get(racer.player)
	if data == nil then return 0 end
	data.racing.finishes += 1
	if placement == 1 then data.racing.first += 1
	elseif placement == 2 then data.racing.second += 1
	elseif placement == 3 then data.racing.third += 1
	end
	local trackMultiplier = RacingConfig.rewardMultiplier(activeRace.trackId, activeRace.laps)
	local reward = math.max(0, math.floor(baseReward * trackMultiplier * repeatMultiplier + 0.5))
	if reward > 0 then TycoonService.addCash(racer.player, reward) end
	if not DataService.commitCritical(racer.player, "racing_podium") then DataService.save(racer.player) end
	return reward
end

local function finishRacer(activeRace: Race, racer: Racer, crossingTime: number?)
	if racer.placement ~= nil or racer.dnf then return end
	local now = Workspace:GetServerTimeNow()
	racer.finishedAt = crossingTime or now
	table.insert(activeRace.finishers, racer)
	table.sort(activeRace.finishers, function(a, b)
		local aTime = a.finishedAt or math.huge
		local bTime = b.finishedAt or math.huge
		if aTime ~= bTime then return aTime < bTime end
		return a.player.UserId < b.player.UserId
	end)
	for placement, finisher in activeRace.finishers do finisher.placement = placement end
	if not hasMeaningfulOpponent(activeRace, racer) then activeRace.rewardsEnabled = false end
	racer.reward = award(racer, racer.placement or 0)
	racer.terminalReason = "FINISHED"
	lockTerminalVehicle(racer)
	if activeRace.finishGraceDeadline == nil then
		activeRace.finishGraceDeadline = now + activeRace.safety.finishGraceSeconds
	end
	send(racer.player, {
		kind = "finished",
		id = activeRace.id,
		placement = racer.placement,
		reward = racer.reward,
		penaltySeconds = racer.penaltySeconds,
		noContest = not activeRace.rewardsEnabled,
		positions = positionPayload(activeRace),
	})
end

local function releaseRacer(activeRace: Race, racer: Racer, index: number)
	if racer.released then return end
	racer.released = true
	if racer.seatConnection ~= nil then
		racer.seatConnection:Disconnect()
		racer.seatConnection = nil
	end
	racer.player:SetAttribute("RacingActive", nil)
	racer.player:SetAttribute("RacingMatchId", nil)
	local character = racer.player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		-- Clear the racing line before restoring the personal car; RaceSpectators
		-- remains ghosted against live RaceVehicles until the match ends. The character
		-- stands just beyond the arch so the 16-stud car summon lands on open road, not
		-- directly beneath the finish gantry.
		character:PivotTo(activeRace.finishCFrame * CFrame.new(-18 - (index - 1) * 5, 4, -12))
	end
	if racer.car.Parent ~= nil then racer.car:Destroy() end
	if racer.player.Parent == Players then
		task.defer(PersonalGarageService.restoreAfterRace, racer.player)
	end
end

local function cleanRace(activeRace: Race)
	-- Remove all temporary race state, then restore each player's authored personal car.
	for index, racer in activeRace.racers do
		releaseRacer(activeRace, racer, index)
	end
	for part, originalGroup in activeRace.spectatorGroups do
		if part.Parent ~= nil then part.CollisionGroup = originalGroup end
	end
	if activeRace.folder.Parent ~= nil then activeRace.folder:Destroy() end
end
local function endRace(activeRace: Race, reason: string)
	if race ~= activeRace or activeRace.phase == "results" then return end
	activeRace.phase = "results"
	for _, racer in activeRace.racers do
		if racer.placement == nil and not racer.dnf then markDnf(activeRace, racer, reason) end
	end
	local payload = racePayload(activeRace, "results")
	payload.reason = reason
	payload.resultsUntil = Workspace:GetServerTimeNow() + RacingConfig.RESULTS_SECONDS
	broadcastRace(activeRace, payload)
	nextRaceAllowedAt = os.clock() + RacingConfig.SERVER_COOLDOWN_SECONDS
	generation += 1
	local token = generation
	task.delay(RacingConfig.RESULTS_SECONDS, function()
		if race ~= activeRace or generation ~= token then return end
		cleanRace(activeRace)
		broadcastRace(activeRace, { kind = "idle" })
		race = nil
	end)
end

local function startCountdown(activeRace: Race)
	task.spawn(function()
		for remaining = RacingConfig.COUNTDOWN_SECONDS, 1, -1 do
			if race ~= activeRace then return end
			for _, racer in activeRace.racers do
				for part in racer.countdownAnchors do
					if part.Parent ~= nil then part.Anchored = true end
				end
			end
			local payload = racePayload(activeRace, "countdown")
			payload.countdown = remaining
			broadcastRace(activeRace, payload)
			task.wait(1)
		end
		if race ~= activeRace then return end
		if allTerminal(activeRace) then endRace(activeRace, "NO READY RACERS"); return end
		activeRace.phase = "racing"
		activeRace.startedAt = Workspace:GetServerTimeNow()
		activeRace.deadline = activeRace.startedAt + activeRace.safety.hardLimitSeconds
		for _, racer in activeRace.racers do
			racer.lastProgressAt = activeRace.startedAt
			racer.lastSampleAt = activeRace.startedAt
			racer.previousPosition = racer.chassis.Position
			for part in racer.countdownAnchors do
				if part.Parent ~= nil then part.Anchored = false end
			end
			table.clear(racer.countdownAnchors)
			pcall(function() racer.chassis:SetNetworkOwner(racer.player) end)
		end
		broadcastRace(activeRace, racePayload(activeRace, "go"))
	end)
end

local function startRace(activeLobby: Lobby)
	if lobby ~= activeLobby or race ~= nil then return end
	local players = participantArray(activeLobby)
	local readyPlayers: { Player } = {}
	for _, player in players do
		local character = player.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		local blockedByModal = playerGui ~= nil and playerGui:GetAttribute("SellCarsWorkshopModalOpen") == true
		local seat = if humanoid ~= nil then humanoid.SeatPart else nil
		local seatModel = if seat ~= nil then seat:FindFirstAncestorWhichIsA("Model") else nil
		local personalSeat = seatModel == nil or seatModel:GetAttribute("PersonalVehicle") == true or string.sub(seatModel.Name, 1, 9) == "Personal_"
		if humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart") and not blockedByModal and personalSeat then
			table.insert(readyPlayers, player)
		else
			reject(player, "FINISH YOUR CURRENT ACTION BEFORE RACING")
		end
	end
	players = readyPlayers
	for index = #players, 2, -1 do
		local swapIndex = shuffleRandom:NextInteger(1, index)
		players[index], players[swapIndex] = players[swapIndex], players[index]
	end
	local soloDebug = #players == 1 and AdminAccess.isDebugAuthorized(players[1])
	local minimum = if soloDebug then 1 else RacingConfig.MIN_PLAYERS
	if #players < minimum then
		clearLobby("NOT ENOUGH RACERS")
		return
	end
	local gates = routeGates(activeLobby.trackId)
	local points: { Vector3 } = {}
	local gateCFrames: { CFrame } = {}
	local gateSizes: { Vector3 } = {}
	for _, gate in gates do
		table.insert(points, gate.position)
		table.insert(gateCFrames, gate.cframe)
		table.insert(gateSizes, gate.size)
	end
	local grids = gridCFrames(activeLobby.trackId)
	if #points < 2 or #grids < #players then
		clearLobby("TRACK IS NOT READY")
		return
	end
	lobby = nil
	local runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = "ActiveRace_" .. activeLobby.id
	runtimeFolder.Parent = Workspace
	local activeRace: Race = {
		id = activeLobby.id,
		trackId = activeLobby.trackId,
		laps = activeLobby.laps,
		carId = activeLobby.carId,
		phase = "countdown",
		points = points,
		gateCFrames = gateCFrames,
		gateSizes = gateSizes,
		racers = {},
		finishers = {},
		startedAt = 0,
		deadline = 0,
		finishGraceDeadline = nil,
		safety = RacingConfig.safety(activeLobby.trackId, activeLobby.laps),
		folder = runtimeFolder,
		lastPositionsAt = 0,
		updateErrors = 0,
		rewardsEnabled = #players >= RacingConfig.MIN_PLAYERS,
		spectatorGroups = {},
		finishCFrame = CFrame.new(),
	}
	race = activeRace
	local trackFolder = routeFolder(activeRace.trackId)
	local finishPart = if trackFolder ~= nil then trackFolder:FindFirstChild("Finish") else nil
	if finishPart ~= nil and finishPart:IsA("BasePart") then activeRace.finishCFrame = finishPart.CFrame end
	for index, player in players do
		local character = player.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid == nil or root == nil or not root:IsA("BasePart") then continue end
		player:SetAttribute("RacingActive", true)
		player:SetAttribute("RacingMatchId", activeRace.id)
		local car, seat, chassis = spawnRaceCar(player, activeRace.carId, grids[index], index, runtimeFolder)
		if car == nil or seat == nil or chassis == nil then
			player:SetAttribute("RacingActive", nil)
			player:SetAttribute("RacingMatchId", nil)
			reject(player, "RACE CAR COULD NOT SPAWN")
			continue
		end
		local countdownAnchors: { [BasePart]: boolean } = {}
		for _, descendant in car:GetDescendants() do
			if descendant:IsA("BasePart") then
				countdownAnchors[descendant] = descendant.Anchored
				descendant.Anchored = true
			end
		end
		local spawnCFrame = car:GetPivot()
		local racer: Racer = {
			player = player,
			car = car,
			seat = seat,
			chassis = chassis,
			returnCFrame = root.CFrame,
			startCFrame = spawnCFrame,
			lastSafeCFrame = spawnCFrame,
			previousPosition = chassis.Position,
			lastSampleAt = 0,
			lastProgressAt = 0,
			stallResets = 0,
			routeResets = 0,
			penaltySeconds = 0,
			offRouteSince = nil,
			offRouteWarned = false,
			outOfCarSince = nil,
			recoveringUntil = 0,
			flippedSince = nil,
			terminalReason = nil,
			nextIndex = 1,
			lap = 1,
			finishedAt = nil,
			placement = nil,
			dnf = false,
			reward = 0,
			countdownAnchors = countdownAnchors,
			seatConnection = nil,
			seatRecoveryPending = false,
			released = false,
		}
		table.insert(activeRace.racers, racer)
		bindRaceSeatLock(activeRace, racer)
		forceReleaseSeat(character, humanoid)
		task.wait()
		forceSeatRacer(activeRace, racer)
	end
	if #activeRace.racers < minimum then
		endRace(activeRace, "NOT ENOUGH READY RACERS")
		return
	end
	configureGhostCollisions()
	refreshSpectatorGhosts(activeRace)
	startCountdown(activeRace)
end

local function updateRace(activeRace: Race)
	if activeRace.phase == "countdown" then
		-- Enforce the grid continuously, not only once per countdown number. This closes
		-- the exit/re-enter window that could otherwise unanchor a car between ticks.
		for _, racer in activeRace.racers do
			if racer.placement == nil and not racer.dnf and not racer.released then
				for part in racer.countdownAnchors do
					if part.Parent ~= nil then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
						part.Anchored = true
					end
				end
				forceSeatRacer(activeRace, racer)
			end
		end
		return
	elseif activeRace.phase ~= "racing" then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local effectiveDeadline = if activeRace.finishGraceDeadline ~= nil
		then math.min(activeRace.deadline, activeRace.finishGraceDeadline)
		else activeRace.deadline
	if now >= effectiveDeadline then
		endRace(activeRace, if activeRace.finishGraceDeadline ~= nil then "FINISH GRACE EXPIRED" else "TIME LIMIT")
		return
	end
	for _, racer in activeRace.racers do
		if racer.placement ~= nil or racer.dnf then continue end
		if racer.player.Parent ~= Players or racer.car.Parent == nil or racer.player.Character == nil then
			markDnf(activeRace, racer, "LEFT THE SERVER")
			continue
		end
		local humanoid = racer.player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil or humanoid.Health <= 0 then
			markDnf(activeRace, racer, "CHARACTER RESET")
			continue
		end

		if now < racer.recoveringUntil then
			forceSeatRacer(activeRace, racer)
			continue
		end

		local seatedInRaceCar = racer.seat.Parent ~= nil and racer.seat.Occupant == humanoid and humanoid.SeatPart == racer.seat
		if not seatedInRaceCar then
			-- There is no voluntary on-foot race state. Reclaim the assigned seat
			-- immediately; death/reset remains a DNF through the health guard above.
			racer.outOfCarSince = nil
			if not forceSeatRacer(activeRace, racer) then
				markDnf(activeRace, racer, "RACE SEAT LOST")
			end
			continue
		end

		local position = currentPosition(racer)
		local previousPosition = racer.previousPosition
		local sampleDt = math.max(RacingConfig.CHECK_INTERVAL, now - racer.lastSampleAt)
		local sampleDistance = (position - previousPosition).Magnitude
		racer.previousPosition = position
		racer.lastSampleAt = now
		if sampleDistance > RacingConfig.TELEPORT_BASE_ALLOWANCE + RacingConfig.MAX_PLAUSIBLE_SPEED * sampleDt then
			racer.routeResets += 1
			if racer.routeResets <= RacingConfig.MAX_ROUTE_RESETS then resetRacer(activeRace, racer, "IMPOSSIBLE POSITION")
			else markDnf(activeRace, racer, "INVALID MOVEMENT") end
			continue
		end

		local offRoute = position.Y < -20 or distanceFromRoute(activeRace, position) > activeRace.safety.corridorRadius
		if offRoute then
			racer.offRouteSince = racer.offRouteSince or now
			if not racer.offRouteWarned then
				racer.offRouteWarned = true
				send(racer.player, {
					kind = "course_warning",
					id = activeRace.id,
					message = "RETURN TO THE TRACK OR YOUR RACE WILL END",
					seconds = RacingConfig.OFF_ROUTE_GRACE_SECONDS,
				})
			end
			if now - (racer.offRouteSince or now) >= RacingConfig.OFF_ROUTE_GRACE_SECONDS then
				racer.routeResets += 1
				if racer.routeResets <= RacingConfig.MAX_ROUTE_RESETS then resetRacer(activeRace, racer, "RETURNED TO TRACK")
				else markDnf(activeRace, racer, "LEFT THE COURSE") end
				continue
			end
		else
			if racer.offRouteWarned then send(racer.player, { kind = "course_clear", id = activeRace.id }) end
			racer.offRouteSince = nil
			racer.offRouteWarned = false
		end

		local flipped = racer.chassis.CFrame.UpVector.Y < 0.2 and racer.chassis.AssemblyLinearVelocity.Magnitude < 12
		if flipped then
			racer.flippedSince = racer.flippedSince or now
			if now - (racer.flippedSince or now) >= RacingConfig.FLIPPED_GRACE_SECONDS then
				racer.routeResets += 1
				if racer.routeResets <= RacingConfig.MAX_ROUTE_RESETS then resetRacer(activeRace, racer, "CAR RECOVERED")
				else markDnf(activeRace, racer, "CAR DISABLED") end
				continue
			end
		else
			racer.flippedSince = nil
		end

		if now - racer.lastProgressAt >= activeRace.safety.noProgressSeconds then
			racer.stallResets += 1
			if racer.stallResets <= RacingConfig.MAX_STALL_RESETS then resetRacer(activeRace, racer, "NO PROGRESS")
			else markDnf(activeRace, racer, "NO PROGRESS") end
			continue
		end

		local point = activeRace.points[racer.nextIndex]
		local gateCFrame = activeRace.gateCFrames[racer.nextIndex]
		local gateSize = activeRace.gateSizes[racer.nextIndex]
		if point == nil or gateCFrame == nil or gateSize == nil then continue end
		local localPosition = gateCFrame:PointToObjectSpace(position)
		local previousLocalPosition = gateCFrame:PointToObjectSpace(previousPosition)
		local forwardMotion = (position - previousPosition):Dot(gateCFrame.LookVector)
		local withinWidth = math.abs(localPosition.X) <= gateSize.X * 0.5 + RacingConfig.CHECKPOINT_EXTRA_WIDTH
		local withinHeight = math.abs(localPosition.Y) <= gateSize.Y * 0.5 + RacingConfig.CHECKPOINT_EXTRA_HEIGHT
		local withinDepth = math.abs(localPosition.Z) <= gateSize.Z * 0.5 + RacingConfig.CHECKPOINT_EXTRA_DEPTH
		local crossedForward = forwardMotion > 0.02 and previousLocalPosition.Z >= localPosition.Z
		if withinWidth and withinHeight and withinDepth and crossedForward then
			racer.lastProgressAt = now
			racer.lastSafeCFrame = racer.car:GetPivot()
			if racer.nextIndex < #activeRace.points then
				racer.nextIndex += 1
			elseif racer.lap < activeRace.laps then
				racer.lap += 1
				racer.nextIndex = 1
			else
				local crossingTime = now
				local planeTravel = previousLocalPosition.Z - localPosition.Z
				if planeTravel > 0.001 then
					local alpha = math.clamp(previousLocalPosition.Z / planeTravel, 0, 1)
					crossingTime = now - sampleDt * (1 - alpha)
				end
				finishRacer(activeRace, racer, crossingTime)
			end
			if racer.placement == nil then
				local checkpointPayload = racePayload(activeRace, "checkpoint")
				checkpointPayload.lap = racer.lap
				checkpointPayload.laps = activeRace.laps
				checkpointPayload.nextIndex = racer.nextIndex
				checkpointPayload.point = activeRace.points[racer.nextIndex]
				checkpointPayload.gateCFrame = activeRace.gateCFrames[racer.nextIndex]
				checkpointPayload.gateSize = activeRace.gateSizes[racer.nextIndex]
				send(racer.player, checkpointPayload)
			end
		end
	end
	local activeCount = 0
	local meaningfulCount = 0
	for _, racer in activeRace.racers do
		if racer.placement == nil and not racer.dnf then activeCount += 1 end
		if racer.placement ~= nil or rawProgress(activeRace, racer) >= 1 then meaningfulCount += 1 end
	end
	if #activeRace.racers >= RacingConfig.MIN_PLAYERS and activeCount == 1 and #activeRace.finishers == 0 then
		if meaningfulCount < RacingConfig.MIN_PLAYERS then
			activeRace.rewardsEnabled = false
			endRace(activeRace, "NO CONTEST")
			return
		elseif activeRace.finishGraceDeadline == nil then
			activeRace.finishGraceDeadline = now + activeRace.safety.finishGraceSeconds
		end
	end
	if allTerminal(activeRace) then
		endRace(activeRace, "FINISHED")
		return
	end
	if now - activeRace.lastPositionsAt >= 0.5 then
		refreshSpectatorGhosts(activeRace)
		activeRace.lastPositionsAt = now
		broadcastRace(activeRace, racePayload(activeRace, "positions"))
	end
end

local function openPhoneSession(player: Player)
	local session = {
		token = HttpService:GenerateGUID(false),
		expiresAt = os.clock() + PHONE_SESSION_SECONDS,
	}
	phoneSessions[player] = session
	send(player, {
		kind = "phone_session",
		phoneSessionToken = session.token,
	})
end

local function hasValidPhoneSession(player: Player, token: any): boolean
	local session = phoneSessions[player]
	return session ~= nil
		and session.expiresAt >= os.clock()
		and typeof(token) == "string"
		and token == session.token
end

local function requestState(player: Player)
	local allowed, lockedMessage = eligibility(player)
	if not allowed and player:GetAttribute("RacingActive") ~= true then
		send(player, { kind = "locked", message = lockedMessage })
		return
	end
	local activeLobby = lobby
	if activeLobby ~= nil then
		local payload = lobbyPayload(activeLobby)
		payload.joined = activeLobby.participants[player] == true
		payload.isHost = activeLobby.host == player
		send(player, payload)
		return
	end
	local activeRace = race
	if activeRace ~= nil then
		for _, racer in activeRace.racers do
			if racer.player == player and not racer.released then
				send(player, racePayload(activeRace, if activeRace.phase == "results" then "results" else "race_state"))
				return
			end
		end
	end
	send(player, { kind = "idle", cooldown = math.max(0, nextRaceAllowedAt - os.clock()) })
end

local function handleAction(player: Player, payload: any)
	if typeof(payload) ~= "table" or typeof(payload.action) ~= "string" then return end
	local now = os.clock()
	if now - (lastActionAt[player] or 0) < 0.18 then return end
	lastActionAt[player] = now
	local action = payload.action :: string
	if action == "open_phone" then
		openPhoneSession(player)
		-- The phone can have cached a pre-tutorial lock from startup. Re-evaluate the
		-- authoritative profile every time Racing opens so the visible reason advances
		-- from tutorial -> starter car -> first drive without requiring a rejoin.
		requestState(player)
		return
	end
	if action == "request_state" then requestState(player); return end
	if action == "create" or action == "join" then
		local allowed, lockedMessage = eligibility(player)
		if not allowed then reject(player, lockedMessage); return end
	end
	if action == "create" then
		if not hasValidPhoneSession(player, payload.phoneSessionToken) then
			reject(player, "OPEN RACING IN YOUR PHONE TO CREATE A RACE")
			return
		end
		if lobby ~= nil or race ~= nil then reject(player, "A SERVER RACE IS ALREADY ACTIVE"); return end
		if now < nextRaceAllowedAt then reject(player, "RACING IS COOLING DOWN"); return end
		local trackId = tostring(payload.trackId or "")
		local carId = tostring(payload.carId or "")
		local laps = whole(payload.laps)
		if not RacingConfig.validTrack(trackId) or not RacingConfig.validCar(carId)
			or not RacingConfig.validLaps(trackId, laps)
		then
			reject(player, "INVALID RACE SETTINGS")
			return
		end
		local activeLobby: Lobby = {
			id = string.sub(HttpService:GenerateGUID(false), 1, 8),
			host = player,
			trackId = trackId,
			laps = laps,
			carId = carId,
			participants = { [player] = true },
			responses = { [player] = true },
			expiresAt = Workspace:GetServerTimeNow() + RacingConfig.LOBBY_SECONDS,
		}
		lobby = activeLobby
		phoneSessions[player] = nil
		generation += 1
		local token = generation
		publishLobby("invite")
		task.delay(RacingConfig.LOBBY_SECONDS, function()
			if lobby ~= activeLobby or generation ~= token then return end
			startRace(activeLobby)
		end)
		return
	end
	if action == "done" or action == "leave_race" then
		local activeRace = race
		if activeRace == nil or payload.id ~= activeRace.id then
			reject(player, "THIS RACE IS NO LONGER ACTIVE")
			return
		end
		for index, racer in activeRace.racers do
			if racer.player == player then
				if action == "leave_race" and racer.placement == nil and not racer.dnf then
					markDnf(activeRace, racer, "LEFT RACE")
				elseif action == "done" and racer.placement == nil and not racer.dnf then
					reject(player, "RACE IS STILL IN PROGRESS")
					return
				end
				releaseRacer(activeRace, racer, index)
				send(player, { kind = "idle", cooldown = math.max(0, nextRaceAllowedAt - os.clock()) })
				if allTerminal(activeRace) then task.defer(endRace, activeRace, "FINISHED") end
				return
			end
		end
		reject(player, "YOU ARE NOT IN THIS RACE")
		return
	end
	local activeLobby = lobby
	if activeLobby == nil then reject(player, "NO OPEN RACE LOBBY"); return end
	if payload.id ~= activeLobby.id then reject(player, "THIS RACE INVITE EXPIRED"); return end
	if action == "join" then
		activeLobby.responses[player] = true
		if activeLobby.participants[player] ~= true then
			if #participantArray(activeLobby) >= RacingConfig.MAX_PLAYERS then reject(player, "RACE IS FULL"); return end
			activeLobby.participants[player] = true
		end
		publishLobby()
		if #Players:GetPlayers() > 1 and allResponded(activeLobby) then task.defer(startRace, activeLobby) end
	elseif action == "decline" then
		activeLobby.responses[player] = true
		activeLobby.participants[player] = nil
		publishLobby()
		if #Players:GetPlayers() > 1 and allResponded(activeLobby) then task.defer(startRace, activeLobby) end
	elseif action == "leave" then
		if player == activeLobby.host then clearLobby("HOST CANCELED THE RACE")
		else
			activeLobby.responses[player] = true
			activeLobby.participants[player] = nil
			publishLobby()
		end
	elseif action == "cancel" then
		if player == activeLobby.host then clearLobby("HOST CANCELED THE RACE") end
	elseif action == "start" then
		if player ~= activeLobby.host then reject(player, "ONLY THE HOST CAN START"); return end
		if not (canLobbyStart(activeLobby) and allResponded(activeLobby)) then
			reject(player, "WAIT FOR THE LOBBY COUNTDOWN")
			return
		end
		startRace(activeLobby)
	end
end

function RacingService.init()
	ensureRemotes()
	actionEvent.OnServerEvent:Connect(handleAction)
	Players.PlayerAdded:Connect(function(player)
		task.delay(1, function() if player.Parent == Players then requestState(player) end end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastActionAt[player] = nil
		phoneSessions[player] = nil
		rewardHistory[player] = nil
		local activeLobby = lobby
		if activeLobby ~= nil then
			if activeLobby.host == player then clearLobby("HOST LEFT THE SERVER")
			elseif activeLobby.participants[player] then activeLobby.participants[player] = nil; publishLobby() end
		end
		local activeRace = race
		if activeRace ~= nil then
			for _, racer in activeRace.racers do
				if racer.player == player and racer.placement == nil and not racer.dnf then markDnf(activeRace, racer, "LEFT THE SERVER") end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(RacingConfig.CHECK_INTERVAL)
			local activeRace = race
			if activeRace ~= nil then
				local ok, err = pcall(updateRace, activeRace)
				if ok then
					activeRace.updateErrors = 0
				else
					activeRace.updateErrors += 1
					warn("[Racing] " .. tostring(err))
					if activeRace.updateErrors >= 3 then endRace(activeRace, "RACE RECOVERY") end
				end
			end
		end
	end)
	for _, player in Players:GetPlayers() do requestState(player) end
	print("[RacingService] ready")
end

return RacingService
