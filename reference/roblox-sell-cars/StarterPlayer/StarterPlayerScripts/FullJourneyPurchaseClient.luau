-- StarterPlayerScripts: independent FullJourney pad presentation.
-- Progression, funds, ownership, distance checks and geometry stay on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = {
	Panel = Color3.fromRGB(27, 31, 36),
	Cream = Color3.fromRGB(255, 249, 229),
	Muted = Color3.fromRGB(179, 184, 183),
	Yellow = Color3.fromRGB(255, 210, 74),
	Orange = Color3.fromRGB(255, 160, 71),
	Green = Color3.fromRGB(126, 227, 158),
}

local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function round(object, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end

local function label(parent, properties)
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or C.Cream
	properties.TextSize = properties.TextSize or 15
	properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
	return make("TextLabel", properties, parent)
end

local function comma(number)
	local result = tostring(math.floor(tonumber(number) or 0))
	while true do
		local changed
		result, changed = result:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if changed == 0 then return result end
	end
end

local function price(cost)
	return (tonumber(cost) or 0) <= 0 and "FREE" or "$" .. comma(cost)
end

local function tween(object, seconds, properties, style)
	if player:GetAttribute("ReducedMotion") == true then seconds = math.min(seconds, 0.06) end
	local animation = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	animation:Play()
	return animation
end

-- Original Sell Cars owns the screen HUD, objectives and notification rail.
for _, name in {"FullJourneyHUD", "FullJourneyPadPresentation"} do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end
local gui = make("ScreenGui", {
	Name = "FullJourneyPadPresentation", ResetOnSpawn = false, IgnoreGuiInset = false,
	DisplayOrder = 22, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
local NotificationPresenter = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("NotificationPresenter"))
local notifications = NotificationPresenter.get(playerGui)
local function notify(message, success)
	notifications:Show({
		key = "FullJourneyPurchase:" .. message,
		title = success and "UPGRADE BUILT" or "PURCHASE",
		body = message,
		tone = success and "success" or "blocked",
		duration = 2.8,
	})
end

local state = nil
local knownPurchases = {}
local completedPurchases = {}
local selected = nil
local card, cardScale, cardStatus, cardPrice, rim = nil, nil, nil, nil, nil
local pending = nil
local completionUntil = 0
local blockedId = nil
local cachedPad = nil
local lastSearch = 0
local lastStateRequest = 0
local stopped = false
local connections = {}

local function rootPart()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then return nil end
	return root
end

local function nextPurchase()
	return state and state.owned == true and type(state.next) == "table"
		and type(state.next.id) == "string" and state.next or nil
end

local function ownedPlot()
	if not state or state.owned ~= true then return nil end
	if typeof(state.plot) == "Instance" and state.plot:IsDescendantOf(workspace) then return state.plot end
	-- Names are a streaming fallback only; purchase IDs and server ownership authorize purchases.
	local name = type(state.plotName) == "string" and state.plotName or type(state.plot) == "string" and state.plot or nil
	return name and workspace:FindFirstChild(name) or nil
end

local function validPad(part, nextItem, plot)
	return typeof(part) == "Instance" and part:IsA("BasePart") and plot
		and part:IsDescendantOf(plot) and part:GetAttribute("PurchasePadId") == nextItem.id
		and part:GetAttribute("PurchasePadOpen") == true
end

local function findPad()
	local nextItem, plot = nextPurchase(), ownedPlot()
	if not nextItem or not plot then cachedPad = nil return nil end
	if validPad(nextItem.part, nextItem, plot) then cachedPad = nextItem.part return cachedPad end
	if validPad(cachedPad, nextItem, plot) then return cachedPad end
	cachedPad = nil
	if os.clock() - lastSearch < 0.75 then return nil end
	lastSearch = os.clock()
	local padFolder = plot:FindFirstChild("FullJourneyPads") or plot:FindFirstChild("PurchasePads") or plot
	for _, part in ipairs(padFolder:GetDescendants()) do
		if validPad(part, nextItem, plot) then cachedPad = part return part end
	end
	return nil
end

-- Footprint detection is the step-on input gesture, not purchase authorization.
-- The server validates the character's distance when it receives the request.
local function inside(part, root)
	if not part or not root then return false end
	local point = part.CFrame:PointToObjectSpace(root.Position)
	return math.abs(point.X) <= part.Size.X * 0.5
		and math.abs(point.Z) <= part.Size.Z * 0.5 and math.abs(point.Y) <= 7
end

local function clearSelection()
	selected = nil
	if card then card:Destroy() end
	if rim then rim:Destroy() end
	card, cardScale, cardStatus, cardPrice, rim = nil, nil, nil, nil, nil
end

local function makeCard(part, nextItem)
	local billboard = make("BillboardGui", {
		Name = "FullJourneyPadCard", Adornee = part, Size = UDim2.fromOffset(224, 94),
		StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0), AlwaysOnTop = true,
		LightInfluence = 0, MaxDistance = 65,
	}, gui)
	local body = make("Frame", {
		Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.025, BorderSizePixel = 0,
	}, billboard)
	round(body, 13)
	make("UIStroke", { Color = C.Yellow, Thickness = 1.4, Transparency = 0.12 }, body)
	label(body, {
		Name = "Title", Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 36),
		Text = tostring(nextItem.title or part:GetAttribute("Title") or "Upgrade"),
		TextWrapped = true, TextSize = 15,
	})
	local cost = tonumber(nextItem.cost) or tonumber(part:GetAttribute("PurchasePadCost")) or 0
	local costLabel = label(body, {
		Name = "Price", Position = UDim2.fromOffset(12, 43), Size = UDim2.new(1, -24, 0, 23),
		Text = price(cost), TextSize = 18, TextColor3 = cost <= 0 and C.Green or C.Orange,
	})
	local statusLabel = label(body, {
		Name = "Status", Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 17),
		Text = "STEP ON TO BUILD", TextSize = 10, TextColor3 = C.Muted,
	})
	local scale = make("UIScale", { Scale = 0.86 }, body)
	tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	return billboard, scale, statusLabel, costLabel
end

local function selectPad(part, nextItem)
	if selected == part then return end
	clearSelection()
	selected = part
	card, cardScale, cardStatus, cardPrice = makeCard(part, nextItem)
	rim = make("SelectionBox", {
		Name = "FullJourneyPadRim", Adornee = part, Color3 = C.Yellow,
		LineThickness = 0.055, SurfaceColor3 = C.Yellow, SurfaceTransparency = 0.9,
	}, gui)
end

local function successEffect(request, data)
	local location = request and request.cframe or typeof(data.target) == "Vector3" and CFrame.new(data.target)
	if not location then return end
	local size = request and request.size or Vector3.new(6, 0.2, 6)
	-- These parts are client-only effects, never a clone or mutation of purchased geometry.
	local anchor = make("Part", {
		Name = "FullJourneyPurchaseEffect", Size = Vector3.new(0.1, 0.1, 0.1),
		CFrame = location, Anchored = true, CanCollide = false, CanTouch = false,
		CanQuery = false, Transparency = 1, CastShadow = false,
	}, workspace)
	Debris:AddItem(anchor, 1.2)
	local title = request and request.title or "Upgrade"
	local successCard, successScale, successStatus = makeCard(anchor, { title = title, cost = data.cost })
	successStatus.Text = "BUILT!"
	successStatus.TextColor3 = C.Green
	tween(successScale, 0.12, { Scale = 1.08 }, Enum.EasingStyle.Back)
	task.delay(0.14, function()
		if successScale.Parent then tween(successScale, 0.45, { Scale = 0.8 }) end
	end)
	tween(successCard, 0.75, { StudsOffsetWorldSpace = Vector3.new(0, 5, 0) })
	Debris:AddItem(successCard, 0.78)
	for index = 1, 4 do
		local alongX = index <= 2
		local sign = index % 2 == 0 and 1 or -1
		local edgeSize = alongX and Vector3.new(size.X, 0.1, 0.09) or Vector3.new(0.09, 0.1, size.Z)
		local offset = alongX and Vector3.new(0, 0.16, sign * size.Z * 0.5) or Vector3.new(sign * size.X * 0.5, 0.16, 0)
		local edge = make("Part", {
			Name = "Pulse", Size = edgeSize, CFrame = location * CFrame.new(offset),
			Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			CastShadow = false, Material = Enum.Material.Neon, Color = C.Green,
		}, anchor)
		tween(edge, 0.65, { CFrame = location * CFrame.new(offset * 1.9 + Vector3.new(0, 0.7, 0)), Size = edgeSize * 1.9, Transparency = 1 })
	end
end

-- A timed wait avoids an infinite-yield warning during a slow server bootstrap.
local function waitChild(parent, name)
	local result = parent:FindFirstChild(name)
	while not result and script.Parent and gui.Parent do
		result = parent:WaitForChild(name, 4)
	end
	return result
end
local remotes = waitChild(ReplicatedStorage, "FullJourneyRemotes")
if not remotes then gui:Destroy() return end
local purchaseRemote = waitChild(remotes, "Purchase")
local stateRemote = waitChild(remotes, "State")
local resultRemote = waitChild(remotes, "PurchaseResult")
if not purchaseRemote or not stateRemote or not resultRemote then gui:Destroy() return end

local function requestState()
	lastStateRequest = os.clock()
	stateRemote:FireServer()
end

table.insert(connections, stateRemote.OnClientEvent:Connect(function(snapshot)
	if type(snapshot) ~= "table" then return end
	local previousId = nextPurchase() and nextPurchase().id
	state = snapshot
	local entry = nextPurchase()
	if entry then
		local part = entry.part
		knownPurchases[entry.id] = {
			id = entry.id, title = entry.title or "Upgrade", cost = entry.cost,
			cframe = typeof(part) == "Instance" and part:IsA("BasePart") and part.CFrame or nil,
			size = typeof(part) == "Instance" and part:IsA("BasePart") and part.Size or nil,
		}
	end
	local nextId = nextPurchase() and nextPurchase().id
	if previousId ~= nextId then
		cachedPad = nil
		lastSearch = 0
		blockedId = nil
		clearSelection()
	end
end))

local failureMessages = {
	NotOwner = "This is not your dealership.",
	NotAvailable = "This upgrade is not available yet.",
	Unavailable = "This upgrade is not available yet.",
	AlreadyPurchased = "You already own this upgrade.",
	TooFar = "Step off the pad and back on to build.",
	Busy = "Your last build is still finishing. Step on again shortly.",
	NotReady = "Your dealership is still loading. Try again shortly.",
}
local reasonAliases = {
	["Step onto your pad"] = "TooFar",
	["Not enough cash"] = "InsufficientFunds",
	["No plot"] = "NotOwner",
	["This purchase is no longer available"] = "NotAvailable",
	["Complete"] = "AlreadyPurchased",
}
table.insert(connections, resultRemote.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then return end
	if completedPurchases[data.purchaseId] then return end
	local fromPad = pending ~= nil and pending.id == data.purchaseId
	-- The original HUD's BuyPad button uses the same server purchase pipeline.
	-- Its result can arrive after State has already advanced to the next upgrade.
	local request = fromPad and pending or knownPurchases[data.purchaseId]
	if not request then return end
	local reason = reasonAliases[data.reason] or data.reason
	if fromPad then pending = nil end
	if type(data.balance) == "number" and state then state.cash = data.balance end
	if data.ok == true then
		completedPurchases[data.purchaseId] = true
		completionUntil = os.clock() + 0.78
		blockedId = nil
		clearSelection()
		successEffect(request, data)
		notify(tostring(request.title) .. " built", true)
		requestState()
		return
	end
	blockedId = request.id
	local message = failureMessages[reason] or "This purchase is not ready. Step off and try again."
	if reason == "InsufficientFunds" then
		message = "You need $" .. comma(data.shortfall or math.max(0, (tonumber(request.cost) or 0) - (tonumber(data.balance) or 0))) .. " more."
	elseif reason == "OperatingReserve" then
		message = "Keep some cash for your next car and its repairs."
	end
	notify(message, false)
	if cardStatus then cardStatus.Text = "STEP OFF TO TRY AGAIN" cardStatus.TextColor3 = C.Orange end
	if cardScale then
		local scale = cardScale
		tween(scale, 0.1, { Scale = 1.07 }, Enum.EasingStyle.Back)
		task.delay(0.12, function() if scale.Parent then tween(scale, 0.18, { Scale = 1 }) end end)
	end
end))

table.insert(connections, player.CharacterAdded:Connect(function()
	clearSelection()
	pending = nil
	blockedId = nil
	requestState()
end))

local function presentationSuppressed()
	local mode = playerGui:GetAttribute("SellCarsUIMode")
	if mode == "Dialogue" or mode == "DealClosure" or mode == "Cinematic" or mode == "Receipt" then return true end
	local modal = playerGui:GetAttribute("MVPDealModal")
	return (type(modal) == "string" and modal ~= "")
		or playerGui:GetAttribute("SellCarsWorkshopModalOpen") == true
		or playerGui:GetAttribute("ActiveInspectionCard") ~= nil
end

local elapsed = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	if stopped then return end
	elapsed += dt
	if elapsed < 0.08 then return end
	elapsed = 0
	local now = os.clock()
	if (not state or state.owned ~= true or not ownedPlot()) and now - lastStateRequest > 5 then requestState() end
	if pending and now - pending.sent > 8 then
		blockedId = pending.id
		pending = nil
		notify("The purchase is taking longer than expected. Step off and try again.", false)
		requestState()
	end
	if presentationSuppressed() then
		local current = nextPurchase()
		local part, root = findPad(), rootPart()
		if current and part and inside(part, root) then blockedId = current.id end
		clearSelection()
		return
	end
	if now < completionUntil then return end
	local part, nextItem, root = findPad(), nextPurchase(), rootPart()
	if not part or not nextItem or not root then clearSelection() return end
	local distance = (part.Position - root.Position).Magnitude
	local onPad = inside(part, root)
	if blockedId == nextItem.id and not onPad then
		blockedId = nil
		if cardStatus then cardStatus.Text = "STEP ON TO BUILD" cardStatus.TextColor3 = C.Muted end
	end
	if distance <= 14 then
		selectPad(part, nextItem)
		if onPad and not pending and blockedId ~= nextItem.id then
			pending = { id = nextItem.id, title = nextItem.title or "Upgrade", cost = nextItem.cost,
				sent = now, cframe = part.CFrame, size = part.Size }
			cardStatus.Text = "BUILDING…"
			cardStatus.TextColor3 = C.Yellow
			purchaseRemote:FireServer({ purchaseId = nextItem.id })
		end
	elseif distance > 16 then
		clearSelection()
	end
end))

table.insert(connections, gui.Destroying:Connect(function()
	stopped = true
	for _, connection in ipairs(connections) do connection:Disconnect() end
	clearSelection()
end))
requestState()
