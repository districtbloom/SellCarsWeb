--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonService = require(ServerScriptService.TycoonSystem.TycoonService)
local DataService = require(ServerScriptService.TycoonSystem.DataService)
local Remotes = require(ServerScriptService.TycoonSystem.JunkLot.Remotes)

local CarIndexService = {}

local function catalogDto()
	local rows = {}
	for _, template in DealerCarConfig.catalogCars() do
		local afterParts = template.baseValue
		for _, part in DealerCarConfig.PARTS do
			afterParts += part.valueBonus
		end
		table.insert(rows, {
			id = template.id,
			displayName = template.displayName or template.id,
			model = template.model,
			class = template.class,
			baseCost = template.baseCost,
			baseValue = template.baseValue,
			afterParts = afterParts,
			handling = template.handling or "",
			antiTheftCost = template.antiTheftCost or 0,
			unlockHint = DealerCarConfig.unlockHint(template),
			hyper = template.class == "hyper",
		})
	end
	return rows
end

function CarIndexService.unlockedIds(player: Player): { string }
	local data = DataService.get(player)
	return DealerCarConfig.unlockedIds(if data ~= nil then data.pads else nil)
end

function CarIndexService.publish(player: Player, toastUnseen: boolean)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	if data.carIndexSeen == nil then
		data.carIndexSeen = {}
	end
	local unlocked = DealerCarConfig.unlockedIds(data.pads)
	local toasts: { string } = {}
	if toastUnseen then
		for _, carId in unlocked do
			if data.carIndexSeen[carId] ~= true then
				table.insert(toasts, carId)
			end
		end
	end
	local seenChanged = false
	for _, carId in unlocked do
		if data.carIndexSeen[carId] ~= true then
			data.carIndexSeen[carId] = true
			seenChanged = true
		end
	end
	if seenChanged then
		DataService.save(player)
	end
	player:SetAttribute("CarIndexUnlocked", table.concat(unlocked, ","))
	Remotes.CarIndexState:FireClient(player, {
		unlocked = unlocked,
		toasts = toasts,
		catalog = catalogDto(),
	})
end

function CarIndexService.start()
	TycoonService.tycoonClaimed.Event:Connect(function(_record, player: Player)
		-- First session after the feature: mark already-open cars seen, no toast spam.
		CarIndexService.publish(player, false)
	end)
	TycoonService.padPurchased.Event:Connect(function(_record, _definition, player: Player)
		CarIndexService.publish(player, true)
	end)
	Remotes.RequestCarIndex.OnServerEvent:Connect(function(player: Player)
		CarIndexService.publish(player, false)
	end)
end

CarIndexService.start()

return CarIndexService

