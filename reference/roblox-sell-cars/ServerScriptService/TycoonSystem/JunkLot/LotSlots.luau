--!strict

-- Every physical anchor point on a junk lot: where cars park, where a seller stands,
-- and which road node the lot uses as its driveway.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadGraph = require(ReplicatedStorage.RoadGraph)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)

local LotSlots = {}

export type Record = {
	folder: Folder,
	zone: Instance,
	zones: { [string]: Instance },
	locked: Folder,
	owner: Player?,
}

function LotSlots.tycoonIndex(record: Record): number?
	local digits = string.match(record.folder.Name, "^Tycoon(%d+)$")
	return if digits ~= nil then tonumber(digits) else nil
end

local ROAD_UPSTREAM = { 218, 116, 175, 30, 225, 115, 127, 59 }
local ROAD_DOWNSTREAM = { 140, 88, 275, 31, 269, 26, 61, 226 }

local function flatUnit(v: Vector3): Vector3
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude < 0.01 then
		return Vector3.new(0, 0, 1)
	end
	return flat.Unit
end

local function laneSide(direction: Vector3): Vector3
	return Vector3.new(-direction.Z, 0, direction.X)
end

-- The old nodes described the pre-move compositions. Each pair now brackets the exact
-- section of front road shared by the repair driveway and the Used Cars entrance.
function LotSlots.roadNodes(record: Record, fallback: Vector3): (number, number)
	local index = LotSlots.tycoonIndex(record)
	local upstream = if index ~= nil then ROAD_UPSTREAM[index] else nil
	upstream = upstream or RoadGraph.nearestNode(fallback)
	local downstream = if index ~= nil then ROAD_DOWNSTREAM[index] else nil
	if downstream == nil then
		local neighbours = RoadGraph.neighbours(upstream)
		downstream = if neighbours[1] ~= nil then neighbours[1].to else upstream
	end
	return upstream, downstream
end

function LotSlots.roadEntryNode(record: Record, fallback: Vector3): number
	return select(1, LotSlots.roadNodes(record, fallback))
end

-- Project any authored lot gate onto its actual front-road segment, then put it in the
-- correct near-side traffic lane. This follows whole-composition moves without stale X/Z.
function LotSlots.roadLane(record: Record, point: Vector3): (Vector3, Vector3, number, number)
	local upstream, downstream = LotSlots.roadNodes(record, point)
	local a = RoadGraph.position(upstream)
	local b = RoadGraph.position(downstream)
	local direction = flatUnit(b - a)
	local span = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local fromA = Vector3.new(point.X - a.X, 0, point.Z - a.Z)
	local alpha = if span.Magnitude > 0.01
		then math.clamp(fromA:Dot(span) / span:Dot(span), 0, 1)
		else 0
	local center = a:Lerp(b, alpha)
	local lane = center
		+ laneSide(direction) * DealerCarConfig.ROAD_LANE_OFFSET
		+ Vector3.new(0, DealerCarConfig.ROAD_HEIGHT, 0)
	return lane, direction, upstream, downstream
end

-- Used Cars can sit beyond the repair driveway's authored road segment. Extend the
-- projection by one segment only when the road continues virtually straight; otherwise the
-- clamped driveway cuts diagonally through the perimeter fence on even-numbered lots.
function LotSlots.usedRoadLane(record: Record, point: Vector3): (Vector3, Vector3, number, number)
	local upstream, downstream = LotSlots.roadNodes(record, point)
	local a = RoadGraph.position(upstream)
	local b = RoadGraph.position(downstream)
	local direction = flatUnit(b - a)
	local span = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local fromA = Vector3.new(point.X - a.X, 0, point.Z - a.Z)
	local denominator = span:Dot(span)
	local rawAlpha = if denominator > 0.0001 then fromA:Dot(span) / denominator else 0
	if rawAlpha > 1 then
		local extension: number? = nil
		local bestDot = 0.98
		for _, link in RoadGraph.neighbours(downstream) do
			if link.to == upstream then
				continue
			end
			local candidateDirection = flatUnit(RoadGraph.position(link.to) - b)
			local dot = direction:Dot(candidateDirection)
			if dot > bestDot then
				bestDot = dot
				extension = link.to
			end
		end
		if extension ~= nil then
			upstream = downstream
			downstream = extension
			a = RoadGraph.position(upstream)
			b = RoadGraph.position(downstream)
			direction = flatUnit(b - a)
			span = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			fromA = Vector3.new(point.X - a.X, 0, point.Z - a.Z)
		end
	end

	denominator = span:Dot(span)
	local alpha = if denominator > 0.0001
		then math.clamp(fromA:Dot(span) / denominator, 0, 1)
		else 0
	local center = a:Lerp(b, alpha)
	local lane = center
		+ laneSide(direction) * DealerCarConfig.ROAD_LANE_OFFSET
		+ Vector3.new(0, DealerCarConfig.ROAD_HEIGHT, 0)
	return lane, direction, upstream, downstream
end

function LotSlots.roadEntryPosition(record: Record, fallback: Vector3): Vector3
	return select(1, LotSlots.roadLane(record, fallback))
end

function LotSlots.resolveWorkingIndex(index: number?): number?
	local resolved = index or 1
	return if resolved >= 1 and resolved <= DealerCarConfig.MAX_WORKING_SLOTS then resolved else nil
end

function LotSlots.resolveDisplayIndex(index: number?): number?
	local resolved = index or 1
	return if resolved >= 1 and resolved <= DealerCarConfig.MAX_DISPLAY_SLOTS then resolved else nil
end

local function repairSurfaceWithin(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	local slab = instance:FindFirstChild("Base", true)
	if slab ~= nil and slab:IsA("BasePart") then
		return slab
	end
	return nil
end

-- Exact W1/W2 repair slab. Authored slot identity wins; stable names preserve older copies.
function LotSlots.platform(record: Record, workingIndex: number?): BasePart?
	local resolvedIndex = LotSlots.resolveWorkingIndex(workingIndex)
	if resolvedIndex == nil then
		return nil
	end
	local junkZone = record.zones.junk or record.zone
	local usedCarsZone = record.zones.usedcars or record.folder:FindFirstChild("JunkSpot_UsedCars", true)
	local searchZones: { Instance } = { junkZone }
	if usedCarsZone ~= nil and usedCarsZone ~= junkZone then
		table.insert(searchZones, usedCarsZone)
	end

	-- Search only the two authored dealer zones; sale parking has no WorkingSlotIndex.
	for _, zone in searchZones do
		for _, descendant in zone:GetDescendants() do
			if descendant:GetAttribute("WorkingSlotIndex") == resolvedIndex then
				local attributed = repairSurfaceWithin(descendant)
				if attributed ~= nil then
					return attributed
				end
			end
		end
	end
	local platformName = if resolvedIndex == 2 then "DisplayPadRepair2" else "DisplayPadRepair"
	for _, zone in searchZones do
		local platform = zone:FindFirstChild(platformName, true)
		if platform ~= nil then
			local exact = repairSurfaceWithin(platform)
			if exact ~= nil then
				return exact
			end
		end
	end
	-- Only W1 may use the pre-index migration fallback. W2 must never stack on W1.
	if resolvedIndex == 1 then
		local fallback = junkZone:FindFirstChild("RepairPad", true)
			or junkZone:FindFirstChild("RepairPadBase", true)
		if fallback ~= nil and fallback:IsA("BasePart") then
			return fallback
		end
	end
	return nil
end

-- Top face of the selected repair slab.
function LotSlots.platformTop(record: Record, workingIndex: number?): number
	local anchor = LotSlots.platform(record, workingIndex)
	if anchor == nil then
		return record.folder:GetPivot().Position.Y
	end
	return anchor.Position.Y + anchor.Size.Y * 0.5
end

local function parkingSurfaceWithin(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	local named = instance:FindFirstChild("ParkingSurface", true)
	if named ~= nil and named:IsA("BasePart") then
		return named
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

function LotSlots.awaitingDisplayPlatform(record: Record, index: number): BasePart?
	if index < 1 or index > 2 then return nil end
	local display = record.folder:FindFirstChild("JunkSpot_UsedCars", true)
	local queue = if display ~= nil then display:FindFirstChild("AwaitingDisplayQueue") else nil
	if queue == nil then return nil end
	local named = queue:FindFirstChild("Q" .. index)
	if named ~= nil and named:IsA("BasePart") then return named end
	for _, descendant in queue:GetDescendants() do
		if descendant:IsA("BasePart")
			and descendant:GetAttribute("AwaitingDisplayQueueIndex") == index
		then
			return descendant
		end
	end
	return nil
end

function LotSlots.salePlatform(record: Record, index: number?): BasePart?
	local resolvedIndex = LotSlots.resolveDisplayIndex(index)
	if resolvedIndex == nil then
		return nil
	end
	local display = record.folder:FindFirstChild("JunkSpot_UsedCars", true)
	if display == nil then
		return nil
	end

	-- The named ParkingSpace model is the physical sale slot. Purchase PadBase/BuyPad
	-- parts intentionally share UsedCarsSlotIndex, so attribute-first descendant order can
	-- otherwise route a car to the purchase button (Tycoon6 P3 reproduced this).
	local expectedName = ("ParkingSpace_%02d"):format(resolvedIndex)
	local namedSpace = display:FindFirstChild(expectedName, true)
	if namedSpace ~= nil then
		local exact = parkingSurfaceWithin(namedSpace)
		if exact ~= nil then
			return exact
		end
	end

	-- Attribute fallback is restricted to a real ParkingSpace subtree. Never accept a
	-- PadBase/BuyPad carrying the same economy metadata as a parking surface.
	for _, descendant in display:GetDescendants() do
		if descendant:GetAttribute("UsedCarsSlotIndex") == resolvedIndex
			or descendant:GetAttribute("SpaceIndex") == resolvedIndex
			or descendant:GetAttribute("ParkingSpaceId") == ("RepairBayParking_%02d"):format(resolvedIndex)
		then
			local ancestor: Instance? = descendant
			local isParkingSpace = false
			while ancestor ~= nil and ancestor ~= display do
				if string.match(ancestor.Name, "^ParkingSpace_%d%d$") ~= nil then
					isParkingSpace = true
					break
				end
				ancestor = ancestor.Parent
			end
			if isParkingSpace then
				local attributed = parkingSurfaceWithin(descendant)
				if attributed ~= nil then
					return attributed
				end
			end
		end
	end

	-- Preserve the legacy P1 marker while old scene copies are still in circulation.
	if resolvedIndex == 1 then
		for _, descendant in display:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:GetAttribute("UsedCarsActiveSlot") == true then
				return descendant
			end
		end
	end
	return nil
end

function LotSlots.usedLotEntrance(record: Record): BasePart?
	local display = record.folder:FindFirstChild("JunkSpot_UsedCars", true)
	local gate = if display ~= nil then display:FindFirstChild("UsedLotEntranceReference", true) else nil
	return if gate ~= nil and gate:IsA("BasePart") then gate else nil
end

function LotSlots.saleTop(record: Record, index: number?): number
	local anchor = LotSlots.salePlatform(record, index)
	return if anchor ~= nil then anchor.Position.Y + anchor.Size.Y * 0.5 else LotSlots.platformTop(record)
end

function LotSlots.isDisplayState(state: string): boolean
	return state == "Listed" or state == "Offer"
end

-- Seller cars drive straight in along the pad's long local-X axis. Parking nose-in avoids
-- the old forced U-turn; departures deliberately reverse back to the driveway.
local function noseIn(record: Record, anchor: BasePart?, top: number): CFrame
	if anchor == nil then
		return record.folder:GetPivot()
	end
	local base = Vector3.new(anchor.Position.X, top, anchor.Position.Z)
	local driveway = LotSlots.roadEntryPosition(record, base)
	local inward = Vector3.new(base.X - driveway.X, 0, base.Z - driveway.Z)
	local axis = flatUnit(anchor.CFrame.RightVector)
	if inward.Magnitude > 0.01 and axis:Dot(inward) < 0 then
		axis = -axis
	end
	return CFrame.lookAt(base, base + axis)
end

function LotSlots.parkedCFrame(record: Record, workingIndex: number?): CFrame
	return noseIn(record, LotSlots.platform(record, workingIndex), LotSlots.platformTop(record, workingIndex))
end

function LotSlots.saleCFrame(record: Record, index: number?): CFrame
	local anchor = LotSlots.salePlatform(record, index)
	if anchor == nil then
		return LotSlots.parkedCFrame(record)
	end
	local position = Vector3.new(anchor.Position.X, LotSlots.saleTop(record, index), anchor.Position.Z)
	-- The authored spaces are wide on local X; wheel stops sit at -RightVector, so
	-- display cars point toward +RightVector.
	return CFrame.lookAt(position, position + anchor.CFrame.RightVector)
end

function LotSlots.targetPlatform(record: Record, state: string, displayIndex: number?, workingIndex: number?): BasePart?
	if LotSlots.isDisplayState(state) then
		return LotSlots.salePlatform(record, displayIndex) or LotSlots.platform(record, workingIndex)
	end
	return LotSlots.platform(record, workingIndex)
end

function LotSlots.targetTop(record: Record, state: string, displayIndex: number?, workingIndex: number?): number
	if LotSlots.isDisplayState(state) and LotSlots.salePlatform(record, displayIndex) ~= nil then
		return LotSlots.saleTop(record, displayIndex)
	end
	return LotSlots.platformTop(record, workingIndex)
end

function LotSlots.targetCFrame(record: Record, state: string, displayIndex: number?, workingIndex: number?): CFrame
	if LotSlots.isDisplayState(state) and LotSlots.salePlatform(record, displayIndex) ~= nil then
		return LotSlots.saleCFrame(record, displayIndex)
	end
	return LotSlots.parkedCFrame(record, workingIndex)
end

function LotSlots.setDisplayStatus(record: Record, occupied: boolean, listedPrice: number?, index: number?)
	local platform = LotSlots.salePlatform(record, index)
	if platform == nil then
		return
	end
	platform:SetAttribute("Occupied", occupied)
	platform:SetAttribute("ListedPrice", if occupied then math.max(0, math.floor(listedPrice or 0)) else 0)
	local display = platform.Parent
	local label = display and display:FindFirstChild("StatusLabel", true)
	if label ~= nil and label:IsA("TextLabel") then
		label.Text = if occupied
			then ("USED CARS\n$%d"):format(math.max(0, math.floor(listedPrice or 0)))
			else "USED CARS\nAVAILABLE"
	end
end

-- Approved on Tycoon1 from the debug CFrame:
-- root position 478.216, 3.298, 731.827; LookVector 0.620415, 0, 0.784274.
-- Store it in Repair Pad space so every rotated tycoon gets the same composition.
-- This function returns the feet position; LotNpc adds the rig's root height.
local SELLER_STAND_FROM_PARKED = Vector3.new(-6.520935, 0, -4.873840)
local SELLER_LOOK_FROM_PARKED = Vector3.new(-0.747176, 0, -0.664627)

function LotSlots.sellerStandCFrame(record: Record, workingIndex: number?): CFrame
	local parked = LotSlots.parkedCFrame(record, workingIndex)
	local localSpot = parked:PointToWorldSpace(SELLER_STAND_FROM_PARKED)
	local spot = Vector3.new(localSpot.X, LotSlots.platformTop(record, workingIndex), localSpot.Z)
	local look = parked:VectorToWorldSpace(SELLER_LOOK_FROM_PARKED).Unit
	return CFrame.lookAt(spot, spot + look)
end

function LotSlots.queuePromotionPoints(record: Record, from: CFrame, target: CFrame): { Vector3 }
	local points: { Vector3 } = { from.Position }
	local function append(position: Vector3, minimumDistance: number?)
		if (position - points[#points]).Magnitude >= (minimumDistance or 0.25) then
			table.insert(points, position)
		end
	end

	local junk = record.zones.junk or record.zone
	local geometry = junk:FindFirstChild("QueueGeometry", true)
	local route = geometry and geometry:FindFirstChild("PromotionRoute")
	local first = route and route:FindFirstChild("P1")
	local authoredBaseY = if first ~= nil and first:IsA("BasePart") then first.Position.Y else nil
	if route ~= nil and authoredBaseY ~= nil then
		local workingOne = LotSlots.parkedCFrame(record, 1)
		local laneOffset = Vector3.new(
			target.Position.X - workingOne.Position.X,
			0,
			target.Position.Z - workingOne.Position.Z
		)
		local parallelLane = laneOffset.Magnitude > 2
		if parallelLane then
			-- Q1 is already aligned with W2. Leave the queue in its authored facing for a
			-- short lead, make one broad corner, then enter the parallel platform straight.
			local flatLook = Vector3.new(from.LookVector.X, 0, from.LookVector.Z)
			if flatLook.Magnitude < 0.05 then
				flatLook = Vector3.new(1, 0, 0)
			end
			local lead = from.Position + flatLook.Unit * 6
			local p3 = route:FindFirstChild("P3")
			local p4 = route:FindFirstChild("P4")
			if p3 ~= nil and p3:IsA("BasePart") and p4 ~= nil and p4:IsA("BasePart") then
				local routeY = from.Position.Y + (p3.Position.Y - authoredBaseY)
				local turn = Vector3.new(lead.X, routeY, p3.Position.Z + laneOffset.Z)
				local approach = Vector3.new(
					p4.Position.X + laneOffset.X,
					from.Position.Y + (p4.Position.Y - authoredBaseY),
					p4.Position.Z + laneOffset.Z
				)
				append(lead, 2)
				append(turn, 2)
				append(approach, 2)
			end
		else
			for index = 1, 4 do
				local anchor = route:FindFirstChild(("P%d"):format(index))
				if anchor ~= nil and anchor:IsA("BasePart") then
					local position = Vector3.new(
						anchor.Position.X,
						from.Position.Y + (anchor.Position.Y - authoredBaseY),
						anchor.Position.Z
					)
					-- Authored P1 is only 0.613 studs from Q1 and points sideways. It is a
					-- duplicate capture marker, not a useful driving segment.
					append(position, if index == 1 then 2 else 0.25)
				end
			end
		end
	end
	append(target.Position, 0.25)
	return points
end

function LotSlots.carFolder(record: Record): Folder
	local folder = record.folder:FindFirstChild(DealerCarConfig.FOLDER_NAME)
	if folder ~= nil and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = DealerCarConfig.FOLDER_NAME
	created.Parent = record.folder
	return created
end

return LotSlots
