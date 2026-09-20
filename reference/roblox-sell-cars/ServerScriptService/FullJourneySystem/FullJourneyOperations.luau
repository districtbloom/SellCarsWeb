-- Per-plot dealership operations. Routes reproduce Integration's opening lane;
-- permanent departments use its authored service centers after they are earned.
-- All source-world positions pass through the plot transform, including NPCs.
local Operations = {}
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Movement = require(script.Parent.FullJourneyMovement)
local CarVisuals = require(game.ServerScriptService.TycoonSystem.JunkLot.CarVisuals)
local DealerCarConfig = require(game.ReplicatedStorage.DealerCarConfig)
local VehicleIntegrationCatalog = require(game.ReplicatedStorage.VehicleIntegrationCatalog)
local FullJourneyCatalog = require(script.Parent.FullJourneyCatalog)
local HttpService = game:GetService("HttpService")
local active = {}
local function event(s,name,payload)
	if s.hooks.event then s.hooks.event(name,payload or {}) end
end

-- PreviewRules' department z is the split between bays. The first earned bay
-- is 12 studs forward of that split (the composer's shell-review contract).
local DEPARTMENTS = {
	{key = "Wash", title = "Wash", first = 41, staff = 42, x = 3023, z = 132},
	{key = "Body_Restoration", title = "Body restoration", first = 46, staff = 89, x = 3023, z = 251},
	{key = "Tune_Performance", title = "Performance tune", first = 51, staff = 95, x = 3023, z = 319},
	{key = "Paint_Exterior", title = "Paint finish", first = 49, staff = 101, x = 3187, z = 319},
	{key = "Detail_QC", title = "Detail and quality check", first = 43, staff = 105, x = 3187, z = 251},
	{key = "Photo_Listing", title = "Listing photos", first = 60, staff = 108, x = 3187, z = 187},
}
local HOME = {
	Intake = Vector3.new(3017, 1.65, 96),
	Sales = Vector3.new(3066, 1.65, 86),
	Mechanic = Vector3.new(3033, 1.65, 138),
}

local function alive(s)
	return active[s.record] == s and not s.stopped and s.folder.Parent ~= nil
		and s.record.owner == s.owner and s.owner.Parent ~= nil
end
local function step(s)
	return math.clamp(tonumber(s.hooks.getStep()) or 0, 0, 240)
end
local function world(s, p)
	return s.record.origin:PointToWorldSpace(s.record.sourceOrigin:PointToObjectSpace(p))
end
local function frame(s, sourceFrame)
	return s.record.origin * s.record.sourceOrigin:ToObjectSpace(sourceFrame)
end
local function waitValid(s, seconds)
	local finish = os.clock() + seconds / s.speed
	while alive(s) and os.clock() < finish do task.wait(math.clamp(finish - os.clock(), 0, .15)) end
	return alive(s)
end
local function publish(s, title, hint)
	if not alive(s) then return end
	s.status, s.hint = title, hint or ""
	s.record.folder:SetAttribute("OperationStatus", title)
	s.record.folder:SetAttribute("OperationHint", s.hint)
	s.record.folder:SetAttribute("OperationPhase", s.phase or "Waiting")
	if s.car then s.car:SetAttribute("BusinessStatus", title) end
	if s.label then s.label.Text = title .. (s.hint ~= "" and "\n" .. s.hint or "") end
	if s.hooks.changed then s.hooks.changed() end
end
local function disablePrompts(s)
	for _, p in pairs(s.prompts) do p.Enabled = false end
end
local function action(s, id, text, title, hint)
	disablePrompts(s)
	s.expectedAction = id
	local p = s.prompts[id]
	if p then p.ActionText = text; p.Enabled = true end
	publish(s, title, hint)
end
local function rigTemplate(role, override)
	if override and override:IsA("Model") then return override end
	local repair = ServerStorage:FindFirstChild("RepairBay_New_Template")
	if repair then
		local preferred = role == "Mechanic" and "MechanicNPC_Bay1" or "CheckoutClerkNPC"
		local model = repair:FindFirstChild(preferred, true)
		if model and model:IsA("Model") then return model end
	end
	local source = ServerStorage:FindFirstChild("SellCars_Dealership_FullJourney")
	local cast = source and source:FindFirstChild("R6_Cast", true)
	if cast then
		local model = cast:FindFirstChild(role == "Mechanic" and "Mechanical_1" or role == "Sales" and "SalesAdvisor" or "Seller")
		if model and model:IsA("Model") then return model end
	end
	return nil
end
local function sanitize(model, rig)
	local root = model:FindFirstChild("HumanoidRootPart", true)
	for _, descendant in ipairs(model:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(descendant)) do CollectionService:RemoveTag(descendant, tag) end
		if descendant:IsA("LuaSourceContainer") or descendant:IsA("ProximityPrompt")
			or descendant:IsA("ClickDetector") or descendant:IsA("LayerCollector") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = not rig or descendant == root or root == nil
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
	for _, tag in ipairs(CollectionService:GetTags(model)) do CollectionService:RemoveTag(model, tag) end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.AutoRotate = false
		humanoid.BreakJointsOnDeath = false
	end
	-- Seats are also BaseParts and therefore need their own pass.
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("Seat") or item:IsA("VehicleSeat") then item.Disabled = true end
	end
	return model
end
local function billboard(part, name, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(270, 72)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(23, 32, 39)
	label.BackgroundTransparency = .12
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(245, 245, 230)
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 9); corner.Parent = label
	return label
end
local function anchor(s, name, sourcePoint)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Position = world(s, sourcePoint + Vector3.new(0, 2, 0))
	part.Parent = s.folder
	return part
end
local function makeRig(s, name, sourcePoint, role)
	local template = rigTemplate(role, s.hooks.npcTemplate)
	if not template then return nil end
	local model = sanitize(template:Clone(), true)
	model.Name = name
	model.Parent = s.folder
	s.rigs[model] = true
	Movement.prepareNPC(model,frame(s,CFrame.new(sourcePoint)),name)
	model:SetAttribute("StaffJob", "Ready")
	return model
end
local function destroyRig(s, model)
	if model then s.rigs[model]=nil;Movement.destroyNPC(model) end
end
local function walk(s, model, position, face)
	if not model then return alive(s) end
	local p = position
	local target = face and Vector3.new(face.X, p.Y, face.Z) or p + Vector3.new(0, 0, -1)
	if (target - p).Magnitude < .01 then target = p + Vector3.new(0, 0, -1) end
	return Movement.walkNPC(model,frame(s,CFrame.lookAt(p,target)),function() return alive(s) end,s.speed)
end

-- CIRC02 from Integration, sampled at 3 studs while preserving turning arcs.
local function buildRoutes()
	local routes = {}
	local function line(out, x, z, X, Z, hx, hz)
		local n = math.max(1, math.ceil(Vector2.new(X-x, Z-z).Magnitude / 3))
		for i = 0, n do
			local t = i / n; local p = Vector3.new(x+(X-x)*t, 1.65, z+(Z-z)*t)
			table.insert(out, CFrame.lookAt(p, p+Vector3.new(hx, 0, hz)))
		end
	end
	local function arc(out, x, z, r, a, b, reverse)
		a, b = math.rad(a), math.rad(b)
		local n = math.max(1, math.ceil(math.abs(b-a)*r / 3)); local sign = b > a and 1 or -1
		for i = 0, n do
			local t = a + (b-a)*i/n; local p = Vector3.new(x+r*math.cos(t), 1.65, z+r*math.sin(t))
			local h = Vector3.new(-math.sin(t)*sign, 0, math.cos(t)*sign)*(reverse and -1 or 1)
			table.insert(out, CFrame.lookAt(p, p+h))
		end
	end
	local a = {}; routes.arrival = a
	line(a,3076,8,3076,17,0,1); arc(a,3063,17,13,0,90); line(a,3063,30,3021,30,-1,0)
	arc(a,3021,43,13,-90,-180); line(a,3008,43,3008,88,0,1)
	local w = {}; routes.work = w
	line(w,3008,88,3008,90,0,1); arc(w,3021,90,13,180,90); line(w,3021,103,3060,103,1,0)
	arc(w,3060,117.5,14.5,-90,0); arc(w,3060,117.5,14.5,0,90); line(w,3060,132,3041,132,-1,0)
	local sales = {}; routes.sales = sales
	line(sales,3041,132,3060,132,-1,0); arc(sales,3060,117.5,14.5,90,0,true)
	line(sales,3074.5,117.5,3074.5,96,0,-1); line(sales,3074.5,96,3073,82,0,-1)
	local exit = {}; routes.exit = exit; line(exit,3073,82,3073,8,0,-1)
	return routes
end
local ROUTES = buildRoutes()
local function travel(s, route, text)
	publish(s, text, "Follow your car through the dealership")
	local transformed={}
	for _, sourceFrame in ipairs(route) do
		if not alive(s) or not s.car then return false end
		transformed[#transformed+1]=frame(s,sourceFrame+Vector3.new(0,s.carHeight,0))
	end
	return Movement.driveCar(s.car,transformed,function() return alive(s) end,{
		speedMultiplier=s.speed,departure=s.phase=="Departing",
	})
end
local function laneRoute(s, x, z)
	local current = s.record.sourceOrigin:PointToWorldSpace(s.record.origin:PointToObjectSpace(s.car:GetPivot().Position))
	local out = {}
	local function point(X, Z)
		local p = Vector3.new(X, 1.65, Z)
		local from = #out > 0 and out[#out].Position or Vector3.new(current.X, 1.65, current.Z)
		local direction = p-from
		if direction.Magnitude > .01 then table.insert(out, CFrame.lookAt(p, p+direction.Unit)) end
	end
	local oldLane = current.X < 3105 and 3074.5 or 3135.5
	local newLane = x < 3105 and 3074.5 or 3135.5
	point(oldLane, current.Z)
	-- Rear cross-lane avoids the central courtyard when moving between wings.
	if oldLane ~= newLane then point(oldLane, 373); point(newLane, 373) end
	point(newLane, z); point(x, z)
	return out
end
local function makeCar(s)
	s.deal=s.hooks.getTutorialDeal and s.hooks.getTutorialDeal() or nil
	s.tutorialDealIndex=s.deal and 1 or 0
	local choices=step(s)>=90 and {"Bavora","HondoCivixEK","Rusty"} or {"Rusty","HondoCivixEK"}
	for _, id in ipairs(VehicleIntegrationCatalog.fullJourneyAdditions(step(s), FullJourneyCatalog.Entries)) do
		if VehicleIntegrationCatalog[id].channels.dealerRepair and not table.find(choices, id) then
			table.insert(choices, id)
		end
	end
	s.templateId=s.deal and (s.deal.carId or "Rusty") or choices[(s.sold%#choices)+1]
	s.tradeId=tostring(s.owner.UserId)..":FJ:"..HttpService:GenerateGUID(false)
	s.parts=s.deal and {Body=true,Engine=false,Wheels=false} or {Body=false,Engine=false,Wheels=false}
	s.accepted=false;s.haggleUsed=false;s.saleHaggleUsed=false;s.rejected=false;s.currentPart=nil;s.tradeState="Offered"
	s.ask=s.deal and 25 or 200+math.floor(step(s)/10)*50
	local cars=s.record.folder:FindFirstChild("DealerCars") or Instance.new("Folder")
	cars.Name="DealerCars";cars.Parent=s.record.folder
	local model=CarVisuals.spawn(s.templateId,frame(s,ROUTES.arrival[1]),cars)
	assert(model,"Missing Sell Cars vehicle source")
	local cf, size = model:GetBoundingBox()
	s.carHeight = model:GetPivot().Y - (cf.Y - size.Y/2) + .1
	Movement.prepareCar(model,frame(s,ROUTES.arrival[1]+Vector3.new(0,s.carHeight,0)))
	model:SetAttribute("OwnerUserId", s.owner.UserId)
	model:SetAttribute("TradeId",s.tradeId);model:SetAttribute("DealerJourneyTradeId",s.tradeId)
	model:SetAttribute("DealerSlot","working");model:SetAttribute("WorkingSlotIndex",1)
	model:SetAttribute("State","Offered");model:SetAttribute("Arriving",true)
	CarVisuals.applyCondition(model,s.parts,false,false,false,s.deal and {"FL"} or nil)
	s.car = model
	return model
end
local function waitStep(s, needed, title)
	while alive(s) and step(s) < needed do
		publish(s, title, "Buy journey upgrade " .. needed .. " to continue this car")
		if not waitValid(s, .6) then return false end
	end
	return alive(s)
end
local function awaitAction(s, id, staffStep, title, hint)
	s.phase = id
	s.acknowledged = false
	action(s, id, title, title, hint)
	while alive(s) and not s.acknowledged and (not staffStep or step(s) < staffStep) do
		if not waitValid(s, .15) then return false end
	end
	disablePrompts(s); s.expectedAction = nil
	return alive(s)
end
local function ensureStaff(s)
	local n = step(s)
	if n >= 29 and not s.staff.Intake then s.staff.Intake = makeRig(s,"CarBuyer",HOME.Intake,"Intake") end
	if n >= 33 and not s.staff.Sales then s.staff.Sales = makeRig(s,"SalesAdvisor",HOME.Sales,"Sales") end
	if n >= 6 and not s.staff.Manny then s.staff.Manny=makeRig(s,"Manny",Vector3.new(3055,1.65,89),"Sales") end
	if n >= 40 and not s.staff.Mechanic then
		local p = n >= 35 and Vector3.new(3018,1.65,181) or HOME.Mechanic
		s.staff.Mechanic = makeRig(s,"Mechanic",p,"Mechanic")
	end
end
local function service(s, title, position, staffThreshold, role,partId)
	local entranceSide = position.X < 3105 and 1 or -1
	local home = position + Vector3.new(entranceSide*10,0,-6)
	local oldPrompt=s.prompts.Service
	if oldPrompt then oldPrompt:Destroy() end
	s.currentPart=partId
	if partId then
		CarVisuals.attachRepairPrompt(s.car,partId,DealerCarConfig.displayName(s.templateId),1.2,function(player)
			Operations.act(s.record,player,"Service")
		end)
		s.prompts.Service=s.car:FindFirstChild(DealerCarConfig.REPAIR_PROMPT_NAME,true)
	else
		local host=s.folder:FindFirstChild("ServiceInteraction")
		host.Position=world(s,position+Vector3.new(entranceSide*10,2,-6))
		local prompt=Instance.new("ProximityPrompt");prompt.Name="HoodServicePrompt";prompt.ObjectText=title
		prompt.HoldDuration=1.2;prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false;prompt.Parent=host
		s.prompts.Service=prompt
		table.insert(s.connections,prompt.Triggered:Connect(function(player)Operations.act(s.record,player,"Service")end))
	end
	s.tradeState="Repairing"
	if not awaitAction(s, "Service", staffThreshold, title, "Hold E by the car to complete this service") then return false end
	local worker = role == "Mechanical" and s.staff.Mechanic or s.specialists[role]
	if not worker and step(s) >= staffThreshold then
		worker = makeRig(s, role .. "Specialist", home, "Mechanic")
		s.specialists[role] = worker
	end
	if worker then
		worker:SetAttribute("StaffJob", title)
		if not walk(s, worker, position + Vector3.new(entranceSide*5,0,-6), position) then return false end
	end
	publish(s, title .. " in progress", "Your vehicle is being prepared")
	if worker then
		local animation=title=="Repair body" and "repairBody" or title=="Repair wheels" and "repairWheels"
			or title=="Repair engine" and "repairEngine" or "work"
		Movement.playNPC(worker,animation)
	end
	if not waitValid(s, math.max(1, 3 - step(s)/120)) then return false end
	if worker then
		-- Cars enter across X; keep staff outside their width and walk around an
		-- end instead of cutting diagonally through the bonnet and cabin.
		if not walk(s, worker, position + Vector3.new(entranceSide*10,0,-6), position) then return false end
		if not walk(s, worker, position + Vector3.new(entranceSide*10,0,6), position) then return false end
		if not walk(s, worker, position + Vector3.new(entranceSide*5,0,6), position) then return false end
		if not waitValid(s, .7) then return false end
		if not walk(s, worker, position + Vector3.new(entranceSide*10,0,6), position) then return false end
		if not walk(s, worker, home, position) then return false end
		worker:SetAttribute("StaffJob", "Ready for next car")
	end
	s.services += 1
	if partId then
		s.parts[partId]=true
		CarVisuals.applyCondition(s.car,s.parts,CarVisuals.allPartsRepaired(s.parts),true,false,s.deal and {"FL"} or nil)
		event(s,"PartFixed",{partId=partId,tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex})
	end
	s.currentPart=nil
	publish(s,title.." complete","")
	return alive(s)
end
local function cycle(s)
	if not waitStep(s,2,"Set up the seller corner") then return false end
	ensureStaff(s)
	s.deposit,s.paid,s.services=0,false,0
	s.phase="Arriving"
	makeCar(s)
	s.seller=Movement.addDriver(s.car)
	if s.seller then s.rigs[s.seller]=true end
	if not travel(s,ROUTES.arrival,"A seller is arriving") then return false end
	if s.seller then
		Movement.unseatDriver(s.seller,s.folder,frame(s,CFrame.new(3008,1.65,97)),"idle")
		s.seller.Name="Seller"
	else s.seller=makeRig(s,"Seller",Vector3.new(3008,1.65,97),"Intake") end
	s.car:SetAttribute("Arriving",false)
	if s.seller then
		s.seller:SetAttribute("DealerSellerOwnerUserId",s.owner.UserId)
		s.seller:SetAttribute("DealerSellerTradeId",s.tradeId)
	end
	if not walk(s,s.seller,HOME.Intake,Vector3.new(3008,1.65,88)) then return false end
	event(s,"CarArrived",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex})
	local canBuy=s.hooks.getCash()>=s.ask+(s.deal and 0 or 50)
	if not canBuy and not s.deal then s.ask=0 end
	if not awaitAction(s,"Buy",if s.deal then nil else 29,"Talk to seller","Meet the seller and choose your deal") then return false end
	if s.rejected then
		if s.seller then destroyRig(s,s.seller);s.seller=nil end
		s.phase="Departing";s.tradeState="None";publish(s,"Seller leaving","Another seller will arrive shortly")
		if not travel(s,laneRoute(s,3073,8),"Seller leaving") then return false end
		s.car:Destroy();s.car=nil
		return waitValid(s,3)
	end
	if s.ask>0 and s.deposit==0 then
		-- Staff purchases reserve capital here; manual purchases reserve it in
		-- the validated action before acknowledging the original dialogue.
		if s.hooks.spend(s.ask) then s.deposit=s.ask
		else s.ask=0 end -- A free consignment keeps automated intake moving.
	end
	s.accepted=true;s.tradeState="Junk"
	s.car:SetAttribute("TradeType",s.deposit>0 and "Owned" or "Consignment")
	event(s,"CarBought",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex,paid=s.deposit})
	publish(s,"Car purchased","Set up your repair tools")
	if not waitStep(s,3,"Your car needs a repair kit") then return false end
	local repairPosition=step(s)>=35 and Vector3.new(3008,1.65,187) or Vector3.new(3041,1.65,132)
	if s.seller then Movement.seatDriver(s.seller,s.car) end
	if not travel(s,step(s)>=35 and laneRoute(s,repairPosition.X,repairPosition.Z) or ROUTES.work,"Moving to the repair bay") then return false end
	if s.seller then
		Movement.unseatDriver(s.seller,s.folder,frame(s,CFrame.new(repairPosition+Vector3.new(10,0,-6))),"idle")
		if not walk(s,s.seller,Vector3.new(3017,1.65,35),Vector3.new(3017,1.65,8)) then return false end
		destroyRig(s,s.seller);s.seller=nil
	end
	local partOrder=s.deal and {"Engine","Wheels"} or {"Body","Wheels","Engine"}
	for _,partId in partOrder do
		if step(s)>=35 and repairPosition.Z<180 then
			repairPosition=Vector3.new(3008,1.65,187)
			if not travel(s,laneRoute(s,repairPosition.X,repairPosition.Z),"Moving to the new mechanical bay") then return false end
		end
		ensureStaff(s)
		if not service(s,"Repair "..partId:lower(),repairPosition,s.deal and math.huge or 40,"Mechanical",partId) then return false end
	end
	s.tradeState="Ready"
	event(s,"RepairCompleted",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex})
	for _,department in DEPARTMENTS do
		if step(s)>=department.first then
			if not travel(s,laneRoute(s,department.x,department.z),"Moving to "..department.title:lower()) then return false end
			if not service(s,department.title,Vector3.new(department.x,1.65,department.z),department.staff,department.key) then return false end
		end
	end
	s.tradeState="Ready";s.phase="Ready";publish(s,"Repairs complete","Prepare your listing and hire Manny")
	if not waitStep(s,5,"Set up phone-photo listing") then return false end
	if not waitStep(s,6,"Hire Manny at the sales desk") then return false end
	ensureStaff(s)
	local driver=s.staff.Manny
	if driver then
		local sourcePos=s.record.sourceOrigin:PointToWorldSpace(s.record.origin:PointToObjectSpace(s.car:GetPivot().Position))
		if not walk(s,driver,Vector3.new(sourcePos.X+10,1.65,sourcePos.Z-6),sourcePos) then return false end
		Movement.seatDriver(driver,s.car)
	end
	s.phase="Transporting";s.tradeState="Ready";s.car:SetAttribute("ListingTransport","Manny")
	publish(s,"Manny is taking the car to sales","Follow Manny to the handover space")
	local sourcePosition=s.record.sourceOrigin:PointToWorldSpace(s.record.origin:PointToObjectSpace(s.car:GetPivot().Position))
	local atOpeningRepair=Vector2.new(sourcePosition.X-3041,sourcePosition.Z-132).Magnitude<3
	if not travel(s,atOpeningRepair and ROUTES.sales or laneRoute(s,3073,82),"Manny is taking the car to sales") then return false end
	if driver then
		Movement.unseatDriver(driver,s.folder,frame(s,CFrame.new(3066,1.65,82)),"idle")
		if not walk(s,driver,Vector3.new(3055,1.65,89),Vector3.new(3073,1.65,82)) then return false end
	end
	s.car:SetAttribute("DealerSlot","display");s.car:SetAttribute("DisplaySlotIndex",1)
	s.car:SetAttribute("ListingTransport",nil)
	s.phase="Listed";s.tradeState="Listed"
	event(s,"CarListed",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex})
	publish(s,"Car listed","A buyer is on the way")
	repeat
		s.rejected=false
		s.buyer=makeRig(s,"Customer",Vector3.new(3061,1.65,35),"Sales")
		if s.buyer then
			s.buyer:SetAttribute("DealerBuyerOwnerUserId",s.owner.UserId)
			s.buyer:SetAttribute("DealerBuyerTradeId",s.tradeId)
		end
		if not walk(s,s.buyer,Vector3.new(3061,1.65,82),Vector3.new(3073,1.65,82)) then return false end
		s.profit=math.floor(150+step(s)*14+s.services*35+math.pow(step(s),1.35)*3)
		if s.deposit==0 then s.profit=math.floor(s.profit*.75) end
		s.saleOffer=s.deal and (s.deal.fixedOffer or 1000) or s.deposit+s.profit
		s.tradeState="Offer";s.saleHaggleUsed=false
		event(s,"OfferReceived",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex,currentOffer=s.saleOffer})
		if not awaitAction(s,"Sell",if s.deal then nil else 33,"Speak to buyer","Review the buyer's offer on your phone") then return false end
		if s.rejected then
			s.phase="Listed";s.tradeState="Listed";publish(s,"Waiting for another buyer","The car remains listed")
			if not walk(s,s.buyer,Vector3.new(3061,1.65,35)) then return false end
			destroyRig(s,s.buyer);s.buyer=nil
			if not waitValid(s,2) then return false end
		end
	until not s.rejected
	local paid=s.saleOffer
	s.paid=true;s.profit=paid-s.deposit;s.tradeState="Sold"
	s.sold+=1
	s.record.folder:SetAttribute("CarsSold",s.sold)
	s.record.folder:SetAttribute("LastSaleProfit",s.profit)
	s.hooks.credit(paid)
	event(s,"CarSold",{tradeId=s.tradeId,tutorialDealIndex=s.tutorialDealIndex,carName=DealerCarConfig.displayName(s.templateId),paid=paid,cost=s.deposit,profit=s.profit})
	if s.buyer then Movement.seatDriver(s.buyer,s.car) end
	s.phase="Departing"
	if not travel(s,ROUTES.exit,"Sold · profit $"..s.profit) then return false end
	if s.buyer then destroyRig(s,s.buyer);s.buyer=nil end
	s.car:Destroy();s.car=nil;s.deposit=0;s.tradeState="None"
	publish(s,"Sale complete","Your next seller is on the way")
	return waitValid(s,math.max(3,10-step(s)/30))
end

function Operations.canAct(record, player, id,phone)
	local s = active[record]
	if not s or not alive(s) or player ~= s.owner or id ~= s.expectedAction or s.acknowledged then return false end
	local prompt = s.prompts[id]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not prompt or not prompt.Enabled or not root or not humanoid or humanoid.Health<=0 then return false end
	local position=prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition or prompt.Parent.Position
	if not (phone==true and id=="Sell") and (root.Position-position).Magnitude>prompt.MaxActivationDistance+3 then return false end
	return true
end
function Operations.act(record,player,id,phone)
	if not Operations.canAct(record,player,id,phone) then return false end
	local s=active[record]
	if id=="Buy" and not s.rejected and s.ask>0 then
		if not s.hooks.spend(s.ask) then return false end
		s.deposit=s.ask
	end
	s.acknowledged = true
	disablePrompts(s)
	return true
end
function Operations.reject(record,player,id,phone)
	if not Operations.canAct(record,player,id,phone) then return false end
	active[record].rejected=true
	return Operations.act(record,player,id,phone)
end
function Operations.getRuntime(record) return active[record] end
function Operations.getState(record)
	local s = active[record]
	if not s then return nil end
	return {phase=s.phase,status=s.status,hint=s.hint,action=s.expectedAction,carsSold=s.sold,
		deposit=s.deposit or 0,profit=s.profit or 0,services=s.services or 0,tradeId=s.tradeId,
		tutorialDealIndex=s.tutorialDealIndex,parts=s.parts,currentPart=s.currentPart,tradeState=s.tradeState,
		car=s.car,seller=s.seller,buyer=s.buyer}
end
function Operations.refresh(record)
	local s = active[record]
	if s and alive(s) then ensureStaff(s) end
end
function Operations.stop(record)
	local s = active[record]
	if not s then return end
	s.stopped = true
	active[record] = nil
	for _, connection in ipairs(s.connections) do connection:Disconnect() end
	for rig in pairs(s.rigs) do Movement.destroyNPC(rig) end
	table.clear(s.rigs)
	-- Root calls stop before saving/releasing the owner; recover reserved capital.
	if not s.paid and (s.deposit or 0) > 0 then s.hooks.credit(s.deposit); s.deposit = 0 end
	if s.hooks.closed then s.hooks.closed() end
	if s.car then s.car:Destroy();s.car=nil end
	if s.folder then s.folder:Destroy() end
	record.folder:SetAttribute("OperationStatus",nil)
	record.folder:SetAttribute("OperationHint",nil)
	record.folder:SetAttribute("OperationPhase",nil)
end
function Operations.start(record, hooks)
	Operations.stop(record)
	if not record.owner then return nil end
	local folder = Instance.new("Folder"); folder.Name = "FullJourneyOperations"; folder.Parent = record.folder
	local s = {record=record,hooks=hooks,folder=folder,owner=record.owner,connections={},prompts={},
		staff={},specialists={},rigs={},sold=0,phase="Waiting",speed=math.clamp(tonumber(hooks.speedMultiplier) or 1,.1,100)}
	active[record] = s
	record.folder:SetAttribute("CarsSold",0)
	record.folder:SetAttribute("LastSaleProfit",nil)
	for id, position in pairs({Buy=HOME.Intake,Service=Vector3.new(3048,1.65,130),Sell=HOME.Sales}) do
		local part = anchor(s,id.."Interaction",position)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FullJourney"..id
		prompt.ObjectText = id == "Buy" and "Seller" or id == "Sell" and "Customer" or "Vehicle service"
		prompt.ActionText = id
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 13
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = id == "Service" and .65 or .3
		prompt.Enabled = false
		prompt.Parent = part
		s.prompts[id] = prompt
		table.insert(s.connections,prompt.Triggered:Connect(function(player)
			if id=="Buy" and hooks.openBuy then hooks.openBuy(player)
			elseif id=="Sell" and hooks.openOffer then hooks.openOffer(player)
			else Operations.act(record,player,id) end
		end))
	end
	-- Original Sell Cars HUD, prompts, dialogue and car billboards own presentation.
	ensureStaff(s)
	task.spawn(function()
		while alive(s) do
			local ok, result = xpcall(function() return cycle(s) end,debug.traceback)
			if not ok then
				warn("[FullJourneyOperations] "..tostring(result))
				publish(s,"Operations paused","The next seller will retry shortly")
				if not s.paid and (s.deposit or 0) > 0 then hooks.credit(s.deposit) end
				s.deposit = 0
				if s.car then s.car:Destroy();s.car=nil end
				for _,key in ipairs({"seller","buyer"}) do if s[key] then destroyRig(s,s[key]);s[key]=nil end end
				if not waitValid(s,3) then break end
			elseif not result then break end
		end
	end)
	return s
end
Operations.Departments = DEPARTMENTS
return Operations
