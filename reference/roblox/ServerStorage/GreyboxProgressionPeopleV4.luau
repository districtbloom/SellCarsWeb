--!strict

-- Blockout-lock pass:
--   * four same-footprint architectural states;
--   * two flush visitor arrival positions;
--   * explicit customer/staff pedestrian paths;
--   * production-vehicle clearance references from Sell Cars CarModels;
--   * visible moving-person waypoint routes for Studio playtests.

local Module = {}

local COLORS = {
	structure = Color3.fromRGB(65, 75, 84),
	dark = Color3.fromRGB(34, 39, 44),
	junk = Color3.fromRGB(119, 91, 63),
	working = Color3.fromRGB(86, 137, 141),
	professional = Color3.fromRGB(69, 129, 169),
	institution = Color3.fromRGB(161, 100, 186),
	work = Color3.fromRGB(218, 126, 69),
	wash = Color3.fromRGB(49, 207, 187),
	visitor = Color3.fromRGB(250, 211, 88),
	premium = Color3.fromRGB(224, 112, 210),
	staff = Color3.fromRGB(255, 151, 73),
	pedestrian = Color3.fromRGB(238, 240, 229),
	glass = Color3.fromRGB(101, 200, 229),
	road = Color3.fromRGB(65, 71, 78),
	white = Color3.fromRGB(231, 235, 237),
	black = Color3.fromRGB(26, 29, 33),
}

local function model(parent: Instance, name: string, minStep: number?, role: string?): Model
	local result = Instance.new("Model")
	result.Name = name
	if minStep then result:SetAttribute("MinStep", minStep) end
	if role then result:SetAttribute("Role", role) end
	result:SetAttribute("BlockoutVersion", 4)
	result.Parent = parent
	return result
end

local function part(
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
	local result = Instance.new("Part")
	result.Name = name
	result.Anchored = true
	result.CanCollide = canCollide == true
	result.CanTouch = false
	result.Material = material or Enum.Material.SmoothPlastic
	result.Color = color
	result.Transparency = transparency or 0
	result.Size = size
	result.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result.Parent = parent
	return result
end

local function line(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3, transparency: number?): Part
	local delta = b - a
	local midpoint = (a + b) / 2
	return part(parent, name, midpoint, Vector3.new(width, 0.16, delta.Magnitude), color, transparency or 0.15, false, Enum.Material.Neon, math.deg(math.atan2(delta.X, delta.Z)))
end

local function posts(parent: Instance, center: Vector3, footprint: Vector2, height: number, color: Color3)
	for _, offset in {
		Vector3.new(-footprint.X / 2 + 1.5, 0, -footprint.Y / 2 + 1.5),
		Vector3.new(footprint.X / 2 - 1.5, 0, -footprint.Y / 2 + 1.5),
		Vector3.new(-footprint.X / 2 + 1.5, 0, footprint.Y / 2 - 1.5),
		Vector3.new(footprint.X / 2 - 1.5, 0, footprint.Y / 2 - 1.5),
	} do
		part(parent, "Post", center + offset + Vector3.new(0, height / 2, 0), Vector3.new(1, height, 1), color, 0.05, true, Enum.Material.Metal)
	end
end

local function canopy(parent: Instance, name: string, center: Vector3, footprint: Vector2, height: number, color: Color3)
	local result = model(parent, name, nil, "Open canopy")
	part(result, "Roof", center + Vector3.new(0, height, 0), Vector3.new(footprint.X, 0.8, footprint.Y), color, 0.18, true, Enum.Material.Metal)
	posts(result, center, footprint, height, color)
	return result
end

local function shell(parent: Instance, name: string, center: Vector3, footprint: Vector2, height: number, color: Color3, openEast: boolean?): Model
	local result = model(parent, name, nil, "Building shell")
	part(result, "Floor", center + Vector3.new(0, 0.8, 0), Vector3.new(footprint.X, 0.8, footprint.Y), color, 0.42, true, Enum.Material.Concrete)
	part(result, "BackWall", center + Vector3.new(0, 1.2 + height / 2, footprint.Y / 2), Vector3.new(footprint.X, height, 1), color, 0.18, true, Enum.Material.Concrete)
	part(result, "LeftWall", center + Vector3.new(-footprint.X / 2, 1.2 + height / 2, 0), Vector3.new(1, height, footprint.Y), color, 0.18, true, Enum.Material.Concrete)
	if not openEast then
		part(result, "RightWall", center + Vector3.new(footprint.X / 2, 1.2 + height / 2, 0), Vector3.new(1, height, footprint.Y), color, 0.18, true, Enum.Material.Concrete)
	end
	part(result, "FrontPierLeft", center + Vector3.new(-footprint.X / 2 + 1.5, 1.2 + height / 2, -footprint.Y / 2), Vector3.new(3, height, 3), color, 0.08, true, Enum.Material.Concrete)
	part(result, "FrontPierRight", center + Vector3.new(footprint.X / 2 - 1.5, 1.2 + height / 2, -footprint.Y / 2), Vector3.new(3, height, 3), color, 0.08, true, Enum.Material.Concrete)
	part(result, "Roof", center + Vector3.new(0, height + 1.6, 0), Vector3.new(footprint.X + 2, 0.8, footprint.Y + 2), color, 0.65, false, Enum.Material.Metal)
	return result
end

local function stage(parent: Instance, name: string, index: number, minStep: number, maxStep: number): Model
	local result = model(parent, name, minStep, "Architectural progression state")
	result:SetAttribute("StageIndex", index)
	result:SetAttribute("MinPreviewStep", minStep)
	result:SetAttribute("MaxPreviewStep", maxStep)
	result:SetAttribute("MaxStep", maxStep)
	return result
end

local function buildProgression(parent: Model)
	local variants = model(parent, "A_Architectural_Progression_States", 1, "Same-property transformation states")

	local junk = stage(variants, "Stage_1_Junk_Operation", 1, 1, 9)
	part(junk, "UnevenLotPatch", Vector3.new(0, 0.48, 92), Vector3.new(184, 0.16, 178), COLORS.junk, 0.55, false, Enum.Material.Ground)
	canopy(junk, "FirstRepairShade", Vector3.new(-82, 0.8, 132), Vector2.new(42, 46), 9, COLORS.junk)
	canopy(junk, "RoadsideSaleShade", Vector3.new(-15, 0.8, 38), Vector2.new(34, 28), 7, COLORS.junk)
	shell(junk, "StarterOwnerShed", Vector3.new(-87, 0, 34), Vector2.new(28, 48), 9, COLORS.junk, false)
	shell(junk, "MakeshiftDealCabin", Vector3.new(14, 0, 112), Vector2.new(24, 28), 8, COLORS.junk, false)
	for _, x in {-110, -65, -20, 25, 70, 110} do part(junk, "FenceFragment", Vector3.new(x, 3.2, 92), Vector3.new(18, 4, 0.4), COLORS.junk, 0.12, true, Enum.Material.CorrodedMetal) end

	local working = stage(variants, "Stage_2_Working_Dealership", 2, 10, 25)
	canopy(working, "CountyForecourtCanopy", Vector3.new(-15, 0.8, 42), Vector2.new(78, 66), 12, COLORS.working)
	canopy(working, "OrganizedIntakeCanopy", Vector3.new(89, 0.8, 48), Vector2.new(52, 78), 12, COLORS.working)
	shell(working, "TwoBayOwnerGarage", Vector3.new(-87, 0, 46), Vector2.new(58, 82), 14, COLORS.working, false)
	shell(working, "SmallSalesOffice", Vector3.new(14, 0, 120), Vector2.new(44, 52), 13, COLORS.working, false)
	shell(working, "WorkingWorkshop", Vector3.new(-82, 0, 184), Vector2.new(68, 152), 15, COLORS.work, true)
	canopy(working, "WashDetailShelter", Vector3.new(88, 0.8, 181), Vector2.new(50, 34), 13, COLORS.wash)
	shell(working, "BodyPaintWorkingWing", Vector3.new(88, 0, 255), Vector2.new(50, 104), 15, COLORS.working, true)

	local professional = stage(variants, "Stage_3_Professional_Campus", 3, 26, 33)
	shell(professional, "ProfessionalOwnerGarage", Vector3.new(-87, 0, 46), Vector2.new(58, 82), 18, COLORS.professional, false)
	canopy(professional, "PremiumFourCarForecourt", Vector3.new(-15, 0.8, 42), Vector2.new(78, 68), 17, COLORS.professional)
	shell(professional, "ProfessionalAppraisal", Vector3.new(89, 0, 48), Vector2.new(52, 80), 18, COLORS.professional, false)
	shell(professional, "SingleLevelOperationsOffice", Vector3.new(14, 0, 120), Vector2.new(46, 54), 18, COLORS.professional, false)
	shell(professional, "ProfessionalRestorationHall", Vector3.new(-82, 0, 210), Vector2.new(70, 204), 24, COLORS.work, true)
	shell(professional, "ProfessionalFinishAtelier", Vector3.new(88, 0, 237), Vector2.new(52, 146), 24, COLORS.wash, true)
	shell(professional, "ProfessionalWarehouse", Vector3.new(-52, 0, 335), Vector2.new(134, 42), 20, COLORS.professional, false)
	canopy(professional, "WorkingRevealCanopy", Vector3.new(12, 0.8, 196), Vector2.new(54, 38), 17, COLORS.professional)

	local institution = stage(variants, "Stage_4_Automotive_Institution", 4, 34, 36)
	institution:SetAttribute("UsesFinalBuildingBlockouts", true)
	institution:SetAttribute("Description", "Final V3 shells, two-level collector hall, owner mezzanine and reveal landmark")

	-- Edit mode stays on the clean final state. The local preview controller restores
	-- these authored values when stages 1-3 are selected in Play.
	for _, descendant in variants:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetAttribute("ProgressionBaseTransparency", descendant.Transparency)
			descendant:SetAttribute("ProgressionBaseCanCollide", descendant.CanCollide)
			descendant.Transparency = 1
			descendant.CanCollide = false
		end
	end
end

local function bayOutline(parent: Instance, name: string, center: Vector3, width: number, length: number, yaw: number, color: Color3): Model
	local result = model(parent, name, nil, "Flush vehicle bay")
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
	local edge = 0.35
	for _, info in {
		{Vector3.new(-width / 2, 0, 0), Vector3.new(edge, 0.15, length)},
		{Vector3.new(width / 2, 0, 0), Vector3.new(edge, 0.15, length)},
		{Vector3.new(0, 0, -length / 2), Vector3.new(width, 0.15, edge)},
		{Vector3.new(0, 0, length / 2), Vector3.new(width, 0.15, edge)},
	} do
		local offset = info[1] :: Vector3
		local size = info[2] :: Vector3
		local p = part(result, "PaintLine", (cf * CFrame.new(offset)).Position, size, color, 0.05, false, Enum.Material.Neon, yaw)
		p.CFrame = cf * CFrame.new(offset)
	end
	return result
end

local function carReference(parent: Instance, name: string, center: Vector3, size: Vector3, color: Color3, yaw: number, minStep: number): Model
	local result = model(parent, name, minStep, "Production-size vehicle reference")
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
	local body = part(result, "Body", center + Vector3.new(0, size.Y * 0.32, 0), Vector3.new(size.X, size.Y * 0.5, size.Z), color, 0.12, false, Enum.Material.SmoothPlastic, yaw)
	body.CFrame = cf * CFrame.new(0, size.Y * 0.32, 0)
	local cabin = part(result, "Cabin", center + Vector3.new(0, size.Y * 0.68, size.Z * 0.05), Vector3.new(size.X * 0.78, size.Y * 0.48, size.Z * 0.45), COLORS.glass, 0.28, false, Enum.Material.Glass, yaw)
	cabin.CFrame = cf * CFrame.new(0, size.Y * 0.68, size.Z * 0.05)
	return result
end

local function stripes(parent: Instance, name: string, center: Vector3, span: number, yaw: number, color: Color3): Model
	local result = model(parent, name, nil, "Flush protected crossing")
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
	for index = -4, 4 do
		local stripe = part(result, "Stripe", center, Vector3.new(1.1, 0.12, span), color, 0.08, false, Enum.Material.Neon, yaw)
		stripe.CFrame = cf * CFrame.new(index * 1.8, 0, 0)
	end
	return result
end

local function buildArrivalsAndPaths(parent: Model)
	local arrival = model(parent, "B_Customer_Arrival_and_Pedestrian_Network", 8, "Two visitor positions without a parking lot")
	arrival:SetAttribute("RaisedCurbs", false)
	arrival:SetAttribute("CustomerPositions", 2)
	arrival:SetAttribute("StandardPosition", "Short-stay visitor bay")
	arrival:SetAttribute("PremiumPosition", "Appointment and exceptional-car drop-off")

	-- Flush overlays: no curb, ramp or low-car special casing.
	part(arrival, "CustomerAccessSpur", Vector3.new(32, 1.34, 39), Vector3.new(14, 0.14, 102), COLORS.road, 0.16, false, Enum.Material.Asphalt)
	line(arrival, "CustomerLaneCenter", Vector3.new(32, 1.46, -12), Vector3.new(32, 1.46, 90), 0.35, COLORS.visitor, 0.05)
	local regular = bayOutline(arrival, "StandardVisitorBay", Vector3.new(47, 1.46, 45), 13, 22, 90, COLORS.visitor)
	regular:SetAttribute("MinStep", 8)
	local premium = bayOutline(arrival, "PremiumAppointmentPocket", Vector3.new(32, 1.46, 83), 13, 22, 0, COLORS.premium)
	premium:SetAttribute("MinStep", 29)
	carReference(arrival, "StandardVisitorCar", Vector3.new(47, 1.5, 45), Vector3.new(8.45, 6.39, 15.68), Color3.fromRGB(67, 125, 174), 90, 8)
	carReference(arrival, "PremiumVisitorCar", Vector3.new(32, 1.5, 83), Vector3.new(8.17, 4.93, 15.87), Color3.fromRGB(178, 74, 123), 0, 29)

	part(arrival, "CustomerWalkway", Vector3.new(18, 1.45, 47), Vector3.new(6, 0.16, 94), COLORS.pedestrian, 0.16, false, Enum.Material.Concrete)
	line(arrival, "OfficeWalkConnector", Vector3.new(18, 1.48, 91), Vector3.new(14, 1.48, 98), 5, COLORS.pedestrian, 0.18)
	stripes(arrival, "StandardVisitorCrossing", Vector3.new(31, 1.5, 45), 6, 90, COLORS.pedestrian)
	stripes(arrival, "PremiumVisitorCrossing", Vector3.new(25, 1.5, 83), 6, 90, COLORS.pedestrian)

	-- The central staff spine is protected inside the courtyard; only two lane crossings are used.
	part(arrival, "CentralStaffSpine", Vector3.new(29, 1.47, 203), Vector3.new(6, 0.16, 114), COLORS.staff, 0.25, false, Enum.Material.Concrete)
	line(arrival, "OfficeStaffConnector", Vector3.new(14, 1.5, 144), Vector3.new(29, 1.5, 151), 5, COLORS.staff, 0.2)
	line(arrival, "MechanicalStaffConnector", Vector3.new(29, 1.5, 260), Vector3.new(-55, 1.5, 260), 5, COLORS.staff, 0.2)
	line(arrival, "FinishStaffConnector", Vector3.new(29, 1.5, 260), Vector3.new(66, 1.5, 260), 5, COLORS.staff, 0.2)
	stripes(arrival, "WestVehicleLaneCrossing", Vector3.new(-34, 1.52, 260), 6, 0, COLORS.pedestrian)
	stripes(arrival, "EastVehicleLaneCrossing", Vector3.new(49, 1.52, 260), 6, 0, COLORS.pedestrian)
	part(arrival, "WorkshopStaffWalk", Vector3.new(-57, 1.48, 227), Vector3.new(5, 0.16, 66), COLORS.staff, 0.24, false, Enum.Material.Concrete)
	part(arrival, "FinishStaffWalk", Vector3.new(66, 1.48, 256), Vector3.new(5, 0.16, 102), COLORS.staff, 0.24, false, Enum.Material.Concrete)
end

local function actor(parent: Instance, name: string, position: Vector3, color: Color3, minStep: number): Model
	local result = model(parent, name, minStep, "Moving pedestrian proof")
	local body = part(result, "Body", position + Vector3.new(0, 3.1, 0), Vector3.new(2.2, 3.2, 1.2), color, 0, false, Enum.Material.SmoothPlastic)
	part(result, "Head", position + Vector3.new(0, 5.5, 0), Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(210, 168, 124), 0, false, Enum.Material.SmoothPlastic)
	part(result, "LegL", position + Vector3.new(-0.55, 1.2, 0), Vector3.new(0.75, 2.2, 0.75), COLORS.dark, 0, false, Enum.Material.SmoothPlastic)
	part(result, "LegR", position + Vector3.new(0.55, 1.2, 0), Vector3.new(0.75, 2.2, 0.75), COLORS.dark, 0, false, Enum.Material.SmoothPlastic)
	result.PrimaryPart = body
	return result
end

local function movementRoute(parent: Instance, name: string, points: {{p: Vector3, hold: number?}}, color: Color3, minStep: number): Model
	local result = model(parent, name, minStep, "Animated pedestrian route")
	result:SetAttribute("RouteMinStep", minStep)
	for index = 1, #points - 1 do line(result, string.format("Segment_%02d", index), points[index].p, points[index + 1].p, 0.45, color, 0.22) end
	local waypoints = Instance.new("Folder")
	waypoints.Name = "DemoWaypoints"
	waypoints.Parent = result
	for index, info in points do
		local node = part(waypoints, string.format("WP_%02d", index), info.p, Vector3.new(0.5, 0.5, 0.5), color, 1, false, Enum.Material.SmoothPlastic)
		node:SetAttribute("Order", index)
		node:SetAttribute("HoldSeconds", info.hold or 0)
	end
	return result
end

local function buildPeople(parent: Model)
	local people = model(parent, "C_Visible_People_Movement", 8, "Customer, collector and staff circulation proofs")
	local routes = model(people, "Routes", 8, "Pedestrian waypoint routes")
	local actors = model(people, "Actors", 8, "Moving people proxies")

	local buyerPoints = {
		{p = Vector3.new(47, 3.3, 45), hold = 1},
		{p = Vector3.new(38, 3.3, 45)},
		{p = Vector3.new(18, 3.3, 45), hold = 0.7},
		{p = Vector3.new(18, 3.3, 88)},
		{p = Vector3.new(14, 3.3, 98)},
		{p = Vector3.new(14, 3.3, 111), hold = 3},
	}
	movementRoute(routes, "Standard_Buyer_to_Office", buyerPoints, COLORS.visitor, 8)
	actor(actors, "MovingStandardBuyer", buyerPoints[1].p - Vector3.new(0, 3.3, 0), COLORS.visitor, 8)

	local collectorPoints = {
		{p = Vector3.new(32, 3.3, 83), hold = 1},
		{p = Vector3.new(18, 3.3, 83)},
		{p = Vector3.new(18, 3.3, 90)},
		{p = Vector3.new(-12, 3.3, 90)},
		{p = Vector3.new(-12, 3.3, 111)},
	}
	for index = 1, 14 do table.insert(collectorPoints, {p = Vector3.new(-12, 3.3 + index, 111 + (index - 1) * 1.7)}) end
	table.insert(collectorPoints, {p = Vector3.new(-12, 17.7, 137), hold = 0.5})
	table.insert(collectorPoints, {p = Vector3.new(-12, 17.7, 116)})
	table.insert(collectorPoints, {p = Vector3.new(-5, 17.7, 116)})
	table.insert(collectorPoints, {p = Vector3.new(10, 17.7, 116), hold = 4})
	movementRoute(routes, "Collector_to_Upper_Lounge", collectorPoints, COLORS.premium, 34)
	actor(actors, "MovingCollectorGuest", collectorPoints[1].p - Vector3.new(0, 3.3, 0), COLORS.premium, 34)

	local staffPoints = {
		{p = Vector3.new(14, 3.3, 111), hold = 1},
		{p = Vector3.new(14, 3.3, 91)},
		{p = Vector3.new(40, 3.3, 91)},
		{p = Vector3.new(40, 3.3, 151)},
		{p = Vector3.new(29, 3.3, 151)},
		{p = Vector3.new(29, 3.3, 260), hold = 0.8},
		{p = Vector3.new(-20, 3.3, 260), hold = 0.6},
		{p = Vector3.new(-48, 3.3, 260)},
		{p = Vector3.new(-57, 3.3, 260), hold = 2},
		{p = Vector3.new(29, 3.3, 260), hold = 0.8},
		{p = Vector3.new(42, 3.3, 260), hold = 0.6},
		{p = Vector3.new(61, 3.3, 260)},
		{p = Vector3.new(66, 3.3, 260), hold = 2},
		{p = Vector3.new(29, 3.3, 260)},
		{p = Vector3.new(29, 3.3, 151)},
		{p = Vector3.new(40, 3.3, 151)},
		{p = Vector3.new(40, 3.3, 91)},
		{p = Vector3.new(14, 3.3, 91)},
		{p = Vector3.new(14, 3.3, 111), hold = 2},
	}
	movementRoute(routes, "Operations_Staff_Campus_Loop", staffPoints, COLORS.staff, 10)
	actor(actors, "MovingOperationsRunner", staffPoints[1].p - Vector3.new(0, 3.3, 0), COLORS.staff, 10)
end

local function buildProductionReferences(parent: Model, root: Model)
	local refs = model(parent, "D_Production_Vehicle_Clearance_References", 1, "Exact current CarModels bounding dimensions")
	refs:SetAttribute("SourcePlace", "Sell Cars ServerStorage.CarModels")
	refs:SetAttribute("LargestWidthModel", "ZentauriR")
	refs:SetAttribute("LongestModel", "Mercurion190r")
	refs:SetAttribute("LowestSportsModel", "FierroRossa")
	refs:SetAttribute("LargestEnvelope", "10.58 x 6.40 x 18.94")
	refs:SetAttribute("LowSportsEnvelope", "7.85 x 4.70 x 15.64")
	part(refs, "LargestProductionEnvelope", Vector3.new(47, 4.7, 45), Vector3.new(10.58, 6.4, 18.94), COLORS.visitor, 0.88, false, Enum.Material.ForceField, 90)
	part(refs, "LowSportsEnvelope", Vector3.new(32, 3.85, 83), Vector3.new(7.85, 4.7, 15.64), COLORS.premium, 0.9, false, Enum.Material.ForceField, 0)
	root:SetAttribute("ReferenceVehicleWidth", 10.58)
	root:SetAttribute("ReferenceVehicleLength", 18.94)
	root:SetAttribute("ReferenceVehicleHeight", 6.4)
	root:SetAttribute("ReferenceVehicleSource", "Current production CarModels: ZentauriR width + Mercurion190r length")
	root:SetAttribute("LowSportsReference", "FierroRossa 7.85 x 4.70 x 15.64; flush paths require no curb tuning")
end

local function shiftModelOnce(target: Instance?, offset: Vector3, marker: string)
	if not target or not target:IsA("Model") or target:GetAttribute(marker) == true then return end
	target:PivotTo(target:GetPivot() + offset)
	target:SetAttribute(marker, true)
end

local function setModelCenterXZ(target: Instance?, x: number, z: number)
	if not target or not target:IsA("Model") then return end
	local bounds = target:GetBoundingBox()
	target:PivotTo(target:GetPivot() + Vector3.new(x - bounds.Position.X, 0, z - bounds.Position.Z))
end

local function setRouteSegment(route: Instance, name: string, a: Vector3, b: Vector3)
	local segment = route:FindFirstChild(name)
	if not segment or not segment:IsA("BasePart") then return end
	local delta = b - a
	segment.Size = Vector3.new(segment.Size.X, segment.Size.Y, delta.Magnitude)
	segment.CFrame = CFrame.new((a + b) / 2) * CFrame.Angles(0, math.atan2(delta.X, delta.Z), 0)
end

local function flattenCurbModel(target: Instance?)
	if not target then return end
	for _, descendant in target:GetDescendants() do
		if descendant:IsA("BasePart") and string.find(descendant.Name, "Curb", 1, true) then
			descendant.CanCollide = false
			descendant.Size = Vector3.new(descendant.Size.X, 0.12, descendant.Size.Z)
			descendant.Position = Vector3.new(descendant.Position.X, 1.16, descendant.Position.Z)
			descendant:SetAttribute("FlushLowCarMarker", true)
		end
	end
end

local function clearProductionEnvelopeBlockers(root: Model)
	-- Keep the personal-car centreline intact and move storage/legacy furniture to
	-- the gallery's service wall. This preserves a straight, readable garage entry.
	shiftModelOnce(root:FindFirstChild("GAR-10_Storage_Lift_and_Parts_Wall", true), Vector3.new(16, 0, 0), "V4ClearanceShift")
	shiftModelOnce(root:FindFirstChild("GAR-16_Legacy_Archive", true), Vector3.new(16, 0, 0), "V4ClearanceShift")

	-- The appraisal lane stays centred on its existing 24-stud entrance. Small
	-- furniture shifts to the staff-side strip instead of narrowing that route.
	local stockRoute = root:FindFirstChild("Dealer_Stock_Path_V2", true)
	if stockRoute then
		local xByName = {Node_01 = 105, Node_02 = 105, Node_03 = 99}
		for nodeName, x in xByName do
			local node = stockRoute:FindFirstChild(nodeName)
			if node and node:IsA("BasePart") then
				node.Position = Vector3.new(x, node.Position.Y, node.Position.Z)
			end
		end
		local y = 1.3
		setRouteSegment(stockRoute, "Segment_01", Vector3.new(105, y, -12), Vector3.new(105, y, 35))
		setRouteSegment(stockRoute, "Segment_02", Vector3.new(105, y, 35), Vector3.new(99, y, 64))
		setRouteSegment(stockRoute, "Segment_03", Vector3.new(99, y, 64), Vector3.new(72, y, 64))
	end
	setModelCenterXZ(root:FindFirstChild("INT-03_Folding_Intake_Desk", true), 75, 39)
	setModelCenterXZ(root:FindFirstChild("INT-04_Seller_Stool_and_Shade", true), 82, 38)
	setModelCenterXZ(root:FindFirstChild("INT-11_Scan_Tablet", true), 78, 84)
	setModelCenterXZ(root:FindFirstChild("INT-12_Paint_Gauge_and_Underbody_Mirrors", true), 82, 80)
	setModelCenterXZ(root:FindFirstChild("INT-13_Photo_Documentation_Wall", true), 75, 54)
	setModelCenterXZ(root:FindFirstChild("INT-14_Appraiser_Workstation", true), 75, 80)
	shiftModelOnce(root:FindFirstChild("INT-01_We_Buy_Cars_Sign", true), Vector3.new(0, 5, 0), "V4ClearanceRaise")

	local divider = root:FindFirstChild("PocketDivider", true)
	if divider and divider:IsA("BasePart") then
		divider.Size = Vector3.new(20, divider.Size.Y, divider.Size.Z)
		divider.Position = Vector3.new(76, divider.Position.Y, divider.Position.Z)
		divider:SetAttribute("VehicleLaneOpeningWidth", 28)
	end

	-- Wheel stops and all decorative curb edges become paint-height markers. The
	-- lowest production sports car therefore needs no special suspension tuning.
	local wheelStops = root:FindFirstChild("INT-08_Wheel_Stops_and_Rejection_Lane", true)
	if wheelStops then
		for _, descendant in wheelStops:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Stop" then
				descendant.CanCollide = false
				descendant.Size = Vector3.new(descendant.Size.X, 0.12, descendant.Size.Z)
				descendant.Position = Vector3.new(descendant.Position.X, 1.16, descendant.Position.Z)
				descendant:SetAttribute("FlushLowCarMarker", true)
			end
		end
	end
	flattenCurbModel(root:FindFirstChild("YRD-05_Protected_Island_Curb", true))
	flattenCurbModel(root:FindFirstChild("SAL-07_Pedestrian_Curb", true))

	-- Event utilities live against the rear edge instead of in the east treatment branch.
	local eventPower = root:FindFirstChild("EST-13_Event_Power_Audio", true)
	if eventPower then
		local machine = eventPower:FindFirstChild("Machine", true)
		if machine and machine:IsA("BasePart") then
			local delta = Vector3.new(12, machine.Position.Y, 231) - machine.Position
			machine.Position += delta
			local control = eventPower:FindFirstChild("Control", true)
			if control and control:IsA("BasePart") then control.Position += delta end
		end
	end

	root:SetAttribute("ProductionEnvelopeClearancePass", "V4 largest current fleet envelope")
	root:SetAttribute("LowCarCurbHandling", "Flush paint markers; no special-case curb logic")
end

local function clearPedestrianEnvelopeBlockers(root: Model)
	-- Keep furniture beside the public path, not on it.
	setModelCenterXZ(root:FindFirstChild("SAL-03_Buyer_Bench_and_Shade", true), 8, 67)
	setModelCenterXZ(root:FindFirstChild("Wayfinding2", true), 8, 88)
	local planter = root:FindFirstChild("Planter2", true)
	if planter and planter:IsA("BasePart") then planter.Position = Vector3.new(13, planter.Position.Y, 92) end
	local plant = root:FindFirstChild("DesertPlant2", true)
	if plant and plant:IsA("BasePart") then plant.Position = Vector3.new(13, plant.Position.Y, 92) end
	setModelCenterXZ(root:FindFirstChild("CUS-09_Digital_Configurator", true), 80, 260)

	-- The exterior collector stair now opens directly onto a shallow upper terrace
	-- and the lounge. Guests never need to cut through the staff back office.
	local upperLanding = root:FindFirstChild("UpperLanding", true)
	if upperLanding and upperLanding:IsA("BasePart") then
		upperLanding.Size = Vector3.new(upperLanding.Size.X, upperLanding.Size.Y, 32)
		upperLanding.Position = Vector3.new(upperLanding.Position.X, upperLanding.Position.Y, 124)
		upperLanding:SetAttribute("Role", "Exterior collector terrace and stair landing")
	end
	local upperWestWallFront = root:FindFirstChild("UpperWestWallFront", true)
	if upperWestWallFront and upperWestWallFront:IsA("BasePart") then
		upperWestWallFront.Size = Vector3.new(upperWestWallFront.Size.X, upperWestWallFront.Size.Y, 17)
		upperWestWallFront.Position = Vector3.new(upperWestWallFront.Position.X, upperWestWallFront.Position.Y, 102.5)
		upperWestWallFront:SetAttribute("LoungeTerraceOpening", true)
	end

	root:SetAttribute("PedestrianEnvelopeClearancePass", "Public, collector and operations routes")
	root:SetAttribute("CollectorAccess", "Exterior stair to upper terrace and lounge; no back-office crossing")
end

function Module.Build(): {[string]: number}
	local root = workspace:FindFirstChild("SellCars_CompactCampus_Greybox_V1")
	assert(root and root:IsA("Model"), "SellCars_CompactCampus_Greybox_V1 is missing")
	local old = root:FindFirstChild("08_Progression_and_People_V4")
	if old then old:Destroy() end

	local pass = model(root, "08_Progression_and_People_V4", 1, "Blockout-lock progression, arrival and people pass")
	pass:SetAttribute("ProgressionStates", 4)
	pass:SetAttribute("CustomerArrivalPositions", 2)
	pass:SetAttribute("RaisedCurbs", false)
	pass:SetAttribute("PeopleRoutes", 3)
	local finalBuildings = root:FindFirstChild("03_Building_Blockouts")
	if finalBuildings then
		for _, building in finalBuildings:GetChildren() do
			if building:IsA("Model") then
				local original = building:GetAttribute("FunctionalMinStep")
				if typeof(original) ~= "number" then original = building:GetAttribute("MinStep") end
				if typeof(original) == "number" then building:SetAttribute("FunctionalMinStep", original) end
				building:SetAttribute("MinStep", 34)
				building:SetAttribute("FinalInstitutionShell", true)
			end
		end
	end
	local fantasy = root:FindFirstChild("07_Fantasy_Completion_V3")
	if fantasy then fantasy:SetAttribute("MinStep", 34) end
	buildProgression(pass)
	buildArrivalsAndPaths(pass)
	buildPeople(pass)
	buildProductionReferences(pass, root)
	clearProductionEnvelopeBlockers(root)
	clearPedestrianEnvelopeBlockers(root)

	local models, parts = 0, 0
	for _, descendant in pass:GetDescendants() do
		if descendant:IsA("Model") then models += 1 elseif descendant:IsA("BasePart") then parts += 1 end
	end
	root:SetAttribute("ProgressionPeopleVersion", 4)
	root:SetAttribute("ProgressionStateCount", 4)
	root:SetAttribute("CustomerArrivalCount", 2)
	root:SetAttribute("PeopleMovementRouteCount", 3)
	root:SetAttribute("V4ModelCount", models)
	root:SetAttribute("V4PartCount", parts)
	return {models = models, parts = parts}
end

return Module

