--!strict

-- Sell Cars V5 — Institution Production A.
-- Adds complete function-specific production scenes inside the accepted V5
-- service/utility bands. The route skeleton, portals, bay centres, crossovers,
-- frontage and rear campus remain unchanged.

local Workspace = game:GetService("Workspace")

local Installer = {}
Installer.Version = "2026-09-03.v5-institution-production-a.1"

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local LAYER_NAME = "08_Institution_Production_A"
local ORIGIN_X = 3130

local C = {
	Navy = Color3.fromRGB(20, 29, 40),
	Dark = Color3.fromRGB(31, 37, 43),
	Steel = Color3.fromRGB(70, 80, 88),
	MidSteel = Color3.fromRGB(105, 116, 122),
	White = Color3.fromRGB(226, 234, 236),
	WarmWhite = Color3.fromRGB(247, 235, 202),
	Rubber = Color3.fromRGB(23, 25, 28),
	Yellow = Color3.fromRGB(242, 185, 42),
	Amber = Color3.fromRGB(235, 121, 38),
	Red = Color3.fromRGB(218, 57, 48),
	Cyan = Color3.fromRGB(38, 207, 220),
	Teal = Color3.fromRGB(48, 173, 151),
	Blue = Color3.fromRGB(60, 130, 205),
	Purple = Color3.fromRGB(130, 92, 214),
	Pink = Color3.fromRGB(225, 78, 166),
	Green = Color3.fromRGB(63, 181, 119),
	Orange = Color3.fromRGB(235, 132, 48),
	Glass = Color3.fromRGB(111, 195, 213),
	Oil = Color3.fromRGB(83, 63, 36),
	Brick = Color3.fromRGB(125, 61, 46),
}

local FUNCTIONS = {
	{Name = "Wash", Side = -1, Z = 120, Depth = 44, Accent = C.Cyan},
	{Name = "Mechanical", Side = -1, Z = 175, Depth = 58, Accent = C.Red},
	{Name = "Body_Restoration", Side = -1, Z = 239, Depth = 64, Accent = C.Orange},
	{Name = "Tune_Performance", Side = -1, Z = 307, Depth = 60, Accent = C.Purple},
	{Name = "Paint_Exterior", Side = 1, Z = 307, Depth = 68, Accent = C.Pink},
	{Name = "Detail_QC", Side = 1, Z = 239, Depth = 58, Accent = C.Teal},
	{Name = "Photo_Listing", Side = 1, Z = 175, Depth = 54, Accent = C.Blue},
}

type FunctionData = {
	Name: string,
	Side: number,
	Z: number,
	Depth: number,
	Accent: Color3,
}

local function model(parent: Instance, name: string, functionId: string?): Model
	local result = Instance.new("Model")
	result.Name = name
	result:SetAttribute("V5ProductionA", true)
	if functionId then result:SetAttribute("FunctionId", functionId) end
	result.Parent = parent
	return result
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?,
	transparency: number?,
	functionId: string?
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Anchored = true
	result.Size = size
	result.CFrame = cframe
	result.Color = color
	result.Material = material or Enum.Material.Metal
	result.Transparency = transparency or 0
	result.CanCollide = solid == true
	result.CanTouch = false
	result.CanQuery = true
	result.CastShadow = result.Transparency < 0.6
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result:SetAttribute("V5ProductionADetail", true)
	if functionId then result:SetAttribute("FunctionId", functionId) end
	if solid then
		result:SetAttribute("V5ProductionASolid", true)
		result:SetAttribute("V5Blocker", true)
	end
	result.Parent = parent
	return result
end

local function block(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?,
	transparency: number?,
	functionId: string?
): Part
	return part(parent, name, size, CFrame.new(position), color, material, solid, transparency, functionId)
end

local function oriented(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	rotation: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?,
	transparency: number?,
	functionId: string?
): Part
	return part(
		parent,
		name,
		size,
		CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)),
		color,
		material,
		solid,
		transparency,
		functionId
	)
end

local function cylinder(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	rotation: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?,
	functionId: string?
): Part
	local result = oriented(parent, name, position, size, rotation, color, material, solid, nil, functionId)
	result.Shape = Enum.PartType.Cylinder
	return result
end

local function surfaceText(target: BasePart, value: string, face: Enum.NormalId, color: Color3, small: boolean?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ProductionLabel"
	gui.Face = face
	gui.CanvasSize = if small then Vector2.new(360, 120) else Vector2.new(720, 180)
	gui.LightInfluence = 0.15
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.Parent = target
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = value
	text.TextColor3 = color
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = gui
end

local function context(data: FunctionData): {[string]: any}
	return {
		Side = data.Side,
		Z = data.Z,
		BayX = ORIGIN_X + data.Side * 64,
		ServiceX = ORIGIN_X + data.Side * 108,
		EquipmentX = ORIGIN_X + data.Side * 114,
		InnerAisleX = ORIGIN_X + data.Side * 99,
		WallX = ORIGIN_X + data.Side * 119,
		Accent = data.Accent,
		Name = data.Name,
	}
end

local function taskLight(parent: Instance, name: string, position: Vector3, size: Vector3, functionId: string)
	local lightPart = block(parent, name, position, size, C.White, Enum.Material.Neon, false, 0.05, functionId)
	local light = Instance.new("PointLight")
	light.Name = "WorkLight"
	light.Color = Color3.fromRGB(222, 239, 244)
	light.Brightness = 0.45
	light.Range = 19
	light.Shadows = false
	light.Parent = lightPart
end

local function effectAnchor(parent: Instance, functionId: string, bayIndex: number, position: Vector3, effect: string)
	local anchor = block(parent, "VehicleEffectAnchor_Bay_" .. bayIndex, position, Vector3.new(1, 1, 1), C.White, Enum.Material.SmoothPlastic, false, 1, functionId)
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor:SetAttribute("VehicleEffect", effect)
	anchor:SetAttribute("BayIndex", bayIndex)
end

local function staffFigure(parent: Instance, functionId: string, index: number, position: Vector3, role: string, accent: Color3)
	local group = model(parent, string.format("Staff_%02d_%s", index, role), functionId)
	group:SetAttribute("StaffRole", role)
	group:SetAttribute("OccupationPrototype", true)
	local pad = block(group, "WorkAnchor", Vector3.new(position.X, 0.45, position.Z), Vector3.new(2.8, 0.12, 2.8), C.Green, Enum.Material.Neon, false, 0.62, functionId)
	pad:SetAttribute("StaffWorkAnchor", true)
	local body = cylinder(group, "Body", Vector3.new(position.X, 3, position.Z), Vector3.new(4.2, 2.1, 2.1), Vector3.new(0, 0, 90), C.Navy, Enum.Material.SmoothPlastic, false, functionId)
	body.Transparency = 0.12
	block(group, "HiVisStripe", Vector3.new(position.X, 3.25, position.Z - 1.08), Vector3.new(1.2, 0.45, 0.08), accent, Enum.Material.Neon, false, 0.1, functionId)
	local head = block(group, "Head", Vector3.new(position.X, 5.75, position.Z), Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(190, 148, 112), Enum.Material.SmoothPlastic, false, nil, functionId)
	head.Shape = Enum.PartType.Ball
end

local function statusBoard(parent: Instance, data: FunctionData, positionZ: number, lines: {string})
	local c = context(data)
	local face = if data.Side < 0 then Enum.NormalId.Right else Enum.NormalId.Left
	local board = block(parent, "JobControlBoard", Vector3.new(c.WallX, 7.1, positionZ), Vector3.new(0.32, 6.8, 13), C.Navy, Enum.Material.Metal, false, nil, data.Name)
	surfaceText(board, string.upper(data.Name), face, C.White)
	for i, line in ipairs(lines) do
		local z = positionZ - 4.2 + (i - 1) * 2.1
		local lamp = block(parent, "StatusLamp_" .. i, Vector3.new(c.WallX - data.Side * 0.22, 4.8 + (i % 2) * 1.1, z), Vector3.new(0.16, 0.55, 1.4), i == 1 and data.Accent or i == 2 and C.Green or C.Yellow, Enum.Material.Neon, false, nil, data.Name)
		lamp:SetAttribute("StatusMeaning", line)
	end
end

local function commonDepartment(parent: Instance, data: FunctionData, effect: string): Model
	local c = context(data)
	local department = model(parent, data.Name, data.Name)
	department:SetAttribute("CompositionLayers", 10)
	department:SetAttribute("MaximumBays", 2)
	department:SetAttribute("RouteGeometryChanged", false)
	department:SetAttribute("ProtectedStaffAisleWidth", 6)
	department:SetAttribute("HeroSystemRequired", true)

	local floor = model(department, "01_Bay_Floor_and_Transformation", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		block(floor, "BayDeck_" .. bayIndex, Vector3.new(c.BayX, 0.48, bayZ), Vector3.new(31, 0.12, 13), Color3.fromRGB(61, 66, 70), Enum.Material.DiamondPlate, false, 0.15, data.Name)
		block(floor, "CenterServiceLine_" .. bayIndex, Vector3.new(c.BayX, 0.56, bayZ), Vector3.new(23, 0.06, 0.42), data.Accent, Enum.Material.Neon, false, 0.20, data.Name)
		for _, zOffset in ipairs({-6.2, 6.2}) do
			block(floor, "BayEdge_" .. bayIndex, Vector3.new(c.BayX, 0.55, bayZ + zOffset), Vector3.new(28, 0.07, 0.28), C.White, Enum.Material.Neon, false, 0.32, data.Name)
		end
		taskLight(floor, "OverheadTaskLight_" .. bayIndex, Vector3.new(c.BayX, 13.25, bayZ), Vector3.new(18, 0.24, 1.0), data.Name)
		effectAnchor(floor, data.Name, bayIndex, Vector3.new(c.BayX, 3.1, bayZ), effect)
	end

	local aisle = model(department, "08_Staff_Aisle_and_Occupation", data.Name)
	block(aisle, "ProtectedStaffAisle", Vector3.new(c.InnerAisleX, 0.5, data.Z), Vector3.new(6, 0.08, data.Depth - 6), C.Green, Enum.Material.Neon, false, 0.76, data.Name)
	staffFigure(aisle, data.Name, 1, Vector3.new(c.InnerAisleX, 0, data.Z - data.Depth * 0.26), data.Name .. "_LEAD", data.Accent)
	staffFigure(aisle, data.Name, 2, Vector3.new(c.InnerAisleX, 0, data.Z + data.Depth * 0.26), data.Name .. "_TECH", data.Accent)

	local identity = model(department, "10_Identity_and_Status", data.Name)
	local sign = block(identity, "DepartmentIdentity", Vector3.new(c.WallX - data.Side * 0.18, 10.4, data.Z), Vector3.new(0.28, 2.8, math.min(20, data.Depth - 10)), C.Navy, Enum.Material.Metal, false, nil, data.Name)
	surfaceText(sign, string.gsub(string.upper(data.Name), "_", " / "), if data.Side < 0 then Enum.NormalId.Right else Enum.NormalId.Left, data.Accent)
	block(identity, "IdentityLight", Vector3.new(c.WallX - data.Side * 0.38, 8.55, data.Z), Vector3.new(0.14, 0.24, math.min(20, data.Depth - 10)), data.Accent, Enum.Material.Neon, false, 0.08, data.Name)
	return department
end

local function addWash(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "CLEANLINESS_TO_GOOD")
	local hero = model(d, "02_Hero_Collector_Safe_Wash_Arches", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		for _, edge in ipairs({-8.35, 8.35}) do
			block(hero, "ArchPost_" .. bayIndex, Vector3.new(c.BayX, 5.4, bayZ + edge), Vector3.new(1.1, 9.8, 1.1), data.Accent, Enum.Material.Metal, true, nil, data.Name)
			local brush = cylinder(hero, "SoftBrush_" .. bayIndex, Vector3.new(c.BayX, 5.0, bayZ + edge * 0.92), Vector3.new(7.2, 3.1, 3.1), Vector3.new(0, 0, 90), edge < 0 and C.Cyan or C.Blue, Enum.Material.Fabric, false, data.Name)
			brush.Transparency = 0.10
		end
		block(hero, "ArchHeader_" .. bayIndex, Vector3.new(c.BayX, 10.55, bayZ), Vector3.new(1.2, 1, 17.7), C.Navy, Enum.Material.Metal, true, nil, data.Name)
		local topBrush = cylinder(hero, "TopBrush_" .. bayIndex, Vector3.new(c.BayX, 8.6, bayZ), Vector3.new(13.5, 3.0, 3.0), Vector3.new(0, 90, 0), C.Cyan, Enum.Material.Fabric, false, data.Name)
		topBrush.Transparency = 0.12
		for nozzle = -1, 1 do
			local n = block(hero, "PressureNozzle_" .. bayIndex, Vector3.new(c.BayX - data.Side * 3, 7.6, bayZ + nozzle * 3.8), Vector3.new(0.45, 0.45, 0.75), C.Yellow, Enum.Material.Metal, false, nil, data.Name)
			n:SetAttribute("VehicleEffect", "PRESSURE_STEAM_RINSE")
		end
	end

	local utilities = model(d, "03_Reclaim_Chemistry_and_Drying", data.Name)
	for i, zOffset in ipairs({-13, 0, 13}) do
		cylinder(utilities, "ReclaimTank_" .. i, Vector3.new(c.EquipmentX, 3.7, data.Z + zOffset), Vector3.new(7.0, 4.2, 4.2), Vector3.new(0, 0, 90), i == 1 and C.Blue or C.Teal, Enum.Material.Metal, true, data.Name)
		block(utilities, "TankGauge_" .. i, Vector3.new(c.EquipmentX - data.Side * 2.2, 4.6, data.Z + zOffset), Vector3.new(0.22, 1.4, 1.4), C.Cyan, Enum.Material.Neon, false, nil, data.Name)
	end
	block(utilities, "PumpSkid", Vector3.new(c.ServiceX, 1.3, data.Z - 5), Vector3.new(8, 2.6, 6), C.Steel, Enum.Material.DiamondPlate, true, nil, data.Name)
	for i = 0, 2 do
		cylinder(utilities, "PumpMotor_" .. i, Vector3.new(c.ServiceX + data.Side * (2.4 - i * 2.4), 3.0, data.Z - 5), Vector3.new(2.4, 1.5, 1.5), Vector3.new(0, 0, 0), C.Blue, Enum.Material.Metal, false, data.Name)
	end
	block(utilities, "ChemistryCabinet", Vector3.new(c.EquipmentX, 4.0, data.Z + 16), Vector3.new(7.5, 8, 6), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 5 do
		block(utilities, "DoseBottle_" .. i, Vector3.new(c.EquipmentX - data.Side * 4, 1.5 + math.floor(i / 3) * 2.4, data.Z + 13.8 + (i % 3) * 2.1), Vector3.new(1, 1.8, 1), i % 2 == 0 and C.Yellow or C.Orange, Enum.Material.SmoothPlastic, false, nil, data.Name)
	end
	block(utilities, "DryerPlant", Vector3.new(c.ServiceX, 7.8, data.Z - 17), Vector3.new(8, 5.5, 5), C.Steel, Enum.Material.Metal, true, nil, data.Name)
	for i = -1, 1 do cylinder(utilities, "DryerFan_" .. i, Vector3.new(c.ServiceX - data.Side * 4.1, 7.8, data.Z - 17 + i * 1.5), Vector3.new(0.4, 1.2, 1.2), Vector3.new(0, 0, 0), C.Rubber, Enum.Material.Metal, false, data.Name) end
	statusBoard(d, data, data.Z, {"WATER_RECLAIM", "SOFT_RINSE", "READY"})
end

local function addMechanical(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "MECHANICAL_TO_GOOD")
	local hero = model(d, "02_Hero_Two_Post_Lift_Systems", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		for _, edge in ipairs({-8.4, 8.4}) do
			block(hero, "LiftColumn_" .. bayIndex, Vector3.new(c.BayX, 5.4, bayZ + edge), Vector3.new(2.0, 10.2, 1.1), C.Red, Enum.Material.Metal, true, nil, data.Name)
			block(hero, "LiftCarriage_" .. bayIndex, Vector3.new(c.BayX - data.Side * 0.2, 3.0, bayZ + edge * 0.94), Vector3.new(2.3, 1.7, 1.5), C.Dark, Enum.Material.Metal, false, nil, data.Name)
		end
		block(hero, "LiftHeader_" .. bayIndex, Vector3.new(c.BayX, 10.9, bayZ), Vector3.new(2.1, 0.9, 17.8), C.Navy, Enum.Material.Metal, true, nil, data.Name)
		for _, xOffset in ipairs({-5.5, 5.5}) do
			for _, zOffset in ipairs({-3.1, 3.1}) do
				oriented(hero, "LiftArm_" .. bayIndex, Vector3.new(c.BayX + xOffset, 1.0, bayZ + zOffset), Vector3.new(8, 0.32, 0.65), Vector3.new(0, xOffset * 2.5, 0), C.Yellow, Enum.Material.Metal, false, nil, data.Name)
			end
		end
	end

	local diagnostics = model(d, "03_Diagnostics_and_Job_Control", data.Name)
	for i, zOffset in ipairs({-18, -9, 0, 9}) do
		local screen = block(diagnostics, "DiagnosticDisplay_" .. i, Vector3.new(c.WallX - data.Side * 0.22, 7.0, data.Z + zOffset), Vector3.new(0.15, 3.2, 6.0), C.Cyan, Enum.Material.Neon, false, nil, data.Name)
		screen:SetAttribute("DisplayMode", ({"ENGINE", "COOLING", "FLUIDS", "FAULTS"})[i])
	end
	block(diagnostics, "MobileScanCart", Vector3.new(c.ServiceX, 2.3, data.Z - 20), Vector3.new(6, 4.6, 5), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	block(diagnostics, "ScanMonitor", Vector3.new(c.ServiceX - data.Side * 3.1, 5.2, data.Z - 20), Vector3.new(0.35, 3, 4.2), C.Cyan, Enum.Material.Neon, false, nil, data.Name)

	local equipment = model(d, "04_Powertrain_Wheels_Fluids_and_Tools", data.Name)
	block(equipment, "ToolVault", Vector3.new(c.EquipmentX, 4, data.Z + 20), Vector3.new(8, 8, 12), C.Red, Enum.Material.Metal, true, nil, data.Name)
	for drawer = 0, 5 do block(equipment, "ToolDrawer_" .. drawer, Vector3.new(c.EquipmentX - data.Side * 4.1, 1.0 + drawer * 0.95, data.Z + 20), Vector3.new(0.18, 0.7, 10.5), C.Dark, Enum.Material.Metal, false, nil, data.Name) end
	block(equipment, "EngineStandBase", Vector3.new(c.ServiceX, 1.2, data.Z + 7), Vector3.new(7, 1, 5), C.Blue, Enum.Material.Metal, true, nil, data.Name)
	block(equipment, "EngineBlock", Vector3.new(c.ServiceX, 4.3, data.Z + 7), Vector3.new(5.2, 3.6, 4), C.Dark, Enum.Material.Metal, false, nil, data.Name)
	block(equipment, "ValveCover", Vector3.new(c.ServiceX, 6.25, data.Z + 7), Vector3.new(4.1, 0.7, 3.2), C.Red, Enum.Material.Metal, false, nil, data.Name)
	for i = 0, 5 do
		cylinder(equipment, "Tyre_" .. i, Vector3.new(c.EquipmentX, 2.2 + math.floor(i / 3) * 4.2, data.Z - 15 + (i % 3) * 4.2), Vector3.new(1.8, 3.5, 3.5), Vector3.new(0, 0, 0), C.Rubber, Enum.Material.Rubber, false, data.Name)
	end
	cylinder(equipment, "CompressorTank", Vector3.new(c.EquipmentX, 2.2, data.Z - 25), Vector3.new(7.2, 3.5, 3.5), Vector3.new(0, 90, 0), C.Red, Enum.Material.Metal, true, data.Name)
	block(equipment, "FluidStation", Vector3.new(c.ServiceX, 4, data.Z + 27), Vector3.new(7, 8, 5), C.Blue, Enum.Material.Metal, true, nil, data.Name)
	for i, color in ipairs({C.Amber, C.Cyan, C.Green}) do cylinder(equipment, "FluidDrum_" .. i, Vector3.new(c.ServiceX - data.Side * 3.7, 1.7 + i * 1.7, data.Z + 25 + i * 1.5), Vector3.new(2.4, 1.5, 1.5), Vector3.new(0, 0, 0), color, Enum.Material.Metal, false, data.Name) end
	statusBoard(d, data, data.Z, {"ENGINE", "COOLING", "FLUIDS"})
end

local function addBody(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "BODY_FRAME_TO_GOOD")
	local hero = model(d, "02_Hero_Frame_and_Coachwork_Benches", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		block(hero, "FrameBench_" .. bayIndex, Vector3.new(c.BayX, 0.82, bayZ), Vector3.new(25, 0.45, 8), C.Dark, Enum.Material.DiamondPlate, false, nil, data.Name)
		for _, edge in ipairs({-8.4, 8.4}) do
			block(hero, "PullTower_" .. bayIndex, Vector3.new(c.BayX + data.Side * 2, 3.6, bayZ + edge), Vector3.new(2.4, 6.2, 1.0), C.Orange, Enum.Material.Metal, true, nil, data.Name)
			block(hero, "MeasureLaser_" .. bayIndex, Vector3.new(c.BayX - data.Side * 1.2, 6.3, bayZ + edge * 0.95), Vector3.new(0.5, 0.5, 1.2), C.Cyan, Enum.Material.Neon, false, nil, data.Name)
		end
		for _, xOffset in ipairs({-8, 0, 8}) do block(hero, "BenchClamp_" .. bayIndex, Vector3.new(c.BayX + xOffset, 1.35, bayZ), Vector3.new(1.1, 1.0, 3.8), C.Yellow, Enum.Material.Metal, false, nil, data.Name) end
	end

	local hotWork = model(d, "03_Welding_Forming_and_Extraction", data.Name)
	block(hotWork, "WeldingScreen", Vector3.new(c.EquipmentX, 4.2, data.Z - 22), Vector3.new(7, 8, 10), C.Glass, Enum.Material.Glass, true, 0.42, data.Name)
	block(hotWork, "SpotWelder", Vector3.new(c.ServiceX, 3.4, data.Z - 21), Vector3.new(5.5, 6.2, 4.5), C.Orange, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 1 do cylinder(hotWork, "WeldingGas_" .. i, Vector3.new(c.EquipmentX, 3.4, data.Z - 10 + i * 4), Vector3.new(6.2, 1.8, 1.8), Vector3.new(0, 0, 90), i == 0 and C.Cyan or C.Red, Enum.Material.Metal, true, data.Name) end
	block(hotWork, "ExtractionHood", Vector3.new(c.ServiceX, 10.7, data.Z - 21), Vector3.new(7, 1.6, 6), C.Dark, Enum.Material.Metal, false, nil, data.Name)

	local craft = model(d, "04_Panel_Craft_Profile_and_Heritage_Storage", data.Name)
	block(craft, "PanelFormingBench", Vector3.new(c.EquipmentX, 3.1, data.Z + 22), Vector3.new(8, 6.2, 13), C.Steel, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 4 do
		oriented(craft, "ProfileTemplate_" .. i, Vector3.new(c.WallX - data.Side * 0.3, 5.5, data.Z + 8 + i * 4), Vector3.new(0.15, 4.5 + (i % 2), 2.8), Vector3.new(0, 0, (i - 2) * 5), i % 2 == 0 and C.Orange or C.White, Enum.Material.Metal, false, nil, data.Name)
	end
	for i = 0, 3 do block(craft, "ProtectedPanel_" .. i, Vector3.new(c.EquipmentX - data.Side * 0.8, 2.2 + i * 1.35, data.Z + 4), Vector3.new(6.2, 0.28, 8), i % 2 == 0 and C.MidSteel or C.Brick, Enum.Material.Metal, false, nil, data.Name) end
	block(craft, "FireSafetyStation", Vector3.new(c.ServiceX, 3.5, data.Z + 30), Vector3.new(5, 7, 4), C.Red, Enum.Material.Metal, true, nil, data.Name)
	statusBoard(d, data, data.Z, {"MEASURE", "PULL", "FABRICATE"})
end

local function addTune(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "RUNNING_GEAR_AND_SPECIAL_BUILD")
	local hero = model(d, "02_Hero_Rolling_Road_and_Chassis_Setup", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		for _, xOffset in ipairs({-5.5, 5.5}) do
			cylinder(hero, "DynoRoller_" .. bayIndex, Vector3.new(c.BayX + xOffset, 0.82, bayZ - 3.8), Vector3.new(5.4, 2.5, 2.5), Vector3.new(0, 90, 0), C.MidSteel, Enum.Material.Metal, false, data.Name)
			cylinder(hero, "DynoRoller_" .. bayIndex, Vector3.new(c.BayX + xOffset, 0.82, bayZ + 3.8), Vector3.new(5.4, 2.5, 2.5), Vector3.new(0, 90, 0), C.MidSteel, Enum.Material.Metal, false, data.Name)
		end
		local fanX = c.BayX + data.Side * 19
		block(hero, "CoolingFanStand_" .. bayIndex, Vector3.new(fanX, 3.8, bayZ), Vector3.new(2.4, 6.8, 12), C.Dark, Enum.Material.Metal, true, nil, data.Name)
		for i = -1, 1 do cylinder(hero, "CoolingFan_" .. bayIndex, Vector3.new(fanX - data.Side * 1.3, 4.2, bayZ + i * 3.4), Vector3.new(0.35, 2.5, 2.5), Vector3.new(0, 0, 0), C.Rubber, Enum.Material.Metal, false, data.Name) end
		for _, edge in ipairs({-8.35, 8.35}) do block(hero, "AlignmentTarget_" .. bayIndex, Vector3.new(c.BayX - data.Side * 3, 4.6, bayZ + edge), Vector3.new(1, 5.5, 1), C.Cyan, Enum.Material.Neon, true, nil, data.Name) end
	end

	local telemetry = model(d, "03_ECU_Telemetry_and_Calibration", data.Name)
	block(telemetry, "TelemetryConsole", Vector3.new(c.EquipmentX, 4, data.Z - 18), Vector3.new(8, 8, 15), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 3 do
		local screen = block(telemetry, "TelemetryScreen_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.15, 5.0 + math.floor(i / 2) * 2.2, data.Z - 21.5 + (i % 2) * 7), Vector3.new(0.16, 1.8, 5.5), i == 3 and C.Yellow or C.Cyan, Enum.Material.Neon, false, nil, data.Name)
		screen:SetAttribute("DataChannel", ({"POWER", "AFR", "CHASSIS", "THERMAL"})[i + 1])
	end
	block(telemetry, "CalibrationDesk", Vector3.new(c.ServiceX, 2.3, data.Z + 2), Vector3.new(7, 4.6, 10), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	block(telemetry, "ECUProgrammer", Vector3.new(c.ServiceX - data.Side * 3.6, 4.8, data.Z + 2), Vector3.new(0.4, 3, 6), C.Purple, Enum.Material.Neon, false, nil, data.Name)

	local hardware = model(d, "04_Aero_Exhaust_Wheels_and_Accessories", data.Name)
	block(hardware, "PerformanceRack", Vector3.new(c.EquipmentX, 4.2, data.Z + 21), Vector3.new(8, 8.4, 13), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 3 do cylinder(hardware, "ExhaustSection_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.2, 1.5 + i * 1.8, data.Z + 18), Vector3.new(0.35, 0.9, 10), Vector3.new(0, 90, 0), C.MidSteel, Enum.Material.Metal, false, data.Name) end
	for i = 0, 3 do oriented(hardware, "AeroProfile_" .. i, Vector3.new(c.WallX - data.Side * 0.28, 5.0 + (i % 2) * 2.2, data.Z + 10 + i * 4), Vector3.new(0.18, 1.0, 4.0), Vector3.new(0, 0, (i - 1.5) * 4), i % 2 == 0 and C.Purple or C.White, Enum.Material.Metal, false, nil, data.Name) end
	block(hardware, "AccessoryVault", Vector3.new(c.ServiceX, 3.8, data.Z + 28), Vector3.new(7, 7.6, 5), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 2 do block(hardware, "NeonModule_" .. i, Vector3.new(c.ServiceX - data.Side * 3.7, 2.0 + i * 2.0, data.Z + 28), Vector3.new(0.18, 0.6, 3.5), ({C.Cyan, C.Pink, C.Purple})[i + 1], Enum.Material.Neon, false, nil, data.Name) end
	statusBoard(d, data, data.Z, {"DYNO", "CHASSIS", "CALIBRATE"})
end

local function addPaint(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "EXTERIOR_AND_FINISH")
	local hero = model(d, "02_Hero_Controlled_Finish_Positions", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		for _, edge in ipairs({-8.3, 8.3}) do
			block(hero, "BoothSideFrame_" .. bayIndex, Vector3.new(c.BayX, 5.0, bayZ + edge), Vector3.new(30, 8.8, 0.6), C.Navy, Enum.Material.Metal, true, nil, data.Name)
			block(hero, "BoothGlassBand_" .. bayIndex, Vector3.new(c.BayX, 5.3, bayZ + edge * 0.97), Vector3.new(27, 4.8, 0.18), C.Glass, Enum.Material.Glass, false, 0.38, data.Name)
		end
		block(hero, "FilterCeiling_" .. bayIndex, Vector3.new(c.BayX, 11.0, bayZ), Vector3.new(28, 0.8, 16.8), C.White, Enum.Material.SmoothPlastic, false, 0.12, data.Name)
		for strip = -1, 1 do taskLight(hero, "ColourLight_" .. bayIndex, Vector3.new(c.BayX, 10.45, bayZ + strip * 4.8), Vector3.new(22, 0.22, 0.7), data.Name) end
		for i = -2, 2 do
			local nozzle = block(hero, "FinishNozzle_" .. bayIndex, Vector3.new(c.BayX - data.Side * (i * 3.1), 7.5, bayZ - data.Side * 7.5), Vector3.new(0.5, 0.5, 0.8), i % 2 == 0 and C.Pink or C.Cyan, Enum.Material.Metal, false, nil, data.Name)
			nozzle:SetAttribute("VehicleEffect", "PAINT_WRAP_TINT")
		end
	end

	local lab = model(d, "03_Mix_Tint_and_Rare_Colour_Laboratory", data.Name)
	block(lab, "MixLabBench", Vector3.new(c.EquipmentX, 3.3, data.Z - 22), Vector3.new(8, 6.6, 15), C.White, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 8 do
		local sample = block(lab, "RareColourSample_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.15, 3.1 + math.floor(i / 3) * 2.1, data.Z - 27 + (i % 3) * 5), Vector3.new(0.14, 1.5, 3.7), ({C.Red, C.Cyan, C.Yellow, C.Purple, C.Green, C.Pink, C.Blue, C.Orange, C.White})[i + 1], Enum.Material.SmoothPlastic, false, nil, data.Name)
		sample:SetAttribute("RareFinishSlot", i + 1)
	end
	block(lab, "SpectralScanner", Vector3.new(c.ServiceX, 4.5, data.Z - 8), Vector3.new(6, 9, 5), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	block(lab, "SpectralDisplay", Vector3.new(c.ServiceX - data.Side * 3.1, 6.0, data.Z - 8), Vector3.new(0.18, 2.8, 3.6), C.Cyan, Enum.Material.Neon, false, nil, data.Name)

	local support = model(d, "04_Wrap_Glass_Extraction_and_Safety", data.Name)
	block(support, "WrapRollVault", Vector3.new(c.EquipmentX, 4.4, data.Z + 22), Vector3.new(8, 8.8, 14), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 5 do cylinder(support, "WrapRoll_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.1, 1.3 + i * 1.35, data.Z + 22), Vector3.new(0.35, 1.0, 11), Vector3.new(0, 90, 0), ({C.Red, C.Cyan, C.Yellow, C.Purple, C.Green, C.White})[i + 1], Enum.Material.Fabric, false, data.Name) end
	block(support, "TintGlassTable", Vector3.new(c.ServiceX, 2.0, data.Z + 7), Vector3.new(7, 4, 10), C.Glass, Enum.Material.Glass, true, 0.32, data.Name)
	block(support, "ExtractionPlenum", Vector3.new(c.EquipmentX, 10.0, data.Z + 1), Vector3.new(8, 3, 16), C.Steel, Enum.Material.Metal, true, nil, data.Name)
	for i = -2, 2 do block(support, "PlenumSlot_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.1, 10, data.Z + 1 + i * 2.5), Vector3.new(0.16, 1.6, 1.3), C.Rubber, Enum.Material.Metal, false, nil, data.Name) end
	block(support, "FireSolventCabinet", Vector3.new(c.ServiceX, 3.7, data.Z + 31), Vector3.new(7, 7.4, 4.5), C.Yellow, Enum.Material.Metal, true, nil, data.Name)
	statusBoard(d, data, data.Z, {"PREP", "COLOUR", "CURE"})
end

local function addDetail(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "FINAL_CLEAN_AND_QC_PASS")
	local hero = model(d, "02_Hero_Correction_Light_Tunnels", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		for _, edge in ipairs({-8.3, 8.3}) do
			block(hero, "LightTunnelRail_" .. bayIndex, Vector3.new(c.BayX, 6.2, bayZ + edge), Vector3.new(25, 0.55, 0.55), C.White, Enum.Material.Neon, true, nil, data.Name)
			for xOffset = -10, 10, 5 do block(hero, "VerticalCorrectionLight_" .. bayIndex, Vector3.new(c.BayX + xOffset, 5.3, bayZ + edge), Vector3.new(0.35, 7.5, 0.35), C.White, Enum.Material.Neon, false, nil, data.Name) end
		end
		block(hero, "GlossScanBridge_" .. bayIndex, Vector3.new(c.BayX, 10.4, bayZ), Vector3.new(2, 0.8, 17), C.Navy, Enum.Material.Metal, true, nil, data.Name)
		block(hero, "GlossSensor_" .. bayIndex, Vector3.new(c.BayX, 9.5, bayZ), Vector3.new(1.2, 1.2, 2), C.Cyan, Enum.Material.Neon, false, nil, data.Name)
	end

	local tools = model(d, "03_Correction_Steam_Vacuum_and_Chemistry", data.Name)
	block(tools, "PolisherCabinet", Vector3.new(c.EquipmentX, 4, data.Z - 18), Vector3.new(8, 8, 13), C.Teal, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 5 do cylinder(tools, "PolishingPad_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.15, 1.6 + math.floor(i / 3) * 3.1, data.Z - 22 + (i % 3) * 4), Vector3.new(0.25, 2.1, 2.1), Vector3.new(0, 0, 0), i % 2 == 0 and C.White or C.Yellow, Enum.Material.Fabric, false, data.Name) end
	block(tools, "SteamExtractor", Vector3.new(c.ServiceX, 2.6, data.Z + 1), Vector3.new(6.5, 5.2, 6), C.Blue, Enum.Material.Metal, true, nil, data.Name)
	cylinder(tools, "VacuumReceiver", Vector3.new(c.ServiceX, 5.5, data.Z + 1), Vector3.new(4.5, 3.5, 3.5), Vector3.new(0, 0, 90), C.Dark, Enum.Material.Metal, false, data.Name)
	block(tools, "ChemistryVault", Vector3.new(c.EquipmentX, 4.1, data.Z + 18), Vector3.new(8, 8.2, 13), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 8 do block(tools, "DetailBottle_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.2, 1.4 + math.floor(i / 3) * 2.3, data.Z + 14 + (i % 3) * 4), Vector3.new(0.18, 1.5, 2.4), ({C.Cyan, C.Green, C.Yellow})[(i % 3) + 1], Enum.Material.SmoothPlastic, false, nil, data.Name) end

	local qc = model(d, "04_Measurement_Records_and_Wet_Dry_Control", data.Name)
	block(qc, "QCConsole", Vector3.new(c.ServiceX, 3.6, data.Z + 24), Vector3.new(7, 7.2, 5), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	block(qc, "QCDisplay", Vector3.new(c.ServiceX - data.Side * 3.6, 5.2, data.Z + 24), Vector3.new(0.2, 2.8, 3.8), C.Green, Enum.Material.Neon, false, nil, data.Name)
	for i = 0, 2 do cylinder(qc, "HoseReel_" .. i, Vector3.new(c.WallX - data.Side * 0.4, 4 + i * 2.2, data.Z - 2 + i * 5), Vector3.new(0.3, 2.2, 2.2), Vector3.new(0, 0, 0), i == 1 and C.Yellow or C.Cyan, Enum.Material.Metal, false, data.Name) end
	block(qc, "WetDryDivider", Vector3.new(c.EquipmentX, 0.58, data.Z), Vector3.new(7.5, 0.12, 2), C.Yellow, Enum.Material.Neon, false, 0.2, data.Name)
	statusBoard(d, data, data.Z, {"CORRECT", "CLEAN", "QC_PASS"})
end

local function addPhoto(parent: Instance, data: FunctionData)
	local c = context(data)
	local d = commonDepartment(parent, data, "LISTING_PRICE_AND_BUILD_STORY")
	local hero = model(d, "02_Hero_Turntables_and_Editorial_Lighting", data.Name)
	for bayIndex, offset in ipairs({-12, 12}) do
		local bayZ = data.Z + offset
		cylinder(hero, "Turntable_" .. bayIndex, Vector3.new(c.BayX, 0.66, bayZ), Vector3.new(0.28, 13.2, 13.2), Vector3.new(0, 0, 90), C.MidSteel, Enum.Material.DiamondPlate, false, data.Name)
		local backdropX = c.BayX + data.Side * 18.5
		block(hero, "EditorialBackdrop_" .. bayIndex, Vector3.new(backdropX, 5.2, bayZ), Vector3.new(1, 9.4, 13), C.White, Enum.Material.SmoothPlastic, true, nil, data.Name)
		for _, edge in ipairs({-8.35, 8.35}) do
			block(hero, "LightStand_" .. bayIndex, Vector3.new(c.BayX - data.Side * 2, 5.4, bayZ + edge), Vector3.new(1, 9.5, 0.7), C.Dark, Enum.Material.Metal, true, nil, data.Name)
			oriented(hero, "SoftBox_" .. bayIndex, Vector3.new(c.BayX - data.Side * 2, 7.0, bayZ + edge * 0.95), Vector3.new(4.5, 3.5, 0.35), Vector3.new(0, 0, edge < 0 and 12 or -12), C.WarmWhite, Enum.Material.Neon, false, 0.08, data.Name)
		end
		block(hero, "CameraRail_" .. bayIndex, Vector3.new(c.BayX, 11.5, bayZ), Vector3.new(25, 0.55, 0.55), C.Dark, Enum.Material.Metal, false, nil, data.Name)
		local camera = block(hero, "TrackedCamera_" .. bayIndex, Vector3.new(c.BayX - data.Side * 7, 10.2, bayZ), Vector3.new(2.4, 1.7, 2), C.Navy, Enum.Material.Metal, false, nil, data.Name)
		camera:SetAttribute("VehicleEffect", "CAPTURE_LISTING_MEDIA")
	end

	local editorial = model(d, "03_Listing_Provenance_and_Editorial_Desk", data.Name)
	block(editorial, "EditingDesk", Vector3.new(c.EquipmentX, 3.0, data.Z - 16), Vector3.new(8, 6, 13), C.Dark, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 2 do
		block(editorial, "EditMonitor_" .. i, Vector3.new(c.EquipmentX - data.Side * 4.2, 5.2, data.Z - 20 + i * 4), Vector3.new(0.16, 2.2, 3.3), i == 1 and C.Yellow or C.Blue, Enum.Material.Neon, false, nil, data.Name)
	end
	block(editorial, "ProvenanceScanner", Vector3.new(c.ServiceX, 3.8, data.Z + 1), Vector3.new(6, 7.6, 6), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	block(editorial, "ScannerGlass", Vector3.new(c.ServiceX - data.Side * 3.1, 4.6, data.Z + 1), Vector3.new(0.18, 3.3, 4.2), C.Cyan, Enum.Material.Glass, false, 0.25, data.Name)

	local archive = model(d, "04_Media_Archive_and_Secure_Equipment", data.Name)
	block(archive, "MediaArchive", Vector3.new(c.EquipmentX, 4.2, data.Z + 17), Vector3.new(8, 8.4, 13), C.Navy, Enum.Material.Metal, true, nil, data.Name)
	for row = 0, 3 do
		for column = 0, 2 do
			local card = block(archive, "BuildStoryCard_" .. row .. "_" .. column, Vector3.new(c.EquipmentX - data.Side * 4.2, 1.3 + row * 1.8, data.Z + 13 + column * 4), Vector3.new(0.14, 1.2, 3.1), (row + column) % 2 == 0 and C.WarmWhite or C.Blue, Enum.Material.SmoothPlastic, false, nil, data.Name)
			card:SetAttribute("RecordType", "CAR_BUILD_HISTORY")
		end
	end
	block(archive, "CameraVault", Vector3.new(c.ServiceX, 3.8, data.Z + 24), Vector3.new(7, 7.6, 4.5), C.Steel, Enum.Material.Metal, true, nil, data.Name)
	for i = 0, 3 do cylinder(archive, "LensCase_" .. i, Vector3.new(c.ServiceX - data.Side * 3.6, 1.5 + i * 1.65, data.Z + 24), Vector3.new(0.3, 1.2, 1.2), Vector3.new(0, 0, 0), C.Rubber, Enum.Material.SmoothPlastic, false, data.Name) end
	statusBoard(d, data, data.Z, {"CAPTURE", "PROVENANCE", "LISTED"})
end

local function hideHeroReserves(root: Model): number
	local count = 0
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") and item.Name == "HeroEquipmentReserve" then
			if item:GetAttribute("ProductionASavedTransparency") == nil then
				item:SetAttribute("ProductionASavedTransparency", item.Transparency)
				item:SetAttribute("ProductionASavedCanCollide", item.CanCollide)
				item:SetAttribute("ProductionASavedCanTouch", item.CanTouch)
				item:SetAttribute("ProductionASavedCanQuery", item.CanQuery)
			end
			item.Transparency = 1
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item:SetAttribute("ReplacedByInstitutionProductionA", true)
			count += 1
		end
	end
	return count
end

local function restoreHeroReserves(root: Model)
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("ProductionASavedTransparency") ~= nil then
			item.Transparency = item:GetAttribute("ProductionASavedTransparency") :: number
			item.CanCollide = item:GetAttribute("ProductionASavedCanCollide") :: boolean
			item.CanTouch = item:GetAttribute("ProductionASavedCanTouch") :: boolean
			item.CanQuery = item:GetAttribute("ProductionASavedCanQuery") :: boolean
			item:SetAttribute("ProductionASavedTransparency", nil)
			item:SetAttribute("ProductionASavedCanCollide", nil)
			item:SetAttribute("ProductionASavedCanTouch", nil)
			item:SetAttribute("ProductionASavedCanQuery", nil)
			item:SetAttribute("ReplacedByInstitutionProductionA", nil)
		end
	end
end

local function validate(root: Model, layer: Model): ({string}, {[string]: number}, number, number)
	local clearances = root:FindFirstChild("03_Protected_Clearances")
	assert(clearances, "V5 protected-clearance folder missing")
	local conflicts = {}
	local byFunction: {[string]: number} = {}
	local partCount = 0
	local solidCount = 0
	for _, item in ipairs(layer:GetDescendants()) do
		if item:IsA("BasePart") then
			partCount += 1
			if item:GetAttribute("V5ProductionASolid") then solidCount += 1 end
		end
	end
	for _, envelope in ipairs(clearances:GetDescendants()) do
		if envelope:IsA("BasePart") and envelope:GetAttribute("V5ProtectedEnvelope") then
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {layer}
			params.RespectCanCollide = false
			for _, hit in ipairs(Workspace:GetPartBoundsInBox(envelope.CFrame, envelope.Size, params)) do
				if hit:IsA("BasePart") and hit:GetAttribute("V5ProductionASolid") then
					local id = hit:GetAttribute("FunctionId") or "UNKNOWN"
					byFunction[id] = (byFunction[id] or 0) + 1
					table.insert(conflicts, envelope.Name .. " <- " .. hit:GetFullName())
					hit:SetAttribute("V5ProductionAConflict", envelope.Name)
				end
			end
		end
	end
	return conflicts, byFunction, partCount, solidCount
end

function Installer.Install(): {[string]: any}
	assert(game.PlaceId == 125334614375606, "Production A installer must run only in Sell Cars Tycoon")
	local root = Workspace:FindFirstChild(ROOT_NAME)
	assert(root and root:IsA("Model"), "V5 Institution root is missing")
	assert(root:GetAttribute("StaticValidationStatus") == "PASS", "V5 static geometry is not accepted")
	assert(root:GetAttribute("DynamicValidationStatus") == "PASS", "V5 route proof is not accepted")

	local previous = root:FindFirstChild(LAYER_NAME)
	if previous then previous:Destroy() end
	local reservesHidden = hideHeroReserves(root)

	local layer = model(root, LAYER_NAME)
	layer:SetAttribute("Version", Installer.Version)
	layer:SetAttribute("Checkpoint", "V5_INSTITUTION_PRODUCTION_A")
	layer:SetAttribute("StateId", "INSTITUTION")
	layer:SetAttribute("DepartmentCount", 7)
	layer:SetAttribute("MaxProductionBays", 2)
	layer:SetAttribute("Bay3Count", 0)
	layer:SetAttribute("TrafficLayoutChanged", false)
	layer:SetAttribute("PurchasePadsIncluded", false)
	layer:SetAttribute("FinalArt", false)
	layer:SetAttribute("Purpose", "Complete function-specific production composition")

	for _, data in ipairs(FUNCTIONS) do
		if data.Name == "Wash" then addWash(layer, data :: FunctionData)
		elseif data.Name == "Mechanical" then addMechanical(layer, data :: FunctionData)
		elseif data.Name == "Body_Restoration" then addBody(layer, data :: FunctionData)
		elseif data.Name == "Tune_Performance" then addTune(layer, data :: FunctionData)
		elseif data.Name == "Paint_Exterior" then addPaint(layer, data :: FunctionData)
		elseif data.Name == "Detail_QC" then addDetail(layer, data :: FunctionData)
		elseif data.Name == "Photo_Listing" then addPhoto(layer, data :: FunctionData)
		end
	end

	local conflicts, byFunction, partCount, solidCount = validate(root, layer)
	local evidence = Instance.new("Folder")
	evidence.Name = "99_Production_A_Evidence"
	evidence.Parent = layer
	evidence:SetAttribute("PartCount", partCount)
	evidence:SetAttribute("SolidPartCount", solidCount)
	evidence:SetAttribute("DepartmentCount", 7)
	evidence:SetAttribute("CompositionLayersPerDepartment", 10)
	evidence:SetAttribute("HeroReservesHidden", reservesHidden)
	evidence:SetAttribute("StaticEnvelopeConflicts", #conflicts)
	evidence:SetAttribute("StaticConflictList", table.concat(conflicts, " | "))
	evidence:SetAttribute("StaticStatus", if #conflicts == 0 then "PASS" else "FAIL")
	for functionId, count in pairs(byFunction) do evidence:SetAttribute(functionId .. "_Conflicts", count) end

	local departmentSummary = {}
	for _, data in ipairs(FUNCTIONS) do
		local department = layer:FindFirstChild(data.Name)
		local count = 0
		if department then
			for _, item in ipairs(department:GetDescendants()) do if item:IsA("BasePart") then count += 1 end end
			department:SetAttribute("PartCount", count)
			department:SetAttribute("StaticEnvelopeConflicts", byFunction[data.Name] or 0)
			department:SetAttribute("CompositionStatus", if (byFunction[data.Name] or 0) == 0 then "COMPLETE_AWAITING_VISUAL_REVIEW" else "BLOCKED")
		end
		table.insert(departmentSummary, data.Name .. ":" .. count)
	end
	evidence:SetAttribute("DepartmentPartSummary", table.concat(departmentSummary, " | "))

	root:SetAttribute("EnvironmentStatus", if #conflicts == 0 then "INSTITUTION_PRODUCTION_A_STATIC_PASS" else "INSTITUTION_PRODUCTION_A_CONFLICT")
	root:SetAttribute("InstitutionProductionAStatus", if #conflicts == 0 then "STATIC_PASS_AWAITING_VISUAL_AND_ROUTE" else "STATIC_FAIL")
	root:SetAttribute("InstitutionProductionAParts", partCount)
	root:SetAttribute("InstitutionProductionAConflicts", #conflicts)
	root:SetAttribute("InstitutionProductionAVersion", Installer.Version)

	return {
		Root = layer:GetFullName(),
		Version = Installer.Version,
		Departments = 7,
		Parts = partCount,
		Solids = solidCount,
		HeroReservesHidden = reservesHidden,
		StaticConflicts = #conflicts,
		Status = evidence:GetAttribute("StaticStatus"),
		DepartmentPartSummary = evidence:GetAttribute("DepartmentPartSummary"),
	}
end

function Installer.Uninstall()
	local root = Workspace:FindFirstChild(ROOT_NAME)
	if not root or not root:IsA("Model") then return end
	local layer = root:FindFirstChild(LAYER_NAME)
	if layer then layer:Destroy() end
	restoreHeroReserves(root)
	root:SetAttribute("EnvironmentStatus", "STATIC_GREYBOX_INSTALLED")
	root:SetAttribute("InstitutionProductionAStatus", nil)
	root:SetAttribute("InstitutionProductionAParts", nil)
	root:SetAttribute("InstitutionProductionAConflicts", nil)
	root:SetAttribute("InstitutionProductionAVersion", nil)
end

return Installer

