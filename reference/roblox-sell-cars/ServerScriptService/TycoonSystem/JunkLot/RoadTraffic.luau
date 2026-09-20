--!strict

-- Moving anything between the road network and a lot. Dealer cars use it today; service
-- clients can reuse the same entry and exit paths later without touching this file.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadGraph = require(ReplicatedStorage.RoadGraph)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local LotSlots = require(script.Parent.LotSlots)
local CarVisuals = require(script.Parent.CarVisuals)
local LotNpc = require(script.Parent.LotNpc)

type Record = LotSlots.Record

export type DriveOptions = {
	turnRate: number?,
	steer: boolean?,
	reverse: boolean?,
	initialLook: Vector3?,
}

local RoadTraffic = {}

local DISPLAY_REVERSE_DISTANCE = 14
local DISPLAY_APPROACH_HANDLE = 8
local DISPLAY_ALIGNMENT_DISTANCE = 5
local TOW_HOME_LOOP_SIDE_DISTANCE = 10
local TOW_HOME_LOOP_FORWARD_DISTANCE = 10
local TOW_HOME_FINAL_ALIGNMENT_DISTANCE = 7
local TOW_ROUTE_MAX_SAMPLE_DISTANCE = 3
-- RoadGraph's shared 1.55-stud vehicle pivot fits normal traffic cars. The TowTruck's
-- authored wheel centres sit lower relative to its pivot, so its tyres need this extra
-- road-only lift. Authored apron/home points already contain their correct world height.
local TOW_ROAD_PIVOT_LIFT = 0.4
local TOW_CORRECTION_ALIGNMENT_TAIL = 7
local TOW_CORRECTION_LOOP_SIDE = 5
local TOW_CORRECTION_LOOP_FORWARD = 3
local TOW_GROUND_CLEARANCE = 0.03
local TOW_GROUND_PROBE_UP = 16
local TOW_GROUND_PROBE_DOWN = 96

-- Owner-authored Tow Truck departure anchors captured on Tycoon1. They are converted
-- through the W1 repair-pad frame below instead of being used as global coordinates, so
-- the same route rotates/translates with all eight plot compositions.
local TOW_ROUTE_TYCOON1_WORLD = {
	Vector3.new(430.890, 3.998, 752.492),
	Vector3.new(430.782, 2.999, 739.712),
	Vector3.new(430.647, 2.999, 723.767),
	Vector3.new(430.489, 3.247, 705.105),
	Vector3.new(434.154, 3.123, 690.504),
}

-- Owner-authored return loop. P1 is the queue calibration anchor; runtime starts at the
-- truck's actual unload position and carries that horizontal offset through P2, then
-- eases it out by P5. This lets Q2 rejoin without cutting through a car already in Q1.
local TOW_HOME_ROUTE_TYCOON1_WORLD = {
	Vector3.new(454.844, 3.248, 696.749),
	Vector3.new(463.904, 3.123, 680.066),
	Vector3.new(457.590, 3.123, 660.358),
	Vector3.new(432.448, 3.123, 660.518),
	Vector3.new(432.127, 3.123, 675.650),
	Vector3.new(431.661, 3.248, 702.043),
	Vector3.new(431.264, 2.999, 724.571),
	Vector3.new(430.836, 2.999, 748.832),
}

-- Tycoon1 W1 pad SURFACE frame, not a placed vehicle pivot. The previous 3.298 Y
-- subtracted almost three studs from every transformed route point and buried the Tow
-- Truck's wheels/body in the ground during departure.
local TOW_ROUTE_TYCOON1_W1 = CFrame.lookAt(
	Vector3.new(472.640453, 0.300191, 725.894868),
	Vector3.new(472.466805, 0.300191, 726.879676)
)

local function usedParkingV2Enabled(): boolean
	-- Keep the rollout opt-in. Missing fields on older TycoonConfig copies intentionally
	-- read as nil and therefore keep the exact legacy transfer behaviour.
	return TycoonConfig.ROUTING_V2_USED_PARKING == true
end

local function flatUnit(v: Vector3): Vector3
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude < 0.01 then
		return Vector3.new(0, 0, 1)
	end
	return flat.Unit
end

-- Same handedness RoadGraph.lanePath uses, so a positive lane offset lands on this side.
local function laneSide(direction: Vector3): Vector3
	return Vector3.new(-direction.Z, 0, direction.X)
end

local function towSurfaceY(model: Model, position: Vector3): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	params.IgnoreWater = true
	params.RespectCanCollide = true
	local filter: { Instance } = { model }
	local origin = position + Vector3.yAxis * TOW_GROUND_PROBE_UP
	local direction = -Vector3.yAxis * TOW_GROUND_PROBE_DOWN
	for _ = 1, 12 do
		local hit = workspace:Raycast(origin, direction, params)
		if hit == nil then
			return nil
		end
		local part = hit.Instance
		local ancestor = part:FindFirstAncestorOfClass("Model")
		local isCharacter = ancestor ~= nil and ancestor:FindFirstChildOfClass("Humanoid") ~= nil
		local isVehicle = ancestor ~= nil and (
			CollectionService:HasTag(ancestor, "Car")
			or CollectionService:HasTag(ancestor, "ManagedVehicle")
			or ancestor:GetAttribute("ManagedVehicle") == true
			or ancestor:GetAttribute("TowAutomation") == true
			or ancestor:GetAttribute("IncomingSellerQueue") == true
			or ancestor:GetAttribute("DealerProxyId") ~= nil
		)
		local isMarker = part:GetAttribute("PurchaseId") ~= nil
			or part:GetAttribute("PadId") ~= nil
			or string.find(string.lower(part.Name), "buypad", 1, true) ~= nil
		if isCharacter or isVehicle or isMarker then
			local ignored = if ancestor ~= nil and (isCharacter or isVehicle) then ancestor else part
			table.insert(filter, ignored)
			params.FilterDescendantsInstances = filter
			continue
		end
		return hit.Position.Y
	end
	return nil
end

local function groundedTowPosition(model: Model, position: Vector3, pivotClearance: number): Vector3
	local surfaceY = towSurfaceY(model, position)
	if surfaceY == nil then
		return position
	end
	return Vector3.new(position.X, surfaceY + pivotClearance + TOW_GROUND_CLEARANCE, position.Z)
end

-- Tow route points come from several authored and graph coordinate systems. The visible tyres,
-- not those raw Y values, are authoritative: every tow pose is raycast onto the actual surface.
function RoadTraffic.groundTowFrame(model: Model, rawFrame: CFrame): CFrame
	local clearance = CarVisuals.visibleTirePivotClearance(model)
	local position = groundedTowPosition(model, rawFrame.Position, clearance)
	return CFrame.new(position) * rawFrame.Rotation
end

-- Which way traffic has to be travelling past this driveway for the lot to sit on the
-- near side of the road. Approaching against it means crossing the centre line, which is
-- exactly what a delivery driver would never do.
local function travelDirection(entry: number, lotPosition: Vector3): Vector3
	local entryPosition = RoadGraph.position(entry)
	local toLot = Vector3.new(lotPosition.X - entryPosition.X, 0, lotPosition.Z - entryPosition.Z)
	local best: Vector3? = nil
	local bestScore = -math.huge
	for _, link in RoadGraph.neighbours(entry) do
		-- Heading at the driveway if the car came from that neighbour.
		local heading = -flatUnit(RoadGraph.position(link.to) - entryPosition)
		local score = laneSide(heading):Dot(toLot)
		if score > bestScore then
			bestScore = score
			best = heading
		end
	end
	return best or flatUnit(toLot)
end

local function neighbourAlong(entry: number, direction: Vector3): number?
	local entryPosition = RoadGraph.position(entry)
	local best: number? = nil
	local bestDot = -math.huge
	for _, link in RoadGraph.neighbours(entry) do
		local dot = flatUnit(RoadGraph.position(link.to) - entryPosition):Dot(direction)
		if dot > bestDot then
			bestDot = dot
			best = link.to
		end
	end
	return best
end

-- Node route leading outward from the driveway through a chosen neighbour. A visited
-- set prevents the old random wander from circling back into a visible loop near the lot;
-- at junctions the straightest unvisited continuation is deterministic and predictable.
local function routeOutward(entry: number, first: number?, roadSteps: number?): { number }
	local route: { number } = { entry }
	if first == nil then
		return route
	end

	local visited: { [number]: boolean } = {
		[entry] = true,
		[first] = true,
	}
	table.insert(route, first)
	local current = first
	local incoming = flatUnit(RoadGraph.position(first) - RoadGraph.position(entry))
	for _ = 1, math.max(1, math.floor(roadSteps or DealerCarConfig.ROAD_STEPS)) do
		local currentPosition = RoadGraph.position(current)
		local nextNode: number? = nil
		local bestDot = -math.huge
		for _, link in RoadGraph.neighbours(current) do
			if visited[link.to] then
				continue
			end
			local candidateDirection = flatUnit(RoadGraph.position(link.to) - currentPosition)
			local dot = incoming:Dot(candidateDirection)
			if dot > bestDot or (dot == bestDot and (nextNode == nil or link.to < nextNode)) then
				bestDot = dot
				nextNode = link.to
			end
		end
		if nextNode == nil then
			break
		end
		visited[nextNode] = true
		table.insert(route, nextNode)
		incoming = flatUnit(RoadGraph.position(nextNode) - currentPosition)
		current = nextNode
	end
	return route
end

-- Lane offset is measured from the direction of travel, so the route has to be built in
-- the direction the vehicle actually drives or it ends up in the oncoming lane.
local function lane(route: { number }): { Vector3 }
	if #route < 2 then
		return { RoadGraph.position(route[1]) }
	end
	return RoadGraph.lanePath(route, DealerCarConfig.ROAD_LANE_OFFSET, DealerCarConfig.ROAD_HEIGHT, DealerCarConfig.ROAD_SPACING)
end

local function reversed(route: { number }): { number }
	local result: { number } = {}
	for i = #route, 1, -1 do
		table.insert(result, route[i])
	end
	return result
end

local function cubic(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local u = 1 - t
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
 end

-- The turn between the road and the pad is a curve that leaves along one heading and
-- arrives on another; a straight lerp would cut the corner across the oncoming lane.
local function appendCurve(points: { Vector3 }, from: Vector3, fromDirection: Vector3, to: Vector3, toDirection: Vector3)
	local reach = (to - from).Magnitude * DealerCarConfig.APPROACH_BULGE
	local handleA = from + fromDirection * reach
	local handleB = to - toDirection * reach
	local segments = DealerCarConfig.APPROACH_SEGMENTS
	for i = 1, segments do
		table.insert(points, cubic(from, handleA, handleB, to, i / segments))
	end
end

local function appendPoint(points: { Vector3 }, point: Vector3)
	if #points == 0 or (points[#points] - point).Magnitude > 0.2 then
		table.insert(points, point)
	end
end

local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2 = t * t
	local t3 = t2 * t
	return (p1 * 2
		+ (p2 - p0) * t
		+ (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
		+ (-p0 + p1 * 3 - p2 * 3 + p3) * t3) * 0.5
end

-- Catmull-Rom passes through every approved anchor while keeping the tangent continuous.
-- The conservative control-polygon estimate deliberately oversamples; densifyPoints then
-- enforces the hard three-stud adjacency contract even if a curve segment overshoots.
local function smoothControls(controls: { Vector3 }, maxSpacing: number): { Vector3 }
	if #controls <= 1 then
		return table.clone(controls)
	end
	local points: { Vector3 } = { controls[1] }
	for index = 1, #controls - 1 do
		local p0 = controls[math.max(1, index - 1)]
		local p1 = controls[index]
		local p2 = controls[index + 1]
		local p3 = controls[math.min(#controls, index + 2)]
		local estimate = (p1 - p0).Magnitude + (p2 - p1).Magnitude + (p3 - p2).Magnitude
		local segments = math.max(1, math.ceil(estimate / math.max(0.5, maxSpacing)))
		for segment = 1, segments do
			appendPoint(points, catmullRom(p0, p1, p2, p3, segment / segments))
		end
	end
	return points
end

local function densifyPoints(raw: { Vector3 }, maxSpacing: number): { Vector3 }
	if #raw <= 1 then
		return table.clone(raw)
	end
	local points: { Vector3 } = { raw[1] }
	for index = 2, #raw do
		local from = points[#points]
		local target = raw[index]
		local distance = (target - from).Magnitude
		local segments = math.max(1, math.ceil(distance / math.max(0.5, maxSpacing)))
		for segment = 1, segments do
			appendPoint(points, from:Lerp(target, segment / segments))
		end
	end
	return points
end

local function closestPointIndex(points: { Vector3 }, target: Vector3): number
	local bestIndex = 1
	local bestDistance = math.huge
	for index, point in points do
		local distance = (point - target).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			bestIndex = index
		end
	end
	return bestIndex
end

local function transformTowRoute(record: Record, sourcePoints: { Vector3 }): { Vector3 }
	local plotFrame = LotSlots.parkedCFrame(record, 1)
	local controls: { Vector3 } = {}
	for _, tycoonOnePoint in sourcePoints do
		local plotLocal = TOW_ROUTE_TYCOON1_W1:PointToObjectSpace(tycoonOnePoint)
		table.insert(controls, plotFrame:PointToWorldSpace(plotLocal))
	end
	return controls
end

local function towRouteControls(record: Record): { Vector3 }
	return transformTowRoute(record, TOW_ROUTE_TYCOON1_WORLD)
end

local function towHomeRouteControls(record: Record, fromPosition: Vector3): { Vector3 }
	local authored = transformTowRoute(record, TOW_HOME_ROUTE_TYCOON1_WORLD)
	local offset = fromPosition - authored[1]
	local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
	local controls: { Vector3 } = { fromPosition }
	for index = 2, #authored do
		-- Preserve the owner's P1->P2 direction from either queue position, then merge
		-- gradually into the shared apron loop instead of crossing an occupied Q1.
		local offsetWeight = math.clamp((5 - index) / 3, 0, 1)
		table.insert(controls, authored[index] + horizontalOffset * offsetWeight)
	end
	return controls
end

-- Parking approaches need a bounded final handle. Scaling the handle to P3/P6 distance
-- pulled the curve through occupied spaces; the capped version stays in the centre aisle.
local function appendCappedCurve(
	points: { Vector3 },
	from: Vector3,
	fromDirection: Vector3,
	to: Vector3,
	toDirection: Vector3,
	maxReach: number
)
	local reach = math.min((to - from).Magnitude * DealerCarConfig.APPROACH_BULGE, maxReach)
	local handleA = from + flatUnit(fromDirection) * reach
	local handleB = to - flatUnit(toDirection) * reach
	for i = 1, DealerCarConfig.APPROACH_SEGMENTS do
		table.insert(points, cubic(from, handleA, handleB, to, i / DealerCarConfig.APPROACH_SEGMENTS))
	end
end

local function forwardRoad(record: Record, driveway: Vector3, heading: Vector3, downstream: number): { Vector3 }
	local road = lane(routeOutward(downstream, neighbourAlong(downstream, heading)))
	local points: { Vector3 } = { driveway }
	for _, point in road do
		appendPoint(points, point)
	end
	return points
end

-- Road in the correct lane, ending at the projected driveway directly opposite the moved
-- Repair Pad, then one forward curve into its nose-in pose.
function RoadTraffic.arrivalPoints(record: Record, target: CFrame, roadSteps: number?): { Vector3 }
	local driveway, heading, upstream = LotSlots.roadLane(record, target.Position)
	local points = lane(reversed(routeOutward(upstream, neighbourAlong(upstream, -heading), roadSteps)))
	if #points == 0 then
		table.insert(points, driveway - heading * 30)
	end
	appendPoint(points, driveway)
	appendCurve(points, driveway, heading, target.Position, flatUnit(target.LookVector))
	return points
end

-- Tow returns keep the normal road-graph route, but use a denser final representation so
-- neither a streamed-in truck nor its mounted cargo can jump six studs between route samples.
function RoadTraffic.towArrivalPoints(record: Record, target: CFrame, roadSteps: number?): ({ Vector3 }, number)
	local driveway = LotSlots.roadLane(record, target.Position)
	local raw = RoadTraffic.arrivalPoints(record, target, roadSteps)
	local rawDrivewayIndex = closestPointIndex(raw, driveway)
	for index, point in raw do
		-- Keep the truck level on the road, then ease the model-specific lift out across
		-- the authored driveway curve so the exact queue target remains unchanged.
		local liftWeight = if index <= rawDrivewayIndex
			then 1
			else 1 - (index - rawDrivewayIndex) / math.max(1, #raw - rawDrivewayIndex)
		raw[index] = point + Vector3.yAxis * (TOW_ROAD_PIVOT_LIFT * liftWeight)
	end
	local raisedDriveway = driveway + Vector3.yAxis * TOW_ROAD_PIVOT_LIFT
	local points = densifyPoints(raw, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	-- Sample density may change freely; the slowdown seam remains the physical driveway,
	-- which is the first point of the actual lot approach.
	return points, closestPointIndex(points, raisedDriveway)
end

export type DrivePlan = {
	reverseOut: { Vector3 },
	forward: { Vector3 },
	reversePark: { Vector3 },
	slowForwardUntil: number?,
}

local function usedCarsRoadApproach(record: Record, originStage: unknown, groundY: number): Vector3?
	local editorRoot = workspace:FindFirstChild("ServiceRouteMarkers")
	local tycoonMarkers = editorRoot and editorRoot:FindFirstChild(record.folder.Name)
	local overrides = tycoonMarkers and tycoonMarkers:FindFirstChild("LinkOverrides")
	local stage = if typeof(originStage) == "string" then string.lower(originStage) else ""
	local markerName = if string.find(stage, "tuning", 1, true) ~= nil
		then "AtelierToUsedCarsApproach"
		else "RepairToUsedCarsApproach"
	local marker = overrides and overrides:FindFirstChild(markerName)
	if marker ~= nil and marker:IsA("BasePart") then
		return Vector3.new(marker.Position.X, groundY, marker.Position.Z)
	end
	return nil
end

-- Shared Used Cars final leg. Every P first follows the authored RB/TA road seam,
-- then enters the lot and gets a forward centre-aisle approach plus a short reverse.
local function displayParkingPlanV2(record: Record, rawTarget: CFrame, originStage: unknown): DrivePlan
	local gate = LotSlots.usedLotEntrance(record)
	if gate == nil then
		return { reverseOut = {}, forward = { rawTarget.Position }, reversePark = {} }
	end
	local target = rawTarget
	local finalLook = flatUnit(target.LookVector)
	local gatePoint = Vector3.new(gate.Position.X, target.Position.Y, gate.Position.Z)
	local setup = target.Position + finalLook * DISPLAY_REVERSE_DISTANCE
	local alignment = setup - finalLook * DISPLAY_ALIGNMENT_DISTANCE
	local inward = flatUnit(alignment - gatePoint)
	local approach = usedCarsRoadApproach(record, originStage, target.Position.Y)
	local forward: { Vector3 } = {}
	if approach ~= nil then
		table.insert(forward, approach)
	end
	appendPoint(forward, gatePoint)
	appendCappedCurve(forward, gatePoint, inward, alignment, finalLook, DISPLAY_APPROACH_HANDLE)
	-- A final authored straight makes the sampled endpoint tangent exactly match the
	-- nose-out target before the reverse phase. Coarse cubic sampling differed by up to
	-- 21 degrees on P3/P6 and left the client in an impossible alignment hold.
	appendPoint(forward, setup)
	return {
		reverseOut = {},
		forward = forward,
		reversePark = { setup, target.Position },
	}
end

function RoadTraffic.displayParkingPlan(record: Record, rawTarget: CFrame, forceV2: boolean?, originStage: unknown): DrivePlan
	local useV2 = if forceV2 ~= nil then forceV2 else usedParkingV2Enabled()
	if useV2 then
		return displayParkingPlanV2(record, rawTarget, originStage)
	end
	-- V1 owner-helper handoff ended at the Used Cars entrance and the authoritative
	-- display clone was placed directly on its P slot. One point keeps that seam intact.
	return { reverseOut = {}, forward = { rawTarget.Position }, reversePark = {} }
end

-- Tow rigs are authored nose-out. Unlike a repair car, they leave the home pose forward.
function RoadTraffic.forwardDeparturePlan(record: Record, from: CFrame): DrivePlan
	local rawDriveway, heading, _, downstream = LotSlots.roadLane(record, from.Position)
	local road = forwardRoad(record, rawDriveway, heading, downstream)
	for index, point in road do
		road[index] = point + Vector3.yAxis * TOW_ROAD_PIVOT_LIFT
	end
	local driveway = rawDriveway + Vector3.yAxis * TOW_ROAD_PIVOT_LIFT
	local controls: { Vector3 } = { from.Position }
	for _, point in towRouteControls(record) do
		appendPoint(controls, point)
	end
	appendPoint(controls, driveway)
	-- Feed the first downstream lane sample into Catmull-Rom so the apron curve reaches the
	-- road with its tangent already aligned instead of snapping its yaw at the driveway.
	if road[2] ~= nil then
		appendPoint(controls, road[2])
	end
	local points = smoothControls(controls, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	for index = 3, #road do
		appendPoint(points, road[index])
	end
	local dense = densifyPoints(points, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	return {
		reverseOut = {},
		forward = dense,
		reversePark = {},
		-- P5 and the driveway stay on apron speed. Normal road speed begins only after this
		-- geometry anchor, independent of the number of spline samples.
		slowForwardUntil = closestPointIndex(dense, driveway),
	}
end

-- After unloading at Q, drive the owner-authored apron loop back to P8. A compact
-- turnaround derived from P8 makes the final forward tangent exactly match the parked
-- truck's LookVector; the rig can then back straight into its authored home pose.
function RoadTraffic.towHomePlan(record: Record, from: CFrame, home: CFrame): DrivePlan
	local controls = towHomeRouteControls(record, from.Position)
	local setup = controls[#controls]
	local homeLook = flatUnit(home.LookVector)
	local homeRight = flatUnit(home.RightVector)
	table.insert(
		controls,
		setup - homeLook * TOW_HOME_LOOP_FORWARD_DISTANCE + homeRight * TOW_HOME_LOOP_SIDE_DISTANCE
	)
	local alignment = setup - homeLook * TOW_HOME_FINAL_ALIGNMENT_DISTANCE
	table.insert(controls, alignment)
	local forward = smoothControls(controls, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	-- Keep the last metres geometrically straight. The spline reaches the alignment
	-- point smoothly; this tail guarantees the exact home-facing tangent at the reverse seam.
	local tail = densifyPoints({ alignment, setup }, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	for index = 2, #tail do
		appendPoint(forward, tail[index])
	end
	return {
		reverseOut = {},
		forward = densifyPoints(forward, TOW_ROUTE_MAX_SAMPLE_DISTANCE),
		reversePark = densifyPoints({ setup, home.Position }, TOW_ROUTE_MAX_SAMPLE_DISTANCE),
	}
end

-- Late FIFO movement can change Q after the truck has already completed its road arrival.
-- Correct through a bounded curve whose endpoint tangent matches the new target rotation;
-- callers may then apply only a tiny epsilon snap, never an arbitrary pose teleport.
function RoadTraffic.towCorrectionPoints(from: CFrame, target: CFrame): { Vector3 }
	local fromLook = flatUnit(from.LookVector)
	local targetLook = flatUnit(target.LookVector)
	local tailStart = target.Position - targetLook * TOW_CORRECTION_ALIGNMENT_TAIL
	local distance = (target.Position - from.Position).Magnitude
	local points: { Vector3 }
	if distance < 2 then
		-- A coincident cubic has zero translation and cannot pay down yaw. Route a compact
		-- one-sided loop around Q, ending behind the target; it is bounded to five studs of
		-- lateral excursion and never asks drive() to reverse along the same segment.
		local cross = fromLook:Cross(targetLook).Y
		local sideSign = if math.abs(cross) > 0.01 then math.sign(cross) else 1
		local side = flatUnit(target.RightVector) * sideSign
		points = smoothControls({
			from.Position,
			from.Position + fromLook * TOW_CORRECTION_LOOP_FORWARD + side * 1.5,
			target.Position + side * TOW_CORRECTION_LOOP_SIDE,
			tailStart + side * 3,
			tailStart,
		}, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	else
		points = { from.Position }
		appendCappedCurve(
			points,
			from.Position,
			fromLook,
			tailStart,
			targetLook,
			6
		)
	end

	-- This geometric tail is the guarantee: at speed 10 and turnRate 10 it provides 0.7s
	-- of unchanging target heading, reducing even a 180-degree residual below five degrees.
	local tail = densifyPoints({ tailStart, target.Position }, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
	for index = 2, #tail do
		appendPoint(points, tail[index])
	end
	return densifyPoints(points, TOW_ROUTE_MAX_SAMPLE_DISTANCE)
end

-- Repair cars back out to their exact driveway. Cars already displayed at Used Cars leave
-- through the authored UsedLot entrance instead of cutting diagonally across the Junk Spot.
function RoadTraffic.departurePlan(record: Record, from: CFrame, displayIndex: number?): DrivePlan
	local sale = LotSlots.saleCFrame(record, displayIndex)
	local repair = LotSlots.parkedCFrame(record)
	local fromUsedCars = (from.Position - sale.Position).Magnitude < (from.Position - repair.Position).Magnitude
	if fromUsedCars then
		local gate = LotSlots.usedLotEntrance(record)
		local gatePoint = if gate ~= nil
			then gate.Position + Vector3.new(0, DealerCarConfig.ROAD_HEIGHT, 0)
			else from.Position + flatUnit(from.LookVector) * 18
		local driveway, heading, _, downstream = LotSlots.usedRoadLane(record, gatePoint)
		local towardRoad = flatUnit(driveway - gatePoint)
		local points: { Vector3 } = { from.Position }
		appendCurve(points, from.Position, flatUnit(from.LookVector), gatePoint, towardRoad)
		appendCurve(points, gatePoint, towardRoad, driveway, heading)
		local road = forwardRoad(record, driveway, heading, downstream)
		for index = 2, #road do
			appendPoint(points, road[index])
		end
		return { reverseOut = {}, forward = points, reversePark = {} }
	end

	local driveway, heading, _, downstream = LotSlots.roadLane(record, from.Position)
	local reverseOut: { Vector3 } = { from.Position }
	appendCurve(reverseOut, from.Position, -flatUnit(from.LookVector), driveway, -heading)
	return {
		reverseOut = reverseOut,
		forward = forwardRoad(record, driveway, heading, downstream),
		reversePark = {},
	}
end

-- Original salesman route retained verbatim as the rollback path. It backs from the
-- Used Cars gate all the way to the selected P, matching pre-V2 live behaviour.
local function listingPlanV1(record: Record, from: CFrame, rawTarget: CFrame): DrivePlan
	local target = CFrame.new(rawTarget.X, from.Y, rawTarget.Z) * rawTarget.Rotation
	local repairDriveway, heading = LotSlots.roadLane(record, from.Position)
	local reverseOut: { Vector3 } = { from.Position }
	appendCurve(reverseOut, from.Position, -flatUnit(from.LookVector), repairDriveway, -heading)

	local gate = LotSlots.usedLotEntrance(record)
	if gate == nil then
		local direct: { Vector3 } = { repairDriveway }
		appendCurve(direct, repairDriveway, heading, target.Position, flatUnit(target.LookVector))
		return { reverseOut = reverseOut, forward = direct, reversePark = {} }
	end

	local gatePoint = gate.Position + Vector3.new(0, DealerCarConfig.ROAD_HEIGHT, 0)
	local usedDriveway, usedHeading = LotSlots.usedRoadLane(record, gatePoint)
	local backingFacing = flatUnit(gatePoint - target.Position)
	local forward: { Vector3 } = { repairDriveway }
	appendPoint(forward, usedDriveway)
	appendCurve(forward, usedDriveway, usedHeading, gatePoint, backingFacing)
	local reversePark: { Vector3 } = { gatePoint }
	appendCurve(reversePark, gatePoint, -backingFacing, target.Position, -flatUnit(target.LookVector))
	return { reverseOut = reverseOut, forward = forward, reversePark = reversePark }
end

-- Salesman transfer: back out of Junk Spot, follow the front lane to Used Cars, then use
-- the same centre-aisle/setup/reverse geometry as the Service Helper final handoff.
local function listingPlanV2(record: Record, from: CFrame, rawTarget: CFrame): DrivePlan
	local target = CFrame.new(rawTarget.X, from.Y, rawTarget.Z) * rawTarget.Rotation
	local repairDriveway, heading = LotSlots.roadLane(record, from.Position)
	local reverseOut: { Vector3 } = { from.Position }
	appendCurve(reverseOut, from.Position, -flatUnit(from.LookVector), repairDriveway, -heading)

	local parking = displayParkingPlanV2(record, target)
	if #parking.forward < 2 then
		local direct: { Vector3 } = { repairDriveway }
		appendCurve(direct, repairDriveway, heading, target.Position, flatUnit(target.LookVector))
		return { reverseOut = reverseOut, forward = direct, reversePark = {} }
	end

	local gatePoint = parking.forward[1]
	local usedDriveway, usedHeading = LotSlots.usedRoadLane(record, gatePoint)
	local gateHeading = flatUnit(parking.forward[2] - gatePoint)
	local forward: { Vector3 } = { repairDriveway }
	appendPoint(forward, usedDriveway)
	appendCurve(forward, usedDriveway, usedHeading, gatePoint, gateHeading)
	for index = 2, #parking.forward do
		appendPoint(forward, parking.forward[index])
	end
	return { reverseOut = reverseOut, forward = forward, reversePark = parking.reversePark }
end

function RoadTraffic.listingPlan(
	record: Record,
	from: CFrame,
	rawTarget: CFrame,
	forceV2: boolean?
): DrivePlan
	-- Automated owner cars pass their persisted journey flag explicitly. Nil remains the
	-- compatibility contract for callers that are not associated with a latched car.
	local useV2 = if forceV2 ~= nil then forceV2 else usedParkingV2Enabled()
	return if useV2
		then listingPlanV2(record, from, rawTarget)
		else listingPlanV1(record, from, rawTarget)
end

local function driverOf(model: Model): Model?
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") ~= nil then
			return child
		end
	end
	return nil
end

-- Walks a model along the points at a constant speed. Matches TrafficClient: yaw ease,
-- all wheels steered/spun every frame, driver PivotTo'd into the seat (not left on a
-- weld that ApplyDescription can break mid-drive).
function RoadTraffic.drive(model: Model, points: { Vector3 }, speed: number, stillValid: () -> boolean, options: DriveOptions?): boolean
	if #points < 2 then
		return true
	end
	local turnRate = if options ~= nil and options.turnRate ~= nil then options.turnRate else DealerCarConfig.TURN_RATE
	local doSteer = options ~= nil and options.steer == true
	local reverseDrive = options ~= nil and options.reverse == true
	local wheels: { CarVisuals.Wheel } = if doSteer then CarVisuals.wheels(model) else {}
	local radius = (model:GetAttribute("WheelRadius") :: number?) or 1.2
	local driver = driverOf(model)
	local towGrounded = model:GetAttribute("TowAutomation") == true
	local towPivotClearance = if towGrounded then CarVisuals.visibleTirePivotClearance(model) else 0
	local rideToken: number? = nil
	if driver ~= nil then
		rideToken = LotNpc.beginRide(driver)
	end

	local position = points[1]
	local movementLook = flatUnit(points[2] - points[1])
	local authoredInitialLook = if options ~= nil then options.initialLook else nil
	local initialLook = if authoredInitialLook ~= nil then flatUnit(authoredInitialLook) else movementLook
	local look = if reverseDrive then -initialLook else initialLook
	local steer = 0
	local spin = 0
	local index = 1
	while index < #points do
		local delta = RunService.Heartbeat:Wait()
		if model.Parent == nil or not stillValid() then
			if driver ~= nil and driver.Parent ~= nil then
				LotNpc.endRide(driver, model, rideToken)
			end
			return false
		end
		local budget = speed * delta
		local heading = movementLook
		while budget > 0 and index < #points do
			local target = points[index + 1]
			local toTarget = target - position
			local distance = toTarget.Magnitude
			if distance <= budget then
				position = target
				budget -= distance
				index += 1
				if distance > 0.01 then
					heading = flatUnit(toTarget)
				end
			else
				position += toTarget.Unit * budget
				heading = flatUnit(toTarget)
				budget = 0
			end
		end
		movementLook = heading

		local wantedLook = if reverseDrive then -heading else heading
		local blend = 1 - math.exp(-turnRate * delta)
		local turned = flatUnit(look:Lerp(wantedLook, blend))
		local yaw = math.asin(math.clamp(look:Cross(turned).Y, -1, 1))
		look = turned

		local steeringDirection = if reverseDrive then -1 else 1
		local wanted = math.clamp(
			yaw / math.max(delta, 1 / 240) * DealerCarConfig.STEER_GAIN * steeringDirection,
			-DealerCarConfig.STEER_LIMIT,
			DealerCarConfig.STEER_LIMIT
		)
		steer += (wanted - steer) * math.min(1, DealerCarConfig.STEER_SMOOTH * delta)
		local spinDirection = if reverseDrive then -1 else 1
		-- Vehicle forward is local -Z while the canonical axle points +X, so forward
		-- rolling is a negative axle rotation. CarVisuals handles mirrored wheels.
		spin = (spin - (speed / radius) * delta * spinDirection) % (math.pi * 2)

		local visualPosition = if towGrounded
			then groundedTowPosition(model, position, towPivotClearance)
			else position
		local uprightFrame = CFrame.lookAt(visualPosition, visualPosition + look)
		CarVisuals.pivotToConditionFrame(model, uprightFrame)
		local frame = model:GetPivot()
		if doSteer then
			CarVisuals.applyWheels(frame, wheels, steer, spin)
		end
		if driver ~= nil and driver.Parent ~= nil then
			LotNpc.rideAt(driver, frame, rideToken)
		end
	end

	-- Park pose must be straight. Leaving the last steer angle baked into the wheels is
	-- why some arrivals look fine (almost straight in) and others look broken.
	if doSteer and model.Parent ~= nil then
		CarVisuals.applyWheels(model:GetPivot(), wheels, 0, 0)
	end
	if driver ~= nil and driver.Parent ~= nil then
		LotNpc.endRide(driver, model, rideToken)
	end
	return true
end

return RoadTraffic
