if game.PlaceId~=105869926920733 or not game:GetService('RunService'):IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Journey=require(ReplicatedStorage:WaitForChild('CoreUX'):WaitForChild('BusinessJourney'))
local Config = require(ReplicatedStorage:WaitForChild("CorePrototypeConfig"))
local WorldBuilder = require(ReplicatedStorage:WaitForChild("CoreWorldBuilder"))
local world = WorldBuilder.Build()

local remotes = ReplicatedStorage:FindFirstChild("CorePrototypeRemotes") or Instance.new("Folder")
remotes.Name = "CorePrototypeRemotes"
remotes.Parent = ReplicatedStorage
local event = remotes:FindFirstChild("PrototypeEvent") or Instance.new("RemoteEvent")
event.Name = "PrototypeEvent"
event.Parent = remotes

local states = {}
local owner
local loading={}
local IntegrationWorld=require(game.ServerStorage.SellCarsIntegrationWorld)
local Automation=require(game.ServerStorage.SellCarsIntegrationAutomation)
local Save=require(game.ServerStorage.SellCarsIntegrationSave)
local Specialist=require(game.ServerStorage.SellCarsIntegrationSpecialist)
local Negotiation=require(game.ServerStorage.SellCarsIntegrationNegotiation)
local specialistPrompt=Specialist.Build(world)
Automation.OnReceipt=function(player,data)event:FireClient(player,'Receipt',data)end
local opening=Instance.new("Folder");opening.Name="SellCarsIntegrationOpening";opening.Parent=workspace
local function near(player,target,range)
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 return h and h.Health>0 and r and target and (r.Position-target.Position).Magnitude<=(range or 18)
end


local function freshState()
	return {
		stage = 1,
  journeyVersion = 10,
  shelterBuilt=false,
  serviceFloorBuilt=false,
  salesDisplayBuilt = false,
  salesBuilt = false,
  firstAtRepair = false,
  firstAtSales = false,
		openingStep = 0,
		workshopStep = 0,
		operationsStep = 0,
		automationDemoComplete = false,
		automationDemoRunning = false,
		automationProfitAwarded = false,
		cash = Config.StartingCash,
		purchase = 0,
		repairTotal = 0,
		carValue = Config.FirstCar.ask,
		condition = Config.FirstCar.condition,
		fixes = { Body = false, Wheels = false, Engine = false },
		repairStarted = false,
		firstAsk = Config.FirstCar.ask,
		listed = false,
		phone = nil,
		buyerMet = false,
		secondVisible = false,
		secondAsk = Config.SecondSeller.ask,
		mechanicHired = false,
		personalType = "COUPE",
		personalColor = "BLUE",
		personalWheel = "STOCK",
		personalVinyl = "NONE",
		personalTint = "LIGHT",
		personalNeon = "OFF",
		customizationUndo = nil,
		lastRandomRecipe = nil,
		driving = false,
		driveThrottle = 0,
		driveSteer = 0,
		rarePhase = "Dormant",
		rareRoute = nil,
		rareTravelPhase = nil,
		pendingDeal = nil,
		rareAsk = Config.RareSeller.ask,
		rareOwned = false,
		rareArrivalComplete = false,
	}
end

local function statePacket(s)
	return {
		stage = s.stage,
  salesDisplayBuilt=s.salesDisplayBuilt, specialistGuide=s.specialistGuide,businessWaiting=s.businessWaiting,rareFocus=s.rareFocus,operatingReserve=s.rareFocus and 500 or s.automationDemoComplete and 1400 or 0,
  panelBench=s.panelBench,touchupKit=s.touchupKit,wheelTools=s.wheelTools,fluidKit=s.fluidKit,finishKit=s.finishKit,partsShelves=s.partsShelves,
  salesBuilt = s.salesBuilt,
  shelterBuilt=s.shelterBuilt,serviceFloorBuilt=s.serviceFloorBuilt,
  secondWorkComplete=s.secondWorkComplete,secondPhase=s.secondPhase,
  firstAtRepair = s.firstAtRepair,
  firstAtSales = s.firstAtSales,
  firstTransit = s.firstTransit,
  pendingDeal=s.pendingDeal and {kind=s.pendingDeal.kind} or nil,
		openingStep = s.openingStep,
		workshopStep = s.workshopStep,
		operationsStep = s.operationsStep,
		automationDemoComplete = s.automationDemoComplete,
		automationProfitAwarded = s.automationProfitAwarded,
		cash = s.cash,
		purchase = s.purchase,
		repairTotal = s.repairTotal,
		carValue = s.carValue,
		condition = s.condition,
		fixes = {
			Body = s.fixes.Body,
			Wheels = s.fixes.Wheels,
			Engine = s.fixes.Engine,
		},
		repairStarted = s.repairStarted,
		listed = s.listed,
		phone = s.phone,
		buyerMet = s.buyerMet,
		secondVisible = s.secondVisible,
		mechanicHired = s.mechanicHired,
		personalType = s.personalType,
		personalColor = s.personalColor,
		personalWheel = s.personalWheel,
		personalVinyl = s.personalVinyl,
		personalTint = s.personalTint,
		personalNeon = s.personalNeon,
		customizationCanUndo = s.customizationUndo ~= nil,
		driving = s.driving,
		rarePhase = s.rarePhase,
		rareRoute = s.rareRoute,
		rareTravelPhase = s.rareTravelPhase,
		rareAsk = s.rareAsk,
		rareOwned = s.rareOwned,
	}
end

local function notify(player, title, detail, tone)
	event:FireClient(player, "Notify", {
		title = title,
		detail = detail,
		tone = tone or "Yellow",
	})
end

local function sendState(player)
	local s = states[player]
	if s then
		player:SetAttribute("SellCarsCash",s.cash)
  local snapshot=game.ServerStorage:FindFirstChild('SellCarsIntegrationSessionSnapshot') or Instance.new('StringValue')
  snapshot.Name='SellCarsIntegrationSessionSnapshot';snapshot.Value=game.HttpService:JSONEncode(s);snapshot.Parent=game.ServerStorage
  opening:SetAttribute("JourneyStage",s.stage)
  opening:SetAttribute("JourneyText",Config.Stages[s.stage] and Config.Stages[s.stage].objective or "Your dealership is ready.")
  event:FireClient(player, "State", statePacket(s))
  Save.Write(player,s)
	end
end

local function setPrompt(name, enabled)
	local p = world:FindFirstChild(name, true)
	if p and p:IsA("ProximityPrompt") then
		local state=owner and states[owner]
  enabled=enabled and not(state and state.pendingDeal) or false
  p:SetAttribute('BusinessPromptEnabled',enabled)
  p.Enabled = enabled
	end
end

local function show(path, visible)
	local item = world
	for token in string.gmatch(path, "[^%.]+") do
		item = item and item:FindFirstChild(token)
	end
	if item then
		WorldBuilder.SetVisible(item, visible)
	end
end

local function allFixed(s)
	return s.fixes.Body and s.fixes.Wheels and s.fixes.Engine
end

local function money(value)
	local result = tostring(math.floor(tonumber(value) or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return result:gsub("^,", "")
end

local function updateFirstCar(s)
	local body = world:FindFirstChild("FirstCar", true)
	body = body and body:FindFirstChild("Body")
	local gui = body and body:FindFirstChild("CarState")
	local card = gui and gui:FindFirstChild("Card")
	if not card then return end
	local stateWord = s.condition >= 95 and "RESTORED" or (s.condition >= 60 and "FAIR" or "ROUGH")
	local conditionHex = s.condition >= 95 and "#48D65E" or (s.condition >= 60 and "#FFBE1D" or "#F17831")
	card.Tags.RichText = true
	card.Tags.TextColor3 = Config.Colors.White
	card.Tags.Text = (s.purchase > 0 and "OWNED · " or "")
		.. '<font color="#FFBE1D">' .. Config.FirstCar.rarity .. "</font> · "
		.. '<font color="' .. conditionHex .. '">' .. stateWord .. " " .. tostring(math.min(100, s.condition)) .. "%</font>"
	card.Condition.Text = ""
	card.Value.RichText = true
	card.Value.TextColor3 = Config.Colors.White
	if s.purchase > 0 then
		local invested = s.purchase + s.repairTotal
		local projectedProfit = s.carValue - invested
		local profitHex = projectedProfit >= 0 and "#48D65E" or "#F17831"
		local sign = projectedProfit >= 0 and "+" or "-"
		card.Value.Text = '<font color="' .. profitHex .. '">PROJECTED PROFIT ' .. sign .. "$" .. money(math.abs(projectedProfit)) .. "</font>"
	else
		card.Value.Text = '<font color="#F17831">ASK $' .. money(s.firstAsk) .. '</font>  ·  <font color="#48D65E">EST. $2.3K</font>'
	end
end

local function resetRareTransporter()
	local set = world:FindFirstChild("RareArrival")
	local transporter = set and set:FindFirstChild("Transporter")
	local markers = set and set:FindFirstChild("Markers")
	local startMarker = markers and markers:FindFirstChild("TransportStart")
	if transporter and startMarker then
		transporter:PivotTo(startMarker.CFrame)
	end
end

local function updateRareCar(s)
	local rareCar = world:FindFirstChild("RareCar", true)
	local body = rareCar and rareCar:FindFirstChild("Body")
	local gui = body and body:FindFirstChild("CarState")
	local card = gui and gui:FindFirstChild("Card")
	if not card then return end
	card.Tags.Text = (s.rareOwned and "OWNED · " or "") .. Config.RareSeller.rarity .. " · " .. Config.RareSeller.state .. " " .. tostring(Config.RareSeller.condition) .. "%"
	card.Condition.Text = ""
	card.Value.Text = s.rareOwned
		and ("BOUGHT $" .. tostring(s.rareAsk) .. "  ·  EST. $" .. tostring(Config.RareSeller.estimate))
		or ("$" .. tostring(s.rareAsk) .. "  →  EST. $7.2K")
	gui.Enabled = s.rarePhase == "Revealed" or s.rarePhase == "Purchased"
end

local function canCustomizePersonalCar(s)
	return s ~= nil and s.stage == 9 and not s.driving
end

local PERSONAL_PAINTS = {
	BLUE = Color3.fromRGB(56, 128, 223),
	RED = Color3.fromRGB(211, 63, 54),
	LIME = Color3.fromRGB(116, 194, 67),
	SAND = Color3.fromRGB(194, 155, 91),
	BLACK = Color3.fromRGB(36, 39, 43),
	WHITE = Color3.fromRGB(228, 228, 222),
}

local PERSONAL_TYPES = {
	COUPE = {
		label = "STREET COUPE",
		bodySize = Vector3.new(8, 1.5, 4.2),
		bodyY = 1.7,
		cabinSize = Vector3.new(4.2, 1.6, 3.7),
		cabinOffset = Vector3.new(0.5, 3.15, 0),
		wheelX = 2.6, wheelY = 0.9, wheelZ = 2.15, wheelSize = 1.5,
	},
	MUSCLE = {
		label = "MUSCLE CAR",
		bodySize = Vector3.new(8.8, 1.55, 4.45),
		bodyY = 1.72,
		cabinSize = Vector3.new(3.8, 1.45, 3.62),
		cabinOffset = Vector3.new(0.8, 3.08, 0),
		wheelX = 3.0, wheelY = 0.93, wheelZ = 2.28, wheelSize = 1.7,
	},
	OFFROAD = {
		label = "OFF-ROAD",
		bodySize = Vector3.new(8.3, 1.8, 4.65),
		bodyY = 2.05,
		cabinSize = Vector3.new(4.5, 1.8, 3.95),
		cabinOffset = Vector3.new(0.3, 3.62, 0),
		wheelX = 2.75, wheelY = 1.15, wheelZ = 2.45, wheelSize = 1.95,
	},
}

local function applyPersonalAppearance(s)
	if not s or s.stage < 9 then return end
	local car = world:FindFirstChild("PersonalCar", true)
	if not car or not car:IsA("Model") then return end
	local anchor = car:FindFirstChild("VisualAnchor")
	local body = car:FindFirstChild("Body")
	local cabin = car:FindFirstChild("Cabin")
	if not anchor or not body or not cabin then return end

	local typeName = PERSONAL_TYPES[s.personalType] and s.personalType or "COUPE"
	local definition = PERSONAL_TYPES[typeName]
	local paint = PERSONAL_PAINTS[s.personalColor] or PERSONAL_PAINTS.BLUE
	local base = anchor.CFrame
	body.Size = definition.bodySize
	body.CFrame = base * CFrame.new(0, definition.bodyY, 0)
	body.Color = paint
	body.Transparency = 0
	cabin.Size = definition.cabinSize
	cabin.CFrame = base * CFrame.new(definition.cabinOffset)
	cabin.Color = paint:Lerp(Color3.new(1, 1, 1), 0.12)
	cabin.Transparency = 0

	local wheelStyle = s.personalWheel or "STOCK"
	local wheelScale = wheelStyle == "RUGGED" and 1.12 or (wheelStyle == "SPORT" and 0.94 or 1)
	local rimScale = wheelStyle == "CLASSIC" and 0.7 or (wheelStyle == "SPORT" and 0.78 or (wheelStyle == "RUGGED" and 0.58 or 0.62))
	local rimColor = wheelStyle == "CLASSIC" and Color3.fromRGB(230, 222, 195)
		or (wheelStyle == "SPORT" and Color3.fromRGB(45, 48, 54)
		or (wheelStyle == "RUGGED" and Color3.fromRGB(109, 111, 107) or Color3.fromRGB(188, 193, 199)))
	for _, part in ipairs(car:GetChildren()) do
		if part:IsA("BasePart") and (part.Name == "Wheel" or part.Name == "Rim") then
			local xSign = part:GetAttribute("WheelXSign") or 1
			local zSign = part:GetAttribute("WheelZSign") or 1
			local wheelCFrame = base * CFrame.new(xSign * definition.wheelX, definition.wheelY, zSign * definition.wheelZ)
				* CFrame.Angles(0, math.rad(90), 0)
			part.CFrame = wheelCFrame
			if part.Name == "Wheel" then
				local size = definition.wheelSize * wheelScale
				part.Size = Vector3.new(0.55, size, size)
				part.Color = Color3.fromRGB(25, 27, 30)
				part.Material = wheelStyle == "RUGGED" and Enum.Material.DiamondPlate or Enum.Material.SmoothPlastic
				part.Transparency = 0
			else
				local size = definition.wheelSize * rimScale
				part.Size = Vector3.new(0.6, size, size)
				part.Color = rimColor
				part.Material = wheelStyle == "SPORT" and Enum.Material.SmoothPlastic or Enum.Material.Metal
				part.Transparency = 0
			end
		end
	end

	local tintName = s.personalTint or "LIGHT"
	local tintTransparency = ({ CLEAR = 0.6, LIGHT = 0.38, DARK = 0.16, LIMO = 0.04 })[tintName] or 0.38
	local tintColor = tintName == "CLEAR" and Color3.fromRGB(121, 167, 192) or Color3.fromRGB(20, 27, 33)
	for _, side in ipairs({ -1, 1 }) do
		local window = car:FindFirstChild(side < 0 and "WindowLeft" or "WindowRight")
		if window then
			window.Size = Vector3.new(math.max(2.9, definition.cabinSize.X - 0.7), math.max(0.72, definition.cabinSize.Y - 0.75), 0.12)
			window.CFrame = base * CFrame.new(definition.cabinOffset.X, definition.cabinOffset.Y + 0.05, side * (definition.cabinSize.Z * 0.5 + 0.02))
			window.Color = tintColor
			window.Transparency = tintTransparency
		end
	end

	local bodyTop = definition.bodyY + definition.bodySize.Y * 0.5 + 0.05
	local vinylName = s.personalVinyl or "NONE"
	local vinylColor = vinylName == "DESERT" and Color3.fromRGB(94, 61, 36) or Color3.fromRGB(238, 236, 228)
	local vinylVisible = vinylName ~= "NONE"
	local left1, right1 = car:FindFirstChild("VinylLeft1"), car:FindFirstChild("VinylRight1")
	local left2, right2 = car:FindFirstChild("VinylLeft2"), car:FindFirstChild("VinylRight2")
	for _, stripe in ipairs({ left1, right1, left2, right2 }) do
		if stripe then
			stripe.Color = vinylColor
			stripe.Material = vinylName == "DESERT" and Enum.Material.Fabric or Enum.Material.SmoothPlastic
			stripe.Transparency = 1
		end
	end
	if vinylVisible then
		if vinylName == "STRIPE" then
			if left1 then left1.CFrame = base * CFrame.new(0, bodyTop, 0); left1.Size = Vector3.new(definition.bodySize.X * 0.8, 0.08, 0.62); left1.Transparency = 0 end
		elseif vinylName == "DOUBLE" then
			if left1 then left1.CFrame = base * CFrame.new(0, bodyTop, -0.44); left1.Transparency = 0 end
			if right1 then right1.CFrame = base * CFrame.new(0, bodyTop, 0.44); right1.Transparency = 0 end
		elseif vinylName == "DESERT" then
			if left1 then left1.CFrame = base * CFrame.new(-0.2, bodyTop, -0.56) * CFrame.Angles(0, math.rad(-8), 0); left1.Transparency = 0 end
			if right2 then right2.CFrame = base * CFrame.new(0.35, bodyTop + 0.01, 0.42) * CFrame.Angles(0, math.rad(11), 0); right2.Transparency = 0 end
		end
	end

	local neonColors = {
		AMBER = Color3.fromRGB(255, 176, 32),
		CYAN = Color3.fromRGB(39, 222, 236),
		LIME = Color3.fromRGB(109, 232, 67),
		PURPLE = Color3.fromRGB(173, 73, 232),
	}
	local neonColor = neonColors[s.personalNeon or "OFF"]
	for _, side in ipairs({ -1, 1 }) do
		local neon = car:FindFirstChild(side < 0 and "NeonLeft" or "NeonRight")
		if neon then
			neon.CFrame = base * CFrame.new(0, 0.62, side * (definition.bodySize.Z * 0.5 - 0.06))
			neon.Size = Vector3.new(definition.bodySize.X * 0.84, 0.12, 0.16)
			neon.Color = neonColor or Color3.fromRGB(255, 190, 29)
			neon.Transparency = neonColor and 0.08 or 1
			local glow = neon:FindFirstChild("Glow")
			if glow then glow.Color = neon.Color; glow.Enabled = neonColor ~= nil end
		end
	end

	local muscle = typeName == "MUSCLE"
	local offroad = typeName == "OFFROAD"
	for _, name in ipairs({ "MuscleHood", "OffroadRackLeft", "OffroadRackRight", "OffroadRackFront", "OffroadRackRear", "OffroadBumper" }) do
		local accessory = car:FindFirstChild(name)
		if accessory then accessory.Transparency = ((name == "MuscleHood" and muscle) or (string.sub(name, 1, 7) == "Offroad" and offroad)) and 0 or 1 end
	end
	local hood = car:FindFirstChild("MuscleHood")
	if hood then hood.CFrame = base * CFrame.new(1.65, bodyTop + 0.2, 0) end
	local rackY = definition.cabinOffset.Y + definition.cabinSize.Y * 0.5 + 0.22
	local rackPositions = {
		OffroadRackLeft = Vector3.new(definition.cabinOffset.X, rackY, -1.55),
		OffroadRackRight = Vector3.new(definition.cabinOffset.X, rackY, 1.55),
		OffroadRackFront = Vector3.new(definition.cabinOffset.X + 1.6, rackY, 0),
		OffroadRackRear = Vector3.new(definition.cabinOffset.X - 1.4, rackY, 0),
		OffroadBumper = Vector3.new(definition.bodySize.X * 0.5 + 0.2, definition.bodyY, 0),
	}
	for name, offset in pairs(rackPositions) do
		local accessory = car:FindFirstChild(name)
		if accessory then accessory.CFrame = base * CFrame.new(offset) end
	end

	local promptObject = body:FindFirstChild("CustomizePrompt")
	if promptObject and promptObject:IsA("ProximityPrompt") then promptObject.ObjectText = definition.label end
end

local function updateWorld(s)
 if s.stage==4 and s.firstAtSales and not s.firstTransit and s.salesBuilt then s.listed=true;s.buyerMet=true end
 IntegrationWorld.Sync(world,s)
 Specialist.Sync(world,s)
	show("LotEntrance.OpenAnchor", s.stage == 1 and s.openingStep == 0)
	show("LotEntrance.GateSign", s.stage >= 2 or (s.stage == 1 and s.openingStep >= 1))
	show("DealStation.DealTablePad", s.stage == 1 and s.openingStep == 1)
	show("DealStation.Furniture", s.stage >= 2)
	show("FirstDeal", s.stage >= 2 and s.stage <= 4)
	show("FirstDeal.FirstSeller", s.stage == 2)
	show("FirstBuyer", s.stage == 4 and s.buyerMet)
	show("FirstDeal.ForSaleSign", s.stage == 4 and s.listed)

	show("FirstDeal.BodyRepairAnchor", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Body)
	show("FirstDeal.WheelsRepairAnchor", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Wheels)
	show("FirstDeal.EngineRepairAnchor", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Engine)
	show("FirstDeal.ListAnchor", false)

	show("Workshop.FoundationPad", s.stage == 3 and s.workshopStep == 0)
	show("Workshop.Foundation", s.workshopStep >= 4 or (s.stage == 3 and s.workshopStep >= 1))
	show("Workshop.ApproachPad", s.stage == 3 and s.workshopStep == 1)
	show("Workshop.Approach", s.workshopStep >= 4 or (s.stage == 3 and s.workshopStep >= 2))
	show("Workshop.ServiceSlabPad", s.stage == 3 and s.workshopStep == 2)
	show("Workshop.ServiceSlab", s.workshopStep >= 4 or (s.stage == 3 and s.workshopStep >= 3))
	show("Workshop.LiftPad", s.stage == 3 and s.workshopStep == 3)
	show("Workshop.Lift", s.workshopStep >= 4)
	show("Workshop.Mechanic", s.mechanicHired)
	show("Workshop.HirePad", s.stage == 6)
	show("SecondDeal", (s.stage == 7 and s.secondVisible) or (s.stage>=8 and not s.secondDeparted))
 show("SecondDeal.SecondSeller",s.stage==7 and s.secondVisible)

	show("Operations.AppraisalPad", s.stage == 8 and s.operationsStep == 0)
	show("Operations.AppraisalPosition", s.stage > 8 or (s.stage == 8 and s.operationsStep >= 1))
	show("Operations.CarBuyerPad", s.stage == 8 and s.operationsStep == 1)
	show("Operations.CarBuyer", s.stage > 8 or (s.stage == 8 and s.operationsStep >= 2))
	show("Operations.SalesPositionPad", s.stage == 4 and not s.salesBuilt)
	show("Operations.SalesPosition", s.salesBuilt == true)
	show("Operations.SalesRepPad", s.stage == 8 and s.operationsStep == 3)
	show("Operations.SalesRep", s.stage > 8 or (s.stage == 8 and s.operationsStep >= 4))
	show("Operations.AutoRouteCar", s.stage >= 8 and ((s.automationDemoRunning and not s.automationDemoComplete and s.autoCycle and s.autoCycle.bought) or (s.routineRunning and s.routine and s.routine.bought and not s.routine.departed)))

	local mechanic = world:FindFirstChild("Mechanic", true)
	local staffState = mechanic and mechanic:FindFirstChild("StaffState", true)
	local staffCard = staffState and staffState:FindFirstChild("Card")
	local staffProgress = staffCard and staffCard:FindFirstChild("Progress")
	if staffProgress then
		staffProgress.Text = "HIRE $" .. tostring(Config.MechanicCost)
		staffProgress.TextColor3 = Config.Colors.Yellow
	end
	if staffState and staffState:IsA("BillboardGui") then staffState.Enabled = false end
	for _, staffName in ipairs({ "CarBuyer", "SalesRep" }) do
		local staff = world:FindFirstChild(staffName, true)
		local staffBillboard = staff and staff:FindFirstChild("StaffState", true)
		if staffBillboard and staffBillboard:IsA("BillboardGui") then staffBillboard.Enabled = false end
	end
	show("PersonalGarage.ClaimPad", s.stage == 8 and s.operationsStep >= 4 and s.automationDemoComplete)
	show("PersonalGarage.PersonalCar", s.stage >= 9)

	local sellerRoute = s.stage == 10 and s.rareRoute == "Seller"
	local sellerReady = sellerRoute and (s.rareTravelPhase == "AtSeller" or s.rareTravelPhase == "ReturnChoice")
	local rarePresent = s.stage == 10 and s.rarePhase ~= "Dormant" and s.rarePhase ~= "Lead"
		and (not sellerRoute or sellerReady)
	show("RareArrival.IntakeBay", false)
	show("RareArrival.SellerGarage", sellerRoute and s.rareTravelPhase ~= nil)
	show("RareArrival.Transporter", false)
	show("RareArrival.Transporter.RareCar", false)
	show("RareArrival.Transporter.Cover", false)
	show("RareArrival.RareSeller", s.stage == 10 and (s.rarePhase == "Waiting" or s.rarePhase == "Revealed") and (not sellerRoute or sellerReady))

	setPrompt("OpenLotPrompt", false)
	setPrompt("FirstSellerPrompt", s.stage == 2)
	setPrompt("StartRepairPrompt", false)
	setPrompt("BodyRepairPrompt", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Body)
	setPrompt("WheelsRepairPrompt", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Wheels)
	setPrompt("EngineRepairPrompt", s.stage == 3 and s.firstAtRepair and not s.firstTransit and s.repairStarted and not s.fixes.Engine)
	setPrompt("ListCarPrompt", false)
	setPrompt("BuyerPrompt", s.stage == 4 and s.buyerMet)
	setPrompt("BuildWorkshopPrompt", false)
	setPrompt("HireMechanicPrompt", false)
	setPrompt("SecondSellerPrompt", s.stage == 7 and s.secondVisible)
	setPrompt("ClaimCarPrompt", false)
	local boardingRareLead = s.stage == 10 and s.rareRoute == "Seller" and s.rareTravelPhase == "GetIn"
	setPrompt("CustomizePrompt", canCustomizePersonalCar(s))
	setPrompt("RareDrivePrompt", boardingRareLead)
	setPrompt("RareSellerPrompt", s.stage == 10 and (s.rarePhase == "Waiting" or s.rarePhase == "Revealed") and (s.rareRoute ~= "Seller" or s.rareTravelPhase == "AtSeller" or s.rareTravelPhase == "ReturnChoice"))

 local activePad=Journey.Active(s)
 for _,pad in Journey.Pads do show(pad.path,Journey.Available(s,pad.id))end
 local readiness=world.FirstDeal.FirstCar.Body:FindFirstChild('CarReadiness')
 if readiness then
  local status=s.firstTransit and (s.firstTransit=='Repair' and 'MOVING TO REPAIR BAY' or 'MOVING TO SALES AREA')
   or (s.pendingDeal and s.pendingDeal.kind=='FirstSale' and 'SOLD · DEPARTING') or (s.buyerMet and 'BUYER WAITING') or (s.listed and 'WAITING FOR BUYER') or (allFixed(s) and 'READY TO SELL')
   or (s.firstAtRepair and 'NEEDS REPAIRS') or 'WAITING FOR REPAIR BAY'
  readiness.Status.Text=status
 end
	updateFirstCar(s)
	updateRareCar(s)
	applyPersonalAppearance(s)
end

local function focusDialogue(player, kind, head, data)
 if not near(player,head) or (states[player] and states[player].pendingDeal) then return end
 local s=states[player];s.allowedOptions={}
 for _,option in data.options or {} do s.allowedOptions[option.id]=true end
 s.dialogueTarget=kind
 data.kind = kind
 local selling=kind=='FirstBuyer'
 local car=kind=='SecondSeller' and Config.SecondSeller.car or (kind:find('Rare') and Config.RareSeller.car or Config.FirstCar.name)
 local price
 for _,option in data.options or {} do
  if option.tone=='Green' then price=tonumber(((option.text:match('%$([%d,]+)') or ''):gsub(',','')));break end
 end
 local cost=kind:find('Rare') and 500 or selling and (s.purchase+s.repairTotal) or (kind=='FirstSeller' or kind=='SecondSeller') and 500 or nil
 data.deal={reserve=s.rareFocus and 500 or s.automationDemoComplete and 1400 or 0,condition=kind=='SecondSeller' and Config.SecondSeller.condition or (kind:find('Rare') and Config.RareSeller.condition or s.condition),mode=selling and 'Sell' or 'Buy',car=car,price=price,cost=cost,value=selling and price and price-cost or (kind=='SecondSeller' and Config.SecondSeller.estimate or (kind:find('Rare') and Config.RareSeller.estimate or Config.FirstCar.estimate))}
 local profiles={
  FirstSeller={price=900,limit=850,mode='Buy',name='Jesse',line='I need it gone today. Make me an offer.',suggest=850},
  FirstBuyer={price=2350,limit=2350,mode='Sell',name='Marcus',role='Daily driver',line='It’s repaired. I brought my full budget.',suggest=2450},
  SecondSeller={price=1400,limit=1200,mode='Buy',name='Maya',line='It needs work. I’ve left room in the price.',suggest=1250},
  RareSellerDeal={price=s.rareRoute=='Seller' and 4500 or 4800,limit=s.rareRoute=='Seller' and 4350 or 4650,mode='Buy',name='Elias',line='Original motor. A rare find, even with the work it needs.',suggest=s.rareRoute=='Seller' and 4350 or 4650},
 }
 local profile=profiles[kind]
 if profile then
  local key=kind=='RareSellerDeal' and kind..tostring(s.specialistNumber or 1) or kind
  local q=Negotiation.Open(s,key,profile)
  data.name=q.name;data.line=q.line;data.deal.price=q.price
  data.deal.quote=Negotiation.Public(q)
  data.deal.value=selling and q.price-cost or data.deal.value
  if kind=='FirstSeller' then s.firstAsk=q.price;data.deal.value=2350
  elseif kind=='SecondSeller' then s.secondAsk=q.price
  elseif kind=='RareSellerDeal' then s.rareAsk=q.price;data.deal.value=6200 end
  s.activeNegotiation=key;s.allowedOptions={};data.options={}
 else s.activeNegotiation=nil end
 event:FireClient(player, "Dialogue", data, head)
end

specialistPrompt.Triggered:Connect(function(player)local s=states[player];if s and player==owner then Specialist.Dialogue(player,s,world,event,function()return states[player]==s end)end end)

local function firstSellerDialogue(player, s, asked)
	local head = world:FindFirstChild("FirstSeller", true)
	head = head and head:FindFirstChild("Head")
	local price = asked and 850 or s.firstAsk
	s.firstAsk = price
	focusDialogue(player, "FirstSeller", head, {
		name = "JESSE",
		line = asked and "Fine. $850, but that is my floor." or "Runs rough. Body is tired. I want $900.",
		greed = asked and 0.58 or 0.36,
		options = asked and {
			{ id = "FirstBuy", text = "BUY  $850", tone = "Green" },
			{ id = "CloseDialogue", text = "WALK", tone = "Dark" },
		} or {
			{ id = "FirstBuy", text = "BUY  $900", tone = "Green" },
			{ id = "FirstAsk", text = "OFFER  $850", tone = "Yellow" },
			{ id = "CloseDialogue", text = "WALK", tone = "Dark" },
		},
	})
end

local function buyerDialogue(player, asked)
	local s = states[player]
	local head = world:FindFirstChild("FirstBuyer", true)
	head = head and head:FindFirstChild("Head")
	local amount = asked and Config.FirstBuyer.counter or Config.FirstBuyer.offer
	focusDialogue(player, "FirstBuyer", head, {
		name = Config.FirstBuyer.name,
		line = asked and "I will do $2,400. Right now." or "Looks clean. I can take it today for $2,350.",
		greed = asked and 0.82 or 0.61,
		options = asked and {
			{ id = "BuyerSell2400", text = "SELL  $2,400", tone = "Green" },
			{ id = "KeepListed", text = "KEEP LISTED", tone = "Dark" },
		} or {
			{ id = "BuyerSell2350", text = "SELL  $2,350", tone = "Green" },
			{ id = "BuyerAsk", text = "ASK  $2,450", tone = "Yellow" },
			{ id = "KeepListed", text = "KEEP LISTED", tone = "Dark" },
		},
	})
end

local function secondSellerDialogue(player, asked)
	local s = states[player]
	local head = world:FindFirstChild("SecondSeller", true)
	head = head and head:FindFirstChild("Head")
	local price = asked and Config.SecondSeller.counter or Config.SecondSeller.ask
	s.secondAsk = price
	focusDialogue(player, "SecondSeller", head, {
		name = Config.SecondSeller.name,
		line = asked and "You read the work correctly. $1,200 is fair." or "I know what it is worth. The weak finish is already priced in.",
		greed = asked and 0.9 or Config.SecondSeller.greed,
		options = asked and {
			{ id = "SecondBuy", text = "BUY  $1,200", tone = "Green" },
			{ id = "CloseDialogue", text = "PASS", tone = "Dark" },
		} or {
			{ id = "SecondBuy", text = "BUY  $1,400", tone = "Green" },
			{ id = "SecondAsk", text = "OFFER  $1,200", tone = "Yellow" },
			{ id = "CloseDialogue", text = "PASS", tone = "Dark" },
		},
	})
end

local function rareSellerDialogue(player, revealed, countered)
	local s = states[player]
	local head = world:FindFirstChild("RareSeller", true)
	head = head and head:FindFirstChild("Head")
	if not revealed then
		focusDialogue(player, "RareSellerReveal", head, {
			name = Config.RareSeller.name,
			greed = 0.42,
			line = s.rareRoute == "Seller"
				and "You came before I listed it. That saves both of us time. Take a look."
				or "I brought something unusual. If you are serious, take a look.",
			options = {
				{ id = "ShowRare", text = "SHOW ME", tone = "Yellow" },
				{ id = "CloseDialogue", text = "NOT NOW", tone = "Dark" },
			},
		})
		return
	end
	local sellerVisit = s.rareRoute == "Seller"
	local openingAsk = sellerVisit and (Config.RareSeller.ask - 300) or Config.RareSeller.ask
	local counterAsk = sellerVisit and (Config.RareSeller.counter - 300) or Config.RareSeller.counter
	local amount = countered and counterAsk or openingAsk
	s.rareAsk = amount
	focusDialogue(player, "RareSellerDeal", head, {
		name = Config.RareSeller.name,
		greed = countered and 0.88 or Config.RareSeller.greed,
		line = countered and ("Meet me at $" .. money(counterAsk) .. ". It should go to someone who understands it.")
			or ("Original motor. Survivor body. I want $" .. money(openingAsk) .. "."),
		options = countered and {
			{ id = "RareBuy", text = "BUY  $" .. money(counterAsk), tone = "Green" },
			{ id = "CloseDialogue", text = "KEEP LEAD", tone = "Dark" },
		} or {
			{ id = "RareBuy", text = "BUY  $" .. money(openingAsk), tone = "Green" },
			{ id = "RareAsk", text = "OFFER  $" .. money(counterAsk - 150), tone = "Yellow" },
			{ id = "CloseDialogue", text = "WALK", tone = "Dark" },
		},
	})
end

local function rareNeedCashDialogue(player)
	local s = states[player]
	local head = world:FindFirstChild("RareSeller", true)
	head = head and head:FindFirstChild("Head")
	local short = math.max(0, s.rareAsk + (s.rareFocus and 500 or s.automationDemoComplete and 1400 or 500) - s.cash)
	focusDialogue(player, "RareSellerCash", head, {
		name = Config.RareSeller.name,
		greed = 1,
		line = "You need $" .. tostring(short) .. " more to buy this car and retain repair and operating funds. I can wait.",
		options = {
			{ id = "CloseDialogue", text = "KEEP LEAD", tone = "Yellow" },
			{ id = "CloseDialogue", text = "WALK", tone = "Dark" },
		},
	})
end

local function advance(player, stage)
	local s = states[player]
	if not s then return end
	s.stage = stage
	updateWorld(s)
	sendState(player)
end

local function animateRareArrival(player, s)
	local set = world:FindFirstChild("RareArrival")
	local transporter = set and set:FindFirstChild("Transporter")
	local markers = set and set:FindFirstChild("Markers")
	local startMarker = markers and markers:FindFirstChild("TransportStart")
	local endMarker = markers and markers:FindFirstChild("TransportEnd")
	if not transporter or not startMarker or not endMarker then
		if states[player] == s and s.rarePhase == "EnRoute" then
			s.rareArrivalComplete = true
		end
		return
	end
	local duration = set:GetAttribute("ArrivalDuration") or 3.4
	transporter:PivotTo(startMarker.CFrame)
	local started = os.clock()
	while states[player] == s and s.stage == 10 and s.rarePhase == "EnRoute" do
		local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
		local eased = alpha * alpha * (3 - 2 * alpha)
		transporter:PivotTo(startMarker.CFrame:Lerp(endMarker.CFrame, eased))
		if alpha >= 1 then break end
		RunService.Heartbeat:Wait()
	end
	if states[player] == s and s.stage == 10 and s.rarePhase == "EnRoute" then
		transporter:PivotTo(endMarker.CFrame)
		s.rareArrivalComplete = true
	end
end

local function connectPrompt(name, callback)
	local p = world:FindFirstChild(name, true)
	if p and p:IsA("ProximityPrompt") then
		p.Triggered:Connect(function(player)
   local target=p.Parent:IsA('Attachment') and p.Parent.Parent or p.Parent
   if player==owner and p.Enabled and near(player,target,p.MaxActivationDistance+3) then callback(player) end
  end)
	else
		warn("Core prototype prompt missing:", name)
	end
end

connectPrompt("FirstSellerPrompt", function(player)
	local s = states[player]
	if s and s.stage == 2 then firstSellerDialogue(player, s, false) end
end)

for _, repairName in ipairs({"Body", "Wheels", "Engine"}) do
	connectPrompt(repairName .. "RepairPrompt", function(player)
		local s = states[player]
		if not s or s.stage ~= 3 or not s.repairStarted or s.fixes[repairName] then return end
		local repair = Config.Repairs[repairName]
		if s.cash < repair.cost then
			notify(player, "NOT ENOUGH CASH", "This repair costs $" .. tostring(repair.cost), "Red")
			return
		end
		s.cash -= repair.cost
		s.repairTotal += repair.cost
		s.carValue += repair.value
		s.condition = math.min(100, s.condition + repair.condition)
		s.fixes[repairName] = true
		local anchor = world:FindFirstChild(repairName .. "RepairAnchor", true)
		event:FireClient(player, "WorldFloater", {
			title = "-$" .. tostring(repair.cost),
			detail = string.upper(repairName) .. " FIXED  ·  +$" .. tostring(repair.value) .. " VALUE",
			tone = "Red",
			detailTone = "Green",
		}, anchor)
		if allFixed(s) then
			s.condition = 100
			s.stage = 4
			local body = world:FindFirstChild("FirstCar", true)
			body = body and body:FindFirstChild("Body")
			event:FireClient(player, "WorldFloater", {
				title = "RESTORED · 100%",
				detail = "VALUE $" .. tostring(s.carValue) .. " · BUILD YOUR SALES AREA",
				tone = "Green",
			}, body)
		end
		updateWorld(s)
		sendState(player)
	end)
end

connectPrompt("BuyerPrompt", function(player)
	local s = states[player]
	if s and s.stage == 4 and s.buyerMet then buyerDialogue(player, false) end
end)

connectPrompt("SecondSellerPrompt", function(player)
	local s = states[player]
	if s and s.stage == 7 and s.secondVisible then secondSellerDialogue(player, false) end
end)

connectPrompt("RareSellerPrompt", function(player)
	local s = states[player]
	if not s or s.stage ~= 10 then return end
	if s.rarePhase == "Waiting" then
		rareSellerDialogue(player, false, false)
	elseif s.rarePhase == "Revealed" then
		rareSellerDialogue(player, true, false)
	end
end)

connectPrompt("CustomizePrompt", function(player)
	local s = states[player]
	if canCustomizePersonalCar(s) then
		local car = world:FindFirstChild("PersonalCar", true)
		event:FireClient(player, "Customize", statePacket(s), car)
	end
end)

local finalizePendingDeal

local function closeDeal(player)
 if states[player] then states[player].activeNegotiation=nil;states[player].allowedOptions=nil end
	event:FireClient(player, "CloseDialogue")
end

local function sellFirst(player, amount)
	local s = states[player]
	if not s or s.stage ~= 4 or s.pendingDeal then return end
	local totalCost = s.purchase + s.repairTotal
	local profit = amount - totalCost
	s.cash += amount
	s.phone = nil
	s.pendingDeal = { kind = "FirstSale", amount = amount, profit = profit }
 updateWorld(s)
	event:FireClient(player, "DealResolved", {
		kind = "Sell",
		amount = amount,
		profit = profit,
		carName = Config.FirstCar.name,
		result = "SOLD",
	})
	sendState(player)
	local pending = s.pendingDeal
	task.delay(2.2, function()
		if states[player] == s and s.pendingDeal == pending then finalizePendingDeal(player, s) end
	end)
end

local CUSTOMIZATION_FIELDS = {
	TYPE = { field = "personalType", values = { COUPE = true, MUSCLE = true, OFFROAD = true } },
	PAINT = { field = "personalColor", values = { BLUE = true, RED = true, LIME = true, SAND = true, BLACK = true, WHITE = true } },
	WHEELS = { field = "personalWheel", values = { STOCK = true, CLASSIC = true, SPORT = true, RUGGED = true } },
	VINYL = { field = "personalVinyl", values = { NONE = true, STRIPE = true, DOUBLE = true, DESERT = true } },
	TINT = { field = "personalTint", values = { CLEAR = true, LIGHT = true, DARK = true, LIMO = true } },
	NEON = { field = "personalNeon", values = { OFF = true, AMBER = true, CYAN = true, LIME = true, PURPLE = true } },
}

local function snapshotCustomization(s)
	return {
		personalType = s.personalType,
		personalColor = s.personalColor,
		personalWheel = s.personalWheel,
		personalVinyl = s.personalVinyl,
		personalTint = s.personalTint,
		personalNeon = s.personalNeon,
	}
end

local function setCustomizationValue(s, category, value)
	category = string.upper(tostring(category or ""))
	value = string.upper(tostring(value or ""))
	local definition = CUSTOMIZATION_FIELDS[category]
	if not definition or not definition.values[value] or s[definition.field] == value then return false end
	s.customizationUndo = snapshotCustomization(s)
	s[definition.field] = value
	applyPersonalAppearance(s)
	return true
end

local RANDOM_BUILDS = {
	{ name = "CLEAN", personalType = "COUPE", personalColor = "BLUE", personalWheel = "CLASSIC", personalVinyl = "NONE", personalTint = "LIGHT", personalNeon = "OFF" },
	{ name = "DESERT", personalType = "OFFROAD", personalColor = "SAND", personalWheel = "RUGGED", personalVinyl = "DESERT", personalTint = "LIGHT", personalNeon = "AMBER" },
	{ name = "STREET", personalType = "MUSCLE", personalColor = "RED", personalWheel = "SPORT", personalVinyl = "DOUBLE", personalTint = "DARK", personalNeon = "CYAN" },
	{ name = "NIGHT", personalType = "COUPE", personalColor = "BLACK", personalWheel = "SPORT", personalVinyl = "STRIPE", personalTint = "LIMO", personalNeon = "PURPLE" },
	{ name = "WILD", personalType = "MUSCLE", personalColor = "LIME", personalWheel = "CLASSIC", personalVinyl = "DOUBLE", personalTint = "DARK", personalNeon = "LIME" },
}

local function randomizeCustomization(s)
	s.customizationUndo = snapshotCustomization(s)
	local candidates = {}
	for _, build in ipairs(RANDOM_BUILDS) do
		if build.name ~= s.lastRandomRecipe then table.insert(candidates, build) end
	end
	local build = candidates[math.random(1, #candidates)]
	s.lastRandomRecipe = build.name
	for field, value in pairs(build) do
		if field ~= "name" then s[field] = value end
	end
	applyPersonalAppearance(s)
end

local function undoCustomization(s)
	local previous = s.customizationUndo
	if not previous then return false end
	s.customizationUndo = snapshotCustomization(s)
	for field, value in pairs(previous) do s[field] = value end
	applyPersonalAppearance(s)
	return true
end

local function placeRareTransport(markerName)
	local set = world:FindFirstChild("RareArrival")
	local transporter = set and set:FindFirstChild("Transporter")
	local marker = set and set:FindFirstChild(markerName, true)
	if transporter and marker and marker:IsA("BasePart") then
		transporter:PivotTo(marker.CFrame)
	end
end

local function beginRareRouteDrive(player, s, mode)
	if s.driving then return end
	local car = world:FindFirstChild("PersonalCar", true)
	if not car or not car:IsA("Model") then return end
	s.driving = true
	s.driveThrottle = 0
	s.driveSteer = 0
	if mode == "RareOutbound" then
		s.rarePhase = "Travel"
		s.rareTravelPhase = "Driving"
		car:PivotTo(CFrame.new(IntegrationWorld.PersonalHome+Vector3.new(0,0,16)) * CFrame.Angles(0, math.pi, 0))
	else
		s.rareTravelPhase = "DrivingHome"
		car:PivotTo(CFrame.new(Vector3.new(88, 0, 28)+IntegrationWorld.RareOffset) * CFrame.Angles(0, math.rad(90), 0))
	end
	updateWorld(s)
	sendState(player)
	event:FireClient(player, "DriveStart", {
		car = car,
		mode = mode,
	})
end

local function arriveAtRareSeller(player, s)
	if states[player] ~= s then return end
	s.driving = false
	s.driveThrottle = 0
	s.driveSteer = 0
	s.rareTravelPhase = "AtSeller"
	s.rarePhase = "Waiting"
	s.rareArrivalComplete = true
	placeRareTransport("SellerTransport")
	local seller = world:FindFirstChild("RareSeller", true)
	if seller and seller:IsA("Model") then seller:PivotTo(CFrame.new(Vector3.new(96, 1.5, 18)+IntegrationWorld.RareOffset)) end
	local car = world:FindFirstChild("PersonalCar", true)
	if car and car:IsA("Model") then car:PivotTo(CFrame.new(Vector3.new(86, 0, 27)+IntegrationWorld.RareOffset)) end
	local character = player.Character
	if character then character:PivotTo(CFrame.lookAt((Vector3.new(88, 3, 23)+IntegrationWorld.RareOffset), (Vector3.new(96, 3, 18)+IntegrationWorld.RareOffset))) end
	updateWorld(s)
	sendState(player)
	event:FireClient(player, "DriveEnd")
	event:FireClient(player, "RareSellerArrival")
	notify(player, "EARLY LOOK", "You drove here first and saved $300 on Elias's opening ask.", "Green")
end

local function returnRareToLot(player, s)
	if states[player] ~= s then return end
	s.driving = false
	s.driveThrottle = 0
	s.driveSteer = 0
	s.rareTravelPhase = nil
	local car = world:FindFirstChild("PersonalCar", true)
	if car and car:IsA("Model") then car:PivotTo(CFrame.new(IntegrationWorld.PersonalHome)) end
	local character = player.Character
	if character then character:PivotTo(CFrame.lookAt((IntegrationWorld.PersonalHome+Vector3.new(-6,3,1)), (IntegrationWorld.PersonalHome+Vector3.new(0,2,0)))) end
	if s.rareOwned then
		s.rareRoute = "Lot"
		s.rarePhase = "Purchased"
		s.phone = nil
		placeRareTransport("TransportEnd")
	else
		s.rareRoute = nil
		s.rarePhase = "Lead"
		s.phone = "FutureLead"
		s.rareAsk = Config.RareSeller.ask
		resetRareTransporter()
	end
	local seller = world:FindFirstChild("RareSeller", true)
	if seller and seller:IsA("Model") then seller:PivotTo(CFrame.new(Vector3.new(-15,1.5,16)+IntegrationWorld.RareOffset)) end
	updateWorld(s)
	sendState(player)
	event:FireClient(player, "DriveEnd")
	notify(player, "BACK AT YOUR LOT", s.rareOwned and "The rare car is waiting in private intake." or "The private lead remains on your phone.", "Green")
end

finalizePendingDeal = function(player, s)
	if states[player] ~= s or not s.pendingDeal then return end
	local pending = s.pendingDeal
 if pending.kind=="FirstSale" and not pending.departureComplete then
  if not pending.departureStarted then
   pending.departureStarted=true
   Automation.ExitFirst(player,s,world,function()return states[player]==s end,function()
    pending.departureComplete=true;finalizePendingDeal(player,s)
   end)
  end
  return
 end
 s.pendingDeal = nil
	if pending.kind == "FirstBuy" then
		s.stage = 3
	elseif pending.kind == "FirstSale" then
		s.stage = 6
		s.buyerMet = false
	elseif pending.kind == "SecondBuy" then
		s.stage = 8
		s.secondVisible = false
  task.defer(function()Automation.StartSecond(player,s,world,function()updateWorld(s);sendState(player)end,function()return states[player]==s end)end)
 elseif pending.kind == "RareBuy" then
		s.rareOwned = true
		s.rarePhase = "Purchased"
		if s.rareRoute == "Seller" then s.rareTravelPhase = "ReturnChoice" end
	end
	updateWorld(s)
	sendState(player)
	if pending.kind == "RareBuy" and s.rareRoute == "Seller" then
		task.delay(0.25, function()
			if states[player] == s and player.Parent then event:FireClient(player, "ReturnChoice") end
		end)
	end
end

connectPrompt("RareDrivePrompt", function(player)
	local s = states[player]
	if s and s.stage == 10 and s.rareRoute == "Seller" and s.rareTravelPhase == "GetIn" then
		beginRareRouteDrive(player, s, "RareOutbound")
	end
end)

local function runAutomationDemo(player,s)
 Automation.StartOperations(player,s,world,function()updateWorld(s);sendState(player)end,
 function(title,detail)notify(player,title,detail,"Green")end,function()return states[player]==s end)
end

local function handlePadPurchase(player, s, payload)
	if typeof(payload) ~= "table" or type(payload.padId) ~= "string" then
		event:FireClient(player, "PadPurchaseResult", {
			ok = false,
			reason = "InvalidRequest",
		})
		return
	end

 local definitions={}
 for _,pad in Journey.Pads do definitions[pad.id]={requiredStage=pad.stage,stepKey=pad.key,requiredStep=pad.step,cost=pad.cost,requiresAutomation=pad.automation,part=Journey.Find(world,pad.path)}end

	local definition = definitions[payload.padId]
	if not definition or not definition.part or not definition.part:IsA("BasePart") then
		event:FireClient(player, "PadPurchaseResult", {
			padId = payload.padId,
			ok = false,
			reason = "Unavailable",
		})
		return
	end
	if not Journey.Available(s,payload.padId) then
		event:FireClient(player, "PadPurchaseResult", {
			padId = payload.padId,
			ok = false,
			reason = s.stage > (definition.requiredStage or 0) and "Owned" or "Unavailable",
		})
		return
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local function withinPad()
		if not root.Parent or player.Character ~= root.Parent then return false end
		local localPosition = definition.part.CFrame:PointToObjectSpace(root.Position)
		return math.abs(localPosition.X) <= definition.part.Size.X * 0.5 + 2
			and math.abs(localPosition.Z) <= definition.part.Size.Z * 0.5 + 2
			and math.abs(localPosition.Y) <= 7
	end
	-- The contact request can arrive before the character's replicated position.
	-- Wait briefly for that position; keep the same authoritative purchase bounds.
	local deadline = os.clock() + 0.4
	while not withinPad() and os.clock() < deadline and states[player] == s do
		task.wait(0.05)
	end
	if states[player] ~= s then return end
	if not withinPad() then
		event:FireClient(player, "PadPurchaseResult", {
			padId = payload.padId,
			ok = false,
			reason = "TooFar",
		})
		return
	end

	-- Another request or a deal transition may have completed while we waited.
	if not Journey.Available(s, payload.padId) then
		event:FireClient(player, "PadPurchaseResult", {padId=payload.padId, ok=false, reason="Unavailable"})
		return
	end

	if s.cash < definition.cost then
		event:FireClient(player, "PadPurchaseResult", {
			padId = payload.padId,
			ok = false,
			reason = "InsufficientFunds",
			cost = definition.cost,
			shortfall = definition.cost - s.cash,
			balance = s.cash,
		})
		return
	end

local purchaseDefinition=Journey.Get(payload.padId)
 if purchaseDefinition.optional and definition.cost>0 and s.automationDemoComplete and s.cash-definition.cost<(s.rareFocus and 500 or 1400) then event:FireClient(player,"PadPurchaseResult",{padId=payload.padId,ok=false,reason="OperatingReserve"});notify(player,"OPERATING FUNDS","Keep $1,400 for your team’s next car and repairs.","Red");return end
	s.cash -= definition.cost
 if purchaseDefinition.owned then s[purchaseDefinition.owned]=true end
	if payload.padId == "PlantSaleSign" then
		s.openingStep = 1
	elseif payload.padId == "DealTable" then
		s.stage = 2
	elseif payload.padId == "WorkshopFoundation" then
		s.workshopStep = 1
	elseif payload.padId == "RepairTools" then
        s.workshopStep=2
    elseif payload.padId == "YardPower" then
        s.workshopStep=3
    elseif payload.padId == "WorkshopApproach" then
		s.shelterBuilt = true
	elseif payload.padId == "WorkshopServiceSlab" then
		s.serviceFloorBuilt = true
	elseif payload.padId == "WorkshopLift" then
		s.workshopStep = 4
	elseif payload.padId == "FirstMechanic" then
		s.stage = 7
		s.mechanicHired = true
		s.phone = nil
		s.secondVisible = true
	elseif payload.padId == "AppraisalPosition" then
		s.operationsStep = 1
	elseif payload.padId == "CarBuyer" then
		s.operationsStep = 3
  world.Operations.CarBuyer:SetAttribute('StaffJob','Sourcing the next car')
	elseif payload.padId == "SalesPosition" then
        s.salesDisplayBuilt=true
    elseif payload.padId == "SalesDesk" then
		s.salesBuilt = true
	elseif payload.padId == "SalesRep" then
		s.operationsStep = 4
		s.automationDemoComplete = false
	elseif payload.padId == "FirstPersonalCar" then
		-- Claiming unlocks the personal-car step. The rare lead is armed only
		-- after the player explicitly finishes customization.
		s.stage = 9
		s.phone = nil
		s.rarePhase = "Dormant"
		s.rareRoute = nil
		s.rareTravelPhase = nil
		s.rareAsk = Config.RareSeller.ask
	end
	updateWorld(s)
	event:FireClient(player, "PadPurchaseResult", {
		padId = payload.padId,
		ok = true,
		cost = definition.cost,
		balance = s.cash,
	})
	sendState(player)

 if payload.padId=="WorkshopLift" or payload.padId=="SalesDesk" then
  Automation.TransferFirst(player,s,world,payload.padId=="WorkshopLift" and "Repair" or "Sales",function()return states[player]==s end,function()updateWorld(s);sendState(player)end)
 end
	if payload.padId == "PlantSaleSign" then
		notify(player, "SIGN PLANTED", "Set up the seller area to receive your first car.", "Green")
	elseif payload.padId == "DealTable" then
		notify(player, "READY TO TRADE", "Jesse is waiting beside the rusty sedan.", "Green")
	elseif payload.padId == "WorkshopLift" then
		notify(player, "WORKSHOP READY", "Your car is moving to the equipped repair bay.", "Green")
	elseif payload.padId == "SalesRep" then
		notify(player, "TEAM COMPLETE", "Watch the first car route through your dealership.", "Yellow")
		task.spawn(runAutomationDemo, player, s)
	elseif payload.padId == "FirstMechanic" then
		task.delay(0.7, function()
			if states[player] ~= s or not player.Parent then return end
			local seller = world:FindFirstChild("SecondSeller", true)
			local head = seller and seller:FindFirstChild("Head")
			event:FireClient(player, "WorldFloater", {
				title = "NEW SELLER",
				detail = "A TOUGHER DEAL JUST ARRIVED",
				tone = "Yellow",
			}, head)
		end)
	elseif payload.padId == "FirstPersonalCar" then
		notify(player, "PERSONAL CAR CLAIMED", "Choose a car style, then make it yours.", "Green")
	end
end

event.OnServerEvent:Connect(function(player, action, payload)
	local s = states[player]
 if action == "Ready" then
  if owner and owner~=player then notify(player,"LOT IN USE","This integration session has one dealership owner.","Yellow");return end
  if loading[player] then return end
  owner=player
  if not s then
   loading[player]=true
   s=freshState()
   local saved=Save.Load(player)
   if not player.Parent then loading[player]=nil;owner=nil;return end
   if type(saved)=="table" then for k,v in saved do s[k]=v end end
   if (s.journeyVersion or 0)<9 then
    s.salesBuilt=s.stage>=5 or (s.operationsStep or 0)>=3
    s.firstAtRepair=s.stage>=4 or s.repairStarted
    s.firstAtSales=s.stage>=5 or s.listed
    if s.stage==5 then s.stage=6 end
    s.shelterBuilt=(s.workshopStep or 0)>=2
    s.serviceFloorBuilt=(s.workshopStep or 0)>=3
    if s.workshopStep==2 or s.workshopStep==3 then s.workshopStep=1 end
    if s.operationsStep==1 then s.operationsStep=0 end
    s.journeyVersion=9
   end
   if s.journeyVersion~=10 then
    s.salesDisplayBuilt=s.salesBuilt
    if (s.workshopStep or 0)==1 then s.workshopStep=2 end
    for _,key in {'panelBench','touchupKit','wheelTools','fluidKit','finishKit','partsShelves'}do if (s.workshopStep or 0)>=2 then s[key]=true end end
    if s.autoPurchased and not s.autoCycle then s.autoCycle={id=s.autoTradeId or 'AUTO-'..player.UserId,bought=900,repairs=s.autoRepairs or 0,fixes=s.autoFixes or {},sold=s.automationProfitAwarded and 2350 or nil,departed=s.automationDemoComplete}end
    s.journeyVersion=10
   end
   s.lotTrade=nil;s.rareQueued=nil
   s.firstTransit=nil;s.activeNegotiation=nil;s.allowedOptions=nil
   if s.specialist then s.specialist.negotiationActive=nil end
   if s.stage==3 and s.firstAtRepair then s.repairStarted=true end
   if s.pendingDeal then s.pendingDeal.departureStarted=nil end
   states[player]=s;loading[player]=nil
   if s.pendingDeal then finalizePendingDeal(player,s)end
  end
  updateWorld(s);sendState(player)
  if s.stage==3 and s.workshopStep>=4 and not s.firstAtRepair then Automation.TransferFirst(player,s,world,'Repair',function()return states[player]==s end,function()updateWorld(s);sendState(player)end)end
  if s.stage==4 and s.salesBuilt and not s.firstAtSales then Automation.TransferFirst(player,s,world,'Sales',function()return states[player]==s end,function()updateWorld(s);sendState(player)end)end
  if s.stage>=8 and not s.secondWorkComplete then Automation.StartSecond(player,s,world,function()updateWorld(s);sendState(player)end,function()return states[player]==s end)end
  if s.stage>=8 and s.operationsStep>=4 and not s.automationDemoComplete then runAutomationDemo(player,s)end
  if s.automationDemoComplete then Automation.StartRoutine(player,s,world,function()updateWorld(s);sendState(player)end,function(a,b)notify(player,a,b,"Green")end,function()return states[player]==s end)end
  return
 end
 if owner~=player or not s then return end
 if type(action)=="string"and Specialist.Action(player,s,world,event,action,function()updateWorld(s);sendState(player)end,function()return states[player]==s end,payload)then return end
 if type(action)~="string" then return end
 local customActions={SetCarType=true,SetCustomization=true,SetColor=true,RandomizeCustomization=true,UndoCustomization=true,CompleteCustomization=true}
 if customActions[action] and not near(player,world.PersonalGarage.PersonalCar.Body,26) then return end
 if s and s.firstTransit then return end
 if s and s.pendingDeal and action~="DealClosureDone" then return end
 local validatedTrade=false
 if action=='TradeCounter' or action=='TradeAccept' or action=='TradePause' then
  local key=s.activeNegotiation;local q=key and s.negotiations and s.negotiations[key]
  local kind=s.dialogueTarget
  local spec=({FirstSeller={2,'FirstSeller','FirstBuy'},FirstBuyer={4,'FirstBuyer','BuyerSell2350'},SecondSeller={7,'SecondSeller','SecondBuy'},RareSellerDeal={10,'RareSeller','RareBuy'}})[kind]
  local npc=spec and world:FindFirstChild(spec[2],true)
  if not spec or s.stage~=spec[1] or not near(player,npc and npc:FindFirstChild('Head')) or not Negotiation.Valid(q,payload) then return end
  if action=='TradePause' then closeDeal(player);sendState(player);return end
  if action=='TradeCounter' then
   if not Negotiation.Counter(q,payload) then return end
   if kind=='FirstSeller' then firstSellerDialogue(player,s,false)
   elseif kind=='FirstBuyer' then buyerDialogue(player,false)
   elseif kind=='SecondSeller' then secondSellerDialogue(player,false)
   else rareSellerDialogue(player,true,false) end
   sendState(player);return
  end
  validatedTrade=true;action=spec[3]
  -- Quote acceptance only authorizes this transaction. Legacy fixed-price actions stay disabled.
  s.activeNegotiation=nil;s.allowedOptions=nil
 end
 local dialogueActions={FirstAsk='FirstSeller',FirstBuy='FirstSeller',BuyerAsk='FirstBuyer',BuyerSell2350='FirstBuyer',BuyerSell2400='FirstBuyer',SecondAsk='SecondSeller',SecondBuy='SecondSeller',RareAsk='RareSeller',RareBuy='RareSeller',ShowRare='RareSeller'}
 if dialogueActions[action] and not validatedTrade then
  local target=world:FindFirstChild(dialogueActions[action],true)
  target=target and target:FindFirstChild('Head')
  if not s or not s.allowedOptions or not s.allowedOptions[action] or not near(player,target) then return end
 end

	if not s then return end

	if action == "ConfirmPadPurchase" then
		handlePadPurchase(player, s, payload)
		return
	elseif action == "Begin" and s.stage == 0 then
		advance(player, 1)
		return
	elseif action == "FirstAsk" and s.stage == 2 then
		firstSellerDialogue(player, s, true)
	elseif action == "FirstBuy" and s.stage == 2 then
		local price = s.firstAsk
		if s.cash < price or s.pendingDeal then firstSellerDialogue(player,s,false);return end
		s.cash -= price
		s.purchase = price
		s.carValue = price
		s.pendingDeal = { kind = "FirstBuy" }
  updateWorld(s)
		event:FireClient(player, "DealResolved", {
			kind = "Buy",
			amount = price,
			carName = Config.FirstCar.name,
			result = "OWNED",
		})
		sendState(player)
		local pending = s.pendingDeal
		task.delay(2.2, function()
			if states[player] == s and s.pendingDeal == pending then finalizePendingDeal(player, s) end
		end)
	elseif action == "BuyerAsk" then
		buyerDialogue(player, true)
	elseif action == "BuyerSell2350" then
		sellFirst(player, s.negotiations.FirstBuyer.price)
	elseif action == "BuyerSell2400" then
		sellFirst(player, 2400)
	elseif action == "KeepListed" or action == "CloseDialogue" then
		closeDeal(player)
		if s.stage == 10 and s.rareRoute == "Seller"
			and (s.rareTravelPhase == "AtSeller" or s.rareTravelPhase == "ReturnChoice") then
			s.rareTravelPhase = "ReturnChoice"
			sendState(player)
			task.delay(0.15, function()
				if states[player] == s and player.Parent then event:FireClient(player, "ReturnChoice") end
			end)
		end
	elseif action == "MeetBuyer" and s.stage == 4 and s.listed then
		s.buyerMet = true
		s.phone = nil
		updateWorld(s)
		sendState(player)
		notify(player, "BUYER ARRIVED", "Meet Marcus beside the car.", "Yellow")
	elseif action == "ViewSecond" and s.stage == 7 then
		s.secondVisible = true
		s.phone = nil
		updateWorld(s)
		sendState(player)
		notify(player, "LEAD PINNED", "Maya is waiting beside the Desert Coupe.", "Yellow")
	elseif action == "SecondAsk" and s.stage == 7 then
		secondSellerDialogue(player, true)
	elseif action == "SecondBuy" and s.stage == 7 then
		local price = s.secondAsk
		if s.cash < price then
			secondSellerDialogue(player,false)
			return
		end
		if s.pendingDeal then return end
		s.cash -= price
		s.secondPurchase=price
		s.pendingDeal = { kind = "SecondBuy" }
  updateWorld(s)
		event:FireClient(player, "DealResolved", {
			kind = "Buy",
			amount = price,
			carName = Config.SecondSeller.car,
			result = "OWNED",
		})
		sendState(player)
		local pending = s.pendingDeal
		task.delay(2.2, function()
			if states[player] == s and s.pendingDeal == pending then finalizePendingDeal(player, s) end
		end)
	elseif action == "SetCarType" and canCustomizePersonalCar(s) then
		if setCustomizationValue(s, "TYPE", payload) then sendState(player) end
	elseif action == "SetCustomization" and canCustomizePersonalCar(s) and typeof(payload) == "table" then
		if setCustomizationValue(s, payload.category, payload.value) then sendState(player) end
	elseif action == "SetColor" and canCustomizePersonalCar(s) then
		if setCustomizationValue(s, "PAINT", payload) then sendState(player) end
	elseif action == "RandomizeCustomization" and canCustomizePersonalCar(s) then
		randomizeCustomization(s)
		sendState(player)
	elseif action == "UndoCustomization" and canCustomizePersonalCar(s) then
		if undoCustomization(s) then sendState(player) end
	elseif action == "CompleteCustomization" and canCustomizePersonalCar(s) then
		-- Completing the finish is the sole gate for the private rare lead.
		s.stage = 10
		s.phone = "FutureLead"
		s.rarePhase = "Lead"
		s.rareRoute = nil
		s.rareTravelPhase = nil
		s.rareAsk = Config.RareSeller.ask
		s.rareOwned = false
		s.rareArrivalComplete = false
		updateWorld(s)
		sendState(player)
		task.delay(0.45, function()
			if states[player] == s and s.stage == 10 and s.phone == "FutureLead" and s.rarePhase == "Lead" then
				event:FireClient(player, "PhonePing", {
					title = "RARE LEAD",
					detail = "Unknown car · 0.2 mi · choose where to meet",
					autoOpen = true,
				})
			end
		end)
	elseif action == "StartDrive" and s.stage == 10
		and s.rareRoute == "Seller" and s.rareTravelPhase == "GetIn" then
		beginRareRouteDrive(player, s, "RareOutbound")
	elseif action == "DriveInput" and s.driving and typeof(payload) == "table" then
		s.driveThrottle = math.clamp((type(payload.throttle)=="number" and payload.throttle==payload.throttle and payload.throttle) or 0, 0, 1)
		s.driveSteer = math.clamp((type(payload.steer)=="number" and payload.steer==payload.steer and payload.steer) or 0, -1, 1)
	elseif action == "DriveToRareSeller" and s.stage == 10 and s.phone == "FutureLead" and s.rarePhase == "Lead" then
		s.phone = nil
		s.rareRoute = "Seller"
		s.rareAsk = Config.RareSeller.ask - 300
		s.rarePhase = "Travel"
		s.rareTravelPhase = "GetIn"
		s.rareArrivalComplete = false
		resetRareTransporter()
		updateWorld(s)
		sendState(player)
		notify(player, "MYSTERY ROUTE PINNED", "Get into your personal coupe. Yellow arrows lead to Elias.", "Yellow")
	elseif action == "DealClosureDone" then
		finalizePendingDeal(player, s)
	elseif action == "QuickReturn" and s.stage == 10 and s.rareRoute == "Seller"
		and s.rareTravelPhase == "ReturnChoice" then
		returnRareToLot(player, s)
	elseif action == "DriveBack" and s.stage == 10 and s.rareRoute == "Seller"
		and s.rareTravelPhase == "ReturnChoice" then
		beginRareRouteDrive(player, s, "RareReturn")
	elseif action == "RequestRareArrival" and s.stage == 10 and s.phone == "FutureLead" and s.rarePhase == "Lead" then
		s.phone = nil
		s.rareRoute = "Lot"
		s.rareTravelPhase = nil
		s.rareAsk = Config.RareSeller.ask
		s.rarePhase = "EnRoute"
		s.rareArrivalComplete = false
		local seller = world:FindFirstChild("RareSeller", true)
		if seller and seller:IsA("Model") then
			seller:PivotTo(CFrame.new(Vector3.new(-15,1.5,16)+IntegrationWorld.RareOffset))
		end
		resetRareTransporter()
		updateWorld(s)
		sendState(player)
		event:FireClient(player, "RareArrivalStart")
		task.spawn(animateRareArrival, player, s)
		-- A cinematic acknowledgement should improve pacing, never gate progression forever.
		local arrivalSet = world:FindFirstChild("RareArrival")
		local fallbackDelay = (arrivalSet and arrivalSet:GetAttribute("ArrivalDuration") or 3.4) + 0.8
		task.delay(fallbackDelay, function()
			if states[player] ~= s or s.stage ~= 10 or s.rarePhase ~= "EnRoute" then return end
			local transporter = arrivalSet and arrivalSet:FindFirstChild("Transporter")
			local endMarker = arrivalSet and arrivalSet:FindFirstChild("TransportEnd", true)
			if transporter and endMarker then transporter:PivotTo(endMarker.CFrame) end
			s.rareArrivalComplete = true
			s.rarePhase = "Revealing"
			updateWorld(s)
			sendState(player)
			event:FireClient(player, "RareReveal")
		end)
	elseif action == "RareArrivalReady" and s.stage == 10 and s.rarePhase == "EnRoute" then
		if not s.rareArrivalComplete then
			local set = world:FindFirstChild("RareArrival")
			local transporter = set and set:FindFirstChild("Transporter")
			local endMarker = set and set:FindFirstChild("TransportEnd", true)
			if transporter and endMarker then transporter:PivotTo(endMarker.CFrame) end
			s.rareArrivalComplete = true
		end
		s.rarePhase = "Revealing"
		updateWorld(s)
		sendState(player)
		event:FireClient(player, "RareReveal")
	elseif action == "ShowRare" and s.stage == 10 and s.rarePhase == "Waiting" then
		s.rarePhase = "Revealing"
		closeDeal(player)
		updateWorld(s)
		sendState(player)
		event:FireClient(player, "RareReveal")
	elseif action == "RareRevealDone" and s.stage == 10 and s.rarePhase == "Revealing" then
		s.rarePhase = "Revealed"
		updateWorld(s)
		sendState(player)
	elseif action == "RareAsk" and s.stage == 10 and s.rarePhase == "Revealed" then
		rareSellerDialogue(player, true, true)
	elseif action == "RareBuy" and s.stage == 10 and s.rarePhase == "Revealed" then
		if s.cash < s.rareAsk+(s.rareFocus and 500 or s.automationDemoComplete and 1400 or 500) then
			rareNeedCashDialogue(player)
			return
		end
		if s.pendingDeal then return end
		local amount = s.rareAsk
		s.cash -= amount
        s.rarePurchase=amount
		s.pendingDeal = { kind = "RareBuy" }
  updateWorld(s)
		event:FireClient(player, "DealResolved", {
			kind = "Buy",
			amount = amount,
			carName = Config.RareSeller.car,
			result = "OWNED",
		})
		sendState(player)
		local pending = s.pendingDeal
		task.delay(2.2, function()
			if states[player] == s and s.pendingDeal == pending then finalizePendingDeal(player, s) end
		end)

	end
end)

task.spawn(function()while true do task.wait(1);for player,s in states do if s.rareOwned and s.rareRoute=="Lot"and not s.pendingDeal and not s.rareSold then Specialist.Start(player,s,world,function()updateWorld(s);sendState(player)end,function()return states[player]==s end)end end end end)

RunService.Heartbeat:Connect(function(dt)
	for player, s in pairs(states) do
		if s.driving then
			local car = world:FindFirstChild("PersonalCar", true)
			if car and car.PrimaryPart then
				if s.driveThrottle > 0 then
					local cf = car:GetPivot()
					local turn = CFrame.Angles(0, -s.driveSteer * dt * 1.25, 0)
					cf = cf * turn
					cf += cf.LookVector * (s.driveThrottle * dt * 24)
					car:PivotTo(cf)
				end
				local position = car:GetPivot().Position
				if s.rareTravelPhase == "Driving" then
					local target = world:FindFirstChild("SellerDriveTarget", true)
					if target and (position - target.Position).Magnitude <= 10 then
						arriveAtRareSeller(player, s)
					end
				elseif s.rareTravelPhase == "DrivingHome" and (position - IntegrationWorld.PersonalHome).Magnitude <= 12 then
					returnRareToLot(player, s)
				end
			end
		end
	end
end)

local function joined(player)
 local function place(character)
  local root=character:WaitForChild('HumanoidRootPart',10)
  if root then character:PivotTo(IntegrationWorld.Spawn);root.AssemblyLinearVelocity=Vector3.zero end
  local s=states[player]
  if s then s.driving=false;event:FireClient(player,'CloseAll');updateWorld(s);sendState(player)end
 end
 player.RespawnLocation=world.PrototypeSpawn
 player.CharacterAdded:Connect(place)
 if player.Character then task.spawn(place,player.Character)end
end
Players.PlayerAdded:Connect(joined)
for _,p in Players:GetPlayers()do joined(p)end
Players.PlayerRemoving:Connect(function(player)
 local s=states[player]
 states[player]=nil
 if owner==player then owner=nil end
 if s then Save.Release(player,s)end
end)
task.spawn(function()while true do task.wait(30);for p,s in states do Save.Write(p,s)end end end)
print('[Integration INT012] Trading flow ready')

