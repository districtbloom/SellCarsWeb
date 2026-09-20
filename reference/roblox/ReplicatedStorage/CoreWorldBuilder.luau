local WorldBuilder = {}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("CorePrototypeConfig"))

local C = {
	ink = Color3.fromRGB(24, 27, 30),
	asphalt = Color3.fromRGB(64, 67, 70),
	concrete = Color3.fromRGB(127, 126, 119),
	yellow = Color3.fromRGB(255, 190, 29),
	green = Color3.fromRGB(72, 214, 94),
	red = Color3.fromRGB(220, 67, 57),
	blue = Color3.fromRGB(58, 128, 220),
	white = Color3.fromRGB(238, 236, 228),
	rust = Color3.fromRGB(116, 70, 43),
}

local function makePart(parent, name, size, cframe, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = true
	p.Color = color or C.concrete
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function setVisible(root, visible)
 if root:GetAttribute("IntegrationHidden") then visible=false end
	local items = { root }
	for _, d in ipairs(root:GetDescendants()) do
		table.insert(items, d)
	end
	for _, d in ipairs(items) do
		if d:IsA("BasePart") then
			local base = d:GetAttribute("ShownTransparency")
			if base == nil then
				base = d.Transparency
				d:SetAttribute("ShownTransparency", base)
			end
			if d:GetAttribute("ShownCollision") == nil then
				d:SetAttribute("ShownCollision", d.CanCollide)
			end
			d.Transparency = visible and base or 1
			d.CanCollide = visible and d:GetAttribute("ShownCollision") ~= false
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			d.Enabled = visible
		elseif d:IsA("ProximityPrompt") then
			d.Enabled = false
		end
	end
	root:SetAttribute("Visible", visible)
end

local function prompt(parent, name, action, object, hold)
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 11
	-- The custom in-world presenter uses distance, so engine activation must use the same rule.
	-- Car/build geometry should never create a visible-but-dead E prompt.
	p.RequiresLineOfSight = false
	p.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
	p.Style = Enum.ProximityPromptStyle.Default
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.Enabled = false
	p.Parent = parent
	return p
end

local function billboard(parent, name, width, height, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 30
	gui.LightInfluence = 0
	gui.Parent = parent
	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = C.ink
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.yellow
	stroke.Thickness = 2
	stroke.Parent = frame
	return gui, frame
end

local function carBillboard(parent, name, width, height, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 24
	gui.LightInfluence = 0
	gui.Parent = parent
	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	return gui, frame
end

local function addText(parent, name, text, pos, size, fontSize, color, align)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Position = pos
	t.Size = size
	t.Text = text
	t.TextColor3 = color or C.white
	t.TextSize = fontSize or 18
	t.Font = Enum.Font.GothamBold
	t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Center
	t.TextWrapped = true
	t.Parent = parent
	if parent.Parent and parent.Parent:IsA("BillboardGui") and parent.Parent.Name == "CarState" then
		t.TextStrokeColor3 = C.ink
		t.TextStrokeTransparency = 0.12
	end
	return t
end

local function sign(parent, name, text, cframe, size, color)
	local p = makePart(parent, name, size or Vector3.new(14, 7, 1), cframe, color or C.ink)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SignGui"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 32
	sg.Parent = p
	local label = addText(sg, "Label", text, UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.9), 34, C.white, Enum.TextXAlignment.Center)
	label.TextScaled = true
	return p
end

local function padMoney(value)
	local amount = math.floor(tonumber(value) or 0)
	if amount <= 0 then return "FREE" end
	local text = tostring(amount)
	while true do
		local nextText, changed = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		text = nextText
		if changed == 0 then break end
	end
	return "$" .. text
end

local function decoratePad(pad, action, title, cost, accent)
	accent = accent or C.yellow
	pad.Color = C.ink
	pad.Material = Enum.Material.SmoothPlastic
	pad.Transparency = 0.03

	local halfX = pad.Size.X * 0.5
	local halfZ = pad.Size.Z * 0.5
	local top = pad.Position.Y + pad.Size.Y * 0.5 + 0.07
	local rimThickness = 0.24
	local rimHeight = 0.08
	for _, spec in ipairs({
		{ "FrontRim", Vector3.new(pad.Size.X, rimHeight, rimThickness), CFrame.new(pad.Position.X, top, pad.Position.Z - halfZ) },
		{ "BackRim", Vector3.new(pad.Size.X, rimHeight, rimThickness), CFrame.new(pad.Position.X, top, pad.Position.Z + halfZ) },
		{ "LeftRim", Vector3.new(rimThickness, rimHeight, pad.Size.Z), CFrame.new(pad.Position.X - halfX, top, pad.Position.Z) },
		{ "RightRim", Vector3.new(rimThickness, rimHeight, pad.Size.Z), CFrame.new(pad.Position.X + halfX, top, pad.Position.Z) },
	}) do
		local rim = makePart(pad, spec[1], spec[2], spec[3], accent, Enum.Material.Neon)
		rim.CanCollide = false
		rim.CanTouch = false
		rim.CanQuery = false
	end

	local surface = Instance.new("SurfaceGui")
	surface.Name = "PadSurface"
	surface.Face = Enum.NormalId.Top
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.LightInfluence = 0
	surface.Parent = pad
	local surfaceFrame = Instance.new("Frame")
	surfaceFrame.Size = UDim2.fromScale(1, 1)
	surfaceFrame.BackgroundTransparency = 1
	surfaceFrame.Parent = surface
	local surfaceStroke = Instance.new("UIStroke")
	surfaceStroke.Color = accent
	surfaceStroke.Thickness = 3
	surfaceStroke.Transparency = 0.08
	surfaceStroke.Parent = surfaceFrame
	local surfaceTitle = addText(surfaceFrame, "Instruction", "STEP ON TO PREVIEW", UDim2.fromScale(0.08, 0.18), UDim2.fromScale(0.84, 0.64), 22, C.white, Enum.TextXAlignment.Center)
	surfaceTitle.TextScaled = true
	surfaceTitle.TextTransparency = 0.12

	local callout, card = billboard(pad, "PadCallout", 250, 76, Vector3.new(0, 4.1, 0))
	callout.MaxDistance = 30
	card.BackgroundTransparency = 0.02
	local actionText = tostring(action or "BUY") .. "  " .. tostring(title or "UPGRADE")
	addText(card, "Action", actionText, UDim2.fromScale(0.06, 0.08), UDim2.fromScale(0.88, 0.42), 17, C.white)
	addText(card, "Price", padMoney(cost), UDim2.fromScale(0.06, 0.52), UDim2.fromScale(0.88, 0.32), 15, accent)
	return callout
end

local function makeNPC(parent, name, position, shirtColor, profileText)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local root = makePart(m, "Root", Vector3.new(2, 3, 1), CFrame.new(position + Vector3.new(0, 2.5, 0)), shirtColor or C.blue)
	local head = makePart(m, "Head", Vector3.new(2, 2, 2), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(218, 166, 117))
	makePart(m, "LeftArm", Vector3.new(0.8, 3, 0.8), CFrame.new(position + Vector3.new(-1.4, 2.6, 0)), Color3.fromRGB(218, 166, 117))
	makePart(m, "RightArm", Vector3.new(0.8, 3, 0.8), CFrame.new(position + Vector3.new(1.4, 2.6, 0)), Color3.fromRGB(218, 166, 117))
	makePart(m, "LeftLeg", Vector3.new(0.85, 3, 0.9), CFrame.new(position + Vector3.new(-0.55, -0.4, 0)), C.ink)
	makePart(m, "RightLeg", Vector3.new(0.85, 3, 0.9), CFrame.new(position + Vector3.new(0.55, -0.4, 0)), C.ink)
	local face = Instance.new("SurfaceGui")
	face.Name = "Face"
	face.Face = Enum.NormalId.Front
	face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	face.PixelsPerStud = 50
	face.Parent = head
	local faceText = addText(face, "Expression", "•  ‿  •", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 24, C.ink, Enum.TextXAlignment.Center)
	faceText.TextScaled = true
	m.PrimaryPart = root
	m:SetAttribute("Profile", profileText or "")
	return m, root, head
end

local function makeCar(parent, name, position, color)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local body = makePart(m, "Body", Vector3.new(8, 1.5, 4.2), CFrame.new(position + Vector3.new(0, 1.7, 0)), color)
	local cabin = makePart(m, "Cabin", Vector3.new(4.2, 1.6, 3.7), CFrame.new(position + Vector3.new(0.5, 3.15, 0)), color:Lerp(C.white, 0.12))
	local wheelOffsets = {
		Vector3.new(-2.6, 0.9, -2.15), Vector3.new(2.6, 0.9, -2.15),
		Vector3.new(-2.6, 0.9, 2.15), Vector3.new(2.6, 0.9, 2.15),
	}
	for index, o in ipairs(wheelOffsets) do
		local wheel = makePart(m, "Wheel", Vector3.new(0.55, 1.5, 1.5), CFrame.new(position + o) * CFrame.Angles(0, math.rad(90), 0), C.ink)
		wheel.Shape = Enum.PartType.Cylinder
		wheel:SetAttribute("WheelIndex", index)
		wheel:SetAttribute("WheelXSign", o.X < 0 and -1 or 1)
		wheel:SetAttribute("WheelZSign", o.Z < 0 and -1 or 1)
	end

	if name == "PersonalCar" then
		local anchor = makePart(m, "VisualAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(position), C.white, Enum.Material.SmoothPlastic, 1)
		anchor.CanCollide = false
		anchor:SetAttribute("ShownCollision", false)

		for index, o in ipairs(wheelOffsets) do
			local rim = makePart(m, "Rim", Vector3.new(0.6, 0.92, 0.92), CFrame.new(position + o) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(190, 194, 198), Enum.Material.Metal)
			rim.Shape = Enum.PartType.Cylinder
			rim.CanCollide = false
			rim:SetAttribute("ShownCollision", false)
			rim:SetAttribute("WheelIndex", index)
			rim:SetAttribute("WheelXSign", o.X < 0 and -1 or 1)
			rim:SetAttribute("WheelZSign", o.Z < 0 and -1 or 1)
		end

		for _, side in ipairs({ -1, 1 }) do
			local window = makePart(m, side < 0 and "WindowLeft" or "WindowRight", Vector3.new(3.45, 0.82, 0.12), CFrame.new(position + Vector3.new(0.5, 3.22, side * 1.88)), Color3.fromRGB(84, 113, 132), Enum.Material.SmoothPlastic, 0.28)
			window.CanCollide = false
			window:SetAttribute("ShownCollision", false)
		end

		local vinylParts = {
			{ "VinylLeft1", Vector3.new(6.4, 0.08, 0.42), Vector3.new(0, 2.49, -0.42) },
			{ "VinylRight1", Vector3.new(6.4, 0.08, 0.42), Vector3.new(0, 2.49, 0.42) },
			{ "VinylLeft2", Vector3.new(5.4, 0.09, 0.25), Vector3.new(-0.15, 2.5, -0.76) },
			{ "VinylRight2", Vector3.new(5.4, 0.09, 0.25), Vector3.new(-0.15, 2.5, 0.76) },
		}
		for _, spec in ipairs(vinylParts) do
			local vinyl = makePart(m, spec[1], spec[2], CFrame.new(position + spec[3]), C.white, Enum.Material.SmoothPlastic, 1)
			vinyl.CanCollide = false
			vinyl:SetAttribute("ShownCollision", false)
		end

		for _, side in ipairs({ -1, 1 }) do
			local neon = makePart(m, side < 0 and "NeonLeft" or "NeonRight", Vector3.new(6.8, 0.12, 0.16), CFrame.new(position + Vector3.new(0, 0.62, side * 2.02)), C.yellow, Enum.Material.Neon, 1)
			neon.CanCollide = false
			neon:SetAttribute("ShownCollision", false)
			local light = Instance.new("PointLight")
			light.Name = "Glow"
			light.Brightness = 1.2
			light.Range = 10
			light.Enabled = false
			light.Parent = neon
		end

		local accessories = {
			{ "MuscleHood", Vector3.new(2.2, 0.42, 1.55), Vector3.new(1.55, 2.62, 0) },
			{ "OffroadRackLeft", Vector3.new(3.8, 0.18, 0.18), Vector3.new(0.35, 4.16, -1.55) },
			{ "OffroadRackRight", Vector3.new(3.8, 0.18, 0.18), Vector3.new(0.35, 4.16, 1.55) },
			{ "OffroadRackFront", Vector3.new(0.18, 0.18, 3.25), Vector3.new(1.9, 4.16, 0) },
			{ "OffroadRackRear", Vector3.new(0.18, 0.18, 3.25), Vector3.new(-1.2, 4.16, 0) },
			{ "OffroadBumper", Vector3.new(0.38, 0.62, 4.7), Vector3.new(4.24, 1.72, 0) },
		}
		for _, spec in ipairs(accessories) do
			local accessory = makePart(m, spec[1], spec[2], CFrame.new(position + spec[3]), C.ink, Enum.Material.Metal, 1)
			accessory.CanCollide = false
			accessory:SetAttribute("ShownCollision", false)
		end
		cabin:SetAttribute("PersonalCabin", true)
	end
	m.PrimaryPart = body
	return m, body
end

function WorldBuilder.BuildOpeningCinematic(world)
	if world:FindFirstChild("OpeningCinematic") then
		return world.OpeningCinematic
	end

	local set = Instance.new("Model")
	set.Name = "OpeningCinematic"
	set.Parent = world

	local garage = Instance.new("Model")
	garage.Name = "StarterGarage"
	garage.Parent = set
	makePart(garage, "Floor", Vector3.new(18, 0.5, 16), CFrame.new(-84, 0.25, -17), Color3.fromRGB(85, 78, 67), Enum.Material.Concrete)
	makePart(garage, "BackWall", Vector3.new(18, 8, 0.8), CFrame.new(-84, 4, -24.6), Color3.fromRGB(104, 87, 65), Enum.Material.WoodPlanks)
	makePart(garage, "LeftWall", Vector3.new(0.8, 8, 16), CFrame.new(-92.6, 4, -17), Color3.fromRGB(104, 87, 65), Enum.Material.WoodPlanks)
	makePart(garage, "RightWall", Vector3.new(0.8, 8, 16), CFrame.new(-75.4, 4, -17), Color3.fromRGB(104, 87, 65), Enum.Material.WoodPlanks)
	makePart(garage, "FrontBeam", Vector3.new(18, 1, 0.8), CFrame.new(-84, 7.6, -9.4), Color3.fromRGB(79, 65, 49), Enum.Material.Wood)
	makePart(garage, "Roof", Vector3.new(20, 0.7, 18), CFrame.new(-84, 8.4, -17) * CFrame.Angles(0, 0, math.rad(-2)), Color3.fromRGB(78, 74, 68), Enum.Material.CorrodedMetal)
	local loosePanel = makePart(garage, "LoosePanel", Vector3.new(4.5, 0.35, 5), CFrame.new(-90, 8.85, -14) * CFrame.Angles(0, 0, math.rad(-7)), Color3.fromRGB(116, 92, 64), Enum.Material.CorrodedMetal)
	loosePanel:SetAttribute("CinematicHome", loosePanel.CFrame)
	makePart(garage, "Crate", Vector3.new(3, 2.5, 3), CFrame.new(-89.5, 1.5, -20), Color3.fromRGB(91, 65, 39), Enum.Material.WoodPlanks)
	makePart(garage, "OldTire", Vector3.new(2.3, 2.3, 0.7), CFrame.new(-78, 1.25, -21) * CFrame.Angles(math.rad(90), 0, 0), C.ink).Shape = Enum.PartType.Cylinder
	sign(garage, "GarageName", "WEST MESA\nMOTORS", CFrame.new(-84, 6.25, -9) * CFrame.Angles(0, 0, math.rad(-4)), Vector3.new(8, 3.2, 0.45), Color3.fromRGB(79, 57, 35))

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = set
	local function marker(name, cframe)
		local p = makePart(markers, name, Vector3.new(1, 1, 1), cframe, C.yellow, Enum.Material.Neon, 1)
		p.CanCollide = false
		p:SetAttribute("ShownCollision", false)
		return p
	end
	marker("Player", CFrame.new(-81, 3, -3) * CFrame.Angles(0, math.rad(-78), 0))
	marker("CamPlayerIdle", CFrame.lookAt(Vector3.new(-72, 5.6, 7), Vector3.new(-81, 3.4, -3)))
	marker("CamRoad", CFrame.lookAt(Vector3.new(-45, 5.5, 54), Vector3.new(-69, 2.5, 37)))
	marker("CamDriverWink", CFrame.lookAt(Vector3.new(-58.5, 5.2, 25.5), Vector3.new(-66.2, 4.2, 31)))
	marker("CamReveal", CFrame.lookAt(Vector3.new(-58, 10, 15), Vector3.new(-83, 3.6, -15)))
	marker("CamDecision", CFrame.lookAt(Vector3.new(-91, 6.7, 2), Vector3.new(-68, 4.2, -1)))

	local cars = Instance.new("Folder")
	cars.Name = "CrazyCars"
	cars.Parent = set

	local tuner, tunerBody = makeCar(cars, "NeonTuner", Vector3.new(-125, 0, 34), Color3.fromRGB(146, 56, 220))
	makePart(tuner, "Underglow", Vector3.new(7.2, 0.15, 3.5), CFrame.new(-125, 0.55, 34), Color3.fromRGB(33, 239, 255), Enum.Material.Neon)
	makePart(tuner, "Spoiler", Vector3.new(0.5, 0.35, 5.2), CFrame.new(-128.2, 3.1, 34), C.ink, Enum.Material.Metal)
	tuner:SetAttribute("Delay", 0)
	tuner:SetAttribute("LaneZ", 34)
	tuner:SetAttribute("Duration", 3.2)

	local offroad, offroadBody = makeCar(cars, "LiftedOffroader", Vector3.new(-132, 0.9, 40), Color3.fromRGB(121, 194, 55))
	makePart(offroad, "RoofRack", Vector3.new(3.8, 0.3, 3.6), CFrame.new(-131.5, 5.2, 40), C.ink, Enum.Material.Metal)
	makePart(offroad, "RoofScoop", Vector3.new(1.8, 0.75, 1.4), CFrame.new(-130.5, 5.7, 40), C.yellow, Enum.Material.Metal)
	offroad:SetAttribute("Delay", 0.55)
	offroad:SetAttribute("LaneZ", 40)
	offroad:SetAttribute("Duration", 3.5)

	local muscle, muscleBody = makeCar(cars, "WildMuscle", Vector3.new(-138, 0, 37), Color3.fromRGB(223, 69, 48))
	makePart(muscle, "HoodScoop", Vector3.new(2.1, 0.65, 1.5), CFrame.new(-136.5, 3, 37), C.ink, Enum.Material.Metal)
	makePart(muscle, "Vinyl", Vector3.new(6, 0.08, 0.75), CFrame.new(-138, 2.48, 37), C.white, Enum.Material.Neon)
	muscle:SetAttribute("Delay", 1.05)
	muscle:SetAttribute("LaneZ", 37)
	muscle:SetAttribute("Duration", 3.1)

	local rich = makeCar(cars, "RichStopper", Vector3.new(-125, 0, 31), Color3.fromRGB(232, 174, 36))
	makePart(rich, "Chrome", Vector3.new(6.2, 0.1, 0.55), CFrame.new(-125, 2.5, 31), C.white, Enum.Material.Metal)
	local driverHead = makePart(rich, "DriverHead", Vector3.new(1.25, 1.25, 1.25), CFrame.new(-124.2, 4.35, 31), Color3.fromRGB(225, 178, 128))
	driverHead.CanCollide = false
	local driverFace = Instance.new("SurfaceGui")
	driverFace.Name = "DriverFace"
	driverFace.Face = Enum.NormalId.Front
	driverFace.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	driverFace.PixelsPerStud = 45
	driverFace.Parent = driverHead
	local expression = addText(driverFace, "Expression", "•  ‿  •", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 22, C.ink, Enum.TextXAlignment.Center)
	expression.TextScaled = true
	rich:SetAttribute("Delay", 0.18)
	rich:SetAttribute("LaneZ", 31)
	rich:SetAttribute("Duration", 3.4)
	rich:SetAttribute("StopX", -67)
	rich:SetAttribute("StopDuration", 0.72)
	rich:SetAttribute("RichMoment", true)

	for _, car in ipairs(cars:GetChildren()) do
		if car:IsA("Model") then
			for _, d in ipairs(car:GetDescendants()) do
				if d:IsA("BasePart") then
					d:SetAttribute("CinematicTransparency", d.Transparency)
					d.Transparency = 1
					d.CanCollide = false
					d:SetAttribute("ShownCollision", false)
				end
			end
		end
	end

	local arrivalSign = world:FindFirstChild("ArrivalSign")
	local arrivalLabel = arrivalSign and arrivalSign:FindFirstChild("Label", true)
	if arrivalLabel and arrivalLabel:IsA("TextLabel") then
		arrivalLabel.Text = "WEST MESA MOTORS\nSTARTER LOT"
	end

	set:SetAttribute("Duration", 8.2)
	return set
end

function WorldBuilder.BuildRareArrival(world)
	if world:FindFirstChild("RareArrival") then
		return world.RareArrival
	end

	local set = Instance.new("Model")
	set.Name = "RareArrival"
	set.Parent = world

	local bay = Instance.new("Model")
	bay.Name = "IntakeBay"
	bay.Parent = set
	makePart(bay, "BayPad", Vector3.new(28, 0.18, 15), CFrame.new(-7, 0.11, 24.5), Color3.fromRGB(52, 55, 58), Enum.Material.Asphalt)
	for _, z in ipairs({18, 31}) do
		local line = makePart(bay, "BayLine", Vector3.new(26, 0.06, 0.22), CFrame.new(-7, 0.24, z), C.yellow, Enum.Material.Neon)
		line.CanCollide = false
	end
	sign(bay, "PrivateIntakeSign", "PRIVATE INTAKE", CFrame.new(-20, 4.2, 31), Vector3.new(10, 4, 0.6), C.ink)
	local beacon = makePart(bay, "ArrivalBeacon", Vector3.new(0.8, 1.2, 0.8), CFrame.new(-20, 7, 31), C.yellow, Enum.Material.Neon)

	local sellerGarage = Instance.new("Model")
	sellerGarage.Name = "SellerGarage"
	sellerGarage.Parent = set
	makePart(sellerGarage, "Floor", Vector3.new(22, 0.35, 16), CFrame.new(92, 0.18, 18), Color3.fromRGB(67, 69, 71), Enum.Material.Concrete)
	makePart(sellerGarage, "BackWall", Vector3.new(22, 8, 0.7), CFrame.new(92, 4, 10.3), Color3.fromRGB(81, 73, 64), Enum.Material.Concrete)
	makePart(sellerGarage, "LeftWall", Vector3.new(0.7, 8, 16), CFrame.new(81.3, 4, 18), Color3.fromRGB(81, 73, 64), Enum.Material.Concrete)
	makePart(sellerGarage, "RightWall", Vector3.new(0.7, 8, 16), CFrame.new(102.7, 4, 18), Color3.fromRGB(81, 73, 64), Enum.Material.Concrete)
	makePart(sellerGarage, "Roof", Vector3.new(22, 0.65, 16), CFrame.new(92, 8, 18), Color3.fromRGB(46, 49, 52), Enum.Material.Metal)
	sign(sellerGarage, "GarageSign", "ELIAS · PRIVATE GARAGE", CFrame.new(92, 6.2, 10.0), Vector3.new(14, 3, 0.5), C.ink)
	beacon.Shape = Enum.PartType.Ball
	beacon.CanCollide = false

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = set
	local function rareMarker(name, cframe)
		local markerPart = makePart(markers, name, Vector3.new(1, 1, 1), cframe, C.yellow, Enum.Material.Neon, 1)
		markerPart.CanCollide = false
		markerPart:SetAttribute("ShownCollision", false)
		return markerPart
	end

	local startPosition = Vector3.new(105, 0, 25)
	local transporter = Instance.new("Model")
	transporter.Name = "Transporter"
	transporter.Parent = set
	local chassis = makePart(transporter, "Chassis", Vector3.new(18, 0.8, 6), CFrame.new(startPosition + Vector3.new(0, 1.2, 0)), C.ink, Enum.Material.Metal)
	makePart(transporter, "Cab", Vector3.new(5.8, 4.6, 5.4), CFrame.new(startPosition + Vector3.new(-6, 3.35, 0)), Color3.fromRGB(55, 61, 68), Enum.Material.Metal)
	makePart(transporter, "Windshield", Vector3.new(0.18, 1.7, 4.2), CFrame.new(startPosition + Vector3.new(-8.95, 3.75, 0)), Color3.fromRGB(94, 145, 166), Enum.Material.Glass, 0.18)
	makePart(transporter, "Flatbed", Vector3.new(11.5, 0.45, 5.5), CFrame.new(startPosition + Vector3.new(3.1, 2.05, 0)), Color3.fromRGB(75, 79, 83), Enum.Material.DiamondPlate)
	for _, offset in ipairs({
		Vector3.new(-5.8, 0.85, -3.15), Vector3.new(-5.8, 0.85, 3.15),
		Vector3.new(4.8, 0.85, -3.15), Vector3.new(4.8, 0.85, 3.15),
	}) do
		local wheel = makePart(transporter, "TruckWheel", Vector3.new(2.1, 2.1, 0.75), CFrame.new(startPosition + offset) * CFrame.Angles(math.rad(90), 0, 0), C.ink)
		wheel.Shape = Enum.PartType.Cylinder
	end
	transporter.PrimaryPart = chassis

	local rareCar, rareBody = makeCar(transporter, "RareCar", startPosition + Vector3.new(3.1, 2.1, 0), Color3.fromRGB(120, 48, 155))
	makePart(rareCar, "HeritageStripe", Vector3.new(6.4, 0.08, 0.72), CFrame.new(startPosition + Vector3.new(3.1, 4.58, 0)), C.yellow, Enum.Material.Neon)
	makePart(rareCar, "RearSpoiler", Vector3.new(0.4, 0.35, 5), CFrame.new(startPosition + Vector3.new(6.25, 5.1, 0)), C.ink, Enum.Material.Metal)

	local cover = Instance.new("Model")
	cover.Name = "Cover"
	cover.Parent = transporter
	local coverTop = makePart(cover, "ClothTop", Vector3.new(9.2, 3.35, 5.1), CFrame.new(startPosition + Vector3.new(3.1, 5.15, 0)), Color3.fromRGB(36, 39, 43), Enum.Material.Fabric)
	coverTop.CanCollide = false
	makePart(cover, "TieDown", Vector3.new(0.25, 3.5, 5.3), CFrame.new(startPosition + Vector3.new(3.1, 4.8, 0)), C.yellow, Enum.Material.Fabric).CanCollide = false

	local carGui, carCard = carBillboard(rareBody, "CarState", 290, 96, Vector3.new(0, 6.2, 0))
	addText(carCard, "CarName", "1972 PHOENIX GT", UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.94, 0.31), 21, C.white)
	addText(carCard, "Tags", "RARE · SURVIVOR 62%", UDim2.fromScale(0.03, 0.33), UDim2.fromScale(0.94, 0.25), 15, C.yellow)
	addText(carCard, "Condition", "", UDim2.fromScale(0.03, 0.48), UDim2.fromScale(0.2, 0.1), 1, C.yellow)
	addText(carCard, "Value", "$4.8K  →  EST. $7.2K", UDim2.fromScale(0.03, 0.61), UDim2.fromScale(0.94, 0.31), 16, C.green)

	local seller, sellerRoot = makeNPC(set, "RareSeller", Vector3.new(-15, 1.5, 16), Color3.fromRGB(74, 83, 98), "")
	prompt(sellerRoot, "RareSellerPrompt", "TALK", "PRIVATE SELLER", 0)

	rareMarker("TransportStart", transporter:GetPivot())
	rareMarker("TransportEnd", CFrame.new(-10, 1.2, 25))
	rareMarker("SellerTransport", CFrame.new(92, 1.2, 18))
	rareMarker("SellerDriveTarget", CFrame.new(88, 0.5, 28))
	rareMarker("ArrivalCamera", CFrame.lookAt(Vector3.new(-43, 7.5, 49), Vector3.new(8, 2.8, 25)))
	rareMarker("ArrivalCameraStop", CFrame.lookAt(Vector3.new(-27, 6.4, 11), Vector3.new(-8, 3.2, 25)))
	rareMarker("RevealCamera", CFrame.lookAt(Vector3.new(-7, 7.5, 10.5), Vector3.new(-7, 4.2, 25)))
	rareMarker("SellerRevealCamera", CFrame.lookAt(Vector3.new(77, 6.8, 32), Vector3.new(92, 4.1, 18)))

	setVisible(set, false)
	set:SetAttribute("ArrivalDuration", 3.4)
	return set
end

function WorldBuilder.SetVisible(root, visible)
	setVisible(root, visible)
end

function WorldBuilder.Build()
	local old = Workspace:FindFirstChild("CoreUXPrototype")
	if old and old:GetAttribute("BuiltVersion") == "CoreUXLandscapeV7" then
		WorldBuilder.BuildOpeningCinematic(old)
		WorldBuilder.BuildRareArrival(old)
		return old
	elseif old then
		old:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "CoreUXPrototype"
	world.Parent = Workspace

	local base = Workspace:FindFirstChild("Baseplate")
	-- Preserve Integration ground.
	local oldSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	-- Preserve original spawn.

	makePart(world, "Ground", Vector3.new(210, 1, 130), CFrame.new(0, -0.5, 0), C.asphalt, Enum.Material.Asphalt)
	makePart(world, "Road", Vector3.new(190, 0.25, 18), CFrame.new(0, 0.1, 37), Color3.fromRGB(42, 44, 46), Enum.Material.Asphalt)
	for x = -85, 85, 14 do
		local stripe = makePart(world, "RoadStripe", Vector3.new(7, 0.08, 0.35), CFrame.new(x, 0.28, 37), C.yellow, Enum.Material.Neon)
		stripe.CanCollide = false
	end
	for _, z in ipairs({-25, 0, 25}) do
		makePart(world, "FlowLine", Vector3.new(185, 0.05, 0.18), CFrame.new(0, 0.03, z), Color3.fromRGB(93, 96, 99), Enum.Material.Neon)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PrototypeSpawn"
	spawn.Size = Vector3.new(7, 0.5, 7)
	spawn.Position = Vector3.new(-88, 0.5, 18)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.35
	spawn.Color = C.green
	spawn.Parent = world

	sign(world, "ArrivalSign", "SELL CARS\nCORE UX PROTOTYPE", CFrame.new(-87, 5, 4), Vector3.new(16, 8, 1), C.ink)

	local lot = Instance.new("Model")
	lot.Name = "LotEntrance"
	lot.Parent = world
	local gate = sign(lot, "GateSign", "WE BUY CARS", CFrame.new(-67, 5, 0), Vector3.new(14, 7, 1), Color3.fromRGB(117, 88, 31))
	local openAnchor = makePart(lot, "OpenAnchor", Vector3.new(12, 0.4, 8), CFrame.new(-67, 0.2, -7), C.ink, Enum.Material.SmoothPlastic, 0.03)
	openAnchor:SetAttribute("PadId", "PlantSaleSign")
	openAnchor:SetAttribute("Action", "PLANT")
	openAnchor:SetAttribute("Cost", 0)
	openAnchor:SetAttribute("Title", "WE BUY CARS SIGN")
	openAnchor:SetAttribute("Benefit", "INVITES YOUR FIRST SELLER")
	openAnchor:SetAttribute("RequiredStage", 1)
	openAnchor:SetAttribute("PreviewPath", "LotEntrance.GateSign")
	decoratePad(openAnchor, "PLANT", "SELL SIGN", 0, C.yellow)
	prompt(openAnchor, "OpenLotPrompt", "SELECT", "WE BUY CARS SIGN", 0)
	openAnchor.OpenLotPrompt.Enabled = false
	makePart(lot, "LeftPost", Vector3.new(1, 7, 1), CFrame.new(-73, 3.5, 0), C.concrete)
	makePart(lot, "RightPost", Vector3.new(1, 7, 1), CFrame.new(-61, 3.5, 0), C.concrete)
	gate:SetAttribute("Gate", true)
	setVisible(gate, false)

	local dealStation = Instance.new("Model")
	dealStation.Name = "DealStation"
	dealStation.Parent = world
	local dealPad = makePart(dealStation, "DealTablePad", Vector3.new(12, 0.4, 8), CFrame.new(-51, 0.2, -7), C.ink, Enum.Material.SmoothPlastic, 0.03)
	dealPad:SetAttribute("PadId", "DealTable")
	dealPad:SetAttribute("Action", "PLACE")
	dealPad:SetAttribute("Cost", Config.DealTableCost)
	dealPad:SetAttribute("Title", "DEAL TABLE")
	dealPad:SetAttribute("Benefit", "UNLOCKS FACE-TO-FACE DEALS")
	dealPad:SetAttribute("RequiredStage", 1)
	dealPad:SetAttribute("PreviewPath", "DealStation.Furniture")
	decoratePad(dealPad, "SET UP", "SELLER AREA", Config.DealTableCost, C.yellow)
	local furniture = Instance.new("Model")
	furniture.Name = "Furniture"
	furniture.Parent = dealStation
	makePart(furniture, "TableTop", Vector3.new(7, 0.45, 3.2), CFrame.new(-51, 2.7, 0), Color3.fromRGB(110, 78, 47), Enum.Material.WoodPlanks)
	for _, x in ipairs({ -53.6, -48.4 }) do
		makePart(furniture, "TableLeg", Vector3.new(0.45, 2.5, 0.45), CFrame.new(x, 1.35, 0), Color3.fromRGB(65, 58, 52), Enum.Material.Metal)
	end
	for _, z in ipairs({ -3.2, 3.2 }) do
		makePart(furniture, "ChairSeat", Vector3.new(2.6, 0.35, 2.4), CFrame.new(-51, 1.6, z), Color3.fromRGB(53, 57, 62), Enum.Material.Metal)
		makePart(furniture, "ChairBack", Vector3.new(2.6, 2.4, 0.35), CFrame.new(-51, 2.65, z + (z < 0 and -1 or 1)), Color3.fromRGB(53, 57, 62), Enum.Material.Metal)
	end
	sign(furniture, "DealBoard", "MAKE THE DEAL", CFrame.new(-51, 5.8, 4.7), Vector3.new(8, 2.8, 0.5), C.ink)
	setVisible(furniture, false)
	setVisible(dealPad, false)

	local deal = Instance.new("Model")
	deal.Name = "FirstDeal"
	deal.Parent = world
	local car, carBody = makeCar(deal, "FirstCar", Vector3.new(-35, 0, 0), C.rust)
	local carGui, carCard = carBillboard(carBody, "CarState", 275, 92, Vector3.new(0, 5.1, 0))
	addText(carCard, "CarName", "RUSTY SEDAN", UDim2.fromScale(0.03, 0.01), UDim2.fromScale(0.94, 0.32), 21, C.white)
	addText(carCard, "Tags", "COMMON · ROUGH 35%", UDim2.fromScale(0.03, 0.33), UDim2.fromScale(0.94, 0.25), 15, C.yellow)
	addText(carCard, "Condition", "", UDim2.fromScale(0.03, 0.5), UDim2.fromScale(0.2, 0.1), 1, C.red)
	addText(carCard, "Value", "$900  →  EST. $2.3K", UDim2.fromScale(0.03, 0.62), UDim2.fromScale(0.94, 0.29), 16, C.green)
	local seller, sellerRoot = makeNPC(deal, "FirstSeller", Vector3.new(-35, 1.5, -8), Color3.fromRGB(151, 91, 38), "")
	prompt(sellerRoot, "FirstSellerPrompt", "TALK", "BUY RUSTY SEDAN", 0)
	local startAttachment = Instance.new("Attachment")
	startAttachment.Name = "StartRepairAttachment"
	startAttachment.Position = Vector3.new(0, 1.2, 2.5)
	startAttachment.Parent = carBody
	for index, item in ipairs({
		{name = "Body", x = -39, z = 3.2, action = "PATCH BODY", cost = 120, value = 300},
		{name = "Wheels", x = -35, z = 4.2, action = "REPLACE TIRES", cost = 160, value = 400},
		{name = "Engine", x = -31, z = 3.2, action = "TUNE ENGINE", cost = 220, value = 600},
	}) do
		local a = makePart(deal, item.name .. "RepairAnchor", Vector3.new(1, 1, 1), CFrame.new(item.x, 1.1, item.z), C.yellow, Enum.Material.Neon, 1)
		a.CanCollide = false
		a:SetAttribute("ShownCollision", false)
		a:SetAttribute("PromptRank", index)
		a:SetAttribute("RepairCost", item.cost)
		a:SetAttribute("RepairValue", item.value)
		prompt(a, item.name .. "RepairPrompt", item.action, "RESTORE PART", 0.8 + index * 0.08)
	end
	local listAnchor = makePart(deal, "ListAnchor", Vector3.new(1, 1, 1), CFrame.new(-28, 1.1, 0), C.yellow, Enum.Material.Neon, 1)
	listAnchor.CanCollide = false
	-- Listing happens automatically at the sales space.
	local saleSign = sign(deal, "ForSaleSign", "FOR SALE", CFrame.new(-35, 4.8, 3.2), Vector3.new(7, 3.2, 0.5), C.green)
	saleSign:SetAttribute("ShownCollision", false)
	setVisible(saleSign, false)
	setVisible(deal, false)

	local buyer, buyerRoot = makeNPC(world, "FirstBuyer", Vector3.new(-24, 1.5, -8), Color3.fromRGB(57, 111, 171), "")
	prompt(buyerRoot, "BuyerPrompt", "TALK", "REVIEW OFFER", 0)
	local buyerCar = makeCar(buyer, "BuyerCar", Vector3.new(-18, 0, -4), Color3.fromRGB(36, 45, 58))
	makePart(buyerCar, "GoldTrim", Vector3.new(6.2, 0.08, 0.45), CFrame.new(-18, 2.5, -4), C.yellow, Enum.Material.Metal)
	setVisible(buyer, false)

	local workshop = Instance.new("Model")
	workshop.Name = "Workshop"
	workshop.Parent = world

	local workshopPadIndex = 0
	local function workshopPad(name, padId, title, benefit, cost, previewPath)
		workshopPadIndex += 1
		local padX = -4 + (workshopPadIndex - 1) * 6
		local pad = makePart(workshop, name, Vector3.new(5.2, 0.4, 7), CFrame.new(padX, 0.2, -14), C.ink, Enum.Material.SmoothPlastic, 0.03)
		pad:SetAttribute("PadId", padId)
		pad:SetAttribute("Action", "BUILD")
		pad:SetAttribute("Cost", cost)
		pad:SetAttribute("Title", title)
		pad:SetAttribute("Benefit", benefit)
		pad:SetAttribute("RequiredStage", 5)
		pad:SetAttribute("PreviewPath", previewPath)
		decoratePad(pad, "BUILD", title, cost, C.yellow)
		setVisible(pad, false)
		return pad
	end

	local foundation = Instance.new("Model")
	foundation.Name = "Foundation"
	foundation.Parent = workshop
	makePart(foundation, "WorkshopFloor", Vector3.new(24, 0.5, 20), CFrame.new(5, 0.25, 0), Color3.fromRGB(92, 94, 93), Enum.Material.Concrete)
	setVisible(foundation, false)

	local approach = Instance.new("Model")
	approach.Name = "Approach"
	approach.Parent = workshop
	makePart(approach, "EntryRamp", Vector3.new(11, 0.35, 5), CFrame.new(5, 0.18, -11.8) * CFrame.Angles(math.rad(-3), 0, 0), Color3.fromRGB(104, 105, 101), Enum.Material.Concrete)
	for _, x in ipairs({ 1, 9 }) do
		local stripe = makePart(approach, "GuideStripe", Vector3.new(0.24, 0.08, 7), CFrame.new(x, 0.42, -9), C.yellow, Enum.Material.Neon)
		stripe.CanCollide = false
	end
	setVisible(approach, false)

	local serviceSlab = Instance.new("Model")
	serviceSlab.Name = "ServiceSlab"
	serviceSlab.Parent = workshop
	makePart(serviceSlab, "BackWall", Vector3.new(24, 9, 1), CFrame.new(5, 4.5, 9), C.concrete, Enum.Material.Concrete)
	makePart(serviceSlab, "LeftWall", Vector3.new(1, 9, 19), CFrame.new(-6.5, 4.5, 0), C.concrete, Enum.Material.Concrete)
	makePart(serviceSlab, "RightWall", Vector3.new(1, 9, 19), CFrame.new(16.5, 4.5, 0), C.concrete, Enum.Material.Concrete)
	makePart(serviceSlab, "Roof", Vector3.new(24, 1, 20), CFrame.new(5, 9, 0), Color3.fromRGB(78, 81, 84), Enum.Material.Metal)
	sign(serviceSlab, "WorkshopSign", "BASIC WORKSHOP", CFrame.new(5, 8, 9.5), Vector3.new(16, 4, 1), C.ink)
	setVisible(serviceSlab, false)

	local lift = Instance.new("Model")
	lift.Name = "Lift"
	lift.Parent = workshop
	makePart(lift, "LiftLeft", Vector3.new(1, 6, 1), CFrame.new(1, 3, 0), C.blue, Enum.Material.Metal)
	makePart(lift, "LiftRight", Vector3.new(1, 6, 1), CFrame.new(9, 3, 0), C.blue, Enum.Material.Metal)
	makePart(lift, "LiftDeck", Vector3.new(10, 0.45, 5.2), CFrame.new(5, 0.65, 0), Color3.fromRGB(48, 54, 62), Enum.Material.DiamondPlate)
	setVisible(lift, false)

	workshopPad("FoundationPad", "WorkshopFoundation", "FOUNDATION", "CREATES THE REPAIR FOOTPRINT", Config.WorkshopCosts.Foundation, "Workshop.Foundation")
	workshopPad("ApproachPad", "WorkshopApproach", "APPROACH", "LETS CARS SELF-ROUTE INSIDE", Config.WorkshopCosts.Approach, "Workshop.Approach")
	workshopPad("ServiceSlabPad", "WorkshopServiceSlab", "SERVICE SLAB", "ENCLOSES THE WORK AREA", Config.WorkshopCosts.ServiceSlab, "Workshop.ServiceSlab")
	workshopPad("LiftPad", "WorkshopLift", "CAR LIFT", "UNLOCKS ROUTINE REPAIRS", Config.WorkshopCosts.Lift, "Workshop.Lift")

	local mechanic, mechanicRoot = makeNPC(workshop, "Mechanic", Vector3.new(5, 1.5, 3), Color3.fromRGB(45, 48, 54), "")
	prompt(mechanicRoot, "HireMechanicPrompt", "SELECT", "MECHANIC", 0)
	mechanicRoot.HireMechanicPrompt.Enabled = false
	local staffGui, staffCard = billboard(mechanicRoot, "StaffState", 220, 82, Vector3.new(0, 5.2, 0))
	staffGui.MaxDistance = 18
	addText(staffCard, "Role", "MECHANIC · LV 1", UDim2.fromScale(0.06, 0.06), UDim2.fromScale(0.88, 0.4), 17, C.white)
	addText(staffCard, "Progress", "HIRE $" .. tostring(Config.MechanicCost), UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.88, 0.36), 15, C.yellow)
	local hirePad = makePart(workshop, "HirePad", Vector3.new(12, 0.35, 7), CFrame.new(5, 0.18, -13), C.ink, Enum.Material.SmoothPlastic, 0.03)
	hirePad:SetAttribute("PadId", "FirstMechanic")
	hirePad:SetAttribute("Action", "HIRE")
	hirePad:SetAttribute("Cost", Config.MechanicCost)
	hirePad:SetAttribute("Title", "MECHANIC · LV 1")
	hirePad:SetAttribute("Benefit", "HANDLES ROUTINE REPAIRS")
	hirePad:SetAttribute("RequiredStage", 6)
	hirePad:SetAttribute("PreviewPath", "Workshop.Mechanic")
	hirePad:SetAttribute("PreviewStyle", "Character")
	decoratePad(hirePad, "HIRE", "MECHANIC", Config.MechanicCost, C.yellow)
	setVisible(mechanic, false)
	setVisible(hirePad, false)

	local second = Instance.new("Model")
	second.Name = "SecondDeal"
	second.Parent = world
	local secondCar, secondBody = makeCar(second, "SecondCar", Vector3.new(39, 0, -15), Color3.fromRGB(87, 112, 128))
	local secondGui, secondCard = carBillboard(secondBody, "CarState", 280, 92, Vector3.new(0, 5.1, 0))
	addText(secondCard, "CarName", "DESERT COUPE", UDim2.fromScale(0.03, 0.01), UDim2.fromScale(0.94, 0.32), 21, C.white)
	addText(secondCard, "Tags", "UNCOMMON · FAIR 58%", UDim2.fromScale(0.03, 0.33), UDim2.fromScale(0.94, 0.25), 15, C.yellow)
	addText(secondCard, "Condition", "", UDim2.fromScale(0.03, 0.5), UDim2.fromScale(0.2, 0.1), 1, C.yellow)
	addText(secondCard, "Value", "$1.4K  →  EST. $2.85K", UDim2.fromScale(0.03, 0.62), UDim2.fromScale(0.94, 0.29), 16, C.green)
	local secondSeller, secondRoot = makeNPC(second, "SecondSeller", Vector3.new(39, 1.5, -23), Color3.fromRGB(132, 66, 92), "")
	prompt(secondRoot, "SecondSellerPrompt", "TALK", "BUY DESERT COUPE", 0)
	setVisible(second, false)

	local operations = Instance.new("Model")
	operations.Name = "Operations"
	operations.Parent = world
	local operationsPadIndex = 0
	local function operationsPad(name, padId, action, title, benefit, cost, previewPath, previewStyle)
		operationsPadIndex += 1
		local padX = 30 + (operationsPadIndex - 1) * 6
		local pad = makePart(operations, name, Vector3.new(5.2, 0.4, 7), CFrame.new(padX, 0.2, -14), C.ink, Enum.Material.SmoothPlastic, 0.03)
		pad:SetAttribute("PadId", padId)
		pad:SetAttribute("Action", action)
		pad:SetAttribute("Cost", cost)
		pad:SetAttribute("Title", title)
		pad:SetAttribute("Benefit", benefit)
		pad:SetAttribute("RequiredStage", 8)
		pad:SetAttribute("PreviewPath", previewPath)
		if previewStyle then pad:SetAttribute("PreviewStyle", previewStyle) end
		decoratePad(pad, action, title, cost, C.yellow)
		setVisible(pad, false)
		return pad
	end

	local appraisal = Instance.new("Model")
	appraisal.Name = "AppraisalPosition"
	appraisal.Parent = operations
	makePart(appraisal, "InspectionDeck", Vector3.new(10, 0.35, 6), CFrame.new(31, 0.2, 6), Color3.fromRGB(76, 79, 81), Enum.Material.DiamondPlate)
	makePart(appraisal, "ScannerPost", Vector3.new(0.8, 4.5, 0.8), CFrame.new(26.5, 2.3, 6), C.yellow, Enum.Material.Metal)
	sign(appraisal, "AppraisalSign", "APPRAISAL", CFrame.new(31, 4.5, 9.2), Vector3.new(9, 2.5, 0.5), C.ink)
	setVisible(appraisal, false)

	local carBuyer, carBuyerRoot = makeNPC(operations, "CarBuyer", Vector3.new(31, 1.5, 12), Color3.fromRGB(47, 91, 132), "")
	local buyerGui, buyerCard = billboard(carBuyerRoot, "StaffState", 220, 82, Vector3.new(0, 5.2, 0))
	buyerGui.MaxDistance = 18
	addText(buyerCard, "Role", "CAR BUYER · LV 1", UDim2.fromScale(0.06, 0.06), UDim2.fromScale(0.88, 0.4), 17, C.white)
	addText(buyerCard, "Progress", "ROUTINE ACQUISITIONS", UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.88, 0.36), 13, C.green)
	setVisible(carBuyer, false)

	local salesPosition = Instance.new("Model")
	salesPosition.Name = "SalesPosition"
	salesPosition.Parent = operations
	makePart(salesPosition, "SalesDesk", Vector3.new(7, 0.5, 3.2), CFrame.new(50, 2.7, 6), Color3.fromRGB(103, 75, 48), Enum.Material.WoodPlanks)
	makePart(salesPosition, "DeskBase", Vector3.new(5.5, 2.4, 1.1), CFrame.new(50, 1.35, 6), Color3.fromRGB(48, 51, 55), Enum.Material.Metal)
	sign(salesPosition, "SalesSign", "CARS FOR SALE", CFrame.new(50, 5.2, 9.2), Vector3.new(10, 3, 0.5), C.ink)
 for _,z in {2.8,9.2}do
  makePart(salesPosition,'ChairSeat',Vector3.new(2.4,.35,2),CFrame.new(50,1.6,z),Color3.fromRGB(60,100,94),Enum.Material.Wood)
  makePart(salesPosition,'ChairBack',Vector3.new(2.4,2.2,.3),CFrame.new(50,2.6,z+(z<6 and -1 or 1)),Color3.fromRGB(60,100,94),Enum.Material.Wood)
 end
	setVisible(salesPosition, false)

	local salesRep, salesRepRoot = makeNPC(operations, "SalesRep", Vector3.new(50, 1.5, 12), Color3.fromRGB(126, 78, 45), "")
	local salesGui, salesCard = billboard(salesRepRoot, "StaffState", 220, 82, Vector3.new(0, 5.2, 0))
	salesGui.MaxDistance = 18
	addText(salesCard, "Role", "SALES REP · LV 1", UDim2.fromScale(0.06, 0.06), UDim2.fromScale(0.88, 0.4), 17, C.white)
	addText(salesCard, "Progress", "ROUTINE SALES", UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.88, 0.36), 13, C.green)
	setVisible(salesRep, false)

	operationsPad("AppraisalPad", "AppraisalPosition", "BUILD", "APPRAISAL POSITION", "INSPECTS INCOMING CARS", Config.OperationsCosts.AppraisalPosition, "Operations.AppraisalPosition")
	operationsPad("CarBuyerPad", "CarBuyer", "HIRE", "CAR BUYER · LV 1", "BUYS ROUTINE CARS TO YOUR RULES", Config.OperationsCosts.CarBuyer, "Operations.CarBuyer", "Character")
	operationsPad("SalesPositionPad", "SalesPosition", "BUILD", "SALES POSITION", "CREATES A CUSTOMER HANDOFF", Config.OperationsCosts.SalesPosition, "Operations.SalesPosition")
	operationsPad("SalesRepPad", "SalesRep", "HIRE", "SALES REP · LV 1", "SELLS ROUTINE INVENTORY", Config.OperationsCosts.SalesRep, "Operations.SalesRep", "Character")

	local autoCar = makeCar(operations, "AutoRouteCar", Vector3.new(31, 0, -15), Color3.fromRGB(202, 132, 48))
	autoCar:SetAttribute("Route", "INTAKE > REPAIR > SALES")
	setVisible(autoCar, false)
	local routeMarkers = Instance.new("Folder")
	routeMarkers.Name = "RouteMarkers"
	routeMarkers.Parent = operations
	for name, position in pairs({
		Intake = Vector3.new(31, 0, -15),
		Repair = Vector3.new(5, 0, -5),
		Sales = Vector3.new(50, 0, 4),
	}) do
		local marker = makePart(routeMarkers, name, Vector3.new(1, 1, 1), CFrame.new(position), C.yellow, Enum.Material.Neon, 1)
		marker.CanCollide = false
		marker:SetAttribute("ShownCollision", false)
	end

	local garage = Instance.new("Model")
	garage.Name = "PersonalGarage"
	garage.Parent = world
	local claimPad = makePart(garage, "ClaimPad", Vector3.new(22, 0.4, 18), CFrame.new(69, 0.2, 3), C.ink, Enum.Material.SmoothPlastic, 0.03)
	claimPad:SetAttribute("PadId", "FirstPersonalCar")
	claimPad:SetAttribute("Action", "CLAIM")
	claimPad:SetAttribute("Cost", 0)
	claimPad:SetAttribute("Title", "PERSONAL COUPE")
	claimPad:SetAttribute("Benefit", "YOURS TO CUSTOMIZE")
	claimPad:SetAttribute("RequiredStage", 8)
	claimPad:SetAttribute("PreviewPath", "PersonalGarage.PersonalCar")
	decoratePad(claimPad, "CLAIM", "PERSONAL CAR", 0, C.yellow)
	prompt(claimPad, "ClaimCarPrompt", "HOLD TO CLAIM", "YOUR FIRST PERSONAL CAR", 0.55)
	claimPad.ClaimCarPrompt.Enabled = false
	sign(garage, "GarageSign", "PERSONAL GARAGE", CFrame.new(69, 7, 11.5), Vector3.new(17, 4, 1), C.ink)
	local personalCar, personalBody = makeCar(garage, "PersonalCar", Vector3.new(69, 0, 3), C.blue)
	prompt(personalBody, "CustomizePrompt", "CUSTOMIZE", "PERSONAL COUPE", 0)
	prompt(personalBody, "RareDrivePrompt", "DRIVE", "MYSTERY LEAD", 0)
	setVisible(personalCar, false)

	local finish = sign(world, "FinishGate", "PRIVATE LEAD\nROUTE", CFrame.new(77, 6, 37), Vector3.new(13, 7, 1), C.yellow)
	finish:SetAttribute("ShownCollision", false)

	WorldBuilder.BuildOpeningCinematic(world)
	WorldBuilder.BuildRareArrival(world)
	world:SetAttribute("BuiltVersion", "CoreUXPadProgressionV9")
	require(game.ServerStorage.SellCarsIntegrationWorld).Build(world)
	return world
end

return WorldBuilder


