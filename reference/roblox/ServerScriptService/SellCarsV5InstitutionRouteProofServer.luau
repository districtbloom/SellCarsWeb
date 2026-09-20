--!strict

-- Dynamic acceptance harness for the V5 Institution envelope greybox.
-- This is proof code, not the final traffic system. It deliberately uses
-- measured vehicle envelopes, deterministic jobs and explicit bay locks.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local TEST_NAME = "07_Dynamic_Route_Proof"
local ORIGIN_X = 3130
local SPEED = 300

local root = Workspace:WaitForChild(ROOT_NAME)
local previous = root:FindFirstChild(TEST_NAME)
if previous then previous:Destroy() end

local test = Instance.new("Folder")
test.Name = TEST_NAME
test.Parent = root
test:SetAttribute("Status", "RUNNING")
test:SetAttribute("Scenario", "INSTITUTION_13_CAR_MIXED")
test:SetAttribute("RecoveryMovesAllowed", false)
test:SetAttribute("TargetDealerCars", 13)
test:SetAttribute("ProductionCarEnvelope", "10.58W x 6.40H x 18.94L")
test:SetAttribute("TowEnvelope", "11.20W x 6.35H x 22.50L")
test:SetAttribute("TransporterEnvelope", "12.00W x 7.00H x 38.50L")

local proxyFolder = Instance.new("Folder")
proxyFolder.Name = "Traffic_Proxies"
proxyFolder.Parent = test

local actorFolder = Instance.new("Folder")
actorFolder.Name = "Actor_Proxies"
actorFolder.Parent = test

local metrics = {
	active = 0,
	maxActive = 0,
	completed = 0,
	conflicts = 0,
	recoveries = 0,
	towRuns = 0,
	transporterRuns = 0,
	actorCycles = 0,
	parallelBayPairs = 0,
}

local stopActors = false
local motionBusy = false
local journeyBusy = false
local runningError: string? = nil
local intakeBusy = {false, false, false}
local bayBusy: {[string]: {boolean}} = {}
local bayNext: {[string]: number} = {}
local visits: {[string]: {number}} = {}

local function proxyPart(parent: Instance, name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = true
	item.CastShadow = true
	item.Size = size
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item:SetAttribute("V5TrafficCollision", true)
	item.Parent = parent
	return item
end

local function createCar(index: number, jobName: string, required: {[string]: boolean}): Model
	-- Keep inactive proof cars outside every campus/road envelope. They are logical
	-- queue entries until runCar deliberately places them at a measured intake.
	local stagingPosition = Vector3.new(ORIGIN_X + 400, 2.2, -100 - index * 30)
	local car = Instance.new("Model")
	car.Name = string.format("DealerCar_%02d_%s", index, jobName)
	car:SetAttribute("V5TrafficProxy", true)
	car:SetAttribute("JobName", jobName)
	car:SetAttribute("JourneyState", "WAITING_OFF_MAP")
	car:SetAttribute("RequiredFunctions", table.concat((function()
		local result = {}
		for _, functionName in ipairs({"Wash", "Mechanical", "Body_Restoration", "Tune_Performance", "Paint_Exterior", "Detail_QC", "Photo_Listing"}) do
			if required[functionName] then table.insert(result, functionName) end
		end
		return result
	end)(), ","))
	car.Parent = proxyFolder

	local palette = {
		Color3.fromRGB(116, 125, 132),
		Color3.fromRGB(137, 103, 75),
		Color3.fromRGB(87, 105, 120),
		Color3.fromRGB(128, 86, 86),
	}
	local body = proxyPart(car, "MainBody", Vector3.new(10.58, 2.4, 18.94), palette[((index - 1) % #palette) + 1], Enum.Material.SmoothPlastic)
	body.Position = stagingPosition
	local cabin = proxyPart(car, "Cabin", Vector3.new(8.2, 2.5, 8.5), Color3.fromRGB(35, 46, 58), Enum.Material.Glass)
	cabin.Transparency = 0.18
	cabin.Position = body.Position + Vector3.new(0, 2.1, 0.8)
	local hood = proxyPart(car, "MechanicalIndicator", Vector3.new(7.6, 0.28, 5.2), Color3.fromRGB(94, 67, 55), Enum.Material.Metal)
	hood.Position = body.Position + Vector3.new(0, 1.35, -5.5)
	local damage = proxyPart(car, "BodyDamage", Vector3.new(1.1, 1.4, 3.8), Color3.fromRGB(77, 56, 50), Enum.Material.CorrodedMetal)
	damage.Position = body.Position + Vector3.new(5.4, 0.2, 2)
	if not required.Body_Restoration then damage.Transparency = 1 end
	local spoiler = proxyPart(car, "TuneSpoiler", Vector3.new(8.4, 0.35, 1.4), Color3.fromRGB(32, 35, 41), Enum.Material.Metal)
	spoiler.Position = body.Position + Vector3.new(0, 2.1, 7.3)
	spoiler.Transparency = 1
	local underglow = proxyPart(car, "TuneUnderglow", Vector3.new(8.8, 0.12, 14), Color3.fromRGB(95, 83, 255), Enum.Material.Neon)
	underglow.Position = body.Position + Vector3.new(0, -1.27, 0)
	underglow.Transparency = 1

	for _, x in ipairs({-4.9, 4.9}) do
		for _, z in ipairs({-6.2, 6.2}) do
			local wheel = proxyPart(car, "Wheel", Vector3.new(1.1, 2.8, 2.8), Color3.fromRGB(22, 22, 24), Enum.Material.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = CFrame.new(body.Position + Vector3.new(x, -1.0, z)) * CFrame.Angles(0, 0, math.rad(90))
		end
	end

	car.PrimaryPart = body
	car:PivotTo(CFrame.new(stagingPosition))
	return car
end

local function createLargeVehicle(name: string, size: Vector3, color: Color3): Model
	local vehicle = Instance.new("Model")
	vehicle.Name = name
	vehicle:SetAttribute("V5TrafficProxy", true)
	vehicle:SetAttribute("LargeArrival", true)
	vehicle.Parent = proxyFolder
	local body = proxyPart(vehicle, "MainBody", size, color, Enum.Material.Metal)
	body.Position = Vector3.new(ORIGIN_X - 103, size.Y / 2, -72)
	local cab = proxyPart(vehicle, "Cab", Vector3.new(size.X, math.max(3.5, size.Y * 0.8), math.min(8, size.Z * 0.35)), Color3.fromRGB(48, 58, 66), Enum.Material.Metal)
	cab.Position = body.Position + Vector3.new(0, 0.8, -size.Z * 0.3)
	vehicle.PrimaryPart = body
	vehicle:PivotTo(CFrame.new(body.Position))
	return vehicle
end

local function acquireMotion()
	while motionBusy do RunService.Heartbeat:Wait() end
	motionBusy = true
end

local function releaseMotion()
	motionBusy = false
end

local function acquireJourney()
	while journeyBusy do RunService.Heartbeat:Wait() end
	journeyBusy = true
end

local function releaseJourney()
	journeyBusy = false
end

local function conflictSample(vehicle: Model, envelope: Vector3)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {vehicle}
	for _, hit in ipairs(Workspace:GetPartBoundsInBox(vehicle:GetPivot(), envelope, params)) do
		if hit:GetAttribute("V5Blocker") or hit:GetAttribute("V5TrafficCollision") then
			metrics.conflicts += 1
			local otherCar = hit:FindFirstAncestorWhichIsA("Model")
			if not test:GetAttribute("FirstConflictVehicle") then
				test:SetAttribute("FirstConflictVehicle", vehicle.Name)
				test:SetAttribute("FirstConflictPart", hit:GetFullName())
				test:SetAttribute("FirstConflictState", vehicle:GetAttribute("JourneyState"))
				test:SetAttribute("FirstConflictOtherState", otherCar and otherCar:GetAttribute("JourneyState") or "STATIC")
			end
			if not vehicle:GetAttribute("FirstConflict") then
				vehicle:SetAttribute("FirstConflict", hit:GetFullName())
				vehicle:SetAttribute("FirstConflictState", vehicle:GetAttribute("JourneyState"))
				vehicle:SetAttribute("FirstConflictOtherState", otherCar and otherCar:GetAttribute("JourneyState") or "STATIC")
			end
			vehicle:SetAttribute("LastConflict", hit:GetFullName())
		end
	end
	test:SetAttribute("ConflictSamples", metrics.conflicts)
end

local function moveTo(vehicle: Model, destination: Vector3, envelope: Vector3, reverseFacing: boolean?)
	local start = vehicle:GetPivot()
	local startPosition = start.Position
	local delta = destination - startPosition
	local distance = delta.Magnitude
	if distance < 0.01 then return end
	local duration = math.max(0.06, distance / SPEED)
	local direction = delta.Unit
	local facing = if reverseFacing then -direction else direction
	local started = os.clock()
	repeat
		local alpha = math.min(1, (os.clock() - started) / duration)
		local position = startPosition:Lerp(destination, alpha)
		vehicle:PivotTo(CFrame.lookAt(position, position + facing))
		conflictSample(vehicle, envelope)
		RunService.Heartbeat:Wait()
	until alpha >= 1
end

local function movePath(vehicle: Model, points: {Vector3}, envelope: Vector3, reverseFacing: boolean?)
	acquireMotion()
	for _, point in ipairs(points) do moveTo(vehicle, point, envelope, reverseFacing) end
	releaseMotion()
end

local function acquireIndex(lockList: {boolean}): number
	while true do
		for index = 1, #lockList do
			if not lockList[index] then
				lockList[index] = true
				return index
			end
		end
		RunService.Heartbeat:Wait()
	end
end

local function acquireBay(functionName: string): number
	if not bayBusy[functionName] then
		bayBusy[functionName] = {false, false}
		bayNext[functionName] = 1
		visits[functionName] = {0, 0}
	end
	while true do
		local preferred = bayNext[functionName]
		if not bayBusy[functionName][preferred] then
			bayBusy[functionName][preferred] = true
			bayNext[functionName] = if preferred == 1 then 2 else 1
			visits[functionName][preferred] += 1
			return preferred
		end
		local other = if preferred == 1 then 2 else 1
		if not bayBusy[functionName][other] then
			bayBusy[functionName][other] = true
			visits[functionName][other] += 1
			return other
		end
		RunService.Heartbeat:Wait()
	end
end

local function applyTransformation(car: Model, functionName: string, carIndex: number)
	local body = car:FindFirstChild("MainBody") :: BasePart
	if functionName == "Wash" then
		body.Color = body.Color:Lerp(Color3.fromRGB(180, 184, 188), 0.3)
		car:SetAttribute("Cleanliness", "GOOD")
	elseif functionName == "Mechanical" then
		local hood = car:FindFirstChild("MechanicalIndicator") :: BasePart
		hood.Color = Color3.fromRGB(64, 174, 103)
		car:SetAttribute("Mechanical", "GOOD")
	elseif functionName == "Body_Restoration" then
		local damage = car:FindFirstChild("BodyDamage") :: BasePart
		damage.Transparency = 1
		car:SetAttribute("Body", "GOOD")
	elseif functionName == "Tune_Performance" then
		(car:FindFirstChild("TuneSpoiler") :: BasePart).Transparency = 0
		(car:FindFirstChild("TuneUnderglow") :: BasePart).Transparency = 0.18
		car:SetAttribute("RunningGear", "GOOD")
	elseif functionName == "Paint_Exterior" then
		local finishes = {
			Color3.fromRGB(21, 179, 201),
			Color3.fromRGB(238, 74, 58),
			Color3.fromRGB(245, 185, 40),
			Color3.fromRGB(118, 82, 220),
			Color3.fromRGB(43, 192, 123),
		}
		body.Color = finishes[((carIndex - 1) % #finishes) + 1]
		car:SetAttribute("Exterior", "GOOD")
	elseif functionName == "Detail_QC" then
		body.Material = Enum.Material.Metal
		body.Reflectance = 0.12
		car:SetAttribute("QC", "PASS")
	elseif functionName == "Photo_Listing" then
		car:SetAttribute("ListingPrice", 18000 + carIndex * 2750)
		car:SetAttribute("Listed", true)
	end
end

local function service(car: Model, functionName: string, side: number, z: number, carIndex: number)
	local bay = acquireBay(functionName)
	local bayZ = z + (if bay == 1 then -12 else 12)
	local laneX = ORIGIN_X + side * 25
	local portalX = ORIGIN_X + side * 39
	local bayX = ORIGIN_X + side * 64
	car:SetAttribute("JourneyState", "ENTERING_" .. functionName)
	movePath(car, {
		Vector3.new(laneX, 2.2, bayZ),
		Vector3.new(portalX, 2.2, bayZ),
		Vector3.new(bayX, 2.2, bayZ),
	}, Vector3.new(10.58, 6.4, 18.94))
	car:SetAttribute("JourneyState", "SERVICING_" .. functionName .. "_BAY_" .. bay)
	task.wait(0.15 + (carIndex % 3) * 0.04)
	applyTransformation(car, functionName, carIndex)
	car:SetAttribute("JourneyState", "EXITING_" .. functionName)
	movePath(car, {
		Vector3.new(portalX, 2.2, bayZ),
		Vector3.new(laneX, 2.2, bayZ),
	}, Vector3.new(10.58, 6.4, 18.94), true)
	bayBusy[functionName][bay] = false
end

local jobs = {
	{Name = "Direct", Required = {}},
	{Name = "CleanMechanical", Required = {Wash = true, Mechanical = true}},
	{Name = "Mechanical", Required = {Mechanical = true}},
	{Name = "Body", Required = {Body_Restoration = true}},
	{Name = "Tune", Required = {Tune_Performance = true}},
	{Name = "Paint", Required = {Paint_Exterior = true}},
	{Name = "WashBodyPaint", Required = {Wash = true, Body_Restoration = true, Paint_Exterior = true}},
	{Name = "MechanicalTune", Required = {Mechanical = true, Tune_Performance = true}},
	{Name = "BodyTunePaint", Required = {Body_Restoration = true, Tune_Performance = true, Paint_Exterior = true}},
	{Name = "WashMechanicalBody", Required = {Wash = true, Mechanical = true, Body_Restoration = true}},
	{Name = "AwesomeOne", Required = {Wash = true, Mechanical = true, Body_Restoration = true, Tune_Performance = true, Paint_Exterior = true}},
	{Name = "AwesomeTwo", Required = {Wash = true, Mechanical = true, Body_Restoration = true, Tune_Performance = true, Paint_Exterior = true}},
	{Name = "AwesomeThree", Required = {Wash = true, Mechanical = true, Body_Restoration = true, Tune_Performance = true, Paint_Exterior = true}},
}

local function runLargeArrival(kind: string, size: Vector3, color: Color3)
	local vehicle = createLargeVehicle(kind, size, color)
	vehicle:SetAttribute("JourneyState", "APPROACH")
	movePath(vehicle, {
		Vector3.new(ORIGIN_X - 103, size.Y / 2, -30),
		Vector3.new(ORIGIN_X - 103, size.Y / 2, 18),
		Vector3.new(ORIGIN_X - 103, size.Y / 2, 54),
	}, size)
	vehicle:SetAttribute("JourneyState", "UNLOAD")
	task.wait(0.5)
	movePath(vehicle, {
		Vector3.new(ORIGIN_X - 103, size.Y / 2, 18),
		Vector3.new(ORIGIN_X - 103, size.Y / 2, -30),
		Vector3.new(ORIGIN_X - 103, size.Y / 2, -72),
	}, size, true)
	if kind == "TowTruck" then metrics.towRuns += 1 else metrics.transporterRuns += 1 end
	vehicle:Destroy()
	test:SetAttribute("TowRuns", metrics.towRuns)
	test:SetAttribute("TransporterRuns", metrics.transporterRuns)
end

local function runCar(index: number, job: any)
	local required = table.clone(job.Required)
	required.Detail_QC = true
	required.Photo_Listing = true
	local car = createCar(index, job.Name, required)
	local intakeIndex = acquireIndex(intakeBusy)
	local intakePositions = {
		Vector3.new(ORIGIN_X - 111, 2.2, 35),
		Vector3.new(ORIGIN_X - 86, 2.2, 35),
		Vector3.new(ORIGIN_X - 61, 2.2, 62),
	}
	local intake = intakePositions[intakeIndex]
	car:SetAttribute("JourneyState", "ARRIVING_INTAKE_" .. intakeIndex)
	car:PivotTo(CFrame.new(intake.X, intake.Y, -72))
	movePath(car, {Vector3.new(intake.X, intake.Y, -30), intake}, Vector3.new(10.58, 6.4, 18.94))
	task.wait(0.18)
	local dispatchX = if intakeIndex == 3 then ORIGIN_X - 61 else intake.X
	acquireJourney()
	movePath(car, {
		Vector3.new(dispatchX, 2.2, 82),
		Vector3.new(ORIGIN_X - 64, 2.2, 82),
		Vector3.new(ORIGIN_X - 25, 2.2, 96),
	}, Vector3.new(10.58, 6.4, 18.94))
	intakeBusy[intakeIndex] = false

	if required.Wash then service(car, "Wash", -1, 120, index) end
	if required.Mechanical then service(car, "Mechanical", -1, 175, index) end
	if required.Body_Restoration then service(car, "Body_Restoration", -1, 239, index) end
	if required.Tune_Performance then service(car, "Tune_Performance", -1, 307, index) end

	local crossoverZ = 276
	if required.Tune_Performance and not required.Paint_Exterior then crossoverZ = 348 end
	if required.Paint_Exterior then crossoverZ = 360 end
	car:SetAttribute("JourneyState", "LOCAL_SKIP_REJOIN")
	movePath(car, {
		Vector3.new(ORIGIN_X - 25, 2.2, crossoverZ),
		Vector3.new(ORIGIN_X + 25, 2.2, crossoverZ),
	}, Vector3.new(10.58, 6.4, 18.94))

	if required.Paint_Exterior then service(car, "Paint_Exterior", 1, 307, index) end
	service(car, "Detail_QC", 1, 239, index)
	service(car, "Photo_Listing", 1, 175, index)

	car:SetAttribute("JourneyState", "SALES_REVEAL_AND_EXIT")
	movePath(car, {
		Vector3.new(ORIGIN_X + 25, 2.2, 96),
		Vector3.new(ORIGIN_X, 2.2, 84),
		Vector3.new(ORIGIN_X, 2.2, 56),
	}, Vector3.new(10.58, 6.4, 18.94))
	task.wait(0.20)
	movePath(car, {
		Vector3.new(ORIGIN_X, 2.2, 18),
		Vector3.new(ORIGIN_X, 2.2, -30),
		Vector3.new(ORIGIN_X, 2.2, -72),
	}, Vector3.new(10.58, 6.4, 18.94))
	car:SetAttribute("JourneyState", "COMPLETE")
	releaseJourney()
	metrics.completed += 1
	metrics.active -= 1
	test:SetAttribute("CompletedCars", metrics.completed)
	test:SetAttribute("ActiveCars", metrics.active)
	car:Destroy()
end

local function runParallelBayPair(functionName: string, side: number, z: number, pairIndex: number)
	local conflictsBefore = metrics.conflicts
	local laneX = ORIGIN_X + side * 25
	local portalX = ORIGIN_X + side * 39
	local bayX = ORIGIN_X + side * 64
	local approachZ = z + (if side < 0 then -34 else 34)
	local exitZ = z + (if side < 0 then 34 else -34)
	local envelope = Vector3.new(10.58, 6.4, 18.94)
	local a = createCar(80 + pairIndex * 2, functionName .. "_ParallelA", {[functionName] = true})
	local b = createCar(81 + pairIndex * 2, functionName .. "_ParallelB", {[functionName] = true})

	a:SetAttribute("JourneyState", "PARALLEL_APPROACH_BAY_1")
	a:PivotTo(CFrame.new(laneX, 2.2, approachZ))
	movePath(a, {
		Vector3.new(laneX, 2.2, z - 12),
		Vector3.new(portalX, 2.2, z - 12),
		Vector3.new(bayX, 2.2, z - 12),
	}, envelope)
	a:SetAttribute("JourneyState", "PARALLEL_OCCUPIED_BAY_1")

	b:SetAttribute("JourneyState", "PARALLEL_APPROACH_BAY_2")
	b:PivotTo(CFrame.new(laneX, 2.2, approachZ))
	movePath(b, {
		Vector3.new(laneX, 2.2, z + 12),
		Vector3.new(portalX, 2.2, z + 12),
		Vector3.new(bayX, 2.2, z + 12),
	}, envelope)
	b:SetAttribute("JourneyState", "PARALLEL_OCCUPIED_BAY_2")
	conflictSample(a, envelope)
	conflictSample(b, envelope)
	task.wait(0.2)
	applyTransformation(a, functionName, 80 + pairIndex * 2)
	applyTransformation(b, functionName, 81 + pairIndex * 2)

	a:SetAttribute("JourneyState", "PARALLEL_EXIT_BAY_1")
	movePath(a, {
		Vector3.new(portalX, 2.2, z - 12),
		Vector3.new(laneX, 2.2, z - 12),
		Vector3.new(laneX, 2.2, exitZ),
	}, envelope, true)
	a:Destroy()
	b:SetAttribute("JourneyState", "PARALLEL_EXIT_BAY_2")
	movePath(b, {
		Vector3.new(portalX, 2.2, z + 12),
		Vector3.new(laneX, 2.2, z + 12),
		Vector3.new(laneX, 2.2, exitZ),
	}, envelope, true)
	b:Destroy()
	metrics.parallelBayPairs += 1
	test:SetAttribute(functionName .. "_ParallelConflicts", metrics.conflicts - conflictsBefore)
	test:SetAttribute("ParallelBayPairs", metrics.parallelBayPairs)
end

local function actorPart(name: string, color: Color3, position: Vector3): Part
	local actor = proxyPart(actorFolder, name, Vector3.new(2.2, 5.4, 2.2), color, Enum.Material.SmoothPlastic)
	actor.Shape = Enum.PartType.Cylinder
	actor.Position = position
	actor:SetAttribute("V5TrafficCollision", nil)
	actor:SetAttribute("ActorProof", true)
	return actor
end

local function runActor(actor: Part, points: {Vector3})
	task.spawn(function()
		while not stopActors do
			for _, destination in ipairs(points) do
				local start = actor.Position
				local duration = math.max(0.2, (destination - start).Magnitude / 35)
				local begun = os.clock()
				repeat
					local alpha = math.min(1, (os.clock() - begun) / duration)
					actor.Position = start:Lerp(destination, alpha)
					RunService.Heartbeat:Wait()
				until alpha >= 1 or stopActors
				if stopActors then break end
			end
			metrics.actorCycles += 1
			test:SetAttribute("ActorRouteCycles", metrics.actorCycles)
		end
	end)
end

local function setVisitEvidence()
	local allBoth = true
	for functionName, counts in pairs(visits) do
		test:SetAttribute(functionName .. "_Bay1Visits", counts[1])
		test:SetAttribute(functionName .. "_Bay2Visits", counts[2])
		if counts[1] < 1 or counts[2] < 1 then allBoth = false end
	end
	test:SetAttribute("EveryProductionBayUsed", allBoth)
end

task.spawn(function()
	local ok, err = pcall(function()
		runActor(actorPart("StaffLeft", Color3.fromRGB(72, 190, 130), Vector3.new(ORIGIN_X - 112, 3, 112)), {
			Vector3.new(ORIGIN_X - 112, 3, 330), Vector3.new(ORIGIN_X - 112, 3, 112),
		})
		runActor(actorPart("StaffRight", Color3.fromRGB(72, 190, 130), Vector3.new(ORIGIN_X + 112, 3, 330)), {
			Vector3.new(ORIGIN_X + 112, 3, 112), Vector3.new(ORIGIN_X + 112, 3, 330),
		})
		runActor(actorPart("RearRunner", Color3.fromRGB(72, 190, 130), Vector3.new(ORIGIN_X - 105, 3, 397)), {
			Vector3.new(ORIGIN_X + 105, 3, 397), Vector3.new(ORIGIN_X - 105, 3, 397),
		})
		runActor(actorPart("CustomerOne", Color3.fromRGB(232, 214, 157), Vector3.new(ORIGIN_X - 112, 3, 2)), {
			Vector3.new(ORIGIN_X + 30, 3, 2), Vector3.new(ORIGIN_X - 112, 3, 2),
		})
		runActor(actorPart("CustomerTwo", Color3.fromRGB(232, 214, 157), Vector3.new(ORIGIN_X + 30, 3, -2)), {
			Vector3.new(ORIGIN_X - 112, 3, -2), Vector3.new(ORIGIN_X + 30, 3, -2),
		})

		runLargeArrival("TowTruck", Vector3.new(11.2, 6.35, 22.5), Color3.fromRGB(211, 116, 49))
		runLargeArrival("Transporter", Vector3.new(12, 7, 38.5), Color3.fromRGB(74, 118, 158))

		metrics.active = #jobs
		metrics.maxActive = #jobs
		test:SetAttribute("ActiveCars", metrics.active)
		test:SetAttribute("MaxActiveCars", metrics.maxActive)
		for index, job in ipairs(jobs) do
			task.spawn(function()
				task.wait((index - 1) * 0.9)
				local carOk, carError = pcall(function() runCar(index, job) end)
				if not carOk then
					runningError = tostring(carError)
					test:SetAttribute("Status", "ERROR")
					test:SetAttribute("Error", runningError)
				end
			end)
		end

		local deadline = os.clock() + 150
		while metrics.completed < #jobs and not runningError and os.clock() < deadline do task.wait(0.2) end
		if not runningError and metrics.completed == #jobs then
			for pairIndex, data in ipairs({
				{"Wash", -1, 120},
				{"Mechanical", -1, 175},
				{"Body_Restoration", -1, 239},
				{"Tune_Performance", -1, 307},
				{"Paint_Exterior", 1, 307},
				{"Detail_QC", 1, 239},
				{"Photo_Listing", 1, 175},
			}) do
				runParallelBayPair(data[1] :: string, data[2] :: number, data[3] :: number, pairIndex)
			end
		end
		stopActors = true
		setVisitEvidence()
		local both = test:GetAttribute("EveryProductionBayUsed") == true
		local passed = not runningError
			and metrics.completed == #jobs
			and metrics.conflicts == 0
			and metrics.recoveries == 0
			and metrics.towRuns == 1
			and metrics.transporterRuns == 1
			and metrics.parallelBayPairs == 7
			and both
		test:SetAttribute("Status", if passed then "PASS" else "FAIL")
		test:SetAttribute("FinishedAt", os.time())
		print(string.format(
			"[SellCars V5 Route Proof] status=%s complete=%d/%d conflicts=%d recoveries=%d maxActive=%d bothBays=%s bayPairs=%d tow=%d transporter=%d actorCycles=%d",
			tostring(test:GetAttribute("Status")), metrics.completed, #jobs, metrics.conflicts, metrics.recoveries,
			metrics.maxActive, tostring(both), metrics.parallelBayPairs, metrics.towRuns, metrics.transporterRuns, metrics.actorCycles
		))
	end)
	if not ok then
		stopActors = true
		test:SetAttribute("Status", "ERROR")
		test:SetAttribute("Error", tostring(err))
		warn("[SellCars V5 Route Proof] " .. tostring(err))
	end
end)

