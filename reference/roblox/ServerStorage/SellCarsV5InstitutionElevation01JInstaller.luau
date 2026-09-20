--!nocheck
-- ELEV01J: removable industrial wall liners reveal retained Tune equipment.
local I={Version="2026-09-08.elevation01j.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","10_Tune_Equipment_Backdrop"
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


local V=Vector3.new
local function tune()return root()["10_Institution_Fidelity_R1"]["03_Remaining_Production"]["03_Tune"]end
local function wall()return root()["05_Architecture_Massing"]["02_Production"].Tune_Performance.OuterWall end
local spans={{279.15,293.85},{294.15,304.85},{305.15,316.85},{317.15,331.85},{332.15,334.85}}
local function xzOverlap(pa,pb)
 local ac,bc=pa.CFrame,pb.CFrame
 local delta=bc.Position-ac.Position
 for _,axis in {ac.RightVector,ac.LookVector,bc.RightVector,bc.LookVector}do
  local n=V(axis.X,0,axis.Z);if n.Magnitude<.001 then continue end;n=n.Unit
  local ar=math.abs(n:Dot(ac.RightVector))*pa.Size.X/2+math.abs(n:Dot(ac.LookVector))*pa.Size.Z/2
  local br=math.abs(n:Dot(bc.RightVector))*pb.Size.X/2+math.abs(n:Dot(bc.LookVector))*pb.Size.Z/2
  if math.abs(delta:Dot(n))>=ar+br-.001 then return false end
 end
 return true
end

local function build(l)
 local m=Instance.new("Model");m.Name="Inset_Enamel_Wall_Liners"
 for k,v in {BundleId="Institution.Elevation01J.TuneWallLiners",FunctionId="Tune_Performance",ZoneId="RetainedTuneSupportWall",FidelityRole="ARCHITECTURE",PhaseMin="INSTITUTION",Ancestor="Original dark workshop shell -> clean calibration-workshop liner",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="WALL_FINISH_ONLY",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="FITTED_ENAMEL_LINER_RETAIN_DARK_PLINTH_JOINTS_AND_SHELL"}do m:SetAttribute(k,v)end
 m.Parent=l
 for i,span in spans do
  local p=Instance.new("Part");p.Name="WallLiner_"..i
  p.Size=V(.06,8.9,span[2]-span[1]);p.CFrame=CFrame.new(3008.03,6,(span[1]+span[2])/2)
  p.Color=Color3.fromRGB(183,188,180);p.Material=Enum.Material.Metal;p.Reflectance=0
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
 end
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned J exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01IStatus")=="ACCEPTED_PROXY","Accepted I required")
 assert(geometryHash(r)=="b432f926" and #r:GetDescendants()==14217,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","b432f926");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01JStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"J absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true,["09_Sales_Desk_Joinery"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned J changed; preserve")
 assert(geometryHash(r,l)=="b432f926" and #r:GetDescendants()-#l:GetDescendants()-1==14217,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01JStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01JStatus",nil);assert(geometryHash(r)=="b432f926","Unexpected rollback");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local w=wall()
 local a={parts=0,models=0,solids=0,lights=0,meshes=0,scripts=0,issues={},metadataIssues={},contacts=0,cornerChecks=0,externalPairs=0,ownPairs=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,accessPaths=0,bodyPoses=0,standingVolumes=0,floorSamples=0,inheritedFloorMismatches={}}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 local wmin,wmax=bounds(w)
 for _,v in l:GetDescendants()do
  if v:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k)end end
  elseif v:IsA("BasePart")then a.parts+=1;if v.CanCollide then a.solids+=1 end;if not v.Anchored or v.CanTouch or v.CastShadow or not v.CanQuery then table.insert(a.issues,"Behavior:"..v.Name)end
  elseif v:IsA("Light")then a.lights+=1
  elseif v:IsA("DataModelMesh")then a.meshes+=1
  elseif v:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for i,v in own do
  a.contacts+=1;if math.abs(v.mn.X-wmax.X)>.001 then table.insert(a.issues,"WallContact:"..v.p.Name)end
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   a.cornerChecks+=1;local q=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2)
   if q.X<3007.999 or q.X>3008.061 or q.Y<1.549 or q.Y>10.451 or q.Z<279.149 or q.Z>334.851 then table.insert(a.issues,"OutsideLinerBounds:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)and xzOverlap(v.p,o.p)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
  for j=i+1,#own do local o=own[j];a.ownPairs+=1;if overlap(v.mn,v.mx,o.mn,o.mx,.001)then table.insert(a.issues,"OwnOverlap:"..v.p.Name..":"..o.p.Name)end end
 end
 local joints={}
 for _,p in tune().Calibration_Floor_And_Utility_Edge:GetChildren()do if p.Name=="WorkshopWallJoint"then table.insert(joints,p)end end
 table.sort(joints,function(a,b)return a.Position.Z<b.Position.Z end)
 assert(#joints==4,"Retained joints changed")
 for i,j in joints do
  local a1,a2=bounds(l.Inset_Enamel_Wall_Liners["WallLiner_"..i]);local b1,b2=bounds(l.Inset_Enamel_Wall_Liners["WallLiner_"..(i+1)]);local j1,j2=bounds(j)
  a.contacts+=1;if math.abs((a2.Z+b1.Z)/2-j.Position.Z)>.001 or j1.Z-a2.Z<.12 or b1.Z-j2.Z<.12 then table.insert(a.issues,"JointReveal:"..i)end
 end
 local function volume(n,cf,s)
  for _,v in own do local mn,mx=cf.Position-s/2,cf.Position+s/2;if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,n..":"..v.p.Name)end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)and xzOverlap(v.p,p)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;for _,v in own do a.routeTests+=1;if xzOverlap(v.p,p)then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 for _,z in {295,319}do
  volume("TuneCar",CFrame.new(3066,4,z),V(34,8,14))
  volume("TuneOperatorSweptReservation",CFrame.new(3037,3.35,z),V(4,6.5,4))
 end
 volume("TuneStaffAisle",CFrame.new(3031,4.5,307),V(6,7.5,54))
 for _,m in tune():GetDescendants()do if m:IsA("Model")then local n=m:GetAttribute("InteractionAnchor");if n and n~=""then local p=m:FindFirstChild(n,true);if p and p:IsA("BasePart")then a.standingVolumes+=1;volume("Standing:"..n,CFrame.new(p.Position.X,3.5,p.Position.Z),V(3,5.5,3))end end end end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,path in tune()["98_Access_Paths"]:GetChildren()do
  a.accessPaths+=1;local pts=path:GetChildren();table.sort(pts,function(a,b)return a.Name<b.Name end)
  for i=2,#pts do local p,q=pts[i-1].Value,pts[i].Value;local steps=math.ceil((q-p).Magnitude/.5)
   for j=0,steps do local c=p:Lerp(q,j/steps);a.bodyPoses+=1;volume("TuneAccess:"..path.Name,CFrame.new(c),V(3,5.5,3))
    a.floorSamples+=1;local hit=workspace:Raycast(V(c.X,1.1,c.Z),V(0,-3,0),ray);if not hit then table.insert(a.issues,"MissingPhysicalFloor:"..path.Name)end
   end
  end
 end
 for _,z in {280,295,307,319,334}do
  local hit=workspace:Raycast(V(3031,1.1,z),V(0,-3,0),ray)
  if hit then local _,top=bounds(tune().Calibration_Floor_And_Utility_Edge.StaffNonSlipWalk)
   if top.Y-hit.Position.Y>.1 then table.insert(a.inheritedFloorMismatches,{x=3031,z=z,visibleTop=top.Y,physicalTop=hit.Position.Y})end
  end
 end
 if a.parts~=5 or a.models~=1 or a.solids+a.lights+a.meshes+a.scripts~=0 then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"J audit failed")
 for _,k in {"VisualPass","DayNightReviewed","RegressionsPass","OperatorCyclesPass","RollbackPass","SourceMatch","RenderingReviewed","PreservationGuardPass","InheritedFloorFindingRecorded"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l.Inset_Enamel_Wall_Liners:SetAttribute("AssetStatus","MODELER_READY");l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01JStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

