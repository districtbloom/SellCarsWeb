--!strict

local LuckConfig = require(script.Parent.LuckConfig)

export type PartId = "Body" | "Wheels" | "Engine"

export type CarTier = "Basic" | "Premium"
export type CarClass = "low" | "mid" | "high" | "hyper"
export type UnlockRule = "pads" | "fullService"

export type CarTemplate = {
	id: string,
	displayName: string?,
	model: string,
	baseCost: number,
	baseValue: number,
	tier: CarTier,
	class: CarClass,
	rarityOneInN: number,
	requiresPads: { string }?,
	unlockRule: UnlockRule?,
	handling: string?,
	topSpeedKph: number?,
	handlingRating: number?,
	accelerationRating: number?,
	antiTheftCost: number?,
	dealerEligible: boolean?,
	streetEligible: boolean?,
	indexVisible: boolean?,
	spawnWeight: number?,
	unlockHint: string?,
}

export type RarityTier = {
	id: string,
	label: string,
	colour: Color3,
	text: Color3,
	maxOneInN: number,
	offerBonus: number,
}

export type PartDef = {
	id: PartId,
	label: string,
	valueBonus: number,
}

export type TutorialDeal = {
	carId: string,
	beat: "TRANSFORMATION" | "DECISION" | "WILDCARD",
	manualParts: { PartId },
	preRepaired: { [string]: boolean },
	fixedValue: number?,
	fixedOffer: number?,
	repairObjective: string,
	sellObjective: string,
	diagnosis: string?,
	wildcard: boolean?,
}

export type ArrivalPoolEntry = {
	template: CarTemplate,
	templateId: string,
	class: CarClass,
	classWeight: number,
	templateWeight: number,
	weight: number,
	probability: number,
}

export type ArrivalPool = {
	tier: string,
	classWeights: { [string]: number },
	totalWeight: number,
	entries: { ArrivalPoolEntry },
}

export type ArrivalOdds = {
	tier: string,
	class: CarClass?,
	classWeight: number,
	probability: number,
	percent: number,
	oneInN: number,
}

local DealerCarConfig = {}

DealerCarConfig.MAX_WORKING_SLOTS = 2
DealerCarConfig.MAX_DISPLAY_SLOTS = 6

DealerCarConfig.PART_REPAIR_SECONDS = 1.2

-- Selling side: a buyer messages the phone after the car has been listed for a bit.
DealerCarConfig.OFFER_DELAY_MIN = 10
DealerCarConfig.OFFER_DELAY_MAX = 18
-- Back-compat alias used nowhere new; keep a mid value for any leftover callers.
DealerCarConfig.OFFER_DELAY = 14
DealerCarConfig.ASK_MORE_BONUS = 0.12
DealerCarConfig.OFFER_MIN_RATIO = 0.85
DealerCarConfig.OFFER_MAX_RATIO = 1.05

-- Buying side: a seller drives a junk car onto the lot and haggles in person.
DealerCarConfig.ASK_MIN_RATIO = 0.9
DealerCarConfig.ASK_MAX_RATIO = 1.25
DealerCarConfig.BUY_HAGGLE_DISCOUNT = 0.12
DealerCarConfig.BUY_HAGGLE_CHANCE = 0.65
-- Soft-cap early junk AFK before the bay lift: wider seller gaps + pickier auto-buy
-- target ~$150-250/min post-Salesman so the Repair Bay reads as a real income jump.
DealerCarConfig.SELLER_GAP_MIN = 7
DealerCarConfig.SELLER_GAP_MAX = 14
DealerCarConfig.SELLER_PATIENCE = 60
DealerCarConfig.SELLER_LEAVE_DELAY = 1
-- Cars rest on the pad by their own wheels, so this is only the gap under them.
DealerCarConfig.PARK_CLEARANCE = 0.05
DealerCarConfig.SELLER_SIDE_OFFSET = 5
DealerCarConfig.SELLER_PROMPT_NAME = "SellerDealPrompt"
DealerCarConfig.SELLER_MODEL_NAME = "JunkSeller"
-- He leaves on foot: a handful of steps off the lot and he is gone.
DealerCarConfig.SELLER_WALK_STEPS_MIN = 5
DealerCarConfig.SELLER_WALK_STEPS_MAX = 7
DealerCarConfig.SELLER_STEP_LENGTH = 2.6
DealerCarConfig.SELLER_FADE_TIME = 0.5

DealerCarConfig.RESPAWN_DELAY = 1.25
-- Cars enter and leave along the road graph, matching the ambient traffic lane.
DealerCarConfig.ROAD_LANE_OFFSET = 11
DealerCarConfig.ROAD_HEIGHT = 1.55
DealerCarConfig.ROAD_SPACING = 6
DealerCarConfig.ROAD_STEPS = 4
DealerCarConfig.ARRIVE_SPEED = 45
DealerCarConfig.DEPART_SPEED = 48
DealerCarConfig.WALK_SPEED = 7
-- Turning: how fast a vehicle may swing its nose, and how far the front wheels follow.
DealerCarConfig.TURN_RATE = 4
DealerCarConfig.STEER_GAIN = 0.55
DealerCarConfig.STEER_LIMIT = 0.5
DealerCarConfig.STEER_SMOOTH = 7
-- The turn between road and pad is a curve, not a diagonal across the centre line.
DealerCarConfig.APPROACH_SEGMENTS = 14
DealerCarConfig.APPROACH_BULGE = 0.45
-- Junk Spot automation roles are deliberately split. The junk-lot salesman only
-- transports Ready working cars to Used Cars; the Used Cars worker accepts buyer offers.
DealerCarConfig.AUTO_REPAIR_PADS = {
	[1] = "FirstMechanic",
	[2] = "SecondMechanic",
} :: { [number]: string }
-- Rolling compatibility: legacy systems address the original W1 mechanic through this alias.
DealerCarConfig.AUTO_REPAIR_PAD = DealerCarConfig.AUTO_REPAIR_PADS[1]
-- This is a transport role, separate from the W-lane mechanics and the listing salesman.
-- It unlocks beside the Junk Spot only after the first Repair Bay lift is functional.
DealerCarConfig.SERVICE_HELPER_PAD = "ServiceHelper"

function DealerCarConfig.autoRepairPad(workingIndex: number?): string?
	local resolved = workingIndex or 1
	if resolved ~= math.floor(resolved) then
		return nil
	end
	return DealerCarConfig.AUTO_REPAIR_PADS[resolved]
end

DealerCarConfig.AUTO_LIST_PAD = "FirstSalesman"
-- Retention MVP: the first salesman owns the whole simple loop (seller, listing and buyer).
-- The separate forecourt employee remains save-compatible but is not a required purchase.
DealerCarConfig.AUTO_ACCEPT_PAD = "FirstSalesman"
-- Rolling compatibility: old callers may still ask whether listing is automated.
DealerCarConfig.AUTO_SELL_PAD = DealerCarConfig.AUTO_LIST_PAD
DealerCarConfig.AUTO_REPAIR_SECONDS = 3
DealerCarConfig.AUTO_LIST_DELAY = 1.25
DealerCarConfig.AUTO_ACCEPT_DELAY = 3.5
DealerCarConfig.AUTO_BUY_DELAY = 3.5
-- The salesman turns down anything priced above this share of the car's junk value.
DealerCarConfig.AUTO_BUY_MAX_RATIO = 0.32
-- Safety net only; automation reacts to state changes rather than polling.
DealerCarConfig.AUTOMATION_INTERVAL = 7

-- Deals unlock the phone once the trade desk is built. After that, sourcing MIXES:
-- sometimes a seller still drives onto the lot, sometimes a fence texts a list.
-- Never both for the same deal - one channel per incoming car.
DealerCarConfig.PHONE_TRADE_PAD = "CashRegister"
-- Chance the next sourcing deal is phone fence once Cash Register is owned (else live).
DealerCarConfig.PHONE_DEAL_CHANCE = 0.25
DealerCarConfig.FENCE_OFFER_COUNT = 3
DealerCarConfig.FENCE_REFRESH_DELAY = 10
DealerCarConfig.FOLDER_NAME = "DealerCars"
DealerCarConfig.LIST_PROMPT_NAME = "ListForSalePrompt"
DealerCarConfig.REPAIR_PROMPT_NAME = "RepairPartPrompt"

-- Staff: how the mechanic and the salesman behave once their pads are bought.
DealerCarConfig.STAFF_WALK_SPEED = 11
DealerCarConfig.STAFF_WORK_OFFSET = 4.5
DealerCarConfig.STAFF_CHEER_TIME = 2.5 -- seconds

DealerCarConfig.PARTS = {
	{ id = "Body", label = "Body", valueBonus = 40 },
	{ id = "Wheels", label = "Wheels", valueBonus = 35 },
	{ id = "Engine", label = "Engine", valueBonus = 55 },
} :: { PartDef }

local PART_IDS = {}
for _, part in DealerCarConfig.PARTS do
	table.insert(PART_IDS, part.id)
end

-- FTUE is one complete flip. Rusty's body is already sound; the player restores the engine
-- first and then replaces the missing front-left wheel. The fixed sale funds the sequential
-- post-tutorial Car Jack and Air Compressor; later flips fund the First Mechanic.
DealerCarConfig.TUTORIAL_DEALS = {
	[1] = {
		carId = "Rusty",
		beat = "TRANSFORMATION",
		manualParts = { "Engine", "Wheels" },
		preRepaired = { Body = true },
		fixedValue = 1000,
		fixedOffer = 1000,
		repairObjective = "RESTORE RUSTY",
		sellObjective = "SELL RUSTY",
		diagnosis = "ENGINE IS DEAD · FRONT-LEFT WHEEL IS MISSING",
	},
} :: { [number]: TutorialDeal }
DealerCarConfig.TUTORIAL_DEAL_COUNT = #DealerCarConfig.TUTORIAL_DEALS

function DealerCarConfig.tutorialDeal(dealIndex: number): TutorialDeal?
	local source = DealerCarConfig.TUTORIAL_DEALS[math.floor(dealIndex)]
	if source == nil then
		return nil
	end
	local deal = table.clone(source)
	deal.manualParts = table.clone(source.manualParts)
	deal.preRepaired = table.clone(source.preRepaired)
	return deal
end

function DealerCarConfig.tutorialParts(dealIndex: number): { [string]: boolean }
	local parts: { [string]: boolean } = {}
	for _, definition in DealerCarConfig.PARTS do
		parts[definition.id] = false
	end
	local deal = DealerCarConfig.tutorialDeal(dealIndex)
	if deal ~= nil then
		for partId, repaired in deal.preRepaired do
			if repaired == true then
				parts[partId] = true
			end
		end
	end
	return parts
end

function DealerCarConfig.tutorialManualProgress(
	dealIndex: number,
	parts: { [string]: boolean }
): (number, number)
	local deal = DealerCarConfig.tutorialDeal(dealIndex)
	local manualParts = if deal ~= nil then deal.manualParts else PART_IDS
	local current = 0
	for _, partId in manualParts do
		if parts[partId] == true then
			current += 1
		end
	end
	return current, #manualParts
end

function DealerCarConfig.nextRepairPart(
	dealIndex: number,
	parts: { [string]: boolean }
): string?
	local deal = DealerCarConfig.tutorialDeal(dealIndex)
	if deal ~= nil then
		for _, partId in deal.manualParts do
			if parts[partId] ~= true then
				return partId
			end
		end
	end
	for _, definition in DealerCarConfig.PARTS do
		if parts[definition.id] ~= true then
			return definition.id
		end
	end
	return nil
end

function DealerCarConfig.partValue(partId: string): number
	for _, definition in DealerCarConfig.PARTS do
		if definition.id == partId then
			return definition.valueBonus
		end
	end
	return 0
end

function DealerCarConfig.manualRepairValue(dealIndex: number, parts: { [string]: boolean }): number
	local deal = DealerCarConfig.tutorialDeal(dealIndex)
	local manualParts = if deal ~= nil then deal.manualParts else PART_IDS
	local value = 0
	for _, partId in manualParts do
		if parts[partId] == true then
			value += DealerCarConfig.partValue(partId)
		end
	end
	return value
end

DealerCarConfig.FULL_SERVICE_PADS = {
	"RB_CarLift",
	"RB2_CarLift",
	"CW_BrushMachine",
	"CW2_BrushMachine",
	"TA_DynoRollers",
	"TA_BodyKitStation",
	"TA_PaintControl",
} :: { string }

DealerCarConfig.PAD_ALIASES = {
	OpenRepairBay = { "RB_Foundation" },
} :: { [string]: { string } }

-- Incoming supply is weighted by the strongest functional service tier the tycoon owns.
-- Every row totals 100 so product tuning and telemetry can read these as exact percentages.
DealerCarConfig.ARRIVAL_CLASS_WEIGHTS = {
	starter = { low = 100, mid = 0, high = 0, hyper = 0 },
	repair = { low = 70, mid = 30, high = 0, hyper = 0 },
	wash = { low = 45, mid = 55, high = 0, hyper = 0 },
	tuning = { low = 20, mid = 45, high = 35, hyper = 0 },
	fullTuning = { low = 10, mid = 35, high = 55, hyper = 0 },
	fullService = { low = 10, mid = 34.5, high = 55, hyper = 0.5 },
} :: { [string]: { [string]: number } }

DealerCarConfig.FULL_TUNING_PADS = {
	"TA_DynoRollers",
	"TA_BodyKitStation",
	"TA_PaintControl",
} :: { string }

DealerCarConfig.CARS = {
	{ id = "Gblock", displayName = "G-Block", model = "Gblock", baseCost = 4800, baseValue = 10500, tier = "Premium", class = "high", rarityOneInN = 85, requiresPads = { "CW_BrushMachine" }, topSpeedKph = 250, handlingRating = 7.6, accelerationRating = 8.0, handling = "Luxury AWD SUV. Strong acceleration, deliberate cornering.", antiTheftCost = 3500, spawnWeight = 1, dealerEligible = true, streetEligible = true, indexVisible = true, unlockHint = "Car Wash: Brush Machine" },
	-- Low-class junk is available from the first flip.
	{ id = "Rusty", model = "RustyCar", baseCost = 25, baseValue = 90, tier = "Basic", class = "low", rarityOneInN = 2, topSpeedKph = 105, handlingRating = 3.2, accelerationRating = 2.4, handling = "Slow, loose, and honest. Fine for the first flips.", antiTheftCost = 40 },
	{ id = "Wronkler", model = "Wronkler", baseCost = 35, baseValue = 130, tier = "Basic", class = "low", rarityOneInN = 6, topSpeedKph = 115, handlingRating = 2.8, accelerationRating = 2.7, handling = "Crooked and stubborn. Needs a firm hand in corners.", antiTheftCost = 55 },
	{ id = "ChevroluxC10", displayName = "Chevrolux C10", model = "ChevroluxC10", baseCost = 80, baseValue = 220, tier = "Basic", class = "low", rarityOneInN = 12, requiresPads = { "Parking2" }, topSpeedKph = 125, handlingRating = 3.5, accelerationRating = 2.6, handling = "Heavy pickup. Straight-line stable, slow to turn.", antiTheftCost = 120, unlockHint = "Parking Space 2" },
	{ id = "RadoBoxlet", displayName = "Rado Boxlet", model = "RadoBoxlet", baseCost = 75, baseValue = 215, tier = "Basic", class = "low", rarityOneInN = 10, requiresPads = { "RepairPad2" }, topSpeedKph = 130, handlingRating = 4.8, accelerationRating = 4.0, handling = "Light compact box. Quick in town, nervous at speed.", antiTheftCost = 110, unlockHint = "Repair Pad 2" },
	-- Mid-class unlocks with Repair Bay foundation, first lift, then second bay.
	{ id = "Nissho", displayName = "Nissho Slide SX", model = "NisshoSlideSX", baseCost = 250, baseValue = 600, tier = "Premium", class = "mid", rarityOneInN = 20, requiresPads = { "OpenRepairBay" }, topSpeedKph = 185, handlingRating = 7.0, accelerationRating = 6.6, handling = "Born to slide. Loose rear, sharp throttle.", antiTheftCost = 420, unlockHint = "Repair Bay" },
	{ id = "Bavora", displayName = "Bavora B3", model = "Bavora", baseCost = 650, baseValue = 1400, tier = "Premium", class = "mid", rarityOneInN = 25, requiresPads = { "RB_CarLift" }, topSpeedKph = 190, handlingRating = 7.5, accelerationRating = 6.0, handling = "Premium sedan. Planted, expensive to upset.", antiTheftCost = 780, unlockHint = "Repair Bay lift" },
	{ id = "HondoCivixEK", displayName = "Hondo Civix EK", model = "HondoCivixEK", baseCost = 500, baseValue = 1100, tier = "Premium", class = "mid", rarityOneInN = 23, requiresPads = { "RB2_Foundation" }, topSpeedKph = 180, handlingRating = 7.8, accelerationRating = 7.1, handling = "Light shell, eager engine. Loves clean revs.", antiTheftCost = 640, unlockHint = "Repair Bay 2" },
	-- High-class: one car per Tuning stand. Hyper is full-service only.
	{ id = "FierroRossa", displayName = "Fierro Rossa", model = "FierroRossa", baseCost = 4200, baseValue = 9800, tier = "Premium", class = "high", rarityOneInN = 80, requiresPads = { "TA_DynoRollers" }, topSpeedKph = 285, handlingRating = 8.8, accelerationRating = 9.0, handling = "Italian mid-engine bite. Fast in, faster out.", antiTheftCost = 3200, unlockHint = "Dyno" },
	{ id = "Porschka911", displayName = "Porschka 911", model = "Porschka911", baseCost = 5100, baseValue = 11200, tier = "Premium", class = "high", rarityOneInN = 90, requiresPads = { "TA_BodyKitStation" }, topSpeedKph = 275, handlingRating = 8.4, accelerationRating = 8.7, handling = "Rear-engine snap. Rewards commitment, punishes hesitation.", antiTheftCost = 3800, unlockHint = "Body stand" },
	{ id = "Mercurion190r", displayName = "Mercurion 190R", model = "Mercurion190r", baseCost = 3900, baseValue = 8600, tier = "Premium", class = "mid", rarityOneInN = 70, requiresPads = { "TA_PaintControl" }, topSpeedKph = 205, handlingRating = 7.7, accelerationRating = 6.8, handling = "Tight chassis, calm at speed. A driver's saloon.", antiTheftCost = 2900, unlockHint = "Paint stand" },
	{ id = "ZentauriR", displayName = "Zentauri R", model = "ZentauriR", baseCost = 24000, baseValue = 52000, tier = "Premium", class = "hyper", rarityOneInN = 200, unlockRule = "fullService", dealerEligible = true, spawnWeight = 1, topSpeedKph = 360, handlingRating = 9.4, accelerationRating = 10.0, handling = "Hypercar. Brutal acceleration, no second chances.", antiTheftCost = 25000, unlockHint = "Full service" },
} :: { CarTemplate }

-- Spoken once when a mechanic takes responsibility for an exact car. Each template has its
-- own small pool so repeat visits feel authored without delaying the repair workflow.
DealerCarConfig.MECHANIC_START_LINES = {
	Rusty = {
		"This old Rusty has seen better decades. Give me a minute and a lot of patience.",
		"Rust everywhere, but the bones are still here. I can bring this one back.",
	},
	Wronkler = {
		"A Wronkler always fights the wrench. Good thing I fight harder.",
		"Crooked panels and stubborn bolts — classic Wronkler. I'll sort it out.",
	},
	ChevroluxC10 = {
		"Nice C10. The body is honest steel, and this engine still wants to work.",
		"Chevrolux pickup — heavy, simple, fixable. This one will clean up well.",
	},
	RadoBoxlet = {
		"Little Rado, big personality. These compact boxes are tougher than they look.",
		"A Boxlet is easy to underestimate. Let me tighten it up and it'll sell fast.",
	},
	Nissho = {
		"This Nissho was born to slide, not to smoke at idle. I'll calm it down.",
		"Good chassis on this Nissho. Once the rough bits are gone, it'll move quickly.",
	},
	HondoCivixEK = {
		"An EK with potential. Keep the revs clean and buyers will line up.",
		"Hondo Civix — light shell, eager engine. This one deserves a careful repair.",
	},
	Bavora = {
		"Bavora parts are fussy, but the finished car pays for the extra care.",
		"Premium machine, premium headaches. Don't worry — I've worked on worse.",
	},
	FierroRossa = {
		"A Rossa does not forgive sloppy work. I'll treat it like it costs a house.",
		"Italian electrics, Italian attitude. Give me room and I'll make it sing.",
	},
	Porschka911 = {
		"Rear engine, rear drama. Once it's tight, buyers will fight over it.",
		"A 911 wants precision. I'll give it that.",
	},
	Mercurion190r = {
		"Old-school Mercurion. Heavy doors, honest steel, worth the hours.",
		"This 190R will feel expensive again when I'm done.",
	},
	ZentauriR = {
		"Hypercar on my lift. Nobody rush me.",
		"If I scratch this Zentauri, we both leave town.",
	},
} :: { [string]: { string } }

function DealerCarConfig.mechanicRemark(templateId: string): string
	local lines = DealerCarConfig.MECHANIC_START_LINES[templateId]
	if lines == nil or #lines == 0 then
		return "Let's see what this one needs. I'll have it ready for the lot."
	end
	return lines[math.random(1, #lines)]
end

DealerCarConfig.RARITY_TIERS = {
	{ id = "common", label = "COMMON", colour = Color3.fromRGB(122, 128, 138), text = Color3.fromRGB(240, 243, 248), maxOneInN = 4, offerBonus = 0 },
	{ id = "uncommon", label = "UNCOMMON", colour = Color3.fromRGB(72, 158, 96), text = Color3.fromRGB(238, 255, 242), maxOneInN = 14, offerBonus = 0.03 },
	{ id = "rare", label = "RARE", colour = Color3.fromRGB(58, 128, 208), text = Color3.fromRGB(238, 248, 255), maxOneInN = 49, offerBonus = 0.08 },
	{ id = "epic", label = "EPIC", colour = Color3.fromRGB(146, 92, 206), text = Color3.fromRGB(248, 240, 255), maxOneInN = 149, offerBonus = 0.15 },
	{ id = "legendary", label = "LEGENDARY", colour = Color3.fromRGB(214, 164, 52), text = Color3.fromRGB(255, 250, 232), maxOneInN = math.huge, offerBonus = 0.25 },
} :: { RarityTier }

function DealerCarConfig.displayName(templateId: string): string
	for _, template in DealerCarConfig.CARS do
		if template.id == templateId then
			return template.displayName or template.id
		end
	end
	return templateId
end

function DealerCarConfig.rarityTier(oneInN: number): RarityTier
	for _, tier in DealerCarConfig.RARITY_TIERS do
		if oneInN <= tier.maxOneInN then
			return tier
		end
	end
	return DealerCarConfig.RARITY_TIERS[#DealerCarConfig.RARITY_TIERS]
end

function DealerCarConfig.rarityOf(templateId: string): (number, RarityTier)
	for _, template in DealerCarConfig.CARS do
		if template.id == templateId then
			local oneInN = template.rarityOneInN or 1
			return oneInN, DealerCarConfig.rarityTier(oneInN)
		end
	end
	return 1, DealerCarConfig.RARITY_TIERS[1]
end

function DealerCarConfig.hasPad(pads: { [string]: boolean }?, padId: string): boolean
	if pads == nil then
		return false
	end
	if pads[padId] == true then
		return true
	end
	local aliases = DealerCarConfig.PAD_ALIASES[padId]
	if aliases ~= nil then
		for _, alias in aliases do
			if pads[alias] == true then
				return true
			end
		end
	end
	return false
end

function DealerCarConfig.isFullServiceOpen(pads: { [string]: boolean }?): boolean
	for _, padId in DealerCarConfig.FULL_SERVICE_PADS do
		if not DealerCarConfig.hasPad(pads, padId) then
			return false
		end
	end
	return true
end

function DealerCarConfig.isCarUnlocked(template: CarTemplate, pads: { [string]: boolean }?): boolean
	if template.unlockRule == "fullService" then
		return DealerCarConfig.isFullServiceOpen(pads)
	end
	local requiredPads = template.requiresPads
	if requiredPads == nil then
		return true
	end
	if pads == nil then
		return false
	end
	for _, padId in requiredPads do
		if not DealerCarConfig.hasPad(pads, padId) then
			return false
		end
	end
	return true
end

function DealerCarConfig.isDealerEligible(template: CarTemplate): boolean
	return template.dealerEligible ~= false
end

function DealerCarConfig.isStreetEligible(template: CarTemplate): boolean
	return template.streetEligible ~= false
end

function DealerCarConfig.isIndexVisible(template: CarTemplate): boolean
	return template.indexVisible ~= false
end

function DealerCarConfig.templateById(templateId: string): CarTemplate?
	for _, template in DealerCarConfig.CARS do
		if template.id == templateId then
			return template
		end
	end
	return nil
end

function DealerCarConfig.templateByModel(modelName: string): CarTemplate?
	for _, template in DealerCarConfig.CARS do
		if template.model == modelName or template.id == modelName then
			return template
		end
	end
	return nil
end

function DealerCarConfig.isStreetModelUnlocked(modelName: string, pads: { [string]: boolean }?): boolean
	local template = DealerCarConfig.templateByModel(modelName)
	if template == nil then
		return false
	end
	return DealerCarConfig.isStreetEligible(template) and DealerCarConfig.isCarUnlocked(template, pads)
end

function DealerCarConfig.unlockHint(template: CarTemplate): string
	if template.unlockHint ~= nil and template.unlockHint ~= "" then
		return template.unlockHint
	end
	if template.unlockRule == "fullService" then
		return "Full service"
	end
	local requiredPads = template.requiresPads
	if requiredPads ~= nil and #requiredPads > 0 then
		return requiredPads[1]
	end
	return "Start"
end

function DealerCarConfig.catalogCars(): { CarTemplate }
	local catalog: { CarTemplate } = {}
	local authoredOrder: { [string]: number } = {}
	for index, template in DealerCarConfig.CARS do
		authoredOrder[template.id] = index
	end
	for _, template in DealerCarConfig.CARS do
		if DealerCarConfig.isIndexVisible(template) then
			table.insert(catalog, template)
		end
	end
	local classOrder: { [string]: number } = { low = 1, mid = 2, high = 3, hyper = 4 }
	table.sort(catalog, function(a: CarTemplate, b: CarTemplate): boolean
		local aClass = classOrder[a.class] or math.huge
		local bClass = classOrder[b.class] or math.huge
		if aClass ~= bClass then
			return aClass < bClass
		end
		return (authoredOrder[a.id] or math.huge) < (authoredOrder[b.id] or math.huge)
	end)
	return catalog
end

function DealerCarConfig.unlockedIds(pads: { [string]: boolean }?): { string }
	local ids: { string } = {}
	for _, template in DealerCarConfig.catalogCars() do
		if DealerCarConfig.isCarUnlocked(template, pads) then
			table.insert(ids, template.id)
		end
	end
	return ids
end

function DealerCarConfig.eligibleCars(pads: { [string]: boolean }?): { CarTemplate }
	local eligible: { CarTemplate } = {}
	for _, template in DealerCarConfig.CARS do
		if DealerCarConfig.isDealerEligible(template) and DealerCarConfig.isCarUnlocked(template, pads) then
			table.insert(eligible, template)
		end
	end
	return eligible
end

local function ownsEveryPad(pads: { [string]: boolean }?, required: { string }): boolean
	for _, padId in required do
		if not DealerCarConfig.hasPad(pads, padId) then
			return false
		end
	end
	return true
end

function DealerCarConfig.arrivalTier(pads: { [string]: boolean }?): string
	if DealerCarConfig.isFullServiceOpen(pads) then
		return "fullService"
	end
	if ownsEveryPad(pads, DealerCarConfig.FULL_TUNING_PADS) then
		return "fullTuning"
	end
	if DealerCarConfig.hasPad(pads, "TA_DynoRollers")
		or DealerCarConfig.hasPad(pads, "TA_BodyKitStation")
		or DealerCarConfig.hasPad(pads, "TA_PaintControl")
	then
		return "tuning"
	end
	-- A Car Wash begins changing supply only when the functional brush stage is online.
	if DealerCarConfig.hasPad(pads, "CW_BrushMachine") then
		return "wash"
	end
	if DealerCarConfig.hasPad(pads, "OpenRepairBay") then
		return "repair"
	end
	return "starter"
end

-- Builds one authoritative, inspectable probability table. Class weights control the broad
-- quality mix; spawnWeight only divides that class share between currently unlocked models.
function DealerCarConfig.arrivalPool(pads: { [string]: boolean }?, luckValue: number?): ArrivalPool
	local tier = DealerCarConfig.arrivalTier(pads)
	local sourceWeights = DealerCarConfig.ARRIVAL_CLASS_WEIGHTS[tier]
	assert(sourceWeights ~= nil, `Missing arrival weights for tier {tier}`)
	local classWeights = table.clone(sourceWeights)
	for classId, weight in classWeights do
		classWeights[classId] = weight * LuckConfig.arrivalClassMultiplier(classId, luckValue)
	end
	local buckets: { [string]: { CarTemplate } } = {
		low = {},
		mid = {},
		high = {},
		hyper = {},
	}
	for _, template in DealerCarConfig.eligibleCars(pads) do
		if (classWeights[template.class] or 0) > 0 then
			table.insert(buckets[template.class], template)
		end
	end

	local entries: { ArrivalPoolEntry } = {}
	local totalWeight = 0
	for _, classId in { "low", "mid", "high", "hyper" } do
		local templates = buckets[classId]
		local classWeight = classWeights[classId] or 0
		if classWeight > 0 and #templates > 0 then
			local templateWeightTotal = 0
			for _, template in templates do
				templateWeightTotal += math.max(0, template.spawnWeight or 1)
			end
			if templateWeightTotal <= 0 then
				templateWeightTotal = #templates
			end
			for _, template in templates do
				local templateWeight = math.max(0, template.spawnWeight or 1)
				if templateWeightTotal == #templates and templateWeight <= 0 then
					templateWeight = 1
				end
				local weight = classWeight * (templateWeight / templateWeightTotal)
				totalWeight += weight
				table.insert(entries, {
					template = template,
					templateId = template.id,
					class = template.class,
					classWeight = classWeight,
					templateWeight = templateWeight,
					weight = weight,
					probability = 0,
				})
			end
		end
	end
	assert(totalWeight > 0 and #entries > 0, `DealerCarConfig has no arrival templates for tier {tier}`)
	for _, entry in entries do
		entry.probability = entry.weight / totalWeight
	end
	return {
		tier = tier,
		classWeights = classWeights,
		totalWeight = totalWeight,
		entries = entries,
	}
end

function DealerCarConfig.arrivalOdds(templateId: string, pads: { [string]: boolean }?, luckValue: number?): ArrivalOdds
	local pool = DealerCarConfig.arrivalPool(pads, luckValue)
	for _, entry in pool.entries do
		if entry.templateId == templateId then
			return {
				tier = pool.tier,
				class = entry.class,
				classWeight = entry.classWeight,
				probability = entry.probability,
				percent = entry.probability * 100,
				oneInN = 1 / entry.probability,
			}
		end
	end
	local template = DealerCarConfig.templateById(templateId)
	return {
		tier = pool.tier,
		class = if template ~= nil then template.class else nil,
		classWeight = 0,
		probability = 0,
		percent = 0,
		oneInN = math.huge,
	}
end

function DealerCarConfig.formatArrivalPercent(probability: number): string
	local percent = math.max(0, probability) * 100
	if math.abs(percent - math.floor(percent + 0.5)) < 0.001 then
		return `{math.floor(percent + 0.5)}%`
	elseif percent >= 1 then
		return string.format("%.1f%%", percent)
	end
	return string.format("%.2f%%", percent)
end

function DealerCarConfig.selectArrival(
	pads: { [string]: boolean }?,
	luckOrRandom: any?,
	randomMaybe: (() -> number)?
): CarTemplate
	local luckValue = if typeof(luckOrRandom) == "number" then luckOrRandom else nil
	local randomSource = if typeof(luckOrRandom) == "function" then luckOrRandom else randomMaybe
	local pool = DealerCarConfig.arrivalPool(pads, luckValue)
	local sampled = if randomSource ~= nil then randomSource() else math.random()
	if typeof(sampled) ~= "number" or sampled ~= sampled then
		sampled = math.random()
	end
	local roll = math.clamp(sampled, 0, 0.999999999) * pool.totalWeight
	local cumulative = 0
	for _, entry in pool.entries do
		cumulative += entry.weight
		if roll < cumulative then
			return entry.template
		end
	end
	return pool.entries[#pool.entries].template
end

-- Compatibility accepts the former (cyclicIndex, pads) signature, but deliberately ignores
-- the index. New callers should use (pads, randomSource); every channel now samples this pool.
function DealerCarConfig.pickCar(indexOrPads: any?, padsOrRandom: any?, randomMaybe: any?): CarTemplate
	local pads: { [string]: boolean }? = nil
	local randomSource: (() -> number)? = nil
	if typeof(indexOrPads) == "table" then
		pads = indexOrPads
		if typeof(padsOrRandom) == "function" then
			randomSource = padsOrRandom
		end
	elseif typeof(padsOrRandom) == "table" then
		pads = padsOrRandom
	end
	if typeof(randomMaybe) == "function" then
		randomSource = randomMaybe
	end
	return DealerCarConfig.selectArrival(pads, randomSource)
end

-- Price the seller opens with, jittered around the template cost.
function DealerCarConfig.askingPrice(template: CarTemplate): number
	local ratio = DealerCarConfig.ASK_MIN_RATIO + math.random() * (DealerCarConfig.ASK_MAX_RATIO - DealerCarConfig.ASK_MIN_RATIO)
	return math.max(1, math.floor(template.baseCost * ratio))
end

-- What the fence says about a car, so three phone offers do not read identically.
DealerCarConfig.FENCE_PITCHES = {
	"barely runs",
	"needs everything",
	"sat in a field for years",
	"engine knocks a bit",
	"no questions asked",
	"cheap because it has to go today",
}

return DealerCarConfig
