local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PurchasePadPresenter = {}
PurchasePadPresenter.__index = PurchasePadPresenter

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

local function comma(value)
	local formatted = tostring(math.floor(tonumber(value) or 0))
	while true do
		local changed
		formatted, changed = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if changed == 0 then break end
	end
	return formatted
end

local function findFromWorld(path)
	local current = workspace:FindFirstChild("CoreUXPrototype")
	if not current then return nil end
	for token in string.gmatch(path or "", "[^%.]+") do
		current = current and current:FindFirstChild(token)
	end
	return current
end

function PurchasePadPresenter.new(screenGui, theme, motion, event, focus, audio)
	local self = setmetatable({}, PurchasePadPresenter)
	self.gui = screenGui
	self.theme = theme
	self.motion = motion
	self.event = event
	self.focus = focus
	self.audio = audio
	self.state = nil
	self.selected = nil
	self.pending = false
	self.retryAfter = 0
	self.completing = false
	self.suppressed = false
	self.leaveStarted = nil
	self.preview = nil
	self.highlight = nil
	self.card = nil

	self.actionButton = make("TextButton", {
		Name = "PadConfirmAction",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(270, theme.Metrics.TouchHeight),
		BackgroundColor3 = theme.Colors.Yellow,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Active = false,
		Font = theme.Fonts.Display,
		Text = "BUILD  $1,000",
		TextColor3 = theme.Colors.Ink,
		TextSize = 16,
		Visible = false,
		ZIndex = 82,
	}, screenGui)
	corner(self.actionButton, 14)
	self.buttonStroke = stroke(self.actionButton, theme.Colors.Edge, 1.4, 0.14)
	self.actionScale = make("UIScale", { Scale = 1 }, self.actionButton)
	motion.AttachPress(self.actionButton, { pressedScale = theme.Motion.PressedScale })
	self.actionButton.Activated:Connect(function()
		self:Confirm()
	end)

	self.connection = RunService.Heartbeat:Connect(function()
		self:_step()
	end)
	-- Pads commit from physical contact. The approach preview is the decision window;
	-- no second keyboard, gamepad or touch confirmation is required.
	self.inputConnection = nil

	return self
end

function PurchasePadPresenter:_activePadId()
 local J=require(script.Parent.BusinessJourney)
 local best,dist
 for _,p in J.Pads do if J.Available(self.state,p.id)then
  local part=self:_findPad(p.id);local d=self:_distance(part)
  if not dist or d<dist then best,dist=p.id,d end
 end end
 return best
end

function PurchasePadPresenter:_findPad(padId)
	local world = workspace:FindFirstChild("CoreUXPrototype")
	if not world then return nil end
	for _, item in ipairs(world:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("PadId") == padId then
			return item
		end
	end
	return nil
end

function PurchasePadPresenter:_inside(part)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part then return false end
	local point = part.CFrame:PointToObjectSpace(root.Position)
	return math.abs(point.X) <= part.Size.X * 0.5
		and math.abs(point.Z) <= part.Size.Z * 0.5
		and math.abs(point.Y) <= 7
end

function PurchasePadPresenter:_distance(part)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part then return math.huge end
	return (root.Position - part.Position).Magnitude
end

function PurchasePadPresenter:_makeWorldCard(part)
	local gui = make("BillboardGui", {
		Name = "PadSelectionCard",
		Size = UDim2.fromOffset(190, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0),
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = 60,
	}, part)
	local panel = make("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = self.theme.Colors.Panel,
		BackgroundTransparency = 0.025,
		BorderSizePixel = 0,
	}, gui)
	corner(panel, 13)
	stroke(panel, self.theme.Colors.Ink, 2, 0.08)

	local tag = make("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 18),
		BackgroundTransparency = 1,
		Font = self.theme.Fonts.Strong,
		Text = "",
        Visible = false,
		TextColor3 = self.theme.Colors.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local title = make("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(10, 5),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundTransparency = 1,
		Font = self.theme.Fonts.Display,
		Text = part:GetAttribute("Title") or "UPGRADE",
		TextColor3 = self.theme.Colors.Cream,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, panel)
	local price = make("TextLabel", {
		Name = "Price",
		Position = UDim2.fromOffset(10, 32),
		Size = UDim2.new(1, -28, 0, 27),
		BackgroundTransparency = 1,
		Font = self.theme.Fonts.Display,
		Text = (tonumber(part:GetAttribute("Cost")) or 0) <= 0 and "FREE" or ("$" .. comma(part:GetAttribute("Cost"))),
		TextColor3 = (tonumber(part:GetAttribute("Cost")) or 0) <= 0 and self.theme.Colors.Green or self.theme.Colors.Orange,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local benefit = make("TextLabel", {
		Name = "Benefit",
        Visible = false,
		Position = UDim2.fromOffset(14, 87),
		Size = UDim2.new(1, -28, 0, 34),
		BackgroundTransparency = 1,
		Font = self.theme.Fonts.Strong,
		Text = part:GetAttribute("Benefit") or "",
		TextColor3 = self.theme.Colors.Muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, panel)
	self.cardStatus = tag
	self.cardPrice = price
	self.cardScale = make("UIScale", { Scale = 0.86 }, panel)
	self.motion.Tween(self.cardScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	return gui
end

function PurchasePadPresenter:_makePreview(part)
	local path = part:GetAttribute("PreviewPath")
	if type(path) == "string" and path ~= "" then
		local source = findFromWorld(path)
		if source then
			local clone = source:Clone()
			clone.Name = "LocalPadPreview"
			local previewStyle = part:GetAttribute("PreviewStyle")
			local previewItems = { clone }
			for _, descendant in ipairs(clone:GetDescendants()) do table.insert(previewItems, descendant) end
			for _, item in ipairs(previewItems) do
				if item:IsA("BasePart") then
					if previewStyle == "Character" then
						item.Transparency = item:GetAttribute("ShownTransparency") or 0
					else
						item.Transparency = 0.58
						item.Color = self.theme.Colors.Yellow
						item.Material = Enum.Material.ForceField
					end
					item.CanCollide = false
					item.CanTouch = false
					item.CanQuery = false
				elseif item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
					item.Enabled = false
				elseif item:IsA("ProximityPrompt") then
					item.Enabled = false
				end
			end
			clone.Parent = workspace
			self.preview = clone
			local highlight = make("Highlight", {
				Name = "PreviewOutline",
				Adornee = clone,
				DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
				FillColor = self.theme.Colors.Yellow,
				FillTransparency = 0.82,
				OutlineColor = self.theme.Colors.Cream,
				OutlineTransparency = 0.15,
			}, clone)
			self.highlight = highlight
			return
		end
	end

	local existingPath = part:GetAttribute("ExistingPreviewPath")
	local existing = type(existingPath) == "string" and findFromWorld(existingPath) or nil
	if existing then
		self.highlight = make("Highlight", {
			Name = "PadPreviewOutline",
			Adornee = existing,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = self.theme.Colors.Yellow,
			FillTransparency = 0.88,
			OutlineColor = self.theme.Colors.Yellow,
			OutlineTransparency = 0.05,
		}, existing)
	end
end

function PurchasePadPresenter:Select(part)
	if self.selected == part or self.completing then return end
	self:ClearSelection()
	self.selected = part
    self.requireReentry=false
	self.gui:SetAttribute("PadGuide", part:GetAttribute("Benefit"))
	self.leaveStarted = nil
	self.pending = false
	self.retryAfter = 0
	self.focus:Acquire("PurchasePad", self.theme.FocusPriority.Workshop)

	local callout = part:FindFirstChild("PadCallout")
	if callout and callout:IsA("BillboardGui") then
		self.baseCallout = callout
		self.baseCalloutWasEnabled = callout.Enabled
		callout.Enabled = false
	end
	self.card = self:_makeWorldCard(part)
	-- One card and a rim; no duplicate donor geometry preview.
	if self.audio then self.audio:PlayAt("PadPreview", part) end
	self.padSelection = make("SelectionBox", {
		Name = "PadRim",
		Adornee = part,
		Color3 = self.theme.Colors.Yellow,
		LineThickness = 0.06,
		SurfaceColor3 = self.theme.Colors.Yellow,
		SurfaceTransparency = 0.86,
	}, part)

	-- The world card is the sole decision surface. Because stepping onto the pad commits,
	-- a second screen-space confirmation button would only duplicate and obscure it.
	self.actionButton.Visible = false
end

function PurchasePadPresenter:ClearSelection()
	if self.completing then return end
	self.gui:SetAttribute("PadGuide", nil)
	self.focus:Release("PurchasePad")
	self.selected = nil
	self.pending = false
	self.leaveStarted = nil
	self.actionButton.Visible = false
	if self.card then self.card:Destroy() self.card = nil end
	if self.baseCallout and self.baseCallout.Parent then
		local pad = self.baseCallout.Parent
		local stillActive = pad:IsA("BasePart")
			and pad:GetAttribute("PadId") == self:_activePadId()
			and pad.Transparency < 1
		self.baseCallout.Enabled = stillActive and self.baseCalloutWasEnabled ~= false
	end
	self.baseCallout = nil
	self.baseCalloutWasEnabled = nil
	if self.preview then self.preview:Destroy() self.preview = nil end
	if self.highlight then self.highlight:Destroy() self.highlight = nil end
	if self.padSelection then self.padSelection:Destroy() self.padSelection = nil end
end

function PurchasePadPresenter:Confirm()
	if not self.selected or self.pending or self.completing then return end
	self.pending = true
	if self.audio then self.audio:PlayAt("PadCommit", self.selected) end
	if self.cardStatus then
		self.cardStatus.Text = "PURCHASING…"
		self.cardStatus.TextColor3 = self.theme.Colors.Muted
	end
	self.event:FireServer("ConfirmPadPurchase", {
		padId = self.selected:GetAttribute("PadId"),
	})
end

function PurchasePadPresenter:HandleResult(data)
	if type(data) ~= "table" then return end
	if not self.selected or data.padId ~= self.selected:GetAttribute("PadId") then return end
	self.pending = false
	if not data.ok then
		if data.reason == "TooFar" then
			-- Retry only while physically on the pad; position replication can lag.
			self.retryAfter = os.clock() + 0.35
			self.requireReentry = false
			return
		end
		self.retryAfter = os.clock() + 1.0
        self.requireReentry=true
        self.gui:SetAttribute("HelperNotice",data.reason=="OperatingReserve" and "Keep $1,400 for your team’s next car and repairs." or data.reason=="InsufficientFunds" and ("You need $"..comma(data.shortfall).." more for this purchase.") or "This purchase is not available yet.")
        self.gui:SetAttribute("HelperNoticeVersion",os.clock())
		if self.audio then self.audio:Play("Error") end
		if data.reason == "InsufficientFunds" then
			self.cardStatus.Text = "NEED $" .. comma(data.shortfall) .. " MORE"
			self.cardStatus.TextColor3 = self.theme.Colors.Orange
			self.cardPrice.TextColor3 = self.theme.Colors.Orange
			self.actionButton.Text = "NOT ENOUGH CASH"
			self.actionButton.BackgroundColor3 = self.theme.Colors.SoftPanel
			self.actionButton.TextColor3 = self.theme.Colors.Cream
			self.motion.Pulse(self.cardScale, 1.07)
			task.delay(0.9, function()
				if self.selected and not self.pending then
					self.cardStatus.Text = ""
					self.cardStatus.TextColor3 = self.theme.Colors.Muted
					self.cardPrice.TextColor3 = (tonumber(self.selected:GetAttribute("Cost")) or 0) <= 0
						and self.theme.Colors.Green or self.theme.Colors.Orange
					self.actionButton.Text = (self.selected:GetAttribute("Action") or "BUY")
						.. "  $" .. comma(self.selected:GetAttribute("Cost"))
					self.actionButton.BackgroundColor3 = self.theme.Colors.Yellow
					self.actionButton.TextColor3 = self.theme.Colors.Ink
				end
			end)
		else
			self.cardStatus.Text = data.reason == "TooFar" and "STEP BACK ON THE PAD" or "UNAVAILABLE"
			self.cardStatus.TextColor3 = self.theme.Colors.Orange
			self.actionButton.Text = "TRY AGAIN"
		end
		return
	end

	self.completing = true
	local isHire = data.padId == "FirstMechanic" or data.padId == "CarBuyer" or data.padId == "SalesRep"
	local completeStatus = data.padId == "PlantSaleSign" and "PLANTED"
		or (isHire and "HIRED"
		or (data.padId == "FirstPersonalCar" and "CLAIMED" or "BUILT"))
	local completeAction = data.padId == "PlantSaleSign" and "SIGN PLANTED"
		or (isHire and "TEAM MEMBER HIRED"
		or (data.padId == "FirstPersonalCar" and "CAR CLAIMED" or "PURCHASE COMPLETE"))
	self.cardStatus.Text = completeStatus
	self.cardStatus.TextColor3 = self.theme.Colors.Green
	self.actionButton.Text = completeAction
	self.actionButton.BackgroundColor3 = self.theme.Colors.Green
	if self.audio then
		local padId = data.padId or ""
		local isBuild = string.find(padId, "Workshop") ~= nil
			or padId == "PlantSaleSign" or padId == "DealTable"
			or padId == "AppraisalPosition" or padId == "SalesPosition"
		local cue = isBuild and "Build" or (isHire and "Hire" or "Success")
		self.audio:PlayAt(cue, self.selected)
	end
	self.motion.Pulse(self.cardScale, 1.08)
	self.motion.Pulse(self.actionScale, 1.04)
	if self.preview then
		for _, item in ipairs(self.preview:GetDescendants()) do
			if item:IsA("BasePart") then
				self.motion.Tween(item, 0.45, { Transparency = 0.9 }, Enum.EasingStyle.Quad)
			end
		end
	end

	task.delay(0.72, function()
		self.completing = false
		self:ClearSelection()
	end)
end

function PurchasePadPresenter:UpdateState(state)
	self.state = state
	if self.completing then return end
	local activeId = self:_activePadId()
	if self.selected and self.selected:GetAttribute("PadId") ~= activeId then
		self:ClearSelection()
	end
end

function PurchasePadPresenter:SetSuppressed(suppressed)
	self.suppressed = suppressed == true
	if self.suppressed and self.selected and not self.completing then
		self:ClearSelection()
	end
end

function PurchasePadPresenter:_step()
	if self.completing or self.suppressed then return end
	local padId = self:_activePadId()
	if not padId then
		if self.selected then self:ClearSelection() end
		return
	end
	local pad = self:_findPad(padId)
	if not pad then return end
	local distance = self:_distance(pad)
	if self.requireReentry and not self:_inside(pad) then self.requireReentry = false end
	local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 local delta=root and (pad.Position-root.Position)
 local facing=delta and (delta.Magnitude<7 or root.CFrame.LookVector:Dot(delta.Unit)>0.1)
 if distance <= 14 and facing then
		self.leaveStarted = nil
		if self.selected~=pad then self:ClearSelection();self:Select(pad)end
		if self.selected == pad and self:_inside(pad) and not self.pending and not self.requireReentry and os.clock() >= (self.retryAfter or 0) then
			self:Confirm()
		end
	elseif self.selected and (distance > 16 or not facing) then
		self.leaveStarted = self.leaveStarted or os.clock()
		if os.clock() - self.leaveStarted >= 0.3 then
			self:ClearSelection()
		end
	end
end

function PurchasePadPresenter:Destroy()
	if self.connection then self.connection:Disconnect() end
	if self.inputConnection then self.inputConnection:Disconnect() end
	self.completing = false
	self:ClearSelection()
	self.actionButton:Destroy()
end

return PurchasePadPresenter

