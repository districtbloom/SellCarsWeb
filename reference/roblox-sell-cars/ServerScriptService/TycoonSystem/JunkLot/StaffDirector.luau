--!strict

-- The people the automation pads pay for. The mechanic walks AROUND the car (never through
-- it), kneels at the wheels, then goes home. The salesman leaves the desk to list a Ready
-- car, then comes back; after a sale he cheers at the register.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonService = require(script.Parent.Parent.TycoonService)
local LotSlots = require(script.Parent.LotSlots)
local RoadTraffic = require(script.Parent.RoadTraffic)
local CarVisuals = require(script.Parent.CarVisuals)
local LotNpc = require(script.Parent.LotNpc)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord
type RepairContext = {
	player: Player,
	tradeId: string,
	templateId: string,
}

local StaffDirector = {}

local MECHANIC_MODELS: { [number]: string } = {
	[1] = "FirstMechanic",
	[2] = "SecondMechanic",
}
local USED_CARS_SALESMAN_MODEL = "UsedCarsSalesman"
local STEP_LENGTH = 2.4
local WORK_HOLD = 0.8
local WORK_OFFSET = DealerCarConfig.STAFF_WORK_OFFSET or 4.5
-- All current dealer cars are roughly 8 studs wide and 16-17 studs long. The old
-- half-extents (2.5 x 3.4) described only the cabin, so routes legally cut through
-- the doors and the engine work spot landed inside the hood.
local CAR_HALF_X = WORK_OFFSET * 1.05
local CAR_HALF_Z = WORK_OFFSET * 2
local ROUTE_CLEARANCE = 1

-- Clockwise: left side -> beyond the front bumper -> rear-right wheel.
local PART_OFFSETS: { [string]: Vector3 } = {
	Body = Vector3.new(-CAR_HALF_X - 0.5, 0, 0),
	Engine = Vector3.new(0, 0, -CAR_HALF_Z - 0.75),
	Wheels = Vector3.new(CAR_HALF_X + 0.35, 0, WORK_OFFSET * 0.65),
}

local PART_ORDER = { "Body", "Wheels", "Engine" }
local MECHANIC_YIELD_LINES = {
	"Got it, Boss. I'll wait.",
	"All yours, Boss. Give me a shout if you want backup.",
	"Sure thing, Boss. I'll let you handle this one.",
	"Okay, Boss — show me how you want it done.",
	"No problem, Boss. I'll stand by.",
	"You've got it, Boss. The tools are yours.",
	"Go ahead, Boss. I'll pick it up if you stop.",
	"Your call, Boss. I'll wait nearby.",
	"All right, Boss. Take over.",
	"Okay, Boss. I'll give you some room.",
}

-- Rolling fallback only. New plots use FirstSalesman's authored _PIVOT0, which is the
-- actual scene position and must not be replaced by a desk-relative guess.
local SALESMAN_HOME_FALLBACK_FROM_PAD = CFrame.new(16.619995, 0, 15.770447)
	* CFrame.Angles(0, math.rad(-77.105), 0)

-- Hand-authored way back from the used-car forecourt to the desk. Walking it as one
-- straight leg cut a diagonal across the parking bays and the kerb between them; these
-- three points take him out of the row, along the pavement and back in from the side.
-- Stored in Repair Pad space like the home above, so the rotated lots all reproduce it.
-- Only X and Z are kept: the authored heights were read three studs above the ground
-- (character root, not soles) and every point is re-projected onto whatever it stands on.
-- Authored spot behind the parts-auction laptop. With no car on the pad the mechanic waits
-- here and keeps his hands busy instead of standing to attention on his buy pad. Stored in
-- Repair Pad space like the salesman's home so the rotated lots reproduce it; only X/Z and
-- the facing are kept, because the authored height was read three studs up (character root,
-- not soles) and the spot is re-projected onto the slab anyway.
local MECHANIC_BENCH_FROM_PAD = CFrame.lookAt(
	Vector3.new(-25.00946, 0, 21.447479),
	Vector3.new(-25.00946, 0, 21.447479) + Vector3.new(0.060791, 0, 0.998152)
)
-- FirstMechanic works the parts-auction laptop between repairs. SecondMechanic uses the
-- ordinary standing idle from the Tuning Atelier instead of miming work at an empty W2.
local function mechanicIdleAnimation(workingIndex: number?): string
	return if workingIndex == 1 then "computer" else "idle"
end

local SALESMAN_RETURN_FROM_PAD: { Vector3 } = {
	Vector3.new(34.0507, 0, 69.0568),
	Vector3.new(29.2377, 0, 35.4551),
	Vector3.new(16.6675, 0, 22.2950),
}
local PART_ANIM: { [string]: string } = {
	Body = "repairBody",
	Engine = "repairEngine",
	Wheels = "repairWheels",
}

-- Locked once at spawn. Never rewrite mid-job or after a return walk, or "home" becomes
-- whatever spot he was standing on when a delayed plant fired.
local homes: { [Model]: CFrame } = {}
local salesmanHomes: { [Model]: CFrame } = {}
local usedCarsHomes: { [Model]: CFrame } = {}
local mechanicHomes: { [Model]: CFrame } = {}
local mechanicEpoch: { [Model]: number } = {}
-- A successful listing releases the assignment before the salesman finishes walking home.
-- Each new listing advances this token, so an older idle return stops before it can compete
-- with the new outbound route.
local salesmanEpoch: { [Model]: number } = {}
local busy: { [Model]: boolean } = {}
local busyWorkingIndex: { [Model]: number } = {}
-- Staff is temporarily parented under a dealer car while driving. Keep an authoritative
-- reference and an unparented recovery source so deleting/moving that car can never
-- permanently remove a purchased worker from the tycoon.
local cachedStaff: { [Instance]: { [string]: Model } } = {}
local staffSources: { [Instance]: { [string]: Model } } = {}
local watchedRecords: { [Instance]: boolean } = {}

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
	return LotNpc.footPosition(rig)
end

local function soleFrame(rig: Model): CFrame
	local sole = footOf(rig)
	local facing = rig:GetPivot().LookVector
	local flat = Vector3.new(facing.X, 0, facing.Z)
	if flat.Magnitude < 0.05 then
		flat = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(sole, sole + flat.Unit)
end

local function exactSlotIndex(value: unknown, capacity: number): number?
	if typeof(value) ~= "number"
		or value ~= math.floor(value)
		or value < 1
		or value > capacity
	then
		return nil
	end
	return value
end

local function lotIgnore(record: Record, extra: Instance?): { Instance }
	local ignore: { Instance } = { LotSlots.carFolder(record) }
	if extra ~= nil then
		table.insert(ignore, extra)
	end
	-- The walk home crosses the used-car forecourt, whose buy pads are thick discs a foot
	-- above the tarmac. They belong to a different zone, so they have to be skipped here
	-- too or the salesman ends up standing on one.
	local forecourt = record.zones.usedcars
	if forecourt ~= nil then
		local staffRoutes = forecourt:FindFirstChild("StaffRoutes")
		if staffRoutes ~= nil then
			table.insert(ignore, staffRoutes)
		end
		for _, descendant in forecourt:GetDescendants() do
			if descendant:IsA("BasePart") then
				local name = descendant.Name
				if string.find(name, "BuyPad", 1, true) ~= nil or string.find(name, "PadBase", 1, true) ~= nil then
					table.insert(ignore, descendant)
				end
			end
		end
	end
	local zone = record.zones.junk
	if zone == nil then
		return ignore
	end
	-- Furniture and other NPCs sit above the slab; never treat them as the floor.
	for _, child in zone:GetChildren() do
		if child:IsA("Model") and child.Name ~= "ConcreteBase" and child.Name ~= "DisplayPadRepair" then
			table.insert(ignore, child)
		end
	end
	-- Buy pads / pad bases are thick disks above the concrete. Raycasts that land on them
	-- plant staff in the air (and after ApplyDescription that becomes a floating head).
	for _, descendant in zone:GetDescendants() do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			if string.find(name, "BuyPad", 1, true) ~= nil or string.find(name, "PadBase", 1, true) ~= nil then
				table.insert(ignore, descendant)
			end
		end
	end
	return ignore
end

local function plantOnly(rig: Model, record: Record)
	LotNpc.plant(rig, lotIgnore(record, rig))
end

local function rememberHome(rig: Model)
	-- Always capture post-plant pivot. ApplyDescription moves WorldPivot from feet to
	-- root; keeping the pre-dress home is exactly what floats a head in the air.
	homes[rig] = rig:GetPivot()
end

local function plantAndRemember(rig: Model, record: Record)
	plantOnly(rig, record)
	rememberHome(rig)
end

-- Stand CFrame is a foot point on the slab. Always place by soles - never PivotTo a
-- remembered home after ApplyDescription, because that rewrite moves WorldPivot from
-- feet to HumanoidRootPart and sinks the body (leaving only the head/hat in view).
local function snapToStand(rig: Model, record: Record, stand: CFrame?)
	if stand == nil then
		plantAndRemember(rig, record)
		return
	end
	LotNpc.applyPhysics(rig)
	LotNpc.place(rig, stand.Position, stand.LookVector)
	plantAndRemember(rig, record)
end

-- Where the mechanic waits between cars: at the bench, not on his buy pad. Resolved from
-- the Repair Pad rather than the model's current pivot, which can be miles off after a bad
-- plant got saved into the place.
local function mechanicIndexForModel(modelName: string): number?
	for workingIndex, expectedName in MECHANIC_MODELS do
		if modelName == expectedName then
			return workingIndex
		end
	end
	return nil
end

local function mechanicIndexForRig(rig: Model): number?
	local attributed = exactSlotIndex(
		rig:GetAttribute("MechanicWorkingIndex"),
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	if attributed ~= nil and MECHANIC_MODELS[attributed] == rig.Name then
		return attributed
	end
	return mechanicIndexForModel(rig.Name)
end

local function mechanicStand(record: Record, workingIndex: number, rig: Model?): CFrame?
	if workingIndex ~= 1 then
		if rig == nil then
			return nil
		end
		local remembered = mechanicHomes[rig]
		if remembered ~= nil then
			return remembered
		end
		-- W2 is hand-authored beside its own purchase pad. Capture that sole frame once,
		-- before any job can move the rig, and project it onto the local slab.
		local authored = soleFrame(rig)
		local ground = LotNpc.groundY(authored.Position, lotIgnore(record, rig))
		local flat = Vector3.new(authored.Position.X, ground, authored.Position.Z)
		local look = Vector3.new(authored.LookVector.X, 0, authored.LookVector.Z)
		if look.Magnitude < 0.05 then
			look = Vector3.new(0, 0, -1)
		end
		local home = CFrame.lookAt(flat, flat + look.Unit)
		mechanicHomes[rig] = home
		return home
	end

	local zone = record.zones.junk
	if zone == nil then
		return nil
	end
	local pad = zone:FindFirstChild("DisplayPadRepair", true)
	if pad == nil then
		return nil
	end
	local authored = pad:GetPivot() * MECHANIC_BENCH_FROM_PAD
	local ground = LotNpc.groundY(authored.Position, lotIgnore(record, pad))
	local flat = Vector3.new(authored.Position.X, ground, authored.Position.Z)
	local look = Vector3.new(authored.LookVector.X, 0, authored.LookVector.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(flat, flat + look.Unit)
end

local function parkingFoundation(record: Record): BasePart?
	local zone = record.zones.usedcars
	local foundation = if zone ~= nil then zone:FindFirstChild("ParkingFoundation", true) else nil
	return if foundation ~= nil and foundation:IsA("BasePart") then foundation else nil
end

-- Exact-P exit -> clear centre aisle -> authored pavement corners -> desk. The aisle leg
-- prevents a P2/P3/P5/P6 return from cutting through cars in the rows ahead of it.
local function salesmanReturnRoute(record: Record, displayIndex: number): { Vector3 }
	local zone = record.zones.junk
	local pad = if zone ~= nil then zone:FindFirstChild("DisplayPadRepair", true) else nil
	if pad == nil then
		return {}
	end
	local points: { Vector3 } = {}
	local foundation = parkingFoundation(record)
	if foundation ~= nil and LotSlots.salePlatform(record, displayIndex) ~= nil then
		local exit = (LotSlots.saleCFrame(record, displayIndex) * CFrame.new(-6.2, 0, 0)).Position
		local exitLocal = foundation.CFrame:PointToObjectSpace(exit)
		local frontZ = -foundation.Size.Z * 0.5 + 2.5
		table.insert(points, foundation.CFrame:PointToWorldSpace(Vector3.new(0, 0, exitLocal.Z)))
		table.insert(points, foundation.CFrame:PointToWorldSpace(Vector3.new(0, 0, frontZ)))
	end
	local padPivot = pad:GetPivot()
	for _, offset in SALESMAN_RETURN_FROM_PAD do
		table.insert(points, (padPivot * CFrame.new(offset)).Position)
	end
	return points
end

local groundAt: (Record, Vector3, Model) -> Vector3

local function authoredUsedCarsRoute(record: Record, rig: Model): (CFrame?, CFrame?)
	local zone = record.zones.usedcars
	local routes = zone and zone:FindFirstChild("StaffRoutes")
	local folder = routes and routes:FindFirstChild("UsedCarsSalesman")
	local p1 = folder and folder:FindFirstChild("P1")
	local p2 = folder and folder:FindFirstChild("P2")
	if p1 == nil or not p1:IsA("BasePart") or p2 == nil or not p2:IsA("BasePart") then
		return nil, nil
	end
	local homeFoot = groundAt(record, p1.Position, rig)
	local workFoot = groundAt(record, p2.Position, rig)
	local direction = Vector3.new(workFoot.X - homeFoot.X, 0, workFoot.Z - homeFoot.Z)
	if direction.Magnitude < 0.05 then
		direction = Vector3.new(0, 0, -1)
	end
	direction = direction.Unit
	return CFrame.lookAt(homeFoot, homeFoot + direction),
		CFrame.lookAt(workFoot, workFoot - direction)
end

-- Legacy perimeter route remains as a fallback for scenes without authored worker points.
local function usedCarsDealRoutes(record: Record, target: CFrame): ({ Vector3 }, { Vector3 })
	local foundation = parkingFoundation(record)
	if foundation == nil then
		return {}, {}
	end
	local targetLocal = foundation.CFrame:PointToObjectSpace(target.Position)
	local edgeX = -foundation.Size.X * 0.5 + 2.5
	local frontZ = -foundation.Size.Z * 0.5 + 2.5
	local edgeFront = foundation.CFrame:PointToWorldSpace(Vector3.new(edgeX, 0, frontZ))
	local aisleFront = foundation.CFrame:PointToWorldSpace(Vector3.new(0, 0, frontZ))
	local aisleTarget = foundation.CFrame:PointToWorldSpace(Vector3.new(0, 0, targetLocal.Z))
	return { edgeFront, aisleFront, aisleTarget }, { aisleTarget, aisleFront, edgeFront }
end

-- FirstSalesman's authored model pivot is the authority for his idle/home position.
-- PadService already propagates that pivot with each rotated plot, so applying another
-- Repair-Pad offset is both redundant and the reason he drifted behind the cash register.
local function salesmanStand(record: Record): CFrame?
	local zone = record.zones.junk
	if zone == nil then
		return nil
	end
	local candidate = zone:FindFirstChild(TycoonConfig.SALESMAN_MODEL, true)
	local rig = if candidate ~= nil and candidate:IsA("Model") then candidate else nil
	if rig ~= nil then
		local cached = salesmanHomes[rig]
		if cached ~= nil then
			return cached
		end
		local authored = rig:GetAttribute("_PIVOT0")
		if typeof(authored) == "CFrame" then
			-- _PIVOT0 may have been captured before HumanoidDescription changed WorldPivot.
			-- On the first plant the current pivot still has the same convention, so convert
			-- it once to a sole position and keep that invariant through later dress changes.
			local pivotToSole = rig:GetPivot().Position.Y - footBottom(rig)
			local authoredFoot = (authored :: CFrame).Position - Vector3.new(0, pivotToSole, 0)
			local ground = LotNpc.groundY(authoredFoot, lotIgnore(record, rig))
			local flat = Vector3.new(authoredFoot.X, ground, authoredFoot.Z)
			local look = Vector3.new((authored :: CFrame).LookVector.X, 0, (authored :: CFrame).LookVector.Z)
			if look.Magnitude < 0.05 then
				look = Vector3.new(0, 0, -1)
			end
			local stand = CFrame.lookAt(flat, flat + look.Unit)
			salesmanHomes[rig] = stand
			return stand
		end
	end

	-- Old snapshots without _PIVOT0 keep the previous plot-local fallback.
	local pad = zone:FindFirstChild("DisplayPadRepair", true)
	if pad == nil then
		return nil
	end
	local authored = pad:GetPivot() * SALESMAN_HOME_FALLBACK_FROM_PAD
	local ground = LotNpc.groundY(authored.Position, lotIgnore(record, pad))
	local flat = Vector3.new(authored.Position.X, ground, authored.Position.Z)
	local look = Vector3.new(authored.LookVector.X, 0, authored.LookVector.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(flat, flat + look.Unit)
end

local function ensureRig(
	record: Record,
	modelName: string,
	padId: string,
	mechanicWorkingIndex: number?
): Model?
	if not TycoonService.hasPad(record, padId) then
		return nil
	end
	local zone = record.zones.junk
	if zone == nil then
		return nil
	end
	local cache = cachedStaff[zone]
	if cache == nil then
		cache = {}
		cachedStaff[zone] = cache
	end
	local sources = staffSources[zone]
	if sources == nil then
		sources = {}
		staffSources[zone] = sources
	end

	local found = zone:FindFirstChild(modelName, true)
	local rig = if found ~= nil and found:IsA("Model") then found else cache[modelName]
	if rig == nil or rig.Parent == nil or rig:FindFirstChildOfClass("Humanoid") == nil then
		local source = sources[modelName]
		if source == nil then
			return nil
		end
		rig = source:Clone()
		rig.Name = modelName
		rig.Parent = zone
	end
	cache[modelName] = rig
	if sources[modelName] == nil then
		local source = rig:Clone()
		source.Parent = nil
		sources[modelName] = source
	end
	-- The owner moves between the junk pad and used-car forecourt while this worker drives.
	-- A persistent staff model must not visually vanish merely because streaming focus moved.
	pcall(function()
		rig.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	local isMechanic = mechanicWorkingIndex ~= nil
	if isMechanic then
		rig:SetAttribute("MechanicWorkingIndex", mechanicWorkingIndex)
		-- Never let a staff model masquerade as the grey working platform.
		rig:SetAttribute("WorkingSlotIndex", nil)
	end
	if homes[rig] == nil then
		local stand: CFrame? = nil
		if mechanicWorkingIndex ~= nil then
			stand = mechanicStand(record, mechanicWorkingIndex, rig)
		elseif modelName == TycoonConfig.SALESMAN_MODEL then
			stand = salesmanStand(record)
		end
		snapToStand(rig, record, stand)
		LotNpc.play(rig, if isMechanic then mechanicIdleAnimation(mechanicWorkingIndex) else "idle")
		-- Friend appearances land a second later and rewrite HipHeight / WorldPivot.
		-- Re-resolve the exact stand; never replay a pre-dress pivot as a different rig's home.
		task.delay(1.5, function()
			if rig.Parent == nil or busy[rig] then
				return
			end
			local again: CFrame? = nil
			if mechanicWorkingIndex ~= nil then
				again = mechanicStand(record, mechanicWorkingIndex, rig)
			elseif modelName == TycoonConfig.SALESMAN_MODEL then
				again = salesmanStand(record)
			else
				again = homes[rig]
			end
			snapToStand(rig, record, again)
		end)
	end
	return rig
end

local function mechanic(record: Record, workingIndex: number?): Model?
	local resolvedWorkingIndex = exactSlotIndex(
		workingIndex or 1,
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	if resolvedWorkingIndex == nil then
		return nil
	end
	local modelName = MECHANIC_MODELS[resolvedWorkingIndex]
	local padId = DealerCarConfig.autoRepairPad(resolvedWorkingIndex)
	if modelName == nil or padId == nil then
		return nil
	end
	return ensureRig(record, modelName, padId, resolvedWorkingIndex)
end

local function salesman(record: Record): Model?
	local padId = DealerCarConfig.AUTO_LIST_PAD or DealerCarConfig.AUTO_SELL_PAD
	return ensureRig(record, TycoonConfig.SALESMAN_MODEL, padId)
end

local function usedCarsSalesman(record: Record): Model?
	local padId = DealerCarConfig.AUTO_ACCEPT_PAD or "UsedCarsSalesman"
	if not TycoonService.hasPad(record, padId) then
		return nil
	end
	local zone = record.zones.usedcars
	if zone == nil then
		return nil
	end
	local rig = zone:FindFirstChild(USED_CARS_SALESMAN_MODEL, true)
	if rig == nil or not rig:IsA("Model") or rig:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	pcall(function()
		rig.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	if homes[rig] == nil then
		plantAndRemember(rig, record)
		local authoredHome = select(1, authoredUsedCarsRoute(record, rig))
		if authoredHome ~= nil then
			snapToStand(rig, record, authoredHome)
			homes[rig] = authoredHome
			usedCarsHomes[rig] = authoredHome
		else
			usedCarsHomes[rig] = soleFrame(rig)
		end
		LotNpc.play(rig, "idle")
	elseif usedCarsHomes[rig] == nil then
		usedCarsHomes[rig] = soleFrame(rig)
	end
	return rig
end

function StaffDirector.mechanicYield(record: Record, player: Player, workingIndex: number?)
	local requested = exactSlotIndex(
		workingIndex or 1,
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	if requested == nil then
		return
	end
	local rig = mechanic(record, requested)
	if rig == nil then
		return
	end
	local assigned = busyWorkingIndex[rig]
	if assigned ~= nil and requested ~= assigned then
		return
	end
	-- Invalidate only this mechanic's walk/work predicate. The other W lane keeps running.
	mechanicEpoch[rig] = (mechanicEpoch[rig] or 0) + 1
	LotNpc.play(rig, "idle")
	local adornee = rig:FindFirstChild("Head", true) or rig:FindFirstChildWhichIsA("BasePart", true)
	if adornee ~= nil then
		Remotes.ListingNotice:FireClient(player, {
			mode = "bubble",
			adornee = adornee,
			text = MECHANIC_YIELD_LINES[math.random(1, #MECHANIC_YIELD_LINES)],
		})
	end
end

groundAt = function(record: Record, position: Vector3, rig: Model): Vector3
	local ignore = lotIgnore(record, rig)
	return Vector3.new(position.X, LotNpc.groundY(position, ignore), position.Z)
end

local function crossesCar(parked: CFrame, from: Vector3, to: Vector3): boolean
	for t = 0.15, 0.85, 0.14 do
		local sample = from:Lerp(to, t)
		local localPos = parked:PointToObjectSpace(sample)
		if math.abs(localPos.X) < CAR_HALF_X and math.abs(localPos.Z) < CAR_HALF_Z then
			return true
		end
	end
	return false
end

-- Skirt the chassis via nose or rear - never a diagonal through the cabin.
local function aroundWaypoints(parked: CFrame, from: Vector3, to: Vector3): { Vector3 }
	if not crossesCar(parked, from, to) then
		return { from, to }
	end
	local fromLocal = parked:PointToObjectSpace(from)
	local toLocal = parked:PointToObjectSpace(to)
	local routeHalfX = CAR_HALF_X + ROUTE_CLEARANCE
	local routeHalfZ = CAR_HALF_Z + ROUTE_CLEARANCE
	local fromX = math.clamp(fromLocal.X, -routeHalfX, routeHalfX)
	local toX = math.clamp(toLocal.X, -routeHalfX, routeHalfX)

	-- Two corridor points keep both diagonal legs outside the chassis. A single midpoint
	-- still allowed the first leg to clip a front corner of the hood.
	local noseA = (parked * CFrame.new(fromX, 0, -routeHalfZ)).Position
	local noseB = (parked * CFrame.new(toX, 0, -routeHalfZ)).Position
	local rearA = (parked * CFrame.new(fromX, 0, routeHalfZ)).Position
	local rearB = (parked * CFrame.new(toX, 0, routeHalfZ)).Position
	local noseLen = (from - noseA).Magnitude + (noseA - noseB).Magnitude + (noseB - to).Magnitude
	local rearLen = (from - rearA).Magnitude + (rearA - rearB).Magnitude + (rearB - to).Magnitude
	if noseLen <= rearLen then
		return { from, noseA, noseB, to }
	end
	return { from, rearA, rearB, to }
end

local function walkTo(
	rig: Model,
	record: Record,
	target: CFrame,
	animation: string,
	skirtCar: boolean?,
	isValid: (() -> boolean)?,
	via: { Vector3 }?,
	workingIndex: number?
): boolean
	local ignore = lotIgnore(record, rig)
	local from = footOf(rig)
	local groundTarget = groundAt(record, target.Position, rig)
	local route: { Vector3 }
	if via ~= nil and #via > 0 then
		-- An authored path: walk the given corners in order, ends resolved by the caller.
		route = { from }
		for _, point in via do
			table.insert(route, groundAt(record, point, rig))
		end
		table.insert(route, groundTarget)
	elseif skirtCar == true then
		local parked = LotSlots.parkedCFrame(record, workingIndex)
		local raw = aroundWaypoints(parked, from, groundTarget)
		route = {}
		for _, point in raw do
			table.insert(route, groundAt(record, point, rig))
		end
	else
		route = { from, groundTarget }
	end

	local points: { Vector3 } = { route[1] }
	for index = 2, #route do
		local a = points[#points]
		local b = route[index]
		local span = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local distance = span.Magnitude
		if distance > 1.5 then
			local steps = math.max(2, math.ceil(distance / STEP_LENGTH))
			local filled = LotNpc.walkPoints(a, span, steps, distance / steps, ignore)
			for i = 2, #filled do
				table.insert(points, filled[i])
			end
		else
			table.insert(points, b)
		end
	end

	if #points >= 2 then
		if not LotNpc.walk(rig, points, DealerCarConfig.STAFF_WALK_SPEED or 11, function()
			return rig.Parent ~= nil and (isValid == nil or isValid())
		end) then
			return false
		end
	end
	if rig.Parent == nil or (isValid ~= nil and not isValid()) then
		return false
	end
	local pivot = CFrame.lookAt(
		Vector3.new(groundTarget.X, rig:GetPivot().Position.Y, groundTarget.Z),
		Vector3.new(groundTarget.X, rig:GetPivot().Position.Y, groundTarget.Z) + Vector3.new(target.LookVector.X, 0, target.LookVector.Z)
	)
	rig:PivotTo(pivot)
	LotNpc.plant(rig, ignore)
	local planted = footOf(rig)
	local lookAt = planted + Vector3.new(target.LookVector.X, 0, target.LookVector.Z)
	local lift = rig:GetPivot().Position.Y - planted.Y
	rig:PivotTo(CFrame.lookAt(planted + Vector3.new(0, lift, 0), lookAt + Vector3.new(0, lift, 0)))
	LotNpc.play(rig, animation)
	return true
end

local function workSpot(record: Record, partId: string, workingIndex: number?): CFrame
	local parked = LotSlots.parkedCFrame(record, workingIndex)
	local offset = PART_OFFSETS[partId] or PART_OFFSETS.Body
	local beside = (parked * CFrame.new(offset)).Position
	local spot = Vector3.new(beside.X, LotSlots.platformTop(record, workingIndex), beside.Z)
	return CFrame.lookAt(spot, parked.Position)
end

local function listSpot(record: Record, workingIndex: number?): CFrame
	local parked = LotSlots.parkedCFrame(record, workingIndex)
	local beside = (parked * CFrame.new(-WORK_OFFSET * 0.85, 0, 0)).Position
	local spot = Vector3.new(beside.X, LotSlots.platformTop(record, workingIndex), beside.Z)
	return CFrame.lookAt(spot, parked.Position)
end

-- One outing: start -> each broken part around the chassis -> home.
function StaffDirector.repairJob(
	record: Record,
	partIds: { string },
	onPart: (string) -> (),
	workingIndex: number?,
	shouldContinue: (() -> boolean)?,
	context: RepairContext?
): boolean
	local resolvedWorkingIndex = exactSlotIndex(
		workingIndex or 1,
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	if resolvedWorkingIndex == nil or LotSlots.platform(record, resolvedWorkingIndex) == nil then
		return false
	end

	local function callbackAllows(): boolean
		if shouldContinue == nil then
			return true
		end
		local ok, allowed = pcall(shouldContinue)
		return ok and allowed == true
	end

	local rig = mechanic(record, resolvedWorkingIndex)
	if rig == nil then
		for _, partId in partIds do
			if not callbackAllows() then
				return false
			end
			local ok, err = pcall(onPart, partId)
			if not ok then
				warn(`[StaffDirector] headless W{resolvedWorkingIndex} repair failed: {err}`)
				return false
			end
		end
		return true
	end
	if busy[rig] then
		return false
	end

	local epoch = (mechanicEpoch[rig] or 0) + 1
	mechanicEpoch[rig] = epoch
	busy[rig] = true
	busyWorkingIndex[rig] = resolvedWorkingIndex
	rig:SetAttribute("StaffJob", "Repair")
	rig:SetAttribute("StaffWorkingSlotIndex", resolvedWorkingIndex)
	if context ~= nil
		and context.player.Parent ~= nil
		and context.tradeId ~= ""
		and rig:GetAttribute("LastRemarkTradeId") ~= context.tradeId
	then
		rig:SetAttribute("LastRemarkTradeId", context.tradeId)
		local adornee = rig:FindFirstChild("Head", true)
			or rig:FindFirstChildWhichIsA("BasePart", true)
		if adornee ~= nil then
			Remotes.ListingNotice:FireClient(context.player, {
				mode = "bubble",
				adornee = adornee,
				text = DealerCarConfig.mechanicRemark(context.templateId),
			})
		end
	end

	local function assignmentCurrent(): boolean
		return rig.Parent ~= nil
			and busy[rig] == true
			and busyWorkingIndex[rig] == resolvedWorkingIndex
			and mechanicEpoch[rig] == epoch
	end

	local function jobValid(): boolean
		return assignmentCurrent() and callbackAllows()
	end

	local function clearAssignment()
		if busyWorkingIndex[rig] == resolvedWorkingIndex then
			busy[rig] = nil
			busyWorkingIndex[rig] = nil
		end
		if rig.Parent ~= nil then
			rig:SetAttribute("StaffJob", nil)
			rig:SetAttribute("StaffWorkingSlotIndex", nil)
		end
	end

	local function returnHome(success: boolean): boolean
		if rig.Parent ~= nil then
			local stand = mechanicStand(record, resolvedWorkingIndex, rig) or soleFrame(rig)
			local foot = stand.Position
			if not walkTo(
				rig,
				record,
				CFrame.lookAt(foot, foot + stand.LookVector),
				mechanicIdleAnimation(resolvedWorkingIndex),
				true,
				nil,
				nil,
				resolvedWorkingIndex
			) then
				if rig.Parent ~= nil then
					snapToStand(rig, record, stand)
				end
			end
			if rig.Parent ~= nil then
				snapToStand(rig, record, stand)
				LotNpc.play(rig, mechanicIdleAnimation(resolvedWorkingIndex))
			end
		end
		clearAssignment()
		return success
	end

	local ordered: { string } = {}
	local wanted: { [string]: boolean } = {}
	for _, partId in partIds do
		wanted[partId] = true
	end
	for _, partId in PART_ORDER do
		if wanted[partId] then
			table.insert(ordered, partId)
			wanted[partId] = nil
		end
	end
	for partId, on in wanted do
		if on then
			table.insert(ordered, partId)
		end
	end

	for _, partId in ordered do
		if not jobValid() then
			return returnHome(false)
		end
		local anim = PART_ANIM[partId] or "work"
		if not walkTo(
			rig,
			record,
			workSpot(record, partId, resolvedWorkingIndex),
			anim,
			true,
			jobValid,
			nil,
			resolvedWorkingIndex
		) then
			return returnHome(false)
		end
		local hold = if partId == "Wheels" then WORK_HOLD + 0.55 else WORK_HOLD
		task.wait(hold)
		if not jobValid() then
			return returnHome(false)
		end
		local ok, err = pcall(onPart, partId)
		if not ok then
			warn(`[StaffDirector] W{resolvedWorkingIndex} repair callback failed: {err}`)
			return returnHome(false)
		end
		if not jobValid() then
			return returnHome(false)
		end
		task.wait(0.35)
	end

	return returnHome(jobValid())
end

-- Invalidates one exact listing assignment. The epoch prevents the abandoned coroutine
-- from later clearing or moving a newer salesman job after the watchdog has reassigned him.
function StaffDirector.cancelListing(record: Record, expectedTradeId: string?): boolean
	local rig = salesman(record)
	if rig == nil or rig:GetAttribute("StaffJob") ~= "Listing" then
		rig = nil
		for _, candidate in record.folder:GetDescendants() do
			if candidate:IsA("Model")
				and candidate:GetAttribute("StaffJob") == "Listing"
				and (expectedTradeId == nil or candidate:GetAttribute("StaffTradeId") == expectedTradeId)
			then
				rig = candidate
				break
			end
		end
	end
	if rig == nil then return false end
	local assignedTradeId = rig:GetAttribute("StaffTradeId")
	if expectedTradeId ~= nil and assignedTradeId ~= expectedTradeId then
		return false
	end
	local listingStaffId = rig:GetAttribute("ListingStaffId")
	salesmanEpoch[rig] = (salesmanEpoch[rig] or 0) + 1
	busy[rig] = nil
	busyWorkingIndex[rig] = nil
	for _, attribute in { "StaffJob", "StaffWorkingSlotIndex", "StaffDisplaySlotIndex", "StaffTradeId", "ListingStaffId" } do
		rig:SetAttribute(attribute, nil)
	end
	if rig.Parent ~= nil then
		local stand = if typeof(listingStaffId) == "string"
			then (homes[rig] or soleFrame(rig))
			else (salesmanStand(record) or soleFrame(rig))
		local zone = record.zones.junk or record.zone
		pcall(LotNpc.unseat, rig, zone, stand.Position, stand.LookVector)
		if rig.Parent ~= nil then
			snapToStand(rig, record, stand)
			LotNpc.play(rig, "idle")
		end
	end
	return true
end

-- Desk -> driver door -> reverse to road -> Used Cars entrance -> reverse into P1
-- -> exit -> desk. The callback runs only after the physical car is exactly parked.
function StaffDirector.listJob(
	record: Record,
	model: Model,
	onListed: () -> (),
	shouldContinue: (() -> boolean)?,
	onTakeWheel: (() -> boolean)?,
	onWorkingPadCleared: (() -> ())?,
	usedParkingV2: boolean?,
	listingStaffId: string?
): boolean
	if model.Parent == nil then
		return false
	end
	local displayIndex = exactSlotIndex(
		model:GetAttribute("ListingDisplayIndex"),
		DealerCarConfig.MAX_DISPLAY_SLOTS
	)
	local listingWorkingIndex = exactSlotIndex(
		model:GetAttribute("ListingWorkingIndex"),
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	local modelWorkingIndex = exactSlotIndex(
		model:GetAttribute("WorkingSlotIndex"),
		DealerCarConfig.MAX_WORKING_SLOTS
	)
	local tradeId = model:GetAttribute("TradeId")
	if displayIndex == nil
		or listingWorkingIndex == nil
		or modelWorkingIndex ~= listingWorkingIndex
		or typeof(tradeId) ~= "string"
		or tradeId == ""
		or model:GetAttribute("DealerSlot") ~= "working"
		or model:GetAttribute("State") ~= "Ready"
		or model:GetAttribute("Arriving") == true
		or model:GetAttribute("ListingAutopilot") ~= true
		or LotSlots.platform(record, listingWorkingIndex) == nil
		or LotSlots.salePlatform(record, displayIndex) == nil
	then
		return false
	end

	local workingIndex = listingWorkingIndex
	local rig = if listingStaffId ~= nil
		then ensureRig(record, listingStaffId, listingStaffId)
		else salesman(record)
	if rig == nil or busy[rig] then
		return false
	end
	local epoch = (salesmanEpoch[rig] or 0) + 1
	salesmanEpoch[rig] = epoch
	busy[rig] = true
	busyWorkingIndex[rig] = workingIndex
	rig:SetAttribute("StaffJob", "Listing")
	rig:SetAttribute("StaffWorkingSlotIndex", workingIndex)
	rig:SetAttribute("StaffDisplaySlotIndex", displayIndex)
	rig:SetAttribute("StaffTradeId", tradeId)
	rig:SetAttribute("ListingStaffId", listingStaffId)

	local function identityValid(): boolean
		return model.Parent ~= nil
			and model:IsDescendantOf(record.folder)
			and model:GetAttribute("DealerSlot") == "working"
			and model:GetAttribute("State") == "Ready"
			and model:GetAttribute("TradeId") == tradeId
			and model:GetAttribute("WorkingSlotIndex") == workingIndex
			and model:GetAttribute("ListingWorkingIndex") == workingIndex
			and model:GetAttribute("ListingDisplayIndex") == displayIndex
			and model:GetAttribute("Arriving") ~= true
			and model:GetAttribute("ListingAutopilot") == true
	end
	local function jobValid(): boolean
		return rig.Parent ~= nil
			and salesmanEpoch[rig] == epoch
			and busy[rig] == true
			and identityValid()
			and (shouldContinue == nil or shouldContinue())
	end
	local function clearAssignment()
		if salesmanEpoch[rig] ~= epoch then
			return
		end
		busy[rig] = nil
		busyWorkingIndex[rig] = nil
		if rig.Parent ~= nil then
			rig:SetAttribute("StaffJob", nil)
			rig:SetAttribute("StaffWorkingSlotIndex", nil)
			rig:SetAttribute("StaffDisplaySlotIndex", nil)
			rig:SetAttribute("StaffTradeId", nil)
			rig:SetAttribute("ListingStaffId", nil)
		end
	end
	local function abortJob(): boolean
		if salesmanEpoch[rig] ~= epoch then
			return false
		end
		if rig.Parent ~= nil then
			local stand = if listingStaffId ~= nil
				then (homes[rig] or soleFrame(rig))
				else (salesmanStand(record) or soleFrame(rig))
			snapToStand(rig, record, stand)
			LotNpc.play(rig, "idle")
		end
		clearAssignment()
		return false
	end

	if not walkTo(
		rig,
		record,
		listSpot(record, workingIndex),
		"walk",
		true,
		jobValid,
		nil,
		workingIndex
	) then
		return abortJob()
	end

	local tookWheel = true
	if onTakeWheel ~= nil then
		local ok, result = pcall(onTakeWheel)
		tookWheel = ok and result == true
		if not ok then
			warn(string.format("[StaffDirector] W%d listing lock failed: %s", workingIndex, tostring(result)))
		end
	end
	if not jobValid() or not tookWheel then
		return abortJob()
	end

	local driveOk, driveResult = pcall(function(): boolean
		CarVisuals.resetWheels(model)
		CarVisuals.setRunningLights(model, true)
		LotNpc.seat(rig, model, CarVisuals.driverSeat(model))
		task.wait(0.35)

		local plan = RoadTraffic.listingPlan(
			record,
			model:GetPivot(),
			LotSlots.saleCFrame(record, displayIndex),
			usedParkingV2
		)
		-- Every FirstSalesman transfer is productive work, not ambient traffic.
		-- Keep the brisk FTUE pace for the full W -> P automation loop.
		local reverseOutSpeed = 13
		local forwardSpeed = 30
		local reverseParkSpeed = 12
		local finished = true
		if #plan.reverseOut >= 2 then
			finished = RoadTraffic.drive(model, plan.reverseOut, reverseOutSpeed, jobValid, {
				steer = true,
				reverse = true,
			})
		end
		if finished and onWorkingPadCleared ~= nil then
			local callbackOk, callbackError = pcall(onWorkingPadCleared)
			if not callbackOk then
				warn(string.format("[StaffDirector] W%d early queue callback failed: %s", workingIndex, tostring(callbackError)))
			end
		end
		if finished and #plan.forward >= 2 then
			finished = RoadTraffic.drive(model, plan.forward, forwardSpeed, jobValid, { steer = true })
		end
		if finished and #plan.reversePark >= 2 then
			finished = RoadTraffic.drive(model, plan.reversePark, reverseParkSpeed, jobValid, {
				steer = true,
				reverse = true,
			})
		end
		return finished
	end)
	if not driveOk then
		warn(string.format(
			"[StaffDirector] W%d -> P%d listing drive failed: %s",
			workingIndex,
			displayIndex,
			tostring(driveResult)
		))
	end
	local finished = driveOk and driveResult == true

	local zone = record.zones.junk or record.zone
	local target = LotSlots.saleCFrame(record, displayIndex)
	local current = if model.Parent ~= nil then model:GetPivot() else target
	if finished and jobValid() then
		local parkedOk, parkedError = pcall(function()
			model:PivotTo(target)
			CarVisuals.settleOnVisibleTires(model, LotSlots.saleTop(record, displayIndex), 0.01)
			CarVisuals.resetWheels(model)
			CarVisuals.setRunningLights(model, false)
			current = model:GetPivot()
		end)
		if not parkedOk then
			warn(string.format(
				"[StaffDirector] W%d -> P%d final park failed: %s",
				workingIndex,
				displayIndex,
				tostring(parkedError)
			))
			finished = false
		end
	end
	if rig.Parent ~= nil then
		local beside = (current * CFrame.new(-6.2, 0, 0)).Position
		local foot = groundAt(record, beside, rig)
		local unseatOk, unseatError = pcall(
			LotNpc.unseat,
			rig,
			zone,
			foot,
			current.Position - foot
		)
		if not unseatOk then
			warn(string.format("[StaffDirector] listing unseat failed: %s", tostring(unseatError)))
			finished = false
		end
	end
	if not finished or not jobValid() then
		return abortJob()
	end

	local callbackOk, callbackError = pcall(onListed)
	if not callbackOk then
		warn(string.format(
			"[StaffDirector] W%d -> P%d listing callback failed: %s",
			workingIndex,
			displayIndex,
			tostring(callbackError)
		))
		return abortJob()
	end
	-- The car is committed to its display slot, so W can schedule the next listing now.
	-- Walking home is presentation-only. A newer listing advances salesmanEpoch and makes
	-- this task's predicate false before it can compete with the new outbound movement.
	local returnEpoch = epoch
	clearAssignment()
	task.spawn(function()
		task.wait(0.25)
		local function returnValid(): boolean
			return rig.Parent ~= nil
				and salesmanEpoch[rig] == returnEpoch
				and busy[rig] ~= true
		end
		if not returnValid() then
			return
		end

		rig:SetAttribute("StaffJob", "Returning")
		local stand = if listingStaffId ~= nil
			then (homes[rig] or soleFrame(rig))
			else (salesmanStand(record) or soleFrame(rig))
		-- Start is wherever he stepped out of the exact P slot, end is the worker's home; the
		-- authored corners in between keep him off the bays and the kerb.
		local walked = walkTo(
			rig,
			record,
			stand,
			"idle",
			false,
			returnValid,
			if listingStaffId == nil then salesmanReturnRoute(record, displayIndex) else nil
		)
		if not returnValid() then
			return
		end
		if not walked then
			snapToStand(rig, record, stand)
		end
		if returnValid() then
			snapToStand(rig, record, stand)
			LotNpc.play(rig, "idle")
			rig:SetAttribute("StaffJob", nil)
		end
	end)
	return true
end

function StaffDirector.closeDisplayDeal(
	record: Record,
	displayIndex: number,
	shouldContinue: (() -> boolean)?,
	onAccept: () -> ()
): boolean
	local resolvedDisplayIndex = exactSlotIndex(
		displayIndex,
		DealerCarConfig.MAX_DISPLAY_SLOTS
	)
	if resolvedDisplayIndex == nil then
		return false
	end
	local saleSurface = LotSlots.salePlatform(record, resolvedDisplayIndex)
	if saleSurface == nil then
		return false
	end

	local rig = usedCarsSalesman(record)
	if rig == nil or busy[rig] then
		return false
	end
	busy[rig] = true
	rig:SetAttribute("StaffJob", "CloseDisplayDeal")
	rig:SetAttribute("StaffDisplaySlotIndex", resolvedDisplayIndex)

	local authoredHome, authoredTarget = authoredUsedCarsRoute(record, rig)
	local home = authoredHome or usedCarsHomes[rig] or soleFrame(rig)
	usedCarsHomes[rig] = home
	local target: CFrame
	local outboundRoute: { Vector3 }
	local returnRoute: { Vector3 }
	if authoredTarget ~= nil then
		target = authoredTarget
		outboundRoute = {}
		returnRoute = {}
	else
		local sale = LotSlots.saleCFrame(record, resolvedDisplayIndex)
		local raw = (sale * CFrame.new(6.5, 0, -1.5)).Position
		local foot = groundAt(record, raw, rig)
		target = CFrame.lookAt(foot, Vector3.new(sale.Position.X, foot.Y, sale.Position.Z))
		outboundRoute, returnRoute = usedCarsDealRoutes(record, target)
	end

	local function valid(): boolean
		if rig.Parent == nil
			or saleSurface.Parent == nil
			or LotSlots.salePlatform(record, resolvedDisplayIndex) ~= saleSurface
		then
			return false
		end
		if shouldContinue == nil then
			return true
		end
		local ok, result = pcall(shouldContinue)
		return ok and result == true
	end
	local function clearAssignment()
		busy[rig] = nil
		if rig.Parent ~= nil then
			rig:SetAttribute("StaffJob", nil)
			rig:SetAttribute("StaffDisplaySlotIndex", nil)
		end
	end
	local function goHome()
		if rig.Parent == nil then
			return
		end
		if not walkTo(rig, record, home, "idle", false, nil, returnRoute) then
			snapToStand(rig, record, home)
		end
		if rig.Parent ~= nil then
			-- Re-place by soles after every walk. R15 description changes move WorldPivot;
			-- this final plant is what prevents a floating body/head on the next outing.
			snapToStand(rig, record, home)
			LotNpc.play(rig, "idle")
		end
	end

	if not walkTo(rig, record, target, "walk", false, valid, outboundRoute) or not valid() then
		goHome()
		clearAssignment()
		return false
	end

	-- The director never mutates trade state itself. The owner service must close this exact
	-- P slot through the guarded callback after the authored worker has physically arrived.
	local ok, err = pcall(onAccept)
	if not ok then
		warn(string.format(
			"[StaffDirector] Used Cars P%d close callback failed: %s",
			resolvedDisplayIndex,
			tostring(err)
		))
		goHome()
		clearAssignment()
		return false
	end
	if rig.Parent ~= nil then
		LotNpc.play(rig, "cheer")
		task.wait(math.min(1.2, DealerCarConfig.STAFF_CHEER_TIME or 1.2))
	end
	goHome()
	clearAssignment()
	return true
end

local PLAYER_DEAL_LINES = {
	"Nice save, Boss — you handled that one.",
	"Good deal, Boss. Thanks for covering me.",
	"That's teamwork, Boss — clean close.",
	"You beat me to it, Boss. Solid buy.",
}

function StaffDirector.isSalesmanBusy(record: Record): boolean
	local rig = salesman(record)
	return rig == nil or busy[rig] == true
end

function StaffDirector.closeIncomingDeal(
	record: Record,
	workingIndex: number,
	shouldContinue: () -> boolean,
	onClose: () -> ()
): boolean
	local resolvedWorkingIndex = exactSlotIndex(workingIndex, DealerCarConfig.MAX_WORKING_SLOTS)
	local rig = salesman(record)
	if resolvedWorkingIndex == nil or rig == nil or busy[rig] then
		return false
	end

	local epoch = (salesmanEpoch[rig] or 0) + 1
	salesmanEpoch[rig] = epoch
	busy[rig] = true
	busyWorkingIndex[rig] = resolvedWorkingIndex
	rig:SetAttribute("StaffJob", "IncomingDeal")
	rig:SetAttribute("StaffWorkingSlotIndex", resolvedWorkingIndex)
	local home = salesmanStand(record) or soleFrame(rig)

	local function valid(): boolean
		if rig.Parent == nil then
			return false
		end
		local ok, result = pcall(shouldContinue)
		return ok and result == true
	end
	local function clearAssignment()
		busy[rig] = nil
		busyWorkingIndex[rig] = nil
		if rig.Parent ~= nil then
			rig:SetAttribute("StaffJob", nil)
			rig:SetAttribute("StaffWorkingSlotIndex", nil)
		end
	end
	local function goHome()
		if rig.Parent == nil then
			return
		end
		if not walkTo(rig, record, home, "idle", false) then
			snapToStand(rig, record, home)
		end
		if rig.Parent ~= nil then
			snapToStand(rig, record, home)
			LotNpc.play(rig, "idle")
		end
	end

	if not valid()
		or not walkTo(rig, record, listSpot(record, resolvedWorkingIndex), "work", true, valid, nil, resolvedWorkingIndex)
		or not valid()
	then
		goHome()
		clearAssignment()
		return false
	end

	task.wait(0.65)
	if not valid() then
		goHome()
		clearAssignment()
		return false
	end
	local ok, err = pcall(onClose)
	if not ok then
		warn(string.format("[StaffDirector] incoming W%d callback failed: %s", resolvedWorkingIndex, tostring(err)))
	end
	if rig.Parent ~= nil then
		LotNpc.play(rig, "cheer")
		task.wait(0.55)
	end
	goHome()
	clearAssignment()
	return ok
end

function StaffDirector.acknowledgePlayerDeal(record: Record, amount: number)
	local rig = salesman(record)
	if rig == nil or rig.Parent == nil then
		return
	end
	local host = rig:FindFirstChild("Head") or rig:FindFirstChild("HumanoidRootPart")
	if host == nil or not host:IsA("BasePart") then
		return
	end
	local old = rig:FindFirstChild("PlayerDealReaction", true)
	if old ~= nil then
		old:Destroy()
	end

	local bubble = Instance.new("BillboardGui")
	bubble.Name = "PlayerDealReaction"
	bubble.AlwaysOnTop = true
	bubble.LightInfluence = 0
	bubble.MaxDistance = 85
	bubble.Size = UDim2.fromOffset(320, 82)
	bubble.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
	bubble.Adornee = host
	bubble.Parent = host

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.RichText = true
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = string.format(
		"<font color=\"#68E06F\">$%d DEAL</font>\n%s",
		math.max(0, math.floor(amount)),
		PLAYER_DEAL_LINES[math.random(1, #PLAYER_DEAL_LINES)]
	)
	label.Parent = bubble

	if not busy[rig] then
		LotNpc.play(rig, "cheer")
	end
	task.delay(3.5, function()
		if bubble.Parent ~= nil then
			bubble:Destroy()
		end
		if rig.Parent ~= nil and not busy[rig] then
			LotNpc.play(rig, "idle")
		end
	end)
end

function StaffDirector.celebrate(record: Record)
	local rig = salesman(record)
	if rig == nil then
		return
	end
	if busy[rig] then
		return
	end
	local stand = salesmanStand(record)
	snapToStand(rig, record, stand)
	LotNpc.play(rig, "cheer")
	task.delay(DealerCarConfig.STAFF_CHEER_TIME or 2.5, function()
		if rig.Parent ~= nil and not busy[rig] then
			LotNpc.play(rig, "idle")
		end
	end)
end

function StaffDirector.beginHireArrival(record: Record, padId: string)
	local zone = record.zones.junk
	if zone == nil or (padId ~= "FirstMechanic" and padId ~= "FirstSalesman") then
		return
	end
	local rig = if padId == "FirstMechanic" then mechanic(record, 1) else salesman(record)
	if rig == nil or busy[rig] then
		return
	end
	local padName = if padId == "FirstMechanic" then "FirstMechanicBuyPad" else "FirstSalesManBuyPad"
	local pad = zone:FindFirstChild(padName, true)
	local stand = if padId == "FirstMechanic" then mechanicStand(record, 1, rig) else salesmanStand(record)
	if pad == nil or not pad:IsA("BasePart") or stand == nil then
		return
	end

	busy[rig] = true
	rig:SetAttribute("StaffJob", "Onboarding")
	local padGround = LotNpc.groundY(pad.Position, lotIgnore(record, pad))
	local start = Vector3.new(pad.Position.X, padGround, pad.Position.Z)
	snapToStand(rig, record, CFrame.lookAt(start, Vector3.new(stand.X, start.Y, stand.Z)))
	LotNpc.play(rig, "idle")
	task.spawn(function()
		task.wait(0.65)
		if rig.Parent ~= nil then
			if not walkTo(
				rig,
				record,
				stand,
				if padId == "FirstMechanic" then mechanicIdleAnimation(1) else "idle",
				true,
				function(): boolean
					return rig.Parent ~= nil and busy[rig] == true
				end
			) then
				snapToStand(rig, record, stand)
			end
		end
		if rig.Parent ~= nil then
			snapToStand(rig, record, stand)
			LotNpc.play(rig, if padId == "FirstMechanic" then mechanicIdleAnimation(1) else "idle")
			rig:SetAttribute("StaffJob", nil)
		end
		busy[rig] = nil
	end)
end

function StaffDirector.refresh(record: Record)
	for workingIndex in MECHANIC_MODELS do
		mechanic(record, workingIndex)
	end
	salesman(record)
	usedCarsSalesman(record)

	-- A worker normally survives every job. This low-frequency guard only acts when the
	-- FirstSalesman is actually missing, dead, outside his tycoon, or stranded far away
	-- while idle; it never interrupts a live listing drive.
	if not watchedRecords[record.folder] then
		watchedRecords[record.folder] = true
		task.spawn(function()
			while record.folder.Parent ~= nil do
				task.wait(2)
				local rig = salesman(record)
				if rig ~= nil and not busy[rig] then
					local humanoid = rig:FindFirstChildOfClass("Humanoid")
					local stand = salesmanStand(record)
					if humanoid ~= nil and humanoid.Health <= 0 then
						local zone = record.zones.junk
						if zone ~= nil then
							local cache = cachedStaff[zone]
							if cache ~= nil and cache[TycoonConfig.SALESMAN_MODEL] == rig then
								cache[TycoonConfig.SALESMAN_MODEL] = nil
							end
						end
						salesmanHomes[rig] = nil
						rig:Destroy()
					elseif stand ~= nil then
						local outsideTycoon = not rig:IsDescendantOf(record.folder)
						local stranded = (rig:GetPivot().Position - stand.Position).Magnitude > 180
						if outsideTycoon or stranded then
							rig.Parent = record.zones.junk
							snapToStand(rig, record, stand)
							LotNpc.play(rig, "idle")
						end
					end
				end
			end
			watchedRecords[record.folder] = nil
		end)
	end
end

-- Called after a friend appearance is applied so the new HipHeight cannot leave them floating.
function StaffDirector.replant(record: Record, rig: Model)
	if busy[rig] then
		return
	end
	local stand: CFrame? = nil
	local mechanicWorkingIndex = mechanicIndexForRig(rig)
	if mechanicWorkingIndex ~= nil then
		stand = mechanicStand(record, mechanicWorkingIndex, rig)
	elseif rig.Name == TycoonConfig.SALESMAN_MODEL then
		stand = salesmanStand(record)
	elseif rig.Name == USED_CARS_SALESMAN_MODEL then
		stand = usedCarsHomes[rig] or soleFrame(rig)
		usedCarsHomes[rig] = stand
	else
		stand = homes[rig]
	end
	snapToStand(rig, record, stand)
end

function StaffDirector.release(record: Record)
	local targets: { any } = {
		{ zone = record.zones.junk, name = MECHANIC_MODELS[1], mechanicWorkingIndex = 1 },
		{ zone = record.zones.junk, name = MECHANIC_MODELS[2], mechanicWorkingIndex = 2 },
		{ zone = record.zones.junk, name = TycoonConfig.SALESMAN_MODEL },
		{ zone = record.zones.usedcars, name = USED_CARS_SALESMAN_MODEL },
	}
	for _, target in targets do
		local zone = target.zone
		local rig = if zone ~= nil then zone:FindFirstChild(target.name, true) else nil
		if rig ~= nil and rig:IsA("Model") then
			local stand: CFrame? = nil
			if target.mechanicWorkingIndex ~= nil then
				mechanicEpoch[rig] = (mechanicEpoch[rig] or 0) + 1
				stand = mechanicStand(record, target.mechanicWorkingIndex, rig)
			elseif target.name == TycoonConfig.SALESMAN_MODEL then
				stand = salesmanStand(record)
			elseif target.name == USED_CARS_SALESMAN_MODEL then
				stand = usedCarsHomes[rig] or soleFrame(rig)
			end
			if stand ~= nil then
				snapToStand(rig, record, stand)
			else
				local home = homes[rig]
				if home ~= nil then
					rig:PivotTo(home)
					LotNpc.plant(rig, { rig })
				end
			end
			busy[rig] = nil
			busyWorkingIndex[rig] = nil
			usedCarsHomes[rig] = nil
			salesmanHomes[rig] = nil
			mechanicHomes[rig] = nil
			mechanicEpoch[rig] = nil
			salesmanEpoch[rig] = nil
			homes[rig] = nil
			rig:SetAttribute("StaffJob", nil)
			rig:SetAttribute("StaffWorkingSlotIndex", nil)
			rig:SetAttribute("StaffDisplaySlotIndex", nil)
			rig:SetAttribute("StaffTradeId", nil)
		end
	end
end

StaffDirector.PART_ORDER = PART_ORDER

return StaffDirector
