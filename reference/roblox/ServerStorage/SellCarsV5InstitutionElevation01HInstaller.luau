--!nocheck
-- ELEV01H: fitted Intake waiting cushion and separately owned ground continuity.
local I={Version="2026-09-08.elevation01h.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","08_Intake_Waiting_Comfort"
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
local function intake()return root()["10_Institution_Fidelity_R1"]["04_Frontage_And_Owner"]["01_Intake"]end
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
 local function model(n,role,collision)
  local m=Instance.new("Model");m.Name=n
  for k,v in {BundleId="Institution.Elevation01H."..n,FunctionId="Intake_Appraisal",ZoneId="ExistingSellerPublicExchange",FidelityRole=role,PhaseMin="INSTITUTION",Ancestor="The retained timber waiting benches and public exchange walk",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=collision,InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",FinalDetailIntent="WEATHER_RESISTANT_FITTED_CUSHION_GROUNDED_ACCESS_NO_NEW_STATION"}do m:SetAttribute(k,v)end;m.Parent=l;return m
 end
 local ground=model("Owned_Ground_Continuity","ACCESS","SUPPORT")
 local comfort=model("Fitted_Waiting_Comfort","STORY","SEATING")
 local concrete=Color3.fromRGB(156,158,148)
 local function B(m,n,x,y,z,w,h,d,c,mat,cls,angle,solid)
  local p=Instance.new(cls or "Part");p.Name=n;p.Size=V(w,h,d);p.CFrame=CFrame.new(x,y,z)*CFrame.Angles(0,angle or 0,0);p.Color=c;p.Material=mat;p.Anchored=true;p.CanCollide=solid==true;p.CanTouch=p:IsA("Seat");p.CanQuery=true;p.CastShadow=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
 end
 local function slab(n,x,z,w,d,cls,angle)
  return B(ground,n,x,.4145,z,w,.591,d,concrete,Enum.Material.Concrete,cls,angle,true)
 end
 for _,s in {{"SouthWalkSupport",27.05,31.1},{"NorthWalkSupport",59.9,29.2}}do
  local p=slab(s[1],3082.5,s[2],4,s[3]);p.Transparency=1;p.CastShadow=false
 end
 slab("SouthEntryRamp",3082.5,10,4,3,"WedgePart",0)
 slab("NorthEntryRamp",3082.5,76,4,3,"WedgePart",math.pi)
 slab("SouthBenchAlcove",3086.4,35,3.8,6)
 slab("NorthBenchAlcove",3086.4,54,3.8,6)
 slab("SellerSoleApron",3084.75,40.45,.5,4.3)
 slab("AppraiserSoleApron",3084.75,47.65,.5,4.7)
 for i,z in {33.2,36.8,52.2,55.8}do
  B(ground,"BenchFootShoe_"..i,3086.6,.78,z,2.3,.14,.25,Color3.fromRGB(66,74,75),Enum.Material.Metal,nil,0,false)
 end
 local canvas=Color3.fromRGB(91,111,99);local binding=Color3.fromRGB(173,154,119)
 local seat=B(comfort,"WaitingCushion",3086.55,2.56,35,4.7,.22,2.3,canvas,Enum.Material.Fabric,"Seat",math.pi/2,true)
 seat.Disabled=false;seat:SetAttribute("ExistingBench","WaitingBenchSeat at Z35");seat:SetAttribute("Role","NATIVE_WAITING_SEAT")
 B(comfort,"FittedBackPad",3087.785,3.36,35,.18,1.24,4.7,canvas,Enum.Material.Fabric,nil,0,false)
 B(comfort,"SeatFrontBinding",3085.38,2.60,35,.04,.04,4.6,binding,Enum.Material.Fabric,nil,0,false)
 B(comfort,"BackUpperBinding",3087.675,3.96,35,.04,.035,4.6,binding,Enum.Material.Fabric,nil,0,false)
 B(comfort,"BackLowerBinding",3087.675,2.76,35,.04,.035,4.6,binding,Enum.Material.Fabric,nil,0,false)
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned H exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01GStatus")=="ACCEPTED_PROXY","Accepted G required")
 assert(geometryHash(r)=="876a5e4f" and #r:GetDescendants()==14172,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","876a5e4f");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01HStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"H absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true,["07_Owner_Craft_Vise"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned H changed; preserve")
 assert(geometryHash(r,l)=="876a5e4f" and #r:GetDescendants()-#l:GetDescendants()-1==14172,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01HStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01HStatus",nil);assert(geometryHash(r)=="876a5e4f","Unexpected rollback result");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local g,c=l.Owned_Ground_Continuity,l.Fitted_Waiting_Comfort
 local a={parts=0,solids=0,seats=0,models=0,scripts=0,meshes=0,lights=0,issues={},metadataIssues={},externalPairs=0,retainedFinishPairs=0,cornerChecks=0,contactChecks=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,accessPaths=0,bodyPoses=0,floorSamples=0}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"}do if p:GetAttribute(k)==nil then table.insert(a.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then a.parts+=1;if p.CanCollide then a.solids+=1 end;if p:IsA("Seat")then a.seats+=1 end;if not p.Anchored then table.insert(a.issues,"Unanchored:"..p.Name)end
  elseif p:IsA("DataModelMesh")then a.meshes+=1
  elseif p:IsA("Light")then a.lights+=1
  elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 local retained=intake().Seller_Public_Exchange.CustomerWalkInset
 for _,v in own do
  for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
   a.cornerChecks+=1;local p=v.p.CFrame:PointToWorldSpace(v.p.Size*V(sx,sy,sz)/2)
   if p.X<3080.499 or p.X>3088.301 or p.Z<8.499 or p.Z>77.501 or p.Y<.118 or p.Y>3.981 then table.insert(a.issues,"OutsideOwnedPocket:"..v.p.Name)end
  end end end
  for _,o in other do if overlap(v.mn,v.mx,o.mn,o.mx,.001)and xzOverlap(v.p,o.p)then
   if o.p==retained and(v.p==g.SouthWalkSupport or v.p==g.NorthWalkSupport)then a.retainedFinishPairs+=1
   else a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..o.p:GetFullName())end
  end end
 end
 local function near(n,x,y)a.contactChecks+=1;if math.abs(x-y)>.001 then table.insert(a.issues,"Contact:"..n..":"..x..":"..y)end end
 local walkmn,walkmx=bounds(retained)
 for _,n in {"SouthWalkSupport","NorthWalkSupport","SouthBenchAlcove","NorthBenchAlcove","SellerSoleApron","AppraiserSoleApron"}do local mn,mx=bounds(g[n]);near(n..":Finish",mx.Y,walkmx.Y);near(n..":Bottom",mn.Y,.119)end
 local bench,back,legs=nil,nil,{}
 for _,p in intake().Seller_Public_Exchange:GetChildren()do
  if p:IsA("BasePart")then
   if p.Name=="WaitingBenchSeat"and math.abs(p.Position.Z-35)<.1 then bench=p end
   if p.Name=="WaitingBenchBack"and math.abs(p.Position.Z-35)<.1 then back=p end
   if p.Name=="BenchLeg"then table.insert(legs,p)end
  end
 end
 assert(bench and back and #legs==4,"Retained bench changed")
 table.sort(legs,function(x,y)return x.Position.Z<y.Position.Z end)
 for i,p in legs do local mn=bounds(p);local smn,smx=bounds(g["BenchFootShoe_"..i]);near("LegFoot",smx.Y,mn.Y);near("FootGround",smn.Y,.71)end
 local smn=bounds(c.WaitingCushion);local _,bmx=bounds(bench);near("CushionTimber",smn.Y,bmx.Y)
 local pmn,pmx=bounds(c.FittedBackPad);local bmn=bounds(back);near("BackPadTimber",pmx.X,bmn.X)
 if c.WaitingCushion.CFrame.LookVector.X>-.999 or c.WaitingCushion.Disabled then table.insert(a.issues,"SeatFacingOrDisabled")end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)and xzOverlap(v.p,p)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;for _,v in own do a.routeTests+=1;if xzOverlap(v.p,p)then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 for _,path in intake()["98_Access_Paths"]:GetChildren()do
  a.accessPaths+=1;local pts=path:GetChildren();table.sort(pts,function(x,y)return x.Name<y.Name end)
  for i=2,#pts do local p,q=pts[i-1].Value,pts[i].Value;local steps=math.ceil((q-p).Magnitude/.5)
   for j=0,steps do local center=p:Lerp(q,j/steps);a.bodyPoses+=1;local mn,mx=center-V(1.5,2.75,1.5),center+V(1.5,2.75,1.5)
    for _,v in own do if overlap(v.mn,v.mx,mn,mx,.001)then table.insert(a.issues,"IntakeAccess:"..path.Name..":"..v.p.Name)end end
   end
  end
 end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={r};ray.RespectCanCollide=true
 for _,t in {{3082.5,12,.71},{3082.5,30,.71},{3082.5,41,.71},{3082.5,46,.71},{3082.5,60,.71},{3082.5,74,.71},{3085,35,.71},{3085,54,.71},{3084.7,40.5,.71},{3084.7,48,.71},{3082.5,9,.2175},{3082.5,10,.4145},{3082.5,11,.6115},{3082.5,75,.6115},{3082.5,76,.4145},{3082.5,77,.2175}}do
  a.floorSamples+=1;local hit=workspace:Raycast(V(t[1],1.05,t[2]),V(0,-2,0),ray)
  if not hit or math.abs(hit.Position.Y-t[3])>.002 then table.insert(a.issues,"Floor:"..t[1]..":"..t[2]..":"..tostring(hit and hit.Position.Y))end
 end
 if a.parts~=17 or a.models~=2 or a.solids~=9 or a.seats~=1 or a.scripts+a.meshes+a.lights~=0 or a.retainedFinishPairs~=2 then table.insert(a.issues,"UnexpectedInventoryOrRetainedPairs")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"H audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","NativeSeatPass","SideStepsPass","StaffGesturePass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 for _,m in {l.Owned_Ground_Continuity,l.Fitted_Waiting_Comfort}do m:SetAttribute("AssetStatus","MODELER_READY")end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01HStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

