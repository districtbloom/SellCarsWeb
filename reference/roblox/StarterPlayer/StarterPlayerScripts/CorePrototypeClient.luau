if game.PlaceId~=105869926920733 or not game:GetService('RunService'):IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("CorePrototypeConfig"))
local CoreUX = ReplicatedStorage:WaitForChild("CoreUX")
local Theme = require(CoreUX:WaitForChild("Theme"))
local Motion = require(CoreUX:WaitForChild("Motion"))
local FocusController = require(CoreUX:WaitForChild("FocusController"))
local PromptPresenter = require(CoreUX:WaitForChild("PromptPresenter"))
local DealClosurePresenter = require(CoreUX:WaitForChild("DealClosurePresenter"))
local PurchasePadPresenter = require(CoreUX:WaitForChild("PurchasePadPresenter"))
local GuidancePresenter = require(CoreUX:WaitForChild("GuidancePresenter"))
local CustomizationPresenter = require(CoreUX:WaitForChild("CustomizationPresenter"))
local AudioFeedback = require(CoreUX:WaitForChild("AudioFeedback"))
local event = ReplicatedStorage:WaitForChild("CorePrototypeRemotes"):WaitForChild("PrototypeEvent")
local audio = AudioFeedback.new()

Motion.SetReducedMotion(player:GetAttribute("ReducedMotion") == true)
player:GetAttributeChangedSignal("ReducedMotion"):Connect(function()
	Motion.SetReducedMotion(player:GetAttribute("ReducedMotion") == true)
end)

local C = Theme.Colors
local currentState
local focusedHead
local drivingCar
local driveRenderConnection
local throttle = 0
local steer = 0
local cinematicToken = 0
local cinematicPlaying = false
local cinematicCarStarts = {}
local finishCinematic
local rareSequenceToken = 0
local rareSequencePlaying = false
local setUIMode
local defaultModeForState
local uiMode = "World"

local function new(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function round(object, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end

local function stroke(object, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or C.Yellow,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, object)
end

local function padding(object, left, right, top, bottom)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or left or 0),
		PaddingTop = UDim.new(0, top or left or 0),
		PaddingBottom = UDim.new(0, bottom or top or left or 0),
	}, object)
end

local function label(parent, properties)
	properties = properties or {}
	properties.BackgroundTransparency = properties.BackgroundTransparency == nil and 1 or properties.BackgroundTransparency
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or C.White
	properties.TextSize = properties.TextSize or 18
	properties.TextWrapped = properties.TextWrapped == nil and true or properties.TextWrapped
	local object = new("TextLabel", properties, parent)
	return object
end

local function button(parent, properties, callback)
	properties = properties or {}
	properties.AutoButtonColor = false
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or C.Ink
	properties.TextSize = properties.TextSize or 17
	local object = new("TextButton", properties, parent)
	round(object, properties.CornerRadius or Theme.Metrics.ButtonRadius)
	Motion.AttachPress(object, { pressedScale = Theme.Motion.PressedScale })
	if callback then
		object.Activated:Connect(function(...)
			audio:Play("Click")
			callback(...)
		end)
	end
	return object
end

local old = playerGui:FindFirstChild("CorePrototypeUI")
if old then old:Destroy() end

local gui = new("ScreenGui", {
	Name = "CorePrototypeUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.ClipToDeviceSafeArea = true
end)

local focus = FocusController.new(function(owner)
	gui:SetAttribute("ActiveFocus", owner or "HUD")
end)
local promptPresenter = PromptPresenter.new(gui, Theme, Motion)
local dealClosure = DealClosurePresenter.new(gui, Theme, Motion)
local purchasePads = PurchasePadPresenter.new(gui, Theme, Motion, event, focus, audio)
local guidance = GuidancePresenter.new(gui, Theme)

local hud = new("Frame", {
	Name = "HUD",
	Position = UDim2.fromOffset(18, 70),
	Size = UDim2.fromOffset(350, 62),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.14,
	BorderSizePixel = 0,
}, gui)
round(hud, 12)
stroke(hud, Color3.fromRGB(74, 78, 83), 1, 0.28)
local flowLabel = label(hud, {
	Name = "Flow",
	Position = UDim2.fromOffset(14, 7),
	Size = UDim2.new(1, -28, 0, 17),
	Text = "ASPIRATION",
	TextColor3 = C.Ink,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local objectiveLabel = label(hud, {
	Name = "Objective",
	Position = UDim2.fromOffset(14, 23),
	Size = UDim2.new(1, -28, 0, 33),
	Text = "Turn a forgotten lot into a dealership.",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local cash = new("Frame", {
	Name = "Cash",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -96, 0, 70),
	Size = UDim2.fromOffset(132, 50),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
}, gui)
round(cash, 13)
stroke(cash, C.Green, 1.5)
local cashText = label(cash, {
	Size = UDim2.fromScale(1, 1),
	Text = "$1,800",
	TextColor3 = C.Ink,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
})
local cashScale = new("UIScale", { Scale = 1 }, cash)
local lastCash

local phoneButton = button(gui, {
	Name = "PhoneButton",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 70),
	Size = UDim2.fromOffset(64, 50),
	BackgroundColor3 = C.Panel,
	Text = "PHONE",
	TextColor3 = C.White,
	TextSize = 11,
}, function() end)
stroke(phoneButton, Color3.fromRGB(91, 96, 102), 1)
local phoneGlyph = label(phoneButton, {
	Position = UDim2.fromScale(0, 0.02),
	Size = UDim2.fromScale(1, 0.55),
	Text = "▯",
	TextSize = 27,
	TextXAlignment = Enum.TextXAlignment.Center,
})
local phoneWord = phoneButton
local phoneDot = new("Frame", {
	Name = "Unread",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -3, 0, 3),
	Size = UDim2.fromOffset(13, 13),
	BackgroundColor3 = C.Red,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 5,
}, phoneButton)
round(phoneDot, 7)
stroke(phoneDot, C.White, 2)

local incomingPhone = button(gui, {
	Name = "IncomingPhone",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 16),
	Size = UDim2.fromOffset(64, 50),
	BackgroundColor3 = C.Panel,
	Text = "",
	Visible = false,
	ClipsDescendants = true,
	ZIndex = 42,
})
round(incomingPhone, 17)
stroke(incomingPhone, C.Yellow, 2)
local incomingDevice = new("Frame", {
	Name = "Device",
	Position = UDim2.fromOffset(9, 9),
	Size = UDim2.fromOffset(47, 72),
	BackgroundColor3 = Color3.fromRGB(224, 229, 219),
	BorderSizePixel = 0,
	ZIndex = 43,
}, incomingPhone)
round(incomingDevice, 11)
stroke(incomingDevice, Color3.fromRGB(123, 127, 133), 1.5)
local incomingScreen = new("Frame", {
	Position = UDim2.fromOffset(5, 7),
	Size = UDim2.new(1, -10, 1, -14),
	BackgroundColor3 = C.SoftPanel,
	BorderSizePixel = 0,
	ZIndex = 44,
}, incomingDevice)
round(incomingScreen, 7)
label(incomingScreen, {
	Size = UDim2.fromScale(1, 1),
	Text = "▯",
	TextColor3 = C.Ink,
	TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 45,
})
local incomingTitle = label(incomingPhone, {
	Name = "IncomingTitle",
	Position = UDim2.fromOffset(68, 10),
	Size = UDim2.new(1, -78, 0, 23),
	Text = "INCOMING OFFER",
	TextColor3 = C.Ink,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 44,
})
local incomingDetail = label(incomingPhone, {
	Name = "IncomingDetail",
	Position = UDim2.fromOffset(68, 32),
	Size = UDim2.new(1, -78, 0, 34),
	Text = "Buyer wants to meet at the car",
	TextColor3 = C.White,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 44,
})
label(incomingPhone, {
	Position = UDim2.fromOffset(68, 66),
	Size = UDim2.new(1, -78, 0, 17),
	Text = "",
	Visible = false,
	TextColor3 = C.Ink,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 44,
})

local toast
local incomingToken = 0
local incomingQueueToken = 0
local openFullPhone
local function hideIncomingPhone()
	incomingToken += 1
	incomingQueueToken += 1
	incomingPhone.Visible = false
	incomingPhone.Rotation = 0
end

local function showIncomingPhone(data)
	if uiMode ~= "World" then phoneDot.Visible = true return end
	incomingQueueToken += 1
	local requestToken = incomingQueueToken
	phoneDot.Visible = true
	local function present()
		if requestToken ~= incomingQueueToken or uiMode ~= "World" then return end
		if toast and toast.Position.Y.Offset > -40 then
			task.delay(0.38, present)
			return
		end
		incomingToken += 1
		local token = incomingToken
		local layoutMargin = gui:GetAttribute("LayoutMargin") or 18
		local compact = gui:GetAttribute("LayoutClass") == "CompactLandscape"
		local targetWidth = compact and 248 or 284
		local targetHeight = compact and 64 or 70
		incomingTitle.Text = data.title or "INCOMING"
		incomingDetail.Text = data.detail or "New dealership opportunity"
		incomingPhone.Position = UDim2.new(1, -layoutMargin, 0, layoutMargin)
		incomingPhone.Size = UDim2.fromOffset(54, 48)
		incomingPhone.Rotation = 0
		incomingPhone.Visible = true
		TweenService:Create(incomingPhone, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -layoutMargin, 0, layoutMargin + (compact and 56 or 62)),
			Size = UDim2.fromOffset(targetWidth, targetHeight),
		}):Play()
		task.spawn(function()
			task.wait(0.38)
			for _ = 1, 3 do
				if token ~= incomingToken or not incomingPhone.Visible then return end
				TweenService:Create(incomingPhone, TweenInfo.new(0.08), { Rotation = -1.5 }):Play()
				task.wait(0.08)
				TweenService:Create(incomingPhone, TweenInfo.new(0.12), { Rotation = 1.5 }):Play()
				task.wait(0.12)
				TweenService:Create(incomingPhone, TweenInfo.new(0.08), { Rotation = 0 }):Play()
				task.wait(0.45)
			end
		end)
		if data.autoOpen == true then
			task.delay(1.3, function()
				if token ~= incomingToken or requestToken ~= incomingQueueToken then return end
				if not incomingPhone.Visible or uiMode ~= "World" then return end
				if not currentState or not currentState.phone or not openFullPhone then return end
				openFullPhone()
			end)
		end
	end
	present()
end

local repairStrip = new("Frame", {
	Name = "RepairTracker",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -20),
	Size = UDim2.fromOffset(218, 126),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Visible = false,
}, gui)
round(repairStrip, 12)
stroke(repairStrip, C.Yellow, 1, 0.35)
local repairProgress = label(repairStrip, {
	Name = "RepairTitle",
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 0, 20),
	Text = "RESTORATION · 0/3",
	TextColor3 = C.Ink,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local repairRows = new("Frame", {
	Name = "RepairSteps",
	Position = UDim2.fromOffset(10, 32),
	Size = UDim2.new(1, -20, 1, -40),
	BackgroundTransparency = 1,
}, repairStrip)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 3),
}, repairRows)
local repairLabels = {}
local repairEffects = { BODY = "+$300 VALUE", WHEELS = "+$400 VALUE", ENGINE = "+$600 VALUE" }
for _, name in ipairs({"BODY", "WHEELS", "ENGINE"}) do
	local chip = label(repairRows, {
		Name = name,
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
		Text = name .. "    " .. repairEffects[name],
		TextColor3 = C.White,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	repairLabels[name] = chip
end

toast = new("Frame", {
	Name = "Toast",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -220),
	Size = UDim2.new(0.48, 0, 0, 70),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	ZIndex = 50,
}, gui)
round(toast, 14)
local toastStripe = new("Frame", {
	Name = "Stripe",
	Size = UDim2.fromOffset(7, 70),
	BackgroundColor3 = C.Yellow,
	BorderSizePixel = 0,
}, toast)
round(toastStripe, 14)
local toastTitle = label(toast, {
	Position = UDim2.fromOffset(22, 8),
	Size = UDim2.new(1, -34, 0, 24),
	Text = "UPDATE",
	TextColor3 = C.Ink,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local toastDetail = label(toast, {
	Position = UDim2.fromOffset(22, 31),
	Size = UDim2.new(1, -34, 0, 31),
	Text = "",
	TextColor3 = C.White,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local toastToken = 0
local function showToast(data)
 -- Guidance has one owner: the bottom helper. No top banner.
 toast.Visible=false
 if data and data.tone=='Red' then
  gui:SetAttribute('HelperNotice',(data.title or '')..'. '..(data.detail or ''))
  gui:SetAttribute('HelperNoticeVersion',(gui:GetAttribute('HelperNoticeVersion')or 0)+1)
 end
end

local function pulseCash(gained)
	cashText.TextColor3 = gained and C.Green or C.Red
	TweenService:Create(cashScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1.13 }):Play()
	task.delay(0.14, function()
		TweenService:Create(cashScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
		TweenService:Create(cashText, TweenInfo.new(0.3), { TextColor3 = C.Ink }):Play()
	end)
end

local function showWorldFloater(data, target)
	if uiMode ~= "World" and uiMode ~= "Repair" then return end
	if not target or not target.Parent then return end
	if target:IsA("Model") then target = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart") end
	if not target or (not target:IsA("BasePart") and not target:IsA("Attachment")) then return end
	local floater = new("BillboardGui", {
		Name = "MomentFloater",
		Size = UDim2.fromOffset(300, 86),
		StudsOffsetWorldSpace = Vector3.new(0, 4.1, 0),
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = 34,
	}, target)
	local title = label(floater, {
		Size = UDim2.new(1, 0, 0.55, 0),
		Text = data.title or "UPDATED",
		TextColor3 = C[data.tone or "Yellow"] or C.Yellow,
		TextSize = 22,
		TextTransparency = 1,
		TextStrokeColor3 = C.Ink,
		TextStrokeTransparency = 0.1,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local detail = label(floater, {
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0.38, 0),
		Text = data.detail or "",
		TextColor3 = C[data.detailTone or "White"] or C.White,
		TextSize = 13,
		TextTransparency = 1,
		TextStrokeColor3 = C.Ink,
		TextStrokeTransparency = 0.12,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local scale = new("UIScale", { Scale = 0.72 }, floater)
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(title, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
	TweenService:Create(detail, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
	TweenService:Create(floater, TweenInfo.new(1.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, 6.2, 0),
	}):Play()
	task.delay(1.35, function()
		if not floater.Parent then return end
		TweenService:Create(title, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
		TweenService:Create(detail, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
		task.delay(0.3, function()
			if floater.Parent then floater:Destroy() end
		end)
	end)
end

local aspiration = new("Frame", {
	Name = "Aspiration",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 100,
}, gui)
local aspirationPanel = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.76, 0, 0.72, 0),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	ZIndex = 101,
}, aspiration)
round(aspirationPanel, 22)
stroke(aspirationPanel, C.Yellow, 2)
label(aspirationPanel, {
	Position = UDim2.fromScale(0.07, 0.08),
	Size = UDim2.fromScale(0.86, 0.13),
	Text = "START WITH NOTHING",
	TextColor3 = C.Ink,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 102,
})
label(aspirationPanel, {
	Position = UDim2.fromScale(0.07, 0.22),
	Size = UDim2.fromScale(0.86, 0.28),
	Text = "TURN FORGOTTEN CARS\nINTO YOUR OWN DEALERSHIP",
	TextColor3 = C.White,
	TextScaled = true,
	ZIndex = 102,
})
label(aspirationPanel, {
	Position = UDim2.fromScale(0.12, 0.53),
	Size = UDim2.fromScale(0.76, 0.12),
	Text = "Buy smart. Restore physically. Sell for visible profit.",
	TextColor3 = C.Muted,
	TextSize = 16,
	ZIndex = 102,
})
button(aspirationPanel, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.93),
	Size = UDim2.fromScale(0.56, 0.21),
	BackgroundColor3 = C.Yellow,
	Text = "OPEN THE LOT",
	TextSize = 20,
	ZIndex = 103,
}, function()
	aspiration.Visible = false
	event:FireServer("Begin")
end)

local cinematicUI = new("Frame", {
	Name = "OpeningCinematicUI",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 140,
}, gui)
local cinematicSkip = button(cinematicUI, {
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 16),
	Size = UDim2.fromOffset(86, 44),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.15,
	Text = "SKIP",
	TextColor3 = C.White,
	TextSize = 14,
	ZIndex = 143,
}, function()
	if finishCinematic then
		finishCinematic(true)
	end
end)
stroke(cinematicSkip, Color3.fromRGB(92, 97, 103), 1)
local cinematicLine = new("Frame", {
	Name = "DecisionLine",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -28),
	Size = UDim2.new(0.62, 0, 0, 82),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 142,
}, cinematicUI)
round(cinematicLine, 15)
local cinematicLineTitle = label(cinematicLine, {
	Position = UDim2.fromScale(0.05, 0.08),
	Size = UDim2.fromScale(0.9, 0.52),
	Text = "LET'S BUILD A BUSINESS.",
	TextColor3 = C.Ink,
	TextTransparency = 1,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 143,
})
local cinematicLineSub = label(cinematicLine, {
	Position = UDim2.fromScale(0.05, 0.58),
	Size = UDim2.fromScale(0.9, 0.3),
	Text = "EVERYONE STARTS SOMEWHERE",
	TextColor3 = C.White,
	TextTransparency = 1,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 143,
})
local cinematicWink = label(cinematicUI, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 82),
	Size = UDim2.fromOffset(390, 38),
	Text = "THE DRIVER WINKS — ONE DAY, THAT COULD BE YOURS",
	TextColor3 = C.Ink,
	TextTransparency = 1,
	TextSize = 14,
	TextStrokeColor3 = C.Ink,
	TextStrokeTransparency = 0.12,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
	ZIndex = 145,
})

local dialogue = new("Frame", {
	Name = "Dialogue",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 60,
}, gui)
local dialogueShade = new("Frame", {
	Name = "DialogueCard",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -18),
	Size = UDim2.new(0.66, -36, 0, 178),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.13,
	BorderSizePixel = 0,
	ZIndex = 61,
}, dialogue)
round(dialogueShade, 16)
stroke(dialogueShade, Color3.fromRGB(82, 87, 93), 1, 0.34)
new("UISizeConstraint", { MinSize = Vector2.new(560, 178), MaxSize = Vector2.new(900, 178) }, dialogueShade)
local dialogueProfile = label(dialogue, {
	Name = "ProfilePill",
	Position = UDim2.new(0, 34, 1, -224),
	Size = UDim2.fromOffset(190, 26),
	BackgroundTransparency = 0.12,
	BackgroundColor3 = C.Panel,
	Text = "",
	TextColor3 = C.Ink,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 62,
})
round(dialogueProfile, 13)
stroke(dialogueProfile, C.Yellow, 1, 0.32)
local dialogueName = label(dialogue, {
	Name = "NPCName",
	Position = UDim2.new(0, 36, 1, -178),
	Size = UDim2.fromOffset(110, 28),
	Text = "MARCUS",
	TextColor3 = C.White,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 62,
})
local dialogueLine = label(dialogue, {
	Name = "NPCLine",
	Position = UDim2.new(0, 150, 1, -184),
	Size = UDim2.new(0.5, -80, 0, 42),
	Text = "",
	TextColor3 = C.White,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 62,
})
local dialogueSubline = label(dialogue, {
	Name = "DealFacts",
	Position = UDim2.new(0, 36, 1, -139),
	Size = UDim2.new(0.6, -40, 0, 24),
	Text = "",
	TextColor3 = C.Ink,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 62,
})
local dialogueOptions = new("Frame", {
	Name = "DecisionDock",
	Position = UDim2.new(0, 34, 1, -104),
	Size = UDim2.new(0.62, -40, 0, 70),
	BackgroundTransparency = 1,
	ZIndex = 62,
}, dialogue)
new("UISizeConstraint", { MinSize = Vector2.new(520, 70), MaxSize = Vector2.new(840, 70) }, dialogueOptions)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 9),
}, dialogueOptions)

local oldDialogueSpeech = playerGui:FindFirstChild("CoreDialogueSpeech")
if oldDialogueSpeech then oldDialogueSpeech:Destroy() end
local dialogueSpeech = new("BillboardGui", {
	Name = "CoreDialogueSpeech",
	AlwaysOnTop = true,
	Enabled = false,
	LightInfluence = 0,
	MaxDistance = 28,
	Size = UDim2.fromOffset(326, 116),
	StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0),
}, playerGui)
local dialogueSpeechBubble = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -6, 1, -6),
	BackgroundColor3 = C.Paper,
	BackgroundTransparency = 0.03,
	BorderSizePixel = 0,
}, dialogueSpeech)
round(dialogueSpeechBubble, 15)
stroke(dialogueSpeechBubble, C.Ink, 2, 0.08)
local dialogueSpeechName = label(dialogueSpeechBubble, {
	Position = UDim2.fromOffset(16, 9),
	Size = UDim2.new(0.58, -16, 0, 24),
	Font = Theme.Fonts.Display,
	Text = "SELLER",
	TextColor3 = C.PaperDark,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})
local dialogueSpeechGreed = label(dialogueSpeechBubble, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 10),
	Size = UDim2.new(0.42, -8, 0, 22),
	Font = Theme.Fonts.Display,
	Text = "LOW GREED",
	TextColor3 = C.Ink,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextYAlignment = Enum.TextYAlignment.Center,
})
new("Frame", {
	Position = UDim2.fromOffset(16, 37),
	Size = UDim2.new(1, -32, 0, 1),
	BackgroundColor3 = C.PaperDark,
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
}, dialogueSpeechBubble)
local dialogueSpeechText = label(dialogueSpeechBubble, {
	Position = UDim2.fromOffset(16, 43),
	Size = UDim2.new(1, -32, 1, -50),
	Font = Theme.Fonts.Strong,
	Text = "",
	TextColor3 = C.PaperDark,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})
local dialogueSpeechScale = new("UIScale", { Scale = 0.9 }, dialogueSpeechBubble)
local dialogueSpeechToken = 0

local function hideNpcSpeech(immediate)
	dialogueSpeechToken += 1
	local token = dialogueSpeechToken
	if immediate then
		dialogueSpeech.Enabled = false
		dialogueSpeech.Adornee = nil
		return
	end
	TweenService:Create(dialogueSpeechScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 }):Play()
	task.delay(0.13, function()
		if dialogueSpeechToken == token then
			dialogueSpeech.Enabled = false
			dialogueSpeech.Adornee = nil
		end
	end)
end

local function showNpcSpeech(head, phrase, speakerName, greed)
	dialogueSpeechToken += 1
	local token = dialogueSpeechToken
	if not head or not head:IsA("BasePart") or phrase == "" then
		hideNpcSpeech(true)
		return
	end
	dialogueSpeech.Adornee = head
	dialogueSpeech.Enabled = true
	dialogueSpeechName.Text = string.upper(speakerName or "SELLER")
	local greedValue = math.clamp(tonumber(greed) or 0.5, 0, 1)
	dialogueSpeechGreed.Text = greedValue >= 0.75 and "HIGH GREED" or (greedValue >= 0.45 and "MID GREED" or "LOW GREED")
	dialogueSpeechGreed.TextColor3 = greedValue >= 0.75 and C.Red or (greedValue >= 0.45 and C.Yellow or C.Green)
	dialogueSpeechScale.Scale = 0.9
	dialogueSpeechText.Text = "▌"
	TweenService:Create(dialogueSpeechScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.spawn(function()
		if Motion.IsReducedMotion() then
			dialogueSpeechText.Text = phrase
			return
		end
		for index = 1, #phrase do
			if dialogueSpeechToken ~= token or not dialogueSpeech.Enabled then return end
			local character = string.sub(phrase, index, index)
			dialogueSpeechText.Text = string.sub(phrase, 1, index) .. " ▌"
			task.wait((character == "." or character == "," or character == "!") and 0.045 or 0.018)
		end
		if dialogueSpeechToken == token then
			dialogueSpeechText.Text = phrase
		end
	end)
end

local function restoreCamera()
	focusedHead = nil
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then camera.CameraSubject = humanoid end
end

local cinematicCharacterState

local function setCinematicCarVisible(car, visible)
	for _, d in ipairs(car:GetDescendants()) do
		if d:IsA("BasePart") then
			local shown = d:GetAttribute("CinematicTransparency")
			d.Transparency = visible and (shown or 0) or 1
			d.CanCollide = false
		end
	end
end

local function resetCinematicSet(set)
	if not set then return end
	local cars = set:FindFirstChild("CrazyCars")
	if cars then
		for _, car in ipairs(cars:GetChildren()) do
			if car:IsA("Model") then
				local start = cinematicCarStarts[car]
				if start then car:PivotTo(start) end
				setCinematicCarVisible(car, false)
			end
		end
	end
	local panel = set:FindFirstChild("LoosePanel", true)
	local home = panel and panel:GetAttribute("CinematicHome")
	if panel and typeof(home) == "CFrame" then
		panel.CFrame = home
	end
end

finishCinematic = function(_, beginFlow)
	if not cinematicPlaying then return end
	cinematicToken += 1
	cinematicPlaying = false
	local set = workspace:FindFirstChild("CoreUXPrototype") and workspace.CoreUXPrototype:FindFirstChild("OpeningCinematic")
	resetCinematicSet(set)
	cinematicUI.Visible = false
	cinematicLine.Visible = false
	aspiration.Visible = false
	hud.Visible = false
	cash.Visible = false
	phoneButton.Visible = true
	repairStrip.Visible = false
	local hint = workspace:FindFirstChild("SpawnHint", true)
	if hint and hint:IsA("BillboardGui") then hint.Enabled = true end
	if cinematicCharacterState then
		local humanoid = cinematicCharacterState.humanoid
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = cinematicCharacterState.walkSpeed
			humanoid.AutoRotate = cinematicCharacterState.autoRotate
			pcall(function()
				humanoid.JumpPower = cinematicCharacterState.jumpPower
				humanoid.JumpHeight = cinematicCharacterState.jumpHeight
			end)
		end
	end
	cinematicCharacterState = nil
	restoreCamera()
	if setUIMode then setUIMode(currentState and currentState.stage == 3 and currentState.repairStarted and "Repair" or "World") end
	if beginFlow ~= false then
		event:FireServer("Begin")
	end
end

local function animateCinematicCar(car, token)
	local start = cinematicCarStarts[car] or car:GetPivot()
	cinematicCarStarts[car] = start
	local delayTime = car:GetAttribute("Delay") or 0
	local duration = car:GetAttribute("Duration") or 3
	local laneZ = car:GetAttribute("LaneZ") or start.Position.Z
	local stopX = car:GetAttribute("StopX")
	task.wait(delayTime)
	if token ~= cinematicToken or not cinematicPlaying then return end
	setCinematicCarVisible(car, true)

	local function drive(fromX, toX, travelTime)
		local started = os.clock()
		while token == cinematicToken and cinematicPlaying do
			local alpha = math.clamp((os.clock() - started) / travelTime, 0, 1)
			local eased = 1 - (1 - alpha) * (1 - alpha)
			car:PivotTo(CFrame.new(fromX + (toX - fromX) * eased, start.Position.Y, laneZ) * start.Rotation)
			if alpha >= 1 then return true end
			RunService.RenderStepped:Wait()
		end
		return false
	end

	if stopX then
		if not drive(-125, stopX, duration * 0.42) then return end
		local expression = car:FindFirstChild("Expression", true)
		if expression and expression:IsA("TextLabel") then expression.Text = "•  ◡  -" end
		if car:GetAttribute("RichMoment") then
			cinematicWink.Visible = true
			cinematicWink.TextTransparency = 1
			TweenService:Create(cinematicWink, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
		end
		task.wait(car:GetAttribute("StopDuration") or 0.7)
		if expression and expression:IsA("TextLabel") then expression.Text = "•  ‿  •" end
		TweenService:Create(cinematicWink, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
		task.delay(0.2, function() cinematicWink.Visible = false end)
		if not drive(stopX, 120, duration * 0.58) then return end
	else
		if not drive(-125, 120, duration) then return end
	end
	setCinematicCarVisible(car, false)
end

local function playOpeningCinematic()
	local world = workspace:FindFirstChild("CoreUXPrototype")
	local set = world and world:FindFirstChild("OpeningCinematic")
	local markers = set and set:FindFirstChild("Markers")
	local cars = set and set:FindFirstChild("CrazyCars")
	if not set or not markers or not cars then
		aspiration.Visible = true
		return
	end
	local playerMarker = markers:WaitForChild("Player", 3)
	local idleMarker = markers:FindFirstChild("CamPlayerIdle")
	local roadMarker = markers:WaitForChild("CamRoad", 3)
	local winkMarker = markers:FindFirstChild("CamDriverWink")
	local revealMarker = markers:WaitForChild("CamReveal", 3)
	local decisionMarker = markers:WaitForChild("CamDecision", 3)
	if not playerMarker or not roadMarker or not revealMarker or not decisionMarker then
		aspiration.Visible = true
		return
	end
	if cinematicPlaying then
		finishCinematic(true, false)
	end
	cinematicToken += 1
	local token = cinematicToken
	cinematicPlaying = true
	if setUIMode then setUIMode("Cinematic") end
	aspiration.Visible = false
	cinematicUI.Visible = true
	cinematicLine.Visible = false
	hud.Visible = false
	cash.Visible = false
	phoneButton.Visible = false
	repairStrip.Visible = false
	hideIncomingPhone()
	local reset = gui:FindFirstChild("ResetPrototype")
	local nextFlow = gui:FindFirstChild("NextFlow")
	local layoutAudit = gui:FindFirstChild("LayoutAudit")
	if reset then reset.Visible = false end
	if nextFlow then nextFlow.Visible = false end
	if layoutAudit then layoutAudit.Visible = false end
	local hint = workspace:FindFirstChild("SpawnHint", true)
	if hint and hint:IsA("BillboardGui") then hint.Enabled = false end

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	cinematicCharacterState = {
		humanoid = humanoid,
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		autoRotate = humanoid.AutoRotate,
	}
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	pcall(function()
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end)
	character:PivotTo(playerMarker.CFrame)

	for _, car in ipairs(cars:GetChildren()) do
		if car:IsA("Model") then
			cinematicCarStarts[car] = cinematicCarStarts[car] or car:GetPivot()
			car:PivotTo(cinematicCarStarts[car])
			setCinematicCarVisible(car, false)
		end
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = (idleMarker or roadMarker).CFrame
	task.wait(0.9)
	if token ~= cinematicToken or not cinematicPlaying then return end
	for _, car in ipairs(cars:GetChildren()) do
		if car:IsA("Model") then task.spawn(animateCinematicCar, car, token) end
	end
	camera.CFrame = roadMarker.CFrame
	task.wait(1.48)
	if token ~= cinematicToken or not cinematicPlaying then return end
	if winkMarker then
		TweenService:Create(camera, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { CFrame = winkMarker.CFrame }):Play()
		task.wait(0.68)
		if token ~= cinematicToken or not cinematicPlaying then return end
	end

	local revealTween = TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		CFrame = revealMarker.CFrame,
	})
	revealTween:Play()
	revealTween.Completed:Wait()
	if token ~= cinematicToken or not cinematicPlaying then return end

	task.wait(0.45)
	local panel = set:FindFirstChild("LoosePanel", true)
	local panelHome = panel and panel:GetAttribute("CinematicHome")
	if panel and typeof(panelHome) == "CFrame" then
		TweenService:Create(panel, TweenInfo.new(0.38, Enum.EasingStyle.Bounce), {
			CFrame = panelHome * CFrame.new(0, -1.9, 0) * CFrame.Angles(0, 0, math.rad(-13)),
		}):Play()
	end
	task.wait(0.52)
	if token ~= cinematicToken or not cinematicPlaying then return end

	local decisionTween = TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		CFrame = decisionMarker.CFrame,
	})
	decisionTween:Play()
	decisionTween.Completed:Wait()
	if token ~= cinematicToken or not cinematicPlaying then return end

	cinematicLine.Visible = true
	cinematicLine.BackgroundTransparency = 1
	cinematicLineTitle.TextTransparency = 1
	cinematicLineSub.TextTransparency = 1
	TweenService:Create(cinematicLine, TweenInfo.new(0.22), { BackgroundTransparency = 0.12 }):Play()
	TweenService:Create(cinematicLineTitle, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()
	TweenService:Create(cinematicLineSub, TweenInfo.new(0.22), { TextTransparency = 0.18 }):Play()
	task.wait(1.45)
	if token ~= cinematicToken or not cinematicPlaying then return end
	finishCinematic(false)
end

local dialoguePreviousFov
local hiddenDialogueCards = {}
local hiddenDialoguePrompts = {}

local function canCustomizePersonalCar(state)
	return state ~= nil and state.stage == 9 and not state.driving
end

local function promptEnabledForState(name, state)
	if not state then return nil end
 if state.pendingDeal then return false end
	if name == "OpenLotPrompt" then return false end
	if name == "FirstSellerPrompt" then return state.stage == 2 end
	if name == "StartRepairPrompt" then return false end
	if name == "BodyRepairPrompt" then return state.stage == 3 and state.repairStarted and not state.fixes.Body end
	if name == "WheelsRepairPrompt" then return state.stage == 3 and state.repairStarted and not state.fixes.Wheels end
	if name == "EngineRepairPrompt" then return state.stage == 3 and state.repairStarted and not state.fixes.Engine end
	if name == "ListCarPrompt" then return false end
	if name == "BuyerPrompt" then return state.stage == 4 and state.buyerMet end
	if name == "BuildWorkshopPrompt" then return false end
	if name == "HireMechanicPrompt" then return false end
	if name == "SecondSellerPrompt" then return state.stage == 7 and state.secondVisible end
	if name == "ClaimCarPrompt" then return false end
	if name == "CustomizePrompt" then
		return canCustomizePersonalCar(state)
	end
	if name == "RareDrivePrompt" then
		return state.stage == 10 and state.rareRoute == "Seller" and state.rareTravelPhase == "GetIn"
	end
	if name == "RareSellerPrompt" then
		return state.stage == 10 and (state.rarePhase == "Waiting" or state.rarePhase == "Revealed")
	end
	return nil
end

local function setPromptLayerEnabled(enabled)
	if not enabled then
		table.clear(hiddenDialoguePrompts)
		for _, item in ipairs(workspace:GetDescendants()) do
			if item:IsA("ProximityPrompt") then
				hiddenDialoguePrompts[item] = item.Enabled
				item.Enabled = false
			end
		end
	else
		local snapshot = {}
		for prompt, wasEnabled in pairs(hiddenDialoguePrompts) do
			snapshot[prompt] = wasEnabled
		end
		table.clear(hiddenDialoguePrompts)
		task.delay(0.08, function()
			for prompt, wasEnabled in pairs(snapshot) do
				if prompt.Parent then
					local desired = prompt:GetAttribute('BusinessPromptEnabled')
					if desired == nil then desired = promptEnabledForState(prompt.Name, currentState) end
					prompt.Enabled = desired == nil and wasEnabled or desired
				end
			end
		end)
	end
end

local function setConversationChrome(open)
	if open then
		hud.Visible = false
		cash.Visible = false
		phoneButton.Visible = false
		repairStrip.Visible = false
		hideIncomingPhone()
		local reset = gui:FindFirstChild("ResetPrototype")
		local nextFlow = gui:FindFirstChild("NextFlow")
		local layoutAudit = gui:FindFirstChild("LayoutAudit")
		if reset then reset.Visible = false end
		if nextFlow then nextFlow.Visible = false end
		if layoutAudit then layoutAudit.Visible = false end
		setPromptLayerEnabled(false)
		table.clear(hiddenDialogueCards)
		for _, item in ipairs(workspace:GetDescendants()) do
			if item:IsA("BillboardGui") and item.Name == "CarState" then
				hiddenDialogueCards[item] = item.Enabled
				item.Enabled = false
			end
		end
	else
		setPromptLayerEnabled(true)
		for card, wasEnabled in pairs(hiddenDialogueCards) do
			if card.Parent then card.Enabled = wasEnabled end
		end
		table.clear(hiddenDialogueCards)
		local showChrome = not cinematicPlaying and not rareSequencePlaying and not drivingCar
		hud.Visible = false
		cash.Visible = false
		phoneButton.Visible = showChrome
		repairStrip.Visible = false
		local showDev = false
		local reset = gui:FindFirstChild("ResetPrototype")
		local nextFlow = gui:FindFirstChild("NextFlow")
		local layoutAudit = gui:FindFirstChild("LayoutAudit")
		if reset then reset.Visible = showDev or false end
		if nextFlow then nextFlow.Visible = showDev or false end
		if layoutAudit then layoutAudit.Visible = showDev or false end
	end
end

local dealPresenter
local function closeDialogue()
 if dealPresenter then dealPresenter.scene:Close()end
	if not dialogue.Visible then
		if uiMode == "DealClosure" and setUIMode then setUIMode(defaultModeForState()) end
		return
	end
	hideNpcSpeech(false)
	focus:Release("Negotiation")
	dialogue.Visible = false
	setConversationChrome(false)
	if dialoguePreviousFov then
		TweenService:Create(camera, TweenInfo.new(0.18), { FieldOfView = dialoguePreviousFov }):Play()
	end
	dialoguePreviousFov = nil
	restoreCamera()
	if setUIMode then setUIMode(currentState and currentState.stage == 3 and currentState.repairStarted and "Repair" or "World") end
end

dealPresenter = require(CoreUX:WaitForChild('DealPresenter')).new(gui,dialogue,Theme,event)
local function openDialogue(data, head)
 focus:Acquire('Negotiation',Theme.FocusPriority.Negotiation)
 if setUIMode then setUIMode('Dialogue')end
 if not dialogue.Visible then dialoguePreviousFov=camera.FieldOfView;setConversationChrome(true)end
 dialogue.Visible=true;dialogue:SetAttribute('DealClosing',false)
 hideNpcSpeech(false)
 dealPresenter:Show(data,head,currentState)
 if head and head:IsA('BasePart')then focusedHead=head end
end

local rareRevealMoment = new("Frame", {
	Name = "RareRevealMoment",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0.055, 0, 0.14, 0),
	Size = UDim2.fromOffset(460, 132),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 151,
}, gui)
round(rareRevealMoment, 18)
stroke(rareRevealMoment, C.Yellow, 2, 0.05)
local rareRevealScale = new("UIScale", { Scale = 0.75 }, rareRevealMoment)
local rareRevealTag = label(rareRevealMoment, {
	Position = UDim2.fromOffset(18, 10),
	Size = UDim2.new(1, -36, 0, 22),
	Text = "RARE FIND",
	TextColor3 = C.Ink,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 152,
})
local rareRevealName = label(rareRevealMoment, {
	Position = UDim2.fromOffset(18, 31),
	Size = UDim2.new(1, -36, 0, 42),
	Text = "1972 PHOENIX GT",
	TextColor3 = C.White,
	TextSize = 26,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 152,
})
local rareRevealState = label(rareRevealMoment, {
	Position = UDim2.fromOffset(18, 75),
	Size = UDim2.new(1, -36, 0, 25),
	Text = "RARE · SURVIVOR · 62%",
	TextColor3 = C.Ink,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 152,
})

local rareCharacterState

local function freezeForRareSequence(frozen)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if frozen then
		if humanoid and not rareCharacterState then
			rareCharacterState = {
				humanoid = humanoid,
				walkSpeed = humanoid.WalkSpeed,
				autoRotate = humanoid.AutoRotate,
			}
			humanoid.WalkSpeed = 0
			humanoid.AutoRotate = false
		end
	elseif rareCharacterState then
		local saved = rareCharacterState
		if saved.humanoid and saved.humanoid.Parent then
			saved.humanoid.WalkSpeed = saved.walkSpeed
			saved.humanoid.AutoRotate = saved.autoRotate
		end
		rareCharacterState = nil
	end
end

local function finishRareSequence()
	rareSequencePlaying = false
	freezeForRareSequence(false)
	setConversationChrome(false)
	restoreCamera()
	if setUIMode then setUIMode(currentState and currentState.stage == 3 and currentState.repairStarted and "Repair" or "World") end
end

local function cancelRareSequence()
	rareSequenceToken += 1
	if rareSequencePlaying then
		finishRareSequence()
	end
end

local function playRareArrival()
	cancelRareSequence()
	rareSequenceToken += 1
	local token = rareSequenceToken
	rareSequencePlaying = true
	if setUIMode then setUIMode("Cinematic") end
	setConversationChrome(true)
	freezeForRareSequence(true)

	local world = workspace:FindFirstChild("CoreUXPrototype")
	local set = world and world:FindFirstChild("RareArrival")
	local markers = set and set:FindFirstChild("Markers")
	local cameraMarker = markers and markers:FindFirstChild("ArrivalCamera")
	local stopMarker = markers and markers:FindFirstChild("ArrivalCameraStop")
	if not set or not cameraMarker then
		finishRareSequence()
		event:FireServer("RareArrivalReady")
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraMarker.CFrame
	local duration = set:GetAttribute("ArrivalDuration") or 3.4
	local firstBeat = duration * 0.54
	task.wait(firstBeat)
	if token ~= rareSequenceToken then return end
	if stopMarker then
		local stopTween = TweenService:Create(camera, TweenInfo.new(duration - firstBeat, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { CFrame = stopMarker.CFrame })
		stopTween:Play()
		-- Never let a cancelled or non-signalling camera tween strand the FTUE.
		task.wait(math.max(0.05, duration - firstBeat))
		if token ~= rareSequenceToken then return end
		camera.CFrame = stopMarker.CFrame
	else
		task.wait(duration - firstBeat)
	end
	task.wait(0.1)
	if token ~= rareSequenceToken then return end
	finishRareSequence()
	event:FireServer("RareArrivalReady")
end

local function playRareReveal()
	cancelRareSequence()
	rareSequenceToken += 1
	local token = rareSequenceToken
	rareSequencePlaying = true
	if setUIMode then setUIMode("Cinematic") end
	setConversationChrome(true)
	freezeForRareSequence(true)

	local world = workspace:FindFirstChild("CoreUXPrototype")
	local set = world and world:FindFirstChild("RareArrival")
	local markers = set and set:FindFirstChild("Markers")
	local revealName = currentState and currentState.rareRoute == "Seller" and "SellerRevealCamera" or "RevealCamera"
	local cameraMarker = markers and markers:FindFirstChild(revealName)
	local cover = set and set:FindFirstChild("Cover", true)
	if not cover or not cameraMarker then
		finishRareSequence()
		event:FireServer("RareRevealDone")
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraMarker.CFrame
	rareRevealMoment.Visible = false
	task.wait(0.28)
	for _, item in ipairs(cover:GetDescendants()) do
		if item:IsA("BasePart") then
			TweenService:Create(item, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1,
			}):Play()
		end
	end
	task.wait(0.88)
	if token ~= rareSequenceToken then return end
	rareRevealMoment.Visible = true
	rareRevealScale.Scale = 0.72
	rareRevealMoment.BackgroundTransparency = 1
	TweenService:Create(rareRevealScale, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(rareRevealMoment, TweenInfo.new(0.18), { BackgroundTransparency = 0.08 }):Play()
	task.wait(1.8)
	if token ~= rareSequenceToken then return end
	TweenService:Create(rareRevealMoment, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.22)
	rareRevealMoment.Visible = false
	finishRareSequence()
	event:FireServer("RareRevealDone")
end

local phoneBackdrop = new("TextButton", {
	Name = "PhoneBackdrop",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.48,
	BorderSizePixel = 0,
	Text = "",
	Visible = false,
	ZIndex = 70,
	AutoButtonColor = false,
}, gui)
local phoneShell = new("Frame", {
	Name = "PhoneShell",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.31, 0.88),
	BackgroundColor3 = Color3.fromRGB(224, 229, 219),
	BorderSizePixel = 0,
	ZIndex = 71,
}, phoneBackdrop)
round(phoneShell, 28)
stroke(phoneShell, Color3.fromRGB(122, 126, 132), 3)
new("UIAspectRatioConstraint", {
	AspectRatio = 0.56,
	DominantAxis = Enum.DominantAxis.Height,
}, phoneShell)
new("Frame", {
	Name = "SideButton",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(0, -2, 0.28, 0),
	Size = UDim2.fromScale(0.03, 0.18),
	BackgroundColor3 = Color3.fromRGB(30, 39, 42),
	BorderSizePixel = 0,
	ZIndex = 70,
}, phoneShell)
local phoneScreen = new("Frame", {
	Name = "Screen",
	Position = UDim2.fromScale(0.055, 0.035),
	Size = UDim2.fromScale(0.89, 0.93),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 72,
}, phoneShell)
round(phoneScreen, 20)
local phoneNotch = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromScale(0.45, 0.055),
	BackgroundColor3 = Color3.fromRGB(224, 229, 219),
	BorderSizePixel = 0,
	ZIndex = 75,
}, phoneScreen)
round(phoneNotch, 12)
local phoneHeader = label(phoneScreen, {
	Name = "Header",
	Position = UDim2.fromScale(0.08, 0.065),
	Size = UDim2.fromScale(0.84, 0.1),
	Text = "DEALS",
	TextColor3 = C.White,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneStatus = label(phoneScreen, {
	Name = "Status",
	Position = UDim2.fromScale(0.08, 0.15),
	Size = UDim2.fromScale(0.84, 0.07),
	Text = "TODAY",
	TextColor3 = C.Ink,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneCard = new("Frame", {
	Name = "LeadCard",
	Position = UDim2.fromScale(0.07, 0.23),
	Size = UDim2.fromScale(0.86, 0.57),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	ZIndex = 73,
}, phoneScreen)
round(phoneCard, 15)
stroke(phoneCard, C.Yellow, 1.5)
local phoneCardTag = label(phoneCard, {
	Name = "Tag",
	Position = UDim2.fromScale(0.08, 0.06),
	Size = UDim2.fromScale(0.84, 0.13),
	Text = "NEW OFFER",
	TextColor3 = C.Ink,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneCardTitle = label(phoneCard, {
	Name = "Title",
	Position = UDim2.fromScale(0.08, 0.2),
	Size = UDim2.fromScale(0.84, 0.17),
	Text = "RUSTY SEDAN",
	TextColor3 = C.White,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneCardValue = label(phoneCard, {
	Name = "Value",
	Position = UDim2.fromScale(0.08, 0.37),
	Size = UDim2.fromScale(0.84, 0.16),
	Text = "$2,350",
	TextColor3 = C.Ink,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneCardDetail = label(phoneCard, {
	Name = "Detail",
	Position = UDim2.fromScale(0.08, 0.54),
	Size = UDim2.fromScale(0.84, 0.16),
	Text = "Buyer wants to view it in person.",
	TextColor3 = C.Muted,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 74,
})
local phoneAction = button(phoneCard, {
	Name = "Action",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.98),
	Size = UDim2.fromScale(0.84, 0.25),
	BackgroundColor3 = C.Yellow,
	Text = "MEET AT CAR",
	TextSize = 14,
	ZIndex = 75,
}, function() end)
local phoneSecondaryAction = button(phoneCard, {
	Name = "SecondaryAction",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.99),
	Size = UDim2.fromScale(0.84, 0.20),
	BackgroundColor3 = C.SoftPanel,
	Text = "BRING TO MY LOT\nNO TRAVEL · FULL ASK",
	TextColor3 = C.White,
	TextSize = 11,
	Visible = false,
	ZIndex = 75,
}, function() end)
phoneAction.TextWrapped = true
phoneSecondaryAction.TextWrapped = true
local homeBar = new("Frame", {
	Name = "HomeBar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.985),
	Size = UDim2.fromScale(0.34, 0.012),
	BackgroundColor3 = C.Muted,
	BorderSizePixel = 0,
	ZIndex = 75,
}, phoneScreen)
round(homeBar, 5)

local function closePhone()
	focus:Release("Phone")
	phoneBackdrop.Visible = false
	if setUIMode and uiMode == "Phone" then setUIMode(currentState and currentState.stage == 3 and currentState.repairStarted and "Repair" or "World") end
end

phoneBackdrop.Activated:Connect(closePhone)
phoneShell.InputBegan:Connect(function() end)

local phoneActionConnection
local phoneSecondaryConnection
local function configurePhone()
	if phoneActionConnection then phoneActionConnection:Disconnect() end
	if phoneSecondaryConnection then phoneSecondaryConnection:Disconnect() end
	phoneSecondaryAction.Visible = false
	phoneAction.Position = UDim2.fromScale(0.5, 0.98)
	phoneAction.Size = UDim2.fromScale(0.84, 0.25)
	local kind = currentState and currentState.phone
	phoneHeader.Text = "DEALS"
	if kind == "FirstOffer" then
		phoneStatus.Text = "OFFER TO VIEW"
		phoneCardTag.Text = "BUYER NEARBY"
		phoneCardTitle.Text = "RUSTY SEDAN"
		phoneCardValue.Text = "$2,350"
		phoneCardDetail.Text = "Marcus wants to see the car in person."
		phoneAction.Text = "MEET AT CAR"
		phoneAction.BackgroundColor3 = C.Yellow
		phoneActionConnection = phoneAction.Activated:Connect(function()
			closePhone()
			phoneDot.Visible = false
			event:FireServer("MeetBuyer")
		end)
	elseif kind == "SecondLead" then
		phoneStatus.Text = "LOCAL LEAD · 0.3 MI"
		phoneCardTag.Text = "SMART SELLER"
		phoneCardTitle.Text = "DESERT COUPE"
		phoneCardValue.Text = "$1,400"
		phoneCardDetail.Text = "State is visible. Seller knows the market."
		phoneAction.Text = "VIEW IN PERSON"
		phoneAction.BackgroundColor3 = C.Yellow
		phoneActionConnection = phoneAction.Activated:Connect(function()
			closePhone()
			phoneDot.Visible = false
			event:FireServer("ViewSecond")
		end)
	elseif kind == "Opportunities" then
        phoneHeader.Text="NEXT FLIP";phoneStatus.Text="YOUR BUSINESS CONTINUES";phoneCardTag.Text="CHOOSE AN OPPORTUNITY";phoneCardTitle.Text="ROUTINE OR SPECIALIST";phoneCardValue.Text="";phoneCardDetail.Text="Staff handle routine cars. Take another private lead when you want to negotiate personally."
        phoneAction.Position=UDim2.fromScale(.5,.77);phoneAction.Size=UDim2.fromScale(.84,.20);phoneAction.Text="CONTINUE ROUTINE FLIPS"
        phoneSecondaryAction.Visible=true;phoneSecondaryAction.Position=UDim2.fromScale(.5,.99);phoneSecondaryAction.Size=UDim2.fromScale(.84,.20);phoneSecondaryAction.Text="TAKE A SPECIALIST LEAD"
        phoneActionConnection=phoneAction.Activated:Connect(function()closePhone();event:FireServer('RoutineOpportunity')end)
        phoneSecondaryConnection=phoneSecondaryAction.Activated:Connect(function()closePhone();event:FireServer('SpecialistOpportunity')end)
	elseif kind == "FutureLead" then
        phoneHeader.Text="RARE OPPORTUNITY";phoneStatus.Text="YOUR SELLER AREA";phoneCardTag.Text="ONE SPECIAL FLIP";phoneCardTitle.Text="RARE CAR";phoneCardValue.Text="$4,800 + REPAIRS";phoneCardDetail.Text="The seller drives to your normal intake. Other arrivals pause until this car is sold."
        phoneAction.Text="INVITE THE SELLER";phoneAction.BackgroundColor3=C.Green
        phoneActionConnection=phoneAction.Activated:Connect(function()closePhone();event:FireServer('RequestRareArrival')end)

	else
		phoneHeader.Text = "DEALS"
		phoneStatus.Text = "TODAY"
		phoneCardTag.Text = "NO NEW LEADS"
		phoneCardTitle.Text = "KEEP BUILDING"
		phoneCardValue.Text = "—"
		phoneCardDetail.Text = "Opportunities will arrive here."
		phoneAction.Text = "CLOSE"
		phoneAction.BackgroundColor3 = C.SoftPanel
		phoneActionConnection = phoneAction.Activated:Connect(closePhone)
	end
end

openFullPhone = function()
	if not focus:CanShow(Theme.FocusPriority.Phone) then
		phoneDot.Visible = true
		return
	end
	focus:Acquire("Phone", Theme.FocusPriority.Phone)
	hideIncomingPhone()
	configurePhone()
	if setUIMode then setUIMode("Phone") end
	phoneBackdrop.Visible = true
	phoneDot.Visible = false
end

phoneButton.Activated:Connect(openFullPhone)
incomingPhone.Activated:Connect(openFullPhone)

local profit = new("Frame", {
	Name = "Profit",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 80,
}, gui)
local profitCard = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 360, 0.5, 0),
	Size = UDim2.fromOffset(324, 250),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	ZIndex = 81,
}, profit)
round(profitCard, 17)
stroke(profitCard, C.Green, 2, 0.08)
new("Frame", {
	Size = UDim2.fromOffset(7, 250),
	BackgroundColor3 = C.Green,
	BorderSizePixel = 0,
	ZIndex = 82,
}, profitCard)
label(profitCard, {
	Position = UDim2.fromOffset(24, 15),
	Size = UDim2.new(1, -42, 0, 28),
	Text = "SOLD · FIRST FLIP",
	TextColor3 = C.White,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 82,
})
local profitRows = new("Frame", {
	Position = UDim2.fromOffset(24, 56),
	Size = UDim2.new(1, -46, 0, 126),
	BackgroundTransparency = 1,
	ZIndex = 82,
}, profitCard)
local rowLabels = {}
for index, name in ipairs({"INVESTED", "SOLD", "PROFIT"}) do
	label(profitRows, {
		Position = UDim2.new(0, 0, (index - 1) / 3, 0),
		Size = UDim2.new(0.52, 0, 1 / 3, -2),
		Text = name,
		TextColor3 = name == "PROFIT" and C.Green or C.Muted,
		TextSize = name == "PROFIT" and 16 or 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 83,
	})
	local value = label(profitRows, {
		Position = UDim2.new(0.52, 0, (index - 1) / 3, 0),
		Size = UDim2.new(0.48, 0, 1 / 3, -2),
		Text = "$0",
		TextColor3 = name == "PROFIT" and C.Green or C.White,
		TextSize = name == "PROFIT" and 22 or 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 83,
	})
	rowLabels[name] = value
end
label(profitCard, {
	Position = UDim2.fromOffset(24, 198),
	Size = UDim2.new(1, -46, 0, 34),
	BackgroundTransparency = 0.12,
	BackgroundColor3 = C.Panel,
	Text = "WORKSHOP UNLOCKED  →",
	TextColor3 = C.Ink,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 83,
})
local profitToken = 0
local function showProfit(data)
	profitToken += 1
	local token = profitToken
	local invested = data.invested or ((data.bought or 0) + (data.repairs or 0))
	rowLabels.INVESTED.Text = "-$" .. tostring(invested)
	rowLabels.SOLD.Text = "+$" .. tostring(data.sold or 0)
	rowLabels.PROFIT.Text = "+$" .. tostring(data.profit or 0)
	profit.Visible = true
	profitCard.Position = UDim2.new(1, 360, 0.5, 0)
	TweenService:Create(profitCard, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -18, 0.5, 0),
	}):Play()
	task.delay(4.8, function()
		if profitToken ~= token then return end
		TweenService:Create(profitCard, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 360, 0.5, 0),
		}):Play()
		task.delay(0.28, function()
			if profitToken == token then profit.Visible = false end
		end)
	end)
end

local customizationPresenter = CustomizationPresenter.new({
	gui = gui,
	event = event,
	camera = camera,
	restoreCamera = restoreCamera,
	setMode = function(mode)
		if setUIMode then setUIMode(mode) end
	end,
	defaultMode = function()
		return defaultModeForState and defaultModeForState() or "World"
	end,
	playSound = function(cue)
		audio:Play(cue)
	end,
})
local customize = customizationPresenter.root

local returnChoice = new("Frame", {
	Name = "ReturnChoice",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.58,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 86,
}, gui)
local returnPanel = new("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(620, 138),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	ZIndex = 87,
}, returnChoice)
round(returnPanel, 17)
stroke(returnPanel, C.Yellow, 1.5, 0.08)
label(returnPanel, {
	Position = UDim2.fromOffset(18, 12),
	Size = UDim2.new(1, -36, 0, 28),
	Text = "HEAD BACK TO YOUR DEALERSHIP",
	TextColor3 = C.White,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 88,
})
label(returnPanel, {
	Position = UDim2.fromOffset(18, 39),
	Size = UDim2.new(1, -36, 0, 22),
	Text = "Skip the empty return trip, or drive back yourself.",
	TextColor3 = C.Muted,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 88,
})
local quickReturnButton = button(returnPanel, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -14),
	Size = UDim2.new(0.58, -24, 0, 54),
	BackgroundColor3 = C.Yellow,
	Text = "RETURN TO LOT",
	TextSize = 15,
	ZIndex = 88,
}, function()
	returnChoice.Visible = false
	event:FireServer("QuickReturn")
end)
local driveBackButton = button(returnPanel, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -14),
	Size = UDim2.new(0.42, -6, 0, 54),
	BackgroundColor3 = C.SoftPanel,
	Text = "DRIVE BACK",
	TextColor3 = C.White,
	TextSize = 14,
	ZIndex = 88,
}, function()
	returnChoice.Visible = false
	event:FireServer("DriveBack")
end)

local drive = new("Frame", {
	Name = "Drive",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 90,
}, gui)
local driveGoal = label(drive, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.04),
	Size = UDim2.fromScale(0.38, 0.12),
	BackgroundTransparency = 0,
	BackgroundColor3 = C.Panel,
	Text = "MYSTERY LEAD · FOLLOW THE YELLOW ROUTE",
	TextColor3 = C.Ink,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 91,
})
round(driveGoal, 12)
local leftButton = button(drive, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0.035, 0.94),
	Size = UDim2.fromScale(0.13, 0.24),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.15,
	Text = "‹",
	TextColor3 = C.White,
	TextSize = 48,
	ZIndex = 91,
})
local rightButton = button(drive, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0.18, 0.94),
	Size = UDim2.fromScale(0.13, 0.24),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.15,
	Text = "›",
	TextColor3 = C.White,
	TextSize = 48,
	ZIndex = 91,
})
local gasButton = button(drive, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(0.965, 0.94),
	Size = UDim2.fromScale(0.2, 0.26),
	BackgroundColor3 = C.Yellow,
	Text = "HOLD\nGAS",
	TextColor3 = C.Ink,
	TextSize = 20,
	ZIndex = 91,
})
local finishDriveButton = button(drive, {
	Name = "FinishDrive",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(0.965, 0.18),
	Size = UDim2.fromScale(0.18, 0.15),
	BackgroundColor3 = C.Green,
	Text = "ARRIVE",
	Visible = false,
	TextColor3 = C.Ink,
	TextSize = 14,
	ZIndex = 91,
}, function()
	event:FireServer("FinishDrive")
end)

local function sendDrive()
	event:FireServer("DriveInput", { throttle = throttle, steer = steer })
end

local function bindHold(guiButton, onBegin, onEnd)
	guiButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			onBegin()
		end
	end)
	guiButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			onEnd()
		end
	end)
end

bindHold(gasButton, function()
	throttle = 1
	sendDrive()
end, function()
	throttle = 0
	sendDrive()
end)
bindHold(leftButton, function()
	steer = -1
	sendDrive()
end, function()
	steer = 0
	sendDrive()
end)
bindHold(rightButton, function()
	steer = 1
	sendDrive()
end, function()
	steer = 0
	sendDrive()
end)

local setLayoutAudit

local resetButton = button(gui, {
	Name = "ResetPrototype",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -18),
	Size = UDim2.fromOffset(94, 30),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.25,
	Text = "RESET FLOW",
	TextColor3 = C.Muted,
	TextSize = 10,
	Visible = RunService:IsStudio(),
	ZIndex = 30,
}, function()
	event:FireServer("ResetPrototype")
end)

local nextFlowButton = button(gui, {
	Name = "NextFlow",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 120, 1, -18),
	Size = UDim2.fromOffset(94, 30),
	BackgroundColor3 = C.Yellow,
	Text = "NEXT FLOW",
	TextColor3 = C.Ink,
	TextSize = 10,
	Visible = RunService:IsStudio(),
	ZIndex = 30,
}, function()
	aspiration.Visible = false
	event:FireServer("DebugNext")
end)

local layoutAuditBadge = label(gui, {
	Name = "LayoutAuditBadge",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(330, 38),
	BackgroundTransparency = 0.04,
	BackgroundColor3 = C.Panel,
	Text = "STUDIO UI LAYOUT AUDIT · ALL SYSTEMS",
	TextColor3 = C.Ink,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
	ZIndex = 200,
})
round(layoutAuditBadge, 11)
stroke(layoutAuditBadge, C.Yellow, 1.5, 0.08)

local layoutAuditButton = button(gui, {
	Name = "LayoutAudit",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 222, 1, -18),
	Size = UDim2.fromOffset(94, 30),
	BackgroundColor3 = C.SoftPanel,
	Text = "UI AUDIT",
	TextColor3 = C.Ink,
	TextSize = 10,
	Visible = RunService:IsStudio(),
	ZIndex = 30,
}, function()
	gui:SetAttribute("LayoutAuditMode", gui:GetAttribute("LayoutAuditMode") ~= true)
end)

local layoutAuditConnection
local layoutAuditBackgrounds = {}
local function rememberBackground(object)
	if object and layoutAuditBackgrounds[object] == nil then
		layoutAuditBackgrounds[object] = object.BackgroundTransparency
	end
end

local function auditShowWorld()
	local world = workspace:FindFirstChild("CoreUXPrototype")
	local deal = world and world:FindFirstChild("FirstDeal")
	if deal then
		for _, item in ipairs(deal:GetDescendants()) do
			if item:IsA("BasePart") then
				item.Transparency = item:GetAttribute("ShownTransparency") or 0
			elseif item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
				item.Enabled = item.Name ~= "CarState"
			end
		end
	end
	local seller = deal and deal:FindFirstChild("FirstSeller")
	local head = seller and seller:FindFirstChild("Head")
	if head then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(head.Position + Vector3.new(0, 2.2, -16), head.Position + Vector3.new(0, 0.3, 0))
	end
	return head
end

local function enforceLayoutAudit()
	if gui:GetAttribute("LayoutAuditMode") ~= true then return end
	layoutAuditBadge.Visible = true
	resetButton.Visible = false
	nextFlowButton.Visible = false
	layoutAuditButton.Visible = false
	aspiration.Visible = false
	cinematicUI.Visible = false

	hud.Visible = false
	flowLabel.Text = "FIRST HIRE  ·  6/9"
	objectiveLabel.Text = "Hire a mechanic, then follow the route to the next seller"
	cash.Visible = false
	cashText.Text = "$5,300"
	phoneButton.Visible = true
	phoneDot.Visible = true
	incomingPhone.Visible = true

	toast.Visible = false
	toast.Position = UDim2.new(0.5, 0, 0, 78)
	toastTitle.Text = "ACTION COMPLETE"
	toastDetail.Text = "-$220 COST  ·  +$600 VALUE"
	toastStripe.BackgroundColor3 = C.Green
	toastTitle.TextColor3 = C.Ink

	repairStrip.Visible = false
	repairProgress.Text = "RESTORATION · 2/3"
	repairLabels.BODY.Text = "✓  BODY    +$300 VALUE"
	repairLabels.BODY.TextColor3 = C.Ink
	repairLabels.WHEELS.Text = "✓  WHEELS    +$400 VALUE"
	repairLabels.WHEELS.TextColor3 = C.Ink
	repairLabels.ENGINE.Text = "○  ENGINE    +$600 VALUE"
	repairLabels.ENGINE.TextColor3 = C.White

	if promptPresenter and promptPresenter.root then
		promptPresenter.root.Visible = true
		local helper = promptPresenter.root
		local actionText = helper:FindFirstChild("ActionText", true)
		local objectText = helper:FindFirstChild("ObjectText", true)
		local costText = helper:FindFirstChild("CostText", true)
		local valueText = helper:FindFirstChild("ValueText", true)
		if actionText then actionText.Text = "TUNE ENGINE" end
		if objectText then objectText.Visible = false end
		if costText then costText.Text = "-$220 COST" costText.Visible = true end
		if valueText then valueText.Text = "+$600 VALUE" valueText.Visible = true end
	end

	purchasePads.actionButton.Visible = true
	purchasePads.actionButton.Text = "HIRE  $500"
	purchasePads.actionButton.BackgroundColor3 = C.Yellow
	purchasePads.actionButton.TextColor3 = C.Ink

	dialogue.Visible = true
	dialogueShade.Visible = true
	dialogueProfile.Visible = true
	dialogueProfile.Text = "LOW GREED"
	dialogueName.Visible = true
	dialogueName.Text = "JESSE"
	dialogueLine.Visible = true
	dialogueLine.Text = "Runs rough. Body is tired. I want $900."
	dialogueSubline.Visible = true
	dialogueSubline.Text = "ASK $900  ·  EST. $2.3K"
	dialogueOptions.Visible = true
	local auditGreedPanel = dialogue:FindFirstChild("GreedPanel")
	if auditGreedPanel then auditGreedPanel.Visible = true end
	dialogueSpeech.Enabled = true
	dialogueSpeechName.Text = "JESSE"
	dialogueSpeechGreed.Text = "LOW GREED"
	dialogueSpeechText.Text = "Runs rough. Body is tired. I want $900."

	local closure = gui:FindFirstChild("DealClosureResult")
	if closure then
		closure.Visible = true
		closure.Position = UDim2.new(0.5, 0, 0.66, 0)
	end

	local receipt = gui:FindFirstChild("HFProfitReceipt")
	if receipt then
		receipt.Visible = true
		local card = receipt:FindFirstChildWhichIsA("Frame")
		if card then card.Position = UDim2.new(1, -18, 0.54, 0) end
	end
	profit.Visible = false

	rememberBackground(phoneBackdrop)
	phoneBackdrop.Visible = true
	phoneBackdrop.BackgroundTransparency = 1
	phoneShell.Visible = true
	phoneHeader.Text = "PRIVATE LEADS"
	phoneStatus.Text = "RARE SELLER · 0.2 MI"
	phoneCardTag.Text = "RARE LEAD"
	phoneCardTitle.Text = "UNKNOWN VEHICLE"
	phoneCardValue.Text = "EST. $7.2K"
	phoneCardDetail.Text = "Choose how to meet Elias."
	phoneAction.Visible = true
	phoneAction.Text = "DRIVE TO SELLER\nSAVE $300"
	phoneSecondaryAction.Visible = true
	phoneSecondaryAction.Text = "BRING TO MY LOT\nNO TRAVEL · FULL ASK"

	rememberBackground(customize)
	customize.Visible = true
	customize.BackgroundTransparency = 1
	rememberBackground(drive)
	drive.Visible = true
	drive.BackgroundTransparency = 1
	rareRevealMoment.Visible = true
	rareRevealMoment.BackgroundTransparency = 0.08
end

setLayoutAudit = function(enabled)
	gui:SetAttribute("LayoutAuditMode", enabled == true)
	if layoutAuditConnection then
		layoutAuditConnection:Disconnect()
		layoutAuditConnection = nil
	end
	if enabled then
		local head = auditShowWorld()
		if head then dialogueSpeech.Adornee = head end
		showIncomingPhone({
			title = "RARE LEAD",
			detail = "Unknown car · seller waiting",
		})
		openDialogue({
			kind = "FirstSeller",
			name = "JESSE",
			line = "Runs rough. Body is tired. I want $900.",
			greed = 0.36,
			options = {
				{ id = "FirstBuy", text = "BUY  $900", tone = "Green" },
				{ id = "FirstAsk", text = "OFFER  $850", tone = "Yellow" },
				{ id = "CloseDialogue", text = "WALK", tone = "Dark" },
			},
		}, head)
		enforceLayoutAudit()
		layoutAuditConnection = RunService.Heartbeat:Connect(enforceLayoutAudit)
	else
		layoutAuditBadge.Visible = false
		for object, transparency in pairs(layoutAuditBackgrounds) do
			if object.Parent then object.BackgroundTransparency = transparency end
		end
		table.clear(layoutAuditBackgrounds)
		dialogueSpeech.Enabled = false
		restoreCamera()
		event:FireServer("ResetPrototype")
	end
end

gui:SetAttribute("LayoutAuditMode", false)
gui:GetAttributeChangedSignal("LayoutAuditMode"):Connect(function()
	local enabled = gui:GetAttribute("LayoutAuditMode") == true
	if enabled and not layoutAuditConnection then
		setLayoutAudit(true)
	elseif not enabled and layoutAuditConnection then
		setLayoutAudit(false)
	end
end)

defaultModeForState = function()
	if currentState and currentState.stage == 3 and currentState.repairStarted then return "Repair" end
	if gui:GetAttribute("ActiveFocus") == "PurchasePad" then return "PadPreview" end
	return "World"
end

setUIMode = function(mode)
	if mode == "World" and gui:GetAttribute("ActiveFocus") == "PurchasePad" then mode = "PadPreview" end
	uiMode = mode or "World"
	gui:SetAttribute("UIMode", uiMode)
	local worldMode = uiMode == "World" or uiMode == "PadPreview"
	local contextualMode = worldMode or uiMode == "Repair"
	local ordinaryHUD = worldMode and not (currentState and currentState.stage == 3 and currentState.repairStarted)
	hud.Visible = false
	cash.Visible = false
	phoneButton.Visible = uiMode == "World"
	repairStrip.Visible = false
	if uiMode ~= "Phone" then phoneBackdrop.Visible = false end
	if uiMode ~= "Customize" then customize.Visible = false end
	if uiMode ~= "Drive" then drive.Visible = false end
	if uiMode ~= "ReturnChoice" then returnChoice.Visible = false end
	if uiMode ~= "Dialogue" and uiMode ~= "DealClosure" then
		dialogue.Visible = false
		dialogueSpeech.Enabled = false
	end
	if not contextualMode then
		hideIncomingPhone()
		toast.Visible = false
	end
	promptPresenter:SetSuppressed(not (uiMode == "World" or uiMode == "Repair"))
	purchasePads:SetSuppressed(not (uiMode == "World" or uiMode == "PadPreview"))
end

gui:GetAttributeChangedSignal("ActiveFocus"):Connect(function()
	local owner = gui:GetAttribute("ActiveFocus")
	if owner == "PurchasePad" and uiMode == "World" then
		setUIMode("PadPreview")
	elseif owner ~= "PurchasePad" and uiMode == "PadPreview" then
		setUIMode(defaultModeForState())
	end
end)

local Journey=require(CoreUX:WaitForChild('BusinessJourney'))
local function activePadIdForState(state)return Journey.Active(state)end

local function carCardRelevant(card, state)
	if not state then return false end
	if card:FindFirstAncestor("FirstCar") then
		return state.stage == 2 and not dialogue.Visible
	end
	if card:FindFirstAncestor("SecondCar") then
		return state.stage == 7 and state.secondVisible
	end
	if card:FindFirstAncestor("RareCar") then
		return state.stage == 10 and (state.rarePhase == "Revealed" or state.rarePhase == "Purchased")
	end
	return false
end

local worldChromeClock = 0
RunService.Heartbeat:Connect(function(dt)
	worldChromeClock += dt
	if worldChromeClock < 0.12 then return end
	worldChromeClock = 0
	local world = workspace:FindFirstChild("CoreUXPrototype")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not world or not root then return end
	local allowWorldInfo = uiMode == "World"
	local nearestCar, nearestDistance
	local activePadId = activePadIdForState(currentState)
	for _, item in ipairs(world:GetDescendants()) do
		if item:IsA("BillboardGui") then
			if item.Name == "CarState" then
				item.Enabled = false
				local adornee = item.Parent
				local position = adornee and adornee:IsA("BasePart") and adornee.Position
				local distance = position and (root.Position - position).Magnitude
				if allowWorldInfo and distance and distance <= 22 and carCardRelevant(item, currentState)
					and (not nearestDistance or distance < nearestDistance) then
					nearestCar, nearestDistance = item, distance
				end
			elseif item.Name=='CarReadiness' then
    local body=item.Parent;local distance=(root.Position-body.Position).Magnitude
    item.Enabled=(uiMode=='World' or uiMode=='Repair') and currentState and currentState.stage>=3 and currentState.stage<=4 and distance<35
			elseif item.Name == "StaffState" then
				item.Enabled = false
			elseif item.Name == "PadCallout" then
				local pad = item.Parent
				local distance = pad and pad:IsA("BasePart") and (root.Position - pad.Position).Magnitude
				local selected = purchasePads.selected == pad
				item.Enabled = false and allowWorldInfo and not selected and distance ~= nil and distance <= 28
					and Journey.Available(currentState,pad:GetAttribute("PadId")) and pad.Transparency < 1
			end
		end
	end
	if nearestCar then nearestCar.Enabled = true end
end)

setUIMode("World")

local function updateHUD(state)
	currentState = state
	customizationPresenter:UpdateState(state)
	purchasePads:UpdateState(state)
	guidance:UpdateState(state)
	if cinematicPlaying and state.stage > 0 and finishCinematic then
		finishCinematic(true, false)
	end
	cashText.Text = "$" .. string.format("%d", state.cash or 0)
	if not state.phone then
		hideIncomingPhone()
	end
	local showDevControls = false
	resetButton.Visible = showDevControls and gui:GetAttribute("LayoutAuditMode") ~= true
	nextFlowButton.Visible = showDevControls and gui:GetAttribute("LayoutAuditMode") ~= true
	layoutAuditButton.Visible = showDevControls and gui:GetAttribute("LayoutAuditMode") ~= true
	if state.stage == 0 then
		flowLabel.Text = "ASPIRATION"
		objectiveLabel.Text = "Turn a forgotten lot into a dealership."
	else
		local stageInfo = Config.Stages[state.stage]
		local displayTotal = #Config.Stages - 1
		local displayStage = state.stage >= 10 and displayTotal or state.stage
		flowLabel.Text = string.format("%s  ·  %d/%d", stageInfo and stageInfo.title or "JOURNEY", displayStage, displayTotal)
		objectiveLabel.Text = stageInfo and stageInfo.objective or "Core journey complete"
		if state.stage == 1 then
			objectiveLabel.Text = (state.openingStep or 0) == 0
				and "Let’s open your dealership. Step onto the first pad."
				or "Let’s set up a place to meet sellers."
		elseif state.stage == 3 and (state.workshopStep or 0) < 4 then
			objectiveLabel.Text = ({
				"Equip the shared workshop",
				"Build the workshop canopy",
				"Seal the service slab",
				"Connect power and air to your service tools",
			})[(state.workshopStep or 0) + 1] or "Workshop ready"
		elseif state.stage == 8 then
			if (state.operationsStep or 0) >= 4 then
				objectiveLabel.Text = state.automationDemoComplete and "Claim your personal car" or "Watch a car route from intake to repair to sales"
			else
				objectiveLabel.Text = ({
					"Build an appraisal position",
					"Hire a Car Buyer for routine acquisitions",
					"Build a sales position",
					"Hire a Sales Rep for routine sales",
				})[(state.operationsStep or 0) + 1] or "Set up dealership operations"
			end
		end
		if state.stage == 10 then
			local rareObjectives = {
				Lead = "Choose how to meet the private seller",
				Travel = "Follow the private route to Elias",
				Waiting = "Talk to Elias for your early look",
				EnRoute = "A private car is pulling into the intake bay",
				Revealing = "A rare car is being revealed",
				Revealed = "Talk to Elias after reviewing the rare car",
				Purchased = "Rare car acquired",
			}
			local travelObjectives = {
				GetIn = "Get into your personal coupe",
				Driving = "Follow the yellow route to Elias",
				AtSeller = "Meet Elias at his private garage",
				ReturnChoice = "Choose how to return to your lot",
				DrivingHome = "Follow the yellow route back to your lot",
			}
			objectiveLabel.Text = travelObjectives[state.rareTravelPhase] or rareObjectives[state.rarePhase] or objectiveLabel.Text
		end
	end
 if state.firstTransit then
  objectiveLabel.Text=state.firstTransit=='Repair' and 'Your car is moving to the repair bay. Meet it there.' or 'Your restored car is moving to the sales area.'
 elseif state.stage==3 and (state.workshopStep or 0)>=4 then
  objectiveLabel.Text=state.repairStarted and 'Repair the body, wheels and engine. Each repair adds value.' or 'Your bay is ready. Start restoring the car.'
 elseif state.stage==4 and not state.salesBuilt then objectiveLabel.Text='Set up a sales area with a deal table for your first buyer.'
 end
 local pad=Journey.Get(Journey.Active(state))
 if pad then objectiveLabel.Text=pad.guide end
 if state.stage==8 and state.automationDemoComplete then objectiveLabel.Text='Your team is running the dealership. Improve the yard or claim a personal car whenever you like.'end
 if state.stage==8 and state.secondPhase=='Repairing' then objectiveLabel.Text='Your mechanic is repairing the coupe in the bay you built.'end
 if state.specialistGuide then objectiveLabel.Text=state.specialistGuide elseif state.businessWaiting then objectiveLabel.Text=state.businessWaiting end
 if state.stage==4 and state.listed then objectiveLabel.Text="Your car is for sale. Meet the buyer beside it."end
	if state.pendingDeal and state.pendingDeal.kind=="FirstSale" then objectiveLabel.Text="Sold. Your car is leaving the dealership." end
	gui:SetAttribute("GuideText",objectiveLabel.Text)
	if lastCash ~= nil and lastCash ~= (state.cash or 0) then
		pulseCash((state.cash or 0) > lastCash)
	end
	lastCash = state.cash or 0
	local repairing = state.stage == 3 and state.repairStarted
	if uiMode == "World" or uiMode == "Repair" or uiMode == "PadPreview" then
		setUIMode(repairing and "Repair" or (gui:GetAttribute("ActiveFocus") == "PurchasePad" and "PadPreview" or "World"))
	end
	local fixedCount = 0
	for _, key in ipairs({"Body", "Wheels", "Engine"}) do
		local fixed = state.fixes and state.fixes[key]
		if fixed then fixedCount += 1 end
		local upper = string.upper(key)
		local chip = repairLabels[upper]
		chip.Text = (fixed and "✓  " or "○  ") .. upper .. "    " .. repairEffects[upper]
		chip.TextColor3 = fixed and C.Ink or C.Muted
	end
	repairProgress.Text = "RESTORATION · " .. tostring(fixedCount) .. "/3"
end

local function startDrive(payload)
	hideIncomingPhone()
	local mode = type(payload) == "table" and payload.mode or "RareOutbound"
	local car = type(payload) == "table" and payload.car or payload
	drivingCar = car
	driveGoal.Text = mode == "RareReturn" and "RETURN TO YOUR LOT · FOLLOW THE YELLOW ROUTE"
		or "MYSTERY LEAD · FOLLOW THE YELLOW ROUTE"
	finishDriveButton.Visible = false
	if setUIMode then setUIMode("Drive") end
	drive.Visible = true
	hud.Visible = false
	cash.Visible = false
	phoneButton.Visible = false
	repairStrip.Visible = false
	camera.CameraType = Enum.CameraType.Scriptable
	if driveRenderConnection then driveRenderConnection:Disconnect() end
	driveRenderConnection = RunService.RenderStepped:Connect(function()
		if drivingCar and drivingCar.Parent then
			local cf = drivingCar:GetPivot()
			local target = cf.Position + cf.LookVector * 7 + Vector3.new(0, 1.6, 0)
			local desired = cf.Position - cf.LookVector * 13 + Vector3.new(0, 7, 0)
			camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(desired, target), 0.16)
		end
	end)
end

local function endDrive()
	throttle = 0
	steer = 0
	drive.Visible = false
	drivingCar = nil
	if driveRenderConnection then
		driveRenderConnection:Disconnect()
		driveRenderConnection = nil
	end
	restoreCamera()
	if setUIMode then setUIMode(defaultModeForState()) end
end

event.OnClientEvent:Connect(function(kind, data, extra)
	if kind == "State" then
		updateHUD(data)
	elseif kind == "Aspiration" then
		playOpeningCinematic()
	elseif kind == "Notify" then
		local cue = data and data.tone == "Green" and "NotifyGood" or (data and data.tone == "Red" and "Error" or "Notify")
		audio:Play(cue)
		showToast(data)
	elseif kind == "WorldFloater" then
		local floaterTitle = data and tostring(data.title) or ""
		local floaterDetail = string.upper(data and tostring(data.detail) or "")
		local cue = "Notify"
		if string.sub(floaterTitle, 1, 2) == "-$" then
			cue = string.find(floaterDetail, "BODY", 1, true) and "RepairBody"
				or (string.find(floaterDetail, "WHEEL", 1, true) and "RepairWheels"
				or (string.find(floaterDetail, "ENGINE", 1, true) and "RepairEngine" or "Spend"))
		elseif string.find(string.upper(floaterTitle), "RESTORED", 1, true) then
			cue = "Success"
		end
		audio:PlayAt(cue, extra)
		if data and (data.title or ''):find('%$') then showWorldFloater(data, extra)end
	elseif kind == "PhonePing" then
		audio:Play("Phone")
		phoneDot.Visible = true
		showIncomingPhone(data)
	elseif kind == "Dialogue" then
		openDialogue(data, extra)
	elseif kind == 'DealEnded' then
  dealPresenter:End(data.line)
  task.delay(1.1,function()closeDialogue()end)
	elseif kind == "DealResolved" then
  dealPresenter:Hide()
  dealPresenter.scene:React('happy')
		audio:Play("Deal")
		hideNpcSpeech(true)
		if setUIMode then setUIMode("DealClosure") end
		dealClosure:Play(data, focusedHead, function()
			closeDialogue()
			event:FireServer("DealClosureDone")
		end)
	elseif kind == "PadPurchaseResult" then
		purchasePads:HandleResult(data)
	elseif kind == "RareArrivalStart" then
		audio:Play("Engine")
		task.spawn(playRareArrival)
	elseif kind == "RareReveal" then
		audio:Play("Rare")
		task.spawn(playRareReveal)
	elseif kind == "CloseDialogue" then
		closeDialogue()
	elseif kind == "Profit" then
		audio:Play("Profit")
		if setUIMode then setUIMode("Receipt") end
		showProfit(data)
		task.delay(3.35, function()
			if uiMode == "Receipt" and setUIMode then setUIMode(defaultModeForState()) end
		end)
	elseif kind == "Customize" then
		audio:Play("Preview")
		customizationPresenter:Open(data, extra)
	elseif kind == "DriveStart" then
		audio:Play("Engine")
		startDrive(data)
	elseif kind == "DriveEnd" then
		endDrive()
	elseif kind == "ReturnChoice" then
		if setUIMode then setUIMode("ReturnChoice") end
		returnChoice.Visible = true
	elseif kind == "RareSellerArrival" then
		audio:Play("Engine")
		showToast({ title = "PRIVATE GARAGE", detail = "Elias is ready for your early look.", tone = "Yellow" })
	elseif kind == "CloseAll" then
		dealClosure:Cancel()
		cancelRareSequence()
		if cinematicPlaying and finishCinematic then
			finishCinematic(true, false)
		end
		closeDialogue()
		closePhone()
		hideIncomingPhone()
		profitToken += 1
		profit.Visible = false
		rareRevealMoment.Visible = false
		customizationPresenter:Close(false)
		endDrive()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not drive.Visible then return end
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		throttle = 1
		sendDrive()
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		steer = -1
		sendDrive()
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		steer = 1
		sendDrive()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not drive.Visible then return end
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		throttle = 0
		sendDrive()
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		steer = 0
		sendDrive()
	end
end)

event:FireServer("Ready")
print("[CoreUXPrototype] Mobile client ready · reference-aligned UI and FTUE guidance V8")

