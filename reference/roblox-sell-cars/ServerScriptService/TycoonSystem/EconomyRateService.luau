--!strict
-- Factual rolling business revenue only. Callers must opt in from approved payout sites;
-- generic cash mutations deliberately do not feed this window.

local Players = game:GetService("Players")

local Remotes = require(script.Parent.JunkLot.Remotes)

local WINDOW_SECONDS = 60
local PUBLISH_INTERVAL = 1

type RevenueSample = {
	at: number,
	amount: number,
}

type RevenueWindow = {
	head: number,
	samples: { RevenueSample },
	total: number,
}

local EconomyRateService = {}

local windows: { [Player]: RevenueWindow } = {}
local started = false

local function windowFor(player: Player): RevenueWindow
	local existing = windows[player]
	if existing ~= nil then
		return existing
	end
	local created: RevenueWindow = {
		head = 1,
		samples = {},
		total = 0,
	}
	windows[player] = created
	return created
end

local function prune(window: RevenueWindow, now: number)
	local cutoff = now - WINDOW_SECONDS
	while window.head <= #window.samples do
		local sample = window.samples[window.head]
		if sample.at > cutoff then
			break
		end
		window.total = math.max(0, window.total - sample.amount)
		window.head += 1
	end

	-- Bound retained table storage during long sessions without shifting on every prune.
	if window.head > 64 and window.head > math.floor(#window.samples / 2) then
		local compacted: { RevenueSample } = {}
		for index = window.head, #window.samples do
			table.insert(compacted, window.samples[index])
		end
		window.samples = compacted
		window.head = 1
	end
end

local function publish(player: Player, now: number)
	if player.Parent ~= Players then
		return
	end
	local window = windowFor(player)
	prune(window, now)
	Remotes.EconomyRateUpdate:FireClient(player, {
		windowSeconds = WINDOW_SECONDS,
		total = math.max(0, math.floor(window.total + 0.5)),
	})
end

function EconomyRateService.record(player: Player, amount: number)
	if player.Parent ~= Players or amount ~= amount or amount == math.huge then
		return
	end
	local resolvedAmount = math.max(0, math.floor(amount + 0.5))
	if resolvedAmount <= 0 then
		return
	end
	local now = workspace:GetServerTimeNow()
	local window = windowFor(player)
	prune(window, now)
	table.insert(window.samples, {
		at = now,
		amount = resolvedAmount,
	})
	window.total += resolvedAmount
	publish(player, now)
end

function EconomyRateService.init()
	if started then
		return
	end
	started = true

	Players.PlayerRemoving:Connect(function(player)
		windows[player] = nil
	end)

	task.spawn(function()
		while started do
			task.wait(PUBLISH_INTERVAL)
			local now = workspace:GetServerTimeNow()
			for _, player in Players:GetPlayers() do
				publish(player, now)
			end
		end
	end)
end

return EconomyRateService
