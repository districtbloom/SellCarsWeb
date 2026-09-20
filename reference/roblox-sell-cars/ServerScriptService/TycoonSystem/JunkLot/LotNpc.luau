--!strict

-- Everyone who shows up on a junk lot: the seller who brings a car in, whoever sits
-- behind the wheel while it drives, and the staff the pads unlock. Placing a rig by hand
-- leaves it grey and hovering, so appearance, footing and animation all live here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local TownsfolkConfig = require(ReplicatedStorage:WaitForChild("TownsfolkConfig"))
local JuiceAnimations = require(ReplicatedStorage:WaitForChild("JuiceAnimations"))
local NPCSeatFit = require(ReplicatedStorage:WaitForChild("NPCSeatFit"))
local RuntimeFlags = require(ReplicatedStorage.Shared.Config.RuntimeFlags)
local NpcAnimationController = require(ServerScriptService.Systems.NPC.NpcAnimationController)

local LotNpc = {}

-- Real accounts, so a seller turns up dressed instead of as a grey mannequin.
local LOOK_USER_IDS = { 1, 156, 261, 1122, 2032622, 13365322, 1345737, 91380101 }

local ANIMATION_IDS: { [string]: string } = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://913402848",
	work = "rbxassetid://507770453",
	-- R15 sit - used as a kneel/crouch at the wheel so repairs don't look like a standing tool swing.
	kneel = "rbxassetid://507771019",
	cheer = JuiceAnimations.cheer.id,
	drive = "rbxassetid://15570378042",
	-- One verb per job so three repairs never read as the same hold three times.
	repairBody = JuiceAnimations.repairBody.id,
	repairWheels = JuiceAnimations.repairWheels.id,
	repairEngine = JuiceAnimations.repairEngine.id,
	computer = JuiceAnimations.repairEngine.id,
	customerEnergized = "rbxassetid://112387112633214",
}

-- The named cast are authored R6 rigs, and R15 animation assets simply do not load on
-- them, so a townsperson would stand frozen using the table above.
local ANIMATION_IDS_R6: { [string]: string } = {
	idle = "rbxassetid://180435571",
	walk = "rbxassetid://180426354",
	work = "rbxassetid://182491770",
	kneel = "rbxassetid://178130996",
	cheer = "rbxassetid://129423131",
	drive = "rbxassetid://178130996",
	-- The cast rigs are R6 and cannot play the R15 juice clips, so the named verbs fall
	-- back to the generic holds rather than leaving them frozen.
	repairBody = "rbxassetid://182491770",
	repairWheels = "rbxassetid://178130996",
	repairEngine = "rbxassetid://182491770",
	computer = "rbxassetid://182491770",
}

local function isR6(rig: Model): boolean
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R6
end

-- The named townsfolk are R6. Roblox's legacy sit asset is not guaranteed to evaluate on
-- a server-owned, anchored queue rig, so preserve its exact keyframe as a deterministic
-- fallback before the limbs are frozen to the car.
local R6_DRIVE_TRANSFORMS: { [string]: CFrame } = {
	-- R6 limbs are one solid piece. A shallow forward/down pose keeps both legs visible in
	-- the footwell and the hands near the wheel instead of hiding legs sideways in the body.
	["Left Hip"] = CFrame.Angles(math.rad(-32), 0, math.rad(-8)),
	["Right Hip"] = CFrame.Angles(math.rad(-32), 0, math.rad(8)),
	["Left Shoulder"] = CFrame.Angles(math.rad(-28), 0, math.rad(-24)),
	["Right Shoulder"] = CFrame.Angles(math.rad(-28), 0, math.rad(24)),
}
local neutralR6JointC0: { [Model]: { [Motor6D]: CFrame } } = setmetatable({}, { __mode = "k" })
local seatGeneration: { [Model]: number } = setmetatable({}, { __mode = "k" })
local rideGeneration: { [Model]: number } = setmetatable({}, { __mode = "k" })

local function captureR6NeutralPose(rig: Model)
	if not isR6(rig) or neutralR6JointC0[rig] ~= nil then
		return
	end
	local pose: { [Motor6D]: CFrame } = {}
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("Motor6D") then
			pose[descendant] = descendant.C0
		end
	end
	neutralR6JointC0[rig] = pose
end

local function settleR6MotorChain(rig: Model, joints: { Motor6D })
	local root = rig:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local positioned: { [BasePart]: boolean } = { [root] = true }
	for _ = 1, #joints do
		local changed = false
		for _, joint in joints do
			local part0 = joint.Part0
			local part1 = joint.Part1
			if part0 ~= nil
				and part1 ~= nil
				and positioned[part0] == true
				and positioned[part1] ~= true
			then
				part1.CFrame = part0.CFrame * joint.C0 * joint.C1:Inverse()
				positioned[part1] = true
				changed = true
			end
		end
		if not changed then
			break
		end
	end
end

local function setR6DrivePose(rig: Model, enabled: boolean)
	if not isR6(rig) then
		return
	end
	captureR6NeutralPose(rig)
	local pose = neutralR6JointC0[rig]
	if pose == nil then
		return
	end
	local joints: { Motor6D } = {}
	for joint, original in pose do
		if joint.Parent ~= nil and joint:IsDescendantOf(rig) then
			joint.Transform = CFrame.identity
			local seated = R6_DRIVE_TRANSFORMS[joint.Name]
			joint.C0 = if enabled and seated ~= nil then original * seated else original
			table.insert(joints, joint)
		end
	end
	-- Rebuild from HRP -> Torso -> limbs in graph order. Restoring only hips/shoulders
	-- leaves a stale RootJoint drive frame visible as a crouched seller after reparenting.
	settleR6MotorChain(rig, joints)
end

local SHIRT_COLORS = {
	Color3.fromRGB(196, 40, 28),
	Color3.fromRGB(13, 105, 172),
	Color3.fromRGB(75, 151, 75),
	Color3.fromRGB(218, 134, 122),
	Color3.fromRGB(245, 205, 48),
	Color3.fromRGB(102, 102, 102),
}
local SKIN_COLORS = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(143, 89, 58),
	Color3.fromRGB(90, 58, 42),
}

local TURN_RATE = 9
local GROUND_PROBE_UP = 30
local GROUND_PROBE_DOWN = 90
local POSE_SETTLE = 0.35
local DRIVER_HEADROOM = 0.2

local descriptions: { [number]: HumanoidDescription } = {}
local animations: { [string]: Animation } = {}
local playing: { [Model]: AnimationTrack } = {}
-- Car a seated rig belongs to, so ApplyDescription can re-seat instead of snapping to a
-- stale world position while the car has already driven off.
local seatedIn: { [Model]: Model } = {}
-- Keep the authored/rough seat separate from the fitted result. Re-fitting an already
-- fitted Y offset after every queue shift compounds the adjustment and sinks the driver.
local roughSeatOffset: { [Model]: CFrame } = {}
local seatOffset: { [Model]: CFrame } = {}
-- Animation poses move R15 feet relative to the anchored root. Grounding must use one
-- neutral pivot-to-sole measurement, never whatever walk/cheer blend happens to be playing.
local soleOffsets: { [Model]: number } = {}

local function templateRig(): Model?
	local folder = ReplicatedStorage:FindFirstChild("NPCTemplates")
	local character = folder ~= nil and folder:FindFirstChild("Character") or nil
	if character ~= nil and character:IsA("Model") then
		return character
	end
	return nil
end

local function driveAnimationId(): string
	local car = ReplicatedStorage:FindFirstChild("Car")
	local folder = car ~= nil and car:FindFirstChild("Animations") or nil
	local drive = folder ~= nil and folder:FindFirstChild("DriveAnimation") or nil
	if drive ~= nil and drive:IsA("Animation") and drive.AnimationId ~= "" then
		return drive.AnimationId
	end
	return ANIMATION_IDS.drive
end

local function animationFor(name: string, r6: boolean?): Animation?
	local key = if r6 then "r6_" .. name else name
	local cached = animations[key]
	if cached ~= nil then
		return cached
	end
	local id
	if r6 then
		id = ANIMATION_IDS_R6[name]
	elseif name == "drive" then
		id = driveAnimationId()
	else
		id = ANIMATION_IDS[name]
	end
	if id == nil then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.Name = key
	animation.AnimationId = id
	animation.Parent = script
	animations[key] = animation
	return animation
end

-- Distance from the model's pivot down to the soles. Authored staff rigs keep their
-- WorldPivot at the feet with HipHeight 0; cloned R15 templates pivot from the root, so
-- HipHeight alone would lift the staff into the air and sink the drivers into the seat.
function LotNpc.rootHeight(rig: Model): number
	local pivotY = rig:GetPivot().Position.Y
	local lowest = pivotY
	for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
		local part = rig:FindFirstChild(name, true)
		if part ~= nil and part:IsA("BasePart") then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y * 0.5)
		end
	end
	if lowest < pivotY - 0.05 then
		return pivotY - lowest
	end
	local box, boxSize = rig:GetBoundingBox()
	local bottom = box.Position.Y - boxSize.Y * 0.5
	return math.max(0.05, pivotY - bottom)
end

function LotNpc.headClearance(rig: Model): number
	return NPCSeatFit.headTopAbovePivot(rig)
end

-- Only the root is anchored when standing: the limbs have to stay loose or the animator
-- cannot move them. Seated rigs get welded to the car instead.
function LotNpc.applyPhysics(rig: Model)
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			part.Anchored = part.Name == "HumanoidRootPart"
		end
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.AutoRotate = false
		humanoid.EvaluateStateMachine = false
		humanoid.PlatformStand = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end
end

local function clearInternalWelds(rig: Model)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp == nil then
		return
	end
	for _, child in hrp:GetChildren() do
		if child:IsA("WeldConstraint") and (string.sub(child.Name, 1, 5) == "Weld_" or child.Name == "SeatWeld") then
			child:Destroy()
		end
	end
end

-- Motor6Ds already carry every limb from the root. Extra limb welds freeze whichever
-- partial animation frame happened to be visible and then fight the next pose on exit.
function LotNpc.solidify(rig: Model)
	clearInternalWelds(rig)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp == nil or not hrp:IsA("BasePart") then
		return
	end
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") and part ~= hrp then
			part.Anchored = false
		end
	end
	rig:SetAttribute("Solid", true)
end

-- Seated NPCs are kinematic descendants of the car Model. Model:PivotTo moves every
-- descendant, including an anchored HRP, so a chassis-to-driver weld is unnecessary.
-- Keeping that weld would let any delayed rig:PivotTo rotate the entire vehicle assembly.
local function pinInCar(rig: Model)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp == nil or not hrp:IsA("BasePart") then
		return
	end
	clearInternalWelds(rig)
	hrp.Anchored = true
end

function LotNpc.play(rig: Model, name: string): AnimationTrack?
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return nil
	end
	local animation = animationFor(name, isR6(rig))
	if animation == nil then
		return nil
	end

	if RuntimeFlags.UseCentralNpcAnimation == true then
		local priority = if name == "idle"
			then Enum.AnimationPriority.Idle
			elseif name == "walk"
			then Enum.AnimationPriority.Movement
			else Enum.AnimationPriority.Action4
		local track = NpcAnimationController.playBase(rig, animation, {
			priority = priority,
			looped = name ~= "customerEnergized",
			fadeTime = 0.08,
			exclusive = true,
		})
		playing[rig] = track
		return track
	end

	-- Temporary rollback path retained until the centralized rollout passes Play validation.
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		local created = Instance.new("Animator")
		created.Parent = humanoid
		animator = created
	end
	local current = playing[rig]
	if current ~= nil and current.Animation == animation and current.IsPlaying then
		return current
	end
	for _, active in animator:GetPlayingAnimationTracks() do
		active:Stop(0)
	end
	playing[rig] = nil
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or track == nil then
		return nil
	end
	track.Priority = if name == "idle"
		then Enum.AnimationPriority.Idle
		elseif name == "walk"
		then Enum.AnimationPriority.Movement
		else Enum.AnimationPriority.Action4
	track.Looped = name ~= "customerEnergized"
	track:Play(0.08)
	playing[rig] = track
	return track
end

function LotNpc.stopAnimations(rig: Model)
	if RuntimeFlags.UseCentralNpcAnimation == true then
		NpcAnimationController.stopAll(rig, 0)
		playing[rig] = nil
		return
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid ~= nil then humanoid:FindFirstChildOfClass("Animator") else nil
	if animator ~= nil then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
	playing[rig] = nil
end

function LotNpc.groundY(position: Vector3, ignore: { Instance }): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local filter: { Instance } = {}
	for _, instance in ignore do
		table.insert(filter, instance)
	end
	params.FilterDescendantsInstances = filter
	local origin = position + Vector3.new(0, GROUND_PROBE_UP, 0)
	local direction = Vector3.new(0, -GROUND_PROBE_DOWN, 0)
	-- Other tycoons' staff can sit on the same ray, so keep skipping anything with a
	-- Humanoid until we hit real ground or the lot itself.
	for _ = 1, 12 do
		local hit = workspace:Raycast(origin, direction, params)
		if hit == nil then
			return position.Y
		end
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		if model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil then
			table.insert(filter, model)
			params.FilterDescendantsInstances = filter
			continue
		end
		return hit.Position.Y
	end
	return position.Y
end

local function flatLook(look: Vector3): Vector3
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		return Vector3.new(0, 0, 1)
	end
	return flat.Unit
end

local function measureSoleOffset(rig: Model): number
	local pivotY = rig:GetPivot().Position.Y
	local lowest = math.huge
	for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
		local part = rig:FindFirstChild(name, true)
		if part ~= nil and part:IsA("BasePart") then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y * 0.5)
		end
	end
	if lowest == math.huge then
		local box, boxSize = rig:GetBoundingBox()
		lowest = box.Position.Y - boxSize.Y * 0.5
	end
	return math.max(0, pivotY - lowest)
end

local function soleOffset(rig: Model): number
	local cached = soleOffsets[rig]
	if cached == nil then
		cached = measureSoleOffset(rig)
		soleOffsets[rig] = cached
	end
	return cached
end

function LotNpc.footPosition(rig: Model): Vector3
	local pivot = rig:GetPivot().Position
	return Vector3.new(pivot.X, pivot.Y - soleOffset(rig), pivot.Z)
end

function LotNpc.resetFooting(rig: Model)
	soleOffsets[rig] = nil
	soleOffsets[rig] = measureSoleOffset(rig)
end

function LotNpc.place(rig: Model, footPosition: Vector3, look: Vector3)
	local root = footPosition + Vector3.new(0, soleOffset(rig), 0)
	local facing = flatLook(look)
	rig:PivotTo(CFrame.lookAt(root, root + facing))
end

-- Snaps an authored staff rig onto the ground under its current XZ. Uses the actual
-- soles rather than HipHeight/WorldPivot guesses, because ApplyDescription rewrites both
-- and that is exactly how a planted NPC ends up floating again.
function LotNpc.plant(rig: Model, ignore: { Instance }?)
	local filter = ignore or { rig }
	local pivot = rig:GetPivot()
	local ground = LotNpc.groundY(pivot.Position, filter)
	local lowest = pivot.Position.Y - soleOffset(rig)
	rig:PivotTo(pivot + Vector3.new(0, ground - lowest, 0))
end

local function driveRoot(rig: Model, footPosition: Vector3, look: Vector3)
	LotNpc.place(rig, footPosition, look)
end

local function applyFallbackLook(rig: Model)
	local colors = rig:FindFirstChildOfClass("BodyColors")
	if colors == nil then
		return
	end
	local shirt = SHIRT_COLORS[math.random(1, #SHIRT_COLORS)]
	local skin = SKIN_COLORS[math.random(1, #SKIN_COLORS)]
	colors.HeadColor3 = skin
	colors.LeftArmColor3 = skin
	colors.RightArmColor3 = skin
	colors.TorsoColor3 = shirt
	colors.LeftLegColor3 = Color3.fromRGB(40, 44, 52)
	colors.RightLegColor3 = Color3.fromRGB(40, 44, 52)
end

LotNpc.tint = applyFallbackLook

local function fittedSeat(rig: Model, car: Model, seat: CFrame): CFrame
	return NPCSeatFit.fit(rig, car, seat, DRIVER_HEADROOM)
end

local function reseatAfterDress(rig: Model)
	local car = seatedIn[rig]
	local seat = seatOffset[rig]
	if car == nil or seat == nil or car.Parent == nil or rig.Parent == nil then
		return
	end
	-- ApplyDescription rewrites the bounding box; reuse XZ but refit Y under the roof.
	local fitted = fittedSeat(rig, car, roughSeatOffset[rig] or seat)
	seatOffset[rig] = fitted
	rig:SetAttribute("SeatFitted", true)
	-- Never PivotTo a nested driver while SeatWeld still joins it to Chassis:
	-- Roblox moves the complete rigid assembly and can pitch the whole car upright.
	clearInternalWelds(rig)
	rig:PivotTo(car:GetPivot() * fitted)
	-- Let the drive animation reach its seated pose before rigid welds capture the limbs.
	-- Applying a description can finish before that pose settles, so only solidify once
	-- the original seat operation marks the pose ready.
	if rig:GetAttribute("SeatPoseReady") == true then
		LotNpc.solidify(rig)
	end
	-- While RoadTraffic is riding, keep the traffic-style anchored follow - do not weld.
	if rig:GetAttribute("Riding") == true then
		local hrp = rig:FindFirstChild("HumanoidRootPart")
		if hrp ~= nil and hrp:IsA("BasePart") then
			hrp.Anchored = true
		end
		return
	end
	pinInCar(rig)
end

-- Traffic-style ride: HRP stays anchored and is PivotTo'd every frame. Every drive
-- receives an ownership generation so a cancelled old queue shift cannot end a newer ride.
function LotNpc.beginRide(rig: Model): number
	local generation = (rideGeneration[rig] or 0) + 1
	rideGeneration[rig] = generation
	rig:SetAttribute("Riding", true)
	rig:SetAttribute("SeatFitted", nil)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp ~= nil and hrp:IsA("BasePart") then
		local weld = hrp:FindFirstChild("SeatWeld")
		if weld ~= nil then
			weld:Destroy()
		end
		hrp.Anchored = true
	end
	return generation
end

function LotNpc.rideAt(rig: Model, carFrame: CFrame, generation: number?)
	if generation ~= nil and rideGeneration[rig] ~= generation then
		return
	end
	local seat = seatOffset[rig]
	if seat == nil then
		return
	end
	local car = seatedIn[rig]
	if car ~= nil and rig:GetAttribute("SeatFitted") ~= true then
		seat = fittedSeat(rig, car, roughSeatOffset[rig] or seat)
		seatOffset[rig] = seat
		rig:SetAttribute("SeatFitted", true)
	end
	-- Be defensive if rideAt is called after a previous seated phase: an old SeatWeld
	-- must never be allowed to transfer this PivotTo into the vehicle chassis.
	clearInternalWelds(rig)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp ~= nil and hrp:IsA("BasePart") then
		hrp.Anchored = true
	end
	rig:PivotTo(carFrame * seat)
end

function LotNpc.endRide(rig: Model, car: Model, generation: number?)
	if generation ~= nil and rideGeneration[rig] ~= generation then
		return
	end
	local seat = seatOffset[rig]
	if seat == nil or seatedIn[rig] ~= car then
		return
	end
	rig:SetAttribute("Riding", nil)
	local fitted = fittedSeat(rig, car, roughSeatOffset[rig] or seat)
	seatOffset[rig] = fitted
	rig:SetAttribute("SeatFitted", true)
	-- endRide is intentionally safe to repeat: detach before repositioning the nested rig.
	clearInternalWelds(rig)
	rig:PivotTo(car:GetPivot() * fitted)
	if rig:GetAttribute("SeatPoseReady") == true then
		LotNpc.solidify(rig)
	end
	pinInCar(rig)
end

function LotNpc.dress(rig: Model)
	if rig:GetAttribute("Dressed") == true then
		return
	end
	rig:SetAttribute("Dressed", true)
	applyFallbackLook(rig)
	task.spawn(function()
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then
			return
		end
		local userId = LOOK_USER_IDS[math.random(1, #LOOK_USER_IDS)]
		local description = descriptions[userId]
		if description == nil then
			local ok, result = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(userId)
			end)
			if ok and result ~= nil then
				descriptions[userId] = result
				description = result
			end
		end
		if description == nil or rig.Parent == nil then
			return
		end
		local wasSeated = seatedIn[rig] ~= nil
		local pivot = rig:GetPivot()
		pcall(function()
			humanoid:ApplyDescription(description)
		end)
		if rig.Parent == nil then
			return
		end
		-- ApplyDescription can change body scale. Capture the new neutral geometry once;
		-- all subsequent walking/planting remains independent of animated foot poses.
		LotNpc.resetFooting(rig)
		if wasSeated then
			-- The car may have moved during the web call; snap back into the seat instead
			-- of the world position we remembered before it left.
			reseatAfterDress(rig)
		else
			rig:PivotTo(pivot)
			LotNpc.applyPhysics(rig)
		end
	end)
end

-- A townsperson always wears their own face. Their rig ships with scripts that would
-- fight the poses this module drives, so they come off with the clone.
local function stripAuthoredRig(rig: Model)
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("LuaSourceContainer")
			or descendant:IsA("ProximityPrompt")
			or descendant:IsA("BillboardGui")
			or descendant:IsA("ClickDetector")
		then
			descendant:Destroy()
		end
	end
end

function LotNpc.personRig(personId: string?): Model?
	return TownsfolkConfig.rigTemplate(TownsfolkConfig.get(personId))
end

-- Named townsfolk were authored as R6. Buyers alone need R15 so their purchase celebration
-- can use the dedicated R15 animation without changing driveway sellers or the rest of town.
-- Build one appearance-preserving R15 template per person and clone it for later visits.
local buyerR15Templates: { [string]: Model } = {}

-- Two legacy pack entries shipped with incomplete classic-clothing values. Keep the rest of
-- their authored look, but borrow a complete outfit from a thematically close townsfolk.
local BUYER_OUTFIT_FALLBACKS: { [string]: string } = {
	BigMike = "TowTruckTony",
	NewbieNora = "Marla",
}

local function usableClassicClothing(instance: Instance?): boolean
	if instance == nil then return false end
	if instance:IsA("Shirt") then return instance.ShirtTemplate ~= "" end
	if instance:IsA("Pants") then return instance.PantsTemplate ~= "" end
	if instance:IsA("ShirtGraphic") then return instance.Graphic ~= "" end
	return true
end

local function copyBuyerAppearance(source: Model, target: Model, personId: string): boolean
	local fallbackId = BUYER_OUTFIT_FALLBACKS[personId]
	local fallbackPerson = TownsfolkConfig.get(fallbackId or "SheriffBuck")
	local fallbackRig = TownsfolkConfig.rigTemplate(fallbackPerson)
	local usedFallback = false

	for _, className in { "Shirt", "Pants", "ShirtGraphic", "BodyColors" } do
		local existing = target:FindFirstChildOfClass(className)
		if existing ~= nil then existing:Destroy() end
		local authored = source:FindFirstChildOfClass(className)
		if className ~= "BodyColors" and not usableClassicClothing(authored) then
			local replacement = fallbackRig and fallbackRig:FindFirstChildOfClass(className)
			if usableClassicClothing(replacement) then
				authored = replacement
				usedFallback = true
			end
		end
		if authored ~= nil then authored:Clone().Parent = target end
	end

	local sourceHead = source:FindFirstChild("Head", true)
	local targetHead = target:FindFirstChild("Head", true)
	if sourceHead ~= nil and targetHead ~= nil and sourceHead:IsA("BasePart") and targetHead:IsA("BasePart") then
		for _, child in targetHead:GetChildren() do
			if child:IsA("Decal") then child:Destroy() end
		end
		for _, child in sourceHead:GetChildren() do
			if child:IsA("Decal") then child:Clone().Parent = targetHead end
		end
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		for _, child in source:GetChildren() do
			-- The imported pack mixes modern Accessory and legacy Hat instances. AddAccessory
			-- accepts both at runtime and rebuilds their head welds for the new R15 skeleton.
			if child:IsA("Accoutrement") then
				local accessory = child:Clone()
				local ok = pcall(function() humanoid:AddAccessory(accessory) end)
				if not ok then accessory:Destroy() end
			end
		end
	end
	return usedFallback
end

local function buyerR15Template(personId: string?): Model?
	if personId == nil then return nil end
	local cached = buyerR15Templates[personId]
	if cached ~= nil then return cached end
	local source = LotNpc.personRig(personId)
	if source == nil then return nil end

	local description = Instance.new("HumanoidDescription")
	local ok, created = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	description:Destroy()
	if not ok or created == nil then
		warn(string.format("[LotNpc] could not create R15 buyer %s: %s", personId, tostring(created)))
		return nil
	end
	local template = created :: Model
	stripAuthoredRig(template)
	local usedOutfitFallback = copyBuyerAppearance(source, template, personId)
	template.Name = personId .. "_BuyerR15"
	template:SetAttribute("BuyerRigVersion", "R15_customer_energized_v2")
	template:SetAttribute("BuyerOutfitFallback", if usedOutfitFallback then BUYER_OUTFIT_FALLBACKS[personId] or "SheriffBuck" else nil)
	template:SetAttribute("PersonId", personId)
	template.Parent = nil
	buyerR15Templates[personId] = template
	return template
end

function LotNpc.spawnBuyer(name: string, parent: Instance, footPosition: Vector3, look: Vector3, personId: string): Model?
	local source = buyerR15Template(personId)
	if source == nil then
		warn(string.format("[LotNpc] R15 buyer template missing for %s", personId))
		return nil
	end
	local rig = source:Clone()
	rig.Name = name
	rig:SetAttribute("Dressed", true)
	rig:SetAttribute("PersonId", personId)
	LotNpc.applyPhysics(rig)
	LotNpc.place(rig, footPosition, look)
	rig.Parent = parent
	LotNpc.play(rig, "idle")
	return rig
end

function LotNpc.spawn(name: string, parent: Instance, footPosition: Vector3, look: Vector3, personId: string?): Model?
	local authored = LotNpc.personRig(personId)
	local source = authored or templateRig()
	if source == nil then
		warn("[LotNpc] ReplicatedStorage.NPCTemplates.Character missing")
		return nil
	end
	local rig = source:Clone()
	rig.Name = name
	if authored ~= nil then
		stripAuthoredRig(rig)
		-- Their look is the point; a random HumanoidDescription would wipe the face.
		rig:SetAttribute("Dressed", true)
		rig:SetAttribute("PersonId", personId)
	end
	captureR6NeutralPose(rig)
	LotNpc.applyPhysics(rig)
	LotNpc.place(rig, footPosition, look)
	rig.Parent = parent
	if authored == nil then
		LotNpc.dress(rig)
	end
	LotNpc.play(rig, "idle")
	return rig
end

function LotNpc.adopt(rig: Model)
	captureR6NeutralPose(rig)
	LotNpc.applyPhysics(rig)
	if rig:GetAttribute("FriendUserId") == nil then
		applyFallbackLook(rig)
	end
	LotNpc.plant(rig)
	LotNpc.play(rig, "idle")
end

function LotNpc.walkPoints(from: Vector3, direction: Vector3, steps: number, stride: number, ignore: { Instance }): { Vector3 }
	local facing = flatLook(direction)
	local points: { Vector3 } = { from }
	for step = 1, steps do
		local flat = from + facing * (stride * step)
		table.insert(points, Vector3.new(flat.X, LotNpc.groundY(flat, ignore), flat.Z))
	end
	return points
end

function LotNpc.walk(rig: Model, points: { Vector3 }, speed: number, stillValid: (() -> boolean)?): boolean
	if #points < 2 then
		return true
	end
	LotNpc.play(rig, "walk")
	local position = points[1]
	local look = flatLook(points[2] - points[1])
	local index = 1
	while index < #points do
		local delta = RunService.Heartbeat:Wait()
		if rig.Parent == nil or (stillValid ~= nil and not stillValid()) then
			return false
		end
		local budget = speed * delta
		local heading = look
		while budget > 0 and index < #points do
			local target = points[index + 1]
			local toTarget = target - position
			local distance = toTarget.Magnitude
			if distance <= budget then
				position = target
				budget -= distance
				index += 1
				if distance > 0.01 then
					heading = flatLook(toTarget)
				end
			else
				position += toTarget.Unit * budget
				heading = flatLook(toTarget)
				budget = 0
			end
		end
		look = flatLook(look:Lerp(heading, math.min(1, TURN_RATE * delta)))
		driveRoot(rig, position, look)
	end
	LotNpc.play(rig, "idle")
	return true
end

-- Puts the rig behind the wheel. A generation owns the complete delayed transition,
-- so an old seat callback can never reapply a drive pose after this NPC has walked away.
function LotNpc.seat(rig: Model, car: Model, seat: CFrame)
	local generation = (seatGeneration[rig] or 0) + 1
	seatGeneration[rig] = generation
	rideGeneration[rig] = (rideGeneration[rig] or 0) + 1

	LotNpc.stopAnimations(rig)
	clearInternalWelds(rig)
	setR6DrivePose(rig, false)
	rig.Parent = car
	rig:SetAttribute("Solid", nil)
	rig:SetAttribute("SeatPoseReady", nil)
	rig:SetAttribute("SeatFitted", nil)

	rig:PivotTo(car:GetPivot() * seat)
	LotNpc.applyPhysics(rig)
	local r6 = isR6(rig)
	local track = if r6 then nil else LotNpc.play(rig, "drive")
	local fitted = fittedSeat(rig, car, seat)
	rig:PivotTo(car:GetPivot() * fitted)
	seatedIn[rig] = car
	roughSeatOffset[rig] = seat
	seatOffset[rig] = fitted
	pinInCar(rig)

	-- Queue sellers are authored R6 rigs. Apply one deterministic pose immediately so a newly
	-- arriving car never spends 0.35s in a different animation pose than the cars ahead of it.
	if r6 then
		playing[rig] = nil
		setR6DrivePose(rig, true)
		rig:SetAttribute("SeatPoseReady", true)
		reseatAfterDress(rig)
		return
	end

	task.delay(POSE_SETTLE, function()
		if rig.Parent == nil
			or seatGeneration[rig] ~= generation
			or seatedIn[rig] ~= car
		then
			return
		end
		if track ~= nil then
			track:AdjustSpeed(0)
		end
		if seatGeneration[rig] ~= generation or seatedIn[rig] ~= car then
			return
		end
		rig:SetAttribute("SeatPoseReady", true)
		reseatAfterDress(rig)
	end)
end

function LotNpc.unseat(
	rig: Model,
	parent: Instance,
	footPosition: Vector3,
	look: Vector3,
	stateName: string?
)
	local generation = (seatGeneration[rig] or 0) + 1
	seatGeneration[rig] = generation
	rideGeneration[rig] = (rideGeneration[rig] or 0) + 1
	LotNpc.stopAnimations(rig)
	seatedIn[rig] = nil
	roughSeatOffset[rig] = nil
	seatOffset[rig] = nil
	rig:SetAttribute("Solid", nil)
	rig:SetAttribute("Riding", nil)
	rig:SetAttribute("SeatFitted", nil)
	rig:SetAttribute("SeatPoseReady", nil)
	clearInternalWelds(rig)
	setR6DrivePose(rig, false)
	rig.Parent = parent
	LotNpc.applyPhysics(rig)
	LotNpc.place(rig, footPosition, look)
	LotNpc.play(rig, stateName or "idle")
	-- Animator evaluation can write one final frozen drive frame after Stop(0). Reassert
	-- the complete neutral skeleton on the next runtime frame, but never after a reseat.
	task.spawn(function()
		RunService.Heartbeat:Wait()
		if rig.Parent ~= nil
			and seatGeneration[rig] == generation
			and seatedIn[rig] == nil
		then
			setR6DrivePose(rig, false)
		end
	end)
end

function LotNpc.fadeOut(rig: Model, duration: number)
	LotNpc.stopAnimations(rig)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			TweenService:Create(part, info, { Transparency = 1 }):Play()
		elseif part:IsA("Decal") then
			TweenService:Create(part, info, { Transparency = 1 }):Play()
		end
	end
	task.delay(duration, function()
		LotNpc.destroy(rig)
	end)
end

function LotNpc.destroy(rig: Model?)
	if rig == nil then
		return
	end
	seatGeneration[rig] = (seatGeneration[rig] or 0) + 1
	rideGeneration[rig] = (rideGeneration[rig] or 0) + 1
	LotNpc.stopAnimations(rig)
	playing[rig] = nil
	seatedIn[rig] = nil
	roughSeatOffset[rig] = nil
	seatOffset[rig] = nil
	soleOffsets[rig] = nil
	neutralR6JointC0[rig] = nil
	rig:Destroy()
end

return LotNpc

