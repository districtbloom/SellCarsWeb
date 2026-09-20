--!strict

-- How a dealer car looks and what you can interact with on it: the model itself, the
-- junk-to-repaired treatment, engine smoke while the engine is broken, repair prompts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local CarConditionVisuals = require(ReplicatedStorage.CarConditionVisuals)
local VehiclePaint = require(ReplicatedStorage.VehiclePaint)
local VehicleNeon = require(ReplicatedStorage.VehicleNeon)
local VehicleWindowTint = require(ReplicatedStorage.VehicleWindowTint)
local VehicleHeadlightLens = require(ReplicatedStorage.VehicleHeadlightLens)

local CarVisuals = {}

local BODY_DAMAGE_TEMPLATES: { [string]: boolean } = {
	Gblock = true,
	Rusty = true,
	Bavora = true,
	ChevroluxC10 = true,
	FierroRossa = true,
	Nissho = true,
	Wronkler = true,
}
local MISSING_LEFT_HEADLIGHT_TEMPLATES: { [string]: boolean } = {
	Rusty = true,
	Bavora = true,
	HondoCivixEK = true,
	ChevroluxC10 = true,
	Nissho = true,
}
local MISSING_BROKEN_FRONT_ASSEMBLY_TEMPLATES: { [string]: boolean } = {
	FierroRossa = true,
}

local function bodyDamageTemplate(templateId: any): boolean
	return typeof(templateId) == "string" and BODY_DAMAGE_TEMPLATES[templateId :: string] == true
end

type Parts = { [string]: boolean }

export type Wheel = { part: BasePart, offset: CFrame, front: boolean, axis: string, direction: number }

local function wheelSpinAxis(part: BasePart): string
	local authored = part:GetAttribute("SpinAxis")
	if typeof(authored) == "string" then
		local axis = string.upper(authored)
		if axis == "X" or axis == "Y" or axis == "Z" then
			return axis
		end
	end
	local size = part.Size
	if size.X <= size.Y and size.X <= size.Z then return "X" end
	if size.Y <= size.X and size.Y <= size.Z then return "Y" end
	return "Z"
end

local function wheelSpinDirection(offset: CFrame, axis: string): number
	local localAxis = if axis == "X" then Vector3.xAxis
		elseif axis == "Y" then Vector3.yAxis
		else Vector3.zAxis
	local carAxis = offset.Rotation:VectorToWorldSpace(localAxis)
	return if carAxis.X < 0 then -1 else 1
end

function CarVisuals.template(templateId: string)
	for _, car in DealerCarConfig.CARS do
		if car.id == templateId then
			return car
		end
	end
	return DealerCarConfig.CARS[1]
end

function CarVisuals.allPartsRepaired(parts: Parts): boolean
	for _, part in DealerCarConfig.PARTS do
		if parts[part.id] ~= true then
			return false
		end
	end
	return true
end

function CarVisuals.nextPartId(parts: Parts): string?
	for _, part in DealerCarConfig.PARTS do
		if parts[part.id] ~= true then
			return part.id
		end
	end
	return nil
end

function CarVisuals.partLabel(partId: string): string
	for _, part in DealerCarConfig.PARTS do
		if part.id == partId then
			return part.label
		end
	end
	return partId
end

-- A car carries its driver around inside the model, and no condition treatment may touch
-- that rig: recolouring a person is how a seller ends up looking like scrap metal.
-- Dirt shells live in _CarConditionVisuals and must keep their own brown grime color.
-- Repair restore and paint hue used to repaint DirtShell (the name contains "shell")
-- to the body/paint color, so a dirty Nissho looked freshly washed.
local function isConditionVisual(instance: Instance): boolean
	local current: Instance? = instance
	while current ~= nil do
		if current.Name == "_CarConditionVisuals" then
			return true
		end
		if current:IsA("BasePart")
			and (current.Name == "DirtShell" or current:GetAttribute("ConditionSurface") ~= nil)
		then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isBodywork(part: BasePart): boolean
	if isConditionVisual(part) then
		return false
	end
	local current: Instance? = part
	while current ~= nil do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") ~= nil then
			return false
		end
		current = current.Parent
	end
	return true
end

CarVisuals.isBodywork = isBodywork

local function bodyworkParts(model: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and isBodywork(descendant) then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function rememberColor(part: BasePart): Color3
	if part:GetAttribute("_DealerColor") == nil then
		part:SetAttribute("_DealerColor", part.Color:ToHex())
	end
	local hex = part:GetAttribute("_DealerColor")
	if typeof(hex) == "string" then
		local ok, color = pcall(Color3.fromHex, hex)
		if ok and typeof(color) == "Color3" then
			return color
		end
	end
	return part.Color
end

-- Dirt fades per repaired area, so progress reads on the car itself.
local function applyJunkLook(model: Model, parts: Parts)
	local bodyDone = parts.Body == true
	local wheelsDone = parts.Wheels == true
	for _, descendant in bodyworkParts(model) do
		local baseColor = rememberColor(descendant)
		local name = string.lower(descendant.Name)
		local isWheel = string.find(name, "wheel", 1, true) ~= nil or string.find(name, "tire", 1, true) ~= nil
		local dirty: number
		if isWheel then
			dirty = if wheelsDone then 0.15 else 1
		else
			dirty = if bodyDone then 0.25 else 1
		end
		local h, s, v = baseColor:ToHSV()
		descendant.Color = Color3.fromHSV(
			h,
			math.clamp(s * (1 - 0.55 * dirty), 0, 1),
			math.clamp(v * (1 - 0.35 * dirty), 0, 1)
		)
	end
end

local function applyRepairedLook(model: Model)
	for _, descendant in bodyworkParts(model) do
		descendant.Color = rememberColor(descendant)
	end
end

-- Lamps, glass and wheels sit at the very front of most templates, so "furthest forward"
-- on its own picks a headlight, and the plume then pours out of the light housing mostly
-- buried inside the bodywork. None of these is ever what an engine smokes through.
local function isSmokeHostCandidate(part: BasePart): boolean
	local name = string.lower(part.Name)
	for _, banned in { "light", "lamp", "glass", "window", "windscreen", "wheel", "tire", "tyre", "signal", "mirror", "plate" } do
		if string.find(name, banned, 1, true) ~= nil then
			return false
		end
	end
	return true
end

local function smokeHost(model: Model): BasePart?
	local parts = bodyworkParts(model)
	for _, descendant in parts do
		local name = string.lower(descendant.Name)
		if string.find(name, "hood", 1, true) or string.find(name, "engine", 1, true) or string.find(name, "bonnet", 1, true) then
			return descendant
		end
	end
	-- No named hood part: the biggest panel in the front half of the car. Going by volume
	-- keeps it on real bodywork rather than on a trim sliver that happens to poke forward.
	local pivot = model:GetPivot()
	local best: BasePart? = nil
	local bestVolume = -1
	for _, descendant in parts do
		if not isSmokeHostCandidate(descendant) then
			continue
		end
		local forward = (descendant.Position - pivot.Position):Dot(pivot.LookVector)
		if forward < 0 then
			continue
		end
		local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
		if volume > bestVolume then
			bestVolume = volume
			best = descendant
		end
	end
	return best or model.PrimaryPart
end

local function applyEngineSmoke(model: Model, engineRepaired: boolean)
	local existing = model:FindFirstChild("EngineSmoke", true)
	if engineRepaired then
		if existing ~= nil then
			existing:Destroy()
		end
		return
	end
	if existing ~= nil then
		return
	end

	local host = smokeHost(model)
	if host == nil then
		return
	end

	-- Place the plume against the CAR, not against whatever part happens to host it: over
	-- the nose and just clear of the roofline. Anchoring it to the host's own half-height
	-- buried it inside the body whenever the host turned out to be a small part.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local nose = boxCFrame * CFrame.new(0, boxSize.Y * 0.30, -boxSize.Z * 0.32)

	local attachment = Instance.new("Attachment")
	attachment.Name = "EngineSmoke"
	attachment.Position = host.CFrame:PointToObjectSpace(nose.Position)
	attachment.Parent = host

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 70, 70), Color3.fromRGB(140, 140, 140))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(0.35, 2.2),
		NumberSequenceKeypoint.new(1, 4.2),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(2.1, 3.2)
	smoke.Speed = NumberRange.new(2.0, 4.2)
	smoke.SpreadAngle = Vector2.new(42, 28)
	smoke.Rate = 40
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.RotSpeed = NumberRange.new(-40, 40)
	smoke.LightEmission = 0
	smoke.LockedToPart = false
	smoke.Parent = attachment
end

local WHEEL_ORDER = { "WheelFL", "WheelFR", "WheelRL", "WheelRR" }
local VALID_WHEEL_NAMES: { [string]: boolean } = {
	WheelFL = true,
	WheelFR = true,
	WheelRL = true,
	WheelRR = true,
}
local LOCAL_WHEEL_NAMES: { [string]: string } = {
	LF_Wheel = "WheelFL",
	RF_Wheel = "WheelFR",
	LR_Wheel = "WheelRL",
	RR_Wheel = "WheelRR",
}

local function stableMissingWheel(model: Model): string
	local existing = model:GetAttribute("DealerMissingWheel")
	if typeof(existing) == "string" and VALID_WHEEL_NAMES[existing] == true then
		return existing
	end
	local tutorialIndex = tonumber(model:GetAttribute("TutorialDealIndex")) or 0
	local selected: string
	if tutorialIndex > 0 then
		-- The authored tutorial diagnosis explicitly calls out the front-left wheel.
		selected = "WheelFL"
	else
		local seed = tostring(model:GetAttribute("DealerProxyId")
			or model:GetAttribute("TradeId")
			or model.Name)
		local hash = 0
		for index = 1, #seed do
			hash = (hash * 31 + (string.byte(seed, index) or 0)) % 2147483647
		end
		selected = WHEEL_ORDER[(hash % #WHEEL_ORDER) + 1]
	end
	model:SetAttribute("DealerMissingWheel", selected)
	return selected
end

local function resolvedMissingWheels(model: Model, requested: { string }?): ({ [string]: boolean }, { string })
	local requestedSet: { [string]: boolean } = {}
	if requested ~= nil then
		for _, corner in requested do
			if VALID_WHEEL_NAMES[corner] == true then
				requestedSet[corner] = true
			end
		end
	end
	local ordered: { string } = {}
	for _, corner in WHEEL_ORDER do
		if requestedSet[corner] == true then
			table.insert(ordered, corner)
		end
	end
	if #ordered == 0 then
		local encoded = model:GetAttribute("DealerMissingWheelCorners")
		if typeof(encoded) == "string" then
			for _, corner in WHEEL_ORDER do
				if string.find("," .. encoded .. ",", "," .. corner .. ",", 1, true) ~= nil then
					table.insert(ordered, corner)
				end
			end
		end
	end
	if #ordered == 0 then
		table.insert(ordered, stableMissingWheel(model))
	end
	local result: { [string]: boolean } = {}
	for _, corner in ordered do
		result[corner] = true
	end
	return result, ordered
end

local function wheelAssemblyName(model: Model, wheelsRoot: Instance?, part: BasePart): string?
	local localName = part:GetAttribute("WheelLocalName")
	if typeof(localName) == "string" and LOCAL_WHEEL_NAMES[localName] ~= nil then
		return LOCAL_WHEEL_NAMES[localName]
	end
	local cursor: Instance? = part
	while cursor ~= nil and cursor ~= model do
		if VALID_WHEEL_NAMES[cursor.Name] == true then
			return cursor.Name
		end
		if wheelsRoot ~= nil and cursor.Parent == wheelsRoot then
			break
		end
		cursor = cursor.Parent
	end
	return nil
end

local WHEEL_TILT_RADIANS = math.rad(2.4)
local WHEEL_PITCH_RADIANS = math.rad(1.8)

local function applyMissingWheel(model: Model, wheelsRepaired: boolean, requested: { string }?)
	local missingSet, missingOrder = resolvedMissingWheels(model, requested)
	local pitch = 0
	local roll = 0
	if not wheelsRepaired then
		for _, corner in missingOrder do
			local missingOnLeft = corner == "WheelFL" or corner == "WheelRL"
			local missingAtFront = corner == "WheelFL" or corner == "WheelFR"
			-- Every missing corner contributes its own drop. FL therefore lowers front-left,
			-- FR lowers front-right, both fronts pitch the whole nose, and a third rear-left
			-- wheel adds the matching rear/left component without inventing a centre pivot.
			roll += if missingOnLeft then WHEEL_TILT_RADIANS else -WHEEL_TILT_RADIANS
			pitch += if missingAtFront then -WHEEL_PITCH_RADIANS else WHEEL_PITCH_RADIANS
		end
	end
	local encoded = if not wheelsRepaired then table.concat(missingOrder, ",") else nil
	model:SetAttribute("DealerMissingWheelCorners", encoded)
	model:SetAttribute("DealerMissingWheelCount", if wheelsRepaired then 0 else #missingOrder)
	model:SetAttribute("DealerMissingWheelCorner", if not wheelsRepaired and #missingOrder == 1 then missingOrder[1] else nil)
	if not wheelsRepaired and #missingOrder == 1 then
		local selected = missingOrder[1]
		local missingOnLeft = selected == "WheelFL" or selected == "WheelRL"
		local missingAtFront = selected == "WheelFL" or selected == "WheelFR"
		model:SetAttribute("DealerMissingWheelSide", if missingOnLeft then "Left" else "Right")
		model:SetAttribute("DealerMissingWheelAxle", if missingAtFront then "Front" else "Rear")
	else
		model:SetAttribute("DealerMissingWheelSide", nil)
		model:SetAttribute("DealerMissingWheelAxle", nil)
	end
	model:SetAttribute("DealerConditionPitchRadians", pitch)
	model:SetAttribute("DealerConditionTiltRadians", roll)
	local wheelsRoot = model:FindFirstChild("Wheels", true)
	for _, descendant in model:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local wheelName = wheelAssemblyName(model, wheelsRoot, descendant)
		if wheelName == nil then
			continue
		end
		local original = descendant:GetAttribute("_DealerWheelTransparency")
		if typeof(original) ~= "number" then
			original = descendant.Transparency
			descendant:SetAttribute("_DealerWheelTransparency", original)
		end
		local hide = not wheelsRepaired and missingSet[wheelName] == true
		descendant.Transparency = if hide then 1 else original :: number
	end
	-- Dirt shells live under a shared condition folder rather than under WheelXX.
	CarConditionVisuals.setMissingWheels(model, encoded)
end

local function conditionTilt(model: Model): (number, number)
	local pitchValue = model:GetAttribute("DealerConditionPitchRadians")
	local rollValue = model:GetAttribute("DealerConditionTiltRadians")
	local pitch = if typeof(pitchValue) == "number" then pitchValue :: number else 0
	local roll = if typeof(rollValue) == "number" then rollValue :: number else 0
	return pitch, roll
end

function CarVisuals.conditionFrame(model: Model, uprightFrame: CFrame): CFrame
	local pitch, roll = conditionTilt(model)
	return uprightFrame * CFrame.Angles(pitch, 0, roll)
end

function CarVisuals.pivotToUprightFrame(model: Model, uprightFrame: CFrame)
	model:PivotTo(uprightFrame)
	-- PivotTo does not know whether its input already includes the condition rotation. Every
	-- caller supplying an explicitly upright frame must reset the pose tracker at the same time.
	model:SetAttribute("DealerAppliedPitchRadians", 0)
	model:SetAttribute("DealerAppliedTiltRadians", 0)
end

function CarVisuals.pivotToConditionFrame(model: Model, uprightFrame: CFrame)
	local pitch, roll = conditionTilt(model)
	model:PivotTo(uprightFrame * CFrame.Angles(pitch, 0, roll))
	model:SetAttribute("DealerAppliedPitchRadians", pitch)
	model:SetAttribute("DealerAppliedTiltRadians", roll)
end

local function clearConditionTilt(model: Model): CFrame
	local pivot = model:GetPivot()
	local appliedPitch = model:GetAttribute("DealerAppliedPitchRadians")
	local appliedRoll = model:GetAttribute("DealerAppliedTiltRadians")
	local pitch = if typeof(appliedPitch) == "number" then appliedPitch :: number else 0
	local roll = if typeof(appliedRoll) == "number" then appliedRoll :: number else 0
	if math.abs(pitch) > 0.00001 or math.abs(roll) > 0.00001 then
		pivot *= CFrame.Angles(pitch, 0, roll):Inverse()
		model:PivotTo(pivot)
	end
	model:SetAttribute("DealerAppliedPitchRadians", 0)
	model:SetAttribute("DealerAppliedTiltRadians", 0)
	return pivot
end

function CarVisuals.applyConditionTilt(model: Model)
	local upright = clearConditionTilt(model)
	CarVisuals.pivotToConditionFrame(model, upright)
end

local function applyBodyDamageHiddenParts(model: Model, bodyRepaired: boolean)
	local templateId = model:GetAttribute("TemplateId")
	if typeof(templateId) ~= "string" then
		return
	end
	local missingLeftHeadlight = MISSING_LEFT_HEADLIGHT_TEMPLATES[templateId :: string] == true or templateId == "Gblock"
	local missingFrontAssembly = MISSING_BROKEN_FRONT_ASSEMBLY_TEMPLATES[templateId :: string] == true
	if not missingLeftHeadlight and not missingFrontAssembly and templateId ~= "Gblock" then
		return
	end

	for _, descendant in model:GetDescendants() do
		local isBrokenPart = descendant:IsA("BasePart") and (
			(templateId == "Gblock" and (descendant.Name == "L_Headlight3" or descendant.Name == "LF_TurnSignal"))
			or
			(missingLeftHeadlight and (
				descendant.Name == "L_Headlight"
				or (templateId == "Bavora" and descendant.Name == "LF_TurnSignal")
				or (templateId == "HondoCivixEK" and descendant.Name == "L_Turn")
			))
			or (missingFrontAssembly and (
				descendant.Name == "FrontLights"
				or descendant.Name == "LF_TurnSignal"
				or descendant.Name == "RF_TurnSignal"
				or descendant.Name == "Front_LicensePlate"
			))
		)
		if not isBrokenPart then
			continue
		end

		local original = descendant:GetAttribute("_DealerDamageBodyPartTransparency")
		if typeof(original) ~= "number" then
			original = descendant.Transparency
			descendant:SetAttribute("_DealerDamageBodyPartTransparency", original)
		end
		descendant.Transparency = if bodyRepaired then original :: number else 1

		for _, child in descendant:GetDescendants() do
			if child:IsA("Light") or child:IsA("LayerCollector") then
				local toggle = child :: any
				local enabled = child:GetAttribute("_DealerDamageBodyPartEnabled")
				if typeof(enabled) ~= "boolean" then
					enabled = toggle.Enabled
					child:SetAttribute("_DealerDamageBodyPartEnabled", enabled)
				end
				toggle.Enabled = bodyRepaired and enabled == true
			end
		end
	end

	model:SetAttribute("DealerDamageLeftHeadlightMissing", missingLeftHeadlight and not bodyRepaired)
	model:SetAttribute(
		"DealerDamageLeftTurnSignalMissing",
		(templateId == "Bavora" or templateId == "HondoCivixEK" or templateId == "Gblock") and not bodyRepaired
	)
	model:SetAttribute("DealerDamageFrontAssemblyMissing", missingFrontAssembly and not bodyRepaired)
end

function CarVisuals.applyCondition(
	model: Model,
	parts: Parts,
	fullyRepaired: boolean,
	serviced: boolean?,
	washed: boolean?,
	missingWheels: { string }?
)
	-- Authored FBX damage is the single body-repair source of truth for every supported car.
	-- The same replicated amount drives EditableMesh, broken glass, dents and body dirt in
	-- queue traffic and on the repair pad.
	local templateId = model:GetAttribute("TemplateId")
	-- Factory application intentionally clears PaintHue. Preserve the already-rendered custom
	-- repaint before that base reset so state changes such as Listed -> Offer -> Sold cannot
	-- turn a blue car back into its yellow/red factory swatch.
	local savedPaintHue = model:GetAttribute("PaintHue")
	-- Preserve the first visible queue swatch across every later condition refresh and rebuilt
	-- service/display proxy. Legacy/new cars without a captured id still use stable identity.
	local factoryPaintId = model:GetAttribute("FactoryPaintId")
	if VehiclePaint.applyFactoryId(model, templateId, factoryPaintId) == nil then
		VehiclePaint.applyFactoryForModel(model)
	end
	if bodyDamageTemplate(templateId) then
		local profileId = if templateId == "Rusty" then "Rusty" else templateId :: string
		model:SetAttribute("DamageProfile", profileId)
		model:SetAttribute("ConditionBodyShellDisabled", true)
		model:SetAttribute("BrokenAmount", if parts.Body == true then 0 else 1)
		model:AddTag("CarBodyDamageMorph")
	end

	if fullyRepaired then
		applyRepairedLook(model)
	else
		applyJunkLook(model, parts)
	end
	applyEngineSmoke(model, parts.Engine == true)
	-- Roadworthy JunkSpot repairs and business services are independent: the engine can stop
	-- smoking while an external oil leak and road grime remain until their respective bays.
	CarConditionVisuals.apply(model, {
		dirty = washed ~= true,
		oilLeak = serviced ~= true,
	})
	-- DealerCar can refresh condition on an existing displayed model. Repaired-look
	-- restoration uses authored colors, so reapply every already-installed cosmetic last.
	VehiclePaint.applyFinal(model, if typeof(savedPaintHue) == "number" then savedPaintHue else nil)
	VehicleNeon.applyFinal(model, model.Name, model:GetAttribute("NeonColorId"))
	VehicleWindowTint.applyFinal(model, model:GetAttribute("WindowTinted") == true)

	-- Supported damaged bodies hide authored lamp assemblies until Body is repaired.
	-- FierroRossa loses both front lamps, both front turn-signal blocks and the front plate
	-- because the broken nose no longer supports them; authored state returns on repair.
	applyBodyDamageHiddenParts(model, parts.Body == true)
	-- Wheel assemblies stay physically present for traffic/rig stability, while the authored
	-- arrival condition controls which one, two, or three corners are visually absent.
	applyMissingWheel(model, parts.Wheels == true, missingWheels)
	CarVisuals.applyConditionTilt(model)
	-- A queue proxy carries this exact treatment into W. DealerCar can use the stamp to
	-- avoid tearing down/rebuilding visual children when only ownership changes.
	model:SetAttribute("DealerConditionBody", parts.Body == true)
	model:SetAttribute("DealerConditionWheels", parts.Wheels == true)
	model:SetAttribute("DealerConditionEngine", parts.Engine == true)
	model:SetAttribute("DealerConditionRepaired", fullyRepaired)
	model:SetAttribute("DealerConditionServiced", serviced == true)
	model:SetAttribute("DealerConditionWashed", washed == true)
end

local function isPaintableBodyPart(part: BasePart): boolean
	return not isConditionVisual(part) and VehiclePaint.isPaintable(part)
end

-- MeshPart.Color multiplies the authored ColorMap, preserving panel/rust-free texture detail
-- while changing its HSL-family hue. Lamps, glass, wheels and trim retain their authored colors.
function CarVisuals.applyPaintHue(model: Model, hue: number?)
	VehiclePaint.applyFinal(model, hue)
end

function CarVisuals.applyNeon(model: Model, modelName: string, colorId: unknown)
	VehicleNeon.applyFinal(model, modelName, colorId)
end

function CarVisuals.applyWindowTint(model: Model, enabled: boolean)
	VehicleWindowTint.applyFinal(model, enabled)
end

local function isRunningLightPart(part: BasePart): boolean
	return VehicleHeadlightLens.isFrontLens(part)
end

-- A parked front lens mirrors full optical-black tint: SmoothPlastic supplies a
-- controlled material highlight, while very low reflectance prevents the bright desert sky
-- from washing the switched-off lamp back to grey. Turn/brake lamps stay separate.

-- Rear markers. A moving car with dead tail lamps reads as switched off from behind, so
-- these glow dimly whenever the car is running. They are not stop lamps: no light source
-- is attached and the colour stays well under the braking red.
local REAR_MARKER_DIM = 0.42
local REAR_MARKER_COLOR = Color3.fromRGB(255, 40, 30)

local function isRearMarkerPart(part: BasePart): boolean
	local name = string.lower(part.Name)
	return string.find(name, "taillight", 1, true) ~= nil
		or string.find(name, "backlight", 1, true) ~= nil
		or string.find(name, "rearlight", 1, true) ~= nil
		or string.find(name, "brakelight", 1, true) ~= nil
		or string.find(name, "stoplight", 1, true) ~= nil
		or string.find(name, "stopsignal", 1, true) ~= nil
end

-- Traffic templates carry their daytime lights in the lit state. Dealer cars keep that
-- state while moving, but a parked car on the repair slab must read as switched off.
function CarVisuals.setRunningLights(model: Model, enabled: boolean)
	for _, part in bodyworkParts(model) do
		if isRearMarkerPart(part) then
			local savedRear = part:GetAttribute("_DealerRearColor")
			if typeof(savedRear) ~= "Color3" then
				savedRear = part.Color
				part:SetAttribute("_DealerRearColor", savedRear)
				part:SetAttribute("_DealerRearMaterial", part.Material.Name)
			end
			if enabled then
				part.Color = REAR_MARKER_COLOR:Lerp(Color3.new(0, 0, 0), REAR_MARKER_DIM)
				part.Material = Enum.Material.Neon
			else
				part.Color = savedRear :: Color3
				local restMaterial = part:GetAttribute("_DealerRearMaterial")
				if typeof(restMaterial) == "string" then
					local material = Enum.Material[restMaterial]
					if material ~= nil then
						part.Material = material
					end
				end
			end
			continue
		end
		if not isRunningLightPart(part) then
			continue
		end
		local savedColor = part:GetAttribute("_DealerRunningColor")
		if typeof(savedColor) ~= "Color3" then
			savedColor = part.Color
			part:SetAttribute("_DealerRunningColor", savedColor)
			part:SetAttribute("_DealerRunningMaterial", part.Material.Name)
		end
		local savedReflectance = part:GetAttribute("_DealerRunningReflectance")
		if typeof(savedReflectance) ~= "number" then
			savedReflectance = part.Reflectance
			part:SetAttribute("_DealerRunningReflectance", savedReflectance)
		end
		if enabled then
			part.Color = savedColor :: Color3
			local materialName = part:GetAttribute("_DealerRunningMaterial")
			if typeof(materialName) == "string" then
				local material = Enum.Material[materialName]
				if material ~= nil then
					part.Material = material
				end
			end
			part.Reflectance = savedReflectance :: number
			VehicleHeadlightLens.markOn(part)
		else
			VehicleHeadlightLens.applyOff(part)
		end
		for _, descendant in part:GetDescendants() do
			if descendant:IsA("Light") then
				local wasEnabled = descendant:GetAttribute("_DealerRunningEnabled")
				if typeof(wasEnabled) ~= "boolean" then
					wasEnabled = descendant.Enabled
					descendant:SetAttribute("_DealerRunningEnabled", wasEnabled)
				end
				descendant.Enabled = enabled and wasEnabled == true
			end
		end
	end
end

function CarVisuals.lockDealerDriving(model: Model)
	model:SetAttribute("DealerDriveLocked", true)
	model:SetAttribute("VehicleRuntimeActive", false)
	model:SetAttribute("owner", nil)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			if descendant:IsA("VehicleSeat") then
				descendant.Transparency = 1
				descendant.CastShadow = false
			end
			descendant.CanTouch = false
			descendant.Disabled = true
			local occupant = descendant.Occupant
			if occupant ~= nil then
				occupant.Sit = false
			end
		elseif descendant:IsA("ProximityPrompt")
			and (descendant.Name == "DrivePrompt" or descendant.Name == "GetInToListPrompt")
		then
			descendant.Enabled = false
		end
	end
end

-- Spawns the car model for a template. The identity of the car never changes with
-- repair state; only its condition treatment does.
function CarVisuals.spawn(templateId: string, pivot: CFrame, parent: Instance): Model?
	local traffic = ReplicatedStorage:FindFirstChild("TrafficCars")
	local template = CarVisuals.template(templateId)
	local rigFolder = ServerStorage:FindFirstChild("CarModels")
	local rigSource = if rigFolder ~= nil then rigFolder:FindFirstChild(template.model) else nil
	local fullRig = rigSource ~= nil and rigSource:IsA("Model")
	local source = if fullRig
		then rigSource
		else if traffic ~= nil
			then traffic:FindFirstChild(template.model)
				or traffic:FindFirstChild("RustyCar")
				or traffic:FindFirstChildWhichIsA("Model")
			else nil
	if source == nil or not source:IsA("Model") then
		warn("[CarVisuals] no car template model")
		return nil
	end

	local clone = source:Clone()
	clone.Name = "DealerCar"
	clone:SetAttribute("TemplateId", templateId)
	clone:SetAttribute("DealerFullRig", fullRig)
	clone:SetAttribute("DealerNitroDisabled", true)
	clone:SetAttribute("DealerDriveLocked", true)
	if fullRig then
		clone:AddTag("Car")
		clone:AddTag("ManagedVehicle")
		clone:SetAttribute("VehicleProfileId", source.Name)
		-- Queue/service presentation owns the anchored model until restoreDriveRig promotes it.
		clone:SetAttribute("VehicleRuntimeActive", false)
	end
	local inputs = clone:FindFirstChild("Inputs")
	if inputs ~= nil then
		inputs:SetAttribute("nitroInput", false)
	end
	local engine = clone:FindFirstChild("Engine")
	if engine ~= nil then
		local normalSpeed = engine:GetAttribute("forwardMaxSpeed")
		local normalAcceleration = engine:GetAttribute("acceleration")
		local normalTorque = engine:GetAttribute("minSpeedTorque")
		if typeof(normalSpeed) == "number" then
			engine:SetAttribute("nitroMaxSpeed", normalSpeed)
		end
		if typeof(normalAcceleration) == "number" then
			engine:SetAttribute("nitroAcceleration", normalAcceleration)
		end
		if typeof(normalTorque) == "number" then
			engine:SetAttribute("nitroTorque", normalTorque)
		end
		engine:SetAttribute("_nitro", 0)
		engine:SetAttribute("_nitroEnabled", false)
		local velocity = engine:FindFirstChild("NitroVelocity")
		if velocity ~= nil and velocity:IsA("LinearVelocity") then
			velocity.Enabled = false
		end
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("GuiObject")
			and (descendant.Name == "NitroFrame" or descendant.Name == "NitroButton")
		then
			descendant.Visible = false
		end
	end
	clone:PivotTo(pivot)
	if clone.PrimaryPart == nil then
		local any = clone:FindFirstChildWhichIsA("BasePart", true)
		if any ~= nil and any:IsA("BasePart") then
			clone.PrimaryPart = any
		end
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if not fullRig then
				descendant.CanCollide = false
			elseif descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
				if descendant:IsA("VehicleSeat") then
					descendant.Transparency = 1
					descendant.CastShadow = false
				end
				-- Dealer stock is never enterable merely because its authored rig has a seat.
				-- ListingTransport is the only owner allowed to unlock the exact Ready car.
				descendant.CanTouch = false
				descendant.Disabled = true
			end
		elseif descendant:IsA("ProximityPrompt") then
			if fullRig then
				descendant.Enabled = false
			else
				descendant:Destroy()
			end
		elseif not fullRig and (descendant:IsA("VehicleSeat") or descendant:IsA("Seat")) then
			descendant:Destroy()
		end
	end
	CarVisuals.lockDealerDriving(clone)
	clone.Parent = parent
	return clone
end

-- Rough car-space seat from the template attribute. LotNpc.seat fits the Y under the
-- roof after the driver exists, because every avatar has a different head height.
function CarVisuals.driverSeat(model: Model, _headroom: number?): CFrame
	local actualSeat = model:FindFirstChild("DriverSeat", true)
	if actualSeat ~= nil and actualSeat:IsA("BasePart") then
		return model:GetPivot():ToObjectSpace(actualSeat.CFrame)
	end
	local seat = model:GetAttribute("SeatOffset")
	if typeof(seat) == "CFrame" then
		local base = seat :: CFrame
		return CFrame.new(base.Position.X, base.Position.Y, base.Position.Z)
	end
	return CFrame.new(-1.15, 0, 0.6)
end

-- Drops the model until its lowest point rests on the given surface. Every car template
-- has a different ride height, so a shared constant always leaves one of them hovering.
function CarVisuals.settle(model: Model, groundY: number, clearance: number): CFrame
	clearConditionTilt(model)
	local pivot = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local lowest = boxCFrame.Position.Y - boxSize.Y * 0.5
	local settled = pivot + Vector3.new(0, (groundY + clearance) - lowest, 0)
	CarVisuals.pivotToConditionFrame(model, settled)
	return model:GetPivot()
end

function CarVisuals.visibleTirePivotClearance(model: Model): number
	local pivot = model:GetPivot()
	if model:GetAttribute("DealerFullRig") == true then
		local lowestTire = math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				local half = descendant.Size * 0.5
				local frame = descendant.CFrame
				local verticalHalf = math.abs(frame.RightVector.Y) * half.X
					+ math.abs(frame.UpVector.Y) * half.Y
					+ math.abs(frame.LookVector.Y) * half.Z
				lowestTire = math.min(lowestTire, descendant.Position.Y - verticalHalf)
			end
		end
		if lowestTire < math.huge then
			return math.max(0, pivot.Position.Y - lowestTire)
		end
	end
	local boxCFrame, boxSize = model:GetBoundingBox()
	return math.max(0, pivot.Position.Y - (boxCFrame.Position.Y - boxSize.Y * 0.5))
end

-- Display parking uses the visible tyre tread as the contact point. Full rigs contain
-- suspension helpers and a slightly oversized invisible wheel collider; using the whole
-- model bounding box leaves the tyre visibly hovering above P1.
local function visibleWheelLowest(model: Model): number?
	local wheelsRoot = model:FindFirstChild("Wheels", true)
	if wheelsRoot == nil then
		return nil
	end
	local lowest = math.huge
	for _, descendant in wheelsRoot:GetDescendants() do
		if not descendant:IsA("BasePart") or descendant.Transparency >= 0.95 then
			continue
		end
		local half = descendant.Size * 0.5
		local frame = descendant.CFrame
		local verticalHalf = math.abs(frame.RightVector.Y) * half.X
			+ math.abs(frame.UpVector.Y) * half.Y
			+ math.abs(frame.LookVector.Y) * half.Z
		lowest = math.min(lowest, descendant.Position.Y - verticalHalf)
	end
	return if lowest < math.huge then lowest else nil
end

function CarVisuals.settleOnVisibleTires(model: Model, groundY: number, clearance: number?): CFrame
	local resolvedClearance = clearance or 0
	clearConditionTilt(model)
	local lowest = visibleWheelLowest(model)
	if lowest == nil then
		return CarVisuals.settle(model, groundY, resolvedClearance)
	end
	local upright = model:GetPivot() + Vector3.new(0, (groundY + resolvedClearance) - lowest, 0)
	CarVisuals.pivotToConditionFrame(model, upright)

	-- Roll around the chassis centre, then lift just enough that the three remaining visible
	-- wheels stay on the slab. This makes the missing side sag without burying the other tyre.
	local tiltedLowest = visibleWheelLowest(model)
	if tiltedLowest ~= nil then
		model:PivotTo(model:GetPivot() + Vector3.new(0, (groundY + resolvedClearance) - tiltedLowest, 0))
	end
	return model:GetPivot()
end

-- Wheels in car space. The front axle is the one the steering shows on, and LookVector
-- runs down local -Z, so the front wheels are the ones with a negative Z offset.
-- Capture while the car is still straight - after a steered drive these relatives are wrong.
function CarVisuals.wheels(model: Model): { Wheel }
	local folder = model:FindFirstChild("Wheels")
	if folder == nil then
		return {}
	end
	local pivot = model:GetPivot()
	local result: { Wheel } = {}
	-- Lightweight TrafficCars keep four visible wheels directly under Wheels, while full
	-- dealer rigs nest the visible Tire part inside WheelXX/Tire. Traverse both layouts and
	-- ignore invisible suspension/collision carriers.
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 0.95 then
			local offset = pivot:ToObjectSpace(part.CFrame)
			local axis = wheelSpinAxis(part)
			table.insert(result, {
				part = part,
				offset = offset,
				front = offset.Position.Z < 0,
				axis = axis,
				direction = wheelSpinDirection(offset, axis),
			})
		end
	end
	return result
end

-- Same pose math TrafficClient uses every PreRender: front wheels steer, all wheels spin.
function CarVisuals.applyWheels(frame: CFrame, wheels: { Wheel }, steer: number, spin: number)
	for _, wheel in wheels do
		if wheel.part.Parent == nil then
			continue
		end
		local rotation: CFrame
		local signedSpin = spin * wheel.direction
		if wheel.axis == "X" then
			rotation = CFrame.Angles(signedSpin, 0, 0)
		elseif wheel.axis == "Y" then
			rotation = CFrame.Angles(0, signedSpin, 0)
		else
			rotation = CFrame.Angles(0, 0, signedSpin)
		end
		if wheel.front then
			wheel.part.CFrame = frame
				* CFrame.new(wheel.offset.Position)
				* CFrame.Angles(0, steer, 0)
				* wheel.offset.Rotation
				* rotation
		else
			wheel.part.CFrame = frame * wheel.offset * rotation
		end
	end
end

-- Straighten after a drive so PivotTo(parked) does not bake the last steer angle in.
function CarVisuals.resetWheels(model: Model, wheels: { Wheel }?)
	local list = wheels or CarVisuals.wheels(model)
	CarVisuals.applyWheels(model:GetPivot(), list, 0, 0)
end

local function formatMoney(value: number): string
	local raw = tostring(math.max(0, math.floor(value)))
	local grouped = raw:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. grouped
end

-- Bold, world-space value readout. It lives on the car so repairs update where the
-- player is already looking instead of being buried in the phone.
function CarVisuals.setValueBillboard(
	model: Model,
	carName: string,
	currentValue: number,
	repairGain: number,
	enabled: boolean,
	initialValue: number?,
	soldPrice: number?
)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BillboardGui") and descendant.Name == "DealerValueBillboard" then
			descendant:Destroy()
		end
	end
	local host = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if host == nil or not host:IsA("BasePart") then
		return
	end
	local boxFrame, boxSize = model:GetBoundingBox()
	local height = math.max(4.5, boxFrame.Position.Y + boxSize.Y * 0.5 - host.Position.Y + 2.6)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DealerValueBillboard"
	billboard.Adornee = host
	billboard.Size = UDim2.fromOffset(280, 112)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 130
	billboard.Enabled = enabled
	billboard.Parent = host

	-- Keep the value stack open to the world: gradients, type hierarchy and strokes
	-- provide contrast without a panel obscuring the car behind it.
	local function line(name: string, text: string, y: number, heightPixels: number, color: Color3, size: number)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Position = UDim2.fromOffset(0, y)
		label.Size = UDim2.new(1, 0, 0, heightPixels)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Color3.fromRGB(5, 7, 10)
		label.TextStrokeTransparency = 0.18
		label.Font = if name == "RepairGain" then Enum.Font.GothamSemibold else Enum.Font.GothamBold
		label.TextSize = size
		label.TextWrapped = false
		label.ZIndex = 3
		label.Parent = billboard
		local labelGradient = Instance.new("UIGradient")
		labelGradient.Name = "TextGradient"
		labelGradient.Color = ColorSequence.new(
			color:Lerp(Color3.new(1, 1, 1), 0.22),
			color:Lerp(Color3.new(0, 0, 0), 0.12)
		)
		labelGradient.Rotation = 90
		labelGradient.Parent = label
	end

	-- Three lines, three jobs, so three colours. The name used to share plain white with
	-- the price directly under it, which read as one block of text; amber separates the
	-- identity of the car from what it is worth without competing with the green gain line.
	line("CarName", string.upper(carName), 0, 34, Color3.fromRGB(255, 196, 64), 28)
	if typeof(soldPrice) == "number" then
		line("SoldLabel", "SOLD", 31, 43, Color3.fromRGB(76, 255, 108), 34)
		line("SoldPrice", formatMoney(soldPrice), 73, 29, Color3.fromRGB(255, 255, 255), 24)
	else
		line("CurrentValue", formatMoney(initialValue or currentValue) .. " VALUE", 31, 43, Color3.fromRGB(255, 255, 255), 34)
		line(
			"RepairGain",
			if repairGain > 0 then "+" .. formatMoney(repairGain) .. " FROM REPAIRS" else "REPAIR IT TO RAISE VALUE",
			73,
			29,
			if repairGain > 0 then Color3.fromRGB(76, 255, 108) else Color3.fromRGB(220, 224, 230),
			19
		)
	end
end

function CarVisuals.setSoldBillboard(model: Model, carName: string, soldPrice: number)
	CarVisuals.setValueBillboard(model, carName, soldPrice, 0, true, nil, soldPrice)
end

function CarVisuals.setValueBillboardEnabled(model: Model, enabled: boolean)
	local billboard = model:FindFirstChild("DealerValueBillboard", true)
	if billboard ~= nil and billboard:IsA("BillboardGui") then
		billboard.Enabled = enabled
	end
end

function CarVisuals.clearPrompts(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			if descendant.Name == "DrivePrompt" then
				descendant.Enabled = false
			else
				descendant:Destroy()
			end
		end
	end
end

local function carBounds(model: Model): (Vector3, Vector3)
	local pivot = model:GetPivot()
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in bodyworkParts(model) do
		local half = part.Size * 0.5
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					local corner = pivot:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z)))
					minimum = Vector3.new(
						math.min(minimum.X, corner.X),
						math.min(minimum.Y, corner.Y),
						math.min(minimum.Z, corner.Z)
					)
					maximum = Vector3.new(
						math.max(maximum.X, corner.X),
						math.max(maximum.Y, corner.Y),
						math.max(maximum.Z, corner.Z)
					)
				end
			end
		end
	end
	if minimum.X == math.huge then
		return Vector3.zero, Vector3.new(8, 5, 15)
	end
	return (minimum + maximum) * 0.5, maximum - minimum
end

-- Each job should happen where that system lives on the car. The car templates share
-- local -Z as their front, but differ enough in size that fixed world offsets drift.
local function repairPoint(model: Model, partId: string): Vector3
	local pivot = model:GetPivot()
	local boundsCenter, boundsSize = carBounds(model)
	local wheelsFolder = model:FindFirstChild("Wheels")
	local rightFrontWheel: BasePart? = nil
	local bestX = -math.huge
	local bestZ = math.huge
	local frontAxleZ = math.huge

	if wheelsFolder ~= nil then
		for _, child in wheelsFolder:GetChildren() do
			if child:IsA("BasePart") then
				local localPosition = pivot:PointToObjectSpace(child.Position)
				frontAxleZ = math.min(frontAxleZ, localPosition.Z)
				if localPosition.X > bestX + 0.05
					or (math.abs(localPosition.X - bestX) <= 0.05 and localPosition.Z < bestZ)
				then
					rightFrontWheel = child
					bestX = localPosition.X
					bestZ = localPosition.Z
				end
			end
		end
	end

	if partId == "Wheels" and rightFrontWheel ~= nil then
		-- Slightly outside and above the tyre, so the prompt does not sit inside the mesh.
		return rightFrontWheel.Position + pivot.RightVector * 0.65 + Vector3.new(0, 0.35, 0)
	end

	if partId == "Engine" then
		local frontEdgeZ = boundsCenter.Z - boundsSize.Z * 0.5
		-- Keep the engine target inside the hood, behind the nose and front lamps.
		local hoodZ = frontEdgeZ + boundsSize.Z * 0.28
		local hoodY = math.clamp(boundsCenter.Y + boundsSize.Y * 0.12, 1.2, 2.4)
		return pivot:PointToWorldSpace(Vector3.new(boundsCenter.X, hoodY, hoodZ))
	end

	-- Body work is presented on the passenger side, around the middle of the panels.
	local bodyPoint = Vector3.new(
		boundsCenter.X + boundsSize.X * 0.5 + 0.35,
		math.clamp(boundsCenter.Y, 1, 1.8),
		boundsCenter.Z
	)
	return pivot:PointToWorldSpace(bodyPoint)
end

function CarVisuals.attachRepairPrompt(
	model: Model,
	partId: string,
	objectText: string,
	holdDuration: number,
	onTrigger: (Player) -> (),
	onHoldBegan: ((Player) -> ())?,
	onHoldEnded: ((Player) -> ())?
)
	local host = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if host == nil or not host:IsA("BasePart") then
		return
	end

	local oldAnchor = host:FindFirstChild("RepairPromptAnchor")
	if oldAnchor ~= nil then
		oldAnchor:Destroy()
	end
	local oldEngineMarker = model:FindFirstChild("RepairEngineMarker", true)
	if oldEngineMarker ~= nil then
		oldEngineMarker:Destroy()
	end

	local point = repairPoint(model, partId)
	local anchor = Instance.new("Attachment")
	anchor.Name = "RepairPromptAnchor"
	anchor.Position = host.CFrame:PointToObjectSpace(point)
	anchor:SetAttribute("PartId", partId)
	anchor.Parent = host

	if partId == "Engine" then
		local _, boundsSize = carBounds(model)
		local marker = Instance.new("Part")
		marker.Name = "RepairEngineMarker"
		marker.Size = Vector3.new(
			math.clamp(boundsSize.X * 0.26, 1.4, 2.6),
			0.06,
			math.clamp(boundsSize.Z * 0.09, 1.1, 1.8)
		)
		marker.CFrame = CFrame.new(point + Vector3.new(0, 0.2, 0)) * model:GetPivot().Rotation
		-- The marker is geometry only for the temporary outline; it must never read as a visible engine block.
		marker.Color = Color3.new(1, 1, 1)
		marker.Material = Enum.Material.SmoothPlastic
		marker.Transparency = 1
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.CastShadow = false
		marker:SetAttribute("PartId", "Engine")
		marker.Parent = model
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = DealerCarConfig.REPAIR_PROMPT_NAME
	prompt.ActionText = "Repair " .. CarVisuals.partLabel(partId)
	prompt.ObjectText = objectText
	prompt.HoldDuration = math.max(0.2, holdDuration)
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("PartId", partId)
	prompt.Parent = anchor
	if onHoldBegan ~= nil then
		prompt.PromptButtonHoldBegan:Connect(onHoldBegan)
	end
	if onHoldEnded ~= nil then
		prompt.PromptButtonHoldEnded:Connect(onHoldEnded)
	end
	prompt.Triggered:Connect(onTrigger)
end

return CarVisuals
