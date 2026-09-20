--!strict

-- Checkpoint 2D dynamic proxy traffic harness. Vehicles use the measured
-- 10.58 x 18.94 production envelope and deterministic anchored motion. This
-- proves route/occupancy behaviour; it does not claim real-chassis steering.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ROOT_NAME = "SellCars_Dealership_RouteGreybox_V3"
local ORIGIN = Vector3.new(3000, 0, 0)
local REMOTE_NAME = "SellCarsV3FlowStress"

local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or Instance.new("Folder")
remoteFolder.Name = REMOTE_NAME
remoteFolder.Parent = ReplicatedStorage
local commandEvent = remoteFolder:FindFirstChild("Command") or Instance.new("RemoteEvent")
commandEvent.Name = "Command"
commandEvent.Parent = remoteFolder
local statusEvent = remoteFolder:FindFirstChild("Status") or Instance.new("RemoteEvent")
statusEvent.Name = "Status"
statusEvent.Parent = remoteFolder

local root = workspace:WaitForChild(ROOT_NAME)
local runtime = root:FindFirstChild("12_Dynamic_Flow_Test") or Instance.new("Folder")
runtime.Name = "12_Dynamic_Flow_Test"
runtime.Parent = root
runtime:SetAttribute("TestType", "MEASURED_ANCHORED_PROXY")
runtime:SetAttribute("ProductionEnvelope", "10.58x18.94")
runtime:SetAttribute("RealChassis", false)
runtime:SetAttribute("Limitation", "Steering and suspension remain pending production chassis")

local carsFolder = runtime:FindFirstChild("Cars") or Instance.new("Folder")
carsFolder.Name = "Cars"
carsFolder.Parent = runtime

local state = {
	runToken = 0,
	running = false,
	paused = false,
	speed = 1,
	scenario = "MIXED",
	progression = root:GetAttribute("ProgressionState") or "WORKING",
	active = 0,
	completed = 0,
	spawned = 0,
	maxQueue = 0,
	maxWait = 0,
	bottleneckResource = "NONE",
	bottleneckWait = 0,
	conflicts = 0,
	recoveries = 0,
}

local resources: {[string]: string} = {}
local waiting: {[string]: number} = {}
local seenConflicts: {[string]: boolean} = {}

local function localPosition(x: number, y: number, z: number): Vector3
	return ORIGIN + Vector3.new(x, y, z)
end

local function sendStatus(message: string?)
	root:SetAttribute("ProgressionState", state.progression)
	runtime:SetAttribute("ProgressionState", state.progression)
	runtime:SetAttribute("Scenario", state.scenario)
	runtime:SetAttribute("Running", state.running)
	runtime:SetAttribute("Paused", state.paused)
	runtime:SetAttribute("Speed", state.speed)
	runtime:SetAttribute("ActiveCars", state.active)
	runtime:SetAttribute("CompletedCars", state.completed)
	runtime:SetAttribute("SpawnedCars", state.spawned)
	runtime:SetAttribute("MaximumResourceQueue", state.maxQueue)
	runtime:SetAttribute("MaximumWaitSeconds", math.floor(state.maxWait * 10 + 0.5) / 10)
	runtime:SetAttribute("BottleneckResource", state.bottleneckResource)
	runtime:SetAttribute("BottleneckWaitSeconds", math.floor(state.bottleneckWait * 10 + 0.5) / 10)
	runtime:SetAttribute("ProxyConflicts", state.conflicts)
	runtime:SetAttribute("Recoveries", state.recoveries)
	statusEvent:FireAllClients({
		progression = state.progression,
		scenario = state.scenario,
		running = state.running,
		paused = state.paused,
		speed = state.speed,
		active = state.active,
		completed = state.completed,
		spawned = state.spawned,
		maxQueue = state.maxQueue,
		maxWait = state.maxWait,
		bottleneckResource = state.bottleneckResource,
		bottleneckWait = state.bottleneckWait,
		conflicts = state.conflicts,
		message = message or "",
	})
end

local function waitForPlay(token: number): boolean
	while state.paused and token == state.runToken do task.wait(0.05) end
	return token == state.runToken
end

local function acquire(resource: string?, carId: string, token: number): boolean
	if not resource then return token == state.runToken end
	local start = os.clock()
	while token == state.runToken and resources[resource] and resources[resource] ~= carId do
		waiting[resource] = (waiting[resource] or 0) + 1
		local queue = 0
		for _, count in pairs(waiting) do if count > 0 then queue += 1 end end
		state.maxQueue = math.max(state.maxQueue, queue)
		waiting[resource] = math.max(0, (waiting[resource] or 1) - 1)
		if not waitForPlay(token) then return false end
		task.wait(0.08)
	end
	if token ~= state.runToken then return false end
	resources[resource] = carId
	local waitTime = os.clock() - start
	state.maxWait = math.max(state.maxWait, waitTime)
	if waitTime > state.bottleneckWait then
		state.bottleneckWait = waitTime
		state.bottleneckResource = resource
	end
	return true
end

local function release(resource: string?, carId: string)
	if resource and resources[resource] == carId then resources[resource] = nil end
end

local function newPart(parent: Instance, name: string, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function createCar(id: string, color: Color3, spawnX: number, spawnZ: number): Model
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("RouteState", "SPAWN")
	model:SetAttribute("ProxyEnvelope", "10.58x18.94")
	model.Parent = carsFolder
	local origin = CFrame.new(localPosition(spawnX, 2.2, spawnZ))
	local body = newPart(model, "Body", Vector3.new(10.58, 2.5, 18.94), color, origin)
	model.PrimaryPart = body
	local roof = newPart(model, "Cabin", Vector3.new(8.2, 2.2, 8.5), Color3.fromRGB(45, 55, 63), origin * CFrame.new(0, 2.25, -0.5), Enum.Material.Glass)
	roof.Transparency = 0.18
	for _, info in ipairs({{-5.2,-6.1},{5.2,-6.1},{-5.2,6.1},{5.2,6.1}}) do
		local wheel = newPart(model, "Wheel", Vector3.new(1.2, 2.8, 3.2), Color3.fromRGB(20,20,20), origin * CFrame.new(info[1], -0.8, info[2]), Enum.Material.Rubber)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame *= CFrame.Angles(0,0,math.rad(90))
	end
	local dirt = newPart(model, "Dirt", Vector3.new(10.7, 0.18, 12), Color3.fromRGB(116, 76, 38), origin * CFrame.new(0,1.35,1), Enum.Material.Ground)
	dirt.Transparency = 0.12
	local dent = newPart(model, "DamageMarker", Vector3.new(2.2, 1.2, 3), Color3.fromRGB(95,65,51), origin * CFrame.new(4.6,0.8,-3), Enum.Material.CorrodedMetal)
	local spoiler = newPart(model, "Spoiler", Vector3.new(8, 0.5, 1.4), Color3.fromRGB(30,30,34), origin * CFrame.new(0,2,8.1), Enum.Material.Metal)
	spoiler.Transparency = 1
	local lights = newPart(model, "Headlights", Vector3.new(7.6, 0.7, 0.25), Color3.fromRGB(255,242,180), origin * CFrame.new(0,0.6,-9.55), Enum.Material.Neon)
	lights.Transparency = 1
	return model
end

local function applyTreatment(car: Model, station: string, finalColor: Color3)
	car:SetAttribute("RouteState", station)
	local body = car:FindFirstChild("Body") :: Part?
	local dirt = car:FindFirstChild("Dirt") :: Part?
	local damage = car:FindFirstChild("DamageMarker") :: Part?
	local spoiler = car:FindFirstChild("Spoiler") :: Part?
	local lights = car:FindFirstChild("Headlights") :: Part?
	if station == "BIRTH_CYCLE" then
		if dirt then dirt.Transparency = 1 end
		if damage then damage.Transparency = 1 end
		if body then body.Reflectance = 0.08 end
		if lights then lights.Transparency = 0.28 end
		for _, child in ipairs(car:GetChildren()) do if child.Name == "Wheel" and child:IsA("Part") then child.Color = Color3.fromRGB(30,30,34) end end
	elseif station == "WORKING_REPAIR" then
		if damage then damage.Transparency = 1 end
		for _, child in ipairs(car:GetChildren()) do if child.Name == "Wheel" and child:IsA("Part") then child.Color = Color3.fromRGB(30,30,34) end end
	elseif station == "WORKING_FINISH" then
		if dirt then dirt.Transparency = 1 end
		if body then body.Reflectance = 0.14 end
		if lights then lights.Transparency = 0.16 end
	elseif station == "WAS" and dirt then
		dirt.Transparency = 0.78
	elseif station == "MEC" then
		for _, child in ipairs(car:GetChildren()) do if child.Name == "Wheel" and child:IsA("Part") then child.Color = Color3.fromRGB(30,30,34) end end
	elseif station == "BOD" and damage then
		damage.Transparency = 1
	elseif station == "TUN" and spoiler then
		spoiler.Transparency = 0
	elseif station == "PNT" and body then
		body.Color = finalColor
		body.Material = Enum.Material.SmoothPlastic
	elseif station == "DET" and body then
		body.Reflectance = 0.18
		if dirt then dirt.Transparency = 1 end
	elseif station == "PHO" and lights then
		lights.Transparency = 0
	elseif station == "SAL" then
		local sold = car:FindFirstChild("SoldSign")
		if not sold and body then
			local gui = Instance.new("BillboardGui")
			gui.Name = "SoldSign"
			gui.Size = UDim2.fromOffset(130, 38)
			gui.StudsOffset = Vector3.new(0, 5.2, 0)
			gui.AlwaysOnTop = true
			gui.Parent = body
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1,1)
			label.BackgroundColor3 = Color3.fromRGB(22,26,30)
			label.BackgroundTransparency = 0.15
			label.Text = "SOLD"
			label.TextColor3 = Color3.fromRGB(255,219,86)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Parent = gui
		end
	end
end

type Node = {
	x: number,
	z: number,
	resource: string?,
	dwell: number?,
	station: string?,
}

local function node(x: number, z: number, resource: string?, dwell: number?, station: string?): Node
	return {x=x,z=z,resource=resource,dwell=dwell,station=station}
end

local function fullRoute(lane: number, queueIndex: number?): {Node}
	local dirtyX = lane == 1 and 68 or 44
	local cleanX = lane == 1 and 176 or 196
	local intakeX = dirtyX
	local queueDepth = queueIndex or 1
	local route: {Node} = {}
	for slot = queueDepth, 1, -1 do
		table.insert(route, node(intakeX, -24 - ((slot - 1) * 24), "ROAD_QUEUE_" .. lane .. "_" .. slot))
	end
	local production = {
		node(intakeX,42,"INTAKE_"..(lane == 1 and 3 or 2),2,"INT"), node(intakeX,78,"INTAKE_HOLD_"..(lane == 1 and 3 or 2),1),
		node(dirtyX,109,"WAS_"..lane,3,"WAS"), node(dirtyX,137,"DIRTY_GAP_1",0.5),
		node(dirtyX,166,"MEC_"..lane,4,"MEC"), node(dirtyX,195,"DIRTY_GAP_2",0.5),
		node(dirtyX,224,"BOD_"..lane,4,"BOD"), node(dirtyX,253,"DIRTY_GAP_3",0.5),
		node(dirtyX,284,"TUN_"..lane,3,"TUN"), node(dirtyX,317,"REAR_TRANSFER",0.5),
		node(cleanX,317), node(cleanX,284,"PNT_"..lane,4,"PNT"), node(cleanX,253,"CLEAN_GAP_3",0.5),
		node(cleanX,224,"DET_"..lane,3,"DET"), node(cleanX,195,"CLEAN_GAP_2",0.5),
		node(cleanX,166,"PHO_"..lane,2,"PHO"), node(cleanX,137,"CLEAN_GAP_1",0.5),
		node(148,137), node(148,108), node(146,80,"SALES_DISPLAY",3,"SAL"), node(146,22,"DELIVERY",1), node(146,-26),
	}
	for _, step in ipairs(production) do table.insert(route, step) end
	return route
end

local function skipRoute(): {Node}
	return {
		node(68,-48,"ROAD_QUEUE_1_2"), node(68,-24,"ROAD_QUEUE_1_1"), node(68,42,"INTAKE_3",2,"INT"), node(68,78,"INTAKE_HOLD_3",1),
		node(68,109,"WAS_1",3,"WAS"), node(68,137,"DIRTY_GAP_1",0.5), node(102,137),
		node(102,195,"DIRTY_GAP_2",0.5), node(68,195), node(68,224,"BOD_1",4,"BOD"),
		node(68,253,"DIRTY_GAP_3",0.5), node(102,253), node(102,317,"REAR_TRANSFER",0.5), node(176,317),
		node(176,284,"PNT_1",4,"PNT"), node(176,253,"CLEAN_GAP_3",0.5), node(148,253),
		node(148,108), node(168,80,"SALES_DISPLAY",3,"SAL"), node(168,22,"DELIVERY",1), node(168,-26),
	}
end

local function directResaleRoute(): {Node}
	return {
		node(20,-24), node(20,42,"INTAKE_1",2,"INT"), node(20,12), node(20,-12,"FRONTAGE_EXCHANGE"),
		node(122,-12,"FRONTAGE_EXCHANGE"), node(122,22,"SALES_DISPLAY",3,"SAL"), node(168,22,"DELIVERY",1), node(168,-26),
	}
end

local function birthRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth = queueIndex or 1
	for slot = depth, 1, -1 do
		table.insert(route, node(44,-24-((slot-1)*24),"BIRTH_ROAD_QUEUE_"..slot))
	end
	for _, step in ipairs({
		node(44,42,"BIRTH_INTAKE",2,"INT"), node(44,78,"BIRTH_INTAKE_HOLD",0.6),
		node(44,109,"BIRTH_SHARED_WORK",8,"BIRTH_CYCLE"), node(44,137,"BIRTH_RETURN",0.3),
		node(102,137,"BIRTH_RETURN",0.3), node(102,42), node(108,42,"BIRTH_SALES",3,"SAL"),
		node(108,18,"BIRTH_DELIVERY",0.8), node(108,-26),
	}) do table.insert(route,step) end
	return route
end

local function birthDirectResaleRoute(): {Node}
	return {
		node(20,-24,"BIRTH_DIRECT_QUEUE"), node(20,42,"BIRTH_DIRECT_INTAKE",2,"INT"),
		node(20,12,"BIRTH_FRONTAGE_EXCHANGE"), node(108,12,"BIRTH_FRONTAGE_EXCHANGE"),
		node(108,42,"BIRTH_SALES",3,"SAL"), node(108,18,"BIRTH_DELIVERY",0.8), node(108,-26),
	}
end

local function workingRoute(salesIndex: number, queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth = queueIndex or 1
	for slot = depth, 1, -1 do
		table.insert(route,node(44,-24-((slot-1)*24),"WORKING_ROAD_QUEUE_"..slot))
	end
	local saleX = salesIndex == 2 and 146 or 122
	for _, step in ipairs({
		node(44,42,"WORKING_INTAKE",2,"INT"), node(44,78,"WORKING_INTAKE_HOLD",0.6),
		node(44,109,"WORKING_WASH",3,"WAS"), node(44,137,"WORKING_DIRTY_APPROACH",0.3),
		node(44,166,"WORKING_REPAIR",5,"WORKING_REPAIR"), node(44,195,"WORKING_CROSSOVER",0.4),
		node(102,195,"WORKING_CROSSOVER",0.3), node(176,195,"WORKING_CROSSOVER",0.4),
		node(176,166,"WORKING_FINISH",4,"WORKING_FINISH"), node(176,142,"WORKING_RETURN",0.3),
		node(148,142,"WORKING_RETURN",0.3), node(148,80), node(saleX,42,"WORKING_SALES_"..salesIndex,3,"SAL"),
		node(146,16,"WORKING_DELIVERY",0.8), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function workingDirectResaleRoute(): {Node}
	return {
		node(68,-24,"WORKING_DIRECT_QUEUE"), node(68,42,"WORKING_DIRECT_INTAKE",2,"INT"),
		node(68,14,"WORKING_FRONTAGE_EXCHANGE"), node(122,14,"WORKING_FRONTAGE_EXCHANGE"),
		node(122,42,"WORKING_SALES_1",3,"SAL"), node(146,16,"WORKING_DELIVERY",0.8), node(146,-26),
	}
end

local function dedicatedFullRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth = queueIndex or 1
	for slot=depth,1,-1 do table.insert(route,node(44,-24-((slot-1)*24),"DEDICATED_ROAD_QUEUE_"..slot)) end
	for _,step in ipairs({
		node(44,42,"DEDICATED_INTAKE",2,"INT"), node(44,78,"DEDICATED_INTAKE_HOLD",0.5),
		node(44,109,"DEDICATED_WAS",3,"WAS"), node(44,137,"DEDICATED_DIRTY_GAP_1",0.3),
		node(44,166,"DEDICATED_MEC",4,"MEC"), node(44,195,"DEDICATED_DIRTY_GAP_2",0.3),
		node(44,224,"DEDICATED_BOD",4,"BOD"), node(44,253,"DEDICATED_DIRTY_GAP_3",0.3),
		node(44,284,"DEDICATED_TUN",3,"TUN"), node(44,317,"DEDICATED_REAR_TRANSFER",0.4),
		node(176,317,"DEDICATED_REAR_TRANSFER",0.3), node(176,284,"DEDICATED_PNT",4,"PNT"),
		node(176,253,"DEDICATED_CLEAN_GAP_3",0.3), node(176,224,"DEDICATED_DET",3,"DET"),
		node(176,195,"DEDICATED_CLEAN_GAP_2",0.3), node(176,166,"DEDICATED_PHO",2,"PHO"),
		node(176,142,"DEDICATED_RETURN",0.3), node(148,142,"DEDICATED_RETURN",0.3), node(148,80),
		node(122,42,"DEDICATED_SALES_1",3,"SAL"), node(146,16,"DEDICATED_DELIVERY",0.8), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function dedicatedMechanicalRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth=queueIndex or 1
	for slot=depth,1,-1 do table.insert(route,node(44,-24-((slot-1)*24),"DEDICATED_ROAD_QUEUE_"..slot)) end
	for _,step in ipairs({
		node(44,42,"DEDICATED_INTAKE",2,"INT"), node(44,78,"DEDICATED_INTAKE_HOLD",0.5),
		node(44,109,"DEDICATED_WAS",3,"WAS"), node(44,137,"DEDICATED_DIRTY_GAP_1",0.3),
		node(44,166,"DEDICATED_MEC",4,"MEC"), node(44,195,"DEDICATED_DIRTY_GAP_2",0.3),
		node(102,195,"DEDICATED_BYPASS",0.3), node(102,253,"DEDICATED_BYPASS",0.3),
		node(176,253,"DEDICATED_CLEAN_GAP_3",0.3), node(176,224,"DEDICATED_DET",3,"DET"),
		node(176,195,"DEDICATED_CLEAN_GAP_2",0.3), node(176,166,"DEDICATED_PHO",2,"PHO"),
		node(176,142,"DEDICATED_RETURN",0.3), node(148,142,"DEDICATED_RETURN",0.3), node(148,80),
		node(146,42,"DEDICATED_SALES_2",3,"SAL"), node(146,16,"DEDICATED_DELIVERY",0.8), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function dedicatedDirectResaleRoute(): {Node}
	return {
		node(68,-24,"DEDICATED_DIRECT_QUEUE"), node(68,42,"DEDICATED_SPECIAL_INTAKE",2,"INT"),
		node(68,14,"DEDICATED_FRONTAGE_EXCHANGE"), node(122,14,"DEDICATED_FRONTAGE_EXCHANGE"),
		node(122,42,"DEDICATED_SALES_1",3,"SAL"), node(146,16,"DEDICATED_DELIVERY",0.8), node(146,-26),
	}
end

-- Professional retains every Dedicated route centre. Improved equipment
-- reduces dwell before another physical bay is activated.
local function professionalFullRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth=queueIndex or 1
	for slot=depth,1,-1 do table.insert(route,node(44,-24-((slot-1)*24),"PRO_ROAD_QUEUE_"..slot)) end
	for _,step in ipairs({
		node(44,42,"PRO_INT",1.7,"INT"), node(44,78,"PRO_INT_HOLD",0.35),
		node(44,109,"PRO_WAS",2.4,"WAS"), node(44,137,"PRO_DIRTY_GAP_1",0.2),
		node(44,166,"PRO_MEC",3.2,"MEC"), node(44,195,"PRO_DIRTY_GAP_2",0.2),
		node(44,224,"PRO_BOD",3.3,"BOD"), node(44,253,"PRO_DIRTY_GAP_3",0.2),
		node(44,284,"PRO_TUN",2.4,"TUN"), node(44,317,"PRO_REAR_TRANSFER",0.3),
		node(176,317,"PRO_REAR_TRANSFER",0.2), node(176,284,"PRO_PNT",3.3,"PNT"),
		node(176,253,"PRO_CLEAN_GAP_3",0.2), node(176,224,"PRO_DET",2.4,"DET"),
		node(176,195,"PRO_CLEAN_GAP_2",0.2), node(176,166,"PRO_PHO",1.5,"PHO"),
		node(176,142,"PRO_RETURN",0.2), node(148,142,"PRO_RETURN",0.2), node(148,80),
		node(122,42,"PRO_SALES_1",2.4,"SAL"), node(146,16,"PRO_DELIVERY",0.6), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function professionalMechanicalRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth=queueIndex or 1
	for slot=depth,1,-1 do table.insert(route,node(44,-24-((slot-1)*24),"PRO_ROAD_QUEUE_"..slot)) end
	for _,step in ipairs({
		node(44,42,"PRO_INT",1.7,"INT"), node(44,78,"PRO_INT_HOLD",0.35),
		node(44,109,"PRO_WAS",2.4,"WAS"), node(44,137,"PRO_DIRTY_GAP_1",0.2),
		node(44,166,"PRO_MEC",3.2,"MEC"), node(44,195,"PRO_DIRTY_GAP_2",0.2),
		node(102,195,"PRO_BYPASS",0.2), node(102,253,"PRO_BYPASS",0.2),
		node(176,253,"PRO_CLEAN_GAP_3",0.2), node(176,224,"PRO_DET",2.4,"DET"),
		node(176,195,"PRO_CLEAN_GAP_2",0.2), node(176,166,"PRO_PHO",1.5,"PHO"),
		node(176,142,"PRO_RETURN",0.2), node(148,142,"PRO_RETURN",0.2), node(148,80),
		node(146,42,"PRO_SALES_2",2.4,"SAL"), node(146,16,"PRO_DELIVERY",0.6), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function professionalCosmeticRoute(queueIndex: number?): {Node}
	local route: {Node} = {}
	local depth=queueIndex or 1
	for slot=depth,1,-1 do table.insert(route,node(44,-24-((slot-1)*24),"PRO_ROAD_QUEUE_"..slot)) end
	for _,step in ipairs({
		node(44,42,"PRO_INT",1.7,"INT"), node(44,78,"PRO_INT_HOLD",0.35),
		node(44,109,"PRO_WAS",2.4,"WAS"), node(44,137,"PRO_DIRTY_GAP_1",0.2),
		node(44,166,"PRO_MEC",0.1), node(44,195,"PRO_DIRTY_GAP_2",0.2),
		node(102,195,"PRO_BYPASS",0.2), node(102,253,"PRO_BYPASS",0.2),
		node(176,253,"PRO_CLEAN_GAP_3",0.2), node(176,224,"PRO_DET",2.4,"DET"),
		node(176,195,"PRO_CLEAN_GAP_2",0.2), node(176,166,"PRO_PHO",1.5,"PHO"),
		node(176,142,"PRO_RETURN",0.2), node(148,142,"PRO_RETURN",0.2), node(148,80),
		node(122,42,"PRO_SALES_1",2.4,"SAL"), node(146,16,"PRO_DELIVERY",0.6), node(146,-26),
	}) do table.insert(route,step) end
	return route
end

local function professionalDirectResaleRoute(): {Node}
	return {
		node(68,-24,"PRO_DIRECT_QUEUE"), node(68,42,"PRO_SPECIAL_INTAKE",1.7,"INT"),
		node(68,14,"PRO_FRONTAGE_EXCHANGE"), node(122,14,"PRO_FRONTAGE_EXCHANGE"),
		node(122,42,"PRO_SALES_1",2.4,"SAL"), node(146,16,"PRO_DELIVERY",0.6), node(146,-26),
	}
end

local function institutionOwnerKeepRoute(queueIndex: number?): {Node}
	local route=professionalFullRoute(queueIndex)
	-- Remove Professional return-to-sales, sale, delivery and road-exit tail.
	for _=1,6 do table.remove(route) end
	for _,step in ipairs({
		node(176,142,"INST_OWNER_RETURN",0.2), node(148,142,"INST_OWNER_RETURN",0.2),
		node(148,108,"INST_OWNER_APPROACH",0.2), node(174,108,"INST_OWNER_APPROACH",0.2),
		node(174,88,"INST_OWNER_GARAGE",2,"PHO"),
	}) do table.insert(route,step) end
	return route
end

local function routeForState(lane: number, queueIndex: number?): {Node}
	if state.progression == "BIRTH" then return birthRoute(queueIndex) end
	if state.progression == "WORKING" then return workingRoute(lane,queueIndex) end
	if state.progression == "DEDICATED" then return dedicatedFullRoute(queueIndex) end
	if state.progression == "PROFESSIONAL" then return professionalFullRoute(queueIndex) end
	if state.progression == "INSTITUTION" then return professionalFullRoute(queueIndex) end
	return fullRoute(lane,queueIndex)
end

local function directRouteForState(): {Node}
	if state.progression == "BIRTH" then return birthDirectResaleRoute() end
	if state.progression == "WORKING" then return workingDirectResaleRoute() end
	if state.progression == "DEDICATED" then return dedicatedDirectResaleRoute() end
	if state.progression == "PROFESSIONAL" then return professionalDirectResaleRoute() end
	if state.progression == "INSTITUTION" then return professionalDirectResaleRoute() end
	return directResaleRoute()
end

local function setProgressionGroupVisible(group: Instance?, visible: boolean)
	if not group then return end
	for _, descendant in ipairs(group:GetDescendants()) do
		local isDedicatedOrLater = state.progression == "DEDICATED" or state.progression == "PROFESSIONAL" or state.progression == "INSTITUTION"
		local isProfessionalOrLater = state.progression == "PROFESSIONAL" or state.progression == "INSTITUTION"
		local hiddenForDedicated = isDedicatedOrLater and descendant:GetAttribute("HideInDedicated") == true
		local hiddenForProfessional = isProfessionalOrLater and descendant:GetAttribute("HideInProfessional") == true
		local hiddenForInstitution = state.progression == "INSTITUTION" and descendant:GetAttribute("HideInInstitution") == true
		local show = visible and not hiddenForDedicated and not hiddenForProfessional and not hiddenForInstitution
		if descendant:IsA("BasePart") then
			descendant.Transparency = show and (descendant:GetAttribute("ProgressionBaseTransparency") or 0) or 1
			descendant.CanCollide = show and descendant:GetAttribute("ProgressionBaseCanCollide") == true or false
			descendant.CanQuery = show and descendant:GetAttribute("ProgressionBaseCanQuery") ~= false or false
		elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
			descendant.Enabled = show and descendant:GetAttribute("ProgressionBaseEnabled") ~= false
		end
	end
end

local function setBaselineVisible(visible: boolean)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("ProgressionBaselineTransparency") ~= nil then
			descendant.Transparency = visible and descendant:GetAttribute("ProgressionBaselineTransparency") or 1
			descendant.CanCollide = visible and descendant:GetAttribute("ProgressionBaselineCanCollide") == true or false
			descendant.CanQuery = visible and descendant:GetAttribute("ProgressionBaselineCanQuery") ~= false or false
		elseif (descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui")) and descendant:GetAttribute("ProgressionBaselineEnabled") ~= nil then
			descendant.Enabled = visible and descendant:GetAttribute("ProgressionBaselineEnabled") == true
		end
	end
end

local function applyProgressionVisibility()
	local progression = root:FindFirstChild("14_Progression_3A")
	if not progression then return end
	local progression3B = root:FindFirstChild("15_Progression_3B")
	local progression3C = root:FindFirstChild("16_Progression_3C")
	local progression3D = root:FindFirstChild("17_Progression_3D")
	local rearCampus3E = root:FindFirstChild("18_RearCampus_3E")
	local isRoute = state.progression == "ROUTE_CONTRACT"
	setBaselineVisible(isRoute)
	setProgressionGroupVisible(progression:FindFirstChild("01_Persistent_Core"),not isRoute)
	setProgressionGroupVisible(progression:FindFirstChild("02_Birth_Only"),state.progression == "BIRTH")
	setProgressionGroupVisible(progression:FindFirstChild("03_Working_Only"),state.progression == "WORKING" or state.progression == "DEDICATED" or state.progression == "PROFESSIONAL" or state.progression == "INSTITUTION")
	if progression3B then setProgressionGroupVisible(progression3B:FindFirstChild("01_Dedicated_Only"),state.progression == "DEDICATED" or state.progression == "PROFESSIONAL" or state.progression == "INSTITUTION") end
	if progression3C then setProgressionGroupVisible(progression3C:FindFirstChild("01_Professional_Only"),state.progression == "PROFESSIONAL" or state.progression == "INSTITUTION") end
	if progression3D then setProgressionGroupVisible(progression3D:FindFirstChild("01_Institution_Only"),state.progression == "INSTITUTION") end
	if rearCampus3E then
		setProgressionGroupVisible(rearCampus3E:FindFirstChild("01_Birth_Rear"),state.progression == "BIRTH")
		setProgressionGroupVisible(rearCampus3E:FindFirstChild("02_Working_Rear"),state.progression == "WORKING")
		setProgressionGroupVisible(rearCampus3E:FindFirstChild("03_Dedicated_Rear"),state.progression == "DEDICATED")
		setProgressionGroupVisible(rearCampus3E:FindFirstChild("04_Professional_Rear"),state.progression == "PROFESSIONAL")
		setProgressionGroupVisible(rearCampus3E:FindFirstChild("05_Institution_Rear"),state.progression == "INSTITUTION")
	end
	root:SetAttribute("ProgressionState",state.progression)
end

local function moveTo(car: Model, target: Vector3, token: number): boolean
	local startCF = car:GetPivot()
	local start = startCF.Position
	local horizontalTarget = Vector3.new(target.X, start.Y, target.Z)
	local delta = horizontalTarget - start
	local distance = delta.Magnitude
	if distance < 0.05 then return token == state.runToken end
	local facing = CFrame.lookAt(start, horizontalTarget)
	local duration = distance / 18
	local elapsed = 0
	while elapsed < duration and token == state.runToken do
		if not waitForPlay(token) then return false end
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt * state.speed
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local position = start:Lerp(horizontalTarget, alpha)
		car:PivotTo(CFrame.lookAt(position, position + facing.LookVector))
	end
	if token ~= state.runToken then return false end
	car:PivotTo(CFrame.lookAt(horizontalTarget, horizontalTarget + facing.LookVector))
	return true
end

local function dwell(seconds: number, token: number): boolean
	local elapsed = 0
	while elapsed < seconds and token == state.runToken do
		if not waitForPlay(token) then return false end
		elapsed += task.wait(0.05) * state.speed
	end
	return token == state.runToken
end

local palette = {
	Color3.fromRGB(175, 72, 53),
	Color3.fromRGB(63, 113, 184),
	Color3.fromRGB(223, 178, 65),
	Color3.fromRGB(81, 153, 110),
	Color3.fromRGB(144, 82, 174),
	Color3.fromRGB(220, 220, 218),
}

local function runCar(index: number, route: {Node}, delaySeconds: number, token: number)
	if not dwell(delaySeconds, token) then return end
	local id = string.format("FLOW_CAR_%02d", index)
	local finalColor = palette[((index - 1) % #palette) + 1]
	local car = createCar(id, Color3.fromRGB(111, 82, 58), route[1].x, route[1].z)
	state.spawned += 1
	state.active += 1
	sendStatus(id .. " entered")
	local heldResource: string? = nil
	for _, step in ipairs(route) do
		if token ~= state.runToken then break end
		if step.resource and not acquire(step.resource, id, token) then break end
		if not moveTo(car, localPosition(step.x, 2.2, step.z), token) then break end
		if heldResource then release(heldResource, id) end
		heldResource = step.resource
		if step.station then applyTreatment(car, step.station, finalColor) end
		if step.dwell and step.dwell > 0 and not dwell(step.dwell, token) then break end
	end
	if heldResource then release(heldResource, id) end
	if token == state.runToken then
		state.completed += 1
		state.active -= 1
		car:Destroy()
		if state.active == 0 and state.completed >= state.spawned then
			state.running = false
		end
		sendStatus(id .. " completed")
	end
end

local function resetRuntime()
	state.runToken += 1
	state.running = false
	state.paused = false
	state.active = 0
	state.completed = 0
	state.spawned = 0
	state.maxQueue = 0
	state.maxWait = 0
	state.bottleneckResource = "NONE"
	state.bottleneckWait = 0
	state.conflicts = 0
	state.recoveries = 0
	table.clear(resources)
	table.clear(waiting)
	table.clear(seenConflicts)
	for _, child in ipairs(carsFolder:GetChildren()) do child:Destroy() end
	local oldLog = runtime:FindFirstChild("ConflictEvents")
	if oldLog then oldLog:Destroy() end
	sendStatus("Reset")
end

local function startScenario(scenario: string)
	resetRuntime()
	state.scenario = scenario
	state.running = true
	state.runToken += 1
	local token = state.runToken
	if state.progression == "BIRTH" then
		if scenario == "NORMAL" then
			task.spawn(runCar,1,birthRoute(1),0,token)
		elseif scenario == "CAPACITY" then
			for i=1,3 do task.spawn(runCar,i,birthRoute(i),(i-1)*1.5,token) end
		else
			task.spawn(runCar,1,birthRoute(1),0,token)
			task.spawn(runCar,2,birthDirectResaleRoute(),3,token)
		end
	elseif state.progression == "WORKING" then
		if scenario == "NORMAL" then
			task.spawn(runCar,1,workingRoute(1,1),0,token)
			task.spawn(runCar,2,workingRoute(2,2),2,token)
		elseif scenario == "CAPACITY" then
			for i=1,4 do task.spawn(runCar,i,workingRoute(i%2==0 and 2 or 1,i),(i-1)*1.5,token) end
		else
			task.spawn(runCar,1,workingRoute(1,1),0,token)
			task.spawn(runCar,2,workingRoute(2,2),2,token)
			task.spawn(runCar,3,workingDirectResaleRoute(),4,token)
		end
	elseif state.progression == "DEDICATED" then
		if scenario == "NORMAL" then
			task.spawn(runCar,1,dedicatedFullRoute(1),0,token)
			task.spawn(runCar,2,dedicatedMechanicalRoute(2),2,token)
		elseif scenario == "CAPACITY" then
			for i=1,6 do
				local route = i%3==0 and dedicatedMechanicalRoute(i) or dedicatedFullRoute(i)
				task.spawn(runCar,i,route,(i-1)*1.3,token)
			end
		else
			task.spawn(runCar,1,dedicatedFullRoute(1),0,token)
			task.spawn(runCar,2,dedicatedMechanicalRoute(2),2,token)
			task.spawn(runCar,3,dedicatedDirectResaleRoute(),4,token)
		end
	elseif state.progression == "PROFESSIONAL" then
		if scenario == "NORMAL" then
			task.spawn(runCar,1,professionalFullRoute(1),0,token)
			task.spawn(runCar,2,professionalMechanicalRoute(2),1.7,token)
			task.spawn(runCar,3,professionalCosmeticRoute(3),3.4,token)
		elseif scenario == "CAPACITY" then
			for i=1,10 do
				local route = i%4==0 and professionalCosmeticRoute(i) or i%3==0 and professionalMechanicalRoute(i) or professionalFullRoute(i)
				task.spawn(runCar,i,route,(i-1)*1.05,token)
			end
		else
			task.spawn(runCar,1,professionalFullRoute(1),0,token)
			task.spawn(runCar,2,professionalMechanicalRoute(2),1.6,token)
			task.spawn(runCar,3,professionalCosmeticRoute(3),3.2,token)
			task.spawn(runCar,4,professionalDirectResaleRoute(),4.8,token)
		end
	elseif state.progression == "INSTITUTION" then
		if scenario == "NORMAL" then
			task.spawn(runCar,1,professionalFullRoute(1),0,token)
			task.spawn(runCar,2,professionalMechanicalRoute(2),1.5,token)
			task.spawn(runCar,3,institutionOwnerKeepRoute(3),3,token)
		elseif scenario == "CAPACITY" then
			for i=1,12 do
				local route=i%4==0 and professionalCosmeticRoute(i) or i%3==0 and professionalMechanicalRoute(i) or professionalFullRoute(i)
				task.spawn(runCar,i,route,(i-1)*1.5,token)
			end
			task.spawn(runCar,13,institutionOwnerKeepRoute(13),18.2,token)
		else
			task.spawn(runCar,1,professionalFullRoute(1),0,token)
			task.spawn(runCar,2,professionalMechanicalRoute(2),1.4,token)
			task.spawn(runCar,3,professionalCosmeticRoute(3),2.8,token)
			task.spawn(runCar,4,professionalDirectResaleRoute(),4.2,token)
			task.spawn(runCar,5,institutionOwnerKeepRoute(4),4.8,token)
		end
	elseif scenario == "NORMAL" then
		task.spawn(runCar, 1, routeForState(1, 1), 0, token)
		task.spawn(runCar, 2, routeForState(2, 1), 2, token)
	elseif scenario == "CAPACITY" then
		for i = 1, 8 do
			local lane = i % 2 == 0 and 2 or 1
			local queueIndex = math.ceil(i / 2)
			task.spawn(runCar, i, routeForState(lane, queueIndex), (i - 1) * 1.5, token)
		end
	else
		task.spawn(runCar, 1, routeForState(1, 1), 0, token)
		task.spawn(runCar, 2, routeForState(2, 1), 2, token)
		task.spawn(runCar, 3, skipRoute(), 4, token)
		task.spawn(runCar, 4, directRouteForState(), 7, token)
	end
	sendStatus("Scenario started")
end

applyProgressionVisibility()

-- Conservative proxy proximity evidence. Occupancy locks should keep centers
-- farther apart than this threshold except while independently parked in
-- adjacent 20+ stud lane centres.
task.spawn(function()
	while true do
		task.wait(0.12)
		local cars = carsFolder:GetChildren()
		for i = 1, #cars do
			for j = i + 1, #cars do
				local a = cars[i]:IsA("Model") and cars[i]:GetPivot().Position or nil
				local b = cars[j]:IsA("Model") and cars[j]:GetPivot().Position or nil
				if a and b then
					local flat = (Vector3.new(a.X,0,a.Z) - Vector3.new(b.X,0,b.Z)).Magnitude
					local pair = cars[i].Name < cars[j].Name and cars[i].Name.."|"..cars[j].Name or cars[j].Name.."|"..cars[i].Name
					if flat < 10.5 and not seenConflicts[pair] then
						seenConflicts[pair] = true
						state.conflicts += 1
						local log = runtime:FindFirstChild("ConflictEvents") or Instance.new("Folder")
						log.Name = "ConflictEvents"
						log.Parent = runtime
						local event = Instance.new("StringValue")
						event.Name = string.format("Conflict_%02d", state.conflicts)
						event.Value = string.format(
							"%s | distance %.2f | %s=(%.1f,%.1f) %s | %s=(%.1f,%.1f) %s",
							pair,
							flat,
							cars[i].Name, a.X, a.Z, tostring(cars[i]:GetAttribute("RouteState")),
							cars[j].Name, b.X, b.Z, tostring(cars[j]:GetAttribute("RouteState"))
						)
						event.Parent = log
						runtime:SetAttribute("LastConflict", event.Value)
						sendStatus("Proxy proximity conflict: " .. pair)
					elseif flat >= 13 then
						seenConflicts[pair] = nil
					end
				end
			end
		end
	end
end)

commandEvent.OnServerEvent:Connect(function(_player, command, value)
	if command == "Start" then
		startScenario(typeof(value) == "string" and value or state.scenario)
	elseif command == "State" and typeof(value) == "string" and table.find({"BIRTH","WORKING","DEDICATED","PROFESSIONAL","INSTITUTION","ROUTE_CONTRACT"},value) then
		resetRuntime()
		state.progression = value
		applyProgressionVisibility()
		sendStatus("Progression state changed")
	elseif command == "Reset" then
		resetRuntime()
	elseif command == "Pause" then
		state.paused = not state.paused
		sendStatus(state.paused and "Paused" or "Resumed")
	elseif command == "Speed" and typeof(value) == "number" then
		state.speed = math.clamp(value, 0.5, 4)
		sendStatus("Speed changed")
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.delay(1, function() if player.Parent then sendStatus("Ready") end end)
end)

task.delay(2, function()
	if #Players:GetPlayers() > 0 and not state.running then startScenario("MIXED") end
end)

