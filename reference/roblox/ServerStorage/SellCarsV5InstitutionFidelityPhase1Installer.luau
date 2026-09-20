--!strict

-- Sell Cars V5 — Institution Fidelity R1 / Phase 1 shared-kit proof installer.
-- Installs only under 10_Institution_Fidelity_R1/00_Shared_Kit.

local ServerStorage = game:GetService("ServerStorage")

local ROOT_NAME = "SellCars_Dealership_Growth_V5"
local FIDELITY_LAYER_NAME = "10_Institution_Fidelity_R1"
local PHASE_NAME = "00_Shared_Kit"
local EVIDENCE_NAME = "99_Shared_Kit_Evidence"
local EXPECTED_A_HASH = "26945dcb"
local EXPECTED_B_HASH = "358dbf5d"
local PROOF_ORIGIN = Vector3.new(3130, 0, -125)

local Installer = {}
Installer.Version = "2026-09-03.v5-institution-fidelity-phase1.1"

local function requireRoot(): Model
	local root = workspace:FindFirstChild(ROOT_NAME)
	assert(root and root:IsA("Model"), "Accepted V5 dealership root is missing")
	assert(root:GetAttribute("InstitutionFidelityPhase0Status") == "ACCEPTED", "Phase 0 must be accepted")
	assert(root:GetAttribute("InstitutionFidelityAcceptedAHash") == EXPECTED_A_HASH, "Accepted Production A hash changed")
	assert(root:GetAttribute("InstitutionFidelityAcceptedBHash") == EXPECTED_B_HASH, "Accepted Production B hash changed")
	assert(root:GetAttribute("InstitutionProductionAStatus") == "ACCEPTED", "Production A is not accepted")
	assert(root:GetAttribute("InstitutionProductionBStatus") == "ACCEPTED", "Production B is not accepted")
	return root :: Model
end

local function requireFidelityLayer(root: Model): Model
	local layer = root:FindFirstChild(FIDELITY_LAYER_NAME)
	assert(layer and layer:IsA("Model"), "Institution fidelity layer is missing")
	return layer :: Model
end

local function countClasses(root: Instance): {[string]: number}
	local result = {
		Instances = 0,
		Parts = 0,
		Models = 0,
		Scripts = 0,
		Lights = 0,
		Sounds = 0,
		Effects = 0,
		Attachments = 0,
		MetadataModels = 0,
		IncompleteMetadataModels = 0,
	}
	local required = {
		"BundleId", "FunctionId", "ZoneId", "FidelityRole", "PhaseMin", "InheritanceRule",
		"AssetStatus", "CollisionClass", "InteractionAnchor", "FXSocket", "SourceGeometry",
	}
	for _, item in ipairs(root:GetDescendants()) do
		result.Instances += 1
		if item:IsA("BasePart") then result.Parts += 1 end
		if item:IsA("Model") then
			result.Models += 1
			if item:GetAttribute("V5FidelitySharedKit") then
				result.MetadataModels += 1
				for _, key in ipairs(required) do
					if item:GetAttribute(key) == nil then
						result.IncompleteMetadataModels += 1
						break
					end
				end
			end
		end
		if item:IsA("BaseScript") or item:IsA("ModuleScript") then result.Scripts += 1 end
		if item:IsA("Light") then result.Lights += 1 end
		if item:IsA("Sound") then result.Sounds += 1 end
		if item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("Smoke") or item:IsA("Fire") or item:IsA("Sparkles") then result.Effects += 1 end
		if item:IsA("Attachment") then result.Attachments += 1 end
	end
	return result
end

local function overlappingParts(a: Instance, b: Instance): {BasePart}
	local bParts = {}
	for _, item in ipairs(b:GetDescendants()) do if item:IsA("BasePart") then table.insert(bParts, item) end end
	if #bParts == 0 then return {} end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = bParts
	params.RespectCanCollide = false
	params.MaxParts = 0
	local found = {}
	local seen: {[BasePart]: boolean} = {}
	for _, item in ipairs(a:GetDescendants()) do
		if item:IsA("BasePart") then
			for _, hit in ipairs(workspace:GetPartBoundsInBox(item.CFrame, item.Size, params)) do
				if not seen[hit] then seen[hit] = true; table.insert(found, hit) end
			end
		end
	end
	return found
end

local function hashProof(layer: Instance): string
	local rows = {}
	for _, item in ipairs(layer:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(rows, string.format("%s|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f", item:GetFullName(), item.Position.X, item.Position.Y, item.Position.Z, item.Size.X, item.Size.Y, item.Size.Z))
		end
	end
	table.sort(rows)
	local hash = 2166136261
	for _, row in ipairs(rows) do
		for index = 1, #row do
			hash = bit32.bxor(hash, string.byte(row, index))
			hash = (hash * 16777619) % 4294967296
		end
	end
	return string.format("%08x", hash)
end

local function writeEvidence(root: Model, phase: Model): Folder
	local previous = phase:FindFirstChild(EVIDENCE_NAME)
	if previous then previous:Destroy() end
	local evidence = Instance.new("Folder")
	evidence.Name = EVIDENCE_NAME
	evidence.Parent = phase
	local counts = countClasses(phase)
	for key, value in pairs(counts) do evidence:SetAttribute(key, value) end
	local clearances = root:FindFirstChild("03_Protected_Clearances")
	local routes = root:FindFirstChild("02_Vehicle_Routes")
	local clearanceHits = if clearances then overlappingParts(phase, clearances) else {}
	local routeHits = if routes then overlappingParts(phase, routes) else {}
	evidence:SetAttribute("ProtectedClearanceConflicts", #clearanceHits)
	evidence:SetAttribute("VehicleRouteConflicts", #routeHits)
	evidence:SetAttribute("AcceptedAHash", tostring(root:GetAttribute("InstitutionFidelityAcceptedAHash")))
	evidence:SetAttribute("AcceptedBHash", tostring(root:GetAttribute("InstitutionFidelityAcceptedBHash")))
	evidence:SetAttribute("ProofHash", hashProof(phase))
	evidence:SetAttribute("ReviewLabels", 0)
	evidence:SetAttribute("PurchasePads", 0)
	evidence:SetAttribute("RouteGeometryChanged", false)
	evidence:SetAttribute("ProofOrigin", tostring(PROOF_ORIGIN))
	return evidence
end

function Installer.Install()
	local root = requireRoot()
	local fidelity = requireFidelityLayer(root)
	local old = fidelity:FindFirstChild(PHASE_NAME)
	if old then old:Destroy() end

	local kitModule = ServerStorage:FindFirstChild("SellCarsV5InstitutionFidelitySharedKit")
	assert(kitModule and kitModule:IsA("ModuleScript"), "Shared kit ModuleScript is missing")
	local Kit = require(kitModule :: ModuleScript)

	local phase = Instance.new("Model")
	phase.Name = PHASE_NAME
	phase:SetAttribute("Version", Installer.Version)
	phase:SetAttribute("Decision", "FID-01")
	phase:SetAttribute("Phase", 1)
	phase:SetAttribute("StateId", "INSTITUTION")
	phase:SetAttribute("FidelityStatus", "PHASE_1_BUILT_AWAITING_REVIEW")
	phase:SetAttribute("AcceptedLayersImmutable", true)
	phase:SetAttribute("RouteGeometryChanged", false)
	phase:SetAttribute("PurchasePadsIncluded", false)
	phase:SetAttribute("ReviewOnlyProof", true)
	phase:SetAttribute("ProofOrigin", tostring(PROOF_ORIGIN))
	phase:SetAttribute("ProofRetiresBeforePhase2Acceptance", true)
	phase.Parent = fidelity

	Kit.BuildProofRack(phase, PROOF_ORIGIN)
	local evidence = writeEvidence(root, phase)
	root:SetAttribute("InstitutionFidelityPhase1Status", "BUILT_AWAITING_REVIEW")
	root:SetAttribute("InstitutionFidelityPhase1Version", Installer.Version)
	root:SetAttribute("InstitutionFidelityPhase1ProofHash", evidence:GetAttribute("ProofHash"))
	return phase, evidence
end

function Installer.Validate()
	local root = requireRoot()
	local fidelity = requireFidelityLayer(root)
	local phase = fidelity:FindFirstChild(PHASE_NAME)
	assert(phase and phase:IsA("Model"), "Phase 1 proof is not installed")
	local evidence = writeEvidence(root, phase :: Model)
	local pass = evidence:GetAttribute("IncompleteMetadataModels") == 0
		and evidence:GetAttribute("ProtectedClearanceConflicts") == 0
		and evidence:GetAttribute("VehicleRouteConflicts") == 0
		and evidence:GetAttribute("Scripts") == 0
		and evidence:GetAttribute("Sounds") == 0
		and evidence:GetAttribute("Effects") == 0
	return pass, evidence
end

function Installer.Accept(visualVerdict: string, visualNotes: string?)
	assert(visualVerdict == "PASS", "Phase 1 acceptance requires explicit visual PASS")
	local root = requireRoot()
	local fidelity = requireFidelityLayer(root)
	local phase = fidelity:FindFirstChild(PHASE_NAME)
	assert(phase and phase:IsA("Model"), "Phase 1 proof is not installed")
	local pass, evidence = Installer.Validate()
	assert(pass, "Phase 1 validation gates are not clean")
	local Kit = require(ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
	Kit.MarkModelerReady(phase)
	phase:SetAttribute("FidelityStatus", "PHASE_1_ACCEPTED")
	phase:SetAttribute("VisualVerdict", visualVerdict)
	phase:SetAttribute("VisualNotes", visualNotes or "")
	phase:SetAttribute("AcceptedProofHash", evidence:GetAttribute("ProofHash"))
	evidence:SetAttribute("VisualVerdict", visualVerdict)
	evidence:SetAttribute("AcceptanceStatus", "ACCEPTED")
	root:SetAttribute("InstitutionFidelityPhase1Status", "ACCEPTED")
	return phase, evidence
end

function Installer.RecordRuntime(data: {[string]: any})
	local root = requireRoot()
	local phase = requireFidelityLayer(root):FindFirstChild(PHASE_NAME)
	assert(phase and phase:IsA("Model"), "Phase 1 proof is not installed")
	local evidence = phase:FindFirstChild(EVIDENCE_NAME)
	assert(evidence and evidence:IsA("Folder"), "Phase 1 evidence is missing")
	for key, value in pairs(data) do evidence:SetAttribute(key, value) end
	evidence:SetAttribute("RuntimeRecorded", true)
	return evidence
end

function Installer.SetProofVisible(isVisible: boolean)
	local root = requireRoot()
	local phase = requireFidelityLayer(root):FindFirstChild(PHASE_NAME)
	assert(phase and phase:IsA("Model"), "Phase 1 proof is not installed")
	local rack = phase:FindFirstChild("01_Proof_Rack")
	assert(rack, "Proof rack is missing")
	for _, item in ipairs(rack:GetDescendants()) do
		if item:IsA("BasePart") then item.Transparency = if isVisible then (item:GetAttribute("InteractionAnchor") and 1 or 0) else 1 end
	end
	phase:SetAttribute("ProofVisible", isVisible)
end

function Installer.Uninstall()
	local root = requireRoot()
	local fidelity = requireFidelityLayer(root)
	local phase = fidelity:FindFirstChild(PHASE_NAME)
	if phase then phase:Destroy() end
	root:SetAttribute("InstitutionFidelityPhase1Status", nil)
	root:SetAttribute("InstitutionFidelityPhase1Version", nil)
	root:SetAttribute("InstitutionFidelityPhase1ProofHash", nil)
	return true
end

return Installer

