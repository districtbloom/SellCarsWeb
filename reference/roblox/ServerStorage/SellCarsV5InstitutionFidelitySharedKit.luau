--!strict

-- Sell Cars V5 — Institution Fidelity R1 shared construction kit.
-- These are modeller-readable parametric assemblies, not final meshes.

local Kit = {}
Kit.Version = "2026-09-03.v5-institution-fidelity-shared-kit.1"

Kit.Colors = {
	DeepNavy = Color3.fromRGB(13, 23, 35),
	Navy = Color3.fromRGB(24, 39, 56),
	Charcoal = Color3.fromRGB(39, 43, 46),
	Steel = Color3.fromRGB(75, 83, 87),
	Galvanized = Color3.fromRGB(145, 154, 156),
	Stainless = Color3.fromRGB(194, 203, 202),
	CleanPanel = Color3.fromRGB(220, 225, 219),
	WarmWhite = Color3.fromRGB(238, 229, 207),
	Brick = Color3.fromRGB(126, 62, 44),
	Concrete = Color3.fromRGB(133, 130, 119),
	OldConcrete = Color3.fromRGB(105, 104, 96),
	Rubber = Color3.fromRGB(24, 26, 27),
	Timber = Color3.fromRGB(145, 99, 57),
	Bronze = Color3.fromRGB(145, 100, 45),
	Gold = Color3.fromRGB(220, 172, 49),
	Red = Color3.fromRGB(188, 50, 42),
	Amber = Color3.fromRGB(227, 135, 42),
	Green = Color3.fromRGB(60, 164, 102),
	Cyan = Color3.fromRGB(53, 178, 188),
	Glass = Color3.fromRGB(105, 174, 190),
}

Kit.MaterialFamilies = {
	YardLegacy = {
		SurfaceFamily = "YARD_LEGACY",
		PhaseMin = "BIRTH",
		InheritanceRule = "LEGACY",
	},
	Workshop = {
		SurfaceFamily = "WORKSHOP",
		PhaseMin = "WORKING",
		InheritanceRule = "UPGRADE",
	},
	CleanProcess = {
		SurfaceFamily = "CLEAN_PROCESS",
		PhaseMin = "DEDICATED",
		InheritanceRule = "UPGRADE",
	},
	Commercial = {
		SurfaceFamily = "COMMERCIAL",
		PhaseMin = "WORKING",
		InheritanceRule = "UPGRADE",
	},
	Prestige = {
		SurfaceFamily = "PRESTIGE",
		PhaseMin = "PROFESSIONAL",
		InheritanceRule = "UPGRADE",
	},
}

local C = Kit.Colors

local function assembly(
	parent: Instance,
	name: string,
	bundleId: string,
	role: string,
	phaseMin: string,
	inheritance: string,
	collisionClass: string,
	interactionAnchor: string?,
	fxSocket: string?
): Model
	local result = Instance.new("Model")
	result.Name = name
	result:SetAttribute("V5FidelitySharedKit", true)
	result:SetAttribute("BundleId", bundleId)
	result:SetAttribute("FunctionId", "SHARED")
	result:SetAttribute("ZoneId", "SHARED_KIT")
	result:SetAttribute("FidelityRole", role)
	result:SetAttribute("PhaseMin", phaseMin)
	result:SetAttribute("InheritanceRule", inheritance)
	result:SetAttribute("AssetStatus", "PROXY")
	result:SetAttribute("CollisionClass", collisionClass)
	result:SetAttribute("InteractionAnchor", interactionAnchor or "")
	result:SetAttribute("FXSocket", fxSocket or "")
	result:SetAttribute("SourceGeometry", "PARAMETRIC_PROXY")
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
	collide: boolean?,
	transparency: number?,
	shadow: boolean?
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Anchored = true
	result.Size = size
	result.CFrame = cframe
	result.Color = color
	result.Material = material or Enum.Material.Metal
	result.Transparency = transparency or 0
	result.CanCollide = collide == true
	result.CanTouch = false
	result.CanQuery = collide == true
	result.CastShadow = if shadow == nil then result.Transparency < 0.45 else shadow
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result:SetAttribute("V5FidelitySharedKitPart", true)
	result:SetAttribute("CollisionClass", if collide then "STRUCTURE_OR_EQUIPMENT" else "NONE")
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
	collide: boolean?,
	transparency: number?
): Part
	return part(parent, name, size, CFrame.new(position), color, material, collide, transparency)
end

local function localPart(
	parent: Instance,
	name: string,
	origin: CFrame,
	offset: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?
): Part
	return part(parent, name, size, origin * CFrame.new(offset), color, material, collide, transparency)
end

local function orientedPart(
	parent: Instance,
	name: string,
	origin: CFrame,
	offset: Vector3,
	size: Vector3,
	rotation: Vector3,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?
): Part
	local cf = origin * CFrame.new(offset) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	return part(parent, name, size, cf, color, material, collide, transparency)
end

local function cylinder(
	parent: Instance,
	name: string,
	origin: CFrame,
	offset: Vector3,
	size: Vector3,
	rotation: Vector3,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?
): Part
	local result = orientedPart(parent, name, origin, offset, size, rotation, color, material, collide)
	result.Shape = Enum.PartType.Cylinder
	return result
end

local function cylinderBetween(parent: Instance, name: string, a: Vector3, b: Vector3, diameter: number, color: Color3, material: Enum.Material?): Part
	local delta = b - a
	local midpoint = (a + b) * 0.5
	local cf = CFrame.lookAt(midpoint, b) * CFrame.Angles(0, math.rad(90), 0)
	local result = part(parent, name, Vector3.new(delta.Magnitude, diameter, diameter), cf, color, material, false)
	result.Shape = Enum.PartType.Cylinder
	result.CastShadow = false
	return result
end

local function bolt(parent: Instance, name: string, origin: CFrame, offset: Vector3)
	local item = cylinder(parent, name, origin, offset, Vector3.new(0.18, 0.28, 0.28), Vector3.new(0, 0, 90), C.Galvanized, Enum.Material.Metal, false)
	item.CastShadow = false
end

local function anchor(parent: Instance, name: string, origin: CFrame, offset: Vector3, kind: string): Part
	local result = localPart(parent, name, origin, offset, Vector3.new(2.8, 0.08, 2.8), C.Green, Enum.Material.SmoothPlastic, false, 1)
	result:SetAttribute("InteractionAnchor", true)
	result:SetAttribute("AnchorKind", kind)
	result.CanQuery = false
	result.CastShadow = false
	return result
end

function Kit.CreateStructuralPortal(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local portal = assembly(parent, "Structural_Portal", bundleId or "Institution.SharedKit.Architecture.StructuralPortal.R1", "ARCHITECTURE", "WORKING", "UPGRADE", "STRUCTURE")
	for _, x in ipairs({-8.5, 8.5}) do
		localPart(portal, "ColumnWeb", origin, Vector3.new(x, 6.1, 0), Vector3.new(0.42, 11.7, 1.55), C.Charcoal, Enum.Material.Metal, true)
		localPart(portal, "ColumnFrontFlange", origin, Vector3.new(x, 6.1, -0.9), Vector3.new(1.7, 11.7, 0.26), C.Navy, Enum.Material.Metal, true)
		localPart(portal, "ColumnRearFlange", origin, Vector3.new(x, 6.1, 0.9), Vector3.new(1.7, 11.7, 0.26), C.Navy, Enum.Material.Metal, true)
		localPart(portal, "BasePlate", origin, Vector3.new(x, 0.18, 0), Vector3.new(2.4, 0.28, 2.4), C.Steel, Enum.Material.DiamondPlate, true)
		for _, dx in ipairs({-0.78, 0.78}) do
			for _, dz in ipairs({-0.78, 0.78}) do bolt(portal, "AnchorBolt", origin, Vector3.new(x + dx, 0.42, dz)) end
		end
	end
	localPart(portal, "HeaderWeb", origin, Vector3.new(0, 12.05, 0), Vector3.new(18.7, 0.48, 1.55), C.Charcoal, Enum.Material.Metal, true)
	localPart(portal, "HeaderFrontFlange", origin, Vector3.new(0, 12.05, -0.9), Vector3.new(18.7, 0.28, 2.0), C.Navy, Enum.Material.Metal, true)
	localPart(portal, "HeaderRearFlange", origin, Vector3.new(0, 12.05, 0.9), Vector3.new(18.7, 0.28, 2.0), C.Navy, Enum.Material.Metal, true)
	localPart(portal, "IdentityStrip", origin, Vector3.new(0, 11.65, -1.08), Vector3.new(16.5, 0.22, 0.12), accent, Enum.Material.Metal, false)
	for _, x in ipairs({-7.6, 7.6}) do
		orientedPart(portal, "CornerBrace", origin, Vector3.new(x, 10.65, 0), Vector3.new(0.24, 3.0, 0.62), Vector3.new(0, 0, if x < 0 then -42 else 42), C.Steel, Enum.Material.Metal, false)
	end
	portal:SetAttribute("ClearOpeningWidth", 15.2)
	portal:SetAttribute("ClearOpeningHeight", 11.45)
	return portal
end

function Kit.CreateWallAndRoofBay(parent: Instance, origin: CFrame, family: string, accent: Color3, bundleId: string?): Model
	local wall = assembly(parent, "Wall_And_Roof_Bay", bundleId or "Institution.SharedKit.Architecture.WallRoofBay.R1", "ARCHITECTURE", "WORKING", "UPGRADE", "STRUCTURE")
	local familyKey = family
	local upperColor = if familyKey == "CLEAN_PROCESS" then C.CleanPanel elseif familyKey == "COMMERCIAL" then C.WarmWhite elseif familyKey == "PRESTIGE" then C.DeepNavy else C.Galvanized
	local upperMaterial = if familyKey == "COMMERCIAL" then Enum.Material.SmoothPlastic else Enum.Material.Metal
	for _, x in ipairs({-6, 0, 6}) do
		localPart(wall, "MasonryBase", origin, Vector3.new(x, 1.25, 0), Vector3.new(5.8, 2.5, 0.7), if familyKey == "PRESTIGE" then C.OldConcrete else C.Brick, if familyKey == "PRESTIGE" then Enum.Material.Concrete else Enum.Material.Brick, true)
		localPart(wall, "UpperPanel", origin, Vector3.new(x, 5.35, 0), Vector3.new(5.8, 5.7, 0.42), upperColor, upperMaterial, true)
	end
	for _, x in ipairs({-9, -3, 3, 9}) do
		localPart(wall, "PanelPost", origin, Vector3.new(x, 5.4, -0.38), Vector3.new(0.3, 8.3, 0.55), C.Charcoal, Enum.Material.Metal, true)
	end
	for x = -8, 8, 2 do
		localPart(wall, "PanelRib", origin, Vector3.new(x, 5.35, -0.3), Vector3.new(0.12, 5.4, 0.12), C.Steel, Enum.Material.Metal, false)
	end
	localPart(wall, "ClerestoryGlass", origin, Vector3.new(0, 9.15, -0.1), Vector3.new(17.5, 1.55, 0.28), C.Glass, Enum.Material.Glass, false, 0.28)
	localPart(wall, "ClerestoryTopRail", origin, Vector3.new(0, 10.0, -0.1), Vector3.new(18.2, 0.25, 0.5), C.Charcoal, Enum.Material.Metal, true)
	localPart(wall, "RoofDeck", origin, Vector3.new(0, 10.5, -2.3), Vector3.new(19.2, 0.45, 5.2), C.Navy, Enum.Material.Metal, true)
	localPart(wall, "Fascia", origin, Vector3.new(0, 10.35, -4.85), Vector3.new(19.6, 0.9, 0.28), C.DeepNavy, Enum.Material.Metal, false)
	local gutter = cylinder(wall, "Gutter", origin, Vector3.new(0, 9.86, -5.02), Vector3.new(18.7, 0.38, 0.38), Vector3.new(0, 0, 0), C.Galvanized, Enum.Material.Metal, false)
	gutter.CastShadow = false
	cylinder(wall, "Downpipe", origin, Vector3.new(8.7, 5.1, -5.02), Vector3.new(9.5, 0.42, 0.42), Vector3.new(0, 0, 90), C.Galvanized, Enum.Material.Metal, false)
	localPart(wall, "MaterialJoint", origin, Vector3.new(0, 2.65, -0.42), Vector3.new(18.2, 0.18, 0.14), accent, Enum.Material.Metal, false)
	wall:SetAttribute("SurfaceFamily", familyKey)
	return wall
end

function Kit.CreateControlStation(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local station = assembly(parent, "Control_Station", bundleId or "Institution.SharedKit.Equipment.ControlStation.R1", "UTILITY", "DEDICATED", "UPGRADE", "EQUIPMENT", "Operator_Stand", "Machine_Status_Socket")
	localPart(station, "CabinetBody", origin, Vector3.new(0, 3.2, 0), Vector3.new(4.8, 6.2, 2.6), C.Navy, Enum.Material.Metal, true)
	localPart(station, "RecessedDoor", origin, Vector3.new(0, 3.2, -1.34), Vector3.new(4.25, 5.55, 0.16), C.Charcoal, Enum.Material.Metal, false)
	for _, y in ipairs({1.15, 5.25}) do cylinder(station, "DoorHinge", origin, Vector3.new(-2.0, y, -1.48), Vector3.new(0.65, 0.22, 0.22), Vector3.new(0, 0, 90), C.Galvanized, Enum.Material.Metal, false) end
	localPart(station, "DoorHandle", origin, Vector3.new(1.65, 3.0, -1.56), Vector3.new(0.22, 1.25, 0.22), C.Stainless, Enum.Material.Metal, false)
	localPart(station, "ScreenBezel", origin, Vector3.new(-0.55, 4.35, -1.52), Vector3.new(2.25, 1.35, 0.18), C.Rubber, Enum.Material.SmoothPlastic, false)
	localPart(station, "Screen", origin, Vector3.new(-0.55, 4.35, -1.64), Vector3.new(1.75, 0.85, 0.08), accent, Enum.Material.Neon, false, 0.08)
	for index, data in ipairs({{C.Green, 3.1}, {C.Amber, 2.45}, {C.Red, 1.8}}) do
		cylinder(station, "ControlButton_" .. index, origin, Vector3.new(1.15, data[2] :: number, -1.66), Vector3.new(0.22, 0.42, 0.42), Vector3.new(0, 90, 0), data[1] :: Color3, Enum.Material.SmoothPlastic, false)
	end
	localPart(station, "EmergencyStopCollar", origin, Vector3.new(1.15, 4.4, -1.64), Vector3.new(0.85, 0.85, 0.14), C.Amber, Enum.Material.SmoothPlastic, false)
	cylinder(station, "EmergencyStop", origin, Vector3.new(1.15, 4.4, -1.82), Vector3.new(0.42, 0.65, 0.65), Vector3.new(0, 90, 0), C.Red, Enum.Material.SmoothPlastic, false)
	localPart(station, "BeaconMast", origin, Vector3.new(0, 6.75, 0), Vector3.new(0.35, 0.9, 0.35), C.Charcoal, Enum.Material.Metal, false)
	for index, color in ipairs({C.Green, C.Amber, C.Red}) do cylinder(station, "StatusBeacon_" .. index, origin, Vector3.new(0, 7.15 + (index - 1) * 0.38, 0), Vector3.new(0.3, 0.48, 0.48), Vector3.new(0, 0, 90), color, Enum.Material.Neon, false) end
	localPart(station, "FloorConduit", origin, Vector3.new(-1.8, 0.65, 0.65), Vector3.new(0.35, 1.3, 0.35), C.Galvanized, Enum.Material.Metal, false)
	localPart(station, "ServiceConduit", origin, Vector3.new(-1.8, 0.18, -1.4), Vector3.new(0.35, 0.35, 4.0), C.Galvanized, Enum.Material.Metal, false)
	anchor(station, "Operator_Stand", origin, Vector3.new(0, 0.05, -4.0), "OPERATOR")
	local socket = Instance.new("Attachment")
	socket.Name = "Machine_Status_Socket"
	socket.Position = Vector3.new(0, 0, 0)
	socket:SetAttribute("FXSocket", true)
	socket.Parent = station.BeaconMast
	return station
end

function Kit.CreateHoseReel(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local reel = assembly(parent, "Hose_Air_Reel", bundleId or "Institution.SharedKit.Utility.HoseAirReel.R1", "UTILITY", "WORKING", "UPGRADE", "NONE", "Hose_Holster", "Utility_Active_Socket")
	localPart(reel, "WallMount", origin, Vector3.new(0, 6.2, 0.6), Vector3.new(4.4, 4.4, 0.5), C.Charcoal, Enum.Material.DiamondPlate, false)
	localPart(reel, "MountArm", origin, Vector3.new(0, 6.2, -0.4), Vector3.new(0.65, 0.65, 2.2), C.Steel, Enum.Material.Metal, false)
	for _, z in ipairs({-1.4, -2.0}) do cylinder(reel, "ReelDisc", origin, Vector3.new(0, 6.2, z), Vector3.new(0.28, 4.2, 4.2), Vector3.new(0, 90, 0), C.Navy, Enum.Material.Metal, false) end
	cylinder(reel, "ReelHub", origin, Vector3.new(0, 6.2, -1.7), Vector3.new(0.9, 1.25, 1.25), Vector3.new(0, 90, 0), accent, Enum.Material.Metal, false)
	for angle = 0, 135, 45 do
		orientedPart(reel, "ReelSpoke", origin, Vector3.new(0, 6.2, -2.17), Vector3.new(0.22, 3.3, 0.18), Vector3.new(0, 0, angle), C.Galvanized, Enum.Material.Metal, false)
	end
	local points = {
		(origin * CFrame.new(0, 4.5, -2.2)).Position,
		(origin * CFrame.new(0.7, 3.0, -2.4)).Position,
		(origin * CFrame.new(0.2, 1.6, -2.6)).Position,
		(origin * CFrame.new(1.0, 0.8, -2.8)).Position,
	}
	for index = 1, #points - 1 do cylinderBetween(reel, "HoseSegment_" .. index, points[index], points[index + 1], 0.24, C.Rubber, Enum.Material.SmoothPlastic) end
	cylinder(reel, "QuickConnector", origin, Vector3.new(1.0, 0.75, -3.05), Vector3.new(0.55, 0.38, 0.38), Vector3.new(0, 90, 0), accent, Enum.Material.Metal, false)
	localPart(reel, "NozzleGrip", origin, Vector3.new(1.0, 0.55, -3.45), Vector3.new(0.42, 0.8, 0.42), C.Charcoal, Enum.Material.SmoothPlastic, false)
	anchor(reel, "Hose_Holster", origin, Vector3.new(1.0, 0.04, -3.4), "UTILITY_ACCESS")
	return reel
end

function Kit.CreateToolCart(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local cart = assembly(parent, "Mobile_Tool_Cart", bundleId or "Institution.SharedKit.Support.MobileToolCart.R1", "SUPPORT", "BIRTH", "UPGRADE", "EQUIPMENT", "Cart_Workside")
	localPart(cart, "CartBody", origin, Vector3.new(0, 2.5, 0), Vector3.new(6.0, 4.4, 3.2), C.Charcoal, Enum.Material.Metal, true)
	localPart(cart, "Worktop", origin, Vector3.new(0, 4.85, 0), Vector3.new(6.4, 0.35, 3.55), C.Rubber, Enum.Material.SmoothPlastic, false)
	for index = 1, 5 do
		localPart(cart, "DrawerFace_" .. index, origin, Vector3.new(0, 1.0 + index * 0.63, -1.65), Vector3.new(5.4, 0.5, 0.14), if index == 1 then accent else C.Navy, Enum.Material.Metal, false)
		localPart(cart, "DrawerPull_" .. index, origin, Vector3.new(0, 1.0 + index * 0.63, -1.78), Vector3.new(2.2, 0.12, 0.16), C.Stainless, Enum.Material.Metal, false)
	end
	localPart(cart, "PushHandle", origin, Vector3.new(3.55, 4.0, 0), Vector3.new(1.0, 0.35, 3.0), C.Stainless, Enum.Material.Metal, false)
	for _, x in ipairs({-2.4, 2.4}) do
		for _, z in ipairs({-1.1, 1.1}) do
			localPart(cart, "CasterFork", origin, Vector3.new(x, 0.58, z), Vector3.new(0.32, 0.85, 0.32), C.Galvanized, Enum.Material.Metal, false)
			cylinder(cart, "CasterWheel", origin, Vector3.new(x, 0.3, z), Vector3.new(0.32, 0.85, 0.85), Vector3.new(0, 0, 0), C.Rubber, Enum.Material.SmoothPlastic, false)
		end
	end
	for _, x in ipairs({-2.75, 2.75}) do localPart(cart, "CornerBumper", origin, Vector3.new(x, 2.2, 1.7), Vector3.new(0.38, 2.2, 0.38), C.Rubber, Enum.Material.SmoothPlastic, false) end
	anchor(cart, "Cart_Workside", origin, Vector3.new(0, 0.04, -3.5), "MOBILE_WORKSIDE")
	return cart
end

function Kit.CreateStorageRack(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local rack = assembly(parent, "Parts_Storage_Rack", bundleId or "Institution.SharedKit.Support.StorageRack.R1", "SUPPORT", "WORKING", "UPGRADE", "EQUIPMENT", "Picking_Side")
	for _, x in ipairs({-4.6, 4.6}) do
		for _, z in ipairs({-1.25, 1.25}) do localPart(rack, "RackPost", origin, Vector3.new(x, 4.2, z), Vector3.new(0.35, 8.4, 0.35), C.Charcoal, Enum.Material.Metal, true) end
	end
	for level = 0, 3 do
		local y = 0.55 + level * 2.35
		localPart(rack, "ShelfBeamFront", origin, Vector3.new(0, y, -1.35), Vector3.new(9.5, 0.35, 0.35), accent, Enum.Material.Metal, true)
		localPart(rack, "ShelfBeamRear", origin, Vector3.new(0, y, 1.35), Vector3.new(9.5, 0.35, 0.35), C.Steel, Enum.Material.Metal, true)
		localPart(rack, "ShelfDeck", origin, Vector3.new(0, y + 0.16, 0), Vector3.new(9.2, 0.18, 2.6), C.Galvanized, Enum.Material.Metal, false)
		if level < 3 then
			for slot = -2, 2 do
				local binColor = if (slot + level) % 3 == 0 then accent elseif (slot + level) % 3 == 1 then C.Navy else C.OldConcrete
				localPart(rack, "InventoryBin", origin, Vector3.new(slot * 1.7, y + 0.8, -0.05), Vector3.new(1.45, 1.25, 2.15), binColor, Enum.Material.SmoothPlastic, false)
			end
		end
	end
	anchor(rack, "Picking_Side", origin, Vector3.new(0, 0.04, -3.6), "PICKING")
	return rack
end

function Kit.CreateSafetyStation(parent: Instance, origin: CFrame, accent: Color3, bundleId: string?): Model
	local safety = assembly(parent, "Safety_Station", bundleId or "Institution.SharedKit.Safety.ResponseStation.R1", "UTILITY", "WORKING", "PERSIST", "NONE", "Safety_Access")
	localPart(safety, "Backplate", origin, Vector3.new(0, 4.2, 0), Vector3.new(7.2, 7.4, 0.35), C.WarmWhite, Enum.Material.Metal, false)
	localPart(safety, "HeaderBand", origin, Vector3.new(0, 7.4, -0.25), Vector3.new(6.6, 0.7, 0.18), accent, Enum.Material.Metal, false)
	localPart(safety, "PPECabinet", origin, Vector3.new(1.8, 4.35, -0.55), Vector3.new(2.7, 3.8, 0.95), C.Navy, Enum.Material.Metal, false)
	localPart(safety, "PPEWindow", origin, Vector3.new(1.8, 4.5, -1.05), Vector3.new(2.1, 2.4, 0.08), C.Glass, Enum.Material.Glass, false, 0.2)
	cylinder(safety, "ExtinguisherBody", origin, Vector3.new(-1.9, 3.2, -0.75), Vector3.new(3.5, 1.45, 1.45), Vector3.new(0, 0, 90), C.Red, Enum.Material.Metal, false)
	cylinder(safety, "ExtinguisherCollar", origin, Vector3.new(-1.9, 5.05, -0.75), Vector3.new(0.4, 1.1, 1.1), Vector3.new(0, 0, 90), C.Charcoal, Enum.Material.Metal, false)
	localPart(safety, "ExtinguisherHandle", origin, Vector3.new(-1.3, 5.45, -0.75), Vector3.new(1.25, 0.22, 0.32), C.Charcoal, Enum.Material.Metal, false)
	localPart(safety, "ExtinguisherHose", origin, Vector3.new(-2.8, 3.9, -0.95), Vector3.new(0.22, 2.0, 0.22), C.Rubber, Enum.Material.SmoothPlastic, false)
	for x = -2.5, 2.5, 1.25 do localPart(safety, "LowerHazardMarker", origin, Vector3.new(x, 0.35, -0.5), Vector3.new(0.7, 0.18, 1.8), if math.floor(x * 2) % 2 == 0 then C.Amber else C.Charcoal, Enum.Material.SmoothPlastic, false) end
	anchor(safety, "Safety_Access", origin, Vector3.new(0, 0.04, -3.0), "SAFETY_ACCESS")
	return safety
end

function Kit.CreateServiceDrain(parent: Instance, origin: CFrame, bundleId: string?): Model
	local drain = assembly(parent, "Service_Drain", bundleId or "Institution.SharedKit.Architecture.ServiceDrain.R1", "UTILITY", "BIRTH", "UPGRADE", "NONE")
	localPart(drain, "Channel", origin, Vector3.new(0, 0.06, 0), Vector3.new(14, 0.1, 2.2), C.Rubber, Enum.Material.SmoothPlastic, false)
	for _, z in ipairs({-1.1, 1.1}) do localPart(drain, "DrainFrame", origin, Vector3.new(0, 0.12, z), Vector3.new(14.4, 0.18, 0.18), C.Stainless, Enum.Material.Metal, false) end
	for x = -6.5, 6.5, 1 do localPart(drain, "GrateSlat", origin, Vector3.new(x, 0.16, 0), Vector3.new(0.16, 0.14, 2.0), C.Galvanized, Enum.Material.Metal, false) end
	drain:SetAttribute("WheelSafe", true)
	return drain
end

function Kit.CreateMaterialFamilyWall(parent: Instance, origin: CFrame, bundleId: string?): Model
	local wall = assembly(parent, "Material_Family_Wall", bundleId or "Institution.SharedKit.Materials.FiveFamilies.R1", "STORY", "BIRTH", "UPGRADE", "STRUCTURE")
	local families = {
		{"YARD_LEGACY", C.Brick, Enum.Material.Brick, C.Galvanized, Enum.Material.CorrodedMetal, "BIRTH", "LEGACY"},
		{"WORKSHOP", C.OldConcrete, Enum.Material.Concrete, C.Navy, Enum.Material.Metal, "WORKING", "UPGRADE"},
		{"CLEAN_PROCESS", C.Concrete, Enum.Material.Concrete, C.CleanPanel, Enum.Material.Metal, "DEDICATED", "UPGRADE"},
		{"COMMERCIAL", C.Timber, Enum.Material.WoodPlanks, C.WarmWhite, Enum.Material.SmoothPlastic, "WORKING", "UPGRADE"},
		{"PRESTIGE", C.OldConcrete, Enum.Material.Slate, C.DeepNavy, Enum.Material.Metal, "PROFESSIONAL", "UPGRADE"},
	}
	for index, data in ipairs(families) do
		local x = (index - 3) * 18
		local sample = assembly(wall, data[1] :: string, "Institution.SharedKit.Materials." .. (data[1] :: string) .. ".R1", "STORY", data[6] :: string, data[7] :: string, "STRUCTURE")
		sample:SetAttribute("SurfaceFamily", data[1])
		localPart(sample, "Base", origin, Vector3.new(x, 1.5, 0), Vector3.new(17.4, 3.0, 0.75), data[2] :: Color3, data[3] :: Enum.Material, true)
		localPart(sample, "Upper", origin, Vector3.new(x, 6.2, 0), Vector3.new(17.4, 6.4, 0.45), data[4] :: Color3, data[5] :: Enum.Material, true)
		for rib = -3, 3 do localPart(sample, "ExpressedJoint", origin, Vector3.new(x + rib * 2.3, 6.2, -0.3), Vector3.new(0.12, 6.1, 0.12), C.Steel, Enum.Material.Metal, false) end
		local accentColor = if data[1] == "PRESTIGE" then C.Gold elseif data[1] == "CLEAN_PROCESS" then C.Cyan else C.Bronze
		localPart(sample, "FamilyAccent", origin, Vector3.new(x, 3.25, -0.42), Vector3.new(16.2, 0.22, 0.12), accentColor, Enum.Material.Metal, false)
	end
	return wall
end

function Kit.BuildProofRack(parent: Instance, originPosition: Vector3): Model
	local origin = CFrame.new(originPosition)
	local rack = assembly(parent, "01_Proof_Rack", "Institution.SharedKit.ProofRack.R1", "STORY", "INSTITUTION", "RETIRE", "NONE")
	rack:SetAttribute("ReviewOnly", true)
	rack:SetAttribute("RetireBeforePhase2Acceptance", true)
	localPart(rack, "ReviewSlab", origin, Vector3.new(0, 0.15, 0), Vector3.new(104, 0.3, 46), C.OldConcrete, Enum.Material.Concrete, false)
	localPart(rack, "RearServiceApron", origin, Vector3.new(0, 0.22, 12), Vector3.new(100, 0.16, 18), C.Concrete, Enum.Material.Pavement, false)
	Kit.CreateMaterialFamilyWall(rack, origin * CFrame.new(0, 0, 16), "Institution.SharedKit.Materials.ProofWall.R1")
	Kit.CreateStructuralPortal(rack, origin * CFrame.new(-38, 0, -3), C.Red, "Institution.SharedKit.Architecture.ProofPortal.R1")
	Kit.CreateControlStation(rack, origin * CFrame.new(-17, 0, -1), C.Cyan, "Institution.SharedKit.Equipment.ProofControl.R1")
	Kit.CreateHoseReel(rack, origin * CFrame.new(-7, 0, 14), C.Cyan, "Institution.SharedKit.Utility.ProofHose.R1")
	Kit.CreateToolCart(rack, origin * CFrame.new(7, 0, -1), C.Red, "Institution.SharedKit.Support.ProofCart.R1")
	Kit.CreateStorageRack(rack, origin * CFrame.new(24, 0, 11), C.Amber, "Institution.SharedKit.Support.ProofRack.R1")
	Kit.CreateSafetyStation(rack, origin * CFrame.new(43, 0, 12), C.Red, "Institution.SharedKit.Safety.ProofStation.R1")
	Kit.CreateServiceDrain(rack, origin * CFrame.new(6, 0, -11), "Institution.SharedKit.Architecture.ProofDrain.R1")
	return rack
end

function Kit.MarkModelerReady(root: Instance)
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("Model") and item:GetAttribute("V5FidelitySharedKit") then
			item:SetAttribute("AssetStatus", "MODELER_READY")
		end
	end
	if root:IsA("Model") and root:GetAttribute("V5FidelitySharedKit") then
		root:SetAttribute("AssetStatus", "MODELER_READY")
	end
end

return Kit

