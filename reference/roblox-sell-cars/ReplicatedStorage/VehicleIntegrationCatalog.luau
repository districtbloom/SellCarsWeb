--!strict
-- Additive vehicle data for the ongoing FullJourney migration.
-- Does not start systems, mutate profiles, select trade cars, or change cash formulas.
local Catalog = {}

Catalog.Gblock = table.freeze({
 id = "Gblock",
 displayName = "G-Block",
 bodyStyle = "SUV",
 class = "high",
 tier = "Premium",
 modelName = "Gblock",
 fullModelPath = "ServerStorage.CarModels.Gblock",
 trafficModelPath = "ReplicatedStorage.TrafficCars.Gblock",
 vehicleProfileId = "Gblock",
 damageProfileId = "Gblock",
 damageProfilePath = "ReplicatedStorage.GblockDamageProfile",
 damageMeshName = "Body",
 glassMeshName = "Glass",
 brokenHiddenMeshes = table.freeze({ "L_Headlight3", "LF_TurnSignal" }),
 brokenAmountAttribute = "BrokenAmount",
 bodyDamageTag = "CarBodyDamageMorph",
 crackedGlass = true,
 personalPrice = 3900000,
 dealerBaseCost = 4800,
 dealerBaseValue = 10500,
 antiTheftCost = 3500,
 rarityOneInN = 85, -- legacy rarity label; actual arrival odds come from the active selector
 spawnWeight = 1,
 topSpeedKph = 250,
 accelerationRating = 8.0,
 handlingRating = 7.6,
 physicsForwardMaxSpeed = 164,
 physicsAcceleration = 43,
 performanceReference = "Porschka911",
 fullJourneyUnlockId = "FJ_DEDICATED_WASH_ENCLOSURE",
 fullJourneyUnlockStepObserved = 72, -- diagnostic only; resolve current stable ID below
 legacyUnlockPadId = "CW_BrushMachine",
 factoryColors = table.freeze({
  table.freeze({ id="ObsidianBlack", color=Color3.fromRGB(27,32,38), default=true }),
  table.freeze({ id="PolarWhite", color=Color3.fromRGB(242,241,236) }),
  table.freeze({ id="GarnetRed", color=Color3.fromRGB(125,32,43) }),
 }),
 channels = table.freeze({ personalPurchase=true, racing=true, carIndex=true, dealerRepair=true, streetTraffic=true }),
})

Catalog.ORDER = table.freeze({ "Gblock" })

-- A caller opts in explicitly. The migration's current selection/cash logic is untouched.
function Catalog.fullJourneyUnlockStep(vehicleId: string, entries: {any}): number?
 local spec = (Catalog :: any)[vehicleId]
 if typeof(spec) ~= "table" or typeof(spec.fullJourneyUnlockId) ~= "string" then return nil end
 for _, entry in entries do
  if entry.id == spec.fullJourneyUnlockId and typeof(entry.step) == "number" then return entry.step end
 end
 return nil
end

function Catalog.isFullJourneyUnlocked(vehicleId: string, currentStep: number, entries: {any}): boolean
 local unlockStep = Catalog.fullJourneyUnlockStep(vehicleId, entries)
 return unlockStep ~= nil and currentStep >= unlockStep
end

function Catalog.fullJourneyAdditions(currentStep: number, entries: {any}): {string}
 local result = {}
 for _, id in Catalog.ORDER do
  if Catalog.isFullJourneyUnlocked(id, currentStep, entries) then table.insert(result, id) end
 end
 return result
end

return table.freeze(Catalog)

