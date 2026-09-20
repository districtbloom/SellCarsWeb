--!strict

-- Dense, rerunnable blockout pass for the Sell Cars compact-campus prototype.
-- This module is copied into Place1/ServerStorage and invoked in Edit mode.

local Builder = {}

local ROOT_NAME = "SellCars_CompactCampus_Greybox_V1"
local DETAIL_FOLDER_NAME = "Detailed_Blockout_V2"
local ROUTE_SUFFIX = "_V2"

local COLORS = {
	structure = Color3.fromRGB(103, 105, 108),
	structureDark = Color3.fromRGB(55, 59, 63),
	furniture = Color3.fromRGB(128, 92, 58),
	wood = Color3.fromRGB(151, 104, 61),
	metal = Color3.fromRGB(92, 101, 108),
	glass = Color3.fromRGB(103, 179, 203),
	light = Color3.fromRGB(255, 214, 122),
	asphalt = Color3.fromRGB(53, 58, 64),
	curb = Color3.fromRGB(185, 183, 169),
	public = Color3.fromRGB(229, 166, 63),
	work = Color3.fromRGB(224, 105, 73),
	clean = Color3.fromRGB(78, 180, 142),
	garage = Color3.fromRGB(166, 91, 180),
	logistics = Color3.fromRGB(130, 105, 190),
	flow = Color3.fromRGB(88, 192, 210),
	ownerFlow = Color3.fromRGB(216, 92, 226),
	serviceFlow = Color3.fromRGB(165, 132, 225),
	pedestrian = Color3.fromRGB(238, 207, 102),
	safety = Color3.fromRGB(232, 83, 65),
	white = Color3.fromRGB(235, 235, 230),
	black = Color3.fromRGB(31, 34, 38),
}

local function setAttributes(instance: Instance, attributes: {[string]: any}?)
	if not attributes then return end
	for key, value in attributes do
		instance:SetAttribute(key, value)
	end
end

local function newModel(parent: Instance, name: string, functionId: string?, minStep: number?, attributes: {[string]: any}?): Model
	local model = Instance.new("Model")
	model.Name = name
	if functionId then model:SetAttribute("FunctionId", functionId) end
	if minStep then model:SetAttribute("MinStep", minStep) end
	setAttributes(model, attributes)
	model.Parent = parent
	return model
end

local function box(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3?,
	transparency: number?,
	canCollide: boolean?,
	material: Enum.Material?,
	yaw: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide == true
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = (transparency or 0) < 0.45
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color or COLORS.structure
	part.Transparency = transparency or 0
	part.Size = size
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	part.Parent = parent
	return part
end

local function cylinder(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3?, transparency: number?, yaw: number?): Part
	local part = box(parent, name, position, size, color, transparency, false, Enum.Material.SmoothPlastic, yaw)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function verticalCylinder(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3?, transparency: number?, yaw: number?): Part
	local part = box(parent, name, position, size, color, transparency, false, Enum.Material.SmoothPlastic)
	part.Shape = Enum.PartType.Cylinder
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), math.rad(90))
	return part
end

local function lineBetween(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3, transparency: number?): Part
	local midpoint = (a + b) * 0.5
	local length = (b - a).Magnitude
	local part = box(parent, name, midpoint, Vector3.new(width, 0.16, length), color, transparency, false, Enum.Material.Neon)
	part.CFrame = CFrame.lookAt(midpoint, b)
	return part
end

local function footprint(parent: Instance, name: string, position: Vector3, sizeXZ: Vector2, color: Color3, transparency: number?, yaw: number?): Part
	return box(parent, name, position, Vector3.new(sizeXZ.X, 0.18, sizeXZ.Y), color, transparency or 0.55, false, Enum.Material.SmoothPlastic, yaw)
end

local function tableKit(parent: Instance, name: string, position: Vector3, sizeXZ: Vector2, color: Color3?, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local top = box(model, "Top", position + Vector3.new(0, 3.1, 0), Vector3.new(sizeXZ.X, 0.45, sizeXZ.Y), color or COLORS.furniture, 0, true, Enum.Material.Wood, yaw)
	local offsets = {
		Vector3.new(sizeXZ.X * 0.38, 1.55, sizeXZ.Y * 0.34), Vector3.new(-sizeXZ.X * 0.38, 1.55, sizeXZ.Y * 0.34),
		Vector3.new(sizeXZ.X * 0.38, 1.55, -sizeXZ.Y * 0.34), Vector3.new(-sizeXZ.X * 0.38, 1.55, -sizeXZ.Y * 0.34),
	}
	for index, offset in offsets do
		local world = (CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)):PointToWorldSpace(offset)
		box(model, "Leg_" .. index, world, Vector3.new(0.35, 3, 0.35), color or COLORS.furniture, 0, true, Enum.Material.Wood)
	end
	model.PrimaryPart = top
	return model
end

local function chairKit(parent: Instance, name: string, position: Vector3, color: Color3?, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local seat = box(model, "Seat", cf:PointToWorldSpace(Vector3.new(0, 2.05, 0)), Vector3.new(2.2, 0.5, 2.2), color or COLORS.structureDark, 0, true, Enum.Material.Fabric, yaw)
	box(model, "Back", cf:PointToWorldSpace(Vector3.new(0, 3.35, 0.9)), Vector3.new(2.2, 2.6, 0.45), color or COLORS.structureDark, 0, true, Enum.Material.Fabric, yaw)
	box(model, "Base", cf:PointToWorldSpace(Vector3.new(0, 1, 0)), Vector3.new(0.45, 2, 0.45), COLORS.metal, 0, true, Enum.Material.Metal, yaw)
	model.PrimaryPart = seat
	return model
end

local function workstation(parent: Instance, name: string, position: Vector3, yaw: number?, premium: boolean?): Model
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local desk = tableKit(model, "Desk", position, Vector2.new(6.5, 3.2), premium and COLORS.wood or COLORS.furniture, yaw)
	local screenPos = cf:PointToWorldSpace(Vector3.new(0, 4.55, -0.2))
	box(model, "Monitor", screenPos, Vector3.new(2.6, 1.65, 0.35), COLORS.black, 0, true, Enum.Material.SmoothPlastic, yaw)
	box(model, "Screen", cf:PointToWorldSpace(Vector3.new(0, 4.55, -0.4)), Vector3.new(2.25, 1.3, 0.08), COLORS.glass, 0.15, false, Enum.Material.Neon, yaw)
	chairKit(model, "Chair", cf:PointToWorldSpace(Vector3.new(0, 0, 3)), premium and Color3.fromRGB(104, 69, 50) or COLORS.structureDark, (yaw or 0) + 180)
	model.PrimaryPart = desk.PrimaryPart
	return model
end

local function shelfKit(parent: Instance, name: string, position: Vector3, width: number, height: number, yaw: number?, color: Color3?): Model
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	for _, x in {-width * 0.46, width * 0.46} do
		box(model, "Upright", cf:PointToWorldSpace(Vector3.new(x, height * 0.5, 0)), Vector3.new(0.4, height, 2.2), COLORS.metal, 0, true, Enum.Material.Metal, yaw)
	end
	for index = 0, 3 do
		local y = 0.6 + index * ((height - 1.2) / 3)
		box(model, "Shelf_" .. index, cf:PointToWorldSpace(Vector3.new(0, y, 0)), Vector3.new(width, 0.32, 2.4), color or COLORS.metal, 0, true, Enum.Material.Metal, yaw)
	end
	for index = 1, 5 do
		local x = -width * 0.38 + (index - 1) * width * 0.19
		box(model, "Bin_" .. index, cf:PointToWorldSpace(Vector3.new(x, 2, 0)), Vector3.new(math.max(width * 0.14, 0.8), 1, 1.6), Color3.fromRGB(190, 117, 52), 0, true, Enum.Material.SmoothPlastic, yaw)
	end
	return model
end

local function cabinetKit(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3?, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	box(model, "Body", position + Vector3.new(0, size.Y * 0.5, 0), size, color or COLORS.structureDark, 0, true, Enum.Material.Metal, yaw)
	for index = 1, 4 do
		local y = size.Y * (0.18 + (index - 1) * 0.18)
		box(model, "Drawer_" .. index, position + Vector3.new(0, y, -(size.Z * 0.5 + 0.04)), Vector3.new(size.X * 0.86, size.Y * 0.12, 0.08), COLORS.metal, 0, false, Enum.Material.Metal, yaw)
	end
	return model
end

local function machineKit(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3?, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	box(model, "Machine", position + Vector3.new(0, size.Y * 0.5, 0), size, color or COLORS.metal, 0, true, Enum.Material.Metal, yaw)
	box(model, "Control", position + Vector3.new(0, size.Y * 0.72, -(size.Z * 0.5 + 0.08)), Vector3.new(size.X * 0.62, size.Y * 0.28, 0.15), COLORS.glass, 0.05, false, Enum.Material.Neon, yaw)
	return model
end

local function boardKit(parent: Instance, name: string, position: Vector3, size: Vector2, color: Color3?, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local board = box(model, "Board", position, Vector3.new(size.X, size.Y, 0.35), color or COLORS.black, 0, true, Enum.Material.SmoothPlastic, yaw)
	for index = 1, 4 do
		box(model, "Row_" .. index, position + Vector3.new(0, size.Y * 0.32 - index * size.Y * 0.14, -0.23), Vector3.new(size.X * (0.78 - index * 0.04), 0.12, 0.08), COLORS.white, 0, false, Enum.Material.Neon, yaw)
	end
	model.PrimaryPart = board
	return model
end

local function lightRig(parent: Instance, name: string, position: Vector3, width: number, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	for _, x in {-width * 0.5, width * 0.5} do
		box(model, "Stand", cf:PointToWorldSpace(Vector3.new(x, 3.5, 0)), Vector3.new(0.35, 7, 0.35), COLORS.metal, 0, false, Enum.Material.Metal, yaw)
		box(model, "Lamp", cf:PointToWorldSpace(Vector3.new(x, 7.1, 0)), Vector3.new(2.1, 1.2, 0.7), COLORS.light, 0.05, false, Enum.Material.Neon, yaw)
	end
	return model
end

local function staffProxy(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local root = box(model, "Body", position + Vector3.new(0, 3.1, 0), Vector3.new(2.3, 3.2, 1.25), color, 0, false, Enum.Material.SmoothPlastic, yaw)
	cylinder(model, "Head", position + Vector3.new(0, 5.55, 0), Vector3.new(1.55, 1.55, 1.55), Color3.fromRGB(204, 157, 118), 0, 90)
	box(model, "LegL", position + Vector3.new(-0.55, 1, 0), Vector3.new(0.75, 2, 0.75), COLORS.structureDark, 0, false, Enum.Material.SmoothPlastic, yaw)
	box(model, "LegR", position + Vector3.new(0.55, 1, 0), Vector3.new(0.75, 2, 0.75), COLORS.structureDark, 0, false, Enum.Material.SmoothPlastic, yaw)
	model.PrimaryPart = root
	return model
end

local function carKit(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number?, scale: number?): Model
	local s = scale or 1
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local body = box(model, "Body", cf:PointToWorldSpace(Vector3.new(0, 2.05 * s, 0)), Vector3.new(9.4 * s, 2.2 * s, 15 * s), color, 0, false, Enum.Material.SmoothPlastic, yaw)
	box(model, "Cabin", cf:PointToWorldSpace(Vector3.new(0, 3.45 * s, 0.6 * s)), Vector3.new(7.4 * s, 1.6 * s, 7.4 * s), Color3.fromRGB(45, 55, 62), 0.08, false, Enum.Material.Glass, yaw)
	for _, x in {-4.55 * s, 4.55 * s} do
		for _, z in {-4.8 * s, 4.8 * s} do
			cylinder(model, "Wheel", cf:PointToWorldSpace(Vector3.new(x, 1.35 * s, z)), Vector3.new(1.1 * s, 2.1 * s, 2.1 * s), COLORS.black, 0, yaw)
		end
	end
	box(model, "FrontMarker", cf:PointToWorldSpace(Vector3.new(0, 2.25 * s, -7.6 * s)), Vector3.new(5.2 * s, 0.35 * s, 0.18 * s), COLORS.light, 0, false, Enum.Material.Neon, yaw)
	model.PrimaryPart = body
	return model
end

local function towTruckKit(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number?): Model
	local model = newModel(parent, name, nil, nil)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local chassis = box(model, "Chassis", cf:PointToWorldSpace(Vector3.new(0, 2.1, 1.5)), Vector3.new(10.5, 1.7, 22), color, 0, false, Enum.Material.Metal, yaw)
	box(model, "Cab", cf:PointToWorldSpace(Vector3.new(0, 4.3, -6.5)), Vector3.new(9.5, 4.5, 7), color, 0, false, Enum.Material.Metal, yaw)
	box(model, "Bed", cf:PointToWorldSpace(Vector3.new(0, 3.1, 4)), Vector3.new(9.5, 0.7, 14), COLORS.metal, 0, false, Enum.Material.DiamondPlate, yaw)
	for _, x in {-5, 5} do
		for _, z in {-6.5, 6} do cylinder(model, "Wheel", cf:PointToWorldSpace(Vector3.new(x, 1.4, z)), Vector3.new(1.2, 2.4, 2.4), COLORS.black, 0, yaw) end
	end
	model.PrimaryPart = chassis
	return model
end

local function component(parent: Instance, id: string, functionId: string, step: number, displayName: string, build: (Model) -> ()): Model
	local model = newModel(parent, id .. "_" .. displayName:gsub("[^%w]+", "_"), functionId, step, {
		ComponentId = id,
		DisplayName = displayName,
		DetailedBlockout = true,
	})
	build(model)
	return model
end

local function addEnvelope(parent: Instance, name: string, position: Vector3, sizeXZ: Vector2, functionId: string, minStep: number, yaw: number?)
	local model = newModel(parent, name, functionId, minStep, {VehicleClearance = true})
	footprint(model, "Clearance", position + Vector3.new(0, 1.08, 0), sizeXZ, COLORS.flow, 0.78, yaw)
	local halfX, halfZ = sizeXZ.X * 0.5, sizeXZ.Y * 0.5
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	for index, offset in {
		Vector3.new(-halfX, 0, -halfZ), Vector3.new(halfX, 0, -halfZ),
		Vector3.new(-halfX, 0, halfZ), Vector3.new(halfX, 0, halfZ),
	} do
		box(model, "Corner_" .. index, cf:PointToWorldSpace(offset) + Vector3.new(0, 1.18, 0), Vector3.new(1.2, 0.28, 1.2), COLORS.flow, 0.15, false, Enum.Material.Neon)
	end
	return model
end

local function waypoint(parent: Instance, name: string, order: number, position: Vector3, hold: number?, reverse: boolean?): Part
	local node = box(parent, name, position, Vector3.new(1, 1, 1), COLORS.flow, 1, false, Enum.Material.SmoothPlastic)
	node:SetAttribute("Order", order)
	node:SetAttribute("HoldSeconds", hold or 0)
	node:SetAttribute("Reverse", reverse == true)
	return node
end

local function routeModel(parent: Instance, name: string, points: {Vector3}, color: Color3, width: number, attributes: {[string]: any}?): Model
	local model = newModel(parent, name, "MOV", 1, attributes)
	for index = 1, #points - 1 do
		lineBetween(model, string.format("Segment_%02d", index), points[index], points[index + 1], width, color, 0.08)
	end
	for index, point in points do
		local node = footprint(model, string.format("Node_%02d", index), point + Vector3.new(0, 0.12, 0), Vector2.new(width * 1.8, width * 1.8), color, 0.58)
		node.Shape = Enum.PartType.Cylinder
	end
	return model
end

local function refitOfficeAndIntake(root: Model)
	local buildings = root:FindFirstChild("03_Building_Blockouts")
	if not buildings then return end
	local office = buildings:FindFirstChild("Collector_Hall_Office")
	if office and office:IsA("Model") then
		local function configure(name: string, position: Vector3, size: Vector3)
			local part = office:FindFirstChild(name)
			if part and part:IsA("BasePart") then part.Position = position part.Size = size end
		end
		configure("Floor", Vector3.new(14, 0.8, 120), Vector3.new(46, 0.8, 54))
		configure("BackWall", Vector3.new(14, 10.2, 146.25), Vector3.new(46, 18, 1.5))
		configure("LeftWall", Vector3.new(-8.25, 10.2, 120), Vector3.new(1.5, 18, 54))
		configure("RightWall", Vector3.new(36.25, 10.2, 120), Vector3.new(1.5, 18, 54))
		configure("FrontPierL", Vector3.new(-7.5, 10.2, 94.5), Vector3.new(3, 18, 3))
		configure("FrontPierR", Vector3.new(35.5, 10.2, 94.5), Vector3.new(3, 18, 3))
		configure("RoofMass", Vector3.new(14, 19.5, 120), Vector3.new(48, 1.2, 56))
		configure("Collector_Hall_Office_LabelAnchor", Vector3.new(14, 22, 97), Vector3.new(0.5, 0.5, 0.5))
		configure("UpperClientVolume", Vector3.new(14, 22, 133), Vector3.new(42, 6, 26))
		configure("OperationsDeck", Vector3.new(14, 15, 133), Vector3.new(42, 1, 22))
		configure("OperationsGlass", Vector3.new(14, 18, 122.5), Vector3.new(42, 6, 1))
		configure("OperationsUpper_LabelAnchor", Vector3.new(14, 23, 133), Vector3.new(0.5, 0.5, 0.5))
		office:SetAttribute("TrafficRefitVersion", 2)
	end

	local zones = root:FindFirstChild("02_Functional_Zones")
	local officeZone = zones and zones:FindFirstChild("OFF_Collector_Hall")
	if officeZone and officeZone:IsA("Model") then
		for _, part in officeZone:GetChildren() do
			if part:IsA("BasePart") then
				if part.Name == "Footprint" then part.Position = Vector3.new(14, 0.42, 120) part.Size = Vector3.new(46, 0.35, 54)
				elseif part.Name == "Boundary_Front" then part.Position = Vector3.new(14, 0.64, 93) part.Size = Vector3.new(46, 0.22, 0.8)
				elseif part.Name == "Boundary_Back" then part.Position = Vector3.new(14, 0.64, 147) part.Size = Vector3.new(46, 0.22, 0.8)
				elseif part.Name == "Boundary_Left" then part.Position = Vector3.new(-9, 0.64, 120)
				elseif part.Name == "Boundary_Right" then part.Position = Vector3.new(37, 0.64, 120)
				elseif part.Name:find("LabelAnchor") then part.Position = Vector3.new(14, 2.2, 120) end
			end
		end
	end

	local intake = buildings:FindFirstChild("Seller_Intake_Appraisal")
	if intake and intake:IsA("Model") then
		local leftWall = intake:FindFirstChild("LeftWall")
		if leftWall and leftWall:IsA("BasePart") then
			leftWall.Name = "LeftWall_Front"
			leftWall.Position = Vector3.new(64.75, 7.2, 27)
			leftWall.Size = Vector3.new(1.5, 12, 36)
		end
		local rearPier = intake:FindFirstChild("LeftWall_RearPier")
		if not rearPier then
			rearPier = box(intake, "LeftWall_RearPier", Vector3.new(64.75, 7.2, 84), Vector3.new(1.5, 12, 6), COLORS.structure, 0.18, true, Enum.Material.Concrete)
		end
		intake:SetAttribute("LateralVehicleExit", true)
		intake:SetAttribute("TrafficRefitVersion", 2)
	end

	local site = root:FindFirstChild("00_Site_and_Road")
	local spine = site and site:FindFirstChild("InternalVehicleSpine")
	if spine and spine:IsA("BasePart") then
		spine.Position = Vector3.new(49, 0.5, 198)
		spine.Size = Vector3.new(20, 0.4, 218)
		spine:SetAttribute("LaneWidth", 20)
		spine:SetAttribute("OneWay", true)
	end
end

local function suppressOldRoutes(root: Model)
	local routes = root:FindFirstChild("05_Vehicle_Routes")
	if not routes then return end
	for _, name in {"Dealer_Stock_Path", "Personal_Car_Path", "Tow_and_Parts_Path", "Customer_Walk_and_Handover"} do
		local item = routes:FindFirstChild(name)
		if item then
			item:SetAttribute("Superseded", true)
			item:SetAttribute("SupersededBy", name .. ROUTE_SUFFIX)
			for _, descendant in item:GetDescendants() do
				if descendant:IsA("BasePart") then descendant.Transparency = 1 descendant.CanCollide = false end
				if descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then descendant.Enabled = false end
			end
		end
	end
end

local function buildRoutes(root: Model, detail: Folder)
	local routes = root:FindFirstChild("05_Vehicle_Routes")
	if not routes then return end
	for _, child in routes:GetChildren() do
		if child.Name:sub(-#ROUTE_SUFFIX) == ROUTE_SUFFIX or child.Name == "Vehicle_Clearance_Envelopes_V2" or child.Name == "Traffic_Interface_V2" then
			child:Destroy()
		end
	end

	local envelopes = Instance.new("Folder")
	envelopes.Name = "Vehicle_Clearance_Envelopes_V2"
	envelopes:SetAttribute("FunctionId", "MOV")
	envelopes:SetAttribute("MinStep", 1)
	envelopes.Parent = routes

	footprint(envelopes, "East_OneWay_Lane", Vector3.new(49, 1.03, 198), Vector2.new(20, 218), COLORS.asphalt, 0.2)
	footprint(envelopes, "West_Return_Lane", Vector3.new(-34, 1.03, 198), Vector2.new(20, 218), COLORS.asphalt, 0.2)
	footprint(envelopes, "Rear_Transfer_Lane", Vector3.new(7.5, 1.03, 304), Vector2.new(103, 20), COLORS.asphalt, 0.2)
	footprint(envelopes, "Front_Transfer_Pocket", Vector3.new(7, 1.03, 82), Vector2.new(83, 18), COLORS.asphalt, 0.2)
	footprint(envelopes, "Intake_Side_Exit_Apron", Vector3.new(72, 1.04, 66), Vector2.new(44, 22), COLORS.asphalt, 0.16)
	footprint(envelopes, "Garage_Independent_Drive", Vector3.new(-88, 1.04, 43), Vector2.new(18, 104), COLORS.asphalt, 0.25)
	footprint(envelopes, "Rear_Service_Apron", Vector3.new(64, 1.04, 337), Vector2.new(100, 38), COLORS.asphalt, 0.2)

	local dealerPoints = {
		Vector3.new(105, 1.3, -12), Vector3.new(105, 1.3, 35), Vector3.new(99, 1.3, 64),
		Vector3.new(72, 1.3, 64), Vector3.new(50, 1.3, 80), Vector3.new(49, 1.3, 155),
		Vector3.new(49, 1.3, 240), Vector3.new(49, 1.3, 304), Vector3.new(-34, 1.3, 304),
		Vector3.new(-34, 1.3, 240), Vector3.new(-34, 1.3, 155), Vector3.new(-34, 1.3, 100),
		Vector3.new(-5, 1.3, 78), Vector3.new(-5, 1.3, -12),
	}
	local dealer = routeModel(routes, "Dealer_Stock_Path_V2", dealerPoints, COLORS.flow, 1.5, {
		RoutePurpose = "Seller intake → treatment loop → sale handoff",
		LaneWidth = 20,
		GateWidth = 24,
		MinimumTurnRadius = 18,
		TrafficCompatible = true,
	})

	local dealerWaypoints = Instance.new("Folder")
	dealerWaypoints.Name = "DemoWaypoints"
	dealerWaypoints.Parent = dealer
	local holds = {[3] = 2.4, [6] = 1.2, [13] = 2.2}
	for index, point in dealerPoints do waypoint(dealerWaypoints, string.format("WP_%02d", index), index, point + Vector3.new(0, 1.8, 0), holds[index]) end

	local branchPoints = {
		Vector3.new(17, 1.35, 191), Vector3.new(-34, 1.35, 184), Vector3.new(-58, 1.35, 184), Vector3.new(-82, 1.35, 184),
		Vector3.new(-58, 1.35, 184), Vector3.new(-34, 1.35, 184), Vector3.new(17, 1.35, 191),
		Vector3.new(49, 1.35, 219), Vector3.new(69, 1.35, 219), Vector3.new(88, 1.35, 219),
		Vector3.new(69, 1.35, 219), Vector3.new(49, 1.35, 219), Vector3.new(17, 1.35, 191),
	}
	local branches = routeModel(routes, "Treatment_Branches_V2", branchPoints, COLORS.work, 1.25, {
		RoutePurpose = "Courtyard handoff → workshop/finish cells → courtyard",
		BayApproachWidth = 18,
		UsesReverseExit = true,
	})
	local branchWaypoints = Instance.new("Folder")
	branchWaypoints.Name = "DemoWaypoints"
	branchWaypoints.Parent = branches
	for index, point in branchPoints do
		local reverse = index == 5 or index == 6 or index == 11 or index == 12
		local hold = (index == 4 or index == 10) and 2.2 or 0
		waypoint(branchWaypoints, string.format("WP_%02d", index), index, point + Vector3.new(0, 1.8, 0), hold, reverse)
	end

	local ownerPoints = {Vector3.new(-88, 1.35, -12), Vector3.new(-88, 1.35, 24), Vector3.new(-88, 1.35, 48), Vector3.new(-88, 1.35, 76)}
	local owner = routeModel(routes, "Personal_Car_Path_V2", ownerPoints, COLORS.ownerFlow, 1.5, {
		FunctionId = "GAR", RoutePurpose = "Independent garage arrival/departure", GateWidth = 24,
	})
	owner:SetAttribute("FunctionId", "GAR")
	owner:SetAttribute("MinStep", 6)

	local towPoints = {Vector3.new(110, 1.35, 368), Vector3.new(99, 1.35, 350), Vector3.new(88, 1.35, 335), Vector3.new(49, 1.35, 315), Vector3.new(15, 1.35, 304), Vector3.new(-20, 1.35, 304)}
	local tow = routeModel(routes, "Tow_and_Parts_Path_V2", towPoints, COLORS.serviceFlow, 1.5, {
		RoutePurpose = "Rear service arrival separated from customer frontage", TransporterClearance = true,
	})
	tow:SetAttribute("FunctionId", "LOG")
	tow:SetAttribute("MinStep", 23)

	local pedestrianPoints = {Vector3.new(32, 1.4, -10), Vector3.new(32, 1.4, 75), Vector3.new(20, 1.4, 91), Vector3.new(14, 1.4, 98)}
	local pedestrian = routeModel(routes, "Customer_Walk_and_Handover_V2", pedestrianPoints, COLORS.pedestrian, 3.2, {
		RoutePurpose = "Protected customer path with one marked vehicle crossing",
	})
	pedestrian:SetAttribute("FunctionId", "OFF")
	pedestrian:SetAttribute("MinStep", 3)

	local interface = Instance.new("Folder")
	interface.Name = "Traffic_Interface_V2"
	interface.Parent = routes
	for name, data in {
		SellerEntry = {Vector3.new(105, 1.5, -12), "entry"},
		SoldExit = {Vector3.new(-5, 1.5, -12), "exit"},
		OwnerDrive = {Vector3.new(-88, 1.5, -12), "owner"},
		RearService = {Vector3.new(110, 1.5, 368), "service"},
	} do
		local node = box(interface, name, data[1] :: Vector3, Vector3.new(2, 2, 2), COLORS.flow, 1, false)
		node:SetAttribute("InterfaceType", data[2])
		node:SetAttribute("RoadGraphReady", true)
	end

	-- Bay envelopes show the actual car-plus-working-clearance reservation.
	for index, z in {136, 184, 232, 280} do addEnvelope(envelopes, "Mechanical_Bay_" .. index, Vector3.new(-82, 1.12, z), Vector2.new(30, 19), "MEC", index == 1 and 4 or (index == 2 and 16 or (index == 3 and 18 or 33)), 90) end
	for index, z in {181, 219, 255, 292} do addEnvelope(envelopes, "Finish_Cell_" .. index, Vector3.new(88, 1.12, z), Vector2.new(30, 19), "FIN", ({14,19,18,21})[index], 90) end
	for index, x in {-45, -18, 9} do addEnvelope(envelopes, "Forecourt_Front_" .. index, Vector3.new(x, 1.12, 30), Vector2.new(17, 23), "SAL", index == 1 and 3 or 8) end
	for index, x in {-45, -18, 9} do addEnvelope(envelopes, "Forecourt_Rear_" .. index, Vector3.new(x, 1.12, 57), Vector2.new(17, 23), "SAL", index == 1 and 29 or 34) end
	for index, x in {-101, -82, -63} do addEnvelope(envelopes, "Garage_Bay_" .. index, Vector3.new(x, 1.12, 38), Vector2.new(17, 25), "GAR", ({6,25,36})[index]) end
	addEnvelope(envelopes, "Intake_Pocket_1", Vector3.new(80, 1.12, 35), Vector2.new(18, 25), "INT", 1)
	addEnvelope(envelopes, "Intake_Pocket_2", Vector3.new(99, 1.12, 63), Vector2.new(18, 25), "INT", 7)
	addEnvelope(envelopes, "Courtyard_Handoff", Vector3.new(12, 1.12, 196), Vector2.new(28, 28), "YRD", 24)
	addEnvelope(envelopes, "Tow_Drop_Pocket", Vector3.new(-20, 1.12, 300), Vector2.new(20, 34), "LOG", 23)
	addEnvelope(envelopes, "Transporter_Envelope", Vector3.new(88, 1.12, 335), Vector2.new(20, 40), "MOV", 32)

	-- Lane direction arrows and safety crossings.
	for _, z in {112, 154, 244, 286} do
		box(envelopes, "EastArrow", Vector3.new(49, 1.22, z), Vector3.new(4, 0.16, 10), COLORS.white, 0.2, false, Enum.Material.Neon)
		box(envelopes, "WestArrow", Vector3.new(-34, 1.22, z), Vector3.new(4, 0.16, 10), COLORS.white, 0.2, false, Enum.Material.Neon)
	end
	for index = 1, 6 do box(envelopes, "CrossingStripe_" .. index, Vector3.new(42 + index * 2.2, 1.24, 92), Vector3.new(1.1, 0.18, 8), COLORS.pedestrian, 0.05, false, Enum.Material.Neon) end

	return dealer, branches
end

local function buildDetailedComponents(root: Model, detail: Folder)
	local function group(name: string, functionId: string, step: number): Model
		return newModel(detail, name, functionId, step, {DetailedBlockoutGroup = true})
	end

	-- INTAKE + APPRAISAL -------------------------------------------------------
	local intake = group("INT_Intake_Appraisal_Complete", "INT", 1)
	component(intake, "INT-01", "INT", 1, "We Buy Cars Sign", function(m) boardKit(m, "Sign", Vector3.new(108, 7, 8), Vector2.new(12, 5), COLORS.public, 0) end)
	component(intake, "INT-03", "INT", 1, "Folding Intake Desk", function(m) tableKit(m, "Desk", Vector3.new(105, 0.8, 18), Vector2.new(5.5, 3), COLORS.furniture, 0) box(m, "CashBox", Vector3.new(105, 4.2, 18), Vector3.new(1.5, 0.8, 1.2), COLORS.black, 0, true) end)
	component(intake, "INT-04", "INT", 1, "Seller Stool and Shade", function(m) chairKit(m, "Stool", Vector3.new(108, 0.8, 24), COLORS.structureDark, 180) box(m, "UmbrellaPost", Vector3.new(112, 4.5, 24), Vector3.new(0.35, 7, 0.35), COLORS.metal, 0, true) verticalCylinder(m, "Shade", Vector3.new(112, 8, 24), Vector3.new(0.5, 6, 6), COLORS.public, 0.05, 90) end)
	component(intake, "INT-08", "INT", 7, "Wheel Stops and Rejection Lane", function(m) for _, z in {24,48,75} do box(m, "Stop", Vector3.new(107, 1.35, z), Vector3.new(8, 0.8, 1), COLORS.safety, 0, true, Enum.Material.Concrete) end end)
	component(intake, "INT-09", "INT", 7, "Inspection Light and Tool Cart", function(m) lightRig(m, "InspectionLight", Vector3.new(75, 0.8, 64), 8, 90) machineKit(m, "RollingCart", Vector3.new(70, 0.8, 76), Vector3.new(3, 3.2, 2), COLORS.work, 90) end)
	component(intake, "INT-11", "INT", 17, "Scan Tablet", function(m) machineKit(m, "ScanTrolley", Vector3.new(108, 0.8, 69), Vector3.new(2.4, 4.5, 2.2), COLORS.metal, 0) end)
	component(intake, "INT-12", "INT", 17, "Paint Gauge and Underbody Mirrors", function(m) tableKit(m, "GaugeTable", Vector3.new(108, 0.8, 80), Vector2.new(4, 2), COLORS.metal, 0) box(m, "Mirror", Vector3.new(105, 1.1, 80), Vector3.new(2.5, 0.18, 1.8), COLORS.glass, 0.1, false, Enum.Material.Glass, 0) end)
	component(intake, "INT-13", "INT", 27, "Photo Documentation Wall", function(m) boardKit(m, "PhotoWall", Vector3.new(110.8, 7, 53), Vector2.new(9, 6), COLORS.black, 90) lightRig(m, "CameraLights", Vector3.new(101, 0.8, 54), 8, 0) end)
	component(intake, "INT-14", "INT", 27, "Appraiser Workstation", function(m) workstation(m, "AppraiserDesk", Vector3.new(102, 0.8, 82), 180, true) staffProxy(m, "Appraiser", Vector3.new(97, 0.8, 80), COLORS.public, 0) end)
	component(intake, "INT-15", "INT", 32, "Exceptional Car Pocket", function(m) footprint(m, "PremiumPocket", Vector3.new(76, 1.2, 18), Vector2.new(18, 22), COLORS.public, 0.65) box(m, "PorteCochereBand", Vector3.new(76, 11, 18), Vector3.new(20, 0.8, 24), COLORS.structureDark, 0.25, false, Enum.Material.Metal) end)
	component(intake, "INT-16", "INT", 32, "Controlled Appraisal Cameras", function(m) for _, p in {Vector3.new(68,10,12),Vector3.new(110,10,12),Vector3.new(68,10,82),Vector3.new(110,10,82)} do box(m, "Camera", p, Vector3.new(1.2, 0.8, 1.8), COLORS.black, 0, false) end end)

	-- SALES FORECOURT ----------------------------------------------------------
	local sales = group("SAL_Grand_Forecourt_Complete", "SAL", 3)
	local salePositions = {Vector3.new(-45,0.8,30),Vector3.new(-18,0.8,30),Vector3.new(9,0.8,30),Vector3.new(-45,0.8,57),Vector3.new(-18,0.8,57),Vector3.new(9,0.8,57)}
	for index, p in salePositions do
		component(sales, string.format("SAL-%02d", ({1,4,5,12,15,16})[index]), "SAL", ({3,8,8,29,34,34})[index], "Display Position " .. index, function(m)
			box(m, "WheelStop", p + Vector3.new(0, 0.55, 9), Vector3.new(8, 0.8, 1), COLORS.curb, 0, true, Enum.Material.Concrete)
			box(m, "PricePlinth", p + Vector3.new(6, 2.1, -7), Vector3.new(1.3, 3.4, 1.3), COLORS.black, 0, true)
			box(m, "PriceScreen", p + Vector3.new(6, 3.3, -7.7), Vector3.new(1.05, 1.25, 0.08), COLORS.public, 0, false, Enum.Material.Neon)
		end)
	end
	component(sales, "SAL-03", "SAL", 3, "Buyer Bench and Shade", function(m) tableKit(m, "Bench", Vector3.new(19, 0.8, 67), Vector2.new(7, 2.4), COLORS.wood, 90) box(m, "ShadePost", Vector3.new(17, 5, 67), Vector3.new(0.4, 8, 0.4), COLORS.metal, 0, true) verticalCylinder(m, "Shade", Vector3.new(17, 9, 67), Vector3.new(0.5, 7, 7), COLORS.public, 0.1, 90) end)
	component(sales, "SAL-07", "SAL", 8, "Pedestrian Curb", function(m) box(m, "RearCurbLeft", Vector3.new(-35, 1.35, 77), Vector3.new(38, 0.8, 1.5), COLORS.curb, 0, true, Enum.Material.Concrete) box(m, "RearCurbRight", Vector3.new(12, 1.35, 77), Vector3.new(24, 0.8, 1.5), COLORS.curb, 0, true, Enum.Material.Concrete) end)
	component(sales, "SAL-08", "SAL", 13, "Forecourt Lights", function(m) for _, x in {-50,-15,20} do box(m, "Pole", Vector3.new(x, 6, 76), Vector3.new(0.5, 11, 0.5), COLORS.metal, 0, true, Enum.Material.Metal) box(m, "Lamp", Vector3.new(x, 11.5, 75), Vector3.new(2.5, 0.8, 1.2), COLORS.light, 0.05, false, Enum.Material.Neon) end end)
	component(sales, "SAL-09", "SAL", 11, "Sales Podium", function(m) box(m, "Podium", Vector3.new(19, 2.5, 18), Vector3.new(4, 4.5, 3), COLORS.furniture, 0, true, Enum.Material.Wood) cabinetKit(m, "KeyCabinet", Vector3.new(16, 0.8, 12), Vector3.new(3, 5, 1.3), COLORS.structureDark, 0) staffProxy(m, "SalesRep", Vector3.new(13, 0.8, 18), COLORS.public, 0) end)
	component(sales, "SAL-10", "SAL", 18, "Listing Photo Station", function(m) boardKit(m, "Backdrop", Vector3.new(-51, 5, 68), Vector2.new(12, 8), COLORS.structureDark, 0) lightRig(m, "TripodLights", Vector3.new(-42, 0.8, 67), 8, 90) end)
	component(sales, "SAL-11", "SAL", 18, "Sold Handoff Mat", function(m) footprint(m, "HandoffMat", Vector3.new(-5, 1.22, 73), Vector2.new(18, 10), COLORS.public, 0.22) end)
	component(sales, "SAL-13", "SAL", 29, "Protective Bollards", function(m) for _, p in {Vector3.new(-53,0,8),Vector3.new(23,0,8),Vector3.new(-53,0,77),Vector3.new(23,0,77)} do verticalCylinder(m, "Bollard", p + Vector3.new(0,2,0), Vector3.new(4,1.2,1.2), COLORS.safety, 0, 90) end end)
	component(sales, "SAL-14", "SAL", 29, "Desert Planting", function(m) for _, p in {Vector3.new(-52,0,16),Vector3.new(20,0,25),Vector3.new(-52,0,70)} do verticalCylinder(m, "Planter", p + Vector3.new(0,1,0), Vector3.new(2,4,4), COLORS.furniture, 0, 90) box(m, "Plant", p + Vector3.new(0,3,0), Vector3.new(1.2,4,1.2), COLORS.clean, 0, false) end end)

	-- COLLECTOR HALL, DEAL OFFICE, ACQUISITION AND OPS ------------------------
	local office = group("OFF_ACQ_OPS_Collector_Hall_Complete", "OFF", 1)
	component(office, "OFF-01", "OFF", 1, "Heritage Deal Desk", function(m) tableKit(m, "OriginalDesk", Vector3.new(7, 0.8, 103), Vector2.new(6, 3), COLORS.furniture, 0) box(m, "CashBox", Vector3.new(7, 4.2, 103), Vector3.new(1.5, 0.8, 1.1), COLORS.black, 0, true) end)
	component(office, "OFF-06", "OFF", 10, "Sales Workstation", function(m) workstation(m, "SalesDesk", Vector3.new(25, 0.8, 105), 180, false) end)
	component(office, "OFF-08", "OFF", 10, "Customer Chair", function(m) chairKit(m, "CustomerChair", Vector3.new(25, 0.8, 112), Color3.fromRGB(94,76,60), 0) end)
	component(office, "OFF-10", "OFF", 10, "Printer and Deal Screen", function(m) machineKit(m, "Printer", Vector3.new(33, 0.8, 111), Vector3.new(2.5, 2.2, 2.2), COLORS.structureDark, 0) boardKit(m, "DealScreen", Vector3.new(34, 7, 116), Vector2.new(7, 4), COLORS.black, 90) end)
	component(office, "OFF-11", "OFF", 17, "Filing and Scanner", function(m) cabinetKit(m, "Files", Vector3.new(-5, 0.8, 116), Vector3.new(4, 6, 2), COLORS.structureDark, 90) machineKit(m, "Scanner", Vector3.new(-3, 0.8, 111), Vector3.new(2.5, 2, 2), COLORS.metal, 0) end)
	component(office, "OFF-12", "OFF", 17, "Water and Climate", function(m) verticalCylinder(m, "WaterCooler", Vector3.new(33, 3, 119), Vector3.new(5,2.5,2.5), COLORS.glass, 0.15, 90) box(m, "ACUnit", Vector3.new(-5, 8, 120), Vector3.new(4, 2.5, 1.5), COLORS.white, 0, true, Enum.Material.Metal, 90) end)
	component(office, "OFF-13", "OFF", 29, "Waiting Sofa and Coffee", function(m) box(m, "SofaSeat", Vector3.new(3, 2, 118), Vector3.new(9, 2, 3.5), Color3.fromRGB(104,69,50), 0, true, Enum.Material.Fabric) box(m, "SofaBack", Vector3.new(3, 3.5, 120), Vector3.new(9, 3, 0.8), Color3.fromRGB(104,69,50), 0, true, Enum.Material.Fabric) tableKit(m, "Coffee", Vector3.new(3, 0.8, 112), Vector2.new(4,3), COLORS.wood, 0) end)
	component(office, "OFF-14", "OFF", 29, "Private Consultation", function(m) tableKit(m, "ConsultationTable", Vector3.new(12, 0.8, 134), Vector2.new(8,4), COLORS.wood, 0) chairKit(m, "ChairA", Vector3.new(12,0.8,130), Color3.fromRGB(86,58,43), 180) chairKit(m, "ChairB", Vector3.new(12,0.8,139), Color3.fromRGB(86,58,43), 0) end)
	component(office, "OFF-16", "OFF", 34, "Material Library and Gallery", function(m) shelfKit(m, "MaterialLibrary", Vector3.new(-5, 15.6, 136), 10, 6, 90, COLORS.wood) boardKit(m, "GalleryWall", Vector3.new(14, 19, 145), Vector2.new(20, 6), COLORS.furniture, 0) end)

	component(office, "ACQ-01", "OFF", 1, "Contact Pencil Board", function(m) boardKit(m, "ContactBoard", Vector3.new(-5, 6, 102), Vector2.new(7,5), COLORS.furniture, 90) end)
	component(office, "ACQ-02", "OFF", 1, "Roadside Telephone", function(m) box(m, "Telephone", Vector3.new(3,4.1,103), Vector3.new(1.8,0.6,1.4), COLORS.black, 0, true) end)
	component(office, "ACQ-03", "OFF", 10, "Vehicle Record Box", function(m) box(m, "RecordBox", Vector3.new(11,4.1,103), Vector3.new(2.2,1.1,1.6), COLORS.structureDark, 0, true, Enum.Material.Metal) end)
	component(office, "ACQ-05", "OFF", 10, "Seller Database Computer", function(m) workstation(m, "SourcingComputer", Vector3.new(26,0.8,128), 90, false) end)
	component(office, "ACQ-06", "OFF", 17, "County Sourcing Map", function(m) boardKit(m, "CountyMap", Vector3.new(1,7,146), Vector2.new(10,6), COLORS.public, 0) end)
	component(office, "ACQ-07", "OFF", 17, "Sourcer Desk", function(m) workstation(m, "SourcerDesk", Vector3.new(26,0.8,139), 90, true) staffProxy(m, "Sourcer", Vector3.new(21,0.8,139), COLORS.public, 90) end)
	component(office, "ACQ-09", "OFF", 27, "Provenance Archive", function(m) shelfKit(m, "Archive", Vector3.new(-5,0.8,138), 8, 8, 90, COLORS.furniture) machineKit(m, "DocumentScanner", Vector3.new(1,0.8,138), Vector3.new(3,2.5,2.5), COLORS.metal, 90) end)
	component(office, "ACQ-10", "OFF", 27, "Key and Title Safe", function(m) cabinetKit(m, "Safe", Vector3.new(34,0.8,140), Vector3.new(4,7,3), COLORS.black, 90) end)
	component(office, "ACQ-11", "OFF", 32, "Regional Auction Terminal", function(m) workstation(m, "AuctionTerminal", Vector3.new(25,15.6,136), 180, true) end)

	component(office, "OPS-01", "OFF", 10, "Staff Check In and Key Hooks", function(m) boardKit(m, "CheckIn", Vector3.new(-5,7,126), Vector2.new(7,5), COLORS.work, 90) end)
	component(office, "OPS-03", "OFF", 13, "Radio Charging Shelf", function(m) shelfKit(m, "RadioShelf", Vector3.new(34,0.8,124), 5, 5, 90, COLORS.metal) end)
	component(office, "OPS-04", "OFF", 17, "Staff Lockers", function(m) for index=1,4 do cabinetKit(m, "Locker"..index, Vector3.new(-5 + index*3.5,15.6,126), Vector3.new(3,7,2), COLORS.structureDark, 0) end end)
	component(office, "OPS-05", "OFF", 17, "Staff Break Table", function(m) tableKit(m, "BreakTable", Vector3.new(3,15.6,136), Vector2.new(7,4), COLORS.furniture, 0) chairKit(m, "BreakChairA", Vector3.new(3,15.6,131), COLORS.structureDark, 180) chairKit(m, "BreakChairB", Vector3.new(3,15.6,141), COLORS.structureDark, 0) end)
	component(office, "OPS-06", "OFF", 17, "Queue Whiteboard", function(m) boardKit(m, "QueueBoard", Vector3.new(14,19,123), Vector2.new(10,5), COLORS.white, 0) end)
	component(office, "OPS-07", "OFF", 30, "Dispatch Desk", function(m) workstation(m, "DispatchDesk", Vector3.new(14,15.6,133), 0, true) end)
	component(office, "OPS-09", "OFF", 30, "Policy Board", function(m) boardKit(m, "PolicyBoard", Vector3.new(24,19,145), Vector2.new(11,5), COLORS.public, 0) end)
	component(office, "OPS-10", "OFF", 30, "Camera Status Wall", function(m) for index=1,4 do box(m,"StatusScreen"..index,Vector3.new(4+index*6,20,123),Vector3.new(5,3.2,0.25),COLORS.glass,0.05,false,Enum.Material.Neon) end end)
	component(office, "OPS-11", "OFF", 30, "Manager Station", function(m) workstation(m, "ManagerDesk", Vector3.new(28,15.6,142), 90, true) staffProxy(m, "OperationsManager", Vector3.new(24,15.6,142), COLORS.public, 90) end)

	-- MECHANICAL + BODY RESTORATION -------------------------------------------
	local mechanical = group("MEC_BDY_Restoration_Hall_Complete", "MEC", 2)
	for _, name in {"Lift_1","Lift_2","Lift_3","Lift_4","WorkCar"} do
		local existing = root["04_Equipment_and_Car_Scale"]:FindFirstChild(name)
		if existing and existing:IsA("Model") then
			local position = existing:GetPivot().Position
			existing:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0))
		end
	end
	carKit(mechanical, "MechanicalCar_Bay1", Vector3.new(-82,0.8,136), Color3.fromRGB(192,132,48), 90)
	carKit(mechanical, "BodyCar_Bay3", Vector3.new(-82,0.8,232), Color3.fromRGB(146,69,54), 90)
	carKit(mechanical, "RareRestorationCar_Bay4", Vector3.new(-82,0.8,280), Color3.fromRGB(70,118,102), 90)
	component(mechanical, "MEC-02", "MEC", 2, "Jack Stands and Chocks", function(m) machineKit(m,"FloorJack",Vector3.new(-104,0.8,121),Vector3.new(5,1.4,2.2),COLORS.work,90) for _,x in {-98,-92} do box(m,"Stand",Vector3.new(x,1.6,121),Vector3.new(1.3,1.8,1.3),COLORS.metal,0,true) end end)
	component(mechanical, "MEC-03", "MEC", 2, "Battered Toolbox and Work Lamp", function(m) cabinetKit(m,"Toolbox",Vector3.new(-109,0.8,143),Vector3.new(5,5,2.2),COLORS.work,90) lightRig(m,"PortableLamp",Vector3.new(-102,0.8,143),4,0) end)
	component(mechanical, "MEC-06", "MEC", 4, "Mechanic Workbench Locker Stool", function(m) tableKit(m,"Workbench",Vector3.new(-108,0.8,148),Vector2.new(11,3),COLORS.wood,0) cabinetKit(m,"Locker",Vector3.new(-111,0.8,137),Vector3.new(3,7,2),COLORS.structureDark,0) chairKit(m,"Stool",Vector3.new(-103,0.8,145),COLORS.structureDark,90) staffProxy(m,"Mechanic",Vector3.new(-99,0.8,133),COLORS.work,90) end)
	component(mechanical, "MEC-08", "MEC", 4, "Air Compressor and Reel", function(m) cylinder(m,"Compressor",Vector3.new(-110,3,162),Vector3.new(5,3,3),COLORS.work,0,90) cylinder(m,"Reel",Vector3.new(-113,7,165),Vector3.new(1,2.5,2.5),COLORS.metal,0,0) end)
	component(mechanical, "MEC-09", "MEC", 4, "Tire Changer", function(m) machineKit(m,"TireChanger",Vector3.new(-109,0.8,174),Vector3.new(4,5,4),COLORS.metal,0) end)
	component(mechanical, "MEC-10", "MEC", 4, "Wheel Balancer", function(m) machineKit(m,"WheelBalancer",Vector3.new(-109,0.8,190),Vector3.new(4,4.5,4),COLORS.metal,0) end)
	component(mechanical, "MEC-11", "MEC", 17, "Tool Cabinets Parts Rack Job Bins", function(m) cabinetKit(m,"ToolCabinet",Vector3.new(-109,0.8,199),Vector3.new(7,6,2.2),COLORS.work,0) shelfKit(m,"PartsRack",Vector3.new(-108,0.8,208),9,8,0,COLORS.metal) end)
	component(mechanical, "MEC-12", "MEC", 17, "Diagnostic Cart", function(m) machineKit(m,"DiagnosticCart",Vector3.new(-103,0.8,191),Vector3.new(3,5,2.5),COLORS.metal,90) lightRig(m,"UnderbodyLights",Vector3.new(-82,0.8,184),18,90) end)
	component(mechanical, "MEC-15", "MEC", 16, "Second Mechanic Station", function(m) tableKit(m,"Bench",Vector3.new(-108,0.8,196),Vector2.new(10,3),COLORS.wood,0) staffProxy(m,"Mechanic2",Vector3.new(-101,0.8,181),COLORS.work,90) end)
	component(mechanical, "MEC-16", "MEC", 17, "Alignment Rack", function(m) for _,z in {224,240} do box(m,"AlignmentRail",Vector3.new(-82,1.6,z),Vector3.new(24,1.2,2),COLORS.metal,0,true,Enum.Material.Metal,90) end end)
	component(mechanical, "MEC-17", "MEC", 26, "Overhead Utility Grid", function(m) for _,z in {136,184,232,280} do box(m,"LEDBar",Vector3.new(-82,12,z),Vector3.new(28,0.35,1),COLORS.light,0.05,false,Enum.Material.Neon,90) end box(m,"AirLine",Vector3.new(-108,11,210),Vector3.new(1,1,190),COLORS.flow,0.1,false,Enum.Material.Metal) end)
	component(mechanical, "MEC-19", "MEC", 26, "Master Diagnostic QC", function(m) workstation(m,"MasterTerminal",Vector3.new(-107,0.8,260),0,true) boardKit(m,"QCWall",Vector3.new(-113,8,270),Vector2.new(12,7),COLORS.black,90) end)

	component(mechanical, "BDY-02", "MEC", 18, "Panel Rack", function(m) shelfKit(m,"PanelRack",Vector3.new(-108,0.8,217),11,8,0,COLORS.work) end)
	component(mechanical, "BDY-03", "MEC", 18, "Welding Station", function(m) machineKit(m,"Welder",Vector3.new(-108,0.8,230),Vector3.new(4,5,3),COLORS.work,0) end)
	component(mechanical, "BDY-04", "MEC", 18, "Extraction Curtain", function(m) box(m,"Curtain",Vector3.new(-50,7,254),Vector3.new(1,12,42),COLORS.clean,0.58,false,Enum.Material.Fabric) end)
	component(mechanical, "BDY-05", "MEC", 18, "Frame Bench", function(m) for _,z in {228,236} do box(m,"BenchRail",Vector3.new(-82,1.7,z),Vector3.new(28,1.3,2),COLORS.metal,0,true,Enum.Material.DiamondPlate,90) end end)
	component(mechanical, "BDY-06", "MEC", 18, "Dent and Hammer Tool Wall", function(m) boardKit(m,"ToolWall",Vector3.new(-113,7,244),Vector2.new(14,7),COLORS.work,90) end)
	component(mechanical, "BDY-07", "MEC", 18, "Restoration Workbench", function(m) tableKit(m,"RestorationBench",Vector3.new(-108,0.8,249),Vector2.new(11,3),COLORS.wood,0) cabinetKit(m,"LockableChest",Vector3.new(-101,0.8,249),Vector3.new(4,5,2.2),COLORS.work,0) staffProxy(m,"RestorationSpecialist",Vector3.new(-101,0.8,232),COLORS.work,90) end)
	component(mechanical, "BDY-09", "MEC", 26, "Precision Jig and Rotisserie", function(m) for _,x in {-96,-68} do box(m,"RotisserieStand",Vector3.new(x,4,280),Vector3.new(1.5,7,4),COLORS.metal,0,true,Enum.Material.Metal) end box(m,"RotisserieBeam",Vector3.new(-82,6,280),Vector3.new(28,1,1),COLORS.metal,0,true,Enum.Material.Metal) end)
	component(mechanical, "BDY-11", "MEC", 26, "Fabrication Bench and Inspection Wall", function(m) tableKit(m,"FabricationBench",Vector3.new(-108,0.8,294),Vector2.new(12,3.5),COLORS.metal,0) lightRig(m,"PanelInspection",Vector3.new(-107,0.8,304),8,0) end)
	component(mechanical, "BDY-12", "MEC", 33, "Rare Restoration Cell", function(m) box(m,"SecureGlass",Vector3.new(-49,7,280),Vector3.new(1,12,36),COLORS.glass,0.55,false,Enum.Material.Glass) boardKit(m,"RareBuildRecord",Vector3.new(-113,7,282),Vector2.new(12,7),COLORS.furniture,90) end)

	-- FINISH: DETAIL, PAINT, CUSTOMIZATION, PERFORMANCE ------------------------
	local finish = group("FIN_Detail_Paint_Custom_Performance_Complete", "FIN", 14)
	for _, name in {"DetailRig","FinishCar","PaintBooth","Dyno"} do
		local existing = root["04_Equipment_and_Car_Scale"]:FindFirstChild(name)
		if existing and existing:IsA("Model") then local position=existing:GetPivot().Position existing:PivotTo(CFrame.new(position)*CFrame.Angles(0,math.rad(90),0)) end
	end
	local customBench = root["04_Equipment_and_Car_Scale"]:FindFirstChild("CustomBench")
	if customBench and customBench:IsA("Model") then customBench:PivotTo(CFrame.new(106,3.2,255)) end
	carKit(finish,"PaintCar",Vector3.new(88,0.8,219),Color3.fromRGB(165,165,172),90)
	carKit(finish,"CustomizationCar",Vector3.new(88,0.8,255),Color3.fromRGB(112,67,159),90)
	carKit(finish,"PerformanceCar",Vector3.new(88,0.8,292),Color3.fromRGB(49,100,150),90)
	component(finish,"DET-01","FIN",14,"Drained Wash Slab",function(m) for _,z in {174,188} do box(m,"Drain",Vector3.new(88,1.28,z),Vector3.new(28,0.18,1.2),COLORS.black,0,false,Enum.Material.Metal,90) end end)
	component(finish,"DET-02","FIN",14,"Pressure Washer and Hose Reel",function(m) machineKit(m,"PressureWasher",Vector3.new(108,0.8,173),Vector3.new(3,4,3),COLORS.clean,0) cylinder(m,"HoseReel",Vector3.new(111,6,178),Vector3.new(1,3,3),COLORS.clean,0,0) end)
	component(finish,"DET-03","FIN",14,"Vacuum and Detail Cart",function(m) verticalCylinder(m,"Vacuum",Vector3.new(108,3,187),Vector3.new(5,3,3),COLORS.metal,0,90) machineKit(m,"DetailCart",Vector3.new(105,0.8,194),Vector3.new(3,3.5,2.5),COLORS.clean,0) end)
	component(finish,"DET-05","FIN",14,"Chemical Shelf and Towels",function(m) shelfKit(m,"ChemicalShelf",Vector3.new(109,0.8,197),8,7,0,COLORS.clean) end)
	component(finish,"DET-06","FIN",14,"Finish Inspection Lights",function(m) lightRig(m,"InspectionRig",Vector3.new(88,0.8,181),28,90) end)
	component(finish,"DET-07","FIN",15,"Detailer Station",function(m) cabinetKit(m,"Locker",Vector3.new(109,0.8,166),Vector3.new(3,7,2),COLORS.structureDark,0) staffProxy(m,"Detailer",Vector3.new(103,0.8,181),COLORS.clean,90) end)
	component(finish,"DET-08","FIN",15,"Fan Dryer",function(m) for _,x in {70,106} do cylinder(m,"DryerFan",Vector3.new(x,5.5,193),Vector3.new(1,5,5),COLORS.metal,0,0) end end)
	component(finish,"DET-09","FIN",15,"Polish Station",function(m) tableKit(m,"PolishBench",Vector3.new(107,0.8,185),Vector2.new(7,3),COLORS.metal,0) end)
	component(finish,"DET-10","FIN",26,"Steam Extractor",function(m) machineKit(m,"SteamExtractor",Vector3.new(105,0.8,177),Vector3.new(3,4,3),COLORS.clean,0) end)

	component(finish,"PNT-02","FIN",19,"Fire Rated Paint Booth",function(m) box(m,"RearWall",Vector3.new(108,7,219),Vector3.new(1,12,30),COLORS.clean,0.35,true,Enum.Material.Metal) box(m,"FrontHeader",Vector3.new(66,12,219),Vector3.new(1,3,30),COLORS.clean,0.25,false,Enum.Material.Metal) box(m,"Ceiling",Vector3.new(88,13,219),Vector3.new(44,0.8,32),COLORS.clean,0.65,false,Enum.Material.Metal) end)
	component(finish,"PNT-03","FIN",19,"Observation Window",function(m) box(m,"Window",Vector3.new(108.6,7,219),Vector3.new(0.2,6,12),COLORS.glass,0.35,false,Enum.Material.Glass) end)
	component(finish,"PNT-04","FIN",19,"Filter Bank and Ventilation",function(m) for _,z in {210,219,228} do box(m,"Filter",Vector3.new(109,7,z),Vector3.new(1,5,6),COLORS.white,0.15,true,Enum.Material.Metal) end box(m,"Duct",Vector3.new(100,14,219),Vector3.new(12,1.5,4),COLORS.metal,0,false,Enum.Material.Metal,90) end)
	component(finish,"PNT-05","FIN",19,"Booth Light Grid",function(m) for _,z in {208,218,228} do box(m,"Light",Vector3.new(88,11.5,z),Vector3.new(26,0.3,0.8),COLORS.light,0.05,false,Enum.Material.Neon,90) end end)
	component(finish,"PNT-06","FIN",19,"Booth Control Panel",function(m) machineKit(m,"ControlPanel",Vector3.new(68,0.8,233),Vector3.new(2.5,5,1.8),COLORS.metal,90) end)
	component(finish,"PNT-07","FIN",19,"Mixing Bench and Color Wall",function(m) tableKit(m,"MixBench",Vector3.new(106,0.8,235),Vector2.new(10,3),COLORS.metal,0) boardKit(m,"ColorWall",Vector3.new(111,7,233),Vector2.new(13,7),COLORS.public,90) end)
	component(finish,"PNT-09","FIN",20,"Paint Specialist PPE",function(m) cabinetKit(m,"PPELocker",Vector3.new(108,0.8,204),Vector3.new(3,7,2),COLORS.safety,0) staffProxy(m,"PaintSpecialist",Vector3.new(102,0.8,219),COLORS.clean,90) end)
	component(finish,"PNT-10","FIN",26,"Cure Lamps",function(m) lightRig(m,"CureRig",Vector3.new(88,0.8,219),24,90) end)

	component(finish,"CUS-01","FIN",18,"Wheel Display Rack",function(m) shelfKit(m,"WheelRack",Vector3.new(109,0.8,245),10,8,0,COLORS.structureDark) for _,z in {242,246,250} do cylinder(m,"Wheel",Vector3.new(108,4,z),Vector3.new(1.5,4,4),COLORS.black,0,0) end end)
	component(finish,"CUS-02","FIN",18,"Fitment Stand",function(m) for _,x in {78,98} do box(m,"LowLift",Vector3.new(x,1.6,255),Vector3.new(8,1.2,3),COLORS.metal,0,true,Enum.Material.Metal,90) end end)
	component(finish,"CUS-03","FIN",18,"Body Kit Stands",function(m) shelfKit(m,"BodyKitRack",Vector3.new(109,0.8,262),10,8,0,COLORS.work) end)
	component(finish,"CUS-05","FIN",18,"Tint Cutting Table",function(m) tableKit(m,"TintTable",Vector3.new(106,0.8,268),Vector2.new(11,4),COLORS.metal,0) boardKit(m,"TintSamples",Vector3.new(111,7,267),Vector2.new(9,6),COLORS.glass,90) end)
	component(finish,"CUS-06","FIN",18,"Vinyl Prep and Roll Storage",function(m) shelfKit(m,"VinylRolls",Vector3.new(68,0.8,266),8,7,0,COLORS.public) end)
	component(finish,"CUS-07","FIN",18,"Electrical Neon Bench",function(m) tableKit(m,"ElectricalBench",Vector3.new(69,0.8,244),Vector2.new(9,3),COLORS.structureDark,0) box(m,"NeonSample",Vector3.new(69,5,242),Vector3.new(7,0.25,0.25),COLORS.ownerFlow,0,false,Enum.Material.Neon) end)
	component(finish,"CUS-08","FIN",22,"Customization Specialist",function(m) staffProxy(m,"CustomizationSpecialist",Vector3.new(101,0.8,255),COLORS.clean,90) end)
	component(finish,"CUS-09","FIN",26,"Digital Configurator",function(m) workstation(m,"Configurator",Vector3.new(69,0.8,260),0,true) end)

	component(finish,"PRF-01","FIN",21,"Dyno Safety Barrier",function(m) for _,z in {280,304} do box(m,"Barrier",Vector3.new(66,3,z),Vector3.new(1,4,12),COLORS.safety,0.2,true,Enum.Material.Metal) end end)
	component(finish,"PRF-03","FIN",21,"Cooling Fans and Exhaust",function(m) for _,z in {286,298} do cylinder(m,"CoolingFan",Vector3.new(108,5,z),Vector3.new(1.2,6,6),COLORS.metal,0,0) end box(m,"ExhaustDuct",Vector3.new(104,12,292),Vector3.new(16,1.5,3),COLORS.metal,0,false,Enum.Material.Metal,90) end)
	component(finish,"PRF-04","FIN",21,"Tuning Terminal",function(m) workstation(m,"TuningTerminal",Vector3.new(106,0.8,281),90,false) end)
	component(finish,"PRF-06","FIN",21,"Performance Workbench",function(m) tableKit(m,"PerformanceBench",Vector3.new(107,0.8,306),Vector2.new(10,3),COLORS.metal,0) cabinetKit(m,"ToolChest",Vector3.new(100,0.8,306),Vector3.new(4,5,2),COLORS.work,0) end)
	component(finish,"PRF-07","FIN",21,"Performance Parts Display",function(m) shelfKit(m,"PerformanceParts",Vector3.new(69,0.8,306),10,8,0,COLORS.structureDark) end)
	component(finish,"PRF-08","FIN",22,"Performance Technician",function(m) staffProxy(m,"PerformanceTech",Vector3.new(101,0.8,292),COLORS.clean,90) end)
	component(finish,"PRF-10","FIN",26,"Telemetry Wall",function(m) for index=1,3 do box(m,"TelemetryScreen"..index,Vector3.new(72+index*9,8,309),Vector3.new(7,4,0.25),COLORS.glass,0.05,false,Enum.Material.Neon) end end)

	-- OWNER GARAGE -------------------------------------------------------------
	local garage = group("GAR_Owner_Gallery_Complete", "GAR", 6)
	component(garage,"GAR-04","GAR",6,"Jack Toolbox and Radio",function(m) machineKit(m,"Jack",Vector3.new(-110,0.8,60),Vector3.new(5,1.5,2),COLORS.work,90) cabinetKit(m,"Toolbox",Vector3.new(-110,0.8,70),Vector3.new(5,5,2),COLORS.work,0) box(m,"Radio",Vector3.new(-110,4,66),Vector3.new(2.5,1.5,1.5),COLORS.black,0,true) end)
	component(garage,"GAR-05","GAR",6,"Color Samples and Wheel Rack",function(m) boardKit(m,"ColorSamples",Vector3.new(-113,7,57),Vector2.new(10,6),COLORS.public,90) shelfKit(m,"StarterWheels",Vector3.new(-108,0.8,83),9,8,0,COLORS.structureDark) end)
	component(garage,"GAR-08","GAR",25,"Professional Workbench",function(m) tableKit(m,"Workbench",Vector3.new(-104,0.8,80),Vector2.new(12,3.5),COLORS.wood,0) cabinetKit(m,"Chest",Vector3.new(-112,0.8,80),Vector3.new(5,6,2.5),COLORS.work,0) end)
	component(garage,"GAR-10","GAR",25,"Storage Lift and Parts Wall",function(m) for _,x in {-88,-76} do box(m,"LiftPost",Vector3.new(x,5,69),Vector3.new(1,9,1),COLORS.metal,0,true,Enum.Material.Metal) end box(m,"LiftDeck",Vector3.new(-82,7,69),Vector3.new(14,0.8,8),COLORS.metal,0.1,true,Enum.Material.DiamondPlate) shelfKit(m,"PartsWall",Vector3.new(-90,0.8,82),12,8,0,COLORS.structureDark) end)
	component(garage,"GAR-11","GAR",25,"Garage Configuration Terminal",function(m) workstation(m,"ConfigTerminal",Vector3.new(-72,0.8,80),0,true) end)
	component(garage,"GAR-12","GAR",26,"Display Light Grid",function(m) for _,x in {-101,-82,-63} do box(m,"DisplayLight",Vector3.new(x,13,38),Vector3.new(12,0.35,1),COLORS.light,0.05,false,Enum.Material.Neon) end box(m,"CourtyardGlass",Vector3.new(-59,8,70),Vector3.new(1,12,24),COLORS.glass,0.55,false,Enum.Material.Glass) end)
	component(garage,"GAR-13","GAR",29,"Trophy Best Time Wall",function(m) tableKit(m,"TrophyShelf",Vector3.new(-72,0.8,72),Vector2.new(10,2.5),COLORS.wood,0) boardKit(m,"BestTimes",Vector3.new(-74,8,86),Vector2.new(15,7),COLORS.black,0) for _,x in {-77,-73,-69} do verticalCylinder(m,"Trophy",Vector3.new(x,5.2,72),Vector3.new(2,1.3,1.3),COLORS.public,0,90) end end)
	component(garage,"GAR-14","GAR",36,"Photo Turntable",function(m) verticalCylinder(m,"Turntable",Vector3.new(-63,1.3,63),Vector3.new(0.8,18,18),COLORS.structureDark,0,90) lightRig(m,"PhotoLights",Vector3.new(-63,0.8,63),20,0) end)
	component(garage,"GAR-15","GAR",36,"Owner Lounge",function(m) box(m,"LoungeSeat",Vector3.new(-105,2,72),Vector3.new(8,2,4),Color3.fromRGB(95,61,44),0,true,Enum.Material.Fabric) box(m,"LoungeBack",Vector3.new(-105,3.5,74),Vector3.new(8,3,0.8),Color3.fromRGB(95,61,44),0,true,Enum.Material.Fabric) tableKit(m,"SideTable",Vector3.new(-99,0.8,73),Vector2.new(3,3),COLORS.wood,0) end)
	component(garage,"GAR-16","GAR",36,"Legacy Archive",function(m) shelfKit(m,"Archive",Vector3.new(-88,0.8,84),14,8,0,COLORS.wood) boardKit(m,"FirstSign",Vector3.new(-88,9,86),Vector2.new(13,5),COLORS.furniture,0) box(m,"FirstJack",Vector3.new(-83,2,82),Vector3.new(4,1.3,2),COLORS.work,0,true) end)

	-- COURTYARD / HANDOFF ------------------------------------------------------
	local yard = group("YRD_Reveal_Courtyard_Complete", "YRD", 9)
	component(yard,"YRD-02","YRD",9,"Key Board and Route Hooks",function(m) boardKit(m,"KeyBoard",Vector3.new(-10,7,216),Vector2.new(9,6),COLORS.work,0) end)
	component(yard,"YRD-03","YRD",9,"Porter Shelter Station",function(m) box(m,"ShelterRoof",Vector3.new(-14,9,166),Vector3.new(14,0.8,10),COLORS.structureDark,0.2,false,Enum.Material.Metal) chairKit(m,"Stool",Vector3.new(-14,0.8,166),COLORS.structureDark,0) shelfKit(m,"RadioHooks",Vector3.new(-20,0.8,166),5,5,90,COLORS.metal) staffProxy(m,"Porter",Vector3.new(-8,0.8,166),COLORS.public,90) end)
	component(yard,"YRD-05","YRD",24,"Protected Island Curb",function(m) box(m,"NorthCurb",Vector3.new(12,1.5,173),Vector3.new(54,0.8,1.5),COLORS.curb,0,true,Enum.Material.Concrete) box(m,"SouthCurb",Vector3.new(12,1.5,219),Vector3.new(54,0.8,1.5),COLORS.curb,0,true,Enum.Material.Concrete) box(m,"WestCurb",Vector3.new(-15,1.5,196),Vector3.new(1.5,0.8,46),COLORS.curb,0,true,Enum.Material.Concrete) box(m,"EastCurb",Vector3.new(39,1.5,196),Vector3.new(1.5,0.8,46),COLORS.curb,0,true,Enum.Material.Concrete) end)
	component(yard,"YRD-07","YRD",24,"Treatment Plan Mat",function(m) footprint(m,"PlanMat",Vector3.new(12,1.28,196),Vector2.new(26,26),COLORS.public,0.28) lightRig(m,"InspectionBar",Vector3.new(12,0.8,196),28,0) end)
	component(yard,"YRD-08","YRD",29,"Queue Board and Photo Rig",function(m) boardKit(m,"QueueStatus",Vector3.new(36,7,176),Vector2.new(10,7),COLORS.black,90) lightRig(m,"PhotoRig",Vector3.new(12,0.8,196),32,90) end)
	component(yard,"YRD-09","YRD",35,"Integrated Turntable",function(m) verticalCylinder(m,"Turntable",Vector3.new(12,1.45,196),Vector3.new(0.8,24,24),COLORS.structureDark,0.12,90) end)
	component(yard,"YRD-10","YRD",35,"Audience Points",function(m) for index,p in {Vector3.new(-8,0.8,216),Vector3.new(2,0.8,216),Vector3.new(22,0.8,216),Vector3.new(32,0.8,216)} do box(m,"AudiencePoint"..index,p+Vector3.new(0,0.4,0),Vector3.new(5,0.5,3),COLORS.public,0.35,false) end end)

	-- LOGISTICS / TOW / PARTS -------------------------------------------------
	local logistics = group("LOG_Parts_Tow_Transport_Complete", "LOG", 1)
	component(logistics,"LOG-01","LOG",1,"Scrap Bin",function(m) box(m,"Bin",Vector3.new(-112,3,321),Vector3.new(8,5,6),COLORS.structureDark,0.1,true,Enum.Material.Metal) end)
	component(logistics,"LOG-03","LOG",10,"Parts Shelf",function(m) shelfKit(m,"PartsShelf",Vector3.new(-105,0.8,346),13,9,0,COLORS.metal) end)
	component(logistics,"LOG-05","LOG",23,"Loading Bench and Pallet Jack",function(m) tableKit(m,"LoadingBench",Vector3.new(-74,0.8,320),Vector2.new(13,4),COLORS.metal,0) machineKit(m,"PalletJack",Vector3.new(-63,0.8,321),Vector3.new(6,1.3,2.5),COLORS.public,90) end)
	component(logistics,"LOG-06","LOG",23,"Secure Parts Cage",function(m) for _,x in {-113,-52} do box(m,"CageWall",Vector3.new(x,6,336),Vector3.new(1,10,36),COLORS.metal,0.6,true,Enum.Material.Metal) end box(m,"CageBack",Vector3.new(-82.5,6,353),Vector3.new(61,10,1),COLORS.metal,0.6,true,Enum.Material.Metal) end)
	component(logistics,"LOG-07","LOG",23,"Tagged Job Bins",function(m) for index=1,8 do box(m,"JobBin"..index,Vector3.new(-108+index*7,2,346),Vector3.new(5,2.2,3),index%2==0 and COLORS.public or COLORS.work,0,true) end end)
	component(logistics,"LOG-08","LOG",23,"Tow Drop Off",function(m) footprint(m,"TowPocket",Vector3.new(-20,1.25,300),Vector2.new(20,34),COLORS.serviceFlow,0.5) carKit(m,"DamagedArrival",Vector3.new(-20,0.8,300),Color3.fromRGB(116,91,77),0) end)
	component(logistics,"LOG-09","LOG",23,"Tow Truck",function(m) towTruckKit(m,"TowTruck",Vector3.new(-20,0.8,330),Color3.fromRGB(193,132,45),0) end)
	component(logistics,"LOG-10","LOG",23,"Tow Radio Station",function(m) workstation(m,"TowDispatch",Vector3.new(4,0.8,347),90,false) staffProxy(m,"TowDriver",Vector3.new(0,0.8,338),COLORS.logistics,0) end)
	component(logistics,"LOG-13","LOG",33,"Multi Row Racking",function(m) for index,x in { -105,-88,-71,-54 } do shelfKit(m,"Rack"..index,Vector3.new(x,0.8,336),13,10,0,COLORS.metal) end end)
	component(logistics,"LOG-14","LOG",33,"Warehouse Inventory Terminal",function(m) workstation(m,"InventoryTerminal",Vector3.new(-58,0.8,350),180,false) for _,x in {-105,-80,-55} do box(m,"WarehouseLight",Vector3.new(x,11,335),Vector3.new(12,0.3,1),COLORS.light,0.05,false,Enum.Material.Neon) end end)
	component(logistics,"LOG-15","LOG",33,"Rare Parts Store",function(m) box(m,"ClimateStore",Vector3.new(-104,6,322),Vector3.new(22,10,12),COLORS.logistics,0.42,true,Enum.Material.Glass) shelfKit(m,"RareShelf",Vector3.new(-104,0.8,323),14,8,0,COLORS.wood) end)
	component(logistics,"LOG-16","LOG",33,"Covered Transporter",function(m) local t=newModel(m,"Transporter",nil,nil) box(t,"Trailer",Vector3.new(88,4,338),Vector3.new(12,6,32),COLORS.structureDark,0.05,false,Enum.Material.Metal) box(t,"Cab",Vector3.new(88,4,320),Vector3.new(12,7,9),COLORS.logistics,0,false,Enum.Material.Metal) end)

	-- ESTATE, SAFETY AND SITE DETAIL -----------------------------------------
	local estate = group("EST_Estate_Safety_Brand_Complete", "EST", 1)
	component(estate,"EST-01","EST",1,"Generator and Work Lamps",function(m) machineKit(m,"Generator",Vector3.new(44,0.8,34),Vector3.new(5,4,3),COLORS.public,0) lightRig(m,"WorkLamps",Vector3.new(42,0.8,42),8,0) end)
	component(estate,"EST-05","EST",13,"Entry and Exit Gates",function(m) for _,x in {-88,-5,105} do box(m,"GatePost",Vector3.new(x-12,4,0),Vector3.new(1.2,7,1.2),COLORS.structureDark,0,true,Enum.Material.Metal) box(m,"GatePost",Vector3.new(x+12,4,0),Vector3.new(1.2,7,1.2),COLORS.structureDark,0,true,Enum.Material.Metal) end end)
	component(estate,"EST-06","EST",13,"Campus Floodlights",function(m) for _,p in {Vector3.new(-112,0,100),Vector3.new(112,0,100),Vector3.new(-112,0,300),Vector3.new(112,0,300)} do box(m,"Pole",p+Vector3.new(0,9,0),Vector3.new(.7,18,.7),COLORS.metal,0,true,Enum.Material.Metal) box(m,"Lamp",p+Vector3.new(0,18,0),Vector3.new(3,1,1.4),COLORS.light,0.05,false,Enum.Material.Neon) end end)
	component(estate,"EST-07","EST",13,"Cameras and Lock Boxes",function(m) for _,p in {Vector3.new(-116,8,8),Vector3.new(116,8,8),Vector3.new(-116,8,350),Vector3.new(116,8,350)} do box(m,"Camera",p,Vector3.new(1.2,.8,1.8),COLORS.black,0,false) end end)
	component(estate,"EST-08","EST",17,"Utilities and Storm Drains",function(m) cabinetKit(m,"UtilityPanel",Vector3.new(112,0.8,155),Vector3.new(5,8,2),COLORS.structureDark,90) for _,z in {90,160,240,304} do box(m,"Drain",Vector3.new(38,1.2,z),Vector3.new(2,.18,12),COLORS.black,0,false,Enum.Material.Metal) end end)
	component(estate,"EST-09","EST",18,"Fire Waste and Service Signage",function(m) for _,p in {Vector3.new(-51,2,135),Vector3.new(-51,2,232),Vector3.new(64,2,219)} do verticalCylinder(m,"FirePoint",p,Vector3.new(4,1.5,1.5),COLORS.safety,0,90) end cabinetKit(m,"FluidCabinet",Vector3.new(-110,.8,306),Vector3.new(5,7,3),COLORS.safety,0) end)
	component(estate,"EST-11","EST",26,"Architectural Lighting",function(m) for _,x in {-110,-82,-54,-15,14,49,88,112} do box(m,"BollardLight",Vector3.new(x,2,88),Vector3.new(.8,3,.8),COLORS.light,.05,false,Enum.Material.Neon) end end)
	component(estate,"EST-12","EST",26,"Wayfinding and Desert Landscape",function(m) for index,p in {Vector3.new(-113,0,92),Vector3.new(15,0,88),Vector3.new(65,0,93),Vector3.new(110,0,150),Vector3.new(-110,0,305)} do boardKit(m,"Wayfinding"..index,p+Vector3.new(0,5,0),Vector2.new(7,5),COLORS.public,0) verticalCylinder(m,"Planter"..index,p+Vector3.new(5,1,4),Vector3.new(2,4,4),COLORS.furniture,0,90) box(m,"DesertPlant"..index,p+Vector3.new(5,3,4),Vector3.new(1,4,1),COLORS.clean,0,false) end end)
	component(estate,"EST-13","EST",36,"Event Power Audio",function(m) machineKit(m,"EventPower",Vector3.new(32,.8,211),Vector3.new(4,5,3),COLORS.structureDark,0) for _,x in {-12,32} do box(m,"Speaker",Vector3.new(x,8,214),Vector3.new(3,5,2),COLORS.black,0,false) end end)
	component(estate,"EST-14","EST",36,"Heritage Installations",function(m) tableKit(m,"FirstDeskRelic",Vector3.new(2,.8,143),Vector2.new(5,3),COLORS.furniture,0) boardKit(m,"OriginStory",Vector3.new(14,8,146),Vector2.new(15,6),COLORS.furniture,0) end)

	-- Extra occupied cars and visible staff ensure the blockout reads as operating.
	local population = group("Operational_Population_and_Car_States", "MOV", 1)
	staffProxy(population,"SalesCustomer",Vector3.new(-2,.8,68),Color3.fromRGB(76,119,164),0)
	staffProxy(population,"SellerWaiting",Vector3.new(108,.8,28),Color3.fromRGB(112,91,73),180)
	staffProxy(population,"BuyerBrowsing",Vector3.new(-32,.8,66),Color3.fromRGB(80,132,104),90)
	staffProxy(population,"PorterWalking",Vector3.new(-20,.8,181),COLORS.public,90)
	staffProxy(population,"QCStaff",Vector3.new(32,.8,207),COLORS.clean,180)

	-- Moving proxy cars are animated by GreyboxTrafficSimulationV2 in Play mode.
	local moving = newModel(population,"Moving_DealerCar","MOV",1,{TrafficDemo=true,RouteModel="Dealer_Stock_Path_V2"})
	local dealerCar=carKit(moving,"Vehicle",Vector3.new(105,1.8,-12),Color3.fromRGB(45,151,178),0)
	moving.PrimaryPart=dealerCar.PrimaryPart
	local transfer = newModel(population,"Moving_TreatmentCar","MOV",14,{TrafficDemo=true,RouteModel="Treatment_Branches_V2"})
	local transferCar=carKit(transfer,"Vehicle",Vector3.new(17,1.8,191),Color3.fromRGB(222,138,49),90)
	transfer.PrimaryPart=transferCar.PrimaryPart
end

function Builder.Build()
	local root = workspace:FindFirstChild(ROOT_NAME)
	assert(root and root:IsA("Model"), "Missing " .. ROOT_NAME)

	local equipment = root:FindFirstChild("04_Equipment_and_Car_Scale")
	assert(equipment and equipment:IsA("Folder"), "Missing equipment folder")
	local prior = equipment:FindFirstChild(DETAIL_FOLDER_NAME)
	if prior then prior:Destroy() end
	local detail = Instance.new("Folder")
	detail.Name = DETAIL_FOLDER_NAME
	detail:SetAttribute("DetailedBlockoutVersion", 2)
	detail:SetAttribute("Purpose", "Full operational furniture, tools, staff, car states and traffic clearances")
	detail.Parent = equipment

	refitOfficeAndIntake(root)
	suppressOldRoutes(root)
	buildRoutes(root, detail)
	buildDetailedComponents(root, detail)

	root:SetAttribute("DetailedBlockoutVersion", 2)
	root:SetAttribute("TrafficDesignVersion", 2)
	root:SetAttribute("MinimumVehicleLaneWidth", 20)
	root:SetAttribute("MinimumGateWidth", 24)
	root:SetAttribute("MinimumTurnRadius", 18)
	root:SetAttribute("ReferenceVehicleWidth", 9.4)
	root:SetAttribute("ReferenceVehicleLength", 15)
	root:SetAttribute("DealerTrafficTopology", "Clockwise one-way loop with lateral treatment branches")

	local models, parts, components = 0, 0, 0
	for _, descendant in detail:GetDescendants() do
		if descendant:IsA("Model") then models += 1 end
		if descendant:IsA("BasePart") then parts += 1 end
		if descendant:GetAttribute("ComponentId") then components += 1 end
	end
	return {
		models = models,
		parts = parts,
		components = components,
		routes = 4,
		laneWidth = 20,
		gateWidth = 24,
		turnRadius = 18,
	}
end

return Builder

