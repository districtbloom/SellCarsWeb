--!strict

export type PadKind = "cash" | "speed" | "structure" | "listing" | "repair" | "value" | "npc"

export type PadDefinition = {
	id: string,
	zone: string,
	order: number,
	title: string,
	category: string,
	kind: PadKind,
	bonus: number,
	-- Optional cross-zone economic scope. The pad still lives in its authored zone,
	-- but its multiplier can affect several stations in the same business.
	bonusZones: { string }?,
	cost: number,
	pad: string,
	models: { string },
	requires: { string }?,
	branch: string?,
	priority: number?,
	starter: boolean?,
	-- Retention-first progression metadata. Optional on authored rows; normalized below.
	chapter: number?,
	chapterOrder: number?,
	functionalCategory: string?,
	bundleId: string?,
	mergedInto: string?,
	-- Optional player-facing copy for the world label and the purchase confirmation.
	-- When omitted, padEffectText derives a useful message from kind/bonus/title.
	effectText: string?,
}

export type ZoneDefinition = {
	id: string,
	path: { string },
	title: string,
}

export type StationDefinition = {
	zone: string,
	host: string,
	adornees: { string },
	title: string,
	instantAuto: boolean,
	unlockPad: string,
	autoPad: string,
	fillTime: number,
	basePayout: number,
	payoutPerLevel: number,
	baseUpgradeCost: number,
	upgradeGrowth: number,
	maxLevel: number,
	studsOffset: Vector3,
	maxDistance: number,
	jobDriven: boolean?,
	chapter: number?,
}

local TycoonConfig = {}

TycoonConfig.STARTING_CASH = 3300
TycoonConfig.PAD_DEBOUNCE = 0.15
TycoonConfig.OWNER_ATTRIBUTE = "OwnerUserId"
TycoonConfig.ZONE_NAME = "JunkSpot"
TycoonConfig.LOCKED_FOLDER_NAME = "Locked"
TycoonConfig.SPAWN_MARKER = "Spawn"
TycoonConfig.SPAWN_HEIGHT = 3
-- Fresh progression season for the Repair Bay rebalance (2026-08-05): the lift chain moved
-- to the front of the zone and every cost in it changed, so old profiles would sit on pads
-- they never paid current prices for. The v3 store is left untouched as a rollback backup.
TycoonConfig.DATASTORE_NAME = "SellCarsTycoon_v9_20260810_working2_stock6"
TycoonConfig.STATION_TAG = "MoneyStation"
TycoonConfig.ZONE_TAG = "TycoonZone"
TycoonConfig.SALESMAN_MODEL = "FirstSalesman"
TycoonConfig.LISTING_PAD_ID = "RepairPad"
TycoonConfig.SERVICE_CLIENTS_ENABLED = true
-- Routing V2 is integrated feature-by-feature. A journey latches these values at begin,
-- so a live flag change never switches protocol or geometry halfway through a drive.
TycoonConfig.ROUTING_V2_SERVICE = false
TycoonConfig.ROUTING_V2_USED_PARKING = true
TycoonConfig.ROUTING_V2_TOW = true
-- Chapter 6 is deliberately the first service-business step above the completed Repair Bay.
-- Keep this named because both payout authority and player-facing staff UI consume it.
TycoonConfig.TUNING_OPERATIONS_MANAGER_MULTIPLIER = 1.25
TycoonConfig.TUNING_SERVICE_ADVISOR_SPEED_MULTIPLIER = 1.2
-- The Repair Bay checkout clerk is the service manager for the finished admin block.
-- These named values are consumed by both payout/speed authority and staff inspection UI.
TycoonConfig.REPAIR_SERVICE_MANAGER_PAD = "CO_CheckoutAutomation"
TycoonConfig.REPAIR_SERVICE_MANAGER_INCOME_MULTIPLIER = 1.25
TycoonConfig.REPAIR_SERVICE_MANAGER_SPEED_MULTIPLIER = 1.2

-- Tow procurement is a paid Repair Bay staff stage. The driver never grants free stock:
-- each recovered car enters the normal seller FIFO and still has to be purchased.
TycoonConfig.TOW_TRUCK_DRIVER_PAD = "RB_TowTruckDriver"
TycoonConfig.TOW_TRUCK_DRIVER_SHIRT = "rbxassetid://130837197855668"
TycoonConfig.TOW_TRUCK_DRIVER_PANTS = "rbxassetid://121089657153202"
TycoonConfig.TOW_FIRST_DISPATCH_DELAY = 10
TycoonConfig.TOW_OFFSITE_MIN = 35
TycoonConfig.TOW_OFFSITE_MAX = 55
TycoonConfig.TOW_COOLDOWN_MIN = 25
TycoonConfig.TOW_COOLDOWN_MAX = 40
TycoonConfig.TOW_DRIVE_SPEED = 40
-- Tow returns originate offsite; use more road-graph hops than ordinary seller arrivals so
-- the rig enters from beyond the streamed dealership frontage instead of popping nearby.
TycoonConfig.TOW_RETURN_ROAD_STEPS = 12

TycoonConfig.NPC_MODELS = {
	{ zone = "junk", model = "FirstMechanic", pad = "FirstMechanic" },
	{ zone = "junk", model = "SecondMechanic", pad = "SecondMechanic" },
	{ zone = "junk", model = "ServiceHelper", pad = "ServiceHelper" },
	{ zone = "junk", model = "ServiceHelper2", pad = "ServiceHelper2" },
	{ zone = "junk", model = "ServiceHelper3", pad = "ServiceHelper3" },
	{ zone = "junk", model = "FirstSalesman", pad = "FirstSalesman" },
	{ zone = "usedcars", model = "UsedCarsSalesman", pad = "UsedCarsSalesman" },
	{ zone = "repair", model = "MechanicNPC_Bay1", pad = "RB_MechanicNPC" },
	{ zone = "repair", model = "TowTruckDriverNPC", pad = "RB_TowTruckDriver" },
	{ zone = "repair", model = "MechanicNPC_Bay2", pad = "RB2_MechanicNPC" },
	{ zone = "repair", model = "CheckoutClerkNPC", pad = "CO_CheckoutAutomation" },
	{ zone = "tuningDyno", model = "DynoSpecialistNPC", pad = "TA_DynoSpecialist" },
	{ zone = "tuningBody", model = "BodySpecialistNPC", pad = "TA_BodySpecialist" },
	{ zone = "tuningPaint", model = "PaintSpecialistNPC", pad = "TA_PaintSpecialist" },
	{ zone = "tuningDyno", model = "ServiceAdvisorNPC", pad = "TA_ServiceAdvisor" },
	{ zone = "tuningDyno", model = "OperationsManagerNPC", pad = "TA_OperationsManager" },
}
TycoonConfig.MIN_FILL_TIME = 0.15

TycoonConfig.ZONES = {
	{ id = "junk", path = { "Buildings", "JunkSpot", "JunkSpot" }, title = "Junk Car Lot" },
	-- The used-car forecourt is a sibling of the junk lot, not a child, so its pads and
	-- models are invisible to the junk zone lookup and need a zone of their own.
	{ id = "usedcars", path = { "Buildings", "JunkSpot", "JunkSpot_UsedCars" }, title = "Used Car Lot" },
	{ id = "repair", path = { "Buildings", "RepairBay" }, title = "Repair Bay" },
	-- A distinct station ledger on the same authored building keeps Tow Truck payouts and
	-- MoneyStation attributes independent from the ordinary Repair Station host.
	{ id = "tow", path = { "Buildings", "RepairBay" }, title = "Tow Truck Service" },
	{ id = "wash", path = { "Buildings", "CarWash" }, title = "Car Wash" },
	{ id = "wash2", path = { "Buildings", "CarWash", "CarWash", "CarWash2" }, title = "Car Wash 2" },
	{ id = "tuningDyno", path = { "Buildings", "TuningAtelier" }, title = "Tuning Atelier — Dyno" },
	{ id = "tuningBody", path = { "Buildings", "TuningAtelier" }, title = "Tuning Atelier — Body" },
	{ id = "tuningPaint", path = { "Buildings", "TuningAtelier" }, title = "Tuning Atelier — Paint" },
} :: { ZoneDefinition }

-- The junk lot keeps one repeatable parts-auction job at the workbench laptop. It remains
-- the anti-softlock recovery loop: a player who spends their last dollar can always sell
-- another batch of car parts and get back to the cheapest incoming deal.
TycoonConfig.STATIONS = {
	{
		zone = "junk",
		host = "SimpleWorkbench",
		adornees = { "SimpleWorkbench" },
		title = "SELL CAR PARTS",
		instantAuto = false,
		unlockPad = "FirstWorkbench",
		autoPad = "FirstMechanic",
		fillTime = 5,
		basePayout = 28,
		payoutPerLevel = 16,
		baseUpgradeCost = 220,
		upgradeGrowth = 1.35,
		maxLevel = 20,
		studsOffset = Vector3.new(0, 7, 0),
		maxDistance = 90,
	},
	{
		zone = "repair",
		host = "RepairBay",
		adornees = { "RepairStation", "CarLift" },
		title = "REPAIR STATION",
		instantAuto = false,
		jobDriven = true,
		unlockPad = "RB_Foundation",
		autoPad = "RB_MechanicNPC",
		-- A bay job is a ~64s round trip (~0.94 jobs/min). Upgrade payback is tuned to that
		-- full cycle, not fillTime: ~$3000 / ($1100 * 0.94) ≈ 2.9 min wall-clock.
		fillTime = 12,
		basePayout = 600,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		-- Payout is LINEAR (+payoutPerLevel a level) so the cost curve has to stay gentle.
		-- At 1.28 the two diverged badly: an upgrade paid for itself in 22 min at level 15,
		-- 1.2 h at level 20 and 15 h at level 30, which put the top half of the 50 levels
		-- out of reach and made every press feel like a worse deal than the last. At 1.15
		-- payback climbs smoothly instead - about 5 min at level 20, 40 min at level 30,
		-- 11 h at level 50 - so the whole range stays worth buying.
		upgradeGrowth = 1,
		maxLevel = 1,
		-- X/Z are read in the host part's own axes, so the panel keeps its place relative to
		-- the bay in all eight rotated lots. Sat at the origin it hung over the car on the
		-- lift; it now floats above and ahead of the bonnet, clear of the bodywork.
		studsOffset = Vector3.new(0, 9, 10),
		maxDistance = 120,
	},
	{
		-- One successful, exact queue delivery is one towing service job. It shares Repair
		-- cash pads but uses half the base, so max-upgrade payout is exactly 50% of Repair.
		zone = "tow",
		host = "RB1_TowTruckModel",
		adornees = { "Car_Body" },
		title = "TOWING SERVICE",
		instantAuto = true,
		jobDriven = true,
		unlockPad = "RB_TowTruckDriver",
		autoPad = "RB_TowTruckDriver",
		fillTime = 12,
		basePayout = 300,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 8, 0),
		maxDistance = 120,
	},
	{
		-- The visible NPC-car cycle is authoritative; this station prices and pays
		-- every completed wash exactly once.
		zone = "wash",
		host = "CarWash",
		adornees = { "CarWash_ServicePad", "BrushMachineBody" },
		title = "CAR WASH",
		instantAuto = true,
		jobDriven = true,
		unlockPad = "CW_BrushMachine",
		autoPad = "CW_BrushMachine",
		fillTime = 12,
		basePayout = 2400,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 8, 0),
		maxDistance = 140,
	},
	{
		-- The second lane has its own host, payout ledger and upgrade multiplier scope.
		zone = "wash2",
		host = "CarWash2",
		adornees = { "CarWash2_ServicePad", "CarWash2_DriveSurface" },
		title = "CAR WASH 2",
		instantAuto = true,
		jobDriven = true,
		unlockPad = "CW2_BrushMachine",
		autoPad = "CW2_BrushMachine",
		fillTime = 12,
		basePayout = 2400,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 8, 0),
		maxDistance = 140,
	},
	-- Each Tuning Atelier bay has an independent job ledger and payout authority. Their
	-- distinct zones prevent upgrades, hosts and idempotency ledgers from leaking across bays.
	{
		zone = "tuningDyno",
		host = "TuningDyno",
		adornees = { "DynoStand" },
		title = "DYNO + ENGINE TUNE",
		instantAuto = false,
		jobDriven = true,
		unlockPad = "TA_DynoRollers",
		autoPad = "TA_DynoSpecialist",
		fillTime = 10,
		basePayout = 22000,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 7, 0),
		maxDistance = 140,
	},
	{
		zone = "tuningBody",
		host = "TuningBody",
		adornees = { "BodyKitStation" },
		title = "BODY KIT INSTALL",
		instantAuto = false,
		jobDriven = true,
		unlockPad = "TA_BodyKitStation",
		autoPad = "TA_BodySpecialist",
		fillTime = 10,
		basePayout = 25000,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 7, 0),
		maxDistance = 140,
	},
	{
		zone = "tuningPaint",
		host = "TuningPaint",
		adornees = { "ControlPanel" },
		title = "PAINT + FINISH",
		instantAuto = false,
		jobDriven = true,
		unlockPad = "TA_PaintControl",
		autoPad = "TA_PaintSpecialist",
		fillTime = 10,
		basePayout = 30000,
		payoutPerLevel = 0,
		baseUpgradeCost = 0,
		upgradeGrowth = 1,
		maxLevel = 1,
		studsOffset = Vector3.new(0, 7, 0),
		maxDistance = 140,
	},
} :: { StationDefinition }

local STATION_CHAPTERS = {
	junk = 1,
	repair = 3,
	tow = 3,
	wash = 4,
	wash2 = 5,
	tuningDyno = 6,
	tuningBody = 6,
	tuningPaint = 6,
}
for _, station in TycoonConfig.STATIONS do
	station.chapter = STATION_CHAPTERS[station.zone] or 1
end

TycoonConfig.STATION = TycoonConfig.STATIONS[1]

TycoonConfig.PADS = {
	-- Junk Spot has one sequential functional spine. Optional decor appears gradually
	-- beside later money-making upgrades and never blocks automation or the next business.
	{ id = "RepairPad", zone = "junk", order = 1, title = "Repair Pad", category = "BUSINESS", kind = "listing", bonus = 1, cost = 0, pad = "RepairPadBuyPad", models = { "DisplayPadRepair" }, starter = true, branch = "core", priority = 1, effectText = "UNLOCKS CAR REPAIR + LISTING" },
	{ id = "RepairPad2", zone = "junk", order = 1.5, title = "Repair Pad 2", category = "BUSINESS", kind = "listing", bonus = 1, cost = 1600, pad = "RepairPad2BuyPad", models = { "DisplayPadRepair2" }, requires = { "FirstSalesman" }, branch = "core", priority = 1.5, effectText = "+1 ACTIVE CAR SLOT", functionalCategory = "CAPACITY" },
	{ id = "SecondMechanic", zone = "junk", order = 1.6, title = "Second Mechanic", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 2400, pad = "SecondMechanicBuyPad", models = { "SecondMechanic" }, requires = { "Parking2" }, branch = "core", priority = 1.6, effectText = "+1 AUTO-REPAIR WORKER", functionalCategory = "AUTOMATION" },
	{ id = "FirstWorkbench", zone = "junk", order = 2, title = "Parts Sales Laptop", category = "BUSINESS", kind = "structure", bonus = 1, cost = 0, pad = "FirstWorkbenchBuyPad", models = { "SimpleWorkbench" }, starter = true, branch = "core", priority = 2, effectText = "SELL SALVAGED PARTS FOR CASH" },
	{ id = "CashRegister", zone = "junk", order = 3, title = "Cash Register", category = "TRADE", kind = "structure", bonus = 1, cost = 100, pad = "CashRegisterBuyPad", models = { "CashDeskA" }, requires = { "RepairPad", "FirstWorkbench" }, branch = "main", priority = 10, effectText = "UNLOCKS BUYING + SELLING", functionalCategory = "PROGRESSION" },
	{ id = "SalesSign", zone = "junk", order = 10, title = "Sales Sign", category = "TRADE", kind = "value", bonus = 1.15, cost = 300, pad = "SalesSignBuyPad", models = { "SaleSign" }, requires = { "WheelBalancer" }, branch = "main", priority = 23 },
	{ id = "CarJack", zone = "junk", order = 5, title = "Car Jack", category = "REPAIR", kind = "repair", bonus = 1.25, cost = 300, pad = "CarJackBuyPad", models = { "CarJack" }, requires = { "FirstSalesman" }, branch = "main", priority = 11, functionalCategory = "PROGRESSION" },
	{ id = "FirstMechanic", zone = "junk", order = 5, title = "First Mechanic", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 700, pad = "FirstMechanicBuyPad", models = { "FirstMechanic" }, requires = { "AirCompressor" }, branch = "main", priority = 13, effectText = "AUTOMATES REPAIRS + PARTS SALES", functionalCategory = "AUTOMATION" },
	{ id = "FirstSalesman", zone = "junk", order = 4, title = "First Salesman", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 1500, pad = "FirstSalesManBuyPad", models = { "FirstSalesman" }, requires = { "CashRegister" }, branch = "main", priority = 11, effectText = "AUTOMATES BUYING + CAR TRANSPORT", functionalCategory = "AUTOMATION" },
	-- The first post-tutorial purchases are deliberately serialized: Jack, Compressor,
	-- then Mechanic. Showing two cyan pads at once makes the intended progression ambiguous.
	{ id = "AirCompressor", zone = "junk", order = 7, title = "Air Compressor", category = "REPAIR", kind = "repair", bonus = 1.25, cost = 600, pad = "AirComperssorBuyPad", models = { "AirCompressor" }, requires = { "CarJack" }, branch = "main", priority = 12, functionalCategory = "PROGRESSION" },
	{ id = "TireMount", zone = "junk", order = 8, title = "Tire Mount", category = "REPAIR", kind = "repair", bonus = 1.2, cost = 900, pad = "TireMountBuyPad", models = { "TireMount" }, requires = { "AirCompressor" }, branch = "speed", priority = 21 },
	{ id = "WheelBalancer", zone = "junk", order = 9, title = "Wheel Balancer", category = "REPAIR", kind = "repair", bonus = 1.2, cost = 900, pad = "WheelBalancerBuyPad", models = { "WheelBalancer" }, requires = { "TireMount" }, branch = "speed", priority = 22 },
	{ id = "ScrapBin", zone = "junk", order = 11, title = "Scrap Bin", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1200, pad = "ScrapBinBuyPad", models = { "ScrapBin" }, requires = { "AirCompressor" }, branch = "decor", priority = 30, effectText = "UNLOCKS STORAGE SHED PATH" },
	{ id = "StorageShed", zone = "junk", order = 12, title = "Storage Shed", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1600, pad = "StorageShedBuyPad", models = { "RustyBuilding" }, requires = { "TireMount", "ScrapBin" }, branch = "decor", priority = 31 },
	{ id = "StorageShelf", zone = "junk", order = 13, title = "Storage Shelf", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1400, pad = "StorageShelfBuyPad", models = { "PartsShelf_old" }, requires = { "WheelBalancer", "StorageShed" }, branch = "decor", priority = 32 },
	{ id = "LeftFence", zone = "junk", order = 14, title = "Left Fence", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1200, pad = "LeftFenceBuyPad", models = { "LeftFence" }, requires = { "FirstMechanic", "StorageShed" }, branch = "decor", priority = 33 },
	{ id = "RightFence", zone = "junk", order = 15, title = "Right Fence", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1200, pad = "RightFenceBuyPad", models = { "RightFence" }, requires = { "FirstMechanic", "StorageShed" }, branch = "decor", priority = 34 },
	{ id = "BackFence", zone = "junk", order = 16, title = "Back Fence", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 1800, pad = "BackFenceBuyPad", models = { "BackFence" }, requires = { "LeftFence", "RightFence" }, branch = "decor", priority = 35 },
	{ id = "RightFloodlight", zone = "junk", order = 18, title = "Right Floodlight", category = "LOT UPGRADE", kind = "structure", bonus = 1, cost = 2200, pad = "RightFloodlightBuyPad", models = { "JunkSpotFloodlight_Right" }, requires = { "ScrapBin" }, branch = "decor", priority = 37 },

	-- Used-car forecourt. Space 1 and the floodlight beside it come with the lot; the rest
	-- of the row is bought a space at a time and each one is worth more than the last.
	-- Opens alongside the Repair Bay permit rather than gating it: priorities sit behind
	-- the core chain so the "next pad" arrow keeps pointing at the main progression while
	-- these stay available in parallel.
	{ id = "Parking2", zone = "usedcars", order = 19, title = "Parking Space 2", category = "USED CARS", kind = "value", bonus = 1.06, cost = 800, pad = "Parking2BuyPad", models = { "ParkingSpace_02" }, requires = { "RepairPad2" }, branch = "used-cars", priority = 23, functionalCategory = "CAPACITY" },
	{ id = "UsedCarsSalesman", zone = "usedcars", order = 19.5, title = "Used Cars Salesman", category = "USED CARS", kind = "npc", bonus = 1, cost = 2500, pad = "UsedCarsSalesmanBuyPad", models = { "UsedCarsSalesman" }, requires = { "FirstSalesman" }, branch = "used-cars", priority = 23.5 },
	{ id = "Parking3", zone = "usedcars", order = 20, title = "Parking Space 3", category = "USED CARS", kind = "value", bonus = 1.07, cost = 1600, pad = "Parking3BuyPad", models = { "ParkingSpace_03" }, requires = { "Parking2" }, branch = "used-cars", priority = 24 },
	{ id = "Parking4", zone = "usedcars", order = 21, title = "Parking Space 4", category = "USED CARS", kind = "value", bonus = 1.08, cost = 3000, pad = "Parking4BuyPad", models = { "ParkingSpace_04" }, requires = { "Parking3" }, branch = "used-cars", priority = 25 },
	{ id = "Parking5", zone = "usedcars", order = 22, title = "Parking Space 5", category = "USED CARS", kind = "value", bonus = 1.09, cost = 5500, pad = "Parking5BuyPad", models = { "ParkingSpace_05" }, requires = { "Parking4" }, branch = "used-cars", priority = 26 },
	{ id = "Parking6", zone = "usedcars", order = 23, title = "Parking Space 6", category = "USED CARS", kind = "value", bonus = 1.1, cost = 9500, pad = "Parking6BuyPad", models = { "ParkingSpace_06" }, requires = { "Parking5" }, branch = "used-cars", priority = 27 },

	-- The forecourt's four corner floodlights. The one beside space 1 comes with the lot;
	-- the other three are bought on their own pads, each unlocked by the space it lights,
	-- so the corner lights up once there is a car parked under it. A lit lot sells better,
	-- hence a small value bonus rather than a purchase that moves nothing.
	{ id = "ParkingLightRightFront", zone = "usedcars", order = 24, title = "Forecourt Light — Front", category = "USED CARS", kind = "value", bonus = 1.04, cost = 1200, pad = "ParkingLightRightFrontBuyPad", models = { "Floodlight_Right_Front" }, requires = { "Parking4" }, branch = "used-cars", priority = 28 },
	{ id = "ParkingLightLeftRear", zone = "usedcars", order = 25, title = "Forecourt Light — Rear Left", category = "USED CARS", kind = "value", bonus = 1.04, cost = 2000, pad = "ParkingLightLeftRearBuyPad", models = { "Floodlight_Left_Rear" }, requires = { "Parking3" }, branch = "used-cars", priority = 29 },
	{ id = "ParkingLightRightRear", zone = "usedcars", order = 26, title = "Forecourt Light — Rear Right", category = "USED CARS", kind = "value", bonus = 1.04, cost = 3500, pad = "ParkingLightRightRearBuyPad", models = { "Floodlight_Right_Rear" }, requires = { "Parking6" }, branch = "used-cars", priority = 30 },

	-- Chapter break: Junk Lot automation is done; this permit opens the Repair Bay as a
	-- second business instead of letting the foundation pad feel like the next junk upgrade.
	{ id = "OpenRepairBay", zone = "repair", order = 11, title = "Open Repair Bay", category = "NEXT BUSINESS", kind = "structure", bonus = 1, cost = 900, pad = "OpenRepairBayBuyPad", models = { "RB1_FoundationModel" }, requires = { "SecondMechanic" }, branch = "repair-bay", priority = 17.5, functionalCategory = "PROGRESSION" },
	-- Dedicated owner-stock escort. Its pad is physically at the Junk Spot, but it does not
	-- appear until the first Repair Bay lift can actually accept a car.
	{ id = "ServiceHelper", zone = "junk", order = 11.5, title = "Service Helper", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 3000, pad = "ServiceHelperBuyPad", models = { "ServiceHelper" }, requires = { "RB_CarLift" }, branch = "owner-pipeline", priority = 17.75, effectText = "+1 SERVICE HELPER", functionalCategory = "AUTOMATION" },
	{ id = "ServiceHelper2", zone = "junk", order = 11.6, title = "Second Service Helper", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 6000, pad = "ServiceHelper2BuyPad", models = { "ServiceHelper2" }, requires = { "ServiceHelper" }, branch = "owner-pipeline", priority = 17.76, effectText = "+1 SERVICE HELPER" },
	{ id = "ServiceHelper3", zone = "junk", order = 11.7, title = "Third Service Helper", category = "AUTOMATION", kind = "npc", bonus = 1, cost = 15000, pad = "ServiceHelper3BuyPad", models = { "ServiceHelper3" }, requires = { "ServiceHelper2" }, branch = "owner-pipeline", priority = 17.77, effectText = "+1 SERVICE HELPER" },

	-- Repair Bay New — stage 1. The lift chain comes FIRST: foundation, ramps, lift and
	-- mechanic are the cheapest things in the zone, so the bay starts paying within a
	-- couple of minutes of unlocking. The shell that used to sit in front of them is now
	-- a run of cash upgrades behind them, because 600k of inert walls before the first
	-- dollar was three and a half hours of completely flat income.
	{ id = "RB_Foundation", zone = "repair", order = 12, title = "Repair Bay Foundation", category = "REPAIR BAY", kind = "structure", bonus = 1, cost = 600, pad = "RepairBayBuyPad", models = {}, requires = { "OpenRepairBay" }, branch = "repair-bay", priority = 18 },
	{ id = "RB_ApproachRamp", zone = "repair", order = 13, title = "Approach Ramp", category = "REPAIR BAY", kind = "structure", bonus = 1, cost = 300, pad = "ApproachRampBuyPad", models = { "RB1_ApproachRampModel" }, requires = { "OpenRepairBay" }, branch = "repair-bay", priority = 19, functionalCategory = "BUILD" },
	{ id = "RB_ServiceRamp", zone = "repair", order = 14, title = "Service Area", category = "REPAIR BAY", kind = "structure", bonus = 1, cost = 300, pad = "ServiceRampBuyPad", models = { "RB1_ServiceRampModel" }, requires = { "RB_ApproachRamp" }, branch = "repair-bay", priority = 20, functionalCategory = "BUILD" },
	-- Car Lift completes the job slot: the bay takes its first customer here.
	{ id = "RB_CarLift", zone = "repair", order = 15, title = "Install Car Lift", category = "REPAIR BAY", kind = "structure", bonus = 1, cost = 1200, pad = "CarLiftBuyPad", models = { "RB1_CarLiftModel" }, requires = { "RB_ServiceRamp" }, branch = "repair-bay", priority = 21, functionalCategory = "EQUIPMENT" },
	{ id = "RB_MechanicNPC", zone = "repair", order = 23, title = "Hire Bay Mechanic", category = "REPAIR BAY", kind = "cash", bonus = 1.5, cost = 1800, pad = "MechanicNPCBuyPad", models = { "MechanicNPC_Bay1" }, requires = { "RB_CarLift" }, branch = "repair-bay", priority = 22, functionalCategory = "AUTOMATION" },
	{ id = "RB_BackWall", zone = "repair", order = 24, title = "Back Wall", category = "REPAIR BAY", kind = "cash", bonus = 1.12, cost = 2000, pad = "RepairBayBackWallBuyPad", models = { "RB1_BackWallModel" }, requires = { "RB_MechanicNPC" }, branch = "repair-bay", priority = 23 },
	{ id = "RB_SideWall1", zone = "repair", order = 25, title = "Side Wall 1", category = "REPAIR BAY", kind = "cash", bonus = 1.12, cost = 2500, pad = "RepairBaySideWall1BuyPad", models = { "RB1_SideWall1Model" }, requires = { "RB_BackWall" }, branch = "repair-bay", priority = 24 },
	{ id = "RB_SideWall2", zone = "repair", order = 26, title = "Side Wall 2", category = "REPAIR BAY", kind = "cash", bonus = 1.12, cost = 3000, pad = "RepairBaySideWall2BuyPad", models = { "RB1_SideWall2Model" }, requires = { "RB_SideWall1" }, branch = "repair-bay", priority = 25 },
	{ id = "RB_FrontWall", zone = "repair", order = 27, title = "Front Wall", category = "REPAIR BAY", kind = "cash", bonus = 1.12, cost = 3500, pad = "RepairBayFrontWallBuyPad", models = { "RB1_FrontWallModel" }, requires = { "RB_SideWall2" }, branch = "repair-bay", priority = 26 },
	{ id = "RB_Ceiling", zone = "repair", order = 28, title = "Ceiling", category = "REPAIR BAY", kind = "cash", bonus = 1.12, cost = 4000, pad = "CeilingBuyPad", models = { "RB1_CeilingModel" }, requires = { "RB_FrontWall" }, branch = "repair-bay", priority = 27 },
	{ id = "RB_Lights", zone = "repair", order = 29, title = "Lights", category = "REPAIR BAY", kind = "speed", bonus = 1.12, cost = 5000, pad = "LightsBuyPad", models = { "RB1_LightsModel" }, requires = { "RB_Ceiling" }, branch = "repair-bay", priority = 28 },
	{ id = "RB_GarageDoor", zone = "repair", order = 30, title = "Garage Door", category = "REPAIR BAY", kind = "cash", bonus = 1.15, cost = 6000, pad = "GarageDoorBuyPad", models = { "RB1_GarageDoorModel" }, requires = { "RB_Lights" }, branch = "repair-bay", priority = 29 },
	{ id = "RB_ToolCabinet", zone = "repair", order = 31, title = "Tool Cabinet", category = "REPAIR BAY", kind = "speed", bonus = 1.2, cost = 8000, pad = "ToolCabinetBuyPad", models = { "RB1_ToolCabinetModel" }, requires = { "RB_GarageDoor" }, branch = "repair-bay", priority = 30 },
	{ id = "RB_PartsRack", zone = "repair", order = 32, title = "Parts Rack", category = "REPAIR BAY", kind = "cash", bonus = 1.2, cost = 10000, pad = "PartsRackBuyPad", models = { "RB1_PartsRackModel" }, requires = { "RB_ToolCabinet" }, branch = "repair-bay", priority = 31 },
	{ id = "RB_ModernAirCompressor", zone = "repair", order = 33, title = "Modern Air Compressor", category = "REPAIR BAY", kind = "speed", bonus = 1.2, cost = 12500, pad = "ModernAirCompressorBuyPad", models = { "RB1_CompressorModel" }, requires = { "RB_PartsRack" }, branch = "repair-bay", priority = 32 },
	-- DISABLED: this pad has no models at all, so $360k bought a bonus and nothing you
	-- could see. Left defined rather than deleted so existing saves that already contain
	-- it stay readable; it is simply off the MVP gate and out of the requires chain.
	{ id = "RB_CarRepairPlace", zone = "repair", order = 34, title = "Car Repair Place", category = "REPAIR BAY", kind = "cash", bonus = 1.2, cost = 360000, pad = "CarRepairPlaceBuyPad", models = {  }, requires = { "RB_ModernAirCompressor" }, branch = "repair-bay", priority = 33 },
	{ id = "RB_TireStack", zone = "repair", order = 35, title = "Tire Stack", category = "REPAIR BAY", kind = "speed", bonus = 1.2, cost = 15000, pad = "TireStackBuyPad", models = { "RB1_TireStackModel" }, requires = { "RB_ModernAirCompressor" }, branch = "repair-bay", priority = 34 },
	{ id = "RB_TowTruckDropOff", zone = "repair", order = 36, title = "Tow Truck Drop-Off", category = "REPAIR BAY", kind = "cash", bonus = 1.2, cost = 20000, pad = "TowTruckDropOffBuyPad", models = { "RB1_TowTruckDropOffModel" }, requires = { "RB_TireStack" }, branch = "repair-bay", priority = 35 },
	{ id = "RB_TowTruck", zone = "repair", order = 37, title = "Tow Truck", category = "REPAIR BAY", kind = "cash", bonus = 1.1, cost = 30000, pad = "TowTruckBuyPad", models = { "RB1_TowTruckModel" }, requires = { "RB_TowTruckDropOff" }, branch = "repair-bay", priority = 36 },
	{ id = "RB_TowTruckDriver", zone = "repair", order = 37.5, title = "Hire Tow Truck Driver", category = "AUTOMATION", kind = "cash", bonus = 1.2, cost = 35000, pad = "TowTruckDriverBuyPad", models = { "RB1_TowTruckDriverModel" }, requires = { "RB_TowTruck" }, branch = "repair-bay", priority = 36.5, functionalCategory = "AUTOMATION" },
	{ id = "RB_RepairBaySign", zone = "repair", order = 38, title = "Repair Bay Sign", category = "REPAIR BAY", kind = "cash", bonus = 1.25, cost = 7500, pad = "RepairBaySignBuyPad", models = { "RB1_SignModel" }, requires = { "RB_TowTruckDriver" }, branch = "repair-bay", priority = 37 },

	-- Stage 2: administrative block. Every step carries a bonus now - a purchase that
	-- moves no income term is a step the player pays for and feels nothing from.
	{ id = "CO_Walls1", zone = "repair", order = 39, title = "Admin Walls 1", category = "ADMIN BLOCK", kind = "cash", bonus = 1.08, cost = 2500, pad = "CheckoutWalls1BuyPad", models = { "CO_Walls1Model" }, requires = { "RB_RepairBaySign" }, branch = "admin", priority = 38, functionalCategory = "BUILD" },
	{ id = "CO_Walls2", zone = "repair", order = 40, title = "Admin Walls 2", category = "ADMIN BLOCK", kind = "cash", bonus = 1.1, cost = 3000, pad = "CheckoutWalls2BuyPad", models = { "CO_Walls2Model" }, requires = { "CO_Walls1" }, branch = "admin", priority = 39, functionalCategory = "BUILD" },
	{ id = "CO_Walls3", zone = "repair", order = 41, title = "Admin Walls 3", category = "ADMIN BLOCK", kind = "cash", bonus = 1.08, cost = 3500, pad = "CheckoutWalls3BuyPad", models = { "CO_Walls3Model" }, requires = { "CO_Walls2" }, branch = "admin", priority = 40, functionalCategory = "BUILD" },
	{ id = "CO_Ceiling", zone = "repair", order = 42, title = "Admin Ceiling", category = "ADMIN BLOCK", kind = "cash", bonus = 1.1, cost = 4000, pad = "CheckoutCeilingBuyPad", models = { "CO_CeilingModel" }, requires = { "CO_Walls3" }, branch = "admin", priority = 41, functionalCategory = "BUILD" },
	{ id = "CO_Lighting", zone = "repair", order = 43, title = "Admin Lighting", category = "ADMIN BLOCK", kind = "speed", bonus = 1.1, cost = 4500, pad = "CheckoutLightingBuyPad", models = { "CO_LightingModel" }, requires = { "CO_Ceiling" }, branch = "admin", priority = 42, functionalCategory = "SPEED" },
	{ id = "CO_ComputerDesk", zone = "repair", order = 44, title = "Computer Desk", category = "ADMIN BLOCK", kind = "cash", bonus = 1.15, cost = 5000, pad = "CheckoutComputerDeskBuyPad", models = { "CO_DeskModel" }, requires = { "CO_Lighting" }, branch = "admin", priority = 43, functionalCategory = "INCOME" },
	{ id = "CO_Chair", zone = "repair", order = 45, title = "Office Chair", category = "ADMIN BLOCK", kind = "cash", bonus = 1.08, cost = 5500, pad = "CheckoutChairBuyPad", models = { "CO_ChairModel" }, requires = { "CO_ComputerDesk" }, branch = "admin", priority = 44, functionalCategory = "INCOME" },
	{ id = "CO_StorageCrates", zone = "repair", order = 46, title = "Storage Crates", category = "ADMIN BLOCK", kind = "cash", bonus = 1.15, cost = 6000, pad = "CheckoutStorageCratesBuyPad", models = { "CO_StorageModel" }, requires = { "CO_Chair" }, branch = "admin", priority = 45, functionalCategory = "INCOME" },
	{ id = "CO_RearExitLight", zone = "repair", order = 47, title = "Back Exit Light", category = "ADMIN BLOCK", kind = "speed", bonus = 1.08, cost = 6500, pad = "RearExitLightBuyPad", models = { "CO_RearExitLightModel" }, requires = { "CO_StorageCrates" }, branch = "admin", priority = 46, functionalCategory = "SPEED" },

	-- Stage 3: first warehouse.
	{ id = "WH1_Foundation", zone = "repair", order = 48, title = "Warehouse 1 Foundation", category = "WAREHOUSE 1", kind = "cash", bonus = 1.08, cost = 8000, pad = "Warehouse1FoundationBuyPad", models = { "WH1_FoundationModel" }, requires = { "CO_CheckoutAutomation" }, branch = "warehouse-1", priority = 47, functionalCategory = "BUILD" },
	{ id = "WH1_Supports", zone = "repair", order = 49, title = "Warehouse 1 Supports", category = "WAREHOUSE 1", kind = "cash", bonus = 1.08, cost = 9000, pad = "Warehouse1SupportsBuyPad", models = { "WH1_SupportsModel" }, requires = { "WH1_Foundation" }, branch = "warehouse-1", priority = 48, functionalCategory = "BUILD" },
	{ id = "WH1_Canopy", zone = "repair", order = 50, title = "Warehouse 1 Canopy", category = "WAREHOUSE 1", kind = "cash", bonus = 1.08, cost = 10000, pad = "Warehouse1CanopyBuyPad", models = { "WH1_CanopyModel" }, requires = { "WH1_Supports" }, branch = "warehouse-1", priority = 49, functionalCategory = "BUILD" },
	{ id = "WH1_Row1", zone = "repair", order = 51, title = "Warehouse 1 Row 1", category = "WAREHOUSE 1", kind = "cash", bonus = 1.12, cost = 11000, pad = "Warehouse1Row1BuyPad", models = { "WH1_Row1Model" }, requires = { "WH1_Canopy" }, branch = "warehouse-1", priority = 50, functionalCategory = "INCOME" },
	{ id = "WH1_Row2", zone = "repair", order = 52, title = "Warehouse 1 Row 2", category = "WAREHOUSE 1", kind = "cash", bonus = 1.12, cost = 12000, pad = "Warehouse1Row2BuyPad", models = { "WH1_Row2Model" }, requires = { "WH1_Row1" }, branch = "warehouse-1", priority = 51, functionalCategory = "INCOME" },
	{ id = "WH1_Row3", zone = "repair", order = 53, title = "Warehouse 1 Row 3", category = "WAREHOUSE 1", kind = "cash", bonus = 1.12, cost = 13000, pad = "Warehouse1Row3BuyPad", models = { "WH1_Row3Model" }, requires = { "WH1_Row2" }, branch = "warehouse-1", priority = 52, functionalCategory = "INCOME" },
	{ id = "WH1_Row4", zone = "repair", order = 54, title = "Warehouse 1 Row 4", category = "WAREHOUSE 1", kind = "cash", bonus = 1.12, cost = 14000, pad = "Warehouse1Row4BuyPad", models = { "WH1_Row4Model" }, requires = { "WH1_Row3" }, branch = "warehouse-1", priority = 53, functionalCategory = "INCOME" },
	{ id = "WH1_Lights", zone = "repair", order = 55, title = "Warehouse 1 Lights", category = "WAREHOUSE 1", kind = "speed", bonus = 1.12, cost = 15000, pad = "Warehouse1LightsBuyPad", models = { "WH1_LightsModel" }, requires = { "WH1_Row4" }, branch = "warehouse-1", priority = 54, functionalCategory = "SPEED" },

	-- Stage B: the second Repair Bay now builds one visible piece at a time, mirroring
	-- the first bay. The lift opens the extra service slot; the mechanic automates it.
	{ id = "RB2_Foundation", zone = "repair", order = 56, title = "Bay 2 Foundation", category = "REPAIR BAY 2", kind = "structure", bonus = 1, cost = 4000, pad = "SecondRepairBayBuyPad", models = { "RB2_FoundationModel" }, requires = { "Parking2", "RB_CarLift", "CO_CheckoutAutomation" }, branch = "repair-bay-2", priority = 55, functionalCategory = "BUILD" },
	{ id = "RB2_ApproachRamp", zone = "repair", order = 56.1, title = "Bay 2 Approach Ramp", category = "REPAIR BAY 2", kind = "structure", bonus = 1, cost = 2000, pad = "SecondRepairBayApproachBuyPad", models = { "RB2_ApproachRampModel" }, requires = { "RB2_Foundation" }, branch = "repair-bay-2", priority = 55.1, functionalCategory = "BUILD" },
	{ id = "RB2_ServiceArea", zone = "repair", order = 56.2, title = "Bay 2 Service Area", category = "REPAIR BAY 2", kind = "structure", bonus = 1, cost = 2000, pad = "SecondRepairBayServiceAreaBuyPad", models = { "RB2_ServiceAreaModel" }, requires = { "RB2_ApproachRamp" }, branch = "repair-bay-2", priority = 55.2, functionalCategory = "BUILD" },
	{ id = "RB2_CarLift", zone = "repair", order = 56.3, title = "Bay 2 Car Lift", category = "REPAIR BAY 2", kind = "structure", bonus = 1.5, cost = 8000, pad = "SecondRepairBayCarLiftBuyPad", models = { "RB2_CarLiftModel" }, requires = { "RB2_ServiceArea" }, branch = "repair-bay-2", priority = 55.3, functionalCategory = "CAPACITY" },
	{ id = "RB2_MechanicNPC", zone = "repair", order = 56.4, title = "Second Bay Mechanic", category = "REPAIR BAY 2", kind = "cash", bonus = 1.25, cost = 18000, pad = "SecondRepairBayMechanicBuyPad", models = { "MechanicNPC_Bay2" }, requires = { "RB2_CarLift" }, branch = "repair-bay-2", priority = 55.4, functionalCategory = "AUTOMATION" },
	{ id = "RB2_BackWall", zone = "repair", order = 56.5, title = "Bay 2 Back Wall", category = "REPAIR BAY 2", kind = "cash", bonus = 1.08, cost = 4000, pad = "SecondRepairBayBackWallBuyPad", models = { "RB2_BackWallModel" }, requires = { "RB2_MechanicNPC" }, branch = "repair-bay-2", priority = 55.5, functionalCategory = "INCOME" },
	{ id = "RB2_SideWall", zone = "repair", order = 56.6, title = "Bay 2 Side Wall", category = "REPAIR BAY 2", kind = "cash", bonus = 1.08, cost = 4000, pad = "SecondRepairBaySideWallBuyPad", models = { "RB2_SideWallModel" }, requires = { "RB2_BackWall" }, branch = "repair-bay-2", priority = 55.6, functionalCategory = "INCOME" },
	{ id = "RB2_FrontFrame", zone = "repair", order = 56.7, title = "Bay 2 Front Frame", category = "REPAIR BAY 2", kind = "cash", bonus = 1.08, cost = 4000, pad = "SecondRepairBayFrontFrameBuyPad", models = { "RB2_FrontFrameModel" }, requires = { "RB2_SideWall" }, branch = "repair-bay-2", priority = 55.7, functionalCategory = "INCOME" },
	{ id = "RB2_Ceiling", zone = "repair", order = 56.8, title = "Bay 2 Ceiling", category = "REPAIR BAY 2", kind = "cash", bonus = 1.08, cost = 5000, pad = "SecondRepairBayCeilingBuyPad", models = { "RB2_CeilingModel" }, requires = { "RB2_FrontFrame" }, branch = "repair-bay-2", priority = 55.8, functionalCategory = "INCOME" },
	{ id = "RB2_Lights", zone = "repair", order = 56.9, title = "Bay 2 Lights", category = "REPAIR BAY 2", kind = "speed", bonus = 1.1, cost = 4000, pad = "SecondRepairBayLightsBuyPad", models = { "RB2_LightsModel" }, requires = { "RB2_Ceiling" }, branch = "repair-bay-2", priority = 55.9, functionalCategory = "SPEED" },
	{ id = "RB2_GarageDoor", zone = "repair", order = 57, title = "Bay 2 Garage Door", category = "REPAIR BAY 2", kind = "cash", bonus = 1.1, cost = 5000, pad = "SecondRepairBayGarageDoorBuyPad", models = { "RB2_GarageDoorModel" }, requires = { "RB2_Lights" }, branch = "repair-bay-2", priority = 56, functionalCategory = "INCOME" },
	{ id = "RB2_PartsShelf", zone = "repair", order = 57.1, title = "Bay 2 Parts Shelf", category = "REPAIR BAY 2", kind = "cash", bonus = 1.12, cost = 5000, pad = "SecondRepairBayPartsShelfBuyPad", models = { "RB2_PartsShelfModel" }, requires = { "RB2_GarageDoor" }, branch = "repair-bay-2", priority = 56.1, functionalCategory = "INCOME" },
	{ id = "RB2_Compressor", zone = "repair", order = 57.2, title = "Bay 2 Air Compressor", category = "REPAIR BAY 2", kind = "speed", bonus = 1.12, cost = 6000, pad = "SecondRepairBayCompressorBuyPad", models = { "RB2_CompressorModel" }, requires = { "RB2_PartsShelf" }, branch = "repair-bay-2", priority = 56.2, functionalCategory = "SPEED" },
	{ id = "RB2_Sign", zone = "repair", order = 57.3, title = "Bay 2 Sign", category = "REPAIR BAY 2", kind = "cash", bonus = 1.12, cost = 3000, pad = "SecondRepairBaySignBuyPad", models = { "RB2_SignModel" }, requires = { "RB2_Compressor" }, branch = "repair-bay-2", priority = 56.3, functionalCategory = "INCOME" },

	-- Stage 5: second warehouse.
	{ id = "WH2_Foundation", zone = "repair", order = 58, title = "Warehouse 2 Foundation", category = "WAREHOUSE 2", kind = "cash", bonus = 1.08, cost = 20000, pad = "Warehouse2FoundationBuyPad", models = { "WH2_FoundationModel" }, requires = { "RB2_Sign" }, branch = "warehouse-2", priority = 57, functionalCategory = "BUILD" },
	{ id = "WH2_Supports", zone = "repair", order = 59, title = "Warehouse 2 Supports", category = "WAREHOUSE 2", kind = "cash", bonus = 1.08, cost = 22000, pad = "Warehouse2SupportsBuyPad", models = { "WH2_SupportsModel" }, requires = { "WH2_Foundation" }, branch = "warehouse-2", priority = 58, functionalCategory = "BUILD" },
	{ id = "WH2_Canopy", zone = "repair", order = 60, title = "Warehouse 2 Canopy", category = "WAREHOUSE 2", kind = "cash", bonus = 1.08, cost = 24000, pad = "Warehouse2CanopyBuyPad", models = { "WH2_CanopyModel" }, requires = { "WH2_Supports" }, branch = "warehouse-2", priority = 59, functionalCategory = "BUILD" },
	{ id = "WH2_Row1", zone = "repair", order = 61, title = "Warehouse 2 Row 1", category = "WAREHOUSE 2", kind = "cash", bonus = 1.12, cost = 26000, pad = "Warehouse2Row1BuyPad", models = { "WH2_Row1Model" }, requires = { "WH2_Canopy" }, branch = "warehouse-2", priority = 60, functionalCategory = "INCOME" },
	{ id = "WH2_Row2", zone = "repair", order = 62, title = "Warehouse 2 Row 2", category = "WAREHOUSE 2", kind = "cash", bonus = 1.12, cost = 28000, pad = "Warehouse2Row2BuyPad", models = { "WH2_Row2Model" }, requires = { "WH2_Row1" }, branch = "warehouse-2", priority = 61, functionalCategory = "INCOME" },
	{ id = "WH2_Row3", zone = "repair", order = 63, title = "Warehouse 2 Row 3", category = "WAREHOUSE 2", kind = "cash", bonus = 1.12, cost = 30000, pad = "Warehouse2Row3BuyPad", models = { "WH2_Row3Model" }, requires = { "WH2_Row2" }, branch = "warehouse-2", priority = 62, functionalCategory = "INCOME" },
	{ id = "WH2_Row4", zone = "repair", order = 64, title = "Warehouse 2 Row 4", category = "WAREHOUSE 2", kind = "cash", bonus = 1.12, cost = 32000, pad = "Warehouse2Row4BuyPad", models = { "WH2_Row4Model" }, requires = { "WH2_Row3" }, branch = "warehouse-2", priority = 63, functionalCategory = "INCOME" },
	{ id = "WH2_Lights", zone = "repair", order = 65, title = "Warehouse 2 Lights", category = "WAREHOUSE 2", kind = "speed", bonus = 1.12, cost = 35000, pad = "Warehouse2LightsBuyPad", models = { "WH2_LightsModel" }, requires = { "WH2_Row4" }, branch = "warehouse-2", priority = 64, functionalCategory = "SPEED" },

	-- Car Wash starts as soon as its Brush Machine is installed; walls are optional.
	{ id = "CW_Foundation", zone = "wash", order = 66, title = "Car Wash Foundation", category = "CAR WASH", kind = "structure", bonus = 1, cost = 3500, pad = "CarWashFoundationBuyPad", models = { "CarWash_ConcreteBase", "ServicePads", "CarWash_ParkingApproachBase" }, requires = { "CO_CheckoutAutomation" }, branch = "car-wash", priority = 66, functionalCategory = "BUILD" },
	{ id = "CW_EntryRamp", zone = "wash", order = 67, title = "Entry Ramp", category = "CAR WASH", kind = "structure", bonus = 1, cost = 1000, pad = "EntryRampBuyPad", models = { "EntryRamp" }, requires = { "CW_Foundation" }, branch = "car-wash", priority = 67, functionalCategory = "BUILD" },
	{ id = "CW_ExitRamp", zone = "wash", order = 68, title = "Exit Ramp", category = "CAR WASH", kind = "structure", bonus = 1, cost = 1500, pad = "ExitRampBuyPad", models = { "ExitRamp", "CarWash_ExitWay1", "CarWash_ExitWayAll" }, requires = { "CW_EntryRamp" }, branch = "car-wash", priority = 68, functionalCategory = "BUILD" },
	{ id = "CW_BrushMachine", zone = "wash", order = 69, title = "Brush Machine", category = "CAR WASH", kind = "cash", bonus = 1, cost = 8000, pad = "BrushMachineBuyPad", models = { "BrushMachine" }, requires = { "CW_ExitRamp" }, branch = "car-wash", priority = 69, functionalCategory = "EQUIPMENT" },
	{ id = "CW_LeftSide", zone = "wash", order = 70, title = "Left Side", category = "CAR WASH", kind = "structure", bonus = 1, cost = 700, pad = "LeftSideBuyPad", models = { "LeftSide" }, requires = { "CW_BrushMachine" }, branch = "car-wash", priority = 70, functionalCategory = "BUILD" },
	{ id = "CW_RightSide", zone = "wash", order = 71, title = "Right Side", category = "CAR WASH", kind = "structure", bonus = 1, cost = 700, pad = "RightSideBuyPad", models = { "RightSide" }, requires = { "CW_LeftSide" }, branch = "car-wash", priority = 71, functionalCategory = "BUILD" },
	{ id = "CW_FrontEntranceFrame", zone = "wash", order = 72, title = "Front Entrance Frame", category = "CAR WASH", kind = "structure", bonus = 1, cost = 700, pad = "FrontEntranceFrameBuyPad", models = { "FrontEntranceFrame" }, requires = { "CW_RightSide" }, branch = "car-wash", priority = 72, functionalCategory = "BUILD" },
	{ id = "CW_BackExitFrame", zone = "wash", order = 73, title = "Back Exit Frame", category = "CAR WASH", kind = "structure", bonus = 1, cost = 700, pad = "BackExitFrameBuyPad", models = { "BackExitFrame" }, requires = { "CW_FrontEntranceFrame" }, branch = "car-wash", priority = 73, functionalCategory = "BUILD" },
	{ id = "CW_SideDoor", zone = "wash", order = 74, title = "Side Door", category = "CAR WASH", kind = "structure", bonus = 1, cost = 400, pad = "SideDoorBuyPad", models = { "PersonnelDoor" }, requires = { "CW_BackExitFrame" }, branch = "car-wash", priority = 74, functionalCategory = "BUILD" },
	{ id = "CW_Ceiling", zone = "wash", order = 75, title = "Ceiling + Lights", category = "CAR WASH", kind = "structure", bonus = 1, cost = 800, pad = "CeilingBuyPad", models = { "CarWash_FlatRoof", "CarWash_RoofRimFront", "CarWash_RoofRimBack", "CarWash_RoofRimLeft", "CarWash_RoofRimRight", "CarWash_FrontBlueAccent", "CeilingLightBlocks", "TopSigns" }, requires = { "CW_WaterTank" }, branch = "car-wash", priority = 75, functionalCategory = "BUILD" },
	{ id = "CW_FanDryer", zone = "wash", order = 76, title = "Fan Dryer", category = "CAR WASH", kind = "cash", bonus = 1.2, cost = 5500, pad = "FanDryerBuyPad", models = { "DryerFan" }, requires = { "CW_Ceiling" }, branch = "car-wash", priority = 76, functionalCategory = "INCOME" },
	{ id = "CW_PolishStation", zone = "wash", order = 77, title = "Polish Station", category = "CAR WASH", kind = "cash", bonus = 1.25, cost = 6500, pad = "PolishStationBuyPad", models = { "PolishStation" }, requires = { "CW_FanDryer" }, branch = "car-wash", priority = 77, functionalCategory = "INCOME" },
	{ id = "CW_WaterTank", zone = "wash", order = 78, title = "Water Tank", category = "CAR WASH", kind = "cash", bonus = 1.3, cost = 8000, pad = "WaterTankBuyPad", models = { "WaterTank" }, requires = { "CW_SideDoor" }, branch = "car-wash", priority = 78, functionalCategory = "INCOME" },

	-- The attached second lane unlocks only after the first wash is fully upgraded. Its
	-- construction prices are exactly 1.5x lane one, while its cash upgrades affect wash2 only.
	{ id = "CW2_Foundation", zone = "wash2", order = 80, title = "Car Wash 2 Foundation", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 9000, pad = "CarWash2FoundationBuyPad", models = { "CarWash2_ConcreteBase", "CarWash2_ServicePads" }, requires = { "CW_PolishStation" }, branch = "car-wash-2", priority = 80, functionalCategory = "CAPACITY" },
	{ id = "CW2_EntryRamp", zone = "wash2", order = 81, title = "Entry Ramp", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2500, pad = "CarWash2EntryRampBuyPad", models = { "CarWash2_EntryRamp" }, requires = { "CW2_Foundation" }, branch = "car-wash-2", priority = 81, functionalCategory = "BUILD" },
	{ id = "CW2_ExitRamp", zone = "wash2", order = 82, title = "Exit Ramp", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 3500, pad = "CarWash2ExitRampBuyPad", models = { "CarWash2_ExitRampModel", "CarWash_ExitWay2" }, requires = { "CW2_EntryRamp" }, branch = "car-wash-2", priority = 82, functionalCategory = "BUILD" },
	{ id = "CW2_BrushMachine", zone = "wash2", order = 83, title = "Brush Machine", category = "CAR WASH 2", kind = "cash", bonus = 1, cost = 20000, pad = "CarWash2BrushMachineBuyPad", models = { "CarWash2_BrushMachine" }, requires = { "CW2_ExitRamp" }, branch = "car-wash-2", priority = 83, functionalCategory = "EQUIPMENT" },
	{ id = "CW2_LeftSide", zone = "wash2", order = 84, title = "Left Side", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2000, pad = "CarWash2LeftSideBuyPad", models = { "CarWash2_LeftSide" }, requires = { "CW2_BrushMachine" }, branch = "car-wash-2", priority = 84, functionalCategory = "BUILD" },
	{ id = "CW2_RightSide", zone = "wash2", order = 85, title = "Right Side", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2000, pad = "CarWash2RightSideBuyPad", models = { "CarWash2_RightSide" }, requires = { "CW2_LeftSide" }, branch = "car-wash-2", priority = 85, functionalCategory = "BUILD" },
	{ id = "CW2_FrontEntranceFrame", zone = "wash2", order = 86, title = "Front Entrance Frame", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2000, pad = "CarWash2FrontEntranceFrameBuyPad", models = { "CarWash2_FrontEntranceFrame" }, requires = { "CW2_RightSide" }, branch = "car-wash-2", priority = 86, functionalCategory = "BUILD" },
	{ id = "CW2_BackExitFrame", zone = "wash2", order = 87, title = "Back Exit Frame", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2500, pad = "CarWash2BackExitFrameBuyPad", models = { "CarWash2_BackExitFrame" }, requires = { "CW2_FrontEntranceFrame" }, branch = "car-wash-2", priority = 87, functionalCategory = "BUILD" },
	{ id = "CW2_SideDoor", zone = "wash2", order = 88, title = "Side Door", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 1000, pad = "CarWash2SideDoorBuyPad", models = { "CarWash2_PersonnelDoor" }, requires = { "CW2_BackExitFrame" }, branch = "car-wash-2", priority = 88, functionalCategory = "BUILD" },
	{ id = "CW2_Ceiling", zone = "wash2", order = 89, title = "Ceiling + Lights", category = "CAR WASH 2", kind = "structure", bonus = 1, cost = 2500, pad = "CarWash2CeilingBuyPad", models = { "CarWash2_FlatRoof", "CarWash2_RoofRimFront", "CarWash2_RoofRimBack", "CarWash2_RoofRimLeft", "CarWash2_RoofRimRight", "CarWash2_FrontBlueAccent", "CarWash2_CeilingLightBlocks", "CarWash2_TopSigns" }, requires = { "CW2_WaterTank" }, branch = "car-wash-2", priority = 89, functionalCategory = "BUILD" },
	{ id = "CW2_FanDryer", zone = "wash2", order = 90, title = "Fan Dryer", category = "CAR WASH 2", kind = "cash", bonus = 1.2, cost = 15000, pad = "CarWash2FanDryerBuyPad", models = { "CarWash2_DryerFan" }, requires = { "CW2_Ceiling" }, branch = "car-wash-2", priority = 90, functionalCategory = "INCOME" },
	{ id = "CW2_PolishStation", zone = "wash2", order = 91, title = "Polish Station", category = "CAR WASH 2", kind = "cash", bonus = 1.25, cost = 18000, pad = "CarWash2PolishStationBuyPad", models = { "CarWash2_PolishStation" }, requires = { "CW2_FanDryer" }, branch = "car-wash-2", priority = 91, functionalCategory = "INCOME" },
	{ id = "CW2_WaterTank", zone = "wash2", order = 92, title = "Water Tank", category = "CAR WASH 2", kind = "cash", bonus = 1.3, cost = 20000, pad = "CarWash2WaterTankBuyPad", models = { "CarWash2_WaterTank" }, requires = { "CW2_SideDoor" }, branch = "car-wash-2", priority = 92, functionalCategory = "INCOME" },
	-- Tuning Atelier: $73.2m complete build. The three service cores branch after the
	-- structural shell so every installed bay can run manually before its specialist is hired.
	{ id = "TA_Foundation", zone = "tuningDyno", order = 100, title = "Tuning Atelier Foundation", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 6000, pad = "ConcreteFoundationBuyPad", models = { "ConcreteBase", "ServiceFloors", "ParkingBase" }, requires = { "CW2_WaterTank" }, branch = "tuning-shell", priority = 100, functionalCategory = "BUILD" },
	{ id = "TA_Approach", zone = "tuningDyno", order = 101, title = "Approach Ramp", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 2000, pad = "ApproachRampBuyPad", models = { "ApproachRamp" }, requires = { "TA_Foundation" }, branch = "tuning-shell", priority = 101, functionalCategory = "BUILD" },
	{ id = "TA_FrontArches", zone = "tuningDyno", order = 102, title = "Front Arches", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 3000, pad = "FrontArchesBuyPad", models = { "FrontArches", "Signs" }, requires = { "TA_Approach" }, branch = "tuning-shell", priority = 102, functionalCategory = "BUILD" },
	{ id = "TA_LeftWall", zone = "tuningDyno", order = 103, title = "Left Wall", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 2500, pad = "LeftWallBuyPad", models = { "LeftWall" }, requires = { "TA_FrontArches" }, branch = "tuning-shell", priority = 103, functionalCategory = "BUILD" },
	{ id = "TA_RightWall", zone = "tuningDyno", order = 104, title = "Right Wall", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 2500, pad = "RightWallBuyPad", models = { "RightWall" }, requires = { "TA_LeftWall" }, branch = "tuning-shell", priority = 104, functionalCategory = "BUILD" },
	{ id = "TA_BackWall", zone = "tuningDyno", order = 105, title = "Back Wall", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 3000, pad = "BackWallBuyPad", models = { "BackWall" }, requires = { "TA_RightWall" }, branch = "tuning-shell", priority = 105, functionalCategory = "BUILD" },
	{ id = "TA_Ceiling", zone = "tuningDyno", order = 106, title = "Atelier Ceiling", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 3000, pad = "CeilingBuyPad", models = { "FlatRoofHeavy", "RoofFrontLip", "RoofBackLip", "RoofLeftLip", "RoofRightLip", "RoofBackLip_AccessSplit" }, requires = { "TA_BackWall" }, branch = "tuning-shell", priority = 106, functionalCategory = "BUILD" },
	{ id = "TA_Lights", zone = "tuningDyno", order = 107, title = "Atelier Lights", category = "TUNING ATELIER", kind = "structure", bonus = 1, cost = 1500, pad = "AtelierLightsBuyPad", models = { "CeilingLights" }, requires = { "TA_Ceiling" }, branch = "tuning-shell", priority = 107, functionalCategory = "BUILD" },

	{ id = "TA_Door1", zone = "tuningDyno", order = 108, title = "Dyno Bay Door", category = "DYNO BAY", kind = "structure", bonus = 1, cost = 1500, pad = "GarageDoor1BuyPad", models = { "GarageDoor1" }, requires = { "TA_Lights" }, branch = "tuning-dyno", priority = 108, functionalCategory = "BUILD" },
	{ id = "TA_DynoRollers", zone = "tuningDyno", order = 109, title = "Dyno Rollers", category = "DYNO BAY", kind = "structure", bonus = 1, cost = 40000, pad = "TestDynoRollersBuyPad", models = { "DynoStand" }, requires = { "TA_Door1" }, branch = "tuning-dyno", priority = 109, functionalCategory = "EQUIPMENT" },
	{ id = "TA_DynoSpecialist", zone = "tuningDyno", order = 110, title = "Dyno Specialist", category = "DYNO BAY", kind = "npc", bonus = 1, cost = 25000, pad = "TuningSpecialistNPCBuyPad", models = { "DynoSpecialistNPC" }, requires = { "TA_DynoRollers" }, branch = "tuning-dyno", priority = 110, functionalCategory = "AUTOMATION" },
	{ id = "TA_ChipLaptop", zone = "tuningDyno", order = 111, title = "Chip Tuning Laptop", category = "DYNO BAY", kind = "speed", bonus = 1.2, cost = 30000, pad = "ChipTuningLaptopBuyPad", models = { "ChipTuningLaptopStation" }, requires = { "TA_DynoSpecialist" }, branch = "tuning-dyno", priority = 111, functionalCategory = "SPEED" },
	{ id = "TA_NOS", zone = "tuningDyno", order = 112, title = "NOS Station", category = "DYNO BAY", kind = "cash", bonus = 2.0, cost = 35000, pad = "NOSStationBuyPad", models = { "NOSStation" }, requires = { "TA_ChipLaptop" }, branch = "tuning-dyno", priority = 112, functionalCategory = "INCOME" },

	{ id = "TA_Door2", zone = "tuningBody", order = 113, title = "Body Bay Door", category = "BODY BAY", kind = "structure", bonus = 1, cost = 10000, pad = "GarageDoor2BuyPad", models = { "GarageDoor2" }, requires = { "TA_NOS" }, branch = "tuning-body", priority = 113, functionalCategory = "BUILD" },
	{ id = "TA_BodyKitStation", zone = "tuningBody", order = 114, title = "Body Kit Station", category = "BODY BAY", kind = "structure", bonus = 1, cost = 35000, pad = "WheelAlignmentStationBuyPad", models = { "BodyKitStation" }, requires = { "TA_Door2" }, branch = "tuning-body", priority = 114, functionalCategory = "EQUIPMENT" },
	{ id = "TA_BodySpecialist", zone = "tuningBody", order = 115, title = "Body Specialist", category = "BODY BAY", kind = "npc", bonus = 1, cost = 35000, pad = "BodySpecialistBuyPad", models = { "BodySpecialistNPC" }, requires = { "TA_BodyKitStation" }, branch = "tuning-body", priority = 115, functionalCategory = "AUTOMATION" },
	{ id = "TA_Workbench", zone = "tuningBody", order = 116, title = "Tuning Workbench", category = "BODY BAY", kind = "speed", bonus = 1.2, cost = 35000, pad = "TuningWorkbenchBuyPad", models = { "TuningWorkbench" }, requires = { "TA_BodySpecialist" }, branch = "tuning-body", priority = 116, functionalCategory = "SPEED" },
	{ id = "TA_BodyKitDisplay", zone = "tuningBody", order = 117, title = "Body Kit Display", category = "BODY BAY", kind = "cash", bonus = 1.5, cost = 45000, pad = "BodyKitDisplayBuyPad", models = { "BodyKitDisplay", "ExhaustRack" }, requires = { "TA_Workbench" }, branch = "tuning-body", priority = 117, functionalCategory = "INCOME" },
	{ id = "TA_Neon", zone = "tuningBody", order = 118, title = "Neon Light Strips", category = "BODY BAY", kind = "cash", bonus = 1.25, cost = 4000, pad = "NeonLightStripsBuyPad", models = { "NeonDisplay" }, requires = { "TA_PaintCanisters" }, branch = "tuning-body", priority = 118, functionalCategory = "INCOME" },
	{ id = "TA_ToolChest", zone = "tuningBody", order = 119, title = "Tool Chest", category = "BODY BAY", kind = "speed", bonus = 1.15, cost = 4000, pad = "ToolChestBuyPad", models = { "ToolChest" }, requires = { "TA_Neon" }, branch = "tuning-body", priority = 119, functionalCategory = "SPEED" },

	{ id = "TA_Door3", zone = "tuningPaint", order = 120, title = "Paint Bay Door", category = "PAINT BAY", kind = "structure", bonus = 1, cost = 8000, pad = "GarageDoor3BuyPad", models = { "GarageDoor3" }, requires = { "TA_BodyKitDisplay" }, branch = "tuning-paint", priority = 120, functionalCategory = "BUILD" },
	{ id = "TA_PaintFoundation", zone = "tuningPaint", order = 121, title = "Paint Booth Foundation", category = "PAINT BAY", kind = "structure", bonus = 1, cost = 10000, pad = "PaintBoothFoundationBuyPad", models = { "Foundation" }, requires = { "TA_Door3" }, branch = "tuning-paint", priority = 121, functionalCategory = "BUILD" },
	{ id = "TA_PaintWalls", zone = "tuningPaint", order = 122, title = "Paint Booth Walls", category = "PAINT BAY", kind = "structure", bonus = 1, cost = 10000, pad = "PaintBoothWallsBuyPad", models = { "Walls" }, requires = { "TA_PaintFoundation" }, branch = "tuning-paint", priority = 122, functionalCategory = "BUILD" },
	{ id = "TA_PaintCeiling", zone = "tuningPaint", order = 123, title = "Paint Booth Ceiling", category = "PAINT BAY", kind = "structure", bonus = 1, cost = 12000, pad = "PaintBoothCeilingBuyPad", models = { "Ceiling" }, requires = { "TA_PaintWalls" }, branch = "tuning-paint", priority = 123, functionalCategory = "BUILD" },
	{ id = "TA_PaintControl", zone = "tuningPaint", order = 124, title = "Paint Booth Control", category = "PAINT BAY", kind = "structure", bonus = 1, cost = 15000, pad = "PaintBoothControlPanelBuyPad", models = { "ControlPanel" }, requires = { "TA_PaintCeiling" }, branch = "tuning-paint", priority = 124, functionalCategory = "EQUIPMENT" },
	{ id = "TA_PaintSpecialist", zone = "tuningPaint", order = 125, title = "Paint Specialist", category = "PAINT BAY", kind = "npc", bonus = 1, cost = 40000, pad = "PaintSpecialistBuyPad", models = { "PaintSpecialistNPC" }, requires = { "TA_PaintControl" }, branch = "tuning-paint", priority = 125, functionalCategory = "AUTOMATION" },
	{ id = "TA_PaintCanisters", zone = "tuningPaint", order = 126, title = "Paint Canisters", category = "PAINT BAY", kind = "cash", bonus = 1.8, cost = 50000, pad = "PaintCanistersBuyPad", models = { "PaintCanisters" }, requires = { "TA_PaintSpecialist" }, branch = "tuning-paint", priority = 126, functionalCategory = "INCOME" },
	{ id = "TA_WarehouseRack1", zone = "tuningPaint", order = 138, title = "Warehouse Rack 1", category = "ATELIER WAREHOUSE", kind = "cash", bonus = 1.25, bonusZones = { "tuningDyno", "tuningBody", "tuningPaint" }, cost = 55000, pad = "WarehouseRack1BuyPad", models = { "WarehouseRack1" }, requires = { "TA_Ceiling" }, branch = "tuning-warehouse", priority = 138, functionalCategory = "INCOME" },
	{ id = "TA_WarehouseRack2", zone = "tuningPaint", order = 139, title = "Warehouse Rack 2", category = "ATELIER WAREHOUSE", kind = "cash", bonus = 1.3, bonusZones = { "tuningDyno", "tuningBody", "tuningPaint" }, cost = 75000, pad = "WarehouseRack2BuyPad", models = { "WarehouseRack2" }, requires = { "TA_WarehouseRack1" }, branch = "tuning-warehouse", priority = 139, functionalCategory = "INCOME" },
	{ id = "TA_Compressor", zone = "tuningPaint", order = 127, title = "Modern Compressor", category = "PAINT BAY", kind = "speed", bonus = 1.2, cost = 3000, pad = "ModernCompressorBuyPad", models = { "ModernCompressor" }, requires = { "TA_AdminFurniture" }, branch = "tuning-paint", priority = 127, functionalCategory = "SPEED" },

	{ id = "TA_SideDoor", zone = "tuningDyno", order = 128, title = "Personnel Door", category = "ATELIER EXTRAS", kind = "structure", bonus = 1, cost = 3000, pad = "SideDoorBuyPad", models = { "WorkingSideDoor" }, requires = { "TA_WheelRack" }, branch = "tuning-extras", priority = 128, functionalCategory = "BUILD" },
	{ id = "TA_WheelRack", zone = "tuningBody", order = 129, title = "Wheel Rack", category = "ATELIER EXTRAS", kind = "structure", bonus = 1, cost = 4000, pad = "WheelRackBuyPad", models = { "WheelRack" }, requires = { "TA_ToolChest" }, branch = "tuning-extras", priority = 129, functionalCategory = "BUILD" },
	{ id = "TA_Staircase", zone = "tuningDyno", order = 130, title = "Roof Staircase", category = "ATELIER EXTRAS", kind = "structure", bonus = 1, cost = 4000, pad = "StaircaseBuyPad", models = { "RoofStaircase" }, requires = { "TA_SideDoor" }, branch = "tuning-extras", priority = 130, functionalCategory = "BUILD" },
	{ id = "TA_RoofVents", zone = "tuningDyno", order = 131, title = "Roof Vents", category = "ATELIER EXTRAS", kind = "structure", bonus = 1, cost = 3000, pad = "RoofVentsBuyPad", models = { "RoofVents" }, requires = { "TA_Staircase" }, branch = "tuning-extras", priority = 131, functionalCategory = "BUILD" },
	{ id = "TA_ACUnit", zone = "tuningDyno", order = 132, title = "AC Unit", category = "ATELIER EXTRAS", kind = "structure", bonus = 1, cost = 3000, pad = "ACUnitBuyPad", models = { "ACUnit" }, requires = { "TA_RoofVents" }, branch = "tuning-extras", priority = 132, functionalCategory = "BUILD" },

	{ id = "TA_AdminFoundation", zone = "tuningDyno", order = 133, title = "Admin Foundation", category = "ATELIER ADMIN", kind = "structure", bonus = 1, cost = 4000, pad = "AdminFoundationBuyPad", models = { "AdminFoundation" }, requires = { "TA_BodyKitStation" }, branch = "tuning-admin", priority = 133, functionalCategory = "BUILD" },
	{ id = "TA_AdminWalls", zone = "tuningDyno", order = 134, title = "Admin Walls + Roof", category = "ATELIER ADMIN", kind = "structure", bonus = 1, cost = 4000, pad = "AdminWallsBuyPad", models = { "AdminLeftWall", "AdminRightWall", "AdminBackWall", "AdminRoof", "AdminLeftAccent", "AdminRightAccent", "AdminBackAccent", "PassageFrameLeft", "PassageFrameRight", "PassageFrameTop", "AdminOperationsSign" }, requires = { "TA_AdminFoundation" }, branch = "tuning-admin", priority = 134, functionalCategory = "BUILD" },
	{ id = "TA_AdminFurniture", zone = "tuningDyno", order = 135, title = "Admin Furniture", category = "ATELIER ADMIN", kind = "structure", bonus = 1, cost = 4000, pad = "AdminFurnitureBuyPad", models = { "ServiceAdvisorWorkArea", "OperationsManagerWorkArea", "ReceptionCounter", "ReceptionCounterAccent", "AdminCeilingLight_64", "AdminCeilingLight_79", "AdminCeilingLight_94" }, requires = { "TA_AdminWalls" }, branch = "tuning-admin", priority = 135, functionalCategory = "BUILD" },
	{ id = "TA_ServiceAdvisor", zone = "tuningDyno", order = 136, title = "Service Advisor", category = "ATELIER ADMIN", kind = "npc", bonus = 1, cost = 3000000, pad = "ServiceAdvisorBuyPad", models = { "ServiceAdvisorNPC" }, requires = { "TA_AdminFurniture" }, branch = "tuning-admin", priority = 136, effectText = "+20% ATELIER SERVICE SPEED" },
	{ id = "TA_OperationsManager", zone = "tuningDyno", order = 137, title = "Operations Manager", category = "ATELIER ADMIN", kind = "npc", bonus = 1, cost = 4000000, pad = "OperationsManagerBuyPad", models = { "OperationsManagerNPC" }, requires = { "TA_ServiceAdvisor" }, branch = "tuning-admin", priority = 137, effectText = "+25% ATELIER INCOME" },
	-- Optional checkout automation: manual checkout remains available as soon as the desk is built.
	{ id = "CO_CheckoutAutomation", zone = "repair", order = 79, title = "Hire Checkout Clerk", category = "ADMIN BLOCK", kind = "npc", bonus = 1, cost = 8000, pad = "CheckoutAutomationBuyPad", models = { "CheckoutClerkNPC" }, requires = { "CO_RearExitLight" }, branch = "admin-automation", priority = 79, effectText = "+25% REPAIR/TOW INCOME +20% SERVICE SPEED", functionalCategory = "AUTOMATION" },
} :: { PadDefinition }

-- Purchase pads must answer "what changes if I buy this?" before money is spent.
-- Most rows can derive truthful copy from their economic kind, while effectText remains
-- available for unlocks whose value cannot be expressed by the generic multiplier.
local PAD_EFFECT_LABELS: { [string]: string } = {
	cash = "CASH EARNINGS",
	speed = "SERVICE SPEED",
	repair = "REPAIR SPEED",
	value = "SALE VALUE",
}

function TycoonConfig.padEffectText(definition: PadDefinition): string
	if definition.effectText ~= nil and definition.effectText ~= "" then
		return definition.effectText
	end

	local percent = math.max(0, math.floor((definition.bonus - 1) * 100 + 0.5))
	local title = string.upper(definition.title)
	local lowerTitle = string.lower(definition.title)

	-- Capacity is sometimes authored as a structure (a lift) rather than a listing pad.
	if definition.kind == "listing" or string.find(lowerTitle, "parking space", 1, true) ~= nil then
		return "+1 ACTIVE CAR SLOT"
	elseif string.find(lowerTitle, "car lift", 1, true) ~= nil then
		return "+1 SERVICE BAY"
	end
	local effect = PAD_EFFECT_LABELS[definition.kind]
	if effect then
		return if percent > 0 then `+{percent}% {effect}` else `INCREASES {effect}`
	end
	if definition.kind == "npc" then
		return `HIRES {title}`
	elseif definition.kind == "structure" then
		for _, candidate in TycoonConfig.PADS do
			if candidate.requires ~= nil and table.find(candidate.requires, definition.id) ~= nil then
				return "UNLOCKS NEXT: " .. string.upper(candidate.title)
			end
		end
		return "COMPLETES " .. title .. " CONSTRUCTION"
	end
	return title
end

-- Towing is a second Repair Bay ledger, not a new upgrade tree. Share every Repair pad with
-- its stage capsule; only cash-kind pads affect the payout because cashMultiplier filters it.
for _, definition in TycoonConfig.PADS do
	if definition.zone == "repair" then
		definition.bonusZones = definition.bonusZones or {}
		if table.find(definition.bonusZones, "tow") == nil then
			table.insert(definition.bonusZones, "tow")
		end
	end
end

-- Chapter progression keeps authored construction steps when each purchase has a visible
-- result and a useful economic effect. Bundles remain only where several pieces form one
-- indivisible purchase; Repair Bay ramps, shell and equipment are bought one step at a time.
TycoonConfig.CHAPTERS = {
	{ id = 1, title = "FIRST FLIP", completionPad = nil },
	{ id = 2, title = "AUTOMATION", completionPad = "SecondMechanic" },
	{ id = 3, title = "REPAIR BAY", completionPad = "CO_CheckoutAutomation" },
	{ id = 4, title = "CAR WASH", completionPad = "CW_PolishStation" },
	{ id = 5, title = "SECOND WASH LANE", completionPad = "CW2_WaterTank" },
	{ id = 6, title = "TUNING ATELIER", completionPad = "TA_Compressor" },
}

TycoonConfig.BUNDLES = {
	-- Compatibility-only entitlement: OpenRepairBay owns the visible foundation while the
	-- empty legacy RB_Foundation id remains readable in old saves. No visible construction
	-- stage in Repair Bay, Car Wash or Tuning Atelier is bundled.
	OpenRepairBay = { "RB_Foundation" },
} :: { [string]: { string } }

local MERGED_INTO: { [string]: string } = {}
for leaderId, members in TycoonConfig.BUNDLES do
	for _, memberId in members do
		MERGED_INTO[memberId] = leaderId
	end
end
-- These systems remain readable in old saves, but are not offered in the retention MVP.
MERGED_INTO.UsedCarsSalesman = "FirstSalesman"
-- Parking2..Parking6 are real purchasable stock spaces again. Their authored geometry,
-- sequential requirements and saved ownership are already handled by the generic pad path.
MERGED_INTO.ParkingLightRightFront = "post-tutorial-capacity"
MERGED_INTO.ParkingLightLeftRear = "post-tutorial-capacity"
MERGED_INTO.ParkingLightRightRear = "post-tutorial-capacity"
-- Repair Bay 2 and both Tuning Atelier administrators are live optional expansions,
-- not post-MVP compatibility aliases. Their authored pads/models remain independently owned.

local CHAPTER_BY_ZONE: { [string]: number } = {
	usedcars = 2,
	repair = 3,
	wash = 4,
	wash2 = 5,
	tuningDyno = 6,
	tuningBody = 6,
	tuningPaint = 6,
}

local function defaultChapterForZone(zone: string): number
	return CHAPTER_BY_ZONE[zone] or 2
end

for _, definition in TycoonConfig.PADS do
	definition.chapter = definition.chapter or defaultChapterForZone(definition.zone)
	definition.chapterOrder = definition.chapterOrder or definition.priority or definition.order
	definition.functionalCategory = definition.functionalCategory or definition.kind
	definition.mergedInto = MERGED_INTO[definition.id]
end
-- The first-flip chapter contains the free equipment, Cash Register and the tutorial
-- Salesman. EDITOR_STAGE_ORDER below is the final authority for chapter placement.
local firstPad = TycoonConfig.PADS[1]
firstPad.chapter = 1
firstPad.chapterOrder = 1
TycoonConfig.PADS[4].chapter = 1
TycoonConfig.PADS[4].chapterOrder = 2

-- Editorial order imported from purchase-pads-active-all.csv. Requirements still define
-- availability; this rank controls deterministic guidance among currently unlocked pads.
local EDITOR_STAGE_ORDER = {
	[1] = { "RepairPad", "FirstWorkbench", "CashRegister", "FirstSalesman" },
	[2] = { "RepairPad2", "Parking2", "SecondMechanic", "CarJack", "AirCompressor", "FirstMechanic", "TireMount", "WheelBalancer", "SalesSign", "Parking3", "Parking4", "Parking5", "Parking6", "ScrapBin", "RightFloodlight", "StorageShed", "StorageShelf", "LeftFence", "RightFence", "BackFence" },
	[3] = { "OpenRepairBay", "RB_ApproachRamp", "RB_ServiceRamp", "RB_CarLift", "ServiceHelper", "RB_MechanicNPC", "RB_BackWall", "RB_SideWall1", "RB_SideWall2", "RB_FrontWall", "RB_Ceiling", "RB_Lights", "RB_GarageDoor", "RB_ToolCabinet", "RB_PartsRack", "RB_ModernAirCompressor", "RB_TireStack", "RB_TowTruckDropOff", "RB_TowTruck", "RB_TowTruckDriver", "RB_RepairBaySign", "CO_Walls1", "CO_Walls2", "CO_Walls3", "CO_Ceiling", "CO_Lighting", "CO_ComputerDesk", "CO_Chair", "CO_StorageCrates", "CO_RearExitLight", "CO_CheckoutAutomation", "WH1_Foundation", "WH1_Supports", "WH1_Canopy", "WH1_Row1", "WH1_Row2", "WH1_Row3", "WH1_Row4", "WH1_Lights", "RB2_Foundation", "RB2_ApproachRamp", "RB2_ServiceArea", "RB2_CarLift", "RB2_MechanicNPC", "RB2_BackWall", "RB2_SideWall", "RB2_FrontFrame", "RB2_Ceiling", "RB2_Lights", "RB2_GarageDoor", "RB2_PartsShelf", "RB2_Compressor", "RB2_Sign", "WH2_Foundation", "WH2_Supports", "WH2_Canopy", "WH2_Row1", "WH2_Row2", "WH2_Row3", "WH2_Row4", "WH2_Lights" },
	[4] = { "CW_Foundation", "CW_EntryRamp", "CW_ExitRamp", "CW_BrushMachine", "CW_LeftSide", "CW_RightSide", "CW_FrontEntranceFrame", "CW_BackExitFrame", "CW_SideDoor", "CW_WaterTank", "CW_Ceiling", "CW_FanDryer", "CW_PolishStation" },
	[5] = { "CW2_Foundation", "CW2_EntryRamp", "CW2_ExitRamp", "CW2_BrushMachine", "CW2_LeftSide", "CW2_RightSide", "CW2_FrontEntranceFrame", "CW2_BackExitFrame", "CW2_SideDoor", "CW2_WaterTank", "CW2_Ceiling", "CW2_FanDryer", "CW2_PolishStation" },
	[6] = { "TA_Foundation", "TA_Approach", "TA_FrontArches", "TA_LeftWall", "TA_RightWall", "TA_BackWall", "TA_Ceiling", "TA_Lights", "TA_Door1", "TA_DynoRollers", "TA_DynoSpecialist", "TA_ChipLaptop", "TA_NOS", "TA_Door2", "TA_BodyKitStation", "TA_AdminFoundation", "TA_AdminWalls", "TA_AdminFurniture", "TA_ServiceAdvisor", "TA_OperationsManager", "TA_BodySpecialist", "TA_Workbench", "TA_BodyKitDisplay", "TA_Door3", "TA_PaintFoundation", "TA_PaintWalls", "TA_Compressor", "TA_PaintCeiling", "TA_PaintControl", "TA_PaintSpecialist", "TA_PaintCanisters", "TA_Neon", "TA_ToolChest", "TA_WheelRack", "TA_SideDoor", "TA_Staircase", "TA_RoofVents", "TA_ACUnit", "TA_WarehouseRack1", "TA_WarehouseRack2" },
}
local definitionById = {}
for _, definition in TycoonConfig.PADS do
	definitionById[definition.id] = definition
end
for chapter, ids in EDITOR_STAGE_ORDER do
	for order, id in ids do
		local definition = definitionById[id]
		if definition ~= nil then
			definition.chapter = chapter
			definition.chapterOrder = order
		end
	end
end
for offset, id in { "ServiceHelper2", "ServiceHelper3" } do
	local definition = definitionById[id]
	if definition ~= nil then
		definition.chapter = 3
		definition.chapterOrder = 5 + offset * 0.1
	end
end

-- Content visibility gate. Optional Junk Spot storage and Repair Bay expansion stay
-- purchasable in parallel; only unfinished/no-model or intentionally retired pads remain hidden.
TycoonConfig.MVP_ALLOWED_PADS = {
	RepairPad = true,
	RepairPad2 = true,
	SecondMechanic = true,
	FirstWorkbench = true,
	CashRegister = true,
	CarJack = true,
	FirstMechanic = true,
	FirstSalesman = true,
	ServiceHelper = true,
	ServiceHelper2 = true,
	ServiceHelper3 = true,
	-- Junk Spot income and storage branches stay available beside later businesses.
	AirCompressor = true,
	TireMount = true,
	WheelBalancer = true,
	SalesSign = true,
	ScrapBin = true,
	StorageShed = true,
	StorageShelf = true,
	LeftFence = true,
	RightFence = true,
	BackFence = true,
	RightFloodlight = true,

	OpenRepairBay = true,
	RB_Foundation = true,
	RB_ApproachRamp = true,
	RB_ServiceRamp = true,
	RB_CarLift = true,
	RB2_Foundation = true,
	RB2_ApproachRamp = true,
	RB2_ServiceArea = true,
	RB2_CarLift = true,
	RB2_MechanicNPC = true,
	RB2_BackWall = true,
	RB2_SideWall = true,
	RB2_FrontFrame = true,
	RB2_Ceiling = true,
	RB2_Lights = true,
	RB2_GarageDoor = true,
	RB2_PartsShelf = true,
	RB2_Compressor = true,
	RB2_Sign = true,
	WH1_Foundation = true,
	WH1_Supports = true,
	WH1_Canopy = true,
	WH1_Row1 = true,
	WH1_Row2 = true,
	WH1_Row3 = true,
	WH1_Row4 = true,
	WH1_Lights = true,
	WH2_Foundation = true,
	WH2_Supports = true,
	WH2_Canopy = true,
	WH2_Row1 = true,
	WH2_Row2 = true,
	WH2_Row3 = true,
	WH2_Row4 = true,
	WH2_Lights = true,
	-- Everything through the bay sign: once the lift is running there has to be something
	-- left to build with the money it makes.
	RB_MechanicNPC = true,
	RB_BackWall = true,
	RB_SideWall1 = true,
	RB_SideWall2 = true,
	RB_FrontWall = true,
	RB_Ceiling = true,
	RB_Lights = true,
	RB_GarageDoor = true,
	RB_ToolCabinet = true,
	RB_PartsRack = true,
	RB_ModernAirCompressor = true,
	RB_TireStack = true,
	RB_TowTruckDropOff = true,
	RB_TowTruck = true,
	RB_TowTruckDriver = true,
	RB_RepairBaySign = true,
	CO_Walls1 = true,
	CO_Walls2 = true,
	CO_Walls3 = true,
	CO_Ceiling = true,
	CO_Lighting = true,
	CO_ComputerDesk = true,
	CO_Chair = true,
	CO_StorageCrates = true,
	CO_RearExitLight = true,
	CO_CheckoutAutomation = true,
	Parking2 = true,
	UsedCarsSalesman = true,
	Parking3 = true,
	Parking4 = true,
	Parking5 = true,
	Parking6 = true,
	ParkingLightRightFront = true,
	ParkingLightLeftRear = true,
	 ParkingLightRightRear = true,
	CW_Foundation = true,
	CW_EntryRamp = true,
	CW_ExitRamp = true,
	CW_BrushMachine = true,
	CW_LeftSide = true,
	CW_RightSide = true,
	CW_FrontEntranceFrame = true,
	CW_BackExitFrame = true,
	CW_SideDoor = true,
	CW_Ceiling = true,
	CW_FanDryer = true,
	CW_PolishStation = true,
	CW_WaterTank = true,
	CW2_Foundation = true,
	CW2_EntryRamp = true,
	CW2_ExitRamp = true,
	CW2_BrushMachine = true,
	CW2_LeftSide = true,
	CW2_RightSide = true,
	CW2_FrontEntranceFrame = true,
	CW2_BackExitFrame = true,
	CW2_SideDoor = true,
	CW2_Ceiling = true,
	CW2_FanDryer = true,
	CW2_PolishStation = true,
	CW2_WaterTank = true,
	TA_Foundation = true,
	TA_Approach = true,
	TA_FrontArches = true,
	TA_LeftWall = true,
	TA_RightWall = true,
	TA_BackWall = true,
	TA_Ceiling = true,
	TA_Lights = true,
	TA_Door1 = true,
	TA_DynoRollers = true,
	TA_DynoSpecialist = true,
	TA_ChipLaptop = true,
	TA_NOS = true,
	TA_Door2 = true,
	TA_BodyKitStation = true,
	TA_BodySpecialist = true,
	TA_Workbench = true,
	TA_BodyKitDisplay = true,
	TA_Neon = true,
	TA_ToolChest = true,
	TA_Door3 = true,
	TA_PaintFoundation = true,
	TA_PaintWalls = true,
	TA_PaintCeiling = true,
	TA_PaintControl = true,
	TA_PaintSpecialist = true,
	TA_PaintCanisters = true,
	TA_WarehouseRack1 = true,
	TA_WarehouseRack2 = true,
	TA_Compressor = true,
	TA_SideDoor = true,
	TA_WheelRack = true,
	TA_Staircase = true,
	TA_RoofVents = true,
	TA_ACUnit = true,
	TA_AdminFoundation = true,
	TA_AdminWalls = true,
	TA_AdminFurniture = true,
	TA_ServiceAdvisor = true,
	TA_OperationsManager = true,
}

function TycoonConfig.isPadEnabled(definition: PadDefinition): boolean
	return TycoonConfig.MVP_ALLOWED_PADS[definition.id] == true and definition.mergedInto == nil
end

function TycoonConfig.getPad(id: string): PadDefinition?
	for _, pad in TycoonConfig.PADS do
		if pad.id == id then
			return pad
		end
	end
	return nil
end

function TycoonConfig.getPadByOrder(order: number): PadDefinition?
	for _, pad in TycoonConfig.PADS do
		if pad.order == order then
			return pad
		end
	end
	return nil
end

function TycoonConfig.bundleMembers(id: string): { string }
	return TycoonConfig.BUNDLES[id] or {}
end

function TycoonConfig.chapterForPad(id: string): number
	local definition = TycoonConfig.getPad(id)
	return if definition ~= nil then (definition.chapter or defaultChapterForZone(definition.zone)) else 1
end

function TycoonConfig.deriveChapter(purchasedPads: { [string]: boolean }, tutorialComplete: boolean): number
	-- Never send a returning player backwards: later-business ownership wins over old or
	-- missing tutorial fields.
	for _, definition in TycoonConfig.PADS do
		if purchasedPads[definition.id] == true
			and (definition.zone == "tuningDyno" or definition.zone == "tuningBody" or definition.zone == "tuningPaint")
		then
			return 6
		end
	end
	if purchasedPads.CW2_WaterTank == true then
		return 6
	elseif purchasedPads.CW_PolishStation == true then
		return 5
	elseif purchasedPads.CO_CheckoutAutomation == true then
		return 4
	elseif tutorialComplete and purchasedPads.SecondMechanic == true then
		return 3
	elseif tutorialComplete then
		return 2
	end
	return 1
end

function TycoonConfig.isPadUnlocked(
	definition: PadDefinition,
	purchasedPads: { [string]: boolean },
	tutorialComplete: boolean?,
	progressionChapter: number?
): boolean
	if not TycoonConfig.isPadEnabled(definition) then
		return false
	end
	-- Checkout Clerk is the hard business gate for both wash lanes. Keeping this check
	-- on every wash definition also handles old saves that already own an early wash pad.
	if (definition.zone == "wash" or definition.zone == "wash2")
		and purchasedPads.CO_CheckoutAutomation ~= true
	then
		return false
	end
	-- The second lane must never overtake the finishing steps of lane one. This explicit
	-- boundary also repairs old saves whose stored chapter advanced after Water Tank.
	if definition.zone == "wash2" and purchasedPads.CW_PolishStation ~= true then
		return false
	end
	-- FirstSalesman is the final paid FTUE action. PadService adds the dynamic condition that
	-- keeps his pad hidden until Rusty's two repairs are complete.
	local tutorialSalesman = tutorialComplete ~= true
		and definition.id == "FirstSalesman"
		and purchasedPads.CashRegister == true
	if tutorialComplete ~= true
		and definition.id ~= "CashRegister"
		and not tutorialSalesman
		and definition.starter ~= true
	then
		return false
	end
	local derived = TycoonConfig.deriveChapter(purchasedPads, tutorialComplete == true)
	local currentChapter = math.max(derived, progressionChapter or 1)
	if currentChapter < (definition.chapter or 1) then
		return false
	end
	if definition.starter == true then
		return true
	end
	if definition.requires ~= nil then
		for _, requiredId in definition.requires do
			if purchasedPads[requiredId] ~= true then
				return false
			end
		end
		return true
	end
	local previous = TycoonConfig.getPadByOrder(definition.order - 1)
	return previous == nil or purchasedPads[previous.id] == true
end

TycoonConfig.AUTO_BUY_MAX_CASH_RATIO = 0.35
TycoonConfig.AUTO_BUY_MAX_RESERVE = 150
TycoonConfig.AUTO_BUY_RESERVE_FRACTION = 0.25

local MANDATORY_PROGRESSION = {
	"CashRegister", "FirstSalesman", "RepairPad2", "Parking2", "SecondMechanic",
	"OpenRepairBay", "RB_ApproachRamp", "RB_ServiceRamp", "RB_CarLift", "RB_MechanicNPC",
	"RB_BackWall", "RB_SideWall1", "RB_SideWall2", "RB_FrontWall", "RB_Ceiling",
	"RB_Lights", "RB_GarageDoor", "RB_ToolCabinet", "RB_PartsRack",
	"RB_ModernAirCompressor", "RB_TireStack", "RB_TowTruckDropOff", "RB_TowTruck", "RB_TowTruckDriver", "RB_RepairBaySign",
	"CO_Walls1", "CO_Walls2", "CO_Walls3", "CO_Ceiling", "CO_Lighting",
	"CO_ComputerDesk", "CO_Chair", "CO_StorageCrates", "CO_RearExitLight", "CO_CheckoutAutomation",
	"CW_Foundation", "CW_EntryRamp", "CW_ExitRamp", "CW_BrushMachine", "CW_LeftSide", "CW_RightSide",
	"CW_FrontEntranceFrame", "CW_BackExitFrame", "CW_SideDoor", "CW_WaterTank",
	"CW_Ceiling", "CW_FanDryer", "CW_PolishStation",
	"CW2_Foundation", "CW2_EntryRamp", "CW2_ExitRamp", "CW2_BrushMachine", "CW2_LeftSide", "CW2_RightSide",
	"CW2_FrontEntranceFrame", "CW2_BackExitFrame", "CW2_SideDoor", "CW2_Ceiling",
	"CW2_FanDryer", "CW2_PolishStation", "CW2_WaterTank",
	"TA_Foundation", "TA_Approach", "TA_FrontArches", "TA_LeftWall", "TA_RightWall", "TA_BackWall",
	"TA_Ceiling", "TA_Lights", "TA_Door1", "TA_DynoRollers", "TA_DynoSpecialist", "TA_ChipLaptop", "TA_NOS",
	"TA_Door2", "TA_BodyKitStation", "TA_BodySpecialist", "TA_Workbench", "TA_BodyKitDisplay",
	"TA_Door3", "TA_PaintFoundation", "TA_PaintWalls", "TA_PaintCeiling", "TA_PaintControl",
	"TA_PaintSpecialist", "TA_PaintCanisters", "TA_Neon", "TA_ToolChest", "TA_WheelRack",
	"TA_SideDoor", "TA_Staircase", "TA_RoofVents", "TA_ACUnit", "TA_WarehouseRack1", "TA_WarehouseRack2", "TA_AdminFoundation",
	"TA_AdminWalls", "TA_AdminFurniture", "TA_Compressor",
}
TycoonConfig.MANDATORY_PROGRESSION = MANDATORY_PROGRESSION

function TycoonConfig.nextMandatoryPad(
	purchasedPads: { [string]: boolean },
	tutorialComplete: boolean,
	progressionChapter: number?
): PadDefinition?
	local currentChapter = math.max(
		TycoonConfig.deriveChapter(purchasedPads, tutorialComplete),
		progressionChapter or 1
	)
	for _, padId in MANDATORY_PROGRESSION do
		local definition = TycoonConfig.getPad(padId)
		if definition ~= nil
			and purchasedPads[padId] ~= true
			and (definition.chapter or 1) <= currentChapter
			and TycoonConfig.isPadUnlocked(definition, purchasedPads, tutorialComplete, currentChapter)
		then
			return definition
		end
	end
	return nil
end

function TycoonConfig.salesmanCashReserve(
	purchasedPads: { [string]: boolean },
	tutorialComplete: boolean,
	progressionChapter: number?
): number
	local currentChapter = math.max(
		TycoonConfig.deriveChapter(purchasedPads, tutorialComplete),
		progressionChapter or 1
	)
	for _, padId in MANDATORY_PROGRESSION do
		local definition = TycoonConfig.getPad(padId)
		if definition ~= nil
			and purchasedPads[padId] ~= true
			and (definition.chapter or 1) == currentChapter
			and TycoonConfig.isPadUnlocked(definition, purchasedPads, tutorialComplete, currentChapter)
		then
			return math.min(
				TycoonConfig.AUTO_BUY_MAX_RESERVE,
				math.max(0, math.floor(definition.cost * TycoonConfig.AUTO_BUY_RESERVE_FRACTION))
			)
		end
	end
	return TycoonConfig.AUTO_BUY_MAX_RESERVE
end

function TycoonConfig.salesmanCanBuy(
	cash: number,
	askingPrice: number,
	purchasedPads: { [string]: boolean },
	tutorialComplete: boolean,
	progressionChapter: number?
): boolean
	if askingPrice <= 0 or askingPrice > cash * TycoonConfig.AUTO_BUY_MAX_CASH_RATIO then
		return false
	end
	return cash - askingPrice >= TycoonConfig.salesmanCashReserve(
		purchasedPads,
		tutorialComplete,
		progressionChapter
	)
end

function TycoonConfig.getZone(id: string): ZoneDefinition?
	for _, zone in TycoonConfig.ZONES do
		if zone.id == id then
			return zone
		end
	end
	return nil
end

function TycoonConfig.getStation(zoneId: string): StationDefinition?
	for _, station in TycoonConfig.STATIONS do
		if station.zone == zoneId then
			return station
		end
	end
	return nil
end

local function bonusAppliesToZone(pad: PadDefinition, zoneId: string?): boolean
	if zoneId == nil or pad.zone == zoneId then
		return true
	end
	return pad.bonusZones ~= nil and table.find(pad.bonusZones, zoneId) ~= nil
end

function TycoonConfig.cashMultiplier(pads: { [string]: boolean }, zoneId: string?): number
	local total = 1
	for _, pad in TycoonConfig.PADS do
		if TycoonConfig.isPadEnabled(pad) and pad.kind == "cash" and pads[pad.id] == true and bonusAppliesToZone(pad, zoneId) then
			total *= pad.bonus
		end
	end
	return total
end

function TycoonConfig.speedMultiplier(pads: { [string]: boolean }, zoneId: string?): number
	local total = 1
	for _, pad in TycoonConfig.PADS do
		if TycoonConfig.isPadEnabled(pad) and (pad.kind == "speed" or pad.kind == "repair") and pads[pad.id] == true and (zoneId == nil or pad.zone == zoneId) then
			total *= pad.bonus
		end
	end
	return total
end

function TycoonConfig.effectiveSpeedMultiplier(pads: { [string]: boolean }, zoneId: string?): number
	local total = TycoonConfig.speedMultiplier(pads, zoneId)
	if (zoneId == "repair" or zoneId == "tow") and pads[TycoonConfig.REPAIR_SERVICE_MANAGER_PAD] == true then
		total *= TycoonConfig.REPAIR_SERVICE_MANAGER_SPEED_MULTIPLIER
	elseif (zoneId == "tuningDyno" or zoneId == "tuningBody" or zoneId == "tuningPaint")
		and pads.TA_ServiceAdvisor == true
	then
		total *= TycoonConfig.TUNING_SERVICE_ADVISOR_SPEED_MULTIPLIER
	end
	return total
end

function TycoonConfig.administrativeIncomeMultiplier(pads: { [string]: boolean }, zoneId: string?): number
	if (zoneId == "repair" or zoneId == "tow") and pads[TycoonConfig.REPAIR_SERVICE_MANAGER_PAD] == true then
		return TycoonConfig.REPAIR_SERVICE_MANAGER_INCOME_MULTIPLIER
	end
	if (zoneId == "tuningDyno" or zoneId == "tuningBody" or zoneId == "tuningPaint")
		and pads.TA_OperationsManager == true
	then
		return TycoonConfig.TUNING_OPERATIONS_MANAGER_MULTIPLIER
	end
	return 1
end

-- Each workshop machine speeds up the job it belongs to rather than every job at once,
-- so the sign on the machine and the hold on the prompt describe the same thing.
TycoonConfig.REPAIR_BOOSTS = {
	Body = { "AirCompressor" },
	Engine = { "CarJack" },
	Wheels = { "TireMount", "WheelBalancer" },
}

TycoonConfig.REPAIR_PART_LABEL = {
	Body = "BODY",
	Engine = "ENGINE",
	Wheels = "WHEEL",
}

function TycoonConfig.repairMultiplierFor(pads: { [string]: boolean }, partId: string): number
	local owners = TycoonConfig.REPAIR_BOOSTS[partId]
	if owners == nil then
		return 1
	end
	local total = 1
	for _, padId in owners do
		if pads[padId] == true then
			local pad = TycoonConfig.getPad(padId)
			if pad ~= nil then
				total *= pad.bonus
			end
		end
	end
	return total
end

-- Which job a machine speeds up, for the sign above it.
function TycoonConfig.repairBoostOf(padId: string): (string?, number)
	for partId, owners in TycoonConfig.REPAIR_BOOSTS do
		for _, id in owners do
			if id == padId then
				local pad = TycoonConfig.getPad(padId)
				return partId, if pad ~= nil then pad.bonus else 1
			end
		end
	end
	return nil, 1
end

function TycoonConfig.repairMultiplier(pads: { [string]: boolean }): number
	local total = 1
	for _, pad in TycoonConfig.PADS do
		if TycoonConfig.isPadEnabled(pad) and pad.kind == "repair" and pads[pad.id] == true then
			total *= pad.bonus
		end
	end
	return total
end

function TycoonConfig.valueMultiplier(pads: { [string]: boolean }): number
	local total = 1
	for _, pad in TycoonConfig.PADS do
		if TycoonConfig.isPadEnabled(pad) and pad.kind == "value" and pads[pad.id] == true then
			total *= pad.bonus
		end
	end
	return total
end

function TycoonConfig.upgradeCost(station: StationDefinition, level: number): number
	return math.floor(station.baseUpgradeCost * station.upgradeGrowth ^ (level - 1))
end

function TycoonConfig.payoutFor(station: StationDefinition, level: number, cashMultiplier: number): number
	local base = station.basePayout + station.payoutPerLevel * (level - 1)
	return math.max(1, math.floor(base * cashMultiplier))
end

function TycoonConfig.fillTimeFor(station: StationDefinition, speedMultiplier: number): number
	return math.max(TycoonConfig.MIN_FILL_TIME, station.fillTime / speedMultiplier)
end

function TycoonConfig.isInstant(station: StationDefinition, speedMultiplier: number): boolean
	return station.fillTime / speedMultiplier <= TycoonConfig.MIN_FILL_TIME
end

return TycoonConfig
