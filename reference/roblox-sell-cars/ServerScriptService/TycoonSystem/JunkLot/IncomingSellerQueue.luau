--!strict

-- Waiting stock for the junk-lot source lane. Each queue entry owns one physical proxy;
-- TradeService adopts that exact Model into W instead of destroying and cloning it again.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local DataService = require(script.Parent.Parent.DataService)
local TycoonService = require(script.Parent.Parent.TycoonService)
local LotSlots = require(script.Parent.LotSlots)
local CarVisuals = require(script.Parent.CarVisuals)
local LotNpc = require(script.Parent.LotNpc)
local RoadTraffic = require(script.Parent.RoadTraffic)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord

export type Item = {
	queueId: string,
	templateId: string,
	ask: number,
	sellerId: string?,
	source: string?,
	paintHue: number?,
	bodyKit: boolean?,
	neonColorId: string?,
	dirty: boolean?,
	oilLeak: boolean?,
	wheelsPresent: boolean?,
	missingWheels: { string }?,
	towStock: boolean?,
}

type State = {
	record: Record,
	folder: Folder,
	items: { Item },
	models: { [string]: Model },
	presentationIndex: { [string]: number },
	arrivalSerial: number,
	-- Tow delivery owns an exclusive source reservation while the truck is away. This
	-- prevents the normal 7-14s seller pump from stealing its FIFO slot.
	towReservations: { [string]: boolean },
}

local IncomingSellerQueue = {}
IncomingSellerQueue.CAPACITY = 3

local RUNTIME_FOLDER = "IncomingSellerQueueRuntime"
local FRONT_DEPTH = 18
local REAR_DEPTH = 32
local FALLBACK_CLEARANCE = 9
local QUEUE_DRIVE_SPEED = 32
local MOVE_TIMEOUT = 15
local ARRIVAL_TIMEOUT = 30
local ENTRY_EXTRA_SLOTS = 1.25
-- The generic R15 queue driver needs a consistent eye line across every authored cabin.
-- Some full-rig templates carry legacy negative NPC offsets for their R6 seller, which
-- otherwise leaves only a hat visible above the seat back while the car waits in FIFO.
local QUEUE_DRIVER_Y_OFFSET = 0.1

local states: { [Player]: State } = {}

local function upright(frame: CFrame): CFrame
	local look = Vector3.new(frame.LookVector.X, 0, frame.LookVector.Z)
	if look.Magnitude < 0.01 then
		look = Vector3.new(0, 0, -1)
	else
		look = look.Unit
	end
	return CFrame.lookAt(frame.Position, frame.Position + look)
end

local function sameRecord(a: Record?, b: Record?): boolean
	return a ~= nil and b ~= nil and a.folder == b.folder
end

local function destroyState(player: Player)
	local state = states[player]
	states[player] = nil
	if state ~= nil and state.folder.Parent ~= nil then
		state.folder:Destroy()
	end
end

local function stateFor(player: Player, record: Record): State
	local current = states[player]
	if current ~= nil and sameRecord(current.record, record) and current.folder.Parent ~= nil then
		-- TycoonService may return a fresh record table for the same authored folder.
		current.record = record
		-- Data can finish loading after the authored tycoon setup. Recover a persisted FIFO
		-- lazily instead of freezing the first empty runtime snapshot for the whole session.
		if #current.items == 0 then
			local loadedData = DataService.get(player)
			if loadedData ~= nil and #loadedData.incomingQueue > 0 then
				for _, item in loadedData.incomingQueue do
					table.insert(current.items, table.clone(item))
				end
			end
		end
		return current
	end
	destroyState(player)

	local carFolder = LotSlots.carFolder(record)
	local stale = carFolder:FindFirstChild(RUNTIME_FOLDER)
	if stale ~= nil then
		stale:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = RUNTIME_FOLDER
	folder:SetAttribute("OwnerUserId", player.UserId)
	folder.Parent = carFolder
	local restored: { Item } = {}
	local data = DataService.get(player)
	if data ~= nil then
		for _, item in data.incomingQueue do
			table.insert(restored, table.clone(item))
		end
	end
	local state: State = {
		record = record,
		folder = folder,
		items = restored,
		models = {},
		presentationIndex = {},
		arrivalSerial = 0,
		towReservations = {},
	}
	states[player] = state
	return state
end

local function persist(player: Player, state: State)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local saved = {}
	for _, item in state.items do
		table.insert(saved, table.clone(item))
	end
	data.incomingQueue = saved
end

local function towFootprintExtra(state: State, item: Item): number
	local model = state.models[item.queueId]
	return if item.source == "tow"
			and model ~= nil
			and model.Parent ~= nil
			and model:GetAttribute("TowCarrierQueueActive") == true
		then 1
		else 0
end

local function occupiedSlotCount(state: State): number
	local total = 0
	for _, item in state.items do
		total += 1 + towFootprintExtra(state, item)
	end
	return total
end

local function presentationIndexForItem(state: State, itemIndex: number): number
	local queueIndex = 0
	for index = 1, itemIndex do
		queueIndex += 1
		if index < itemIndex then
			queueIndex += towFootprintExtra(state, state.items[index])
		end
	end
	return queueIndex
end

local function nextPresentationIndex(state: State): number
	return occupiedSlotCount(state) + 1
end

local function authoredAnchor(record: Record, queueIndex: number): BasePart?
	local junk = record.zones.junk or record.zone
	local geometry = junk:FindFirstChild("QueueGeometry", true)
	local group = geometry and geometry:FindFirstChild("IncomingSeller")
	local anchor = group and group:FindFirstChild(("Queue%02d"):format(queueIndex))
	return if anchor ~= nil and anchor:IsA("BasePart") then anchor else nil
end

local function nearPart(part: BasePart, position: Vector3): boolean
	local localPosition = part.CFrame:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= part.Size.X * 0.5 + FALLBACK_CLEARANCE
		and math.abs(localPosition.Z) <= part.Size.Z * 0.5 + FALLBACK_CLEARANCE
end

local function fallbackBlocked(record: Record, position: Vector3): boolean
	-- Formula fallback must fail closed. Authored anchors are the normal path; if a future
	-- composition omits them, never stack a queue car on a pad, fence, bay, or street.
	for _, descendant in record.folder:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local name = string.lower(descendant:GetFullName())
		local prohibited = name:find("displaypadrepair", 1, true) ~= nil
			or name:find("padbase", 1, true) ~= nil
			or name:find("buypad", 1, true) ~= nil
			or name:find("fence", 1, true) ~= nil
			or name:find("repairbay", 1, true) ~= nil
		if prohibited and nearPart(descendant, position) then
			return true
		end
	end
	local streets = workspace:FindFirstChild("Streets")
	if streets ~= nil then
		for _, descendant in streets:GetDescendants() do
			if descendant:IsA("BasePart") and nearPart(descendant, position) then
				return true
			end
		end
	end
	return false
end

local function targetFrame(record: Record, queueIndex: number): (CFrame?, number?)
	local anchor = authoredAnchor(record, queueIndex)
	if anchor ~= nil then
		return upright(anchor.CFrame), anchor.Position.Y + anchor.Size.Y * 0.5
	end

	-- Two W-derived lanes x two depths. Unsafe computed positions are suppressed instead of
	-- placing a physical clone through progression pads or the live traffic road.
	local lane = ((queueIndex - 1) % 2) + 1
	local depth = if queueIndex <= 2 then FRONT_DEPTH else REAR_DEPTH
	local frame = LotSlots.parkedCFrame(record, lane) * CFrame.new(0, 0, depth)
	if fallbackBlocked(record, frame.Position) then
		return nil, nil
	end
	return upright(frame), LotNpc.groundY(frame.Position, {})
end

local function sanitize(model: Model)
	-- Central vehicle workers must be detached before queue presentation takes ownership.
	model:SetAttribute("VehicleRuntimeActive", false)
	CarVisuals.clearPrompts(model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetAttribute("QueueWasCanCollide", descendant.CanCollide)
			descendant:SetAttribute("QueueWasCanQuery", descendant.CanQuery)
			-- Dirt shells are welded followers. Anchoring both them and their source wheel
			-- breaks the weld when steering/spin updates that wheel independently.
			descendant.Anchored = descendant:GetAttribute("ConditionSurface") == nil
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
				-- Queue presentation temporarily owns the vehicle. Preserve the authored seat
				-- state so promotion cannot permanently strand a full drive rig disabled.
				descendant:SetAttribute("QueueWasDisabled", descendant.Disabled)
				descendant.Disabled = true
			end
		elseif descendant:IsA("ProximityPrompt") then
			-- Occupant.lua captures this authored instance once at startup. Destroying it made
			-- every promoted full rig permanently lose entry and listing automation.
			if descendant.Name == "DrivePrompt" then
				descendant.Enabled = false
			else
				descendant:Destroy()
			end
		elseif descendant:IsA("ClickDetector") then
			descendant:Destroy()
		end
	end
end

local function restoreDriveRig(model: Model)
	local hull = model:FindFirstChild("QueueCollisionHull")
	if hull ~= nil then
		hull:Destroy()
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local wasCollide = descendant:GetAttribute("QueueWasCanCollide")
			if typeof(wasCollide) == "boolean" then
				descendant.CanCollide = wasCollide
				descendant:SetAttribute("QueueWasCanCollide", nil)
			end
			local wasQuery = descendant:GetAttribute("QueueWasCanQuery")
			if typeof(wasQuery) == "boolean" then
				descendant.CanQuery = wasQuery
				descendant:SetAttribute("QueueWasCanQuery", nil)
			end
			if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
				-- Promotion to W restores presentation/physics, not player driving. The exact
				-- Ready ListingTransport session later unlocks this seat deliberately.
				descendant.Disabled = true
				descendant.CanTouch = false
				descendant:SetAttribute("QueueWasDisabled", nil)
			end
		elseif descendant:IsA("ProximityPrompt") then
			if descendant.Name == "DrivePrompt" then
				descendant.Enabled = false
			end
		end
	end
	-- Seller arrival and repair presentation are kinematic. Keeping the centralized
	-- vehicle runtime detached prevents Occupant from racing this lock and re-enabling entry.
	model:SetAttribute("DealerDriveLocked", true)
	model:SetAttribute("VehicleRuntimeActive", false)
end

local function ensureCollisionHull(model: Model)
	local existing = model:FindFirstChild("QueueCollisionHull")
	if existing ~= nil and existing:IsA("BasePart") then
		return
	elseif existing ~= nil then
		existing:Destroy()
	end

	local box, size = model:GetBoundingBox()
	local hull = Instance.new("Part")
	hull.Name = "QueueCollisionHull"
	hull.Size = Vector3.new(
		math.max(4, size.X * 0.82),
		math.max(2.5, math.min(4, size.Y * 0.65)),
		math.max(7, size.Z * 0.82)
	)
	hull.CFrame = box
	hull.Transparency = 1
	hull.Anchored = true
	-- Queue presentation moves anchored models by authored CFrames. A collidable hull at
	-- that speed behaves like a kinematic hammer, so this legacy hull is query-only.
	hull.CanCollide = false
	hull.CanTouch = false
	hull.CanQuery = true
	hull.CastShadow = false
	pcall(function()
		hull.CollisionGroup = "Car"
	end)
	hull.Parent = model
end

local function queueLabel(model: Model, queueIndex: number)
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if anchor == nil then
		return
	end
	local gui = model:FindFirstChild("QueueStatus", true)
	if gui ~= nil and not gui:IsA("BillboardGui") then
		gui:Destroy()
		gui = nil
	end
	if gui == nil then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "QueueStatus"
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.MaxDistance = 50
		billboard.Size = UDim2.fromOffset(150, 32)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.1, 0)
		billboard.Adornee = anchor
		billboard.Parent = anchor

		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBlack
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		text.TextStrokeTransparency = 0
		text.TextScaled = true
		text.Parent = billboard
		gui = billboard
	end
	if gui ~= nil and gui:IsA("BillboardGui") then
		-- Three large depth-compressed labels obscured the working car and PARK HERE marker.
		-- Only the actionable head of the FIFO needs a world label.
		gui.Enabled = queueIndex == 1
		gui.MaxDistance = 50
		gui.Size = UDim2.fromOffset(150, 32)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 5.1, 0)
	end
	local label = gui and gui:FindFirstChild("Label")
	if label ~= nil and label:IsA("TextLabel") then
		label.Text = if model:GetAttribute("QueueSource") == "tow" then "TOW DELIVERY" else "NEXT IN QUEUE"
	end
end

local function applyIdentity(model: Model, player: Player, item: Item, queueIndex: number)
	model.Name = ("IncomingQueueCar_%02d"):format(queueIndex)
	model:SetAttribute("IncomingSellerQueue", true)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("QueueId", item.queueId)
	-- This identity survives Queue -> Incoming -> owned Junk state. QueueId is intentionally
	-- not the save tradeId: it proves that the physical proxy itself was never replaced.
	model:SetAttribute("DealerProxyId", item.queueId)
	model:SetAttribute("QueueIndex", queueIndex)
	model:SetAttribute("QueueLane", 1)
	model:SetAttribute("QueueDepth", queueIndex)
	model:SetAttribute("TemplateId", item.templateId)
	model:SetAttribute("Ask", item.ask)
	model:SetAttribute("SellerId", item.sellerId)
	model:SetAttribute("QueueSource", item.source)
	model:SetAttribute("IncomingPaintHue", item.paintHue)
	model:SetAttribute("IncomingBodyKit", item.bodyKit == true)
	model:SetAttribute("IncomingNeonColorId", item.neonColorId)
	model:SetAttribute("TowStock", item.source == "tow" or item.towStock == true)
	model:SetAttribute(
		"QueueSlotFootprint",
		if model:GetAttribute("TowCarrierQueueActive") == true then 2 else 1
	)
	model:SetAttribute("MissingWheelCount", if item.missingWheels ~= nil then #item.missingWheels else 0)
	queueLabel(model, queueIndex)
end

local function applyVariant(model: Model, item: Item)
	CarVisuals.applyPaintHue(model, item.paintHue)
	CarVisuals.applyWindowTint(model, item.bodyKit == true or item.neonColorId ~= nil)
	local template = DealerCarConfig.templateById(item.templateId)
	CarVisuals.applyNeon(model, if template ~= nil then template.model else item.templateId, item.neonColorId)
end

local function applyQueueDriverFit(model: Model)
	if model:GetAttribute("QueueDriverFitApplied") == true then
		return
	end
	local authored = model:GetAttribute("NPCSeatYOffset")
	model:SetAttribute("QueueDriverFitApplied", true)
	model:SetAttribute("QueueHadNPCSeatYOffset", typeof(authored) == "number")
	model:SetAttribute("QueueOriginalNPCSeatYOffset", if typeof(authored) == "number" then authored else 0)
	model:SetAttribute("NPCSeatYOffset", QUEUE_DRIVER_Y_OFFSET)
end

local function restoreAuthoredDriverFit(model: Model)
	if model:GetAttribute("QueueDriverFitApplied") ~= true then
		return
	end
	local hadAuthored = model:GetAttribute("QueueHadNPCSeatYOffset") == true
	local authored = model:GetAttribute("QueueOriginalNPCSeatYOffset")
	model:SetAttribute("NPCSeatYOffset", if hadAuthored and typeof(authored) == "number" then authored else nil)
	model:SetAttribute("QueueDriverFitApplied", nil)
	model:SetAttribute("QueueHadNPCSeatYOffset", nil)
	model:SetAttribute("QueueOriginalNPCSeatYOffset", nil)
end

local function clearDrivers(model: Model)
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") ~= nil then
			LotNpc.destroy(child)
		end
	end
end

local function ensureDriver(model: Model, sellerId: string?, useSavedSeller: boolean?): Model?
	if useSavedSeller and sellerId == nil then
		warn("[IncomingSellerQueue] Tow delivery is missing its saved sellerId")
		return nil
	end
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") ~= nil then
			local expected = if useSavedSeller then "QueueTowSeller" else "QueueTrafficDriver"
			if child:GetAttribute(expected) == true
				and (not useSavedSeller or child:GetAttribute("PersonId") == sellerId)
			then
				return child
			end
			-- Restored snapshots may contain an old authored rig or a driver for a different
			-- seller identity. Replace it before seating the authoritative queue occupant.
			LotNpc.destroy(child)
		end
	end
	local pivot = model:GetPivot()
	local foot = Vector3.new(pivot.X, pivot.Y - 2, pivot.Z)
	local rig = LotNpc.spawn(
		if useSavedSeller then "JunkSeller" else "QueueTrafficDriver",
		model,
		foot,
		pivot.LookVector,
		if useSavedSeller then sellerId else nil
	)
	if rig ~= nil then
		if useSavedSeller and rig:GetAttribute("PersonId") ~= sellerId then
			warn(("[IncomingSellerQueue] Saved Tow seller appearance is unavailable: %s"):format(tostring(sellerId)))
			LotNpc.destroy(rig)
			return nil
		end
		rig:SetAttribute(if useSavedSeller then "QueueTowSeller" else "QueueTrafficDriver", true)
		LotNpc.seat(rig, model, CarVisuals.driverSeat(model))
	end
	return rig
end

local function movePivot(model: Model, target: CFrame, stateName: string)
	local start = model:GetPivot()
	if (start.Position - target.Position).Magnitude < 0.05 then
		model:PivotTo(target)
		model:SetAttribute("QueueState", "Queued")
		return
	end
	local token = (model:GetAttribute("QueueMoveToken") or 0) + 1
	model:SetAttribute("QueueMoveToken", token)
	model:SetAttribute("QueueState", stateName)
	model:SetAttribute("QueueTarget", target.Position)
	local points = { start.Position, target.Position }
	-- Ignore vertical travel when choosing the vehicle heading. A height-only correction
	-- must preserve yaw instead of standing the car on its bumper.
	local travel = points[2] - points[1]
	local flatTravel = Vector3.new(travel.X, 0, travel.Z)
	local initialFrame = if flatTravel.Magnitude > 0.01
		then CFrame.lookAt(points[1], points[1] + flatTravel.Unit)
		else CFrame.new(points[1]) * target.Rotation
	model:PivotTo(initialFrame)
	task.delay(MOVE_TIMEOUT, function()
		if model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token then
			-- Route recovery is identity-preserving: cancel only this move and snap the
			-- same queue model into its authoritative slot.
			model:SetAttribute("QueueMoveToken", token + 1)
			model:PivotTo(target)
			CarVisuals.resetWheels(model)
			model:SetAttribute("QueueState", "Queued")
		end
	end)
	task.spawn(function()
		local finished = RoadTraffic.drive(model, points, QUEUE_DRIVE_SPEED, function()
			return model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token
		end, { steer = false })
		if finished and model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token then
			model:PivotTo(target)
			CarVisuals.resetWheels(model)
			model:SetAttribute("QueueState", "Queued")
		end
	end)
end

local function placedFrame(model: Model, frame: CFrame, groundY: number, clearance: number?): CFrame
	-- Measuring ground clearance must never move the replicated queue model. A temporary
	-- PivotTo(target) + PivotTo(restore) on the live car is visible to clients as a teleport,
	-- especially while the FIFO refresh is also starting its normal forward drive.
	local probe = model:Clone()
	probe.Parent = nil
	CarVisuals.pivotToUprightFrame(probe, frame)
	CarVisuals.settleOnVisibleTires(probe, groundY, clearance or 0.02)
	local result = probe:GetPivot()
	probe:Destroy()
	return result
end

local function place(model: Model, record: Record, queueIndex: number, animate: boolean?, stateName: string?): boolean
	local frame, groundY = targetFrame(record, queueIndex)
	if frame == nil or groundY == nil then
		return false
	end
	local target = placedFrame(model, frame, groundY)
	if animate == true then
		movePivot(model, target, stateName or "Shifting")
	else
		model:PivotTo(target)
	end
	return true
end

local function towCarrierTargetFrame(cargo: Model, cargoTarget: CFrame): (Model?, CFrame?)
	local truck = cargo.Parent
	if truck == nil or not truck:IsA("Model") or truck.Parent == nil then
		return nil, nil
	end
	local mount = truck:GetPivot():ToObjectSpace(cargo:GetPivot())
	local rawRotation = cargoTarget.Rotation * mount.Rotation:Inverse()
	local flat = Vector3.new(rawRotation.LookVector.X, 0, rawRotation.LookVector.Z)
	local uprightRotation = if flat.Magnitude > 0.01
		then CFrame.lookAt(Vector3.zero, flat.Unit).Rotation
		else upright(rawRotation).Rotation
	local truckTarget = RoadTraffic.groundTowFrame(
		truck,
		CFrame.new(cargoTarget.Position - uprightRotation:VectorToWorldSpace(mount.Position)) * uprightRotation
	)
	return truck, truckTarget
end

local function placeTowCarrier(
	cargo: Model,
	record: Record,
	queueIndex: number,
	animate: boolean?
): boolean
	local frame, groundY = targetFrame(record, queueIndex)
	if frame == nil or groundY == nil then
		return false
	end
	local cargoTarget = placedFrame(cargo, frame, groundY)
	local truck, truckTarget = towCarrierTargetFrame(cargo, cargoTarget)
	if truck == nil or truckTarget == nil then
		return false
	end

	local token = (cargo:GetAttribute("QueueMoveToken") or 0) + 1
	cargo:SetAttribute("QueueMoveToken", token)
	cargo:SetAttribute("QueueTarget", cargoTarget.Position)
	local function finish()
		if cargo.Parent == truck
			and truck.Parent ~= nil
			and cargo:GetAttribute("QueueMoveToken") == token
			and cargo:GetAttribute("TowCarrierQueueActive") == true
		then
			truck:PivotTo(truckTarget)
			CarVisuals.resetWheels(truck)
			cargo:SetAttribute("QueueState", "Queued")
		end
	end
	if animate ~= true then
		finish()
		return true
	end

	cargo:SetAttribute("QueueState", "Shifting")
	task.delay(MOVE_TIMEOUT, finish)
	task.spawn(function()
		local finished = RoadTraffic.drive(
			truck,
			{ truck:GetPivot().Position, truckTarget.Position },
			math.min(18, QUEUE_DRIVE_SPEED),
			function()
				return cargo.Parent == truck
					and truck.Parent ~= nil
					and cargo:GetAttribute("QueueMoveToken") == token
					and cargo:GetAttribute("TowCarrierQueueActive") == true
			end,
			{
				steer = false,
				initialLook = truck:GetPivot().LookVector,
			}
		)
		if finished then
			finish()
		end
	end)
	return true
end

local function entryFrame(record: Record, queueIndex: number): (CFrame?, number?)
	local target, groundY = targetFrame(record, queueIndex)
	if target == nil or groundY == nil then
		return nil, nil
	end
	local points = RoadTraffic.arrivalPoints(record, target)
	if #points < 2 then
		return nil, nil
	end
	local direction = points[2] - points[1]
	local flat = Vector3.new(direction.X, 0, direction.Z)
	local rotation = if flat.Magnitude > 0.01
		then CFrame.lookAt(Vector3.zero, flat.Unit).Rotation
		else target.Rotation
	return CFrame.new(points[1]) * rotation, groundY
end

local function spawnModel(player: Player, state: State, item: Item, queueIndex: number, animateArrival: boolean?): Model?
	local finalFrame, finalGroundY = targetFrame(state.record, queueIndex)
	if finalFrame == nil or finalGroundY == nil then
		return nil
	end
	local entry, entryGroundY = if animateArrival == true
		then entryFrame(state.record, queueIndex)
		else finalFrame, finalGroundY
	if entry == nil or entryGroundY == nil then
		return nil
	end
	local model = CarVisuals.spawn(item.templateId, entry, state.folder)
	if model == nil then
		return nil
	end
	-- Identity supplies the stable queue seed used to choose the one missing wheel.
	applyIdentity(model, player, item, queueIndex)
	CarVisuals.applyCondition(model, {
		Body = false,
		Wheels = item.wheelsPresent ~= false,
		Engine = false,
	}, false, item.oilLeak ~= true, item.dirty ~= true, item.missingWheels)
	applyVariant(model, item)
	sanitize(model)
	ensureCollisionHull(model)
	model:PivotTo(placedFrame(model, entry, entryGroundY))
	applyQueueDriverFit(model)
	local restoredTow = item.source == "tow"
	local driver = ensureDriver(model, item.sellerId, restoredTow)
	if restoredTow and driver == nil then
		-- A rejoined Tow item must retain the same seller contract as a live unload. Refuse
		-- to materialize an anonymous queue presentation and retry on the next refresh.
		model:Destroy()
		return nil
	end
	state.presentationIndex[item.queueId] = queueIndex
	if animateArrival == true then
		local target = placedFrame(model, finalFrame, finalGroundY)
		local points = RoadTraffic.arrivalPoints(state.record, target)
		local token = (model:GetAttribute("QueueMoveToken") or 0) + 1
		model:SetAttribute("QueueMoveToken", token)
		model:SetAttribute("QueueState", "Approaching")
		model:SetAttribute("QueueTarget", target.Position)
		task.delay(ARRIVAL_TIMEOUT, function()
			if model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token then
				model:SetAttribute("QueueMoveToken", token + 1)
				model:PivotTo(target)
				CarVisuals.resetWheels(model)
				model:SetAttribute("QueueState", "Queued")
				for currentItemIndex, current in state.items do
					if current.queueId == item.queueId then
						local currentQueueIndex = presentationIndexForItem(state, currentItemIndex)
						if currentQueueIndex ~= queueIndex then
							applyIdentity(model, player, item, currentQueueIndex)
							state.presentationIndex[item.queueId] = currentQueueIndex
							place(model, state.record, currentQueueIndex, true, "Shifting")
						end
						break
					end
				end
			end
		end)
		task.spawn(function()
			local finished = RoadTraffic.drive(model, points, QUEUE_DRIVE_SPEED, function()
				return model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token
			end, { steer = true })
			if finished and model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token then
				model:PivotTo(target)
				CarVisuals.resetWheels(model)
				model:SetAttribute("QueueState", "Queued")
				-- The FIFO may have advanced while this long road approach was running. Finish the
				-- arrival first, then shift this exact model to its current authoritative index.
				local currentQueueIndex: number? = nil
				for currentItemIndex, current in state.items do
					if current.queueId == item.queueId then
						currentQueueIndex = presentationIndexForItem(state, currentItemIndex)
						break
					end
				end
				if currentQueueIndex ~= nil and currentQueueIndex ~= queueIndex then
					applyIdentity(model, player, item, currentQueueIndex)
					state.presentationIndex[item.queueId] = currentQueueIndex
					place(model, state.record, currentQueueIndex, true, "Shifting")
				end
			end
		end)
	else
		model:PivotTo(placedFrame(model, finalFrame, finalGroundY))
		model:SetAttribute("QueueState", "Queued")
	end
	return model
end

local function refresh(player: Player, state: State)
	local live: { [string]: boolean } = {}
	for itemIndex, item in state.items do
		local queueIndex = presentationIndexForItem(state, itemIndex)
		live[item.queueId] = true
		local model = state.models[item.queueId]
		if model ~= nil and model.Parent == nil then
			state.models[item.queueId] = nil
			model = nil
		end
		if model == nil then
			-- Restored queue snapshots are already waiting stock and should snap into place.
			-- A newly appended live seller alone receives the full road-to-queue approach.
			local liveArrival = itemIndex == state.arrivalSerial
			model = spawnModel(player, state, item, queueIndex, liveArrival)
			state.models[item.queueId] = model
		else
			applyIdentity(model, player, item, queueIndex)
			local oldIndex = state.presentationIndex[item.queueId]
			if oldIndex ~= queueIndex
				and model:GetAttribute("QueueState") ~= "Approaching"
			then
				local isTowCarrier = model:GetAttribute("TowCarrierQueueActive") == true
				local placed = if isTowCarrier
					then placeTowCarrier(model, state.record, queueIndex, true)
					else place(model, state.record, queueIndex, true, "Shifting")
				if not placed then
					if isTowCarrier then
						warn(("[IncomingSellerQueue] Tow carrier could not shift to Queue%02d"):format(queueIndex))
					else
						model:Destroy()
						state.models[item.queueId] = nil
						model = nil
					end
				end
			end
			state.presentationIndex[item.queueId] = queueIndex
		end
		if model ~= nil then
			applyIdentity(model, player, item, queueIndex)
		end
	end
	for queueId, model in state.models do
		if live[queueId] ~= true then
			model:Destroy()
			state.models[queueId] = nil
			state.presentationIndex[queueId] = nil
		end
	end
	local occupied = occupiedSlotCount(state)
	state.folder:SetAttribute("QueueItemCount", #state.items)
	state.folder:SetAttribute("QueueCount", occupied)
	if player.Parent ~= nil then
		Remotes.QueueUpdate:FireClient(player, {
			count = occupied,
			capacity = IncomingSellerQueue.CAPACITY,
		})
	end
end

function IncomingSellerQueue.ensure(player: Player, record: Record)
	local state = stateFor(player, record)
	refresh(player, state)
end

function IncomingSellerQueue.count(player: Player): number
	local state = states[player]
	return if state ~= nil then occupiedSlotCount(state) else 0
end

local function hasTowReservation(state: State): boolean
	return next(state.towReservations) ~= nil
end

-- Normal live sellers may append only while no tow cycle owns the source lane.
function IncomingSellerQueue.canEnqueue(player: Player): boolean
	local state = states[player]
	return state ~= nil
		and not hasTowReservation(state)
		and occupiedSlotCount(state) < IncomingSellerQueue.CAPACITY
end

-- The reservation is intentionally exclusive even while Q is full. It lets existing stock
-- drain to a safe one-car corridor, while preventing the normal source pump from refilling it.
function IncomingSellerQueue.reserveTow(player: Player, record: Record, reservationId: string): boolean
	if reservationId == "" then
		return false
	end
	local state = stateFor(player, record)
	if state.towReservations[reservationId] == true then
		return true
	end
	if hasTowReservation(state) then
		return false
	end
	state.towReservations[reservationId] = true
	state.folder:SetAttribute("TowReservationId", reservationId)
	state.folder:SetAttribute("TowReservationActive", true)
	return true
end

function IncomingSellerQueue.towLaneReady(player: Player, record: Record, reservationId: string): boolean
	local state = states[player]
	return state ~= nil
		and sameRecord(state.record, record)
		and state.towReservations[reservationId] == true
		and occupiedSlotCount(state) <= IncomingSellerQueue.CAPACITY - 2
end

function IncomingSellerQueue.releaseTow(player: Player, reservationId: string)
	local state = states[player]
	if state == nil or state.towReservations[reservationId] ~= true then
		return
	end
	state.towReservations[reservationId] = nil
	if not hasTowReservation(state) then
		state.folder:SetAttribute("TowReservationId", nil)
		state.folder:SetAttribute("TowReservationActive", nil)
	end
end

function IncomingSellerQueue.peek(player: Player): Item?
	local state = states[player]
	return if state ~= nil then state.items[1] else nil
end

function IncomingSellerQueue.headReady(player: Player, expectedQueueId: string?): boolean
	local state = states[player]
	local head = state and state.items[1]
	local model = state and head and state.models[head.queueId]
	local queueState = if model ~= nil then model:GetAttribute("QueueState") else nil
	return state ~= nil
		and head ~= nil
		and (expectedQueueId == nil or head.queueId == expectedQueueId)
		and model ~= nil
		and model.Parent ~= nil
		and model:GetAttribute("QueueIndex") == 1
		and (queueState == "Queued" or queueState == "Prestaged")
end

-- As soon as the salesman reverses the sold car clear of W, let the presentation-only FIFO
-- head occupy the empty slab. Save ownership stays in the queue until the old W -> P commit,
-- so an interrupted listing can put this same queueId back without duplicating or losing it.
function IncomingSellerQueue.prestageHead(player: Player, record: Record, workingIndex: number): (boolean, string?)
	local state = states[player]
	local head = state and state.items[1]
	local model = state and head and state.models[head.queueId]
	if state == nil
		or not sameRecord(state.record, record)
		or head == nil
		or model == nil
		or model.Parent == nil
		or model:GetAttribute("QueueIndex") ~= 1
		or model:GetAttribute("QueueState") ~= "Queued"
		or model:GetAttribute("TowCarrierQueueActive") == true
		or LotSlots.platform(record, workingIndex) == nil
	then
		return false, nil
	end

	local target = placedFrame(
		model,
		upright(LotSlots.parkedCFrame(record, workingIndex)),
		LotSlots.platformTop(record, workingIndex),
		DealerCarConfig.PARK_CLEARANCE
	)
	local points = LotSlots.queuePromotionPoints(record, model:GetPivot(), target)
	if #points < 2 then
		return false, nil
	end
	local token = (model:GetAttribute("QueueMoveToken") or 0) + 1
	model:SetAttribute("QueueMoveToken", token)
	model:SetAttribute("QueueState", "Prestaging")
	model:SetAttribute("PrestagedWorkingIndex", workingIndex)
	model:SetAttribute("QueueTarget", target.Position)
	local queueId = head.queueId

	local function finishAtWorkingPad()
		if model.Parent ~= nil and model:GetAttribute("QueueMoveToken") == token then
			model:PivotTo(target)
			CarVisuals.resetWheels(model)
			model:SetAttribute("QueueState", "Prestaged")
		end
	end
	task.delay(MOVE_TIMEOUT, finishAtWorkingPad)
	task.spawn(function()
		local finished = RoadTraffic.drive(model, points, QUEUE_DRIVE_SPEED, function()
			return model.Parent ~= nil
				and model:GetAttribute("QueueMoveToken") == token
				and state.items[1] ~= nil
				and state.items[1].queueId == queueId
		end, { steer = true })
		if finished then
			finishAtWorkingPad()
		end
	end)
	return true, queueId
end

function IncomingSellerQueue.cancelPrestage(player: Player, expectedQueueId: string)
	local state = states[player]
	local head = state and state.items[1]
	local model = state and head and state.models[head.queueId]
	if state == nil or head == nil or head.queueId ~= expectedQueueId or model == nil or model.Parent == nil then
		return
	end
	local queueState = model:GetAttribute("QueueState")
	if queueState ~= "Prestaging" and queueState ~= "Prestaged" then
		return
	end
	model:SetAttribute("QueueMoveToken", (model:GetAttribute("QueueMoveToken") or 0) + 1)
	model:SetAttribute("PrestagedWorkingIndex", nil)
	applyIdentity(model, player, head, 1)
	state.presentationIndex[head.queueId] = 1
	if not place(model, state.record, 1, true, "Shifting") then
		model:Destroy()
		state.models[head.queueId] = nil
		refresh(player, state)
	end
end

-- Builds the exact broken car while it is still off-site. It stays completely empty while
-- mounted on the hook; the saved seller is attached only after the car touches its queue slot.
function IncomingSellerQueue.prepareTowCargo(
	player: Player,
	record: Record,
	item: Item,
	reservationId: string
): Model?
	local state = states[player]
	if state == nil
		or not sameRecord(state.record, record)
		or state.towReservations[reservationId] ~= true
	then
		return nil
	end
	local model = CarVisuals.spawn(item.templateId, CFrame.new(0, -1000, 0), state.folder)
	if model == nil then
		return nil
	end
	-- Tow cargo needs the same stable wheel choice before it is mounted off-site.
	model:SetAttribute("DealerProxyId", item.queueId)
	model:SetAttribute("TemplateId", item.templateId)
	CarVisuals.applyCondition(model, {
		Body = false,
		Wheels = item.wheelsPresent ~= false,
		Engine = false,
	}, false, item.oilLeak ~= true, item.dirty ~= true, item.missingWheels)
	applyVariant(model, item)
	sanitize(model)
	-- Full-rig templates and old snapshots may carry an authored occupant. Tow cargo must
	-- visibly remain an unoccupied recovery vehicle for the entire offsite/hook phase.
	clearDrivers(model)
	ensureCollisionHull(model)
	model.Name = "TowCargo"
	model:SetAttribute("TowCargo", true)
	model:SetAttribute("TowReservationId", reservationId)
	model:SetAttribute("QueueSource", "tow")
	return model
end

function IncomingSellerQueue.towDeliveryFrame(
	player: Player,
	record: Record,
	reservationId: string,
	cargo: Model
): CFrame?
	local state = states[player]
	if state == nil
		or not sameRecord(state.record, record)
		or state.towReservations[reservationId] ~= true
		or cargo.Parent == nil
		or occupiedSlotCount(state) > IncomingSellerQueue.CAPACITY - 2
	then
		return nil
	end
	local frame, groundY = targetFrame(record, nextPresentationIndex(state))
	if frame == nil or groundY == nil then
		return nil
	end
	return placedFrame(cargo, frame, groundY)
end

local function unloadTowCarrier(
	player: Player,
	state: State,
	item: Item,
	cargo: Model,
	workingIndex: number
): boolean
	local truck = cargo.Parent
	if truck == nil
		or not truck:IsA("Model")
		or truck.Parent == nil
		or cargo:GetAttribute("TowCarrierQueueActive") ~= true
		or LotSlots.platform(state.record, workingIndex) == nil
	then
		return false
	end
	local cargoTarget = placedFrame(
		cargo,
		upright(LotSlots.parkedCFrame(state.record, workingIndex)),
		LotSlots.platformTop(state.record, workingIndex),
		DealerCarConfig.PARK_CLEARANCE
	)
	local mount = truck:GetPivot():ToObjectSpace(cargo:GetPivot())
	local rawRotation = cargoTarget.Rotation * mount.Rotation:Inverse()
	local flat = Vector3.new(rawRotation.LookVector.X, 0, rawRotation.LookVector.Z)
	local uprightRotation = if flat.Magnitude > 0.01
		then CFrame.lookAt(Vector3.zero, flat.Unit).Rotation
		else upright(rawRotation).Rotation
	local truckTarget = RoadTraffic.groundTowFrame(
		truck,
		CFrame.new(cargoTarget.Position - uprightRotation:VectorToWorldSpace(mount.Position)) * uprightRotation
	)
	local points = LotSlots.queuePromotionPoints(state.record, truck:GetPivot(), truckTarget)
	if #points < 2 then
		return false
	end
	cargo:SetAttribute("QueueState", "TowUnloading")
	truck:SetAttribute("TowTruckWaitingInQueue", nil)
	truck:SetAttribute("TowTruckUnloading", true)
	local finished = RoadTraffic.drive(truck, points, math.min(18, QUEUE_DRIVE_SPEED), function()
		return player.Parent ~= nil
			and truck.Parent ~= nil
			and cargo.Parent == truck
			and cargo:GetAttribute("TowCarrierQueueActive") == true
			and state.items[1] ~= nil
			and state.items[1].queueId == item.queueId
	end, {
		steer = true,
		initialLook = truck:GetPivot().LookVector,
	})
	if not finished or truck.Parent == nil or cargo.Parent ~= truck then
		truck:SetAttribute("TowTruckUnloading", nil)
		cargo:SetAttribute("QueueState", "Queued")
		return false
	end
	truck:PivotTo(truckTarget)
	CarVisuals.resetWheels(truck)
	cargo.Parent = state.folder
	cargo:PivotTo(cargoTarget)
	cargo:SetAttribute("TowCarrierQueueActive", nil)
	cargo:SetAttribute("TowCargoMounted", nil)
	cargo:SetAttribute("TowCargo", nil)
	cargo:SetAttribute("TowReservationId", nil)
	cargo:SetAttribute("QueueState", "Queued")
	truck:SetAttribute("TowTruckUnloading", nil)
	truck:SetAttribute("TowQueueId", nil)
	truck:SetAttribute("TowCargoQueueId", nil)
	truck:SetAttribute("TowQueueSlotFootprint", nil)
	return true
end

-- Atomic visual + save-FIFO handoff. The exact car stays mounted on the truck while its FIFO
-- item waits; it is detached only when take() owns the free W platform.
function IncomingSellerQueue.enqueueTowDelivery(
	player: Player,
	record: Record,
	item: Item,
	reservationId: string,
	cargo: Model
): boolean
	local state = states[player]
	if state == nil
		or not sameRecord(state.record, record)
		or state.towReservations[reservationId] ~= true
		or cargo.Parent == nil
		or occupiedSlotCount(state) > IncomingSellerQueue.CAPACITY - 2
	then
		return false
	end
	local queueIndex = nextPresentationIndex(state)
	local frame, groundY = targetFrame(record, queueIndex)
	if frame == nil or groundY == nil then
		return false
	end
	local truck = cargo.Parent
	if truck == nil or not truck:IsA("Model") then
		return false
	end
	-- The carrier has reached its queue slot. Attach the saved seller now: the recovery car
	-- stays empty while off-site, but it must never look self-driving while waiting to unload.
	applyIdentity(cargo, player, item, queueIndex)
	applyQueueDriverFit(cargo)
	local seller = ensureDriver(cargo, item.sellerId, true)
	if seller == nil or seller:GetAttribute("PersonId") ~= item.sellerId then
		warn(("[IncomingSellerQueue] Tow queue blocked: seller mismatch queue=%s expected=%s"):format(
			item.queueId,
			tostring(item.sellerId)
		))
		return false
	end
	cargo:SetAttribute("TowCarrierQueueActive", true)
	cargo:SetAttribute("QueueSlotFootprint", 2)
	cargo:SetAttribute("QueueState", "Queued")
	truck:SetAttribute("TowTruckWaitingInQueue", true)
	truck:SetAttribute("TowQueueSlotFootprint", 2)
	truck:SetAttribute("TowQueueId", item.queueId)
	truck:SetAttribute("TowCargoQueueId", item.queueId)
	table.insert(state.items, item)
	state.models[item.queueId] = cargo
	state.presentationIndex[item.queueId] = queueIndex
	state.towReservations[reservationId] = nil
	state.folder:SetAttribute("TowReservationId", nil)
	state.folder:SetAttribute("TowReservationActive", nil)
	persist(player, state)
	refresh(player, state)
	return true
end

function IncomingSellerQueue.enqueue(player: Player, record: Record, item: Item): boolean
	local state = stateFor(player, record)
	if hasTowReservation(state) or occupiedSlotCount(state) >= IncomingSellerQueue.CAPACITY then
		return false
	end
	table.insert(state.items, item)
	state.arrivalSerial = #state.items
	persist(player, state)
	refresh(player, state)
	state.arrivalSerial = 0
	return true
end

function IncomingSellerQueue.take(player: Player, expectedQueueId: string, workingIndex: number?): (Item?, Model?)
	local state = states[player]
	local head = state and state.items[1]
	local model = state and head and state.models[head.queueId]
	if state == nil
		or head == nil
		or head.queueId ~= expectedQueueId
		or model == nil
		or model.Parent == nil
		or model:GetAttribute("QueueIndex") ~= 1
		or (model:GetAttribute("QueueState") ~= "Queued" and model:GetAttribute("QueueState") ~= "Prestaged")
	then
		return nil, nil
	end
	local item = head
	local liveTowCarrier = item.source == "tow" and model:GetAttribute("TowCarrierQueueActive") == true
	if liveTowCarrier then
		if workingIndex == nil or not unloadTowCarrier(player, state, item, model, workingIndex) then
			warn(("[IncomingSellerQueue] Tow unload failed queue=%s W=%s"):format(
				item.queueId,
				tostring(workingIndex)
			))
			return nil, nil
		end
	end
	local seller: Model? = nil
	if item.source == "tow" then
		-- Validate (or reconstruct) the saved seller before mutating FIFO state. This also
		-- captures the exact rig that rode on live Tow cargo, so promotion does not destroy it.
		seller = ensureDriver(model, item.sellerId, true)
		if seller == nil or seller:GetAttribute("PersonId") ~= item.sellerId then
			warn(("[IncomingSellerQueue] Tow promotion blocked: seller mismatch queue=%s expected=%s"):format(
				item.queueId,
				tostring(item.sellerId)
			))
			return nil, nil
		end
	end
	table.remove(state.items, 1)
	-- The queue is only a frozen presentation state. Restore the original controller,
	-- lighting and seat flags before this exact model becomes the live deal car.
	restoreAuthoredDriverFit(model)
	restoreDriveRig(model)
	-- Inspection, driving and listing all key off this name. Leaving the FIFO label
	-- made W1 click the previous Bavora card while a Wronkler sat on the pad.
	model.Name = "DealerCar"
	-- Normal queue arrivals use a generic traffic driver; Tow deliveries already carry the
	-- exact saved seller after unloading. Reuse that rig instead of spawning a duplicate.
	for _, child in model:GetChildren() do
		if child:IsA("Model")
			and child:FindFirstChildOfClass("Humanoid") ~= nil
		then
			if child == seller then
				child:SetAttribute("QueueTowSeller", nil)
				child.Name = "JunkSeller"
			elseif child:GetAttribute("QueueTrafficDriver") == true
				or child:GetAttribute("QueueTowSeller") == true
			then
				LotNpc.destroy(child)
			end
		end
	end
	local pivot = model:GetPivot()
	if seller == nil and not liveTowCarrier then
		-- Non-Tow arrivals deliberately replace their generic traffic driver with the saved
		-- authored seller at promotion. Restored Tow snapshots also use this compatibility path.
		seller = LotNpc.spawn(
			"JunkSeller",
			model,
			Vector3.new(pivot.X, pivot.Y - 2, pivot.Z),
			pivot.LookVector,
			item.sellerId
		)
	end
	if seller ~= nil then
		-- Queue fit was restored above; recalculate the authored seat fit for the promoted car.
		LotNpc.seat(seller, model, CarVisuals.driverSeat(model))
	end
	state.models[item.queueId] = nil
	state.presentationIndex[item.queueId] = nil
	persist(player, state)
	model:SetAttribute("QueueMoveToken", (model:GetAttribute("QueueMoveToken") or 0) + 1)
	model:SetAttribute("QueueState", "Promoting")
	local status = model:FindFirstChild("QueueStatus", true)
	if status ~= nil then
		status:Destroy()
	end
	for _, attribute in ipairs({
		"IncomingSellerQueue",
		"QueueId",
		"QueueIndex",
		"QueueLane",
		"QueueDepth",
		"QueueMoveToken",
		"QueueTarget",
		"QueueSource",
		"QueueSlotFootprint",
		"PrestagedWorkingIndex",
		"TowCarrierQueueActive",
		"TowCargoMounted",
		"TowCargo",
		"TowReservationId",
	}) do
		model:SetAttribute(attribute, nil)
	end
	refresh(player, state)
	return item, model
end

function IncomingSellerQueue.clear(player: Player)
	destroyState(player)
end

function IncomingSellerQueue.release(record: Record)
	local players: { Player } = {}
	for player, state in states do
		if sameRecord(state.record, record) then
			table.insert(players, player)
		end
	end
	for _, player in players do
		destroyState(player)
	end
end

function IncomingSellerQueue.snapshot(player: Player): { Item }
	local result: { Item } = {}
	local state = states[player]
	if state ~= nil then
		for _, item in state.items do
			table.insert(result, table.clone(item))
		end
	end
	return result
end

return IncomingSellerQueue
