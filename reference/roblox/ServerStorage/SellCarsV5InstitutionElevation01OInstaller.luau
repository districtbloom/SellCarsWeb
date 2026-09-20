--!nocheck
-- ELEV01O: one shallow exterior coachbuilder styling study; existing Owner/F interiors and lighting unchanged.
local I={Version="2026-09-08.elevation01o.2"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","15_Owner_Styling_Study"
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
local function supportWall()
 for _,p in root()["10_Institution_Fidelity_R1"]["04_Frontage_And_Owner"]["03_Owner"].Personal_Workshop_Shell:GetChildren()do
  if p.Name=="RearCleanPanel"and math.abs(p.Position.X-3198)<.001 then return p end
 end;error("Exact retained wall absent")
end
local function B(m,n,x,y,z,w,h,d,col,mat)
 local p=Instance.new("Part");p.Name=n;p.CFrame=CFrame.new(x,y,z);p.Size=V(w,h,d);p.Material=mat or Enum.Material.SmoothPlastic;p.Color=col
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local PAPER=Color3.fromRGB(211,204,177)
local INK=Color3.fromRGB(40,58,64)
local BRASS=Color3.fromRGB(142,110,62)
local function build(l)
 local m=Instance.new("Model");m.Name="Coachbuilder_Profile_Study"
 for k,v in {BundleId="Institution.Elevation01O.OwnerStylingStudy",FunctionId="Owner_Garage",ZoneId="OwnerPhotoExterior",FidelityRole="STORY",PhaseMin="INSTITUTION",Ancestor="Personal build folio -> retained exterior coachbuilder styling study",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="SHALLOW_WALL_ART",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_FLAT_RELIEF_PROXY",FinalDetailIntent="LONG_HOOD_FASTBACK_SIDE_PROFILE_AND_WHEELBASE_STUDY_NO_GAMEPLAY_BINDING",AllowedMin=V(3198,5.4,100.5),AllowedMax=V(3211,9.6,100.75),MountPath=supportWall():GetFullName(),CompositionRule="ONE_COURTYARD_STUDY_NOT_INDOOR_HISTORY_DUPLICATION"}do m:SetAttribute(k,v)end;m.Parent=l
 local steel=Color3.fromRGB(47,51,48)
 for _,y in {5.95,9.05}do B(m,"WallStandOffRail_"..y,3204.5,y,100.545,12,.16,.09,steel,Enum.Material.Metal)end
 B(m,"DrawingPanel",3204.5,7.5,100.59,12.72,3.92,.10,PAPER)
 B(m,"FrameLeft",3198.07,7.5,100.65,.14,4.2,.20,steel,Enum.Material.Metal)
 B(m,"FrameRight",3210.93,7.5,100.65,.14,4.2,.20,steel,Enum.Material.Metal)
 B(m,"FrameTop",3204.5,9.53,100.65,12.72,.14,.20,steel,Enum.Material.Metal)
 B(m,"FrameBottom",3204.5,5.47,100.65,12.72,.14,.20,steel,Enum.Material.Metal)
 local index=0
 local function line(n,a,b,color,width)
  index+=1;local delta=b-a;local p=B(m,n.."_"..index,3204.5+(a.X+b.X)/2,7.5+(a.Y+b.Y)/2,100.655,delta.Magnitude,width or .055,.03,color or INK)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,0,math.atan2(delta.Y,delta.X));return p
 end
 local function poly(n,pts,color,width)for i=2,#pts do line(n,Vector2.new(pts[i-1][1],pts[i-1][2]),Vector2.new(pts[i][1],pts[i][2]),color,width)end end
 poly("Silhouette",{{-4.9,-.62},{-4.9,-.02},{-4.65,.17},{-2.2,.34},{-1.15,1.10},{.90,1.13},{2.20,.38},{4.32,.20},{4.7,-.02},{4.75,-.62},{3.9,-.62}},INK,.075)
 poly("RearArch",{{3.9,-.62},{3.84,-.28},{3.56,.12},{2.76,.12},{2.45,-.28},{2.38,-.62},{-2.43,-.62},{-2.48,-.28},{-2.80,.12},{-3.63,.12},{-3.95,-.28},{-4,-.62},{-4.9,-.62}},INK,.06)
 poly("GlassStudy",{{-1.95,.38},{-1.04,.93},{.78,.95},{1.87,.39},{-1.95,.38}},INK,.045)
 line("B_Pillar",Vector2.new(.25,.95),Vector2.new(.42,.39),INK,.055)
 line("DoorCut",Vector2.new(.55,.26),Vector2.new(.63,-.47),INK,.04)
 line("ShoulderLine",Vector2.new(-4.48,.02),Vector2.new(4.26,.02),BRASS,.035)
 line("DoorHandle",Vector2.new(.15,.15),Vector2.new(.45,.15),INK,.045)
 local function disc(n,x,y,diam,z,col)
  local thick=n:match("^Tyre")and .052 or .020
  local centerZ=z+.009-thick/2 -- preserve visible front; rear bears on panel/prior disc
  local p=B(m,n,3204.5+x,7.5+y,centerZ,thick,diam,diam,col)
  p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,math.pi/2,0);return p
 end
 for i,x in {-3.2,3.15}do
  disc("TyreOutline_"..i,x,-.67,1.34,100.683,INK)
  disc("RimPaper_"..i,x,-.67,1.02,100.703,PAPER)
  disc("Hub_"..i,x,-.67,.20,100.723,BRASS)
  for j=0,4 do local a=2*math.pi*j/5
   local p=line("RimSpoke",Vector2.new(x+math.cos(a)*.13,-.67+math.sin(a)*.13),Vector2.new(x+math.cos(a+.12)*.45,-.67+math.sin(a+.12)*.45),BRASS,.045);p.CFrame+=V(0,0,.068)
  end
 end
 line("WheelbaseRule",Vector2.new(-3.2,-1.65),Vector2.new(3.15,-1.65),BRASS,.032)
 for _,x in {-3.2,3.15}do
  line("WheelbaseDatum",Vector2.new(x,-1.43),Vector2.new(x,-1.8),BRASS,.032)
  line("DimensionTick",Vector2.new(x-.1,-1.55),Vector2.new(x+.1,-1.75),INK,.035)
 end
 line("Headlamp",Vector2.new(-4.86,-.12),Vector2.new(-4.35,-.12),INK,.10)
 line("RearLamp",Vector2.new(4.25,-.10),Vector2.new(4.65,-.10),BRASS,.10)
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned O exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01NStatus")=="ACCEPTED_PROXY","Accepted N required")
 assert(geometryHash(r)=="0edccbe2" and #r:GetDescendants()==14320,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","0edccbe2");l:SetAttribute("PriorLightSignature",priorLightSignature());l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01OStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"O absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true,["09_Sales_Desk_Joinery"]=true,["10_Tune_Equipment_Backdrop"]=true,["11_Mechanical_Roof_Connections"]=true,["13_Bed3_Desert_Silhouette"]=true,["14_Intake_Waiting_Light"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned O changed; preserve")
 assert(geometryHash(r,l)=="0edccbe2" and #r:GetDescendants()-#l:GetDescendants()-1==14320,"Predecessor changed; preserve")
 assert(priorLightSignature(l)==l:GetAttribute("PriorLightSignature"),"Prior lights changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01OStatus")==l:GetAttribute("Status"),"Root ownership changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01OStatus",nil);assert(geometryHash(r)=="0edccbe2");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local m=l.Coachbuilder_Profile_Study
 local a={parts=0,models=0,solids=0,lights=0,meshes=0,scripts=0,shadowParts=0,issues={},metadataIssues={},cornerChecks=0,externalPairs=0,contactChecks=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,bodyPoses=0,floorSamples=0}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry","AllowedMin","AllowedMax","MountPath","CompositionRule"}do if p:GetAttribute(k)==nil then table.insert(a.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then a.parts+=1;if p.CanCollide then a.solids+=1 end;if p.CastShadow then a.shadowParts+=1 end;if not p.Anchored or p.CanTouch or not p.CanQuery or p.Transparency~=0 then table.insert(a.issues,"Behavior:"..p.Name)end
  elseif p:IsA("Light")then a.lights+=1 elseif p:IsA("DataModelMesh")then a.meshes+=1 elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 local lo,hi=m:GetAttribute("AllowedMin"),m:GetAttribute("AllowedMax")
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   local q=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2);a.cornerChecks+=1
   if q.X<lo.X-.001 or q.X>hi.X+.001 or q.Y<lo.Y-.001 or q.Y>hi.Y+.001 or q.Z<lo.Z-.001 or q.Z>hi.Z+.001 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
 end
 local function volume(n,c,s)
  local mn,mx=c-s/2,c+s/2
  for _,v in own do if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,n..":"..v.p.Name)end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.001 and v.mx.X>mn.X+.001 and v.mn.Z<mx.Z-.001 and v.mx.Z>mn.Z+.001 then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 local paths=require(game.ServerStorage.SellCarsV5InstitutionElevation01FInstaller).AccessPaths
 for _,path in paths do for i=2,#path.points do
  local p,q=path.points[i-1],path.points[i];local len=Vector2.new(p[1]-q[1],p[2]-q[2]).Magnitude;local steps=math.ceil(len/.5)
  for j=0,steps do local t=j/steps;a.bodyPoses+=1;volume("FPath:"..path.name,V(p[1]+(q[1]-p[1])*t,3.6,p[2]+(q[2]-p[2])*t),V(3,5.5,3))end
 end end
 for _,q in {{3204.5,108.5},{3204.5,105.28},{3204.5,102.5},{3212,103},{3220,101.8},{3229,150}}do a.bodyPoses+=1;volume("ObserverAndSeat",V(q[1],5.4,q[2]),V(3,10.6,3))end
 for _,q in {{3203,28},{3233,28},{3203,56},{3233,56},{3203,84},{3233,84}}do volume("OwnerCar",V(q[1],3.6,q[2]),V(13.3001,6.4,19.94))end
 volume("OwnerDrive",V(3218,3.6,54),V(13.3001,6.4,90));volume("OwnerDoor",V(3220,7,100),V(13,13,1))
 local wall=supportWall();local wm,wx=bounds(wall);a.mount=wall:GetFullName();a.wallFace=wx.Z
 assert(m:GetAttribute("MountPath")==wall:GetFullName(),"Mountpath mismatch")
 for _,p in m:GetChildren()do if p.Name:match("^WallStandOffRail")then local mn,mx=bounds(p);a.contactChecks+=1
  if math.abs(mn.Z-wx.Z)>.001 or mn.X<wm.X or mx.X>wx.X or mn.Y<wm.Y or mx.Y>wx.Y then table.insert(a.issues,"UnsupportedMountRail")end
 end end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,q in {{3204.5,108.5,.095},{3220,101.8,.095},{3220,111,.095},{3229,145,.095},{3229,154,.7},{3229,175,.7}}do a.floorSamples+=1;local h=workspace:Raycast(V(q[1],1.1,q[2]),V(0,-2,0),ray);if not h or math.abs(h.Position.Y-q[3])>.003 then table.insert(a.issues,"PhysicalFloor:"..q[1]..":"..q[2])end end
 a.priorLightsUnchanged=priorLightSignature(l)==l:GetAttribute("PriorLightSignature");if not a.priorLightsUnchanged then table.insert(a.issues,"PriorLightDrift")end
 if a.models~=1 or a.parts~=60 or a.solids+a.shadowParts+a.meshes+a.scripts+a.lights~=0 then table.insert(a.issues,"UnexpectedInventory:"..a.parts)end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"O audit failed")
 for _,k in {"VisualPass","RecognizableProfilePass","DayNightReviewed","RegressionsPass","ActualWalkingPass","NativeSeatPass","PhotoConnectionPass","RollbackPass","SourceMatch","RenderingReviewed","PreservationGuardPass"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted");local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l.Coachbuilder_Profile_Study:SetAttribute("AssetStatus","MODELER_READY");l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01OStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

