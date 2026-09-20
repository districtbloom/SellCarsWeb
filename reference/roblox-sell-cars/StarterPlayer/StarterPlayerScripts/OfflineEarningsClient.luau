--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local shown = false

type ScreenGuiState = { target: ScreenGui, enabled: boolean }
type WorldGuiState = { target: BillboardGui | SurfaceGui, enabled: boolean }
type GuiObjectState = { target: GuiObject, visible: boolean }

local function formatMoney(value: number): string
	local amount = math.max(0, math.floor(value))
	local text = tostring(amount)
	repeat
		local changed
		text, changed = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until changed == 0
	return "$" .. text
end

local function formatAway(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm", math.max(1, minutes))
end

local function corner(parent: Instance, radius: number)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Thickness = thickness
	item.Transparency = transparency
	item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	item.Parent = parent
end

local function button(parent: Instance, name: string, text: string, color: Color3, position: UDim2): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.AnchorPoint = Vector2.new(0.5, 0)
	item.Position = position
	item.Size = UDim2.new(1, -60, 0, 54)
	item.BackgroundColor3 = color
	item.BorderSizePixel = 0
	item.AutoButtonColor = false
	item.Font = Enum.Font.RobotoCondensed
	item.Text = text
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.TextSize = 18
	item.ZIndex = 4
	item.Parent = parent
	corner(item, 8)
	stroke(item, Color3.fromRGB(7, 10, 13), 2, 0.28)
	return item
end

local function showPopup(amount: number, awaySeconds: number)
	if shown or amount <= 0 then
		return
	end
	shown = true

	while player.Parent ~= nil
		and (playerGui:GetAttribute("MVPDealModal") ~= nil or playerGui:GetAttribute("SellCarsWorkshopModalOpen") == true)
	do
		task.wait(0.25)
	end
	if player.Parent == nil then
		return
	end

	local previous = playerGui:FindFirstChild("OfflineEarningsUI")
	if previous ~= nil then
		previous:Destroy()
	end

	local previousModal = playerGui:GetAttribute("MVPDealModal")
	local previousDetails = playerGui:GetAttribute("MVPDetailsOpen")
	playerGui:SetAttribute("MVPDealModal", "OfflineEarnings")
	playerGui:SetAttribute("MVPDetailsOpen", true)

	local gui = Instance.new("ScreenGui")
	gui.Name = "OfflineEarningsUI"
	gui.DisplayOrder = 420
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = playerGui

	-- Roblox post-processing blurs the 3D scene but not ScreenGui/BillboardGui.
	-- During the welcome-back acknowledgement, suppress every non-exempt gameplay
	-- surface and restore its exact authored state when the modal closes. CoreGui is
	-- outside PlayerGui, while SellCarsHUD.TopHUD stays sharp and visible.
	local screenGuiStates: { ScreenGuiState } = {}
	local screenGuiSeen: { [ScreenGui]: boolean } = {}
	local worldGuiStates: { WorldGuiState } = {}
	local worldGuiSeen: { [BillboardGui | SurfaceGui]: boolean } = {}
	local guardedPlayerWorldGuis: { [BillboardGui | SurfaceGui]: boolean } = {}
	local hudObjectStates: { GuiObjectState } = {}
	local hudObjectSeen: { [GuiObject]: boolean } = {}
	local suppressionConnections: { RBXScriptConnection } = {}
	local promptsWereEnabled = ProximityPromptService.Enabled
	local previousInputLocked = playerGui:GetAttribute("OfflineEarningsInputLocked")
	local suppressionRestored = false

	local function suppressScreenGui(instance: Instance)
		if not instance:IsA("ScreenGui") or instance == gui or instance.Name == "SellCarsHUD" then
			return
		end
		if screenGuiSeen[instance] then
			return
		end
		screenGuiSeen[instance] = true
		table.insert(screenGuiStates, { target = instance, enabled = instance.Enabled })
		instance.Enabled = false
	end

	local function suppressWorldGui(instance: Instance)
		if not (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) then
			return
		end
		if worldGuiSeen[instance] then
			return
		end
		worldGuiSeen[instance] = true
		table.insert(worldGuiStates, { target = instance, enabled = instance.Enabled })
		instance.Enabled = false
	end

	local function guardPlayerWorldGui(instance: Instance)
		if not (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) then
			return
		end
		suppressWorldGui(instance)
		if guardedPlayerWorldGuis[instance] then
			return
		end
		guardedPlayerWorldGuis[instance] = true
		table.insert(suppressionConnections, instance:GetPropertyChangedSignal("Enabled"):Connect(function()
			if not suppressionRestored and instance.Parent ~= nil and instance.Enabled then
				instance.Enabled = false
			end
		end))
	end

	local function suppressHudObject(instance: Instance)
		if not instance:IsA("GuiObject") or instance.Name == "TopHUD" then
			return
		end
		if hudObjectSeen[instance] then
			return
		end
		hudObjectSeen[instance] = true
		table.insert(hudObjectStates, { target = instance, visible = instance.Visible })
		instance.Visible = false
	end

	for _, child in playerGui:GetChildren() do
		suppressScreenGui(child)
	end
	for _, descendant in workspace:GetDescendants() do
		suppressWorldGui(descendant)
	end
	table.insert(suppressionConnections, workspace.DescendantAdded:Connect(suppressWorldGui))
	for _, descendant in playerGui:GetDescendants() do
		guardPlayerWorldGui(descendant)
	end
	table.insert(suppressionConnections, playerGui.DescendantAdded:Connect(guardPlayerWorldGui))

	local sellCarsHud = playerGui:FindFirstChild("SellCarsHUD")
	local root = sellCarsHud and sellCarsHud:FindFirstChild("Root")
	local canvas = root and root:FindFirstChild("Canvas")
	if root ~= nil then
		for _, child in root:GetChildren() do
			if child ~= canvas then
				suppressHudObject(child)
			end
		end
		table.insert(suppressionConnections, root.ChildAdded:Connect(function(child)
			if child ~= canvas then
				suppressHudObject(child)
			end
		end))
	end
	if canvas ~= nil then
		for _, child in canvas:GetChildren() do
			suppressHudObject(child)
		end
		table.insert(suppressionConnections, canvas.ChildAdded:Connect(suppressHudObject))
	end
	ProximityPromptService.Enabled = false
	playerGui:SetAttribute("OfflineEarningsInputLocked", true)

	local function restoreSuppressedUi()
		if suppressionRestored then
			return
		end
		suppressionRestored = true
		for _, connection in suppressionConnections do
			connection:Disconnect()
		end
		for _, state in screenGuiStates do
			if state.target.Parent ~= nil then
				state.target.Enabled = state.enabled
			end
		end
		for _, state in worldGuiStates do
			if state.target.Parent ~= nil then
				state.target.Enabled = state.enabled
			end
		end
		for _, state in hudObjectStates do
			if state.target.Parent ~= nil then
				state.target.Visible = state.visible
			end
		end
		ProximityPromptService.Enabled = promptsWereEnabled
		playerGui:SetAttribute("OfflineEarningsInputLocked", previousInputLocked)
	end
	local blur = Instance.new("BlurEffect")
	blur.Name = "OfflineEarningsBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local focusedCamera = workspace.CurrentCamera
	local originalFieldOfView = if focusedCamera ~= nil then focusedCamera.FieldOfView else nil
	gui.Destroying:Connect(function()
		restoreSuppressedUi()
		if blur.Parent ~= nil then
			blur:Destroy()
		end
		if focusedCamera ~= nil and originalFieldOfView ~= nil and focusedCamera.Parent ~= nil then
			focusedCamera.FieldOfView = originalFieldOfView
		end
	end)

	local shade = Instance.new("TextButton")
	shade.Name = "Shade"
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(3, 5, 8)
	shade.BackgroundTransparency = 1
	shade.BorderSizePixel = 0
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.Active = true
	shade.InputSink = Enum.InputSink.All
	shade.ZIndex = 1
	shade.Parent = gui

	-- Keep the visual blocker fully transparent. Lighting blur already supplies
	-- focus across the whole 3D scene; a lower-screen tint creates a hard seam
	-- below TopHUD and makes the viewport look vertically clipped.
	local backdropVisual = Instance.new("Frame")
	backdropVisual.Name = "BackdropVisual"
	backdropVisual.Size = UDim2.fromScale(1, 1)
	backdropVisual.BackgroundColor3 = Color3.fromRGB(3, 5, 8)
	backdropVisual.BackgroundTransparency = 1
	backdropVisual.BorderSizePixel = 0
	backdropVisual.Active = false
	backdropVisual.ZIndex = 1
	backdropVisual.Parent = shade

	local card = Instance.new("CanvasGroup")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 18)
	card.Size = UDim2.fromOffset(720, 450)
	card.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Active = true
	card.InputSink = Enum.InputSink.All
	card.GroupTransparency = 1
	card.ZIndex = 2
	card.Parent = gui
	corner(card, 16)
	stroke(card, Color3.fromRGB(255, 60, 47), 3, 0.05)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 43, 48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 8, 10)),
	})
	gradient.Rotation = 90
	gradient.Parent = card

	-- UICorner rounds only the card's own pixels; ClipsDescendants still clips to
	-- a rectangle. Keep every visual inside an inset mask so square child layers
	-- can never reach beyond the outer 16 px Workshop radius.
	local contentMask = Instance.new("Frame")
	contentMask.Name = "RoundedContentMask"
	contentMask.Position = UDim2.fromOffset(6, 6)
	contentMask.Size = UDim2.new(1, -12, 1, -12)
	contentMask.BackgroundColor3 = Color3.fromRGB(23, 24, 28)
	contentMask.BorderSizePixel = 0
	contentMask.ClipsDescendants = true
	contentMask.ZIndex = 3
	contentMask.Parent = card
	corner(contentMask, 11)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 96)
	header.BackgroundColor3 = Color3.fromRGB(47, 49, 55)
	header.BorderSizePixel = 0
	header.ZIndex = 3
	header.Parent = card
	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new(Color3.fromRGB(47, 49, 55), Color3.fromRGB(21, 22, 25))
	headerGradient.Rotation = 90
	headerGradient.Parent = header

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.fromOffset(14, 96)
	accent.BackgroundColor3 = Color3.fromRGB(248, 204, 24)
	accent.BorderSizePixel = 0
	accent.ZIndex = 3
	accent.Parent = card
	corner(accent, 4)
	local accentNotches: { Frame } = {}
	for index = 0, 5 do
		local notch = Instance.new("Frame")
		notch.Position = UDim2.fromOffset(0, index * 18)
		notch.Size = UDim2.fromOffset(14, 8)
		notch.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
		notch.BorderSizePixel = 0
		notch.ZIndex = 5
		notch.Parent = accent
		table.insert(accentNotches, notch)
	end

	local eyebrow = Instance.new("TextLabel")
	eyebrow.Name = "Eyebrow"
	eyebrow.Position = UDim2.fromOffset(44, 12)
	eyebrow.Size = UDim2.new(1, -70, 0, 42)
	eyebrow.BackgroundTransparency = 1
	eyebrow.Font = Enum.Font.RobotoCondensed
	eyebrow.Text = "WELCOME BACK"
	eyebrow.TextColor3 = Color3.fromRGB(248, 204, 24)
	eyebrow.TextSize = 36
	eyebrow.TextXAlignment = Enum.TextXAlignment.Left
	eyebrow.ZIndex = 4
	eyebrow.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(46, 54)
	title.Size = UDim2.new(1, -74, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.RobotoCondensed
	title.Text = "YOUR BUSINESS KEPT WORKING"
	title.TextColor3 = Color3.fromRGB(165, 170, 181)
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = card
	local titleSize = Instance.new("UITextSizeConstraint")
	titleSize.MinTextSize = 14
	titleSize.MaxTextSize = 20
	titleSize.Parent = title

	local rewardPanel = Instance.new("Frame")
	rewardPanel.Name = "RewardPanel"
	rewardPanel.Position = UDim2.fromOffset(30, 116)
	rewardPanel.Size = UDim2.fromOffset(660, 132)
	rewardPanel.BackgroundColor3 = Color3.fromRGB(28, 29, 33)
	rewardPanel.BorderSizePixel = 0
	rewardPanel.ZIndex = 3
	rewardPanel.Parent = card
	corner(rewardPanel, 10)
	stroke(rewardPanel, Color3.fromRGB(67, 70, 77), 2, 0.12)
	local rewardAccent = Instance.new("Frame")
	rewardAccent.Size = UDim2.fromOffset(7, 132)
	rewardAccent.BackgroundColor3 = Color3.fromRGB(72, 255, 53)
	rewardAccent.BorderSizePixel = 0
	rewardAccent.ZIndex = 4
	rewardAccent.Parent = rewardPanel
	corner(rewardAccent, 4)

	local amountLabel = Instance.new("TextLabel")
	amountLabel.Name = "Amount"
	amountLabel.Position = UDim2.fromOffset(50, 132)
	amountLabel.Size = UDim2.new(1, -100, 0, 70)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Font = Enum.Font.RobotoCondensed
	amountLabel.Text = formatMoney(amount)
	amountLabel.TextColor3 = Color3.fromRGB(72, 255, 53)
	amountLabel.TextSize = 58
	amountLabel.TextXAlignment = Enum.TextXAlignment.Left
	amountLabel.ZIndex = 4
	amountLabel.Parent = card
	local amountSize = Instance.new("UITextSizeConstraint")
	amountSize.MinTextSize = 22
	amountSize.MaxTextSize = 58
	amountSize.Parent = amountLabel

	local detail = Instance.new("TextLabel")
	detail.Name = "Detail"
	detail.Position = UDim2.fromOffset(52, 207)
	detail.Size = UDim2.new(1, -104, 0, 26)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.RobotoCondensed
	detail.Text = "EARNED WHILE YOU WERE AWAY · " .. formatAway(awaySeconds)
	detail.TextColor3 = Color3.fromRGB(248, 204, 24)
	detail.TextSize = 17
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.ZIndex = 4
	detail.Parent = card
	local detailSize = Instance.new("UITextSizeConstraint")
	detailSize.MinTextSize = 10
	detailSize.MaxTextSize = 17
	detailSize.Parent = detail

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.new(0, 30, 1, -29)
	status.Size = UDim2.new(1, -60, 0, 20)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.RobotoCondensed
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(165, 170, 181)
	status.TextSize = 11
	status.Visible = false
	status.ZIndex = 4
	status.Parent = card

	local collect = button(card, "Collect", "COLLECT", Color3.fromRGB(34, 184, 69), UDim2.new(0.5, 0, 0, 272))
	-- UIGradient on a TextButton also multiplies its glyph color. A solid Workshop
	-- green keeps the label independently warm-white and fully opaque.
	collect.TextColor3 = Color3.fromRGB(255, 248, 226)
	collect.TextTransparency = 0
	collect.TextStrokeTransparency = 1
	local boost = button(card, "DoublePlaceholder", "2× EARNINGS  ·  SOON", Color3.fromRGB(13, 14, 17), UDim2.new(0.5, 0, 0, 338))
	boost.Active = false
	boost.AutoButtonColor = false
	boost.Selectable = false
	stroke(boost, Color3.fromRGB(130, 83, 255), 2, 0)

	local badge = Instance.new("TextLabel")
	badge.Name = "PlaceholderBadge"
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -12, 0.5, 0)
	badge.Size = UDim2.fromOffset(92, 24)
	badge.BackgroundColor3 = Color3.fromRGB(255, 192, 54)
	badge.BorderSizePixel = 0
	badge.Font = Enum.Font.RobotoCondensed
	badge.Text = "COMING SOON"
	badge.TextColor3 = Color3.fromRGB(38, 28, 8)
	badge.TextSize = 9
	badge.ZIndex = 7
	badge.Parent = boost
	corner(badge, 6)

	-- Reparent the complete visual stack into the inset mask. Nested children
	-- (gradients, reward accent, badge) follow their owners automatically.
	for _, visual in {
		header,
		accent,
		eyebrow,
		title,
		rewardPanel,
		amountLabel,
		detail,
		status,
		collect,
		boost,
	} do
		visual.Parent = contentMask
	end

	local targetScale = 1
	local targetPosition = UDim2.fromScale(0.5, 0.5)
	local closing = false

	local function offsetPosition(position: UDim2, yOffset: number): UDim2
		return UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + yOffset)
	end
	local function close()
		if closing then
			return
		end
		closing = true
		TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			GroupTransparency = 1,
			Position = offsetPosition(targetPosition, -4),
		}):Play()
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = targetScale * 0.9,
		}):Play()
		TweenService:Create(backdropVisual, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(blur, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = 0,
		}):Play()
		if focusedCamera ~= nil and originalFieldOfView ~= nil and focusedCamera.Parent ~= nil then
			TweenService:Create(focusedCamera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = originalFieldOfView,
			}):Play()
		end
		task.delay(0.2, function()
			restoreSuppressedUi()
			if blur.Parent ~= nil then
				blur:Destroy()
			end
			if gui.Parent ~= nil then
				gui:Destroy()
			end
			if playerGui:GetAttribute("MVPDealModal") == "OfflineEarnings" then
				playerGui:SetAttribute("MVPDealModal", previousModal)
				playerGui:SetAttribute("MVPDetailsOpen", previousDetails)
			end
		end)
	end

	local function press(item: TextButton)
		local itemScale = item:FindFirstChildOfClass("UIScale")
		if itemScale == nil then
			itemScale = Instance.new("UIScale")
			itemScale.Parent = item
		end
		local down = TweenService:Create(itemScale, TweenInfo.new(0.07), { Scale = 0.96 })
		down:Play()
		down.Completed:Wait()
		TweenService:Create(itemScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end

	shade.Activated:Connect(close)
	collect.Activated:Connect(function()
		task.spawn(press, collect)
		close()
	end)

	local function layout()
		local camera = workspace.CurrentCamera
		local viewport = if camera ~= nil then camera.ViewportSize else Vector2.new(1280, 720)
		local isPhone = UserInputService.TouchEnabled and math.min(viewport.X, viewport.Y) <= 600

		if isPhone then
			local mobileWidth = math.floor(math.clamp(viewport.X - 32, 320, 520))
			local contentWidth = mobileWidth - 12
			local actionWidth = math.floor((contentWidth - 28) / 2)
			local amountWidth = math.floor(math.clamp(mobileWidth * 0.34, 112, 170))
			local detailX = 24 + amountWidth + 8

			card.Size = UDim2.fromOffset(mobileWidth, 208)
			targetScale = 1
			targetPosition = if viewport.X > viewport.Y
				then UDim2.new(0.5, 0, 0.5, 28)
				else UDim2.fromScale(0.5, 0.5)

			header.Size = UDim2.new(1, 0, 0, 52)
			accent.Size = UDim2.fromOffset(8, 52)
			for _, notch in accentNotches do
				notch.Visible = false
			end
			eyebrow.Position = UDim2.fromOffset(24, 4)
			eyebrow.Size = UDim2.new(1, -40, 0, 24)
			eyebrow.TextSize = 22
			title.Position = UDim2.fromOffset(24, 28)
			title.Size = UDim2.new(1, -40, 0, 18)
			title.TextSize = 14

			rewardPanel.Position = UDim2.fromOffset(12, 62)
			rewardPanel.Size = UDim2.fromOffset(contentWidth - 24, 54)
			rewardAccent.Size = UDim2.fromOffset(5, 54)
			amountLabel.Position = UDim2.fromOffset(24, 68)
			amountLabel.Size = UDim2.fromOffset(amountWidth, 42)
			amountLabel.TextScaled = true
			amountSize.MinTextSize = 22
			amountSize.MaxTextSize = 32
			detail.Position = UDim2.fromOffset(detailX, 72)
			detail.Size = UDim2.fromOffset(math.max(80, contentWidth - detailX - 14), 34)
			detail.TextScaled = true
			detailSize.MinTextSize = 10
			detailSize.MaxTextSize = 14

			collect.AnchorPoint = Vector2.zero
			collect.Position = UDim2.fromOffset(10, 128)
			collect.Size = UDim2.fromOffset(actionWidth, 56)
			collect.TextSize = 16
			boost.AnchorPoint = Vector2.zero
			boost.Position = UDim2.fromOffset(18 + actionWidth, 128)
			boost.Size = UDim2.fromOffset(actionWidth, 56)
			boost.Text = "2× · SOON"
			boost.TextSize = 13
			badge.Visible = false
		else
			card.Size = UDim2.fromOffset(720, 450)
			targetScale = math.min(1, (viewport.X - 32) / 720, (viewport.Y - 32) / 450)
			targetPosition = UDim2.fromScale(0.5, 0.5)

			header.Size = UDim2.new(1, 0, 0, 96)
			accent.Size = UDim2.fromOffset(14, 96)
			for index, notch in accentNotches do
				notch.Visible = true
				notch.Position = UDim2.fromOffset(0, (index - 1) * 18)
				notch.Size = UDim2.fromOffset(14, 8)
			end
			eyebrow.Position = UDim2.fromOffset(44, 12)
			eyebrow.Size = UDim2.new(1, -70, 0, 42)
			eyebrow.TextSize = 36
			title.Position = UDim2.fromOffset(46, 54)
			title.Size = UDim2.new(1, -74, 0, 28)
			title.TextSize = 20

			rewardPanel.Position = UDim2.fromOffset(30, 116)
			rewardPanel.Size = UDim2.fromOffset(660, 132)
			rewardAccent.Size = UDim2.fromOffset(7, 132)
			amountLabel.Position = UDim2.fromOffset(50, 132)
			amountLabel.Size = UDim2.new(1, -100, 0, 70)
			amountLabel.TextScaled = false
			amountLabel.TextSize = 58
			amountSize.MinTextSize = 22
			amountSize.MaxTextSize = 58
			detail.Position = UDim2.fromOffset(52, 207)
			detail.Size = UDim2.new(1, -104, 0, 26)
			detail.TextScaled = false
			detail.TextSize = 17
			detailSize.MinTextSize = 10
			detailSize.MaxTextSize = 17

			collect.AnchorPoint = Vector2.new(0.5, 0)
			collect.Position = UDim2.new(0.5, 0, 0, 272)
			collect.Size = UDim2.new(1, -60, 0, 54)
			collect.TextSize = 18
			boost.AnchorPoint = Vector2.new(0.5, 0)
			boost.Position = UDim2.new(0.5, 0, 0, 338)
			boost.Size = UDim2.new(1, -60, 0, 54)
			boost.Text = "2× EARNINGS  ·  SOON"
			boost.TextSize = 18
			badge.Visible = true
			badge.AnchorPoint = Vector2.new(1, 0.5)
			badge.Position = UDim2.new(1, -12, 0.5, 0)
			badge.Size = UDim2.fromOffset(92, 24)
			badge.TextSize = 9
		end

		if not closing then
			card.Position = if card.GroupTransparency < 0.99
				then targetPosition
				else offsetPosition(targetPosition, 18)
		end
		scale.Scale = if card.GroupTransparency < 0.99 then targetScale else targetScale * 0.9
	end

	local viewportConnection: RBXScriptConnection? = nil
	local function bindViewport()
		if viewportConnection ~= nil then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
		local camera = workspace.CurrentCamera
		if camera ~= nil then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
			table.insert(suppressionConnections, viewportConnection)
		end
		layout()
	end
	bindViewport()
	table.insert(suppressionConnections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport))

	-- Do not tint the viewport: uniform Lighting blur is the complete backdrop treatment.
	backdropVisual.BackgroundTransparency = 1
	TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
		Position = targetPosition,
	}):Play()
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = targetScale,
	}):Play()
	TweenService:Create(blur, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = 16,
	}):Play()
	if focusedCamera ~= nil and originalFieldOfView ~= nil then
		TweenService:Create(focusedCamera, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = math.max(1, originalFieldOfView - 7),
		}):Play()
	end
	-- Studio can temporarily suspend Tween stepping while its viewport loses focus.
	-- Converge to the intended modal state even in that case; this is idempotent
	-- after a normally completed entrance animation.
	task.delay(0.35, function()
		if closing or gui.Parent == nil then
			return
		end
		backdropVisual.BackgroundTransparency = 1
		card.GroupTransparency = 0
		card.Position = targetPosition
		scale.Scale = targetScale
		if blur.Parent ~= nil then
			blur.Size = 16
		end
		if focusedCamera ~= nil and originalFieldOfView ~= nil and focusedCamera.Parent ~= nil then
			focusedCamera.FieldOfView = math.max(1, originalFieldOfView - 7)
		end
	end)
end

local function tryShow()
	if shown then
		return
	end
	if player:GetAttribute("OfflineEarningsEligible") ~= true then
		return
	end
	local amount = player:GetAttribute("OfflineEarnings")
	if typeof(amount) ~= "number" or amount <= 0 then
		return
	end
	local seconds = player:GetAttribute("OfflineSeconds")
	task.delay(1.25, function()
		showPopup(amount, if typeof(seconds) == "number" then seconds else 0)
	end)
end

player:GetAttributeChangedSignal("OfflineEarnings"):Connect(tryShow)
player:GetAttributeChangedSignal("OfflineEarningsEligible"):Connect(tryShow)
task.defer(tryShow)

