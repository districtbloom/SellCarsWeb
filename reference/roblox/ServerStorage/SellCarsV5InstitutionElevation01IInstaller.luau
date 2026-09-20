--!nocheck
-- ELEV01I: fitted Sales desk fronts and lined handover tray; no new station.
local I={Version="2026-09-08.elevation01i.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","09_Sales_Desk_Joinery"
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
local function sales()return root()["10_Institution_Fidelity_R1"]["04_Frontage_And_Owner"]["02_Sales"]end
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
 local function group(n)
  local m=Instance.new("Model");m.Name=n
  for k,v in {BundleId="Institution.Elevation01I."..n,FunctionId="Sales_Delivery",ZoneId="ExistingDealDesk",FidelityRole="STORY",PhaseMin="INSTITUTION",Ancestor="The first yard sales desk and key envelope",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="STOWED_DETAIL",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="FITTED_TIMBER_CABINET_FRONT_LINED_KEY_TRAY_NO_NEW_FURNITURE"}do m:SetAttribute(k,v)end;m.Parent=l;return m
 end
 local joinery,tray=group("Fitted_Pedestal_Fronts"),group("Lined_Handover_Tray")
 local bronze,wood,lining=Color3.fromRGB(145,103,58),Color3.fromRGB(150,107,66),Color3.fromRGB(40,59,68)
 local function B(m,n,x,y,z,w,h,d,col,mat)
  local p=Instance.new("Part");p.Name=n;p.Size=V(w,h,d);p.CFrame=CFrame.new(x,y,z);p.Color=col;p.Material=mat;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
 end
 for i,x in {3158,3166}do
  B(joinery,"TimberField_"..i,x,1.95,73.58,1.47,2.16,.04,wood,Enum.Material.Wood)
  for j,dx in {-.8,.8}do B(joinery,"FrameStile_"..i.."_"..j,x+dx,1.95,73.555,.13,2.42,.09,bronze,Enum.Material.Metal)end
  for j,y in {.805,3.095}do B(joinery,"FrameRail_"..i.."_"..j,x,y,73.555,1.47,.13,.09,bronze,Enum.Material.Metal)end
 end
 B(tray,"DeskContactPad",3157.7,3.630,74.8,1.8,.010,1.5,lining,Enum.Material.Fabric)
 B(tray,"FittedLining",3157.7,3.815,74.8,1.68,.020,1.38,lining,Enum.Material.Fabric)
 for i,z in {74.08,75.52}do B(tray,"TrayEndRim_"..i,3157.7,3.86,z,1.8,.11,.06,bronze,Enum.Material.Metal)end
 for i,x in {3156.83,3158.57}do B(tray,"TraySideRim_"..i,x,3.86,74.8,.06,.11,1.38,bronze,Enum.Material.Metal)end
 for i,x in {3157.4,3158.05}do for j,dx in {-.215,.215}do
  local a,b=V(x+dx,3.86,74.40),V(x,3.86,74.70)
  local p=B(tray,"EnvelopeFold_"..i.."_"..j,0,0,0,(b-a).Magnitude,.010,.018,Color3.fromRGB(153,161,153),Enum.Material.SmoothPlastic)
  p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0)
 end end
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned I exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01HStatus")=="ACCEPTED_PROXY","Accepted H required")
 assert(geometryHash(r)=="379d7985" and #r:GetDescendants()==14193,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","379d7985");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01IStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"I absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true,["08_Intake_Waiting_Comfort"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned I changed; preserve")
 assert(geometryHash(r,l)=="379d7985" and #r:GetDescendants()-#l:GetDescendants()-1==14193,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01IStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01IStatus",nil);assert(geometryHash(r)=="379d7985","Unexpected rollback result");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local desk=sales().Deal_And_Listing_Exchange
 local a={parts=0,solids=0,models=0,scripts=0,meshes=0,lights=0,issues={},metadataIssues={},externalPairs=0,cornerChecks=0,contactChecks=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,accessPaths=0,bodyPoses=0,standingVolumes=0,floorSamples=0,inheritedFloorMismatches={}}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if p:GetAttribute(k)==nil then table.insert(a.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then a.parts+=1;if p.CanCollide then a.solids+=1 end;if not p.Anchored then table.insert(a.issues,"Unanchored:"..p.Name)end
  elseif p:IsA("DataModelMesh")then a.meshes+=1
  elseif p:IsA("Light")then a.lights+=1
  elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   a.cornerChecks+=1;local p=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2)
   if p.X<3156.799 or p.X>3166.866 or p.Z<73.509 or p.Z>75.551 or p.Y<.739 or p.Y>3.916 then table.insert(a.issues,"OutsideDeskPocket:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)and xzOverlap(v.p,o.p)then a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
 end
 local function near(n,x,y)a.contactChecks+=1;if math.abs(x-y)>.001 then table.insert(a.issues,"Contact:"..n..":"..x..":"..y)end end
 local fronts=l.Fitted_Pedestal_Fronts;local tray=l.Lined_Handover_Tray
 local pedestals,envelopes={},{}
 for _,p in desk:GetChildren()do if p:IsA("BasePart")then if p.Name=="DealDeskPedestal"then table.insert(pedestals,p)elseif p.Name=="KeyEnvelope"then table.insert(envelopes,p)end end end
 table.sort(pedestals,function(a,b)return a.Position.X<b.Position.X end);table.sort(envelopes,function(a,b)return a.Position.X<b.Position.X end)
 assert(#pedestals==2 and #envelopes==2,"Original furniture changed")
 for i,p in pedestals do local mn=bounds(p)
  for _,n in {"TimberField_"..i,"FrameStile_"..i.."_1","FrameStile_"..i.."_2","FrameRail_"..i.."_1","FrameRail_"..i.."_2"}do local _,mx=bounds(fronts[n]);near(n.."Back",mx.Z,mn.Z)end
 end
 local padmn,padmx=bounds(tray.DeskContactPad);local _,top=bounds(desk.DealDeskTop);local traymn,traymx=bounds(desk.KeyPresentationTray)
 local linmn,linmx=bounds(tray.FittedLining);near("PadDesk",padmn.Y,top.Y);near("PadTray",padmx.Y,traymn.Y);near("LiningTray",linmn.Y,traymx.Y)
 for i,p in envelopes do local mn,mx=bounds(p);near("LiningEnvelope_"..i,linmx.Y,mn.Y)
  for j=1,2 do local fmn=bounds(tray["EnvelopeFold_"..i.."_"..j]);near("EnvelopeFold_"..i.."_"..j,fmn.Y,mx.Y)end
 end
 for _,n in {"TrayEndRim_1","TrayEndRim_2","TraySideRim_1","TraySideRim_2"}do local mn=bounds(tray[n]);near(n.."Base",mn.Y,traymx.Y)end
 local function volume(name,cf,sz)
  local half=sz/2
  for _,v in own do
   -- All body reservations here are axis-aligned; use their fixed centres.
   if overlap(v.mn,v.mx,cf.Position-half,cf.Position+half,.001)then table.insert(a.issues,name..":"..v.p.Name)end
  end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)and xzOverlap(v.p,p)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;for _,v in own do a.routeTests+=1;if xzOverlap(v.p,p)then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 volume("WashBay2Launch",CFrame.new(3105,3.2,97),V(10.58,6.4,40.94))
 for _,p in {{3104,30},{3156,30},{3104,56},{3156,56},{3144,84},{3116,84}}do volume("SalesGroundRevealStaging",CFrame.new(p[1],4.1,p[2]),V(10.58,6.4,18.94))end
 for _,z in {30,56}do volume("ElevatedSales",CFrame.new(3130,12.5,z),V(10.9,3.6,17.9))end
 for _,m in sales():GetDescendants()do if m:IsA("Model")then local n=m:GetAttribute("InteractionAnchor");if n and n~=""then local anchor=m:FindFirstChild(n,true);if anchor and anchor:IsA("BasePart")then a.standingVolumes+=1;volume("Standing:"..n,CFrame.new(anchor.Position.X,3.5,anchor.Position.Z),V(3,5.5,3))end end end end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,path in sales()["98_Access_Paths"]:GetChildren()do
  a.accessPaths+=1;local pts=path:GetChildren();table.sort(pts,function(a,b)return a.Name<b.Name end)
  for i=2,#pts do local p,q=pts[i-1].Value,pts[i].Value;local steps=math.ceil((q-p).Magnitude/.5)
   for j=0,steps do local c=p:Lerp(q,j/steps);a.bodyPoses+=1;volume("SalesAccess:"..path.Name,CFrame.new(c),V(3,5.5,3))
    a.floorSamples+=1;local hit=workspace:Raycast(V(c.X,1.1,c.Z),V(0,-3,0),ray);if not hit then table.insert(a.issues,"MissingPhysicalFloor:"..path.Name)end
   end
  end
 end
 for _,xz in {{3154,70},{3154,79},{3160,79},{3144,70}}do
  local hit=workspace:Raycast(V(xz[1],1.1,xz[2]),V(0,-3,0),ray)
  if hit then local _,top=bounds(sales().Sales_Floor_And_Customer_Approaches.ShowroomPaving);if top.Y-hit.Position.Y>.1 then table.insert(a.inheritedFloorMismatches,{x=xz[1],z=xz[2],visibleTop=top.Y,physicalTop=hit.Position.Y})end end
 end
 if a.parts~=20 or a.models~=2 or a.solids+a.scripts+a.meshes+a.lights~=0 then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"I audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","StaffGesturePass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass","InheritedFloorFindingRecorded"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in {l.Fitted_Pedestal_Fronts,l.Lined_Handover_Tray}do m:SetAttribute("AssetStatus","MODELER_READY")end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01IStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

