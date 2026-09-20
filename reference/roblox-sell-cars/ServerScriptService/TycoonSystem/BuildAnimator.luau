--!strict

-- Pads used to blink into existence: one frame absent, the next frame whole. Now their
-- parts grow in one after another, each sailing a little past full size and settling back.
--
-- The animation is carried entirely by Size. Transparency still snaps the way it always
-- did, in `PadService.setModelHidden` - fading it would be invisible at this speed and
-- would fight the scale for attention. A part at 2% size reads as "not there yet" on its
-- own, so scale alone is enough to sell the build.
--
-- Server-driven on purpose: pad ownership already lives on the server, and every player
-- standing in the lot should watch the same machine assemble itself.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildAnimConfig = require(ReplicatedStorage.BuildAnimConfig)

local BuildAnimator = {}

-- One generation counter per model. A second purchase, or a refresh landing mid-build,
-- bumps it so the run already in flight stops touching Size instead of two tween sets
-- fighting over the same parts.
local generation: { [Instance]: number } = {}
local active: { [Instance]: { Tween } } = {}

local MIN_AXIS = 0.01

-- NPC pads are character rigs, and a rig must never be caught by this. Resizing limbs
-- deforms the character, detaches accessories from their attachment points and fights the
-- `_PIVOT0` snap that PadService re-asserts on every refresh. Staff arrive the way they
-- always did - instantly.
local function inRig(part: BasePart, root: Instance): boolean
	local current: Instance? = part.Parent
	while current ~= nil and current ~= root.Parent do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") ~= nil then
			return true
		end
		current = current.Parent
	end
	return false
end

local function partsOf(model: Instance): { BasePart }
	if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") ~= nil then
		return {}
	end
	local parts: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and not inRig(descendant, model) then
			table.insert(parts, descendant)
		end
	end
	if model:IsA("BasePart") then
		table.insert(parts, model)
	end
	return parts
end

-- Authored size, captured once and never overwritten. Everything else keys off this, so a
-- refresh that lands while a part is 30% grown still restores the real size rather than
-- baking the half-grown one in as the truth.
local function authoredSize(part: BasePart): Vector3
	local stored = part:GetAttribute("_S0")
	if typeof(stored) == "Vector3" then
		return stored :: Vector3
	end
	part:SetAttribute("_S0", part.Size)
	return part.Size
end

local function ordered(model: Instance, order: { string }?): { BasePart }
	local parts = partsOf(model)
	local rank: { [string]: number } = {}
	if order ~= nil then
		for index, name in order do
			rank[name] = index
		end
	end
	-- Explorer order is the tie-break for anything the config does not name, so an
	-- unlisted part lands in a stable, obvious place rather than wherever the sort felt
	-- like putting it.
	local discovered: { [BasePart]: number } = {}
	for index, part in parts do
		discovered[part] = index
	end
	local UNLISTED = 1e6
	table.sort(parts, function(a: BasePart, b: BasePart): boolean
		local ra = rank[a.Name] or (UNLISTED + discovered[a])
		local rb = rank[b.Name] or (UNLISTED + discovered[b])
		if ra == rb then
			return discovered[a] < discovered[b]
		end
		return ra < rb
	end)
	return parts
end

local function cancelRun(model: Instance)
	local tweens = active[model]
	if tweens == nil then
		return
	end
	for _, tween in tweens do
		tween:Cancel()
	end
	active[model] = nil
end

-- Collapse every part to nothing. Must run in the same frame as the reveal, before the
-- engine draws anything, or the pad flashes at full size for one frame and then shrinks.
function BuildAnimator.prime(model: Instance, padId: string?)
	local spec = BuildAnimConfig.forPad(padId)
	cancelRun(model)
	generation[model] = (generation[model] or 0) + 1
	for _, part in partsOf(model) do
		local size = authoredSize(part)
		part.Size = Vector3.new(
			math.max(size.X * spec.startScale, MIN_AXIS),
			math.max(size.Y * spec.startScale, MIN_AXIS),
			math.max(size.Z * spec.startScale, MIN_AXIS)
		)
	end
end

-- Grow the parts back, staggered, in config order.
function BuildAnimator.play(model: Instance, padId: string?)
	local spec = BuildAnimConfig.forPad(padId)
	local parts = ordered(model, spec.order)
	if #parts == 0 then
		return
	end

	local token = generation[model] or 0
	local tweens: { Tween } = {}
	active[model] = tweens

	-- The whole build fits inside `duration`: the last part *starts* early enough that its
	-- own pop finishes exactly on time.
	local stagger = if #parts > 1 then math.max(0, (spec.duration - spec.popTime) / (#parts - 1)) else 0

	for index, part in parts do
		local info = TweenInfo.new(
			spec.popTime,
			spec.easingStyle,
			Enum.EasingDirection.Out,
			0,
			false,
			stagger * (index - 1)
		)
		local tween = TweenService:Create(part, info, { Size = authoredSize(part) })
		table.insert(tweens, tween)
		tween:Play()
	end

	-- Land on the authored numbers exactly. Back/Out ends on target anyway, but a
	-- cancelled or interrupted tween does not, and a pad left at 99.4% size would quietly
	-- become the new authored size the next time something captured it.
	task.delay(spec.duration + 0.05, function()
		if generation[model] ~= token or model.Parent == nil then
			return
		end
		for _, part in parts do
			if part.Parent ~= nil then
				part.Size = authoredSize(part)
			end
		end
		active[model] = nil
	end)
end

-- Undo a build instantly: used when a pad goes back to hidden, so a model that was
-- interrupted mid-pop never keeps a shrunken size.
function BuildAnimator.reset(model: Instance)
	cancelRun(model)
	generation[model] = (generation[model] or 0) + 1
	for _, part in partsOf(model) do
		if part:GetAttribute("_S0") ~= nil then
			part.Size = authoredSize(part)
		end
	end
end

return BuildAnimator

