--!nocheck
-- ELEV01M: one economical mature desert silhouette; accepted garden and paths untouched.
local I={Version="2026-09-08.elevation01m.2"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","13_Bed3_Desert_Silhouette"
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
local C={bark=Color3.fromRGB(106,93,66),base=Color3.fromRGB(81,79,57),sage=Color3.fromRGB(99,128,105),blue=Color3.fromRGB(110,139,123),tip=Color3.fromRGB(141,153,112)}
local function part(m,n,cf,size,col,cls)
 local p=Instance.new(cls or "Part");p.Name=n;p.CFrame=cf;p.Size=size;p.Color=col;p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true;p.TopSurface=0;p.BottomSurface=0;p.Parent=m
 return p
end
local function tube(m,n,a,b,d,c)
 local p=part(m,n,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),V((b-a).Magnitude,d,d),c);p.Shape=Enum.PartType.Cylinder;p.Material=Enum.Material.Wood
 p:SetAttribute("BotanicalRole","STEM");return p
end
local function leaf(m,n,a,b,w,col)
 -- Two native triangular halves form one tapered blade with a sharp, legible end.
 for _,sign in {-1,1}do
  local cf=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,sign*math.pi/2)*CFrame.new(0,w/4,0)
  local p=part(m,n.."_"..(sign<0 and "L"or"R"),cf,V(.065,w/2,(b-a).Magnitude),col,"WedgePart");p:SetAttribute("BotanicalRole","LEAF")
 end
end
local function crown(m,n,p,s,phase)
 -- Same fourteen paired blades distributed through three pitches for a fuller crown.
 for i=1,5 do
  local a=i*math.pi*2/5+phase;local d=V(math.cos(a),0,math.sin(a))
  leaf(m,n.."_Lower"..i,p+d*.07*s,p+d*(2.02+.17*math.sin(i))*s+V(0,(-.68+.2*math.cos(i))*s,0),.62*s,i%2==0 and C.blue or C.sage)
 end
 for i=1,5 do
  local a=i*math.pi*2/5+phase+.55;local d=V(math.cos(a),0,math.sin(a))
  leaf(m,n.."_Middle"..i,p,p+d*(1.58+.16*math.sin(i))*s+V(0,(.55+.24*math.cos(i))*s,0),.60*s,i%3==0 and C.blue or C.sage)
 end
 for i=1,4 do
  local a=i*math.pi*2/4+phase+.3;local d=V(math.cos(a),0,math.sin(a))
  leaf(m,n.."_Upright"..i,p,p+d*.70*s+V(0,(1.35+.16*math.sin(i))*s,0),.38*s,C.tip)
 end
end
local function build(l)
 local m=Instance.new("Model");m.Name="Mature_Branching_Desert_Specimen"
 for k,v in {BundleId="Institution.Elevation01M.Bed3DesertSilhouette",FunctionId="EstateLandscape",ZoneId="Desert_Bed_3_East",FidelityRole="STORY",PhaseMin="INSTITUTION",Ancestor="Retained low scrub -> selectively maintained mature desert specimen",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="PLANTED_RESERVE_ONLY",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="BRANCHING_YUCCA_FORM_TWO_UNEQUAL_CROWNS_FINAL_BOTANICAL_MESH_PENDING",AllowedMin=V(3136.4,.09,222.5),AllowedMax=V(3143.6,10,230),GeometryShadows=true}do m:SetAttribute(k,v)end
 m.Parent=l
 tube(m,"Grounded_Root_Neck",V(3140,.149,226),V(3140,.5,226),.82,C.bark)
 tube(m,"Main_Stem",V(3140,.42,226),V(3140.12,6.55,226.08),.67,C.bark)
 tube(m,"Branch_Shoulder",V(3140.03,3.65,226.03),V(3139.32,4.55,226.6),.52,C.bark)
 tube(m,"Side_Stem",V(3139.32,4.45,226.6),V(3139.10,5.35,226.78),.43,C.bark)
 crown(m,"Main_Crown",V(3140.12,6.55,226.08),1.12,.23)
 crown(m,"Side_Crown",V(3139.10,5.35,226.78),.8,1.1)
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned M exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01KStatus")=="ACCEPTED_PROXY","Accepted K required")
 assert(geometryHash(r)=="5a07bc8f" and #r:GetDescendants()==14243,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","5a07bc8f");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01MStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"M absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true,["09_Sales_Desk_Joinery"]=true,["10_Tune_Equipment_Backdrop"]=true,["11_Mechanical_Roof_Connections"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned M changed; preserve")
 assert(geometryHash(r,l)=="5a07bc8f" and #r:GetDescendants()-#l:GetDescendants()-1==14243,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01MStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01MStatus",nil);assert(geometryHash(r)=="5a07bc8f","Unexpected rollback");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local m=l.Mature_Branching_Desert_Specimen
 local a={parts=0,models=0,solids=0,lights=0,meshes=0,scripts=0,shadowParts=0,issues={},metadataIssues={},cornerChecks=0,externalPairs=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,bodyPoses=0,floorSamples=0,landmarkRays=0}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,v in l:GetDescendants()do
  if v:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry","AllowedMin","AllowedMax"}do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k)end end
  elseif v:IsA("BasePart")then a.parts+=1;if v.CanCollide then a.solids+=1 end;if v.CastShadow then a.shadowParts+=1 end;if not v.Anchored or v.CanTouch or not v.CanQuery or v.CanCollide or v.Transparency~=0 then table.insert(a.issues,"Behavior:"..v.Name)end
  elseif v:IsA("Light")then a.lights+=1
  elseif v:IsA("DataModelMesh")then a.meshes+=1
  elseif v:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 local pocketMin,pocketMax=m:GetAttribute("AllowedMin"),m:GetAttribute("AllowedMax")
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   local q=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2);a.cornerChecks+=1
   if q.X<pocketMin.X-.001 or q.X>pocketMax.X+.001 or q.Y<pocketMin.Y-.001 or q.Y>pocketMax.Y+.001 or q.Z<pocketMin.Z-.001 or q.Z>pocketMax.Z+.001 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
 end
 local function volume(n,cf,size)
  local mn,mx=cf.Position-size/2,cf.Position+size/2
  for _,v in own do if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,n..":"..v.p.Name)end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.001 and v.mx.X>mn.X+.001 and v.mn.Z<mx.Z-.001 and v.mx.Z>mn.Z+.001 then table.insert(a.issues,"RouteFootprint:"..p.Name)end end
 end end
 volume("FullEightStudAxis",CFrame.new(3130,6,245),V(8,12,310))
 for _,z in {211,276}do volume("Crossover",CFrame.new(3130,4,z),V(68,8,14))end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,x in {3127,3130,3133}do for z=205,282,.5 do
  a.bodyPoses+=1;volume("ActualAxisBody",CFrame.new(x,3.2,z),V(3,5.8,3));a.floorSamples+=1
  local h=workspace:Raycast(V(x,1,z),V(0,-2,0),ray);if not h or math.abs(h.Position.Y-.095)>.003 then table.insert(a.issues,"AxisFloor")end
 end end
 -- A plant-side viewing pocket is on retained gravel, outside the root and path; no new walkway.
 for _,x in {3134.5,3135}do for z=222,231,.5 do
  a.bodyPoses+=1;volume("PlantSideView",CFrame.new(x,3.2,z),V(3,5.8,3));a.floorSamples+=1
  local h=workspace:Raycast(V(x,1,z),V(0,-2,0),ray);if not h or math.abs(h.Position.Y-.095)>.003 then table.insert(a.issues,"PocketFloor")end
 end end
 local justNew=RaycastParams.new();justNew.FilterType=Enum.RaycastFilterType.Include;justNew.FilterDescendantsInstances={l};justNew.RespectCanCollide=false
 for _,x in {3127,3130,3133}do for _,z in {103,145,212,276}do for _,y in {10,20,32}do
  local p,q=V(x,5.5,z),V(3130,y,385);a.landmarkRays+=1
  if workspace:Raycast(p,q-p,justNew)then table.insert(a.issues,"LandmarkOcclusion")end
 end end end
 local bottom=m.Grounded_Root_Neck.Position.Y-m.Grounded_Root_Neck.Size.X/2
 local gravel
 for _,p in r["10_Institution_Fidelity_R1"]["06_Atmosphere"]["01_Movement_Surfaces"].Central_Gravel_Reservations:GetChildren()do
  if p:IsA("BasePart") and p.Name=="CompactedGravel" and math.abs(p.Position.Z-243.5)<.001 then assert(not gravel,"Duplicate retained gravel");gravel=p end
 end
 assert(gravel,"Retained bed3 gravel absent")
 local gm,gx=bounds(gravel);local neck=m.Grounded_Root_Neck;local radius=neck.Size.Y/2
 a.rootSurface=gravel:GetFullName();a.rootSurfaceTop=gx.Y;a.rootSurfaceGap=bottom-gx.Y
 if gravel.Orientation.Magnitude>.001 or math.abs(gm.X-3115.25)>.001 or math.abs(gx.X-3144.75)>.001 or math.abs(gm.Z-219)>.001 or math.abs(gx.Z-268)>.001 or math.abs(gx.Y-.149)>.001 or math.abs(a.rootSurfaceGap)>.001 or neck.Position.X-radius<gm.X or neck.Position.X+radius>gx.X or neck.Position.Z-radius<gm.Z or neck.Position.Z+radius>gx.Z then table.insert(a.issues,"RootNotGroundedOnRetainedGravel")end
 if a.parts~=60 or a.models~=1 or a.solids+a.lights+a.meshes+a.scripts~=0 or a.shadowParts~=a.parts then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"M audit failed")
 for _,k in {"VisualPass","DayNightReviewed","RegressionsPass","ActualWalkingPass","AxisSightlinePass","RollbackPass","SourceMatch","RenderingReviewed","ShadowCostReviewed","PreservationGuardPass"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l.Mature_Branching_Desert_Specimen:SetAttribute("AssetStatus","MODELER_READY")
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01MStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

