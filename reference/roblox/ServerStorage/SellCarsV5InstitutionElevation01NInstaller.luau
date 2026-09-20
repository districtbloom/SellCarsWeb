--!nocheck
-- ELEV01N: one constant warm Intake hospitality fixture; existing lighting controller remains unchanged.
local I={Version="2026-09-08.elevation01n.3"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","14_Intake_Waiting_Light"
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
  if v:IsA("Light")then table.insert(rows,path.."|lightform|"..tostring(v.Color).."|"..tostring(v.Enabled).."|"..tostring(v.Brightness).."|"..tostring(v.Range).."|"..tostring(v.Shadows).."|"..((v:IsA("SurfaceLight")or v:IsA("SpotLight"))and(v.Face.Name..":"..tostring(v.Angle))or"POINT"))end
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
local function plinth()return root()["10_Institution_Fidelity_R1"]["07_Elevation_01"]["08_Intake_Waiting_Comfort"].Owned_Ground_Continuity.SouthBenchAlcove end
local function priorLightSignature(excluded)
 local rows={}
 for _,v in root():GetDescendants()do if v:IsA("Light")and not(excluded and v:IsDescendantOf(excluded))then
  for k,value in v:GetAttributes()do table.insert(rows,v:GetFullName().."|attribute|"..k.."|"..typeof(value).."|"..tostring(value))end
  for _,tag in v:GetTags()do table.insert(rows,v:GetFullName().."|tag|"..tag)end
  local form=(v:IsA("SurfaceLight")or v:IsA("SpotLight"))and(v.Face.Name..":"..tostring(v.Angle))or"POINT"
  table.insert(rows,v:GetFullName().."|"..tostring(v.Parent.Position).."|"..tostring(v.Color).."|"..tostring(v.Enabled).."|"..tostring(v.Brightness).."|"..tostring(v.Range).."|"..tostring(v.Shadows).."|"..form)
 end end
 table.sort(rows);local h=5381;for _,s in rows do h=addHash(h,s.."\n")end;return string.format("%08x",h)
end
local function B(m,n,x,y,z,w,h,d,col,mat)
 local p=Instance.new("Part");p.Name=n;p.CFrame=CFrame.new(x,y,z);p.Size=V(w,h,d);p.Material=mat or Enum.Material.Metal;p.Color=col or Color3.fromRGB(39,44,44)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local function build(l)
 local m=Instance.new("Model");m.Name="Waiting_Porch_Light"
 for k,v in {BundleId="Institution.Elevation01N.IntakeWaitingLight",FunctionId="Intake_Appraisal",ZoneId="ExistingSellerPublicExchange",FidelityRole="UTILITY",PhaseMin="INSTITUTION",Ancestor="Retained waiting bench -> carefully lit institutional customer welcome",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="BENCH_CORNER_RESERVE",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="SLIM_SUPPORTED_INDUSTRIAL_PORCH_FIXTURE_NO_NEW_CANOPY",AllowedMin=V(3085.39,.709,37.12),AllowedMax=V(3088.17,8.881,38.38),LightingPolicy="CONSTANT_LOW_PUBLIC_ACCENT_BOTH_DAY_AND_NIGHT",MountPath=plinth():GetFullName()}do m:SetAttribute(k,v)end;m.Parent=l
 B(m,"FootPlate",3087.9,.77,37.70,.5,.12,.5)
 B(m,"SquareMast",3087.9,4.855,37.75,.18,8.05,.18)
 B(m,"BaseSocketCollar",3087.9,.94,37.75,.3,.22,.3)
 B(m,"SupportedTopArm",3087.275,8.8,37.75,1.43,.16,.18)
 B(m,"FoldedBronzeHood",3086.65,8.6,38,2.5,.24,.6,Color3.fromRGB(151,119,65))
 B(m,"WestCutoffReturn",3085.46,8.37,38,.12,.24,.6)
 B(m,"EastCutoffReturn",3087.84,8.37,38,.12,.24,.6)
 B(m,"SouthCutoffReturn",3086.65,8.37,37.76,2.26,.24,.12)
 B(m,"NorthCutoffReturn",3086.65,8.37,38.24,2.26,.24,.12)
 local lens=B(m,"RecessedDiffuser",3086.65,8.365,38,2.26,.03,.36,Color3.fromRGB(220,221,209),Enum.Material.Glass)
 local lamp=Instance.new("SurfaceLight");lamp.Name="HospitalityLight";lamp.Face=Enum.NormalId.Bottom;lamp.Color=Color3.fromRGB(255,224,177);lamp.Range=10;lamp.Angle=110;lamp.Brightness=1.1;lamp.Shadows=false;lamp.Enabled=true;lamp:SetAttribute("Ownership","Elevation01N_ConstantPublicAccent");lamp.Parent=lens
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned N exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01MStatus")=="ACCEPTED_PROXY","Accepted M required")
 assert(geometryHash(r)=="55949c80" and #r:GetDescendants()==14306,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","55949c80");l:SetAttribute("PriorLightSignature",priorLightSignature());l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01NStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"N absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true,["09_Sales_Desk_Joinery"]=true,["10_Tune_Equipment_Backdrop"]=true,["11_Mechanical_Roof_Connections"]=true,["13_Bed3_Desert_Silhouette"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned N changed; preserve")
 assert(geometryHash(r,l)=="55949c80" and #r:GetDescendants()-#l:GetDescendants()-1==14306,"Predecessor changed; preserve")
 assert(priorLightSignature(l)==l:GetAttribute("PriorLightSignature"),"Prior light color/face/angle/state changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01NStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01NStatus",nil);assert(geometryHash(r)=="55949c80","Unexpected rollback");return true
end
function I.Audit()
 local r,l=root(),assert(layer());assert(r["10_Institution_Fidelity_R1"]["06_Atmosphere"]["03_Lighting_Hierarchy"]:GetAttribute("Preset")=="Day","N Audit is Day-only; validate Night via explicit69-light check then restore Day");local m=l.Waiting_Porch_Light
 local a={parts=0,models=0,solids=0,lights=0,meshes=0,scripts=0,shadowParts=0,issues={},metadataIssues={},cornerChecks=0,externalPairs=0,contactChecks=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,accessPaths=0,bodyPoses=0,floorSamples=0,lightTargetRays=0}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry","AllowedMin","AllowedMax","LightingPolicy","MountPath"}do if p:GetAttribute(k)==nil then table.insert(a.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then a.parts+=1;if p.CanCollide then a.solids+=1 end;if p.CastShadow then a.shadowParts+=1 end;if not p.Anchored or p.CanTouch or not p.CanQuery or p.Transparency~=0 then table.insert(a.issues,"Behavior:"..p.Name)end
  elseif p:IsA("Light")then a.lights+=1
  elseif p:IsA("DataModelMesh")then a.meshes+=1
  elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 local lo,hi=m:GetAttribute("AllowedMin"),m:GetAttribute("AllowedMax")
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   local q=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2);a.cornerChecks+=1
   if q.X<lo.X-.001 or q.X>hi.X+.001 or q.Y<lo.Y-.001 or q.Y>hi.Y+.001 or q.Z<lo.Z-.001 or q.Z>hi.Z+.001 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
 end
 local function volume(n,center,size)
  local mn,mx=center-size/2,center+size/2
  for _,v in own do if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,n..":"..v.p.Name)end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.001 and v.mx.X>mn.X+.001 and v.mn.Z<mx.Z-.001 and v.mx.Z>mn.Z+.001 then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 local intake=r["10_Institution_Fidelity_R1"]["04_Frontage_And_Owner"]["01_Intake"]
 for _,path in intake["98_Access_Paths"]:GetChildren()do
  a.accessPaths+=1;local pts=path:GetChildren();table.sort(pts,function(x,y)return x.Name<y.Name end)
  for i=2,#pts do local p,q=pts[i-1].Value,pts[i].Value;local steps=math.ceil((q-p).Magnitude/.5)
   for j=0,steps do a.bodyPoses+=1;volume("RetainedAccess:"..path.Name,p:Lerp(q,j/steps),V(3,5.5,3))end
  end
 end
 for _,q in {V(3086.55,5.15,35),V(3083.3,3.75,35),V(3082.5,3.75,35),V(3078.8,3.2,40.5),V(3078.8,3.2,49.5)}do a.bodyPoses+=1;volume("SeatAndSafeApproach",q,V(3,5.5,3))end
 local ground=plinth();local gm,gx=bounds(ground);local fm,fx=bounds(m.FootPlate)
 a.mount=ground:GetFullName();a.mountGap=fm.Y-gx.Y;a.footNorthMargin=gx.Z-fx.Z;a.contactChecks+=1
 if math.abs(a.mountGap)>.001 or fm.X<gm.X-.001 or fx.X>gx.X+.001 or fm.Z<gm.Z-.001 or fx.Z>gx.Z+.001 or m:GetAttribute("MountPath")~=ground:GetFullName()then table.insert(a.issues,"UnsupportedFoot")end
 local function touch(n,x,y)a.contactChecks+=1;if math.abs(x-y)>.001 then table.insert(a.issues,"Contact:"..n)end end
 local mm,mx=bounds(m.SquareMast);local am,ax=bounds(m.SupportedTopArm);local cm,cx=bounds(m.FoldedBronzeHood)
 touch("MastFoot",mm.Y,fx.Y);touch("MastArmTop",mx.Y,ax.Y);touch("ArmHood",am.Y,cx.Y)
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,q in {{3082.5,12,.71},{3082.5,30,.71},{3082.5,35,.71},{3085,35,.71},{3087.9,37.7,.71},{3078.8,35,.095},{3078.8,40.5,.095},{3078.8,49.5,.095},{3082.5,54,.71}}do
  a.floorSamples+=1;local h=workspace:Raycast(V(q[1],1.1,q[2]),V(0,-2,0),ray);if not h or math.abs(h.Position.Y-q[3])>.003 then table.insert(a.issues,"PhysicalFloor:"..q[1]..":"..q[2])end
 end
 local lamp=m.RecessedDiffuser.HospitalityLight
 if not lamp.Enabled or lamp.Shadows or lamp.Face~=Enum.NormalId.Bottom or lamp.Angle~=110 or lamp.Range~=10 or math.abs(lamp.Brightness-1.1)>.0001 or lamp.Color~=Color3.fromRGB(255,224,177)then table.insert(a.issues,"ConstantAccentSettings")end
 a.priorLightsUnchanged=priorLightSignature(l)==l:GetAttribute("PriorLightSignature");if not a.priorLightsUnchanged then table.insert(a.issues,"PriorLightDrift")end
 a.activeLights=0;for _,p in r:GetDescendants()do if p:IsA("Light")and p.Enabled then a.activeLights+=1 end end
 if a.activeLights~=52 then table.insert(a.issues,"DayActiveCountNot52")end
 -- Sample intended target visibility through retained geometry; these are not irradiance or universal spill certificates.
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=false
 local origin=m.RecessedDiffuser.Position-V(0,.02,0)
 for _,target in {V(3086.55,2.69,34),V(3086.55,2.69,35),V(3086.55,2.69,36),V(3083,1,35)}do
  a.lightTargetRays+=1
  local delta=target-origin;local reach=delta.Magnitude;local angle=math.deg(math.acos(math.clamp(-delta.Y/reach,-1,1)))
  -- Conservative centre-emitter sample, not a full SurfaceLight irradiance certificate.
  if reach>lamp.Range or angle>lamp.Angle/2 then table.insert(a.issues,"LightTargetOutsideCentreReach")end
  local h=workspace:Raycast(origin,target-origin,rp)
  if h and (h.Position-target).Magnitude>.15 then table.insert(a.issues,"LightTargetBlocked:"..h.Instance:GetFullName())end
 end
 if a.parts~=10 or a.models~=1 or a.lights~=1 or a.solids+a.shadowParts+a.meshes+a.scripts~=0 then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"N audit failed")
 for _,k in {"VisualPass","DayNightReviewed","NightHospitalityPass","GlareAndSpillReviewed","RegressionsPass","ActualWalkingPass","NativeSeatPass","StaffGesturePass","RollbackPass","SourceMatch","RenderingReviewed","PreservationGuardPass","LightingOwnershipQualified"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l.Waiting_Porch_Light:SetAttribute("AssetStatus","MODELER_READY")
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01NStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

