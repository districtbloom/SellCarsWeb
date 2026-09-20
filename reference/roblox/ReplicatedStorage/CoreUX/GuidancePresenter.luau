local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GuidancePresenter = {}
GuidancePresenter.__index = GuidancePresenter

local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function worldFind(name)
	local world = Workspace:FindFirstChild("CoreUXPrototype")
	return world and world:FindFirstChild(name, true) or nil
end

local function worldPosition(item)
	if not item then return nil end
	if item:IsA("Attachment") then return item.WorldPosition end
	if item:IsA("BasePart") then return item.Position end
	if item:IsA("Model") then return item:GetPivot().Position end
	return nil
end

function GuidancePresenter.new(screenGui, theme)
	local self = setmetatable({
		gui = screenGui,
		theme = theme,
		state = nil,
		clock = 0,
		markers = {},
		currentTarget = nil,
	}, GuidancePresenter)

	self.folder = make("Folder", { Name = "LocalFTUEGuide" }, Workspace)
	for index = 1, 12 do
		local marker = make("Part", {
			Name = "RouteMarker" .. index,
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			CastShadow = false,
			Material = Enum.Material.Neon,
			Color = theme.Colors.Yellow,
			Size = Vector3.new(1.15, 0.07, 2.3),
			Transparency = 1,
		}, self.folder)
		table.insert(self.markers, marker)
	end

	self.beacon = make("Part", {
		Name = "ObjectiveBeacon",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.one,
	}, self.folder)
	local billboard = make("BillboardGui", {
		Name = "NextStep",
		Size = UDim2.fromOffset(150, 46),
		StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 90,
		Enabled = false,
	}, self.beacon)
	local panel = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Colors.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
	}, billboard)
	make("UICorner", { CornerRadius = UDim.new(0, 11) }, panel)
	make("UIStroke", {
		Color = theme.Colors.Yellow,
		Thickness = 2,
		Transparency = 0.04,
	}, panel)
	self.beaconLabel = make("TextLabel", {
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -16, 1, -8),
		BackgroundTransparency = 1,
		Font = theme.Fonts.Display,
		Text = "NEXT",
		TextColor3 = theme.Colors.Cream,
		TextSize = 13,
		TextWrapped = true,
	}, panel)
	self.billboard = billboard

	self.connection = RunService.Heartbeat:Connect(function(dt)
		self.clock += dt
		if self.clock >= 0.16 then
			self.clock = 0
			self:_refresh()
		end
	end)
	return self
end

function GuidancePresenter:UpdateState(state)
	self.state = state
	self:_refresh(true)
end

function GuidancePresenter:_objective()
	local state = self.state
 local J=require(script.Parent.BusinessJourney);local pad=J.Get(J.Active(state))
 if pad then return J.Find(Workspace.CoreUXPrototype,pad.path),pad.title end
	if not state then return nil end
 if state.pendingDeal then return nil end
	if state.stage == 1 then
		if (state.openingStep or 0) == 0 then return worldFind("OpenAnchor"), "PLANT THE SELL SIGN" end
		return worldFind("DealTablePad"), "PLACE THE DEAL TABLE"
	end
	if state.stage == 2 then return worldFind("FirstSeller"), "TALK TO JESSE" end
 if state.firstTransit then return worldFind('FirstCar'), 'CAR MOVING' end
 if state.stage==3 and (state.workshopStep or 0)<4 then
  return worldFind(({'FoundationPad','ApproachPad','ServiceSlabPad','LiftPad'})[(state.workshopStep or 0)+1]), 'EQUIP REPAIR BAY'
 end
 if state.stage==4 and not state.salesBuilt then return worldFind('SalesPositionPad'),'BUILD SALES AREA' end
	if state.stage == 3 then
		if not state.firstAtRepair then return worldFind("FirstCar"), "WAIT FOR ARRIVAL" end
		local fixes = state.fixes or {}
		if not fixes.Body then return worldFind("BodyRepairAnchor"), "FIX BODY" end
		if not fixes.Wheels then return worldFind("WheelsRepairAnchor"), "FIT WHEELS" end
		if not fixes.Engine then return worldFind("EngineRepairAnchor"), "TUNE ENGINE" end
	end
	if state.stage == 4 then
		if not state.listed then return worldFind("ListAnchor"), "LIST THE CAR" end
		if state.buyerMet then return worldFind("FirstBuyer"), "MEET MARCUS" end
	end
	if state.stage == 5 then
		local targets = {
			{ "FoundationPad", "LAY FOUNDATION" },
			{ "ApproachPad", "BUILD APPROACH" },
			{ "ServiceSlabPad", "BUILD SERVICE SLAB" },
			{ "LiftPad", "INSTALL CAR LIFT" },
		}
		local target = targets[(state.workshopStep or 0) + 1]
		if target then return worldFind(target[1]), target[2] end
	end
	if state.stage == 6 then return worldFind("HirePad"), "HIRE MECHANIC" end
	if state.stage == 7 and state.secondVisible then return worldFind("SecondSeller"), "MEET MAYA" end
	if state.stage == 8 then
		local targets = {
			{ "AppraisalPad", "BUILD APPRAISAL" },
			{ "CarBuyerPad", "HIRE CAR BUYER" },
			{ "SalesPositionPad", "BUILD SALES POSITION" },
			{ "SalesRepPad", "HIRE SALES REP" },
		}
		local target = targets[(state.operationsStep or 0) + 1]
		if target then return worldFind(target[1]), target[2] end
		if state.automationDemoComplete then return worldFind("ClaimPad"), "CLAIM YOUR CAR" end
		return worldFind("AutoRouteCar"), "WATCH THE ROUTE"
	end
	if state.stage == 10 then
		if state.rareTravelPhase == "GetIn" then
			return worldFind("PersonalCar"), "GET IN YOUR CAR"
		end
		if state.rareTravelPhase == "Driving" then
			return worldFind("SellerDriveTarget"), "PRIVATE GARAGE"
		end
		if state.rareTravelPhase == "DrivingHome" then
			return worldFind("PersonalGarage"), "RETURN TO YOUR LOT"
		end
		if state.rarePhase == "Waiting" or state.rarePhase == "Revealed" then
			return worldFind("RareSeller"), "MEET ELIAS"
		end
		if state.rarePhase == "EnRoute" or state.rarePhase == "Revealing" then
			return worldFind("IntakeBay"), "GO TO INTAKE BAY"
		end
	end
	return nil
end

function GuidancePresenter:_hide()
	for _, marker in ipairs(self.markers) do marker.Transparency = 1 end
	self.billboard.Enabled = false
	if self.highlight then
		self.highlight:Destroy()
		self.highlight = nil
	end
	self.currentTarget = nil
end

function GuidancePresenter:_refresh(force)
	local state = self.state
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local mode = self.gui:GetAttribute("UIMode") or "World"
	local modeAllowsGuide = mode == "World" or mode == "Repair" or mode == "PadPreview" or mode == "Drive"
	if not state or not root or not modeAllowsGuide then
		self:_hide()
		return
	end

	local target, title = self:_objective()
	local targetPosition = worldPosition(target)
	if not target or not targetPosition then
		self:_hide()
		return
	end

	if target ~= self.currentTarget then
		if self.highlight then self.highlight:Destroy() end
		self.highlight = make("Highlight", {
			Name = "FTUEObjectiveOutline",
			Adornee = target,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = self.theme.Colors.Yellow,
			FillTransparency = 0.9,
			OutlineColor = self.theme.Colors.Yellow,
			OutlineTransparency = 0.14,
		}, self.folder)
		self.currentTarget = target
	end

	local origin = root.Position
	if state.driving then
		local personalCar = worldFind("PersonalCar")
		if personalCar and personalCar:IsA("Model") then origin = personalCar:GetPivot().Position end
	end
	local flatTarget = Vector3.new(targetPosition.X, origin.Y, targetPosition.Z)
	local delta = flatTarget - origin
	local distance = delta.Magnitude
	if distance < 13 then
		for _, marker in ipairs(self.markers) do marker.Transparency = 1 end
	else
		local direction = delta.Unit
		local count = math.clamp(math.floor(distance / (state.driving and 10 or 7)), 2, #self.markers)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { character, self.folder }
		for index, marker in ipairs(self.markers) do
			if index <= count then
				local alpha = index / (count + 1)
				local position = origin:Lerp(flatTarget, alpha)
				local hit = Workspace:Raycast(position + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), rayParams)
				local y = hit and hit.Position.Y + 0.09 or origin.Y - 2.8
				position = Vector3.new(position.X, y, position.Z)
				marker.CFrame = CFrame.lookAt(position, position + direction)
				local wave = (math.sin(os.clock() * 5 - index * 0.55) + 1) * 0.5
				marker.Transparency = 0.12 + wave * 0.22
			else
				marker.Transparency = 1
			end
		end
	end

	self.beacon.Position = targetPosition
	self.beaconLabel.Text = title or "NEXT"
	self.billboard.Enabled = false
end

function GuidancePresenter:Destroy()
	if self.connection then self.connection:Disconnect() end
	if self.folder then self.folder:Destroy() end
end

return GuidancePresenter


