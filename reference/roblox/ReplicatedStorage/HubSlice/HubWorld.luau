-- Reuses the authored Integration world and its source pad coordinates.
local W={};local D=require(script.Parent.HubData);local M=require(script.Parent.HubModel)
local SS=game:GetService('ServerStorage');local Tween=game:GetService('TweenService')
local composer=require(SS.SellCarsIntegrationOpeningComposer)
local function part(parent,name,size,cf,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Anchored=true;p.Material=Enum.Material.SmoothPlastic;p.Parent=parent;return p
end
local function clean(o)for _,v in o:GetDescendants()do if v:IsA('LuaSourceContainer')or v:IsA('ProximityPrompt')or(v:IsA('LayerCollector')and v.Name~='Face')then v:Destroy()end end end
local function visible(o,on)for _,p in o:GetDescendants()do if p:IsA('BasePart')then if p:GetAttribute('HubTrans')==nil then p:SetAttribute('HubTrans',p:GetAttribute('ShownTransparency')or p.Transparency)end;p.Transparency=on and p:GetAttribute('HubTrans')or 1;p.CanCollide=false;p.CanTouch=false;p.CanQuery=on elseif p:IsA('SurfaceGui')and p.Name=='Face'then p.Enabled=on end end end
local function detailCar(model)
 local body=model:FindFirstChild('Body');local cabin=model:FindFirstChild('Cabin');if not body or not cabin then return end
 local glass=Color3.fromRGB(45,70,79)
 for _,side in {-1,1}do
  local window=part(model,'SideGlass',Vector3.new(cabin.Size.X*.72,cabin.Size.Y*.62,.04),cabin.CFrame*CFrame.new(0,.06,side*(cabin.Size.Z/2+.025)),glass);window.CanCollide=false
  local endGlass=part(model,'EndGlass',Vector3.new(.04,cabin.Size.Y*.62,cabin.Size.Z*.8),cabin.CFrame*CFrame.new(side*(cabin.Size.X/2+.025),.06,0),glass);endGlass.CanCollide=false
  for _,z in {-1,1}do local lamp=part(model,'Lamp',Vector3.new(.05,.34,.8),body.CFrame*CFrame.new(side*(body.Size.X/2+.03),.1,z*body.Size.Z*.31),side==1 and Color3.fromRGB(251,232,166)or Color3.fromRGB(173,63,44));lamp.CanCollide=false end
 end
end
function W.new()
 local w=require(game.ReplicatedStorage.CoreWorldBuilder).Build();local self={source=w,pads={},templates={},lastPads=-1}
 local root=Instance.new('Folder');root.Name='HubSlice';root.Parent=workspace;self.root=root
 for i,car in {w.FirstDeal.FirstCar,w.SecondDeal.SecondCar,w.SecondDeal.SecondCar,w.RareArrival.Transporter.RareCar}do local c=car:Clone();clean(c);detailCar(c);c.Parent=nil;self.templates[i]=c end
 self.npcTemplate=w.FirstDeal.FirstSeller:Clone();clean(self.npcTemplate);self.npcTemplate.Parent=nil
 self.worker=w.Workshop.Mechanic:Clone();clean(self.worker);self.worker.Name='Jo';self.worker.Parent=root;visible(self.worker,false)
 self.personal=w.PersonalGarage.PersonalCar:Clone();clean(self.personal);detailCar(self.personal);self.personal.Name='PersonalCar';self.personal.Parent=root;visible(self.personal,false)
 for _,p in w:GetDescendants()do if p:IsA('BasePart')then p.Transparency=1;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false elseif p:IsA('LayerCollector')then p.Enabled=false elseif p:IsA('ProximityPrompt')then p.Enabled=false end end
 for _,p in D.pads do local pad=part(root,p.id,Vector3.new(6,.22,6),CFrame.new(table.unpack(p.sourcePosition)),Color3.fromRGB(228,199,105));pad.CanCollide=false;pad:SetAttribute('HubPad',p.id);pad:SetAttribute('Title',p.name);pad:SetAttribute('Cost',p.cost);self.pads[p.id]=pad end
 local terrain=part(root,'LeadGround',Vector3.new(70,.3,62),CFrame.new(D.world({43,-39},1.55)),Color3.fromRGB(139,143,117))
 for _,r in {{49,-26,20,5},{55,-31,5,15},{40,-36,35,5}}do part(root,'LeadRoad',Vector3.new(r[3]*3,.12,r[4]*3),CFrame.new(D.world({r[1],r[2]},1.76)),Color3.fromRGB(76,88,85))end
 part(root,'EliasGarage',Vector3.new(30,13,12),CFrame.new(D.world({40,-51},8)),Color3.fromRGB(187,173,145));part(root,'EliasRoof',Vector3.new(33,1,15),CFrame.new(D.world({40,-51},14.8)),Color3.fromRGB(61,88,81))
 self.seat=Instance.new('Seat');self.seat.Name='DriverSeat';self.seat.Size=Vector3.new(2,1,2);self.seat.Transparency=1;self.seat.Anchored=true;self.seat.CanCollide=false;self.seat.Disabled=true;self.seat.Parent=root
 function self:pose(model,pos,angle)model:PivotTo(CFrame.new(D.world(pos))*CFrame.Angles(0,(angle or 0)+math.pi/2,0))end
 function self:environment(s,animate)
  if self.lastPads==#s.pads then return end;self.lastPads=#s.pads
  local before={};local preview=SS.SellCarsV5FullJourneyPackage.Preview.Value
  if animate then for _,p in preview:GetDescendants()do if p:IsA('BasePart')then before[p]=p.Transparency end end end
  local h=function(id)return M.has(s,id)end
  local n=h('display')and 22 or h('salesrep')and 21 or h('carbuyer')and 18 or h('power')and 16 or h('tools')and 3 or h('intake')and 2 or h('lot')and 1 or 0
  -- Granular tools 7–12 are shown by the same ownership filter as the Studio source.
  if h('finish')or h('restoration')then n=math.max(n,16)end
  composer.SetStep(n);composer.ApplyOpeningStations({stage=10,workshopStep=h('air')and 4 or h('power')and 3 or h('tools')and 2 or 0,salesDisplayBuilt=h('sales'),salesBuilt=h('salesdesk'),shelterBuilt=h('shade'),serviceFloorBuilt=h('servicefloor'),panelBench=h('restoration'),touchupKit=h('finish'),wheelTools=h('wheeltools'),fluidKit=h('fluidkit'),finishKit=h('finishtrolley'),partsShelves=h('partsshelves')})
  for _,p in preview:GetDescendants()do if p:IsA('BasePart')then
   -- Remove static demonstration cars/NPCs from the working lane.
   local a=p:FindFirstAncestorWhichIsA('Model');if a and(a.Name:find('SalesCar')or a.Name:find('First_Sale_Display'))then p.Transparency=1;p.CanCollide=false;p.CanQuery=false end
   if animate and before[p]==1 and p.Transparency<1 then local transparency=p.Transparency;p.Transparency=1;Tween:Create(p,TweenInfo.new(.7),{Transparency=transparency}):Play()end
  end end
 end
 function self:sync(s)
  self:environment(s,true)
  for _,p in D.pads do local o=self.pads[p.id];local eligible=M.eligible(s,p);o.Transparency=eligible and 0 or 1;o.CanQuery=eligible;o:SetAttribute('Available',eligible)end
  local c=s.car
  if self.car and(not c or self.car:GetAttribute('CarId')~=c.id)then self.car:Destroy();self.car=nil end
  if c then if not self.car then self.car=self.templates[c.index]:Clone();self.car.Name='TradingCar';self.car:SetAttribute('CarId',c.id);self.car.Parent=root;visible(self.car,true)end
   self:pose(self.car,c.pos,c.angle);self.car:SetAttribute('HubCar',true);self.car:SetAttribute('Condition',D.grade(c.condition));self.car:SetAttribute('Status',c.status)
   local custom=c.custom or{};local color=Color3.fromHex(({cream='#e8d9b2',blue='#609fb6',red='#bd594a',green='#648b71'})[custom.paint]or D.cars[c.index].color)
   for _,p in self.car:GetDescendants()do if p:IsA('BasePart')then if p.Name=='Body'or p.Name=='Cabin'or p.Name=='Hood'or p.Name=='Roof'or p.Name=='Trunk'then p.Color=color elseif p.Name:find('Wheel')then p.Color=custom.wheels=='sport'and Color3.fromRGB(33,40,47)or Color3.fromRGB(55,53,48)end end end
   local stripe=self.car:FindFirstChild('HubStripe');if custom.stripe and not stripe then stripe=part(self.car,'HubStripe',Vector3.new(3.8,.04,.5),self.car:GetPivot(),Color3.fromRGB(242,229,189));stripe.CanCollide=false end
   if stripe then stripe.Transparency=custom.stripe and 0 or 1;local body=self.car:FindFirstChild('Body');stripe.CFrame=body.CFrame*CFrame.new(0,body.Size.Y/2+.04,0)end
  end
  local actor=c and(c.status=='seller'or c.status=='buyer'or c.status=='sold')
  if actor then if not self.actor then self.actor=self.npcTemplate:Clone();self.actor.Name='DealPerson';self.actor.Parent=root;visible(self.actor,true)end
   self.actorPos=c.remote and{43,-43}or c.status=='seller'and{-6,-5.33333}or{10.33333,-6.7};self.actor:PivotTo(CFrame.new(D.world(self.actorPos,5))*CFrame.Angles(0,math.pi,0));self.actor:SetAttribute('HubActor',true)
   local b=c.status~='seller'and M.buyer(s);local color=b and b.role=='Collector'and Color3.fromRGB(133,102,159)or b and b.role=='Bargain hunter'and Color3.fromRGB(168,116,77)or Color3.fromRGB(74,140,138)
   for _,p in self.actor:GetDescendants()do if p:IsA('BasePart')and(p.Name=='Root'or p.Name:find('Arm'))then p.Color=color end;if p:IsA('TextLabel')and p.Name=='Expression'then p.Text=c.quote and c.quote.reaction=='firm'and'• ─ •'or c.quote and c.quote.reaction=='happy'and'• ▿ •'or'• ‿ •'end end
  elseif self.actor then self.actor:Destroy();self.actor=nil end
  visible(self.worker,s.worker.hired);if s.worker.hired then self.worker:PivotTo(CFrame.new(D.world(s.worker.pos,5))*CFrame.Angles(0,math.pi,0));self.worker:SetAttribute('HubWorker',true)end
  visible(self.personal,s.personal~=nil);if s.personal then self:pose(self.personal,s.personal.pos,s.personal.angle);self.personal:SetAttribute('HubPersonal',true);self.seat.CFrame=self.personal:GetPivot()*CFrame.new(0,2,0)end
 end
 function self:mount(player)self.seat.Disabled=false;local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then player.Character:PivotTo(self.seat.CFrame+Vector3.new(0,3,0));self.seat:Sit(h)end end
 function self:dismount(player,s)self.seat.Disabled=true;local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then h.Sit=false;h:ChangeState(Enum.HumanoidStateType.GettingUp);local weld=self.seat:FindFirstChild('SeatWeld');if weld then weld:Destroy()end;player.Character:PivotTo(CFrame.new(D.world({s.personal.pos[1]+3,s.personal.pos[2]+1},5)))end end
 return self
end
return W

