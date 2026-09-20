--!strict

-- One server-authoritative Luck stat drives both desirable supply and buyer quality.
-- Luck 1 is the neutral baseline; higher values are deliberately capped so jackpots
-- stay rare instead of becoming guaranteed economy output.
local VehicleNeon = require(script.Parent.VehicleNeon)

export type IncomingVariant = {
	paintHue: number?,
	bodyKit: boolean,
	neonColorId: string?,
	modCount: number,
	askMultiplier: number,
}

local LuckConfig = {}

LuckConfig.DEFAULT = 1
LuckConfig.MIN = 1
LuckConfig.MAX = 5

local LABELS = {
	{ minimum = 4, label = "LEGENDARY" },
	{ minimum = 3, label = "VERY LUCKY" },
	{ minimum = 2, label = "LUCKY" },
	{ minimum = 1, label = "NORMAL" },
}

local BASE_VARIANT_CHANCE = {
	common = 0,
	uncommon = 0.05,
	rare = 0.22,
	epic = 0.48,
	legendary = 0.75,
}

local function roll(randomSource: (() -> number)?): number
	local value = if randomSource ~= nil then randomSource() else math.random()
	if typeof(value) ~= "number" or value ~= value then
		return math.random()
	end
	return math.clamp(value, 0, 0.999999999)
end

function LuckConfig.normalize(value: unknown): number
	if typeof(value) ~= "number" or value ~= value then
		return LuckConfig.DEFAULT
	end
	return math.clamp(value, LuckConfig.MIN, LuckConfig.MAX)
end

function LuckConfig.label(value: unknown): string
	local luck = LuckConfig.normalize(value)
	for _, tier in LABELS do
		if luck >= tier.minimum then
			return tier.label
		end
	end
	return "NORMAL"
end

function LuckConfig.richChance(value: unknown): number
	local luck = LuckConfig.normalize(value)
	return math.clamp(0.15 * luck, 0.15, 0.65)
end

function LuckConfig.superRichChance(value: unknown): number
	local luck = LuckConfig.normalize(value)
	return math.clamp(0.03 * luck ^ 1.5, 0.03, 0.25)
end

-- Reweights the already-unlocked progression pool. Luck never bypasses a pad unlock.
function LuckConfig.arrivalClassMultiplier(classId: string, value: unknown): number
	local luck = LuckConfig.normalize(value)
	if classId == "low" then
		return 1 / math.sqrt(luck)
	elseif classId == "mid" then
		return luck ^ 0.35
	elseif classId == "high" then
		return luck ^ 1.15
	elseif classId == "hyper" then
		return luck ^ 2
	end
	return 1
end

function LuckConfig.variantChance(rarityId: string, value: unknown): number
	local base = BASE_VARIANT_CHANCE[rarityId] or 0
	local luck = LuckConfig.normalize(value)
	return math.clamp(base + (luck - 1) * 0.08, 0, 0.95)
end

function LuckConfig.rollIncomingVariant(
	rarityId: string,
	value: unknown,
	randomSource: (() -> number)?
): IncomingVariant
	local empty: IncomingVariant = {
		paintHue = nil,
		bodyKit = false,
		neonColorId = nil,
		modCount = 0,
		askMultiplier = 1,
	}
	if roll(randomSource) >= LuckConfig.variantChance(rarityId, value) then
		return empty
	end

	local maximumMods = if rarityId == "legendary" then 3 elseif rarityId == "epic" then 2 else 1
	local modCount = 1
	if maximumMods >= 2 and roll(randomSource) < 0.55 then
		modCount = 2
	end
	if maximumMods >= 3 and modCount == 2 and roll(randomSource) < 0.35 then
		modCount = 3
	end

	local choices = { "paint", "body", "neon" }
	for index = #choices, 2, -1 do
		local swap = math.floor(roll(randomSource) * index) + 1
		choices[index], choices[swap] = choices[swap], choices[index]
	end
	for index = 1, modCount do
		local choice = choices[index]
		if choice == "paint" then
			empty.paintHue = roll(randomSource)
		elseif choice == "body" then
			empty.bodyKit = true
		elseif choice == "neon" then
			empty.bodyKit = true
			local palette = VehicleNeon.PALETTE_IDS
			empty.neonColorId = palette[math.floor(roll(randomSource) * #palette) + 1]
		end
	end
	empty.modCount = modCount
	-- Sellers understand that a modified car is worth more, but Luck still leaves upside.
	empty.askMultiplier = 1 + modCount * 0.10
	return empty
end

return LuckConfig

