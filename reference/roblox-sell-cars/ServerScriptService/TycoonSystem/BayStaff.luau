--!strict

-- Indoor Repair Bay and Tuning Atelier staff. Service workers walk between authored
-- stands and their active cars; static administrators are planted on authored foot frames.
-- Nothing here decides when a job happens - the slot state machine in NPCService drives it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonService = require(ServerScriptService.TycoonSystem.TycoonService)
local LotNpc = require(ServerScriptService.TycoonSystem.JunkLot.LotNpc)
local StaffAnimationController = require(ServerScriptService.TycoonSystem.StaffAnimationController)

type Record = TycoonService.TycoonRecord

local BayStaff = {}

type StaffDefinition = { zone: string, name: string }

local RIG_FOR_SLOT: { [string]: StaffDefinition } = {
	RepairBay1 = { zone = "repair", name = "MechanicNPC_Bay1" },
	RepairBay2 = { zone = "repair", name = "MechanicNPC_Bay2" },
	TuningDyno = { zone = "tuningDyno", name = "DynoSpecialistNPC" },
	TuningBody = { zone = "tuningBody", name = "BodySpecialistNPC" },
	TuningPaint = { zone = "tuningPaint", name = "PaintSpecialistNPC" },
	-- Home-only pseudo slots: administrators never walk to a service car, but sharing the
	-- same authored-foot placement path keeps them off the roof and out of the floor.
	TuningServiceAdvisor = { zone = "tuningDyno", name = "ServiceAdvisorNPC" },
	TuningOperationsManager = { zone = "tuningDyno", name = "OperationsManagerNPC" },
}

local TUNING_HOME_IDS: { string } = {
	"TuningDyno",
	"TuningBody",
	"TuningPaint",
	"TuningServiceAdvisor",
	"TuningOperationsManager",
}

local ADMIN_WORK_AREA_BY_SLOT: { [string]: string } = {
	TuningServiceAdvisor = "ServiceAdvisorWorkArea",
	TuningOperationsManager = "OperationsManagerWorkArea",
}

local COMPUTER_BASE_ANIMATION = "idle_working_computer"
local COMPUTER_SIT_OVERLAY = "sit_legs"
local TUNING_ADMIN_POSE_VERSION = "TuningAdminComputerDesk_v1"

local STEP_LENGTH = 2.4
local WALK_SPEED = DealerCarConfig.STAFF_WALK_SPEED or 11

local busy: { [Model]: boolean } = {}
local homes: { [Model]: CFrame } = {}
local authoredPivots: { [Model]: CFrame } = {}
local motionToken: { [Model]: number } = {}

local function footBottom(rig: Model): number
	local lowest = math.huge
	for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
		local part = rig:FindFirstChild(name, true)
		if part ~= nil and part:IsA("BasePart") then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y * 0.5)
		end
	end
	if lowest < math.huge then
		return lowest
	end
	local box, boxSize = rig:GetBoundingBox()
	return box.Position.Y - boxSize.Y * 0.5
end

local function footOf(rig: Model): Vector3
	local pivot = rig:GetPivot().Position
	return Vector3.new(pivot.X, footBottom(rig), pivot.Z)
end

local function seatAdministrator(record: Record, slotId: string, rig: Model): boolean
	local workAreaName = ADMIN_WORK_AREA_BY_SLOT[slotId]
	if workAreaName == nil then
		return false
	end
	local definition = RIG_FOR_SLOT[slotId]
	local zone = definition and record.zones[definition.zone]
	local workArea = zone and zone:FindFirstChild(workAreaName, true)
	local chair = workArea and workArea:FindFirstChild("ChairSeat", true)
	local keyboard = workArea and workArea:FindFirstChild("Keyboard", true)
	local desk = workArea and workArea:FindFirstChild("DeskTop", true)
	if chair == nil or not chair:IsA("BasePart") then
		return false
	end
	local facingTarget: BasePart? = nil
	if keyboard ~= nil and keyboard:IsA("BasePart") then
		facingTarget = keyboard
	elseif desk ~= nil and desk:IsA("BasePart") then
		facingTarget = desk
	end
	if facingTarget == nil then
		return false
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local rootPart = rig:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.RigType ~= Enum.HumanoidRigType.R15
		or rootPart == nil or not rootPart:IsA("BasePart")
	then
		warn(`[BayStaff] {rig:GetFullName()} must be R15 for the computer animation blend`)
		return false
	end

	local seatTop = chair.Position.Y + chair.Size.Y * 0.5
	local facing = Vector3.new(
		facingTarget.Position.X - chair.Position.X,
		0,
		facingTarget.Position.Z - chair.Position.Z
	)
	if facing.Magnitude < 0.1 then
		facing = Vector3.new(0, 0, -1)
	else
		facing = facing.Unit
	end
	-- Standard R15 root sits 1.10 studs above the authored chair top in this blended pose.
	local pivotPosition = Vector3.new(chair.Position.X, seatTop + 1.10, chair.Position.Z)
	local pivot = CFrame.lookAt(pivotPosition, pivotPosition + facing)
	rig:PivotTo(pivot)
	rig:SetAttribute("_PIVOT0", pivot)
	rig:SetAttribute("TuningAdminPoseVersion", TUNING_ADMIN_POSE_VERSION)
	homes[rig] = CFrame.new(pivotPosition) * pivot.Rotation
	authoredPivots[rig] = pivot

	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = descendant == rootPart
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = descendant ~= rootPart
		end
	end
	humanoid.AutoRotate = false
	humanoid.EvaluateStateMachine = false
	humanoid.PlatformStand = true
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator ~= nil then
		for _, active in animator:GetPlayingAnimationTracks() do
			active:Stop(0.1)
		end
	end
	StaffAnimationController.StopAll(rig)
	StaffAnimationController.PlayBaseAnimation(rig, COMPUTER_BASE_ANIMATION)
	StaffAnimationController.PlayOverlay(rig, COMPUTER_SIT_OVERLAY)
	return true
end

-- _PIVOT0 is stamped in Studio, where these rigs sit with their pivot exactly on their
-- soles. At runtime that stops being true: the rig gets dressed and its legs end up well
-- below the pivot. So the stored home is treated as a FOOT position and the body is placed
-- on top of it with LotNpc.place, which measures the current sole offset. Replaying it as a
-- pivot instead is what left the mechanic hovering over the deck (or sunk into it).

local function rigFor(record: Record, slotId: string): Model?
	local definition = RIG_FOR_SLOT[slotId]
	if definition == nil then
		return nil
	end
	local zone = record.zones[definition.zone]
	if zone == nil then
		return nil
	end
	local rig = zone:FindFirstChild(definition.name, true)
	if rig == nil or not rig:IsA("Model") or rig:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	-- Not paid for yet: the rig is hidden and must not walk anywhere.
	if rig:GetAttribute("Built") ~= true then
		return nil
	end
	return rig
end

-- PadService stamps the authored pivot on every rig, so home survives a bad plant.
local function homeOf(rig: Model): CFrame
	local stored = homes[rig]
	if stored ~= nil then
		return stored
	end

	-- _PIVOT0 is an authored MODEL pivot. Older repair rigs happen to pivot near their
	-- soles, while the Tuning Atelier R6 staff pivot around the torso. Convert either
	-- convention into the foot-frame expected by LotNpc.place without changing _PIVOT0;
	-- PadService still needs the original model pivot when it hides/reveals the rig.
	local authoredValue = rig:GetAttribute("_PIVOT0")
	local authored = if typeof(authoredValue) == "CFrame" then authoredValue :: CFrame else rig:GetPivot()
	authoredPivots[rig] = authored
	local currentPivot = rig:GetPivot()
	local soleOffset = math.max(0, currentPivot.Position.Y - footBottom(rig))
	local footPosition = authored.Position - Vector3.new(0, soleOffset, 0)
	local home = CFrame.new(footPosition) * authored.Rotation
	homes[rig] = home
	return home
end

-- The lot staff can raycast for the floor because the junk lot is open sky. The bay is
-- not: LotNpc.groundY starts its probe 30 studs up, which inside a roofed building is
-- above the ceiling, so the first thing it hits is the roof and the mechanic gets planted
-- on top of the building. The bay floor is flat and its height is already known from the
-- service geometry, so walk on a straight interpolation between two known heights instead.
local function walkTo(
	rig: Model,
	record: Record,
	target: CFrame | { CFrame },
	animation: string,
	token: number
): boolean
	-- PadService parks idle rigs fully anchored; hand the limbs back to physics so the
	-- walk and work animations actually play.
	LotNpc.applyPhysics(rig)

	local targets = if typeof(target) == "CFrame" then { target :: CFrame } else target :: { CFrame }
	if #targets == 0 then
		return false
	end

	local points: { Vector3 } = { footOf(rig) }
	local from = points[1]
	for _, targetFrame in targets do
		local to = targetFrame.Position
		local span = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		local distance = span.Magnitude
		if distance > 1.5 then
			local steps = math.max(2, math.ceil(distance / STEP_LENGTH))
			for step = 1, steps do
				table.insert(points, from:Lerp(to, step / steps))
			end
		else
			table.insert(points, to)
		end
		from = to
	end

	if not LotNpc.walk(rig, points, WALK_SPEED, function()
		return rig.Parent ~= nil and motionToken[rig] == token
	end) then
		return false
	end
	if rig.Parent == nil or motionToken[rig] ~= token then
		return false
	end

	local finalTarget = targets[#targets]
	local look = Vector3.new(finalTarget.LookVector.X, 0, finalTarget.LookVector.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, -1)
	end
	-- The final target is a foot position, which is the convention LotNpc.place expects.
	LotNpc.place(rig, finalTarget.Position, look.Unit)
	LotNpc.play(rig, animation)
	return true
end

-- Lift is coming up: go stand at the car and work it.
function BayStaff.toWork(
	record: Record,
	slotId: string,
	stand: (CFrame | { CFrame })?,
	workAnimation: string?,
	onFinished: ((boolean) -> ())?
): boolean
	local rig = rigFor(record, slotId)
	if rig == nil or stand == nil or busy[rig] then
		return false
	end
	homeOf(rig)
	motionToken[rig] = (motionToken[rig] or 0) + 1
	local token = motionToken[rig]
	local animation = workAnimation or "work"
	busy[rig] = true
	task.spawn(function()
		local ok, reached = pcall(walkTo, rig, record, stand, animation, token)
		if not ok then
			warn(`[BayStaff] {slotId} walk to work failed: {reached}`)
		end
		if motionToken[rig] == token then
			busy[rig] = nil
			if onFinished ~= nil then
				local callbackOk, callbackErr = pcall(onFinished, ok and reached == true)
				if not callbackOk then
					warn(`[BayStaff] {slotId} arrival callback failed: {callbackErr}`)
				end
			end
		end
	end)
	return true
end

-- Job over: back to the stand and idle there.
function BayStaff.toHome(record: Record, slotId: string)
	local rig = rigFor(record, slotId)
	if rig == nil then
		return
	end
	local home = homeOf(rig)

	-- A player can take over while the specialist is still walking to the car. Invalidate
	-- that route immediately and launch the return from the rig's current foot position.
	motionToken[rig] = (motionToken[rig] or 0) + 1
	local token = motionToken[rig]
	busy[rig] = true
	task.spawn(function()
		local foot = home.Position
		local ok, err = pcall(walkTo, rig, record, CFrame.lookAt(foot, foot + home.LookVector), "idle", token)
		if not ok then
			warn(`[BayStaff] {slotId} walk home failed: {err}`)
		end
		if motionToken[rig] == token then
			busy[rig] = nil
		end
	end)
end

-- Stand him on his mark without a walk. PadService pins idle rigs by pivot, which at
-- runtime buries the feet, so this is called once the rig exists to put him back on his
-- soles before anyone looks at him.
function BayStaff.settle(record: Record, slotId: string)
	local rig = rigFor(record, slotId)
	if rig == nil or busy[rig] then
		return
	end
	if ADMIN_WORK_AREA_BY_SLOT[slotId] ~= nil then
		seatAdministrator(record, slotId, rig)
		return
	end
	local home = homeOf(rig)
	local look = Vector3.new(home.LookVector.X, 0, home.LookVector.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, -1)
	end
	LotNpc.applyPhysics(rig)
	LotNpc.place(rig, home.Position, look.Unit)
	LotNpc.play(rig, "idle")
end

-- Replant every bought Tuning Atelier role after a claim, reveal or appearance update.
-- Active service workers are left alone; administrators have no physical service slot and
-- are always safe to settle. This path deliberately never performs a sky-down raycast.
function BayStaff.settleTuning(record: Record)
	local slots = record.folder:FindFirstChild("ServiceSlots")
	for _, staffId in TUNING_HOME_IDS do
		local serviceSlot = if slots ~= nil then slots:FindFirstChild(staffId) else nil
		if serviceSlot == nil or serviceSlot:GetAttribute("ServiceKind") == nil then
			BayStaff.settle(record, staffId)
		end
	end
end

-- Tycoon released or job abandoned: no walking, just be where you belong.
function BayStaff.release(record: Record)
	for _, definition in RIG_FOR_SLOT do
		local zone = record.zones[definition.zone]
		local rig = zone and zone:FindFirstChild(definition.name, true)
		if rig ~= nil and rig:IsA("Model") then
			StaffAnimationController.StopAll(rig)
			motionToken[rig] = (motionToken[rig] or 0) + 1
			local authored = authoredPivots[rig]
			if authored == nil then
				local stored = rig:GetAttribute("_PIVOT0")
				authored = if typeof(stored) == "CFrame" then stored :: CFrame else nil
			end
			if authored ~= nil then
				rig:PivotTo(authored)
			end
			busy[rig] = nil
		end
	end
end

return BayStaff

