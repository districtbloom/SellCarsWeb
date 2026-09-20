--!nocheck
-- ELEV01D: crafted staff bench and low agave at the existing covered briefing edge.
local I={Version="2026-09-07.elevation01d.3"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","04_Operations_Pause_Pocket"
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
 for k,v in {BundleId="Institution.Elevation01D."..n,FunctionId="Operations",ZoneId="OperationsCoveredApron",FidelityRole=role,PhaseMin="WORKING",Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="FURNITURE",InteractionAnchor="",FXSocket="",SourceOwned=true,SourceGeometry="PARAMETRIC_PROXY"}do m:SetAttribute(k,v)end
 m.Parent=l;return m
end
local function part(m,n,p,s,c,mat,solid,cls,cf)
 local v=Instance.new(cls or "Part");v.Name=n;v.Size=s;v.CFrame=cf or CFrame.new(p);v.Anchored=true
 v.Material=mat or Enum.Material.Metal;v.Color=c;v.CanCollide=solid==true;v.CanQuery=true;v.CanTouch=v:IsA("Seat");v.CastShadow=true
 v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v:SetAttribute("Elevation01DOwned",true);v.Parent=m;return v
end
local function build(l)
 local m=model(l,"Briefing_Timber_Bench","First staff resting plank beside a yard job board","SUPPORT")
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
 local plant=model(l,"Low_Agave_End_Planter","One hardy potted plant at the staff doorway","LANDSCAPE")
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
end
function I.Install()
 local r,p=root(),parent()
 assert(not layer(),"Owned D already exists; verify and explicitly Uninstall instead of overwrite")
 assert(r:GetAttribute("InstitutionElevation01CStatus")=="ACCEPTED_PROXY","Accepted C required")
 assert(geometryHash(r)=="d8f4df2b" and #r:GetDescendants()==13991,"Unexpected predecessor geometry; preserve edits")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","d8f4df2b");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01DStatus","BUILT_AWAITING_REVIEW")
 l:SetAttribute("ContentSignature",ownedSignature(l))
 return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=layer()
 assert(l,"D absent; nothing to uninstall")
 for _,v in p:GetChildren()do assert(v==l or v.Name=="01_Central_Craft_Pocket"or v.Name=="02_Garden_Promenade_Link"or v.Name=="03_Remaining_Garden_Walks","Later/unknown sibling; do not remove dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned D changed; preserve and investigate")
 assert(geometryHash(r,l)=="d8f4df2b" and #r:GetDescendants()-#l:GetDescendants()-1==13991,"Predecessor changed; preserve D and investigate")
 assert(r:GetAttribute("InstitutionElevation01DStatus")==l:GetAttribute("Status"),"Owned root status changed; preserve")
 l:Destroy();r:SetAttribute("InstitutionElevation01DStatus",nil)
 assert(geometryHash(r)=="d8f4df2b","Prior geometry differs; do not automatically restore it")
 return true
end

local PATHS={
 {name="ApronStepAndBench",points={{3228,397},{3228,406},{3228,410},{3228,414},{3206.5,414},{3206.5,415.9}}},
 {name="BriefingCounter",points={{3228,414},{3228,428},{3195,428},{3195,424}}},
 {name="CentreHall",points={{3228,428},{3228,450}}},
 {name="ServiceSpine",points={{3182,397},{3252,397}}},
}
I.AccessPaths=PATHS
function I.Audit()
 local r,l=root(),assert(layer())
 local a={parts=0,models=0,solids=0,seats=0,meshes=0,lights=0,scripts=0,issues={},metadataIssues={},externalPairs=0,protectedVolumes=0,routeVolumes=0,envelopeTests=0,routeTests=0,bodyPoses=0,floorRays=0,floors={},cornerChecks=0}
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
   if p.X<3203-.001 or p.X>3213+.001 or p.Z<417.5-.001 or p.Z>421.5+.001 or p.Y<.5-.001 or p.Y>3.6 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  for _,g in other do if overlap(v.mn,v.mx,g.mn,g.mx)then a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..g.p:GetFullName())end end
 end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local function checkBody(name,x,z,dx,dz,anchor)
  local hit=workspace:Raycast(Vector3.new(x,1.05,z),Vector3.new(0,-2,0),rp);a.floorRays+=1
  if not hit then table.insert(a.issues,"MissingFloor:"..name);return end
  local feet=hit.Position.Y
  if feet<.09 or feet>.51 then table.insert(a.issues,"UnexpectedFloor:"..name..":"..feet)end
  a.floors[string.format("%.3f",feet)]=(a.floors[string.format("%.3f",feet)]or 0)+1
  local half=anchor and Vector3.new(1.5,2.9,1.5)or Vector3.new(math.abs(dz)*1.5+math.abs(dx)*.3,2.9,math.abs(dx)*1.5+math.abs(dz)*.3)
  local mid=Vector3.new(x,feet+3.5,z);a.bodyPoses+=1
  for _,g in all do if overlap(mid-half,mid+half,g.mn,g.mx)then table.insert(a.issues,"BodyObstacle:"..name..":"..g.p:GetFullName())end end
 end
 for _,path in PATHS do for i=2,#path.points do
  local a0,b0=path.points[i-1],path.points[i];local dx,dz=b0[1]-a0[1],b0[2]-a0[2];local len=math.sqrt(dx*dx+dz*dz);dx/=len;dz/=len
  local steps=math.ceil(len/.5);for s=0,steps do checkBody(path.name,a0[1]+dx*len*s/steps,a0[2]+dz*len*s/steps,dx,dz,false)end
 end end
 checkBody("BenchStanding",3206.5,415.9,0,1,true);checkBody("BriefingStanding",3195,424,0,1,true)
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then
  a.protectedVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end
 end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then
  a.routeVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.0001 and v.mx.X>mn.X+.0001 and v.mn.Z<mx.Z-.0001 and v.mx.Z>mn.Z+.0001 then table.insert(a.issues,"VehicleRouteFootprint:"..p.Name)end end
 end end
 local slat=l.Briefing_Timber_Bench.RestSeat
 for _,p in l.Briefing_Timber_Bench:GetChildren()do if p.Name=="SeatBearing"then local _,mx=bounds(p);local mn=bounds(slat);if math.abs(mx.Y-mn.Y)>.001 then table.insert(a.issues,"SeatBearingContact")end end end
 if a.models~=2 or a.seats~=1 or a.meshes+a.lights+a.scripts~=0 then table.insert(a.issues,"UnexpectedLayerInventory")end
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
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01DStatus","ACCEPTED_PROXY")
 l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

