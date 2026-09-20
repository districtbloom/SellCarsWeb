--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)

local RestartMigrationService = {}

local FINAL_COUNTDOWN_SECONDS = 10
local SAVE_START_SECONDS = 5
local SHUTDOWN_MARGIN_SECONDS = 1

local stateRemote = ReplicatedStorage:WaitForChild("TycoonRemotes"):WaitForChild("ServerRestartState") :: RemoteEvent

local initialized = false
local active = false
local generation = 0
local revision = 0
local currentPhase = "Idle"
local currentDeadlineServerTime = 0
local currentRestartServerTime = 0
local currentSource = ""
local currentMessage = ""

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function cleanMessage(attributes: { [string]: any }?): string
	if typeof(attributes) ~= "table" then
		return ""
	end
	local raw = attributes.message
	if typeof(raw) ~= "string" then
		return ""
	end
	local normalized = string.gsub(raw, "%s+", " ")
	return string.sub(normalized, 1, 140)
end

local function payload(): { [string]: any }
	return {
		active = active,
		phase = currentPhase,
		deadlineServerTime = currentDeadlineServerTime,
		restartServerTime = currentRestartServerTime,
		source = currentSource,
		message = currentMessage,
		revision = revision,
	}
end

local function publish(phase: string, isActive: boolean)
	active = isActive
	currentPhase = phase
	stateRemote:SetAttribute("Active", active)
	stateRemote:SetAttribute("Phase", currentPhase)
	stateRemote:SetAttribute("DeadlineServerTime", currentDeadlineServerTime)
	stateRemote:SetAttribute("RestartServerTime", currentRestartServerTime)
	stateRemote:SetAttribute("Source", currentSource)
	stateRemote:SetAttribute("Message", currentMessage)
	revision += 1
	stateRemote:SetAttribute("Revision", revision)
	stateRemote:FireAllClients(payload())
end

local function resetState(clearResults: boolean)
	currentDeadlineServerTime = 0
	currentRestartServerTime = 0
	currentSource = ""
	currentMessage = ""
	if clearResults then
		stateRemote:SetAttribute("SavedPlayers", 0)
		stateRemote:SetAttribute("FailedSaves", 0)
	end
	publish("Idle", false)
end

local function waitUntil(myGeneration: number, targetServerTime: number): boolean
	while myGeneration == generation and active and serverNow() < targetServerTime do
		task.wait(math.min(0.2, math.max(0.03, targetServerTime - serverNow())))
	end
	return myGeneration == generation and active
end

local function flushStable(player: Player): boolean
	for _ = 1, 2 do
		if player.Parent ~= Players then
			return true
		end
		local ok, saved = pcall(DataService.flush, player)
		if not ok or saved ~= true then
			return false
		end
		if not DataService.isDirty(player) then
			return true
		end
	end
	return not DataService.isDirty(player)
end

local function flushPlayers(players: { Player }, stopAt: number): (number, number)
	local pending = #players
	local savedCount = 0
	local failedCount = 0
	for _, player in players do
		task.spawn(function()
			local saved = flushStable(player)
			if saved then
				savedCount += 1
			else
				failedCount += 1
				warn(("[RestartMigration] final save did not confirm for %s (%d)"):format(player.Name, player.UserId))
			end
			pending -= 1
		end)
	end

	while pending > 0 and serverNow() < stopAt do
		task.wait(0.05)
	end
	if pending > 0 then
		failedCount += pending
		warn(("[RestartMigration] final save budget expired with %d player(s) still pending"):format(pending))
	end
	return savedCount, failedCount
end

local function runRestart(myGeneration: number, debugNoShutdown: boolean)
	local countdownStartsAt = currentRestartServerTime - FINAL_COUNTDOWN_SECONDS
	if serverNow() < countdownStartsAt then
		publish("Scheduled", true)
		if not waitUntil(myGeneration, countdownStartsAt) then
			return
		end
	end

	currentDeadlineServerTime = currentRestartServerTime
	publish("Countdown", true)

	local saveStartsAt = currentRestartServerTime - SAVE_START_SECONDS
	if serverNow() < saveStartsAt and not waitUntil(myGeneration, saveStartsAt) then
		return
	end

	publish("Saving", true)
	local players = Players:GetPlayers()
	local latestSafeSaveEnd = currentRestartServerTime - SHUTDOWN_MARGIN_SECONDS
	local saveStopAt = latestSafeSaveEnd
	if saveStopAt <= serverNow() then
		saveStopAt = serverNow() + 0.75
	end
	local savedCount, failedCount = flushPlayers(players, saveStopAt)
	stateRemote:SetAttribute("SavedPlayers", savedCount)
	stateRemote:SetAttribute("FailedSaves", failedCount)

	if myGeneration ~= generation or not active then
		return
	end
	if serverNow() < currentRestartServerTime then
		publish("Countdown", true)
		if not waitUntil(myGeneration, currentRestartServerTime) then
			return
		end
	end

	-- Restart Servers already migrates the server's players together to a replacement
	-- server on the latest published place version. Keep the UI up while Roblox closes us.
	publish("WaitingForPlatform", true)
	if debugNoShutdown then
		task.wait(2)
		if myGeneration == generation then
			generation += 1
			resetState(false)
		end
	end
end

local function beginRestart(
	restartTime: DateTime,
	source: any,
	attributes: { [string]: any }?,
	debugNoShutdown: boolean
): boolean
	if active then
		return false
	end

	local unixNow = DateTime.now().UnixTimestampMillis / 1000
	local restartUnix = restartTime.UnixTimestampMillis / 1000
	local availableSeconds = math.max(0, restartUnix - unixNow)

	generation += 1
	currentRestartServerTime = serverNow() + availableSeconds
	currentDeadlineServerTime = currentRestartServerTime
	currentSource = tostring(source)
	currentMessage = cleanMessage(attributes)
	stateRemote:SetAttribute("SavedPlayers", 0)
	stateRemote:SetAttribute("FailedSaves", 0)

	print(("[RestartMigration] scheduled by %s; Roblox platform migration in %.1f seconds for %d player(s)"):format(
		currentSource,
		availableSeconds,
		#Players:GetPlayers()
	))
	task.spawn(runRestart, generation, debugNoShutdown)
	return true
end

function RestartMigrationService.debugSchedule(delaySeconds: number?): boolean
	if not RunService:IsStudio() then
		return false
	end
	local delay = math.clamp(tonumber(delaySeconds) or FINAL_COUNTDOWN_SECONDS, 3, 14400)
	local fakeRestart = DateTime.fromUnixTimestampMillis(
		math.floor(DateTime.now().UnixTimestampMillis + delay * 1000)
	)
	return beginRestart(
		fakeRestart,
		Enum.CloseReason.DeveloperUpdate,
		{ message = "Studio restart migration test" },
		true
	)
end

function RestartMigrationService.debugCancel(): boolean
	if not RunService:IsStudio() then
		return false
	end
	generation += 1
	resetState(true)
	return true
end

function RestartMigrationService.init()
	if initialized then
		return
	end
	initialized = true
	resetState(true)

	if RunService:IsStudio() then
		local debugEvent = ServerStorage:FindFirstChild("RestartMigrationDebug")
		if debugEvent == nil then
			debugEvent = Instance.new("BindableEvent")
			debugEvent.Name = "RestartMigrationDebug"
			debugEvent.Parent = ServerStorage
		end
		if debugEvent:IsA("BindableEvent") then
			debugEvent.Event:Connect(function(delaySeconds)
				local parsed = tonumber(delaySeconds)
				if parsed ~= nil and parsed < 0 then
					RestartMigrationService.debugCancel()
				else
					RestartMigrationService.debugSchedule(parsed)
				end
			end)
		end
	end

	game.ServerRestartScheduled:Connect(function(restartTime, source, attributes)
		beginRestart(restartTime, source, attributes, false)
	end)
end

return RestartMigrationService
