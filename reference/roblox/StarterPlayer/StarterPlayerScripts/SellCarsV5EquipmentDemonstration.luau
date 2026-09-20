-- OC01: local, bounded demonstration only. No production/sales/car state.
if not game.RunService:IsStudio()or game.PlaceId~=125334614375606 then return end
local pg=game.Players.LocalPlayer:WaitForChild('PlayerGui')
local journey=pg:WaitForChild('SellCarsV5FullJourney',30);if not journey then return end
local life=pg:WaitForChild('SellCarsV5EverydayLife',30);if not life then return end
local V,CF=Vector3.new,CFrame.new
local records={};local tracked;local dirty=true;local added,removed;local focused=true;local accumulator,time,rescan=0,0,0
local function reset(a)
 if not a.p.Parent then return end
 if a.kind=='RINSE'then a.beam.Enabled=false
 elseif a.kind=='FAN'then a.p.CFrame=a.rest
 elseif a.kind=='TRACE'then a.p.CFrame=a.rest end
end
local function discover(root)
 for _,a in records do reset(a)end;records={};tracked=root;dirty=false
 if added then added:Disconnect();removed:Disconnect()end;if not root then return end
 added=root.DescendantAdded:Connect(function()dirty=true end);removed=root.DescendantRemoving:Connect(function()dirty=true end)
 for _,p in root:GetDescendants()do if p:IsA('BasePart')and p:GetAttribute('OC_Motion')then
  local kind=p:GetAttribute('OC_Motion');local pivot=p:GetAttribute('OC_Pivot');local rest=p:GetAttribute('OC_Rest')or p:GetAttribute('FJ_CF')
  table.insert(records,{p=p,kind=kind,pivot=pivot,rest=rest,relative=pivot and pivot:ToObjectSpace(rest),beam=p:FindFirstChild('BoundedRinse'),center=p:GetAttribute('OC_Center'),index=p:GetAttribute('OC_Index')or 0,first=p:GetAttribute('FJ_First'),retire=p:GetAttribute('FJ_Retire')or 999})
 end end;life:SetAttribute('EquipmentTracked',#records)
end
local f1=game.UserInputService.WindowFocused:Connect(function()focused=true end)
local f2=game.UserInputService.WindowFocusReleased:Connect(function()focused=false end)
local hb=game.RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt;if accumulator<.05 then return end;local elapsed=accumulator;accumulator=0;rescan+=elapsed
 local r=workspace:FindFirstChild('SellCars_Dealership_FullJourney');if r~=tracked or(dirty and rescan>=1)then discover(r);rescan=0 end
 local story=pg:FindFirstChild('SellCarsV5ShopStories');local run=focused and life:GetAttribute('Enabled')~=false and(not story or story:GetAttribute('MotionEnabled')~=false)and journey:GetAttribute('Phase')=='AFTER'
 if run then time+=elapsed end
 local step=journey:GetAttribute('ShownStep')or 0;local cam=workspace.CurrentCamera;local near={}
 for _,a in records do local d=(cam.CFrame.Position-a.rest.Position).Magnitude
  if run and step>=a.first and step<a.retire and d<90 then table.insert(near,{a=a,d=d})else reset(a)end
 end
 table.sort(near,function(a,b)return a.d<b.d end);local moving,jets=0,0
 for i,v in near do local a=v.a
  if i<=32 then
   if a.kind=='FAN'then a.p.CFrame=a.pivot*CFrame.Angles(time*3.7,0,0)*a.relative;moving+=1
   elseif a.kind=='TRACE'then a.p.CFrame=a.center*CF(0,.22*math.sin(a.index*.72-time*3.5),0);moving+=1
   elseif a.kind=='RINSE'then local on=time%14<4.5;a.beam.Enabled=on;a.beam.Width1=.38+.1*math.sin(time*11+a.rest.Z);if on then jets+=1 end end
  else reset(a)end
 end
 life:SetAttribute('EquipmentMoving',moving);life:SetAttribute('RinseJets',jets);life:SetAttribute('EquipmentDemoOnly',true)
end)
script.Destroying:Connect(function()hb:Disconnect();f1:Disconnect();f2:Disconnect();if added then added:Disconnect();removed:Disconnect()end;for _,a in records do reset(a)end end)

