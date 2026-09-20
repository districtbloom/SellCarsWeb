--!nocheck
-- ELEV01K: four steel cleats join retained Mechanical portals to the canopy.
local I={Version="2026-09-08.elevation01k.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","11_Mechanical_Roof_Connections"
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
local ZS={155.25,170.75,179.25,194.75}
local function architecture()return root()["05_Architecture_Massing"]["02_Production"].Mechanical end
local function lightLayer()return root()["10_Institution_Fidelity_R1"]["06_Atmosphere"]["03_Lighting_Hierarchy"]end
local function header(i)return lightLayer()["Mechanical_Matte_Header_"..i].MattePortalHeader end
local function make(m,n,mn,mx)
 local p=Instance.new("Part");p.Name=n;p.Size=mx-mn;p.CFrame=CFrame.new((mn+mx)/2)
 p.Color=Color3.fromRGB(39,44,44);p.Material=Enum.Material.Metal;p.Reflectance=0
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false;p.TopSurface=0;p.BottomSurface=0;p.Parent=m
 return p
end
local function build(l)
 for i,z in ZS do
  local m=Instance.new("Model");m.Name="Roof_Cleat_"..i
  for k,v in {BundleId="Institution.Elevation01K.MechanicalCleat"..i,FunctionId="Mechanical",ZoneId="RetainedMechanicalPortal",FidelityRole="ARCHITECTURE",PhaseMin="INSTITUTION",Ancestor="Original open workshop frame -> fitted canopy bearing cleat",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="OVERHEAD_CONNECTION_ONLY",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="FABRICATED_STEEL_OFFSET_CLEAT_NO_NEW_ROOF_OR_COLUMN",PostCenterZ=z}do m:SetAttribute(k,v)end
  m.Parent=l
  make(m,"Header_Shoe",V(3090.35,13.1,z-.6),V(3091.65,13.22,z+.6))
  make(m,"Vertical_Web",V(3090.9,13.22,z-.48),V(3091.1,13.78,z+.48))
  make(m,"Canopy_Bearing_Plate",V(3089.35,13.78,z-.6),V(3091.65,13.9,z+.6))
 end
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned K exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01JStatus")=="ACCEPTED_PROXY","Accepted J required")
 assert(geometryHash(r)=="aa0830b3" and #r:GetDescendants()==14225,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","aa0830b3");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01KStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"K absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true,["09_Sales_Desk_Joinery"]=true,["10_Tune_Equipment_Backdrop"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned K changed; preserve")
 assert(geometryHash(r,l)=="aa0830b3" and #r:GetDescendants()-#l:GetDescendants()-1==14225,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01KStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01KStatus",nil);assert(geometryHash(r)=="aa0830b3","Unexpected rollback");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local roof=architecture().OpenCanopy;local fixture=lightLayer().Mechanical_Eave
 local a={parts=0,models=0,solids=0,lights=0,meshes=0,scripts=0,issues={},metadataIssues={},contacts=0,cornerChecks=0,externalPairs=0,ownPairs=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,bodyPoses=0,floorSamples=0,lampConeRays=0,lampConeHits=0}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,v in l:GetDescendants()do
  if v:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k)end end
  elseif v:IsA("BasePart")then a.parts+=1;if v.CanCollide then a.solids+=1 end;if not v.Anchored or v.CanTouch or v.CastShadow or not v.CanQuery then table.insert(a.issues,"Behavior:"..v.Name)end
  elseif v:IsA("Light")then a.lights+=1
  elseif v:IsA("DataModelMesh")then a.meshes+=1
  elseif v:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for i,v in own do
  local z=v.p.Parent:GetAttribute("PostCenterZ")
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   a.cornerChecks+=1;local q=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2)
   if q.X<3089.349 or q.X>3091.651 or q.Y<13.099 or q.Y>13.901 or q.Z<z-.601 or q.Z>z+.601 then table.insert(a.issues,"OutsideCleatBounds:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p:GetFullName()..":"..o.p:GetFullName())end end
  for j=i+1,#own do local o=own[j];a.ownPairs+=1;if overlap(v.mn,v.mx,o.mn,o.mx,.001)then table.insert(a.issues,"OwnOverlap:"..v.p:GetFullName()..":"..o.p:GetFullName())end end
 end
 local function checkContact(n,upper,lower)
  local u1,u2=bounds(upper);local d1,d2=bounds(lower);a.contacts+=1
  if math.abs(u1.Y-d2.Y)>.001 or math.min(u2.X,d2.X)-math.max(u1.X,d1.X)<.05 or math.min(u2.Z,d2.Z)-math.max(u1.Z,d1.Z)<.05 then table.insert(a.issues,"UnsupportedContact:"..n)end
 end
 local roofMin,roofMax=bounds(roof)
 for i,z in ZS do
  local m=l["Roof_Cleat_"..i];local h=header(math.ceil(i/2))
  checkContact("HeaderShoe"..i,m.Header_Shoe,h)
  checkContact("ShoeWeb"..i,m.Vertical_Web,m.Header_Shoe)
  checkContact("WebPlate"..i,m.Canopy_Bearing_Plate,m.Vertical_Web)
  checkContact("PlateRoof"..i,roof,m.Canopy_Bearing_Plate)
  local p1,p2=bounds(m.Canopy_Bearing_Plate)
  if math.min(p2.X,roofMax.X)-math.max(p1.X,roofMin.X)<.64 then table.insert(a.issues,"ShortCanopyBearing:"..i)end
 end
 local function volume(n,cf,s)
  for _,v in own do local mn,mx=cf.Position-s/2,cf.Position+s/2;if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,n..":"..v.p:GetFullName())end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then
  a.routeVolumes+=1;local mn,mx=bounds(p);mn=V(mn.X,.1,mn.Z);mx=V(mx.X,8.0,mx.Z)
  for _,v in own do a.routeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"RouteVolume:"..p.Name)end end
 end end
 for _,z in {163,187}do
  volume("MechanicalCar",CFrame.new(3066,4,z),V(34,8,14))
  volume("RetainedPortalAperture",CFrame.new(3091,5.8,z),V(4,11.6,15.4))
 end
 volume("MechanicalStaffAisle",CFrame.new(3031,4.5,175),V(6,7.5,52))
 local mn,mx=fixture:GetAttribute("AllowedMin"),fixture:GetAttribute("AllowedMax");volume("RetainedLampDeclaredEnvelope",CFrame.new((mn+mx)/2),mx-mn)
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={l};ray.RespectCanCollide=false
 local lens=fixture.RecessedLens;local lamp=lens.ManagedLight;assert(lamp.Face==Enum.NormalId.Bottom and lamp.Angle==120,"Lamp configuration changed")
 -- Sample all cone rings from the lens centre and four face corners; no new shadow/light changes.
 for _,uv in {{0,0},{-.49,-.49},{-.49,.49},{.49,-.49},{.49,.49}}do
  local origin=lens.CFrame:PointToWorldSpace(V(lens.Size.X*uv[1],-lens.Size.Y/2-.002,lens.Size.Z*uv[2]))
  for ring=0,6 do for spoke=0,(ring==0 and 0 or 23)do
   local theta=math.rad(60)*ring/6;local az=2*math.pi*spoke/24
   local direction=lens.CFrame:VectorToWorldSpace(V(math.sin(theta)*math.cos(az),-math.cos(theta),math.sin(theta)*math.sin(az)))
   a.lampConeRays+=1;local hit=workspace:Raycast(origin,direction*lamp.Range,ray)
   if hit then a.lampConeHits+=1;table.insert(a.issues,"LampCone:"..hit.Instance:GetFullName())end
  end end
 end
 local ground=RaycastParams.new();ground.FilterType=Enum.RaycastFilterType.Include;ground.FilterDescendantsInstances={r};ground.RespectCanCollide=true
 local points={V(3099,3.2,149),V(3099,3.2,163),V(3086,3.2,163),V(3099,3.2,163),V(3099,3.2,175),V(3099,3.2,187),V(3086,3.2,187),V(3099,3.2,187),V(3099,3.2,201),V(3099,3.2,149)}
 for i=2,#points do local p,q=points[i-1],points[i];local steps=math.ceil((q-p).Magnitude/.5)
  for j=0,steps do local c=p:Lerp(q,j/steps);a.bodyPoses+=1;volume("MechanicalPortalWalk",CFrame.new(c),V(3,5.5,3))
   a.floorSamples+=1;if not workspace:Raycast(V(c.X,1.1,c.Z),V(0,-3,0),ground)then table.insert(a.issues,"MissingPhysicalFloor")end
  end
 end
 if a.parts~=12 or a.models~=4 or a.solids+a.lights+a.meshes+a.scripts~=0 then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"K audit failed")
 for _,k in {"VisualPass","DayNightReviewed","RegressionsPass","OperatorCyclesPass","ActualWalkingPass","RollbackPass","SourceMatch","RenderingReviewed","PreservationGuardPass","LampClearancePass"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in l:GetChildren()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01KStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

