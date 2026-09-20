--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local NumberFormat = require(ReplicatedStorage.NumberFormat)
local TycoonService = require(script.Parent.TycoonService)
local DataService = require(script.Parent.DataService)
local GameplayEvents = require(script.Parent.GameplayEvents)
local BuildAnimator = require(script.Parent.BuildAnimator)
local Remotes = require(script.Parent.JunkLot.Remotes)
require(script.Parent.CarIndexService)

type Record = TycoonService.TycoonRecord

local PadService = {}

local debounces: { [Instance]: number } = {}
local PAD_COLOR_ATTRIBUTE = "_PurchasePadColor0"
local PAD_ID_ATTRIBUTE = "PurchasePadId"
local PAD_COST_ATTRIBUTE = "PurchasePadCost"
local PAD_EFFECT_ATTRIBUTE = "PurchasePadEffect"
local PAD_OPEN_ATTRIBUTE = "PurchasePadOpen"

local function zoneFor(record: Record, definition: TycoonConfig.PadDefinition): Instance?
	return record.zones[definition.zone]
end

local function findPadPart(zone: Instance, padName: string): BasePart?
	local found = zone:FindFirstChild(padName, true)
	if found ~= nil and found:IsA("BasePart") then
		return found
	end
	return nil
end

type NameIndex = { [string]: { Instance } }

local function buildIndex(record: Record): { [string]: NameIndex }
	local wanted: { [string]: boolean } = {}
	for _, definition in TycoonConfig.PADS do
		for _, name in definition.models do
			wanted[name] = true
		end
	end

	for _, child in record.locked:GetChildren() do
		if wanted[child.Name] then
			child.Parent = record.zone
		end
	end

	local index: { [string]: NameIndex } = {}
	for zoneId, zone in record.zones do
		local byName: NameIndex = {}
		for _, descendant in zone:GetDescendants() do
			if wanted[descendant.Name] then
				local bucket = byName[descendant.Name]
				if bucket == nil then
					bucket = {}
					byName[descendant.Name] = bucket
				end
				table.insert(bucket, descendant)
			end
		end
		index[zoneId] = byName
	end
	return index
end

local function collectModels(index: { [string]: NameIndex }, definition: TycoonConfig.PadDefinition): { Instance }
	local byName = index[definition.zone]
	if byName == nil then
		return {}
	end
	local found: { Instance } = {}
	for _, name in definition.models do
		local bucket = byName[name]
		if bucket ~= nil then
			for _, instance in bucket do
				table.insert(found, instance)
			end
		end
	end
	return found
end

local function ownLabel(padPart: BasePart): BillboardGui?
	local roots: { Instance } = { padPart }
	local base = padPart.Parent
	if base ~= nil then
		table.insert(roots, base)
	end
	for _, root in roots do
		for _, child in root:GetDescendants() do
			if child:IsA("BillboardGui") and child.Name ~= "PadLabel" then
				return child
			end
		end
	end
	return nil
end

local function labelTexts(billboard: BillboardGui): (TextLabel?, TextLabel?)
	local title: TextLabel? = nil
	local price: TextLabel? = nil
	for _, child in billboard:GetDescendants() do
		if child:IsA("TextLabel") then
			if child.Name == "Price" then
				price = child
			elseif title == nil then
				title = child
			end
		end
	end
	return title, price
end

local function setPartHidden(part: Instance, hidden: boolean)
	if part:IsA("BasePart") then
		if part:GetAttribute("_T0") == nil then
			part:SetAttribute("_T0", part.Transparency)
			part:SetAttribute("_C0", part.CanCollide)
			part:SetAttribute("_H0", part.CanTouch)
			part:SetAttribute("_Q0", part.CanQuery)
		end
		if hidden then
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		else
			part.Transparency = (part:GetAttribute("_T0") :: number?) or 0
			part.CanCollide = (part:GetAttribute("_C0") :: boolean?) == true
			part.CanTouch = (part:GetAttribute("_H0") :: boolean?) == true
			part.CanQuery = (part:GetAttribute("_Q0") :: boolean?) == true
		end
		-- SurfaceGui / BillboardGui still draw on fully transparent parts — kill them with the mesh.
		for _, child in part:GetChildren() do
			if child:IsA("LayerCollector") then
				if child:GetAttribute("_E0") == nil then
					child:SetAttribute("_E0", child.Enabled)
				end
				child.Enabled = if hidden then false else (child:GetAttribute("_E0") :: boolean?) ~= false
			end
		end
	elseif part:IsA("LayerCollector") or part:IsA("ProximityPrompt") then
		if part:GetAttribute("_E0") == nil then
			part:SetAttribute("_E0", part.Enabled)
		end
		part.Enabled = if hidden then false else (part:GetAttribute("_E0") :: boolean?) ~= false
	elseif part:IsA("Decal") or part:IsA("Texture") then
		if part:GetAttribute("_T0") == nil then
			part:SetAttribute("_T0", part.Transparency)
		end
		part.Transparency = if hidden then 1 else ((part:GetAttribute("_T0") :: number?) or 0)
	elseif part:IsA("Light") or part:IsA("ParticleEmitter") or part:IsA("Beam") then
		if part:GetAttribute("_E0") == nil then
			part:SetAttribute("_E0", part.Enabled)
		end
		part.Enabled = if hidden then false else ((part:GetAttribute("_E0") :: boolean?) == true)
	end
end

local function setNpcPartNonBlocking(part: BasePart, anchorIdle: boolean)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	if anchorIdle then
		part.Anchored = true
	end
end

local function setModelHidden(model: Instance, hidden: boolean)
	setPartHidden(model, hidden)
	for _, descendant in model:GetDescendants() do
		setPartHidden(descendant, hidden)
	end
	-- Humanoids keep rewriting CanCollide on character parts, which turns unbought NPCs
	-- into invisible walls you can jump on. Never run the state machine for lot staff:
	-- after ApplyDescription it yanks unanchored limbs and leaves a floating head.
	local humanoid = if model:IsA("Model") then model:FindFirstChildOfClass("Humanoid") else nil
	if humanoid ~= nil then
		humanoid.EvaluateStateMachine = false
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		-- ApplyDescription and accessory attachment can add physical descendants after this
		-- refresh. Keep every staff rig non-blocking for its full lifetime, bought or ghost.
		if model:IsA("Model") and model:GetAttribute("_NonBlockingNpcGuard") ~= true then
			model:SetAttribute("_NonBlockingNpcGuard", true)
			model.DescendantAdded:Connect(function(descendant)
				if not descendant:IsA("BasePart") then return end
				task.defer(function()
					if descendant.Parent ~= nil and descendant:IsDescendantOf(model) then
						setNpcPartNonBlocking(descendant, model:GetAttribute("Built") ~= true)
					end
				end)
			end)
		end
		-- Remember where the rig was authored the first time we touch it, so a reveal can
		-- always put it back exactly there.
		if model:IsA("Model") and model:GetAttribute("_PIVOT0") == nil then
			model:SetAttribute("_PIVOT0", model:GetPivot())
		end
		-- LotNpc / BayStaff unanchor the limbs when they take a rig out on a job, so an
		-- unanchored limb is the signal that somebody is currently driving this one and
		-- it must be left alone. A hidden rig is never being driven.
		local driven = false
		if not hidden then
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" and not descendant.Anchored then
					driven = true
					break
				end
			end
		end

		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				-- Idle rigs stay fully anchored. These are constraint-driven and every part
				-- is massless, so an unanchored assembly hanging off one anchored root gets
				-- flung by the solver - the bay mechanic ended up 25 studs above his own
				-- workstation.
				setNpcPartNonBlocking(descendant, not driven)
			end
		end

		-- An idle rig belongs on its authored pivot, so snapping it back here is safe and
		-- self-correcting. It has to be re-asserted rather than done once on the purchase
		-- edge: attaching a rig's accessories shoves the root even while it is anchored
		-- (the move lands with an empty Lua traceback, so it is the engine doing it), and
		-- that shove arrives after the first refresh.
		local authored = model:GetAttribute("_PIVOT0")
		if not driven and typeof(authored) == "CFrame" and model:IsA("Model") then
			model:PivotTo(authored :: CFrame)
		end
	end
	model:SetAttribute("Built", not hidden)
end

local function setPadVisible(padPart: BasePart, visible: boolean, definition: TycoonConfig.PadDefinition)
	-- Replicated pad metadata lets the owner's client react to leaderstats.Cash without a
	-- server refresh for every dollar earned. PurchasePadOpen is distinct from CanTouch so
	-- locked/bought pads remain unambiguously hidden while unaffordable pads stay usable and
	-- can still produce the existing exact-shortfall feedback on touch.
	if padPart:GetAttribute(PAD_COLOR_ATTRIBUTE) == nil then
		padPart:SetAttribute(PAD_COLOR_ATTRIBUTE, padPart.Color)
	end
	padPart:SetAttribute(PAD_ID_ATTRIBUTE, definition.id)
	padPart:SetAttribute(PAD_COST_ATTRIBUTE, definition.cost)
	padPart:SetAttribute(PAD_EFFECT_ATTRIBUTE, TycoonConfig.padEffectText(definition))
	padPart:SetAttribute(PAD_OPEN_ATTRIBUTE, visible)

	setPartHidden(padPart, not visible)
	-- Buy pads are touch triggers, never physical walls - including the thick PadBase.
	padPart.CanCollide = false
	padPart.CanTouch = visible

	local base = padPart.Parent
	if base ~= nil and base:IsA("BasePart") then
		-- If several buy pads ever share one PadBase, don't let a locked sibling hide the
		-- black plate out from under an unlocked pad.
		local baseShouldShow = visible
		if not visible then
			for _, sibling in base:GetChildren() do
				if sibling:IsA("BasePart") and sibling ~= padPart and sibling.Name:find("BuyPad", 1, true) then
					if sibling.Transparency < 1 then
						baseShouldShow = true
						break
					end
				end
			end
		end
		setPartHidden(base, not baseShouldShow)
		base.CanCollide = false
	end

	local billboard = ownLabel(padPart)
	if billboard ~= nil then
		billboard.Enabled = visible
		local title, price = labelTexts(billboard)
		if title ~= nil then
			title.Text = string.upper(definition.title)
		end
		if price ~= nil then
			-- Keep the server-authored normal form identical to the client renderer.
			-- A single canonical value avoids replicated Text reconciliation churn.
			price.Text = if definition.cost <= 0 then "FREE" else "$" .. NumberFormat.short(definition.cost)
		end
	end
	local mine = padPart:FindFirstChild("PadLabel")
	if mine ~= nil then
		mine:Destroy()
	end
end

local function setOwnerVisible(part: Instance, visible: boolean)
	if part:IsA("BasePart") then
		if part:GetAttribute("_O0") == nil then
			part:SetAttribute("_O0", part.Transparency)
			part:SetAttribute("_OC0", part.CanCollide)
			part:SetAttribute("_OH0", part.CanTouch)
			part:SetAttribute("_OQ0", part.CanQuery)
		end
		if visible then
			part.Transparency = (part:GetAttribute("_O0") :: number?) or 0
			part.CanCollide = (part:GetAttribute("_OC0") :: boolean?) == true
			part.CanTouch = (part:GetAttribute("_OH0") :: boolean?) == true
			part.CanQuery = (part:GetAttribute("_OQ0") :: boolean?) == true
		else
			-- Invisible content must be absent from every physics and query surface.
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	elseif part:IsA("Decal") or part:IsA("Texture") then
		if part:GetAttribute("_O0") == nil then
			part:SetAttribute("_O0", part.Transparency)
		end
		part.Transparency = if visible then ((part:GetAttribute("_O0") :: number?) or 0) else 1
	elseif part:IsA("LayerCollector")
		or part:IsA("ProximityPrompt")
		or part:IsA("Light")
		or part:IsA("ParticleEmitter")
		or part:IsA("Beam")
	then
		-- Transparent owner-only parts do not suppress SurfaceGui/BillboardGui drawing,
		-- and an invisible terminal must not leave an active prompt behind. Preserve the
		-- authored state so a later claim restores exactly what the tycoon shipped with.
		if part:GetAttribute("_OE0") == nil then
			part:SetAttribute("_OE0", part.Enabled)
		end
		part.Enabled = if visible then ((part:GetAttribute("_OE0") :: boolean?) == true) else false
	end
end

local function isDealerContent(instance: Instance): boolean
	local current: Instance? = instance
	while current ~= nil and current ~= game do
		if current.Name == "DealerCars" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isPersonalGarageExpansionContent(instance: Instance): boolean
	local current: Instance? = instance
	while current ~= nil and current ~= game do
		if current.Name == "GarageExpansionPad" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function applyOwnerVisibility(record: Record, managed: { [Instance]: boolean })
	local visible = record.owner ~= nil
	for _, descendant in record.folder:GetDescendants() do
		if managed[descendant]
			or isDealerContent(descendant)
			or isPersonalGarageExpansionContent(descendant)
		then
			continue
		end
		setOwnerVisible(descendant, visible)
	end
end

local function purchasedPads(record: Record): { [string]: boolean }
	local pads: { [string]: boolean } = {}
	if record.owner == nil then
		return pads
	end
	for _, definition in TycoonConfig.PADS do
		if TycoonService.hasPad(record, definition.id) then
			pads[definition.id] = true
		end
	end
	return pads
end

local function progressionContext(record: Record, pads: { [string]: boolean }): (boolean, number)
	local owner = record.owner
	if owner == nil then
		return false, 1
	end
	local data: any = DataService.get(owner)
	if data == nil then
		return false, 1
	end
	local tutorialComplete = data.tutorial ~= nil and data.tutorial.completed == true
	local savedChapter = if data.progression ~= nil and typeof(data.progression.chapter) == "number"
		then math.clamp(math.floor(data.progression.chapter), 1, 6)
		else 1
	return tutorialComplete, math.max(savedChapter, TycoonConfig.deriveChapter(pads, tutorialComplete))
end

-- Extra service helpers remain purchasable capacity, but they must never take over
-- the progression objective or its ground arrow from the Repair Bay → Tow Truck spine.
local GUIDE_EXCLUDED_PADS = {
	ServiceHelper2 = true,
	ServiceHelper3 = true,
}

local function tutorialGateAllows(record: Record, definition: TycoonConfig.PadDefinition): boolean
	if definition.id ~= "FirstSalesman" or record.owner == nil then
		return true
	end
	local data = DataService.get(record.owner)
	if data == nil or data.tutorial.completed == true or data.pads.FirstSalesman == true then
		return true
	end
	if data.tutorial.eligible ~= true or math.floor(data.tutorial.dealIndex) ~= 1 then
		return false
	end
	for index = 1, DataService.workingCapacityForPads(data.pads) do
		local car = DataService.getWorking(data, index)
		if car ~= nil and car.tutorialDealIndex == 1 and car.state == "Ready" then
			return true
		end
	end
	return false
end

local function recommendedPad(
	record: Record,
	pads: { [string]: boolean },
	tutorialComplete: boolean,
	chapter: number
): (TycoonConfig.PadDefinition?, number)
	local best: TycoonConfig.PadDefinition? = nil
	local bestScore = math.huge
	local availableCount = 0
	for _, definition in TycoonConfig.PADS do
		if pads[definition.id] ~= true
			and TycoonConfig.isPadUnlocked(definition, pads, tutorialComplete, chapter)
			and tutorialGateAllows(record, definition)
		then
			availableCount += 1
			if GUIDE_EXCLUDED_PADS[definition.id] == true then
				continue
			end
			-- The active chapter objective always wins over optional capacity left behind.
			local definitionChapter = definition.chapter or 1
			local score = (if definitionChapter == chapter then 0 else 10000)
				+ (definition.chapterOrder or definition.priority or definition.order)
			if score < bestScore then
				best = definition
				bestScore = score
			end
		end
	end
	return best, availableCount
end

local function publishNextPad(record: Record)
	local nextDefinition: TycoonConfig.PadDefinition? = nil
	local availableCount = 0
	if record.owner ~= nil then
		local pads = purchasedPads(record)
		local tutorialComplete, chapter = progressionContext(record, pads)
		nextDefinition, availableCount = recommendedPad(record, pads, tutorialComplete, chapter)
		record.folder:SetAttribute("CurrentChapter", chapter)
	else
		record.folder:SetAttribute("CurrentChapter", nil)
	end
	record.folder:SetAttribute("NextPadId", if nextDefinition ~= nil then nextDefinition.id else nil)
	record.folder:SetAttribute("NextPadTitle", if nextDefinition ~= nil then nextDefinition.title else nil)
	record.folder:SetAttribute("NextPadCost", if nextDefinition ~= nil then nextDefinition.cost else nil)
	record.folder:SetAttribute("NextPadCategory", if nextDefinition ~= nil then nextDefinition.category else nil)
	record.folder:SetAttribute("NextPadKind", if nextDefinition ~= nil then nextDefinition.kind else nil)
	record.folder:SetAttribute("NextPadBonus", if nextDefinition ~= nil then nextDefinition.bonus else nil)
	record.folder:SetAttribute("AvailablePadCount", availableCount)
end

local function publishMultipliers(record: Record)
	local owner = record.owner
	local pads: { [string]: boolean } = {}
	if owner ~= nil then
		for _, definition in TycoonConfig.PADS do
			if TycoonService.hasPad(record, definition.id) then
				pads[definition.id] = true
			end
		end
	end
	for _, zone in TycoonConfig.ZONES do
		record.folder:SetAttribute(`CashMultiplier_{zone.id}`, TycoonConfig.cashMultiplier(pads, zone.id))
		record.folder:SetAttribute(`SpeedMultiplier_{zone.id}`, TycoonConfig.effectiveSpeedMultiplier(pads, zone.id))
	end
end

-- `models` matches instances by name anywhere in the zone, and several pads wrap a model
-- in a folder that carries the same name (JunkSpot.WheelBalancer contains
-- Props1.WheelBalancer). Animating both would put two competing tween sets on the same
-- parts, so only the outermost match of each nest gets built.
local function outermost(models: { Instance }): { Instance }
	local roots: { Instance } = {}
	for _, model in models do
		local nested = false
		for _, other in models do
			if other ~= model and model:IsDescendantOf(other) then
				nested = true
				break
			end
		end
		if not nested then
			table.insert(roots, model)
		end
	end
	return roots
end

local function centreOf(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	end
	if instance:IsA("Model") then
		local ok, cframe = pcall(function()
			return (instance :: Model):GetBoundingBox()
		end)
		if ok then
			return cframe.Position
		end
	end
	local total = Vector3.zero
	local count = 0
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			total += descendant.Position
			count += 1
		end
	end
	return if count > 0 then total / count else nil
end

-- Every successful purchase must have one authoritative destination for the Junk Spot
-- build spark. Multiple model roots are treated as one purchased construction, so the
-- spark lands at the centre of the whole reveal instead of depending on a Built signal
-- from whichever nested model happens to replicate first.
local function purchaseTarget(record: Record, definition: TycoonConfig.PadDefinition): Vector3?
	local roots = outermost(collectModels(buildIndex(record), definition))
	local total = Vector3.zero
	local count = 0
	for _, root in roots do
		local point = centreOf(root)
		if point ~= nil then
			total += point
			count += 1
		end
	end
	return if count > 0 then total / count else nil
end

-- `animatePadId` is the pad the player just bought. Only that one gets the build-in
-- animation: every other reveal here is a load, a claim or a release, where the lot has to
-- come up already finished rather than assembling itself in front of a player who did
-- nothing.
function PadService.refresh(record: Record, animatePadId: string?)
	local owner = record.owner
	local pads = purchasedPads(record)
	local index = buildIndex(record)
	local managed: { [Instance]: boolean } = {}
	for _, definition in TycoonConfig.PADS do
		local zone = zoneFor(record, definition)
		if zone == nil then
			continue
		end
		local enabled = TycoonConfig.isPadEnabled(definition)
		-- A merged legacy/bundle member still owns its authored model, but never exposes a pad.
		local bought = pads[definition.id] == true
		local tutorialComplete, chapter = progressionContext(record, pads)
		local unlocked = enabled and owner ~= nil
			and TycoonConfig.isPadUnlocked(definition, pads, tutorialComplete, chapter)
			and tutorialGateAllows(record, definition)

		local models = collectModels(index, definition)
		local animate = bought and animatePadId == definition.id
		local buildRoots: { Instance } = if animate then outermost(models) else {}
		-- Shrink before the reveal, not after: they have to land in the same frame or the
		-- pad flashes at full size for one frame and then collapses.
		for _, root in buildRoots do
			BuildAnimator.prime(root, definition.id)
		end
		for _, model in models do
			if not bought then
				BuildAnimator.reset(model)
			end
			setModelHidden(model, not bought)
			managed[model] = true
			for _, descendant in model:GetDescendants() do
				managed[descendant] = true
			end
		end
		for _, root in buildRoots do
			BuildAnimator.play(root, definition.id)
		end
		local padPart = findPadPart(zone, definition.pad)
		if padPart ~= nil then
			setPadVisible(padPart, owner ~= nil and not bought and unlocked, definition)
			managed[padPart] = true
			for _, descendant in padPart:GetDescendants() do
				managed[descendant] = true
			end
			local base = padPart.Parent
			if base ~= nil and base:IsA("BasePart") then
				managed[base] = true
			end
		end
	end
	applyOwnerVisibility(record, managed)
	publishNextPad(record)
	publishMultipliers(record)
end

local function purchase(
	record: Record,
	definition: TycoonConfig.PadDefinition,
	player: Player,
	interactionPad: BasePart?
)
	if TycoonService.hasPad(record, definition.id) then
		return
	end
	local pads = purchasedPads(record)
	local tutorialComplete, chapter = progressionContext(record, pads)
	if not TycoonConfig.isPadUnlocked(definition, pads, tutorialComplete, chapter)
		or not tutorialGateAllows(record, definition)
	then
		return
	end
	local data = DataService.get(player)
	local purchased, reason = DataService.tryPurchasePad(player, definition.id, definition.cost)
	if not purchased then
		if data ~= nil then
			local shortfall = definition.cost - data.cash
			if shortfall > 0 then
				local feedback: any = {
					reason = "funds",
					needed = shortfall,
					title = definition.title,
				}
				-- Only a physical owner touch may arm the world-pad blocked presentation.
				-- BuyNext and any future non-world purchase path keep their existing notification.
				if interactionPad ~= nil then
					feedback.surface = "purchasePad"
					feedback.padId = definition.id
					feedback.pad = interactionPad
				end
				Remotes.InsufficientFunds:FireClient(player, feedback)
			end
		end
		if reason ~= "funds" then
			warn(`[PadService] critical purchase failed for {player.Name}/{definition.id}: {reason}`)
		end
		return
	end
	TycoonService.syncCash(player)
	-- Tell only the owner which exact authored pad was committed. The client animates a
	-- temporary visual copy, so hiding the authoritative touch trigger/build is immediate.
	local purchasedZone = zoneFor(record, definition)
	local purchasedPad = if purchasedZone ~= nil then findPadPart(purchasedZone, definition.pad) else nil
	Remotes.PadPurchased:FireClient(player, {
		padId = definition.id,
		pad = purchasedPad,
		target = purchaseTarget(record, definition),
		title = definition.title,
		effectText = TycoonConfig.padEffectText(definition),
	})
	PadService.refresh(record, definition.id)
	TycoonService.padPurchased:Fire(record, definition, player)
end

local function onPadTouched(record: Record, definition: TycoonConfig.PadDefinition, padPart: BasePart, hit: BasePart)
	-- Accessory handles often touch a pad before a limb does. Resolve the owning character
	-- through ancestors so the first physical contact can purchase immediately.
	local character = hit:FindFirstAncestorOfClass("Model")
	if character == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player == nil or player ~= record.owner then
		return
	end
	local now = os.clock()
	local last = debounces[padPart]
	if last ~= nil and now - last < TycoonConfig.PAD_DEBOUNCE then
		return
	end
	debounces[padPart] = now
	purchase(record, definition, player, padPart)
end

local function onBuyNext(player: Player)
	local record = TycoonService.getForPlayer(player)
	if record == nil or record.owner ~= player then
		return
	end
	local now = os.clock()
	local last = debounces[player]
	if last ~= nil and now - last < TycoonConfig.PAD_DEBOUNCE then
		return
	end
	debounces[player] = now
	local pads = purchasedPads(record)
	local tutorialComplete, chapter = progressionContext(record, pads)
	local definition = recommendedPad(record, pads, tutorialComplete, chapter)
	if definition ~= nil then
		purchase(record, definition, player)
	end
end

function PadService.bind(record: Record)
	-- Accessories and late-authored descendants may appear after the initial hide pass. If
	-- any ancestor is an unbuilt purchase root, normalize the new object immediately so it
	-- cannot become a one-frame ghost wall or touch/query target.
	if record.folder:GetAttribute("_PadDescendantGuardBound") ~= true then
		record.folder:SetAttribute("_PadDescendantGuardBound", true)
		record.folder.DescendantAdded:Connect(function(descendant: Instance)
			task.defer(function()
				if descendant.Parent == nil then return end
				local ancestor: Instance? = descendant.Parent
				while ancestor ~= nil and ancestor ~= record.folder do
					if ancestor:GetAttribute("Built") == false then
						setPartHidden(descendant, true)
						return
					end
					ancestor = ancestor.Parent
				end
			end)
		end)
	end
	for _, child in record.locked:GetChildren() do
		child.Parent = record.zone
	end
	-- Accessory attachment nudges the rigs a moment after the place finishes loading, so
	-- one late pass puts every idle NPC back where it was authored.
	task.delay(3, function()
		if record.folder.Parent ~= nil then
			PadService.refresh(record)
		end
	end)
	for _, definition in TycoonConfig.PADS do
		local zone = zoneFor(record, definition)
		if zone == nil then
			continue
		end
		local padPart = findPadPart(zone, definition.pad)
		if padPart == nil then
			warn(`[PadService] {record.folder.Name}: pad part '{definition.pad}' not found in {definition.zone}`)
			continue
		end
		padPart.Touched:Connect(function(hit: BasePart)
			onPadTouched(record, definition, padPart, hit)
		end)
	end
	PadService.refresh(record)
end

function PadService.init()
	ReplicatedStorage.TycoonRemotes.BuyPad.OnServerEvent:Connect(onBuyNext)

	for _, record in TycoonService.getAll() do
		PadService.bind(record)
	end
	TycoonService.tycoonClaimed.Event:Connect(function(record: Record)
		PadService.refresh(record)
	end)
	TycoonService.tycoonReleased.Event:Connect(function(record: Record)
		PadService.refresh(record)
	end)
	-- Tutorial completion changes chapter access without buying a pad. Re-apply every pad's
	-- visibility after the authoritative sale receipt so Cash Register materializes at once.
	GameplayEvents.connect("CarSold", function(player: Player)
		task.defer(function()
			local record = TycoonService.getForPlayer(player)
			local data = DataService.get(player)
			if record ~= nil
				and record.owner == player
				and data ~= nil
				and data.tutorial.completed == true
			then
				PadService.refresh(record)
			end
		end)
	end)
	-- Rusty's Ready transition is what reveals the tutorial Salesman pad. The event is
	-- emitted just before DealerCar commits Ready, so defer one scheduling turn.
	GameplayEvents.connect("RepairCompleted", function(player: Player, payload: any)
		if typeof(payload) ~= "table" or tonumber(payload.tutorialDealIndex) ~= 1 then
			return
		end
		task.defer(function()
			local record = TycoonService.getForPlayer(player)
			if record ~= nil and record.owner == player then
				PadService.refresh(record)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		debounces[player] = nil
	end)
end

return PadService
