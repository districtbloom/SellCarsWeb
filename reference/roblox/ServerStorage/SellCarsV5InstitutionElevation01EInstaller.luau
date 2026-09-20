--!nocheck
-- ELEV01E: stowed packaging-return stand beside the existing Parts receiving crate.
local I={Version="2026-09-07.elevation01e.3"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","05_Parts_Packaging_Return"
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


local C={frame=Color3.fromRGB(74,81,76),steel=Color3.fromRGB(154,156,143),tray=Color3.fromRGB(94,106,99),strap=Color3.fromRGB(190,144,72),pad=Color3.fromRGB(114,132,139),edge=Color3.fromRGB(92,108,114),paper=Color3.fromRGB(147,112,71)}
local function part(m,n,p,s,c,mat,solid)
 local v=Instance.new("Part");v.Name=n;v.Size=s;v.CFrame=CFrame.new(p);v.Anchored=true
 v.Material=mat or Enum.Material.Metal;v.Color=c;v.CanCollide=solid==true;v.CanQuery=true;v.CanTouch=false;v.CastShadow=true
 v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v:SetAttribute("Elevation01EOwned",true);v.Parent=m;return v
end
local function build(l)
 local m=Instance.new("Model");m.Name="Packaging_Return_Stand"
 for k,v in {BundleId="Institution.Elevation01E.PackagingReturn",FunctionId="Parts_Logistics",ZoneId="PartsCoveredApron",FidelityRole="SUPPORT",PhaseMin="DEDICATED",Ancestor="Folded packing blankets and reusable straps beside the first delivery crate",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="FURNITURE",InteractionAnchor="PackagingApproach",FXSocket="",SourceOwned=true,SourceGeometry="PARAMETRIC_PROXY",Purpose="STOWED_REUSABLE_PACKAGING_NOT_EXTRA_STOCK",PhysicalFloorTop=.5}do m:SetAttribute(k,v)end
 m.Parent=l
 for _,z in {413.85,416.15}do
  part(m,"AnchoredSledFoot",Vector3.new(3016,.58,z),Vector3.new(3.8,.16,.34),C.frame,nil,true)
  part(m,"BackUpright",Vector3.new(3014.3,2.21,z),Vector3.new(.22,3.1,.22),C.frame,nil,true)
  part(m,"LowerTrayBearing",Vector3.new(3016,.905,z),Vector3.new(3.45,.49,.22),C.frame,nil,true)
 end
 part(m,"StrapHangingRail",Vector3.new(3014.3,3.55,415),Vector3.new(.24,.24,2.4),C.steel,nil,true)
 part(m,"OpenPackingTray",Vector3.new(3016,1.21,415),Vector3.new(3.45,.12,2.16),C.tray,nil,true)
 part(m,"TrayBackFold",Vector3.new(3014.32,1.49,415),Vector3.new(.12,.44,2.16),C.tray,nil,true)
 for _,z in {413.96,416.04}do part(m,"TraySideFold",Vector3.new(3016,1.49,z),Vector3.new(3.45,.44,.10),C.tray,nil,true)end
 -- Reusable textile pads occupy one half of the open tray; no generic carton pile.
 for i=0,1 do
  local pad=part(m,"FoldedPackingBlanket_"..i,Vector3.new(3016.45+i*.09,1.395+i*.25,414.56+i*.06),Vector3.new(1.75,.25,.95),i==1 and C.edge or C.pad,Enum.Material.Fabric,false)
  pad:SetAttribute("FinalAssetIntent","FOLDED_QUILTED_MOVING_BLANKET")
 end
 -- Flat webbing droops into a low V; a loose tail distinguishes it from rigid handles.
 local function strap(n,a,b)
  local d=b-a;local v=part(m,n,(a+b)/2,Vector3.new(.075,d.Magnitude,.10),C.strap,Enum.Material.Fabric,false)
  local up=d.Unit;local right=Vector3.xAxis;v.CFrame=CFrame.fromMatrix((a+b)/2,right,up,right:Cross(up));return v
 end
 for i,z in {414.35,415.55}do
  part(m,"RetainingHookTop_"..i,Vector3.new(3014.53,3.51,z),Vector3.new(.47,.10,.12),C.steel,nil,false)
  part(m,"RetainingHookDrop_"..i,Vector3.new(3014.72,3.405,z),Vector3.new(.09,.20,.12),C.steel,nil,false)
  local x,top,low=3014.78,3.365,2.34+(i-1)*.16
  strap("WebbingLeft_"..i,Vector3.new(x,top,z-.09),Vector3.new(x,low+.14,z-.17))
  strap("WebbingRight_"..i,Vector3.new(x,top,z+.09),Vector3.new(x,low+.14,z+.17))
  strap("WebbingFoldLeft_"..i,Vector3.new(x,low+.14,z-.17),Vector3.new(x,low,z))
  strap("WebbingFoldRight_"..i,Vector3.new(x,low,z),Vector3.new(x,low+.14,z+.17))
  part(m,"WebbingRailFold_"..i,Vector3.new(x,top,z),Vector3.new(.075,.075,.27),C.strap,Enum.Material.Fabric,false)
  strap("WebbingLooseTail_"..i,Vector3.new(x+.03,top,z+.09),Vector3.new(x+.03,top-.42,z+.23))
 end
 -- Two L-section edge protectors nest on the other half, supported by the tray.
 for i=0,1 do
  local x=3015.35+i*.48
  part(m,"ReusableCornerFlange_"..i,Vector3.new(x,1.33,415.55),Vector3.new(.42,.12,.70),C.paper,Enum.Material.Wood,false)
  part(m,"ReusableCornerUpright_"..i,Vector3.new(x-.15,1.60,415.55),Vector3.new(.12,.42,.70),C.paper,Enum.Material.Wood,false)
 end
 local a=part(m,"PackagingApproach",Vector3.new(3020.5,.5,415),Vector3.new(.1,.1,.1),C.frame,nil,false)
 a.Transparency=1;a.CanQuery=false;a.CastShadow=false;a:SetAttribute("AnchorKind","OPERATOR");a:SetAttribute("Facing","WEST")
 local socket=Instance.new("Attachment");socket.Name="PackagingUse";socket.Parent=a
end
function I.Install()
 local r,p=root(),parent()
 assert(not layer(),"Owned E already exists; verify and explicitly Uninstall instead of overwrite")
 assert(r:GetAttribute("InstitutionElevation01DStatus")=="ACCEPTED_PROXY","Accepted D required")
 assert(geometryHash(r)=="7b3f594e" and #r:GetDescendants()==14043,"Unexpected predecessor geometry; preserve edits")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","7b3f594e");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01EStatus","BUILT_AWAITING_REVIEW")
 l:SetAttribute("ContentSignature",ownedSignature(l))
 return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=layer()
 assert(l,"E absent; nothing to uninstall")
 for _,v in p:GetChildren()do assert(v==l or v.Name=="01_Central_Craft_Pocket"or v.Name=="02_Garden_Promenade_Link"or v.Name=="03_Remaining_Garden_Walks"or v.Name=="04_Operations_Pause_Pocket","Later/unknown sibling; do not remove dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned E changed; preserve and investigate")
 assert(geometryHash(r,l)=="7b3f594e" and #r:GetDescendants()-#l:GetDescendants()-1==14043,"Predecessor changed; preserve E and investigate")
 assert(r:GetAttribute("InstitutionElevation01EStatus")==l:GetAttribute("Status"),"Owned root status changed; preserve")
 l:Destroy();r:SetAttribute("InstitutionElevation01EStatus",nil)
 assert(geometryHash(r)=="7b3f594e","Prior geometry differs; do not automatically restore it")
 return true
end

local PATHS={
 {name="PartsEntryAndReceiving",selfSweep=true,points={{3024,397},{3024,419},{3032,419},{3032,425}}},
 {name="PackagingApproach",points={{3024,412},{3020.5,412},{3020.5,415}}},
 {name="PartsRunner",selfSweep=true,points={{3032,425},{3032,442},{3046,442}}},
 {name="ReceivingVisitor",points={{3024,412},{3024,419},{3028.5,419},{3028.5,424}}},
 {name="StaffSpine",points={{3009,397},{3072,397}}},
}
I.AccessPaths=PATHS
function I.Audit()
 local r,l=root(),assert(layer())
 local a={parts=0,models=0,solids=0,seats=0,meshes=0,lights=0,scripts=0,issues={},metadataIssues={},externalPairs=0,protectedVolumes=0,routeVolumes=0,envelopeTests=0,routeTests=0,bodyPoses=0,actorSelfExclusions=0,floorRays=0,floors={},cornerChecks=0}
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
   if p.X<3013.5-.001 or p.X>3018.5+.001 or p.Z<413.5-.001 or p.Z>416.5+.001 or p.Y<.5-.001 or p.Y>4 then table.insert(a.issues,"OutsidePocket:"..v.p.Name)end
  end end end
  for _,g in other do if overlap(v.mn,v.mx,g.mn,g.mx)then a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..g.p:GetFullName())end end
 end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local function checkBody(name,x,z,dx,dz,anchor,selfSweep)
  local hit=workspace:Raycast(Vector3.new(x,1.05,z),Vector3.new(0,-2,0),rp);a.floorRays+=1
  if not hit then table.insert(a.issues,"MissingFloor:"..name);return end
  local feet=hit.Position.Y
  if feet<.09 or feet>.51 then table.insert(a.issues,"UnexpectedFloor:"..name..":"..feet)end
  a.floors[string.format("%.3f",feet)]=(a.floors[string.format("%.3f",feet)]or 0)+1
  local half=anchor and Vector3.new(1.5,2.9,1.5)or Vector3.new(math.abs(dz)*1.5+math.abs(dx)*.3,2.9,math.abs(dx)*1.5+math.abs(dz)*.3)
  local mid=Vector3.new(x,feet+3.5,z);a.bodyPoses+=1
  local runner=r["10_Institution_Fidelity_R1"]["06_Atmosphere"]["05_Occupation_Rear"].PartsRunner
  for _,g in all do if overlap(mid-half,mid+half,g.mn,g.mx)then
   if selfSweep and g.p:IsDescendantOf(runner)then a.actorSelfExclusions+=1
   else table.insert(a.issues,"BodyObstacle:"..name..":"..g.p:GetFullName())end
  end end
 end
 for _,path in PATHS do for i=2,#path.points do
  local a0,b0=path.points[i-1],path.points[i];local dx,dz=b0[1]-a0[1],b0[2]-a0[2];local len=math.sqrt(dx*dx+dz*dz);dx/=len;dz/=len
  local steps=math.ceil(len/.5);for s=0,steps do checkBody(path.name,a0[1]+dx*len*s/steps,a0[2]+dz*len*s/steps,dx,dz,false,path.selfSweep)end
 end end
 checkBody("PackagingStanding",3020.5,415,1,0,true);checkBody("ReceivingVisitorStanding",3028.5,424,0,1,true)
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then
  a.protectedVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end
 end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then
  a.routeVolumes+=1;local mn,mx=bounds(p)
  for _,v in own do a.routeTests+=1;if v.mn.X<mx.X-.0001 and v.mx.X>mn.X+.0001 and v.mn.Z<mx.Z-.0001 and v.mx.Z>mn.Z+.0001 then table.insert(a.issues,"VehicleRouteFootprint:"..p.Name)end end
 end end
 local m=l.Packaging_Return_Stand
 for _,p in m:GetChildren()do if p.Name=="LowerTrayBearing"then
  local _,mx=bounds(p);local mn=bounds(m.OpenPackingTray);if math.abs(mx.Y-mn.Y)>.001 then table.insert(a.issues,"TrayBearingContact")end
 end end
 local trayTop=m.OpenPackingTray.Position.Y+m.OpenPackingTray.Size.Y/2
 for i=0,1 do local b=m["FoldedPackingBlanket_"..i];local expected=trayTop+i*.25;if math.abs(b.Position.Y-b.Size.Y/2-expected)>.001 then table.insert(a.issues,"PaddingSupport:"..i)end end
 -- This explicit reservation is not a public yard furnishing zone.
 local freightMin,freightMax=Vector3.new(3030,.5,378),Vector3.new(3056,8,416)
 for _,v in own do if overlap(v.mn,v.mx,freightMin,freightMax)then table.insert(a.issues,"FreightReservation:"..v.p.Name)end end
 if a.models~=1 or a.seats~=0 or a.meshes+a.lights+a.scripts~=0 then table.insert(a.issues,"UnexpectedLayerInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature
 if not a.signatureMatch then table.insert(a.issues,"UnexpectedOwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"Audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","ReceivingAccessPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass"}do assert(e[k],"Missing evidence:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in l:GetChildren()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01EStatus","ACCEPTED_PROXY")
 l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

