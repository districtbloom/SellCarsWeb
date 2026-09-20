--!strict
-- Server-authored Rex tutorial cues, pad reactions, and session-scoped deduplication.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RexVoiceConfig = require(ReplicatedStorage:WaitForChild("RexVoiceConfig"))
local DealerCarConfig = require(ReplicatedStorage:WaitForChild("DealerCarConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local GameplayEvents = require(script.Parent:WaitForChild("GameplayEvents"))
local TycoonService = require(script.Parent:WaitForChild("TycoonService"))

local existingRemote = ReplicatedStorage:FindFirstChild(RexVoiceConfig.RemoteName)
if existingRemote and not existingRemote:IsA("RemoteEvent") then
	existingRemote:Destroy()
	existingRemote = nil
end

local remote = existingRemote
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = RexVoiceConfig.RemoteName
	remote.Parent = ReplicatedStorage
end
local rexRemote = remote :: RemoteEvent

local sent: { [Player]: { [string]: boolean } } = {}
local reminderGeneration: { [Player]: number } = {}

local function canSend(player: Player): boolean
	return player.Parent == Players
end

local function sendLine(player: Player, lineId: string, dedupeKey: string, priority: number)
	if not canSend(player) or RexVoiceConfig.Lines[lineId] == nil then
		return
	end
	local bucket = sent[player]
	if bucket == nil then
		bucket = {}
		sent[player] = bucket
	end
	if bucket[dedupeKey] == true then
		return
	end
	bucket[dedupeKey] = true
	rexRemote:FireClient(player, {
		lineId = lineId,
		dedupeKey = dedupeKey,
		priority = priority,
	})
end

local function tutorialCue(player: Player, cueNumber: number, tradeId: any, dealIndex: number?)
	local lineId = string.format("TUTORIAL_%02d", cueNumber)
	local tradeKey = if typeof(tradeId) == "string" and tradeId ~= ""
		then tradeId
		else `deal:{math.floor(dealIndex or 0)}`
	sendLine(player, lineId, `{tradeKey}:{lineId}`, 100)
end

local function tutorialIndex(payload: any): number
	if typeof(payload) ~= "table" then
		return 0
	end
	return math.floor(tonumber(payload.tutorialDealIndex) or 0)
end

local function connectCue(eventName: string, cueByDeal: { [number]: number })
	GameplayEvents.connect(eventName, function(player: Player, payload: any)
		if not canSend(player) then
			return
		end
		local dealIndex = tutorialIndex(payload)
		local cueNumber = cueByDeal[dealIndex]
		if cueNumber ~= nil then
			tutorialCue(player, cueNumber, payload.tradeId, dealIndex)
		end
	end)
end

-- Arrival owns the seller prompt: Rex must tell the player to talk before they have
-- already opened the deal card. CarArrived carries the exact tutorial trade id.
connectCue("CarArrived", { [1] = 2 })
connectCue("CarBought", { [1] = 3 })
connectCue("RepairCompleted", { [1] = 4 })
connectCue("CarListed", { [1] = 6 })
connectCue("OfferReceived", { [1] = 7 })

GameplayEvents.connect("CarSold", function(player: Player, payload: any)
	if not canSend(player) then
		return
	end
	local dealIndex = tutorialIndex(payload)
	if dealIndex == 1 then
		tutorialCue(player, 8, payload.tradeId, dealIndex)
	end
end)

local function findTutorialCar(data: any, dealIndex: number): any?
	for index = 1, DealerCarConfig.MAX_WORKING_SLOTS do
		local car = DataService.getWorking(data, index)
		if car ~= nil and car.tutorialDealIndex == dealIndex then
			return car
		end
	end
	for _, car in data.processingCars do
		if car.tutorialDealIndex == dealIndex then
			return car
		end
	end
	for index = 1, DealerCarConfig.MAX_DISPLAY_SLOTS do
		local car = DataService.getDisplay(data, index)
		if car ~= nil and car.tutorialDealIndex == dealIndex then
			return car
		end
	end
	return nil
end

local function contextualCue(data: any, dealIndex: number, car: any?): number?
	local incoming = { [1] = 1 }
	if car == nil or car.state == "Incoming" then
		return incoming[dealIndex]
	elseif car.state == "Offered" then
		return ({ [1] = 2 })[dealIndex]
	elseif car.state == "Junk" or car.state == "Repairing" then
		return ({ [1] = 3 })[dealIndex]
	elseif car.state == "Ready" then
		return if data.pads.FirstSalesman == true then 5 else 4
	elseif car.state == "Listed" then
		return ({ [1] = 6 })[dealIndex]
	elseif car.state == "Offer" then
		return ({ [1] = 7 })[dealIndex]
	end
	return incoming[dealIndex]
end

local function scheduleContextualReminder(player: Player)
	reminderGeneration[player] = (reminderGeneration[player] or 0) + 1
	local generation = reminderGeneration[player]
	task.spawn(function()
		-- SessionStarted can race the service script during server boot. Retry only until the
		-- profile is available; the per-session cue key handles duplicate scheduling safely.
		for _ = 1, 20 do
			task.wait(0.5)
			if reminderGeneration[player] ~= generation or not canSend(player) then
				return
			end
			local data = DataService.get(player)
			if data ~= nil then
				if data.tutorial.eligible ~= true or data.tutorial.completed == true then
					return
				end
				local dealIndex = math.floor(data.tutorial.dealIndex)
				if dealIndex < 1 or dealIndex > DealerCarConfig.TUTORIAL_DEAL_COUNT then
					return
				end
				local car = findTutorialCar(data, dealIndex)
				-- Before the first Cash Register purchase Rex introduces the business and points at
				-- the only open paid action. Cue 1 belongs to the purchase receipt and may only say
				-- the first seller is coming after that source is actually open.
				if dealIndex == 1 and car == nil and data.pads.CashRegister ~= true then
					tutorialCue(player, 0, nil, dealIndex)
					return
				end
				local cueNumber = contextualCue(data, dealIndex, car)
				if cueNumber ~= nil then
					tutorialCue(player, cueNumber, if car ~= nil then car.tradeId else nil, dealIndex)
				end
				return
			end
		end
	end)
end

GameplayEvents.connect("SessionStarted", function(player: Player)
	scheduleContextualReminder(player)
end)

TycoonService.padPurchased.Event:Connect(function(_record, definition, player)
	if typeof(definition) ~= "table" or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	if player.Parent ~= Players then
		return
	end

	local padId = definition.id
	if typeof(padId) ~= "string" then
		return
	end
	local data = DataService.get(player)
	if data ~= nil and data.tutorial.eligible == true and data.tutorial.completed ~= true then
		-- Tutorial Rex is deliberately short and step-specific. Cash Register starts the seller;
		-- the post-repair FirstSalesman receipt introduces Manny and his staff-only car role.
		if padId == "CashRegister" and math.floor(data.tutorial.dealIndex) == 1 then
			tutorialCue(player, 1, nil, 1)
		elseif padId == "FirstSalesman" and math.floor(data.tutorial.dealIndex) == 1 then
			local car = findTutorialCar(data, 1)
			tutorialCue(player, 5, if car ~= nil then car.tradeId else nil, 1)
		end
		return
	end

	local lineId, line = RexVoiceConfig.lineForPad(padId)
	if lineId and line then
		sendLine(player, lineId, `pad:{padId}:{lineId}`, 0)
	end
end)

Players.PlayerAdded:Connect(scheduleContextualReminder)
Players.PlayerRemoving:Connect(function(player: Player)
	sent[player] = nil
	reminderGeneration[player] = nil
end)

for _, player in Players:GetPlayers() do
	scheduleContextualReminder(player)
end
