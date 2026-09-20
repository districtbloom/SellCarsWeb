--!strict
-- Persistent Personal Garage ownership, world rig lifecycle, and server-authoritative phone actions.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local AdminAccess = require(script.Parent.AdminAccess)
local DataService = require(script.Parent.DataService)
local GameplayEvents = require(script.Parent.GameplayEvents)
local Remotes = require(script.Parent.JunkLot.Remotes)
local TycoonService = require(script.Parent.TycoonService)
local CarVisuals = require(script.Parent.JunkLot.CarVisuals)
local DealerCarConfig = require(ReplicatedStorage:WaitForChild("DealerCarConfig"))
local VehicleNeon = require(ReplicatedStorage:WaitForChild("VehicleNeon"))
local VehiclePaint = require(ReplicatedStorage:WaitForChild("VehiclePaint"))
local VehicleWindowTint = require(ReplicatedStorage:WaitForChild("VehicleWindowTint"))
local VehiclePlateVisibility = require(ReplicatedStorage:WaitForChild("VehiclePlateVisibility"))
local VehicleHeadlightCustomization = require(ReplicatedStorage:WaitForChild("VehicleHeadlightCustomization"))
local CustomizationConfig = require(ReplicatedStorage:WaitForChild("PersonalGarageCustomizationConfig"))

local NEON_INSTALL_PRICE = 15000
local NEON_RECOLOR_PRICE = 5000
local NITRO_INSTALL_PRICE = 200000
local SALVAGE_RATE = 0.35
local TERMINAL_DISTANCE = 14
local SUMMON_DISTANCE = 16
local SUMMON_COOLDOWN = 2
-- The second bay should arrive early enough to make collecting cars useful, while remaining a meaningful upgrade.
local GARAGE_EXPANSION_PRICE = 1750000
local GARAGE_EXPANSION_OFFSET = 15
local GARAGE_EXPANSION_BUILD_TIME = 1.15
local GARAGE_EXPANSION_PAD_VERSION = 7
local SELL_QUOTE_SECONDS = 15
local CUSTOMIZE_OPEN_ACK_TIMEOUT = 3
-- Capacity recovery is a forced compatibility path, so it repays every tracked dollar
-- plus a small goodwill premium instead of using the ordinary 60%/35% resale formula.
local CAPACITY_REFUND_BONUS_RATE = 0.10
local PAD_COLOR_ATTRIBUTE = "_PurchasePadColor0"
local PAD_ID_ATTRIBUTE = "PurchasePadId"
local PAD_COST_ATTRIBUTE = "PurchasePadCost"
local PAD_EFFECT_ATTRIBUTE = "PurchasePadEffect"
local PAD_OPEN_ATTRIBUTE = "PurchasePadOpen"
local GARAGE_EXPANSION_PAD_ID = "PersonalGarageSecondBay"
local GARAGE_EXPANSION_EFFECT = "UNLOCKS SECOND PERSONAL CAR BAY"
local GARAGE_EXPANSION_PAD_COLOR = Color3.fromRGB(45, 220, 82)

local function formatWholeNumber(value: number): string
	local digits = tostring(math.floor(math.max(0, value)))
	local reversed = string.reverse(digits)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1,")
	local formatted = string.reverse(grouped)
	local cleaned = string.gsub(formatted, "^,", "")
	return cleaned
end

-- Personal cars are permanent collection purchases, not disposable dealer stock.
-- Their prices intentionally sit alongside late-tycoon upgrades, with the hypercar
-- serving as the long-term cash sink at the top of the collection.
local PERSONAL_PRICES: { [string]: number } = {
	Rusty = 90000,
	Wronkler = 135000,
	RadoBoxlet = 225000,
	ChevroluxC10 = 340000,
	Nissho = 585000,
	HondoCivixEK = 810000,
	Bavora = 1100000,
	Mercurion190r = 2250000,
	FierroRossa = 3400000,
	Gblock = 3900000,
	Porschka911 = 4500000,
	ZentauriR = 9000000,
}
local STARTER_IDS = { Rusty = true, Wronkler = true }
local CATALOG: { [string]: any } = {}
local CATALOG_ORDER: { string } = {}
for _, template in DealerCarConfig.catalogCars() do
	local price = PERSONAL_PRICES[template.id]
	if price ~= nil then
		CATALOG[template.id] = {
			id = template.id,
			name = template.displayName or template.id,
			model = template.model,
			price = price,
			sellPrice = math.floor(price * 0.6),
			template = template,
		}
		table.insert(CATALOG_ORDER, template.id)
	end
end

local activeCars: { [Player]: Model } = {}
local secondaryCars: { [Player]: Model } = {}
local entryLocks: { [Player]: any } = {}
type CustomizeTicket = { token: string, confirmed: boolean }
local customizeTickets: { [Player]: CustomizeTicket } = {}
local mutating: { [Player]: boolean } = {}
-- Coalesces claim/bootstrap restoration into one scheduler-turn reconciliation.
-- This closes the existing-player claim race without arbitrary timed retries.
local runtimeSyncQueued: { [Player]: boolean } = {}
local requestAt: { [Player]: number } = {}
local driveTokens: { [Player]: number } = {}
local personalDriveSeconds: { [Player]: number } = {}
local driveMilestoneSent: { [Player]: boolean } = {}
local enteredThisSession: { [Player]: boolean } = {}
local summonAt: { [Player]: number } = {}
local customFxEntitlementCache: { [Player]: { owns: boolean, checkedAt: number } } = {}
local customFxAnalyticsSeen: { [Player]: { [string]: boolean } } = {}
local customFxGrantLogged: { [Player]: boolean } = {}
local CUSTOM_FX_FEATURES: { [string]: boolean } = {
	rainbow_neon = true,
	tint_100 = true,
	plate_delete = true,
	headlight_cop = true,
	headlight_flashing = true,
	headlight_rainbow = true,
	bundle_phone = true,
	bundle_pad = true,
}
type SellQuote = {
	token: string,
	carId: string,
	amount: number,
	freeStarter: boolean,
	expiresAt: number,
	kind: string,
	investment: number,
	bonus: number,
	targetCarId: string?,
	purchasePrice: number?,
}
local sellQuotes: { [Player]: SellQuote } = {}

local remoteFunction: RemoteFunction
local stateEvent: RemoteEvent
local customizeEvent: RemoteEvent
local customFxOfferEvent: RemoteEvent

local PersonalGarageService = {}

local function hasOtherOwnedCar(garageData: any, excludedCarId: string): boolean
	for candidateId, owned in garageData.owned do
		if owned == true and candidateId ~= excludedCarId then
			return true
		end
	end
	return false
end

local function customFxEntitled(player: Player): boolean
	if AdminAccess.isAuthorized(player) then
		local data = DataService.get(player)
		if data ~= nil and data.personalGarage.customFxAdminClaimed == true then
			return true
		end
	end
	local gamePassId = CustomizationConfig.customFxGamePassId()
	if gamePassId <= 0 then
		return false
	end
	local cached = customFxEntitlementCache[player]
	if cached ~= nil and (cached.owns or os.clock() - cached.checkedAt < 60) then
		return cached.owns
	end
	local success, owns = pcall(
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		player.UserId,
		gamePassId
	)
	if not success then
		warn("[PersonalGarage] could not check Custom FX Pass for " .. player.Name)
		return false
	end
	local result = owns == true
	customFxEntitlementCache[player] = { owns = result, checkedAt = os.clock() }
	return result
end

local function plateRemovalEntitled(player: Player): boolean
	return customFxEntitled(player)
end

local function headlightEffectEntitled(player: Player, effectId: string): boolean
	if effectId == "steady" then return true end
	return customFxEntitled(player)
end

local function refreshPersonalDrivePrompts(player: Player, car: Model)
	local occupied = false
	for _, descendant in car:GetDescendants() do
		if descendant:IsA("VehicleSeat") and descendant.Occupant ~= nil then
			occupied = true
			break
		end
	end
	local customizing = player:GetAttribute("PersonalGarageCustomizing") == true
	local promptEnabled = not occupied and not customizing
	for _, descendant in car:GetDescendants() do
		if descendant:IsA("VehicleSeat") then
			-- Customize is the only state that may physically lock an owner seat.
			-- Reassert the normal state as well: a late vehicle lifecycle producer used
			-- to leave a second-bay seat disabled even after its prompt was restored.
			descendant.Disabled = customizing
			descendant.CanTouch = not customizing
		elseif descendant:IsA("ProximityPrompt") and descendant.Name == "DrivePrompt" then
			descendant.Enabled = promptEnabled
		end
	end
end

local function trySeatPersonalOwner(player: Player, car: Model)
	if car:GetAttribute("PersonalVehicle") ~= true
		or tonumber(car:GetAttribute("PersonalVehicleOwnerUserId")) ~= player.UserId
		or car:GetAttribute("DealerDriveLocked") == true
		or player:GetAttribute("PersonalGarageCustomizing") == true
	then
		return
	end
	local exact = car:FindFirstChild("DriverSeat", true)
	local seat = if exact and exact:IsA("VehicleSeat") then exact else car:FindFirstChildWhichIsA("VehicleSeat", true)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if seat == nil or humanoid == nil or humanoid.Health <= 0 or seat.Occupant ~= nil then
		return
	end
	if humanoid.SeatPart ~= nil and not humanoid.SeatPart:IsDescendantOf(car) then
		return
	end
	seat.Disabled = false
	seat.CanTouch = true
	seat:Sit(humanoid)
	-- Runtime vehicle workers may attach one frame after a freshly summoned car. Retry the
	-- same authoritative owner seat once, but never displace a real occupant.
	task.delay(0.15, function()
		if car.Parent ~= nil
			and player.Parent ~= nil
			and player:GetAttribute("PersonalGarageCustomizing") ~= true
			and seat.Parent ~= nil
			and seat.Occupant == nil
			and humanoid.Parent ~= nil
			and humanoid.SeatPart == nil
		then
			seat.Disabled = false
			seat.CanTouch = true
			seat:Sit(humanoid)
		end
	end)
end

local function unlockCarEntry(player: Player)
	local lock = entryLocks[player]
	entryLocks[player] = nil
	if typeof(lock) ~= "table" then return end
	for seat, state in lock.seats or {} do
		if seat.Parent ~= nil then
			seat.Disabled = state.disabled
			seat.CanTouch = state.canTouch
		end
	end
	for prompt, enabled in lock.prompts or {} do
		if prompt.Parent ~= nil then prompt.Enabled = enabled end
	end
end

local function lockCarEntry(player: Player, _car: Model)
	unlockCarEntry(player)
	local lock = { seats = {}, prompts = {} }
	entryLocks[player] = lock
	-- Customize can switch between both physical bays without closing. Lock both
	-- owner cars so the unselected one cannot be entered behind the modal.
	for _, car in { activeCars[player], secondaryCars[player] } do
		if car ~= nil and car.Parent ~= nil then
			for _, descendant in car:GetDescendants() do
				if descendant:IsA("VehicleSeat") then
					lock.seats[descendant] = { disabled = descendant.Disabled, canTouch = descendant.CanTouch }
					local occupant = descendant.Occupant
					if occupant ~= nil then
						occupant.Sit = false
						occupant:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
					descendant.Disabled = true
					descendant.CanTouch = false
				elseif descendant:IsA("ProximityPrompt") and descendant.Name == "DrivePrompt" then
					lock.prompts[descendant] = descendant.Enabled
					descendant.Enabled = false
				end
			end
		end
	end
	local garage = if _car ~= nil then _car:FindFirstAncestor("PersonalGarage") else nil
	if garage ~= nil then
		for _, descendant in garage:GetDescendants() do
			if descendant:IsA("ProximityPrompt") and descendant.Name == "CustomizePrompt" then
				lock.prompts[descendant] = descendant.Enabled
				descendant.Enabled = false
			end
		end
	end
end

local function releaseCustomize(player: Player)
	customizeTickets[player] = nil
	player:SetAttribute("PersonalGarageCustomizing", false)
	unlockCarEntry(player)
	for _, car in { activeCars[player], secondaryCars[player] } do
		if car ~= nil and car.Parent ~= nil then
			refreshPersonalDrivePrompts(player, car)
		end
	end
end

local function customizationFor(garageData: any, carId: string): any
	if typeof(garageData.customizations) ~= "table" then
		garageData.customizations = {}
	end
	local customization = garageData.customizations[carId]
	if typeof(customization) ~= "table" then
		customization = {
			neonInstalled = false,
			neonColorId = nil,
			neonEnabled = false,
			nitroInstalled = false,
			accelerationLevel = 0,
			topSpeedLevel = 0,
			handlingLevel = 0,
			stanceInstalled = false,
			stanceEnabled = false,
			bodyColorId = nil,
			ownedBodyColorIds = {},
			tintLevelId = "0",
			ownedTintLevelIds = { ["0"] = true },
			tintColorId = "black",
			ownedTintColorIds = { black = true },
			headlightColorId = "white",
			ownedHeadlightColorIds = { white = true },
			headlightBrightnessId = "standard",
			ownedHeadlightBrightnessIds = { standard = true },
			headlightEffectId = "steady",
			platesRemoved = false,
			acquisitionPaid = nil,
			customizationPaid = nil,
		}
		garageData.customizations[carId] = customization
	end
	if typeof(customization.ownedBodyColorIds) ~= "table" then customization.ownedBodyColorIds = {} end
	if typeof(customization.ownedTintLevelIds) ~= "table" then customization.ownedTintLevelIds = {} end
	if typeof(customization.ownedTintColorIds) ~= "table" then customization.ownedTintColorIds = {} end
	if typeof(customization.ownedHeadlightColorIds) ~= "table" then customization.ownedHeadlightColorIds = {} end
	if typeof(customization.ownedHeadlightBrightnessIds) ~= "table" then customization.ownedHeadlightBrightnessIds = {} end
	customization.stanceInstalled = customization.stanceInstalled == true
	customization.stanceEnabled = customization.stanceInstalled and customization.stanceEnabled == true
	customization.platesRemoved = customization.platesRemoved == true
	customization.ownedTintLevelIds["0"] = true
	customization.ownedTintColorIds.black = true
	customization.ownedHeadlightColorIds.white = true
	customization.ownedHeadlightBrightnessIds.standard = true
	local definition = CATALOG[carId]
	local modelName = if definition ~= nil then definition.model else nil
	local includedBodyColorId = CustomizationConfig.defaultBodyColorIdForModel(modelName)
	if includedBodyColorId ~= nil then customization.ownedBodyColorIds[includedBodyColorId] = true end
	customization.accelerationLevel = CustomizationConfig.performanceLevel(customization.accelerationLevel)
	customization.topSpeedLevel = CustomizationConfig.performanceLevel(customization.topSpeedLevel)
	customization.handlingLevel = CustomizationConfig.performanceLevel(customization.handlingLevel)
	if definition ~= nil then
		if CustomizationConfig.performanceMaxLevel(definition.template, "acceleration") == 0 then customization.accelerationLevel = 0 end
		if CustomizationConfig.performanceMaxLevel(definition.template, "top_speed") == 0 then customization.topSpeedLevel = 0 end
		if CustomizationConfig.performanceMaxLevel(definition.template, "handling") == 0 then customization.handlingLevel = 0 end
	end
	local selectedBodyColorId = customization.bodyColorId
	local validFactoryBody = CustomizationConfig.isFactoryBodyColorIdForModel(selectedBodyColorId, modelName)
		and customization.ownedBodyColorIds[selectedBodyColorId] == true
	local validOwnedBody = CustomizationConfig.isBodyColorId(selectedBodyColorId)
		and customization.ownedBodyColorIds[selectedBodyColorId] == true
	if not validFactoryBody and not validOwnedBody then
		customization.bodyColorId = nil
	end
	if not CustomizationConfig.isTintLevelId(customization.tintLevelId)
		or customization.ownedTintLevelIds[customization.tintLevelId] ~= true
	then
		customization.tintLevelId = "0"
	end
	if not CustomizationConfig.isTintColorId(customization.tintColorId)
		or customization.ownedTintColorIds[customization.tintColorId] ~= true
	then
		customization.tintColorId = "black"
	end
	if not CustomizationConfig.isHeadlightColorId(customization.headlightColorId)
		or customization.ownedHeadlightColorIds[customization.headlightColorId] ~= true
	then
		customization.headlightColorId = "white"
	end
	if not CustomizationConfig.isHeadlightBrightnessId(customization.headlightBrightnessId)
		or customization.ownedHeadlightBrightnessIds[customization.headlightBrightnessId] ~= true
	then
		customization.headlightBrightnessId = "standard"
	end
	if not CustomizationConfig.isHeadlightEffectId(customization.headlightEffectId) then
		customization.headlightEffectId = "steady"
	end
	customization.headlightColorId = CustomizationConfig.canonicalHeadlightColorId(
		customization.headlightColorId,
		customization.headlightEffectId
	)
	return customization
end

local function salvageFor(customization: any, carId: string): number
	local installed = 0
	if customization.neonInstalled == true then installed += NEON_INSTALL_PRICE end
	if customization.nitroInstalled == true then installed += NITRO_INSTALL_PRICE end
	if customization.stanceInstalled == true then installed += CustomizationConfig.STANCE_INSTALL_PRICE end
	-- Engine tuning is permanent fitted hardware. Recover the same 35% share as
	-- neon/nitro rather than treating purchased levels like disposable paint.
	local definition = CATALOG[carId]
	if definition ~= nil then
		for _, statId in CustomizationConfig.PERFORMANCE_STAT_IDS do
			local levelKey = if statId == "acceleration" then "accelerationLevel"
				elseif statId == "top_speed" then "topSpeedLevel" else "handlingLevel"
			local level = CustomizationConfig.performanceLevel(customization[levelKey])
			for purchasedLevel = 1, level do
				installed += CustomizationConfig.performanceUpgradePrice(definition.price, purchasedLevel)
			end
		end
	end
	-- Paint and tint licenses are cosmetic finishes, not recoverable hardware.
	return math.floor(installed * SALVAGE_RATE + 0.5)
end

local function knownCustomizationSpend(customization: any, carId: string): number
	-- Capacity recovery compensates the car that exists now, not every historical
	-- repaint experiment. Count the currently selected finish and the installed/current
	-- hardware levels once.
	local total = 0
	if customization.neonInstalled == true then total += NEON_INSTALL_PRICE end
	if customization.nitroInstalled == true then total += NITRO_INSTALL_PRICE end
	if customization.stanceInstalled == true then total += CustomizationConfig.STANCE_INSTALL_PRICE end

	local definition = CATALOG[carId]
	local modelName = if definition ~= nil then definition.model else nil
	local includedBodyColorId = CustomizationConfig.defaultBodyColorIdForModel(modelName)
	local bodyColorId = customization.bodyColorId
	if typeof(bodyColorId) == "string" and bodyColorId ~= includedBodyColorId then
		if CustomizationConfig.factoryPaintId(bodyColorId) ~= nil then
			total += CustomizationConfig.FACTORY_BODY_COLOR_PRICE
		elseif CustomizationConfig.isBodyColorId(bodyColorId) then
			total += CustomizationConfig.BODY_COLOR_PRICE
		end
	end

	local tintLevel = CustomizationConfig.TINT_LEVELS[customization.tintLevelId]
	if tintLevel ~= nil then total += tintLevel.price end
	local tintColor = CustomizationConfig.TINT_COLORS[customization.tintColorId]
	if tintColor ~= nil then total += tintColor.price end
	local headlightColor = CustomizationConfig.HEADLIGHT_COLORS[customization.headlightColorId]
	if headlightColor ~= nil then total += headlightColor.price end
	local headlightBrightness = CustomizationConfig.HEADLIGHT_BRIGHTNESS[customization.headlightBrightnessId]
	if headlightBrightness ~= nil then total += headlightBrightness.price end

	if definition ~= nil then
		for _, statId in CustomizationConfig.PERFORMANCE_STAT_IDS do
			local levelKey = if statId == "acceleration" then "accelerationLevel"
				elseif statId == "top_speed" then "topSpeedLevel" else "handlingLevel"
			for purchasedLevel = 1, CustomizationConfig.performanceLevel(customization[levelKey]) do
				total += CustomizationConfig.performanceUpgradePrice(definition.price, purchasedLevel)
			end
		end
	end
	return math.max(0, math.floor(total))
end

local function investmentFor(garageData: any, carId: string): (number, number, number, number)
	local definition = CATALOG[carId]
	local customization = customizationFor(garageData, carId)
	local acquisition = customization.acquisitionPaid
	if typeof(acquisition) ~= "number" then
		acquisition = if garageData.freeStarterCarId == carId then 0
			elseif definition ~= nil then definition.price else 0
		customization.acquisitionPaid = acquisition
	end
	acquisition = math.max(0, math.floor(acquisition :: number))
	local customizationPaid = knownCustomizationSpend(customization, carId)
	-- Saved for audit/display only. It is refreshed from the current configuration,
	-- so repeated old recolors never inflate the compatibility refund.
	customization.customizationPaid = customizationPaid
	local investment = acquisition + customizationPaid
	local bonus = math.floor(investment * CAPACITY_REFUND_BONUS_RATE + 0.5)
	return investment + bonus, acquisition, customizationPaid, bonus
end

local function ownedCount(garageData: any): number
	local count = 0
	for _, owned in garageData.owned do if owned == true then count += 1 end end
	return count
end

local function garageCapacity(garageData: any): number
	return if garageData.expanded == true then 2 else 1
end

local function capacityOverflow(garageData: any): (number, number, number)
	local count = ownedCount(garageData)
	local capacity = garageCapacity(garageData)
	return math.max(0, count - capacity), count, capacity
end

local function runCapacityContractSelfTest()
	local fake = {
		expanded = false,
		owned = { Rusty = true, RadoBoxlet = true, Nissho = true },
		freeStarterCarId = "Rusty",
		customizations = {},
	}
	local overflow, totalOwned, capacity = capacityOverflow(fake)
	assert(overflow == 2 and totalOwned == 3 and capacity == 1, "one bay must allow exactly one owned car")
	local starterRefund = investmentFor(fake, "Rusty")
	assert(starterRefund == 0, "a free starter has no invented acquisition value")
	local paidRefund, acquisition, customizationPaid, bonus = investmentFor(fake, "RadoBoxlet")
	assert(acquisition == PERSONAL_PRICES.RadoBoxlet and customizationPaid == 0, "legacy baseline must use current car/configuration")
	assert(paidRefund == acquisition + bonus and bonus == math.floor(acquisition * CAPACITY_REFUND_BONUS_RATE + 0.5), "goodwill refund formula")
	fake.expanded = true
	overflow, totalOwned, capacity = capacityOverflow(fake)
	assert(overflow == 1 and totalOwned == 3 and capacity == 2, "two bays must allow exactly two owned cars")
	print("[PersonalGarageCapacitySelfTest] PASS")
end

local function cloneBooleanMap(source: any): { [string]: boolean }
	local result: { [string]: boolean } = {}
	if typeof(source) == "table" then
		for id, value in source do
			if typeof(id) == "string" and value == true then result[id] = true end
		end
	end
	return result
end

local function copyCustomization(source: any): any
	local result = if typeof(source) == "table" then table.clone(source) else {}
	result.ownedBodyColorIds = cloneBooleanMap(result.ownedBodyColorIds)
	result.ownedTintLevelIds = cloneBooleanMap(result.ownedTintLevelIds)
	result.ownedTintColorIds = cloneBooleanMap(result.ownedTintColorIds)
	result.ownedHeadlightColorIds = cloneBooleanMap(result.ownedHeadlightColorIds)
	result.ownedHeadlightBrightnessIds = cloneBooleanMap(result.ownedHeadlightBrightnessIds)
	return result
end

local function copyCustomizations(source: any): any
	local result = {}
	if typeof(source) == "table" then
		for carId, value in source do
			if typeof(value) == "table" then result[carId] = copyCustomization(value) end
		end
	end
	return result
end

local function garageForRecord(record: any): Model?
	local buildings = record.folder:FindFirstChild("Buildings")
	local garage = if buildings ~= nil then buildings:FindFirstChild("PersonalGarage") else nil
	return if garage ~= nil and garage:IsA("Model") then garage else nil
end

local function garageForPlayer(player: Player): Model?
	local record = TycoonService.getForPlayer(player)
	return if record ~= nil then garageForRecord(record) else nil
end

local function ensureExpansionInfrastructure(garage: Model): BasePart?
	local marker = garage:FindFirstChild("CarSpawn")
	if marker == nil or not marker:IsA("BasePart") then return nil end

	local secondMarker = garage:FindFirstChild("CarSpawn2")
	if secondMarker == nil or not secondMarker:IsA("BasePart") then
		if secondMarker ~= nil then secondMarker:Destroy() end
		secondMarker = Instance.new("Part")
		secondMarker.Name = "CarSpawn2"
		secondMarker.Size = Vector3.one
		secondMarker.Transparency = 1
		secondMarker.Anchored = true
		secondMarker.CanCollide = false
		secondMarker.CanTouch = false
		secondMarker.CanQuery = false
		secondMarker.CastShadow = false
		secondMarker.Parent = garage
	end
	secondMarker.CFrame = marker.CFrame * CFrame.new(-GARAGE_EXPANSION_OFFSET, 0, 0)

	local padModel = garage:FindFirstChild("GarageExpansionPad")
	if padModel == nil
		or not padModel:IsA("Model")
		or padModel:GetAttribute("Version") ~= GARAGE_EXPANSION_PAD_VERSION
	then
		if padModel ~= nil then padModel:Destroy() end
		padModel = Instance.new("Model")
		padModel.Name = "GarageExpansionPad"
		padModel:SetAttribute("Version", GARAGE_EXPANSION_PAD_VERSION)
		padModel.Parent = garage

		local padPosition = (marker.CFrame * CFrame.new(-GARAGE_EXPANSION_OFFSET, -1.42, -17.5)).Position
		local padFrame = CFrame.fromMatrix(padPosition, marker.CFrame.UpVector, marker.CFrame.LookVector)

		local padBase = Instance.new("Part")
		padBase.Name = "PadBase"
		padBase.Shape = Enum.PartType.Cylinder
		padBase.Size = Vector3.new(0.2743902, 6.09756, 6.09756)
		padBase.CFrame = padFrame - marker.CFrame.UpVector * 0.3811226
		padBase.Anchored = true
		padBase.CanCollide = false
		padBase.CanTouch = false
		padBase.CanQuery = false
		padBase.CastShadow = false
		padBase.Material = Enum.Material.SmoothPlastic
		padBase.Color = Color3.fromRGB(24, 25, 28)
		padBase.Transparency = 0
		padBase:SetAttribute("_GarageExpansionTransparency", padBase.Transparency)
		padBase.Parent = padModel

		local pad = Instance.new("Part")
		pad.Name = "Pad"
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(0.4878048, 5.487804, 5.487804)
		pad.CFrame = padFrame
		pad.Anchored = true
		pad.CanCollide = false
		pad.CanTouch = false
		pad.CanQuery = false
		pad.CastShadow = false
		pad.Material = Enum.Material.Neon
		pad.Color = GARAGE_EXPANSION_PAD_COLOR
		pad.Transparency = 0
		pad:SetAttribute("_GarageExpansionTransparency", pad.Transparency)
		-- Publish the same renderer contract as every TycoonConfig purchase pad. Cost stays
		-- server-authored here and the physical touch path remains authoritative below.
		-- Canonical purchase pads never opt into WorldHover/tap-only compaction: their
		-- authored Price billboard remains visible under the same rules as every other pad.
		pad:SetAttribute(PAD_COLOR_ATTRIBUTE, GARAGE_EXPANSION_PAD_COLOR)
		pad:SetAttribute(PAD_ID_ATTRIBUTE, GARAGE_EXPANSION_PAD_ID)
		pad:SetAttribute(PAD_COST_ATTRIBUTE, GARAGE_EXPANSION_PRICE)
		pad:SetAttribute(PAD_EFFECT_ATTRIBUTE, GARAGE_EXPANSION_EFFECT)
		pad:SetAttribute(PAD_OPEN_ATTRIBUTE, false)
		pad.Parent = padBase

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "GarageExpansionLabel"
		billboard.Adornee = pad
		billboard.AlwaysOnTop = false
		billboard.LightInfluence = 0
		billboard.MaxDistance = 70
		billboard.Size = UDim2.fromOffset(150, 56)
		billboard.StudsOffset = Vector3.new(0, 3.3, 0)
		billboard.Parent = pad

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0.58, 0)
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		title.Font = Enum.Font.GothamBlack
		title.Text = "SECOND GARAGE BAY"
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextStrokeColor3 = Color3.new(0, 0, 0)
		title.TextStrokeTransparency = 0
		title.TextScaled = true
		title.TextSize = 8
		title.TextWrapped = true
		title.Parent = billboard

		local price = Instance.new("TextLabel")
		price.Name = "Price"
		price.Size = UDim2.new(1, 0, 0.42, 0)
		price.Position = UDim2.new(0, 0, 0.58, 0)
		price.BackgroundTransparency = 1
		price.BorderSizePixel = 0
		price.Font = Enum.Font.FredokaOne
		price.Text = "$" .. formatWholeNumber(GARAGE_EXPANSION_PRICE)
		price.TextColor3 = Color3.fromRGB(35, 255, 55)
		price.TextStrokeColor3 = Color3.new(0, 0, 0)
		price.TextStrokeTransparency = 0
		price.TextScaled = true
		price.TextSize = 8
		price.TextWrapped = true
		price.Parent = billboard
	end

	local padBase = padModel:FindFirstChild("PadBase")
	local pad = if padBase ~= nil then padBase:FindFirstChild("Pad") else nil
	return if pad ~= nil and pad:IsA("BasePart") then pad else nil
end

local function setExpansionPadVisible(garage: Model, visible: boolean)
	local padModel = garage:FindFirstChild("GarageExpansionPad")
	if padModel == nil then return end
	for _, descendant in padModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			local isPurchaseSurface = descendant.Name == "Pad"
			local original = descendant:GetAttribute("_GarageExpansionTransparency")
			descendant.Transparency = if visible then (if typeof(original) == "number" then original else 0) else 1
			descendant.CanCollide = false
			descendant.CanTouch = visible and isPurchaseSurface
			descendant.CanQuery = visible and isPurchaseSurface
			if isPurchaseSurface then
				-- Reassert on every state change so streamed/reused infrastructure cannot retain
				-- a stale authored price or availability flag.
				descendant:SetAttribute(PAD_COLOR_ATTRIBUTE, GARAGE_EXPANSION_PAD_COLOR)
				descendant:SetAttribute(PAD_ID_ATTRIBUTE, GARAGE_EXPANSION_PAD_ID)
				descendant:SetAttribute(PAD_COST_ATTRIBUTE, GARAGE_EXPANSION_PRICE)
				descendant:SetAttribute(PAD_EFFECT_ATTRIBUTE, GARAGE_EXPANSION_EFFECT)
				descendant:SetAttribute(PAD_OPEN_ATTRIBUTE, visible)
			end
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

local function expansionTarget(part: BasePart, marker: BasePart, mode: string, expanded: boolean): (CFrame, Vector3)
	local baseCFrame = part:GetAttribute("_GarageExpansionBaseCFrame")
	local baseSize = part:GetAttribute("_GarageExpansionBaseSize")
	if typeof(baseCFrame) ~= "CFrame" or typeof(baseSize) ~= "Vector3" then
		baseCFrame = part.CFrame
		baseSize = part.Size
		part:SetAttribute("_GarageExpansionBaseCFrame", baseCFrame)
		part:SetAttribute("_GarageExpansionBaseSize", baseSize)
	end
	if not expanded then return baseCFrame :: CFrame, baseSize :: Vector3 end
	local direction = -marker.CFrame.RightVector
	if mode == "move" then
		return (baseCFrame :: CFrame) + direction * GARAGE_EXPANSION_OFFSET, baseSize :: Vector3
	end

	local targetSize = baseSize :: Vector3
	local base = baseCFrame :: CFrame
	local xDot = math.abs(base.RightVector:Dot(marker.CFrame.RightVector))
	local yDot = math.abs(base.UpVector:Dot(marker.CFrame.RightVector))
	local zDot = math.abs(base.LookVector:Dot(marker.CFrame.RightVector))
	if xDot >= yDot and xDot >= zDot then
		targetSize = Vector3.new(targetSize.X + GARAGE_EXPANSION_OFFSET, targetSize.Y, targetSize.Z)
	elseif yDot >= zDot then
		targetSize = Vector3.new(targetSize.X, targetSize.Y + GARAGE_EXPANSION_OFFSET, targetSize.Z)
	else
		targetSize = Vector3.new(targetSize.X, targetSize.Y, targetSize.Z + GARAGE_EXPANSION_OFFSET)
	end
	return base + direction * (GARAGE_EXPANSION_OFFSET * 0.5), targetSize
end

local function applyGarageExpansion(garage: Model, expanded: boolean, animate: boolean)
	local marker = garage:FindFirstChild("CarSpawn")
	if marker == nil or not marker:IsA("BasePart") then return end
	ensureExpansionInfrastructure(garage)
	local building = garage:FindFirstChild("Building")
	local moveNames = {
		NorthWall = true,
		BlueBandNorth = true,
		FrontLeftPier = true,
		BlueBandFrontLeft = true,
	}
	local resizeNames = {
		Foundation = true,
		FlatRoof = true,
		BackWall = true,
		BlueBandBack = true,
		FrontThreshold = true,
		DoorHeader = true,
	}
	local targets: { { part: BasePart, mode: string } } = {}
	if building ~= nil then
		for _, descendant in building:GetDescendants() do
			if descendant:IsA("BasePart") then
				if moveNames[descendant.Name] == true then
					table.insert(targets, { part = descendant, mode = "move" })
				elseif resizeNames[descendant.Name] == true then
					table.insert(targets, { part = descendant, mode = "resize" })
				end
			end
		end
	end
	for _, containerName in { "GarageDoor", "Driveway" } do
		local container = garage:FindFirstChild(containerName)
		if container ~= nil then
			for _, descendant in container:GetDescendants() do
				if descendant:IsA("BasePart") then
					table.insert(targets, { part = descendant, mode = "resize" })
				end
			end
		end
	end

	local info = TweenInfo.new(GARAGE_EXPANSION_BUILD_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, target in targets do
		local targetCFrame, targetSize = expansionTarget(target.part, marker, target.mode, expanded)
		if animate then
			TweenService:Create(target.part, info, { CFrame = targetCFrame, Size = targetSize }):Play()
		else
			target.part.CFrame = targetCFrame
			target.part.Size = targetSize
		end
	end
	garage:SetAttribute("Expanded", expanded)
end

local setPersonalHeadlights: (Model, boolean) -> ()

local function setDoorOpen(garage: Model, isOpen: boolean)
	local door = garage:FindFirstChild("GarageDoor", true)
	if door == nil then
		return
	end
	-- Tycoon build-state restoration may touch the authored door after the garage profile
	-- has already applied it. Keep both the locked and open state authoritative so join order
	-- cannot reveal the garage before a starter is chosen or close it afterward.
	if garage:GetAttribute("_PersonalGarageDoorGuardBound") ~= true then
		garage:SetAttribute("_PersonalGarageDoorGuardBound", true)
		local function bind(descendant: Instance)
			if descendant:IsA("BasePart") then
				local function enforce()
					if garage:GetAttribute("DoorOpen") == true then
						descendant.Transparency = 1
						descendant.CanCollide = false
						descendant.CanTouch = false
						descendant.CanQuery = false
					else
						local originalTransparency = descendant:GetAttribute("_PersonalGarageTransparency")
						local originalCanCollide = descendant:GetAttribute("_PersonalGarageCanCollide")
						local originalCanTouch = descendant:GetAttribute("_PersonalGarageCanTouch")
						local originalCanQuery = descendant:GetAttribute("_PersonalGarageCanQuery")
						if typeof(originalTransparency) == "number" then descendant.Transparency = originalTransparency end
						if typeof(originalCanCollide) == "boolean" then descendant.CanCollide = originalCanCollide end
						if typeof(originalCanTouch) == "boolean" then descendant.CanTouch = originalCanTouch end
						if typeof(originalCanQuery) == "boolean" then descendant.CanQuery = originalCanQuery end
					end
				end
				descendant:GetPropertyChangedSignal("Transparency"):Connect(enforce)
				descendant:GetPropertyChangedSignal("CanCollide"):Connect(enforce)
				descendant:GetPropertyChangedSignal("CanTouch"):Connect(enforce)
				descendant:GetPropertyChangedSignal("CanQuery"):Connect(enforce)
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				descendant:GetPropertyChangedSignal("Transparency"):Connect(function()
					if garage:GetAttribute("DoorOpen") == true then
						descendant.Transparency = 1
					else
						local originalTransparency = descendant:GetAttribute("_PersonalGarageTransparency")
						if typeof(originalTransparency) == "number" then descendant.Transparency = originalTransparency end
					end
				end)
			end
		end
		for _, descendant in door:GetDescendants() do bind(descendant) end
		door.DescendantAdded:Connect(bind)
	end
	garage:SetAttribute("DoorOpen", isOpen)
	for _, descendant in door:GetDescendants() do
		if descendant:IsA("BasePart") then
			local originalTransparency = descendant:GetAttribute("_PersonalGarageTransparency")
			if typeof(originalTransparency) ~= "number" then
				originalTransparency = descendant.Transparency
				descendant:SetAttribute("_PersonalGarageTransparency", originalTransparency)
			end
			local originalCanCollide = descendant:GetAttribute("_PersonalGarageCanCollide")
			if typeof(originalCanCollide) ~= "boolean" then
				originalCanCollide = descendant.CanCollide
				descendant:SetAttribute("_PersonalGarageCanCollide", originalCanCollide)
			end
			local originalCanTouch = descendant:GetAttribute("_PersonalGarageCanTouch")
			if typeof(originalCanTouch) ~= "boolean" then
				originalCanTouch = descendant.CanTouch
				descendant:SetAttribute("_PersonalGarageCanTouch", originalCanTouch)
			end
			local originalCanQuery = descendant:GetAttribute("_PersonalGarageCanQuery")
			if typeof(originalCanQuery) ~= "boolean" then
				originalCanQuery = descendant.CanQuery
				descendant:SetAttribute("_PersonalGarageCanQuery", originalCanQuery)
			end
			descendant.Transparency = if isOpen then 1 else originalTransparency :: number
			descendant.CanCollide = if isOpen then false else originalCanCollide :: boolean
			descendant.CanTouch = if isOpen then false else originalCanTouch :: boolean
			descendant.CanQuery = if isOpen then false else originalCanQuery :: boolean
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			local originalTransparency = descendant:GetAttribute("_PersonalGarageTransparency")
			if typeof(originalTransparency) ~= "number" then
				originalTransparency = descendant.Transparency
				descendant:SetAttribute("_PersonalGarageTransparency", originalTransparency)
			end
			descendant.Transparency = if isOpen then 1 else originalTransparency :: number
		end
	end
end

local function summonActiveCar(player: Player): (boolean, string)
	local car = activeCars[player]
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	if car == nil or car.Parent == nil then
		return false, "Your active car is still loading."
	end
	if root == nil or not root:IsA("BasePart") then
		return false, "Your character is still loading."
	end
	if player:GetAttribute("PersonalGarageCustomizing") == true then
		return false, "Close Customize before moving the car."
	end
	for _, descendant in car:GetDescendants() do
		if descendant:IsA("VehicleSeat") and descendant.Occupant ~= nil then
			return false, "Exit the car before moving it."
		end
	end
	local now = os.clock()
	if now - (summonAt[player] or 0) < SUMMON_COOLDOWN then
		return false, "Car summon is cooling down."
	end

	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end
	local wantedXZ = root.Position + forward * SUMMON_DISTANCE
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local raycastExclusions: { Instance } = { character :: Model, car }
	-- A race cleanup can summon the personal car near Main Track's finish. Never
	-- mistake the overhead gantry for drivable ground when raycasting downward.
	local mainTrack = workspace:FindFirstChild("MainTrack")
	local finishArch = if mainTrack ~= nil then mainTrack:FindFirstChild("FinishLineArch") else nil
	if finishArch ~= nil then table.insert(raycastExclusions, finishArch) end
	rayParams.FilterDescendantsInstances = raycastExclusions
	rayParams.IgnoreWater = false
	local groundHit = workspace:Raycast(wantedXZ + Vector3.new(0, 40, 0), Vector3.new(0, -100, 0), rayParams)
	if groundHit == nil then
		return false, "No safe ground was found nearby."
	end

	local sourcePivot = car:GetPivot()
	local boxCFrame, boxSize = car:GetBoundingBox()
	local pivotToBox = sourcePivot:ToObjectSpace(boxCFrame)
	local center = Vector3.new(wantedXZ.X, groundHit.Position.Y + boxSize.Y * 0.5 + 0.12, wantedXZ.Z)
	local wantedBox = CFrame.lookAt(center, center + forward, Vector3.yAxis)
	car:PivotTo(wantedBox * pivotToBox:Inverse())
	for _, descendant in car:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
	setPersonalHeadlights(car, false)
	summonAt[player] = now
	return true, "Your car was moved to you."
end

local function destroyActiveCar(player: Player)
	unlockCarEntry(player)
	local primary = activeCars[player]
	local secondary = secondaryCars[player]
	activeCars[player] = nil
	secondaryCars[player] = nil
	for _, car in { primary, secondary } do
		if car ~= nil and car.Parent ~= nil then
			car:SetAttribute("VehicleRuntimeActive", false)
			car:Destroy()
		end
	end
end

local function destroyGarageCars(garage: Model)
	local runtimeCars = garage:FindFirstChild("RuntimeCars")
	if runtimeCars ~= nil then
		for _, child in runtimeCars:GetChildren() do
			child:Destroy()
		end
	end
	for player, car in activeCars do
		if car.Parent == nil or car:IsDescendantOf(garage) then
			activeCars[player] = nil
		end
	end
	for player, car in secondaryCars do
		if car.Parent == nil or car:IsDescendantOf(garage) then
			secondaryCars[player] = nil
		end
	end
end

local function numericBaseAttribute(car: Model, container: Instance?, prefix: string, attributeName: string): number?
	if container == nil then return nil end
	local storageName = "_PersonalBase_" .. prefix .. "_" .. attributeName
	local stored = car:GetAttribute(storageName)
	if typeof(stored) == "number" then return stored end
	local current = container:GetAttribute(attributeName)
	if typeof(current) ~= "number" then return nil end
	car:SetAttribute(storageName, current)
	return current
end

local function applyPerformance(car: Model, template: any, customization: any)
	local engine = car:FindFirstChild("Engine")
	local steering = car:FindFirstChild("Steering")
	local wheels = car:FindFirstChild("Wheels")
	local multipliers = CustomizationConfig.performanceMultipliers(template, customization)
	local accelerationMultiplier = multipliers.acceleration
	local topSpeedMultiplier = multipliers.topSpeed
	local handlingGain = multipliers.handlingGain

	for _, attributeName in { "acceleration", "minSpeedTorque", "maxSpeedTorque", "nitroAcceleration", "nitroTorque" } do
		local base = numericBaseAttribute(car, engine, "Engine", attributeName)
		if base ~= nil and engine ~= nil then engine:SetAttribute(attributeName, base * accelerationMultiplier) end
	end
	for _, attributeName in { "forwardMaxSpeed", "nitroMaxSpeed" } do
		local base = numericBaseAttribute(car, engine, "Engine", attributeName)
		if base ~= nil and engine ~= nil then engine:SetAttribute(attributeName, base * topSpeedMultiplier) end
	end
	local reverseBase = numericBaseAttribute(car, engine, "Engine", "reverseMaxSpeed")
	if reverseBase ~= nil and engine ~= nil then
		engine:SetAttribute("reverseMaxSpeed", reverseBase * (1 + (topSpeedMultiplier - 1) * 0.35))
	end

	local reductionBase = numericBaseAttribute(car, steering, "Steering", "steeringReduction")
	if reductionBase ~= nil and steering ~= nil then
		steering:SetAttribute("steeringReduction", reductionBase * math.max(0.68, 1 - handlingGain * 0.1))
	end
	local responsivenessBase = numericBaseAttribute(car, steering, "Steering", "steeringRackResponsiveness")
	if responsivenessBase ~= nil and steering ~= nil then
		steering:SetAttribute("steeringRackResponsiveness", responsivenessBase * (1 + handlingGain * 0.045))
	end
	for _, spec in {
		{ name = "staticFriction", gain = 0.04 },
		{ name = "kineticFriction", gain = 0.035 },
		{ name = "slipThreshold", gain = 0.05 },
	} do
		local base = numericBaseAttribute(car, wheels, "Wheels", spec.name)
		if base ~= nil and wheels ~= nil then
			wheels:SetAttribute(spec.name, base * (1 + handlingGain * spec.gain))
		end
	end

	car:SetAttribute("PersonalAccelerationLevel", CustomizationConfig.performanceLevel(customization.accelerationLevel))
	car:SetAttribute("PersonalTopSpeedLevel", CustomizationConfig.performanceLevel(customization.topSpeedLevel))
	car:SetAttribute("PersonalHandlingLevel", CustomizationConfig.performanceLevel(customization.handlingLevel))
end

local function applyCustomization(car: Model, modelName: string, customization: any)
	local templateId = car:GetAttribute("TemplateId")
	local definition = if typeof(templateId) == "string" then CATALOG[templateId :: string] else nil
	if definition ~= nil then applyPerformance(car, definition.template, customization) end
	car:SetAttribute("PersonalNitroInstalled", customization.nitroInstalled == true)
	car:SetAttribute("PersonalStanceInstalled", customization.stanceInstalled == true)
	car:SetAttribute("PersonalStanceEnabled", customization.stanceInstalled == true and customization.stanceEnabled == true)

	local selectedBodyColorId = if CustomizationConfig.isBodySelectionIdForModel(customization.bodyColorId, modelName)
		then customization.bodyColorId :: string else nil
	local factoryPaintId = CustomizationConfig.factoryPaintId(selectedBodyColorId)
	local universalBodyColor = if CustomizationConfig.isBodyColorId(selectedBodyColorId)
		then CustomizationConfig.BODY_COLORS[selectedBodyColorId :: string].color else nil
	if factoryPaintId ~= nil then
		VehiclePaint.applyFactoryId(car, modelName, factoryPaintId)
	elseif universalBodyColor ~= nil then
		VehiclePaint.setColor(car, universalBodyColor)
	else
		VehiclePaint.setHue(car, nil)
	end
	car:SetAttribute("PersonalBodyColorId", selectedBodyColorId)

	local tintLevelId = if CustomizationConfig.isTintLevelId(customization.tintLevelId)
		then customization.tintLevelId :: string else "0"
	local tintColorId = if CustomizationConfig.isTintColorId(customization.tintColorId)
		then customization.tintColorId :: string else "black"
	VehicleWindowTint.applyTint(
		car,
		CustomizationConfig.TINT_LEVELS[tintLevelId].alpha,
		CustomizationConfig.TINT_COLORS[tintColorId].color
	)
	car:SetAttribute("PersonalTintLevelId", tintLevelId)
	car:SetAttribute("PersonalTintColorId", tintColorId)
	VehicleHeadlightCustomization.configure(
		car,
		customization.headlightColorId,
		customization.headlightBrightnessId,
		customization.headlightEffectId
	)
	VehiclePlateVisibility.apply(car, customization.platesRemoved == true)

	if customization.neonInstalled == true and customization.neonEnabled == true
		and VehicleNeon.isColorId(customization.neonColorId)
	then
		VehicleNeon.applyFinal(car, modelName, customization.neonColorId)
	else
		VehicleNeon.clear(car)
	end
end

setPersonalHeadlights = function(car: Model, enabled: boolean)
	VehicleHeadlightCustomization.setEnabled(car, enabled)
end

local function beginDriveTracking(player: Player, car: Model, seat: VehicleSeat, humanoid: Humanoid, carId: string)
	if enteredThisSession[player] ~= true then
		enteredThisSession[player] = true
		local data = DataService.get(player)
		if data ~= nil and data.analytics.personalCarEnteredAt == nil then
			GameplayEvents.emit("PersonalCarEntered", player, { carId = carId })
		end
	end
	driveTokens[player] = (driveTokens[player] or 0) + 1
	local token = driveTokens[player]
	task.spawn(function()
		local previous = os.clock()
		while player.Parent == Players and car.Parent ~= nil and seat.Occupant == humanoid
			and driveTokens[player] == token and driveMilestoneSent[player] ~= true
		do
			task.wait(0.25)
			local now = os.clock()
			local delta = math.min(0.5, now - previous)
			previous = now
			local chassis = car:FindFirstChild("Chassis")
			if chassis ~= nil and chassis:IsA("BasePart") and chassis.AssemblyLinearVelocity.Magnitude >= 2 then
				personalDriveSeconds[player] = (personalDriveSeconds[player] or 0) + delta
			end
			if (personalDriveSeconds[player] or 0) >= 60 then
				driveMilestoneSent[player] = true
				local data = DataService.get(player)
				if data ~= nil and data.analytics.personalCarDriven60At == nil then
					GameplayEvents.emit("PersonalCarDriven60Seconds", player, {
						carId = carId,
						driveSeconds = personalDriveSeconds[player],
					})
				end
				break
			end
		end
	end)
end

local function spawnCarForSlot(
	player: Player,
	_data: any,
	garage: Model,
	garageData: any,
	carId: string,
	markerName: string,
	runtimeName: string,
	slotIndex: number
): Model?
	local definition = CATALOG[carId]
	if definition == nil or garageData.owned[carId] ~= true then
		return nil
	end
	local source = ServerStorage:WaitForChild("CarModels"):FindFirstChild(definition.model)
	local marker = garage:FindFirstChild(markerName)
	local runtimeCars = garage:FindFirstChild("RuntimeCars")
	if source == nil or not source:IsA("Model")
		or marker == nil or not marker:IsA("BasePart")
		or runtimeCars == nil
	then
		warn("[PersonalGarage] missing source, marker, or runtime folder for " .. carId)
		return nil
	end

	local clone = source:Clone()
	clone.Name = runtimeName
	clone:SetAttribute("TemplateId", carId)
	clone:SetAttribute("PersonalVehicleGarageSlot", slotIndex)
	clone:SetAttribute("PersonalVehicle", true)
	clone:SetAttribute("PersonalVehicleOwnerUserId", player.UserId)
	clone:SetAttribute("SellProtected", true)
	clone:SetAttribute("NonDealerInventory", true)
	clone:SetAttribute("DealerDriveLocked", false)
	clone:SetAttribute("VehicleRuntimeActive", true)
	clone:SetAttribute("owner", player.UserId)
	clone:SetAttribute("customPlate", string.upper(string.sub(player.Name, 1, 8)))
	if not CollectionService:HasTag(clone, "Car") then
		CollectionService:AddTag(clone, "Car")
	end
	if not CollectionService:HasTag(clone, "ManagedVehicle") then
		CollectionService:AddTag(clone, "ManagedVehicle")
	end
	CarVisuals.applyCondition(clone, {
		Body = true,
		Wheels = true,
		Engine = true,
	}, true, true, true)
	-- Personal cars are permanently repaired collection vehicles. Never let the dealer
	-- damage client manufacture cracked-glass or rusty overlays for them.
	clone:SetAttribute("BrokenAmount", 0)
	clone:SetAttribute("DealerConditionRepaired", true)
	clone:SetAttribute("PersonalDamageVisualsDisabled", true)
	for _, damageTag in { "CarBodyDamageMorph", "RustyCarBrokenMorph" } do
		if CollectionService:HasTag(clone, damageTag) then
			CollectionService:RemoveTag(clone, damageTag)
		end
	end
	for _, rootName in { "_CarDamageVisuals", "_RustyDamageVisuals" } do
		local damageRoot = clone:FindFirstChild(rootName)
		if damageRoot ~= nil then damageRoot:Destroy() end
	end
	applyCustomization(clone, definition.model, customizationFor(garageData, carId))
	setPersonalHeadlights(clone, false)
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("VehicleSeat") then
			descendant.Transparency = 1
			descendant.CastShadow = false
			descendant.Disabled = false
			descendant.CanTouch = true
			local seat = descendant
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				refreshPersonalDrivePrompts(player, clone)
				local occupant = seat.Occupant
				if occupant == nil then
					driveTokens[player] = (driveTokens[player] or 0) + 1
					setPersonalHeadlights(clone, false)
					-- Re-arm after all vehicle-runtime occupant callbacks have settled.
					task.defer(function()
						if clone.Parent ~= nil then refreshPersonalDrivePrompts(player, clone) end
					end)
					task.delay(0.25, function()
						if clone.Parent ~= nil then refreshPersonalDrivePrompts(player, clone) end
					end)
					return
				end
				local driver = Players:GetPlayerFromCharacter(occupant.Parent)
				if driver ~= player or player:GetAttribute("PersonalGarageCustomizing") == true then
					driveTokens[player] = (driveTokens[player] or 0) + 1
					setPersonalHeadlights(clone, false)
					occupant.Sit = false
					occupant:ChangeState(Enum.HumanoidStateType.GettingUp)
				else
					setPersonalHeadlights(clone, true)
					beginDriveTracking(player, clone, seat, occupant, carId)
				end
			end)
		elseif descendant:IsA("ProximityPrompt") and descendant.Name == "DrivePrompt" then
			local prompt = descendant
			prompt.Enabled = false
			prompt.Triggered:Connect(function(triggeringPlayer)
				if triggeringPlayer == player then
					trySeatPersonalOwner(player, clone)
				end
			end)
			prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
				-- Several vehicle lifecycle producers may restore either authored value
				-- after spawn. Reconcile both false and true late writes on the next task
				-- slice so the personal-garage authority always wins without recursion.
				task.defer(function()
					if clone.Parent ~= nil then
						refreshPersonalDrivePrompts(player, clone)
					end
				end)
			end)
		end
	end
	refreshPersonalDrivePrompts(player, clone)
	player:GetAttributeChangedSignal("PersonalGarageCustomizing"):Connect(function()
		if clone.Parent ~= nil then
			refreshPersonalDrivePrompts(player, clone)
		end
	end)
	local respawnConnection = player.CharacterAdded:Connect(function()
		-- The old Humanoid can disappear without a final replicated Occupant edge.
		-- Reconcile the personal-car prompt against the new character explicitly.
		task.delay(0.35, function()
			if clone.Parent ~= nil then
				refreshPersonalDrivePrompts(player, clone)
			end
		end)
	end)
	clone.Destroying:Once(function()
		respawnConnection:Disconnect()
	end)

	local sourcePivot = clone:GetPivot()
	local boxCFrame, boxSize = clone:GetBoundingBox()
	local pivotToBox = sourcePivot:ToObjectSpace(boxCFrame)
	-- CarSpawn is authored 1.6 studs above the garage slab. Do not raycast here:
	-- a downward ray begins above the roof and would faithfully park the car on top of it.
	local groundY = marker.Position.Y - 1.6
	local center = Vector3.new(marker.Position.X, groundY + boxSize.Y * 0.5 + 0.08, marker.Position.Z)
	local wantedBox = CFrame.lookAt(center, center + marker.CFrame.LookVector, Vector3.yAxis)
	clone:PivotTo(wantedBox * pivotToBox:Inverse())
	clone.Parent = runtimeCars

	task.defer(function()
		if clone.Parent == nil then
			return
		end
		for _, descendant in clone:GetDescendants() do
			if descendant:IsA("BasePart") and not descendant.Anchored then
				pcall(function()
					descendant:SetNetworkOwner(player)
				end)
			end
		end
	end)
	return clone
end


local function spawnActiveCar(player: Player): Model?
	-- Replacing a car is also an explicit escape hatch from a partially opened
	-- Customize session. Restore the terminal before destroying locked car instances.
	releaseCustomize(player)
	destroyActiveCar(player)
	local data = DataService.get(player)
	local garage = garageForPlayer(player)
	if data == nil or garage == nil or data.tutorial.completed ~= true
		or data.personalGarage.starterChosen ~= true
	then
		return nil
	end
	local garageData = data.personalGarage
	applyGarageExpansion(garage, garageData.expanded == true, false)
	local activeCarId = garageData.activeCarId
	if typeof(activeCarId) ~= "string" or garageData.owned[activeCarId] ~= true then
		return nil
	end
	local primary = spawnCarForSlot(
		player,
		data,
		garage,
		garageData,
		activeCarId,
		"CarSpawn",
		"Personal_" .. activeCarId,
		1
	)
	activeCars[player] = primary
	if primary ~= nil and garageData.expanded == true then
		local secondaryCarId = garageData.secondaryCarId
		if typeof(secondaryCarId) == "string" and secondaryCarId ~= activeCarId
			and garageData.owned[secondaryCarId] == true
		then
			secondaryCars[player] = spawnCarForSlot(
				player,
				data,
				garage,
				garageData,
				secondaryCarId,
				"CarSpawn2",
				"PersonalSecond_" .. secondaryCarId,
				2
			)
		end
	end
	return primary
end

function PersonalGarageService.restoreAfterRace(player: Player): boolean
	if player.Parent ~= Players then return false end
	releaseCustomize(player)
	local character = player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid ~= nil then
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	-- Rebuild the authored active car so the temporary race car never strands its owner.
	local car = spawnActiveCar(player)
	if car ~= nil then
		summonAt[player] = nil
		local moved = summonActiveCar(player)
		if moved then
			local seat = car:FindFirstChild("DriverSeat", true)
			if seat == nil or not seat:IsA("VehicleSeat") then
				seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
			end
			if humanoid ~= nil and character ~= nil and seat ~= nil and seat:IsA("VehicleSeat") then
				character:PivotTo(seat.CFrame + Vector3.new(0, 3, 0))
				task.wait()
				seat:Sit(humanoid)
			end
			return true
		end
	end

	-- Defensive fallback for legacy/invalid profiles with no personal car.
	local record = TycoonService.getForPlayer(player)
	local garage = if record ~= nil then record.folder:FindFirstChild("PersonalGarage", true) else nil
	local marker = if garage ~= nil then garage:FindFirstChild("CarSpawn", true) else nil
	if character ~= nil and marker ~= nil and marker:IsA("BasePart") then
		character:PivotTo(marker.CFrame * CFrame.new(0, 4, 12))
	end
	return false
end

local function stateFor(player: Player): any
	local data = DataService.get(player)
	if data == nil then
		return {
			tutorialComplete = false,
			starterChosen = false,
			owned = {},
			activeCarId = nil,
			expanded = false,
			secondaryCarId = nil,
			garageCapacity = 1,
			ownedCount = 0,
			overflowCount = 0,
			capacityResolutionRequired = false,
			capacityRefundBonusRate = CAPACITY_REFUND_BONUS_RATE,
			expansionPrice = GARAGE_EXPANSION_PRICE,
			catalog = {},
			customFxEntitled = false,
			customFxAdmin = false,
			customFxGamePassId = CustomizationConfig.customFxGamePassId(),
			customFxPriceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
			plateRemovalEntitled = false,
			plateRemovalAdmin = false,
			plateRemovalGamePassId = CustomizationConfig.customFxGamePassId(),
		}
	end
	local garageData = data.personalGarage
	local overflowCount, totalOwned, capacity = capacityOverflow(garageData)
	local catalog = {}
	local replacementCarId = if typeof(garageData.activeCarId) == "string"
			and garageData.owned[garageData.activeCarId] == true
		then garageData.activeCarId else nil
	local replacementCarName: string? = nil
	local replacementSaleAmount = 0
	if replacementCarId ~= nil then
		local replacementDefinition = CATALOG[replacementCarId]
		local replacementIsFreeStarter = garageData.freeStarterCarId == replacementCarId
		if replacementDefinition ~= nil then
			replacementCarName = replacementDefinition.name
			if not replacementIsFreeStarter then
				replacementSaleAmount = replacementDefinition.sellPrice
					+ salvageFor(customizationFor(garageData, replacementCarId), replacementCarId)
			end
		end
	end
	for _, carId in CATALOG_ORDER do
		local definition = CATALOG[carId]
		local customization = customizationFor(garageData, carId)
		local isFreeStarter = garageData.freeStarterCarId == carId
		local ownsOtherCar = hasOtherOwnedCar(garageData, carId)
		local salvage = if isFreeStarter then 0 else salvageFor(customization, carId)
		local unlocked = DealerCarConfig.isCarUnlocked(definition.template, data.pads)
		local capacityRefund, capacityAcquisitionPaid, capacityCustomizationPaid, capacityRefundBonus = 0, 0, 0, 0
		if garageData.owned[carId] == true then
			capacityRefund, capacityAcquisitionPaid, capacityCustomizationPaid, capacityRefundBonus =
				investmentFor(garageData, carId)
		end
		table.insert(catalog, {
			id = carId,
			name = definition.name,
			price = if garageData.starterChosen ~= true and STARTER_IDS[carId] == true then 0 else definition.price,
			marketPrice = definition.price,
			sellPrice = if isFreeStarter then 0 else definition.sellPrice + salvage,
			baseSellPrice = if isFreeStarter then 0 else definition.sellPrice,
			salvage = salvage,
			freeStarter = isFreeStarter,
			buybackPrice = definition.price,
			capacityRefund = capacityRefund,
			capacityAcquisitionPaid = capacityAcquisitionPaid,
			capacityCustomizationPaid = capacityCustomizationPaid,
			capacityRefundBonus = capacityRefundBonus,
			buyEligible = unlocked and overflowCount == 0 and totalOwned < capacity,
			replacementEligible = unlocked and overflowCount == 0 and totalOwned >= capacity
				and replacementCarId ~= nil and garageData.owned[carId] ~= true,
			replacementCarId = replacementCarId,
			replacementCarName = replacementCarName,
			replacementSaleAmount = replacementSaleAmount,
			buyBlockedReason = if overflowCount > 0 then "RESOLVE GARAGE CAPACITY FIRST"
				elseif totalOwned >= capacity and replacementCarId == nil then "GARAGE FULL"
				else nil,
			sellEligible = garageData.owned[carId] == true and (not isFreeStarter or ownsOtherCar),
			sellBlockedReason = if isFreeStarter and not ownsOtherCar
				then "KEEP UNTIL YOU OWN ANOTHER PERSONAL CAR" else nil,
			customization = copyCustomization(customization),
			owned = garageData.owned[carId] == true,
			active = garageData.activeCarId == carId,
			secondary = garageData.expanded == true and garageData.secondaryCarId == carId,
			parked = garageData.activeCarId == carId
				or (garageData.expanded == true and garageData.secondaryCarId == carId),
			garageSlot = if garageData.activeCarId == carId then 1
				elseif garageData.expanded == true and garageData.secondaryCarId == carId then 2 else nil,
			unlocked = unlocked,
			unlockHint = DealerCarConfig.unlockHint(definition.template),
			starterEligible = STARTER_IDS[carId] == true,
			model = definition.model,
			performance = CustomizationConfig.performanceState(definition.template, customization, definition.price),
		})
	end
	local headlightEffectEntitlements: { [string]: boolean } = {}
	local headlightEffectGamePassIds: { [string]: number } = {}
	for _, effectId in CustomizationConfig.HEADLIGHT_EFFECT_IDS do
		headlightEffectEntitlements[effectId] = headlightEffectEntitled(player, effectId)
		headlightEffectGamePassIds[effectId] = CustomizationConfig.headlightEffectGamePassId(effectId)
	end
	return {
		tutorialComplete = data.tutorial.completed == true,
		starterChosen = garageData.starterChosen == true,
		owned = garageData.owned,
		activeCarId = garageData.activeCarId,
		expanded = garageData.expanded == true,
		secondaryCarId = garageData.secondaryCarId,
		garageCapacity = capacity,
		ownedCount = totalOwned,
		overflowCount = overflowCount,
		capacityResolutionRequired = overflowCount > 0,
		capacityRefundBonusRate = CAPACITY_REFUND_BONUS_RATE,
		expansionPrice = GARAGE_EXPANSION_PRICE,
		cash = data.cash,
		catalog = catalog,
		customizations = copyCustomizations(garageData.customizations),
		customFxEntitled = customFxEntitled(player),
		customFxAdmin = AdminAccess.isAuthorized(player),
		customFxGamePassId = CustomizationConfig.customFxGamePassId(),
		customFxPriceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
		plateRemovalEntitled = plateRemovalEntitled(player),
		plateRemovalAdmin = AdminAccess.isAuthorized(player),
		plateRemovalGamePassId = CustomizationConfig.customFxGamePassId(),
		headlightEffectAdmin = AdminAccess.isAuthorized(player),
		headlightEffectEntitlements = headlightEffectEntitlements,
		headlightEffectGamePassIds = headlightEffectGamePassIds,
		-- Core ownership customization is available immediately. Atelier pads expand
		-- each palette; they no longer hide the category itself.
		unlocks = {
			neon = true,
			nitro = data.pads.TA_NOS == true,
			paint = true,
			tint = true,
			headlights = true,
			stance = data.pads.TA_BodyKitStation == true,
		},
		expandedUnlocks = {
			neon = data.pads.TA_Neon == true,
			paint = data.pads.TA_PaintCanisters == true,
			tint = data.pads.TA_BodyKitStation == true,
			headlights = data.pads.TA_BodyKitStation == true,
		},
		prices = {
			neonInstall = NEON_INSTALL_PRICE,
			neonRecolor = NEON_RECOLOR_PRICE,
			nitroInstall = NITRO_INSTALL_PRICE,
			stanceInstall = CustomizationConfig.STANCE_INSTALL_PRICE,
			headlightColor = CustomizationConfig.HEADLIGHT_COLOR_PRICE,
			headlightSuperBright = CustomizationConfig.HEADLIGHT_SUPER_BRIGHT_PRICE,
			bodyColor = CustomizationConfig.BODY_COLOR_PRICE,
			factoryBodyColor = CustomizationConfig.FACTORY_BODY_COLOR_PRICE,
			tintColor = CustomizationConfig.TINT_COLOR_PRICE,
			tintLevels = {
				["0"] = CustomizationConfig.TINT_LEVELS["0"].price,
				["50"] = CustomizationConfig.TINT_LEVELS["50"].price,
				["100"] = CustomizationConfig.TINT_LEVELS["100"].price,
			},
		},
		palette = table.clone(VehicleNeon.PERSONAL_PALETTE_IDS),
		bodyPalette = CustomizationConfig.bodyPalette(
			if garageData.activeCarId ~= nil and CATALOG[garageData.activeCarId] ~= nil
				then CATALOG[garageData.activeCarId].model else nil
		),
		tintLevels = CustomizationConfig.tintLevels(),
		tintPalette = CustomizationConfig.tintPalette(),
		headlightPalette = CustomizationConfig.headlightPalette(),
		headlightBrightnessLevels = CustomizationConfig.headlightBrightnessLevels(),
		headlightEffects = CustomizationConfig.headlightEffects(),
	}
end

local function capacityPreviewStateFor(player: Player): any
	local preview = stateFor(player)
	if typeof(preview.catalog) ~= "table" or #preview.catalog < 3 then return preview end
	preview.owned = {}
	preview.customizations = {}
	preview.garageCapacity = 1
	preview.ownedCount = 3
	preview.overflowCount = 2
	preview.capacityResolutionRequired = true
	preview.expanded = false
	preview.secondaryCarId = nil
	preview.activeCarId = preview.catalog[1].id
	for index, entry in preview.catalog do
		local selected = index <= 3
		entry.owned = selected
		entry.active = index == 1
		entry.secondary = false
		entry.parked = index == 1
		if selected then
			preview.owned[entry.id] = true
			local acquisition = if index == 1 then 0 else math.max(0, math.floor(tonumber(entry.marketPrice) or 0))
			local customizationPaid = if index == 2 then 75000 else 0
			local investment = acquisition + customizationPaid
			local bonus = math.floor(investment * CAPACITY_REFUND_BONUS_RATE + 0.5)
			entry.capacityAcquisitionPaid = acquisition
			entry.capacityCustomizationPaid = customizationPaid
			entry.capacityRefundBonus = bonus
			entry.capacityRefund = investment + bonus
		end
	end
	return preview
end

local function publish(player: Player)
	local data = DataService.get(player)
	if data ~= nil then
		player:SetAttribute("PersonalGarageStarterChosen", data.personalGarage.starterChosen)
		player:SetAttribute("PersonalGarageActiveCar", data.personalGarage.activeCarId)
		player:SetAttribute("PersonalGarageExpanded", data.personalGarage.expanded == true)
		player:SetAttribute("PersonalGarageSecondaryCar", data.personalGarage.secondaryCarId)
		local overflowCount, totalOwned, capacity = capacityOverflow(data.personalGarage)
		player:SetAttribute("PersonalGarageCapacity", capacity)
		player:SetAttribute("PersonalGarageOwnedCount", totalOwned)
		player:SetAttribute("PersonalGarageOverflow", overflowCount)
	end
	stateEvent:FireClient(player, stateFor(player))
end

local function refreshCustomizePrompt(player: Player?, garage: Model, starterChosen: boolean)
	local terminal = garage:FindFirstChild("CustomizeTerminal", true)
	local prompt = if terminal ~= nil then terminal:FindFirstChildWhichIsA("ProximityPrompt", true) else nil
	if prompt ~= nil then
		prompt.Enabled = starterChosen
			and player ~= nil
			and player:GetAttribute("PersonalGarageCustomizing") ~= true
	end
end

local function syncWorld(player: Player, respawn: boolean)
	local data = DataService.get(player)
	local garage = garageForPlayer(player)
	if garage == nil then return end
	if data == nil then
		-- Keep every garage-only interaction unavailable until loaded profile state is authoritative.
		ensureExpansionInfrastructure(garage)
		applyGarageExpansion(garage, false, false)
		setExpansionPadVisible(garage, false)
		setDoorOpen(garage, false)
		refreshCustomizePrompt(player, garage, false)
		return
	end
	local starterChosen = data.tutorial.completed == true and data.personalGarage.starterChosen == true
	ensureExpansionInfrastructure(garage)
	applyGarageExpansion(garage, starterChosen and data.personalGarage.expanded == true, false)
	setExpansionPadVisible(garage, starterChosen and data.personalGarage.expanded ~= true)
	setDoorOpen(garage, starterChosen)
	refreshCustomizePrompt(player, garage, starterChosen)
	if respawn and starterChosen then
		spawnActiveCar(player)
	elseif not starterChosen then
		destroyActiveCar(player)
	end
	publish(player)
end

local function queueRuntimeSync(player: Player, record: any)
	if runtimeSyncQueued[player] == true then return end
	runtimeSyncQueued[player] = true
	task.defer(function()
		runtimeSyncQueued[player] = nil
		if player.Parent == Players and TycoonService.getForPlayer(player) == record then
			syncWorld(player, true)
		end
	end)
end

local function cloneOwned(owned: { [string]: boolean }): { [string]: boolean }
	local result: { [string]: boolean } = {}
	for carId, value in owned do
		result[carId] = value
	end
	return result
end

local function normalizeGarageAssignments(garageData: any)
	if typeof(garageData.activeCarId) ~= "string" or garageData.owned[garageData.activeCarId] ~= true then
		garageData.activeCarId = nil
		for _, candidateId in CATALOG_ORDER do
			if garageData.owned[candidateId] == true then
				garageData.activeCarId = candidateId
				break
			end
		end
	end
	if garageData.expanded ~= true then
		garageData.secondaryCarId = nil
		return
	end
	if typeof(garageData.secondaryCarId) ~= "string"
		or garageData.secondaryCarId == garageData.activeCarId
		or garageData.owned[garageData.secondaryCarId] ~= true
	then
		garageData.secondaryCarId = nil
		for _, candidateId in CATALOG_ORDER do
			if garageData.owned[candidateId] == true and candidateId ~= garageData.activeCarId then
				garageData.secondaryCarId = candidateId
				break
			end
		end
	end
end

local function applyReplacementPurchase(
	data: any,
	replacedCarId: string,
	targetCarId: string,
	saleAmount: number,
	purchasePrice: number
)
	local garageData = data.personalGarage
	local releasedFreeStarter = garageData.freeStarterCarId == replacedCarId
	garageData.owned[replacedCarId] = nil
	garageData.customizations[replacedCarId] = nil
	if releasedFreeStarter then
		-- Atomic replacement is the only path allowed to release the sole free starter.
		-- It never reopens the one-time starter choice because the paid replacement exists
		-- before the transaction is committed.
		garageData.freeStarterCarId = nil
	end
	if garageData.secondaryCarId == replacedCarId then
		garageData.secondaryCarId = nil
	end
	data.cash += saleAmount
	data.cash -= purchasePrice
	garageData.owned[targetCarId] = true
	local purchasedCustomization = customizationFor(garageData, targetCarId)
	purchasedCustomization.acquisitionPaid = purchasePrice
	purchasedCustomization.customizationPaid = 0
	garageData.activeCarId = targetCarId
	normalizeGarageAssignments(garageData)
	return releasedFreeStarter
end

local function runReplacementContractSelfTest()
	local fakeData = {
		cash = 500000,
		personalGarage = {
			expanded = false,
			owned = { Rusty = true },
			activeCarId = "Rusty",
			secondaryCarId = nil,
			freeStarterCarId = "Rusty",
			customizations = {},
		},
	}
	local releasedFreeStarter = applyReplacementPurchase(
		fakeData,
		"Rusty",
		"RadoBoxlet",
		0,
		PERSONAL_PRICES.RadoBoxlet
	)
	assert(releasedFreeStarter == true, "atomic replacement must release the sole free-starter marker")
	assert(fakeData.personalGarage.owned.Rusty ~= true and fakeData.personalGarage.owned.RadoBoxlet == true,
		"atomic replacement must leave exactly the purchased car")
	assert(fakeData.personalGarage.activeCarId == "RadoBoxlet", "purchased replacement must become active")
	assert(fakeData.cash == 500000 - PERSONAL_PRICES.RadoBoxlet, "replacement cash delta must be sale minus purchase")
	assert(ownedCount(fakeData.personalGarage) == 1, "one-bay replacement must preserve the capacity invariant")
	print("[PersonalGarageReplacementSelfTest] PASS")
end

local function nearCustomizeTerminal(player: Player, garage: Model): boolean
	local terminal = garage:FindFirstChild("CustomizeTerminal", true)
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	return terminal ~= nil and terminal:IsA("BasePart") and root ~= nil and root:IsA("BasePart")
		and (root.Position - terminal.Position).Magnitude <= TERMINAL_DISTANCE
end

local function garageCarForId(player: Player, carId: string): Model?
	for _, car in { activeCars[player], secondaryCars[player] } do
		if car ~= nil and car.Parent ~= nil and car:GetAttribute("TemplateId") == carId then
			return car
		end
	end
	return nil
end

local function activeCarIsParked(player: Player, garage: Model, carId: string): boolean
	local car = activeCars[player]
	return car ~= nil and car.Parent ~= nil and car:IsDescendantOf(garage)
		and car:GetAttribute("TemplateId") == carId
end

local function garageCarIsParked(player: Player, garage: Model, carId: string): boolean
	local car = garageCarForId(player, carId)
	return car ~= nil and car:IsDescendantOf(garage)
end

local function mutateUnsafe(player: Player, action: string, carId: any, payload: any): any
	if mutating[player] == true then
		return { ok = false, message = "Garage is busy.", state = stateFor(player) }
	end
	local data = DataService.get(player)
	if data == nil then
		return { ok = false, message = "Profile is still loading.", state = stateFor(player) }
	end
	if action == "ClaimCustomFxAdminGrant" then
		if not AdminAccess.isAuthorized(player) then
			return { ok = false, message = "Admin access required.", state = stateFor(player) }
		end
		local garageData = data.personalGarage
		if garageData.customFxAdminClaimed == true then
			return { ok = true, message = "Custom FX admin grant already claimed.", state = stateFor(player) }
		end
		garageData.customFxAdminClaimed = true
		if not DataService.commitCritical(player, "custom_fx_admin_grant") then
			garageData.customFxAdminClaimed = false
			return { ok = false, message = "Could not save the admin grant. Try again.", state = stateFor(player) }
		end
		customFxEntitlementCache[player] = { owns = true, checkedAt = os.clock() }
		customFxGrantLogged[player] = true
		local emitted, emitError = xpcall(function()
			GameplayEvents.emit("CustomFxEntitlementGranted", player, {
				gamePassId = CustomizationConfig.customFxGamePassId(),
				priceRobux = 0,
				grantType = "admin_free_claim",
			})
		end, debug.traceback)
		if not emitted then
			warn("[PersonalGarage] admin Custom FX grant analytics failed: " .. tostring(emitError))
		end
		return { ok = true, message = "Custom FX Pass claimed free for admin QA.", state = stateFor(player) }
	end
	if data.tutorial.completed ~= true then
		return { ok = false, message = "Finish the tutorial first.", state = stateFor(player) }
	end
	if TycoonService.getForPlayer(player) == nil then
		return { ok = false, message = "No dealership is assigned.", state = stateFor(player) }
	end
	local unresolvedOverflow = capacityOverflow(data.personalGarage)
	if unresolvedOverflow > 0 and action ~= "PrepareCapacitySell" and action ~= "ConfirmCapacitySell" then
		return {
			ok = false,
			message = string.format("Choose %d excess personal car%s to sell first.", unresolvedOverflow, if unresolvedOverflow == 1 then "" else "s"),
			state = stateFor(player),
		}
	end
	if action == "TeleportToGarage" then
		if player:GetAttribute("RacingActive") == true then
			return { ok = false, message = "Finish the race first.", state = stateFor(player) }
		end
		local record = TycoonService.getForPlayer(player)
		local character = player.Character
		local garage = if record ~= nil then record.folder:FindFirstChild("PersonalGarage", true) else nil
		local garageSpawn = if garage ~= nil then garage:FindFirstChild("CarSpawn", true) else nil
		if character == nil or garageSpawn == nil or not garageSpawn:IsA("BasePart") then
			return { ok = false, message = "Your garage is not ready.", state = stateFor(player) }
		end
		releaseCustomize(player)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		-- CarSpawn faces through the garage door. Move beyond that door onto the
		-- driveway, ground the character, and turn them back toward the garage.
		local outsidePosition = garageSpawn.Position + garageSpawn.CFrame.LookVector * 17
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character, garage }
		local groundHit = workspace:Raycast(
			outsidePosition + Vector3.new(0, 40, 0),
			Vector3.new(0, -100, 0),
			raycastParams
		)
		local groundY = if groundHit ~= nil then groundHit.Position.Y + 3.1 else garageSpawn.Position.Y + 1.2
		local groundedPosition = Vector3.new(outsidePosition.X, groundY, outsidePosition.Z)
		local faceGarage = Vector3.new(garageSpawn.Position.X, groundY, garageSpawn.Position.Z)
		character:PivotTo(CFrame.lookAt(groundedPosition, faceGarage))
		return { ok = true, message = "Teleported in front of your garage.", state = stateFor(player) }
	end
	if action == "Return" then
		spawnActiveCar(player)
		return { ok = true, message = "Car returned to your garage.", state = stateFor(player) }
	end
	if action == "Summon" then
		-- The phone is not reachable during a healthy Customize modal. If this action
		-- arrives, treat it as recovery from a lost/partial client open before moving.
		releaseCustomize(player)
		local ok, message = summonActiveCar(player)
		return { ok = ok, message = message, state = stateFor(player) }
	end
	if action == "TrackCustomFxOffer" then
		local stage = if typeof(payload) == "table" then payload.stage else nil
		local feature = if typeof(payload) == "table" then payload.feature else nil
		if (stage ~= "view" and stage ~= "prompt") or typeof(feature) ~= "string" or CUSTOM_FX_FEATURES[feature] ~= true then
			return { ok = false, message = "Unknown Custom FX analytics marker.", state = stateFor(player) }
		end
		local seen = customFxAnalyticsSeen[player]
		if seen == nil then
			seen = {}
			customFxAnalyticsSeen[player] = seen
		end
		local key = stage .. ":" .. feature
		if seen[key] ~= true then
			seen[key] = true
			GameplayEvents.emit(if stage == "view" then "CustomFxOfferViewed" else "CustomFxPurchasePrompted", player, {
				feature = feature,
				gamePassId = CustomizationConfig.customFxGamePassId(),
				priceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
			})
		end
		return { ok = true, message = "", state = stateFor(player) }
	end
	if action == "RefreshCustomFxEntitlement"
		or action == "RefreshPlateRemovalEntitlement"
		or action == "RefreshHeadlightEffectEntitlement"
	then
		customFxEntitlementCache[player] = nil
		local entitled = customFxEntitled(player)
		if entitled and customFxGrantLogged[player] ~= true then
			customFxGrantLogged[player] = true
			GameplayEvents.emit("CustomFxEntitlementGranted", player, {
				gamePassId = CustomizationConfig.customFxGamePassId(),
				priceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
			})
		end
		return {
			ok = entitled,
			message = if entitled then "Custom FX Pass unlocked." else "Custom FX Pass purchase was not detected.",
			state = stateFor(player),
		}
	end
	if action ~= "BuyExpansion" and (typeof(carId) ~= "string" or CATALOG[carId] == nil) then
		return { ok = false, message = "Unknown personal car.", state = stateFor(player) }
	end
	if action == "PrepareReplacementPurchase" then
		local garageData = data.personalGarage
		local targetCarId = carId :: string
		local targetDefinition = CATALOG[targetCarId]
		local replacementCarId = garageData.activeCarId
		if garageData.starterChosen ~= true then
			return { ok = false, message = "Choose one free starter first.", state = stateFor(player) }
		elseif garageData.owned[targetCarId] == true then
			return { ok = false, message = "You already own that car.", state = stateFor(player) }
		elseif ownedCount(garageData) < garageCapacity(garageData) then
			return { ok = false, message = "A garage bay is open. Buy this car normally.", state = stateFor(player) }
		elseif typeof(replacementCarId) ~= "string" or garageData.owned[replacementCarId] ~= true then
			return { ok = false, message = "Choose a current car before replacing it.", state = stateFor(player) }
		elseif not DealerCarConfig.isCarUnlocked(targetDefinition.template, data.pads) then
			return { ok = false, message = "Unlock " .. DealerCarConfig.unlockHint(targetDefinition.template) .. " first.", state = stateFor(player) }
		end
		local replacementDefinition = CATALOG[replacementCarId]
		if replacementDefinition == nil then
			return { ok = false, message = "The current car is unavailable.", state = stateFor(player) }
		end
		local freeStarter = garageData.freeStarterCarId == replacementCarId
		local replacementBaseValue = if freeStarter then 0 else replacementDefinition.sellPrice
		local replacementUpgradesValue = if freeStarter then 0
			else salvageFor(customizationFor(garageData, replacementCarId), replacementCarId)
		local saleAmount = replacementBaseValue + replacementUpgradesValue
		local replacementGarageBay = if garageData.activeCarId == replacementCarId then 1
			elseif garageData.secondaryCarId == replacementCarId then 2 else nil
		if data.cash + saleAmount < targetDefinition.price then
			local needed = targetDefinition.price - data.cash - saleAmount
			return {
				ok = false,
				message = string.format("You need $%d more after selling %s.", needed, replacementDefinition.name),
				state = stateFor(player),
			}
		end
		local quote: SellQuote = {
			token = HttpService:GenerateGUID(false),
			carId = replacementCarId,
			amount = saleAmount,
			freeStarter = freeStarter,
			expiresAt = os.clock() + SELL_QUOTE_SECONDS,
			kind = "replacement",
			investment = 0,
			bonus = 0,
			targetCarId = targetCarId,
			purchasePrice = targetDefinition.price,
		}
		sellQuotes[player] = quote
		return {
			ok = true,
			message = "",
			quote = {
				token = quote.token,
				replacement = true,
				replacementCarId = replacementCarId,
				replacementCarName = replacementDefinition.name,
				targetCarId = targetCarId,
				targetCarName = targetDefinition.name,
				purchasePrice = targetDefinition.price,
				sellAmount = saleAmount,
				sellCarValue = replacementBaseValue,
				sellUpgradesValue = replacementUpgradesValue,
				garageBay = replacementGarageBay,
				freeStarter = freeStarter,
				netCost = targetDefinition.price - saleAmount,
				balanceAfter = data.cash + saleAmount - targetDefinition.price,
				expiresIn = SELL_QUOTE_SECONDS,
			},
			state = stateFor(player),
		}
	end
	if action == "PrepareCapacitySell" then
		local garageData = data.personalGarage
		local resolvedCarId = carId :: string
		local overflowCount = capacityOverflow(garageData)
		if overflowCount <= 0 then
			return { ok = false, message = "Garage capacity is already resolved.", state = stateFor(player) }
		end
		if garageData.owned[resolvedCarId] ~= true then
			return { ok = false, message = "You do not own that car.", state = stateFor(player) }
		end
		local definition = CATALOG[resolvedCarId]
		local amount, acquisition, customizationPaid, bonus = investmentFor(garageData, resolvedCarId)
		local quote: SellQuote = {
			token = HttpService:GenerateGUID(false),
			carId = resolvedCarId,
			amount = amount,
			freeStarter = garageData.freeStarterCarId == resolvedCarId,
			expiresAt = os.clock() + SELL_QUOTE_SECONDS,
			kind = "capacity",
			investment = acquisition + customizationPaid,
			bonus = bonus,
		}
		sellQuotes[player] = quote
		return {
			ok = true,
			message = "",
			quote = {
				token = quote.token,
				carId = quote.carId,
				carName = definition.name,
				amount = quote.amount,
				freeStarter = quote.freeStarter,
				capacity = true,
				acquisitionPaid = acquisition,
				customizationPaid = customizationPaid,
				investment = quote.investment,
				bonus = quote.bonus,
				bonusRate = CAPACITY_REFUND_BONUS_RATE,
				expiresIn = SELL_QUOTE_SECONDS,
			},
			state = stateFor(player),
		}
	end
	if action == "PrepareSell" then
		local garageData = data.personalGarage
		local resolvedCarId = carId :: string
		if garageData.owned[resolvedCarId] ~= true then
			return { ok = false, message = "You do not own that car.", state = stateFor(player) }
		end
		local freeStarter = garageData.freeStarterCarId == resolvedCarId
		if freeStarter and not hasOtherOwnedCar(garageData, resolvedCarId) then
			return {
				ok = false,
				message = "Keep your free starter until you own another personal car.",
				state = stateFor(player),
			}
		end
		local definition = CATALOG[resolvedCarId]
		local customization = customizationFor(garageData, resolvedCarId)
		local baseValue = if freeStarter then 0 else definition.sellPrice
		local salvage = if freeStarter then 0 else salvageFor(customization, resolvedCarId)
		local quote: SellQuote = {
			token = HttpService:GenerateGUID(false),
			carId = resolvedCarId,
			amount = baseValue + salvage,
			freeStarter = freeStarter,
			expiresAt = os.clock() + SELL_QUOTE_SECONDS,
			kind = "standard",
			investment = 0,
			bonus = 0,
		}
		sellQuotes[player] = quote
		return {
			ok = true,
			message = "",
			quote = {
				token = quote.token,
				carId = quote.carId,
				carName = definition.name,
				amount = quote.amount,
				carValue = baseValue,
				upgradesValue = salvage,
				garageBay = if garageData.activeCarId == resolvedCarId then 1
					elseif garageData.secondaryCarId == resolvedCarId then 2 else nil,
				freeStarter = quote.freeStarter,
				buybackPrice = definition.price,
				expiresIn = SELL_QUOTE_SECONDS,
			},
			state = stateFor(player),
		}
	end
	if action == "Sell" then
		return { ok = false, message = "Sale confirmation is required.", state = stateFor(player) }
	end

	mutating[player] = true
	local garageData = data.personalGarage
	local oldCash = data.cash
	local oldOwned = cloneOwned(garageData.owned)
	local oldActive = garageData.activeCarId
	local oldExpanded = garageData.expanded == true
	local oldSecondary = garageData.secondaryCarId
	local oldStarter = garageData.starterChosen
	local oldFreeStarterCarId = garageData.freeStarterCarId
	local oldCustomizations = copyCustomizations(garageData.customizations)
	local ok = false
	local message = ""
	local failureReason: string? = nil
	local failureNeeded: number? = nil
	local pendingEventName: string? = nil
	local pendingEventPayload: any = nil
	local pendingCustomFxFeature: string? = nil

	if action == "ConfirmReplacementPurchase" then
		local targetDefinition = CATALOG[carId]
		local token = if typeof(payload) == "table" then payload.token else nil
		local quote = sellQuotes[player]
		-- Single-use token: consume before validation so duplicate confirms are inert.
		sellQuotes[player] = nil
		if quote == nil or quote.kind ~= "replacement" or typeof(token) ~= "string"
			or token ~= quote.token or quote.targetCarId ~= carId
		then
			message = "Replacement confirmation expired. Review the purchase again."
		elseif os.clock() > quote.expiresAt then
			message = "Replacement confirmation expired. Review the purchase again."
		elseif garageData.owned[carId] == true then
			message = "You already own that car."
		elseif ownedCount(garageData) < garageCapacity(garageData) then
			message = "Garage capacity changed. Review the purchase again."
		elseif garageData.activeCarId ~= quote.carId or garageData.owned[quote.carId] ~= true then
			message = "Your current car changed. Review the purchase again."
		elseif not DealerCarConfig.isCarUnlocked(targetDefinition.template, data.pads) then
			message = "That car is no longer unlocked."
		else
			local replacedCarId = quote.carId
			local replacedDefinition = CATALOG[replacedCarId]
			local freeStarterRelease = garageData.freeStarterCarId == replacedCarId
			local saleAmount = if freeStarterRelease then 0
				else replacedDefinition.sellPrice + salvageFor(customizationFor(garageData, replacedCarId), replacedCarId)
			if quote.purchasePrice ~= targetDefinition.price or quote.amount ~= saleAmount
				or quote.freeStarter ~= freeStarterRelease
			then
				message = "Replacement values changed. Review the purchase again."
			elseif data.cash + saleAmount < targetDefinition.price then
				message = "Not enough cash after selling your current car."
			else
				applyReplacementPurchase(data, replacedCarId, carId, saleAmount, targetDefinition.price)
				ok = true
				message = string.format(
					"Purchased %s and sold %s for $%d.",
					targetDefinition.name,
					replacedDefinition.name,
					saleAmount
				)
				pendingEventName = "PersonalCarReplaced"
				pendingEventPayload = {
					replacedCarId = replacedCarId,
					purchasedCarId = carId,
					freeStarterRelease = freeStarterRelease,
					saleAmount = saleAmount,
					purchasePrice = targetDefinition.price,
					netCost = targetDefinition.price - saleAmount,
					cashAfter = data.cash,
				}
			end
		end
	elseif action == "ConfirmCapacitySell" then
		local definition = CATALOG[carId]
		local token = if typeof(payload) == "table" then payload.token else nil
		local quote = sellQuotes[player]
		-- Single-use token: consume before any validation/mutation so repeated taps are inert.
		sellQuotes[player] = nil
		local overflowCount = capacityOverflow(garageData)
		if quote == nil or quote.kind ~= "capacity" or typeof(token) ~= "string"
			or token ~= quote.token or quote.carId ~= carId
		then
			message = "Refund confirmation expired. Review the car again."
		elseif os.clock() > quote.expiresAt then
			message = "Refund confirmation expired. Review the car again."
		elseif overflowCount <= 0 then
			message = "Garage capacity is already resolved."
		elseif garageData.owned[carId] ~= true then
			message = "You do not own that car."
		else
			local amount, acquisition, customizationPaid, bonus = investmentFor(garageData, carId)
			if amount ~= quote.amount or acquisition + customizationPaid ~= quote.investment or bonus ~= quote.bonus then
				message = "Car refund changed. Review it again."
			else
				local freeStarterRelease = garageData.freeStarterCarId == carId
				garageData.owned[carId] = nil
				garageData.customizations[carId] = nil
				if freeStarterRelease then garageData.freeStarterCarId = nil end
				data.cash += amount
				normalizeGarageAssignments(garageData)
				ok = true
				message = string.format(
					"Refunded %s: $%d car + $%d current upgrades + $%d goodwill.",
					definition.name,
					acquisition,
					customizationPaid,
					bonus
				)
				pendingEventName = "PersonalCarSold"
				pendingEventPayload = {
					carId = carId,
					capacityRecovery = true,
					freeStarterRelease = freeStarterRelease,
					acquisitionPaid = acquisition,
					customizationPaid = customizationPaid,
					bonus = bonus,
					amount = amount,
					cashAfter = data.cash,
				}
			end
		end
	elseif action == "BuyExpansion" then
		if garageData.starterChosen ~= true then
			message = "Choose your first personal car before expanding the garage."
		elseif garageData.expanded == true then
			message = "Your second garage bay is already built."
		elseif data.cash < GARAGE_EXPANSION_PRICE then
			failureReason = "funds"
			failureNeeded = GARAGE_EXPANSION_PRICE - data.cash
			message = string.format("You need $%d for the second garage bay.", GARAGE_EXPANSION_PRICE)
		else
			data.cash -= GARAGE_EXPANSION_PRICE
			garageData.expanded = true
			-- Buying capacity never chooses a car for the player. The second bay stays empty
			-- until an explicit collection action assigns it.
			garageData.secondaryCarId = nil
			ok = true
			message = "Second garage bay built. Two personal cars now fit in the garage."
			pendingEventName = "PersonalGarageExpanded"
			pendingEventPayload = { cost = GARAGE_EXPANSION_PRICE, cashAfter = data.cash }
		end
	elseif action == "ChooseStarter" then
		if STARTER_IDS[carId] ~= true then
			message = "Choose Rusty or Wronkler as your free starter."
		elseif garageData.starterChosen then
			message = "Your starter has already been chosen."
		else
			garageData.starterChosen = true
			garageData.freeStarterCarId = carId
			garageData.owned[carId] = true
			garageData.activeCarId = carId
			local starterCustomization = customizationFor(garageData, carId)
			starterCustomization.acquisitionPaid = 0
			starterCustomization.customizationPaid = 0
			ok = true
			message = CATALOG[carId].name .. " is now your personal car."
			pendingEventName = "PersonalCarStarterChosen"
			pendingEventPayload = {
				carId = carId,
				price = 0,
				cashAfter = data.cash,
			}
		end
	elseif action == "SetActive" then
		if garageData.owned[carId] ~= true then
			message = "You do not own that car."
		else
			local previousActive = garageData.activeCarId
			if garageData.expanded == true and previousActive ~= carId then
				garageData.secondaryCarId = previousActive
			end
			garageData.activeCarId = carId
			if garageData.secondaryCarId == carId then
				garageData.secondaryCarId = previousActive
			end
			ok = true
			message = CATALOG[carId].name .. " is now the current garage car."
		end
	elseif action == "Buy" then
		local definition = CATALOG[carId]
		if garageData.starterChosen ~= true then
			message = "Choose one free starter first."
		elseif garageData.owned[carId] == true then
			message = "You already own that car."
		elseif ownedCount(garageData) >= garageCapacity(garageData) then
			message = "Build another personal garage bay before buying another car."
		elseif not DealerCarConfig.isCarUnlocked(definition.template, data.pads) then
			message = "Unlock " .. DealerCarConfig.unlockHint(definition.template) .. " first."
		elseif data.cash < definition.price then
			message = "Not enough cash."
		else
			data.cash -= definition.price
			garageData.owned[carId] = true
			local purchasedCustomization = customizationFor(garageData, carId)
			purchasedCustomization.acquisitionPaid = definition.price
			purchasedCustomization.customizationPaid = 0
			if garageData.expanded == true and garageData.activeCarId ~= carId then
				garageData.secondaryCarId = garageData.activeCarId
			end
			garageData.activeCarId = carId
			ok = true
			message = "Purchased " .. definition.name .. "."
		end
	elseif action == "ConfirmSell" then
		local definition = CATALOG[carId]
		local token = if typeof(payload) == "table" then payload.token else nil
		local quote = sellQuotes[player]
		-- Consume before mutating. Save failure or any changed state requires a fresh quote.
		sellQuotes[player] = nil
		if quote == nil or quote.kind ~= "standard" or typeof(token) ~= "string" or token ~= quote.token or quote.carId ~= carId then
			message = "Sale confirmation expired. Review the car again."
		elseif os.clock() > quote.expiresAt then
			message = "Sale confirmation expired. Review the car again."
		elseif garageData.owned[carId] ~= true then
			message = "You do not own that car."
		else
			local freeStarterRelease = garageData.freeStarterCarId == carId
			if freeStarterRelease and not hasOtherOwnedCar(garageData, carId) then
				message = "Keep your free starter until you own another personal car."
			else
				local customization = customizationFor(garageData, carId)
				local baseValue = if freeStarterRelease then 0 else definition.sellPrice
				local salvage = if freeStarterRelease then 0 else salvageFor(customization, carId)
				local amount = baseValue + salvage
				if amount ~= quote.amount or freeStarterRelease ~= quote.freeStarter then
					message = "Car value changed. Review the sale again."
				else
					garageData.owned[carId] = nil
					garageData.customizations[carId] = nil
					if freeStarterRelease then
						-- Releasing the original free grant never reopens one-time starter onboarding.
						garageData.freeStarterCarId = nil
					end
					data.cash += amount
					if garageData.secondaryCarId == carId then
						garageData.secondaryCarId = nil
					end
					if garageData.activeCarId == carId then
						local promoted = garageData.secondaryCarId
						garageData.activeCarId = nil
						garageData.secondaryCarId = nil
						if typeof(promoted) == "string" and garageData.owned[promoted] == true then
							garageData.activeCarId = promoted
						else
							for _, candidateId in CATALOG_ORDER do
								if garageData.owned[candidateId] == true then
									garageData.activeCarId = candidateId
									break
								end
							end
						end
					end
					ok = true
					message = if freeStarterRelease
						then definition.name .. " released for $0. Your other personal car is now active."
						else string.format("Sold %s for $%d ($%d base + $%d upgrades).", definition.name, amount, baseValue, salvage)
					pendingEventName = "PersonalCarSold"
					pendingEventPayload = {
						carId = carId,
						freeStarterRelease = freeStarterRelease,
						baseValue = baseValue,
						salvageValue = salvage,
						amount = amount,
						cashAfter = data.cash,
					}
				end
			end
		end
	elseif action == "UpgradePerformance" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local definition = CATALOG[carId]
		local requestedStat = if typeof(payload) == "table" then payload.statId else nil
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif not CustomizationConfig.isPerformanceStatId(requestedStat) then
			message = "Choose a valid performance upgrade."
		else
			local statId = requestedStat :: string
			local levelKey = if statId == "acceleration" then "accelerationLevel"
				elseif statId == "top_speed" then "topSpeedLevel" else "handlingLevel"
			local currentLevel = CustomizationConfig.performanceLevel(customization[levelKey])
			local maxLevel = CustomizationConfig.performanceMaxLevel(definition.template, statId)
			if maxLevel == 0 then
				message = CustomizationConfig.PERFORMANCE_STATS[statId].label .. " is already 10/10."
			elseif currentLevel >= maxLevel then
				message = CustomizationConfig.PERFORMANCE_STATS[statId].label .. " is already level 3."
			else
				local nextLevel = currentLevel + 1
				local cost = CustomizationConfig.performanceUpgradePrice(definition.price, nextLevel)
				if data.cash < cost then
					message = "Not enough cash."
				else
					data.cash -= cost
					customization[levelKey] = nextLevel
					ok = true
					message = string.format(
						"%s upgraded to level %d for $%d.",
						CustomizationConfig.PERFORMANCE_STATS[statId].label,
						nextLevel,
						cost
					)
					pendingEventName = "PersonalCarCustomized"
					pendingEventPayload = {
						carId = carId,
						operation = "performance_" .. statId,
						level = nextLevel,
						cost = cost,
						cashAfter = data.cash,
					}
				end
			end
		end
	elseif action == "ApplyBodyColor" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local definition = CATALOG[carId]
		local modelName = if definition ~= nil then definition.model else nil
		local requestedColor = if typeof(payload) == "table" then payload.colorId else nil
		local resolvedColor = if requestedColor == "factory"
			then CustomizationConfig.defaultBodyColorIdForModel(modelName) else requestedColor
		local factoryPaintId = CustomizationConfig.factoryPaintId(resolvedColor)
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_PaintCanisters ~= true
			and factoryPaintId == nil
			and customization.ownedBodyColorIds[resolvedColor] ~= true
		then
			message = "Unlock Paint Canisters in the Tuning Atelier for universal colors."
		elseif not CustomizationConfig.hasBodyPalette(modelName) then
			message = "Body color selection is not available for this car."
		elseif not CustomizationConfig.isBodySelectionIdForModel(resolvedColor, modelName) then
			message = "Choose a valid body color."
		else
			local paidColorId = resolvedColor :: string
			local includedBodyColorId = CustomizationConfig.defaultBodyColorIdForModel(modelName)
			local colorPrice = if paidColorId == includedBodyColorId then 0
				elseif factoryPaintId ~= nil then CustomizationConfig.FACTORY_BODY_COLOR_PRICE
				else CustomizationConfig.BODY_COLOR_PRICE
			local cost = if customization.ownedBodyColorIds[paidColorId] == true then 0 else colorPrice
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				if paidColorId ~= nil then customization.ownedBodyColorIds[paidColorId] = true end
				customization.bodyColorId = resolvedColor
				ok = true
				message = if cost > 0 then string.format("Body color purchased for $%d.", cost)
					elseif factoryPaintId ~= nil then "Owned factory color selected." else "Body color selected."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "body_color_purchase" else "body_color_select",
					cost = cost,
					colorId = resolvedColor,
					cashAfter = data.cash,
				}
			end
		end
	elseif action == "ApplyTintSetup" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedLevel = if typeof(payload) == "table" then payload.levelId else nil
		local requestedColor = if typeof(payload) == "table" then payload.colorId else nil
		local starterOrOwnedLevel = CustomizationConfig.isStarterTintLevelId(requestedLevel)
			or (typeof(requestedLevel) == "string" and customization.ownedTintLevelIds[requestedLevel] == true)
		local starterOrOwnedColor = CustomizationConfig.isStarterTintColorId(requestedColor)
			or (typeof(requestedColor) == "string" and customization.ownedTintColorIds[requestedColor] == true)
		local customFxTint = CustomizationConfig.isCustomFxTintLevel(requestedLevel)
		local customFxTintAllowed = customFxTint and (
			customFxEntitled(player)
				or (typeof(requestedLevel) == "string" and customization.ownedTintLevelIds[requestedLevel] == true)
		)
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif customFxTint and not customFxTintAllowed then
			message = if CustomizationConfig.customFxGamePassId() > 0
				then "Unlock 100% Tint with the Custom FX Pass first."
				else "The Custom FX Pass is not configured yet."
		elseif data.pads.TA_BodyKitStation ~= true and not customFxTintAllowed
			and (not starterOrOwnedLevel or not starterOrOwnedColor)
		then
			message = "Unlock the Body Kit Station in the Tuning Atelier for more tint options."
		elseif not CustomizationConfig.isTintLevelId(requestedLevel) or not CustomizationConfig.isTintColorId(requestedColor) then
			message = "Choose a valid tint level and color."
		else
			local levelId = requestedLevel :: string
			local colorId = requestedColor :: string
			local levelCost = if customFxTintAllowed or customization.ownedTintLevelIds[levelId] == true
				then 0 else CustomizationConfig.TINT_LEVELS[levelId].price
			local colorCost = if customization.ownedTintColorIds[colorId] == true then 0 else CustomizationConfig.TINT_COLORS[colorId].price
			local cost = levelCost + colorCost
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.ownedTintLevelIds[levelId] = true
				customization.ownedTintColorIds[colorId] = true
				customization.tintLevelId = levelId
				customization.tintColorId = colorId
				ok = true
				message = if cost > 0 then string.format("Tint purchased for $%d.", cost) else "Tint applied."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "tint_setup_purchase" else "tint_setup_select",
					cost = cost,
					levelId = levelId,
					colorId = colorId,
					customFxFeature = if customFxTint then "tint_100" else nil,
					cashAfter = data.cash,
				}
				if customFxTint then pendingCustomFxFeature = "tint_100" end
			end
		end
	elseif action == "ApplyTintLevel" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedLevel = if typeof(payload) == "table" then payload.levelId else nil
		local customFxTint = CustomizationConfig.isCustomFxTintLevel(requestedLevel)
		local customFxTintAllowed = customFxTint and (
			customFxEntitled(player)
				or (typeof(requestedLevel) == "string" and customization.ownedTintLevelIds[requestedLevel] == true)
		)
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif customFxTint and not customFxTintAllowed then
			message = if CustomizationConfig.customFxGamePassId() > 0
				then "Unlock 100% Tint with the Custom FX Pass first."
				else "The Custom FX Pass is not configured yet."
		elseif data.pads.TA_BodyKitStation ~= true and not customFxTintAllowed
			and not CustomizationConfig.isStarterTintLevelId(requestedLevel)
			and not (typeof(requestedLevel) == "string" and customization.ownedTintLevelIds[requestedLevel] == true)
		then
			message = "Unlock the Body Kit Station in the Tuning Atelier for more tint levels."
		elseif not CustomizationConfig.isTintLevelId(requestedLevel) then
			message = "Choose a valid tint level."
		else
			local levelId = requestedLevel :: string
			local cost = if customFxTintAllowed or customization.ownedTintLevelIds[levelId] == true
				then 0 else CustomizationConfig.TINT_LEVELS[levelId].price
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.ownedTintLevelIds[levelId] = true
				customization.tintLevelId = levelId
				ok = true
				message = if cost > 0 then string.format("%s tint purchased for $%d.", CustomizationConfig.TINT_LEVELS[levelId].label, cost)
					else CustomizationConfig.TINT_LEVELS[levelId].label .. " tint selected."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "tint_level_purchase" else "tint_level_select",
					cost = cost,
					levelId = levelId,
					customFxFeature = if customFxTint then "tint_100" else nil,
					cashAfter = data.cash,
				}
				if customFxTint then pendingCustomFxFeature = "tint_100" end
			end
		end
	elseif action == "ApplyTintColor" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedColor = if typeof(payload) == "table" then payload.colorId else nil
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_BodyKitStation ~= true
			and not CustomizationConfig.isStarterTintColorId(requestedColor)
			and not (typeof(requestedColor) == "string" and customization.ownedTintColorIds[requestedColor] == true)
		then
			message = "Unlock the Body Kit Station in the Tuning Atelier for more tint colors."
		elseif not CustomizationConfig.isTintColorId(requestedColor) then
			message = "Choose a valid tint color."
		else
			local colorId = requestedColor :: string
			local cost = if customization.ownedTintColorIds[colorId] == true
				then 0 else CustomizationConfig.TINT_COLORS[colorId].price
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.ownedTintColorIds[colorId] = true
				customization.tintColorId = colorId
				ok = true
				message = if cost > 0 then string.format("Tint color purchased for $%d.", cost) else "Tint color selected."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "tint_color_purchase" else "tint_color_select",
					cost = cost,
					colorId = colorId,
					cashAfter = data.cash,
				}
			end
		end
	elseif action == "ApplyHeadlights" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedColor = if typeof(payload) == "table" then payload.colorId else nil
		local requestedBrightness = if typeof(payload) == "table" then payload.brightnessId else nil
		local requestedEffect = if typeof(payload) == "table" then payload.effectId else nil
		local premiumHeadlightEffect = typeof(requestedEffect) == "string" and requestedEffect ~= "steady"
		local premiumHeadlightEntitled = premiumHeadlightEffect
			and CustomizationConfig.isHeadlightEffectId(requestedEffect)
			and headlightEffectEntitled(player, requestedEffect :: string)
		local starterOrOwnedHeadlightSetup = (
			CustomizationConfig.isStarterHeadlightColorId(requestedColor)
				or (typeof(requestedColor) == "string" and customization.ownedHeadlightColorIds[requestedColor] == true)
		) and (
			requestedBrightness == "standard"
				or (typeof(requestedBrightness) == "string" and customization.ownedHeadlightBrightnessIds[requestedBrightness] == true)
		) and requestedEffect == "steady"
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_BodyKitStation ~= true and not starterOrOwnedHeadlightSetup and not premiumHeadlightEntitled then
			message = "Unlock the Body Kit Station in the Tuning Atelier for more headlight options."
		elseif not CustomizationConfig.isHeadlightColorId(requestedColor)
			or not CustomizationConfig.isHeadlightBrightnessId(requestedBrightness)
			or not CustomizationConfig.isHeadlightEffectId(requestedEffect)
		then
			message = "Choose a valid headlight color, brightness, and effect."
		elseif not headlightEffectEntitled(player, requestedEffect :: string) then
			message = if CustomizationConfig.customFxGamePassId() > 0
				then "Unlock that headlight effect with the Custom FX Pass first."
				else "The Custom FX Pass is not configured yet."
		else
			local effectId = requestedEffect :: string
			local colorId = CustomizationConfig.canonicalHeadlightColorId(requestedColor, effectId)
			local brightnessId = requestedBrightness :: string
			local colorCost = if effectId == "rainbow" or customization.ownedHeadlightColorIds[colorId] == true
				then 0 else CustomizationConfig.HEADLIGHT_COLORS[colorId].price
			local brightnessCost = if customization.ownedHeadlightBrightnessIds[brightnessId] == true
				then 0 else CustomizationConfig.HEADLIGHT_BRIGHTNESS[brightnessId].price
			local cost = colorCost + brightnessCost
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.ownedHeadlightColorIds[colorId] = true
				customization.ownedHeadlightBrightnessIds[brightnessId] = true
				customization.headlightColorId = colorId
				customization.headlightBrightnessId = brightnessId
				customization.headlightEffectId = effectId
				ok = true
				message = if cost > 0 then string.format("Headlight setup purchased for $%d.", cost)
					else "Headlight setup selected."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "headlight_purchase" else "headlight_select",
					cost = cost,
					colorId = colorId,
					brightnessId = brightnessId,
					effectId = effectId,
					customFxFeature = if effectId ~= "steady" then "headlight_" .. effectId else nil,
					cashAfter = data.cash,
				}
				if effectId ~= "steady" then pendingCustomFxFeature = "headlight_" .. effectId end
			end
		end
	elseif action == "ApplyStance" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedEnabled = if typeof(payload) == "table" then payload.enabled else nil
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_BodyKitStation ~= true then
			message = "Unlock the Body Kit Station in the Tuning Atelier first."
		elseif typeof(requestedEnabled) ~= "boolean" then
			message = "Choose whether to enable or disable stance."
		elseif customization.stanceInstalled ~= true and requestedEnabled ~= true then
			message = "Install the stance kit first."
		else
			local cost = if customization.stanceInstalled == true then 0 else CustomizationConfig.STANCE_INSTALL_PRICE
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.stanceInstalled = true
				customization.stanceEnabled = requestedEnabled
				ok = true
				message = if cost > 0 then string.format("Stance kit installed for $%d.", cost)
					elseif requestedEnabled then "Negative stance enabled." else "Stock wheel stance restored."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost > 0 then "stance_install" elseif requestedEnabled then "stance_enable" else "stance_disable",
					cost = cost,
					cashAfter = data.cash,
				}
			end
		end
	elseif action == "SetPlatesRemoved" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedRemoved = if typeof(payload) == "table" then payload.removed else nil
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif typeof(requestedRemoved) ~= "boolean" then
			message = "Choose whether to remove or restore the plates."
		elseif not plateRemovalEntitled(player) then
			message = if CustomizationConfig.customFxGamePassId() > 0
				then "Unlock Plate Delete with the Custom FX Pass first."
				else "The Custom FX Pass is not configured yet."
		else
			customization.platesRemoved = requestedRemoved
			ok = true
			message = if requestedRemoved then "License plates removed." else "License plates restored."
			pendingEventName = "PersonalCarCustomized"
			pendingEventPayload = {
				carId = carId,
				operation = if requestedRemoved then "plate_remove" else "plate_restore",
				cost = 0,
				customFxFeature = "plate_delete",
				cashAfter = data.cash,
			}
			pendingCustomFxFeature = "plate_delete"
		end
	elseif action == "ApplyNeon" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		local requestedColor = if typeof(payload) == "table" then payload.colorId else nil
		local requestedEnabled = if typeof(payload) == "table" then payload.enabled else nil
		local rainbowNeon = requestedColor == VehicleNeon.RAINBOW_COLOR_ID
		local rainbowNeonEntitled = rainbowNeon and customFxEntitled(player)
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_Neon ~= true
			and not rainbowNeonEntitled
			and not CustomizationConfig.isStarterNeonColorId(requestedColor)
			and customization.neonColorId ~= requestedColor
		then
			message = "Unlock Neon Light Strips in the Tuning Atelier for more colors."
		elseif not VehicleNeon.isColorId(requestedColor) or typeof(requestedEnabled) ~= "boolean" then
			message = "Choose a valid neon color."
		elseif rainbowNeon and not rainbowNeonEntitled then
			message = if CustomizationConfig.customFxGamePassId() > 0
				then "Unlock Rainbow Neon with the Custom FX Pass first."
				else "The Custom FX Pass is not configured yet."
		else
			local cost = if rainbowNeonEntitled then 0
				elseif customization.neonInstalled ~= true then NEON_INSTALL_PRICE
				elseif customization.neonColorId ~= requestedColor then NEON_RECOLOR_PRICE else 0
			if data.cash < cost then
				message = "Not enough cash."
			else
				data.cash -= cost
				customization.neonInstalled = true
				customization.neonColorId = requestedColor
				customization.neonEnabled = requestedEnabled
				ok = true
				message = if cost > 0 then string.format("Neon applied for $%d.", cost) else "Neon updated."
				pendingEventName = "PersonalCarCustomized"
				pendingEventPayload = {
					carId = carId,
					operation = if cost == NEON_INSTALL_PRICE then "neon_install" elseif cost > 0 then "neon_recolor" else "neon_toggle",
					cost = cost,
					colorId = requestedColor,
					enabled = requestedEnabled,
					customFxFeature = if rainbowNeon then "rainbow_neon" else nil,
					cashAfter = data.cash,
				}
				if rainbowNeon then pendingCustomFxFeature = "rainbow_neon" end
			end
		end
	elseif action == "InstallNitro" then
		local garage = garageForPlayer(player)
		local customization = customizationFor(garageData, carId)
		if garage == nil or not garageCarIsParked(player, garage, carId) or not nearCustomizeTerminal(player, garage) then
			message = "Keep that car in your garage and use the Customize terminal."
		elseif data.pads.TA_NOS ~= true then
			message = "Unlock the NOS Station in the Tuning Atelier first."
		elseif customization.nitroInstalled == true then
			message = "Nitro is already installed."
		elseif data.cash < NITRO_INSTALL_PRICE then
			message = "Not enough cash."
		else
			data.cash -= NITRO_INSTALL_PRICE
			customization.nitroInstalled = true
			ok = true
			message = "Nitro installed permanently."
			pendingEventName = "PersonalCarCustomized"
			pendingEventPayload = {
				carId = carId,
				operation = "nitro_install",
				cost = NITRO_INSTALL_PRICE,
				cashAfter = data.cash,
			}
		end
	else
		message = "Unknown garage action."
	end

	if ok then
		local committed = DataService.commitCritical(player, "personal_garage_" .. string.lower(action))
		if not committed then
			data.cash = oldCash
			garageData.owned = oldOwned
			garageData.activeCarId = oldActive
			garageData.expanded = oldExpanded
			garageData.secondaryCarId = oldSecondary
			garageData.starterChosen = oldStarter
			garageData.freeStarterCarId = oldFreeStarterCarId
			garageData.customizations = oldCustomizations
			ok = false
			message = "Could not save that change. Try again."
		else
			-- The critical save is already authoritative. Analytics, cash mirrors and world
			-- respawns are post-commit receipts: a failure here must be logged, never returned
			-- as "Garage action failed" after the player has already paid.
			local cashSynced, cashSyncError = xpcall(function()
				TycoonService.syncCash(player)
			end, debug.traceback)
			if not cashSynced then
				warn("[PersonalGarage] post-commit cash sync failed: " .. tostring(cashSyncError))
			end
			if pendingEventName ~= nil then
				local eventEmitted, eventError = xpcall(function()
					GameplayEvents.emit(pendingEventName, player, pendingEventPayload)
				end, debug.traceback)
				if not eventEmitted then
					warn("[PersonalGarage] post-commit event failed: " .. tostring(eventError))
				end
			end
			if pendingCustomFxFeature ~= nil then
				local customFxEmitted, customFxError = xpcall(function()
					GameplayEvents.emit("CustomFxUsed", player, {
						feature = pendingCustomFxFeature,
						carId = carId,
						gamePassId = CustomizationConfig.customFxGamePassId(),
						priceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
					})
				end, debug.traceback)
				if not customFxEmitted then
					warn("[PersonalGarage] post-commit Custom FX event failed: " .. tostring(customFxError))
				end
			end
			local worldSynced, worldSyncError = xpcall(function()
				if action == "ApplyNeon" or action == "InstallNitro" or action == "ApplyBodyColor"
					or action == "ApplyTintSetup" or action == "ApplyTintLevel" or action == "ApplyTintColor" or action == "ApplyHeadlights"
					or action == "ApplyStance" or action == "SetPlatesRemoved" or action == "UpgradePerformance"
				then
					local car = garageCarForId(player, carId)
					if car ~= nil and car.Parent ~= nil then
						applyCustomization(car, CATALOG[carId].model, customizationFor(garageData, carId))
					end
				else
					if action == "ChooseStarter" then
						player:SetAttribute("PersonalGarageUpdateOffer", false)
					end
					local garage = garageForPlayer(player)
					if garage ~= nil then
						setDoorOpen(garage, garageData.starterChosen == true)
						refreshCustomizePrompt(player, garage, garageData.starterChosen == true)
						if action == "BuyExpansion" then
							setExpansionPadVisible(garage, false)
							applyGarageExpansion(garage, true, true)
						else
							applyGarageExpansion(garage, garageData.expanded == true, false)
							setExpansionPadVisible(garage, garageData.starterChosen == true and garageData.expanded ~= true)
						end
					end
					if garageData.starterChosen == true then
						if action == "BuyExpansion" then
							task.delay(GARAGE_EXPANSION_BUILD_TIME + 0.08, function()
								if player.Parent == Players then spawnActiveCar(player) end
							end)
						else
							spawnActiveCar(player)
						end
					else
						destroyActiveCar(player)
					end
				end
			end, debug.traceback)
			if not worldSynced then
				warn("[PersonalGarage] post-commit world sync failed: " .. tostring(worldSyncError))
			end
		end
	end
	mutating[player] = nil
	publish(player)
	return {
		ok = ok,
		message = message,
		reason = failureReason,
		needed = failureNeeded,
		state = stateFor(player),
	}
end

local function mutate(player: Player, action: string, carId: any, payload: any): any
	local success, response = xpcall(function()
		return mutateUnsafe(player, action, carId, payload)
	end, debug.traceback)
	if success then
		return response
	end

	-- A failed post-commit side effect must never brick every later garage action for
	-- the rest of the session. The unsafe path owns rollback for normal save failures;
	-- this guard is the final lock cleanup for unexpected runtime exceptions.
	mutating[player] = nil
	warn(string.format("[PersonalGarage] action %s failed for %s: %s", tostring(action), player.Name, tostring(response)))
	return {
		ok = false,
		message = "Garage action failed. Please try again.",
		state = stateFor(player),
	}
end

-- Read-only bridge for server systems that consume the owner-only driving runtime.
-- TrackActivityService never reaches into this module's private activeCars table directly.
function PersonalGarageService.getActiveCar(player: Player): Model?
	local car = activeCars[player]
	return if car ~= nil and car.Parent ~= nil then car else nil
end

function PersonalGarageService.getActiveCarMarketPrice(player: Player): number?
	local data = DataService.get(player)
	if data == nil then
		return nil
	end
	local carId = data.personalGarage.activeCarId
	local definition = if typeof(carId) == "string" then CATALOG[carId] else nil
	return if definition ~= nil then definition.price else nil
end

function PersonalGarageService.init()
	if RunService:IsStudio() then
		runCapacityContractSelfTest()
		runReplacementContractSelfTest()
	end
	local existingFunction = ReplicatedStorage:FindFirstChild("PersonalGarageRemote")
	if existingFunction ~= nil and not existingFunction:IsA("RemoteFunction") then
		existingFunction:Destroy()
		existingFunction = nil
	end
	if existingFunction == nil then
		existingFunction = Instance.new("RemoteFunction")
		existingFunction.Name = "PersonalGarageRemote"
		existingFunction.Parent = ReplicatedStorage
	end
	remoteFunction = existingFunction :: RemoteFunction

	local existingEvent = ReplicatedStorage:FindFirstChild("PersonalGarageState")
	if existingEvent ~= nil and not existingEvent:IsA("RemoteEvent") then
		existingEvent:Destroy()
		existingEvent = nil
	end
	if existingEvent == nil then
		existingEvent = Instance.new("RemoteEvent")
		existingEvent.Name = "PersonalGarageState"
		existingEvent.Parent = ReplicatedStorage
	end
	stateEvent = existingEvent :: RemoteEvent

	local existingCustomizeEvent = ReplicatedStorage:FindFirstChild("PersonalGarageCustomize")
	if existingCustomizeEvent ~= nil and not existingCustomizeEvent:IsA("RemoteEvent") then
		existingCustomizeEvent:Destroy()
		existingCustomizeEvent = nil
	end
	if existingCustomizeEvent == nil then
		existingCustomizeEvent = Instance.new("RemoteEvent")
		existingCustomizeEvent.Name = "PersonalGarageCustomize"
		existingCustomizeEvent.Parent = ReplicatedStorage
	end
	customizeEvent = existingCustomizeEvent :: RemoteEvent

	local existingCustomFxOfferEvent = ReplicatedStorage:FindFirstChild("CustomFxOfferRequested")
	if existingCustomFxOfferEvent ~= nil and not existingCustomFxOfferEvent:IsA("RemoteEvent") then
		existingCustomFxOfferEvent:Destroy()
		existingCustomFxOfferEvent = nil
	end
	if existingCustomFxOfferEvent == nil then
		existingCustomFxOfferEvent = Instance.new("RemoteEvent")
		existingCustomFxOfferEvent.Name = "CustomFxOfferRequested"
		existingCustomFxOfferEvent.Parent = ReplicatedStorage
	end
	customFxOfferEvent = existingCustomFxOfferEvent :: RemoteEvent

	remoteFunction.OnServerInvoke = function(player: Player, action: any, carId: any, payload: any)
		if action == "CustomizeClientReady" then
			-- The terminal may exist before this LocalScript has connected its event.
			-- Never start a server lock until the client explicitly reports readiness.
			player:SetAttribute("PersonalGarageCustomizeClientReady", true)
			releaseCustomize(player)
			return { ok = true, message = "", state = stateFor(player) }
		end
		if action == "ConfirmCustomizeOpen" then
			local token = if typeof(payload) == "table" then payload.token else nil
			local ticket = customizeTickets[player]
			if typeof(token) == "string" and ticket ~= nil and ticket.token == token
				and player:GetAttribute("PersonalGarageCustomizing") == true
			then
				ticket.confirmed = true
				return { ok = true, message = "", state = stateFor(player) }
			end
			releaseCustomize(player)
			return { ok = false, message = "Customize session expired.", state = stateFor(player) }
		end
		if action == "CloseCustomize" then
			releaseCustomize(player)
			return { ok = true, message = "", state = stateFor(player) }
		end
		local now = os.clock()
		if now - (requestAt[player] or 0) < 0.12 then
			return { ok = false, message = "Slow down.", state = stateFor(player) }
		end
		requestAt[player] = now
		if action == "GetState" then
			return { ok = true, message = "", state = stateFor(player) }
		end
		if action == "QAPreviewCapacity" and RunService:IsStudio() and AdminAccess.isAuthorized(player) then
			local preview = capacityPreviewStateFor(player)
			stateEvent:FireClient(player, preview)
			return { ok = true, message = "Studio capacity preview.", state = preview }
		end
		if typeof(action) ~= "string" then
			return { ok = false, message = "Invalid request.", state = stateFor(player) }
		end
		return mutate(player, action, carId, payload)
	end

	local function bindTerminal(record: any)
		local garage = garageForRecord(record)
		local terminal = if garage ~= nil then garage:FindFirstChild("CustomizeTerminal", true) else nil
		local prompt = if terminal ~= nil then terminal:FindFirstChildWhichIsA("ProximityPrompt", true) else nil
		if garage == nil or prompt == nil or prompt:GetAttribute("PersonalGarageBound") == true then return end
		prompt:SetAttribute("PersonalGarageBound", true)
		prompt.Triggered:Connect(function(player: Player)
			local data = DataService.get(player)
			local ownerRecord = TycoonService.getForPlayer(player)
			local carId = if data ~= nil then data.personalGarage.activeCarId else nil
			if ownerRecord ~= record or data == nil or data.tutorial.completed ~= true or typeof(carId) ~= "string"
				or not nearCustomizeTerminal(player, garage)
				or player:GetAttribute("PersonalGarageCustomizeClientReady") ~= true
			then return end

			-- The owner is already standing at the terminal. Bring only the gameplay
			-- vehicle lifecycle back to its authored bay before opening Customize.
			if not activeCarIsParked(player, garage, carId) then
				if player:GetAttribute("RacingActive") == true then return end
				local returnedCar = spawnActiveCar(player)
				if returnedCar == nil or not activeCarIsParked(player, garage, carId) then return end
			end

			local token = HttpService:GenerateGUID(false)
			local ticket: CustomizeTicket = { token = token, confirmed = false }
			customizeTickets[player] = ticket
			player:SetAttribute("PersonalGarageCustomizing", true)
			lockCarEntry(player, activeCars[player])
			customizeEvent:FireClient(player, stateFor(player), activeCars[player], garage, token)
			task.delay(CUSTOMIZE_OPEN_ACK_TIMEOUT, function()
				if customizeTickets[player] == ticket and not ticket.confirmed then
					-- A lost event or client initialization error must never strand walls,
					-- terminal prompts, Drive prompts, or VehicleSeats in Customize state.
					releaseCustomize(player)
				end
			end)
		end)
	end

	local function bindExpansionPad(record: any)
		local garage = garageForRecord(record)
		if garage == nil then return end
		local pad = ensureExpansionInfrastructure(garage)
		if pad == nil or pad:GetAttribute("PersonalGarageExpansionBound") == true then return end
		pad:SetAttribute("PersonalGarageExpansionBound", true)
		local lastTouch = 0
		pad.Touched:Connect(function(hit: BasePart)
			if not pad.CanTouch then return end
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = if character ~= nil then Players:GetPlayerFromCharacter(character) else nil
			if player == nil or TycoonService.getForPlayer(player) ~= record then return end
			local now = os.clock()
			if now - lastTouch < 0.8 then return end
			lastTouch = now
			local response = mutate(player, "BuyExpansion", nil, nil)
			if response.ok ~= true and response.reason == "funds"
				and typeof(response.needed) == "number" and response.needed > 0
			then
				-- Reuse the common authoritative pad-touch feedback DTO; purchase authority and
				-- the $2.5M server constant remain in mutateUnsafe above.
				Remotes.InsufficientFunds:FireClient(player, {
					reason = "funds",
					needed = response.needed,
					title = "SECOND GARAGE BAY",
					surface = "purchasePad",
					padId = GARAGE_EXPANSION_PAD_ID,
					pad = pad,
				})
			end
		end)
	end

	local function bindCustomFxOfferPad(record: any)
		local folder = record.folder
		local buildings = if folder ~= nil then folder:FindFirstChild("Buildings") else nil
		local junkFolder = if buildings ~= nil then buildings:FindFirstChild("JunkSpot") else nil
		local junkModel = if junkFolder ~= nil then junkFolder:FindFirstChild("JunkSpot") else nil
		if junkModel == nil or not junkModel:IsA("Model") then return end

		local existing = junkFolder:FindFirstChild("CustomFxOfferPad")
		local padModel: Model
		if existing ~= nil and existing:IsA("Model") then
			padModel = existing
		else
			if existing ~= nil then existing:Destroy() end
			local reference = junkModel:FindFirstChild("SalesSignPadBase", true)
			if reference == nil or not reference:IsA("BasePart") then
				reference = junkModel:FindFirstChild("Cash RegisterPadBase", true)
			end
			if reference == nil or not reference:IsA("BasePart") then return end

			padModel = Instance.new("Model")
			padModel.Name = "CustomFxOfferPad"
			padModel:SetAttribute("MonetizationSurface", "CustomFxPass")
			padModel:SetAttribute("PriceRobux", CustomizationConfig.CUSTOM_FX_PRICE_ROBUX)
			padModel.Parent = junkFolder

			local base = Instance.new("Part")
			base.Name = "Base"
			base.Shape = Enum.PartType.Cylinder
			base.Size = Vector3.new(0.3, 6.1, 6.1)
			base.CFrame = reference.CFrame * CFrame.new(0, -10.25, 0)
			base.Anchored = true
			base.CanCollide = false
			base.CanQuery = false
			base.CanTouch = false
			base.CastShadow = false
			base.Material = Enum.Material.SmoothPlastic
			base.Color = Color3.fromRGB(20, 21, 25)
			base.Parent = padModel

			local pad = Instance.new("Part")
			pad.Name = "Pad"
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.56, 5.5, 5.5)
			pad.CFrame = base.CFrame * CFrame.new(0.4, 0, 0)
			pad.Anchored = true
			pad.CanCollide = false
			pad.CanQuery = true
			pad.CanTouch = true
			pad.CastShadow = false
			pad.Material = Enum.Material.Neon
			pad.Color = Color3.fromRGB(255, 62, 166)
			pad.Parent = padModel

			local light = Instance.new("PointLight")
			light.Name = "RainbowGlow"
			light.Brightness = 1.4
			light.Range = 12
			light.Shadows = false
			light.Color = pad.Color
			light.Parent = pad

			local offerAnchor = Instance.new("Attachment")
			offerAnchor.Name = "OfferAnchor"
			offerAnchor.Position = pad.CFrame:VectorToObjectSpace(Vector3.new(0, 5.2, 0))
			offerAnchor.Parent = pad

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "Offer"
			billboard.Adornee = offerAnchor
			-- Scale units make this a real world-space sign: it recedes with distance instead of
			-- behaving like a fixed screen overlay.
			billboard.AlwaysOnTop = false
			billboard.LightInfluence = 0
			billboard.MaxDistance = 46
			billboard.Size = UDim2.fromScale(4.4, 1.8)
			billboard.StudsOffsetWorldSpace = Vector3.zero
			billboard.Parent = padModel

			local panel = Instance.new("Frame")
			panel.Name = "Panel"
			panel.Size = UDim2.fromScale(1, 1)
			panel.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
			panel.BorderSizePixel = 0
			panel.Parent = billboard
			local panelCorner = Instance.new("UICorner")
			panelCorner.CornerRadius = UDim.new(0, 10)
			panelCorner.Parent = panel
			local panelStroke = Instance.new("UIStroke")
			panelStroke.Name = "RainbowStroke"
			panelStroke.Thickness = 2
			panelStroke.Color = Color3.fromRGB(255, 255, 255)
			panelStroke.Parent = panel
			local rainbow = Instance.new("UIGradient")
			rainbow.Name = "Rainbow"
			rainbow.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 64, 64)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 220, 45)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(60, 255, 130)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(54, 210, 255)),
				ColorSequenceKeypoint.new(0.8, Color3.fromRGB(134, 90, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 64, 184)),
			})
			rainbow.Parent = panelStroke

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Position = UDim2.fromScale(0.04, 0.07)
			title.Size = UDim2.fromScale(0.92, 0.28)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBlack
			title.Text = "CUSTOM FX PASS"
			title.TextColor3 = Color3.fromRGB(255, 248, 226)
			title.TextScaled = true
			title.TextSize = 14
			local titleSize = Instance.new("UITextSizeConstraint")
			titleSize.MinTextSize = 8
			titleSize.MaxTextSize = 14
			titleSize.Parent = title
			title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			title.TextStrokeTransparency = 0
			title.Parent = panel

			local subtitle = Instance.new("TextLabel")
			subtitle.Name = "Subtitle"
			subtitle.Position = UDim2.fromScale(0.04, 0.34)
			subtitle.Size = UDim2.fromScale(0.92, 0.18)
			subtitle.BackgroundTransparency = 1
			subtitle.Font = Enum.Font.GothamBold
			subtitle.Text = "6 CAR FX • FOREVER"
			subtitle.TextColor3 = Color3.fromRGB(210, 214, 224)
			subtitle.TextScaled = true
			subtitle.TextSize = 9
			local subtitleSize = Instance.new("UITextSizeConstraint")
			subtitleSize.MinTextSize = 7
			subtitleSize.MaxTextSize = 9
			subtitleSize.Parent = subtitle
			subtitle.Parent = panel

			local price = Instance.new("Frame")
			price.Name = "PriceLine"
			price.AnchorPoint = Vector2.new(0.5, 1)
			price.Position = UDim2.fromScale(0.5, 0.92)
			price.Size = UDim2.fromScale(0.55, 0.34)
			price.BackgroundColor3 = Color3.fromRGB(255, 248, 226)
			price.BorderSizePixel = 0
			price.Parent = panel
			local priceCorner = Instance.new("UICorner")
			priceCorner.CornerRadius = UDim.new(0, 6)
			priceCorner.Parent = price

			local robux = Instance.new("ImageLabel")
			robux.Name = "RobuxIcon"
			robux.AnchorPoint = Vector2.new(0, 0.5)
			robux.Position = UDim2.fromScale(0.12, 0.5)
			robux.Size = UDim2.fromScale(0.2, 0.65)
			robux.BackgroundTransparency = 1
			robux.Image = "rbxasset://textures/ui/RobuxIcon.png"
			robux.ImageColor3 = Color3.fromRGB(7, 8, 10)
			robux.Parent = price

			local amount = Instance.new("TextLabel")
			amount.Name = "Amount"
			amount.Position = UDim2.fromScale(0.34, 0)
			amount.Size = UDim2.fromScale(0.6, 1)
			amount.BackgroundTransparency = 1
			amount.Font = Enum.Font.GothamBlack
			amount.Text = tostring(CustomizationConfig.CUSTOM_FX_PRICE_ROBUX)
			amount.TextColor3 = Color3.fromRGB(7, 8, 10)
			amount.TextScaled = true
			amount.TextSize = 14
			local amountSize = Instance.new("UITextSizeConstraint")
			amountSize.MinTextSize = 8
			amountSize.MaxTextSize = 14
			amountSize.Parent = amount
			amount.TextXAlignment = Enum.TextXAlignment.Left
			amount.Parent = price

			CollectionService:AddTag(padModel, "CustomFxOfferPad")
		end

		local pad = padModel:FindFirstChild("Pad")
		if pad == nil or not pad:IsA("BasePart") or pad:GetAttribute("CustomFxOfferBound") == true then return end
		pad:SetAttribute("CustomFxOfferBound", true)
		local lastTouchByPlayer: { [Player]: number } = {}
		pad.Touched:Connect(function(hit: BasePart)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = if character ~= nil then Players:GetPlayerFromCharacter(character) else nil
			if player == nil or TycoonService.getForPlayer(player) ~= record then return end
			local data = DataService.get(player)
			local adminPreview = AdminAccess.isAuthorized(player)
			if data == nil or customFxEntitled(player)
				or (not adminPreview and data.tutorial.completed ~= true)
			then return end
			local now = os.clock()
			if now - (lastTouchByPlayer[player] or 0) < 2 then return end
			lastTouchByPlayer[player] = now
			customFxOfferEvent:FireClient(player, {
				source = "bundle_pad",
				entitled = customFxEntitled(player),
				gamePassId = CustomizationConfig.customFxGamePassId(),
				priceRobux = CustomizationConfig.CUSTOM_FX_PRICE_ROBUX,
			})
		end)
	end

	local function restoreOwnerFromFolder(record: any)
		local folder = record.folder
		if folder == nil or not folder:IsA("Folder") then return end
		local ownerUserId = folder:GetAttribute("OwnerUserId")
		if typeof(ownerUserId) ~= "number" then return end
		local player = Players:GetPlayerByUserId(ownerUserId)
		if player ~= nil and TycoonService.getForPlayer(player) == record then
			queueRuntimeSync(player, record)
		end
	end

	local function bindOwnerRuntimeRestore(record: any)
		local folder = record.folder
		if folder == nil or not folder:IsA("Folder") then return end
		if folder:GetAttribute("_PersonalGarageOwnerRestoreBound") ~= true then
			folder:SetAttribute("_PersonalGarageOwnerRestoreBound", true)
			folder:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				restoreOwnerFromFolder(record)
			end)
		end
		-- Reconcile immediately as well: the claim may have completed before this service initialized.
		restoreOwnerFromFolder(record)
	end

	TycoonService.tycoonClaimed.Event:Connect(function(_record: any, player: Player)
		bindTerminal(_record)
		bindExpansionPad(_record)
		bindCustomFxOfferPad(_record)
		if player:GetAttribute("_PersonalGarageDoorAttributeBound") ~= true then
			player:SetAttribute("_PersonalGarageDoorAttributeBound", true)
			player:GetAttributeChangedSignal("PersonalGarageStarterChosen"):Connect(function()
				local currentGarage = garageForPlayer(player)
				if currentGarage ~= nil then
					setDoorOpen(currentGarage, player:GetAttribute("PersonalGarageStarterChosen") == true)
				end
			end)
		end
		-- Claim events and the bootstrap audit can meet in the same frame. Coalesce them
		-- into one event-driven restore so the saved cars appear immediately and only once.
		queueRuntimeSync(player, _record)
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: any)
		local garage = garageForRecord(record)
		if garage ~= nil then
			destroyGarageCars(garage)
			applyGarageExpansion(garage, false, false)
			setExpansionPadVisible(garage, false)
			refreshCustomizePrompt(nil, garage, false)
			-- Keep unclaimed Personal Garages physically open. The next owner's
			-- loaded tutorial state is applied before they are moved to the plot,
			-- so returning players never watch a closed door wait for profile load.
			setDoorOpen(garage, true)
		end
	end)
	GameplayEvents.connect("CarSold", function(player: Player)
		task.defer(function()
			if player.Parent == Players then
				syncWorld(player, false)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		releaseCustomize(player)
		player:SetAttribute("PersonalGarageCustomizeClientReady", nil)
		destroyActiveCar(player)
		mutating[player] = nil
		runtimeSyncQueued[player] = nil
		requestAt[player] = nil
		driveTokens[player] = nil
		personalDriveSeconds[player] = nil
		driveMilestoneSent[player] = nil
		enteredThisSession[player] = nil
		summonAt[player] = nil
		customFxEntitlementCache[player] = nil
		customFxAnalyticsSeen[player] = nil
		customFxGrantLogged[player] = nil
		sellQuotes[player] = nil
	end)

	for _, record in TycoonService.getAll() do
		bindTerminal(record)
		bindExpansionPad(record)
		bindCustomFxOfferPad(record)
		bindOwnerRuntimeRestore(record)
		local garage = garageForRecord(record)
		if record.owner ~= nil then
			-- PersonalGarageService can initialize while an existing PlayerAdded claim is
			-- already in flight. Queueing this audit after the listener is connected means
			-- either the claim event or this owned-record pass restores the cars, with no gap.
			queueRuntimeSync(record.owner, record)
		elseif garage ~= nil then
			-- Only clean an actually unclaimed garage. Unconditional cleanup here could run
			-- after the claim listener spawned the saved cars and erase both physical bays.
			destroyGarageCars(garage)
			applyGarageExpansion(garage, false, false)
			setExpansionPadVisible(garage, false)
			refreshCustomizePrompt(nil, garage, false)
			setDoorOpen(garage, true)
		end
	end

	print("[PersonalGarage] online")
end

return PersonalGarageService
