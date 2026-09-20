--!nocheck
-- ELEV01G: a hand-fitted alloy bracket and file on the retained Owner craft bench.
local I={Version="2026-09-07.elevation01g.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","07_Owner_Craft_Vise"
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
local CF=CFrame.new(3185.4,0,58)*CFrame.Angles(0,-math.pi/2,0)
local function owner()return root()["10_Institution_Fidelity_R1"]["04_Frontage_And_Owner"]["03_Owner"]end
local function build(l)
 local m=Instance.new("Model");m.Name="Hand_Fitted_Alloy_Bracket"
 for k,v in {BundleId="Institution.Elevation01G.HandFittedAlloyBracket",FunctionId="Owner_Garage",ZoneId="ExistingOwnerCraftBench",FidelityRole="STORY",PhaseMin="DEDICATED",Ancestor="A rough hand-cut bracket and file beside the first personal car",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="STOWED_DETAIL",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",ExistingUseAnchor="04_Frontage_And_Owner/03_Owner/Owner_Craft_Bench/OwnerCraftOperator",WorkState="CLAMPED_PERSONAL_COMPONENT_HAND_FITTING",FinalDetailIntent="SOFT_JAWS_TRUE_SLOT_AND_MATTE_FILE_NO_NEW_GAMEPLAY"}do m:SetAttribute(k,v)end;m.Parent=l
 local function B(n,x,y,z,w,h,d,c,mat)
  local p=Instance.new("Part");p.Name=n;p.Size=V(w,h,d);p.CFrame=CF*CFrame.new(x,y,z);p.Color=c;p.Material=mat;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
 end
 local wood,alloy,steel=Color3.fromRGB(170,119,70),Color3.fromRGB(185,192,190),Color3.fromRGB(72,79,80)
 B("FixedSoftJaw",-3.2,4.6,-.7575,1.35,.50,.215,wood,Enum.Material.Wood)
 B("SlidingSoftJaw",-3.2,4.6,-1.1925,1.35,.50,.215,wood,Enum.Material.Wood)
 -- Web bounds X[-3.775,-2.625],Y[4.32,5.40]; real .60 x .20 through slot at Y5.02..5.22.
 B("WebBelowSlot",-3.2,4.67,-.975,1.15,.70,.22,alloy,Enum.Material.Metal)
 B("WebAboveSlot",-3.2,5.31,-.975,1.15,.18,.22,alloy,Enum.Material.Metal)
 B("WebLeftLigament",-3.6375,5.12,-.975,.275,.20,.22,alloy,Enum.Material.Metal)
 B("WebRightLigament",-2.7625,5.12,-.975,.275,.20,.22,alloy,Enum.Material.Metal)
 B("FoldedMountingFlange",-3.2,5.32,-.5575,1.15,.16,.615,alloy,Enum.Material.Metal)
 B("HandFileBlade",-.7,3.66,-.025,.18,.07,1.75,steel,Enum.Material.Metal)
 B("HandFileTimberHandle",-.7,3.705,-1.225,.28,.16,.65,wood,Enum.Material.Wood)
end
function I.Install()
 local r,p=root(),parent();assert(not layer(),"Owned G exists; no automatic overwrite")
 assert(r:GetAttribute("InstitutionElevation01FStatus")=="ACCEPTED_PROXY","Accepted F required")
 assert(geometryHash(r)=="d22f373c" and #r:GetDescendants()==14160,"Predecessor changed; preserve")
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorGeometry","d22f373c");l.Parent=p
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 r:SetAttribute("InstitutionElevation01GStatus","BUILT_AWAITING_REVIEW");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
function I.Uninstall()
 local r,p=root(),parent();local l=assert(layer(),"G absent")
 local predecessors={["01_Central_Craft_Pocket"]=true,["02_Garden_Promenade_Link"]=true,["03_Remaining_Garden_Walks"]=true,["04_Operations_Pause_Pocket"]=true,["05_Parts_Packaging_Return"]=true,["06_Owner_Build_Review"]=true}
 for _,v in p:GetChildren()do assert(v==l or predecessors[v.Name],"Later/unknown sibling; preserve dependency")end
 assert(l:GetAttribute("Version")==I.Version and l:GetAttribute("ContentSignature")==ownedSignature(l),"Owned G changed; preserve")
 assert(geometryHash(r,l)=="d22f373c" and #r:GetDescendants()-#l:GetDescendants()-1==14160,"Predecessor changed; preserve")
 assert(r:GetAttribute("InstitutionElevation01GStatus")==l:GetAttribute("Status"),"Root ownership state changed")
 l:Destroy();r:SetAttribute("InstitutionElevation01GStatus",nil);assert(geometryHash(r)=="d22f373c","Unexpected rollback result");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local m=l.Hand_Fitted_Alloy_Bracket
 local a={parts=0,solids=0,models=0,scripts=0,meshes=0,lights=0,issues={},metadataIssues={},externalPairs=0,cornerChecks=0,contactChecks=0,slotRays=0,protectedVolumes=0,envelopeTests=0,routeVolumes=0,routeTests=0,accessPaths=0,bodyPoses=0,floorSamples=0,inheritedFloorMismatches={}}
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
   if p.X<3184.55-.001 or p.X>3186.95+.001 or p.Z<54.125-.001 or p.Z>57.44+.001 or p.Y<3.625-.001 or p.Y>5.401 then table.insert(a.issues,"OutsideBenchPocket:"..v.p.Name)end
  end end end
  for _,g in other do if overlap(v.mn,v.mx,g.mn,g.mx,.001)then a.externalPairs+=1;table.insert(a.issues,"ExternalOverlap:"..v.p.Name..":"..g.p:GetFullName())end end
 end
 local bench=owner().Owner_Craft_Bench
 local function near(n,x,y)a.contactChecks+=1;if math.abs(x-y)>.001 then table.insert(a.issues,"Contact:"..n..":"..x..":"..y)end end
 local fjmin,fjmax=bounds(bench.ViseFixedJaw);local sjmin,sjmax=bounds(bench.ViseSlidingJaw)
 local flmin,flmax=bounds(m.FixedSoftJaw);local slmin,slmax=bounds(m.SlidingSoftJaw);local wmin,wmax=bounds(m.WebBelowSlot)
 near("FixedLinerToJaw",flmin.X,fjmax.X);near("FixedLinerToWeb",flmax.X,wmin.X)
 near("SlidingLinerToJaw",slmax.X,sjmin.X);near("SlidingLinerToWeb",slmin.X,wmax.X)
 local _,top=bounds(bench.ToolBenchTop)
 for _,n in {"HandFileBlade","HandFileTimberHandle"}do local mn=bounds(m[n]);near(n.."ToWorktop",mn.Y,top.Y)end
 local bmin,bmax=bounds(m.HandFileBlade);local hmin,hmax=bounds(m.HandFileTimberHandle);near("BladeToHandle",bmax.X,hmin.X)
 local fmin,fmax=bounds(m.FoldedMountingFlange);near("FlangeToWeb",fmax.X,wmin.X)
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={l};op.RespectCanCollide=false
 if #workspace:GetPartBoundsInBox(CF*CFrame.new(-3.2,5.12,-.975),V(.59,.19,.24),op)>0 then table.insert(a.issues,"SlotNotOpen")end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={l};ray.RespectCanCollide=false
 for _,x in {-3.42,-3.2,-2.98}do a.slotRays+=1;local from=CF:PointToWorldSpace(V(x,5.12,-1.15));local dir=CF:VectorToWorldSpace(V(0,0,.35));if workspace:Raycast(from,dir,ray)then table.insert(a.issues,"SlotRayBlocked")end end
 a.slotRays+=1;assert(workspace:Raycast(CF:PointToWorldSpace(V(-3.2,4.95,-1.15)),CF:VectorToWorldSpace(V(0,0,.35)),ray),"Web material control ray missed")
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.envelopeTests+=1;if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;local mn,mx=bounds(p);for _,v in own do a.routeTests+=1;if v.mn.X<mx.X and v.mx.X>mn.X and v.mn.Z<mx.Z and v.mx.Z>mn.Z then table.insert(a.issues,"RouteFootprint:"..p.Name)end end end end
 -- Existing Owner access lines remain immutable. This gate tests new detail against them, not a claim that inherited finish/physics agree.
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={r};rays.RespectCanCollide=true
 for _,path in owner()["98_Access_Paths"]:GetChildren()do
  a.accessPaths+=1;local pts=path:GetChildren();table.sort(pts,function(x,y)return x.Name<y.Name end)
  for i=2,#pts do local p,q=pts[i-1].Value,pts[i].Value;local steps=math.ceil((q-p).Magnitude/.5)
   for j=0,steps do local c=p:Lerp(q,j/steps);a.bodyPoses+=1
    local mn,mx=c-V(1.5,2.75,1.5),c+V(1.5,2.75,1.5)
    for _,v in own do if overlap(v.mn,v.mx,mn,mx)then table.insert(a.issues,"OwnerAccess:"..path.Name..":"..v.p.Name)end end
    a.floorSamples+=1;local hit=workspace:Raycast(V(c.X,1.1,c.Z),V(0,-3,0),rays);if not hit then table.insert(a.issues,"MissingPhysicalFloor:"..path.Name)end
   end
  end
 end
 for _,xz in {{3191.5,12},{3191.5,58},{3191.5,95},{3244.5,37}}do
  local physical=workspace:Raycast(V(xz[1],1.1,xz[2]),V(0,-3,0),rays)
  local band=nil
  for _,p in owner().Owner_Floor_And_Circulation:GetChildren()do if p:IsA("BasePart")and p.Name=="OuterWalkingBand"and math.abs(p.Position.X-xz[1])<.1 then band=p end end
  if band and physical then local _,top=bounds(band);if top.Y-physical.Position.Y>.1 then table.insert(a.inheritedFloorMismatches,{x=xz[1],z=xz[2],visibleTop=top.Y,physicalTop=physical.Position.Y,source=band:GetFullName()})end end
 end
 if a.parts~=9 or a.models~=1 or a.solids+a.scripts+a.meshes+a.lights~=0 then table.insert(a.issues,"UnexpectedInventory")end
 a.surfaceSignature=signature(l);a.ownedSignature=ownedSignature(l);a.signatureMatch=l:GetAttribute("ContentSignature")==a.ownedSignature;if not a.signatureMatch then table.insert(a.issues,"OwnedEdits")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"G audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","ManeuverPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed","PreservationGuardPass","InheritedFloorFindingRecorded"}do assert(e[k],"Missing:"..k)end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l.Hand_Fitted_Alloy_Bracket:SetAttribute("AssetStatus","MODELER_READY")
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01GStatus","ACCEPTED_PROXY");l:SetAttribute("ContentSignature",ownedSignature(l));return I.Audit()
end
return I

