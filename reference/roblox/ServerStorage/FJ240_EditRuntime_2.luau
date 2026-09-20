-- Full environment-only purchase journey; the protected Institution is never filtered.
local A={Version='2026-09-08.FJ240.1'}
local SS=game:GetService('ServerStorage');local RS=game:GetService('ReplicatedStorage');local NAME='SellCarsV5FullJourneyPackage'
local records,package,sourceData,rules
local function object(parent,name,value)local v=Instance.new('ObjectValue');v.Name=name;v.Value=value;v.Parent=parent;return v end
local function path(root,o)local t={};while o~=root do table.insert(t,1,o.Name);o=o.Parent end;return table.concat(t,'/')end
local function order(n)if n==233 then return 229 elseif n>=229 and n<233 then return n+1 end;return n end
local function stamp(o,b)
 o:SetAttribute('FJ_First',order(b.first));o:SetAttribute('FJ_Finish',order(b.finish or b.first));o:SetAttribute('FJ_Mid',order(b.mid or 0));o:SetAttribute('FJ_Kind',b.kind or'asset');o:SetAttribute('FJ_Department',b.department)
 o:SetAttribute('FJ_Retire',order(b.retire or 999));o:SetAttribute('FJ_MoveAt',order(b.moveAt or 999));o:SetAttribute('FJ_Move',b.move or Vector3.zero)
 o:SetAttribute('FJ_CF',o.CFrame);o:SetAttribute('FJ_Size',o.Size);o:SetAttribute('FJ_Color',o.Color);o:SetAttribute('FJ_Material',o.Material.Name);o:SetAttribute('FJ_Transparency',o.Transparency);o:SetAttribute('FJ_Collide',o.CanCollide);o:SetAttribute('FJ_Query',o.CanQuery);o:SetAttribute('FJ_Touch',o.CanTouch)
 for _,c in o:GetDescendants()do
  if c:IsA('Light')or c:IsA('LayerCollector')or c:IsA('ParticleEmitter')or c:IsA('Beam')or c:IsA('Trail')then c:SetAttribute('FJ_Enabled',c.Enabled)end
 end
end
local function setup()
 assert(game.PlaceId==125334614375606 and game.RunService:IsStudio(),'Studio environment preview only')
 if records then return end
 package=assert(SS:FindFirstChild(NAME),'Full journey not installed');sourceData=require(RS.SellCarsV5FullJourneyData);rules=require(SS.SellCarsV5FullJourneyRules);records={}
 for _,o in package.Preview.Value:GetDescendants()do if o:IsA('BasePart')and o:GetAttribute('FJ_First')~=nil then
  local effects={};for _,e in o:GetDescendants()do if e:GetAttribute('FJ_Enabled')~=nil then table.insert(effects,{o=e,on=e:GetAttribute('FJ_Enabled')})end end
  table.insert(records,{o=o,first=o:GetAttribute('FJ_First'),finish=o:GetAttribute('FJ_Finish'),mid=o:GetAttribute('FJ_Mid'),kind=o:GetAttribute('FJ_Kind'),dept=o:GetAttribute('FJ_Department'),retire=o:GetAttribute('FJ_Retire'),moveAt=o:GetAttribute('FJ_MoveAt'),move=o:GetAttribute('FJ_Move'),cf=o:GetAttribute('FJ_CF'),size=o:GetAttribute('FJ_Size'),color=o:GetAttribute('FJ_Color'),material=Enum.Material[o:GetAttribute('FJ_Material')],trans=o:GetAttribute('FJ_Transparency'),collide=o:GetAttribute('FJ_Collide'),query=o:GetAttribute('FJ_Query'),touch=o:GetAttribute('FJ_Touch'),effects=effects,path=o:GetAttribute('FJ_Path')or o.Name,pbCF=o:GetAttribute('FJ_PB_CFrame'),pbSize=o:GetAttribute('FJ_PB_Size'),pbTrans=o:GetAttribute('FJ_PB_Transparency')})
 end end
end
local function clip(cf,size,axis,maximum)
 local c=cf.Position[axis];local h=size[axis]/2
 if c-h>=maximum then return cf,size,false end
 if c+h<=maximum then return cf,size,true end
 local s=math.max(.04,maximum-(c-h));local shift=(s-size[axis])/2
 local v=axis=='Y'and Vector3.new(0,shift,0)or Vector3.new(0,0,shift)
 local sz=axis=='Y'and Vector3.new(size.X,s,size.Z)or Vector3.new(size.X,size.Y,s)
 return cf+v,sz,true
end
local function desired(r,n)
 local show=n>=r.first and n<r.retire;local cf,size=r.cf,r.size;local color,mat=r.color,r.material
 if n>=r.moveAt then cf+=r.move end
 if n<order(233)then cf=r.pbCF or cf;size=r.pbSize or size;if r.pbTrans==1 then show=false end end
 local d=r.dept and rules.Departments[r.dept]
 if r.kind=='productionShell'and d then
  if n<order(d.second)then cf,size,show=clip(cf,size,'Z',d.z);show=show and n>=r.first end
  if n<order(d.shell)then
   local bottom=cf.Position.Y-size.Y/2
   if size.Y>3 then size=Vector3.new(size.X,size.Y*.7,size.Z);cf=CFrame.new(cf.Position.X,bottom+size.Y/2,cf.Position.Z)*cf.Rotation
   elseif cf.Position.Y>10 then cf+=Vector3.new(0,-4,0)end
   mat=Enum.Material.CorrodedMetal;color=Color3.fromRGB(121,108,87)
  end
 elseif r.kind=='hq'and n<order(235)then
  if r.path:find('SecondToTurn',1,true)or r.path:find('TurnToCrown',1,true)or r.path:find('UpperReturnLanding',1,true)or r.path:find('Floor3',1,true)then show=false
  else local good;cf,size,good=clip(cf,size,'Y',29.1);show=show and good end
 elseif r.kind=='wing'and n<order(192)then
  -- The retained rear frame stays on its grid; front annex opens at Professional.
  if cf.Position.Z<461 then show=false end
 elseif r.kind=='owner'then
  local maxZ=n<120 and 66 or(n<183 and 94 or 999)
  local good;cf,size,good=clip(cf,size,'Z',maxZ);show=show and good
 elseif r.kind=='receiving'and n<197 then
  if n<141 and cf.Position.Z<69 then show=false end
  if size.Y>8 then local bottom=cf.Position.Y-size.Y/2;local h=n<141 and math.min(size.Y,10)or math.min(size.Y,15);size=Vector3.new(size.X,h,size.Z);cf=CFrame.new(cf.Position.X,bottom+h/2,cf.Position.Z)*cf.Rotation
  elseif cf.Position.Y>12 then cf+=Vector3.new(0,n<141 and-9 or-4,0)end
 end
 if n<r.finish and r.finish>r.first then
  if r.material==Enum.Material.Wood or r.material==Enum.Material.WoodPlanks or r.material==Enum.Material.Limestone or r.material==Enum.Material.Marble then
   mat=Enum.Material.Concrete;color=Color3.fromRGB(141,139,127)
  elseif r.material==Enum.Material.Metal or r.material==Enum.Material.DiamondPlate then color=r.color:Lerp(Color3.fromRGB(101,110,109),n>=r.mid and r.mid>0 and .12 or .3)end
 end
 return show,cf,size,color,mat
end
function A.Status()
 setup();return {step=package:GetAttribute('Step'),builtMax=package:GetAttribute('BuiltMax'),total=240,active=package:GetAttribute('Active'),scope='ENVIRONMENT PREVIEW / NOT LIVE PURCHASES'}
end
function A.SetStep(n)
 setup();assert(package:GetAttribute('Active'),'Journey paused');assert(type(n)=='number'and n%1==0 and n>=0 and n<=package:GetAttribute('BuiltMax'),'Step has not passed build coverage')
 for _,v in package.Suspended:GetChildren()do assert(v.Value.Disabled,'Conflicting controller '..v.Name)end
 local preview=package.Preview.Value;local original=package.Institution.Value
 assert(preview.Parent==package or preview.Parent==workspace,'Preview ownership changed');assert(original.Parent==package or original.Parent==workspace or original.Parent==SS.SellCarsV5JourneyPreviewPackage,'Institution ownership changed')
 for _,r in records do
  local show,cf,size,color,mat=desired(r,n);local o=r.o
  o.CFrame=cf;o.Size=size;o.Color=color;o.Material=not show and r.material==Enum.Material.Glass and Enum.Material.SmoothPlastic or mat
  o.Transparency=show and r.trans or 1;o.CanCollide=show and r.collide;o.CanQuery=show and r.query;o.CanTouch=false
  for _,e in r.effects do e.o.Enabled=show and e.on end
 end
 original.Parent=package;preview.Parent=workspace;package:SetAttribute('Step',n)
 local spawn=package.Spawn.Value;spawn.CFrame=CFrame.lookAt(Vector3.new(3105,2.2,20),Vector3.new(3105,2.2,80))
 return A.Status()
end
function A.Benchmark()
 setup();package.Preview.Value.Parent=package;package.Institution.Value.Parent=workspace;package:SetAttribute('Step',-1);package.Spawn.Value.CFrame=package:GetAttribute('OriginalSpawn');return A.Status()
end
function A.Camera(n)
 setup();local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge);local count=0
 for _,r in records do if r.first==n or r.finish==n or r.mid==n or r.moveAt==n or r.retire==n then
  local show,cf,size=desired(r,n);if(show or r.retire==n)and r.trans<1 then min=min:Min(cf.Position-size/2);max=max:Max(cf.Position+size/2);count+=1 end
 end end
 if count==0 then return Vector3.new(3140,75,-15),Vector3.new(3060,4,110),0 end
 local center=(min+max)/2;local size=max-min;local extent=math.max(size.X,size.Z,size.Y)
 if extent>145 then return Vector3.new(3325,220,-35),Vector3.new(3105,5,265),count end
 local distance=math.clamp(extent*.9+12,18,125);local side=center.X<3105 and 1 or-1
 return center+Vector3.new(side*distance,distance*.65,-distance*.9),center,count
end
function A.Coverage()
 setup();local out={};for i=1,240 do local _,_,n=A.Camera(i);out[i]={step=i,visibleTargets=n,status=n>0 and'bound_geometry' or'NO_VISIBLE_DELTA'}end;return out
end
function A.DeltaAudit()
 setup();local counts={};for n=1,240 do counts[n]=0 end
 for _,r in records do if r.trans<1 then
  local ps,pc,pz,pcol,pm=desired(r,0)
  for n=1,240 do local s,c,z,col,m=desired(r,n);if(s or ps)and(s~=ps or c~=pc or z~=pz or col~=pcol or m~=pm)then counts[n]+=1 end;ps,pc,pz,pcol,pm=s,c,z,col,m end
 end end
 return counts
end
function A.Install()
 assert(game.RunService:IsStudio()and not game.RunService:IsRunning()and game.PlaceId==125334614375606,'Correct Studio Edit only');assert(not SS:FindFirstChild(NAME),'Already installed')
 local old=SS.SellCarsV5JourneyPreviewPackage;local original=old.Institution.Value;assert(original.Parent==workspace and #original:GetDescendants()==21864,'Restore protected Institution first')
 assert(not SS.SellCarsV5CollectorBackward01Package:GetAttribute('Applied'),'Restore Collector endpoint first')
 local p=Instance.new('Folder');p.Name=NAME;local suspended=Instance.new('Folder');suspended.Name='Suspended';suspended.Parent=p
 local root=original:Clone();root.Name='SellCars_Dealership_FullJourney';root.Parent=p
 local R=require(SS.SellCarsV5FullJourneyRules);local data=require(RS.SellCarsV5FullJourneyData)
 for _,o in root:GetDescendants()do
  if o:IsA('BaseScript')then o.Disabled=true end
  if o:IsA('BasePart')then local q=path(root,o);local b
   if o.Transparency>=1 and not o.CanCollide and not o:FindFirstChildWhichIsA('Light',true)then b={first=0,finish=0,kind='hidden'}else b=R.Bind(o,q)end
   if b.department and o.Size.Y<2 and o.Size.Z>20 and(o.Name:lower():find('floor')or o.Name:lower():find('slab'))then b.kind='productionShell'end
   stamp(o,b);o:SetAttribute('FJ_Path',q)
  end
 end
 -- Reuse the measured Collector predecessor, resolving duplicate names by sibling ordinal.
 local function counterpart(target)
  local chain={};local q=target
  while q~=original do local index=0;for _,s in q.Parent:GetChildren()do if s.Name==q.Name and s.ClassName==q.ClassName then index+=1 end;if s==q then break end end;table.insert(chain,1,{q.Name,q.ClassName,index});q=q.Parent end
  local current=root;for _,key in chain do local index=0;local found;for _,s in current:GetChildren()do if s.Name==key[1]and s.ClassName==key[2]then index+=1;if index==key[3]then found=s;break end end end;current=assert(found,'Clone correspondence')end;return current
 end
 for _,r in SS.SellCarsV5CollectorBackward01Package.Records:GetChildren()do local prop=r:GetAttribute('Property');if prop=='CFrame'or prop=='Size'or prop=='Transparency'then local q=counterpart(r.Value);q:SetAttribute('FJ_PB_'..prop,r:GetAttribute('Professional'))end end
 -- Same original pilot assemblies are cloned with explicit ownership and portable moves.
 local ids={};for _,e in data.Entries do ids[e.sourceOrder]=e.id end
 local starter,bundles=require(SS.SellCarsV5FirstLoopGeometry).Build(p,ids)
 starter.Name='Retained_Starter_Ancestry';starter.Parent=root
 for _,o in starter:GetDescendants()do if o:IsA('BasePart')then
  local b={first=0,finish=0,kind='starter'};local parent=o
  while parent~=starter do local num=parent:GetAttribute('UnlockStep');if num then b.first=num;b.finish=num;break end;parent=parent.Parent end
  local q=path(starter,o)
  if b.first==0 then b.retire=1 end
  if b.first==1 then b.retire=25;if o.Name=='Original_Shared_Slab'then b.retire=999;b.finish=14;o.CFrame-=Vector3.new(0,.3,0)end end
  if b.first==2 then b.retire=26 end
  if b.first==3 then b.moveAt=35;b.move=Vector3.new(0,0,55);b.retire=82 end
  if b.first==4 then b.retire=41 end
  if b.first==5 then b.moveAt=60;b.move=Vector3.new(145,0,58);b.retire=108 end
  if b.first==6 then b.retire=30 end
  stamp(o,b);o:SetAttribute('FJ_Path','Starter/'..q)
 end end
 local extra=require(SS.SellCarsV5FullJourneyExtras);extra.Build(root,stamp,ids)
 A.BuildInfrastructure(root,extra,stamp)
 object(p,'Preview',root);object(p,'Institution',original);object(p,'Spawn',old.Spawn.Value);p:SetAttribute('OriginalSpawn',old:GetAttribute('OriginalSpawn'));p:SetAttribute('OriginalDescendants',21864)
 local scripts={game.ServerScriptService.SellCarsV5JourneyPreviewServer,game.StarterPlayer.StarterPlayerScripts.SellCarsV5JourneyPreviewPanel,game.StarterPlayer.StarterPlayerScripts.SellCarsV5GuidedTourPanel}
 for _,s in scripts do local v=object(suspended,s.Name,s);v:SetAttribute('WasDisabled',s.Disabled)end
 p:SetAttribute('BuiltMax',0);p:SetAttribute('Step',-1);p:SetAttribute('Active',true);p:SetAttribute('Version',A.Version);p.Parent=SS
 for _,s in scripts do s.Disabled=true end
 old.Preview.Value.Parent=old;setup();return A.Status()
end
function A.BuildInfrastructure(root,E,reg)
 local all=Instance.new('Model');all.Name='Journey_Structural_Transitions';all.Parent=root
 local function group(n,name,retire,fn)
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);m.Parent=all;fn(m)
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=n,finish=n,retire=retire or 999,kind='structure'})end end
 end
 local function slab(m,name,x,z,w,d,color)local p=E.Box(m,name,x,1.64,z,w,.2,d,color or'cream',Enum.Material.Concrete);p.CanCollide=true;return p end
 group(13,'Retained_Starter_Frame',41,function(m)
  for _,x in {3023,3061}do for _,z in {121,143}do E.Box(m,'BoltedStarterColumn',x,6.2,z,.5,8.4,.5,'wood')end end
  E.Box(m,'PatchedCanopy',3042,10.6,132,40,.35,25,'steel',Enum.Material.CorrodedMetal)
  for i=1,12 do E.Box(m,'Corrugation',3022+i*3.2,10.85,132,.1,.16,25,'silver')end
 end)
 group(14,'Sealed_Slab_And_Drain',41,function(m)slab(m,'InheritedSlabFinish',3041,132,42,26);for i=1,12 do E.Box(m,'FlushDrainGrille',3023+i*3,1.79,144,1.9,.05,.5,'steel')end end)
 group(19,'Ready_Stock_Edge',30,function(m)for _,z in {74,90}do E.Box(m,'SaleEdge',3073,1.84,z,22,.03,.2,'cream')end;E.Sign(m,'READY STOCK / CUSTOMER HANDOVER',3073,4,93,10)end)
 group(20,'Rough_Boundary',65,function(m)for _,x in {2982,3090}do for z=55,160,15 do E.Box(m,'ScrapFencePost',x,3,z,.4,2.5,.4,'wood');E.Box(m,'ScrapPanel',x,3,z+6,.15,1.8,12,'steel',Enum.Material.CorrodedMetal)end end end)
 group(27,'Seller_Walk',143,function(m)slab(m,'ProtectedSellerApproach',3038,92,5,30);for _,z in {82,96}do E.Box(m,'WalkBollard',3034,3,z,.35,2.5,.35)end end)
 group(68,'Protected_Service_Crossings',999,function(m)for _,z in {167,232,297,373}do for _,x in {3076,3135}do slab(m,'FlushServiceCover',x,z,4,2,'steel');for i=1,4 do E.Box(m,'RecessedHandle',x-1.5+i*.6,1.76,z,.25,.04,.15,'dark')end end end end)
 group(70,'Rear_Drained_Apron',193,function(m)slab(m,'ReceivingApron',3014,423,64,24);for i=1,10 do E.Box(m,'ReceivingDrain',2985+i*5.5,1.77,434,3,.03,.5,'steel')end end)
 group(78,'Mechanical_Masonry_Skirting',157,function(m)for _,z in {179.25,194.75}do E.Box(m,'PortalBrickPlinth',3066,2.6,z,2,1.8,2,'red',Enum.Material.Brick)end end)
 group(96,'Paint_Preparation_Edge',170,function(m)slab(m,'SingleCellPreparationFinish',3187,319,78,22);E.Box(m,'MaskingServicePlinth',3216,2.1,309,9,.55,3,'steel');E.Kit(m,'paint',3216,309)end)
 group(153,'Professional_HQ_Cap',235,function(m)
  E.Box(m,'CompleteTwoStoreyRoof',3105,29.45,501,80,.7,44,'steel');for _,z in {479,523}do E.Box(m,'WeatherFascia',3105,29.55,z,80,.5,.3,'silver')end
  local p=slab(m,'ClosedUpperStairPocket',3083,493,8,4);p.CFrame=CFrame.new(3083,17.63,493)
 end)
 group(187,'Collector_Lower_Roof',233,function(m)
  E.Box(m,'CompleteCentralRoofCassette',3105,33.53,430,30,.6,62,'steel');E.Box(m,'CassetteSoffit',3105,33.12,430,30,.2,61,'cream')
 end)
end
function A.Deactivate()
 setup();assert(not game.RunService:IsRunning(),'Stop Play first');A.Benchmark()
 local old=SS.SellCarsV5JourneyPreviewPackage;package.Institution.Value.Parent=workspace;old:SetAttribute('Step',-1)
 for _,v in package.Suspended:GetChildren()do v.Value.Disabled=v:GetAttribute('WasDisabled')end
 for _,s in {game.ServerScriptService:FindFirstChild('SellCarsV5FullJourneyServer'),game.StarterPlayer.StarterPlayerScripts:FindFirstChild('SellCarsV5FullJourneyPanel')}do if s then s.Disabled=true end end
 package:SetAttribute('Active',false);return {restored=true}
end
return A

