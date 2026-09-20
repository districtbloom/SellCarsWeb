--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local TycoonService = require(script.Parent.TycoonService)
local PadService = require(script.Parent.PadService)
local BayStaff = require(script.Parent.BayStaff)
local StaffDirector = require(script.Parent.JunkLot.StaffDirector)
local LotNpc = require(script.Parent.JunkLot.LotNpc)
local StaffAnimationController = require(script.Parent.StaffAnimationController)

type Record = TycoonService.TycoonRecord

local MAX_FRIENDS = 40

-- Core staff use authored placeholder uniforms until their final skins are supplied.
-- Town residents may still borrow friends' looks, but these roles must remain recognisable.
local FIXED_STAFF_MODELS: { [string]: boolean } = {
	FirstMechanic = true,
	SecondMechanic = true,
	ServiceHelper = true,
	ServiceHelper2 = true,
	ServiceHelper3 = true,
	FirstSalesman = true,
	UsedCarsSalesman = true,
	MechanicNPC_Bay1 = true,
	MechanicNPC_Bay2 = true,
	CheckoutClerkNPC = true,
	TowTruckDriverNPC = true,
}

local FIXED_UNIFORMS: { [string]: { shirt: string, pants: string } } = {
	FirstSalesman = {
		shirt = "rbxassetid://86698594140963",
		pants = "rbxassetid://93060083603617",
	},
	UsedCarsSalesman = {
		shirt = "rbxassetid://86698594140963",
		pants = "rbxassetid://93060083603617",
	},
	FirstMechanic = {
		shirt = "rbxassetid://103446640163480",
		pants = "rbxassetid://137929118885683",
	},
	SecondMechanic = {
		shirt = "rbxassetid://103446640163480",
		pants = "rbxassetid://137929118885683",
	},
	ServiceHelper = {
		shirt = "rbxassetid://113380317733292",
		pants = "rbxassetid://90839955712839",
	},
	ServiceHelper2 = {
		shirt = "rbxassetid://113380317733292",
		pants = "rbxassetid://90839955712839",
	},
	ServiceHelper3 = {
		shirt = "rbxassetid://113380317733292",
		pants = "rbxassetid://90839955712839",
	},
	MechanicNPC_Bay1 = {
		shirt = "rbxassetid://103446640163480",
		pants = "rbxassetid://137929118885683",
	},
	MechanicNPC_Bay2 = {
		shirt = "rbxassetid://103446640163480",
		pants = "rbxassetid://137929118885683",
	},
	CheckoutClerkNPC = {
		shirt = "rbxassetid://120137744642139",
		pants = "rbxassetid://108400556770599",
	},
	TowTruckDriverNPC = {
		shirt = TycoonConfig.TOW_TRUCK_DRIVER_SHIRT,
		pants = TycoonConfig.TOW_TRUCK_DRIVER_PANTS,
	},
}

local function applyFixedUniform(rig: Model, modelName: string)
	local uniform = FIXED_UNIFORMS[modelName]
	if uniform == nil then
		return
	end
	local shirt = rig:FindFirstChildOfClass("Shirt")
	if shirt == nil then
		shirt = Instance.new("Shirt")
		shirt.Name = "StaffShirt"
		shirt.Parent = rig
	end
	shirt.ShirtTemplate = uniform.shirt

	local pants = rig:FindFirstChildOfClass("Pants")
	if pants == nil then
		pants = Instance.new("Pants")
		pants.Name = "StaffPants"
		pants.Parent = rig
	end
	pants.PantsTemplate = uniform.pants
end

-- Authored staff headwear lives in ServerStorage so it never appears loose in the map.
-- A rig attribute can override this table for future staff roles without another code path.
local HEAD_ACCESSORY_BY_MODEL: { [string]: string } = {
	FirstMechanic = "Mechanic_HeadAcc",
	SecondMechanic = "Mechanic_HeadAcc",
	ServiceHelper = "Mechanic_HeadAcc",
	ServiceHelper2 = "Mechanic_HeadAcc",
	ServiceHelper3 = "Mechanic_HeadAcc",
	MechanicNPC_Bay1 = "Mechanic_HeadAcc",
	MechanicNPC_Bay2 = "Mechanic_HeadAcc",
	TuningAtelierMechanic = "TA_HeadAcc",
	FirstSalesman = "Salesman_Hair",
	UsedCarsSalesman = "Salesman_Hair",
	CheckoutClerkNPC = "Salesman_Hair",
}

local MECHANIC_HEAD_COLOR = Color3.fromRGB(216, 170, 94) -- #D8AA5E
local COMPUTER_BASE_ANIMATION = "idle_working_computer"
local COMPUTER_SIT_OVERLAY = "sit_legs"
local CHECKOUT_POSE_VERSION = "CheckoutDesk_v4_ComputerSitBlend"

local function applyMechanicHeadColor(rig: Model)
	local head = rig:FindFirstChild("Head")
	if head == nil or not head:IsA("BasePart") then
		return
	end
	local bodyColors = rig:FindFirstChildOfClass("BodyColors")
	if bodyColors ~= nil then
		bodyColors.HeadColor3 = MECHANIC_HEAD_COLOR
	end
	head.Color = MECHANIC_HEAD_COLOR
end

local function poseCheckoutClerk(record: Record, rig: Model)
	local repair = record.zones.repair
	local chair = repair and repair:FindFirstChild("ChairSeat", true)
	local desk = repair and repair:FindFirstChild("AdminDeskTop", true)
	local keyboard = repair and repair:FindFirstChild("Keyboard", true)
	if chair == nil or not chair:IsA("BasePart") or desk == nil or not desk:IsA("BasePart") then
		return
	end
	local facingTarget = desk
	if keyboard ~= nil and keyboard:IsA("BasePart") then
		facingTarget = keyboard
	end

	local seatTop = chair.Position.Y + chair.Size.Y * 0.5
	local facing = Vector3.new(facingTarget.Position.X - chair.Position.X, 0, facingTarget.Position.Z - chair.Position.Z)
	if facing.Magnitude < 0.1 then
		facing = Vector3.new(0, 0, -1)
	else
		facing = facing.Unit
	end
	-- The R15 character pivot is at its standing ground plane. The looping drive pose bends
	-- the legs at the chair while keeping both arms forward over the desk.
	local pivotPosition = Vector3.new(chair.Position.X, seatTop - 1.55, chair.Position.Z)
	local pivot = CFrame.lookAt(pivotPosition, pivotPosition + facing)
	rig:PivotTo(pivot)
	rig:SetAttribute("_PIVOT0", pivot)
	rig:SetAttribute("CheckoutDeskPoseVersion", CHECKOUT_POSE_VERSION)

	-- PadService freezes idle staff rigs part-by-part. AnimationConstraint joints cannot
	-- move anchored limbs, so keep only the root fixed and release the animated body.
	local rootPart = rig:FindFirstChild("HumanoidRootPart")
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = descendant == rootPart
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = descendant ~= rootPart
		end
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if humanoid ~= nil then
		humanoid.AutoRotate = false
		humanoid.EvaluateStateMachine = false
		humanoid.PlatformStand = true
	end
	if animator == nil then
		return
	end
	for _, active in animator:GetPlayingAnimationTracks() do
		active:Stop(0.1)
	end
	StaffAnimationController.StopAll(rig)
	StaffAnimationController.PlayBaseAnimation(rig, COMPUTER_BASE_ANIMATION)
	StaffAnimationController.PlayOverlay(rig, COMPUTER_SIT_OVERLAY)
end

local function applyHeadAccessory(rig: Model, modelName: string)
	local explicit = rig:GetAttribute("StaffHeadAccessory")
	local templateName = if typeof(explicit) == "string" and explicit ~= ""
		then explicit
		else HEAD_ACCESSORY_BY_MODEL[modelName]
	local existing = rig:FindFirstChild("StaffHeadAccessory")
	if templateName == nil then
		if existing ~= nil then
			existing:Destroy()
		end
		return
	end

	local templates = ServerStorage:FindFirstChild("StaffHeadAccessories")
	local template = templates and templates:FindFirstChild(templateName)
	local head = rig:FindFirstChild("Head")
	if template == nil or not template:IsA("Model") or head == nil or not head:IsA("BasePart") then
		return
	end
	local layoutVersion = template:GetAttribute("LayoutVersion")
	if existing ~= nil
		and existing:IsA("Model")
		and existing:GetAttribute("SourceAccessory") == templateName
		and existing:GetAttribute("LayoutVersion") == layoutVersion
	then
		local validWeld = false
		for _, descendant in existing:GetDescendants() do
			if descendant:IsA("WeldConstraint") and descendant.Name == "HeadWeld"
				and descendant.Part0 == head and descendant.Part1 ~= nil then
				validWeld = true
				break
			end
		end
		if validWeld then
			return
		end
	end
	if existing ~= nil then
		existing:Destroy()
	end

	local clone = template:Clone()
	clone.Name = "StaffHeadAccessory"
	clone:SetAttribute("SourceAccessory", templateName)
	clone.Parent = rig

	local boxCFrame, boxSize = clone:GetBoundingBox()
	local boxFromPivot = clone:GetPivot():ToObjectSpace(boxCFrame)
	local authoredOverlap = template:GetAttribute("HeadOverlap")
	local overlap = if typeof(authoredOverlap) == "number" then authoredOverlap else 0.7
	local authoredOffset = template:GetAttribute("HeadOffset")
	local offset = if typeof(authoredOffset) == "Vector3" then authoredOffset :: Vector3 else Vector3.zero
	local targetBox = head.CFrame
		* CFrame.new(offset.X, head.Size.Y * 0.5 + boxSize.Y * 0.5 - overlap + offset.Y, offset.Z)

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
	clone:PivotTo(targetBox * boxFromPivot:Inverse())
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "HeadWeld"
			weld.Part0 = head
			weld.Part1 = descendant
			weld.Parent = descendant
			descendant.Anchored = false
		end
	end
end

local SalesmanService = {}

local applied: { [Record]: { [string]: number } } = {}

local function findRig(record: Record, zoneId: string, modelName: string): Model?
	local zone = record.zones[zoneId]
	if zone == nil then
		return nil
	end
	local direct = zone:FindFirstChild(modelName, true) or record.locked:FindFirstChild(modelName)
	if direct ~= nil and direct:IsA("Model") then
		return direct
	end
	return nil
end

local function friendIds(player: Player): { number }
	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if not ok or pages == nil then
		return {}
	end

	local ids: { number } = {}
	pcall(function()
		while true do
			for _, entry in pages:GetCurrentPage() do
				if typeof(entry.Id) == "number" then
					table.insert(ids, entry.Id)
				end
				if #ids >= MAX_FRIENDS then
					return
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	return ids
end

local function dressRig(record: Record, player: Player, rig: Model, friendId: number)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(friendId)
	end)
	if not ok or description == nil then
		warn(`[SalesmanService] could not fetch appearance for friend {friendId}`)
		return
	end
	if rig.Parent == nil or record.owner ~= player then
		return
	end
	local applyOk, err = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applyOk then
		warn(`[SalesmanService] ApplyDescription failed: {err}`)
		return
	end
	-- Never restore the pre-description pivot: HipHeight / WorldPivot change, so that
	-- CFrame leaves a body underground and a floating head. Re-apply physics then plant.
	LotNpc.applyPhysics(rig)
	PadService.refresh(record)
	StaffDirector.replant(record, rig)
	rig:SetAttribute("FriendUserId", friendId)
	local nameOk, friendName = pcall(function()
		return Players:GetNameFromUserIdAsync(friendId)
	end)
	if nameOk and typeof(friendName) == "string" then
		rig:SetAttribute("FriendName", friendName)
	end
end

function SalesmanService.dressFor(record: Record, player: Player)
	local pending: { { rig: Model, key: string } } = {}
	local state = applied[record]
	if state == nil then
		state = {}
		applied[record] = state
	end
	local marks = state :: { [string]: number }

	for _, entry in TycoonConfig.NPC_MODELS do
		local rig = findRig(record, entry.zone, entry.model)
		if rig == nil then
			continue
		end
		if FIXED_STAFF_MODELS[entry.model] == true or rig:GetAttribute("FixedStaffAppearance") == true then
			applyFixedUniform(rig, entry.model)
			local explicitHeadAccessory = rig:GetAttribute("StaffHeadAccessory")
			local desiredHeadAccessory = if typeof(explicitHeadAccessory) == "string" and explicitHeadAccessory ~= ""
				then explicitHeadAccessory
				else HEAD_ACCESSORY_BY_MODEL[entry.model]
			-- Salesman hair must not recolour the face; only mechanic headwear carries the mechanic skin contract.
			if desiredHeadAccessory == "Mechanic_HeadAcc"
				or desiredHeadAccessory == "TA_HeadAcc"
				or entry.model == "CheckoutClerkNPC"
			then
				applyMechanicHeadColor(rig)
			end
			applyHeadAccessory(rig, entry.model)
			if entry.model == "CheckoutClerkNPC" then
				poseCheckoutClerk(record, rig)
			end
			rig:SetAttribute("FixedStaffAppearance", true)
			rig:SetAttribute("FriendUserId", nil)
			rig:SetAttribute("FriendName", nil)
			marks[entry.model] = player.UserId
			continue
		end
		if marks[entry.model] == player.UserId then
			continue
		end
		marks[entry.model] = player.UserId
		table.insert(pending, { rig = rig, key = entry.model })
	end

	-- Every Tuning Atelier staff rig has an authored indoor home. Plant bought rigs by
	-- their soles after clothing/accessories settle; a sky-down ray inside this roofed
	-- building lands on the roof and is never a valid staff position.
	BayStaff.settleTuning(record)

	if #pending == 0 then
		return
	end

	task.spawn(function()
		local ids = friendIds(player)
		if #ids == 0 then
			return
		end
		local used: { [number]: boolean } = {}
		for _, item in pending do
			local choice: number? = nil
			for _ = 1, 8 do
				local candidate = ids[math.random(1, #ids)]
				if not used[candidate] then
					choice = candidate
					break
				end
			end
			if choice == nil then
				choice = ids[math.random(1, #ids)]
			end
			used[choice :: number] = true
			if marks[item.key] ~= player.UserId then
				continue
			end
			dressRig(record, player, item.rig, choice :: number)
		end
	end)
end

function SalesmanService.init()
	TycoonService.tycoonClaimed.Event:Connect(function(record: Record, player: Player)
		SalesmanService.dressFor(record, player)
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: Record)
		applied[record] = nil
	end)
	TycoonService.padPurchased.Event:Connect(function(record: Record, _definition, player: Player)
		SalesmanService.dressFor(record, player)
	end)
end

return SalesmanService

