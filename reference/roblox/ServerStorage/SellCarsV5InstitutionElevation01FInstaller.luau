--!nocheck
-- ELEV01F: personal build-review bench, folio ledge and reversible Photo walkway support.
local I={Version="2026-09-07.elevation01f.3"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","06_Owner_Build_Review"
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
   table.insert(rows,v.Name.."|"..v.Parent.Name.."|"..table.concat(cf,",").."|"..tostring(v.Size).."|"..v.Material.Name.."|"..tostring(v.Color).."|"..tostring(v.Transparency).."|"..tostring(v.CanCollide)..tostring(v.CanTouch)..tostring(v.CanQuery)..tostring(v.CastShadow).."|"..(v:IsA("Part") and v.Shape.Name or v.ClassName)..(v:IsA("Seat") and tostring(v.Disabled) or ""))
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

local C={steel=Color3.fromRGB(47,51,48),rust=Color3.fromRGB(117,73,45),wood=Color3.fromRGB(177,131,79),grain=Color3.fromRGB(146,103,61),bolt=Color3.fromRGB(157,157,139),leaf=Color3.fromRGB(91,115,86)}
local function model(l,n,ancestor,role)
 local m=Instance.new("Model");m.Name=n
 for k,v in {BundleId="Institution.Elevation01F."..n,FunctionId="Owner_Garage",ZoneId="OwnerRearPedestrianShoulder",FidelityRole=role,PhaseMin="WORKING",Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="FURNITURE",InteractionAnchor="",FXSocket="",SourceOwned=true,SourceGeometry="PARAMETRIC_PROXY"}do m:SetAttribute(k,v)end
 m.Parent=l;return m
end
local function part(m,n,p,s,c,mat,solid,cls,cf)
 local v=Instance.new(cls or "Part");v.Name=n;v.Size=s;v.CFrame=cf or CFrame.new(p);v.Anchored=true
 v.Material=mat or Enum.Material.Metal;v.Color=c;v.CanCollide=solid==true;v.CanQuery=true;v.CanTouch=v:IsA("Seat");v.CastShadow=true
 v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v:SetAttribute("Elevation01FOwned",true);v.Parent=m;return v
end
local function build(l)
 local m=model(l,"Personal_Build_Review_Bench","A drawing board carried outside the owner's first garage","SUPPORT")
 m:SetAttribute("InteractionAnchor","BenchApproach")
 local x,z=3206.5,418.8
 for _,sx in {-2.55,2.55}do
  part(m,"BaseShoe",Vector3.new(x+sx,.57,z),Vector3.new(.44,.14,2.1),C.rust,nil,true)
  for _,sz in {-.72,.72}do
   part(m,"UFrameLeg",Vector3.new(x+sx,1.18,z+sz),Vector3.new(.23,1.1,.25),C.steel,nil,true)
  end
  part(m,"SeatBearing",Vector3.new(x+sx,1.8475,z),Vector3.new(.23,.235,1.85),C.steel,nil,true)
  part(m,"BackUpright",Vector3.new(x+sx,2.52,z+.88),Vector3.new(.22,2.06,.23),C.steel,nil,true)
  part(m,"ArmFront",Vector3.new(x+sx,2.38,z-.57),Vector3.new(.19,.9,.20),C.steel,nil,true)
  part(m,"TimberArmCap",Vector3.new(x+sx,2.90,z),Vector3.new(.32,.2,1.9),C.wood,Enum.Material.Wood,true)
 end
 for i=0,3 do
  local zz=z-.68+i*.45
  local p=part(m,i==2 and "RestSeat" or "SeatSlat_"..i,Vector3.new(x,2.08,zz),Vector3.new(6.55,.23,.40),i==0 and C.grain or C.wood,Enum.Material.Wood,true,i==2 and "Seat" or nil)
  if p:IsA("Seat")then p.Disabled=false;p:SetAttribute("Role","SINGLE_NATIVE_REST_SEAT_NO_CONTROLLER")end
 end
 for i=0,2 do
  part(m,"BackSlat_"..i,Vector3.new(x,2.57+i*.37,z+.89),Vector3.new(6.55,.29,.20),i==0 and C.grain or C.wood,Enum.Material.Wood,true)
 end
 local anchor=part(m,"BenchApproach",Vector3.new(x,.5,415.9),Vector3.new(.1,.1,.1),C.steel,nil,false)
 anchor.Transparency=1;anchor.CanQuery=false;anchor.CastShadow=false;anchor:SetAttribute("AnchorKind","OPERATOR")
 local a=Instance.new("Attachment");a.Name="SeatUse";a.Parent=anchor
 local plant=model(l,"Low_Agave_End_Planter","A hardy low plant beside the owner's first outdoor build sketch","LANDSCAPE")
 plant:SetAttribute("BotanicalIntent","LOW_BLUE_GREEN_AGAVE_ROSETTE_NO_FLOWER_SPIKE")
 local px,pz=3211.5,419
 part(plant,"RecessedFoot",Vector3.new(px,.57,pz),Vector3.new(1.85,.14,1.85),C.steel,nil,true)
 part(plant,"VesselBase",Vector3.new(px,.70,pz),Vector3.new(2.2,.12,2.2),C.rust,nil,true)
 for _,s in {-1,1}do
  part(plant,"FoldedVesselFaceX",Vector3.new(px+s*1.04,1.23,pz),Vector3.new(.12,1.06,2.2),C.rust,nil,true)
  part(plant,"FoldedVesselFaceZ",Vector3.new(px,1.23,pz+s*1.04),Vector3.new(1.96,1.06,.12),C.rust,nil,true)
  part(plant,"FoldedRimX",Vector3.new(px+s*1.04,1.80,pz),Vector3.new(.18,.08,2.2),C.grain,nil,false)
  part(plant,"FoldedRimZ",Vector3.new(px,1.80,pz+s*1.04),Vector3.new(1.96,.08,.18),C.grain,nil,false)
 end
 part(plant,"RecessedGravel",Vector3.new(px,1.70,pz),Vector3.new(1.95,.10,1.95),Color3.fromRGB(126,119,97),Enum.Material.Pebble,false)
 -- Two rings of tapered native wedges: readable rosette, no imported/dense mesh.
 for ring=1,2 do local count=ring==1 and 5 or 2
  for i=0,count-1 do
   local angle=2*math.pi*i/count+ring*.37
   local radius=ring==1 and .83 or .36
   local rise=ring==1 and .66 or 1.21
   local base=Vector3.new(px,1.78,pz)
   local tip=base+Vector3.new(math.cos(angle)*radius,rise,math.sin(angle)*radius)
   local mid=(base+tip)/2;local len=(tip-base).Magnitude
   local width=ring==1 and .28 or .21
   for _,sign in {-1,1}do
    local leaf=part(plant,"AgaveBlade_"..ring.."_"..i.."_"..sign,mid,Vector3.new(.055,width/2,len),ring==1 and C.leaf or Color3.fromRGB(111,133,103),Enum.Material.SmoothPlastic,false,"WedgePart",CFrame.lookAt(mid,tip)*CFrame.Angles(0,0,sign*math.pi/2)*CFrame.new(0,width/4,0))
    leaf:SetAttribute("FinalAssetIntent","POINTED_AGAVE_LEAF_MESH_PROXY")
   end
  end
 end
 -- Reorient the proven supported bench/plant assembly to face the courtyard.
 -- Feet meet visible concrete finish .119; physical pedestrian floor remains .095.
 local transform=CFrame.new(3204.5,.119,105.5)*CFrame.Angles(0,math.pi,0)*CFrame.new(-3206.5,-.5,-418.8)
 for _,p in l:GetDescendants()do if p:IsA("BasePart")then p.CFrame=transform*p.CFrame end end
 m:SetAttribute("Purpose","PERSONAL_BUILD_REVIEW_NOT_DEALER_LISTING");m:SetAttribute("VisibleGroundTop",.119);m:SetAttribute("PhysicalGroundTop",.095)
 -- Attached drawing ledge grows from the bench frame, not a loose coffee table.
 for _,z in {104.69,106.15}do
  part(m,"LedgeCantilever",Vector3.new(3208.58,2.31,z),Vector3.new(3.06,.26,.20),C.steel,nil,true)
  part(m,"LedgeOuterLeg",Vector3.new(3210.1,1.28,z),Vector3.new(.24,2.322,.24),C.steel,nil,true)
  part(m,"LedgeFoot",Vector3.new(3210.1,.189,z),Vector3.new(.5,.14,.48),C.rust,nil,true)
 end
 part(m,"DrawingLedge",Vector3.new(3209.05,2.53,105.42),Vector3.new(2.5,.18,2.5),C.wood,Enum.Material.Wood,true)
 -- Open clipped folio: a personal profile revision, not a new screen or history display.
 for _,x in {3208.5,3209.6}do
  part(m,"FolioCover",Vector3.new(x,2.66,105.3),Vector3.new(1.07,.08,1.8),Color3.fromRGB(91,76,59),Enum.Material.Fabric,false)
  part(m,"FolioPage",Vector3.new(x,2.7125,105.3),Vector3.new(.97,.025,1.64),Color3.fromRGB(217,209,181),Enum.Material.SmoothPlastic,false)
  part(m,"PageRetainingClip",Vector3.new(x,2.7375,104.58),Vector3.new(.28,.025,.12),C.bolt,nil,false)
 end
 part(m,"FolioHinge",Vector3.new(3209.05,2.675,105.3),Vector3.new(.09,.11,1.8),C.grain,Enum.Material.Fabric,false)
 local ink=Color3.fromRGB(62,80,86)
 for _,v in {{3208.5,105.23,.73,.035},{3208.54,105.01,.38,.035},{3208.33,105.10,.035,.23},{3208.73,105.10,.035,.23}}do
  part(m,"PersonalProfileRevision",Vector3.new(v[1],2.731,v[2]),Vector3.new(v[3],.012,v[4]),ink,Enum.Material.SmoothPlastic,false)
 end
 for _,x in {3208.28,3208.75}do
  local p=part(m,"ProfileWheel",Vector3.new(x,2.732,105.29),Vector3.new(.014,.15,.15),ink,Enum.Material.SmoothPlastic,false)
  p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,0,math.pi/2)
 end
 for _,z in {105.02,105.26}do part(m,"RevisionNoteLine",Vector3.new(3209.6,2.731,z),Vector3.new(.64,.012,.026),ink,Enum.Material.SmoothPlastic,false)end
 part(m,"RetainedDrawingPencil",Vector3.new(3210.19,2.65,105.37),Vector3.new(.045,.06,1.35),Color3.fromRGB(153,83,43),Enum.Material.Wood,false)
 m:SetAttribute("FinalDetailIntent","OPEN_PERSONAL_BUILD_FOLIO_PROFILE_REVISION_AND_RETAINED_PENCIL")
 -- Support the existing noncolliding Photo finish; no older object is edited.
 local support=model(l,"Photo_Walkway_Support","A chalk listing corner becomes a physically supported studio staff walk","ARCHITECTURE")
 support:SetAttribute("FunctionId","Photo_Listing");support:SetAttribute("ZoneId","ExistingPhotoStaffWalk");support:SetAttribute("CollisionClass","STRUCTURE")
 support:SetAttribute("ExistingFinishRetained",true);support:SetAttribute("PhysicalFloorTop",.7)
 local slab=part(support,"ExistingWalkCollisionSupport",Vector3.new(3229,.4095,175),Vector3.new(6,.581,48),C.steel,nil,true)
 slab.Transparency=1;slab.CastShadow=false
 for _,v in {{"PhotoEntryRamp",149.5,0},{"PhotoFarRamp",200.5,math.pi}}do
  local cf=CFrame.new(3229,.4095,v[2])*CFrame.Angles(0,v[3],0)
  part(support,v[1],cf.Position,Vector3.new(6,.581,3),Color3.fromRGB(133,130,119),Enum.Material.Concrete,true,"WedgePart",cf)
 end
end

function I.Install()
 local r,p=root(),parent()
 assert(not layer(),"Owned F already exists; verify and explicitly Uninstall instead of overwrite")
 assert(r:GetAttribute("InstitutionElevation01EStatus")=="ACCEPTED_PROXY","Accepted E required")
 assert(geometryHash(r)=="acb70384" and #r:GetDescendants()==14081,"Unexpected predecessor geometry; preserve edits")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","acb70384");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01FStatus","BUILT_AWAITING_REVIEW")
 l:SetAttribute("ContentSignature",ownedSignature(l))
 return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=layer()
 assert(l,"F absent; nothing to uninstall")
 for _,v in p:GetChildren()do assert(v==l or v.Name=="01_Central_Craft_Pocket"or v.Name=="02_Garden_Promenade_Link"or v.Name=="03_Remaining_Garden_Walks"or v.Name=="04_Operations_Pause_Pocket"or v.Name=="05_Parts_Packaging_Return","Later/unknown sibling; do not remove dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned F changed; preserve and investigate")
 assert(geometryHash(r,l)=="acb70384" and #r:GetDescendants()-#l:GetDescendants()-1==14081,"Predecessor changed; preserve F and investigate")
 assert(r:GetAttribute("InstitutionElevation01FStatus")==l:GetAttribute("Status"),"Owned root status changed; preserve")
 l:Destroy();r:SetAttribute("InstitutionElevation01FStatus",nil)
 assert(geometryHash(r)=="acb70384","Prior geometry differs; do not automatically restore it")
 return true
end

local PATHS={
 {name="OwnerExit",points={{3191.5,95},{3191.5,97.9},{3220,97.9},{3220,103},{3220,111}}},
 {name="ReviewBench",points={{3220,111},{3204.5,111},{3204.5,108.5}}},
 {name="PhotoConnection",points={{3220,111},{3229,111},{3229,145},{3229,154}}},
}
I.AccessPaths=PATHS
function I.Audit()
 local r,l=root(),assert(layer())
 local a={parts=0,models=0,solids=0,seats=0,meshes=0,lights=0,scripts=0,issues={},metadataIssues={},externalPairs=0,intentionalFinishSupportPairs=0,protectedVolumes=0,routeVolumes=0,envelopeTests=0,routeTests=0,bodyPoses=0,floorRays=0,floors={},cornerChecks=0}
 local all,own,other={},{},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then
  local mn,mx=bounds(p);local v={p=p,mn=mn,mx=mx};table.insert(all,v);table.insert(p:IsDescendantOf(l)and own or other,v)
 end end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then
   a.models+=1
   local declared=p:GetAttribute("InteractionAnchor");if declared and declared~="" and not p:FindFirstChild(declared,true)then table.insert(a.metadataIssues,"UnresolvedAnchor:"..p.Name..":"..declared)end
   for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if p:GetAttribute(k)==nil then table.insert(a.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then
   a.parts+=1;if p.CanCollide then a.solids+=1 end;if p:IsA("Seat")then a.seats+=1;if p.Disabled then table.insert(a.issues,"SeatDisabled")end end
   if not p.Anchored then table.insert(a.issues,"Unanchored:"..p.Name)end
  elseif p:IsA("DataModelMesh")then a.meshes+=1
  elseif p:IsA("Light")then a.lights+=1
  elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   a.cornerChecks+=1;local p=v.p.CFrame:PointToWorldSpace(v.p.Size*Vector3.new(sx,sy,sz)/2)
   if v.p.Parent==l.Photo_Walkway_Support then
    if p.X<3226-.001 or p.X>3232+.001 or p.Z<148-.001 or p.Z>202+.001 or p.Y<.095-.001 or p.Y>.701 then table.insert(a.issues,"OutsideExistingWalkSupport:"..v.p.Name)end
   elseif p.X<3198-.001 or p.X>3212+.001 or p.Z<103-.001 or p.Z>108+.001 or p.Y<.119-.001 or p.Y>4 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  local retainedWalk=r["10_Institution_Fidelity_R1"]["03_Remaining_Production"]["05_Photo"].Editorial_Floor_And_Service_Edge.StaffNonSlipWalk
  for _,g in other do if overlap(v.mn,v.mx,g.mn,g.mx)then
   if v.p==l.Photo_Walkway_Support.ExistingWalkCollisionSupport and g.p==retainedWalk then a.intentionalFinishSupportPairs+=1
   else a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..g.p:GetFullName())end
  end end
 end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local function checkBody(name,x,z,dx,dz,anchor)
  local hit=workspace:Raycast(Vector3.new(x,1.05,z),Vector3.new(0,-2,0),rp);a.floorRays+=1
  if not hit then table.insert(a.issues,"MissingFloor:"..name);return end
  local feet=hit.Position.Y
  local onPhoto=x>=3226 and x<=3232 and z>=148 and z<=202
  if feet<.09 or feet>(onPhoto and .701 or .101)then table.insert(a.issues,"UnexpectedFloor:"..name..":"..feet)end
  a.floors[string.format("%.3f",feet)]=(a.floors[string.format("%.3f",feet)]or 0)+1
  local half=anchor and Vector3.new(1.5,2.9,1.5)or Vector3.new(math.abs(dz)*1.5+math.abs(dx)*.3,2.9,math.abs(dx)*1.5+math.abs(dz)*.3)
  local mid=Vector3.new(x,feet+3.5,z);a.bodyPoses+=1
  for _,g in all do if overlap(mid-half,mid+half,g.mn,g.mx)then
   local actualOverlap=true
   if g.p.Parent==l.Photo_Walkway_Support and g.p:IsA("WedgePart")then
    -- Exact slope maximum within this body's XZ footprint, not the wedge's full AABB.
    local z0,z1=math.max((mid-half).Z,g.mn.Z),math.min((mid+half).Z,g.mx.Z)
    local t=g.p.Name=="PhotoEntryRamp" and (z1-g.mn.Z)/(g.mx.Z-g.mn.Z) or (g.mx.Z-z0)/(g.mx.Z-g.mn.Z)
    local top=g.mn.Y+math.clamp(t,0,1)*(g.mx.Y-g.mn.Y)
    actualOverlap=(mid-half).Y<top-.0001 and (mid+half).Y>g.mn.Y+.0001
   end
   if actualOverlap then table.insert(a.issues,"BodyObstacle:"..name..":"..g.p:GetFullName())end
  end end
 end
 for _,path in PATHS do for i=2,#path.points do
  local a0,b0=path.points[i-1],path.points[i];local dx,dz=b0[1]-a0[1],b0[2]-a0[2];local len=math.sqrt(dx*dx+dz*dz);dx/=len;dz/=len
  local steps=math.ceil(len/.5);for s=0,steps do checkBody(path.name,a0[1]+dx*len*s/steps,a0[2]+dz*len*s/steps,dx,dz,false)end
 end end
 checkBody("BenchStanding",3204.5,108.5,0,1,true);checkBody("OwnerThreshold",3220,101.8,0,1,true);checkBody("PhotoThreshold",3229,150,0,1,true)
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then
  a.protectedVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end
 end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then
  a.routeVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.0001 and v.mx.X>mn.X+.0001 and v.mn.Z<mx.Z-.0001 and v.mx.Z>mn.Z+.0001 then table.insert(a.issues,"VehicleRouteFootprint:"..p.Name)end end
 end end
 local slat=l.Personal_Build_Review_Bench.RestSeat
 for _,p in l.Personal_Build_Review_Bench:GetChildren()do if p.Name=="SeatBearing"then local _,mx=bounds(p);local mn=bounds(slat);if math.abs(mx.Y-mn.Y)>.001 then table.insert(a.issues,"SeatBearingContact")end end end
 local walk=r["10_Institution_Fidelity_R1"]["03_Remaining_Production"]["05_Photo"].Editorial_Floor_And_Service_Edge.StaffNonSlipWalk
 local slab=l.Photo_Walkway_Support.ExistingWalkCollisionSupport
 if math.abs(walk.Position.Y+walk.Size.Y/2-(slab.Position.Y+slab.Size.Y/2))>.001 then table.insert(a.issues,"PhotoVisiblePhysicalTopMismatch")end
 if a.intentionalFinishSupportPairs~=1 then table.insert(a.issues,"ExpectedExactFinishSupportPair")end
 if a.models~=3 or a.seats~=1 or a.meshes+a.lights+a.scripts~=0 then table.insert(a.issues,"UnexpectedLayerInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature
 if not a.signatureMatch then table.insert(a.issues,"UnexpectedOwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"Audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","SeatPass","PhotoAccessPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass"}do assert(e[k],"Missing evidence:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in l:GetChildren()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01FStatus","ACCEPTED_PROXY")
 l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

