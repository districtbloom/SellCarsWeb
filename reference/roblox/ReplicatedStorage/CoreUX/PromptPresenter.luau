local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local PromptPresenter = {}
PromptPresenter.__index = PromptPresenter

local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function getAdornee(prompt)
	local parent = prompt.Parent
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment")) then
		return parent
	end
	if parent then
		return parent:FindFirstChildWhichIsA("Attachment", true)
			or parent:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getWorldPosition(adornee)
	if not adornee then return nil end
	if adornee:IsA("Attachment") then return adornee.WorldPosition end
	if adornee:IsA("BasePart") then return adornee.Position end
	return nil
end

local function repairNumbers(prompt)
	local parent = prompt.Parent
	if not parent then return nil, nil end
	local cost = parent:GetAttribute("RepairCost")
	local value = parent:GetAttribute("RepairValue")
	if cost and value then return cost, value end
	local parsedCost, parsedValue = string.match(prompt.ObjectText or "", "%$([%d,]+).-%+%$([%d,]+)")
	return parsedCost, parsedValue
end

function PromptPresenter.new(screenGui, theme, motion)
	local self = setmetatable({}, PromptPresenter)
	self.theme = theme
	self.motion = motion
	self.current = nil
	self.visiblePrompts = {}
	self.connections = {}
	self.refreshClock = 0
	self.displayToken = 0
	self.suppressed = false

	self.root = make("TextButton", {
		Name = "ModelActionHelper",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(270, 72),
		BackgroundColor3 = theme.Colors.Panel,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Selectable = true,
		Visible = false,
		ZIndex = 80,
	}, screenGui)
	corner(self.root, 15)
	stroke(self.root, theme.Colors.Edge, 1.5, 0.08)

	self.action = make("Frame", {
		Name = "Action",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 7, 0.5, 0),
		Size = UDim2.fromOffset(58, 58),
		BackgroundColor3 = theme.Colors.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 81,
	}, self.root)
	corner(self.action, 29)
	stroke(self.action, theme.Colors.Yellow, 2.5, 0)

	self.progress = make("Frame", {
		Name = "Progress",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = theme.Colors.Yellow,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ZIndex = 82,
	}, self.action)

	self.key = make("TextLabel", {
		Name = "Key",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Display,
		Text = "E",
		TextColor3 = theme.Colors.Cream,
		TextSize = 17,
		ZIndex = 83,
	}, self.action)

	self.actionText = make("TextLabel", {
		Name = "ActionText",
		Position = UDim2.fromOffset(76, 9),
		Size = UDim2.new(1, -88, 0, 27),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Display,
		Text = "INTERACT",
		TextColor3 = theme.Colors.Ink,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 81,
	}, self.root)

	self.objectText = make("TextLabel", {
		Name = "ObjectText",
		Position = UDim2.fromOffset(76, 37),
		Size = UDim2.new(1, -88, 0, 21),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Body,
		Text = "",
		TextColor3 = theme.Colors.Cream,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 81,
	}, self.root)

	self.costText = make("TextLabel", {
		Name = "CostText",
		Position = UDim2.fromOffset(76, 37),
		Size = UDim2.fromOffset(80, 21),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Display,
		Text = "",
		TextColor3 = theme.Colors.Orange,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		ZIndex = 82,
	}, self.root)

	self.valueText = make("TextLabel", {
		Name = "ValueText",
		Position = UDim2.fromOffset(158, 37),
		Size = UDim2.new(1, -168, 0, 21),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Display,
		Text = "",
		TextColor3 = theme.Colors.Ink,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = false,
		ZIndex = 82,
	}, self.root)
	self.scale = make("UIScale", { Scale = 1 }, self.root)

	self.marker = make("BillboardGui", {
		Name = "CoreWorldActionMarker",
		AlwaysOnTop = true,
		Enabled = false,
		LightInfluence = 0,
		MaxDistance = 34,
		Size = UDim2.fromOffset(270, 72),
		Active = true,
		StudsOffsetWorldSpace = Vector3.new(0, 0.9, 0),
	}, screenGui.Parent)
	self.root.Parent = screenGui

	self.root.InputBegan:Connect(function(input)
		if not self.current then return end
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.current:InputHoldBegin()
		end
	end)
	self.root.InputEnded:Connect(function(input)
		if not self.current then return end
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.current:InputHoldEnd()
		end
	end)

	local function belongsToPrototype(prompt)
		local world = workspace:FindFirstChild("CoreUXPrototype")
		return world and prompt:IsDescendantOf(world)
	end
	self.belongsToPrototype = belongsToPrototype

	local function prepare(item)
		if item:IsA("ProximityPrompt") and belongsToPrototype(item) then
			item.Style = Enum.ProximityPromptStyle.Custom
		end
	end
	for _, item in ipairs(workspace:GetDescendants()) do prepare(item) end
	table.insert(self.connections, workspace.DescendantAdded:Connect(prepare))

	table.insert(self.connections, ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if not belongsToPrototype(prompt) then return end
		self.visiblePrompts[prompt] = inputType
		self:Refresh()
	end))
	table.insert(self.connections, ProximityPromptService.PromptHidden:Connect(function(prompt)
		self.visiblePrompts[prompt] = nil
		self:Refresh()
	end))
	table.insert(self.connections, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		if self.current ~= prompt then return end
		self.progress.Size = UDim2.fromScale(1, 0)
		local hold = math.max(prompt.HoldDuration, 0.12)
		self.progressTween = TweenService:Create(self.progress, TweenInfo.new(hold, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(1, 1),
		})
		self.progressTween:Play()
	end))
	table.insert(self.connections, ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		if self.current ~= prompt then return end
		if self.progressTween then self.progressTween:Cancel() end
		self.progress.Size = UDim2.fromScale(1, 0)
	end))
	table.insert(self.connections, RunService.Heartbeat:Connect(function(dt)
		self:PositionOnModel()
		self.refreshClock += dt
		if self.refreshClock >= 0.12 then
			self.refreshClock = 0
			self:Refresh()
		end
	end))
	return self
end

-- Screen-space rendering follows the actual model every frame; never docks to a corner.
function PromptPresenter:PositionOnModel()
 local camera = workspace.CurrentCamera
 local position = getWorldPosition(self.marker.Adornee)
 if not self.current or self.suppressed or not camera or not position then
  self.root.Visible = false
  return
 end
 local point, visible = camera:WorldToViewportPoint(position + self.marker.StudsOffsetWorldSpace)
 local inset = self.root.Parent.IgnoreGuiInset and Vector2.zero or game:GetService("GuiService"):GetGuiInset()
 self.root.Position = UDim2.fromOffset(point.X - inset.X, point.Y - inset.Y)
 self.root.Visible = visible and point.Z > 0
end

function PromptPresenter:SetSuppressed(suppressed)
	self.suppressed = suppressed == true
	if self.suppressed then self:Hide() else self:Refresh() end
end

function PromptPresenter:Refresh()
	if self.suppressed then
		if self.current or self.root.Visible then self:Hide() end
		return
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("CoreUXPrototype")
	if world and playerRoot then
		local fallbackInput = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
			and Enum.ProximityPromptInputType.Touch or Enum.ProximityPromptInputType.Keyboard
		for _, item in ipairs(world:GetDescendants()) do
			if item:IsA("ProximityPrompt") then
				local adornee = getAdornee(item)
				local position = getWorldPosition(adornee)
				local inRange = item.Enabled and position
					and (playerRoot.Position - position).Magnitude <= item.MaxActivationDistance
				if inRange then
					self.visiblePrompts[item] = self.visiblePrompts[item] or fallbackInput
				else
					self.visiblePrompts[item] = nil
				end
			end
		end
	end

	local bestPrompt, bestInput, bestScore
	for prompt, inputType in pairs(self.visiblePrompts) do
		if prompt.Parent and prompt.Enabled and self.belongsToPrototype(prompt) then
			local adornee = getAdornee(prompt)
			local position = getWorldPosition(adornee)
			local distance = playerRoot and position and (playerRoot.Position - position).Magnitude or 0
			local rank = prompt.Parent:GetAttribute("PromptRank") or 100
			local score = rank * 1000 + distance
			if not bestScore or score < bestScore then
				bestPrompt, bestInput, bestScore = prompt, inputType, score
			end
		else
			self.visiblePrompts[prompt] = nil
		end
	end
	if bestPrompt then
		self:Show(bestPrompt, bestInput)
	elseif self.current then
		self:Hide()
	end
end

function PromptPresenter:Show(prompt, inputType)
	if self.suppressed then return end
	local samePrompt = self.current == prompt
	self.current = prompt
	self.displayToken += 1
	local adornee = getAdornee(prompt)
	self.marker.Adornee = adornee
	self.marker.MaxDistance = math.max(prompt.MaxActivationDistance + 8, 24)
	local parentName = prompt.Parent and prompt.Parent.Name or ""
	if string.find(parentName, "RepairAnchor") then
		self.marker.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	elseif string.find(string.upper(prompt.ActionText or ""), "TALK") then
		self.marker.StudsOffsetWorldSpace = Vector3.new(0, 3.1, 0)
	else
		self.marker.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	end
	self.marker.Enabled = false

	self.actionText.Text = string.upper(prompt.ActionText ~= "" and prompt.ActionText or "INTERACT")
	local cost, value = repairNumbers(prompt)
	local hasEconomy = cost ~= nil and value ~= nil
	self.objectText.Visible = not hasEconomy
	self.costText.Visible = hasEconomy
	self.valueText.Visible = hasEconomy
	if hasEconomy then
		self.costText.Text = "-$" .. tostring(cost) .. " COST"
		self.valueText.Text = "+$" .. tostring(value) .. " VALUE"
	else
		self.objectText.Text = string.upper(prompt.ObjectText or "")
	end

	local isTouch = inputType == Enum.ProximityPromptInputType.Touch
		or UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if isTouch then
		self.key.Text = prompt.HoldDuration > 0 and "HOLD" or "TAP"
		self.key.TextSize = prompt.HoldDuration > 0 and 10 or 13
	else
		self.key.Text = prompt.KeyboardKeyCode.Name
		self.key.TextSize = 17
	end
	self.progress.Size = UDim2.fromScale(1, 0)
	self:PositionOnModel()
	if not samePrompt then
		self.root.BackgroundTransparency = 0.18
		self.scale.Scale = 0.94
		self.motion.Tween(self.root, 0.16, {
			BackgroundTransparency = 0.02,
		})
		self.motion.Tween(self.scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(0.19, function()
			if self.current == prompt and self.root.Parent then
						self.root.BackgroundTransparency = 0.02
				self.scale.Scale = 1
			end
		end)
	end
end

function PromptPresenter:Hide()
	self.current = nil
	self.displayToken += 1
	local token = self.displayToken
	if self.progressTween then self.progressTween:Cancel() end
	self.progress.Size = UDim2.fromScale(1, 0)
	self.marker.Enabled = false
	self.marker.Adornee = nil
	self.motion.Tween(self.scale, 0.12, { Scale = 0.94 }, Enum.EasingStyle.Quad)
	self.motion.Tween(self.root, 0.12, { BackgroundTransparency = 0.2 }, Enum.EasingStyle.Quad)
	task.delay(0.13, function()
		if self.displayToken == token and not self.current and self.root.Parent then
			self.root.Visible = false
		end
	end)
end

function PromptPresenter:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.root:Destroy()
	self.marker:Destroy()
end

return PromptPresenter

