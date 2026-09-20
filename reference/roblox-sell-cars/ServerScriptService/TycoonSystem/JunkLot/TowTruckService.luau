--!strict

-- Purchased tow-truck automation. The authored truck remains the parked prop; each trip uses
-- the lightweight anchored TrafficCars rig so collisions can never fling or accumulate tilt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local LuckConfig = require(ReplicatedStorage.LuckConfig)
local DataService = require(script.Parent.Parent.DataService)
local TycoonService = require(script.Parent.Parent.TycoonService)
local LotSlots = require(script.Parent.LotSlots)
local LotNpc = require(script.Parent.LotNpc)
local CarVisuals = require(script.Parent.CarVisuals)
local RoadTraffic = require(script.Parent.RoadTraffic)
local IncomingSellerQueue = require(script.Parent.IncomingSellerQueue)
local TradeService = require(script.Parent.TradeService)

type Record = TycoonService.TycoonRecord
type QueueItem = IncomingSellerQueue.Item

type HiddenPart = {
	part: BasePart,
	transparency: number,
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
	castShadow: boolean,
}

type ActiveState = {
	record: Record,
	generation: number,
	reservationId: string?,
	truck: Model?,
	cargo: Model?,
	driver: Model?,
	holder: Instance?,
	decorative: Model?,
	hiddenParts: { HiddenPart }?,
	hiddenConnections: { RBXScriptConnection }?,
	home: CFrame?,
	idleFoot: Vector3?,
	idleLook: Vector3?,
	routingV2: boolean,
}

local TowTruckService = {}
local PAD_ID = TycoonConfig.TOW_TRUCK_DRIVER_PAD
local TOW_TRUCK_PAD_ID = "RB_TowTruck"
local FINAL_POSITION_EPSILON = 0.2
local FINAL_ANGLE_EPSILON = math.rad(5)
local CORRECTION_MAX_ATTEMPTS = 2
local CORRECTION_TIMEOUT = 8
local generations: { [Player]: number } = {}
local active: { [Player]: ActiveState } = {}
local delivered: { [Player]: number } = {}
local initialized = false

local function sameRecord(a: Record?, b: Record?): boolean
	return a ~= nil and b ~= nil and a.folder == b.folder
end

local function flatLook(value: Vector3): Vector3
	local flat = Vector3.new(value.X, 0, value.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
end

local function angularError(current: CFrame, target: CFrame): number
	local _, angle = current.Rotation:ToObjectSpace(target.Rotation):ToAxisAngle()
	return math.abs(angle)
end

local function poseWithin(current: CFrame, target: CFrame): boolean
	if (current.Position - target.Position).Magnitude > FINAL_POSITION_EPSILON then
		return false
	end
	return angularError(current, target) <= FINAL_ANGLE_EPSILON
end

local function pointSlice(points: { Vector3 }, first: number, last: number): { Vector3 }
	local result: { Vector3 } = {}
	for index = math.max(1, first), math.min(#points, last) do
		table.insert(result, points[index])
	end
	return result
end

local function towRoutingV2Enabled(state: ActiveState): boolean
	return state.routingV2
end

local function debugFast(): boolean
	return workspace:GetAttribute("TowTruckDebugFast") == true
end

local function duration(normal: number, fast: number): number
	return if debugFast() then fast else normal
end

local function ownsPad(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.pads[PAD_ID] == true
end

local function valid(player: Player, state: ActiveState): boolean
	if player.Parent == nil or generations[player] ~= state.generation or active[player] ~= state then
		return false
	end
	local current = TycoonService.getForPlayer(player)
	return sameRecord(current, state.record) and ownsPad(player)
end

local function waitValid(player: Player, state: ActiveState, seconds: number): boolean
	local deadline = os.clock() + math.max(0, seconds)
	while os.clock() < deadline do
		if not valid(player, state) then
			return false
		end
		task.wait(math.min(0.25, math.max(0.03, deadline - os.clock())))
	end
	return valid(player, state)
end

local function setState(player: Player, state: ActiveState, name: string)
	if active[player] ~= state then
		return
	end
	state.record.folder:SetAttribute("TowTruckState", name)
	state.record.folder:SetAttribute("TowTruckDeliveries", delivered[player] or 0)
	for _, instance in { state.holder, state.decorative, state.truck, state.driver } do
		if instance ~= nil and instance.Parent ~= nil then
			instance:SetAttribute("TowState", name)
			instance:SetAttribute("TowCarsDelivered", delivered[player] or 0)
		end
	end
	if state.driver ~= nil and state.driver.Parent ~= nil then
		state.driver:SetAttribute("StaffJob", name)
	end
end

local function restoreDecorative(state: ActiveState)
	local connections = state.hiddenConnections
	state.hiddenConnections = nil
	if connections ~= nil then
		for _, connection in connections do
			connection:Disconnect()
		end
	end
	local hidden = state.hiddenParts
	state.hiddenParts = nil
	if hidden == nil then
		return
	end
	for _, saved in hidden do
		local part = saved.part
		if part.Parent ~= nil then
			part.Transparency = saved.transparency
			part.CanCollide = saved.canCollide
			part.CanTouch = saved.canTouch
			part.CanQuery = saved.canQuery
			part.CastShadow = saved.castShadow
		end
	end
end

local function guardDecorativeHidden(state: ActiveState)
	local hidden = state.hiddenParts
	if hidden == nil then
		return
	end
	local connections: { RBXScriptConnection } = {}
	state.hiddenConnections = connections
	for _, saved in hidden do
		local part = saved.part
		local function enforce()
			if state.truck ~= nil and part.Parent ~= nil then
				part.Transparency = 1
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.CastShadow = false
			end
		end
		for _, property in { "Transparency", "CanCollide", "CanTouch", "CanQuery", "CastShadow" } do
			table.insert(connections, part:GetPropertyChangedSignal(property):Connect(enforce))
		end
		enforce()
	end
end

local function hideDecorative(model: Model): { HiddenPart }
	local result: { HiddenPart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(result, {
				part = descendant,
				transparency = descendant.Transparency,
				canCollide = descendant.CanCollide,
				canTouch = descendant.CanTouch,
				canQuery = descendant.CanQuery,
				castShadow = descendant.CastShadow,
			})
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
		end
	end
	return result
end

local function setKinematic(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
				descendant.Disabled = true
				if descendant:IsA("VehicleSeat") then
					descendant.MaxSpeed = 0
					descendant.Torque = 0
					descendant.TurnSpeed = 0
				end
			end
			pcall(function()
				descendant.CollisionGroup = "Car"
			end)
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("ClickDetector") then
			descendant:Destroy()
		end
	end
end

local function softenLiftAccent(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") and string.lower(descendant.Name) == "liftaccent" then
			-- This is painted tow hardware, not an emissive lamp. Neon blooms heavily in the
			-- desert lighting and made the lift read as a white light source.
			descendant.Material = Enum.Material.SmoothPlastic
			descendant.Reflectance = math.min(descendant.Reflectance, 0.05)
			for _, light in descendant:GetDescendants() do
				if light:IsA("Light") then
					light.Brightness = math.min(light.Brightness, 0.35)
				end
			end
		end
	end
end

-- The authored truck is purchased one pad before its driver, so its appearance cannot be
-- tied to setupVehicle(). Resolve the pad's configured model roots instead of depending on
-- the decorative truck's Studio nesting. Reapplying this after a claim or pad refresh is
-- intentionally idempotent: every property only moves toward the same subdued ceiling.
local function softenAuthoredTowTruck(record: Record)
	for _, definition in TycoonConfig.PADS do
		if definition.id ~= TOW_TRUCK_PAD_ID then
			continue
		end
		for _, modelName in definition.models do
			local root = record.folder:FindFirstChild(modelName, true)
			if root ~= nil then
				softenLiftAccent(root)
			end
		end
		return
	end
end

local function findAuthored(state: ActiveState): (Instance?, Model?, Model?)
	local holder = state.record.folder:FindFirstChild("RB1_TowTruckDriverModel", true)
	local driver = state.record.folder:FindFirstChild("TowTruckDriverNPC", true)
	local towRoot = state.record.folder:FindFirstChild("RB1_TowTruckModel", true)
	local decorative = towRoot and towRoot:FindFirstChild("TowTruck", true)
	if driver ~= nil and not driver:IsA("Model") then
		driver = nil
	end
	if decorative ~= nil and not decorative:IsA("Model") then
		decorative = nil
	end
	return holder, driver :: Model?, decorative :: Model?
end

local function parkedFrame(runtimeTruck: Model, decorative: Model): CFrame?
	local runtimeBody = runtimeTruck:FindFirstChild("Car_Body", true)
	local authoredBody = decorative:FindFirstChild("Car_Body", true)
	if runtimeBody == nil
		or not runtimeBody:IsA("BasePart")
		or authoredBody == nil
		or not authoredBody:IsA("BasePart")
	then
		return nil
	end
	local bodyFromPivot = runtimeTruck:GetPivot():ToObjectSpace(runtimeBody.CFrame)
	return authoredBody.CFrame * bodyFromPivot:Inverse()
end

local function restoreDriver(state: ActiveState)
	local driver = state.driver
	state.driver = nil
	if driver == nil or driver.Parent == nil then
		return
	end
	local holder = state.holder
	local parent = if holder ~= nil and holder.Parent ~= nil then holder else state.record.folder
	local foot = state.idleFoot or LotNpc.footPosition(driver)
	local look = state.idleLook or flatLook(driver:GetPivot().LookVector)
	LotNpc.unseat(driver, parent, foot, look, "idle")
	driver:SetAttribute("StaffJob", nil)
	driver:SetAttribute("TowState", "Idle")
end

local function cleanupVehicle(state: ActiveState)
	local cargo = state.cargo
	state.cargo = nil
	if cargo ~= nil and cargo.Parent ~= nil then
		cargo:Destroy()
	end
	restoreDriver(state)
	local truck = state.truck
	state.truck = nil
	if truck ~= nil and truck.Parent ~= nil then
		truck:Destroy()
	end
	restoreDecorative(state)
	state.home = nil
	state.decorative = nil
	state.holder = nil
	state.idleFoot = nil
	state.idleLook = nil
end

local function releaseReservation(player: Player, state: ActiveState)
	local reservationId = state.reservationId
	state.reservationId = nil
	if reservationId ~= nil then
		IncomingSellerQueue.releaseTow(player, reservationId)
	end
end

local function cleanup(player: Player, state: ActiveState)
	local reservationId = state.reservationId
	local releaseOk, releaseError = pcall(releaseReservation, player, state)
	if not releaseOk then
		warn(string.format("[TowTruck] cleanup reservation failed user=%d: %s", player.UserId, tostring(releaseError)))
		if reservationId ~= nil then
			pcall(IncomingSellerQueue.releaseTow, player, reservationId)
		end
		state.reservationId = nil
	end
	local cargo = state.cargo
	local truck = state.truck
	local driver = state.driver
	local holder = state.holder
	local idleFoot = state.idleFoot
	local idleLook = state.idleLook
	local vehicleOk, vehicleError = xpcall(function()
		cleanupVehicle(state)
	end, debug.traceback)
	if not vehicleOk then
		warn(string.format("[TowTruck] cleanup vehicle failed user=%d: %s", player.UserId, tostring(vehicleError)))
		-- Continue with independent, non-yielding pieces even if an authored NPC/part was bad.
		pcall(restoreDecorative, state)
		if cargo ~= nil and cargo.Parent ~= nil then pcall(function() cargo:Destroy() end) end
		if truck ~= nil and truck.Parent ~= nil then pcall(function() truck:Destroy() end) end
		if driver ~= nil and driver.Parent ~= nil then
			pcall(function()
				local parent = if holder ~= nil and holder.Parent ~= nil then holder else state.record.folder
				LotNpc.unseat(
					driver,
					parent,
					idleFoot or LotNpc.footPosition(driver),
					idleLook or flatLook(driver:GetPivot().LookVector),
					"idle"
				)
				driver:SetAttribute("StaffJob", nil)
				driver:SetAttribute("TowState", "Idle")
			end)
		end
		state.cargo = nil
		state.truck = nil
		state.driver = nil
	end
	if active[player] == state then
		pcall(function() state.record.folder:SetAttribute("TowTruckState", nil) end)
		active[player] = nil
	end
end

local function setupVehicle(player: Player, state: ActiveState): boolean
	local holder, driver, decorative = findAuthored(state)
	local traffic = ReplicatedStorage:FindFirstChild("TrafficCars")
	local source = traffic and traffic:FindFirstChild("TowTruck")
	if holder == nil or driver == nil or decorative == nil or source == nil or not source:IsA("Model") then
		warn(("[TowTruck] authored setup missing user=%d holder=%s driver=%s decorative=%s source=%s"):format(
			player.UserId,
			tostring(holder ~= nil),
			tostring(driver ~= nil),
			tostring(decorative ~= nil),
			tostring(source ~= nil)
		))
		return false
	end
	local truck = source:Clone()
	truck.Name = "TowTruckRuntime"
	setKinematic(truck)
	softenLiftAccent(truck)
	softenLiftAccent(decorative)
	local home = parkedFrame(truck, decorative)
	if home == nil then
		truck:Destroy()
		warn(("[TowTruck] could not align parked rig user=%d"):format(player.UserId))
		return false
	end
	truck:PivotTo(home)
	truck:SetAttribute("TowAutomation", true)
	truck:SetAttribute("OwnerUserId", player.UserId)
	state.holder = holder
	state.driver = driver
	state.decorative = decorative
	state.truck = truck
	state.home = home
	state.idleFoot = LotNpc.footPosition(driver)
	state.idleLook = flatLook(driver:GetPivot().LookVector)
	state.hiddenParts = hideDecorative(decorative)
	guardDecorativeHidden(state)
	-- The runtime enters Workspace only after the authored prop is fully hidden. Parenting
	-- it first exposed both trucks for one replicated frame at the parking spot.
	truck.Parent = LotSlots.carFolder(state.record)

	LotNpc.seat(driver, truck, CarVisuals.driverSeat(truck))
	setState(player, state, "Boarding")
	return true
end

local function driveOut(player: Player, state: ActiveState): boolean
	local truck = state.truck
	if truck == nil or truck.Parent == nil then
		return false
	end
	local speed = TycoonConfig.TOW_DRIVE_SPEED
	local stillValid = function(): boolean
		return valid(player, state) and truck.Parent ~= nil
	end
	setState(player, state, "Departing")
	if not towRoutingV2Enabled(state) then
		-- V1 deliberately remains byte-for-byte equivalent at the behavioural seam: the
		-- generic lot departure backs out first, then joins its normal forward road leg.
		local plan = RoadTraffic.departurePlan(state.record, truck:GetPivot())
		if #plan.reverseOut >= 2 and not RoadTraffic.drive(truck, plan.reverseOut, math.min(speed, 12), stillValid, {
			steer = true,
			reverse = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
		if #plan.forward >= 2 and not RoadTraffic.drive(truck, plan.forward, speed, stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
		return true
	end

	local plan = RoadTraffic.forwardDeparturePlan(state.record, truck:GetPivot())
	if #plan.forward >= 2 then
		-- The authored truck faces the driveway already. Roll across the dealership apron
		-- deliberately, then use normal road speed once clear of the building.
		if plan.slowForwardUntil == nil then
			warn(("[TowTruck] departure plan missing geometric slowdown seam user=%d"):format(player.UserId))
			return false
		end
		local approachEnd = math.clamp(plan.slowForwardUntil, 2, #plan.forward)
		local approach = pointSlice(plan.forward, 1, approachEnd)
		local road = pointSlice(plan.forward, approachEnd, #plan.forward)
		if #approach >= 2 and not RoadTraffic.drive(truck, approach, math.min(speed, 18), stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
		if #road >= 2 and not RoadTraffic.drive(truck, road, speed, stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
	end
	return true
end

local function makeItem(player: Player): QueueItem?
	local data = DataService.get(player)
	if data == nil then
		return nil
	end
	-- World sellers, phone offers and Tow recovery all consume the same server-authoritative
	-- arrival pool. Tow owns no cyclic index or private weighting rules.
	local template = DealerCarConfig.selectArrival(data.pads, data.luck)
	local odds = DealerCarConfig.arrivalOdds(template.id, data.pads, data.luck)
	local rarity = DealerCarConfig.rarityTier(odds.oneInN)
	local variant = LuckConfig.rollIncomingVariant(rarity.id, data.luck)
	local missingWheels = { "WheelFL", "WheelFR" }
	if math.random() < 0.4 then
		table.insert(missingWheels, "WheelRL")
	end
	return {
		queueId = HttpService:GenerateGUID(false),
		templateId = template.id,
		-- This is distressed inventory, not a paid towing service. The discounted acquisition
		-- leaves room for the deliberately expensive wheel/engine restoration.
		ask = math.max(1, math.floor(
			DealerCarConfig.askingPrice(template) * variant.askMultiplier * 0.65
		)),
		sellerId = "TowTruckTony",
		source = "tow",
		paintHue = variant.paintHue,
		bodyKit = variant.bodyKit,
		neonColorId = variant.neonColorId,
		dirty = true,
		oilLeak = true,
		wheelsPresent = false,
		missingWheels = missingWheels,
		towStock = true,
	}
end

local function cargoMount(truck: Model, cargo: Model): CFrame
	local rawTruckLength = truck:GetAttribute("Length")
	local truckLength = if typeof(rawTruckLength) == "number" then rawTruckLength :: number else truck:GetExtentsSize().Z
	local rawCargoLength = cargo:GetAttribute("Length")
	local cargoLength = if typeof(rawCargoLength) == "number" then rawCargoLength :: number else cargo:GetExtentsSize().Z
	local behind = math.max(10, truckLength * 0.52 + cargoLength * 0.38)
	-- TrafficCars face local -Z. Positive X pitch raises that front axle onto the
	-- tow lift while leaving the rear axle closest to the road.
	return CFrame.new(0, 1.15, behind) * CFrame.Angles(math.rad(8), 0, 0)
end

local function truckTargetForDelivery(delivery: CFrame, mount: CFrame): CFrame
	-- The hook intentionally pitches the recovered car. Do not pitch the whole truck by the
	-- inverse mount at Q: keep the truck upright, preserve the derived yaw, and solve its
	-- translation so the mounted cargo centre still reaches the exact delivery position.
	local rawRotation = delivery.Rotation * mount.Rotation:Inverse()
	local uprightRotation = CFrame.lookAt(Vector3.zero, flatLook(rawRotation.LookVector)).Rotation
	local position = delivery.Position - uprightRotation:VectorToWorldSpace(mount.Position)
	return CFrame.new(position) * uprightRotation
end

local function arrivalStart(points: { Vector3 }, targetRotation: CFrame): CFrame
	if #points < 2 then
		return CFrame.new(points[1] or Vector3.zero) * targetRotation.Rotation
	end
	local direction = flatLook(points[2] - points[1])
	return CFrame.lookAt(points[1], points[1] + direction)
end

local function returnWithCargo(
	player: Player,
	state: ActiveState,
	item: QueueItem,
	reservationId: string
): boolean
	local truck = state.truck
	if truck == nil or truck.Parent == nil then
		return false
	end
	local cargo = IncomingSellerQueue.prepareTowCargo(player, state.record, item, reservationId)
	if cargo == nil then
		return false
	end
	state.cargo = cargo
	cargo.Parent = truck
	cargo:PivotTo(truck:GetPivot() * cargoMount(truck, cargo))
	cargo:SetAttribute("TowCargoMounted", true)
	local mount = truck:GetPivot():ToObjectSpace(cargo:GetPivot())

	local delivery = IncomingSellerQueue.towDeliveryFrame(player, state.record, reservationId, cargo)
	if delivery == nil then
		return false
	end
	local routingV2 = towRoutingV2Enabled(state)
	local truckTarget = RoadTraffic.groundTowFrame(truck, truckTargetForDelivery(delivery, mount))
	local points: { Vector3 }
	local approachStart = 1
	if routingV2 then
		points, approachStart = RoadTraffic.towArrivalPoints(
			state.record,
			truckTarget,
			TycoonConfig.TOW_RETURN_ROAD_STEPS
		)
	else
		points = RoadTraffic.arrivalPoints(state.record, truckTarget)
	end
	if #points < 2 then
		return false
	end

	truck:PivotTo(RoadTraffic.groundTowFrame(truck, arrivalStart(points, truckTarget)))
	truck.Parent = LotSlots.carFolder(state.record)
	setState(player, state, "ReturningWithCar")
	local stillValid = function(): boolean
		return valid(player, state)
			and truck.Parent ~= nil
			and cargo.Parent == truck
			and state.reservationId == reservationId
	end
	if routingV2 then
		-- Keep the longer offsite road phase brisk, then slow down before entering Q.
		local roadEnd = math.clamp(approachStart, 2, #points)
		local roadPoints = pointSlice(points, 1, roadEnd)
		local approachPoints = pointSlice(points, roadEnd, #points)
		if #roadPoints >= 2 and not RoadTraffic.drive(truck, roadPoints, TycoonConfig.TOW_DRIVE_SPEED, stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
		if #approachPoints >= 2 and not RoadTraffic.drive(
			truck,
			approachPoints,
			math.min(TycoonConfig.TOW_DRIVE_SPEED, 18),
			stillValid,
			{
				steer = true,
				turnRate = 10,
				initialLook = truck:GetPivot().LookVector,
			}
		) then
			return false
		end
	elseif not RoadTraffic.drive(truck, points, TycoonConfig.TOW_DRIVE_SPEED, stillValid, {
		steer = true,
		initialLook = truck:GetPivot().LookVector,
	}) then
		return false
	end

	-- Q may have advanced while the road arrival was running. Recalculate the final exact
	-- slot and make one dense curved correction with the car still on the hook.
	local currentDelivery = IncomingSellerQueue.towDeliveryFrame(player, state.record, reservationId, cargo)
	if currentDelivery == nil then
		return false
	end
	mount = truck:GetPivot():ToObjectSpace(cargo:GetPivot())
	truckTarget = RoadTraffic.groundTowFrame(truck, truckTargetForDelivery(currentDelivery, mount))
	local correctionAttempt = 0
	local correctionDeadline = os.clock() + CORRECTION_TIMEOUT
	while not poseWithin(truck:GetPivot(), truckTarget)
		and correctionAttempt < CORRECTION_MAX_ATTEMPTS
		and os.clock() < correctionDeadline
	do
		correctionAttempt += 1
		local correction = RoadTraffic.towCorrectionPoints(truck:GetPivot(), truckTarget)
		if #correction < 2 then
			warn(("[TowTruck] Q correction cannot align user=%d queue=%s"):format(player.UserId, item.queueId))
			return false
		end
		local correctionValid = function(): boolean
			return stillValid() and os.clock() < correctionDeadline
		end
		if not RoadTraffic.drive(truck, correction, 10, correctionValid, {
			steer = true,
			turnRate = 10,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
	end
	if not poseWithin(truck:GetPivot(), truckTarget) then
		local current = truck:GetPivot()
		local angle = math.deg(angularError(current, truckTarget))
		warn(("[TowTruck] Q correction outside epsilon user=%d queue=%s attempts=%d distance=%.3f angle=%.2f"):format(
			player.UserId,
			item.queueId,
			correctionAttempt,
			(current.Position - truckTarget.Position).Magnitude,
			angle
		))
		return false
	end
	-- Only the sub-epsilon remainder is authoritative-snapped. All visible correction travel
	-- and yaw has already been performed by the dense curved plan above.
	truck:PivotTo(truckTarget)
	setState(player, state, "JoiningSellerQueue")

	if not IncomingSellerQueue.enqueueTowDelivery(player, state.record, item, reservationId, cargo) then
		return false
	end
	setState(player, state, "WaitingInSellerQueue")
	state.record.folder:SetAttribute("TowTruckWaitingQueueId", item.queueId)
	-- take() detaches this exact cargo only after the item reaches FIFO head and a W slot is
	-- reserved. Until that point the truck, driver and car remain one visible queue assembly.
	while valid(player, state)
		and truck.Parent ~= nil
		and cargo.Parent == truck
		and cargo:GetAttribute("TowCarrierQueueActive") == true
	do
		task.wait(0.1)
	end
	state.record.folder:SetAttribute("TowTruckWaitingQueueId", nil)
	if not valid(player, state) or truck.Parent == nil or cargo.Parent == truck then
		return false
	end

	state.cargo = nil
	state.reservationId = nil
	delivered[player] = (delivered[player] or 0) + 1
	state.record.folder:SetAttribute("TowTruckDeliveries", delivered[player])
	state.record.folder:SetAttribute("TowTruckLastUnloadedAt", workspace:GetServerTimeNow())
	DataService.save(player)
	TradeService.noteTowDelivery(player, state.record)
	print(("[TowTruck] stock unloaded user=%d count=%d car=%s ask=%d missing=%d"):format(
		player.UserId,
		delivered[player],
		item.templateId,
		item.ask,
		if item.missingWheels ~= nil then #item.missingWheels else 0
	))
	return true
end

local function driveHome(player: Player, state: ActiveState): boolean
	local truck = state.truck
	local home = state.home
	if truck == nil or truck.Parent == nil or home == nil then
		return false
	end
	setState(player, state, "ReturningHome")
	local stillValid = function(): boolean
		return valid(player, state) and truck.Parent ~= nil
	end
	if not towRoutingV2Enabled(state) then
		local points = { truck:GetPivot().Position, home.Position }
		if not RoadTraffic.drive(truck, points, math.min(18, TycoonConfig.TOW_DRIVE_SPEED), stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
		truck:PivotTo(home)
		return true
	end

	local plan = RoadTraffic.towHomePlan(state.record, truck:GetPivot(), home)
	if #plan.forward >= 2 then
		if not RoadTraffic.drive(truck, plan.forward, math.min(18, TycoonConfig.TOW_DRIVE_SPEED), stillValid, {
			steer = true,
			initialLook = truck:GetPivot().LookVector,
		}) then
			return false
		end
	end
	if #plan.reversePark >= 2 then
		if not RoadTraffic.drive(truck, plan.reversePark, 9, stillValid, {
			steer = true,
			reverse = true,
		}) then
			return false
		end
	end
	truck:PivotTo(home)
	return true
end

local function runTrip(player: Player, state: ActiveState): boolean
	-- A flag change during a fetch must never switch geometry underneath the same truck.
	-- Latch once at the trip boundary; the next trip may adopt a new rollout value.
	state.routingV2 = TycoonConfig.ROUTING_V2_TOW == true
	if not setupVehicle(player, state) then
		return false
	end
	if not waitValid(player, state, duration(0.85, 0.1)) or not driveOut(player, state) then
		return false
	end
	local truck = state.truck
	if truck == nil then
		return false
	end
	setState(player, state, "Fetching")
	truck.Parent = ServerStorage
	local offsite = duration(
		TycoonConfig.TOW_OFFSITE_MIN
			+ math.random() * (TycoonConfig.TOW_OFFSITE_MAX - TycoonConfig.TOW_OFFSITE_MIN),
		2
	)
	if not waitValid(player, state, offsite) then
		return false
	end
	local item = makeItem(player)
	local reservationId = state.reservationId
	if item == nil or reservationId == nil then
		return false
	end
	if not returnWithCargo(player, state, item, reservationId) then
		return false
	end
	return driveHome(player, state)
end

local function run(player: Player, state: ActiveState)
	setState(player, state, "Idle")
	if not waitValid(player, state, duration(TycoonConfig.TOW_FIRST_DISPATCH_DELAY, 1)) then
		cleanup(player, state)
		return
	end
	while valid(player, state) do
		setState(player, state, "ReservingQueue")
		local reservationId = HttpService:GenerateGUID(false)
		while valid(player, state) and not IncomingSellerQueue.reserveTow(player, state.record, reservationId) do
			task.wait(0.5)
		end
		if not valid(player, state) then
			break
		end
		state.reservationId = reservationId
		setState(player, state, "WaitingForLane")
		while valid(player, state)
			and not IncomingSellerQueue.towLaneReady(player, state.record, reservationId)
		do
			task.wait(0.35)
		end
		if not valid(player, state) then
			break
		end

		local success = runTrip(player, state)
		if not success then
			warn(("[TowTruck] trip aborted user=%d state=%s"):format(
				player.UserId,
				tostring(state.record.folder:GetAttribute("TowTruckState"))
			))
			releaseReservation(player, state)
		end
		cleanupVehicle(state)
		if not valid(player, state) then
			break
		end
		setState(player, state, if success then "Cooldown" else "RetryCooldown")
		local cooldown = duration(
			TycoonConfig.TOW_COOLDOWN_MIN
				+ math.random() * (TycoonConfig.TOW_COOLDOWN_MAX - TycoonConfig.TOW_COOLDOWN_MIN),
			if success then 3 else 1
		)
		if not waitValid(player, state, cooldown) then
			break
		end
	end
	cleanup(player, state)
end

local function guardedRun(player: Player, state: ActiveState)
	local ok, message = xpcall(function()
		run(player, state)
	end, debug.traceback)
	if not ok then
		warn(string.format("[TowTruck] automation crashed user=%d: %s", player.UserId, tostring(message)))
	end
	-- run() normally cleans itself up. This idempotent finally also covers exceptions from
	-- route construction, queue delivery, station payout, analytics, or popup listeners so
	-- one bad integration can never retain the exclusive tow reservation for the session.
	local cleanupOk, cleanupError = xpcall(function()
		cleanup(player, state)
	end, debug.traceback)
	if not cleanupOk then
		warn(string.format("[TowTruck] final cleanup failed user=%d: %s", player.UserId, tostring(cleanupError)))
		-- At minimum release the coordinator lease even if an authored model was malformed.
		local releaseOk, releaseError = pcall(releaseReservation, player, state)
		if not releaseOk then
			warn(string.format("[TowTruck] reservation release failed user=%d: %s", player.UserId, tostring(releaseError)))
		end
		if active[player] == state then
			active[player] = nil
		end
	end
end

local function stop(player: Player)
	generations[player] = (generations[player] or 0) + 1
	local state = active[player]
	if state ~= nil then
		cleanup(player, state)
	end
end

local function start(player: Player, record: Record)
	stop(player)
	if not ownsPad(player) then
		return
	end
	generations[player] = (generations[player] or 0) + 1
	local state: ActiveState = {
		record = record,
		generation = generations[player],
		reservationId = nil,
		truck = nil,
		cargo = nil,
		driver = nil,
		holder = nil,
		decorative = nil,
		hiddenParts = nil,
		home = nil,
		idleFoot = nil,
		idleLook = nil,
		routingV2 = false,
	}
	active[player] = state
	task.spawn(guardedRun, player, state)
end

local function startWhenReady(player: Player)
	task.spawn(function()
		local deadline = os.clock() + 15
		while player.Parent ~= nil and os.clock() < deadline do
			local record = TycoonService.getForPlayer(player)
			if record ~= nil and DataService.get(player) ~= nil then
				if ownsPad(player) then
					start(player, record)
				end
				return
			end
			task.wait(0.1)
		end
	end)
end

function TowTruckService.init()
	if initialized then
		return
	end
	initialized = true

	TycoonService.tycoonClaimed.Event:Connect(function(record: Record, player: Player)
		-- PadService may have just restored a purchased authored model during its own claim
		-- refresh. Apply immediately at that lifecycle boundary, before automation is needed.
		softenAuthoredTowTruck(record)
		if player ~= nil then
			startWhenReady(player)
		end
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: Record)
		local toStop: { Player } = {}
		for player, state in active do
			if sameRecord(state.record, record) then
				table.insert(toStop, player)
			end
		end
		for _, player in toStop do
			stop(player)
		end
	end)
	TycoonService.padPurchased.Event:Connect(function(
		record: Record,
		definition: TycoonConfig.PadDefinition,
		player: Player
	)
		if definition.id == TOW_TRUCK_PAD_ID then
			-- PadService.refresh reveals/builds the truck before firing padPurchased, so this
			-- runs on the exact purchase edge even when the driver does not exist yet.
			softenAuthoredTowTruck(record)
		end
		if player ~= nil and definition.id == PAD_ID then
			task.defer(start, player, record)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		stop(player)
		delivered[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		startWhenReady(player)
	end
	-- TowTruckService starts after PadService's initial refresh. Cover already-purchased
	-- trucks (and pre-soften hidden authored copies for future refreshes) without requiring
	-- a driver purchase or a live automation trip.
	for _, record in TycoonService.getAll() do
		softenAuthoredTowTruck(record)
	end
	print("[TowTruck] automation online")
end

return TowTruckService
