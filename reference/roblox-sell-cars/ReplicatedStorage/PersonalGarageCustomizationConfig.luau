--!strict
-- Shared catalog for permanent Personal Garage paint, tint, stance, and headlight purchases.
-- Prices stay server-authoritative; the client receives the same catalog in PersonalGarageState.
local VehiclePaint = require(script.Parent:WaitForChild("VehiclePaint"))

export type BodyColorOption = {
	label: string,
	hue: number?,
	color: Color3,
}

export type TintLevelOption = {
	label: string,
	alpha: number,
	price: number,
}

export type TintColorOption = {
	label: string,
	color: Color3,
	price: number,
}

local Config = {}

-- Define each option once, in display order; callers can also look it up by ID.
local function catalog(entries: { any }): ({ string }, { [string]: any })
	local ids, options = {}, {}
	for _, entry in entries do
		table.insert(ids, entry.id)
		local option = table.clone(entry)
		option.id = nil
		options[entry.id] = option
	end
	return ids, options
end

local function optionList(ids: { string }, options: { [string]: any }): { any }
	local result = {}
	for _, id in ids do
		local option = table.clone(options[id])
		option.id = id
		table.insert(result, option)
	end
	return result
end

Config.BODY_COLOR_PRICE = 25000
Config.FACTORY_BODY_COLOR_PRICE = 5000
Config.TINT_COLOR_PRICE = 10000
Config.STARTER_TINT_COLOR_PRICE = 5000
Config.HEADLIGHT_COLOR_PRICE = 15000
Config.STARTER_HEADLIGHT_COLOR_PRICE = 5000
Config.HEADLIGHT_SUPER_BRIGHT_PRICE = 25000
Config.STANCE_INSTALL_PRICE = 50000

-- One global permanent Game Pass unlock for premium Personal Garage identity FX.
-- Published Custom FX Pass (District Bloom), listed at 129 Robux.
Config.CUSTOM_FX_GAMEPASS_ID = 1969981456
Config.CUSTOM_FX_PRICE_ROBUX = 129
Config.CUSTOM_FX_TINT_LEVEL_ID = "100"

-- Compatibility surfaces used by the existing client/server flow. Every premium
-- headlight effect, Rainbow Neon, 100% Tint and Plate Delete resolve to this pass.
Config.PLATE_REMOVAL_GAMEPASS_ID = Config.CUSTOM_FX_GAMEPASS_ID

Config.FACTORY_BODY_PREFIX = "factory:"
-- Seven paid universal colors. They are offered only to cars with an authored
-- factory paint palette, so unsupported models still remain safely unavailable.
Config.BODY_COLOR_IDS, Config.BODY_COLORS = catalog({
	{ id = "black", label = "Black", hue = 0, color = Color3.fromRGB(8, 9, 12) },
	{ id = "white", label = "White", hue = 0, color = Color3.fromRGB(245, 245, 240) },
	{ id = "dark_red", label = "Dark Red", hue = 0, color = Color3.fromRGB(122, 30, 36) },
	{ id = "emerald", label = "Emerald", hue = 0.44, color = Color3.fromRGB(11, 107, 80) },
	{ id = "nardo_grey", label = "NARDO GREY", hue = 0, color = Color3.fromRGB(105, 106, 104) },
	{ id = "midnight_blue", label = "Midnight Blue", hue = 0.63, color = Color3.fromRGB(20, 33, 61) },
	{ id = "pink", label = "Pink", hue = 0.91, color = Color3.fromRGB(238, 72, 148) },
})

-- Factory colors are never hidden just because a similar universal color exists.
-- The first authored factory entry is the car's included original paint and remains free.
-- Keep this legacy public field empty so older callers cannot reintroduce suppression.
Config.SUPPRESSED_FACTORY_BODY_IDS = {}

Config.STARTER_NEON_COLOR_IDS = { "cyan", "red" }
Config.STARTER_TINT_LEVEL_IDS = { "0", "50" }
Config.STARTER_TINT_COLOR_IDS = { "black", "cyan" }
Config.STARTER_HEADLIGHT_COLOR_IDS = { "white", "blue" }

Config.TINT_LEVEL_IDS, Config.TINT_LEVELS = catalog({
	{ id = "0", label = "0%", alpha = 0, price = 0 },
	{ id = "50", label = "50%", alpha = 0.5, price = 10000 },
	{ id = "100", label = "100%", alpha = 1, price = 50000 },
})

Config.TINT_COLOR_IDS, Config.TINT_COLORS = catalog({
	{ id = "black", label = "Black", color = Color3.new(0, 0, 0), price = 0 },
	{ id = "red", label = "Red", color = Color3.fromRGB(255, 71, 71), price = Config.TINT_COLOR_PRICE },
	{ id = "yellow", label = "Yellow", color = Color3.fromRGB(255, 204, 71), price = Config.TINT_COLOR_PRICE },
	{ id = "cyan", label = "Cyan", color = Color3.fromRGB(71, 222, 255), price = Config.STARTER_TINT_COLOR_PRICE },
	{ id = "magenta", label = "Magenta", color = Color3.fromRGB(251, 71, 255), price = Config.TINT_COLOR_PRICE },
})

Config.HEADLIGHT_COLOR_IDS, Config.HEADLIGHT_COLORS = catalog({
	{ id = "white", label = "White", color = Color3.fromRGB(235, 245, 255), price = 0 },
	{ id = "red", label = "Red", color = Color3.fromRGB(255, 45, 45), price = Config.HEADLIGHT_COLOR_PRICE },
	{ id = "green", label = "Green", color = Color3.fromRGB(45, 255, 115), price = Config.HEADLIGHT_COLOR_PRICE },
	{ id = "blue", label = "Blue", color = Color3.fromRGB(55, 140, 255), price = Config.STARTER_HEADLIGHT_COLOR_PRICE },
	{ id = "purple", label = "Purple", color = Color3.fromRGB(185, 75, 255), price = Config.HEADLIGHT_COLOR_PRICE },
})

Config.HEADLIGHT_BRIGHTNESS_IDS, Config.HEADLIGHT_BRIGHTNESS = catalog({
	{ id = "standard", label = "Standard", brightness = 1.6, range = 28, angle = 58, price = 0 },
	{ id = "super", label = "SUPER BRIGHT", brightness = 4.5, range = 46, angle = 58, price = Config.HEADLIGHT_SUPER_BRIGHT_PRICE },
})

Config.HEADLIGHT_EFFECT_IDS, Config.HEADLIGHT_EFFECTS = catalog({
	{ id = "steady", label = "STEADY", premium = false },
	{ id = "rainbow", label = "RAINBOW", premium = true },
	{ id = "flashing", label = "FLASHING", premium = true },
	{ id = "cop", label = "COP", premium = true },
})
Config.HEADLIGHT_EFFECT_GAMEPASS_IDS = {}
for id, effect in Config.HEADLIGHT_EFFECTS do
	if effect.premium then
		Config.HEADLIGHT_EFFECT_GAMEPASS_IDS[id] = Config.CUSTOM_FX_GAMEPASS_ID
	end
end

Config.PERFORMANCE_MAX_LEVEL = 3
Config.PERFORMANCE_STAT_IDS, Config.PERFORMANCE_STATS = catalog({
	{ id = "acceleration", label = "ACCELERATION", totalRatingGain = 1.8, ratingField = "accelerationRating", ratingDivisor = 1, levelField = "accelerationLevel" },
	{ id = "top_speed", label = "TOP SPEED", totalRatingGain = 1.65, ratingField = "topSpeedKph", ratingDivisor = 36, levelField = "topSpeedLevel" },
	{ id = "handling", label = "HANDLING", totalRatingGain = 1.65, ratingField = "handlingRating", ratingDivisor = 1, levelField = "handlingLevel" },
})
Config.PERFORMANCE_PRICE_RATIOS = { 0.025, 0.04, 0.055 }

-- The catalog's 360 km/h Zentauri is the authored 10/10 top-speed ceiling.
local function performanceBaseRating(template: any, statId: string): number
	local rating = Config.PERFORMANCE_STATS[statId]
	if typeof(template) ~= "table" or rating == nil then
		return 0
	end
	local value = tonumber(template[rating.ratingField]) or 0
	return math.clamp(value / rating.ratingDivisor, 0, 10)
end

function Config.isPerformanceStatId(value: unknown): boolean
	return typeof(value) == "string" and Config.PERFORMANCE_STATS[value :: string] ~= nil
end

function Config.performanceLevel(value: unknown): number
	return if typeof(value) == "number"
		then math.clamp(math.floor(value :: number), 0, Config.PERFORMANCE_MAX_LEVEL)
		else 0
end

function Config.performanceRating(template: any, statId: unknown, level: unknown): number
	if not Config.isPerformanceStatId(statId) then return 0 end
	local resolvedStat = statId :: string
	local base = performanceBaseRating(template, resolvedStat)
	if base >= 9.999 then return 10 end
	local definition = Config.PERFORMANCE_STATS[resolvedStat]
	local totalGain = math.min(10 - base, definition.totalRatingGain)
	return math.min(10, base + totalGain * (Config.performanceLevel(level) / Config.PERFORMANCE_MAX_LEVEL))
end

function Config.performanceMaxLevel(template: any, statId: unknown): number
	if not Config.isPerformanceStatId(statId) then return 0 end
	return if performanceBaseRating(template, statId :: string) >= 9.999 then 0 else Config.PERFORMANCE_MAX_LEVEL
end

function Config.performanceUpgradePrice(marketPrice: unknown, nextLevel: unknown): number
	local level = math.clamp(math.floor(tonumber(nextLevel) or 1), 1, Config.PERFORMANCE_MAX_LEVEL)
	local ratio = Config.PERFORMANCE_PRICE_RATIOS[level]
	local raw = math.max(0, tonumber(marketPrice) or 0) * ratio
	return math.max(25000, math.floor((raw + 2500) / 5000) * 5000)
end

function Config.performanceState(template: any, customization: any, marketPrice: unknown): any
	local saved = if typeof(customization) == "table" then customization else {}
	local result = {}
	for _, statId in Config.PERFORMANCE_STAT_IDS do
		local definition = Config.PERFORMANCE_STATS[statId]
		local level = Config.performanceLevel(saved[definition.levelField])
		local maxLevel = Config.performanceMaxLevel(template, statId)
		if maxLevel == 0 then level = 0 end
		result[statId] = {
			id = statId,
			label = Config.PERFORMANCE_STATS[statId].label,
			base = performanceBaseRating(template, statId),
			rating = Config.performanceRating(template, statId, level),
			level = level,
			maxLevel = maxLevel,
			nextCost = if level < maxLevel then Config.performanceUpgradePrice(marketPrice, level + 1) else 0,
		}
	end
	return result
end

function Config.performanceMultipliers(template: any, customization: any): any
	local state = Config.performanceState(template, customization, 0)
	return {
		acceleration = 1 + math.max(0, state.acceleration.rating - state.acceleration.base) * 0.12,
		topSpeed = 1 + math.max(0, state.top_speed.rating - state.top_speed.base) * 0.08,
		handlingGain = math.max(0, state.handling.rating - state.handling.base),
	}
end

function Config.isBodyColorId(value: unknown): boolean
	return typeof(value) == "string" and Config.BODY_COLORS[value :: string] ~= nil
end

function Config.factoryBodyColorId(paintId: string): string
	return Config.FACTORY_BODY_PREFIX .. paintId
end

function Config.factoryPaintId(value: unknown): string?
	if typeof(value) ~= "string" then return nil end
	local text = value :: string
	if string.sub(text, 1, #Config.FACTORY_BODY_PREFIX) ~= Config.FACTORY_BODY_PREFIX then return nil end
	local paintId = string.sub(text, #Config.FACTORY_BODY_PREFIX + 1)
	return if paintId ~= "" then paintId else nil
end

function Config.hasBodyPalette(modelName: unknown): boolean
	return typeof(modelName) == "string" and VehiclePaint.FACTORY_PALETTES[modelName :: string] ~= nil
end

function Config.isFactoryBodyColorIdForModel(value: unknown, modelName: unknown): boolean
	local paintId = Config.factoryPaintId(value)
	local palette = if typeof(modelName) == "string" then VehiclePaint.FACTORY_PALETTES[modelName :: string] else nil
	if paintId == nil or palette == nil then return false end
	for _, entry in palette do
		if entry.id == paintId then return true end
	end
	return false
end

function Config.isBodySelectionIdForModel(value: unknown, modelName: unknown): boolean
	if Config.isFactoryBodyColorIdForModel(value, modelName) then return true end
	if not Config.isBodyColorId(value) then return false end
	for _, entry in Config.bodyPalette(modelName) do
		if entry.factory ~= true and entry.id == value then return true end
	end
	return false
end

function Config.defaultBodyColorIdForModel(modelName: unknown): string?
	local palette = if typeof(modelName) == "string" then VehiclePaint.FACTORY_PALETTES[modelName :: string] else nil
	local first = if palette then palette[1] else nil
	return if first then Config.factoryBodyColorId(first.id) else nil
end

local function idInList(value: unknown, ids: { string }): boolean
	return typeof(value) == "string" and table.find(ids, value :: string) ~= nil
end

function Config.isStarterNeonColorId(value: unknown): boolean
	return idInList(value, Config.STARTER_NEON_COLOR_IDS)
end

function Config.isStarterTintLevelId(value: unknown): boolean
	return idInList(value, Config.STARTER_TINT_LEVEL_IDS)
end

function Config.isStarterTintColorId(value: unknown): boolean
	return idInList(value, Config.STARTER_TINT_COLOR_IDS)
end

function Config.isStarterHeadlightColorId(value: unknown): boolean
	return idInList(value, Config.STARTER_HEADLIGHT_COLOR_IDS)
end

function Config.isStarterHeadlightSetup(colorId: unknown, brightnessId: unknown, effectId: unknown): boolean
	return Config.isStarterHeadlightColorId(colorId) and brightnessId == "standard" and effectId == "steady"
end

function Config.isTintLevelId(value: unknown): boolean
	return typeof(value) == "string" and Config.TINT_LEVELS[value :: string] ~= nil
end

function Config.isCustomFxTintLevel(value: unknown): boolean
	return value == Config.CUSTOM_FX_TINT_LEVEL_ID
end

function Config.isTintColorId(value: unknown): boolean
	return typeof(value) == "string" and Config.TINT_COLORS[value :: string] ~= nil
end

function Config.isHeadlightColorId(value: unknown): boolean
	return typeof(value) == "string" and Config.HEADLIGHT_COLORS[value :: string] ~= nil
end

function Config.isHeadlightBrightnessId(value: unknown): boolean
	return typeof(value) == "string" and Config.HEADLIGHT_BRIGHTNESS[value :: string] ~= nil
end

function Config.isHeadlightEffectId(value: unknown): boolean
	return typeof(value) == "string" and Config.HEADLIGHT_EFFECTS[value :: string] ~= nil
end

-- Rainbow is a color-mode, not a layer over a separately selected static color.
-- Keep white only as the deterministic stored/runtime fallback while rainbow owns the visible color.
function Config.canonicalHeadlightColorId(colorId: unknown, effectId: unknown): string
	if effectId == "rainbow" then return "white" end
	return if Config.isHeadlightColorId(colorId) then colorId :: string else "white"
end

function Config.customFxGamePassId(): number
	return tonumber(Config.CUSTOM_FX_GAMEPASS_ID) or 0
end

function Config.headlightEffectGamePassId(effectId: unknown): number
	if not Config.isHeadlightEffectId(effectId) or effectId == "steady" then return 0 end
	return Config.customFxGamePassId()
end

function Config.bodyPalette(modelName: unknown): { any }
	local result = {}
	local palette = if typeof(modelName) == "string" then VehiclePaint.FACTORY_PALETTES[modelName :: string] else nil
	if palette == nil then return result end
	for index, entry in palette do
		table.insert(result, {
			id = Config.factoryBodyColorId(entry.id),
			label = entry.id,
			color = entry.color,
			price = if index == 1 then 0 else Config.FACTORY_BODY_COLOR_PRICE,
			factory = true,
			factoryDefault = index == 1,
			factoryPaintId = entry.id,
		})
	end
	for _, id in Config.BODY_COLOR_IDS do
		local option = Config.BODY_COLORS[id]
		table.insert(result, {
			id = id,
			label = option.label,
			hue = option.hue,
			color = option.color,
			price = Config.BODY_COLOR_PRICE,
			factory = false,
		})
	end
	return result
end

function Config.tintLevels(): { any }
	return optionList(Config.TINT_LEVEL_IDS, Config.TINT_LEVELS)
end

function Config.tintPalette(): { any }
	return optionList(Config.TINT_COLOR_IDS, Config.TINT_COLORS)
end

function Config.headlightPalette(): { any }
	return optionList(Config.HEADLIGHT_COLOR_IDS, Config.HEADLIGHT_COLORS)
end

function Config.headlightBrightnessLevels(): { any }
	return optionList(Config.HEADLIGHT_BRIGHTNESS_IDS, Config.HEADLIGHT_BRIGHTNESS)
end

function Config.headlightEffects(): { any }
	local result = {}
	for _, id in Config.HEADLIGHT_EFFECT_IDS do
		local option = Config.HEADLIGHT_EFFECTS[id]
		table.insert(result, {
			id = id,
			label = option.label,
			premium = option.premium == true,
			gamePassId = Config.headlightEffectGamePassId(id),
		})
	end
	return result
end

return Config
