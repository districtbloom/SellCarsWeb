--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DealerCarConfig = require(ReplicatedStorage:WaitForChild("DealerCarConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function hideHudStub(name: string)
	local hud = playerGui:FindFirstChild("HUD")
	if hud == nil then
		return
	end
	local inst = hud:FindFirstChild(name)
	if inst ~= nil and inst:IsA("GuiObject") then
		inst.Visible = false
		inst.Active = false
		if inst:IsA("GuiButton") then
			inst.Interactable = false
		end
	end
end
hideHudStub("CarIndexButton")
hideHudStub("CarIndex")
hideHudStub("CarUnlocked")

local screenGui = playerGui:FindFirstChild("CarIndexGui")
if screenGui == nil or not screenGui:IsA("ScreenGui") then
	local created = Instance.new("ScreenGui")
	created.Name = "CarIndexGui"
	created.ResetOnSpawn = false
	created.IgnoreGuiInset = true
	created.DisplayOrder = 80
	created.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	created.Parent = playerGui
	screenGui = created
end
screenGui.Enabled = true
screenGui.DisplayOrder = 300

local remotes = ReplicatedStorage:WaitForChild("TycoonRemotes")
local carIndexRemote = remotes:WaitForChild("CarIndexState") :: RemoteEvent
local requestRemote = remotes:FindFirstChild("RequestCarIndex")
local trafficCars = ReplicatedStorage:WaitForChild("TrafficCars")

local unlocked: { [string]: boolean } = {}
local catalog = DealerCarConfig.catalogCars()
local selectedId: string? = nil
local toastQueue: { string } = {}
local toastBusy = false

local CLASS_COLOR = {
	low = Color3.fromRGB(160, 168, 176),
	mid = Color3.fromRGB(80, 168, 220),
	high = Color3.fromRGB(168, 96, 220),
	hyper = Color3.fromRGB(220, 168, 48),
}

local function applyUnlockedIds(ids: { string })
	table.clear(unlocked)
	for _, carId in ids do
		unlocked[carId] = true
	end
end

local function applyUnlockedAttribute(raw: any)
	if typeof(raw) ~= "string" or raw == "" then
		return
	end
	local ids: { string } = {}
	for token in string.gmatch(raw, "[^,]+") do
		table.insert(ids, token)
	end
	applyUnlockedIds(ids)
end

for _, template in DealerCarConfig.CARS do
	if template.requiresPads == nil and template.unlockRule ~= "fullService" then
		unlocked[template.id] = true
	end
end
applyUnlockedAttribute(player:GetAttribute("CarIndexUnlocked"))

local function ensureGui(): (ImageButton, Frame, Frame, Frame, Frame, TextLabel, TextLabel, TextLabel, TextLabel, TextLabel, ViewportFrame, Frame)
	local button = screenGui:FindFirstChild("CarIndexButton")
	if button == nil or not button:IsA("TextButton") then
		if button ~= nil then
			button:Destroy()
		end
		local created = Instance.new("TextButton")
		created.Name = "CarIndexButton"
		created.Parent = screenGui
		button = created
	end
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Position = UDim2.fromScale(0.018, 0.42)
	button.Size = UDim2.fromScale(0.07, 0.12)
	button.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Active = true
	button.Interactable = true
	button.Visible = true
	button.ZIndex = 20
	button.Font = Enum.Font.GothamBold
	button.Text = "CAR\nINDEX"
	button.TextColor3 = Color3.fromRGB(255, 244, 214)
	button.TextScaled = true
	button.InputSink = Enum.InputSink.Activate
	if button:FindFirstChild("UICorner") == nil then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.16, 0)
		corner.Parent = button
	end
	if button:FindFirstChild("UIStroke") == nil then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(220, 180, 70)
		stroke.Thickness = 1.5
		stroke.Parent = button
	end

	local panel = screenGui:FindFirstChild("CarIndex")
	if panel == nil or not panel:IsA("Frame") then
		local created = Instance.new("Frame")
		created.Name = "CarIndex"
		created.Parent = screenGui
		panel = created
	end
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.fromScale(0.1, 0.5)
	panel.Size = UDim2.fromScale(0.42, 0.72)
	panel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Active = true
	panel.BorderSizePixel = 0
	panel.ZIndex = 25
	panel.InputSink = Enum.InputSink.All
	if panel:FindFirstChild("UICorner") == nil then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.03, 0)
		corner.Parent = panel
	end
	if panel:FindFirstChild("UIStroke") == nil then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(210, 170, 64)
		stroke.Thickness = 1.4
		stroke.Parent = panel
	end

	local title = panel:FindFirstChild("Title")
	if title == nil or not title:IsA("TextLabel") then
		local created = Instance.new("TextLabel")
		created.Name = "Title"
		created.BackgroundTransparency = 1
		created.Position = UDim2.fromScale(0.04, 0.02)
		created.Size = UDim2.fromScale(0.7, 0.08)
		created.Font = Enum.Font.GothamBold
		created.Text = "CAR INDEX"
		created.TextColor3 = Color3.fromRGB(255, 244, 214)
		created.TextXAlignment = Enum.TextXAlignment.Left
		created.TextScaled = true
		created.Parent = panel
		title = created
	end

	local close = panel:FindFirstChild("Close")
	if close == nil or not close:IsA("TextButton") then
		local created = Instance.new("TextButton")
		created.Name = "Close"
		created.AnchorPoint = Vector2.new(1, 0)
		created.Position = UDim2.fromScale(0.97, 0.025)
		created.Size = UDim2.fromScale(0.1, 0.07)
		created.BackgroundColor3 = Color3.fromRGB(48, 28, 28)
		created.Text = "X"
		created.Font = Enum.Font.GothamBold
		created.TextColor3 = Color3.new(1, 1, 1)
		created.TextScaled = true
		created.Parent = panel
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = created
		close = created
	end

	local grid = panel:FindFirstChild("Grid")
	if grid == nil or not grid:IsA("ScrollingFrame") then
		local created = Instance.new("ScrollingFrame")
		created.Name = "Grid"
		created.Position = UDim2.fromScale(0.04, 0.12)
		created.Size = UDim2.fromScale(0.44, 0.84)
		created.BackgroundTransparency = 1
		created.BorderSizePixel = 0
		created.ScrollBarThickness = 4
		created.CanvasSize = UDim2.fromScale(0, 0)
		created.AutomaticCanvasSize = Enum.AutomaticSize.Y
		created.Parent = panel
		local layout = Instance.new("UIGridLayout")
		layout.CellPadding = UDim2.fromScale(0.04, 0.03)
		layout.CellSize = UDim2.fromScale(0.46, 0.22)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = created
		grid = created
	end

	local detail = panel:FindFirstChild("Detail")
	if detail == nil or not detail:IsA("Frame") then
		local created = Instance.new("Frame")
		created.Name = "Detail"
		created.Position = UDim2.fromScale(0.5, 0.12)
		created.Size = UDim2.fromScale(0.46, 0.84)
		created.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
		created.BorderSizePixel = 0
		created.Parent = panel
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.04, 0)
		corner.Parent = created
		detail = created
	end

	local function ensureLabel(name: string, pos: UDim2, size: UDim2, color: Color3): TextLabel
		local existing = detail:FindFirstChild(name)
		if existing ~= nil and existing:IsA("TextLabel") then
			return existing
		end
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = pos
		label.Size = size
		label.Font = Enum.Font.Gotham
		label.TextColor3 = color
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextWrapped = true
		label.TextScaled = true
		label.Text = ""
		label.Parent = detail
		return label
	end

	local nameLabel = ensureLabel("CarName", UDim2.fromScale(0.06, 0.04), UDim2.fromScale(0.88, 0.1), Color3.fromRGB(255, 244, 214))
	nameLabel.Font = Enum.Font.GothamBold
	local classLabel = ensureLabel("CarClass", UDim2.fromScale(0.06, 0.14), UDim2.fromScale(0.88, 0.07), Color3.fromRGB(180, 190, 200))
	local priceLabel = ensureLabel("CarPrice", UDim2.fromScale(0.06, 0.48), UDim2.fromScale(0.88, 0.16), Color3.fromRGB(230, 230, 230))
	local driveLabel = ensureLabel("CarDrive", UDim2.fromScale(0.06, 0.66), UDim2.fromScale(0.88, 0.18), Color3.fromRGB(210, 214, 220))
	local theftLabel = ensureLabel("CarTheft", UDim2.fromScale(0.06, 0.86), UDim2.fromScale(0.88, 0.1), Color3.fromRGB(255, 210, 140))
	theftLabel.Visible = false

	local preview = detail:FindFirstChild("Preview")
	if preview == nil or not preview:IsA("ViewportFrame") then
		local created = Instance.new("ViewportFrame")
		created.Name = "Preview"
		created.Position = UDim2.fromScale(0.08, 0.22)
		created.Size = UDim2.fromScale(0.84, 0.24)
		created.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
		created.BorderSizePixel = 0
		created.Parent = detail
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.08, 0)
		corner.Parent = created
		preview = created
	end

	local toast = screenGui:FindFirstChild("CarUnlocked")
	if toast == nil or not toast:IsA("Frame") then
		local created = Instance.new("Frame")
		created.Name = "CarUnlocked"
		created.Parent = screenGui
		toast = created
	end
	toast.AnchorPoint = Vector2.new(1, 1)
	toast.Position = UDim2.fromScale(0.985, 0.78)
	toast.Size = UDim2.fromScale(0.28, 0.14)
	toast.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	toast.BackgroundTransparency = 0.05
	toast.Visible = false
	toast.BorderSizePixel = 0
	toast.ZIndex = 30
	if toast:FindFirstChild("UICorner") == nil then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.08, 0)
		corner.Parent = toast
	end
	if toast:FindFirstChild("UIStroke") == nil then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(220, 180, 70)
		stroke.Thickness = 1.5
		stroke.Parent = toast
	end
	local toastTitle = toast:FindFirstChild("Title")
	if toastTitle == nil or not toastTitle:IsA("TextLabel") then
		local created = Instance.new("TextLabel")
		created.Name = "Title"
		created.BackgroundTransparency = 1
		created.Position = UDim2.fromScale(0.05, 0.08)
		created.Size = UDim2.fromScale(0.9, 0.28)
		created.Font = Enum.Font.GothamBold
		created.Text = "NEW CAR IN THE CITY"
		created.TextColor3 = Color3.fromRGB(255, 220, 96)
		created.TextScaled = true
		created.TextXAlignment = Enum.TextXAlignment.Left
		created.ZIndex = 31
		created.Parent = toast
		toastTitle = created
	end
	local toastBody = toast:FindFirstChild("Body")
	if toastBody == nil or not toastBody:IsA("TextLabel") then
		local created = Instance.new("TextLabel")
		created.Name = "Body"
		created.BackgroundTransparency = 1
		created.Position = UDim2.fromScale(0.05, 0.4)
		created.Size = UDim2.fromScale(0.9, 0.52)
		created.Font = Enum.Font.Gotham
		created.Text = ""
		created.TextColor3 = Color3.fromRGB(240, 240, 240)
		created.TextWrapped = true
		created.TextScaled = true
		created.TextXAlignment = Enum.TextXAlignment.Left
		created.TextYAlignment = Enum.TextYAlignment.Top
		created.ZIndex = 31
		created.Parent = toast
		toastBody = created
	end

	return button, panel, close, grid, detail, nameLabel, classLabel, priceLabel, driveLabel, theftLabel, preview, toast
end

local button, panel, close, grid, _detail, nameLabel, classLabel, priceLabel, driveLabel, theftLabel, preview, toast = ensureGui()

local function applyUnifiedTypography(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			descendant.Font = Enum.Font.GothamBlack
			descendant:SetAttribute("MoneyTypography", false)
		end
	end
end
applyUnifiedTypography(screenGui)

local function ensureCorner(parent: Instance, radius: number)
	local corner = parent:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = parent
	end
	local typedCorner = corner :: UICorner
	typedCorner.CornerRadius = UDim.new(0, radius)
end

button.AnchorPoint = Vector2.new(0, 0.5)
button.Position = UDim2.new(0, 18, 0.46, 0)
button.Size = UDim2.fromOffset(132, 50)
button.BackgroundColor3 = Color3.fromRGB(38, 218, 255)
button.BackgroundTransparency = 0
button.Font = Enum.Font.FredokaOne
button.Text = "CAR INDEX"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextStrokeColor3 = Color3.fromRGB(11, 57, 73)
button.TextStrokeTransparency = 0.35
button.TextScaled = false
button.TextSize = 19
ensureCorner(button, 12)
local oldGradient = button:FindFirstChild("ModernGradient")
if oldGradient ~= nil then oldGradient:Destroy() end
local buttonStroke = button:FindFirstChildOfClass("UIStroke")
if buttonStroke then
	buttonStroke.Color = Color3.fromRGB(8, 92, 118)
	buttonStroke.Thickness = 2
	buttonStroke.Transparency = 0
end
local oldShadow = screenGui:FindFirstChild("CarIndexButtonShadow")
if oldShadow ~= nil then oldShadow:Destroy() end
local buttonShadow = Instance.new("Frame")
buttonShadow.Name = "CarIndexButtonShadow"
buttonShadow.AnchorPoint = button.AnchorPoint
buttonShadow.Position = button.Position + UDim2.fromOffset(0, 5)
buttonShadow.Size = button.Size
buttonShadow.BackgroundColor3 = Color3.fromRGB(7, 66, 84)
buttonShadow.BackgroundTransparency = 0.08
buttonShadow.BorderSizePixel = 0
buttonShadow.ZIndex = 19
buttonShadow.Parent = screenGui
ensureCorner(buttonShadow, 12)

panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.56, 0.74)
panel.BackgroundColor3 = Color3.fromRGB(17, 20, 25)
panel.BackgroundTransparency = 0.02
ensureCorner(panel, 18)
local sizeConstraint = panel:FindFirstChild("ModernSize")
if sizeConstraint == nil then
	sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.Name = "ModernSize"
	sizeConstraint.Parent = panel
end
local typedSizeConstraint = sizeConstraint :: UISizeConstraint
typedSizeConstraint.MinSize = Vector2.new(620, 460)
typedSizeConstraint.MaxSize = Vector2.new(860, 610)
local panelStroke = panel:FindFirstChildOfClass("UIStroke")
if panelStroke then
	panelStroke.Color = Color3.fromRGB(214, 173, 58)
	panelStroke.Thickness = 1.5
	panelStroke.Transparency = 0.08
end
if panel:FindFirstChild("ModernGradient") == nil then
	local gradient = Instance.new("UIGradient")
	gradient.Name = "ModernGradient"
	gradient.Color = ColorSequence.new(Color3.fromRGB(24, 28, 34), Color3.fromRGB(14, 16, 20))
	gradient.Rotation = 90
	gradient.Parent = panel
end

local title = panel:FindFirstChild("Title") :: TextLabel
title.Position = UDim2.new(0, 28, 0, 18)
title.Size = UDim2.new(1, -100, 0, 34)
title.TextScaled = false
title.TextSize = 28
title.ZIndex = 27
local subtitle = panel:FindFirstChild("Subtitle")
if subtitle == nil then
	subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Parent = panel
end
local subtitleLabel = subtitle :: TextLabel
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Position = UDim2.new(0, 29, 0, 52)
subtitleLabel.Size = UDim2.new(1, -110, 0, 18)
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.Text = "CITY DISCOVERY CATALOG"
subtitleLabel.TextColor3 = Color3.fromRGB(134, 143, 155)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextSize = 11
subtitleLabel.ZIndex = 27
close.Position = UDim2.new(1, -18, 0, 18)
close.Size = UDim2.fromOffset(42, 42)
close.BackgroundColor3 = Color3.fromRGB(43, 31, 33)
close.Text = "×"
close.TextScaled = false
close.TextSize = 28
ensureCorner(close, 11)

local divider = panel:FindFirstChild("HeaderDivider")
if divider == nil then
	divider = Instance.new("Frame")
	divider.Name = "HeaderDivider"
	divider.Parent = panel
end
local dividerFrame = divider :: Frame
dividerFrame.Position = UDim2.new(0, 28, 0, 83)
dividerFrame.Size = UDim2.new(1, -56, 0, 1)
dividerFrame.BackgroundColor3 = Color3.fromRGB(64, 69, 78)
dividerFrame.BackgroundTransparency = 0.35
dividerFrame.BorderSizePixel = 0
dividerFrame.ZIndex = 26

local collectionLabel = panel:FindFirstChild("CollectionLabel")
if collectionLabel == nil then
	collectionLabel = Instance.new("TextLabel")
	collectionLabel.Name = "CollectionLabel"
	collectionLabel.Parent = panel
end
local collection = collectionLabel :: TextLabel
collection.BackgroundTransparency = 1
collection.Position = UDim2.new(0.035, 0, 0, 102)
collection.Size = UDim2.new(0.31, 0, 0, 22)
collection.Font = Enum.Font.GothamBold
collection.Text = "COLLECTION"
collection.TextColor3 = Color3.fromRGB(205, 211, 220)
collection.TextSize = 12
collection.TextXAlignment = Enum.TextXAlignment.Left
collection.ZIndex = 27

grid.Position = UDim2.new(0.035, 0, 0, 132)
grid.Size = UDim2.new(0.31, 0, 1, -153)
grid.BackgroundColor3 = Color3.fromRGB(21, 24, 30)
grid.BackgroundTransparency = 0
grid.ScrollBarThickness = 3
grid.ScrollBarImageColor3 = Color3.fromRGB(192, 158, 62)
grid.ClipsDescendants = true
ensureCorner(grid, 12)
for _, child in grid:GetChildren() do
	if child:IsA("UIGridLayout") or child:IsA("UIListLayout") then child:Destroy() end
end
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = grid
local padding = grid:FindFirstChildOfClass("UIPadding")
if padding == nil then
	padding = Instance.new("UIPadding")
	padding.Parent = grid
end
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 9)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 10)

_detail.Position = UDim2.new(0.37, 0, 0, 101)
_detail.Size = UDim2.new(0.595, 0, 1, -122)
_detail.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
ensureCorner(_detail, 13)
local detailStroke = _detail:FindFirstChildOfClass("UIStroke")
if detailStroke == nil then
	detailStroke = Instance.new("UIStroke")
	detailStroke.Parent = _detail
end
detailStroke.Color = Color3.fromRGB(63, 70, 82)
detailStroke.Thickness = 1
detailStroke.Transparency = 0.25

nameLabel.Position = UDim2.new(0, 22, 0, 18)
nameLabel.Size = UDim2.new(1, -44, 0, 36)
nameLabel.TextScaled = false
nameLabel.TextSize = 27
classLabel.Position = UDim2.new(0, 22, 0, 54)
classLabel.Size = UDim2.new(1, -44, 0, 22)
classLabel.Font = Enum.Font.GothamBold
classLabel.TextScaled = false
classLabel.TextSize = 13
preview.Position = UDim2.new(0, 22, 0, 84)
preview.Size = UDim2.new(1, -44, 0.43, 0)
preview.BackgroundColor3 = Color3.fromRGB(10, 13, 17)
preview.Ambient = Color3.fromRGB(165, 170, 180)
preview.LightColor = Color3.fromRGB(255, 244, 220)
preview.LightDirection = Vector3.new(-0.8, -1, -0.45)
ensureCorner(preview, 11)
local previewStroke = preview:FindFirstChildOfClass("UIStroke")
if previewStroke == nil then
	previewStroke = Instance.new("UIStroke")
	previewStroke.Parent = preview
end
previewStroke.Color = Color3.fromRGB(52, 60, 72)
previewStroke.Thickness = 1
previewStroke.Transparency = 0.25
priceLabel.Position = UDim2.new(0, 22, 0.64, 0)
priceLabel.Size = UDim2.new(1, -44, 0, 50)
priceLabel.Font = Enum.Font.GothamBold
priceLabel.TextScaled = false
priceLabel.TextSize = 17
driveLabel.Position = UDim2.new(0, 22, 0.77, 0)
driveLabel.Size = UDim2.new(1, -44, 0.17, 0)
driveLabel.TextScaled = false
driveLabel.TextSize = 15
theftLabel.Position = UDim2.new(0, 22, 0.91, 0)
theftLabel.Size = UDim2.new(1, -44, 0, 25)
theftLabel.TextScaled = false
theftLabel.TextSize = 13
priceLabel.Position = UDim2.new(0, 22, 0.63, 0)
priceLabel.Size = UDim2.new(1, -44, 0, 30)
priceLabel.TextSize = 15
driveLabel.Position = UDim2.new(0, 22, 0.86, 0)
driveLabel.Size = UDim2.new(1, -44, 0.11, 0)
driveLabel.TextSize = 14

local statsRow = Instance.new("Frame")
statsRow.Name = "VehicleStats"
statsRow.Position = UDim2.new(0, 22, 0.71, 0)
statsRow.Size = UDim2.new(1, -44, 0, 58)
statsRow.BackgroundTransparency = 1
statsRow.ZIndex = 28
statsRow.Parent = _detail

local function makeStatCard(index: number, titleText: string): TextLabel
	local card = Instance.new("Frame")
	card.Name = titleText
	card.Position = UDim2.new((index - 1) * 0.3425, 0, 0, 0)
	card.Size = UDim2.new(0.315, 0, 1, 0)
	card.BackgroundColor3 = Color3.fromRGB(31, 36, 44)
	card.BorderSizePixel = 0
	card.ZIndex = 28
	card.Parent = statsRow
	ensureCorner(card, 9)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(58, 65, 77)
	cardStroke.Thickness = 1
	cardStroke.Transparency = 0.35
	cardStroke.Parent = card
	local titleTextLabel = Instance.new("TextLabel")
	titleTextLabel.BackgroundTransparency = 1
	titleTextLabel.Position = UDim2.new(0, 10, 0, 7)
	titleTextLabel.Size = UDim2.new(1, -20, 0, 14)
	titleTextLabel.Font = Enum.Font.GothamBold
	titleTextLabel.Text = titleText
	titleTextLabel.TextColor3 = Color3.fromRGB(124, 134, 147)
	titleTextLabel.TextSize = 9
	titleTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleTextLabel.ZIndex = 29
	titleTextLabel.Parent = card
	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.Position = UDim2.new(0, 10, 0, 24)
	value.Size = UDim2.new(1, -20, 0, 24)
	value.Font = Enum.Font.GothamBold
	value.Text = "—"
	value.TextColor3 = Color3.fromRGB(238, 240, 244)
	value.TextSize = 14
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.ZIndex = 29
	value.Parent = card
	return value
end

local speedValue = makeStatCard(1, "TOP SPEED")
local handlingValue = makeStatCard(2, "HANDLING")
local accelerationValue = makeStatCard(3, "ACCELERATION")

local toastTitle = toast:FindFirstChild("Title") :: TextLabel
local toastBody = toast:FindFirstChild("Body") :: TextLabel

local function setPreview(modelName: string?)
	for _, child in preview:GetChildren() do
		if child:IsA("WorldModel") or child:IsA("Camera") or child:IsA("Model") then child:Destroy() end
	end
	if modelName == nil then return end
	local template = trafficCars:FindFirstChild(modelName)
	if template == nil or not template:IsA("Model") then return end
	local world = Instance.new("WorldModel")
	world.Parent = preview
	local clone = template:Clone()
	clone.Parent = world
	clone:PivotTo(CFrame.new())
	local camera = Instance.new("Camera")
	camera.FieldOfView = 18
	camera.Parent = preview
	preview.CurrentCamera = camera
	local minPoint = Vector3.new(math.huge, math.huge, math.huge)
	local maxPoint = Vector3.new(-math.huge, -math.huge, -math.huge)
	local visibleCount = 0
	for _, part in clone:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 0.95 then
			local lowerName = string.lower(part.Name)
			if lowerName ~= "root" and lowerName ~= "queuecollision" then
				local half = part.Size * 0.5
				local position = part.Position
				minPoint = Vector3.new(math.min(minPoint.X, position.X-half.X), math.min(minPoint.Y, position.Y-half.Y), math.min(minPoint.Z, position.Z-half.Z))
				maxPoint = Vector3.new(math.max(maxPoint.X, position.X+half.X), math.max(maxPoint.Y, position.Y+half.Y), math.max(maxPoint.Z, position.Z+half.Z))
				visibleCount += 1
			end
		end
	end
	local center: Vector3
	local size: Vector3
	if visibleCount > 0 then
		center = (minPoint + maxPoint) * 0.5
		size = maxPoint - minPoint
	else
		local boxCFrame, boxSize = clone:GetBoundingBox()
		center = boxCFrame.Position
		size = boxSize
	end
	local pivot = clone:GetPivot()
	local direction = (pivot.LookVector * 0.88 + pivot.RightVector * 0.5 + Vector3.new(0, 0.42, 0)).Unit
	local radius = math.max(size.X, size.Z, size.Y * 1.7) * 0.5
	local distance = math.max(6, radius / math.tan(math.rad(camera.FieldOfView * 0.5)) * 0.95)
	camera.CFrame = CFrame.lookAt(center + direction * distance, center + Vector3.new(0, size.Y * 0.03, 0))
end

local function showLockedDetail(template: DealerCarConfig.CarTemplate)
	selectedId = template.id
	nameLabel.Text = "???"
	classLabel.Text = string.upper(template.class) .. "  ·  " .. DealerCarConfig.unlockHint(template)
	classLabel.TextColor3 = CLASS_COLOR[template.class] or Color3.new(1, 1, 1)
	priceLabel.Text = "Unknown until it appears in the city."
	speedValue.Text = "—"
	handlingValue.Text = "—"
	accelerationValue.Text = "—"
	driveLabel.Text = ""
	theftLabel.Text = ""
	setPreview(nil)
end

local function showOpenDetail(template: DealerCarConfig.CarTemplate)
	selectedId = template.id
	nameLabel.Text = template.displayName or template.id
	classLabel.Text = string.upper(template.class)
	classLabel.TextColor3 = CLASS_COLOR[template.class] or Color3.new(1, 1, 1)
	local after = template.baseValue
	for _, part in DealerCarConfig.PARTS do
		after += part.valueBonus
	end
	priceLabel.Text = "ASK  " .. NumberFormat.short(template.baseCost) .. "     VALUE  " .. NumberFormat.short(template.baseValue) .. " – " .. NumberFormat.short(after)
	speedValue.Text = string.format("%d KM/H", template.topSpeedKph or 0)
	handlingValue.Text = string.format("%.1f / 10", template.handlingRating or 0)
	accelerationValue.Text = string.format("%.1f / 10", template.accelerationRating or 0)
	driveLabel.Text = template.handling or ""
	theftLabel.Text = ""
	theftLabel.Visible = false
	setPreview(template.model)
end

local function refreshGrid()
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then child:Destroy() end
	end
	for index, template in catalog do
		local open = unlocked[template.id] == true
		local selected = selectedId == template.id
		local accent = CLASS_COLOR[template.class] or Color3.fromRGB(110, 116, 126)
		local cell = Instance.new("TextButton")
		cell.Name = template.id
		cell.LayoutOrder = index
		cell.Size = UDim2.new(1, -6, 0, 58)
		cell.BackgroundColor3 = if selected then Color3.fromRGB(45, 51, 61) elseif open then Color3.fromRGB(31, 35, 43) else Color3.fromRGB(24, 26, 31)
		cell.BorderSizePixel = 0
		cell.Text = ""
		cell.AutoButtonColor = true
		cell.ZIndex = 28
		cell.Parent = grid
		ensureCorner(cell, 10)
		local stroke = Instance.new("UIStroke")
		stroke.Color = if selected then accent else Color3.fromRGB(54, 60, 70)
		stroke.Thickness = if selected then 1.6 else 1
		stroke.Transparency = if selected then 0.05 else 0.42
		stroke.Parent = cell
		local bar = Instance.new("Frame")
		bar.Position = UDim2.new(0, 0, 0, 8)
		bar.Size = UDim2.new(0, 4, 1, -16)
		bar.BackgroundColor3 = accent
		bar.BackgroundTransparency = if selected then 0 else 0.48
		bar.BorderSizePixel = 0
		bar.ZIndex = 29
		bar.Parent = cell
		ensureCorner(bar, 3)
		local carName = Instance.new("TextLabel")
		carName.BackgroundTransparency = 1
		carName.Position = UDim2.new(0, 14, 0, 7)
		carName.Size = UDim2.new(1, -24, 0, 25)
		carName.Font = Enum.Font.GothamBold
		carName.Text = if open then (template.displayName or template.id) else "UNKNOWN VEHICLE"
		carName.TextColor3 = if open then Color3.fromRGB(237, 239, 243) else Color3.fromRGB(118, 123, 132)
		carName.TextSize = 16
		carName.TextTruncate = Enum.TextTruncate.AtEnd
		carName.TextXAlignment = Enum.TextXAlignment.Left
		carName.ZIndex = 29
		carName.Parent = cell
		local class = Instance.new("TextLabel")
		class.BackgroundTransparency = 1
		class.Position = UDim2.new(0, 14, 0, 32)
		class.Size = UDim2.new(1, -24, 0, 16)
		class.Font = Enum.Font.GothamBold
		class.Text = if open then string.upper(template.class) else "LOCKED"
		class.TextColor3 = if open then accent else Color3.fromRGB(100, 104, 112)
		class.TextSize = 10
		class.TextXAlignment = Enum.TextXAlignment.Left
		class.ZIndex = 29
		class.Parent = cell
		cell.Activated:Connect(function()
			if open then showOpenDetail(template) else showLockedDetail(template) end
			refreshGrid()
		end)
	end
	applyUnifiedTypography(screenGui)
end

local function setPanel(open: boolean)
	panel.Visible = open
	panel.ZIndex = 25
	if open then
		if selectedId == nil then
			local first = nil
			for _, template in catalog do
				if unlocked[template.id] == true then first = template break end
			end
			first = first or catalog[1]
			if first ~= nil then
				if unlocked[first.id] == true then showOpenDetail(first) else showLockedDetail(first) end
			end
		end
		refreshGrid()
	end
end

local function playToast(carId: string)
	local template = DealerCarConfig.templateById(carId)
	local name = if template ~= nil then (template.displayName or template.id) else carId
	local hyper = template ~= nil and template.class == "hyper"
	toastTitle.Text = if hyper then "ULTRA RARE CUSTOMER" else "NEW CAR IN THE CITY"
	toastBody.Text = `Congratulations! {name} has appeared in the city. Now it drives on our streets.`
	toast.Visible = true
	toast.BackgroundTransparency = 0.05
	task.wait(5.5)
	local fade = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
	toast.Visible = false
	toast.BackgroundTransparency = 0.05
end

local function pumpToasts()
	if toastBusy then
		return
	end
	toastBusy = true
	while #toastQueue > 0 do
		local carId = table.remove(toastQueue, 1) :: string
		playToast(carId)
	end
	toastBusy = false
end

local function togglePanel()
	setPanel(not panel.Visible)
end
button.Activated:Connect(togglePanel)
close.Activated:Connect(function()
	setPanel(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		togglePanel()
		return
	end
	if input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape then
		setPanel(false)
	end
end)

player:GetAttributeChangedSignal("CarIndexUnlocked"):Connect(function()
	applyUnlockedAttribute(player:GetAttribute("CarIndexUnlocked"))
	if panel.Visible then
		refreshGrid()
	end
end)

carIndexRemote.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	if typeof(payload.unlocked) == "table" then
		local ids: { string } = {}
		for _, carId in payload.unlocked do
			if typeof(carId) == "string" then
				table.insert(ids, carId)
			end
		end
		applyUnlockedIds(ids)
	end
	if panel.Visible then
		refreshGrid()
	end
	if typeof(payload.toasts) == "table" then
		for _, carId in payload.toasts do
			if typeof(carId) == "string" then
				table.insert(toastQueue, carId)
			end
		end
		task.spawn(pumpToasts)
	end
end)

refreshGrid()
nameLabel.Text = "Select a car"
classLabel.Text = ""
priceLabel.Text = ""
driveLabel.Text = ""
theftLabel.Text = ""
if requestRemote ~= nil and requestRemote:IsA("RemoteEvent") then
	requestRemote:FireServer()
end
print("[CarIndex] ready")

