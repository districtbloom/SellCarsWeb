--!nocheck
-- PB01: scoped Collector predecessor; never claims the whole Professional chapter.
local A={Version='2026-09-08.PB01.1'}
local SS=game:GetService('ServerStorage')
local NAME='SellCarsV5CollectorBackward01Package'
local function pack(v)return typeof(v)=='EnumItem' and v.Name or v end
local function value(r,key)local v=r:GetAttribute(key);return r:GetAttribute('Property')=='Material' and Enum.Material[v] or v end
local function pkg()return assert(SS:FindFirstChild(NAME),'Collector study not installed')end
function A.Status()local p=SS:FindFirstChild(NAME);return p and p:GetAttribute('Applied')or false end
local function category(r)
 local o=r.Value;local path=o:GetFullName();local prop=r:GetAttribute('Property')
 if path:find('Legacy_Exhibit_2',1,true)or path:find('Legacy_Exhibit_5',1,true)or path:find('Legacy_Snapshot_2',1,true)or path:find('Legacy_Snapshot_5',1,true)or o.Name=='ArchiveIndex_2'or o.Name=='ArchiveIndex_5'then return 2 end
 if o.Name=='SightlineLanternGlass'or(prop~='Material'and prop~='Color')then return 1 end
 if o.Name=='LanternGlass'then return 1 end
 return 3
end
function A.Set(on)return A.SetLevel(on and 0 or 3)end
function A.SetLevel(level)
 assert(type(level)=='number'and level%1==0 and level>=0 and level<=3,'Tour level0–3 only')
 local p=pkg();local root=p.Root.Value;assert(root and root.Parent==workspace,'Restore Institution root before Collector study')
 local previous=p:GetAttribute('TourLevel');if previous==nil then previous=p:GetAttribute('Applied')and 0 or 3 end
 local layer=p.Layer.Value
 assert(layer and (layer.Parent==workspace or layer.Parent==p),'Study layer ownership changed')
 for _,r in p.Records:GetChildren()do
  assert(r.Value and r.Value:IsDescendantOf(root),'Collector target changed')
  local prop=r:GetAttribute('Property');assert(r.Value[prop]==value(r,category(r)<=previous and 'Institution' or 'Professional'),'Edited property: '..r.Value.Name..'.'..prop)
 end
 for _,r in p.Records:GetChildren()do r.Value[r:GetAttribute('Property')]=value(r,category(r)<=level and 'Institution' or 'Professional')end
 layer.Parent=level==0 and workspace or p;p:SetAttribute('Applied',level<3);p:SetAttribute('TourLevel',level)
 return {applied=level<3,level=level,records=#p.Records:GetChildren()}
end
function A.Install()
 assert(game.PlaceId==125334614375606 and game.RunService:IsStudio() and not game.RunService:IsRunning(),'Correct Studio Edit only')
 assert(not SS:FindFirstChild(NAME),'Already installed')
 local jp=SS.SellCarsV5JourneyPreviewPackage;assert(jp:GetAttribute('Active') and jp:GetAttribute('Step')==-1,'Restore benchmark first')
 local root=jp.Institution.Value;assert(root.Parent==workspace and #root:GetDescendants()==21864,'Institution baseline changed')
 local f=root['10_Institution_Fidelity_R1'];local col=f['05_Prestige_And_Public_Realm']['01_Collector']
 local shell=col.Craft_Gallery_Shell;local district=f['13_DistrictFinish02'].Rear_Collector_Hall
 local p=Instance.new('Folder');p.Name=NAME
 local refs=Instance.new('Folder');refs.Name='Records';refs.Parent=p
 local rr=Instance.new('ObjectValue');rr.Name='Root';rr.Value=root;rr.Parent=p
 local layer=Instance.new('Model');layer.Name='SellCars_V5_Professional_Collector_Study';layer.Parent=p
 local lr=Instance.new('ObjectValue');lr.Name='Layer';lr.Value=layer;lr.Parent=p
 local seen={}
 local function set(o,prop,v)
  assert(o and o:IsDescendantOf(root),'Missing bound object')
  seen[o]=seen[o]or{};assert(not seen[o][prop],'Duplicate property owner '..o.Name..'.'..prop);seen[o][prop]=true
  local old=o[prop];if old==v then return end
  local r=Instance.new('ObjectValue');r.Name=string.format('%04d',#refs:GetChildren()+1);r.Value=o
  r:SetAttribute('Property',prop);r:SetAttribute('Institution',pack(old))
  -- Normalize Roblox float properties without leaving the source changed.
  o[prop]=v;r:SetAttribute('Professional',pack(o[prop]));o[prop]=old;r.Parent=refs
 end
 local function hide(o)
  for _,q in {o,table.unpack(o:GetDescendants())}do
   if q:IsA('BasePart')then set(q,'Transparency',1);set(q,'CanCollide',false);set(q,'CanTouch',false);set(q,'CanQuery',false);if q.Material==Enum.Material.Glass then set(q,'Material',Enum.Material.SmoothPlastic)end
   elseif q:IsA('LayerCollector')or q:IsA('Light')then set(q,'Enabled',false)end
  end
 end
 local concrete=Color3.fromRGB(161,161,149);local metal=Color3.fromRGB(75,88,91)
 local function simpleFinish(o)
  for _,q in o:GetDescendants()do if q:IsA('BasePart') and q.Transparency<1 then
   if q.Material==Enum.Material.Limestone then set(q,'Material',Enum.Material.Concrete);set(q,'Color',concrete)
   elseif q.Material==Enum.Material.Wood then set(q,'Material',Enum.Material.Metal);set(q,'Color',metal)
   elseif q.Name:find('Bronze')or q.Name=='ColumnCollar'then set(q,'Color',metal)end
  end end
 end
 local ok,err=pcall(function()
  -- Retain the same shell objects, deck, post bases and rear entry. Shorten upper extensions only.
  simpleFinish(shell);simpleFinish(col.Gallery_Viewing_And_Light)
  local moveNames={RetainedSplitRoof=true,StandingRoofSeam=true,TimberSoffit=true,SoffitJoint=true,ContinuousWindowHead=true}
  local shortenNames={GalleryGlazing=true,SideGlazing=true,FrontMullion=true,RearMullion=true,SideMullion=true}
  for _,q in shell:GetChildren()do if q:IsA('BasePart')then
   if q.Name:match('^Lantern')then hide(q)
   elseif moveNames[q.Name]then set(q,'CFrame',q.CFrame+Vector3.new(0,-2,0))
   elseif shortenNames[q.Name]then set(q,'Size',q.Size-Vector3.new(0,2,0));set(q,'CFrame',q.CFrame+Vector3.new(0,-1,0))end
  end end
  for _,q in district['01_Gallery_Envelope']:GetDescendants()do if q:IsA('BasePart')and(q.Name=='FoldedRoofEdge'or q.Name=='RoofEndFlash')then set(q,'CFrame',q.CFrame+Vector3.new(0,-2,0))end end
  for _,q in col.Gallery_Viewing_And_Light:GetDescendants()do if q:IsA('BasePart')and q.Name=='DiffuseGalleryLight'then set(q,'CFrame',q.CFrame+Vector3.new(0,-2,0))end end
  -- Four symmetric original exhibits: keep1/3/4/6, centre2/5 are future additions.
  local base=root['09_Institution_Production_B']['02_Rear_Operations_And_Prestige']['06_Collector_Hall']
  for _,q in base:GetChildren()do if q.Name=='SightlineLanternGlass' then set(q,'Material',Enum.Material.SmoothPlastic)end end
  for _,n in {2,5}do hide(col['Legacy_Exhibit_'..n]);hide(base['Legacy_Snapshot_'..n]);hide(district['02_Curated_Records']['ArchiveIndex_'..n])end
  for _,n in {1,3,4,6}do
   local m=col['Legacy_Exhibit_'..n]
   for _,q in m:GetDescendants()do if q:IsA('BasePart')and q.Position.Y>32 then set(q,'CFrame',q.CFrame+Vector3.new(0,-2,0))end end
  end
  -- Professional replacement roof closes the lantern opening; not a permanently open roof.
  local function part(name,size,pos,mat,color)
   local q=Instance.new('Part');q.Name=name;q.Anchored=true;q.Size=size;q.Position=pos;q.Material=mat;q.Color=color;q.CanCollide=true;q.Parent=layer;return q
  end
  local y=shell:FindFirstChild('RetainedSplitRoof').Position.Y-2
  part('Removable_Central_Roof_Cassette',Vector3.new(30,1.2,62),Vector3.new(3105,y,430),Enum.Material.Metal,Color3.fromRGB(45,58,63))
  for _,x in {3094,3101,3108,3115}do part('Cassette_Standing_Seam',Vector3.new(.14,.12,62),Vector3.new(x,y+.66,430),Enum.Material.Metal,Color3.fromRGB(67,78,79))end
  part('Cassette_Soffit',Vector3.new(29.7,.13,61.2),Vector3.new(3105,y-.68,430),Enum.Material.Metal,Color3.fromRGB(139,146,143))
  for _,z in {402,430,458}do part('Retained_Grid_Roof_Bearer',Vector3.new(30,.25,.4),Vector3.new(3105,y-.89,z),Enum.Material.Metal,metal)end
  p:SetAttribute('Version',A.Version);p:SetAttribute('Applied',false);p:SetAttribute('Scope','Collector only; rest remains Institution')
  p:SetAttribute('InstitutionTop',41.730002);p:SetAttribute('ProfessionalTop',y+.72)
 end)
 if not ok then p:Destroy();error(err)end
 p.Parent=SS;return {records=#refs:GetChildren(),newRoofParts=#layer:GetChildren(),installed=true}
end
return A

