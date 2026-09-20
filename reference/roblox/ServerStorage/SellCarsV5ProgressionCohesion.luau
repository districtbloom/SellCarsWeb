-- PC01-PC05: architectural continuity around the accepted 240-pad journey.
-- Native geometry and staged material recipes only. No new gameplay/capacity.
local M={Version='2026-09-09.PC05',RootName='PC_ProgressionCohesion'}
local V,CF,A=Vector3.new,CFrame.new,CFrame.Angles
local H=game:GetService('HttpService')
local C=Color3.fromRGB
local P={earth=C(139,119,90),gravel=C(161,148,124),stone=C(189,180,158),steel=C(102,111,108),silver=C(174,181,174),dark=C(53,64,66),wood=C(132,102,68),oxide=C(145,75,50),cream=C(207,199,176),sage=C(118,124,87),teal=C(66,112,117),gold=C(173,136,77)}
local E=Enum.Material
local function box(m,n,x,y,z,w,h,d,col,mat,rot)
 local p=Instance.new('Part');p.Name=n;p.Size=V(w,h,d);p.CFrame=CF(x,y,z)*(rot or CFrame.identity);p.Color=P[col]or col or P.steel;p.Material=mat or E.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(w,h,d)>.1;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local function rod(m,n,a,b,w,col)
 local p=box(m,n,0,0,0,w,w,(b-a).Magnitude,col);p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function vec(c)return {c.R*255,c.G*255,c.B*255}end
local function path(root,p)local t={}while p~=root do table.insert(t,1,p.Name);p=p.Parent end return table.concat(t,'/')end
local function save(folder,p,k)
 local v=Instance.new('ObjectValue');v.Name=string.format('%04d',#folder:GetChildren()+1);v.Value=p;v:SetAttribute('Key',k);v:SetAttribute('HadValue',p:GetAttribute(k)~=nil);v:SetAttribute('Before',p:GetAttribute(k));v.Parent=folder
end
local function patchPalette(folder,p,changes)
 save(folder,p,'FJ_StagePalette');local old=H:JSONDecode(p:GetAttribute('FJ_StagePalette')or'[]');local map={}
 for _,s in old do map[s.step]=s end
 for _,s in changes do map[s.step]=s end
 local out={}for _,s in map do table.insert(out,s)end table.sort(out,function(a,b)return a.step<b.step end)
 p:SetAttribute('FJ_StagePalette',H:JSONEncode(out))
end
local function stage(n,col,mat)return {step=n,color=vec(P[col]or col),material=mat or'Metal'}end
local function layers(root,batch)
 local owner=root:FindFirstChild(M.RootName);if not owner then owner=Instance.new('Model');owner.Name=M.RootName;owner:SetAttribute('Version',M.Version);owner.Parent=root end
 assert(not owner:FindFirstChild(batch),'Batch already built '..batch)
 local m=Instance.new('Model');m.Name=batch;m.Parent=owner;return m
end
local function group(root,batch,n,name,retire,reg,ids,fn)
 local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);m:SetAttribute('PurchaseId',ids[n]);m:SetAttribute('FirstStep',n);m:SetAttribute('RetireStep',retire or 999);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY');m.Parent=batch
 fn(m)
 local count=0
 for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=n,finish=n,retire=retire or 999,kind='extra'});p:SetAttribute('FJ_Path',path(root,p));count+=1 end end
 local cf,sz=m:GetBoundingBox();m.WorldPivot=cf;m:SetAttribute('ReplacementPivot',cf);m:SetAttribute('ReplacementBounds',sz);m:SetAttribute('Parts',count);return m
end
local function deps()
 local out={}for name,d in require(game.ServerStorage.SellCarsV5FullJourneyRules).Departments do local r=table.clone(d);r.name=name;r.west=d.x<3105;r.wall=r.west and 2982 or 3228;r.face=r.west and 3066 or 3144;r.accent=name=='Body_Restoration'and'oxide'or name=='Mechanical'and'oxide'or name=='Tune_Performance'and'dark'or name=='Paint_Exterior'and'cream'or name=='Detail_QC'and'sage'or'teal';table.insert(out,r)end
 table.sort(out,function(a,b)return a.start<b.start end);return out
end
local function grass(m,x,z,scale)
 for i=1,7 do local a=i*math.pi*2/7;rod(m,'DryNativeBunchgrass',V(x,1.66,z),V(x+math.cos(a)*scale,2.2+scale*.5+(i%2)*.2,z+math.sin(a)*scale),.06,'sage')end
 local p=box(m,'LimestoneScatter',x+1.6,1.85,z+.3,1.4,.6,1,'stone',E.Rock);p.Shape=Enum.PartType.Ball
end
function M.PC01(root,reg,ids,recovery)
 local batch=layers(root,'PC01_Beginnings')
 group(root,batch,13,'Repaired_Starter_Shelter',41,reg,ids,function(m)
  for i=1,3 do local x=3029+i*5;box(m,'ReusedGalvanisedRoofPatch',x,10.805,130+i*1.4,4.7,.055,5,'silver');for _,dz in {-2.2,2.2}do box(m,'PatchLapFixing',x,10.844,130+i*1.4+dz,4.2,.04,.08,'dark')end end
 end)
 group(root,batch,34,'Reserved_Land_Beside_Footpath',123,reg,ids,function(m)
  for _,z in {209,275,341}do for _,x in {3095,3115}do
   box(m,'DryReservationBed',x,1.53,z,9,.1,27,'earth',E.Ground)
   for _,dx in {-4.5,4.5}do box(m,'ReclaimedTimberGroundEdge',x+dx,1.66,z,.14,.14,27,'wood',E.Wood)end
   for _,dz in {-13.5,13.5}do box(m,'ReclaimedTimberGroundEdge',x,1.66,z+dz,9,.14,.14,'wood',E.Wood)end
   grass(m,x-2,z-6,.65);grass(m,x+1,z+7,.8)
  end end
 end)
 for _,d in deps()do
  group(root,batch,d.start,d.name..'_Active_Work_Strip',d.shell,reg,ids,function(m)
   local x=d.west and 3003 or 3207
   box(m,'CompactedEquipmentApron',x,1.64,d.z-13,40,.32,26,'gravel',E.Pebble)
   for _,z in {d.z-25.7,d.z-.3}do box(m,'ServicePadTimberEdge',x,1.84,z,40,.12,.12,'wood',E.Wood)end
   -- Repairs sit on the reduced-height first-bay roof and disappear with the permanent shell.
   for i=1,4 do local px=d.x-27+(i-1)*17;box(m,'GalvanisedRoofRepair',px,12.662,d.z-12,10,.045,8,'silver');for _,dz in {-3.7,3.7}do box(m,'RoofRepairFold',px,12.701,d.z-12+dz,10,.035,.07,'dark')end end
  end)
  group(root,batch,d.start,d.name..'_Future_Bay_Reserve',d.second,reg,ids,function(m)
   local x=d.west and 3000 or 3210
   box(m,'PreparedFutureWorkside',x,1.55,d.z+12,30,.14,20,'earth',E.Ground)
   for _,dz in {-9.8,9.8}do box(m,'LowReserveTimber',x,1.68,d.z+12+dz,29,.12,.12,'wood',E.Wood)end
   -- Stored sheets sit at the outer workside edge, not in a car or pedestrian lane.
   local sx=d.west and 2987.7 or 3222.3
   for _,dz in {-2,2}do box(m,'SheetStackBearer',sx,1.83,d.z+12+dz,4,.3,.5,'wood',E.Wood)end
   for i=1,4 do box(m,'ReusableConstructionSheet',sx,2+i*.075,d.z+12,4.5,.05,6,'steel')end
  end)
 end
 -- Only first-stage finish changes: preserve all established Dedicated/Pro/Institution recipes.
 local count=0
 for _,p in root:GetDescendants()do if p:IsA('BasePart')and p:GetAttribute('FJ_Kind')=='productionShell'and(p:GetAttribute('FJ_Transparency')or 1)<1 then
  local first=p:GetAttribute('FJ_First');local d=require(game.ServerStorage.SellCarsV5FullJourneyRules).Departments[p:GetAttribute('FJ_Department')or'']
  if d and(p.Name=='OpenCanopy'or p.Name=='OuterCornerColumn'or p.Name=='PortalPostA'or p.Name=='PortalPostB')then
   local old=H:JSONDecode(p:GetAttribute('FJ_StagePalette')or'[]');local changes={stage(first,p.Name=='OpenCanopy'and'cream'or'steel')}
   if #old==0 then table.insert(changes,stage(d.shell,'dark'));table.insert(changes,stage(d.pro,'dark'));table.insert(changes,stage(d.final,p.Color,p.Material.Name))end
   patchPalette(recovery,p,changes);count+=1
  end
 end end
 batch:SetAttribute('PaletteTargets',count);return count
end
local function clerestory(m,d,z)
 local wall=d.wall
 box(m,'ContinuousClerestorySill',wall,12.62,z,1.8,.18,25.5,'dark')
 box(m,'ContinuousClerestoryHead',wall,15.17,z,1.8,.2,25.5,'dark')
 for i=0,3 do local zz=z-12.6+i*8.4;box(m,'UpperWallMullion',wall,13.88,zz,1.6,2.4,.16,'dark')end
 for i=1,3 do local zz=z-16.8+i*8.4;local p=box(m,'DaylightClerestoryGlass',wall,13.88,zz,.16,2.28,8.2,'teal',E.Glass);p.Transparency=.42 end
 for _,zz in {z-7.75,z+7.75}do
  box(m,'PortalFoundationCollar',d.face,1.8,zz,2.1,.54,2.1,'stone',E.Concrete)
  box(m,'PortalBasePlate',d.face,2.09,zz,1.95,.075,1.95,'steel')
  for _,dx in {-.77,.77}do for _,dz in {-.77,.77}do box(m,'FoundationAnchor',d.face+dx,2.17,zz+dz,.12,.12,.12,'silver')end end
 end
 box(m,'CompletedCanopyEdge',d.face-.4*(d.west and 1 or-1),15.95,z,.26,.8,25.5,'dark')
 box(m,'DepartmentEdgeInlay',d.face+(d.west and-.23 or .23),15.65,z,.045,.16,24.8,d.accent)
end
function M.PC02(root,reg,ids)
 local batch=layers(root,'PC02_Permanent_Workshops')
 for _,d in deps()do
  group(root,batch,d.shell,d.name..'_Permanent_Clerestory',999,reg,ids,function(m)clerestory(m,d,d.z-12)end)
  group(root,batch,d.second,d.name..'_Second_Bay_Construction',999,reg,ids,function(m)clerestory(m,d,d.z+12)end)
 end
end
function M.PC03(root,reg,ids,recovery)
 local batch=layers(root,'PC03_Crew_Continuity');local targets=0;local roles=0
 for _,r in root.EL_EverydayLife.R6_Cast:GetChildren()do
  local d
  for _,row in deps()do if r.Name==row.name..'_1'or r.Name==row.name..'_2'then d=row;break end end
  if d then roles+=1
   for _,name in {'Torso','Left Arm','Right Arm','ChestPocket'}do local p=r:FindFirstChild(name)
    if p and p:IsA('BasePart')then
     local first=p:GetAttribute('FJ_First');local original=p:GetAttribute('FJ_Color');local practical=original:Lerp(P.earth,.22)
     local pro=name=='ChestPocket'and P[d.accent]or original:Lerp(P.dark,.3)
     patchPalette(recovery,p,{stage(first,practical,'Fabric'),stage(math.max(first,d.pro),pro,'Fabric'),stage(math.max(first,d.final),original,'Fabric')});targets+=1
    end
   end
  end
 end
 batch:SetAttribute('PaletteTargets',targets);batch:SetAttribute('ProductionRoles',roles)
 -- Read-only continuity proof: do not create duplicate founding objects or equipment.
 for _,name in {'P024_First_Handmade_Sign','P063_Fridge_And_Analog_Radio','P186_Founder_Memory_Shelf','P232_Founding_Spanner_Exhibit'}do
  assert(root.ST_Character:FindFirstChild(name),'Missing inherited story '..name)
 end
 return targets
end
function M.PC04(root,reg,ids)
 local batch=layers(root,'PC04_Professional_Rhythm')
 for _,d in deps()do
  group(root,batch,d.pro,d.name..'_Coordinated_Solar_Shade',999,reg,ids,function(m)
   local dir=d.west and 1 or-1
   for _,center in {d.z-12,d.z+12}do
    -- Front edge is above the complete entry, attached to the existing canopy.
    for _,zz in {center-10,center+10}do rod(m,'ShadeCantileverBrace',V(d.face-dir*2,16.3,zz),V(d.face+dir*.7,15.12,zz),.16,'dark')end
    box(m,'ShadeFrontRail',d.face+dir*.65,15.15,center,.16,.2,23,'dark')
    for i=0,7 do box(m,'SunshadeBlade',d.face-dir*.25,15.35,center-10.5+i*3,2.4,.13,2.25,'steel',E.Metal,A(0,0,dir*.22))end
   end
  end)
 end
end
function M.PC05(root,reg,ids)
 local batch=layers(root,'PC05_Institution_Finish')
 for _,d in deps()do
  group(root,batch,d.final,d.name..'_Weathering_And_Craft_Caps',999,reg,ids,function(m)
   for _,center in {d.z-12,d.z+12}do
    for i=0,3 do local zz=center-12.6+i*8.4;for _,y in {12.7,15.1}do box(m,'GlazingJointCover',d.wall+(d.west and 1 or-1)*.87,y,zz,.08,.2,.35,'gold')end end
   end
   local outside=d.wall+(d.west and-1.15 or 1.15);local z=d.z-23
   rod(m,'RoofDrainLeader',V(outside,15.8,z),V(outside,2.3,z),.18,'dark')
   for _,y in {3,7,11,15}do box(m,'DrainWallStandOff',d.wall,y,z,2.3,.1,.18,'steel');box(m,'DrainClamp',outside,y,z,.26,.2,.26,'gold')end
   rod(m,'DrainShoe',V(outside,2.3,z),V(outside+(d.west and-1 or 1)*.55,1.85,z),.2,'dark')
   box(m,'LimestoneSplashBlock',outside+(d.west and-.35 or .35),1.66,z,1.15,.32,2.1,'stone',E.Concrete)
  end)
 end
 -- Pick one actual mature roof per non-production district. No guessed building transforms.
 local selected={};local final={owner=227,parts=202,operations=238,hq=235}
 for _,p in root:GetDescendants()do if p:IsA('BasePart')and(p:GetAttribute('FJ_Transparency')or 1)<1 then
  local kind=p:GetAttribute('FJ_Kind');local sz=p:GetAttribute('FJ_Size');local cf=p:GetAttribute('FJ_CF')
  local district=kind=='wing'and(p:GetFullName():find('Parts_Logistics',1,true)and'parts'or'operations')or kind
  if final[district]and sz and cf and (p.Name=='OwnerRoof'or p.Name=='OriginalRoof'or p.Name=='HQCrownRoof')and sz.X>12 and sz.Z>12 and math.abs(cf.UpVector.Y)>.99 then
   local prev=selected[district];if not prev or sz.X*sz.Z>prev.Size.X*prev.Size.Z then selected[district]=p end
  end
 end end
 for kind,p in selected do
  group(root,batch,final[kind],kind..'_Inherited_Roof_Finish',999,reg,ids,function(m)
   local f=p:GetAttribute('FJ_CF');local sz=p:GetAttribute('FJ_Size');local y=sz.Y/2+.075
   for _,x in {-sz.X/2+.2,sz.X/2-.2}do local v=f*V(x,y,0);local q=box(m,'FoldedRoofEdgeCap',v.X,v.Y,v.Z,.18,.12,sz.Z-.4,'gold');q.CFrame=f*CF(x,y,0)end
   for _,z in {-sz.Z/2+.2,sz.Z/2-.2}do local v=f*V(0,y,z);local q=box(m,'FoldedRoofEdgeCap',v.X,v.Y,v.Z,sz.X-.4,.12,.18,'gold');q.CFrame=f*CF(0,y,z)end
  end)
 end
end
function M.Manifest(root)
 local out={}
 for _,batch in root[M.RootName]:GetChildren()do local groups={}
  for _,m in batch:GetChildren()do local f=m:GetAttribute('ReplacementPivot');local s=m:GetAttribute('ReplacementBounds')
   table.insert(groups,{name=m.Name,step=m:GetAttribute('FirstStep'),retire=m:GetAttribute('RetireStep'),id=m:GetAttribute('PurchaseId'),parts=m:GetAttribute('Parts'),pivot=f and{f:GetComponents()},bounds=s and{s.X,s.Y,s.Z}})
  end
  table.insert(out,{batch=batch.Name,paletteTargets=batch:GetAttribute('PaletteTargets')or 0,productionRoles=batch:GetAttribute('ProductionRoles')or 0,groups=groups})
 end return out
end
function M.Build(root,reg,ids,recovery)
 assert(game.PlaceId==125334614375606 and not game.RunService:IsRunning(),'Correct Edit only');assert(recovery,'Recovery required')
 M.PC01(root,reg,ids,recovery);M.PC02(root,reg,ids);M.PC03(root,reg,ids,recovery);M.PC04(root,reg,ids);M.PC05(root,reg,ids);return M.Manifest(root)
end
return M

