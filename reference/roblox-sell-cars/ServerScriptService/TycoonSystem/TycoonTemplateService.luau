--!strict
-- Edit Workspace.TycoonTemplate; the server creates Folder plots before any tycoon services load.
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TycoonTemplateService = {}
local initialized = false
local LOCAL_PREFIX = "_TemplateLocal_"
local WORLD_FRAMES = { "AuthoredRigPivot", "OriginalWallCFrame" }
local WORLD_POINTS = { "IdleFootPosition", "IdleLookAtPosition" }

local function frameOf(instance: Instance): CFrame?
	if instance:IsA("BasePart") then return instance.CFrame end
	if instance:IsA("Model") then return instance:GetPivot() end
	return nil
end

local function hideMarkers(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("BillboardGui") or descendant:IsA("Beam") then
			descendant.Enabled = false
		end
	end
end

-- Also used by the placement check without publishing anything into Workspace.
function TycoonTemplateService.create(template: Model, marker: BasePart): (Folder, Folder?)
	local index = tonumber(string.match(marker.Name, "^Tycoon(%d+)$"))
	assert(index ~= nil, "Invalid tycoon spawn name: " .. marker.Name)
	local clone = template:Clone()
	assert(clone ~= nil, "TycoonTemplate must be Archivable")
	local sourcePivot = clone:GetPivot()
	local delta = marker.CFrame * sourcePivot:Inverse()
	clone:PivotTo(marker.CFrame)

	local editorHelpers = clone:FindFirstChild("EditorOnlyQueueSlots")
	if editorHelpers ~= nil then editorHelpers:Destroy() end

	for _, descendant in clone:GetDescendants() do
		local frame = frameOf(descendant)
		if descendant:IsA("Model") and descendant:GetAttribute("_PIVOT0") ~= nil then
			-- Recapture the current authored pose, including edits made since migration.
			descendant:SetAttribute("_PIVOT0", descendant:GetPivot())
		end
		for _, key in WORLD_FRAMES do
			local relative = descendant:GetAttribute(LOCAL_PREFIX .. key)
			local value = descendant:GetAttribute(key)
			if frame ~= nil and typeof(relative) == "CFrame" then
				descendant:SetAttribute(key, frame * relative)
			elseif typeof(value) == "CFrame" then
				descendant:SetAttribute(key, delta * value)
			end
			descendant:SetAttribute(LOCAL_PREFIX .. key, nil)
		end
		for _, key in WORLD_POINTS do
			local relative = descendant:GetAttribute(LOCAL_PREFIX .. key)
			local value = descendant:GetAttribute(key)
			if frame ~= nil and typeof(relative) == "Vector3" then
				descendant:SetAttribute(key, frame:PointToWorldSpace(relative))
			elseif typeof(value) == "Vector3" then
				descendant:SetAttribute(key, delta:PointToWorldSpace(value))
			end
			descendant:SetAttribute(LOCAL_PREFIX .. key, nil)
		end
		if descendant:GetAttribute("TycoonIndex") ~= nil then
			descendant:SetAttribute("TycoonIndex", index)
		end
		descendant:SetAttribute("_NonBlockingNpcGuard", nil)
		descendant:SetAttribute("_PadDescendantGuardBound", nil)
	end

	local routes = clone:FindFirstChild("ServiceRouteMarkers")
	assert(routes == nil or routes:IsA("Folder"), "Template route markers must be a Folder")
	if routes ~= nil then
		routes.Parent = nil
		routes.Name = marker.Name
		hideMarkers(routes)
	end

	-- Existing clients and TycoonService deliberately discover Folder roots.
	local plot = Instance.new("Folder")
	plot.Name = marker.Name
	plot:SetAttribute("TycoonIndex", index)
	plot:SetAttribute("TemplateSpawnCFrame", marker.CFrame)
	for _, child in clone:GetChildren() do child.Parent = plot end
	clone:Destroy()

	-- These presentation anchors were intentionally offset from the building origins.
	local indicator = plot:FindFirstChild("OwnerIndicator")
	local indicatorOffset = marker:GetAttribute("OwnerIndicatorOffset")
	if indicator ~= nil and indicator:IsA("BasePart") and typeof(indicatorOffset) == "CFrame" then
		indicator.CFrame = marker.CFrame * indicatorOffset
	end
	local locations = plot:FindFirstChild("Locations")
	local legacySpawn = if locations ~= nil then locations:FindFirstChild("Spawn") else nil
	local spawnOffset = marker:GetAttribute("LegacySpawnOffset")
	if legacySpawn ~= nil and legacySpawn:IsA("BasePart") and typeof(spawnOffset) == "CFrame" then
		legacySpawn.CFrame = marker.CFrame * spawnOffset
	end
	return plot, routes :: Folder?
end

function TycoonTemplateService.init()
	if initialized then return end
	local spawns = workspace:FindFirstChild("TycoonSpawns")
	assert(spawns ~= nil and spawns:IsA("Folder"), "Workspace.TycoonSpawns must be a Folder")
	-- Studio commands can require this module in a separate VM. Persist completion
	-- in the DataModel so another caller does not try to consume the template again.
	if spawns:GetAttribute("TycoonsSpawned") == true then
		for _, marker in spawns:GetChildren() do
			local plot = workspace:FindFirstChild(marker.Name)
			assert(plot ~= nil and plot:IsA("Folder") and plot:GetAttribute("TemplateSpawnCFrame") ~= nil,
				"Previously spawned plot is missing: " .. marker.Name)
		end
		initialized = true
		return
	end
	local template = workspace:FindFirstChild("TycoonTemplate")
	assert(template ~= nil and template:IsA("Model"), "Workspace.TycoonTemplate must be a Model")
	assert(ServerStorage:FindFirstChild("TycoonTemplate") == nil, "ServerStorage already contains TycoonTemplate")

	local markers: { BasePart } = {}
	local names: { [string]: boolean } = {}
	for _, child in spawns:GetChildren() do
		assert(child:IsA("BasePart") and string.match(child.Name, "^Tycoon%d+$") ~= nil,
			"TycoonSpawns may only contain BaseParts named Tycoon1, Tycoon2, ...")
		assert(not names[child.Name], "Duplicate tycoon spawn: " .. child.Name)
		assert(workspace:FindFirstChild(child.Name) == nil, "Existing plot conflicts with spawn: " .. child.Name)
		names[child.Name] = true
		table.insert(markers, child :: BasePart)
	end
	assert(#markers > 0, "No tycoon spawn markers")
	table.sort(markers, function(a, b)
		return (tonumber(string.match(a.Name, "%d+")) :: number) < (tonumber(string.match(b.Name, "%d+")) :: number)
	end)

	local staged: { { plot: Folder, routes: Folder? } } = {}
	local ok, err = pcall(function()
		for _, marker in markers do
			local plot, routes = TycoonTemplateService.create(template :: Model, marker)
			table.insert(staged, { plot = plot, routes = routes })
		end
	end)
	if not ok then
		for _, item in staged do
			item.plot:Destroy()
			if item.routes ~= nil then item.routes:Destroy() end
		end
		error(err)
	end

	-- Retain the editable source only on the server; it is never a ninth live dealership.
	for _, descendant in template:GetDescendants() do
		for _, tag in CollectionService:GetTags(descendant) do
			CollectionService:RemoveTag(descendant, tag)
		end
	end
	template.Parent = ServerStorage
	hideMarkers(spawns)

	local routeRoot = workspace:FindFirstChild("ServiceRouteMarkers")
	if routeRoot == nil then
		routeRoot = Instance.new("Folder")
		routeRoot.Name = "ServiceRouteMarkers"
		routeRoot.Parent = workspace
	end
	for _, item in staged do
		if item.routes ~= nil then
			local existing = routeRoot:FindFirstChild(item.plot.Name)
			if existing ~= nil then existing:Destroy() end
			item.routes.Parent = routeRoot
		end
		item.plot.Parent = workspace
	end
	spawns:SetAttribute("TycoonsSpawned", true)
	initialized = true
	print(("[TycoonTemplateService] spawned %d plots from TycoonTemplate"):format(#staged))
end

return TycoonTemplateService
