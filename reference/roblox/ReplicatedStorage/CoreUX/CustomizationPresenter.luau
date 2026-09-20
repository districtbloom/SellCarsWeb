local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("CoreUX"):WaitForChild("Theme"))
local C = Theme.Colors

local Presenter = {}
Presenter.__index = Presenter

local CATEGORY_ORDER = { "CAR", "COLOR", "WHEELS", "VINYL", "TINT", "NEON" }

local OPTIONS = {
	CAR = {
		{ value = "COUPE", label = "STREET" },
		{ value = "MUSCLE", label = "MUSCLE" },
		{ value = "OFFROAD", label = "OFF-ROAD" },
	},
	COLOR = {
		{ value = "BLUE", label = "BLUE", color = Color3.fromRGB(56, 128, 223) },
		{ value = "RED", label = "RED", color = Color3.fromRGB(211, 63, 54) },
		{ value = "LIME", label = "LIME", color = Color3.fromRGB(116, 194, 67) },
		{ value = "SAND", label = "SAND", color = Color3.fromRGB(194, 155, 91) },
		{ value = "BLACK", label = "BLACK", color = Color3.fromRGB(36, 39, 43) },
		{ value = "WHITE", label = "WHITE", color = Color3.fromRGB(228, 228, 222) },
	},
	WHEELS = {
		{ value = "STOCK", label = "STOCK" },
		{ value = "CLASSIC", label = "CLASSIC" },
		{ value = "SPORT", label = "SPORT" },
		{ value = "RUGGED", label = "RUGGED" },
	},
	VINYL = {
		{ value = "NONE", label = "NONE" },
		{ value = "STRIPE", label = "STRIPE" },
		{ value = "DOUBLE", label = "DOUBLE" },
		{ value = "DESERT", label = "SLASH" },
	},
	TINT = {
		{ value = "CLEAR", label = "CLEAR" },
		{ value = "LIGHT", label = "LIGHT" },
		{ value = "DARK", label = "DARK" },
		{ value = "LIMO", label = "LIMO" },
	},
	NEON = {
		{ value = "OFF", label = "OFF" },
		{ value = "AMBER", label = "AMBER", color = Color3.fromRGB(255, 176, 32) },
		{ value = "CYAN", label = "CYAN", color = Color3.fromRGB(39, 222, 236) },
		{ value = "LIME", label = "LIME", color = Color3.fromRGB(109, 232, 67) },
		{ value = "PURPLE", label = "PURPLE", color = Color3.fromRGB(173, 73, 232) },
	},
}

local STATE_FIELDS = {
	CAR = "personalType",
	COLOR = "personalColor",
	WHEELS = "personalWheel",
	VINYL = "personalVinyl",
	TINT = "personalTint",
	NEON = "personalNeon",
}

local SERVER_CATEGORIES = {
	COLOR = "PAINT",
	WHEELS = "WHEELS",
	VINYL = "VINYL",
	TINT = "TINT",
	NEON = "NEON",
}

local CAR_NAMES = {
	COUPE = "STREET COUPE",
	MUSCLE = "MUSCLE CAR",
	OFFROAD = "OFF-ROAD",
}

local function create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function outline(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, parent)
end

local function action(parent, properties, callback)
	properties = properties or {}
	properties.AutoButtonColor = false
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or C.White
	local result = create("TextButton", properties, parent)
	corner(result, properties.CornerRadius or 9)
	result.Activated:Connect(function()
		TweenService:Create(result, TweenInfo.new(0.07), { BackgroundTransparency = 0.16 }):Play()
		task.delay(0.08, function()
			if result.Parent then
				TweenService:Create(result, TweenInfo.new(0.1), { BackgroundTransparency = 0 }):Play()
			end
		end)
		if callback then callback() end
	end)
	return result
end

local function clearButtons(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiButton") then child:Destroy() end
	end
end

function Presenter.new(config)
	local self = setmetatable({}, Presenter)
	self.gui = assert(config.gui, "CustomizationPresenter requires gui")
	self.event = assert(config.event, "CustomizationPresenter requires event")
	self.camera = assert(config.camera, "CustomizationPresenter requires camera")
	self.restoreCamera = config.restoreCamera
	self.setMode = config.setMode
	self.defaultMode = config.defaultMode
	self.playSound = config.playSound
	self.state = {}
	self.category = "CAR"
	self.car = nil
	self.portrait = false

	local root = create("Frame", {
		Name = "Customize",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 80,
	}, self.gui)
	self.root = root

	local dock = create("Frame", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(820, 137),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		ZIndex = 81,
	}, root)
	dock:SetAttribute("SelfResponsive", true)
	corner(dock, 16)
	outline(dock, Color3.fromRGB(69, 75, 81), 2, 0.08)
	self.dock = dock

	local categoryRow = create("ScrollingFrame", {
		Name = "CategoryRow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.fromOffset(0, 0),
		ClipsDescendants = true,
		ZIndex = 82,
	}, dock)
	self.categoryRow = categoryRow
	self.categoryLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, categoryRow)

	local optionRow = create("ScrollingFrame", {
		Name = "OptionRow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.fromOffset(0, 0),
		ClipsDescendants = true,
		ZIndex = 82,
	}, dock)
	self.optionRow = optionRow
	self.optionLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, optionRow)

	self.doneButton = action(dock, {
		Name = "Done",
		BackgroundColor3 = C.Yellow,
		Text = "DONE",
		TextColor3 = C.Ink,
		TextSize = 12,
		ZIndex = 83,
	}, function()
		self:Close(true)
	end)

	local topbar = create("Frame", {
		Name = "Topbar",
		BackgroundTransparency = 1,
		ZIndex = 82,
	}, root)
	self.topbar = topbar
	self.carName = create("TextLabel", {
		Name = "CarName",
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "STREET COUPE",
		TextColor3 = C.White,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 83,
	}, topbar)
	corner(self.carName, 10)

	self.undoButton = action(topbar, {
		Name = "Undo",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Panel,
		Text = "↶  UNDO",
		TextColor3 = C.Muted,
		TextSize = 10,
		ZIndex = 83,
	}, function()
		self.event:FireServer("UndoCustomization")
		if self.playSound then self.playSound("Preview") end
	end)
	self.randomButton = action(topbar, {
		Name = "Random",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Panel,
		Text = "↻  RANDOM",
		TextColor3 = C.Ink,
		TextSize = 10,
		ZIndex = 83,
	}, function()
		self.event:FireServer("RandomizeCustomization")
		if self.playSound then self.playSound("Cash") end
	end)

	self.categoryButtons = {}
	for index, category in ipairs(CATEGORY_ORDER) do
		local button
		button = action(categoryRow, {
			Name = category,
			LayoutOrder = index,
			BackgroundColor3 = C.SoftPanel,
			Text = category,
			TextSize = 10,
			ZIndex = 83,
		}, function()
			self.category = category
			if self.playSound then self.playSound("Preview") end
			self:Refresh()
		end)
		self.categoryButtons[category] = button
	end

	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_layout()
	end)
	task.defer(function()
		if root.Parent then self:_layout() end
	end)

	return self
end

function Presenter:_layout()
	if not self.root.Parent then return end
	local viewport = self.root.AbsoluteSize
	local width = math.max(320, viewport.X)
	local height = math.max(320, viewport.Y)
	local portrait = height > width * 1.08
	local compactLandscape = not portrait and height <= 500
	local margin = compactLandscape and 10 or (portrait and 10 or 18)
	local dockWidth = portrait and (width - margin * 2)
		or math.min(width - margin * 2, compactLandscape and 900 or 980)
	local dockHeight = portrait and 194 or (compactLandscape and 125 or 137)
	local doneWidth = portrait and dockWidth - 20 or (compactLandscape and 116 or 132)
	local categoryWidth = portrait and 76
		or math.floor((dockWidth - 20 - doneWidth - 8 - 6 * 5) / 6)
	categoryWidth = math.max(66, categoryWidth)

	self.portrait = portrait
	self.dock.Position = UDim2.new(0.5, 0, 1, -margin)
	self.dock.Size = UDim2.fromOffset(dockWidth, dockHeight)

	if portrait then
		self.categoryRow.Position = UDim2.fromOffset(10, 10)
		self.categoryRow.Size = UDim2.new(1, -20, 0, 44)
		self.doneButton.Position = UDim2.fromOffset(10, 62)
		self.doneButton.Size = UDim2.fromOffset(doneWidth, 44)
		self.optionRow.Position = UDim2.fromOffset(10, 114)
		self.optionRow.Size = UDim2.new(1, -20, 0, 66)
	else
		self.categoryRow.Position = UDim2.fromOffset(10, 10)
		self.categoryRow.Size = UDim2.new(1, -(doneWidth + 28), 0, 44)
		self.doneButton.Position = UDim2.new(1, -(doneWidth + 10), 0, 10)
		self.doneButton.Size = UDim2.fromOffset(doneWidth, 44)
		self.optionRow.Position = UDim2.fromOffset(10, 62)
		self.optionRow.Size = UDim2.new(1, -20, 0, compactLandscape and 53 or 61)
	end

	for _, button in pairs(self.categoryButtons) do
		button.Size = UDim2.fromOffset(categoryWidth, 44)
	end
	local categoryCanvasWidth = categoryWidth * #CATEGORY_ORDER + 6 * (#CATEGORY_ORDER - 1)
	self.categoryRow.CanvasSize = UDim2.fromOffset(categoryCanvasWidth, 0)

	local definitions = OPTIONS[self.category] or {}
	local availableOptionWidth = dockWidth - 20
	local optionWidth = portrait and 112
		or math.max(96, math.floor((availableOptionWidth - 7 * math.max(0, #definitions - 1)) / math.max(1, #definitions)))
	for _, child in ipairs(self.optionRow:GetChildren()) do
		if child:IsA("GuiButton") then
			child.Size = UDim2.fromOffset(optionWidth, compactLandscape and 53 or 59)
		end
	end
	self.optionRow.CanvasSize = UDim2.fromOffset(optionWidth * #definitions + 7 * math.max(0, #definitions - 1), 0)

	self.topbar.Position = UDim2.fromOffset(margin, margin)
	self.topbar.Size = UDim2.new(1, -margin * 2, 0, 44)
	self.carName.Size = UDim2.fromOffset(portrait and 132 or 168, 42)
	local undoWidth = portrait and 44 or 84
	local randomWidth = portrait and 44 or 102
	self.undoButton.Position = UDim2.new(1, -(randomWidth + 7), 0, 0)
	self.undoButton.Size = UDim2.fromOffset(undoWidth, 42)
	self.randomButton.Position = UDim2.new(1, 0, 0, 0)
	self.randomButton.Size = UDim2.fromOffset(randomWidth, 42)
	self.undoButton.Text = portrait and "↶" or "↶  UNDO"
	self.randomButton.Text = portrait and "↻" or "↻  RANDOM"
end

function Presenter:_focusCar()
	if not self.car or not self.car.Parent then return end
	local target = self.car:GetPivot().Position + Vector3.new(0, 2, 0)
	local viewport = self.root.AbsoluteSize
	local portrait = viewport.Y > viewport.X * 1.08
	local cameraOffset = portrait and Vector3.new(12.5, 6.2, 11.5) or Vector3.new(11, 5.6, 10)
	local desired = CFrame.lookAt(target + cameraOffset, target)
	self.camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(self.camera, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		CFrame = desired,
	}):Play()
end

function Presenter:_selectedValue()
	local field = STATE_FIELDS[self.category]
	return field and self.state[field]
end

function Presenter:_applyChoice(value)
	local field = STATE_FIELDS[self.category]
	if not field or self.state[field] == value then return end
	self.state[field] = value
	if self.category == "CAR" then
		self.event:FireServer("SetCarType", value)
	else
		self.event:FireServer("SetCustomization", {
			category = SERVER_CATEGORIES[self.category],
			value = value,
		})
	end
	if self.playSound then self.playSound("Preview") end
	self:Refresh()
end

function Presenter:_rebuildOptions()
	clearButtons(self.optionRow)
	local definitions = OPTIONS[self.category] or {}
	local selectedValue = self:_selectedValue()
	for index, definition in ipairs(definitions) do
		local background = definition.color or C.SoftPanel
		local darkText = definition.value == "WHITE" or definition.value == "SAND" or definition.value == "LIME"
		local optionButton
		optionButton = action(self.optionRow, {
			Name = "Option_" .. definition.value,
			LayoutOrder = index,
			BackgroundColor3 = background,
			Text = definition.label,
			TextColor3 = darkText and C.Ink or C.White,
			TextSize = 10,
			TextWrapped = true,
			ZIndex = 83,
		}, function()
			self:_applyChoice(definition.value)
		end)
		local selected = selectedValue == definition.value
		local selectedOutline = outline(optionButton, C.Yellow, 3, selected and 0 or 1)
		selectedOutline.Name = "SelectedOutline"
	end
end

function Presenter:Refresh()
	for category, button in pairs(self.categoryButtons) do
		local selected = category == self.category
		button.BackgroundColor3 = selected and C.Yellow or C.SoftPanel
		button.TextColor3 = selected and C.Ink or C.White
	end
	self.carName.Text = CAR_NAMES[self.state.personalType or "COUPE"] or CAR_NAMES.COUPE
	self.undoButton.TextColor3 = self.state.customizationCanUndo and C.White or C.Muted
	self:_rebuildOptions()
	self:_layout()
end

function Presenter:UpdateState(state)
	if type(state) ~= "table" then return end
	self.state = state
	if self.root.Visible then self:Refresh() end
end

function Presenter:Open(state, car)
	if type(state) == "table" then self.state = state end
	self.car = car
	self.category = "CAR"
	if self.setMode then self.setMode("Customize") end
	self.root.Visible = true
	self:_layout()
	self:_focusCar()
	self:Refresh()
end

function Presenter:Close(complete)
	if not self.root.Visible and not complete then return end
	self.root.Visible = false
	if complete then
		self.event:FireServer("CompleteCustomization")
		if self.playSound then self.playSound("Success") end
	end
	if self.restoreCamera then self.restoreCamera() end
	if self.setMode then self.setMode(self.defaultMode and self.defaultMode() or "World") end
end

return Presenter


