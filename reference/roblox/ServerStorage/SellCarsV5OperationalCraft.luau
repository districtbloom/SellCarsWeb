-- OC: scene-fitted details and explicitly non-gameplay equipment demonstrations.
local M={Version='2026-09-09.OC06',RootName='OC_OperationalCraft'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local P={steel=C(93,106,108),silver=C(170,178,172),ink=C(36,46,48),gold=C(160,127,78),stone=C(171,161,141),wood=C(124,96,65),green=C(85,178,136)}
local function path(root,p)local a={}while p~=root do table.insert(a,1,p.Name);p=p.Parent end;return table.concat(a,'/')end
local function save(rec,p,k,v)local q=Instance.new('ObjectValue');q.Name=string.format('%04d',#rec:GetChildren()+1);q.Value=p;q:SetAttribute('Key',k);q:SetAttribute('HadValue',p:GetAttribute(k)~=nil);q:SetAttribute('Before',p:GetAttribute(k));q.Parent=rec;p:SetAttribute(k,v)end
local function box(m,n,f,s,col,mat)
 local p=Instance.new('Part');p.Name=n;p.CFrame=f;p.Size=s;p.Color=P[col]or col or P.steel;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.TopSurface=0;p.BottomSurface=0;p.CastShadow=math.min(s.X,s.Y,s.Z)>.1;p.Parent=m;return p
end
local function stamp(root,p,n,retire)
 for k,v in {FJ_First=n,FJ_Finish=n,FJ_Mid=0,FJ_Kind='extra',FJ_Retire=retire or 999,FJ_MoveAt=999,FJ_Move=V(),FJ_CF=p.CFrame,FJ_Size=p.Size,FJ_Color=p.Color,FJ_Material=p.Material.Name,FJ_Transparency=p.Transparency,FJ_Collide=false,FJ_Query=false,FJ_Touch=false}do p:SetAttribute(k,v)end;p:SetAttribute('FJ_Path',path(root,p))
end
local function batch(root,n)
 local owner=root:FindFirstChild(M.RootName);if not owner then owner=Instance.new('Model');owner.Name=M.RootName;owner:SetAttribute('Version',M.Version);owner.Parent=root end
 assert(not owner:FindFirstChild(n),'Already built '..n);local b=Instance.new('Model');b.Name=n;b.Parent=owner;return b
end
local function group(root,b,n,name,support,fn)
 local g=Instance.new('Model');g.Name=string.format('P%03d_%s_%02d',n,name,#b:GetChildren()+1);g.Parent=b;g:SetAttribute('FirstStep',n);g:SetAttribute('PurchaseId',require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries[n].id);g:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY')
 if support then local v=Instance.new('ObjectValue');v.Name='ExistingSupport';v.Value=support;v.Parent=g;g:SetAttribute('SupportPath',path(root,support))end
 fn(g);local count=0;for _,p in g:GetDescendants()do if p:IsA('BasePart')then stamp(root,p,n,support and support:GetAttribute('FJ_Retire'));count+=1 end end
 local cf,sz=g:GetBoundingBox();g.WorldPivot=cf;g:SetAttribute('ReplacementPivot',cf);g:SetAttribute('ReplacementBounds',sz);g:SetAttribute('Parts',count);return g
end
local function eligible(p)return p:IsA('BasePart')and(p:GetAttribute('FJ_Transparency')or 1)<.95 and(p:GetAttribute('FJ_Retire')or 0)>(p:GetAttribute('FJ_First')or 999)and(p:GetAttribute('FJ_MoveAt')or 999)>240 end
local function sorted(root,predicate)local a={};for _,p in root:GetDescendants()do if eligible(p)and predicate(p)then table.insert(a,p)end end;table.sort(a,function(x,y)local a,b=path(root,x),path(root,y);return a==b and tostring(x.Position)<tostring(y.Position)or a<b end);return a end
function M.Equipment(root,rec)
 local b=batch(root,'OC01_Equipment_Demonstration');local fans=0
 for _,p in sorted(root,function(p)return p.Name=='BroadFanBlade'end)do
  local hub=assert(p.Parent:FindFirstChild('FanHub'));save(rec,p,'OC_Motion','FAN');save(rec,p,'OC_Pivot',CF(hub.Position));save(rec,p,'OC_Rest',p:GetAttribute('FJ_CF'));fans+=1
 end
 local nozzles=sorted(root,function(p)return p.Name=='TopFanNozzle'end)
 for _,p in nozzles do
  group(root,b,p:GetAttribute('FJ_First'),'Wash_Rinse_Demonstration',p,function(g)
   local a=box(g,'RinseEmitter',CF(p.Position-V(0,.28,0)),V(.05,.05,.05),'silver');a.Transparency=1;a:SetAttribute('OC_Motion','RINSE')
   local from=Instance.new('Attachment');from.Name='Outlet';from.Parent=a;local to=Instance.new('Attachment');to.Name='RinseEnd';to.Position=V(0,-5.8,0);to.Parent=a
   local beam=Instance.new('Beam');beam.Name='BoundedRinse';beam.Attachment0=from;beam.Attachment1=to;beam.FaceCamera=true;beam.Width0=.025;beam.Width1=.48;beam.Segments=1;beam.Color=ColorSequence.new(C(172,208,215));beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,.96)});beam.LightEmission=.1;beam.Enabled=false;beam.Parent=a
  end)
 end
 for _,p in sorted(root,function(p)return p.Name=='ScopeScreen'end)do
  group(root,b,p:GetAttribute('FJ_First'),'Live_Diagnostic_Trace',p,function(g)
   local x=p.Size.X/2+.015
   for i=1,14 do local z=-p.Size.Z*.43+(i-1)*p.Size.Z*.86/13;local q=box(g,'OscilloscopeTrace',p.CFrame*CF(x,.18*math.sin(i*.8),z),V(.018,.025,.085),'green',Enum.Material.Neon);q:SetAttribute('OC_Motion','TRACE');q:SetAttribute('OC_Index',i);q:SetAttribute('OC_Center',p.CFrame*CF(x,0,z))end
  end)
 end
 b:SetAttribute('FanBlades',fans);b:SetAttribute('RinseEmitters',#nozzles)
 return {fanBlades=fans,rinseEmitters=#nozzles}
end
function M.Repeated(root)
 local b=batch(root,'OC02_Repeated_Craft');local tally={}
 local selectors={
  worktop=function(p)return p.Name=='SteelWorktop'or p.Name=='AntiStaticWorktop'or p.Name=='EditorialWorktop'or p.Name=='TelemetryWorktop'end,
  cabinet=function(p)return p.Name=='CabinetDoor'or p.Name=='CabinetBody'end,
  shelf=function(p)return p.Name=='RackShelf'or p.Name=='HardwareShelf'or p.Name=='CleanShelf'or p.Name=='EquipmentShelf'end,
  light=function(p)return p.Name=='ShieldedTaskHousing'or p.Name=='TaskLuminaireHousing'end,
  planter=function(p)return p.Name=='Planter'end,
 }
 for _,family in {'worktop','cabinet','shelf','light','planter'}do
  local targets=sorted(root,selectors[family]);tally[family]=#targets
  for _,p in targets do
   local f=p:GetAttribute('FJ_CF');local s=p:GetAttribute('FJ_Size');local n=p:GetAttribute('FJ_First')
   group(root,b,n,family..'_Fitted_Finish',p,function(g)
    if family=='worktop'then
     for _,x in {-s.X/2,s.X/2}do box(g,'FoldedWorktopEdge',f*CF(x,0,0),V(.075,s.Y+.08,s.Z+.08),'silver')end
     for _,z in {-s.Z/2,s.Z/2}do box(g,'FoldedWorktopEnd',f*CF(0,0,z),V(s.X,.18,.075),'silver')end
     for _,x in {-s.X/2+.3,s.X/2-.3}do for _,z in {-s.Z/2+.3,s.Z/2-.3}do box(g,'FlushWorktopFixing',f*CF(x,s.Y/2+.014,z),V(.075,.025,.075),'ink')end end
    elseif family=='cabinet'then
     -- Workside door faces: shallow folded vents, not extra generic handles.
     local thinX=s.X<s.Z;local w=thinX and s.Z or s.X;local face=thinX and CF(-s.X/2-.035,0,0)*CFrame.Angles(0,-math.pi/2,0)or CF(0,0,-s.Z/2-.035)
     for i=1,5 do box(g,'FoldedVentLouvre',f*face*CF(0,-s.Y*.28+i*.14,0),V(w*.57,.065,.055),'ink')end
     for _,x in {-w*.4,w*.4}do for _,y in {-s.Y*.42,s.Y*.42}do box(g,'CaptiveFaceScrew',f*face*CF(x,y,-.01),V(.07,.07,.035),'silver')end end
    elseif family=='shelf'then
     for _,x in {-s.X/2,s.X/2}do box(g,'FoldedShelfLip',f*CF(x,.04,0),V(.09,.25,s.Z),'steel')end
     for _,z in {-s.Z/2,s.Z/2}do box(g,'ShelfEndFold',f*CF(0,.04,z),V(s.X,.25,.09),'steel')end
     for _,x in {-s.X*.42,s.X*.42}do box(g,'ShelfUnderStiffener',f*CF(x,-s.Y/2-.11,0),V(.1,.22,s.Z*.92),'ink')end
    elseif family=='light'then
     for i=1,6 do local x=-s.X*.43+(i-1)*s.X*.86/5;box(g,'TaskLightGlareBaffle',f*CF(x,-s.Y/2-.1,0),V(.045,.2,s.Z*.84),'ink')end
     for _,x in {-s.X/2,s.X/2}do box(g,'TaskLightEndPlate',f*CF(x,0,0),V(.055,s.Y+.08,s.Z+.08),'steel')end
    else
     for _,x in {-s.X/2,s.X/2}do box(g,'FoldedPlanterRim',f*CF(x,s.Y/2,0),V(.16,.12,s.Z+.16),'steel')end
     for _,z in {-s.Z/2,s.Z/2}do box(g,'FoldedPlanterRim',f*CF(0,s.Y/2,z),V(s.X,.12,.16),'steel')end
     for _,x in {-s.X*.32,s.X*.32}do box(g,'PlanterDrainFoot',f*CF(x,-s.Y/2+.08,0),V(.3,.16,s.Z*.75),'ink')end
    end
   end)
  end
 end
 b:SetAttribute('Families',game.HttpService:JSONEncode(tally));return tally
end
function M.People(root,rec)
 local count=0;for _,m in root.EL_EverydayLife.R6_Cast:GetChildren()do
  local kind=m:GetAttribute('EL_Activity');if m:FindFirstChild('HandheldControl')then kind='CONTROL'elseif m:FindFirstChild('FinishSwatch1')then kind='SWATCH'elseif m:FindFirstChild('MeasuringRule')then kind='MEASURE'elseif m:FindFirstChild('InspectionLightGrip')then kind='CHECK'elseif m.Name=='Dispatcher'then kind='RADIO'elseif m.Name=='DeliveryHost'then kind='HANDOVER'elseif m:FindFirstChild('HeldBoard')and kind~='CONVERSE'then kind='RECORD'end
  save(rec,m,'OC_Activity',kind);count+=1
 end;return count
end
function M.Architecture(root,rec)
 local b=batch(root,'OC04_Workshop_Roof_Identity');local rules=require(game.ServerStorage.SellCarsV5FullJourneyRules).Departments
 local profiles={Mechanical={4,12,'steel'},Body_Restoration={3.6,15,'stone'},Tune_Performance={4.8,10,'ink'},Paint_Exterior={5,17,'silver'},Wash={2.7,12,'silver'},Detail_QC={2.5,16,'stone'},Photo_Listing={2.8,19,'ink'}}
 for _,roof in sorted(root,function(p)return p.Name=='OpenCanopy'and p:GetAttribute('FJ_Department')end)do
  local name=roof:GetAttribute('FJ_Department');local d=rules[name];local a=profiles[name];local west=d.x<3105
  local f=roof:GetAttribute('FJ_CF');local s=roof:GetAttribute('FJ_Size');local top=f.Y+s.Y/2
  -- Roof-mounted service enclosures: no fictitious skylight through an opaque slab.
  local x=d.x+(west and 37 or-37);local z=d.z-12
  group(root,b,d.pro,name..'_Raised_Service_Monitor',roof,function(g)
   local w,h,length=7,a[1],a[2];local base=CF(x,top,z)
   box(g,'RoofServiceFlashing',base*CF(0,.12,0),V(w+1,.24,length+1),'silver')
   box(g,'MonitorInsulatedCurb',base*CF(0,.5,0),V(w,.8,length),'ink')
   for _,xx in {-w/2,w/2}do
    box(g,'MonitorCornerFrame',base*CF(xx,h/2,0),V(.15,h,length),a[3])
    for i=1,5 do box(g,'ServiceVentLouvre',base*CF(xx+(xx>0 and .1 or-.1),.7+i*(h-.9)/6,0),V(.23,.16,length-.35),'ink')end
   end
   for _,zz in {-length/2,length/2}do box(g,'MonitorEndClosure',base*CF(0,h/2,zz),V(w,h,.15),a[3])end
   box(g,'RaisedMonitorWeatherCap',base*CF(0,h+.12,0),V(w+.8,.24,length+.8),'steel')
   for i=-1,1 do box(g,'CapStandingFold',base*CF(i*2,h+.29,0),V(.08,.1,length+.7),'silver')end
   -- Clear identification without additional text: one restrained departmental strip.
   box(g,'MonitorFoldedEave',base*CF(west and w/2+.45 or-w/2-.45,h-.18,0),V(.1,.25,length+.4),'gold')
  end)
 end
 local changed=0
 for _,p in sorted(root,function(p)return p:GetAttribute('FJ_Kind')=='productionShell'and(p.Name=='OpenCanopy'or p.Name=='OuterWall')end)do
  local d=rules[p:GetAttribute('FJ_Department')or''];if d then
   local stages=game.HttpService:JSONDecode(p:GetAttribute('FJ_StagePalette')or'[]');local map={};for _,s in stages do map[s.step]=s end
   local isRoof=p.Name=='OpenCanopy';local clean=d==rules.Paint_Exterior or d==rules.Detail_QC or d==rules.Photo_Listing
   map[d.pro]={step=d.pro,color=isRoof and{73,76,71}or clean and{199,199,183}or{189,180,159},material=isRoof and'Metal'or'Concrete'}
   map[d.final]={step=d.final,color=isRoof and{53,58,55}or clean and{219,215,198}or{210,199,174},material=isRoof and'Metal'or'Concrete'}
   local out={}for _,s in map do table.insert(out,s)end;table.sort(out,function(a,b)return a.step<b.step end);save(rec,p,'FJ_StagePalette',game.HttpService:JSONEncode(out));changed+=1
  end
 end
 -- New repeated fixtures share an earned finish; established equipment colours stay intact.
 for _,g in root[M.RootName].OC02_Repeated_Craft:GetChildren()do
  local n=g:GetAttribute('FirstStep');local support=g.ExistingSupport.Value;local _,dept=require(game.ServerStorage.SellCarsV5FullJourneyRules).Department(path(root,support));local finish=dept and dept.final or support:GetAttribute('FJ_Finish')or n
  for _,p in g:GetDescendants()do if p:IsA('BasePart')then
   local final=p.Color;local worn=final:Lerp(P.wood,.16);local stages={{step=n,color={worn.R*255,worn.G*255,worn.B*255},material=p.Material.Name}}
   if finish>n and finish<=240 then table.insert(stages,{step=finish,color={final.R*255,final.G*255,final.B*255},material=p.Material.Name})end
   p:SetAttribute('FJ_StagePalette',game.HttpService:JSONEncode(stages))
  end end
 end
 b:SetAttribute('ExistingMaterialTargets',changed);return changed
end
function M.Build(root,reg,ids,rec)M.Equipment(root,rec);M.Repeated(root);M.People(root,rec);M.Architecture(root,rec)end
function M.Manifest(root)
 local out={version=M.Version,batches={}};for _,b in root[M.RootName]:GetChildren()do local row={name=b.Name,groups={}};for _,g in b:GetChildren()do if g:IsA('Model')then local cf=g:GetAttribute('ReplacementPivot');local s=g:GetAttribute('ReplacementBounds');table.insert(row.groups,{name=g.Name,step=g:GetAttribute('FirstStep'),id=g:GetAttribute('PurchaseId'),support=g:GetAttribute('SupportPath'),parts=g:GetAttribute('Parts'),pivot={cf:GetComponents()},bounds={s.X,s.Y,s.Z}})end end;table.insert(out.batches,row)end;return out
end
return M

