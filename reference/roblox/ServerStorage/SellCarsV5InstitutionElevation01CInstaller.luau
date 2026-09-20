--!nocheck
-- ELEV01C: three thin garden walks; original surfaces, plants and crossings stay intact.
local I={Version="2026-09-07.elevation01c.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Garden_Walks"
local TOP,PHYSICS_TOP=.180,.095
local BEDS={{id=1,lo=104.5,hi=137.5,rows=8,centre=121},{id=3,lo=219.5,hi=267.5,rows=12,centre=243.5},{id=4,lo=284.5,hi=339.5,rows=14,centre=312}}
local function round(value: number): number
	return math.floor(value * 1000 + (if value >= 0 then 0.5 else -0.5)) / 1000
end

local function addHash(seed: number, value: string): number
	local hash = seed
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return hash
end

local function relativePath(item: Instance, ancestor: Instance): string
	local names = {}
	local cursor: Instance? = item
	while cursor and cursor ~= ancestor do
		table.insert(names, 1, cursor.Name)
		cursor = cursor.Parent
	end
	return table.concat(names, "/")
end

local function geometryHash(instance: Instance, excluded: Instance?): (string, number)
	local records = { ".|" .. instance.ClassName }
	for _, item in ipairs(instance:GetDescendants()) do
		if excluded and (item == excluded or item:IsDescendantOf(excluded)) then continue end
		local record = relativePath(item, instance) .. "|" .. item.ClassName
		if item:IsA("BasePart") then
			local position = item.Position
			local size = item.Size
			local orientation = item.Orientation
			local color = item.Color
			record ..= string.format(
				"|p=%.3f,%.3f,%.3f|s=%.3f,%.3f,%.3f|o=%.3f,%.3f,%.3f|t=%.3f|c=%s%s%s%s|m=%s|rgb=%.3f,%.3f,%.3f",
				round(position.X), round(position.Y), round(position.Z),
				round(size.X), round(size.Y), round(size.Z),
				round(orientation.X), round(orientation.Y), round(orientation.Z),
				round(item.Transparency),
				if item.CanCollide then "1" else "0",
				if item.CanTouch then "1" else "0",
				if item.CanQuery then "1" else "0",
				if item.CastShadow then "1" else "0",
				tostring(item.Material), round(color.R), round(color.G), round(color.B)
			)
		elseif item:IsA("Light") then
			record ..= string.format(
				"|e=%s|b=%.3f|r=%.3f|s=%s",
				if item.Enabled then "1" else "0",
				round(item.Brightness), round(item.Range),
				if item.Shadows then "1" else "0"
			)
		elseif item:IsA("LuaSourceContainer") then
			record ..= "|sourceLen=" .. tostring(#item.Source)
		end
		table.insert(records, record)
	end
	table.sort(records)
	local hash = 5381
	for _, record in ipairs(records) do
		hash = addHash(hash, record)
		hash = addHash(hash, "\n")
	end
	return string.format("%08x", hash), #records
end


local function root()
 assert(game.PlaceId==125334614375606 and not game.RunService:IsRunning(),"Correct place / Edit only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function parent()return assert(root()["10_Institution_Fidelity_R1"]:FindFirstChild("07_Elevation_01"))end
local function layer()return parent():FindFirstChild(NAME)end
local function bounds(p)
 local c,s=p.CFrame,p.Size
 local h=Vector3.new(
  math.abs(c.RightVector.X)*s.X+math.abs(c.UpVector.X)*s.Y+math.abs(c.LookVector.X)*s.Z,
  math.abs(c.RightVector.Y)*s.X+math.abs(c.UpVector.Y)*s.Y+math.abs(c.LookVector.Y)*s.Z,
  math.abs(c.RightVector.Z)*s.X+math.abs(c.UpVector.Z)*s.Y+math.abs(c.LookVector.Z)*s.Z)/2
 return p.Position-h,p.Position+h
end
local function overlap(a,b,c,d,e)
 e=e or .0001
 return a.X<d.X-e and b.X>c.X+e and a.Y<d.Y-e and b.Y>c.Y+e and a.Z<d.Z-e and b.Z>c.Z+e
end
local function signature(l)
 local rows={}
 for _,v in l:GetDescendants() do
  if v:IsA("BasePart") then
   local cf={};for _,n in {v.CFrame:GetComponents()} do local s=string.format("%.5f",n);if s=="-0.00000" then s="0.00000" end;table.insert(cf,s) end
   table.insert(rows,v.Name.."|"..v.Parent.Name.."|"..table.concat(cf,",").."|"..tostring(v.Size).."|"..v.Material.Name.."|"..tostring(v.Color).."|"..tostring(v.Transparency).."|"..tostring(v.CanCollide)..tostring(v.CanTouch)..tostring(v.CanQuery)..tostring(v.CastShadow).."|"..v.Shape.Name)
  end
 end
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end;h=(h*33+10)%4294967296 end
 return string.format("%08x",h)
end

local function ownedSignature(l)
 local rows={geometryHash(l),signature(l)}
 local all={l};for _,v in l:GetDescendants()do table.insert(all,v)end
 for _,v in all do
  local path=relativePath(v,l)
  if v:IsA("BasePart")then table.insert(rows,path.."|behavior|"..tostring(v.Anchored).."|"..tostring(v.Reflectance).."|"..v.MaterialVariant.."|"..v.CollisionGroup.."|"..tostring(v.Massless).."|"..tostring(v.CustomPhysicalProperties).."|"..tostring(v.TopSurface).."|"..tostring(v.BottomSurface))end
  for k,value in v:GetAttributes()do
   if not(v==l and k=="ContentSignature")then table.insert(rows,path.."|"..k.."|"..typeof(value).."|"..tostring(value))end
  end
  for _,tag in v:GetTags()do table.insert(rows,path.."|tag|"..tag)end
 end
 table.sort(rows);local h=5381;for _,s in rows do h=addHash(h,s.."\n")end
 return string.format("%08x",h)
end
I.OwnedSignature=ownedSignature
local function model(l,bed)
 local m=Instance.new("Model");m.Name="Bed_"..bed.id.."_Walk"
 for k,v in {BundleId="Institution.Elevation01C.Bed"..bed.id.."Walk",FunctionId="EstateLandscape",ZoneId="Desert_Bed_"..bed.id,FidelityRole="ARCHITECTURE",PhaseMin="PROFESSIONAL",Ancestor="Compacted central walking reserve in the same garden island",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="DECORATIVE",InteractionAnchor="Existing eight-stud central walk",FXSocket="",SourceOwned=true,SurfaceOnly=true,SourceGeometry="PARAMETRIC_PROXY",PhysicalFloorTop=PHYSICS_TOP,VisiblePavingTop=TOP}do m:SetAttribute(k,v)end
 m.Parent=l;return m
end
local function slab(m,n,x,z,w,d,c,top,thickness,mat)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true
 p.Size=Vector3.new(w,thickness,d);p.CFrame=CFrame.new(x,top-thickness/2,z)
 p.Color=c;p.Material=mat or Enum.Material.Limestone
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p:SetAttribute("Elevation01COwned",true);p:SetAttribute("SurfaceLayer",true);p.Parent=m
end
local function build(l)
 for _,bed in BEDS do
  local m=model(l,bed);local step=(bed.hi-bed.lo)/bed.rows
  slab(m,"JointBedding",3130,(bed.lo+bed.hi)/2,8,bed.hi-bed.lo,Color3.fromRGB(122,115,99),.160,.028,Enum.Material.Concrete)
  for row=0,bed.rows-1 do for col=0,1 do
   local shade=((row*3+col*2)%5)-2
   slab(m,string.format("Paving_%02d_%d",row+1,col+1),3128+4*col,bed.lo+step*(row+.5),3.94,step-.06,Color3.fromRGB(166+shade,155+shade,133+shade),TOP,.04)
  end end
 end
end
function I.Install()
 local r,p=root(),parent()
 assert(not layer(),"Owned C already exists; verify and explicitly Uninstall instead of overwrite")
 assert(r:GetAttribute("InstitutionElevation01BStatus")=="ACCEPTED_PROXY","Accepted B required")
 assert(geometryHash(r)=="0a7487b2" and #r:GetDescendants()==13915,"Unexpected predecessor geometry; preserve edits")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","0a7487b2");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01CStatus","BUILT_AWAITING_REVIEW")
 l:SetAttribute("ContentSignature",ownedSignature(l))
 return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=layer()
 assert(l,"C absent; nothing to uninstall")
 for _,v in p:GetChildren()do assert(v==l or v.Name=="01_Central_Craft_Pocket"or v.Name=="02_Garden_Promenade_Link","Later/unknown sibling; do not remove dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned C changed; preserve and investigate")
 assert(geometryHash(r,l)=="0a7487b2" and #r:GetDescendants()-#l:GetDescendants()-1==13915,"Predecessor changed; preserve C and investigate")
 assert(r:GetAttribute("InstitutionElevation01CStatus")==l:GetAttribute("Status"),"Owned root status changed; preserve")
 l:Destroy();r:SetAttribute("InstitutionElevation01CStatus",nil)
 assert(geometryHash(r)=="0a7487b2","Prior geometry differs; do not automatically restore it")
 return true
end
function I.Audit()
 local r,l=root(),assert(layer())
 local a={parts=0,models=0,solids=0,meshes=0,lights=0,scripts=0,issues={},metadataIssues={},supportRays=0,bodyPoses=0,visibleSamples=0,paverTopChecks=0,cornerChecks=0,externalPairs=0,substratePairs=0,internalPairs=0,protectedVolumes=0,routeVolumes=0,envelopeTests=0,routeTests=0,beds={},axisSampleMinZ=101.5,axisSampleMaxZ=343}
 local all,own,other={},{},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then
  local mn,mx=bounds(p);local v={p=p,mn=mn,mx=mx};table.insert(all,v);table.insert(p:IsDescendantOf(l)and own or other,v)
 end end
 local substrates={}
 for _,g in other do
  local p=g.p
  if(p.Name=="ProductionGround"or p.Name=="FrontageApron")and p.Parent==r["01_Ground_And_Road"]then substrates[p]=true
  elseif(p.Name=="ProductionFinish"or p.Name=="FrontageFinish")and p.Parent.Name=="Exterior_Concrete_Districts"then substrates[p]=true
  elseif p.Name=="CompactedGravel"and p.Parent.Name=="Central_Gravel_Reservations"then
   for _,b in BEDS do if math.abs(p.Position.Z-b.centre)<.001 then substrates[p]=true end end
  end
 end
 local ids={}
 for _,v in l:GetDescendants()do
  if v:IsA("Model")then
   a.models+=1
   for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k)end end
   local id=v:GetAttribute("BundleId");if ids[id]then table.insert(a.metadataIssues,"Duplicate:"..id)end;ids[id]=true
  elseif v:IsA("BasePart")then
   a.parts+=1;if v.CanCollide then a.solids+=1 end
   if v.CanCollide or v.CanTouch or v.CanQuery or v.CastShadow or not v.Anchored then table.insert(a.issues,"UnexpectedBehavior:"..v.Name)end
   if v.Shape~=Enum.PartType.Block or v.Orientation.Magnitude>.001 then table.insert(a.issues,"UnexpectedForm:"..v.Name)end
  elseif v:IsA("DataModelMesh")then a.meshes+=1
  elseif v:IsA("Light")then a.lights+=1
  elseif v:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for _,v in own do
  local bed;for _,b in BEDS do if v.p.Parent.Name=="Bed_"..b.id.."_Walk"then bed=b end end
  if not bed then table.insert(a.issues,"UnknownAssembly:"..v.p:GetFullName())else
   for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
    a.cornerChecks+=1;local c=v.p.CFrame:PointToWorldSpace(v.p.Size*Vector3.new(sx,sy,sz)/2)
    if c.X<3126-.001 or c.X>3134+.001 or c.Z<bed.lo-.001 or c.Z>bed.hi+.001 or c.Y<.131 or c.Y>TOP+.001 then table.insert(a.issues,"OutsideScope:"..v.p.Name)end
   end end end
  end
  for _,g in other do if overlap(v.mn,v.mx,g.mn,g.mx)then
   a.externalPairs+=1;if substrates[g.p]and g.mx.Y<TOP-.025 then a.substratePairs+=1 else table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..g.p:GetFullName())end
  end end
 end
 for i=1,#own do for j=i+1,#own do local v,w=own[i],own[j]
  if overlap(v.mn,v.mx,w.mn,w.mx)then a.internalPairs+=1
   if(v.p.Name~="JointBedding"and w.p.Name~="JointBedding")or math.abs(v.mx.Y-w.mx.Y)<.015 then table.insert(a.issues,"InternalOverlap:"..v.p.Name..":"..w.p.Name)end
  end
 end end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 for z=101.5,343,.5 do for _,x in {3127,3130,3133}do
  a.supportRays+=1;a.bodyPoses+=1;a.visibleSamples+=1
  local hit=workspace:Raycast(Vector3.new(x,.6,z),Vector3.new(0,-1.2,0),rp)
  if not hit or math.abs(hit.Position.Y-PHYSICS_TOP)>.002 then table.insert(a.issues,"PhysicalFloor:"..x..","..z)end
  local top=-math.huge;local bodyMin=Vector3.new(x-1.5,.65,z-.3);local bodyMax=Vector3.new(x+1.5,6.45,z+.3)
  for _,g in all do
   if overlap(bodyMin,bodyMax,g.mn,g.mx)then table.insert(a.issues,"BodyObstacle:"..g.p:GetFullName())end
   if g.p.Transparency<.98 and x>=g.mn.X and x<=g.mx.X and z>=g.mn.Z and z<=g.mx.Z and g.mx.Y<.5 then top=math.max(top,g.mx.Y)end
  end
  local expect=false;for _,b in BEDS do if z>=b.lo and z<=b.hi then expect=true end end
  if expect and(top<.159 or top>TOP+.002)then table.insert(a.issues,"VisibleFinish:"..x..","..z)end
  if top>PHYSICS_TOP+.087 then table.insert(a.issues,"FinishSupportDelta:"..x..","..z)end
 end end
 for _,b in BEDS do
  local m=l["Bed_"..b.id.."_Walk"];local q={id=b.id,pavers=0,bedding=0,rowLength=(b.hi-b.lo)/b.rows-.06,southThreshold=0,northThreshold=0}
  for _,p in m:GetChildren()do local _,mx=bounds(p)
   if p.Name=="JointBedding"then q.bedding+=1 else
    q.pavers+=1;a.paverTopChecks+=1;if math.abs(mx.Y-TOP)>.002 then table.insert(a.issues,"PaverTop:"..p.Name)end
   end
  end
  for _,g in other do if g.p.Name=="FlushStoneEdge"and g.p.Parent.Name=="Central_Gravel_Reservations"then
   if math.abs(g.p.Position.Z-(b.lo-.5))<.001 then q.southThreshold=b.lo-g.mx.Z end
   if math.abs(g.p.Position.Z-(b.hi+.5))<.001 then q.northThreshold=g.mn.Z-b.hi end
  end end
  if q.pavers~=2*b.rows or q.bedding~=1 then table.insert(a.issues,"Inventory:Bed"..b.id)end
  if math.abs(q.southThreshold-.36)>.002 or math.abs(q.northThreshold-.36)>.002 then table.insert(a.issues,"Threshold:Bed"..b.id)end
  table.insert(a.beds,q)
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then
  a.protectedVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end
 end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then
  a.routeVolumes+=1;local mn,mx=bounds(p);mn=Vector3.new(mn.X,.7,mn.Z);mx=Vector3.new(mx.X,7.7,mx.Z)
  for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.0001 and v.mx.X>mn.X+.0001 and v.mn.Z<mx.Z-.0001 and v.mx.Z>mn.Z+.0001 then table.insert(a.issues,"VehicleRouteFootprint:"..p.Name)end end
 end end
 if a.parts~=71 or a.models~=3 or a.paverTopChecks~=68 or a.solids+a.meshes+a.lights+a.scripts~=0 then table.insert(a.issues,"UnexpectedLayerInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature
 if not a.signatureMatch then table.insert(a.issues,"UnexpectedOwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"Audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","SeatPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass"}do assert(e[k],"Missing evidence:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in l:GetChildren()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01CStatus","ACCEPTED_PROXY")
 l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

