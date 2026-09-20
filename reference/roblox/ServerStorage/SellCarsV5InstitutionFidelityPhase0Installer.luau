--!strict

-- Sell Cars V5 — Institution Fidelity R1, Phase 0.
-- Freezes the accepted Institution A/B layers as read-only inputs and creates
-- evidence only. This installer intentionally creates no physical geometry.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Installer = {}
Installer.Version = "2026-09-03.v5-institution-fidelity-phase0.3"

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local FIDELITY_ROOT_NAME = "10_Institution_Fidelity_R1"
local EVIDENCE_NAME = "99_Fidelity_Evidence"
local BASELINE_NAME = "00_Phase0_Baseline"
local LAYER_A_NAME = "08_Institution_Production_A"
local LAYER_B_NAME = "09_Institution_Production_B"

local EXPECTED_ROOT_STATUS = "INSTITUTION_COMPLETE_ACCEPTED"
local EXPECTED_A_VERSION = "2026-09-03.v5-institution-production-a.1"
local EXPECTED_B_VERSION = "2026-09-03.v5-institution-production-b.1"
local EXPECTED_A_HASH = "26945dcb"
local EXPECTED_B_HASH = "358dbf5d"

local SOURCE_A_SHA256 = "37892e6e3ad825c2eae7d11bc9535d40e62ed6f99b7c6a18c7a423ce7dd7ced9"
local SOURCE_B_SHA256 = "fcd88439064949ae0434a80933fe4bdebbdf60f6ffc4a83c0b97b4f5259a830a"
local ROUTE_PROOF_SHA256 = "d0297502fca74e13b4824360965125d85e8c3771d1de52f87d7dbfff7ad1947b"

type Snapshot = {
	Parts: number,
	Models: number,
	Folders: number,
	Lights: number,
	Sounds: number,
	Effects: number,
	Textures: number,
	Scripts: number,
	Transparent: number,
	Collidable: number,
	Touchable: number,
	Queryable: number,
	ShadowCasting: number,
	TaggedSolids: number,
	Descendants: number,
	Hash: string,
	HashRecords: number,
}

local function round(value: number): number
	return math.floor(value * 1000 + (if value >= 0 then 0.5 else -0.5)) / 1000
end

local function addHash(seed: number, value: string): number
	local hash = seed
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return hash
end

local function relativePath(item: Instance, ancestor: Instance): string
	local names = {}
	local cursor: Instance? = item
	while cursor and cursor ~= ancestor do
		table.insert(names, 1, cursor.Name)
		cursor = cursor.Parent
	end
	return table.concat(names, "/")
end

local function geometryHash(instance: Instance): (string, number)
	local records = { ".|" .. instance.ClassName }
	for _, item in ipairs(instance:GetDescendants()) do
		local record = relativePath(item, instance) .. "|" .. item.ClassName
		if item:IsA("BasePart") then
			local position = item.Position
			local size = item.Size
			local orientation = item.Orientation
			local color = item.Color
			record ..= string.format(
				"|p=%.3f,%.3f,%.3f|s=%.3f,%.3f,%.3f|o=%.3f,%.3f,%.3f|t=%.3f|c=%s%s%s%s|m=%s|rgb=%.3f,%.3f,%.3f",
				round(position.X), round(position.Y), round(position.Z),
				round(size.X), round(size.Y), round(size.Z),
				round(orientation.X), round(orientation.Y), round(orientation.Z),
				round(item.Transparency),
				if item.CanCollide then "1" else "0",
				if item.CanTouch then "1" else "0",
				if item.CanQuery then "1" else "0",
				if item.CastShadow then "1" else "0",
				tostring(item.Material), round(color.R), round(color.G), round(color.B)
			)
		elseif item:IsA("Light") then
			record ..= string.format(
				"|e=%s|b=%.3f|r=%.3f|s=%s",
				if item.Enabled then "1" else "0",
				round(item.Brightness), round(item.Range),
				if item.Shadows then "1" else "0"
			)
		elseif item:IsA("LuaSourceContainer") then
			record ..= "|sourceLen=" .. tostring(#item.Source)
		end
		table.insert(records, record)
	end
	table.sort(records)
	local hash = 5381
	for _, record in ipairs(records) do
		hash = addHash(hash, record)
		hash = addHash(hash, "\n")
	end
	return string.format("%08x", hash), #records
end

local function snapshot(instance: Instance): Snapshot
	local result: Snapshot = {
		Parts = 0,
		Models = 0,
		Folders = 0,
		Lights = 0,
		Sounds = 0,
		Effects = 0,
		Textures = 0,
		Scripts = 0,
		Transparent = 0,
		Collidable = 0,
		Touchable = 0,
		Queryable = 0,
		ShadowCasting = 0,
		TaggedSolids = 0,
		Descendants = #instance:GetDescendants(),
		Hash = "",
		HashRecords = 0,
	}

	for _, item in ipairs(instance:GetDescendants()) do
		if item:IsA("BasePart") then
			result.Parts += 1
			if item.Transparency > 0 and item.Transparency < 1 then result.Transparent += 1 end
			if item.CanCollide then result.Collidable += 1 end
			if item.CanTouch then result.Touchable += 1 end
			if item.CanQuery then result.Queryable += 1 end
			if item.CastShadow then result.ShadowCasting += 1 end
			if item:GetAttribute("V5ProductionASolid") or item:GetAttribute("V5ProductionBSolid") then
				result.TaggedSolids += 1
			end
		elseif item:IsA("Model") then
			result.Models += 1
		elseif item:IsA("Folder") then
			result.Folders += 1
		elseif item:IsA("Light") then
			result.Lights += 1
		elseif item:IsA("Sound") or item:IsA("AudioPlayer") then
			result.Sounds += 1
		elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail")
			or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") then
			result.Effects += 1
		elseif item:IsA("Decal") or item:IsA("Texture") or item:IsA("SurfaceAppearance") then
			result.Textures += 1
		elseif item:IsA("LuaSourceContainer") then
			result.Scripts += 1
		end
	end

	result.Hash, result.HashRecords = geometryHash(instance)
	return result
end

local function writeSnapshot(parent: Instance, name: string, instance: Instance): Folder
	local result = Instance.new("Folder")
	result.Name = name
	local values = snapshot(instance)
	for key, value in pairs(values) do
		result:SetAttribute(key, value)
	end
	result:SetAttribute("SourcePath", instance:GetFullName())
	result:SetAttribute("Version", instance:GetAttribute("Version"))
	result:SetAttribute("Checkpoint", instance:GetAttribute("Checkpoint"))
	result.Parent = parent
	return result
end

local function setLightingAttributes(target: Instance, clockTime: number, authority: string)
	target:SetAttribute("ClockTime", clockTime)
	target:SetAttribute("Brightness", Lighting.Brightness)
	target:SetAttribute("ExposureCompensation", Lighting.ExposureCompensation)
	target:SetAttribute("Ambient", Lighting.Ambient)
	target:SetAttribute("OutdoorAmbient", Lighting.OutdoorAmbient)
	target:SetAttribute("EnvironmentDiffuseScale", Lighting.EnvironmentDiffuseScale)
	target:SetAttribute("EnvironmentSpecularScale", Lighting.EnvironmentSpecularScale)
	target:SetAttribute("GlobalShadows", Lighting.GlobalShadows)
	target:SetAttribute("PresetAuthority", authority)
end

local function buildLightingSnapshot(parent: Instance): Folder
	local lighting = Instance.new("Folder")
	lighting.Name = "02_Lighting_Baseline"
	lighting.Parent = parent

	local day = Instance.new("Folder")
	day.Name = "Day_Accepted"
	setLightingAttributes(day, Lighting.ClockTime, "ACCEPTED_CURRENT")
	day.Parent = lighting

	local night = Instance.new("Folder")
	night.Name = "Night_Review"
	setLightingAttributes(night, 21, "REVIEW_ONLY_SAME_GLOBAL_RIG")
	night:SetAttribute("Rule", "Only ClockTime changes during Phase 0 review; restore accepted day after capture")
	night.Parent = lighting

	local descendants = Lighting:GetDescendants()
	local postEffects = 0
	local atmosphere = 0
	local sky = 0
	for _, item in ipairs(descendants) do
		if item:IsA("PostEffect") then postEffects += 1 end
		if item:IsA("Atmosphere") then atmosphere += 1 end
		if item:IsA("Sky") then sky += 1 end
	end
	lighting:SetAttribute("LightingDescendants", #descendants)
	lighting:SetAttribute("PostEffects", postEffects)
	lighting:SetAttribute("Atmospheres", atmosphere)
	lighting:SetAttribute("Skies", sky)
	return lighting
end

local CAMERA_FRAMES: {[string]: CFrame} = {
	Frontage = CFrame.lookAt(Vector3.new(3130, 35, -92), Vector3.new(3130, 7, 55)),
	Production_Street = CFrame.lookAt(Vector3.new(3130, 15, 92), Vector3.new(3130, 6, 255)),
	Wash = CFrame.lookAt(Vector3.new(3113, 11, 117), Vector3.new(3046, 5, 120)),
	Mechanical = CFrame.lookAt(Vector3.new(3113, 11, 169), Vector3.new(3046, 5, 176)),
	Body_Restoration = CFrame.lookAt(Vector3.new(3113, 11, 233), Vector3.new(3046, 5, 241)),
	Tune_Performance = CFrame.lookAt(Vector3.new(3113, 11, 300), Vector3.new(3046, 5, 309)),
	Photo_Listing = CFrame.lookAt(Vector3.new(3147, 11, 169), Vector3.new(3214, 5, 176)),
	Detail_QC = CFrame.lookAt(Vector3.new(3147, 11, 233), Vector3.new(3214, 5, 239)),
	Paint_Exterior = CFrame.lookAt(Vector3.new(3147, 11, 300), Vector3.new(3214, 5, 308)),
	Intake = CFrame.lookAt(Vector3.new(3094, 18, -12), Vector3.new(3042, 5, 51)),
	Sales_Delivery = CFrame.lookAt(Vector3.new(3108, 7, -2), Vector3.new(3130, 4, 52)),
	Owner_Garage = CFrame.lookAt(Vector3.new(3166, 18, -12), Vector3.new(3218, 5, 54)),
	Parts_Logistics = CFrame.lookAt(Vector3.new(3130, 14, 385), Vector3.new(3038, 6, 443)),
	Staff_Operations = CFrame.lookAt(Vector3.new(3130, 14, 385), Vector3.new(3222, 6, 443)),
	Collector_HQ_Hero = CFrame.lookAt(Vector3.new(3130, 12, 330), Vector3.new(3130, 26, 468)),
	Aerial_Overview = CFrame.lookAt(Vector3.new(3130, 330, -30), Vector3.new(3130, 0, 232)),
	Aerial_Performance = CFrame.lookAt(Vector3.new(3130, 180, 0), Vector3.new(3130, 0, 232)),
	Neighbour_West = CFrame.lookAt(Vector3.new(2930, 32, 175), Vector3.new(3130, 8, 225)),
	Neighbour_East = CFrame.lookAt(Vector3.new(3330, 32, 175), Vector3.new(3130, 8, 225)),
}

local function buildCameraRegistry(parent: Instance): Folder
	local cameras = Instance.new("Folder")
	cameras.Name = "03_Canonical_Cameras"
	cameras:SetAttribute("CameraCount", 0)
	cameras:SetAttribute("FieldOfView", 60)
	cameras:SetAttribute("ReviewRule", "Capture clean day and night; overlays only after clean view")
	cameras:SetAttribute("DayCaptureStatus", "19/19 CAPTURED")
	cameras:SetAttribute("NightCaptureStatus", "3/3 HERO VIEWS CAPTURED")
	cameras.Parent = parent

	local count = 0
	for name, frame in pairs(CAMERA_FRAMES) do
		local value = Instance.new("CFrameValue")
		value.Name = name
		value.Value = frame
		value:SetAttribute("DayRequired", true)
		value:SetAttribute("DayCaptured", true)
		local nightRequired = name == "Frontage" or name == "Production_Street" or name == "Collector_HQ_Hero"
		value:SetAttribute("NightRequired", nightRequired)
		value:SetAttribute("NightCaptured", nightRequired)
		value.Parent = cameras
		count += 1
	end
	cameras:SetAttribute("CameraCount", count)
	return cameras
end

local function buildRuntimeBaseline(parent: Instance): Folder
	local runtime = Instance.new("Folder")
	runtime.Name = "07_Runtime_Performance_Baseline"
	runtime:SetAttribute("Authority", "PROVISIONAL_STUDIO_CLIENT_NO_TRAFFIC")
	runtime:SetAttribute("MeasuredOn", "2026-09-03")
	runtime:SetAttribute("PhysicsFPS", 60)
	runtime:SetAttribute("InstanceCompositionTotal", 8536)
	runtime:SetAttribute("Objects3D", 6798)
	runtime:SetAttribute("PhysicsInstances", 103)
	runtime:SetAttribute("UIInstances", 435)
	runtime:SetAttribute("LightInstances", 102)
	runtime:SetAttribute("PostProcessingInstances", 5)
	runtime:SetAttribute("ScriptAndRemoteInstances", 73)
	runtime:SetAttribute("AudioInstances", 14)
	runtime:SetAttribute("AnimationInstances", 28)
	runtime:SetAttribute("ValueInstances", 644)
	runtime:SetAttribute("TextureInstances", 1)
	runtime:SetAttribute("AudioMemoryBytes", 2843594)
	runtime:SetAttribute("AnimationMemoryBytes", 139755)
	runtime:SetAttribute("UnparentedInstances", 11)
	runtime:SetAttribute("ScriptMemoryStatus", "UNAVAILABLE_STUDIOPLAT37936_DISABLED")
	runtime:SetAttribute("RenderingExcludesShadows", true)
	runtime:SetAttribute("DayNightRenderDelta", 0)
	runtime:SetAttribute("ReferenceContext", "~800k triangles and ~600 draws is contextual, not an accepted target")
	runtime.Parent = parent

	local views = {
		{ "Frontage", 22342, 106 },
		{ "Production_Street", 14810, 102 },
		{ "Collector_HQ_Hero", 8798, 62 },
		{ "Aerial_Performance", 14726, 93 },
		{ "Mid_Campus_Stress", 18350, 119 },
	}
	for _, data in ipairs(views) do
		local view = Instance.new("Folder")
		view.Name = data[1] :: string
		view:SetAttribute("Triangles", data[2])
		view:SetAttribute("DrawCalls", data[3])
		view:SetAttribute("ClockTime", 14.5)
		view.Parent = runtime
	end
	return runtime
end

local function classifyAssembly(item: Model, layer: Instance): (string, string)
	if item:GetAttribute("OccupationPrototype") then
		return "REPLACE", "Proxy person becomes a gameplay-owned staff/customer representation"
	end
	if item.Parent == layer then
		return "RETAIN", "Accepted top-level composition container and placement authority"
	end
	if item.Parent and item.Parent.Parent == layer then
		return "RETAIN", "Accepted department or zone socket; refine contents without relocating it"
	end
	return "REFINE", "Retain purpose and position; improve construction, materials and readable subcomponents"
end

local function countParts(instance: Instance): number
	local count = 0
	for _, item in ipairs(instance:GetDescendants()) do
		if item:IsA("BasePart") then count += 1 end
	end
	return count
end

local function buildAssemblyInventory(parent: Instance, root: Instance, layerA: Instance, layerB: Instance): Folder
	local inventory = Instance.new("Folder")
	inventory.Name = "04_Assembly_Inventory"
	inventory.Parent = parent
	local index = 0
	local retain = 0
	local refine = 0
	local replace = 0
	local hide = 0

	for _, layer in ipairs({layerA, layerB}) do
		for _, item in ipairs(layer:GetDescendants()) do
			if item:IsA("Model") then
				index += 1
				local disposition, reason = classifyAssembly(item, layer)
				local row = Instance.new("StringValue")
				row.Name = string.format("Assembly_%03d", index)
				row.Value = relativePath(item, layer)
				row:SetAttribute("SourceLayer", layer.Name)
				row:SetAttribute("SourcePath", item:GetFullName())
				row:SetAttribute("Disposition", disposition)
				row:SetAttribute("Reason", reason)
				row:SetAttribute("ZoneId", item:GetAttribute("ZoneId") or "")
				row:SetAttribute("FunctionId", item:GetAttribute("FunctionId") or "")
				row:SetAttribute("PartCount", countParts(item))
				row.Parent = inventory
				if disposition == "RETAIN" then retain += 1 end
				if disposition == "REFINE" then refine += 1 end
				if disposition == "REPLACE" then replace += 1 end
			end
		end
	end

	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("V5ProductionBHidden") then
			index += 1
			local row = Instance.new("StringValue")
			row.Name = string.format("Assembly_%03d", index)
			row.Value = relativePath(item, root)
			row:SetAttribute("SourceLayer", ROOT_NAME)
			row:SetAttribute("SourcePath", item:GetFullName())
			row:SetAttribute("Disposition", "HIDE")
			row:SetAttribute("Reason", item:GetAttribute("V5ProductionBHiddenReason") or "Hidden accepted reserve")
			row:SetAttribute("PartCount", 1)
			row.Parent = inventory
			hide += 1
		end
	end

	inventory:SetAttribute("AssemblyRows", index)
	inventory:SetAttribute("Retain", retain)
	inventory:SetAttribute("Refine", refine)
	inventory:SetAttribute("Replace", replace)
	inventory:SetAttribute("Hide", hide)
	inventory:SetAttribute("Rule", "Inventory is a Phase 0 disposition, not permission to mutate accepted layers")
	return inventory
end

local function assertAccepted(root: Instance): (Instance, Instance, Snapshot, Snapshot)
	assert(root:GetAttribute("EnvironmentStatus") == EXPECTED_ROOT_STATUS, "V5 root is not the accepted Institution")
	assert(root:GetAttribute("InstitutionProductionAStatus") == "ACCEPTED", "Production A acceptance is missing")
	assert(root:GetAttribute("InstitutionProductionBStatus") == "ACCEPTED", "Production B acceptance is missing")
	assert(root:GetAttribute("InstitutionProductionARouteRegression") == "PASS", "Production A route proof is not accepted")
	assert(root:GetAttribute("InstitutionProductionBRouteRegression") == "PASS", "Production B route proof is not accepted")
	assert(root:GetAttribute("DynamicDealerCarsCompleted") == 13, "Expected the accepted 13-car proof")
	assert(root:GetAttribute("DynamicConflictSamples") == 0, "Accepted route proof contains conflicts")
	assert(root:GetAttribute("DynamicRecoveryMoves") == 0, "Accepted route proof contains recoveries")

	local layerA = root:FindFirstChild(LAYER_A_NAME)
	local layerB = root:FindFirstChild(LAYER_B_NAME)
	assert(layerA, "Missing accepted Production A layer")
	assert(layerB, "Missing accepted Production B layer")
	assert(layerA:GetAttribute("Version") == EXPECTED_A_VERSION, "Unexpected Production A version")
	assert(layerB:GetAttribute("Version") == EXPECTED_B_VERSION, "Unexpected Production B version")

	local a = snapshot(layerA)
	local b = snapshot(layerB)
	assert(a.Hash == EXPECTED_A_HASH, "Production A geometry differs from the accepted Phase 0 baseline")
	assert(b.Hash == EXPECTED_B_HASH, "Production B geometry differs from the accepted Phase 0 baseline")
	return layerA, layerB, a, b
end

local function clearPhase0(root: Instance)
	local fidelity = root:FindFirstChild(FIDELITY_ROOT_NAME)
	if not fidelity then return end
	local evidence = fidelity:FindFirstChild(EVIDENCE_NAME)
	if evidence then
		local baseline = evidence:FindFirstChild(BASELINE_NAME)
		if baseline then baseline:Destroy() end
		if #evidence:GetChildren() == 0 then evidence:Destroy() end
	end
	if #fidelity:GetChildren() == 0 then fidelity:Destroy() end
	root:SetAttribute("InstitutionFidelityPhase0Version", nil)
	root:SetAttribute("InstitutionFidelityPhase0Status", nil)
	root:SetAttribute("InstitutionFidelityAcceptedAHash", nil)
	root:SetAttribute("InstitutionFidelityAcceptedBHash", nil)
end

function Installer.Install(): {[string]: any}
	local root = Workspace:FindFirstChild(ROOT_NAME)
	assert(root, "Missing V5 root: " .. ROOT_NAME)
	local layerA, layerB, aBefore, bBefore = assertAccepted(root)

	clearPhase0(root)
	local fidelity = root:FindFirstChild(FIDELITY_ROOT_NAME)
	if not fidelity then
		fidelity = Instance.new("Model")
		fidelity.Name = FIDELITY_ROOT_NAME
		fidelity.Parent = root
	end
	assert(fidelity:IsA("Model"), "Fidelity root name is occupied by a non-Model Instance")
	fidelity:SetAttribute("SourceOwned", true)
	fidelity:SetAttribute("Decision", "FID-01")
	fidelity:SetAttribute("Version", Installer.Version)
	fidelity:SetAttribute("StateId", "INSTITUTION")
	fidelity:SetAttribute("FidelityStatus", "PHASE_0_BASELINE")
	fidelity:SetAttribute("PhysicalPartsAdded", 0)
	fidelity:SetAttribute("AcceptedLayersImmutable", true)
	fidelity:SetAttribute("RouteGeometryChanged", false)
	fidelity:SetAttribute("PurchasePadsIncluded", false)

	local evidence = fidelity:FindFirstChild(EVIDENCE_NAME)
	if not evidence then
		evidence = Instance.new("Folder")
		evidence.Name = EVIDENCE_NAME
		evidence.Parent = fidelity
	end
	local baseline = Instance.new("Folder")
	baseline.Name = BASELINE_NAME
	baseline:SetAttribute("Version", Installer.Version)
	baseline:SetAttribute("CapturedOn", "2026-09-03")
	baseline:SetAttribute("Status", "CAPTURED_AWAITING_RUNTIME_AND_ROLLBACK_PROOF")
	baseline:SetAttribute("AcceptedEnvironmentStatus", EXPECTED_ROOT_STATUS)
	baseline:SetAttribute("PhysicalPartsAdded", 0)
	baseline:SetAttribute("PurchasePadsAdded", 0)
	baseline:SetAttribute("RouteGeometryChanged", false)
	baseline.Parent = evidence

	local layers = Instance.new("Folder")
	layers.Name = "01_Accepted_Layers"
	layers:SetAttribute("ProductionASourceSHA256", SOURCE_A_SHA256)
	layers:SetAttribute("ProductionBSourceSHA256", SOURCE_B_SHA256)
	layers:SetAttribute("RouteProofSourceSHA256", ROUTE_PROOF_SHA256)
	layers.Parent = baseline
	local aSnapshot = writeSnapshot(layers, "Production_A", layerA)
	local bSnapshot = writeSnapshot(layers, "Production_B", layerB)
	aSnapshot:SetAttribute("ExpectedHash", EXPECTED_A_HASH)
	bSnapshot:SetAttribute("ExpectedHash", EXPECTED_B_HASH)

	buildLightingSnapshot(baseline)
	local cameras = buildCameraRegistry(baseline)
	local inventory = buildAssemblyInventory(baseline, root, layerA, layerB)

	local route = Instance.new("Folder")
	route.Name = "05_Route_And_Capacity_Evidence"
	route:SetAttribute("ProtectedEnvelopes", root:GetAttribute("ProtectedEnvelopeCount") or 0)
	route:SetAttribute("CapacitySockets", root:GetAttribute("CapacitySocketCount") or 0)
	route:SetAttribute("ProductionBayMaximum", root:GetAttribute("ProductionBayMaximum") or 0)
	route:SetAttribute("DealerCarsCompleted", root:GetAttribute("DynamicDealerCarsCompleted") or 0)
	route:SetAttribute("ParallelBayPairsPassed", root:GetAttribute("DynamicParallelBayPairsPassed") or 0)
	route:SetAttribute("ConflictSamples", root:GetAttribute("DynamicConflictSamples") or -1)
	route:SetAttribute("RecoveryMoves", root:GetAttribute("DynamicRecoveryMoves") or -1)
	route:SetAttribute("ProductionARouteRegression", root:GetAttribute("InstitutionProductionARouteRegression") or "")
	route:SetAttribute("ProductionBRouteRegression", root:GetAttribute("InstitutionProductionBRouteRegression") or "")
	route.Parent = baseline

	local rollback = Instance.new("Folder")
	rollback.Name = "06_Rollback_Proof"
	rollback:SetAttribute("InstallAHash", aBefore.Hash)
	rollback:SetAttribute("InstallBHash", bBefore.Hash)
	rollback:SetAttribute("UninstallStatus", "PENDING")
	rollback:SetAttribute("ReinstallStatus", "PENDING")
	rollback:SetAttribute("AcceptedLayerMutationCount", 0)
	rollback.Parent = baseline
	buildRuntimeBaseline(baseline)

	root:SetAttribute("InstitutionFidelityPhase0Version", Installer.Version)
	root:SetAttribute("InstitutionFidelityPhase0Status", "CAPTURED_AWAITING_PROOF")
	root:SetAttribute("InstitutionFidelityAcceptedAHash", aBefore.Hash)
	root:SetAttribute("InstitutionFidelityAcceptedBHash", bBefore.Hash)

	return {
		FidelityRoot = fidelity,
		Baseline = baseline,
		ProductionAParts = aBefore.Parts,
		ProductionBParts = bBefore.Parts,
		ProductionAHash = aBefore.Hash,
		ProductionBHash = bBefore.Hash,
		CameraCount = cameras:GetAttribute("CameraCount"),
		InventoryRows = inventory:GetAttribute("AssemblyRows"),
		PhysicalPartsAdded = 0,
	}
end

function Installer.MarkProof(uninstallStatus: string, reinstallStatus: string, runtimeStatus: string, runtimeNote: string?): {[string]: any}
	local root = Workspace:FindFirstChild(ROOT_NAME)
	assert(root, "Missing V5 root")
	local layerA, layerB, a, b = assertAccepted(root)
	local fidelity = root:FindFirstChild(FIDELITY_ROOT_NAME)
	assert(fidelity, "Phase 0 fidelity root is not installed")
	local evidence = fidelity:FindFirstChild(EVIDENCE_NAME)
	local baseline = evidence and evidence:FindFirstChild(BASELINE_NAME)
	local rollback = baseline and baseline:FindFirstChild("06_Rollback_Proof")
	assert(baseline and rollback, "Phase 0 evidence is incomplete")

	local installA = rollback:GetAttribute("InstallAHash")
	local installB = rollback:GetAttribute("InstallBHash")
	local mutationCount = 0
	if installA ~= a.Hash then mutationCount += 1 end
	if installB ~= b.Hash then mutationCount += 1 end
	rollback:SetAttribute("UninstallStatus", uninstallStatus)
	rollback:SetAttribute("ReinstallStatus", reinstallStatus)
	rollback:SetAttribute("RuntimeSceneAnalysisStatus", runtimeStatus)
	rollback:SetAttribute("RuntimeSceneAnalysisNote", runtimeNote or "")
	rollback:SetAttribute("VerifiedAHash", a.Hash)
	rollback:SetAttribute("VerifiedBHash", b.Hash)
	rollback:SetAttribute("AcceptedLayerMutationCount", mutationCount)
	rollback:SetAttribute("ProofedOn", "2026-09-03")

	local passed = uninstallStatus == "PASS" and reinstallStatus == "PASS" and mutationCount == 0
	baseline:SetAttribute("Status", if passed then "PHASE_0_ACCEPTED" else "PHASE_0_PROOF_FAILED")
	fidelity:SetAttribute("FidelityStatus", if passed then "PHASE_0_ACCEPTED" else "PHASE_0_PROOF_FAILED")
	root:SetAttribute("InstitutionFidelityPhase0Status", if passed then "ACCEPTED" else "PROOF_FAILED")
	return {
		LayerA = layerA,
		LayerB = layerB,
		Accepted = passed,
		MutationCount = mutationCount,
		ProductionAHash = a.Hash,
		ProductionBHash = b.Hash,
	}
end

function Installer.Uninstall(): {[string]: any}
	local root = Workspace:FindFirstChild(ROOT_NAME)
	if not root then return {Removed = false, Reason = "V5 root missing"} end
	local _, _, a, b = assertAccepted(root)
	clearPhase0(root)
	return {
		Removed = true,
		ProductionAHash = a.Hash,
		ProductionBHash = b.Hash,
		ProductionAMatches = a.Hash == EXPECTED_A_HASH,
		ProductionBMatches = b.Hash == EXPECTED_B_HASH,
	}
end

return Installer

