--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local LuckConfig = require(ReplicatedStorage.LuckConfig)
local DataService = require(script.Parent.DataService)

export type TycoonRecord = {
	folder: Folder,
	zone: Instance,
	zones: { [string]: Instance },
	locked: Folder,
	owner: Player?,
}

local records: { TycoonRecord } = {}
local byPlayer: { [Player]: TycoonRecord } = {}
local initializing: { [Player]: boolean } = {}

local TycoonService = {}

TycoonService.padPurchased = Instance.new("BindableEvent")
TycoonService.tycoonClaimed = Instance.new("BindableEvent")
TycoonService.tycoonReleased = Instance.new("BindableEvent")

function TycoonService.getAll(): { TycoonRecord }
	return records
end

function TycoonService.getForPlayer(player: Player): TycoonRecord?
	return byPlayer[player]
end

function TycoonService.getOwner(record: TycoonRecord): Player?
	return record.owner
end

function TycoonService.hasPad(record: TycoonRecord, padId: string): boolean
	local owner = record.owner
	if owner == nil then
		return false
	end
	local data = DataService.get(owner)
	return data ~= nil and data.pads[padId] == true
end

function TycoonService.getCash(player: Player): number
	local data = DataService.get(player)
	return if data ~= nil then data.cash else 0
end

local function purchasedPadCount(data: any): number
	local count = 0
	for padId, purchased in data.pads do
		local definition = TycoonConfig.getPad(padId)
		if purchased == true
			and definition ~= nil
			and definition.starter ~= true
			and TycoonConfig.isPadEnabled(definition)
		then
			count += 1
		end
	end
	return count
end

local function updatePublicStats(player: Player, data: any)
	local racing = data.racing
	player:SetAttribute("PurchasedPads", purchasedPadCount(data))
	player:SetAttribute("RaceWins", if racing ~= nil then racing.first else 0)
	player:SetAttribute("RaceFirstPlaces", if racing ~= nil then racing.first else 0)
	player:SetAttribute("RaceSecondPlaces", if racing ~= nil then racing.second else 0)
	player:SetAttribute("RaceThirdPlaces", if racing ~= nil then racing.third else 0)
	player:SetAttribute("RaceFinishes", if racing ~= nil then racing.finishes else 0)
end

local function updateLeaderstat(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats == nil or not stats:IsA("Folder") then
		if stats ~= nil then
			stats:Destroy()
		end
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local cash = stats:FindFirstChild("Cash")
	if cash == nil or not cash:IsA("IntValue") then
		if cash ~= nil then
			cash:Destroy()
		end
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Parent = stats
	end
	(cash :: IntValue).Value = math.floor(data.cash)
	player:SetAttribute("Luck", LuckConfig.normalize(data.luck))
	player:SetAttribute("LuckLabel", LuckConfig.label(data.luck))
	updatePublicStats(player, data)
end

function TycoonService.addCash(player: Player, amount: number)
	local data = DataService.get(player)
	if data == nil or amount <= 0 then
		return
	end
	data.cash += amount
	updateLeaderstat(player)
end

-- Used after DataService commits an idempotent trade snapshot directly.
function TycoonService.syncCash(player: Player)
	updateLeaderstat(player)
end

function TycoonService.syncLuck(player: Player)
	updateLeaderstat(player)
end

function TycoonService.trySpend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if data == nil or data.cash < amount then
		return false
	end
	data.cash -= amount
	updateLeaderstat(player)
	return true
end

function TycoonService.markPadBought(player: Player, padId: string)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	data.pads[padId] = true
end

local function resolvePath(root: Instance, path: { string }): Instance?
	local node: Instance? = root
	for _, segment in path do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function findZone(root: Instance): Instance?
	local best: Instance? = nil
	local bestCount = -1
	local candidates: { Instance } = {}
	if root.Name == TycoonConfig.ZONE_NAME then
		table.insert(candidates, root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant.Name == TycoonConfig.ZONE_NAME then
			table.insert(candidates, descendant)
		end
	end
	for _, candidate in candidates do
		local holdsPads = false
		for _, pad in TycoonConfig.PADS do
			if candidate:FindFirstChild(pad.pad, true) ~= nil then
				holdsPads = true
				break
			end
		end
		if holdsPads then
			local count = #candidate:GetChildren()
			if count > bestCount then
				bestCount = count
				best = candidate
			end
		end
	end
	return best
end

local function spawnPointFor(record: TycoonRecord): CFrame?
	-- The player belongs in the middle of the Junk Spot. Keeping this marker inside the
	-- composition means future whole-lot moves carry the spawn with them.
	local marker = record.zone:FindFirstChild("PlayerSpawn", true)
	if marker ~= nil and marker:IsA("BasePart") then
		return marker.CFrame
	end
	-- Compatibility fallback for old/partial tycoon copies.
	local locations = record.folder:FindFirstChild("Locations")
	local legacy = locations and locations:FindFirstChild(TycoonConfig.SPAWN_MARKER)
	if legacy ~= nil and legacy:IsA("BasePart") then
		return legacy.CFrame
	end
	return nil
end

local function moveToTycoon(player: Player, record: TycoonRecord, character: Model?)
	local target = spawnPointFor(record)
	if target == nil then
		warn(`[TycoonService] {record.folder.Name} has no JunkSpot PlayerSpawn or Locations.{TycoonConfig.SPAWN_MARKER} marker`)
		return
	end
	local model = character or player.Character
	if model == nil then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil then
		root = model:WaitForChild("HumanoidRootPart", 10)
	end
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil and humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	model:PivotTo(target + Vector3.new(0, TycoonConfig.SPAWN_HEIGHT, 0))
	root.AssemblyLinearVelocity = Vector3.zero
end

TycoonService.moveToTycoon = moveToTycoon

local function claim(player: Player): TycoonRecord?
	local existing = byPlayer[player]
	if existing ~= nil and existing.owner == player then
		return existing
	end

	-- Recover a plot whose Player instance disappeared before PlayerRemoving cleanup
	-- completed. Without this, one stale owner permanently consumes a dealership for
	-- the rest of this server's lifetime.
	for _, record in records do
		local staleOwner = record.owner
		if staleOwner ~= nil and staleOwner.Parent ~= Players then
			record.owner = nil
			record.folder:SetAttribute(TycoonConfig.OWNER_ATTRIBUTE, nil)
			byPlayer[staleOwner] = nil
			TycoonService.tycoonReleased:Fire(record)
		end
	end

	for _, record in records do
		if record.owner == nil then
			record.owner = player
			byPlayer[player] = record
			record.folder:SetAttribute(TycoonConfig.OWNER_ATTRIBUTE, player.UserId)
			return record
		end
	end
	return nil
end

local function release(record: TycoonRecord)
	local owner = record.owner
	record.owner = nil
	record.folder:SetAttribute(TycoonConfig.OWNER_ATTRIBUTE, nil)
	if owner ~= nil then
		byPlayer[owner] = nil
	end
	TycoonService.tycoonReleased:Fire(record)
end

local function onPlayerAdded(player: Player)
	-- init() deliberately covers players that arrived before the service connected.
	-- Make that overlap idempotent so one Player can never reserve two plots.
	if initializing[player] == true or byPlayer[player] ~= nil then
		return
	end
	initializing[player] = true
	local data = DataService.load(player)
	if player.Parent ~= Players then
		initializing[player] = nil
		DataService.release(player)
		return
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(data.cash)
	cash.Parent = stats
	stats.Parent = player
	player:SetAttribute("Luck", LuckConfig.normalize(data.luck))
	player:SetAttribute("LuckLabel", LuckConfig.label(data.luck))
	updatePublicStats(player, data)

	local record = claim(player)
	-- A same-server rejoin can overlap the old PlayerRemoving event for a fraction
	-- of a second. Wait for that exact plot to release instead of abandoning this
	-- session forever with "No dealership is assigned".
	for _ = 1, 20 do
		if record ~= nil or player.Parent ~= Players then
			break
		end
		task.wait(0.25)
		record = claim(player)
	end
	if record == nil then
		initializing[player] = nil
		if player.Parent == Players then
			warn(`[TycoonService] no free tycoon for {player.Name} after retry window`)
		end
		return
	end

	if player.Character ~= nil then
		local character = player.Character
		task.spawn(function()
			moveToTycoon(player, record, character)
			task.wait(0.2)
			if byPlayer[player] == record then
				moveToTycoon(player, record, character)
			end
		end)
	end
	player.CharacterAdded:Connect(function(character: Model)
		if byPlayer[player] ~= record then
			return
		end
		task.spawn(function()
			moveToTycoon(player, record, character)
			task.wait(0.2)
			if byPlayer[player] == record then
				moveToTycoon(player, record, character)
			end
		end)
	end)

	initializing[player] = nil
	TycoonService.tycoonClaimed:Fire(record, player)
end

local function onPlayerRemoving(player: Player)
	initializing[player] = nil
	-- Release every record owned by this Player, not only the last byPlayer entry.
	-- This also repairs servers that already contain a duplicate-claim orphan.
	for _, record in records do
		if record.owner == player then
			release(record)
		end
	end
	DataService.release(player)
end

function TycoonService.init()
	for _, child in workspace:GetChildren() do
		if child:IsA("Folder") and string.match(child.Name, "^Tycoon%d+$") ~= nil then
			-- Client-created service proxies are not covered by Workspace streaming. Publish a
			-- tiny stable origin so clients can apply distance interest even after the authored
			-- OwnerIndicator geometry of a far tycoon has streamed out.
			local ownerIndicator = child:FindFirstChild("OwnerIndicator", true)
			if ownerIndicator ~= nil and ownerIndicator:IsA("BasePart") then
				child:SetAttribute("ServiceVisualOrigin", ownerIndicator.Position)
			end
			local zones: { [string]: Instance } = {}
			for _, definition in TycoonConfig.ZONES do
				local resolved = resolvePath(child, definition.path)
				if resolved ~= nil then
					zones[definition.id] = resolved
				else
					warn(`[TycoonService] {child.Name} has no {definition.title} at {table.concat(definition.path, ".")}`)
				end
			end

			local zone = zones.junk or findZone(child)
			if zone == nil then
				warn(`[TycoonService] {child.Name} has no {TycoonConfig.ZONE_NAME}, skipping`)
				continue
			end
			zones.junk = zone
			print(`[TycoonService] {child.Name} zones: {(function()
				local names = {}
				for id, node in zones do
					table.insert(names, `{id}={node.Name}`)
				end
				table.sort(names)
				return table.concat(names, " ")
			end)()}`)
			for _, zoneNode in zones do
				CollectionService:AddTag(zoneNode, TycoonConfig.ZONE_TAG)
			end
			local locked = zone:FindFirstChild(TycoonConfig.LOCKED_FOLDER_NAME)
			if locked == nil then
				local created = Instance.new("Folder")
				created.Name = TycoonConfig.LOCKED_FOLDER_NAME
				created.Parent = zone
				locked = created
			end
			table.insert(records, {
				folder = child,
				zone = zone,
				zones = zones,
				locked = locked :: Folder,
				owner = nil,
			})
		end
	end

	table.sort(records, function(a, b)
		return a.folder.Name < b.folder.Name
	end)

	print(`[TycoonService] found {#records} tycoon(s)`)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return TycoonService
