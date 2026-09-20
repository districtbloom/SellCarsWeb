--!strict

-- Purposeful late-game fantasy pass for the compact dealership blockout.
-- This module does not add new economies. It makes three existing promises legible:
--   1. cars receive a visible wet-wash -> dry-detail treatment;
--   2. professional management and collector hospitality occupy a real upper floor;
--   3. the owner collection and industrial campus gain credible vertical prestige.

local Module = {}

local COLORS = {
	structure = Color3.fromRGB(64, 76, 87),
	dark = Color3.fromRGB(35, 42, 48),
	metal = Color3.fromRGB(118, 129, 137),
	glass = Color3.fromRGB(105, 205, 232),
	office = Color3.fromRGB(56, 154, 207),
	coffee = Color3.fromRGB(157, 104, 61),
	wood = Color3.fromRGB(121, 78, 49),
	wash = Color3.fromRGB(48, 210, 191),
	detail = Color3.fromRGB(113, 226, 183),
	garage = Color3.fromRGB(151, 86, 189),
	work = Color3.fromRGB(221, 126, 69),
	logistics = Color3.fromRGB(139, 112, 191),
	light = Color3.fromRGB(255, 235, 147),
	safety = Color3.fromRGB(252, 196, 66),
	white = Color3.fromRGB(229, 234, 236),
	black = Color3.fromRGB(27, 31, 35),
}

local function newModel(parent: Instance, name: string, unlockStep: number, role: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("UnlockStep", unlockStep)
	model:SetAttribute("FantasyRole", role)
	model:SetAttribute("BlockoutVersion", 3)
	model.Parent = parent
	return model
end

local function makePart(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	transparency: number?,
	canCollide: boolean?,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CanTouch = false
	part.CanQuery = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = transparency or 0
	part.Size = size
	part.CFrame = cf
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function box(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	transparency: number?,
	canCollide: boolean?,
	material: Enum.Material?,
	yaw: number?
): Part
	return makePart(
		parent,
		name,
		CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0),
		size,
		color,
		transparency,
		canCollide,
		material
	)
end

local function glass(parent: Instance, name: string, position: Vector3, size: Vector3, yaw: number?): Part
	return box(parent, name, position, size, COLORS.glass, 0.48, true, Enum.Material.Glass, yaw)
end

local function setPart(model: Model?, name: string, position: Vector3, size: Vector3, transparency: number?, canCollide: boolean?)
	if not model then return end
	local part = model:FindFirstChild(name)
	if not part or not part:IsA("BasePart") then return end
	part.Position = position
	part.Size = size
	if transparency ~= nil then part.Transparency = transparency end
	if canCollide ~= nil then part.CanCollide = canCollide end
end

local function tableKit(parent: Instance, name: string, position: Vector3, size: Vector2, color: Color3, yaw: number?): Model
	local model = newModel(parent, name, 1, "Furniture")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	makePart(model, "Top", cf * CFrame.new(0, 3, 0), Vector3.new(size.X, 0.45, size.Y), color, 0, true, Enum.Material.Wood)
	for _, offset in {
		Vector3.new(-size.X * 0.38, 1.5, -size.Y * 0.34),
		Vector3.new(size.X * 0.38, 1.5, -size.Y * 0.34),
		Vector3.new(-size.X * 0.38, 1.5, size.Y * 0.34),
		Vector3.new(size.X * 0.38, 1.5, size.Y * 0.34),
	} do
		makePart(model, "Leg", cf * CFrame.new(offset), Vector3.new(0.35, 3, 0.35), COLORS.dark, 0, true, Enum.Material.Metal)
	end
	return model
end

local function chairKit(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number?): Model
	local model = newModel(parent, name, 1, "Furniture")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	makePart(model, "Seat", cf * CFrame.new(0, 2, 0), Vector3.new(2.5, 0.45, 2.5), color, 0, true, Enum.Material.Fabric)
	makePart(model, "Back", cf * CFrame.new(0, 3.6, 1), Vector3.new(2.5, 3.2, 0.45), color, 0, true, Enum.Material.Fabric)
	for _, offset in {Vector3.new(-0.9, 1, -0.9), Vector3.new(0.9, 1, -0.9), Vector3.new(-0.9, 1, 0.9), Vector3.new(0.9, 1, 0.9)} do
		makePart(model, "Leg", cf * CFrame.new(offset), Vector3.new(0.25, 2, 0.25), COLORS.dark, 0, true, Enum.Material.Metal)
	end
	return model
end

local function workstation(parent: Instance, name: string, position: Vector3, yaw: number): Model
	local model = newModel(parent, name, 30, "Back-office workstation")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	makePart(model, "Desk", cf * CFrame.new(0, 3, 0), Vector3.new(6.5, 0.5, 3), COLORS.structure, 0, true, Enum.Material.Metal)
	makePart(model, "Monitor", cf * CFrame.new(0, 5.3, -0.45), Vector3.new(3.4, 2.2, 0.35), COLORS.glass, 0.08, false, Enum.Material.Neon)
	makePart(model, "Keyboard", cf * CFrame.new(0, 3.4, 0.5), Vector3.new(2.8, 0.18, 0.9), COLORS.black, 0, false, Enum.Material.SmoothPlastic)
	makePart(model, "Computer", cf * CFrame.new(2.4, 1.7, 0), Vector3.new(1.2, 3.2, 2), COLORS.dark, 0, true, Enum.Material.Metal)
	chairKit(model, "Chair", (cf * CFrame.new(0, 0, 3)).Position, COLORS.office, yaw + 180)
	return model
end

local function staffProxy(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number?): Model
	local model = newModel(parent, name, 1, "Staff occupation proxy")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	makePart(model, "Body", cf * CFrame.new(0, 3.1, 0), Vector3.new(2.2, 3.3, 1.25), color, 0, false, Enum.Material.SmoothPlastic)
	local head = makePart(model, "Head", cf * CFrame.new(0, 5.6, 0), Vector3.new(1.55, 1.55, 1.55), Color3.fromRGB(213, 170, 124), 0, false, Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
	for _, x in {-0.58, 0.58} do
		makePart(model, "Leg", cf * CFrame.new(x, 1.2, 0), Vector3.new(0.78, 2.2, 0.78), COLORS.dark, 0, false, Enum.Material.SmoothPlastic)
	end
	return model
end

local function carProxy(parent: Instance, name: string, position: Vector3, color: Color3, yaw: number): Model
	local model = newModel(parent, name, 14, "Vehicle process state")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	makePart(model, "Body", cf * CFrame.new(0, 2.1, 0), Vector3.new(9.4, 2.1, 15), color, 0, false, Enum.Material.SmoothPlastic)
	makePart(model, "Cabin", cf * CFrame.new(0, 3.7, 0.7), Vector3.new(7.6, 2.2, 7), COLORS.glass, 0.15, false, Enum.Material.Glass)
	for _, offset in {Vector3.new(-4.8, 1.35, -4.7), Vector3.new(4.8, 1.35, -4.7), Vector3.new(-4.8, 1.35, 4.7), Vector3.new(4.8, 1.35, 4.7)} do
		local wheel = makePart(model, "Wheel", cf * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(1.2, 2.5, 2.5), COLORS.black, 0, false, Enum.Material.Rubber)
		wheel.Shape = Enum.PartType.Cylinder
	end
	return model
end

local function filledStair(parent: Instance, name: string, start: Vector3, stepCount: number, tread: number, rise: number, width: number, color: Color3): Model
	local model = newModel(parent, name, 30, "Vertical circulation")
	for index = 1, stepCount do
		local height = index * rise
		box(model, string.format("Step_%02d", index), start + Vector3.new(0, height / 2, (index - 1) * tread), Vector3.new(width, height, tread + 0.05), color, 0, true, Enum.Material.Concrete)
	end
	return model
end

local function lineBetween(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3): Part
	local midpoint = (a + b) / 2
	local length = (b - a).Magnitude
	return makePart(parent, name, CFrame.lookAt(midpoint, b) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(width, 0.2, length), color, 0.08, false, Enum.Material.Neon)
end

local function configureMassing(root: Model)
	local buildings = root:FindFirstChild("03_Building_Blockouts")
	assert(buildings, "03_Building_Blockouts is missing")

	local office = buildings:FindFirstChild("Collector_Hall_Office") :: Model?
	setPart(office, "BackWall", Vector3.new(14, 16.2, 146.25), Vector3.new(46, 30, 1.5))
	setPart(office, "LeftWall", Vector3.new(-8.25, 16.2, 120), Vector3.new(1.5, 30, 54), 1, false)
	setPart(office, "RightWall", Vector3.new(36.25, 16.2, 120), Vector3.new(1.5, 30, 54), 1, false)
	setPart(office, "FrontPierL", Vector3.new(-7.5, 16.2, 94.5), Vector3.new(3, 30, 3))
	setPart(office, "FrontPierR", Vector3.new(35.5, 16.2, 94.5), Vector3.new(3, 30, 3))
	setPart(office, "RoofMass", Vector3.new(14, 31.5, 120), Vector3.new(48, 1.2, 56))
	setPart(office, "Collector_Hall_Office_LabelAnchor", Vector3.new(14, 34, 97), Vector3.new(0.5, 0.5, 0.5))
	setPart(office, "UpperClientVolume", Vector3.new(14, 22, 120), Vector3.new(42, 14, 52), 1, false)
	if office then
		office:SetAttribute("UsableFloors", 2)
		office:SetAttribute("VerticalRole", "Ground-floor deals and hospitality; upper operations and collector lounge")
	end

	local garage = buildings:FindFirstChild("Owner_Garage_Gallery") :: Model?
	setPart(garage, "LeftWall", Vector3.new(-115.25, 15.2, 46), Vector3.new(1.5, 28, 82))
	setPart(garage, "RightWall", Vector3.new(-58.75, 15.2, 46), Vector3.new(1.5, 28, 82))
	setPart(garage, "FrontPierL", Vector3.new(-114.5, 15.2, 6.5), Vector3.new(3, 28, 3))
	setPart(garage, "FrontPierR", Vector3.new(-59.5, 15.2, 6.5), Vector3.new(3, 28, 3))
	setPart(garage, "BackWall_Main", Vector3.new(-96, 15.2, 86.25), Vector3.new(40, 28, 1.5))
	setPart(garage, "BackDoorPier", Vector3.new(-59.5, 15.2, 86.25), Vector3.new(3, 28, 1.5))
	setPart(garage, "RoofMass", Vector3.new(-87, 29.5, 46), Vector3.new(60, 1.2, 84))
	setPart(garage, "UpperGalleryBand", Vector3.new(-83, 22, 68), Vector3.new(44, 12, 34), 1, false)
	setPart(garage, "Owner_Garage_Gallery_LabelAnchor", Vector3.new(-87, 32, 9), Vector3.new(0.5, 0.5, 0.5))
	if garage then
		garage:SetAttribute("UsableFloors", 2)
		garage:SetAttribute("VerticalRole", "Ground-floor cars; upper collection lounge and legacy archive")
	end

	local function highBay(name: string, wallHeight: number, roofY: number)
		local model = buildings:FindFirstChild(name) :: Model?
		if not model then return end
		for _, partName in {"BackWall", "LeftWall", "RightWall", "FrontPierL", "FrontPierR"} do
			local part = model:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Position = Vector3.new(part.Position.X, 1.2 + wallHeight / 2, part.Position.Z)
				part.Size = Vector3.new(part.Size.X, wallHeight, part.Size.Z)
			end
		end
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part.Name:find("CourtyardPier") then
				part.Position = Vector3.new(part.Position.X, 1.2 + wallHeight / 2, part.Position.Z)
				part.Size = Vector3.new(part.Size.X, wallHeight, part.Size.Z)
			end
		end
		local roof = model:FindFirstChild("RoofMass")
		if roof and roof:IsA("BasePart") then roof.Position = Vector3.new(roof.Position.X, roofY, roof.Position.Z) end
		model:SetAttribute("UsableFloors", 1)
		model:SetAttribute("VerticalRole", "Professional high-bay clearance, not an extra office floor")
	end

	highBay("Mechanical_Restoration_Hall", 24, 25.5)
	highBay("Finish_Atelier", 24, 25.5)
	highBay("Parts_Tow_Warehouse", 20, 21.5)
	local finish = buildings:FindFirstChild("Finish_Atelier")
	local obsoleteWashPier = finish and finish:FindFirstChild("CourtyardPier_02")
	if obsoleteWashPier and obsoleteWashPier:IsA("BasePart") then
		obsoleteWashPier.Transparency = 1
		obsoleteWashPier.CanCollide = false
		obsoleteWashPier:SetAttribute("RemovedForWashBranch", true)
	end

	local courtyard = buildings:FindFirstChild("Working_Courtyard_and_Reveal_Plaza") :: Model?
	setPart(courtyard, "EventCanopy", Vector3.new(12, 24, 196), Vector3.new(56, 1, 40))
	if courtyard then
		for _, part in courtyard:GetChildren() do
			if part:IsA("BasePart") and part.Name == "CanopyPost" then
				part.Position = Vector3.new(part.Position.X, 12.5, part.Position.Z)
				part.Size = Vector3.new(part.Size.X, 23, part.Size.Z)
			end
		end
		courtyard:SetAttribute("VerticalRole", "Tall reveal landmark with full vehicle clearance")
	end

	root:SetAttribute("DetailedBlockoutVersion", 3)
	root:SetAttribute("VerticalProgressionVersion", 3)
	root:SetAttribute("CollectorHallFloors", 2)
	root:SetAttribute("OwnerGalleryFloors", 2)
	root:SetAttribute("IndustrialFloors", 1)
	root:SetAttribute("VerticalGrowthRule", "Occupy office and gallery floors; use high-bay volume for vehicle work")
end

local function buildWash(root: Model, parent: Model)
	local wash = newModel(parent, "A_Wash_and_Detail_Process", 14, "Visible wet wash to dry presentation sequence")
	wash:SetAttribute("ProcessOrder", "Arrival -> wet wash -> dry/detail -> QC -> reverse handoff")
	wash:SetAttribute("AddsNewEconomy", false)
	local equipment = root:FindFirstChild("04_Equipment_and_Car_Scale")
	if equipment then
		for _, descendant in equipment:GetDescendants() do
			if descendant:IsA("Model") and descendant.Name == "PressureWasher" and descendant:GetAttribute("FantasyV3Relocated") ~= true then
				descendant:TranslateBy(Vector3.new(0, 0, -7))
				descendant:SetAttribute("FantasyV3Relocated", true)
			elseif descendant:IsA("Model") and descendant.Name == "PolishBench" and descendant:GetAttribute("FantasyV3Relocated") ~= true then
				descendant:TranslateBy(Vector3.new(0, 0, 12))
				descendant:SetAttribute("FantasyV3Relocated", true)
			elseif descendant:IsA("Model") and descendant.Name == "SteamExtractor" and descendant:GetAttribute("FantasyV3Relocated") ~= true then
				descendant:TranslateBy(Vector3.new(-4, 0, 20))
				descendant:SetAttribute("FantasyV3Relocated", true)
			end
		end
	end

	box(wash, "WetWashFloor", Vector3.new(78, 1.28, 181), Vector3.new(20, 0.22, 30), COLORS.wash, 0.42, false, Enum.Material.CeramicTiles)
	box(wash, "DryDetailFloor", Vector3.new(99, 1.28, 181), Vector3.new(20, 0.22, 30), COLORS.detail, 0.42, false, Enum.Material.SmoothPlastic)
	for _, x in {69, 80, 91} do
		box(wash, "GantryPost", Vector3.new(x, 6.2, 168), Vector3.new(1, 10, 1), COLORS.wash, 0, true, Enum.Material.Metal)
		box(wash, "GantryPost", Vector3.new(x, 6.2, 194), Vector3.new(1, 10, 1), COLORS.wash, 0, true, Enum.Material.Metal)
		box(wash, "GantryHeader", Vector3.new(x, 11, 181), Vector3.new(1, 1, 27), COLORS.wash, 0, true, Enum.Material.Metal)
	end
	for _, x in {75, 86} do
		box(wash, "SoftBrushLeft", Vector3.new(x, 6, 170.5), Vector3.new(2.2, 9, 2.2), COLORS.light, 0.1, false, Enum.Material.Fabric)
		box(wash, "SoftBrushRight", Vector3.new(x, 6, 191.5), Vector3.new(2.2, 9, 2.2), COLORS.light, 0.1, false, Enum.Material.Fabric)
	end
	for _, z in {172, 181, 190} do
		box(wash, "DrainChannel", Vector3.new(78, 1.4, z), Vector3.new(18, 0.25, 0.7), COLORS.black, 0, false, Enum.Material.Metal)
	end
	box(wash, "SplashWallNorth", Vector3.new(80, 4, 166), Vector3.new(30, 6, 0.6), COLORS.glass, 0.6, true, Enum.Material.Glass)
	box(wash, "SplashWallSouth", Vector3.new(80, 4, 196), Vector3.new(30, 6, 0.6), COLORS.glass, 0.6, true, Enum.Material.Glass)
	for _, z in {169, 193} do
		box(wash, "DryerTower", Vector3.new(97, 6, z), Vector3.new(2.2, 9, 3.5), COLORS.metal, 0, true, Enum.Material.Metal)
		box(wash, "DryerNozzle", Vector3.new(99, 8, z), Vector3.new(3, 1.2, 2.2), COLORS.dark, 0, false, Enum.Material.Metal)
	end
	box(wash, "WaterRecoveryTank", Vector3.new(108, 5.5, 197), Vector3.new(5, 9, 5), COLORS.wash, 0.15, true, Enum.Material.Metal)
	box(wash, "FilterBank", Vector3.new(103, 4, 198), Vector3.new(4, 6, 4), COLORS.white, 0.1, true, Enum.Material.Metal)
	tableKit(wash, "FinalQCStation", Vector3.new(105, 0.8, 168), Vector2.new(7, 3), COLORS.metal, 90)
	staffProxy(wash, "WashDetailer", Vector3.new(103, 0.8, 181), COLORS.wash, 90)
	local movingCar = carProxy(wash, "Moving_WashCar", Vector3.new(88, 0.8, 181), Color3.fromRGB(66, 132, 193), 90)
	movingCar:SetAttribute("TrafficDemo", "Wash_Detail_Branch_V3")

	local routes = root:FindFirstChild("05_Vehicle_Routes")
	assert(routes, "05_Vehicle_Routes is missing")
	local oldRoute = routes:FindFirstChild("Wash_Detail_Branch_V3")
	if oldRoute then oldRoute:Destroy() end
	local route = newModel(routes, "Wash_Detail_Branch_V3", 14, "Dedicated wash/detail service branch")
	route:SetAttribute("LaneWidth", 18)
	route:SetAttribute("ReferenceVehicleWidth", 9.4)
	route:SetAttribute("VehicleOperation", "Forward into wet/dry positions; reverse to courtyard spine")
	local points = {
		{p = Vector3.new(49, 1.42, 181), hold = 0, reverse = false},
		{p = Vector3.new(65, 1.42, 181), hold = 0, reverse = false},
		{p = Vector3.new(78, 1.42, 181), hold = 2.2, reverse = false},
		{p = Vector3.new(96, 1.42, 181), hold = 2.2, reverse = false},
		{p = Vector3.new(100, 1.42, 181), hold = 1.2, reverse = false},
		{p = Vector3.new(96, 1.42, 181), hold = 0, reverse = true},
		{p = Vector3.new(78, 1.42, 181), hold = 0, reverse = true},
		{p = Vector3.new(65, 1.42, 181), hold = 0, reverse = true},
		{p = Vector3.new(49, 1.42, 181), hold = 0, reverse = true},
	}
	for index = 1, 4 do lineBetween(route, string.format("Segment_%02d", index), points[index].p, points[index + 1].p, 1.4, COLORS.wash) end
	local waypointFolder = Instance.new("Folder")
	waypointFolder.Name = "DemoWaypoints"
	waypointFolder.Parent = route
	for index, info in points do
		local node = box(route, string.format("Node_%02d", index), info.p, Vector3.new(2.5, 0.2, 2.5), COLORS.wash, 0.58, false, Enum.Material.Neon)
		local waypoint = box(waypointFolder, string.format("WP_%02d", index), info.p + Vector3.new(0, 1.75, 0), Vector3.one, COLORS.wash, 1, false, Enum.Material.SmoothPlastic)
		waypoint:SetAttribute("Order", index)
		waypoint:SetAttribute("HoldSeconds", info.hold)
		waypoint:SetAttribute("Reverse", info.reverse)
	end
	box(route, "CarPlusWorkingClearance", Vector3.new(86, 3, 181), Vector3.new(74, 5, 18), COLORS.wash, 0.92, false, Enum.Material.ForceField)
	root:SetAttribute("WashProcessVersion", 3)
	root:SetAttribute("WashDetailStations", 2)
end

local function buildCollectorHall(parent: Model)
	local hall = newModel(parent, "B_Collector_Hall_Second_Level", 34, "Two-level public and management landmark")

	-- A real second floor, ground-floor glazing, and an upper viewing balcony.
	box(hall, "UpperFloor", Vector3.new(14, 15.1, 120), Vector3.new(42, 1, 52), COLORS.office, 0.18, true, Enum.Material.Concrete)
	box(hall, "GroundGlassLeft", Vector3.new(0, 7.8, 94.6), Vector3.new(13, 13, 0.45), COLORS.glass, 0.5, true, Enum.Material.Glass)
	box(hall, "GroundGlassRight", Vector3.new(28, 7.8, 94.6), Vector3.new(13, 13, 0.45), COLORS.glass, 0.5, true, Enum.Material.Glass)
	glass(hall, "UpperFrontGlass", Vector3.new(14, 22.5, 94.6), Vector3.new(42, 13, 0.45))
	glass(hall, "UpperEastGlass", Vector3.new(36.2, 22.5, 120), Vector3.new(0.45, 13, 52))
	box(hall, "LowerEastWall", Vector3.new(36.25, 7.8, 120), Vector3.new(1.5, 13, 54), COLORS.structure, 0.18, true, Enum.Material.Concrete)
	box(hall, "LowerWestWall", Vector3.new(-8.25, 7.8, 120), Vector3.new(1.5, 13, 54), COLORS.structure, 0.18, true, Enum.Material.Concrete)
	box(hall, "UpperWestWallFront", Vector3.new(-8.25, 22.5, 111.5), Vector3.new(1.5, 13, 35), COLORS.structure, 0.18, true, Enum.Material.Concrete)
	box(hall, "UpperWestWallRear", Vector3.new(-8.25, 22.5, 143.5), Vector3.new(1.5, 13, 7), COLORS.structure, 0.18, true, Enum.Material.Concrete)
	box(hall, "UpperWestDoorHeader", Vector3.new(-8.25, 28.2, 134.5), Vector3.new(1.5, 2.5, 11), COLORS.structure, 0.18, true, Enum.Material.Concrete)
	box(hall, "ViewingBalcony", Vector3.new(14, 15.15, 90.5), Vector3.new(34, 1, 7), COLORS.office, 0.12, true, Enum.Material.Concrete)
	glass(hall, "BalconyRail", Vector3.new(14, 17.3, 87.3), Vector3.new(34, 3.2, 0.35))

	local stairs = filledStair(hall, "ExteriorOperationsStair", Vector3.new(-12, 0.8, 111), 14, 1.7, 1, 6, COLORS.structure)
	stairs:SetAttribute("ClearWidth", 6)
	box(hall, "UpperLanding", Vector3.new(-10.2, 15.15, 137), Vector3.new(9, 1, 8), COLORS.structure, 0, true, Enum.Material.Concrete)
	for _, z in {111, 122.9, 134.8, 140.5} do
		box(hall, "StairRailPost", Vector3.new(-15.1, math.max(2.5, 1 + (z - 109) * 0.58), z), Vector3.new(0.3, 4, 0.3), COLORS.safety, 0, true, Enum.Material.Metal)
	end

	-- The back office makes automation visible without turning paperwork into a minigame.
	local office = newModel(hall, "Back_Office_and_Operations_Room", 30, "Management, sourcing, dispatch and records")
	box(office, "PartitionLeft", Vector3.new(-1, 22, 121.5), Vector3.new(14, 12, 0.45), COLORS.structure, 0.25, true, Enum.Material.Metal)
	box(office, "PartitionRight", Vector3.new(27, 22, 121.5), Vector3.new(18, 12, 0.45), COLORS.structure, 0.25, true, Enum.Material.Metal)
	glass(office, "PartitionDoorGlass", Vector3.new(11, 22, 121.5), Vector3.new(10, 12, 0.35))
	for index, x in {2, 11, 20, 29} do workstation(office, "OperationsPC_" .. index, Vector3.new(x, 15.6, 138), 180) end
	workstation(office, "ManagerPC", Vector3.new(29, 15.6, 127), 90)
	box(office, "ServerRack", Vector3.new(34, 19, 142), Vector3.new(3, 7, 3), COLORS.dark, 0, true, Enum.Material.Metal)
	box(office, "RecordsWall", Vector3.new(-5.5, 21.5, 143.8), Vector3.new(7, 10, 1), COLORS.wood, 0, true, Enum.Material.Wood)
	box(office, "DispatchBoard", Vector3.new(14, 25, 145.1), Vector3.new(15, 6, 0.25), COLORS.glass, 0.05, false, Enum.Material.Neon)
	staffProxy(office, "OperationsManagerUpper", Vector3.new(24, 15.6, 130), COLORS.office, 180)

	-- Bounded cafe: hospitality and viewing only, no food-production economy.
	local cafe = newModel(hall, "Collector_Coffee_Bar_and_Viewing_Lounge", 34, "Premium-client hospitality and event viewing")
	cafe:SetAttribute("NoRestaurantEconomy", true)
	box(cafe, "CoffeeCounter", Vector3.new(27, 18, 114), Vector3.new(15, 3, 3), COLORS.wood, 0, true, Enum.Material.Wood)
	box(cafe, "CoffeeMachine", Vector3.new(31, 20.4, 114), Vector3.new(3, 2, 2), COLORS.metal, 0, true, Enum.Material.Metal)
	box(cafe, "CupShelf", Vector3.new(27, 24, 117.1), Vector3.new(14, 4, 0.6), COLORS.wood, 0, true, Enum.Material.Wood)
	for _, x in {22, 27, 32} do chairKit(cafe, "BarStool", Vector3.new(x, 15.6, 110), COLORS.coffee, 0) end
	for index, x in {0, 12} do
		tableKit(cafe, "BistroTable_" .. index, Vector3.new(x, 15.6, 104), Vector2.new(4, 4), COLORS.wood, 0)
		chairKit(cafe, "CollectorChairA_" .. index, Vector3.new(x - 3, 15.6, 104), COLORS.coffee, 90)
		chairKit(cafe, "CollectorChairB_" .. index, Vector3.new(x + 3, 15.6, 104), COLORS.coffee, -90)
	end
	box(cafe, "DisplayStoryWall", Vector3.new(-5.5, 23, 107), Vector3.new(0.4, 9, 18), COLORS.garage, 0.08, false, Enum.Material.Neon)
	staffProxy(cafe, "CollectorHost", Vector3.new(18, 15.6, 108), COLORS.coffee, 180)
end

local function buildOwnerMezzanine(parent: Model)
	local gallery = newModel(parent, "C_Owner_Gallery_Mezzanine", 36, "Visible owner collection, memory and aspiration")
	box(gallery, "MezzanineFloor", Vector3.new(-83, 15.1, 69), Vector3.new(42, 1, 33), COLORS.garage, 0.18, true, Enum.Material.Concrete)
	glass(gallery, "MezzanineRail", Vector3.new(-83, 17.2, 52.8), Vector3.new(42, 3.2, 0.35))
	glass(gallery, "UpperFrontGlass", Vector3.new(-83, 22.2, 52), Vector3.new(42, 11, 0.45))
	filledStair(gallery, "OwnerGalleryStair", Vector3.new(-108, 0.8, 52), 14, 1.7, 1, 6, COLORS.garage)
	box(gallery, "OwnerLanding", Vector3.new(-105, 15.15, 78), Vector3.new(7, 1, 8), COLORS.garage, 0, true, Enum.Material.Concrete)
	tableKit(gallery, "ArchiveTable", Vector3.new(-72, 15.6, 76), Vector2.new(10, 4), COLORS.wood, 0)
	box(gallery, "LegacyArchiveWall", Vector3.new(-84, 22, 84.8), Vector3.new(30, 10, 0.5), COLORS.wood, 0, true, Enum.Material.Wood)
	box(gallery, "FirstSignRelic", Vector3.new(-84, 23, 84.4), Vector3.new(14, 5, 0.3), COLORS.safety, 0.05, false, Enum.Material.Neon)
	for _, x in {-96, -90, -84} do box(gallery, "Trophy", Vector3.new(x, 19.5, 77), Vector3.new(1.4, 4, 1.4), COLORS.light, 0, true, Enum.Material.Metal) end
	chairKit(gallery, "OwnerLoungeChairA", Vector3.new(-94, 15.6, 63), COLORS.garage, 45)
	chairKit(gallery, "OwnerLoungeChairB", Vector3.new(-88, 15.6, 63), COLORS.garage, -45)
	tableKit(gallery, "OwnerCoffeeTable", Vector3.new(-91, 15.6, 68), Vector2.new(5, 3), COLORS.wood, 0)
	box(gallery, "CollectionScreen", Vector3.new(-63, 22, 69), Vector3.new(0.35, 8, 17), COLORS.glass, 0.06, false, Enum.Material.Neon)
end

local function buildHighBayDetail(parent: Model)
	local highBay = newModel(parent, "D_Professional_High_Bay_Massing", 26, "Credible professional vehicle-work volume")
	for _, z in {126, 176, 226, 276} do
		box(highBay, "MechanicalRoofTruss", Vector3.new(-82, 22.2, z), Vector3.new(68, 1, 2), COLORS.work, 0.08, true, Enum.Material.Metal)
		box(highBay, "MechanicalLight", Vector3.new(-82, 20.8, z), Vector3.new(42, 0.35, 0.8), COLORS.light, 0.05, false, Enum.Material.Neon)
	end
	for _, z in {181, 219, 255, 292} do
		box(highBay, "FinishRoofTruss", Vector3.new(88, 22.2, z), Vector3.new(50, 1, 2), COLORS.wash, 0.08, true, Enum.Material.Metal)
		box(highBay, "FinishLight", Vector3.new(88, 20.8, z), Vector3.new(30, 0.35, 0.8), COLORS.light, 0.05, false, Enum.Material.Neon)
	end
	for _, x in {-96, -52, -8} do
		box(highBay, "WarehouseTruss", Vector3.new(x, 18.6, 335), Vector3.new(2, 1, 40), COLORS.logistics, 0.08, true, Enum.Material.Metal)
	end
	box(highBay, "MechanicalClerestory", Vector3.new(-116.1, 20, 210), Vector3.new(0.35, 5, 188), COLORS.glass, 0.58, false, Enum.Material.Glass)
	box(highBay, "FinishClerestory", Vector3.new(113.1, 20, 237), Vector3.new(0.35, 5, 132), COLORS.glass, 0.58, false, Enum.Material.Glass)
end

local function buildRevealLandmark(parent: Model)
	local reveal = newModel(parent, "E_Reveal_Canopy_Vertical_Landmark", 35, "Ceremonial height without consuming more land")
	box(reveal, "LightingBridge", Vector3.new(12, 21, 196), Vector3.new(48, 1, 2), COLORS.safety, 0, true, Enum.Material.Metal)
	for _, x in {-8, 12, 32} do
		box(reveal, "SuspendedRevealLight", Vector3.new(x, 19.5, 196), Vector3.new(6, 0.4, 0.8), COLORS.light, 0.05, false, Enum.Material.Neon)
	end
	box(reveal, "DealerCrest", Vector3.new(12, 27, 216), Vector3.new(20, 5, 0.6), COLORS.safety, 0.05, false, Enum.Material.Neon)
end

function Module.Apply(): {[string]: number}
	local root = workspace:FindFirstChild("SellCars_CompactCampus_Greybox_V1")
	assert(root and root:IsA("Model"), "SellCars_CompactCampus_Greybox_V1 is missing")

	local oldPass = root:FindFirstChild("07_Fantasy_Completion_V3")
	if oldPass then oldPass:Destroy() end
	local pass = newModel(root, "07_Fantasy_Completion_V3", 14, "Simulation-to-blockout fantasy reconciliation")
	pass:SetAttribute("ScopeBoundary", "No restaurant economy, generic office minigame, or stacked workshop floors")
	pass:SetAttribute("StagesRepresented", "14 wash; 26 high-bay; 30 operations floor; 34 collector hospitality; 35 reveal; 36 owner mezzanine")

	configureMassing(root)
	buildWash(root, pass)
	buildCollectorHall(pass)
	buildOwnerMezzanine(pass)
	buildHighBayDetail(pass)
	buildRevealLandmark(pass)

	local modelCount = 0
	local partCount = 0
	for _, descendant in pass:GetDescendants() do
		if descendant:IsA("Model") then modelCount += 1 end
		if descendant:IsA("BasePart") then partCount += 1 end
	end
	root:SetAttribute("FantasyCompletionModelCount", modelCount)
	root:SetAttribute("FantasyCompletionPartCount", partCount)
	return {models = modelCount, parts = partCount}
end

return Module

