--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local TycoonService = require(script.Parent.TycoonService)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.JunkLot.Remotes)

type Record = TycoonService.TycoonRecord
type Station = TycoonConfig.StationDefinition

local CLICK_DEBOUNCE = 0.05
local UPGRADE_DEBOUNCE = 0.15
local DEFAULT_JOB_STATION_ZONE = "repair"

local StationService = {}

local hosts: { [Record]: { [string]: BasePart } } = {}
local cycleToken: { [BasePart]: number } = {}
local paidJobIds: { [BasePart]: { [string]: boolean } } = {}
local lastClick: { [Player]: number } = {}
local lastUpgrade: { [Player]: number } = {}

local function isJobDriven(station: Station): boolean
	return station.jobDriven == true
end

local function ownedPads(record: Record): { [string]: boolean }
	local pads: { [string]: boolean } = {}
	local owner = record.owner
	if owner == nil then
		return pads
	end
	local data = DataService.get(owner)
	if data == nil then
		return pads
	end
	for id, value in data.pads do
		if value == true then
			pads[id] = true
		end
	end
	return pads
end

local function stationLevel(record: Record, station: Station): number
	local owner = record.owner
	if owner == nil then
		return 1
	end
	local data = DataService.get(owner)
	if data == nil then
		return 1
	end
	return math.max(data.stationLevels[station.zone] or 1, 1)
end

local function isUnlocked(record: Record, station: Station): boolean
	if not TycoonService.hasPad(record, station.unlockPad) then
		return false
	end
	local owner = record.owner
	local data: any = if owner ~= nil then DataService.get(owner) else nil
	if data == nil then
		return false
	end
	local tutorialComplete = data.tutorial ~= nil and data.tutorial.completed == true
	local chapter = TycoonConfig.deriveChapter(data.pads, tutorialComplete)
	if data.progression ~= nil and typeof(data.progression.chapter) == "number" then
		chapter = math.max(chapter, math.floor(data.progression.chapter))
	end
	return chapter >= (station.chapter or 1)
end

local function isAuto(record: Record, station: Station): boolean
	return TycoonService.hasPad(record, station.autoPad)
end

local function isInstant(record: Record, station: Station): boolean
	return TycoonConfig.isInstant(station, TycoonConfig.effectiveSpeedMultiplier(ownedPads(record), station.zone))
end

local function autoRuns(record: Record, station: Station): boolean
	if isJobDriven(station) then
		return false
	end
	if isAuto(record, station) then
		return true
	end
	return station.instantAuto and isInstant(record, station)
end

local function payoutForPads(station: Station, level: number, pads: { [string]: boolean }): number
	local payout = TycoonConfig.payoutFor(
		station,
		level,
		TycoonConfig.cashMultiplier(pads, station.zone)
	)
	return math.floor(payout * TycoonConfig.administrativeIncomeMultiplier(pads, station.zone) + 0.5)
end

local function padBelongsToStage(definition: TycoonConfig.PadDefinition, zone: string): boolean
	return definition.zone == zone
		or (definition.bonusZones ~= nil and table.find(definition.bonusZones, zone) ~= nil)
end

-- The stage capsule is informational: its dollar value is the payout unlocked by this
-- stage's purchased cash pads, never a pad price or a station-level upgrade cost.
local function stageProgress(station: Station, pads: { [string]: boolean }): (number, number, number)
	local purchased = 0
	local total = 0
	for _, definition in TycoonConfig.PADS do
		if TycoonConfig.isPadEnabled(definition) and padBelongsToStage(definition, station.zone) then
			total += 1
			if pads[definition.id] == true then
				purchased += 1
			end
		end
	end
	local stagePayout = payoutForPads(station, 1, pads)
	return purchased, total, math.max(0, stagePayout - station.basePayout)
end

local function publishOne(record: Record, station: Station, host: BasePart)
	local pads = ownedPads(record)
	local level = stationLevel(record, station)
	local cashMultiplier = TycoonConfig.cashMultiplier(pads, station.zone)
	local speedMultiplier = TycoonConfig.effectiveSpeedMultiplier(pads, station.zone)
	local payout = payoutForPads(station, level, pads)
	local stagePadsPurchased, stagePadsTotal, stageIncomeBonus = stageProgress(station, pads)
	host:SetAttribute("OwnerUserId", if record.owner ~= nil then record.owner.UserId else nil)
	host:SetAttribute("Zone", station.zone)
	host:SetAttribute("Level", level)
	host:SetAttribute("Payout", payout)
	host:SetAttribute("UpgradeAdd", station.payoutPerLevel)
	host:SetAttribute("UpgradeCost", if level >= station.maxLevel then -1 else TycoonConfig.upgradeCost(station, level))
	host:SetAttribute("FillTime", TycoonConfig.fillTimeFor(station, speedMultiplier))
	host:SetAttribute("CashMultiplier", cashMultiplier)
	host:SetAttribute("SpeedMultiplier", speedMultiplier)
	host:SetAttribute("Auto", isAuto(record, station))
	host:SetAttribute("Instant", autoRuns(record, station) and TycoonConfig.isInstant(station, speedMultiplier))
	host:SetAttribute("JobDriven", isJobDriven(station))
	host:SetAttribute("Unlocked", isUnlocked(record, station))
	host:SetAttribute("StationTitle", station.title)
	host:SetAttribute("StageTitle", station.title)
	host:SetAttribute("StagePadsPurchased", stagePadsPurchased)
	host:SetAttribute("StagePadsTotal", stagePadsTotal)
	host:SetAttribute("StageIncomeBonus", stageIncomeBonus)
	host:SetAttribute("StudsOffsetY", station.studsOffset.Y)
	-- Full offset so the panel can sit ahead of the car as well as above it. X/Z are in the
	-- host part's own axes; the client resolves them against its rotation.
	host:SetAttribute("StudsOffset", station.studsOffset)
	host:SetAttribute("MaxDistance", station.maxDistance)
end

local function publish(record: Record)
	local byZone = hosts[record]
	if byZone == nil then
		return
	end
	for _, station in TycoonConfig.STATIONS do
		local host = byZone[station.zone]
		if host ~= nil then
			publishOne(record, station, host)
		end
	end
end

StationService.publish = publish

local function runCycle(record: Record, station: Station)
	if isJobDriven(station) then
		return
	end
	local byZone = hosts[record]
	local host = byZone and byZone[station.zone]
	if host == nil or not isUnlocked(record, station) then
		return
	end
	local now = workspace:GetServerTimeNow()
	if (host:GetAttribute("CycleEnd") :: number? or 0) > now then
		return
	end

	cycleToken[host] = (cycleToken[host] or 0) + 1
	local token = cycleToken[host]
	local pads = ownedPads(record)
	local fillTime = TycoonConfig.fillTimeFor(station, TycoonConfig.effectiveSpeedMultiplier(pads, station.zone))
	host:SetAttribute("CycleStart", now)
	host:SetAttribute("CycleEnd", now + fillTime)

	task.delay(fillTime, function()
		if cycleToken[host] ~= token then
			return
		end
		local owner = record.owner
		if owner == nil or not isUnlocked(record, station) then
			return
		end
		local current = ownedPads(record)
		local payout = payoutForPads(station, stationLevel(record, station), current)
		TycoonService.addCash(owner, payout)
		host:SetAttribute("CycleStart", 0)
		host:SetAttribute("CycleEnd", 0)
		host:SetAttribute("EarnedAt", workspace:GetServerTimeNow())
		if autoRuns(record, station) then
			task.defer(runCycle, record, station)
		end
	end)
end

local function ensureHosts(record: Record): { [string]: BasePart }
	local byZone = hosts[record]
	if byZone == nil then
		byZone = {}
		hosts[record] = byZone
	end
	local resolved = byZone :: { [string]: BasePart }

	for _, station in TycoonConfig.STATIONS do
		local existing = resolved[station.zone]
		if existing ~= nil and existing.Parent ~= nil then
			continue
		end
		local zone = record.zones[station.zone]
		if zone == nil then
			continue
		end
		local adornee: Instance? = nil
		for _, name in station.adornees do
			local candidate = zone:FindFirstChild(name, true)
			while candidate ~= nil and not candidate:IsA("BasePart") do
				candidate = candidate:FindFirstChildWhichIsA("BasePart", true)
			end
			if candidate ~= nil and candidate:IsA("BasePart") then
				adornee = candidate
				break
			end
		end
		if adornee == nil or not adornee:IsA("BasePart") then
			warn(`[StationService] {record.folder.Name}: no adornee for the {station.zone} station (tried {table.concat(station.adornees, ", ")})`)
			continue
		end
		adornee:SetAttribute("CycleStart", 0)
		adornee:SetAttribute("CycleEnd", 0)
		adornee:SetAttribute("JobDriven", isJobDriven(station))
		adornee:SetAttribute("CompletedJobs", 0)
		adornee:SetAttribute("LastPayout", 0)
		adornee:SetAttribute("PaidJobId", nil)
		resolved[station.zone] = adornee
		CollectionService:AddTag(adornee, TycoonConfig.STATION_TAG)
	end
	return resolved
end

local function stationForHost(record: Record, host: Instance?): Station?
	local byZone = hosts[record]
	if byZone == nil then
		return nil
	end
	for _, station in TycoonConfig.STATIONS do
		local candidate = byZone[station.zone]
		if candidate ~= nil and (host == nil or host == candidate) then
			if host ~= nil or isUnlocked(record, station) then
				return station
			end
		end
	end
	return nil
end

local function stationForZone(zone: string): Station?
	for _, station in TycoonConfig.STATIONS do
		if station.zone == zone then
			return station
		end
	end
	return nil
end

function StationService.expectedServicePayout(record: Record, zoneId: string): number
	local station = stationForZone(zoneId)
	if station == nil or not isJobDriven(station) or not isUnlocked(record, station) then
		return 0
	end
	local payout = payoutForPads(station, stationLevel(record, station), ownedPads(record))
	return math.max(0, payout)
end

-- Completes one externally orchestrated repair job.
-- Returns (completed, payoutAwarded): a duplicate JobId is a successful
-- idempotent completion (true, 0), while an invalid request returns (false, 0).
function StationService.completeServiceJob(record: Record, jobId: string, zoneId: string?): (boolean, number)
	if jobId == "" then
		return false, 0
	end

	local resolvedZone = zoneId or DEFAULT_JOB_STATION_ZONE
	local station = stationForZone(resolvedZone)
	local owner = record.owner
	local byZone = hosts[record]
	local host = byZone and byZone[resolvedZone]
	if station == nil or not isJobDriven(station) or owner == nil or host == nil or not isUnlocked(record, station) then
		return false, 0
	end

	local paid = paidJobIds[host]
	if paid == nil then
		paid = {}
		paidJobIds[host] = paid
	end
	if paid[jobId] == true then
		return true, 0
	end

	-- Mark before crediting cash so overlapping prompt/automation callbacks cannot
	-- award the same car twice, even if they arrive in the same scheduler frame.
	paid[jobId] = true
	cycleToken[host] = (cycleToken[host] or 0) + 1

	-- A bay job pays the station's own curve, exactly like the bench does: base plus
	-- payoutPerLevel for each upgrade, times the zone's cash pads. This used to be pinned
	-- to basePayout, which quietly made every Repair Station upgrade a purchase that
	-- changed nothing while the panel kept advertising "+1100" and charging for it.
	local payout = payoutForPads(station, stationLevel(record, station), ownedPads(record))
	local now = workspace:GetServerTimeNow()
	host:SetAttribute("CycleStart", 0)
	host:SetAttribute("CycleEnd", 0)
	host:SetAttribute("PaidJobId", jobId)
	host:SetAttribute("LastPayout", payout)
	host:SetAttribute("CompletedJobs", ((host:GetAttribute("CompletedJobs") :: number?) or 0) + 1)
	host:SetAttribute("EarnedAt", now)
	TycoonService.addCash(owner, payout)
	return true, payout
end

local function onClick(player: Player, host: any)
	local now = os.clock()
	local last = lastClick[player]
	if last ~= nil and now - last < CLICK_DEBOUNCE then
		return
	end
	lastClick[player] = now

	local record = TycoonService.getForPlayer(player)
	if record == nil or record.owner ~= player then
		return
	end
	if typeof(host) ~= "Instance" then
		return
	end
	local station = stationForHost(record, host)
	if station == nil or isJobDriven(station) or autoRuns(record, station) then
		return
	end
	runCycle(record, station)
end

local function onUpgrade(player: Player, host: any)
	local now = os.clock()
	local last = lastUpgrade[player]
	if last ~= nil and now - last < UPGRADE_DEBOUNCE then
		return
	end
	lastUpgrade[player] = now

	local record = TycoonService.getForPlayer(player)
	if record == nil or record.owner ~= player then
		return
	end
	if typeof(host) ~= "Instance" then
		return
	end
	local station = stationForHost(record, host)
	if station == nil or not isUnlocked(record, station) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local level = math.max(data.stationLevels[station.zone] or 1, 1)
	if level >= station.maxLevel then
		return
	end
	local cost = TycoonConfig.upgradeCost(station, level)
	if not TycoonService.trySpend(player, cost) then
		local shortfall = cost - data.cash
		if shortfall > 0 then
			Remotes.InsufficientFunds:FireClient(player, {
				reason = "funds",
				needed = shortfall,
				title = station.title,
			})
		end
		return
	end
	data.stationLevels[station.zone] = level + 1
	publish(record)
end

function StationService.refresh(record: Record)
	local byZone = ensureHosts(record)
	publish(record)
	if record.owner == nil then
		return
	end
	for _, station in TycoonConfig.STATIONS do
		if byZone[station.zone] ~= nil and not isJobDriven(station) and autoRuns(record, station) then
			runCycle(record, station)
		end
	end
end

function StationService.init()
	local remotes = ReplicatedStorage.TycoonRemotes
	remotes.StationClick.OnServerEvent:Connect(onClick)
	remotes.StationUpgrade.OnServerEvent:Connect(onUpgrade)

	for _, record in TycoonService.getAll() do
		StationService.refresh(record)
	end

	TycoonService.tycoonClaimed.Event:Connect(function(record: Record)
		StationService.refresh(record)
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: Record)
		local byZone = hosts[record]
		if byZone ~= nil then
			for _, host in byZone do
				cycleToken[host] = (cycleToken[host] or 0) + 1
				paidJobIds[host] = nil
				host:SetAttribute("CycleStart", 0)
				host:SetAttribute("CycleEnd", 0)
				host:SetAttribute("EarnedAt", 0)
				host:SetAttribute("PaidJobId", nil)
				host:SetAttribute("LastPayout", 0)
				host:SetAttribute("CompletedJobs", 0)
			end
		end
		publish(record)
	end)
	TycoonService.padPurchased.Event:Connect(function(record: Record)
		StationService.refresh(record)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastClick[player] = nil
		lastUpgrade[player] = nil
	end)
end

return StationService

