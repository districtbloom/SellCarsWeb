--!strict

-- Sell Cars V5 — Institution route, envelope and massing greybox.
-- This is a clean source-owned root. V3/V4 remain in place as reversibly
-- hidden evidence. No purchase pads or production traffic are installed.

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Installer = {}
Installer.Version = "2026-09-03.v5-institution-envelope.1"

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local SPAWN_NAME = "SellCars_V5_PlayerSpawn"
local ORIGIN_X = 3130
local ROAD_Z = -38
local PLOT_FRONT_Z = -20
local PLOT_DEPTH = 520

local COLORS = {
	Ground = Color3.fromRGB(91, 83, 69),
	Concrete = Color3.fromRGB(104, 108, 108),
	Road = Color3.fromRGB(47, 51, 56),
	Frame = Color3.fromRGB(25, 34, 44),
	Roof = Color3.fromRGB(37, 49, 63),
	Glass = Color3.fromRGB(82, 170, 191),
	Inbound = Color3.fromRGB(52, 137, 235),
	Return = Color3.fromRGB(62, 202, 139),
	Crossover = Color3.fromRGB(255, 153, 68),
	Intake = Color3.fromRGB(87, 197, 232),
	Sales = Color3.fromRGB(244, 204, 65),
	Owner = Color3.fromRGB(172, 112, 255),
	Wash = Color3.fromRGB(43, 210, 225),
	Mechanical = Color3.fromRGB(230, 70, 62),
	Body = Color3.fromRGB(242, 146, 51),
	Tune = Color3.fromRGB(104, 89, 224),
	Paint = Color3.fromRGB(235, 79, 174),
	Detail = Color3.fromRGB(53, 209, 170),
	Photo = Color3.fromRGB(92, 164, 255),
	Support = Color3.fromRGB(77, 125, 102),
	Collector = Color3.fromRGB(207, 169, 76),
	HQ = Color3.fromRGB(67, 101, 151),
	Clearance = Color3.fromRGB(255, 239, 122),
}

local previousRootNames = {
	"SellCars_Dealership_RouteGreybox_V3",
	"SellCars_Dealership_Growth_V4",
}

local previousScriptPrefixes = {
	"SellCarsV3",
	"SellCarsV4",
}

local function startsWith(value: string, prefix: string): boolean
	return string.sub(value, 1, #prefix) == prefix
end

local function folder(parent: Instance, name: string): Folder
	local result = Instance.new("Folder")
	result.Name = name
	result.Parent = parent
	return result
end

local function model(parent: Instance, name: string): Model
	local result = Instance.new("Model")
	result.Name = name
	result.Parent = parent
	return result
end

local function part(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Anchored = true
	result.Size = size
	result.Position = position
	result.Color = color
	result.Material = material or Enum.Material.SmoothPlastic
	result.Transparency = transparency or 0
	result.CanCollide = if canCollide == nil then true else canCollide
	result.CanTouch = result.CanCollide
	result.CanQuery = result.CanCollide
	result.CastShadow = result.Transparency < 0.5
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result.Parent = parent
	return result
end

local function setNonPhysical(item: BasePart)
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
end

local function label(parent: Instance, name: string, position: Vector3, text: string, color: Color3): Part
	local anchor = part(parent, name, position, Vector3.new(1, 1, 1), color, Enum.Material.SmoothPlastic, 1, false)
	setNonPhysical(anchor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "CompactGreyboxLabel"
	gui.Size = UDim2.fromOffset(220, 36)
	gui.StudsOffset = Vector3.new(0, 1.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 260
	gui.Enabled = false
	gui.Parent = anchor
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundColor3 = Color3.fromRGB(15, 20, 27)
	textLabel.BackgroundTransparency = 0.18
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(245, 247, 250)
	textLabel.TextScaled = true
	textLabel.Parent = gui
	return anchor
end

local function storeAndHide(instance: Instance)
	if instance:IsA("BasePart") then
		if instance:GetAttribute("V5SavedTransparency") == nil then
			instance:SetAttribute("V5SavedTransparency", instance.Transparency)
			instance:SetAttribute("V5SavedCanCollide", instance.CanCollide)
			instance:SetAttribute("V5SavedCanTouch", instance.CanTouch)
			instance:SetAttribute("V5SavedCanQuery", instance.CanQuery)
		end
		instance.Transparency = 1
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
	elseif instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") or instance:IsA("Light") then
		if instance:GetAttribute("V5SavedEnabled") == nil then
			instance:SetAttribute("V5SavedEnabled", instance.Enabled)
		end
		instance.Enabled = false
	elseif instance:IsA("BaseScript") then
		if instance:GetAttribute("V5SavedEnabled") == nil then
			instance:SetAttribute("V5SavedEnabled", instance.Enabled)
		end
		instance.Enabled = false
	end
end

local function restoreInstance(instance: Instance)
	if instance:IsA("BasePart") then
		local transparency = instance:GetAttribute("V5SavedTransparency")
		local canCollide = instance:GetAttribute("V5SavedCanCollide")
		local canTouch = instance:GetAttribute("V5SavedCanTouch")
		local canQuery = instance:GetAttribute("V5SavedCanQuery")
		if typeof(transparency) == "number" then instance.Transparency = transparency end
		if typeof(canCollide) == "boolean" then instance.CanCollide = canCollide end
		if typeof(canTouch) == "boolean" then instance.CanTouch = canTouch end
		if typeof(canQuery) == "boolean" then instance.CanQuery = canQuery end
	elseif instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") or instance:IsA("Light") or instance:IsA("BaseScript") then
		local enabled = instance:GetAttribute("V5SavedEnabled")
		if typeof(enabled) == "boolean" then instance.Enabled = enabled end
	end
end

local function hidePrevious(): number
	local hidden = 0
	for _, rootName in ipairs(previousRootNames) do
		local root = Workspace:FindFirstChild(rootName)
		if root then
			storeAndHide(root)
			for _, descendant in ipairs(root:GetDescendants()) do
				storeAndHide(descendant)
				if descendant:IsA("BasePart") then hidden += 1 end
			end
			root:SetAttribute("HiddenByV5", true)
			root:SetAttribute("V5ReversibleArchive", true)
		end
	end

	for _, service in ipairs({ServerScriptService, StarterPlayer.StarterPlayerScripts}) do
		for _, descendant in ipairs(service:GetDescendants()) do
			if descendant:IsA("BaseScript") then
				for _, prefix in ipairs(previousScriptPrefixes) do
					if startsWith(descendant.Name, prefix) then
						storeAndHide(descendant)
					end
				end
			end
		end
	end

	for _, spawnName in ipairs({"SellCars_V3_PlayerSpawn", "SellCars_V4_PlayerSpawn"}) do
		local spawn = Workspace:FindFirstChild(spawnName)
		if spawn then storeAndHide(spawn) end
		if spawn and spawn:IsA("SpawnLocation") then spawn.Enabled = false end
	end

	return hidden
end

local function restorePrevious()
	for _, rootName in ipairs(previousRootNames) do
		local root = Workspace:FindFirstChild(rootName)
		if root then
			restoreInstance(root)
			for _, descendant in ipairs(root:GetDescendants()) do restoreInstance(descendant) end
			root:SetAttribute("HiddenByV5", nil)
		end
	end
	for _, service in ipairs({ServerScriptService, StarterPlayer.StarterPlayerScripts}) do
		for _, descendant in ipairs(service:GetDescendants()) do
			if descendant:IsA("BaseScript") then restoreInstance(descendant) end
		end
	end
	for _, spawnName in ipairs({"SellCars_V3_PlayerSpawn", "SellCars_V4_PlayerSpawn"}) do
		local spawn = Workspace:FindFirstChild(spawnName)
		if spawn then restoreInstance(spawn) end
	end
end

local function routePart(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3): Part
	local item = part(parent, name, position, size, color, Enum.Material.Neon, 0.48, false)
	setNonPhysical(item)
	item:SetAttribute("V5RouteRibbon", true)
	return item
end

local function routeBetween(parent: Instance, name: string, from: Vector3, to: Vector3, width: number, color: Color3): Part
	local midpoint = (from + to) / 2
	local length = (to - from).Magnitude
	local item = routePart(parent, name, midpoint, Vector3.new(width, 0.12, length), color)
	item.CFrame = CFrame.lookAt(midpoint, to)
	return item
end

local function clearance(parent: Instance, name: string, position: Vector3, size: Vector3, kind: string): Part
	local item = part(parent, name, position, size, COLORS.Clearance, Enum.Material.ForceField, 1, false)
	setNonPhysical(item)
	item:SetAttribute("V5ProtectedEnvelope", true)
	item:SetAttribute("EnvelopeKind", kind)
	return item
end

local function floorEnvelope(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3): Part
	local item = part(parent, name, position, Vector3.new(size.X, 0.18, size.Z), color, Enum.Material.SmoothPlastic, 0.80, false)
	setNonPhysical(item)
	item:SetAttribute("V5FunctionEnvelope", true)
	return item
end

local function blockerPart(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, material: Enum.Material?): Part
	local item = part(parent, name, position, size, color, material or Enum.Material.Metal, 0, true)
	item:SetAttribute("V5Blocker", true)
	return item
end

local function capacitySocket(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, kind: string, yaw: number?): Part
	local item = part(parent, name, position, size, color, Enum.Material.Neon, 0.58, false)
	setNonPhysical(item)
	if yaw then item.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0) end
	item:SetAttribute("V5CapacitySocket", true)
	item:SetAttribute("SocketKind", kind)
	return item
end

local function addOpenPortal(parent: Instance, name: string, x: number, z: number, openingWidth: number, color: Color3, side: number)
	local portal = model(parent, name)
	local innerX = x
	local postSize = Vector3.new(1.4, 12, 1.4)
	blockerPart(portal, "PortalPostA", Vector3.new(innerX, 6, z - openingWidth / 2), postSize, COLORS.Frame)
	blockerPart(portal, "PortalPostB", Vector3.new(innerX, 6, z + openingWidth / 2), postSize, COLORS.Frame)
	local header = part(portal, "PortalHeader", Vector3.new(innerX, 12.4, z), Vector3.new(1.5, 1.4, openingWidth + 1.4), color, Enum.Material.Neon, 0, false)
	header:SetAttribute("V5Overhead", true)
	portal:SetAttribute("OpenSide", if side < 0 then "EAST_TO_SPINE" else "WEST_TO_SPINE")
end

local function addFunction(
	parent: Instance,
	clearanceParent: Instance,
	socketParent: Instance,
	name: string,
	side: number,
	z: number,
	depth: number,
	color: Color3
)
	local group = model(parent, name)
	group:SetAttribute("V5Function", name)
	group:SetAttribute("MaximumBays", 2)
	group:SetAttribute("EntryExit", "CENTRAL_SPINE_WITH_LOCAL_CROSSOVERS")
	group:SetAttribute("DetailStatus", "MASSING_AND_HERO_RESERVE_ONLY")

	local envelopeX = ORIGIN_X + side * 82
	local innerX = ORIGIN_X + side * 39
	local outerX = ORIGIN_X + side * 123
	local bayX = ORIGIN_X + side * 64
	local serviceX = ORIGIN_X + side * 108

	floorEnvelope(group, "MaximumFunctionEnvelope", Vector3.new(envelopeX, 0.15, z), Vector3.new(86, 0.2, depth), color)
	local service = floorEnvelope(group, "EquipmentAndStaffBand", Vector3.new(serviceX, 0.32, z), Vector3.new(24, 0.2, depth - 4), color)
	service.Transparency = 0.62
	service:SetAttribute("ReservedForEquipmentAndStaff", true)

	blockerPart(group, "OuterWall", Vector3.new(outerX, 5.5, z), Vector3.new(2, 11, depth - 4), COLORS.Frame, Enum.Material.Concrete)
	for _, edgeZ in ipairs({z - depth / 2 + 2, z + depth / 2 - 2}) do
		blockerPart(group, "OuterCornerColumn", Vector3.new(outerX - side * 4, 7, edgeZ), Vector3.new(2, 14, 2), COLORS.Frame)
	end
	local roof = part(group, "OpenCanopy", Vector3.new(envelopeX, 14.5, z), Vector3.new(84, 1.2, depth - 2), COLORS.Roof, Enum.Material.Metal, 0.12, false)
	roof:SetAttribute("V5Overhead", true)

	for bayIndex, bayOffset in ipairs({-12, 12}) do
		local bayZ = z + bayOffset
		capacitySocket(socketParent, name .. "_Bay_" .. bayIndex, Vector3.new(bayX, 0.42, bayZ), Vector3.new(34, 0.16, 14), color, "PRODUCTION_BAY", 0)
		clearance(clearanceParent, name .. "_BayClearance_" .. bayIndex, Vector3.new(bayX, 4, bayZ), Vector3.new(34, 8, 14), "PRODUCTION_BAY")
		addOpenPortal(group, "OpenPortal_" .. bayIndex, innerX, bayZ, 15.5, color, side)
	end

	local hero = blockerPart(group, "HeroEquipmentReserve", Vector3.new(serviceX, 3.2, z), Vector3.new(14, 6.4, math.min(22, depth - 10)), color, Enum.Material.Metal)
	hero.Transparency = 0.18
	hero:SetAttribute("ReplaceWithFunctionSpecificEquipment", true)
	hero:SetAttribute("NotFinalArt", true)
	label(group, "FunctionLabel", Vector3.new(innerX, 13.5, z), string.upper(name), color)
	return group
end

local function aabbOverlap(a: BasePart, b: BasePart): boolean
	local ap, as = a.Position, a.Size
	local bp, bs = b.Position, b.Size
	return math.abs(ap.X - bp.X) < (as.X + bs.X) / 2
		and math.abs(ap.Y - bp.Y) < (as.Y + bs.Y) / 2
		and math.abs(ap.Z - bp.Z) < (as.Z + bs.Z) / 2
end

local function validate(root: Model): (number, number, number)
	local envelopes = {}
	local blockers = {}
	local sockets = 0
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") then
			if item:GetAttribute("V5ProtectedEnvelope") then table.insert(envelopes, item) end
			if item:GetAttribute("V5Blocker") then table.insert(blockers, item) end
			if item:GetAttribute("V5CapacitySocket") then sockets += 1 end
		end
	end
	local conflicts = 0
	for _, envelope in ipairs(envelopes) do
		for _, blocker in ipairs(blockers) do
			if aabbOverlap(envelope, blocker) then
				conflicts += 1
				blocker:SetAttribute("V5EnvelopeConflict", envelope.Name)
			end
		end
	end
	return #envelopes, sockets, conflicts
end

function Installer.Install(): {[string]: any}
	assert(game.PlaceId == 125334614375606, "V5 installer must run only in Sell Cars Tycoon")
	local previousV5 = Workspace:FindFirstChild(ROOT_NAME)
	if previousV5 then previousV5:Destroy() end
	local previousSpawn = Workspace:FindFirstChild(SPAWN_NAME)
	if previousSpawn then previousSpawn:Destroy() end

	local hiddenParts = hidePrevious()

	local root = model(Workspace, ROOT_NAME)
	root:SetAttribute("Version", Installer.Version)
	root:SetAttribute("Checkpoint", "V5_INSTITUTION_ENVELOPE_01")
	root:SetAttribute("ProgressionState", "INSTITUTION")
	root:SetAttribute("EnvironmentStatus", "STATIC_GREYBOX_INSTALLED")
	root:SetAttribute("SourceOwned", true)
	root:SetAttribute("InteractivePadsIncluded", false)
	root:SetAttribute("TrafficRuntimeIncluded", false)
	root:SetAttribute("ProductionBayMaximum", 2)
	root:SetAttribute("InstitutionDealerCarTestTarget", 13)
	root:SetAttribute("OwnerGarageCapacity", 6)
	root:SetAttribute("CollectorSnapshotCapacity", 6)
	root:SetAttribute("GrowthDirection", "DEPTH")
	root:SetAttribute("SupportDirection", "REAR")
	root:SetAttribute("EnvelopeDimensionsStatus", "PROVISIONAL_PENDING_REAL_CHASSIS")
	root:SetAttribute("DebugLabelsHiddenByDefault", true)

	local metadata = folder(root, "00_Contract")
	metadata:SetAttribute("Frontage", "INTAKE_SALES_DELIVERY_OWNER")
	metadata:SetAttribute("ProductionOrder", "WASH_MECHANICAL_BODY_TUNE_PAINT_DETAIL_PHOTO")
	metadata:SetAttribute("Collector", "ELEVATED_SNAPSHOT_ONLY_NO_LIVE_ROUTE")
	metadata:SetAttribute("HQ", "DEEPEST_AND_TALLEST_CROWN")
	metadata:SetAttribute("EarlierRoots", "PRESERVED_HIDDEN_REVERSIBLE")

	local ground = folder(root, "01_Ground_And_Road")
	part(ground, "InstitutionParcel", Vector3.new(ORIGIN_X, -0.55, PLOT_FRONT_Z + PLOT_DEPTH / 2), Vector3.new(260, 1, PLOT_DEPTH), COLORS.Ground, Enum.Material.Ground)
	part(ground, "CityRoad", Vector3.new(ORIGIN_X, -0.35, ROAD_Z), Vector3.new(300, 1, 34), COLORS.Road, Enum.Material.Asphalt)
	part(ground, "FrontageApron", Vector3.new(ORIGIN_X, -0.08, 46), Vector3.new(252, 0.35, 126), COLORS.Concrete, Enum.Material.Concrete)
	part(ground, "ProductionGround", Vector3.new(ORIGIN_X, -0.08, 232), Vector3.new(252, 0.35, 246), Color3.fromRGB(82, 87, 89), Enum.Material.Concrete)
	part(ground, "RearCampusGround", Vector3.new(ORIGIN_X, -0.08, 430), Vector3.new(252, 0.35, 132), Color3.fromRGB(96, 94, 82), Enum.Material.Pavement)
	for x = ORIGIN_X - 125, ORIGIN_X + 125, 25 do
		local dash = part(ground, "RoadDash", Vector3.new(x, 0.18, ROAD_Z), Vector3.new(13, 0.12, 0.8), Color3.fromRGB(247, 202, 67), Enum.Material.Neon, 0, false)
		setNonPhysical(dash)
	end

	local routes = folder(root, "02_Vehicle_Routes")
	local routeClearances = folder(root, "03_Protected_Clearances")
	local sockets = folder(root, "04_Capacity_Sockets")
	local architecture = folder(root, "05_Architecture_Massing")
	local frontage = folder(architecture, "01_Frontage")
	local production = folder(architecture, "02_Production")
	local rear = folder(architecture, "03_Rear_Campus")
	local review = folder(root, "06_Review_And_Evidence")

	-- City entry, front circulation and two-way production spines.
	routeBetween(routes, "RoadToIntake", Vector3.new(ORIGIN_X - 92, 0.3, ROAD_Z + 8), Vector3.new(ORIGIN_X - 92, 0.3, 12), 12, COLORS.Inbound)
	routeBetween(routes, "IntakeDispatch", Vector3.new(ORIGIN_X - 64, 0.3, 82), Vector3.new(ORIGIN_X - 25, 0.3, 102), 12, COLORS.Inbound)
	routePart(routes, "InboundSpine", Vector3.new(ORIGIN_X - 25, 0.3, 226), Vector3.new(18, 0.12, 268), COLORS.Inbound)
	routePart(routes, "ReturnSpine", Vector3.new(ORIGIN_X + 25, 0.3, 226), Vector3.new(18, 0.12, 268), COLORS.Return)
	routePart(routes, "DeepTurn", Vector3.new(ORIGIN_X, 0.3, 360), Vector3.new(68, 0.12, 18), COLORS.Crossover)
	routeBetween(routes, "ReturnToSales", Vector3.new(ORIGIN_X + 25, 0.3, 92), Vector3.new(ORIGIN_X, 0.3, 76), 12, COLORS.Return)
	routeBetween(routes, "SalesExit", Vector3.new(ORIGIN_X, 0.3, 24), Vector3.new(ORIGIN_X, 0.3, ROAD_Z + 8), 12, COLORS.Return)
	routeBetween(routes, "OwnerIndependentEntry", Vector3.new(ORIGIN_X + 91, 0.3, ROAD_Z + 8), Vector3.new(ORIGIN_X + 91, 0.3, 16), 12, COLORS.Owner)

	clearance(routeClearances, "InboundSpineClear", Vector3.new(ORIGIN_X - 25, 4, 226), Vector3.new(18, 8, 268), "VEHICLE_SPINE")
	clearance(routeClearances, "ReturnSpineClear", Vector3.new(ORIGIN_X + 25, 4, 226), Vector3.new(18, 8, 268), "VEHICLE_SPINE")
	clearance(routeClearances, "DeepTurnClear", Vector3.new(ORIGIN_X, 4, 360), Vector3.new(68, 8, 18), "DEEP_CROSSOVER")
	for _, z in ipairs({96, 146, 211, 276, 348}) do
		routePart(routes, "LocalCrossover", Vector3.new(ORIGIN_X, 0.31, z), Vector3.new(68, 0.12, 14), COLORS.Crossover)
		clearance(routeClearances, "LocalCrossoverClear", Vector3.new(ORIGIN_X, 4, z), Vector3.new(68, 8, 14), "LOCAL_SKIP_REJOIN")
	end

	-- Frontage maximum envelopes and capacities.
	floorEnvelope(frontage, "IntakeEnvelope", Vector3.new(ORIGIN_X - 88, 0.18, 50), Vector3.new(76, 0.2, 78), COLORS.Intake)
	floorEnvelope(frontage, "SalesEnvelope", Vector3.new(ORIGIN_X, 0.18, 54), Vector3.new(80, 0.2, 96), COLORS.Sales)
	floorEnvelope(frontage, "OwnerGarageEnvelope", Vector3.new(ORIGIN_X + 88, 0.18, 54), Vector3.new(76, 0.2, 96), COLORS.Owner)
	label(frontage, "IntakeLabel", Vector3.new(ORIGIN_X - 88, 4, 10), "INTAKE / APPRAISAL · 2 + SPECIAL", COLORS.Intake)
	label(frontage, "SalesLabel", Vector3.new(ORIGIN_X, 4, 8), "SALES · 6 + REVEAL + STAGE", COLORS.Sales)
	label(frontage, "OwnerLabel", Vector3.new(ORIGIN_X + 88, 4, 8), "OWNER GARAGE · 6", COLORS.Owner)

	for index, data in ipairs({
		{ORIGIN_X - 111, 35, "ORDINARY"},
		{ORIGIN_X - 86, 35, "ORDINARY"},
		{ORIGIN_X - 61, 62, "RARE_OR_TOW"},
	}) do
		capacitySocket(sockets, "Intake_" .. index, Vector3.new(data[1] :: number, 0.45, data[2] :: number), Vector3.new(14, 0.16, 23), COLORS.Intake, data[3] :: string)
		clearance(routeClearances, "IntakeClear_" .. index, Vector3.new(data[1] :: number, 4, data[2] :: number), Vector3.new(14, 8, 23), "INTAKE_POSITION")
	end
	clearance(routeClearances, "TransporterSweep", Vector3.new(ORIGIN_X - 103, 4, 54), Vector3.new(45, 8, 38.5), "TRANSPORTER_MANOEUVRE")

	local saleIndex = 0
	for _, z in ipairs({30, 56}) do
		for _, xOffset in ipairs({-26, 0, 26}) do
			saleIndex += 1
			capacitySocket(sockets, "SalesDisplay_" .. saleIndex, Vector3.new(ORIGIN_X + xOffset, 0.45, z), Vector3.new(12, 0.16, 20), COLORS.Sales, "SALES_DISPLAY")
		end
	end
	capacitySocket(sockets, "SalesReveal", Vector3.new(ORIGIN_X + 14, 0.45, 84), Vector3.new(12, 0.16, 20), COLORS.Sales, "DELIVERY_REVEAL")
	capacitySocket(sockets, "SalesStaging", Vector3.new(ORIGIN_X - 14, 0.45, 84), Vector3.new(12, 0.16, 20), COLORS.Sales, "DELIVERY_STAGING")

	local ownerIndex = 0
	for _, z in ipairs({28, 56, 84}) do
		for _, xOffset in ipairs({-15, 15}) do
			ownerIndex += 1
			capacitySocket(sockets, "OwnerCar_" .. ownerIndex, Vector3.new(ORIGIN_X + 88 + xOffset, 0.45, z), Vector3.new(14, 0.16, 23), COLORS.Owner, if ownerIndex == 6 then "OWNER_CUSTOMIZATION" else "OWNER_CAR")
		end
	end

	-- Seven routed functions. Cars park perpendicular to the two visible spines.
	addFunction(production, routeClearances, sockets, "Wash", -1, 120, 44, COLORS.Wash)
	addFunction(production, routeClearances, sockets, "Mechanical", -1, 175, 58, COLORS.Mechanical)
	addFunction(production, routeClearances, sockets, "Body_Restoration", -1, 239, 64, COLORS.Body)
	addFunction(production, routeClearances, sockets, "Tune_Performance", -1, 307, 60, COLORS.Tune)
	addFunction(production, routeClearances, sockets, "Paint_Exterior", 1, 307, 68, COLORS.Paint)
	addFunction(production, routeClearances, sockets, "Detail_QC", 1, 239, 58, COLORS.Detail)
	addFunction(production, routeClearances, sockets, "Photo_Listing", 1, 175, 54, COLORS.Photo)

	-- Rear court, holding, support wings, elevated Collector and deepest HQ crown.
	floorEnvelope(rear, "HeroCourtyard", Vector3.new(ORIGIN_X, 0.18, 385), Vector3.new(106, 0.2, 42), COLORS.Collector)
	label(rear, "CourtyardLabel", Vector3.new(ORIGIN_X, 3.5, 378), "HERO COURTYARD / VIEW VOID", COLORS.Collector)
	for index, xOffset in ipairs({-30, 0, 30}) do
		capacitySocket(sockets, "DealerHolding_" .. index, Vector3.new(ORIGIN_X + xOffset, 0.43, 371), Vector3.new(12, 0.16, 20), COLORS.Crossover, "DEALER_HOLDING")
	end

	local logistics = model(rear, "Parts_And_Logistics")
	floorEnvelope(logistics, "LogisticsEnvelope", Vector3.new(ORIGIN_X - 91, 0.18, 442), Vector3.new(68, 0.2, 68), COLORS.Support)
	blockerPart(logistics, "LogisticsMassing", Vector3.new(ORIGIN_X - 98, 10, 448), Vector3.new(52, 20, 48), COLORS.Support, Enum.Material.Concrete)
	part(logistics, "OpenReceivingCanopy", Vector3.new(ORIGIN_X - 72, 12, 415), Vector3.new(34, 1.2, 28), COLORS.Roof, Enum.Material.Metal, 0.12, false)
	label(logistics, "LogisticsLabel", Vector3.new(ORIGIN_X - 91, 17, 416), "PARTS + LOGISTICS", COLORS.Support)
	clearance(routeClearances, "LogisticsVehicleClear", Vector3.new(ORIGIN_X - 87, 4, 397), Vector3.new(26, 8, 38), "LOGISTICS_DELIVERY")

	local operations = model(rear, "Staff_Operations_Utilities")
	floorEnvelope(operations, "OperationsEnvelope", Vector3.new(ORIGIN_X + 91, 0.18, 442), Vector3.new(68, 0.2, 68), COLORS.Support)
	blockerPart(operations, "OperationsMassing", Vector3.new(ORIGIN_X + 98, 10, 448), Vector3.new(52, 20, 48), Color3.fromRGB(72, 101, 112), Enum.Material.Concrete)
	label(operations, "OperationsLabel", Vector3.new(ORIGIN_X + 91, 17, 416), "STAFF + OPERATIONS", COLORS.Support)

	local collector = model(rear, "Elevated_Collector_Hall")
	collector:SetAttribute("LiveVehicleRoute", false)
	collector:SetAttribute("SnapshotCapacity", 6)
	local collectorFloor = part(collector, "CollectorFloor", Vector3.new(ORIGIN_X, 20, 406), Vector3.new(94, 1.4, 58), COLORS.Collector, Enum.Material.Marble)
	collectorFloor:SetAttribute("V5Overhead", true)
	for _, xOffset in ipairs({-44, 44}) do
		for _, zOffset in ipairs({-25, 25}) do
			blockerPart(collector, "CollectorColumn", Vector3.new(ORIGIN_X + xOffset, 10, 406 + zOffset), Vector3.new(2, 20, 2), COLORS.Frame)
		end
	end
	part(collector, "CollectorRoof", Vector3.new(ORIGIN_X, 33, 406), Vector3.new(98, 1.4, 62), COLORS.Roof, Enum.Material.Metal, 0.08, false)
	label(collector, "CollectorLabel", Vector3.new(ORIGIN_X, 29, 378), "ELEVATED COLLECTOR · 6 SNAPSHOTS", COLORS.Collector)
	local collectorIndex = 0
	for _, zOffset in ipairs({-13, 13}) do
		for _, xOffset in ipairs({-28, 0, 28}) do
			collectorIndex += 1
			capacitySocket(sockets, "CollectorSnapshot_" .. collectorIndex, Vector3.new(ORIGIN_X + xOffset, 20.85, 406 + zOffset), Vector3.new(12, 0.16, 20), COLORS.Collector, "COLLECTOR_SNAPSHOT")
		end
	end

	local hq = model(rear, "Institution_Headquarters_Crown")
	floorEnvelope(hq, "HQEnvelope", Vector3.new(ORIGIN_X, 0.18, 468), Vector3.new(96, 0.2, 62), COLORS.HQ)
	blockerPart(hq, "HQLevel1", Vector3.new(ORIGIN_X, 8, 472), Vector3.new(92, 16, 52), COLORS.HQ, Enum.Material.Concrete)
	blockerPart(hq, "HQLevel2", Vector3.new(ORIGIN_X, 22, 477), Vector3.new(78, 12, 42), Color3.fromRGB(59, 91, 139), Enum.Material.Concrete)
	blockerPart(hq, "HQLevel3Crown", Vector3.new(ORIGIN_X, 34, 482), Vector3.new(62, 12, 30), Color3.fromRGB(44, 72, 116), Enum.Material.Metal)
	part(hq, "HQGlassBand", Vector3.new(ORIGIN_X, 25, 455.7), Vector3.new(70, 5, 0.5), COLORS.Glass, Enum.Material.Glass, 0.35, false)
	label(hq, "HQLabel", Vector3.new(ORIGIN_X, 42, 455), "DESERT CUSTOMS HQ · TALLEST CROWN", COLORS.HQ)

	-- Protected public and staff routes are deliberately separate from cars.
	local publicWalk = routePart(routes, "FrontPublicWalk", Vector3.new(ORIGIN_X, 0.36, 2), Vector3.new(246, 0.12, 8), Color3.fromRGB(232, 224, 198))
	publicWalk.Material = Enum.Material.SmoothPlastic
	publicWalk:SetAttribute("RouteClass", "PUBLIC_PEDESTRIAN")
	local staffWalk = routePart(routes, "RearStaffSpine", Vector3.new(ORIGIN_X, 0.36, 397), Vector3.new(216, 0.12, 6), Color3.fromRGB(150, 220, 185))
	staffWalk.Material = Enum.Material.SmoothPlastic
	staffWalk:SetAttribute("RouteClass", "STAFF_ONLY")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = SPAWN_NAME
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(ORIGIN_X, 1, ROAD_Z - 18) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.CanTouch = true
	spawn.CanQuery = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn:SetAttribute("EnvironmentRoot", ROOT_NAME)
	spawn:SetAttribute("FacesDealership", true)
	spawn.Parent = Workspace

	local envelopeCount, socketCount, conflictCount = validate(root)
	root:SetAttribute("ProtectedEnvelopeCount", envelopeCount)
	root:SetAttribute("CapacitySocketCount", socketCount)
	root:SetAttribute("StaticEnvelopeConflicts", conflictCount)
	root:SetAttribute("HiddenPreviousPartCount", hiddenParts)
	root:SetAttribute("StaticValidationStatus", if conflictCount == 0 then "PASS" else "FAIL")
	root:SetAttribute("DynamicValidationStatus", "AWAITING_PLAY_TEST")

	review:SetAttribute("CanonicalViews", "ROAD_PLAYER_AERIAL_PRODUCTION_REAR_HERO_NEIGHBOUR")
	review:SetAttribute("StaticEnvelopeCount", envelopeCount)
	review:SetAttribute("CapacitySocketCount", socketCount)
	review:SetAttribute("StaticConflictCount", conflictCount)
	review:SetAttribute("ExpectedProductionBaySockets", 14)
	review:SetAttribute("ExpectedSalesDisplays", 6)
	review:SetAttribute("ExpectedOwnerCars", 6)
	review:SetAttribute("ExpectedCollectorSnapshots", 6)
	review:SetAttribute("ExpectedIntakePositions", 3)
	review:SetAttribute("GreyboxLimitation", "NO_DYNAMIC_TRAFFIC_OR_DETAILED_EQUIPMENT_YET")

	return {
		Root = root:GetFullName(),
		Version = Installer.Version,
		HiddenPreviousParts = hiddenParts,
		ProtectedEnvelopes = envelopeCount,
		CapacitySockets = socketCount,
		StaticConflicts = conflictCount,
		Status = root:GetAttribute("StaticValidationStatus"),
	}
end

function Installer.RestorePrevious()
	restorePrevious()
end

function Installer.Uninstall(restoreOlder: boolean?)
	local root = Workspace:FindFirstChild(ROOT_NAME)
	if root then root:Destroy() end
	local spawn = Workspace:FindFirstChild(SPAWN_NAME)
	if spawn then spawn:Destroy() end
	if restoreOlder ~= false then restorePrevious() end
end

-- F04: legacy whole-layer rebuilds cannot erase an integrated frontage.
for _,method in {"Install","Uninstall","RestorePrevious"} do
 local legacy=Installer[method]
 Installer[method]=function(...)
  local current=workspace:FindFirstChild("SellCars_Dealership_Growth_V5")
  assert(not(current and current:GetAttribute("Frontage04Activated")),"Frontage04 active: use scoped integration rollback before a legacy rebuild")
  return legacy(...)
 end
end
return Installer

