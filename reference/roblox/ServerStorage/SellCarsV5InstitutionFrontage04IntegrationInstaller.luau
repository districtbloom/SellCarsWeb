--!nocheck
-- F04-5. Scoped permanent activation, with exact retained originals and rollback.
local I={Version="2026-09-08.frontage04.f5.1"}
local SS=game:GetService("ServerStorage")
local function fresh(name)local m=assert(SS:FindFirstChild(name),name):Clone();local ok,v=pcall(require,m);m:Destroy();assert(ok,v);return v end
local function context()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 local r=assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"));local p=assert(SS:FindFirstChild("SellCarsV5Frontage04Package"))
 return r,p,assert(p.CandidateReference.Value)
end
local function folder(p,n)local v=Instance.new("Folder");v.Name=n;v.Parent=p;return v end
local function ref(p,n,v)local q=Instance.new("ObjectValue");q.Name=n;q.Value=v;q.Parent=p;return q end
local function at(p,path)for n in path:gmatch("[^/]+")do p=assert(p:FindFirstChild(n),"Missing "..path)end;return p end
local function inventory(m)local n={parts=0,lights=0,models=0,descendants=#m:GetDescendants()};for _,v in m:GetDescendants()do if v:IsA("BasePart")then n.parts+=1 elseif v:IsA("Light")then n.lights+=1 elseif v:IsA("Model")then n.models+=1 end end;return n end
local NEW={"05_Frontage_Landscape","07_Frontage_Warm_Lighting","08_Integration_Anchors","09_Local_Route_Connections"}
local function routeData(c,K)
 local data=K.model(c,"09_Local_Route_Connections","LOCAL_ROUTE_DATA")
 data:SetAttribute("Contract","REFERENCE_POLYLINES_NOT_FINAL_TRAFFIC_CONTROLLER")
 local function path(name,points)
  local m=folder(data,name);m:SetAttribute("PointCount",#points);m:SetAttribute("Width",12)
  for i,v in points do local p=Instance.new("Vector3Value");p.Name=string.format("Point_%03d",i);p.Value=Vector3.new(v.X,.30,v.Z);p.Parent=m end
  return m
 end
 for i,x in {3033,3052,3014}do
  path("RoadToIntake_"..i,{Vector3.new(x,0,-30),Vector3.new(x,0,64)})
  local points={Vector3.new(x,0,64),Vector3.new(x,0,75)}
  for degrees=10,90,10 do local a=math.rad(degrees);table.insert(points,Vector3.new(x+13.9-13.9*math.cos(a),0,75+13.9*math.sin(a)))end
  table.insert(points,Vector3.new(3091.9,0,88.9))
  for degrees=10,90,10 do local a=math.rad(degrees);table.insert(points,Vector3.new(3091.9+13.1*math.sin(a),0,102-13.1*math.cos(a)))end
  path("IntakeDispatch_"..i,points)
 end
 path("ReturnToSales",{Vector3.new(3155,0,102),Vector3.new(3155,0,92),Vector3.new(3130,0,84)})
 path("SalesExit",{Vector3.new(3130,0,84),Vector3.new(3130,0,24),Vector3.new(3130,0,-30)})
 return data
end
function I.BuildArtwork()
 local r,p,c=context();assert(not p:GetAttribute("PreviewActive")and c.Parent==p,"EndPreview first")
 assert(not p:FindFirstChild("F04_5_Recovery"),"Existing F5 recovery preserved")
 local G=fresh("SellCarsV5InstitutionCourtyard02Installer").GeometryHash
 assert(G(r)=="fa41fccf"and G(c)=="74bb2911","Unexpected baseline; preserve changes")
 local rec=folder(nil,"F04_5_Recovery");rec:SetAttribute("Version",I.Version);rec:SetAttribute("OriginalGeometry",G(r));rec:SetAttribute("CandidateBefore",G(c));rec:SetAttribute("FullPlaceBackup",false)
 local rootCopy=r:Clone();rootCopy.Name="FullOriginalInstitution_BeforeActivation";rootCopy.Parent=rec
 local copy=c:Clone();copy.Name="F04_4_Candidate_BeforeFinish";copy.Parent=rec
 local sources=folder(rec,"BeforeSources")
 for _,m in SS:GetChildren()do if m:IsA("ModuleScript")and m.Name:match("^SellCarsV5")then local q=m:Clone();q.Parent=sources;ref(q,"OriginalSourceInstance",m)end end
 local staged=Instance.new("Model");local K=fresh("SellCarsV5Frontage04Kit")
 local ok,err=pcall(function()
  fresh("SellCarsV5Frontage04Landscape")(K,staged)
  fresh("SellCarsV5Frontage04Lighting")(K,staged,c)
  local anchors=K.model(staged,"08_Integration_Anchors","WORK_ANCHORS")
  for _,d in fresh("SellCarsV5Frontage04Runtime").ActorLayout()do
   local a=K.box(anchors,d.id,d.home.X,d.anchorY,d.home.Z,.15,.04,.15,K.C.black,Enum.Material.SmoothPlastic,false)
   a.Transparency=1;a.CanQuery=false;a:SetAttribute("AnchorKind","WORK");a:SetAttribute("FacingTarget",d.target)
  end
  routeData(staged,K)
 end)
 if not ok then staged:Destroy();rec:Destroy();error(err)end
 rec.Parent=p;local refs=folder(rec,"NewLayers")
 for _,v in staged:GetChildren()do ref(refs,v.Name,v);v.Parent=c end;staged:Destroy()
 rec:SetAttribute("ArtworkAttached",true);c:SetAttribute("SalesHasLaterDependants",true)
 return {landscape=inventory(c[NEW[1]]),lighting=inventory(c[NEW[2]]),candidate=inventory(c),geometry=G(c)}
end

-- Exact records restore in reverse order; no object is destroyed during migration.
local function capture(records,v,seen)
 if seen[v]then return seen[v]end
 local q=ref(records,string.format("Record_%05d",#records:GetChildren()+1),v);seen[v]=q
 ref(q,"OriginalParent",v.Parent);q:SetAttribute("OriginalName",v.Name)
 local attrs=folder(q,"Attributes");for k,val in v:GetAttributes()do attrs:SetAttribute(k,val)end
 local props=folder(q,"Properties")
 if v:IsA("BasePart")then for _,k in {"CFrame","Size","Transparency","Color","Material","CanCollide","CanTouch","CanQuery","CastShadow"}do props:SetAttribute(k,v[k])end end
 if v:IsA("Model")then props:SetAttribute("WorldPivot",v.WorldPivot)end
 if v:IsA("Light")then for _,k in {"Enabled","Brightness","Range","Color","Shadows"}do props:SetAttribute(k,v[k])end end
 if v:IsA("ObjectValue")then ref(q,"OriginalValue",v.Value)end
 return q
end
local function restoreRecords(records)
 local list=records:GetChildren();table.sort(list,function(a,b)return a.Name>b.Name end)
 for _,q in list do assert(q.Value,"Lost original "..q.Name);assert(q.OriginalParent.Value,"Lost original parent")end
 for _,q in list do local v=q.Value;v.Name=q:GetAttribute("OriginalName");v.Parent=q.OriginalParent.Value
  for k in v:GetAttributes()do v:SetAttribute(k,nil)end;for k,val in q.Attributes:GetAttributes()do v:SetAttribute(k,val)end
  for k,val in q.Properties:GetAttributes()do v[k]=val end
  if q:FindFirstChild("OriginalValue")then v.Value=q.OriginalValue.Value end
 end
end
local SCOPES={
 "09_Institution_Production_B/01_Frontage_Commercial/01_Intake_Appraisal",
 "09_Institution_Production_B/01_Frontage_Commercial/02_Sales_Delivery",
 "10_Institution_Fidelity_R1/04_Frontage_And_Owner/01_Intake",
 "10_Institution_Fidelity_R1/04_Frontage_And_Owner/02_Sales",
 "10_Institution_Fidelity_R1/07_Elevation_01/08_Intake_Waiting_Comfort",
 "10_Institution_Fidelity_R1/07_Elevation_01/09_Sales_Desk_Joinery",
 "10_Institution_Fidelity_R1/07_Elevation_01/14_Intake_Waiting_Light",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Coachworks_Gateway",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Appraisal_Waymarker",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Sales_Waymarker",
 "10_Institution_Fidelity_R1/06_Atmosphere/03_Lighting_Hierarchy/Gateway_3120",
 "10_Institution_Fidelity_R1/06_Atmosphere/03_Lighting_Hierarchy/Gateway_3140",
}
local function ribbon(p,a,b)
 p.Size=Vector3.new(12,.12,(b-a).Magnitude);p.CFrame=CFrame.lookAt((a+b)/2,b);p.Transparency=1;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
end
function I.Activate()
 local r,p,c=context();local rec=assert(p:FindFirstChild("F04_5_Recovery"));assert(not p:GetAttribute("PreviewActive")and c.Parent==p,"Stage before activation")
 assert(rec:GetAttribute("ArtworkAttached")and not c:GetAttribute("Frontage04Activated"),"F5 state mismatch")
 assert(fresh("SellCarsV5InstitutionCourtyard02Installer").GeometryHash(r)=="fa41fccf","Original changed; preserve")
 local f=r["10_Institution_Fidelity_R1"];assert(not f:FindFirstChild("11_Frontage04"))
 local legacy={};for _,path in SCOPES do table.insert(legacy,at(r,path))end
 local actorLayer=f["06_Atmosphere"]["07_Occupation_Frontage"]
 local runtime=fresh("SellCarsV5Frontage04Runtime");local actors=runtime.ActorLayout()
 for _,d in actors do assert(actorLayer:FindFirstChild(d.id)and actorLayer[d.id]:FindFirstChild("ExistingWorkAnchor"),"Missing actor "..d.id)end
 local serial=(rec:GetAttribute("ActivationSerial")or 0)+1
 local act=folder(rec,"Activation_"..serial);local records=folder(act,"ExactRecords");local archive=folder(act,"RetiredOriginals");local added=folder(act,"AddedRouteReferences");local seen={}
 rec:SetAttribute("ActivationSerial",serial)
 local current=rec:FindFirstChild("CurrentActivation")
 if current then current.Value=act else ref(rec,"CurrentActivation",act)end
 act:SetAttribute("Status","PREPARING")
 -- Proven vehicle/mask recovery is retained and promoted, not discarded.
 fresh("SellCarsV5InstitutionFrontage04Installer").Preview()
 ref(act,"VehicleAndMaskRecovery",p.ActiveRecovery.Value)
 local ok,err=pcall(function()
  capture(records,c,seen);capture(records,p,seen);capture(records,r,seen)
  for _,v in legacy do capture(records,v,seen)end
  for _,d in actors do local m=actorLayer[d.id];capture(records,m,seen);for _,v in m:GetDescendants()do capture(records,v,seen)end end
  for _,v in r["04_Capacity_Sockets"]:GetChildren()do if v.Name:match("^Intake_")or v.Name:match("^Sales")then capture(records,v,seen)end end
  for _,v in r["03_Protected_Clearances"]:GetChildren()do if v.Name:match("^IntakeClear_")or v.Name=="TransporterSweep"then capture(records,v,seen)end end
  for _,n in {"RoadToIntake","IntakeDispatch","ReturnToSales"}do capture(records,r["02_Vehicle_Routes"][n],seen)end
  local lightRecords=f["06_Atmosphere"]["03_Lighting_Hierarchy"]["99_Baseline"].Lights
  for _,n in {"034","035","036","037","038"}do capture(records,lightRecords[n],seen)end
  -- Store original child names in records, never use duplicate names as identity.
  for i,v in legacy do v.Name=string.format("Scope_%02d_",i)..v.Name;v.Parent=archive end
  -- Any individually masked former paint would otherwise retain invisible
  -- collision/query presence. Retire only exact fully-contained mask targets.
  for _,q in p.ActiveRecovery.Value.ExactModifiedProperties:GetChildren()do
   local v=q.Value
   if v:IsA("BasePart")and v:IsDescendantOf(f["06_Atmosphere"]["01_Movement_Surfaces"])then capture(records,v,seen);v.Parent=archive end
  end
  for _,v in f["06_Atmosphere"]["01_Movement_Surfaces"]:GetDescendants()do
   if v:IsA("BasePart")and(v.Name=="RoadToIntake_Asphalt"or v.Name=="IntakeDispatch_Asphalt")then capture(records,v,seen);v.Parent=archive end
  end
  c.Name="11_Frontage04";c.Parent=f;c:SetAttribute("Frontage04Activated",true);c:SetAttribute("Status","INSTITUTION_FRONTAGE04_INTEGRATED")
  c:SetAttribute("GroundSalesCapacity",6);c:SetAttribute("ElevatedSalesCapacity",0);c:SetAttribute("IntakeCapacity",3)
  c:SetAttribute("FinalTrafficController",false);c:SetAttribute("PhaseInheritance","FIXED_F04_FOOTPRINT_EARLIER_CHAPTER_BUILD_DEFERRED")
  c["06_Actual_Sales_Vehicles"]:SetAttribute("VisualPreviewOnly",false)
  r:SetAttribute("ActiveFrontage","Frontage04");r:SetAttribute("Frontage04Activated",true)
  local slots=r["04_Capacity_Sockets"]
  for i,x in {3033,3052,3014}do local s=slots["Intake_"..i];s.CFrame=CFrame.new(x,.45,64)*CFrame.Angles(0,math.pi,0)
   local clear=r["03_Protected_Clearances"]:FindFirstChild("IntakeClear_"..i)
   if clear then clear.CFrame=CFrame.new(x,4,64);clear.Size=Vector3.new(14,8,23)end
  end
  for _,s in slots:GetChildren()do if s.Name:match("^Sales")then s.Size=Vector3.new(14,.16,23);s:SetAttribute("FrontageLayout","F04_GROUND")end end
  local transport=r["03_Protected_Clearances"]:FindFirstChild("TransporterSweep")
  if transport then transport.CFrame=CFrame.new(3014,4,27.625);transport.Size=Vector3.new(14,8,49.75);transport:SetAttribute("LayoutContract","STRAIGHT_REVERSE_IN_FORWARD_OUT_NOT_U_TURN")end
  local routes=r["02_Vehicle_Routes"]
  ribbon(routes.RoadToIntake,Vector3.new(3033,.3,-30),Vector3.new(3033,.3,64))
  -- Preserve the original route instance as the last approach; exact complete
  -- polylines are linked explicitly instead of misrepresenting a diagonal.
  local a=math.rad(80);ribbon(routes.IntakeDispatch,Vector3.new(3091.9+13.1*math.sin(a),.3,102-13.1*math.cos(a)),Vector3.new(3105,.3,102))
  routes.IntakeDispatch:SetAttribute("PolylineRequired",true)
  local rr=Instance.new("ObjectValue");rr.Name="Frontage04Connections";rr.Value=c["09_Local_Route_Connections"];rr.Parent=routes;ref(added,"Connections",rr)
  for _,d in actors do local m=actorLayer[d.id];m.ExistingWorkAnchor.Value=c["08_Integration_Anchors"][d.id]
   for _,q in p.ActiveRecovery.Value.ExactModifiedProperties:GetChildren()do if q.Value:IsDescendantOf(m)then for k,val in q:GetAttributes()do q.Value[k]=val end end end
  end
  local keys={['034']='Old034Ordinary1',['035']='Old035Ordinary2',['036']='Old036WestSales',['037']='Old037EastSales',['038']='Old038Handover'}
  for n,key in keys do local light=assert(c["07_Frontage_Warm_Lighting"]:FindFirstChild(key,true));assert(light:IsA("Light"));local q=lightRecords[n];q.Value=light;q:SetAttribute("Range",light.Range);q:SetAttribute("Brightness",light:GetAttribute("NightBrightness")/.9)end
  -- Enabled source hosts are unchanged; a fresh runtime boot reads F04 poses.
  local occupation=fresh("SellCarsV5InstitutionFidelityPhase7C2B2FrontageOccupationInstaller")
  for _,d in actors do occupation.Preview(d.id,0)end
  runtime.ApplyLighting(f["06_Atmosphere"]["03_Lighting_Hierarchy"]:GetAttribute("Preset")or"Day")
  p:SetAttribute("PreviewActive",false);p:SetAttribute("InstalledIntoLiveFrontage",true)
  p.ActiveRecovery.Value:SetAttribute("PromotedToPermanentActivation",true)
  act:SetAttribute("Status","ACTIVE");act:SetAttribute("CompleteFrontageMigration",true)
 end)
 if not ok then act:SetAttribute("Failure",tostring(err));act:SetAttribute("Status","PARTIAL");error("Retained exact recovery; call IntegrationInstaller.Rollback: "..tostring(err))end
 return {status="INTEGRATED",candidate=inventory(c),retiredScopes=#legacy,actorCount=#actors,actualCars=#c["06_Actual_Sales_Vehicles"]:GetChildren(),recovery=act:GetFullName()}
end
function I.Rollback()
 local r,p,c=context();local rec=assert(p:FindFirstChild("F04_5_Recovery"));local act=assert(rec.CurrentActivation.Value)
 assert(act:GetAttribute("Status")~="ROLLED_BACK","Already rolled back")
 for _,q in act.AddedRouteReferences:GetChildren()do if q.Value then q.Value.Parent=act end end
 restoreRecords(act.ExactRecords)
 -- Restore the pre-F5 source text, leaving new optional modules inactive.
 for _,q in rec.BeforeSources:GetChildren()do local original=q.OriginalSourceInstance.Value;assert(original,"Lost source");original.Source=q.Source end
 p:SetAttribute("PreviewActive",true)
 fresh("SellCarsV5InstitutionFrontage04Installer").EndPreview()
 local inactive=rec:FindFirstChild("DetachedArtwork")or folder(rec,"DetachedArtwork")
 for _,q in rec.NewLayers:GetChildren()do assert(q.Value.Parent==c,"Owned art moved");q.Value.Parent=inactive end
 c:SetAttribute("SalesHasLaterDependants",nil);c["06_Actual_Sales_Vehicles"]:SetAttribute("VisualPreviewOnly",true)
 rec:SetAttribute("ArtworkAttached",false);act:SetAttribute("Status","ROLLED_BACK")
 local G=fresh("SellCarsV5InstitutionCourtyard02Installer").GeometryHash
 return {original=G(r),candidate=G(c),originalDescendants=#r:GetDescendants(),candidateDescendants=#c:GetDescendants()}
end
function I.ReattachArtwork()
 local r,p,c=context();assert(not p:GetAttribute("PreviewActive")and c.Parent==p)
 local rec=p.F04_5_Recovery;assert(not rec:GetAttribute("ArtworkAttached"))
 for _,q in rec.NewLayers:GetChildren()do assert(q.Value.Parent==rec.DetachedArtwork);q.Value.Parent=c end
 c:SetAttribute("SalesHasLaterDependants",true);rec:SetAttribute("ArtworkAttached",true)
 return inventory(c)
end
return I

