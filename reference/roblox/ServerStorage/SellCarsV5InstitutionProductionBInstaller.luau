--!strict

-- Sell Cars V5 — Institution Production B.
-- Completes the commercial frontage, rear operating campus, Owner Garage,
-- Collector Hall and estate identity around the accepted V5 route skeleton.

local Workspace = game:GetService("Workspace")

local Installer = {}
Installer.Version = "2026-09-03.v5-institution-production-b.1"

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local LAYER_NAME = "09_Institution_Production_B"
local ORIGIN_X = 3130

local C = {
	Navy = Color3.fromRGB(18, 29, 43),
	DeepNavy = Color3.fromRGB(10, 18, 30),
	Charcoal = Color3.fromRGB(35, 39, 43),
	Steel = Color3.fromRGB(70, 80, 88),
	MidSteel = Color3.fromRGB(103, 114, 121),
	Silver = Color3.fromRGB(171, 181, 185),
	White = Color3.fromRGB(230, 235, 234),
	WarmWhite = Color3.fromRGB(246, 229, 194),
	Glass = Color3.fromRGB(94, 180, 207),
	Gold = Color3.fromRGB(236, 184, 55),
	Amber = Color3.fromRGB(235, 125, 45),
	Red = Color3.fromRGB(216, 57, 49),
	Cyan = Color3.fromRGB(38, 205, 220),
	Teal = Color3.fromRGB(48, 171, 149),
	Blue = Color3.fromRGB(54, 126, 202),
	Purple = Color3.fromRGB(126, 88, 210),
	Green = Color3.fromRGB(66, 177, 112),
	Brick = Color3.fromRGB(125, 62, 45),
	Concrete = Color3.fromRGB(145, 142, 132),
	Sand = Color3.fromRGB(180, 145, 96),
	Plant = Color3.fromRGB(73, 112, 67),
	Rubber = Color3.fromRGB(22, 24, 27),
}

local function model(parent: Instance, name: string, zone: string?): Model
	local result = Instance.new("Model")
	result.Name = name
	result:SetAttribute("V5ProductionB", true)
	if zone then result:SetAttribute("ZoneId", zone) end
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
	zone: string?
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
	result.CastShadow = result.Transparency < 0.65
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result:SetAttribute("V5ProductionBDetail", true)
	if zone then result:SetAttribute("ZoneId", zone) end
	if solid then
		result:SetAttribute("V5ProductionBSolid", true)
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
	zone: string?
): Part
	return part(parent, name, size, CFrame.new(position), color, material, solid, transparency, zone)
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
	zone: string?
): Part
	return part(parent, name, size, CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)), color, material, solid, transparency, zone)
end

local function cylinder(parent: Instance, name: string, position: Vector3, size: Vector3, rotation: Vector3, color: Color3, material: Enum.Material?, solid: boolean?, zone: string?): Part
	local result = oriented(parent, name, position, size, rotation, color, material, solid, nil, zone)
	result.Shape = Enum.PartType.Cylinder
	return result
end

local function surfaceText(target: BasePart, value: string, face: Enum.NormalId, color: Color3, small: boolean?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "InstitutionLabel"
	gui.Face = face
	gui.CanvasSize = if small then Vector2.new(420, 120) else Vector2.new(900, 180)
	gui.LightInfluence = 0.15
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

local function taskLight(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, brightness: number, range: number, zone: string)
	local fixture = block(parent, name, position, size, color, Enum.Material.Neon, false, 0.04, zone)
	local light = Instance.new("PointLight")
	light.Name = "InstitutionLight"
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = fixture
end

local function person(parent: Instance, name: string, position: Vector3, uniform: Color3, role: string, zone: string)
	local figure = model(parent, name, zone)
	figure:SetAttribute("OccupationPrototype", true)
	figure:SetAttribute("Role", role)
	local anchor = block(figure, "OccupationAnchor", Vector3.new(position.X, 0.35, position.Z), Vector3.new(2.6, 0.08, 2.6), C.Green, Enum.Material.Neon, false, 0.7, zone)
	anchor:SetAttribute("OccupationAnchor", true)
	local torso = cylinder(figure, "Torso", Vector3.new(position.X, 3.0, position.Z), Vector3.new(4.0, 2.0, 2.0), Vector3.new(0, 0, 90), uniform, Enum.Material.SmoothPlastic, false, zone)
	torso.Transparency = 0.12
	local head = block(figure, "Head", Vector3.new(position.X, 5.55, position.Z), Vector3.new(1.7, 1.7, 1.7), Color3.fromRGB(194, 151, 112), Enum.Material.SmoothPlastic, false, nil, zone)
	head.Shape = Enum.PartType.Ball
end

local function bollard(parent: Instance, name: string, position: Vector3, color: Color3, zone: string)
	cylinder(parent, name, position, Vector3.new(2.4, 1.1, 1.1), Vector3.new(0, 0, 90), color, Enum.Material.Metal, true, zone)
end

local function plant(parent: Instance, name: string, position: Vector3, scale: number, zone: string)
	local group = model(parent, name, zone)
	block(group, "Planter", Vector3.new(position.X, 0.65 * scale, position.Z), Vector3.new(3.2 * scale, 1.3 * scale, 3.2 * scale), C.Charcoal, Enum.Material.Concrete, true, nil, zone)
	for i = 1, 5 do
		local angle = math.rad((i - 1) * 72)
		oriented(group, "DesertLeaf", Vector3.new(position.X + math.cos(angle) * 0.6 * scale, 2.2 * scale, position.Z + math.sin(angle) * 0.6 * scale), Vector3.new(0.45 * scale, 3.3 * scale, 0.8 * scale), Vector3.new(math.sin(angle) * 18, -math.deg(angle), math.cos(angle) * 18), C.Plant, Enum.Material.SmoothPlastic, false, nil, zone)
	end
end

local function bench(parent: Instance, name: string, position: Vector3, rotationY: number, zone: string)
	local group = model(parent, name, zone)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
	part(group, "Seat", Vector3.new(7, 0.55, 2.2), cf * CFrame.new(0, 2.1, 0), C.Sand, Enum.Material.WoodPlanks, true, nil, zone)
	part(group, "Back", Vector3.new(7, 2.8, 0.45), cf * CFrame.new(0, 3.3, 0.95), C.Sand, Enum.Material.WoodPlanks, true, nil, zone)
	for _, x in ipairs({-2.6, 2.6}) do
		part(group, "Leg", Vector3.new(0.5, 2, 0.5), cf * CFrame.new(x, 1, 0), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	end
end

local function car(parent: Instance, name: string, position: Vector3, rotationY: number, color: Color3, zone: string, snapshot: boolean?): Model
	local group = model(parent, name, zone)
	group:SetAttribute("VehicleDisplay", true)
	group:SetAttribute("SnapshotOnly", snapshot == true)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
	local body = part(group, "Body", Vector3.new(9.8, 2.25, 17.5), cf * CFrame.new(0, 2.15, 0), color, Enum.Material.Metal, false, nil, zone)
	body.Reflectance = 0.08
	local cabin = part(group, "Cabin", Vector3.new(7.4, 2.4, 8.2), cf * CFrame.new(0, 4.05, 0.8), C.DeepNavy, Enum.Material.Glass, false, 0.16, zone)
	local hood = part(group, "HoodHighlight", Vector3.new(7.8, 0.18, 4.8), cf * CFrame.new(0, 3.36, -5.2), color:Lerp(C.White, 0.16), Enum.Material.Metal, false, nil, zone)
	for _, x in ipairs({-4.8, 4.8}) do
		for _, z in ipairs({-5.9, 5.9}) do
			local wheel = part(group, "Wheel", Vector3.new(1.1, 2.7, 2.7), cf * CFrame.new(x, 1.15, z) * CFrame.Angles(0, 0, math.rad(90)), C.Rubber, Enum.Material.Rubber, false, nil, zone)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	for _, x in ipairs({-3.1, 3.1}) do
		part(group, "Headlamp", Vector3.new(1.8, 0.55, 0.18), cf * CFrame.new(x, 2.25, -8.82), C.WarmWhite, Enum.Material.Neon, false, 0.05, zone)
	end
	group.PrimaryPart = body
	return group
end

local function desk(parent: Instance, name: string, position: Vector3, width: number, accent: Color3, zone: string)
	local group = model(parent, name, zone)
	block(group, "Worktop", Vector3.new(position.X, position.Y + 3.2, position.Z), Vector3.new(width, 0.55, 3.4), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	block(group, "FrontPanel", Vector3.new(position.X, position.Y + 1.65, position.Z + 1.25), Vector3.new(width - 0.8, 2.8, 0.45), C.Navy, Enum.Material.Metal, true, nil, zone)
	block(group, "Accent", Vector3.new(position.X, position.Y + 2.1, position.Z + 1.51), Vector3.new(width - 1.2, 0.22, 0.08), accent, Enum.Material.Neon, false, 0.05, zone)
	block(group, "Screen", Vector3.new(position.X, position.Y + 5.25, position.Z - 0.3), Vector3.new(math.min(4.2, width - 1), 2.2, 0.35), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	block(group, "ScreenGlow", Vector3.new(position.X, position.Y + 5.25, position.Z - 0.49), Vector3.new(math.min(3.5, width - 1.4), 1.5, 0.05), accent, Enum.Material.Neon, false, 0.12, zone)
end

local function rack(parent: Instance, name: string, position: Vector3, size: Vector3, accent: Color3, zone: string)
	local group = model(parent, name, zone)
	for _, x in ipairs({-size.X / 2 + 0.25, size.X / 2 - 0.25}) do
		block(group, "Upright", position + Vector3.new(x, size.Y / 2, 0), Vector3.new(0.45, size.Y, size.Z), C.Steel, Enum.Material.DiamondPlate, true, nil, zone)
	end
	for i = 0, 3 do
		local y = 0.7 + i * ((size.Y - 0.9) / 3)
		block(group, "Shelf", position + Vector3.new(0, y, 0), Vector3.new(size.X, 0.32, size.Z), C.MidSteel, Enum.Material.Metal, true, nil, zone)
		if i < 3 then
			for j = -1, 1 do
				block(group, "Inventory", position + Vector3.new(j * size.X * 0.24, y + 0.75, 0), Vector3.new(size.X * 0.18, 1.1, size.Z * 0.68), if (i + j) % 2 == 0 then accent else C.Sand, Enum.Material.SmoothPlastic, false, nil, zone)
			end
		end
	end
end

local function hideReservePart(item: BasePart, reason: string)
	item:SetAttribute("V5ProductionBOriginalTransparency", item.Transparency)
	item:SetAttribute("V5ProductionBOriginalCanCollide", item.CanCollide)
	item:SetAttribute("V5ProductionBHidden", true)
	item:SetAttribute("V5ProductionBHiddenReason", reason)
	item.Transparency = 1
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
end

local function restoreHidden(root: Instance)
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("V5ProductionBHidden") then
			local t = item:GetAttribute("V5ProductionBOriginalTransparency")
			local c = item:GetAttribute("V5ProductionBOriginalCanCollide")
			if typeof(t) == "number" then item.Transparency = t end
			if typeof(c) == "boolean" then item.CanCollide = c end
			item.CanTouch = false
			item.CanQuery = true
			item:SetAttribute("V5ProductionBOriginalTransparency", nil)
			item:SetAttribute("V5ProductionBOriginalCanCollide", nil)
			item:SetAttribute("V5ProductionBHidden", nil)
			item:SetAttribute("V5ProductionBHiddenReason", nil)
		elseif item:IsA("BillboardGui") and item:GetAttribute("V5ProductionBHidden") then
			item.Enabled = true
			item:SetAttribute("V5ProductionBHidden", nil)
		end
	end
end

local function hideDiagnosticBillboards(root: Instance, layer: Instance): number
	local count = 0
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BillboardGui") and not item:IsDescendantOf(layer) then
			item.Enabled = false
			item:SetAttribute("V5ProductionBHidden", true)
			count += 1
		end
	end
	return count
end

local function hideMassing(root: Instance): number
	local names = {
		LogisticsMassing = true,
		OperationsMassing = true,
		HQLevel1 = true,
		HQLevel2 = true,
		HQLevel3Crown = true,
		HQGlassBand = true,
		CollectorRoof = true,
	}
	local count = 0
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") and names[item.Name] and not item:GetAttribute("V5ProductionBHidden") then
			hideReservePart(item, "Replaced by detailed Production B architecture")
			count += 1
		end
	end
	return count
end

local function buildIntake(parent: Instance)
	local zone = "Intake_Appraisal"
	local intake = model(parent, "01_Intake_Appraisal", zone)
	intake:SetAttribute("OperatingCapacity", 3)
	intake:SetAttribute("OrdinaryPositions", 2)
	intake:SetAttribute("RareTowSharedPositions", 1)

	-- Open canopy: all ground supports sit outside the protected tow/transporter sweep.
	block(intake, "CanopyRoof", Vector3.new(3040, 13.4, 49), Vector3.new(72, 1.0, 72), C.Navy, Enum.Material.Metal, false, 0.12, zone)
	for _, x in ipairs({3005, 3076}) do
		for _, z in ipairs({14, 85}) do
			if not (x == 3076 and z == 85) then
				block(intake, "CanopyColumn", Vector3.new(x, 6.5, z), Vector3.new(1.4, 13, 1.4), C.Charcoal, Enum.Material.Metal, true, nil, zone)
			end
		end
	end
	block(intake, "FrontHeader", Vector3.new(3040, 11.2, 14), Vector3.new(72, 3.8, 1.1), C.DeepNavy, Enum.Material.Metal, false, nil, zone)
	surfaceText(intake.FrontHeader, "APPRAISAL  /  RARE + TOW INTAKE", Enum.NormalId.Front, C.WarmWhite)
	taskLight(intake, "CanopyLightWest", Vector3.new(3020, 12.75, 38), Vector3.new(22, 0.18, 0.65), C.White, 0.45, 20, zone)
	taskLight(intake, "CanopyLightEast", Vector3.new(3056, 12.75, 61), Vector3.new(22, 0.18, 0.65), C.White, 0.45, 20, zone)

	-- Low appraisal plates and overhead scanners do not occupy a vehicle body envelope.
	for index, x in ipairs({3019, 3044}) do
		local cell = model(intake, "Ordinary_Appraisal_" .. index, zone)
		block(cell, "ConditionPlate", Vector3.new(x, 0.22, 35), Vector3.new(11.5, 0.12, 18.5), C.Steel, Enum.Material.DiamondPlate, false, 0.18, zone)
		-- Scanner heads hang from the shared canopy. Ground posts would obstruct
		-- the tow/transporter approach before the protected unload rectangle.
		for _, px in ipairs({x - 10, x + 10}) do
			block(cell, "SuspendedScannerHead", Vector3.new(px, 10.2, 24), Vector3.new(0.8, 4.0, 0.8), C.Charcoal, Enum.Material.Metal, false, nil, zone)
		end
		block(cell, "ScannerBridge", Vector3.new(x, 10.6, 24), Vector3.new(20.8, 1.0, 1.0), C.Cyan, Enum.Material.Neon, false, 0.08, zone)
		for scan = -2, 2 do
			block(cell, "ConditionSensor", Vector3.new(x + scan * 2.1, 9.8, 35), Vector3.new(0.3, 0.3, 0.3), C.Cyan, Enum.Material.Neon, false, nil, zone)
		end
		local status = block(cell, "ConditionStatus", Vector3.new(x, 7.9, 24.55), Vector3.new(7.4, 2.4, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
		surfaceText(status, if index == 1 then "MECHANICAL / BODY" else "RUNNING GEAR / EXTERIOR", Enum.NormalId.Back, C.Cyan, true)
	end

	local special = model(intake, "Rare_Tow_Receiving", zone)
	block(special, "RareTowPlate", Vector3.new(3069, 0.22, 62), Vector3.new(11.5, 0.12, 18.5), C.Charcoal, Enum.Material.DiamondPlate, false, 0.18, zone)
	for _, x in ipairs({3059, 3079}) do
		block(special, "SpecialGatePost", Vector3.new(x, 7.5, 62), Vector3.new(0.9, 15, 0.9), C.Gold, Enum.Material.Metal, true, nil, zone)
	end
	block(special, "SpecialGateHeader", Vector3.new(3069, 14.6, 62), Vector3.new(20.8, 1.0, 1.1), C.Gold, Enum.Material.Neon, false, 0.08, zone)
	local rareSign = block(special, "RareIntakeSign", Vector3.new(3069, 11.7, 62.6), Vector3.new(9.5, 2.4, 0.3), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(rareSign, "RARE / TOW", Enum.NormalId.Back, C.Gold, true)

	local lab = model(intake, "Condition_Value_Lab", zone)
	-- The lab hugs the west public edge so all three cars retain a straight
	-- road-to-socket approach.
	block(lab, "GlassWall", Vector3.new(3004.5, 5.2, 82), Vector3.new(8, 10, 0.35), C.Glass, Enum.Material.Glass, false, 0.35, zone)
	block(lab, "LabRoof", Vector3.new(3004.5, 10.4, 85), Vector3.new(8, 0.5, 7), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	desk(lab, "ValuationConsole", Vector3.new(3004.5, 0, 86), 5.5, C.Cyan, zone)
	for i = 1, 3 do
		block(lab, "ProvenanceTablet", Vector3.new(3000.7 + i * 1.9, 6.0, 81.75), Vector3.new(1.3, 2.8, 0.08), if i == 2 then C.Gold else C.Cyan, Enum.Material.Neon, false, 0.12, zone)
	end

	desk(intake, "Seller_Handoff_Desk", Vector3.new(3084, 0, 44), 8, C.Gold, zone)
	person(intake, "Senior_Appraiser", Vector3.new(3083, 0, 51), C.Navy, "Senior appraiser", zone)
	person(intake, "Seller", Vector3.new(3083, 0, 58), C.WarmWhite, "Seller", zone)
	intake:SetAttribute("CompositionStatus", "BUILT")
end

local function buildSales(parent: Instance)
	local zone = "Sales_Delivery"
	local sales = model(parent, "02_Sales_Delivery", zone)
	sales:SetAttribute("DisplayCapacity", 6)
	sales:SetAttribute("GroundDisplays", 4)
	sales:SetAttribute("ElevatedCentrelineDisplays", 2)
	sales:SetAttribute("RevealPositions", 1)
	sales:SetAttribute("StagingPositions", 1)

	block(sales, "ShowroomRoof", Vector3.new(3130, 15.0, 54), Vector3.new(78, 1.0, 94), C.Navy, Enum.Material.Metal, false, 0.08, zone)
	for _, position in ipairs({
		Vector3.new(3092, 7.5, 9), Vector3.new(3168, 7.5, 9),
		Vector3.new(3078, 7.5, 99), Vector3.new(3168, 7.5, 99),
	}) do block(sales, "ShowroomColumn", position, Vector3.new(1.2, 15, 1.2), C.Charcoal, Enum.Material.Metal, true, nil, zone) end
	block(sales, "RoadHeader", Vector3.new(3130, 12.4, 9), Vector3.new(76, 4.0, 1.0), C.DeepNavy, Enum.Material.Metal, false, nil, zone)
	surfaceText(sales.RoadHeader, "DESERT CUSTOMS  /  SALES + DELIVERY", Enum.NormalId.Front, C.Gold)
	for _, x in ipairs({3092.4, 3167.6}) do
		block(sales, "GlassSide", Vector3.new(x, 7.0, 54), Vector3.new(0.35, 12, 82), C.Glass, Enum.Material.Glass, false, 0.48, zone)
	end

	local palette = {C.Red, C.Cyan, C.Gold, C.Teal}
	local groundPositions = {
		Vector3.new(3104, 0, 30), Vector3.new(3156, 0, 30),
		Vector3.new(3104, 0, 56), Vector3.new(3156, 0, 56),
	}
	for index, position in ipairs(groundPositions) do
		local display = model(sales, "Ground_Display_" .. index, zone)
		block(display, "DisplayPlinth", Vector3.new(position.X, 0.28, position.Z), Vector3.new(13.5, 0.28, 21.5), C.Charcoal, Enum.Material.Slate, false, nil, zone)
		block(display, "EdgeLight", Vector3.new(position.X, 0.48, position.Z - 10.4), Vector3.new(11.8, 0.15, 0.18), C.Gold, Enum.Material.Neon, false, 0.05, zone)
		car(display, "SalesCar_" .. index, position, 0, palette[index], zone, false)
	end

	-- The two accepted centreline sockets become vertical showcase lifts. This
	-- preserves six visible sale cars without putting a parked car in SalesExit.
	for index, z in ipairs({30, 56}) do
		local showcase = model(sales, "Elevated_Centreline_Display_" .. index, zone)
		block(showcase, "ShowcaseDeck", Vector3.new(3130, 9.2, z), Vector3.new(15.0, 0.7, 21.5), C.Charcoal, Enum.Material.DiamondPlate, false, nil, zone)
		for _, x in ipairs({3120.8, 3139.2}) do
			block(showcase, "LiftTower", Vector3.new(x, 4.6, z), Vector3.new(0.9, 9.2, 0.9), C.Steel, Enum.Material.Metal, true, nil, zone)
		end
		car(showcase, "ElevatedSalesCar_" .. index, Vector3.new(3130, 9.2, z), 0, if index == 1 then C.Purple else C.Blue, zone, false)
		local price = block(showcase, "ListingPrice", Vector3.new(3130, 6.8, z - 10.8), Vector3.new(8.5, 1.8, 0.2), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
		surfaceText(price, if index == 1 then "$84,500" else "$112,000", Enum.NormalId.Front, C.Gold, true)
	end

	local reveal = model(sales, "Delivery_Reveal", zone)
	block(reveal, "RevealFloor", Vector3.new(3144, 0.24, 84), Vector3.new(12, 0.16, 20), C.Charcoal, Enum.Material.Slate, false, 0.08, zone)
	block(reveal, "CeilingRevealLight", Vector3.new(3144, 11.6, 84), Vector3.new(30, 0.8, 1.1), C.Gold, Enum.Material.Neon, false, 0.05, zone)
	for _, x in ipairs({3131, 3157}) do block(reveal, "SuspendedRevealHead", Vector3.new(x, 10.0, 84), Vector3.new(0.7, 2.4, 0.7), C.Gold, Enum.Material.Metal, false, nil, zone) end
	local sold = block(reveal, "SoldMoment", Vector3.new(3144, 8.5, 84.65), Vector3.new(8, 2.2, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(sold, "HANDOVER", Enum.NormalId.Back, C.Gold, true)

	block(sales, "StagingMark", Vector3.new(3116, 0.2, 84), Vector3.new(11.5, 0.12, 19), C.Blue, Enum.Material.SmoothPlastic, false, 0.48, zone)
	-- Customer work remains south of the first protected crossover at Z=89.
	desk(sales, "Deal_And_Listing_Desk", Vector3.new(3162, 0, 75), 11, C.Gold, zone)
	bench(sales, "Customer_Lounge", Vector3.new(3098, 0, 75), 180, zone)
	person(sales, "Sales_Lead", Vector3.new(3157, 0, 86.8), C.Navy, "Sales lead", zone)
	person(sales, "Delivery_Customer", Vector3.new(3104, 0, 88.5), C.WarmWhite, "Delivery customer", zone)
	taskLight(sales, "SalesLightWest", Vector3.new(3105, 14.4, 44), Vector3.new(28, 0.18, 0.7), C.WarmWhite, 0.35, 22, zone)
	taskLight(sales, "SalesLightEast", Vector3.new(3155, 14.4, 44), Vector3.new(28, 0.18, 0.7), C.WarmWhite, 0.35, 22, zone)
	sales:SetAttribute("CompositionStatus", "BUILT")
end

local function buildOwnerGarage(parent: Instance)
	local zone = "Owner_Garage"
	local owner = model(parent, "03_Owner_Garage", zone)
	owner:SetAttribute("ActiveCarCapacity", 6)
	owner:SetAttribute("DealerInventoryAccepted", false)
	owner:SetAttribute("CentralDriveAisleClear", true)

	block(owner, "OwnerRoof", Vector3.new(3218, 15.0, 54), Vector3.new(74, 1.2, 94), C.DeepNavy, Enum.Material.Metal, false, 0.04, zone)
	for _, x in ipairs({3182, 3254}) do
		block(owner, "SideWall", Vector3.new(x, 7.5, 54), Vector3.new(1.2, 15, 92), C.Charcoal, Enum.Material.Brick, true, nil, zone)
		block(owner, "GlassBand", Vector3.new(x + (if x < ORIGIN_X then 0.7 else -0.7), 9.0, 54), Vector3.new(0.25, 7.5, 74), C.Glass, Enum.Material.Glass, false, 0.42, zone)
	end
	block(owner, "RearWallLeft", Vector3.new(3198, 7.5, 100), Vector3.new(31, 15, 1.0), C.Brick, Enum.Material.Brick, true, nil, zone)
	block(owner, "RearWallRight", Vector3.new(3240, 7.5, 100), Vector3.new(27, 15, 1.0), C.Brick, Enum.Material.Brick, true, nil, zone)
	for _, x in ipairs({3188, 3248}) do
		block(owner, "FrontColumn", Vector3.new(x, 7.5, 9), Vector3.new(1.2, 15, 1.2), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	end
	block(owner, "OwnerHeader", Vector3.new(3218, 12.4, 9), Vector3.new(60, 4, 1.1), C.DeepNavy, Enum.Material.Metal, false, nil, zone)
	surfaceText(owner.OwnerHeader, "OWNER GARAGE  /  SIX-CAR ACTIVE FLEET", Enum.NormalId.Front, C.Gold)
	block(owner, "CentralDriveAisle", Vector3.new(3218, 0.17, 54), Vector3.new(12, 0.08, 90), C.Gold, Enum.Material.SmoothPlastic, false, 0.78, zone)

	local palette = {C.Red, C.Cyan, C.Gold, C.Purple, C.Teal, C.Blue}
	local positions = {
		Vector3.new(3203, 0, 28), Vector3.new(3233, 0, 28),
		Vector3.new(3203, 0, 56), Vector3.new(3233, 0, 56),
		Vector3.new(3203, 0, 84), Vector3.new(3233, 0, 84),
	}
	for index, position in ipairs(positions) do
		local cell = model(owner, "Owner_Position_" .. index, zone)
		cell:SetAttribute("OwnerCarPosition", index)
		block(cell, "PersonalBayFloor", Vector3.new(position.X, 0.22, position.Z), Vector3.new(13.5, 0.12, 21.5), C.Charcoal, Enum.Material.Slate, false, 0.05, zone)
		block(cell, "PersonalBayLight", Vector3.new(position.X, 14.25, position.Z), Vector3.new(8, 0.18, 0.7), if index <= 2 then C.WarmWhite else C.Gold, Enum.Material.Neon, false, 0.05, zone)
		car(cell, "PersonalCar_" .. index, position, 0, palette[index], zone, false)
	end

	local config = model(owner, "Personal_Configuration_Cell", zone)
	desk(config, "ConfigurationConsole", Vector3.new(3188.5, 0, 87), 8, C.Purple, zone)
	for i = 1, 4 do
		cylinder(config, "WheelSample", Vector3.new(3185.5, 2 + i * 1.7, 74 + (i % 2) * 4), Vector3.new(1.0, 2.5, 2.5), Vector3.new(0, 90, 0), if i % 2 == 0 then C.Silver else C.Charcoal, Enum.Material.Metal, false, zone)
	end
	local rare = model(owner, "Rare_Parts_Interface", zone)
	block(rare, "SecureCase", Vector3.new(3248.2, 4.2, 85), Vector3.new(8, 7, 7), C.Glass, Enum.Material.Glass, false, 0.38, zone)
	block(rare, "RarePart", Vector3.new(3248.2, 3.2, 85), Vector3.new(5, 1.1, 3.2), C.Gold, Enum.Material.Metal, false, nil, zone)
	local crest = block(owner, "OwnerCrest", Vector3.new(3218, 9.0, 99.35), Vector3.new(12, 5.5, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(crest, "DC / 01", Enum.NormalId.Front, C.Gold, true)
	person(owner, "Owner_Technician", Vector3.new(3190, 0, 70), C.Navy, "Owner vehicle specialist", zone)
	owner:SetAttribute("CompositionStatus", "BUILT")
end

local function buildLogistics(parent: Instance)
	local zone = "Parts_Logistics"
	local logistics = model(parent, "04_Parts_Logistics", zone)
	logistics:SetAttribute("TemporaryVehicleCapacity", 1)
	logistics:SetAttribute("PublicAccess", false)

	block(logistics, "LogisticsFloor", Vector3.new(3032, 0.3, 449), Vector3.new(50, 0.4, 46), C.Concrete, Enum.Material.Concrete, true, nil, zone)
	block(logistics, "RearWall", Vector3.new(3032, 8.5, 472), Vector3.new(50, 17, 1.0), C.Brick, Enum.Material.Brick, true, nil, zone)
	block(logistics, "WestWall", Vector3.new(3007, 8.5, 449), Vector3.new(1.0, 17, 46), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	block(logistics, "EastWall", Vector3.new(3057, 8.5, 453), Vector3.new(1.0, 17, 38), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	block(logistics, "LogisticsRoof", Vector3.new(3032, 17.2, 449), Vector3.new(52, 1.0, 48), C.Navy, Enum.Material.Metal, false, 0.04, zone)
	for _, x in ipairs({3008, 3056}) do block(logistics, "DockPost", Vector3.new(x, 6.5, 424), Vector3.new(1.0, 13, 1.0), C.Charcoal, Enum.Material.Metal, true, nil, zone) end
	block(logistics, "DockHeader", Vector3.new(3032, 12.6, 424), Vector3.new(49, 1.0, 1.0), C.Gold, Enum.Material.Neon, false, 0.08, zone)
	local sign = block(logistics, "LogisticsSign", Vector3.new(3032, 10.2, 423.4), Vector3.new(20, 3.2, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(sign, "PARTS + LOGISTICS", Enum.NormalId.Front, C.Gold)

	block(logistics, "ReceivingDock", Vector3.new(3043, 1.2, 420), Vector3.new(24, 2, 7), C.Steel, Enum.Material.DiamondPlate, true, nil, zone)
	for i = 1, 5 do block(logistics, "DockRoller", Vector3.new(3033 + i * 4, 2.35, 420), Vector3.new(2.6, 0.45, 5.5), C.MidSteel, Enum.Material.Metal, false, nil, zone) end
	rack(logistics, "Fast_Moving_Inventory", Vector3.new(3016, 0, 440), Vector3.new(15, 11, 4), C.Cyan, zone)
	rack(logistics, "Restoration_Inventory", Vector3.new(3016, 0, 458), Vector3.new(15, 11, 4), C.Amber, zone)
	rack(logistics, "Performance_Inventory", Vector3.new(3047, 0, 458), Vector3.new(14, 11, 4), C.Purple, zone)

	local cage = model(logistics, "Rare_Parts_Vault", zone)
	block(cage, "VaultFloor", Vector3.new(3046, 0.5, 439), Vector3.new(17, 0.6, 12), C.Charcoal, Enum.Material.DiamondPlate, true, nil, zone)
	for _, x in ipairs({3037.5, 3054.5}) do block(cage, "MeshWall", Vector3.new(x, 5, 439), Vector3.new(0.3, 9, 12), C.Steel, Enum.Material.Metal, true, 0.22, zone) end
	block(cage, "VaultRear", Vector3.new(3046, 5, 445), Vector3.new(17, 9, 0.3), C.Steel, Enum.Material.Metal, true, 0.22, zone)
	block(cage, "RareCrate", Vector3.new(3046, 1.6, 439), Vector3.new(7, 2.6, 5), C.Gold, Enum.Material.Metal, false, nil, zone)

	local conveyor = model(logistics, "Function_Dispatch_Conveyor", zone)
	block(conveyor, "ConveyorBed", Vector3.new(3065, 2.0, 440), Vector3.new(14, 1.0, 5), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	for i = 1, 5 do cylinder(conveyor, "ConveyorRoller", Vector3.new(3059 + i * 2.2, 2.7, 440), Vector3.new(5, 0.45, 0.45), Vector3.new(0, 90, 0), C.Silver, Enum.Material.Metal, false, zone) end
	local board = block(logistics, "InventoryBoard", Vector3.new(3032, 8, 471.4), Vector3.new(18, 6, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(board, "RECEIVED  18  |  PICKED  12  |  RARE  03", Enum.NormalId.Front, C.Cyan, true)
	person(logistics, "Logistics_Lead", Vector3.new(3030, 0, 433), C.Navy, "Logistics lead", zone)
	person(logistics, "Parts_Runner", Vector3.new(3064, 0, 449), C.Navy, "Parts runner", zone)
	taskLight(logistics, "LogisticsWorkLight", Vector3.new(3032, 16.5, 449), Vector3.new(30, 0.2, 0.8), C.White, 0.45, 24, zone)
	logistics:SetAttribute("CompositionStatus", "BUILT")
end

local function buildOperations(parent: Instance)
	local zone = "Staff_Operations"
	local operations = model(parent, "05_Staff_Operations", zone)
	operations:SetAttribute("VehicleCapacity", 0)

	block(operations, "OperationsFloor", Vector3.new(3228, 0.3, 449), Vector3.new(50, 0.4, 46), C.Concrete, Enum.Material.Concrete, true, nil, zone)
	block(operations, "RearWall", Vector3.new(3228, 8.5, 472), Vector3.new(50, 17, 1.0), C.Brick, Enum.Material.Brick, true, nil, zone)
	block(operations, "EastWall", Vector3.new(3253, 8.5, 449), Vector3.new(1.0, 17, 46), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	block(operations, "WestWall", Vector3.new(3203, 8.5, 453), Vector3.new(1.0, 17, 38), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	block(operations, "OperationsRoof", Vector3.new(3228, 17.2, 449), Vector3.new(52, 1.0, 48), C.Navy, Enum.Material.Metal, false, 0.04, zone)
	for _, x in ipairs({3204, 3252}) do block(operations, "FrontPost", Vector3.new(x, 6.5, 424), Vector3.new(1, 13, 1), C.Charcoal, Enum.Material.Metal, true, nil, zone) end
	local sign = block(operations, "OperationsSign", Vector3.new(3228, 10.4, 423.4), Vector3.new(24, 3.2, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(sign, "STAFF + OPERATIONS", Enum.NormalId.Front, C.Teal)

	local control = model(operations, "Campus_Dispatch_Control", zone)
	desk(control, "DispatchConsoleA", Vector3.new(3214, 0, 435), 10, C.Teal, zone)
	desk(control, "DispatchConsoleB", Vector3.new(3228, 0, 435), 10, C.Cyan, zone)
	local jobBoard = block(control, "LiveJobBoard", Vector3.new(3221, 10.0, 471.35), Vector3.new(27, 9, 0.3), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(jobBoard, "13 ACTIVE  /  7 FUNCTIONS  /  FLOW CLEAR", Enum.NormalId.Front, C.Teal)

	local staff = model(operations, "Staff_Facilities", zone)
	for i = 1, 6 do
		block(staff, "Locker", Vector3.new(3242 + (i % 2) * 4, 3.1, 439 + math.floor((i - 1) / 2) * 5), Vector3.new(3.2, 6, 3.2), if i % 2 == 0 then C.Steel else C.Navy, Enum.Material.Metal, true, nil, zone)
	end
	block(staff, "TrainingTable", Vector3.new(3216, 2.8, 457), Vector3.new(12, 1, 6), C.Sand, Enum.Material.WoodPlanks, true, nil, zone)
	for _, x in ipairs({3211, 3221}) do block(staff, "TrainingSeat", Vector3.new(x, 1.5, 453), Vector3.new(2.5, 3, 2.5), C.Charcoal, Enum.Material.Fabric, true, nil, zone) end
	bench(staff, "BreakBench", Vector3.new(3244, 0, 462), 90, zone)

	local utilities = model(operations, "Campus_Utilities", zone)
	for i = 1, 3 do
		block(utilities, "UtilityCabinet", Vector3.new(3208, 3.5, 442 + i * 7), Vector3.new(6, 7, 5), if i == 1 then C.Blue elseif i == 2 then C.Red else C.Gold, Enum.Material.Metal, true, nil, zone)
		for port = 1, 3 do block(utilities, "StatusLamp", Vector3.new(3204.9, 2.3 + port * 1.3, 442 + i * 7), Vector3.new(0.1, 0.5, 0.5), if port == 3 then C.Green else C.Cyan, Enum.Material.Neon, false, nil, zone) end
	end
	person(operations, "Operations_Manager", Vector3.new(3228, 0, 443), C.Navy, "Operations manager", zone)
	person(operations, "Shift_Supervisor", Vector3.new(3211, 0, 446), C.Navy, "Shift supervisor", zone)
	taskLight(operations, "OperationsWorkLight", Vector3.new(3228, 16.5, 449), Vector3.new(30, 0.2, 0.8), C.White, 0.45, 24, zone)
	operations:SetAttribute("CompositionStatus", "BUILT")
end

local function buildCollector(parent: Instance)
	local zone = "Collector_Hall"
	local collector = model(parent, "06_Collector_Hall", zone)
	collector:SetAttribute("SnapshotCapacity", 6)
	collector:SetAttribute("LiveVehicleRoute", false)
	collector:SetAttribute("SelectionRule", "BEST_SOLD_TRANSFORMATIONS")

	-- Finish overlay sits above the accepted structural floor at Y=20.
	block(collector, "GalleryFinishFloor", Vector3.new(3130, 20.82, 406), Vector3.new(92, 0.22, 56), C.Charcoal, Enum.Material.Marble, false, nil, zone)
	for _, x in ipairs({3084, 3176}) do block(collector, "GallerySideGlass", Vector3.new(x, 27, 406), Vector3.new(0.35, 12, 56), C.Glass, Enum.Material.Glass, false, 0.36, zone) end
	for _, z in ipairs({378, 434}) do block(collector, "GalleryGlass", Vector3.new(3130, 27, z), Vector3.new(92, 12, 0.35), C.Glass, Enum.Material.Glass, false, 0.36, zone) end
	-- Two roof wings preserve a clear central view slot to the taller HQ crown.
	block(collector, "GalleryRoofWest", Vector3.new(3098, 34.0, 406), Vector3.new(34, 1.2, 62), C.DeepNavy, Enum.Material.Metal, false, 0.04, zone)
	block(collector, "GalleryRoofEast", Vector3.new(3162, 34.0, 406), Vector3.new(34, 1.2, 62), C.DeepNavy, Enum.Material.Metal, false, 0.04, zone)
	for _, x in ipairs({3114, 3146}) do
		block(collector, "SightlineLanternGlass", Vector3.new(x, 37.0, 406), Vector3.new(1.0, 5, 54), C.Glass, Enum.Material.Glass, false, 0.48, zone)
		block(collector, "SightlineLanternCap", Vector3.new(x, 39.8, 406), Vector3.new(2.0, 0.8, 58), C.Gold, Enum.Material.Metal, false, nil, zone)
	end
	local title = block(collector, "CollectorTitle", Vector3.new(3130, 18.4, 377.7), Vector3.new(30, 2.6, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(title, "COLLECTOR HALL  /  SIX BEST BUILDS", Enum.NormalId.Front, C.Gold, true)

	local palette = {C.Red, C.Cyan, C.Gold, C.Purple, C.Teal, C.Blue}
	local positions = {
		Vector3.new(3102, 20.9, 393), Vector3.new(3130, 20.9, 393), Vector3.new(3158, 20.9, 393),
		Vector3.new(3102, 20.9, 419), Vector3.new(3130, 20.9, 419), Vector3.new(3158, 20.9, 419),
	}
	for index, position in ipairs(positions) do
		local exhibit = model(collector, "Legacy_Snapshot_" .. index, zone)
		exhibit:SetAttribute("SnapshotIndex", index)
		block(exhibit, "SnapshotPlinth", Vector3.new(position.X, 21.05, position.Z), Vector3.new(13.5, 0.28, 21.5), C.DeepNavy, Enum.Material.Slate, false, nil, zone)
		block(exhibit, "ProvenanceLight", Vector3.new(position.X, 21.3, position.Z - 10.5), Vector3.new(9.5, 0.12, 0.15), C.Gold, Enum.Material.Neon, false, 0.06, zone)
		car(exhibit, "BestBuildSnapshot_" .. index, position, 0, palette[index], zone, true)
		local plaque = block(exhibit, "BuildPlaque", Vector3.new(position.X + 7.0, 22.7, position.Z + 6.5), Vector3.new(0.25, 3.4, 5.2), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
		surfaceText(plaque, "BUILD 0" .. index .. "\nSOLD / ARCHIVED", Enum.NormalId.Right, C.Gold, true)
	end

	local timeline = block(collector, "BeforeAfterTimeline", Vector3.new(3084.3, 27.0, 406), Vector3.new(0.2, 6, 32), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	for i = 1, 6 do block(collector, "TimelineMoment", Vector3.new(3084.15, 25.2 + (i % 2) * 3.2, 391 + i * 4.2), Vector3.new(0.08, 2.2, 2.7), if i % 2 == 0 then C.Gold else C.Cyan, Enum.Material.Neon, false, 0.12, zone) end
	local curator = model(collector, "Curator_Control", zone)
	desk(curator, "RotationConsole", Vector3.new(3169, 20.9, 428), 8, C.Gold, zone)
	person(curator, "Curator", Vector3.new(3163, 20.9, 428), C.Navy, "Collection curator", zone)
	for _, x in ipairs({3102, 3130, 3158}) do taskLight(collector, "GalleryTrack", Vector3.new(x, 33.2, 406), Vector3.new(8, 0.15, 0.5), C.WarmWhite, 0.35, 18, zone) end
	collector:SetAttribute("CompositionStatus", "BUILT")
end

local function buildHQ(parent: Instance)
	local zone = "Headquarters"
	local hq = model(parent, "07_Institution_Headquarters", zone)
	hq:SetAttribute("Levels", 3)
	hq:SetAttribute("DeepestCrownTallest", true)

	-- Level 1: broad operations/reception base.
	block(hq, "HQFloor1", Vector3.new(3130, 0.4, 472), Vector3.new(90, 0.6, 50), C.Charcoal, Enum.Material.Marble, true, nil, zone)
	block(hq, "HQRearWall1", Vector3.new(3130, 8, 497), Vector3.new(90, 16, 1), C.Brick, Enum.Material.Brick, true, nil, zone)
	for _, x in ipairs({3085, 3175}) do block(hq, "HQSideWall1", Vector3.new(x, 8, 472), Vector3.new(1, 16, 50), C.Charcoal, Enum.Material.Metal, true, nil, zone) end
	block(hq, "HQFloor2", Vector3.new(3130, 16.1, 477), Vector3.new(78, 0.8, 42), C.Navy, Enum.Material.Metal, true, nil, zone)
	block(hq, "HQGlassFront1", Vector3.new(3130, 8, 447), Vector3.new(82, 14, 0.35), C.Glass, Enum.Material.Glass, false, 0.34, zone)
	for _, x in ipairs({3090, 3110, 3150, 3170}) do block(hq, "FacadeMullion1", Vector3.new(x, 8, 446.75), Vector3.new(0.45, 14, 0.45), C.Gold, Enum.Material.Metal, false, nil, zone) end
	block(hq, "LobbyDoorLeft", Vector3.new(3125, 5.2, 446.55), Vector3.new(8, 10, 0.25), C.Glass, Enum.Material.Glass, false, 0.48, zone)
	block(hq, "LobbyDoorRight", Vector3.new(3135, 5.2, 446.55), Vector3.new(8, 10, 0.25), C.Glass, Enum.Material.Glass, false, 0.48, zone)
	desk(hq, "Institution_Reception", Vector3.new(3130, 0, 457), 20, C.Gold, zone)
	bench(hq, "LobbyBenchWest", Vector3.new(3098, 0, 461), 90, zone)
	bench(hq, "LobbyBenchEast", Vector3.new(3162, 0, 461), -90, zone)
	plant(hq, "LobbyPlantWest", Vector3.new(3092, 0, 453), 1.0, zone)
	plant(hq, "LobbyPlantEast", Vector3.new(3168, 0, 453), 1.0, zone)

	-- Level 2: analytics and service-control balcony.
	block(hq, "HQRearWall2", Vector3.new(3130, 22.2, 498), Vector3.new(76, 12, 1), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	for _, x in ipairs({3091, 3169}) do block(hq, "HQSideWall2", Vector3.new(x, 22.2, 477), Vector3.new(1, 12, 42), C.Navy, Enum.Material.Metal, true, nil, zone) end
	block(hq, "HQFloor3", Vector3.new(3130, 28.4, 482), Vector3.new(64, 0.8, 30), C.Navy, Enum.Material.Metal, true, nil, zone)
	block(hq, "HQGlassFront2", Vector3.new(3130, 22.2, 456), Vector3.new(72, 10.5, 0.35), C.Glass, Enum.Material.Glass, false, 0.3, zone)
	for i = 1, 5 do
		local analytics = block(hq, "AnalyticsPanel", Vector3.new(3102 + i * 11, 21.8, 456.2), Vector3.new(8.2, 4.8, 0.12), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
		surfaceText(analytics, ({"FLOW","MARGIN","QUALITY","STAFF","LEGACY"})[i], Enum.NormalId.Back, if i == 3 then C.Gold else C.Cyan, true)
	end
	for _, x in ipairs({3105, 3130, 3155}) do desk(hq, "AnalyticsDesk", Vector3.new(x, 16.4, 473), 10, C.Cyan, zone) end

	-- Level 3 and the crown: narrowest, deepest and tallest volume.
	block(hq, "HQCrownRear", Vector3.new(3130, 42, 497), Vector3.new(62, 27, 1), C.DeepNavy, Enum.Material.Metal, true, nil, zone)
	for _, x in ipairs({3099, 3161}) do block(hq, "HQCrownSide", Vector3.new(x, 42, 482), Vector3.new(1, 27, 30), C.DeepNavy, Enum.Material.Metal, true, nil, zone) end
	block(hq, "HQCrownGlass", Vector3.new(3130, 42, 467), Vector3.new(60, 25, 0.35), C.Glass, Enum.Material.Glass, false, 0.25, zone)
	block(hq, "HQCrownRoof", Vector3.new(3130, 56.0, 482), Vector3.new(68, 1.2, 34), C.DeepNavy, Enum.Material.Metal, false, nil, zone)
	block(hq, "CrownBlade", Vector3.new(3130, 64.0, 492), Vector3.new(4, 16, 4), C.Gold, Enum.Material.Metal, true, nil, zone)
	local crest = block(hq, "InstitutionCrest", Vector3.new(3130, 44.0, 466.75), Vector3.new(24, 7, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(crest, "DESERT CUSTOMS\nINSTITUTION", Enum.NormalId.Front, C.Gold)
	local history = block(hq, "BrandHistoryWall", Vector3.new(3130, 42.5, 496.4), Vector3.new(34, 7, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(history, "ROUGH LOT  →  BEST IN THE WEST", Enum.NormalId.Front, C.WarmWhite, true)

	-- Elevated pedestrian bridge ties HQ to Collector without creating a car ramp.
	block(hq, "CollectorBridge", Vector3.new(3130, 20.5, 440.5), Vector3.new(24, 1.0, 11), C.Charcoal, Enum.Material.Metal, true, nil, zone)
	for _, x in ipairs({3118, 3142}) do block(hq, "BridgeGlass", Vector3.new(x, 23.0, 440.5), Vector3.new(0.25, 4.0, 11), C.Glass, Enum.Material.Glass, false, 0.4, zone) end
	person(hq, "Reception_Manager", Vector3.new(3130, 0, 464), C.Navy, "Reception manager", zone)
	person(hq, "Analyst", Vector3.new(3130, 16.4, 480), C.Navy, "Business analyst", zone)
	taskLight(hq, "LobbyLight", Vector3.new(3130, 15.2, 468), Vector3.new(38, 0.2, 0.8), C.WarmWhite, 0.4, 30, zone)
	taskLight(hq, "CrownLight", Vector3.new(3130, 55.2, 474), Vector3.new(34, 0.2, 0.8), C.Gold, 0.5, 35, zone)
	hq:SetAttribute("CompositionStatus", "BUILT")
end

local function buildPublicRealm(parent: Instance)
	local zone = "Campus_Public_Realm"
	local realm = model(parent, "08_Campus_Identity_Public_Realm", zone)
	realm:SetAttribute("VisitorParkingCapacity", 3)
	realm:SetAttribute("HeroAxisPreserved", true)

	-- Roadside visitor lay-bys occupy the gaps between operational entrances.
	for index, x in ipairs({3060, 3160, 3244}) do
		local bay = model(realm, "Visitor_Bay_" .. index, zone)
		block(bay, "VisitorSurface", Vector3.new(x, -0.02, -11.5), Vector3.new(21, 0.12, 9), C.Charcoal, Enum.Material.Asphalt, false, nil, zone)
		for _, dx in ipairs({-10.2, 10.2}) do block(bay, "ParkingLine", Vector3.new(x + dx, 0.08, -11.5), Vector3.new(0.18, 0.08, 9), C.White, Enum.Material.Neon, false, 0.12, zone) end
		bay:SetAttribute("VisitorParkingSocket", index)
	end

	-- Central sales gateway; its legs sit outside the accepted exit lane.
	for _, x in ipairs({3109, 3151}) do block(realm, "GatewayPier", Vector3.new(x, 9.0, -16), Vector3.new(2.0, 18, 3.0), C.Charcoal, Enum.Material.Metal, true, nil, zone) end
	block(realm, "GatewayBeam", Vector3.new(3130, 17.3, -16), Vector3.new(44, 1.6, 3.0), C.Gold, Enum.Material.Metal, false, nil, zone)
	local gateSign = block(realm, "GatewaySign", Vector3.new(3130, 13.4, -14.4), Vector3.new(29, 5.0, 0.35), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(gateSign, "DESERT CUSTOMS", Enum.NormalId.Front, C.Gold)

	-- Road-visible status tower on the east boundary, clear of Owner entry.
	block(realm, "LandmarkTower", Vector3.new(3257.5, 14, 2), Vector3.new(3, 28, 7), C.DeepNavy, Enum.Material.Metal, true, nil, zone)
	block(realm, "TowerBlade", Vector3.new(3257.5, 24, 2), Vector3.new(4.2, 9, 8.2), C.Gold, Enum.Material.Neon, false, 0.08, zone)
	local towerSign = block(realm, "TowerCrest", Vector3.new(3255.8, 16, 2), Vector3.new(0.25, 10, 5), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
	surfaceText(towerSign, "DC", Enum.NormalId.Left, C.Gold, true)

	-- Perimeter is segmented and keeps all three frontage entrances open.
	for z = 118, 490, 31 do
		for _, x in ipairs({3001.5, 3258.5}) do
			block(realm, "BoundaryPost", Vector3.new(x, 3.0, z), Vector3.new(0.6, 6, 0.6), C.Charcoal, Enum.Material.Metal, true, nil, zone)
			block(realm, "BoundaryRail", Vector3.new(x, 3.4, z + 14.8), Vector3.new(0.35, 4.4, 29), C.Steel, Enum.Material.Metal, true, 0.28, zone)
		end
	end

	-- Hero courtyard stays open over holding and staff routes. Furnishing uses
	-- the side islands and the 13-stud band between holding and staff spine.
	block(realm, "CourtyardFinish", Vector3.new(3130, 0.08, 385), Vector3.new(104, 0.12, 40), C.Concrete, Enum.Material.Pavement, false, 0.04, zone)
	for _, x in ipairs({3082, 3178}) do
		plant(realm, "CourtyardPlant", Vector3.new(x, 0, 387), 1.15, zone)
		bench(realm, "CourtyardBench", Vector3.new(x + (if x < ORIGIN_X then 7 else -7), 0, 388), if x < ORIGIN_X then 90 else -90, zone)
	end
	local sculpture = model(realm, "Transformation_Sculpture", zone)
	block(sculpture, "SculpturePlinth", Vector3.new(3130, 0.6, 388), Vector3.new(7, 1.2, 7), C.Charcoal, Enum.Material.Marble, true, nil, zone)
	oriented(sculpture, "BeforeArc", Vector3.new(3128.3, 4.0, 388), Vector3.new(0.8, 7, 5), Vector3.new(0, 0, -20), C.Steel, Enum.Material.CorrodedMetal, false, nil, zone)
	oriented(sculpture, "AfterArc", Vector3.new(3131.7, 5.0, 388), Vector3.new(0.8, 9, 5), Vector3.new(0, 0, 20), C.Gold, Enum.Material.Metal, false, nil, zone)
	block(sculpture, "StoryLight", Vector3.new(3130, 8.5, 388), Vector3.new(6, 0.3, 0.3), C.Gold, Enum.Material.Neon, false, 0.06, zone)

	-- Protected pedestrian language and estate wayfinding.
	for _, x in ipairs({3006, 3254}) do
		for _, z in ipairs({106, 342, 410}) do
			if not (x < 3010 and z == 410) then bollard(realm, "SafetyBollard", Vector3.new(x, 1.2, z), C.Gold, zone) end
		end
	end
	for _, data in ipairs({
		{3084, 6, "APPRAISAL"}, {3144, 6, "SALES"}, {3248, 6, "OWNER"},
		{3009, 407, "PARTS"}, {3250, 407, "OPERATIONS"},
	}) do
		local marker = block(realm, "Wayfinding", Vector3.new(data[1] :: number, 3.3, data[2] :: number), Vector3.new(10, 5, 0.25), C.DeepNavy, Enum.Material.Glass, false, nil, zone)
		marker:SetAttribute("V5VisualObstacle", true)
		surfaceText(marker, data[3] :: string, Enum.NormalId.Front, C.WarmWhite, true)
	end

	for _, position in ipairs({
		Vector3.new(3007, 0, 104), Vector3.new(3253, 0, 106),
		Vector3.new(3007, 0, 350), Vector3.new(3253, 0, 350),
		Vector3.new(3010, 0, 493), Vector3.new(3250, 0, 493),
	}) do plant(realm, "BoundaryLandscape", position, 1.1, zone) end
	for _, position in ipairs({
		Vector3.new(3005, 10, 100), Vector3.new(3255, 10, 100),
		Vector3.new(3005, 10, 350), Vector3.new(3255, 10, 350),
		Vector3.new(3080, 12, 405), Vector3.new(3180, 12, 405),
	}) do taskLight(realm, "CampusLight", position, Vector3.new(0.8, 0.8, 0.8), if position.Z > 360 then C.Gold else C.WarmWhite, 0.65, 28, zone) end

	person(realm, "Courtyard_Customer_A", Vector3.new(3092, 0, 387), C.WarmWhite, "Customer", zone)
	person(realm, "Courtyard_Customer_B", Vector3.new(3168, 0, 387), C.WarmWhite, "Customer", zone)
	realm:SetAttribute("CompositionStatus", "BUILT")
end

local function staticAudit(root: Instance, layer: Instance): ({string}, {[string]: number})
	local clearances = root:FindFirstChild("03_Protected_Clearances")
	local conflicts = {}
	local byZone: {[string]: number} = {}
	if not clearances then return {"MISSING_PROTECTED_CLEARANCES"}, byZone end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {layer}
	for _, envelope in ipairs(clearances:GetChildren()) do
		if envelope:IsA("BasePart") then
			for _, hit in ipairs(Workspace:GetPartBoundsInBox(envelope.CFrame, envelope.Size, params)) do
				if hit:GetAttribute("V5ProductionBSolid") then
					local zone = hit:GetAttribute("ZoneId") or "UNKNOWN"
					local record = envelope.Name .. " <-> " .. hit:GetFullName()
					table.insert(conflicts, record)
					byZone[zone] = (byZone[zone] or 0) + 1
					hit:SetAttribute("V5ProductionBConflict", envelope.Name)
				end
			end
		end
	end
	return conflicts, byZone
end

local function routeVisualAudit(root: Instance, layer: Instance): {string}
	local routes = root:FindFirstChild("02_Vehicle_Routes")
	if not routes then return {"MISSING_VEHICLE_ROUTES"} end
	local conflicts = {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {layer}
	local function isObstacle(hit: BasePart): boolean
		if hit:GetAttribute("V5ProductionBSolid") or hit:GetAttribute("V5VisualObstacle") then return true end
		local cursor: Instance? = hit
		while cursor and cursor ~= layer do
			if cursor:GetAttribute("VehicleDisplay") then return true end
			cursor = cursor.Parent
		end
		return false
	end
	for _, route in ipairs(routes:GetChildren()) do
		if route:IsA("BasePart") and not route.Name:find("Walk") and not route.Name:find("Staff") then
			local envelope = Vector3.new(route.Size.X, 8, route.Size.Z)
			local cframe = CFrame.new(route.Position.X, 4, route.Position.Z) * (route.CFrame - route.Position)
			for _, hit in ipairs(Workspace:GetPartBoundsInBox(cframe, envelope, params)) do
				if isObstacle(hit) then
					table.insert(conflicts, route.Name .. " <-> " .. hit:GetFullName())
					hit:SetAttribute("V5ProductionBRouteVisualConflict", route.Name)
				end
			end
		end
	end
	-- The accepted large-arrival path begins off-map and approaches Intake 1.
	-- Audit its full swept volume, not only the final unload rectangle.
	local largeArrivalCFrame = CFrame.new(ORIGIN_X - 103, 3.5, -9)
	local largeArrivalSize = Vector3.new(12, 7, 164.5)
	for _, hit in ipairs(Workspace:GetPartBoundsInBox(largeArrivalCFrame, largeArrivalSize, params)) do
		if isObstacle(hit) then
			table.insert(conflicts, "LargeArrivalApproach <-> " .. hit:GetFullName())
			hit:SetAttribute("V5ProductionBRouteVisualConflict", "LargeArrivalApproach")
		end
	end
	for index, data in ipairs({
		{ORIGIN_X - 111, 5.0, 172.94},
		{ORIGIN_X - 86, 5.0, 172.94},
		{ORIGIN_X - 61, 5.0, 172.94},
	}) do
		local intakeCFrame = CFrame.new(data[1], 3.2, data[2])
		local intakeSize = Vector3.new(10.58, 6.4, data[3])
		for _, hit in ipairs(Workspace:GetPartBoundsInBox(intakeCFrame, intakeSize, params)) do
			if isObstacle(hit) then
				table.insert(conflicts, "IntakeApproach" .. index .. " <-> " .. hit:GetFullName())
				hit:SetAttribute("V5ProductionBRouteVisualConflict", "IntakeApproach" .. index)
			end
		end
	end
	for index, startX in ipairs({ORIGIN_X - 111, ORIGIN_X - 86, ORIGIN_X - 61}) do
		local minX = math.min(startX, ORIGIN_X - 64) - 9.47
		local maxX = math.max(startX, ORIGIN_X - 64) + 9.47
		local mergeCFrame = CFrame.new((minX + maxX) / 2, 3.2, 82)
		local mergeSize = Vector3.new(maxX - minX, 6.4, 10.58)
		for _, hit in ipairs(Workspace:GetPartBoundsInBox(mergeCFrame, mergeSize, params)) do
			if isObstacle(hit) then
				table.insert(conflicts, "IntakeMerge" .. index .. " <-> " .. hit:GetFullName())
				hit:SetAttribute("V5ProductionBRouteVisualConflict", "IntakeMerge" .. index)
			end
		end
	end
	return conflicts
end

function Installer.Install(): {[string]: any}
	local root = Workspace:FindFirstChild(ROOT_NAME)
	assert(root, "Missing accepted V5 root: " .. ROOT_NAME)
	assert(root:FindFirstChild("08_Institution_Production_A"), "Production A must be installed before Production B")

	local old = root:FindFirstChild(LAYER_NAME)
	if old then old:Destroy() end
	restoreHidden(root)

	local layer = model(root, LAYER_NAME)
	layer:SetAttribute("Checkpoint", "V5_INSTITUTION_PRODUCTION_B")
	layer:SetAttribute("Version", Installer.Version)
	layer:SetAttribute("StateId", "INSTITUTION")
	layer:SetAttribute("Purpose", "Commercial, support, ownership, legacy and campus completion")
	layer:SetAttribute("PurchasePadsIncluded", false)
	layer:SetAttribute("TrafficControllerIncluded", false)
	layer:SetAttribute("TrafficLayoutChanged", false)
	layer:SetAttribute("CollectorLiveTraffic", false)
	layer:SetAttribute("MaxProductionBays", 2)
	layer:SetAttribute("Status", "BUILT_AWAITING_REVIEW")

	local replaced = hideMassing(root)
	local hiddenBillboards = hideDiagnosticBillboards(root, layer)
	local frontage = model(layer, "01_Frontage_Commercial")
	local rear = model(layer, "02_Rear_Operations_And_Prestige")
	local estate = model(layer, "03_Estate_Identity")
	buildIntake(frontage)
	buildSales(frontage)
	buildOwnerGarage(frontage)
	buildLogistics(rear)
	buildOperations(rear)
	buildCollector(rear)
	buildHQ(rear)
	buildPublicRealm(estate)

	local conflicts, byZone = staticAudit(root, layer)
	local routeVisualConflicts = routeVisualAudit(root, layer)
	local partCount = 0
	local solidCount = 0
	local modelCount = 0
	local lightCount = 0
	local occupationCount = 0
	for _, item in ipairs(layer:GetDescendants()) do
		if item:IsA("BasePart") then
			partCount += 1
			if item:GetAttribute("V5ProductionBSolid") then solidCount += 1 end
		elseif item:IsA("Model") then
			modelCount += 1
		elseif item:IsA("PointLight") then
			lightCount += 1
		end
		if item:GetAttribute("OccupationAnchor") then occupationCount += 1 end
	end

	local evidence = Instance.new("Folder")
	evidence.Name = "99_Production_B_Evidence"
	evidence:SetAttribute("StaticStatus", if #conflicts == 0 then "PASS" else "FAIL")
	evidence:SetAttribute("StaticEnvelopeConflicts", #conflicts)
	evidence:SetAttribute("StaticConflictList", table.concat(conflicts, " | "))
	evidence:SetAttribute("RouteVisualConflicts", #routeVisualConflicts)
	evidence:SetAttribute("RouteVisualConflictList", table.concat(routeVisualConflicts, " | "))
	evidence:SetAttribute("PartCount", partCount)
	evidence:SetAttribute("SolidPartCount", solidCount)
	evidence:SetAttribute("AssemblyModelCount", modelCount)
	evidence:SetAttribute("LocalLightCount", lightCount)
	evidence:SetAttribute("OccupationAnchorCount", occupationCount)
	evidence:SetAttribute("ReplacedMassingParts", replaced)
	evidence:SetAttribute("HiddenDiagnosticBillboards", hiddenBillboards)
	evidence:SetAttribute("FrontageZones", 3)
	evidence:SetAttribute("RearZones", 4)
	evidence:SetAttribute("PublicRealmSystems", 1)
	evidence:SetAttribute("OwnerCarPositions", 6)
	evidence:SetAttribute("CollectorSnapshots", 6)
	evidence:SetAttribute("SalesDisplays", 6)
	evidence:SetAttribute("VisitorParkingBays", 3)
	evidence:SetAttribute("VisualReviewStatus", "PENDING")
	evidence:SetAttribute("RouteRegressionStatus", "PENDING")
	for zone, count in pairs(byZone) do evidence:SetAttribute(zone .. "_Conflicts", count) end
	evidence.Parent = layer

	root:SetAttribute("EnvironmentStatus", if #conflicts == 0 and #routeVisualConflicts == 0 then "INSTITUTION_PRODUCTION_B_BUILT" else "INSTITUTION_PRODUCTION_B_CONFLICT")
	root:SetAttribute("InstitutionProductionBVersion", Installer.Version)
	root:SetAttribute("InstitutionProductionBPartCount", partCount)
	root:SetAttribute("InstitutionProductionBConflicts", #conflicts)
	root:SetAttribute("InstitutionProductionBRouteVisualConflicts", #routeVisualConflicts)
	root:SetAttribute("InstitutionProductionBStatus", "AWAITING_VISUAL_AND_ROUTE_REVIEW")

	return {
		Layer = layer,
		Parts = partCount,
		Solids = solidCount,
		Models = modelCount,
		Lights = lightCount,
		OccupationAnchors = occupationCount,
		ReplacedMassing = replaced,
		StaticConflicts = #conflicts,
		RouteVisualConflicts = #routeVisualConflicts,
		ConflictList = conflicts,
	}
end

function Installer.Uninstall()
	local root = Workspace:FindFirstChild(ROOT_NAME)
	if not root then return end
	local layer = root:FindFirstChild(LAYER_NAME)
	if layer then layer:Destroy() end
	restoreHidden(root)
	root:SetAttribute("InstitutionProductionBVersion", nil)
	root:SetAttribute("InstitutionProductionBPartCount", nil)
	root:SetAttribute("InstitutionProductionBConflicts", nil)
	root:SetAttribute("InstitutionProductionBRouteVisualConflicts", nil)
	root:SetAttribute("InstitutionProductionBStatus", nil)
	root:SetAttribute("EnvironmentStatus", "INSTITUTION_PRODUCTION_A_ACCEPTED")
end

-- F04: legacy whole-layer rebuilds cannot erase an integrated frontage.
for _,method in {"Install","Uninstall"} do
 local legacy=Installer[method]
 Installer[method]=function(...)
  local current=workspace:FindFirstChild("SellCars_Dealership_Growth_V5")
  assert(not(current and current:GetAttribute("Frontage04Activated")),"Frontage04 active: use scoped integration rollback before a legacy rebuild")
  return legacy(...)
 end
end
return Installer

