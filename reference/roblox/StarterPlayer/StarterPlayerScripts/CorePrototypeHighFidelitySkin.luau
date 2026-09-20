if game.PlaceId~=105869926920733 or not game:GetService('RunService'):IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("CorePrototypeConfig"))
local CoreUX = ReplicatedStorage:WaitForChild("CoreUX")
local Theme = require(CoreUX:WaitForChild("Theme"))
local Motion = require(CoreUX:WaitForChild("Motion"))
local event = ReplicatedStorage:WaitForChild("CorePrototypeRemotes"):WaitForChild("PrototypeEvent")
local ui = playerGui:WaitForChild("CorePrototypeUI")

local C = Theme.Colors
local METAL = C.Metal
local EDGE = C.Edge
local PAPER = C.Paper
local PAPER_DARK = C.PaperDark
local PURPLE = C.Purple
local MUTED_DARK = Color3.fromRGB(224, 229, 219)

local function getCorner(object)
	local corner = object:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = object
	end
	return corner
end

local function getStroke(object)
	local result = object:FindFirstChildOfClass("UIStroke")
	if not result then
		result = Instance.new("UIStroke")
		result.Parent = object
	end
	return result
end

local function setGradient(object, topColor, bottomColor, rotation)
	local gradient = object:FindFirstChild("HFGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "HFGradient"
		gradient.Parent = object
	end
	gradient.Rotation = rotation or 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	return gradient
end

local function removeGradient(object)
	local gradient = object:FindFirstChild("HFGradient")
	if gradient then gradient:Destroy() end
end

local function styleSurface(object, accent, radius)
	object.BackgroundColor3 = C.Panel
	object.BackgroundTransparency = 0.035
	getCorner(object).CornerRadius = UDim.new(0, radius or Theme.Metrics.PanelRadius)
	local edge = getStroke(object)
	edge.Color = accent or METAL
	edge.Thickness = accent and Theme.Metrics.AccentStroke or Theme.Metrics.Stroke
	edge.Transparency = accent and 0.14 or 0.28
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	removeGradient(object)
end

local function updateActionGradient(button)
	removeGradient(button)
end

local function styleAction(button)
	if button:GetAttribute("HFStyled") then
		updateActionGradient(button)
		return
	end
	button:SetAttribute("HFStyled", true)
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 14
	getCorner(button).CornerRadius = UDim.new(0, 10)
	local edge = getStroke(button)
	edge.Color = C.Ink
	edge.Thickness = 1.5
	edge.Transparency = 0.1
	updateActionGradient(button)
	Motion.AttachPress(button, { pressedScale = Theme.Motion.PressedScale })
end

local function removeSizeConstraint(object)
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("UISizeConstraint") then
			child:Destroy()
		end
	end
end

local hud = ui:WaitForChild("HUD")
styleSurface(hud, nil, 12)
hud.Size = UDim2.fromOffset(350, 62)
local hudFlow = hud:FindFirstChild("Flow")
local hudObjective = hud:FindFirstChild("Objective")
if hudFlow then
	hudFlow.Font = Enum.Font.GothamBlack
	hudFlow.TextColor3 = C.Ink
end
if hudObjective then
	hudObjective.Font = Enum.Font.GothamMedium
end

local cash = ui:WaitForChild("Cash")
styleSurface(cash, C.Green, 13)
local phoneButton = ui:WaitForChild("PhoneButton")
styleSurface(phoneButton, METAL, 13)
styleAction(phoneButton)

local dialogue = ui:WaitForChild("Dialogue")
local dialogueCard = dialogue:WaitForChild("DialogueCard")
local profilePill = dialogue:WaitForChild("ProfilePill")
local npcName = dialogue:WaitForChild("NPCName")
local npcLine = dialogue:WaitForChild("NPCLine")
local dealFacts = dialogue:WaitForChild("DealFacts")
local decisionDock = dialogue:WaitForChild("DecisionDock")

removeSizeConstraint(dialogueCard)
removeSizeConstraint(decisionDock)

dialogueCard.AnchorPoint = Vector2.new(0, 1)
dialogueCard.Position = UDim2.new(0, 14, 1, -100)
dialogueCard.Size = UDim2.fromOffset(292, 94)
styleSurface(dialogueCard, METAL, 15)

profilePill.Visible = false
dealFacts.Visible = false

npcName.Position = UDim2.new(0, 32, 1, -185)
npcName.Size = UDim2.fromOffset(250, 32)
npcName.Font = Theme.Fonts.Display
npcName.TextColor3 = C.Cream
npcName.TextSize = 25

npcLine.Visible = false

local greedPanel = Instance.new("Frame")
greedPanel.Name = "GreedPanel"
greedPanel.Position = UDim2.new(0, 32, 1, -149)
greedPanel.Size = UDim2.fromOffset(250, 28)
greedPanel.BackgroundTransparency = 1
greedPanel.ZIndex = 63
greedPanel.Parent = dialogue

local greedLabel = Instance.new("TextLabel")
greedLabel.Name = "Label"
greedLabel.Size = UDim2.fromOffset(86, 28)
greedLabel.BackgroundTransparency = 1
greedLabel.Font = Theme.Fonts.Strong
greedLabel.Text = "LOW GREED"
greedLabel.TextColor3 = C.Ink
greedLabel.TextSize = 11
greedLabel.TextXAlignment = Enum.TextXAlignment.Left
greedLabel.ZIndex = 64
greedLabel.Parent = greedPanel

local greedSegments = {}
local segments = Instance.new("Frame")
segments.Name = "Segments"
segments.Position = UDim2.fromOffset(91, 7)
segments.Size = UDim2.new(1, -91, 0, 14)
segments.BackgroundTransparency = 1
segments.ZIndex = 64
segments.Parent = greedPanel
local segmentLayout = Instance.new("UIListLayout")
segmentLayout.FillDirection = Enum.FillDirection.Horizontal
segmentLayout.Padding = UDim.new(0, 4)
segmentLayout.Parent = segments

for index = 1, 5 do
	local segment = Instance.new("Frame")
	segment.Name = "Level" .. tostring(index)
	segment.Size = UDim2.new(0.2, -4, 1, 0)
	segment.BackgroundColor3 = C.Metal
	segment.BorderSizePixel = 0
	segment.ZIndex = 64
	segment.Parent = segments
	getCorner(segment).CornerRadius = UDim.new(0, 4)
	table.insert(greedSegments, segment)
end

local function updateGreed()
	local value = math.clamp(dialogue:GetAttribute("Greed") or 0.5, 0, 1)
	local active = math.max(1, math.ceil(value * #greedSegments))
	local greedColor = value >= 0.75 and C.Red or (value >= 0.45 and C.Yellow or C.Green)
	greedLabel.Text = value >= 0.75 and "HIGH GREED" or (value >= 0.45 and "MID GREED" or "LOW GREED")
	greedLabel.TextColor3 = greedColor
	for index, segment in ipairs(greedSegments) do
		local filled = index <= active
		segment.BackgroundColor3 = filled and greedColor or C.Metal
		segment.BackgroundTransparency = filled and 0 or 0.42
	end
end

dialogue:GetAttributeChangedSignal("Greed"):Connect(updateGreed)
updateGreed()

decisionDock.AnchorPoint = Vector2.new(0, 1)
decisionDock.Position = UDim2.new(0, 14, 1, -10)
decisionDock.Size = UDim2.new(1, -28, 0, 74)
decisionDock.BackgroundColor3 = Color3.fromRGB(224, 229, 219)
decisionDock.BackgroundTransparency = 0.02
getCorner(decisionDock).CornerRadius = UDim.new(0, 14)
local dockStroke = getStroke(decisionDock)
dockStroke.Color = METAL
dockStroke.Thickness = 1.4
dockStroke.Transparency = 0.08
removeGradient(decisionDock)

local dockLayout = decisionDock:FindFirstChildOfClass("UIListLayout")
if dockLayout then
	dockLayout.Padding = UDim.new(0, 9)
	dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

local function styleDecisionChild(child)
	if child:IsA("TextButton") then
		child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 1, -12)
		child.TextWrapped = true
		child.TextSize = 16
		styleAction(child)
	end
end
for _, child in ipairs(decisionDock:GetChildren()) do
	styleDecisionChild(child)
end
decisionDock.ChildAdded:Connect(function(child)
	task.defer(styleDecisionChild, child)
end)

local repair = ui:WaitForChild("RepairTracker")
local repairTitle = repair:WaitForChild("RepairTitle")
local repairSteps = repair:WaitForChild("RepairSteps")
removeSizeConstraint(repair)
repair.AnchorPoint = Vector2.new(0.5, 0)
repair.Position = UDim2.new(0.5, 0, 0, 110)
repair.Size = UDim2.new(0.46, 0, 0, 82)
styleSurface(repair, METAL, 14)
local repairConstraint = Instance.new("UISizeConstraint")
repairConstraint.MinSize = Vector2.new(336, 82)
repairConstraint.MaxSize = Vector2.new(520, 82)
repairConstraint.Parent = repair

repairTitle.Position = UDim2.fromOffset(14, 7)
repairTitle.Size = UDim2.new(0.62, -14, 0, 22)
repairTitle.Text = "RESTORE  ·  0/3"
repairTitle.TextColor3 = C.Cream
repairTitle.TextSize = 14
repairTitle.Font = Enum.Font.GothamBlack
repairTitle.TextXAlignment = Enum.TextXAlignment.Left

local repairCondition = Instance.new("TextLabel")
repairCondition.Name = "Condition"
repairCondition.AnchorPoint = Vector2.new(1, 0)
repairCondition.Position = UDim2.new(1, -14, 0, 7)
repairCondition.Size = UDim2.new(0.38, 0, 0, 22)
repairCondition.BackgroundTransparency = 1
repairCondition.Font = Theme.Fonts.Display
repairCondition.Text = "35%"
repairCondition.TextColor3 = C.Orange
repairCondition.TextSize = 12
repairCondition.TextXAlignment = Enum.TextXAlignment.Right
repairCondition.ZIndex = 3
repairCondition.Parent = repair
local repairConditionScale = Instance.new("UIScale")
repairConditionScale.Parent = repairCondition

local repairBar = Instance.new("Frame")
repairBar.Name = "ConditionBar"
repairBar.Position = UDim2.fromOffset(16, 37)
repairBar.Size = UDim2.new(1, -32, 0, 6)
repairBar.BackgroundColor3 = Color3.fromRGB(54, 58, 63)
repairBar.BorderSizePixel = 0
repairBar.ClipsDescendants = true
repairBar.ZIndex = 2
repairBar.Parent = repair
repairBar.Visible = false
getCorner(repairBar).CornerRadius = UDim.new(1, 0)
local repairBarFill = Instance.new("Frame")
repairBarFill.Name = "Fill"
repairBarFill.Size = UDim2.fromScale(0.35, 1)
repairBarFill.BackgroundColor3 = C.Orange
repairBarFill.BorderSizePixel = 0
repairBarFill.ZIndex = 3
repairBarFill.Parent = repairBar
getCorner(repairBarFill).CornerRadius = UDim.new(1, 0)

local repairValue = Instance.new("TextLabel")
repairValue.Name = "Value"
repairValue.Position = UDim2.fromOffset(16, 62)
repairValue.Size = UDim2.new(1, -32, 0, 16)
repairValue.BackgroundTransparency = 1
repairValue.Font = Theme.Fonts.Strong
repairValue.Text = "$900 VALUE"
repairValue.TextColor3 = C.Ink
repairValue.TextSize = 11
repairValue.TextXAlignment = Enum.TextXAlignment.Left
repairValue.ZIndex = 3
repairValue.Parent = repair
repairValue.Visible = true
local repairValueScale = Instance.new("UIScale")
repairValueScale.Parent = repairValue

local repairSpent = Instance.new("TextLabel")
repairSpent.Name = "Invested"
repairSpent.AnchorPoint = Vector2.new(1, 0)
repairSpent.Position = UDim2.new(1, -16, 0, 47)
repairSpent.Size = UDim2.new(0.5, -20, 0, 20)
repairSpent.BackgroundTransparency = 1
repairSpent.Font = Theme.Fonts.Strong
repairSpent.Text = "$900 INVESTED"
repairSpent.TextColor3 = C.Orange
repairSpent.TextSize = 12
repairSpent.TextXAlignment = Enum.TextXAlignment.Right
repairSpent.ZIndex = 3
repairSpent.Parent = repair
repairSpent.Visible = false
local repairSpentScale = Instance.new("UIScale")
repairSpentScale.Parent = repairSpent

repairSteps.Position = UDim2.fromOffset(10, 31)
repairSteps.Size = UDim2.new(1, -20, 0, 29)
local repairLayout = repairSteps:FindFirstChildOfClass("UIListLayout")
if repairLayout then
	repairLayout.FillDirection = Enum.FillDirection.Horizontal
	repairLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	repairLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	repairLayout.Padding = UDim.new(0, 5)
	repairLayout.SortOrder = Enum.SortOrder.LayoutOrder
end

local repairOrder = { "BODY", "WHEELS", "ENGINE" }
for index, name in ipairs(repairOrder) do
	local chip = repairSteps:WaitForChild(name)
	chip.LayoutOrder = index
	chip.Size = UDim2.new(1 / 3, -4, 1, 0)
	chip.BackgroundTransparency = 0.05
	chip.BackgroundColor3 = MUTED_DARK
	chip.TextSize = 10
	chip.Font = Enum.Font.GothamBlack
	chip.TextStrokeTransparency = 1
	getCorner(chip).CornerRadius = UDim.new(0, 9)
	local chipStroke = getStroke(chip)
	chipStroke.Color = METAL
	chipStroke.Thickness = 1.2
	chipStroke.Transparency = 0.12
end

local function money(value)
	local result = tostring(math.floor(tonumber(value) or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return result:gsub("^,", "")
end

local lastCondition, lastRepairValue, lastInvested
local function animateMetric(label, scale, oldValue, newValue, formatter, color)
	local token = (label:GetAttribute("MetricToken") or 0) + 1
	label:SetAttribute("MetricToken", token)
	label.TextColor3 = color
	if oldValue == nil or oldValue == newValue or Motion.IsReducedMotion() then
		label.Text = formatter(newValue)
		scale.Scale = 1
		return
	end
	scale.Scale = 1.08
	task.spawn(function()
		local started = os.clock()
		local duration = 0.38
		while label.Parent and label:GetAttribute("MetricToken") == token do
			local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
			local eased = 1 - (1 - alpha) ^ 3
			local value = oldValue + (newValue - oldValue) * eased
			label.Text = formatter(math.floor(value + 0.5))
			if alpha >= 1 then break end
			RunService.Heartbeat:Wait()
		end
		if label.Parent and label:GetAttribute("MetricToken") == token then
			label.Text = formatter(newValue)
			scale.Scale = 1
		end
	end)
end

local originalProfit = ui:WaitForChild("Profit")
originalProfit:GetPropertyChangedSignal("Visible"):Connect(function()
	if originalProfit.Visible then
		originalProfit.Visible = false
	end
end)
originalProfit.Visible = false

local receiptLayer = Instance.new("Frame")
receiptLayer.Name = "HFProfitReceipt"
receiptLayer.Size = UDim2.fromScale(1, 1)
receiptLayer.BackgroundTransparency = 1
receiptLayer.Visible = false
receiptLayer.ZIndex = 84
receiptLayer.Parent = ui

local receiptBacking = Instance.new("Frame")
receiptBacking.AnchorPoint = Vector2.new(1, 0.5)
receiptBacking.Position = UDim2.new(1, 340, 0.54, 0)
receiptBacking.Size = UDim2.fromOffset(286, 232)
receiptBacking.BackgroundColor3 = Color3.fromRGB(27, 29, 31)
receiptBacking.BorderSizePixel = 0
receiptBacking.ZIndex = 85
receiptBacking.Parent = receiptLayer
getCorner(receiptBacking).CornerRadius = UDim.new(0, 18)
local receiptMetal = getStroke(receiptBacking)
receiptMetal.Color = EDGE
receiptMetal.Thickness = 2
receiptMetal.Transparency = 0.1
setGradient(receiptBacking, Color3.fromRGB(56, 58, 60), Color3.fromRGB(17, 18, 19), 90)

local paper = Instance.new("Frame")
paper.Name = "Paper"
paper.Position = UDim2.fromOffset(13, 13)
paper.Size = UDim2.new(1, -26, 1, -26)
paper.BackgroundColor3 = PAPER
paper.BorderSizePixel = 0
paper.Rotation = 0.8
paper.ZIndex = 86
paper.Parent = receiptBacking
getCorner(paper).CornerRadius = UDim.new(0, 8)
local paperStroke = getStroke(paper)
paperStroke.Color = Color3.fromRGB(184, 164, 124)
paperStroke.Thickness = 1.3
paperStroke.Transparency = 0.2
setGradient(paper, Color3.fromRGB(249, 239, 214), Color3.fromRGB(226, 207, 170), 90)

local receiptTitle = Instance.new("TextLabel")
receiptTitle.Position = UDim2.fromOffset(18, 14)
receiptTitle.Size = UDim2.new(0.58, 0, 0, 34)
receiptTitle.BackgroundTransparency = 1
receiptTitle.Font = Enum.Font.GothamBlack
receiptTitle.Text = "FIRST FLIP"
receiptTitle.TextColor3 = PAPER_DARK
receiptTitle.TextSize = 20
receiptTitle.TextXAlignment = Enum.TextXAlignment.Left
receiptTitle.ZIndex = 87
receiptTitle.Parent = paper

local soldStamp = Instance.new("TextLabel")
soldStamp.AnchorPoint = Vector2.new(1, 0)
soldStamp.Position = UDim2.new(1, -15, 0, 12)
soldStamp.Size = UDim2.fromOffset(82, 35)
soldStamp.BackgroundTransparency = 1
soldStamp.Font = Enum.Font.GothamBlack
soldStamp.Text = "SOLD"
soldStamp.TextColor3 = Color3.fromRGB(47, 126, 67)
soldStamp.TextSize = 20
soldStamp.Rotation = -4
soldStamp.ZIndex = 87
soldStamp.Parent = paper
local stampStroke = getStroke(soldStamp)
stampStroke.Color = Color3.fromRGB(47, 126, 67)
stampStroke.Thickness = 2
stampStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(17, 56)
divider.Size = UDim2.new(1, -34, 0, 2)
divider.BackgroundColor3 = Color3.fromRGB(95, 84, 62)
divider.BackgroundTransparency = 0.35
divider.BorderSizePixel = 0
divider.ZIndex = 87
divider.Parent = paper

local receiptValues = {}
for index, rowName in ipairs({ "INVESTED", "SOLD", "PROFIT" }) do
	local y = 67 + (index - 1) * 42
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(18, y)
	nameLabel.Size = UDim2.new(0.52, 0, 0, 32)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = index == 3 and Enum.Font.GothamBlack or Enum.Font.GothamBold
	nameLabel.Text = rowName
	nameLabel.TextColor3 = index == 3 and Color3.fromRGB(40, 124, 62) or PAPER_DARK
	nameLabel.TextSize = index == 3 and 16 or 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 87
	nameLabel.Parent = paper

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Position = UDim2.new(0.48, 0, 0, y)
	valueLabel.Size = UDim2.new(0.52, -18, 0, 32)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = index == 3 and Enum.Font.GothamBlack or Enum.Font.GothamBold
	valueLabel.Text = "$0"
	valueLabel.TextColor3 = index == 3 and Color3.fromRGB(40, 124, 62) or PAPER_DARK
	valueLabel.TextSize = index == 3 and 22 or 15
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 87
	valueLabel.Parent = paper
	receiptValues[rowName] = valueLabel
end

local nextTab = Instance.new("TextLabel")
nextTab.AnchorPoint = Vector2.new(0.5, 1)
nextTab.Position = UDim2.new(0.5, 0, 1, -14)
nextTab.Size = UDim2.new(1, -34, 0, 46)
nextTab.BackgroundColor3 = C.Yellow
nextTab.BorderSizePixel = 0
nextTab.Font = Enum.Font.GothamBlack
nextTab.Text = "🔧  NEXT · BUILD WORKSHOP"
nextTab.TextColor3 = C.Ink
nextTab.TextSize = 13
nextTab.ZIndex = 87
nextTab.Parent = paper
nextTab.Visible = false
getCorner(nextTab).CornerRadius = UDim.new(0, 9)
local nextStroke = getStroke(nextTab)
nextStroke.Color = Color3.fromRGB(116, 83, 4)
nextStroke.Thickness = 1.4
setGradient(nextTab, C.Yellow:Lerp(Color3.new(1, 1, 1), 0.18), C.Yellow:Lerp(Color3.new(0, 0, 0), 0.12), 90)

local receiptToken = 0
local function showReceipt(data)
	receiptToken += 1
	local token = receiptToken
	local invested = data.invested or ((data.bought or 0) + (data.repairs or 0))
	receiptValues.INVESTED.Text = "-$" .. money(invested)
	receiptValues.SOLD.Text = "+$" .. money(data.sold or 0)
	receiptValues.PROFIT.Text = "+$" .. money(data.profit or 0)
	receiptLayer.Visible = true
	local layoutMargin = ui:GetAttribute("LayoutMargin") or 16
	receiptBacking.Position = UDim2.new(1, 340, 0.54, 0)
	TweenService:Create(receiptBacking, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -layoutMargin, 0.54, 0),
	}):Play()
	task.delay(3.0, function()
		if token ~= receiptToken then return end
		TweenService:Create(receiptBacking, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 340, 0.54, 0),
		}):Play()
		task.delay(0.3, function()
			if token == receiptToken then
				receiptLayer.Visible = false
			end
		end)
	end)
end

local phoneBackdrop = ui:WaitForChild("PhoneBackdrop")
local phoneShell = phoneBackdrop:WaitForChild("PhoneShell")
local phoneScreen = phoneShell:WaitForChild("Screen")
local phoneHeader = phoneScreen:WaitForChild("Header")
local phoneStatus = phoneScreen:WaitForChild("Status")
local leadCard = phoneScreen:WaitForChild("LeadCard")
local leadTag = leadCard:WaitForChild("Tag")
local leadTitle = leadCard:WaitForChild("Title")
local leadValue = leadCard:WaitForChild("Value")
local leadDetail = leadCard:WaitForChild("Detail")
local leadAction = leadCard:WaitForChild("Action")
local leadSecondaryAction = leadCard:WaitForChild("SecondaryAction")

phoneBackdrop.BackgroundTransparency = 1
phoneShell.AnchorPoint = Vector2.new(1, 0.5)
phoneShell.Position = UDim2.new(1, -16, 0.5, 0)
phoneShell.Size = UDim2.fromScale(0.34, 0.94)
getCorner(phoneShell).CornerRadius = UDim.new(0, 30)
local shellStroke = getStroke(phoneShell)
shellStroke.Color = EDGE
shellStroke.Thickness = 3
shellStroke.Transparency = 0.06
setGradient(phoneShell, Color3.fromRGB(39, 42, 46), Color3.fromRGB(4, 5, 6), 90)

phoneScreen.BackgroundColor3 = Color3.fromRGB(13, 15, 17)
setGradient(phoneScreen, Color3.fromRGB(27, 30, 34), Color3.fromRGB(8, 9, 11), 90)
phoneHeader.Font = Enum.Font.GothamBlack
phoneStatus.Font = Enum.Font.GothamBold
styleSurface(leadCard, C.Yellow, 15)
styleAction(leadAction)
styleAction(leadSecondaryAction)
leadSecondaryAction.TextColor3 = C.White

local mystery = Instance.new("Frame")
mystery.Name = "RareSilhouette"
mystery.Position = UDim2.fromScale(0.08, 0.13)
mystery.Size = UDim2.fromScale(0.84, 0.26)
mystery.BackgroundColor3 = Color3.fromRGB(235, 235, 236)
mystery.BackgroundTransparency = 0.03
mystery.BorderSizePixel = 0
mystery.Visible = false
mystery.ZIndex = 75
mystery.Parent = leadCard
getCorner(mystery).CornerRadius = UDim.new(0, 40)
local mysteryStroke = getStroke(mystery)
mysteryStroke.Color = Color3.fromRGB(255, 255, 255)
mysteryStroke.Thickness = 1.4
mysteryStroke.Transparency = 0.25

local question = Instance.new("TextLabel")
question.Size = UDim2.fromScale(1, 1)
question.BackgroundTransparency = 1
question.Font = Enum.Font.GothamBlack
question.Text = "?"
question.TextColor3 = Color3.fromRGB(18, 19, 21)
question.TextSize = 52
question.ZIndex = 76
question.Parent = mystery

local traits = Instance.new("TextLabel")
traits.Name = "RareTraits"
traits.Position = UDim2.fromScale(0.08, 0.51)
traits.Size = UDim2.fromScale(0.84, 0.09)
traits.BackgroundColor3 = Color3.fromRGB(30, 24, 36)
traits.BorderSizePixel = 0
traits.Font = Enum.Font.GothamBlack
traits.Text = "COLLECTOR     ·     PATIENT"
traits.TextColor3 = Color3.fromRGB(227, 211, 244)
traits.TextSize = 10
traits.Visible = false
traits.ZIndex = 75
traits.Parent = leadCard
getCorner(traits).CornerRadius = UDim.new(0, 8)
local traitsStroke = getStroke(traits)
traitsStroke.Color = PURPLE
traitsStroke.Thickness = 1
traitsStroke.Transparency = 0.15

local function refreshPhone()
	local isRare = leadTag.Text == "RARE LEAD"
	local accent = isRare and PURPLE or C.Yellow
	local edge = getStroke(leadCard)
	edge.Color = accent
	edge.Thickness = isRare and 2 or 1.5
	leadTag.TextColor3 = accent
	phoneStatus.TextColor3 = isRare and Color3.fromRGB(192, 139, 238) or C.Yellow
	mystery.Visible = isRare
	traits.Visible = false
	if isRare then
		leadCard.Position = UDim2.fromScale(0.07, 0.20)
		leadCard.Size = UDim2.fromScale(0.86, 0.74)
		leadTag.Position = UDim2.fromScale(0.08, 0.03)
		leadTag.Size = UDim2.fromScale(0.84, 0.09)
		leadTag.TextXAlignment = Enum.TextXAlignment.Center
		leadTitle.Visible = false
		leadValue.Position = UDim2.fromScale(0.08, 0.40)
		leadValue.Size = UDim2.fromScale(0.84, 0.07)
		leadValue.TextColor3 = C.White
		leadValue.TextSize = 10
		leadValue.TextXAlignment = Enum.TextXAlignment.Center
		leadDetail.Position = UDim2.fromScale(0.08, 0.47)
		leadDetail.Size = UDim2.fromScale(0.84, 0.10)
		leadDetail.TextColor3 = Color3.fromRGB(231, 228, 222)
		leadDetail.TextSize = 10
		leadDetail.TextXAlignment = Enum.TextXAlignment.Center
		leadAction.Position = UDim2.fromScale(0.5, 0.77)
		leadAction.Size = UDim2.fromScale(0.84, 0.20)
		leadAction.TextSize = 11
		leadSecondaryAction.Position = UDim2.fromScale(0.5, 0.99)
		leadSecondaryAction.Size = UDim2.fromScale(0.84, 0.20)
		leadSecondaryAction.TextSize = 11
	else
		leadCard.Position = UDim2.fromScale(0.07, 0.23)
		leadCard.Size = UDim2.fromScale(0.86, 0.57)
		leadAction.TextSize = 14
		leadSecondaryAction.TextSize = 14
		leadTitle.Visible = true
		leadTag.Position = UDim2.fromScale(0.08, 0.06)
		leadTag.Size = UDim2.fromScale(0.84, 0.13)
		leadTag.TextXAlignment = Enum.TextXAlignment.Left
		leadValue.Position = UDim2.fromScale(0.08, 0.37)
		leadValue.Size = UDim2.fromScale(0.84, 0.16)
		leadValue.TextColor3 = C.Ink
		leadValue.TextSize = 24
		leadValue.TextXAlignment = Enum.TextXAlignment.Left
		leadDetail.Position = UDim2.fromScale(0.08, 0.54)
		leadDetail.Size = UDim2.fromScale(0.84, 0.16)
		leadDetail.TextColor3 = C.Muted
		leadDetail.TextSize = 12
		leadDetail.TextXAlignment = Enum.TextXAlignment.Left
		leadAction.Position = UDim2.fromScale(0.5, 0.98)
		leadAction.Size = UDim2.fromScale(0.84, 0.25)
	end
	updateActionGradient(leadAction)
	updateActionGradient(leadSecondaryAction)
end
leadTag:GetPropertyChangedSignal("Text"):Connect(function()
	task.defer(refreshPhone)
end)
refreshPhone()

phoneBackdrop:GetPropertyChangedSignal("Visible"):Connect(function()
	if phoneBackdrop.Visible then
		refreshPhone()
		local layoutMargin = ui:GetAttribute("LayoutMargin") or 16
		phoneShell.Position = UDim2.new(1, 300, 0.5, 0)
		TweenService:Create(phoneShell, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -layoutMargin, 0.5, 0),
		}):Play()
	end
end)

local incoming = ui:WaitForChild("IncomingPhone")
local incomingTitle = incoming:WaitForChild("IncomingTitle")
local incomingGlyph = incoming:FindFirstChild("Device") and incoming.Device:FindFirstChildWhichIsA("Frame")
local function refreshIncoming()
	local rare = string.find(string.upper(incomingTitle.Text), "RARE", 1, true) ~= nil
	local incomingStroke = getStroke(incoming)
	incomingStroke.Color = rare and PURPLE or C.Yellow
	incomingStroke.Thickness = 2
	incomingTitle.TextColor3 = rare and Color3.fromRGB(204, 145, 255) or C.Yellow
end
incomingTitle:GetPropertyChangedSignal("Text"):Connect(refreshIncoming)
refreshIncoming()

local function updateRepairState(state)
	if not state or state.stage ~= 3 then return end
	local condition = math.clamp(tonumber(state.condition) or 0, 0, 100)
	local carValue = tonumber(state.carValue) or 0
	local invested = (tonumber(state.purchase) or 0) + (tonumber(state.repairTotal) or 0)
	local conditionColor = condition >= 95 and C.Green or (condition >= 60 and C.Yellow or C.Orange)

	animateMetric(repairCondition, repairConditionScale, lastCondition, condition, function(value)
		return tostring(value) .. "%"
	end, conditionColor)
	animateMetric(repairValue, repairValueScale, lastRepairValue, carValue, function(value)
		return "$" .. money(value) .. " VALUE"
	end, C.Green)
	animateMetric(repairSpent, repairSpentScale, lastInvested, invested, function(value)
		return "$" .. money(value) .. " INVESTED"
	end, C.Orange)
	repairCondition.TextColor3 = conditionColor
	repairValue.TextColor3 = C.Ink
	repairSpent.TextColor3 = C.Orange
	repairBarFill.Size = UDim2.fromScale(condition / 100, 1)
	repairBarFill.BackgroundColor3 = conditionColor
	lastCondition, lastRepairValue, lastInvested = condition, carValue, invested

	local firstOpenFound = false
	local fixedCount = 0
	local fixes = state.fixes or {}
	for index, name in ipairs(repairOrder) do
		local chip = repairSteps:FindFirstChild(name)
		if chip then
			local key = name:sub(1, 1) .. name:sub(2):lower()
			local fixed = fixes[key] == true
			if fixed then fixedCount += 1 end
			local active = not fixed and not firstOpenFound
			if active then firstOpenFound = true end
			chip.Text = (fixed and "✓  " or "") .. name
			chip.TextSize = 12
			chip.TextColor3 = fixed and C.Green or (active and C.Yellow or C.Muted)
			chip.BackgroundColor3 = active and Color3.fromRGB(39, 34, 18) or MUTED_DARK
			local chipEdge = getStroke(chip)
			chipEdge.Color = fixed and C.Green or (active and C.Yellow or METAL)
			chipEdge.Thickness = active and 2 or 1.2
			chipEdge.Transparency = fixed and 0.08 or (active and 0 or 0.18)
		end
	end
	repairTitle.Text = "RESTORE  ·  " .. tostring(fixedCount) .. "/3"
end

local viewportConnection
local function applyLandscapeLayout()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	if viewport.X < 320 or viewport.Y < 180 then
		viewport = ui.AbsoluteSize
	end
	local width, height = viewport.X, viewport.Y
	if width < 320 or height < 180 then return end
	local compact = height < 500 or width < 760
	local margin = compact and 12 or (height < 800 and 18 or 24)
	local dockHeight = compact and 66 or 74
	ui:SetAttribute("LayoutClass", compact and "CompactLandscape" or "Landscape")
	ui:SetAttribute("LayoutMargin", margin)

	-- Persistent world HUD follows the genre's familiar edge lanes:
	-- objective upper-left, phone upper-right, wallet lower-left above touch controls.
	hud.AnchorPoint = Vector2.new(0, 0)
	hud.Position = UDim2.fromOffset(margin, margin)
	hud.Size = UDim2.fromOffset(math.clamp(width * 0.31, compact and 250 or 300, 420), compact and 56 or 62)
	local touchHUD = compact or UserInputService.TouchEnabled
	local walletLift = touchHUD and (compact and 124 or 146) or margin
	cash.AnchorPoint = Vector2.new(0, 1)
	cash.Position = UDim2.new(0, margin, 1, -walletLift)
	cash.Size = UDim2.fromOffset(compact and 122 or 138, compact and 48 or 52)
	phoneButton.AnchorPoint = Vector2.new(1, 0)
	phoneButton.Position = UDim2.new(1, -margin, 0, margin)
	phoneButton.Size = UDim2.fromOffset(compact and 54 or 62, compact and 48 or 52)

	-- Studio QA controls sit under the objective, never in the production wallet lane.
	local devY = margin + (compact and 56 or 62) + 8
	for index, name in ipairs({ "ResetPrototype", "NextFlow", "LayoutAudit" }) do
		local control = ui:FindFirstChild(name)
		if control then
			control.AnchorPoint = Vector2.new(0, 0)
			control.Position = UDim2.fromOffset(margin, devY + ((index - 1) * 34))
		end
	end

	local toast = ui:FindFirstChild("Toast")
	if toast then
		toast.AnchorPoint = Vector2.new(0.5, 0)
		toast.Size = UDim2.fromOffset(math.clamp(width * 0.34, 300, 430), compact and 58 or 64)
		local stripe = toast:FindFirstChild("Stripe")
		if stripe then stripe.Size = UDim2.new(0, 7, 1, 0) end
	end
	local incomingCard = ui:FindFirstChild("IncomingPhone")
	if incomingCard then
		incomingCard.AnchorPoint = Vector2.new(1, 0)
		incomingCard.Size = UDim2.fromOffset(compact and 255 or 292, compact and 58 or 64)
	end

	-- Repair temporarily owns the upper guidance lane; the ordinary objective is hidden in this mode.
	repair.AnchorPoint = Vector2.new(0.5, 0)
	repair.Position = UDim2.new(0.5, 0, 0, margin + 70)
	repair.Size = UDim2.fromOffset(math.clamp(width * 0.42, 336, 520), 82)
	local promptHelper = ui:FindFirstChild("WorldActionHelper")
	if promptHelper then
		promptHelper.AnchorPoint = Vector2.new(1, 1)
		promptHelper.Position = UDim2.new(1, -margin, 1, -margin)
		promptHelper.Size = UDim2.fromOffset(compact and 268 or 310, compact and 66 or 74)
	end
	local padConfirm = ui:FindFirstChild("PadConfirmAction")
	if padConfirm then
		padConfirm.AnchorPoint = Vector2.new(0.5, 1)
		padConfirm.Position = UDim2.new(0.5, 0, 1, -margin)
		padConfirm.Size = UDim2.fromOffset(compact and 270 or 318, compact and 50 or 56)
	end

	-- Negotiation owns a protected bottom lane. Keep it above device chrome/capture crops,
	-- and cap its width on ultrawide displays so the choices remain readable as buttons.
	local decisionBottom = math.max(margin, math.floor(height * 0.075))
	local decisionWidth = math.min(width - (margin * 2), compact and 900 or 1500)
	decisionDock.AnchorPoint = Vector2.new(0.5, 1)
	decisionDock.Position = UDim2.new(0.5, 0, 1, -decisionBottom)
	decisionDock.Size = UDim2.fromOffset(decisionWidth, dockHeight)
	decisionDock.Visible = false
	decisionDock.ZIndex = 162
	for _, child in ipairs(decisionDock:GetChildren()) do
		if child:IsA("GuiButton") then
			child.Visible = true
			child.ZIndex = 163
		end
	end
	local cardBottom = decisionBottom + dockHeight + 10
	dialogueCard.Position = UDim2.new(0, margin, 1, -cardBottom)
	dialogueCard.Size = UDim2.fromOffset(compact and 270 or 292, compact and 88 or 94)
	npcName.Position = UDim2.new(0, margin + 18, 1, -(cardBottom + (compact and 79 or 85)))
	npcName.Size = UDim2.fromOffset(compact and 228 or 250, 30)
	greedPanel.Position = UDim2.new(0, margin + 18, 1, -(cardBottom + (compact and 45 or 49)))
	greedPanel.Size = UDim2.fromOffset(compact and 228 or 250, 28)

	-- Modal sheets use a right-side landscape sheet, never a portrait phone silhouette.
	for _, child in ipairs(phoneShell:GetChildren()) do
		if child:IsA("UIAspectRatioConstraint") then child:Destroy() end
	end
	local phoneWidth = math.min(width - margin * 2, math.clamp(width * 0.39, compact and 330 or 370, 430))
	phoneShell.Position = UDim2.new(1, -margin, 0.5, 0)
	phoneShell.Size = UDim2.fromOffset(phoneWidth, height - margin * 2)
	receiptBacking.Size = UDim2.fromOffset(compact and 268 or 286, math.min(compact and 218 or 232, height - margin * 2))
	if receiptLayer.Visible then receiptBacking.Position = UDim2.new(1, -margin, 0.54, 0) end

	local customize = ui:FindFirstChild("Customize")
	local customSheet = customize and customize:FindFirstChild("Dock")
	if customSheet and customSheet:GetAttribute("SelfResponsive") ~= true then
		customSheet.Position = UDim2.new(0.5, 0, 1, -margin)
		customSheet.Size = UDim2.fromOffset(math.min(width - margin * 2, compact and 700 or 820), math.min(height * 0.62, compact and 228 or 252))
	end
	local returnChoice = ui:FindFirstChild("ReturnChoice")
	local returnPanel = returnChoice and returnChoice:FindFirstChild("Panel")
	if returnPanel then
		returnPanel.Position = UDim2.new(0.5, 0, 1, -margin)
		returnPanel.Size = UDim2.fromOffset(math.min(width - margin * 2, 620), compact and 126 or 138)
	end
	local drive = ui:FindFirstChild("Drive")
	if drive then
		local goal = drive:FindFirstChildWhichIsA("TextLabel")
		if goal then
			goal.Position = UDim2.new(0.5, 0, 0, margin)
			goal.Size = UDim2.fromOffset(math.clamp(width * 0.44, 300, 520), compact and 48 or 56)
		end
	end
end

local function bindViewport()
	if viewportConnection then viewportConnection:Disconnect() end
	viewportConnection = nil
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLandscapeLayout)
	end
	task.defer(applyLandscapeLayout)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLandscapeLayout)
bindViewport()

-- Dialogue content is populated by the core controller. Reassert the interaction lane
-- after that frame so a layout refresh can never leave the speech card without choices.
dialogue:GetPropertyChangedSignal("Visible"):Connect(function()
	if not dialogue.Visible then return end
	task.defer(function()
		if not dialogue.Visible then return end
		decisionDock.Visible = false
		decisionDock.ZIndex = 162
		for _, child in ipairs(decisionDock:GetChildren()) do
			if child:IsA("GuiButton") then
				child.Visible = true
				child.ZIndex = 163
			end
		end
		applyLandscapeLayout()
	end)
end)

decisionDock.ChildAdded:Connect(function(child)
	if not child:IsA("GuiButton") then return end
	child.Visible = true
	child.ZIndex = 163
end)

event.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		task.defer(updateRepairState, data)
	elseif kind == "Profit" then
		task.defer(showReceipt, data)
	elseif kind == "CloseAll" then
		receiptToken += 1
		receiptLayer.Visible = false
	end
end)

print("[CoreUXPrototype] Reference-aligned responsive skin V8 ready")

