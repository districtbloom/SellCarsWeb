--!strict

-- Server authority for inspecting purchased staff. Clients send only a role id;
-- ownership, pad purchase, distance and the exact live rig are all re-validated here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local ServiceConfig = require(ReplicatedStorage.ServiceConfig)
local DataService = require(script.Parent.DataService)
local TycoonService = require(script.Parent.TycoonService)
local Remotes = require(script.Parent.JunkLot.Remotes)

type Record = TycoonService.TycoonRecord

type StaffDefinition = {
	id: string,
	modelName: string,
	displayNames: { string },
	padId: string,
	zoneId: string,
	role: string,
	responsibilities: { string },
	zoneLabels: { string },
	highlightNames: { string },
	metricKind: "mechanic" | "salesman" | "helper" | "tow" | "tuning" | "advisor" | "manager",
	workingIndex: number?,
	baseSeconds: number?,
}

local MAX_CLICK_DISTANCE = 24
local REQUEST_COOLDOWN = 0.2
local HIGHLIGHT_COLOR = Color3.fromRGB(61, 255, 101)
local TUNING_MANAGER_BONUS_PERCENT = math.floor(
	(TycoonConfig.TUNING_OPERATIONS_MANAGER_MULTIPLIER - 1) * 100 + 0.5
)

local STAFF: { [string]: StaffDefinition } = {
	FirstMechanic = {
		id = "FirstMechanic",
		modelName = "FirstMechanic",
		displayNames = { "Axel Grease", "Rusty Ratchet", "Lug Nut Larry", "Greasy Greg", "Sparky Pluggs", "Frank Fender", "Harry Hubcap", "Benny Belt" },
		padId = "FirstMechanic",
		zoneId = "junk",
		role = "JUNK SPOT MECHANIC",
		responsibilities = { "Repairs Body, Wheels and Engine", "Sells car parts between repairs", "Owns Repair Spot 1" },
		zoneLabels = { "Repair Spot 1", "Parts Sales Laptop" },
		highlightNames = { "DisplayPadRepair", "SimpleWorkbench" },
		metricKind = "mechanic",
		workingIndex = 1,
		baseSeconds = DealerCarConfig.AUTO_REPAIR_SECONDS,
	},
	SecondMechanic = {
		id = "SecondMechanic",
		modelName = "SecondMechanic",
		displayNames = { "Jack Piston", "Cam Shaft Carl", "Brake Pad Brad", "Wrench Turner", "Vin Dieselish", "Stan Starter", "Ricky Radiator", "Gus Gearbox" },
		padId = "SecondMechanic",
		zoneId = "junk",
		role = "JUNK SPOT MECHANIC",
		responsibilities = { "Repairs Body, Wheels and Engine", "Owns Repair Spot 2" },
		zoneLabels = { "Repair Spot 2" },
		highlightNames = { "DisplayPadRepair2" },
		metricKind = "mechanic",
		workingIndex = 2,
		baseSeconds = DealerCarConfig.AUTO_REPAIR_SECONDS,
	},
	ServiceHelper = {
		id = "ServiceHelper",
		modelName = "ServiceHelper",
		displayNames = { "Roadie Ray", "Milo Miles", "Hauler Hank", "Route Riley", "Cruise Cruz", "Driver Drew", "Lane Logan", "Parker Pete" },
		padId = DealerCarConfig.SERVICE_HELPER_PAD,
		zoneId = "junk",
		role = "OWNER CAR SERVICE HELPER",
		responsibilities = {
			"Escorts exact owner stock through service bays",
			"Delivers completed or timed-out stock to Used Cars",
			"Lists Ready cars when Manny is busy",
		},
		zoneLabels = { "Repair Bay", "Car Wash", "Tuning Atelier", "Used Cars" },
		highlightNames = { "ServiceLotQueue", "RepairBay", "CarWash", "TuningAtelier", "ParkingSpaces" },
		metricKind = "helper",
	},
	ServiceHelper2 = {
		id = "ServiceHelper2",
		modelName = "ServiceHelper2",
		displayNames = { "Milo Miles", "Hauler Hank", "Route Riley", "Driver Drew" },
		padId = "ServiceHelper2",
		zoneId = "junk",
		role = "OWNER CAR SERVICE HELPER #2",
		responsibilities = { "Escorts a second owner car through service bays", "Lists Ready cars when Manny is busy", "Adds one parallel pipeline lease" },
		zoneLabels = { "Repair Bay", "Car Wash", "Tuning Atelier", "Used Cars" },
		highlightNames = { "ServiceLotQueue", "RepairBay", "CarWash", "TuningAtelier", "ParkingSpaces" },
		metricKind = "helper",
	},
	ServiceHelper3 = {
		id = "ServiceHelper3",
		modelName = "ServiceHelper3",
		displayNames = { "Hauler Hank", "Route Riley", "Cruise Cruz", "Parker Pete" },
		padId = "ServiceHelper3",
		zoneId = "junk",
		role = "OWNER CAR SERVICE HELPER #3",
		responsibilities = { "Escorts a third owner car through service bays", "Lists Ready cars when Manny is busy", "Raises pipeline cap to three" },
		zoneLabels = { "Repair Bay", "Car Wash", "Tuning Atelier", "Used Cars" },
		highlightNames = { "ServiceLotQueue", "RepairBay", "CarWash", "TuningAtelier", "ParkingSpaces" },
		metricKind = "helper",
	},
	RepairBayMechanic = {
		id = "RepairBayMechanic",
		modelName = "MechanicNPC_Bay1",
		displayNames = { "Torque Wrenchley", "Phil Injector", "Rod Bearing", "Tim Timing", "Clutch Hutch", "Eddie Exhaust", "Pete Pulley", "Victor Valve" },
		padId = "RB_MechanicNPC",
		zoneId = "repair",
		role = "REPAIR BAY MECHANIC",
		responsibilities = { "Runs lift diagnosis and repairs", "Returns serviced cars to checkout" },
		zoneLabels = { "Repair Bay 1", "Car Lift 1" },
		highlightNames = { "RB1_FoundationModel", "RB1_CarLiftModel", "RepairStation" },
		metricKind = "mechanic",
		baseSeconds = ServiceConfig.AUTO_REPAIR_TIME,
	},
	RepairBayMechanic2 = {
		id = "RepairBayMechanic2",
		modelName = "MechanicNPC_Bay2",
		displayNames = { "Cal Ipper", "Terry Booster", "Doug Gasket", "Al Ignition", "Mike Anic", "Chad Chassis", "Cooper Coolant", "Barry Battery" },
		padId = "RB2_MechanicNPC",
		zoneId = "repair",
		role = "REPAIR BAY MECHANIC",
		responsibilities = { "Runs the second service lift", "Handles Repair Bay 2 clients" },
		zoneLabels = { "Repair Bay 2", "Car Lift 2" },
		highlightNames = { "RB2_BuildingModel", "CarLift_Bay2" },
		metricKind = "mechanic",
		baseSeconds = ServiceConfig.AUTO_REPAIR_TIME,
	},
	TowTruckDriver = {
		id = "TowTruckDriver",
		modelName = "TowTruckDriverNPC",
		displayNames = { "Tony Tow", "Hauler Hank", "Recovery Ray", "Winch Wade", "Diesel Drew", "Hook Logan", "Roadside Riley", "Towline Terry" },
		padId = TycoonConfig.TOW_TRUCK_DRIVER_PAD,
		zoneId = "repair",
		role = "TOW TRUCK DRIVER",
		responsibilities = {
			"Recovers progression-valid seller cars offsite",
			"Delivers one paid offer into the Junk Spot FIFO",
		},
		zoneLabels = { "Tow Truck", "Junk Spot Incoming Queue" },
		highlightNames = { "RB1_TowTruckModel", "IncomingSellerQueueRuntime" },
		metricKind = "tow",
	},
	FirstSalesman = {
		id = "FirstSalesman",
		modelName = "FirstSalesman",
		displayNames = { "Manny Fold", "Cash Carburetor", "Dealership Dan", "Barry Bargain", "Sellin Cylinder", "Mark Up", "Bill O Sale", "Curt Commission" },
		padId = "FirstSalesman",
		zoneId = "junk",
		role = "LEAD SALESMAN",
		responsibilities = {
			"Buys incoming seller cars",
			"Parks repaired cars on Sale Spots",
			"Handles buyers and closes sales",
		},
		zoneLabels = { "Cash Register", "Incoming Seller Lane", "Repair Spots", "Used Cars Sale Spots" },
		highlightNames = {
			"CashDeskA", "IncomingSeller",
			"DisplayPadRepair", "DisplayPadRepair2", "ParkingSpaces",
		},
		metricKind = "salesman",
	},
	UsedCarsSalesman = {
		id = "UsedCarsSalesman",
		modelName = "UsedCarsSalesman",
		displayNames = { "Otto Matic", "Miles Perhour", "Dealer McWheel", "Nick O Time", "Perry Parts", "Ty ReSale", "Chip N Deal", "Frank Finance" },
		padId = "UsedCarsSalesman",
		zoneId = "usedcars",
		role = "LEGACY LOT SALESMAN",
		responsibilities = { "Assists buyers at displayed cars", "Supports Used Cars sale pads" },
		zoneLabels = { "Used Cars Sale Spots" },
		highlightNames = { "ParkingSpaces" },
		metricKind = "salesman",
	},
	TuningDynoSpecialist = {
		id = "TuningDynoSpecialist",
		modelName = "DynoSpecialistNPC",
		displayNames = { "Chip Torque", "Rev Reynolds", "Boost Bailey", "Cam Carter", "Spark Stone", "Nitro Nash", "Dyno Dean", "Turbo Tate" },
		padId = "TA_DynoSpecialist",
		zoneId = "tuningDyno",
		role = "DYNO TUNING SPECIALIST",
		responsibilities = { "Runs dyno and engine tuning jobs", "Automates the Dyno customer queue" },
		zoneLabels = { "Dyno Bay", "Engine Tune Station" },
		highlightNames = { "DynoStand" },
		metricKind = "tuning",
		baseSeconds = ServiceConfig.TUNING_AUTO_WORK_TIME,
	},
	TuningBodySpecialist = {
		id = "TuningBodySpecialist",
		modelName = "BodySpecialistNPC",
		displayNames = { "Kit Carson", "Panel Paul", "Aero Aaron", "Fender Flynn", "Mold Mason", "Trim Trent", "Rivet Ryan", "Sculpt Sam" },
		padId = "TA_BodySpecialist",
		zoneId = "tuningBody",
		role = "BODY KIT SPECIALIST",
		responsibilities = { "Installs body kits and aero parts", "Automates the Body customer queue" },
		zoneLabels = { "Body Kit Bay", "Body Kit Station" },
		highlightNames = { "BodyKitStation", "BodyKitDisplay" },
		metricKind = "tuning",
		baseSeconds = ServiceConfig.TUNING_AUTO_WORK_TIME,
	},
	TuningPaintSpecialist = {
		id = "TuningPaintSpecialist",
		modelName = "PaintSpecialistNPC",
		displayNames = { "Hue Grant", "Spray Spencer", "Pearl Parker", "Coat Cody", "Gloss Gus", "Tint Tyler", "Clearcoat Cole", "Finish Finn" },
		padId = "TA_PaintSpecialist",
		zoneId = "tuningPaint",
		role = "PAINT & FINISH SPECIALIST",
		responsibilities = { "Applies paint and finish upgrades", "Automates the Paint customer queue" },
		zoneLabels = { "Paint Booth", "Paint Control" },
		highlightNames = { "PaintBooth_Primitive", "PaintControl" },
		metricKind = "tuning",
		baseSeconds = ServiceConfig.TUNING_AUTO_WORK_TIME,
	},
	TuningServiceAdvisor = {
		id = "TuningServiceAdvisor",
		modelName = "ServiceAdvisorNPC",
		displayNames = { "Casey Checkout", "Service Sam", "Queue Quinn", "Advisor Alex", "Desk Drew", "Lane Lee", "Order Owen", "Ticket Terry" },
		padId = ServiceConfig.TUNING_SERVICE_ADVISOR_PAD,
		zoneId = "tuningDyno",
		role = "TUNING SERVICE ADVISOR",
		responsibilities = { "Automatically checks out Tuning customers", "Coordinates Dyno, Body and Paint queues" },
		zoneLabels = { "Admin Office", "All Tuning Service Bays" },
		highlightNames = { "ServiceAdvisorWorkArea", "DynoStand", "BodyKitStation", "PaintBooth_Primitive" },
		metricKind = "advisor",
	},
	TuningOperationsManager = {
		id = "TuningOperationsManager",
		modelName = "OperationsManagerNPC",
		displayNames = { "Morgan Margin", "Bonus Blake", "Profit Pat", "Ledger Logan", "Manager Max", "Revenue Riley", "Numbers Nolan", "Director Drew" },
		padId = ServiceConfig.TUNING_OPERATIONS_MANAGER_PAD,
		zoneId = "tuningDyno",
		role = "TUNING OPERATIONS MANAGER",
		responsibilities = { string.format("Adds %d%% to every Tuning customer payout", TUNING_MANAGER_BONUS_PERCENT), "Oversees Tuning Atelier operations" },
		zoneLabels = { "Admin Office", "Tuning Atelier" },
		highlightNames = { "OperationsManagerWorkArea", "TuningAtelier" },
		metricKind = "manager",
	},
}

local StaffInspectionService = {}
local lastRequest: { [Player]: number } = {}

local function namedRig(root: Instance?, modelName: string): Model?
	if root == nil then
		return nil
	end
	if root.Name == modelName and root:IsA("Model") then
		return root
	end
	for _, descendant in root:GetDescendants() do
		if descendant.Name == modelName and descendant:IsA("Model") then
			return descendant
		end
	end
	return nil
end

local function findRig(record: Record, definition: StaffDefinition): Model?
	return namedRig(record.zones[definition.zoneId], definition.modelName)
		or namedRig(record.locked, definition.modelName)
		-- FirstSalesman rides inside a car while parking it, so he can temporarily leave the
		-- authored zone while still remaining inside this exact owned tycoon.
		or namedRig(record.folder, definition.modelName)
end

local function rootPart(rig: Model): BasePart?
	local named = rig:FindFirstChild("HumanoidRootPart", true)
	if named ~= nil and named:IsA("BasePart") then
		return named
	end
	return rig:FindFirstChildWhichIsA("BasePart", true)
end

local function inspectionHitbox(rig: Model, root: BasePart): BasePart
	local existing = rig:FindFirstChild("StaffInspectHitbox")
	local hitbox: BasePart
	if existing ~= nil and existing:IsA("BasePart") then
		hitbox = existing
	else
		if existing ~= nil then
			existing:Destroy()
		end
		local created = Instance.new("Part")
		created.Name = "StaffInspectHitbox"
		created.Parent = rig
		hitbox = created
	end

	-- Do not derive this shell from Model:GetBoundingBox(). During a claim/reveal the rig
	-- can briefly contain stale or displaced presentation parts, which previously inflated
	-- seated Tuning staff hitboxes to hundreds of studs and moved clicks away from the NPC.
	local oldWeld = hitbox:FindFirstChild("StaffInspectWeld")
	if oldWeld ~= nil then
		oldWeld:Destroy()
	end
	hitbox.Size = Vector3.new(5, 6.5, 4)
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0.75, 0)
	hitbox.Transparency = 1
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.Massless = true
	hitbox.CastShadow = false

	local weld = Instance.new("WeldConstraint")
	weld.Name = "StaffInspectWeld"
	weld.Part0 = root
	weld.Part1 = hitbox
	weld.Parent = hitbox

	-- LotNpc reapplies non-queryable NPC physics while staff sit, walk and work. Keep
	-- this dedicated interaction shell queryable without making body parts clickable.
	if hitbox:GetAttribute("StaffInspectQueryGuardBound") ~= true then
		hitbox:SetAttribute("StaffInspectQueryGuardBound", true)
		hitbox:GetPropertyChangedSignal("CanQuery"):Connect(function()
			if hitbox.Parent ~= nil and not hitbox.CanQuery then
				hitbox.CanQuery = true
			end
		end)
	end
	return hitbox
end

local function purchased(record: Record, definition: StaffDefinition): boolean
	if record.owner == nil then
		return false
	end
	local data = DataService.get(record.owner)
	return data ~= nil and data.pads[definition.padId] == true
end

local function ownedPads(player: Player): { [string]: boolean }
	local data = DataService.get(player)
	return if data ~= nil then data.pads else {}
end

local function averageRepairMultiplier(pads: { [string]: boolean }): number
	local total = 0
	local parts = { "Body", "Wheels", "Engine" }
	for _, partId in parts do
		total += TycoonConfig.repairMultiplierFor(pads, partId)
	end
	return total / #parts
end

local function metricFor(player: Player, definition: StaffDefinition): (string, string)
	if definition.metricKind == "helper" then
		return "QUEUE POLICY", string.format("%ds WAIT · DIRECT DELIVERY", ServiceConfig.QUEUE_WAIT_TIMEOUT)
	elseif definition.metricKind == "tow" then
		return "PROCUREMENT", "1 PAID CAR · RESERVED FIFO"
	elseif definition.metricKind == "advisor" then
		return "CHECKOUT", string.format("%.1fs AUTO · ALL 3 LANES", ServiceConfig.TUNING_CHECKOUT_TIME)
	elseif definition.metricKind == "manager" then
		return "BUSINESS BONUS", string.format("+%d%% TUNING PAYOUT", TUNING_MANAGER_BONUS_PERCENT)
	elseif definition.metricKind == "salesman" then
		local responseSeconds = math.max(0.1, DealerCarConfig.AUTO_ACCEPT_DELAY)
		if definition.id == "FirstSalesman" then
			return "SALES EFFECTIVENESS", string.format("%.1fs RESPONSE · FULL LOOP", responseSeconds)
		end
		return "SALES EFFECTIVENESS", string.format("%.1fs RESPONSE · BUYER SALES", responseSeconds)
	end
	local pads = ownedPads(player)
	local multiplier: number
	if definition.zoneId == "junk" then
		multiplier = averageRepairMultiplier(pads)
	else
		local zone = if definition.metricKind == "tuning" then definition.zoneId else "repair"
		multiplier = TycoonConfig.speedMultiplier(pads, zone)
	end
	local seconds = math.max(0.1, (definition.baseSeconds or 1) / multiplier)
	local unit = if definition.metricKind == "tuning" then "JOB" else "REPAIR"
	return "WORK SPEED", string.format("%.1fs PER %s · %.2fx", seconds, unit, multiplier)
end

local function highlightPaths(record: Record, definition: StaffDefinition): { Instance }
	local paths: { Instance } = {}
	local seen: { [Instance]: boolean } = {}
	for _, name in definition.highlightNames do
		local found = record.folder:FindFirstChild(name, true)
		if found ~= nil and not seen[found] then
			seen[found] = true
			table.insert(paths, found)
		end
	end
	return paths
end

local function nicknameFor(record: Record, definition: StaffDefinition): string
	local tycoonNumber = tonumber(string.match(record.folder.Name, "(%d+)$")) or 1
	local names = definition.displayNames
	local nameIndex = math.clamp(math.floor(tycoonNumber), 1, #names)
	return names[nameIndex]
end

local function payloadFor(
	player: Player,
	record: Record,
	definition: StaffDefinition,
	rig: Model
): any
	local metricLabel, metricValue = metricFor(player, definition)
	local displayName = nicknameFor(record, definition)
	rig:SetAttribute("StaffNickname", displayName)
	return {
		id = definition.id,
		displayName = displayName,
		role = definition.role,
		metricLabel = metricLabel,
		metricValue = metricValue,
		responsibilities = table.clone(definition.responsibilities),
		zoneLabels = table.clone(definition.zoneLabels),
		rig = rig,
		highlights = highlightPaths(record, definition),
	}
end

local function validOwnedRequest(
	player: Player,
	staffId: string,
	requireDistance: boolean,
	rigHint: Model?
): (Record?, StaffDefinition?, Model?)
	local record = TycoonService.getForPlayer(player)
	local definition = STAFF[staffId]
	if record == nil
		or record.owner ~= player
		or definition == nil
		or not purchased(record, definition)
	then
		return nil, nil, nil
	end
	local rig: Model?
	if rigHint ~= nil then
		if rigHint.Name ~= definition.modelName or not rigHint:IsDescendantOf(record.folder) then
			return nil, nil, nil
		end
		rig = rigHint
	else
		rig = findRig(record, definition)
	end
	local staffRoot = if rig ~= nil then rootPart(rig) else nil
	if rig == nil or rig.Parent == nil or staffRoot == nil then
		return nil, nil, nil
	end
	if requireDistance then
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		if playerRoot == nil
			or not playerRoot:IsA("BasePart")
			or (playerRoot.Position - staffRoot.Position).Magnitude > MAX_CLICK_DISTANCE + 4
		then
			return nil, nil, nil
		end
	end
	return record, definition, rig
end

local function inspect(player: Player, staffId: string, requireDistance: boolean, rigHint: Model?)
	local record, definition, rig = validOwnedRequest(player, staffId, requireDistance, rigHint)
	if record == nil or definition == nil or rig == nil then
		return
	end
	Remotes.StaffInspectionState:FireClient(player, payloadFor(player, record, definition, rig))
end

local function bindOne(record: Record, definition: StaffDefinition)
	if not purchased(record, definition) then
		return
	end
	local rig = findRig(record, definition)
	if rig == nil then
		return
	end
	local root = rootPart(rig)
	if root == nil then
		return
	end
	local hitbox = inspectionHitbox(rig, root)
	-- ClickDetector treats the release after a mobile camera drag as a click. Staff world
	-- taps now come through StaffInspectRequest; remove stale runtime detectors defensively.
	local detector = hitbox:FindFirstChild("StaffInspectClick")
	if detector ~= nil then
		detector:Destroy()
	end
	rig:SetAttribute("StaffInspectionId", definition.id)
end

local function refresh(record: Record)
	for _, definition in STAFF do
		bindOne(record, definition)
	end
end

function StaffInspectionService.init()
	Remotes.StaffInspectRequest.OnServerEvent:Connect(function(player: Player, staffId: unknown)
		local now = os.clock()
		if now - (lastRequest[player] or 0) < REQUEST_COOLDOWN then
			return
		end
		lastRequest[player] = now
		if typeof(staffId) ~= "string" or #staffId > 40 or STAFF[staffId] == nil then
			return
		end
		inspect(player, staffId, true, nil)
	end)
	TycoonService.tycoonClaimed.Event:Connect(function(record: Record)
		refresh(record)
	end)
	TycoonService.padPurchased.Event:Connect(function(record: Record)
		refresh(record)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequest[player] = nil
	end)
	for _, record in TycoonService.getAll() do
		refresh(record)
	end
end

StaffInspectionService.STAFF = table.freeze(STAFF)
StaffInspectionService.HIGHLIGHT_COLOR = HIGHLIGHT_COLOR

return StaffInspectionService

