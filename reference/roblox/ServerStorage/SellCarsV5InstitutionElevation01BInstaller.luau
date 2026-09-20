--!nocheck
-- ELEV01B: thin, owned pedestrian finishes. No original part, collider or source is changed.
local I = { Version = "2026-09-07.elevation01b.3" }
local ROOT, PHASE, NAME = "SellCars_Dealership_Growth_V5", "07_Elevation_01", "02_Garden_Promenade_Link"
local TOP, PHYSICS_TOP = .180, .095
local function root()
 assert(game.PlaceId == 125334614375606 and not game.RunService:IsRunning(), "Correct place / Edit only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function parent()
 return assert(root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE), "Accepted ELEV01A required")
end
local function layer() return parent():FindFirstChild(NAME) end
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
   table.insert(rows,v.Name.."|"..v.Parent.Name.."|"..table.concat(cf,",").."|"..tostring(v.Size).."|"..v.Material.Name.."|"..tostring(v.Color).."|"..tostring(v.Transparency).."|"..tostring(v.CanCollide)..tostring(v.CanTouch)..tostring(v.CanQuery)..tostring(v.CastShadow).."|"..v.Shape.Name)
  end
 end
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end;h=(h*33+10)%4294967296 end
 return string.format("%08x",h)
end
local function assembly(l,n,ancestor)
 local m=Instance.new("Model");m.Name=n
 for k,v in {BundleId="Institution.Elevation01B."..n,FunctionId="EstateLandscape",ZoneId="Desert_Bed_2",FidelityRole="ARCHITECTURE",PhaseMin="PROFESSIONAL",Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="DECORATIVE",InteractionAnchor="Existing central walk and ELEV01A BenchApproach",FXSocket="",SourceOwned=true,SurfaceOnly=true,SourceGeometry="PARAMETRIC_PROXY",PhysicalFloorTop=PHYSICS_TOP,VisiblePavingTop=TOP} do m:SetAttribute(k,v) end
 m.Parent=l;return m
end
local function slab(m,n,x,z,w,d,color,top,thickness,material)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true
 p.Size=Vector3.new(w,thickness,d);p.CFrame=CFrame.new(x,top-thickness/2,z)
 p.Color=color;p.Material=material or Enum.Material.Limestone
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p:SetAttribute("Elevation01BOwned",true);p:SetAttribute("SurfaceLayer",true);p.Parent=m;return p
end
local function build(l)
 local path=assembly(l,"Garden_Promenade","Compacted central walking reserve -> maintained limestone promenade in the same axis")
 -- Both bedding and paving are explicit finish layers above the retained gravel.
 slab(path,"JointBedding",3130,178.5,8,48,Color3.fromRGB(122,115,99),.160,.028,Enum.Material.Concrete)
 for row=0,11 do for col=0,1 do
  local shade=((row*3+col*2)%5)-2
  slab(path,string.format("Paving_%02d_%d",row+1,col+1),3128+col*4,156.5+row*4,3.94,3.94,Color3.fromRGB(166+shade,155+shade,133+shade),TOP,.04)
 end end
 local link=assembly(l,"Bench_Apron_Link","Isolated resting plank pad -> accessible garden rest pocket joined to the same pedestrian reserve")
 slab(link,"JointBedding",3125.3875,187,1.225,7.85,Color3.fromRGB(122,115,99),.160,.028,Enum.Material.Concrete)
 for row=0,3 do
  slab(link,string.format("LinkSlab_%02d",row+1),3125.3725,184.03+row*1.98,1.195,1.91,Color3.fromRGB(163,151,125),TOP,.04)
 end
end
function I.Uninstall()
 local p=parent();local l=p:FindFirstChild(NAME)
 if l then
  for _,v in p:GetChildren() do assert(v==l or v.Name=="01_Central_Craft_Pocket","Uninstall later elevation siblings first") end
  l:Destroy()
 end
 root():SetAttribute("InstitutionElevation01BStatus",nil)
 return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionElevation01AStatus")=="ACCEPTED_PROXY","Accepted ELEV01A dependency")
 I.Uninstall()
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW")
 l:SetAttribute("PredecessorGeometry","5bcb7e23");l.Parent=parent()
 local ok,err=pcall(build,l)
 if not ok then I.Uninstall();error(err) end
 root():SetAttribute("InstitutionElevation01BStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local r,l=root(),assert(layer())
 local a={parts=0,models=0,solids=0,meshes=0,lights=0,scripts=0,issues={},metadataIssues={},supportRays=0,visibleSurfaceSamples=0,bodyPoses=0,visibleCornerChecks=0,externalGeometryChecks=0,explicitSubstrateIntersections=0,internalLayerPairs=0}
 local all,owned,geometry={},{},{}
 -- Enumerate visible nonquery geometry too: surface finishes deliberately have CanQuery=false.
 for _,p in r:GetDescendants() do
  if p:IsA("BasePart") and (p.Transparency<.98 or p.CanCollide) then
   local mn,mx=bounds(p);local row={part=p,mn=mn,mx=mx};table.insert(all,row)
   if p:IsDescendantOf(l) then table.insert(owned,row) else table.insert(geometry,row) end
  end
 end
 local substrate={}
 for _,v in geometry do
  local p=v.part
  if p.Name=="ProductionGround" and p.Parent==r["01_Ground_And_Road"] then substrate[p]=true
  elseif p.Name=="ProductionFinish" and p.Parent.Name=="Exterior_Concrete_Districts" then substrate[p]=true
  elseif p.Name=="CompactedGravel" and p.Parent.Name=="Central_Gravel_Reservations" and math.abs(p.Position.Z-178.5)<.001 then substrate[p]=true end
 end
 local ids={}
 for _,v in l:GetDescendants() do
  if v:IsA("Model") then
   a.models+=1
   for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","SourceGeometry"} do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k) end end
   local id=v:GetAttribute("BundleId");if ids[id] then table.insert(a.metadataIssues,"Duplicate:"..id) end;ids[id]=true
  elseif v:IsA("BasePart") then
   a.parts+=1;if v.CanCollide then a.solids+=1 end
   if v.CanCollide or v.CanTouch or v.CanQuery or v.CastShadow then table.insert(a.issues,"Unexpected surface behavior:"..v.Name) end
   if v.Shape~=Enum.PartType.Block or v.Orientation.Magnitude>.001 then table.insert(a.issues,"Unapproved surface form:"..v.Name) end
  elseif v:IsA("DataModelMesh") then a.meshes+=1
  elseif v:IsA("Light") then a.lights+=1
  elseif v:IsA("LuaSourceContainer") then a.scripts+=1 end
 end
 for _,v in owned do
  if v.mn.Y<.131 or v.mx.Y>TOP+.0001 then table.insert(a.issues,"SurfaceHeight:"..v.part.Name) end
  for _,sx in {-1,1} do for _,sy in {-1,1} do for _,sz in {-1,1} do
   a.visibleCornerChecks+=1;local p=v.part.CFrame:PointToWorldSpace(v.part.Size*Vector3.new(sx,sy,sz)/2)
   local axis=p.X>=3126-.001 and p.X<=3134+.001 and p.Z>=154.5-.001 and p.Z<=202.5+.001
   local link=p.X>=3124.775-.001 and p.X<=3126+.001 and p.Z>=183.075-.001 and p.Z<=190.925+.001
   if not(axis or link) then table.insert(a.issues,"OutsideOwnedFootprint:"..v.part.Name) end
  end end end
  for _,g in geometry do
   if overlap(v.mn,v.mx,g.mn,g.mx) then
    a.externalGeometryChecks+=1
    if substrate[g.part] and g.mx.Y<TOP-.025 then a.explicitSubstrateIntersections+=1
    else table.insert(a.issues,"ExternalVisibleOverlap:"..v.part.Name..":"..g.part:GetFullName()) end
   end
  end
 end
 -- Internal bedding/paver overlap is deliberate; same-level coplanar or overlapping pavers are not.
 for i=1,#owned do for j=i+1,#owned do
  local v,w=owned[i],owned[j]
  if overlap(v.mn,v.mx,w.mn,w.mx) then
   a.internalLayerPairs+=1
   if (v.part.Name~="JointBedding" and w.part.Name~="JointBedding") or math.abs(v.mx.Y-w.mx.Y)<.015 then table.insert(a.issues,"InternalCoplanar:"..v.part.Name..":"..w.part.Name) end
  end
 end end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local function sample(x,z,expectFinish,bodySize)
  local p=Vector3.new(x,PHYSICS_TOP,z);local hit=workspace:Raycast(p+Vector3.new(0,.5,0),Vector3.new(0,-1,0),rp);a.supportRays+=1
  if not hit or math.abs(hit.Position.Y-PHYSICS_TOP)>.002 then table.insert(a.issues,"PhysicalFloor:"..x..","..z) end
  local visible=-math.huge;local bodyCentre=Vector3.new(x,3.55,z)
  local bodyMin=bodySize and bodyCentre-bodySize/2;local bodyMax=bodySize and bodyCentre+bodySize/2
  for _,g in all do
   if g.part.Transparency<.98 and x>=g.mn.X and x<=g.mx.X and z>=g.mn.Z and z<=g.mx.Z and g.mx.Y<.5 then visible=math.max(visible,g.mx.Y) end
   if bodySize and overlap(bodyMin,bodyMax,g.mn,g.mx) then table.insert(a.issues,"BodyObstacle:"..g.part:GetFullName()) end
  end
  if bodySize then a.bodyPoses+=1 end;a.visibleSurfaceSamples+=1
  if expectFinish and (visible<.159 or visible>TOP+.002) then table.insert(a.issues,"VisibleFinish:"..x..","..z..":"..visible) end
  if visible>-math.huge and visible-PHYSICS_TOP>.087 then table.insert(a.issues,"FinishSupportDelta:"..x..","..z) end
 end
 for z=154.5,202.5,.5 do for _,x in {3127,3130,3133} do sample(x,z,true,Vector3.new(3,5.8,.6)) end end
 for x=3124.9,3130,.5 do sample(x,187,true) end -- Finish coverage, not a claim that one can stand inside the bench.
 for x=3125.8,3130,.5 do sample(x,187,true,Vector3.new(.6,5.8,3)) end
 sample(3125.8,187,true,Vector3.new(3,5.8,3)) -- Full-size accepted standing anchor.
 sample(3130,154.25,false);sample(3130,202.75,false)
 -- Exact visible seam to existing bench slabs, independent of broad floor tolerance.
 local bench=parent()["01_Central_Craft_Pocket"].Timber_Craft_Bench
 local edge=-math.huge;local oldTop=0
 for _,p in bench:GetChildren() do if p.Name=="LimestonePavingSlab" then local _,mx=bounds(p);edge=math.max(edge,mx.X);oldTop=mx.Y end end
 a.benchEdge=edge;a.benchTop=oldTop;a.connectorGap=3124.775-edge;a.seamHeightDelta=TOP-oldTop
 if math.abs(a.seamHeightDelta)>.002 or a.connectorGap<.015 or a.connectorGap>.05 then table.insert(a.issues,"BenchSeam") end
 local southEdge,northEdge
 for _,g in geometry do if g.part.Name=="FlushStoneEdge" and g.part.Parent.Name=="Central_Gravel_Reservations" then
  if math.abs(g.part.Position.Z-154)<.001 then southEdge=g.mx.Z end
  if math.abs(g.part.Position.Z-203)<.001 then northEdge=g.mn.Z end
 end end
 assert(southEdge and northEdge,"Original threshold edges missing")
 a.endGravelThresholds={south=154.5-southEdge,north=northEdge-202.5}
 a.promenadePavers=0;a.linkPavers=0;a.beddingParts=0;a.paverCentreTests=0
 for _,v in owned do
  if v.part.Name:match("^Paving_") then a.promenadePavers+=1
  elseif v.part.Name:match("^LinkSlab_") then a.linkPavers+=1
  elseif v.part.Name=="JointBedding" then a.beddingParts+=1
  else table.insert(a.issues,"UnexpectedPart:"..v.part.Name) end
  if v.part.Name~="JointBedding" then
   a.paverCentreTests+=1
   if math.abs(v.mx.Y-TOP)>.002 then table.insert(a.issues,"PaverTop:"..v.part.Name) end
  end
 end
 if a.promenadePavers~=24 or a.linkPavers~=4 or a.beddingParts~=2 then table.insert(a.issues,"IncompletePavingInventory") end
 a.protectedEnvelopes=0;a.routes=0;a.envelopeGeometryTests=0;a.routeGeometryTests=0
 for _,p in r["03_Protected_Clearances"]:GetChildren() do if p:IsA("BasePart") then
  a.protectedEnvelopes+=1;local mn,mx=bounds(p)
  for _,v in owned do a.envelopeGeometryTests+=1;if overlap(v.mn,v.mx,mn,mx) then table.insert(a.issues,"ProtectedVolume:"..p.Name..":"..v.part.Name) end end
 end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants() do if p:IsA("BasePart") then
  a.routes+=1;local mn,mx=bounds(p);mn=Vector3.new(mn.X,.7,mn.Z);mx=Vector3.new(mx.X,7.7,mx.Z)
  for _,v in owned do a.routeGeometryTests+=1;if overlap(v.mn,v.mx,mn,mx) then table.insert(a.issues,"VehicleSweep:"..p.Name..":"..v.part.Name) end end
 end end
 assert(a.solids==0 and a.meshes==0 and a.lights==0 and a.scripts==0,"Only thin nonphysical surface work")
 a.signature=signature(l);a.physicalFloorTop=PHYSICS_TOP;a.maximumVisibleTop=TOP
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"Audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","SeatPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed","DayNightReviewed"} do assert(e[k],"Missing evidence:"..k) end
 local l=layer();assert(not l:FindFirstChild("97_Evidence"),"Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v) end;f.Parent=l
 for _,m in l:GetChildren() do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 l:SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01BStatus","ACCEPTED_PROXY");return a
end
return I

