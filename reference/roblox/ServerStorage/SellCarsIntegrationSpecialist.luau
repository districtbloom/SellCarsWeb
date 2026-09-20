-- A complete specialist flip, using the same car, workshop and sales lane as routine work.
local R={};local A=require(game.ServerStorage.SellCarsIntegrationAutomation);local routes=require(game.ServerStorage.SellCarsIntegrationRoutes).Build()
local Config=require(game.ReplicatedStorage.CorePrototypeConfig)
local N=require(game.ServerStorage.SellCarsIntegrationNegotiation)
local jobs={}
function R.Build(w)
 local folder=Instance.new('Folder');folder.Name='SpecialistTrade';folder.Parent=w;folder:SetAttribute('TransportCarOffset',w.RareArrival.Transporter:GetPivot():ToObjectSpace(w.RareArrival.Transporter.RareCar:GetPivot()))
 local buyer=w.FirstBuyer:Clone();buyer.Name='SpecialistBuyer';buyer.Parent=folder
 local old=buyer:FindFirstChild('BuyerPrompt',true);if old then old:Destroy()end
 buyer:PivotTo(CFrame.new(3061,5.65,76));local p=Instance.new('ProximityPrompt');p.Name='SpecialistBuyerPrompt';p.ActionText='Negotiate';p.ObjectText='Collector';p.HoldDuration=0;p.MaxActivationDistance=10;p.RequiresLineOfSight=false;p.Style=Enum.ProximityPromptStyle.Custom;p.Enabled=false;p.Parent=buyer.Root
 return p
end
local function visible(model,on)
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then p.Transparency=on and (p:GetAttribute('ShownTransparency')or 0)or 1;p.CanCollide=false end end
end
function R.ArriveLead(player,s,w,send,valid)
 if jobs[s]or s.rarePhase~='Lead'then return end
 jobs[s]=true;s.rareFocus=true;s.rareQueued=true;s.rareRoute='Lot';s.rarePhase='EnRoute';s.phone=nil
 s.rareTradeId='RARE-'..player.UserId..'-'..(s.specialistNumber or 1);s.specialistGuide='Your team will finish the current car, then the rare seller will arrive at intake.';send()
 task.spawn(function()
  if not A.Acquire(s,s.rareTradeId,valid)then jobs[s]=nil;return end
  if s.cash<s.rareAsk+500 then
   A.Release(s,s.rareTradeId);s.rareFocus=false;s.rareQueued=nil;s.rarePhase='Lead';s.phone='FutureLead';s.specialistGuide='Save $'..(s.rareAsk+500-s.cash)..' more for this car and its repairs. Your team can keep earning.';jobs[s]=nil;send();return
  end
  s.rareQueued=nil
  local car=w.SpecialistTrade:FindFirstChild('RareCar')or w.RareArrival.Transporter:FindFirstChild('RareCar');car.Parent=w.SpecialistTrade
  local cf=routes.arrival[1];car:PivotTo(CFrame.new(cf.X,3.4,cf.Z)*cf.Rotation*CFrame.Angles(0,math.pi/2,0));visible(car,true)
  s.specialistGuide='The rare car is arriving at your seller area. Other arrivals are paused.';send()
  if not A.Travel(car,routes.arrival,valid,'Rare seller arriving')then jobs[s]=nil;return end
  w.RareArrival.RareSeller:PivotTo(CFrame.new(3017,5.65,88));s.rareAtIntake=true;s.rarePhase='Revealed';s.specialistGuide='Meet the rare seller at intake. This flip has the dealership to itself.';car:SetAttribute('BusinessStatus','Rare car · available');jobs[s]=nil;send()
 end)
end
function R.Sync(w,s)
 local listed=s.stage==11 and not s.rareSold and s.specialist and s.specialist.phase=='Listed'
 visible(w.SpecialistTrade.SpecialistBuyer,listed or (s.specialist and s.specialist.phase=='Leaving'))
 w.SpecialistTrade.SpecialistBuyer.Root.SpecialistBuyerPrompt.ObjectText=s.specialist and s.specialist.buyer==2 and 'Collector' or 'Enthusiast'
 local prompt=w.SpecialistTrade.SpecialistBuyer.Root.SpecialistBuyerPrompt
 prompt:SetAttribute('BusinessPromptEnabled',listed and not s.pendingDeal or false)
 prompt.Enabled=listed and not s.pendingDeal or false
end
function R.Start(player,s,w,send,valid)
 if jobs[s]or not s.rareOwned or s.rareRoute~='Lot' or s.rareSold then return end
 s.specialist=s.specialist or {id=s.rareTradeId or 'RARE-'..player.UserId..'-'..(s.specialistNumber or 1),bought=s.rarePurchase or s.rareAsk,repairs=0,fixes={},phase='Waiting'}
 local t=s.specialist;if t.phase=='Sold' or ((t.phase=='Listed' or t.phase=='WaitingBuyer' or t.phase=='Departing') and w.SpecialistTrade:FindFirstChild('RareCar'))then return end
 jobs[s]=true;s.rareQueued=true;s.stage=11;send()
 task.spawn(function()
  if not A.Acquire(s,t.id,valid,function()s.specialistGuide='Your rare car is waiting for the working lane to clear.';send()end)then jobs[s]=nil;return end
  s.rareQueued=nil
  local car=w.SpecialistTrade:FindFirstChild('RareCar')or w.RareArrival.Transporter:FindFirstChild('RareCar');if not car then jobs[s]=nil;return end
  car.Parent=w.SpecialistTrade;visible(car,true);car:SetAttribute('TradeId',t.id)
  if t.phase=='Listed' or t.phase=='WaitingBuyer' or t.phase=='Leaving' or t.sold then
   local cf=routes.sales[#routes.sales];car:PivotTo(CFrame.new(cf.X,3.4,cf.Z)*cf.Rotation*CFrame.Angles(0,math.pi/2,0))
   if t.sold then
    if A.Travel(car,routes.exit,valid,'Sold · departing')then visible(car,false);t.phase='Sold';s.rareSold=true;s.rareFocus=false;s.rareQueued=nil;s.stage=12;s.phone='Opportunities';s.specialistGuide='Your specialist flip is complete. Choose the next opportunity on your phone.';A.Release(s,t.id);A.Receipt(player,s,t.id,t.bought,t.repairs,t.sold,Config.RareSeller.car);send()end
   else t.phase='Listed';car:SetAttribute('BusinessStatus','For sale · specialist buyer');send()end
   jobs[s]=nil;return
  end
  if not t.atRepair then
   t.phase='Arriving';s.specialistGuide='Your rare car is moving through intake to the repair bay.';send()
   if not s.rareAtIntake then local cf=routes.arrival[1];car:PivotTo(CFrame.new(cf.X,3.4,cf.Z)*cf.Rotation*CFrame.Angles(0,math.pi/2,0));if not A.Travel(car,routes.arrival,valid,'Arriving')then jobs[s]=nil;return end end
   if not A.Travel(car,routes.work,valid,'Moving to repair')then jobs[s]=nil;return end;t.atRepair=true
  end
  t.phase='Repairing';s.specialistGuide='Your mechanic is preparing the rare car. The original specification stays intact.';send()
  while valid()and not t.ready do
   local parts={};for _,n in {'Body','Wheels','Engine'}do if not t.fixes[n]then table.insert(parts,n)end end
   t.ready=A.Work(w.Workshop.Mechanic,car,valid,function(n)local cost=({Body=120,Wheels=160,Engine=220})[n];if s.cash<cost then s.specialistGuide='Your rare car needs repair funds. Finish funding its $500 repair budget.';send();return false end;s.cash-=cost;t.repairs+=cost;t.fixes[n]=true;send();return true end,parts)
   if not t.ready then task.wait(3)end
  end
  if not valid()then jobs[s]=nil;return end
  t.phase='Moving';s.specialistGuide='Your rare car is moving to the sales space.';send()
  if not A.Travel(car,routes.sales,valid,'For sale')then jobs[s]=nil;return end
  t.phase='Listed';t.buyer=t.buyer or 1;t.offer=t.buyer==2 and 6200 or 6000;car:SetAttribute('BusinessStatus','For sale · specialist buyer');s.specialistGuide='An enthusiast wants a car they can drive today. Meet them beside the car.';send();jobs[s]=nil
 end)
end
function R.Dialogue(player,s,w,event,valid)
 local t=s.specialist;if s.rareSold or s.stage~=11 or not t or s.lotTrade~=t.id or t.phase~='Listed' or not valid()then return end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local buyer=w.SpecialistTrade.SpecialistBuyer
 if not root or (root.Position-buyer.Head.Position).Magnitude>18 then return end
 local collector=t.buyer==2
 local q=N.Open(t,'buyer',{price=collector and 6200 or 6000,limit=collector and 6500 or 6200,step=100,mode='Sell',name=collector and 'Morgan' or 'Alex',role=collector and 'Collector' or 'Enthusiast',line=collector and 'Original motor. That’s what I collect.' or 'Ready to drive? That’s what I’m looking for.',suggest=6400,forgiving=false,minimum=5000,maximum=8000})
 t.offer=q.price;t.negotiationActive=true
 event:FireClient(player,'Dialogue',{kind='SpecialistBuyer',name=q.name,line=q.line,deal={mode='Sell',car=Config.RareSeller.car,price=q.price,cost=t.bought+t.repairs,value=q.price-t.bought-t.repairs,quote=N.Public(q,'Specialist',true)},options={}},buyer.Head)
end
local function dismiss(player,s,w,event,send,valid,line)
 local t=s.specialist;t.negotiationActive=nil;t.phase='Leaving';s.specialistGuide='Waiting for another buyer. Your car keeps its sales space.'
 event:FireClient(player,'DealEnded',{line=line});send()
 task.delay(1.1,function()if not valid()or t.phase~='Leaving'then return end;t.phase='WaitingBuyer';w.SpecialistTrade.RareCar:SetAttribute('BusinessStatus','Waiting for buyer');send()end)
 task.delay(20,function()
  if not valid()or s.rareSold or t.phase~='WaitingBuyer'then return end
  t.buyer=t.buyer==2 and 1 or 2;t.negotiations=nil;t.countered=nil;t.offer=t.buyer==2 and 6200 or 6000;t.phase='Listed';s.specialistGuide='Another buyer has arrived. Meet them beside the car.';send()
 end)
end

function R.Action(player,s,w,event,action,send,valid,payload)
 if (action=='RequestRareArrival'or action=='DriveToRareSeller')and s.stage==10 and s.phone=='FutureLead'and s.rarePhase=='Lead'then R.ArriveLead(player,s,w,send,valid);return true end
 if action=='RoutineOpportunity'and s.stage==12 then s.specialistGuide='Your team continues routine flips. Specialist opportunities remain on your phone.';send();return true end
 if action=='SpecialistOpportunity'and s.stage==12 then
  local old=w.SpecialistTrade:FindFirstChild('RareCar');if old then old.Parent=w.RareArrival.Transporter;old:PivotTo(w.RareArrival.Transporter:GetPivot()*w.SpecialistTrade:GetAttribute('TransportCarOffset'))end
  s.stage=10;s.specialistNumber=(s.specialistNumber or 1)+1;s.specialist=nil;s.specialistGuide=nil;s.rareOwned=false;s.rareSold=false;s.rareAtIntake=false;s.rareTradeId=nil;s.rareFocus=false;s.rarePhase='Lead';s.rareRoute=nil;s.rareTravelPhase=nil;s.phone='FutureLead';s.rareAsk=Config.RareSeller.ask;send();return true
 end
 if not action:find('Specialist',1,true)then return false end
 local t=s.specialist;local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local q=t and t.negotiations and t.negotiations.buyer
 if s.rareSold or s.stage~=11 or not t or s.lotTrade~=t.id or t.phase~='Listed' or s.pendingDeal or not t.negotiationActive or not N.Valid(q,payload) or not root or(root.Position-w.SpecialistTrade.SpecialistBuyer.Head.Position).Magnitude>18 then return true end
 if action=='SpecialistCounter'then
  if N.Counter(q,payload)then
   t.offer=q.price
   if q.departed then dismiss(player,s,w,event,send,valid,q.line)else R.Dialogue(player,s,w,event,valid);send()end
  end
 elseif action=='SpecialistPause'then t.negotiationActive=nil;event:FireClient(player,'CloseDialogue');send()
 elseif action=='SpecialistDismiss'then dismiss(player,s,w,event,send,valid,'All right. Good luck with the sale.')
 elseif action=='SpecialistAccept'and not t.sold then
  jobs[s]=true;t.negotiationActive=nil;t.sold=q.price;s.cash+=t.sold;t.phase='Departing';s.specialistGuide='Sold. Your rare car is leaving the dealership.'
  -- Receipt is recorded once here; the acknowledgement owns presentation.
  s.receipts=s.receipts or {};s.receipts[t.id]=true
  event:FireClient(player,'DealResolved',{kind='Sell',amount=t.sold,profit=t.sold-t.bought-t.repairs,carName=Config.RareSeller.car});send()
  task.delay(2,function()
   if not valid()then jobs[s]=nil;return end
   if not A.Travel(w.SpecialistTrade.RareCar,routes.exit,valid,'Sold · departing')then jobs[s]=nil;return end
   visible(w.SpecialistTrade.RareCar,false);t.phase='Sold';s.rareSold=true;s.rareFocus=false;s.rareQueued=nil;s.stage=12;s.phone='Opportunities';s.specialistGuide='You completed a specialist flip. Choose another opportunity on your phone; routine trading continues.';A.Release(s,t.id);send();jobs[s]=nil
  end)
 end
 return true
end
return R

