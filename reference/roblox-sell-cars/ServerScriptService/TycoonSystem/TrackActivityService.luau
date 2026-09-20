--!strict
-- Server-authoritative, owner-only MainTrack activity for permanent personal cars.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local GameplayEvents = require(script.Parent.GameplayEvents)
local PersonalGarageService = require(script.Parent.PersonalGarageService)
local TycoonService = require(script.Parent.TycoonService)
local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local TrackConfig = require(ReplicatedStorage.Shared.Config.TrackActivityConfig)

type Session = {
	car: Model,
	lap: number,
	routeDirection: number,
	nextIndex: number,
	collectedCount: number,
	windowStart: number,
	positions: { Vector3 },
	collected: { [number]: boolean },
	rewardPerPickup: number,
	totalReward: number,
	gateArmed: boolean,
	paused: boolean,
	firstDrive: boolean,
}

local TrackActivityService = {}
local sessions: { [Player]: Session } = {}
local starting: { [Player]: boolean } = {}
local wasDriving: { [Player]: boolean } = {}
local racingDriveStartedAt: { [Player]: number } = {}
local seatNotice: { [Player]: string } = {}
local approachSide: { [Player]: number } = {}

local stateEvent: RemoteEvent
local finishLine: BasePart?
local authoredRoute: { Vector3 } = {}

local function publish(player: Player, payload: { [string]: any })
	if player.Parent ~= Players then
		return
	end
	if payload.firstDrive == nil then
		local data = DataService.get(player)
		payload.firstDrive = data ~= nil and data.personalGarage.trackIntroCompleted ~= true
	end
	if typeof(payload.kind) == "string" then
		player:SetAttribute("TrackActivityState", payload.kind)
	end
	if typeof(payload.lap) == "number" then
		player:SetAttribute("TrackActivityLap", payload.lap)
	end
	if typeof(payload.nextIndex) == "number" then
		player:SetAttribute("TrackActivityNextIndex", payload.nextIndex)
	end
	if typeof(payload.rewardPerPickup) == "number" then
		player:SetAttribute("TrackActivityRewardPerPickup", payload.rewardPerPickup)
	end
	if typeof(payload.cooldownUntil) == "number" then
		player:SetAttribute("TrackActivityCooldownUntil", payload.cooldownUntil)
	end
	stateEvent:FireClient(player, payload)
end

local function ensureRemote()
	local existing = ReplicatedStorage:FindFirstChild("TrackActivityEvent")
	if existing ~= nil and not existing:IsA("RemoteEvent") then
		existing:Destroy()
		existing = nil
	end
	if existing == nil then
		existing = Instance.new("RemoteEvent")
		existing.Name = "TrackActivityEvent"
		existing.Parent = ReplicatedStorage
	end
	stateEvent = existing :: RemoteEvent
end

local function preparePickupTemplate()
	local existing = ReplicatedStorage:FindFirstChild("TrackCashPickupTemplate")
	if existing ~= nil then
		existing:Destroy()
	end
	local mainTrack = workspace:FindFirstChild("MainTrack")
	local cashPickups = if mainTrack ~= nil then mainTrack:FindFirstChild("CashPickups") else nil
	local authored = if cashPickups ~= nil then cashPickups:FindFirstChild("CashPickup") else nil
	if authored == nil or not authored:IsA("Model") then
		warn("[TrackActivity] Workspace.MainTrack.CashPickups.CashPickup template is missing")
		return
	end

	local template = authored:Clone()
	template.Name = "TrackCashPickupTemplate"
	template.Parent = ReplicatedStorage

	for _, descendant in authored:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
end

local function readTrack(): boolean
	table.clear(authoredRoute)
	local mainTrack = workspace:FindFirstChild("MainTrack")
	local cashPickups = if mainTrack ~= nil then mainTrack:FindFirstChild("CashPickups") else nil
	local finishArch = if mainTrack ~= nil then mainTrack:FindFirstChild("FinishLineArch") else nil
	local finish = if finishArch ~= nil then finishArch:FindFirstChild("FinishLine") else nil
	if cashPickups == nil or finish == nil or not finish:IsA("BasePart") then
		warn("[TrackActivity] MainTrack route or FinishLine is missing")
		return false
	end
	for index = 1, 24 do
		local marker = cashPickups:FindFirstChild(string.format("%02d", index))
		if marker == nil or not marker:IsA("BasePart") then
			warn("[TrackActivity] missing CashPickups marker " .. string.format("%02d", index))
			table.clear(authoredRoute)
			return false
		end
		table.insert(authoredRoute, marker.Position)
	end
	finishLine = finish
	return true
end

local function routeForLap(player: Player, lap: number, direction: number): { Vector3 }
	local result = {}
	local routeCount = #authoredRoute
	for order = 1, routeCount do
		local sourceIndex = if direction >= 0 then order else routeCount - order + 1
		local point = authoredRoute[sourceIndex]
		local previousIndex = if sourceIndex == 1 then routeCount else sourceIndex - 1
		local followingIndex = if sourceIndex == routeCount then 1 else sourceIndex + 1
		if direction < 0 then
			previousIndex, followingIndex = followingIndex, previousIndex
		end
		local previous = authoredRoute[previousIndex]
		local following = authoredRoute[followingIndex]
		local delta = Vector3.new(following.X - previous.X, 0, following.Z - previous.Z)
		local right = Vector3.zero
		if delta.Magnitude > 0.01 then
			local tangent = delta.Unit
			right = Vector3.new(-tangent.Z, 0, tangent.X)
		end
		local slot = ((order * 17 + lap * 11 + player.UserId % 97) % 3) - 1
		result[order] = point + right * (slot * TrackConfig.LATERAL_OFFSET_STUDS)
	end

	local finish = finishLine
	if finish ~= nil and finish.Parent ~= nil and result[1] ~= nil then
		local look = Vector3.new(finish.CFrame.LookVector.X, 0, finish.CFrame.LookVector.Z)
		if look.Magnitude > 0.01 then
			local travel = if direction < 0 then look.Unit else -look.Unit
			local right = Vector3.new(-travel.Z, 0, travel.X)
			local slot = ((1 * 17 + lap * 11 + player.UserId % 97) % 3) - 1
			result[1] = Vector3.new(finish.Position.X, result[1].Y, finish.Position.Z)
				+ travel * TrackConfig.FIRST_PICKUP_DISTANCE_STUDS
				+ right * (slot * TrackConfig.LATERAL_OFFSET_STUDS)
		end
	end
	return result
end

local function activeCarSeat(car: Model): VehicleSeat?
	local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
	return if seat ~= nil and seat:IsA("VehicleSeat") then seat else nil
end

local function ownerDriving(player: Player, car: Model?): boolean
	if car == nil or car.Parent == nil
		or car:GetAttribute("PersonalVehicle") ~= true
		or car:GetAttribute("PersonalVehicleOwnerUserId") ~= player.UserId
	then
		return false
	end
	local seat = activeCarSeat(car)
	local humanoid = if player.Character ~= nil then player.Character:FindFirstChildOfClass("Humanoid") else nil
	return seat ~= nil and humanoid ~= nil and seat.Occupant == humanoid
end

local function carReferencePoint(car: Model): Vector3
	local chassis = car:FindFirstChild("Chassis", true)
	if chassis ~= nil and chassis:IsA("BasePart") then
		return chassis.Position
	end
	local boxCFrame = car:GetBoundingBox()
	return boxCFrame.Position
end

local function nearTrackRoute(car: Model): boolean
	local point = carReferencePoint(car)
	for _, routePoint in authoredRoute do
		local flat = Vector2.new(point.X - routePoint.X, point.Z - routePoint.Z)
		if flat.Magnitude <= 90 then
			return true
		end
	end
	return false
end

local function insideStartGate(car: Model): boolean
	local finish = finishLine
	if finish == nil or finish.Parent == nil then
		return false
	end
	local localPoint = finish.CFrame:PointToObjectSpace(carReferencePoint(car))
	local expansion = TrackConfig.START_GATE_EXPANSION_STUDS
	return math.abs(localPoint.X) <= finish.Size.X * 0.5 + expansion
		and math.abs(localPoint.Y) <= 14
		and math.abs(localPoint.Z) <= finish.Size.Z * 0.5 + expansion
end

local function pointInsideCarFootprint(car: Model, point: Vector3): boolean
	local ok, boxCFrame, boxSize = pcall(function()
		local cframe, size = car:GetBoundingBox()
		return cframe, size
	end)
	if not ok then
		return false
	end
	local cframe = boxCFrame :: CFrame
	local size = boxSize :: Vector3
	local delta = Vector3.new(point.X - cframe.Position.X, 0, point.Z - cframe.Position.Z)
	local forward = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)
	local expansion = TrackConfig.CAR_BOUND_EXPANSION_STUDS
	if forward.Magnitude < 0.01 then
		-- A tipped/vertical car still gets the same generous horizontal pickup radius.
		return delta.Magnitude <= math.max(size.X, size.Z) * 0.5 + expansion
	end
	forward = forward.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)
	return math.abs(delta:Dot(right)) <= size.X * 0.5 + expansion
		and math.abs(delta:Dot(forward)) <= size.Z * 0.5 + expansion
end

local function routeDirectionForStart(car: Model, recordedApproachSide: number?): number
	if recordedApproachSide ~= nil and math.abs(recordedApproachSide) > 0.01 then
		return if recordedApproachSide > 0 then -1 else 1
	end
	local finish = finishLine
	if finish == nil or finish.Parent == nil then
		return -1
	end
	local finishLook = Vector3.new(finish.CFrame.LookVector.X, 0, finish.CFrame.LookVector.Z)
	if finishLook.Magnitude < 0.01 then
		return -1
	end
	finishLook = finishLook.Unit
	local chassis = car:FindFirstChild("Chassis", true)
	if chassis ~= nil and chassis:IsA("BasePart") then
		local velocity = Vector3.new(chassis.AssemblyLinearVelocity.X, 0, chassis.AssemblyLinearVelocity.Z)
		if velocity.Magnitude >= 2 then
			return if velocity.Unit:Dot(finishLook) >= 0 then -1 else 1
		end
	end
	local facing = Vector3.new(car:GetPivot().LookVector.X, 0, car:GetPivot().LookVector.Z)
	if facing.Magnitude >= 0.01 then
		return if facing.Unit:Dot(finishLook) >= 0 then -1 else 1
	end
	return -1
end

local function activePickupIndices(session: Session): { number }
	local result = {}
	for index = math.clamp(session.windowStart, 1, #session.positions), #session.positions do
		if session.collected[index] ~= true then
			table.insert(result, index)
			if #result >= TrackConfig.VISIBLE_PICKUPS then
				break
			end
		end
	end
	return result
end

local function publishWindow(player: Player, session: Session, kind: string?)
	publish(player, {
		kind = kind or "window",
		lap = session.lap,
		laps = TrackConfig.LAPS,
		nextIndex = session.nextIndex,
		pickupCount = #session.positions,
		minimumPickups = TrackConfig.MINIMUM_PICKUPS_TO_FINISH,
		activeIndices = activePickupIndices(session),
		rewardPerPickup = session.rewardPerPickup,
		totalReward = session.totalReward,
	})
end

local function advanceRollingWindow(player: Player, session: Session)
	local startIndex = math.clamp(session.windowStart, 1, #session.positions)
	local endIndex = math.min(#session.positions, startIndex + TrackConfig.ROUTE_LOOKAHEAD_POINTS)
	local carPoint = carReferencePoint(session.car)
	local bestIndex = startIndex
	local bestDistance = math.huge
	for index = startIndex, endIndex do
		local point = session.positions[index]
		local distance = Vector2.new(carPoint.X - point.X, carPoint.Z - point.Z).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			bestIndex = index
		end
	end
	if bestIndex > session.windowStart then
		session.windowStart = bestIndex
		publishWindow(player, session)
	end
end

local function rewardFor(player: Player): (number, number, number)
	local data = DataService.get(player)
	local marketPrice = PersonalGarageService.getActiveCarMarketPrice(player) or TrackConfig.BASE_CAR_PRICE
	local businessMultiplier = if data ~= nil then TycoonConfig.cashMultiplier(data.pads, nil) else 1
	local carFactor = math.clamp(math.sqrt(math.max(1, marketPrice / TrackConfig.BASE_CAR_PRICE)), 1, TrackConfig.MAX_CAR_FACTOR)
	local incomeFactor = math.clamp(1 + math.log(math.max(1, businessMultiplier)) / math.log(10), 1, TrackConfig.MAX_INCOME_FACTOR)
	local raw = TrackConfig.BASE_REWARD * carFactor * incomeFactor
	local step = TrackConfig.REWARD_ROUNDING
	local reward = math.max(TrackConfig.BASE_REWARD, math.floor(raw / step + 0.5) * step)
	return reward, carFactor, incomeFactor
end

local function sendLapStart(player: Player, session: Session, carFactor: number?, incomeFactor: number?)
	publish(player, {
		kind = "lap_start",
		lap = session.lap,
		laps = TrackConfig.LAPS,
		nextIndex = session.nextIndex,
		pickupCount = #session.positions,
		minimumPickups = TrackConfig.MINIMUM_PICKUPS_TO_FINISH,
		rewardPerPickup = session.rewardPerPickup,
		totalReward = session.totalReward,
		positions = table.clone(session.positions),
		activeIndices = activePickupIndices(session),
		routeDirection = session.routeDirection,
		firstDrive = session.firstDrive,
		carFactor = carFactor,
		incomeFactor = incomeFactor,
	})
end

local function beginSession(player: Player, car: Model, recordedApproachSide: number?)
	if starting[player] == true or sessions[player] ~= nil then
		return
	end
	starting[player] = true
	local data = DataService.get(player)
	local now = os.time()
	if data == nil or not ownerDriving(player, car)
		or data.personalGarage.trackCooldownUntil > now
	then
		starting[player] = nil
		return
	end

	-- Reserve this attempt before spawning rewards. Rejoining cannot reset a partial run.
	local previousCooldown = data.personalGarage.trackCooldownUntil
	data.personalGarage.trackCooldownUntil = now + TrackConfig.COOLDOWN_SECONDS
	if not DataService.commitCritical(player, "track_run_start") then
		data.personalGarage.trackCooldownUntil = previousCooldown
		starting[player] = nil
		publish(player, { kind = "error", message = "TRACK COULD NOT START • TRY AGAIN" })
		return
	end

	if player.Parent ~= Players or car.Parent == nil then
		starting[player] = nil
		return
	end
	local reward, carFactor, incomeFactor = rewardFor(player)
	local routeDirection = routeDirectionForStart(car, recordedApproachSide)
	local session: Session = {
		car = car,
		lap = 1,
		routeDirection = routeDirection,
		nextIndex = 1,
		collectedCount = 0,
		windowStart = 1,
		positions = routeForLap(player, 1, routeDirection),
		collected = {},
		rewardPerPickup = reward,
		totalReward = 0,
		gateArmed = false,
		paused = false,
		firstDrive = data.personalGarage.trackIntroCompleted ~= true,
	}
	sessions[player] = session
	starting[player] = nil
	approachSide[player] = nil
	seatNotice[player] = "active"
	GameplayEvents.emit("TrackRunStarted", player, {
		carId = car:GetAttribute("TemplateId"),
		firstDrive = session.firstDrive,
		rewardPerPickup = reward,
		carFactor = carFactor,
		incomeFactor = incomeFactor,
	})
	sendLapStart(player, session, carFactor, incomeFactor)
end

local function collectPickup(player: Player, session: Session, index: number)
	if session.collected[index] == true or session.positions[index] == nil then
		return
	end
	session.collected[index] = true
	session.collectedCount += 1
	TycoonService.addCash(player, session.rewardPerPickup)
	DataService.save(player)
	session.totalReward += session.rewardPerPickup
	session.nextIndex = session.collectedCount + 1
	publish(player, {
		kind = "pickup",
		lap = session.lap,
		laps = TrackConfig.LAPS,
		index = index,
		nextIndex = session.nextIndex,
		collected = index,
		pickupCount = #session.positions,
		minimumPickups = TrackConfig.MINIMUM_PICKUPS_TO_FINISH,
		activeIndices = activePickupIndices(session),
		rewardPerPickup = session.rewardPerPickup,
		totalReward = session.totalReward,
	})
end

local function finishLap(player: Player, session: Session)
	GameplayEvents.emit("TrackLapCompleted", player, {
		lap = session.lap,
		totalReward = session.totalReward,
		rewardPerPickup = session.rewardPerPickup,
	})
	if session.lap < TrackConfig.LAPS then
		publish(player, {
			kind = "lap_complete",
			lap = session.lap,
			laps = TrackConfig.LAPS,
			totalReward = session.totalReward,
		})
		session.lap += 1
		session.nextIndex = 1
		session.collectedCount = 0
		session.windowStart = 1
		session.positions = routeForLap(player, session.lap, session.routeDirection)
		session.collected = {}
		session.gateArmed = false
		sendLapStart(player, session, nil, nil)
		return
	end

	local now = os.time()
	local cooldownUntil = now + TrackConfig.COOLDOWN_SECONDS
	local data = DataService.get(player)
	if data ~= nil then
		data.personalGarage.trackCooldownUntil = cooldownUntil
		-- Completion, not entering or reserving a run, permanently dismisses first-drive.
		data.personalGarage.trackIntroCompleted = true
		if not DataService.commitCritical(player, "track_run_complete") then
			DataService.save(player)
		end
	end
	GameplayEvents.emit("TrackRunCompleted", player, {
		carId = session.car:GetAttribute("TemplateId"),
		firstDrive = session.firstDrive,
		laps = TrackConfig.LAPS,
		pickups = session.collectedCount,
		pickupTarget = #session.positions,
		minimumPickups = TrackConfig.MINIMUM_PICKUPS_TO_FINISH,
		missedPickups = #session.positions - session.collectedCount,
		totalReward = session.totalReward,
		rewardPerPickup = session.rewardPerPickup,
		cooldownUntil = cooldownUntil,
	})
	sessions[player] = nil
	seatNotice[player] = "cooldown"
	publish(player, {
		kind = "complete",
		firstDrive = session.firstDrive,
		lap = TrackConfig.LAPS,
		laps = TrackConfig.LAPS,
		totalReward = session.totalReward,
		cooldownUntil = cooldownUntil,
	})
end

local function cancelSession(player: Player, reason: string)
	local session = sessions[player]
	if session == nil then
		return
	end
	sessions[player] = nil
	seatNotice[player] = nil
	local data = DataService.get(player)
	local cooldownUntil = if data ~= nil then data.personalGarage.trackCooldownUntil else os.time()
	publish(player, {
		kind = "canceled",
		message = reason,
		cooldownUntil = cooldownUntil,
		totalReward = session.totalReward,
	})
end

local function processPlayer(player: Player)
	if player:GetAttribute("RacingActive") == true then
		if sessions[player] ~= nil then
			cancelSession(player, "TRACK RUN ENDED • RACE MATCHMAKING ACTIVE")
		end
		if seatNotice[player] ~= "racing" then
			seatNotice[player] = "racing"
			publish(player, { kind = "hide" })
		end
		wasDriving[player] = false
		return
	end

local car = PersonalGarageService.getActiveCar(player)
	local session = sessions[player]
	if session ~= nil and (car ~= session.car or session.car.Parent == nil) then
		cancelSession(player, "TRACK RUN ENDED • PERSONAL CAR CHANGED")
		session = nil
	end

	local driving = ownerDriving(player, car)
	local droveBefore = wasDriving[player] == true
	wasDriving[player] = driving
	local profile = DataService.get(player)
	if profile ~= nil and profile.personalGarage.racingUnlocked == true then
		player:SetAttribute("RacingUnlocked", true)
		racingDriveStartedAt[player] = nil
	elseif driving and profile ~= nil and profile.progression.tutorialComplete == true and profile.personalGarage.starterChosen == true then
		local startedAt = racingDriveStartedAt[player]
		if startedAt == nil then
			racingDriveStartedAt[player] = os.clock()
		elseif os.clock() - startedAt >= 5 then
			profile.personalGarage.racingUnlocked = true
			player:SetAttribute("RacingUnlocked", true)
			racingDriveStartedAt[player] = nil
			if not DataService.commitCritical(player, "racing_unlocked_first_drive") then DataService.save(player) end
		end
	else
		racingDriveStartedAt[player] = nil
		player:SetAttribute("RacingUnlocked", false)
	end
	if not driving then
		if droveBefore then
			seatNotice[player] = nil
			if session ~= nil then
				session.paused = true
				publish(player, {
					kind = "paused",
					lap = session.lap,
					laps = TrackConfig.LAPS,
					nextIndex = session.nextIndex,
					pickupCount = #session.positions,
					rewardPerPickup = session.rewardPerPickup,
					totalReward = session.totalReward,
				})
			else
				publish(player, { kind = "hide" })
			end
		end
		return
	end

	if session ~= nil then
		if not droveBefore or session.paused then
			session.paused = false
			seatNotice[player] = "active"
			publish(player, {
				kind = "resume",
				lap = session.lap,
				laps = TrackConfig.LAPS,
				nextIndex = session.nextIndex,
				pickupCount = #session.positions,
				rewardPerPickup = session.rewardPerPickup,
				totalReward = session.totalReward,
			})
		end
		local insideGate = insideStartGate(session.car)
		if not insideGate then
			session.gateArmed = true
		end

		advanceRollingWindow(player, session)
		-- Only the rolling window is collectible. Any of its three visible pickups is valid,
		-- and collection remains horizontal-only for the whole personal-car catalog.
		for _, index in activePickupIndices(session) do
			local position = session.positions[index]
			if pointInsideCarFootprint(session.car, position) then
				collectPickup(player, session, index)
				break
			end
		end

		local routeCompleted = session.windowStart >= math.max(1, #session.positions - 2)
		if session.gateArmed and insideGate and routeCompleted then
			if session.collectedCount >= TrackConfig.MINIMUM_PICKUPS_TO_FINISH then
				finishLap(player, session)
			else
				-- The player completed the circuit but missed too much cash. Keep the reserved
				-- run alive and roll the three-pickup window around for another pass.
				session.windowStart = 1
				session.gateArmed = false
				publishWindow(player, session, "minimum_required")
			end
		end
		return
	end

	local data = DataService.get(player)
	if data == nil or car == nil then
		return
	end
	local now = os.time()
	local cooldownUntil = data.personalGarage.trackCooldownUntil
	local desired = if cooldownUntil > now then "cooldown" else if nearTrackRoute(car) then "guide" else "available"
	if seatNotice[player] ~= desired then
		seatNotice[player] = desired
		if desired == "cooldown" then
			publish(player, { kind = "cooldown", cooldownUntil = cooldownUntil })
		elseif desired == "guide" then
			publish(player, {
				kind = "guide",
				laps = TrackConfig.LAPS,
				pickupCount = #authoredRoute,
			})
		else
			publish(player, {
				kind = "available",
				laps = TrackConfig.LAPS,
				pickupCount = #authoredRoute,
			})
		end
	end
	local insideGate = insideStartGate(car)
	if desired == "guide" and not insideGate then
		local finish = finishLine
		if finish ~= nil and finish.Parent ~= nil then
			local localPoint = finish.CFrame:PointToObjectSpace(carReferencePoint(car))
			if math.abs(localPoint.Z) > 0.01 then
				approachSide[player] = if localPoint.Z > 0 then 1 else -1
			end
		end
	end
	if desired == "guide" and insideGate then
		task.spawn(beginSession, player, car, approachSide[player])
	end
end

function TrackActivityService.init()
	ensureRemote()
	preparePickupTemplate()
	if not readTrack() then
		return
	end

	for _, player in Players:GetPlayers() do
		player:SetAttribute("TrackActivityState", "idle")
	end
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("TrackActivityState", "idle")
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
		starting[player] = nil
		wasDriving[player] = nil
		racingDriveStartedAt[player] = nil
		seatNotice[player] = nil
		approachSide[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(TrackConfig.PICKUP_CHECK_INTERVAL)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(processPlayer, player)
				if not ok then
					warn("[TrackActivity] " .. tostring(err))
				end
			end
		end
	end)
end

return TrackActivityService
