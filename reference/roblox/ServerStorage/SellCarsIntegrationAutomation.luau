-- One shared working lane. A trade retains its reservation until physical departure.
local A={RoutineDelay=25}
local Routes=require(game.ServerStorage.SellCarsIntegrationRoutes).Build()
local active={}
function A.Acquire(s,id,valid,status)
 while valid() and ((s.lotTrade and s.lotTrade~=id) or ((s.rareQueued or s.rareFocus) and s.lotTrade~=id and not id:find('RARE',1,true))) do
  if status then status(s.rareFocus and 'Paused for rare flip' or 'Waiting for sales space')end;task.wait(.3)
 end
 if not valid()then return false end;s.lotTrade=id;return true
end
function A.Release(s,id)if s.lotTrade==id then s.lotTrade=nil end end
function A.Travel(model,route,valid,status)
 if status then model:SetAttribute('BusinessStatus',status)end
 for i=1,#route do
  if not valid()or not model.Parent then return false end
  local cf=route[i];local goal=CFrame.new(cf.X,3.4,cf.Z)*cf.Rotation*CFrame.Angles(0,math.pi/2,0)
  local from=model:GetPivot();local duration=math.max(.03,(from.Position-goal.Position).Magnitude/15);local start=os.clock()
  repeat if not valid()then return false end;model:PivotTo(from:Lerp(goal,math.min(1,(os.clock()-start)/duration)));task.wait()until os.clock()-start>=duration
  model:PivotTo(goal)
 end
 if #route>0 then local cf=route[#route];model:PivotTo(CFrame.new(cf.X,3.4,cf.Z)*cf.Rotation*CFrame.Angles(0,math.pi/2,0))end
 return valid()
end
function A.Work(rig,car,valid,onPart,parts)
 local home=rig:GetPivot()
 for _,name in parts do
  if not valid()then return false end
  rig:SetAttribute('StaffJob','Repairing '..name:lower());car:SetAttribute('BusinessStatus','Repairing '..name:lower())
  local target=car:GetPivot().Position+Vector3.new(name=='Engine' and 5 or -5,0,name=='Wheels' and 2 or -2)
  target=Vector3.new(target.X,home.Y,target.Z);local from=rig:GetPivot()
  for i=1,18 do if not valid()then return false end;rig:PivotTo(from:Lerp(CFrame.lookAt(target,Vector3.new(car:GetPivot().X,target.Y,car:GetPivot().Z)),i/18));task.wait(.04)end
  task.wait(1.5)
  if not onPart(name)then rig:PivotTo(home);rig:SetAttribute('StaffJob','Waiting for repair funds');return false end
 end
 rig:PivotTo(home);rig:SetAttribute('StaffJob','Ready for a car');car:SetAttribute('BusinessStatus','Ready');return true
end
local function show(car,on)for _,p in car:GetDescendants()do if p:IsA('BasePart')then p.Transparency=on and (p:GetAttribute('ShownTransparency')or 0)or 1;p.CanCollide=false end end end
local function receipt(player,s,id,bought,repairs,sold,car)
 s.receipts=s.receipts or {};if s.receipts[id]then return end;s.receipts[id]=true
 if A.OnReceipt then A.OnReceipt(player,{id=id,car=car,bought=bought,repairs=repairs,sold=sold,profit=sold-bought-repairs})end
end
A.Receipt=receipt
function A.TransferFirst(player,s,w,destination,valid,send)
 if s.firstTransit then return end;local flag=destination=='Repair'and'firstAtRepair'or'firstAtSales';if s[flag]then return end
 s.firstTransit=destination;send()
 task.spawn(function()
  local car=w.FirstDeal.FirstCar;local start=car.Body.CFrame
  if not A.Travel(car,destination=='Repair'and Routes.work or Routes.sales,valid,'Moving to '..destination:lower())then s.firstTransit=nil;return end
  local delta=car.Body.CFrame*start:Inverse()
  for _,name in {'BodyRepairAnchor','WheelsRepairAnchor','EngineRepairAnchor','ListAnchor','ForSaleSign'}do local o=w.FirstDeal:FindFirstChild(name);if o then if o:IsA('Model')then o:PivotTo(delta*o:GetPivot())elseif o:IsA('BasePart')then o.CFrame=delta*o.CFrame end end end
  s[flag]=true;s.firstTransit=nil;w.FirstDeal:SetAttribute('Station',destination)
  if destination=='Repair'then s.repairStarted=true else s.listed=true;s.buyerMet=true;s.phone=nil end;send()
 end)
end
function A.ExitFirst(player,s,w,valid,done)task.spawn(function()if A.Travel(w.FirstDeal.FirstCar,Routes.exit,valid,'Sold · departing')then done()end end)end
function A.StartSecond(player,s,w,send,valid)
 if s.secondSold or s.secondWorkComplete or active[s]then return end;active[s]=true
 s.secondTradeId=s.secondTradeId or 'SECOND-'..player.UserId
 task.spawn(function()
  local id=s.secondTradeId;local car=w.SecondDeal.SecondCar
  if not A.Acquire(s,id,valid,function(t)w.Workshop.Mechanic:SetAttribute('StaffJob',t)end)then active[s]=nil;return end
  s.secondPhase='Arriving';send();A.Travel(car,Routes.work,valid,'Moving to repair')
  s.secondPhase='Repairing';s.secondFixes=s.secondFixes or {};send()
  while valid() and not s.secondWorkComplete do
   local parts={};for _,n in {'Body','Wheels','Engine'}do if not s.secondFixes[n]then table.insert(parts,n)end end
   local done=A.Work(w.Workshop.Mechanic,car,valid,function(n)local cost=({Body=120,Wheels=160,Engine=220})[n];if s.cash<cost then return false end;s.cash-=cost;s.secondRepairTotal=(s.secondRepairTotal or 0)+cost;s.secondFixes[n]=true;send();return true end,parts)
   if done then s.secondWorkComplete=true;s.secondPhase='Ready';send()else task.wait(3)end
  end
  active[s]=nil
 end)
end
local function cycle(player,s,w,r,send,valid)
 local car=w.Operations.AutoRouteCar;local buyer=w.Operations.CarBuyer;local rep=w.Operations.SalesRep
 while valid() and not r.bought and s.cash<1400 do buyer:SetAttribute('StaffJob','Waiting for $1,400 operating funds');s.businessWaiting='Staff need $1,400 for a car and repairs.';send();task.wait(3)end
 if not valid()then return false end
 if not A.Acquire(s,r.id,valid,function(t)buyer:SetAttribute('StaffJob',t)end)then return false end
 s.businessWaiting=nil
 if not r.bought then r.bought=900;s.cash-=900 end;r.repairs=r.repairs or 0;r.fixes=r.fixes or {};car:SetAttribute('TradeId',r.id);show(car,true);buyer:SetAttribute('StaffJob','Bringing a car to intake');send()
 if not r.atRepair then
  -- Re-use only after the previous car has departed; arrival starts outside the dealership.
  car:PivotTo(CFrame.new(Routes.arrival[1].Position)*CFrame.Angles(0,math.pi/2,0))
  if not A.Travel(car,Routes.arrival,valid,'Arriving')or not A.Travel(car,Routes.work,valid,'Moving to repair')then return false end;r.atRepair=true
 end
 local parts={};for _,n in {'Body','Wheels','Engine'}do if not r.fixes[n]then table.insert(parts,n)end end
 if not A.Work(w.Workshop.Mechanic,car,valid,function(n)local c=({Body=120,Wheels=160,Engine=220})[n];if s.cash<c then return false end;s.cash-=c;r.repairs+=c;r.fixes[n]=true;send();return true end,parts)then return false end
 rep:SetAttribute('StaffJob','Meeting a buyer');if not A.Travel(car,Routes.sales,valid,'For sale')then return false end;task.wait(2)
 if not valid()then return false end
 if not r.sold then r.sold=2350;s.cash+=2350;send()end
 if not A.Travel(car,Routes.exit,valid,'Sold · departing')then return false end
 r.departed=true;show(car,false);A.Release(s,r.id);rep:SetAttribute('StaffJob','Ready for a car');buyer:SetAttribute('StaffJob','Finding the next car');receipt(player,s,r.id,r.bought,r.repairs,r.sold,'Routine car');send();return true
end
function A.StartOperations(player,s,w,send,notify,valid)
 if s.automationDemoRunning or s.automationDemoComplete then return end;s.automationDemoRunning=true
 task.spawn(function()
  while valid()and not s.secondWorkComplete do A.StartSecond(player,s,w,send,valid);task.wait(.5)end;if not valid()then return end
  local car=w.SecondDeal.SecondCar;w.Operations.SalesRep:SetAttribute('StaffJob','Meeting the second buyer')
  if not s.secondDeparted then
   if not A.Travel(car,Routes.sales,valid,'For sale')then return end;task.wait(2)
   if not s.secondSold then s.cash+=2850;s.secondSold=true;s.secondProfit=2850-(s.secondPurchase or 1400)-(s.secondRepairTotal or 0);send()end
   if not A.Travel(car,Routes.exit,valid,'Sold · departing')then return end
   s.secondDeparted=true;show(car,false);A.Release(s,s.secondTradeId);receipt(player,s,s.secondTradeId,s.secondPurchase or 1400,s.secondRepairTotal or 0,2850,'Desert coupe');send()
  end
  s.autoCycle=s.autoCycle or {id='AUTO-'..player.UserId}
  while valid()and not cycle(player,s,w,s.autoCycle,send,valid)do task.wait(3)end;if not valid()then return end
  s.automationProfitAwarded=true;s.automationProfit=950;s.automationDemoComplete=true;s.automationDemoRunning=false;send();A.StartRoutine(player,s,w,send,notify,valid)
 end)
end
function A.StartRoutine(player,s,w,send,notify,valid)
 if s.routineRunning or not s.automationDemoComplete then return end;s.routineRunning=true
 task.spawn(function()
  while valid()do
   task.wait(A.RoutineDelay);if not valid()then break end
   if not s.routine or s.routine.departed then s.routineNumber=(s.routineNumber or 0)+1;s.routine={id='ROUTINE-'..player.UserId..'-'..s.routineNumber}end
   if cycle(player,s,w,s.routine,send,valid)then s.routineProfit=(s.routineProfit or 0)+950;send()end
  end;s.routineRunning=false
 end)
end
return A

