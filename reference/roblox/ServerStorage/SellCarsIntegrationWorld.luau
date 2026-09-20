local M={}
local SS=game:GetService('ServerStorage')
local Journey=require(game.ReplicatedStorage.CoreUX.BusinessJourney)
local composer=require(SS.SellCarsIntegrationOpeningComposer)
local lastStep=-1
local base=Vector3.new(3100,1.65,100)
M.RareOffset=base
M.PersonalHome=Vector3.new(3166,1.65,31)
M.Spawn=CFrame.lookAt(Vector3.new(3035,5.4,96),Vector3.new(3035,5.4,112))
local function move(o,delta)
 for _,p in o:GetDescendants() do
  if p:IsA('BasePart') then
   p.CFrame+=delta
   local home=p:GetAttribute('CinematicHome');if home then p:SetAttribute('CinematicHome',home+delta) end
  end
 end
 if o:IsA('BasePart') then o.CFrame+=delta end
end
local function shift(o,from,to) move(o,to-from) end
local function suppress(o)
 if not o then return end
 o:SetAttribute('IntegrationHidden',true)
 for _,p in o:GetDescendants() do
  if p:IsA('BasePart')then p.Transparency=1;p.CanCollide=false;p.CanQuery=false;p:SetAttribute('ShownTransparency',1);p:SetAttribute('ShownCollision',false)
  elseif p:IsA('LayerCollector')then p.Enabled=false end
 end
 if o:IsA('BasePart')then o.Transparency=1;o.CanCollide=false;o:SetAttribute('ShownTransparency',1);o:SetAttribute('ShownCollision',false)end
end
function M.Build(w)
 -- New construction purchases reuse existing pad geometry; only metadata drives their behavior.
 for _,p in Journey.Pads do if not Journey.Find(w,p.path)then
  local parentName,name=p.path:match('^([^%.]+)%.(.+)$');local pad=w.Workshop.FoundationPad:Clone();pad.Name=name;pad.Parent=w[parentName];pad:SetAttribute('PadId',p.id)
 end end
 local status=Instance.new('BillboardGui');status.Name='CarReadiness';status.Size=UDim2.fromOffset(254,42);status.StudsOffsetWorldSpace=Vector3.new(0,5,0);status.AlwaysOnTop=true;status.MaxDistance=40;status.Parent=w.FirstDeal.FirstCar.Body
 local label=Instance.new('TextLabel');label.Name='Status';label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(244,241,227);label.TextColor3=Color3.fromRGB(30,39,42);label.Font=Enum.Font.GothamBold;label.TextSize=15;label.Text='NEEDS REPAIRS';label.BorderSizePixel=0;label.Parent=status
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=label
 local edge=Instance.new('UIStroke');edge.Color=Color3.fromRGB(30,39,42);edge.Thickness=2;edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;edge.Parent=label
 composer.SetStep(0);lastStep=0
 local proxy=workspace:FindFirstChild('CIRC02_Temporary_Route_Proxy');if proxy then proxy.Parent=SS end
 for _,o in w:GetChildren()do
  if o:IsA('BasePart') and o.Name~='PrototypeSpawn' then o:Destroy() end
 end
 for _,o in {w:FindFirstChild('ArrivalSign'),w:FindFirstChild('FinishGate'),w:FindFirstChild('OpeningCinematic')}do if o then o:Destroy()end end
 shift(w.LotEntrance,Vector3.new(-67,0,-7),Vector3.new(3035,1.65,112))
 for _,o in w.LotEntrance:GetChildren()do if o.Name~='OpenAnchor' then suppress(o)end end
 shift(w.DealStation,Vector3.new(-51,0,-7),Vector3.new(3022,1.65,92));suppress(w.DealStation.Furniture)
 shift(w.FirstDeal,Vector3.new(-35,0,0),Vector3.new(3008,1.65,88))
 move(w.FirstDeal.FirstSeller,Vector3.new(9,0,8))
 shift(w.FirstBuyer,Vector3.new(-24,0,-8),Vector3.new(3061,1.65,76))
 local buyerCar=w.FirstBuyer:FindFirstChild('BuyerCar');if buyerCar then buyerCar:Destroy()end
 shift(w.Workshop,Vector3.new(5,0,0),Vector3.new(3041,1.65,132))
 move(w.Workshop.Mechanic,Vector3.new(-8,0,6))
 for _,n in {'Foundation','Approach','ServiceSlab','Lift'}do suppress(w.Workshop:FindFirstChild(n))end
 shift(w.SecondDeal,Vector3.new(39,0,-15),Vector3.new(3008,1.65,88))
 move(w.SecondDeal.SecondSeller,Vector3.new(9,0,8))
 shift(w.Operations,Vector3.new(31,0,6),Vector3.new(3020,1.65,57))
 suppress(w.Operations.AppraisalPosition);suppress(w.Operations.AppraisalPad)
 shift(w.Operations.SalesPosition,Vector3.new(3039,1.65,57),Vector3.new(3061,1.65,82))
 shift(w.Operations.SalesRep,Vector3.new(3039,1.65,63),Vector3.new(3066,1.65,86))
 shift(w.PersonalGarage,Vector3.new(69,0,3),M.PersonalHome)
 suppress(w.PersonalGarage:FindFirstChild('GarageSign'))
 move(w.RareArrival,base)
 for _,p in w:GetDescendants()do
  if p:IsA('BasePart') and p:GetAttribute('PadId')then
   p:SetAttribute('IntegrationPad',true)
   p.CanCollide=false;p:SetAttribute('ShownCollision',false)
  end
 end
 local pads={FoundationPad={3015,111},ApproachPad={3042,115},ServiceSlabPad={3056,110},LiftPad={3001,146},HirePad={3033,122},AppraisalPad={3020,57},CarBuyerPad={3012,64},SalesPositionPad={3060,83},SalesRepPad={3060,95},ClaimPad={3166,31}}
 for name,v in pads do local p=w:FindFirstChild(name,true);if p then shift(p,p.Position,Vector3.new(v[1],1.9,v[2])) end end
 local extraPads={ToolsPad={3020,142},PowerPad={3011,146},SalesDeskPad={3060,72},PanelBenchPad={3022,158},TouchupKitPad={3033,158},WheelToolsPad={3044,158},FluidKitPad={3055,158},FinishKitPad={3066,158},PartsShelvesPad={3077,158}}
 for name,v in extraPads do local p=w:FindFirstChild(name,true);p.Position=Vector3.new(v[1],1.9,v[2])end
 local changes={SalesPositionPad={'SALES AREA','DEAL TABLE & CUSTOMER HANDOVER'},OpenAnchor={'OPEN YOUR LOT','CLAIM YOUR WORKYARD'},DealTablePad={'SELLER CORNER','MEET YOUR FIRST SELLER'},FoundationPad={'REPAIR BAY & TOOLS','A WORKBENCH AND TOOLS FOR YOUR FIRST CAR'},ApproachPad={'WORKSHOP CANOPY','SHELTER THE SHARED BAY'},ServiceSlabPad={'SEALED SERVICE SLAB','SAFE WORKING GROUND'},LiftPad={'POWER & AIR','POWER YOUR SERVICE TOOLS'}}
 for name,t in changes do local p=w:FindFirstChild(name,true);p:SetAttribute('Title',t[1]);p:SetAttribute('Benefit',t[2])end
 local markers=w.Operations.RouteMarkers
 markers.Intake.Position=Vector3.new(3008,1.65,88)
 markers.Repair.Position=Vector3.new(3041,1.85,132)
 markers.Sales.Position=Vector3.new(3073,1.85,82)
 local spawn=w.PrototypeSpawn;spawn.CFrame=M.Spawn-Vector3.new(0,3.5,0);spawn.Transparency=1;spawn.CanCollide=false
 SS.SellCarsV5FullJourneyPackage.Spawn.Value.Enabled=false
 for _,pad in Journey.Pads do
  local o=Journey.Find(w,pad.path)
  if o then
   o.Size=Vector3.new(6,.2,6)
   local surface=o:FindFirstChild('PadSurface');local instruction=surface and surface:FindFirstChild('Instruction',true);if instruction then instruction.Text=''  end
   local callout=o:FindFirstChild('PadCallout');if callout then for _,c in callout:GetDescendants()do if c:IsA('TextLabel')and c.Name=='Action'then c.Text=pad.title end end end
   o:SetAttribute('Title',pad.title);o:SetAttribute('Benefit',pad.benefit);o:SetAttribute('Cost',pad.cost);o:SetAttribute('BusinessPhase',pad.phase);o:SetAttribute('RequiredStage',pad.stage)end
 end
 w:SetAttribute('IntegrationVersion','INT010')
end
function M.PlaceFirst(w,cf)
 local body=w.FirstDeal.FirstCar.Body
 local delta=cf*body.CFrame:Inverse()
 local oldPivot=w.FirstDeal.FirstCar:GetPivot()
 w.FirstDeal.FirstCar:PivotTo(delta*oldPivot)
 for _,name in {'BodyRepairAnchor','WheelsRepairAnchor','EngineRepairAnchor','ListAnchor','ForSaleSign'} do
  local o=w.FirstDeal:FindFirstChild(name)
  if o then if o:IsA('Model') then o:PivotTo(delta*o:GetPivot()) elseif o:IsA('BasePart')then o.CFrame=delta*o.CFrame end end
 end
end
function M.Sync(w,s)
 local n=0
 if s.stage==1 then n=s.openingStep>=1 and 1 or 0
 elseif s.stage==2 then n=2
 elseif s.stage==3 then n=({2,2,3,16,16})[(s.workshopStep or 0)+1] or 16
 elseif s.stage==4 or s.stage==5 then n=16
 elseif s.stage==6 or s.stage==7 then n=16
 elseif s.stage==8 then n=({16,18,18,19,21})[s.operationsStep+1] or 21
 elseif s.stage==9 then n=22
 elseif s.stage>=10 then n=24 end
 local key=tostring(n)..':'..tostring(s.salesBuilt)..':'..tostring(s.salesDisplayBuilt)..':'..tostring(s.workshopStep)
 for _,p in Journey.Pads do if p.owned then key..=':'..tostring(s[p.owned])end end
 if key~=lastStep then composer.SetStep(n);composer.ApplyOpeningStations(s);lastStep=key;w:SetAttribute('TycoonStep',n)end
 -- Recover the correct parked pose without moving waiting sellers or buyers.
 if not s.firstTransit and not (s.pendingDeal and s.pendingDeal.kind=='FirstSale') and s.stage<=4 then
  local destination=s.firstAtSales and 'Sales' or (s.firstAtRepair and 'Repair' or 'Intake')
  if w.FirstDeal:GetAttribute('Station')~=destination then
   M.PlaceFirst(w,CFrame.new(w.Operations.RouteMarkers[destination].Position+Vector3.new(0,1.7,0)))
   w.FirstDeal:SetAttribute('Station',destination)
  end
 end
 -- Tycoon owns permanent art; donor roots remain as logical/UI anchors only.
 for _,o in w:GetDescendants()do if o:GetAttribute('IntegrationHidden')then suppress(o)end end
 -- Retire decorative cars and NPCs wherever the live journey owns the encounter.
 for _,o in workspace.SellCars_Dealership_FullJourney:GetDescendants()do
  if o:IsA('Model') and (o.Name=='SalesCar_3' or o.Name:find('First_Sale_Display')) then suppress(o)end
 end
end
return M

