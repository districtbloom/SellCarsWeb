--!nocheck
-- Phase7A1: exterior surface art and two measured ground infills.
-- Original geometry/collision/data remain unchanged; only saved Transparency is suppressed.
local I={Version="2026-09-07.phase7a1.1"}
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","06_Atmosphere","01_Movement_Surfaces"
local C={asphalt=Color3.fromRGB(62,62,59),concrete=Color3.fromRGB(145,140,126),repair=Color3.fromRGB(124,120,108),stone=Color3.fromRGB(182,168,141),gravel=Color3.fromRGB(125,107,80),edge=Color3.fromRGB(103,96,80),joint=Color3.fromRGB(88,83,72),steel=Color3.fromRGB(74,77,72),void=Color3.fromRGB(42,43,40),paint=Color3.fromRGB(204,196,170),amber=Color3.fromRGB(194,153,64)}
local function root()
 assert(game.PlaceId==125334614375606,"Wrong place")
 assert(not game:GetService("RunService"):IsRunning(),"Edit only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function layer()local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME)end
local function hash(rows)
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
local function dataSignature()
 local rows={}
 for _,n in ipairs({"01_Ground_And_Road","02_Vehicle_Routes","03_Protected_Clearances","04_Capacity_Sockets","05_Architecture_Massing","08_Institution_Production_A","09_Institution_Production_B"})do
  for _,p in root()[n]:GetDescendants()do
   if p:IsA("BasePart") then
    local a={p:GetFullName(),tostring(p.CFrame),tostring(p.Size),tostring(p.CanCollide),tostring(p.CanQuery),tostring(p.CanTouch),tostring(p.Material),tostring(p.Color)}
    local attrs={};for k,v in p:GetAttributes()do table.insert(attrs,k.."="..tostring(v))end;table.sort(attrs);table.insert(a,table.concat(attrs,";"));table.insert(rows,table.concat(a,"|"))
   end
  end
 end
 return hash(rows)
end
local function signature(l)
 local rows={};for _,p in l:GetDescendants()do if p:IsA("BasePart")then table.insert(rows,p:GetFullName().."|"..tostring(p.CFrame).."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.CanCollide))end end;return hash(rows)
end
local function group(l,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=l
 for k,v in {BundleId="Institution.Ground."..n..".FidelityR1",FunctionId="CampusSurface",ZoneId=n,FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="DECORATIVE",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",SurfaceOnly=true}do m:SetAttribute(k,v)end
 return m
end
local function part(m,n,x,y,z,w,h,d,color,material,yaw)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*CFrame.Angles(0,yaw or 0,0)
 p.Material=material or Enum.Material.Concrete;p.Color=color or C.concrete;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.TopSurface=0;p.BottomSurface=0;p:SetAttribute("Phase7A1Surface",true);p.Parent=m;return p
end
local function line(m,n,x1,z1,x2,z2,width,y,color,mat)
 local a,b=Vector3.new(x1,y,z1),Vector3.new(x2,y,z2);local p=part(m,n,(x1+x2)/2,y,(z1+z2)/2,width,.018,(b-a).Magnitude,color,mat or Enum.Material.SmoothPlastic)
 p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function hide(l,p)
 if p.Transparency>=.98 then return end
 local f=l:FindFirstChild("99_Restore")or Instance.new("Folder");f.Name="99_Restore";f.Parent=l
 local v=Instance.new("ObjectValue");v.Name=string.format("Original_%03d",#f:GetChildren()+1);v.Value=p;v:SetAttribute("Transparency",p.Transparency);v.Parent=f;p.Transparency=1
end
local function arrow(m,x,z,direction,y)
 y=y or .178
 line(m,"TravelArrowStem",x,z-3*direction,x,z+3*direction,.55,y,C.paint)
 line(m,"TravelArrowHead",x,z+3*direction,x-2,z+1*direction,.55,y,C.paint)
 line(m,"TravelArrowHead",x,z+3*direction,x+2,z+1*direction,.55,y,C.paint)
end
local function corners(m,x,z,w,d,col)
 for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
  local a,b=x+sx*w/2,z+sz*d/2
  line(m,"ReservedPositionCorner",a,b,a-sx*2,b,.18,.194,col)
  line(m,"ReservedPositionCorner",a,b,a,b-sz*3,.18,.194,col)
 end end
end
local function drain(m,x,z,length,alongX)
 local yaw=alongX and math.pi/2 or 0
 part(m,"DrainChannelFrame",x,.166,z,1.1,.028,length,C.steel,Enum.Material.Metal,yaw)
 part(m,"DrainDarkOpening",x,.184,z,.76,.018,length-.24,C.void,Enum.Material.SmoothPlastic,yaw)
 local count=math.floor(length/.32)
 for i=1,count do
  local off=-length/2+i*.32
  part(m,"DrainLoadBar",x+(alongX and off or 0),.201,z+(alongX and 0 or off),.82,.018,.08,C.steel,Enum.Material.Metal,yaw)
 end
 for _,off in ipairs({-length/2+.25,length/2-.25})do
  part(m,"DrainEndPlate",x+(alongX and off or 0),.204,z+(alongX and 0 or off),.95,.022,.35,C.edge,Enum.Material.Metal,yaw)
 end
end
local function build(l)
 local inf=group(l,"Connectivity_Infills","ARCHITECTURE","DEDICATED","Compacted edge -> connected permanent circulation slab")
 inf:SetAttribute("CollisionClass","STRUCTURE");inf:SetAttribute("SurfaceOnly",false)
 for _,v in ipairs({{"RoadParcelBridge",-19,4},{"RearTransitionInfill",359.5,9}})do
  local p=part(inf,v[1],3130,.0225,v[2],252,.145,v[3],C.concrete,Enum.Material.Concrete)
  p.CanCollide=true;p.CanQuery=true;p:SetAttribute("GroundRepair",true)
 end
 local base=group(l,"Exterior_Concrete_Districts","ARCHITECTURE","WORKING","Rough slab -> repaired concrete -> maintained institutional apron")
 for _,v in ipairs({{"Frontage",46,126,C.concrete},{"Production",232,246,Color3.fromRGB(135,132,121)},{"RearService",430,132,Color3.fromRGB(140,134,117)}})do
  part(base,v[1].."Finish",3130,.107,v[2],252,.024,v[3],v[4],Enum.Material.Concrete)
 end
 local road=group(l,"Production_Street_And_Connections","ARCHITECTURE","DEDICATED","Compacted wheel tracks -> surfaced operating lanes")
 for _,p in root()["02_Vehicle_Routes"]:GetChildren()do
  if p:IsA("BasePart")and p.Name~="FrontPublicWalk"and p.Name~="RearStaffSpine"then
   local q=part(road,p.Name.."_Asphalt",p.Position.X,.141,p.Position.Z,p.Size.X,.024,p.Size.Z,C.asphalt,Enum.Material.Asphalt)
   q.CFrame=CFrame.new(p.Position.X,.141,p.Position.Z)*p.CFrame.Rotation
   if p.Name=="RoadToIntake"or p.Name=="SalesExit"or p.Name=="OwnerIndependentEntry"then q.Position+=Vector3.new(0,.038,0)end
  end
 end
 -- Flush, non-landscaped reservations: no raised kerb across a crossover.
 local central=group(l,"Central_Gravel_Reservations","ARCHITECTURE","WORKING","Unused dirt between tracks -> organized gravel islands")
 for _,v in ipairs({{104,138},{154,203},{219,268},{284,340}})do
  local z,d=(v[1]+v[2])/2,v[2]-v[1]
  part(central,"CompactedGravel",3130,.137,z,29.5,.024,d,C.gravel,Enum.Material.Ground)
  for _,x in ipairs({3115,3145})do line(central,"FlushStoneEdge",x,v[1],x,v[2],.28,.166,C.edge,Enum.Material.Concrete)end
  for _,zz in ipairs(v)do line(central,"FlushStoneEdge",3115,zz,3145,zz,.28,.166,C.edge,Enum.Material.Concrete)end
 end
 local marks=group(l,"Operating_Road_Markings","SUPPORT","DEDICATED","Chalk guidance -> restrained permanent traffic paint")
 for _,z in ipairs({122,181,245,311})do arrow(marks,3105,z,1);arrow(marks,3155,z,-1)end
 for _,x in ipairs({3038,3130,3221})do
  -- Entry/exit paint, not a new movement route.
  arrow(marks,x,-10,x==3130 and -1 or 1,.214)
 end
 for _,z in ipairs({146,211,276})do
  for _,x in ipairs({3105,3155})do line(marks,"CrossoverApproachBar",x-5,z+(x==3105 and -9 or 9),x+5,z+(x==3105 and -9 or 9),.28,.176,C.paint)end
 end
 for _,p in root()["01_Ground_And_Road"]:GetChildren()do if p.Name=="RoadDash"then
  part(marks,"PaintedCityCentreDash",p.Position.X,.186,p.Position.Z,p.Size.X,.024,p.Size.Z,C.amber,Enum.Material.SmoothPlastic)
 end end
 local front=group(l,"Public_Frontage_Walk","ARCHITECTURE","PROFESSIONAL","Informal yard approach -> continuous public frontage band")
 part(front,"WarmPublicPaving",3130,.153,2,246,.024,8,C.stone,Enum.Material.Limestone)
 for x=3015,3247,8 do line(front,"WalkPavingJoint",x,-2,x,6,.07,.175,C.joint)end
 for _,z in ipairs({-1.8,5.8})do line(front,"WalkBorder",3007,z,3253,z,.22,.177,C.edge,Enum.Material.Concrete)end
 for _,x in ipairs({3038,3130,3221})do
  for dx=-4.5,4.5,3 do part(front,"EntryCrossingPaint",x+dx,.202,2,1.25,.018,6.3,C.paint,Enum.Material.SmoothPlastic)end
 end
 local visitors=group(l,"Original_Visitor_Reservations","SUPPORT","PROFESSIONAL","Original marked lay-bys; manoeuvre validation still open")
 visitors:SetAttribute("VisitorUseCertification","OPEN_VISITOR_GATE_01");visitors:SetAttribute("CapacityClaim","NO_NEW_OR_CERTIFIED_CAPACITY")
 for _,x in ipairs({3060,3160,3244})do
  part(visitors,"RetainedVisitorFinish",x,.142,-11.5,21,.024,9,C.asphalt,Enum.Material.Asphalt)
  for _,dx in ipairs({-10.2,10.2})do line(visitors,"RetainedNonLuminousLine",x+dx,-16,x+dx,-7,.18,.175,C.paint)end
 end
 local holding=group(l,"Dealer_Holding_And_Service_Aprons","ARCHITECTURE","DEDICATED","Compacted holding yard -> repaired logistics concrete")
 part(holding,"HoldingApron",3130,.16,371,104,.024,20,C.repair,Enum.Material.Concrete)
 for _,x in ipairs({3100,3130,3160})do corners(holding,x,371,12,20,C.paint)end
 for _,x in ipairs({3039,3221})do
  part(holding,"RearServiceApron",x,.153,393,68,.024,30,C.repair,Enum.Material.Concrete)
  for dx=-22,22,22 do line(holding,"ApronSlabJoint",x+dx,378,x+dx,408,.075,.182,C.joint)end
  line(holding,"ApronSlabJoint",x-34,389,x+34,389,.075,.182,C.joint)
 end
 -- Separate pedestrian court begins beyond the rear ends of the dealer holding cars.
 local court=group(l,"Limestone_Craft_Court","ARCHITECTURE","PROFESSIONAL","Repaired original yard -> formal central craft courtyard")
 part(court,"WarmCourtBase",3130,.151,413,104,.024,64,C.stone,Enum.Material.Limestone)
 for x=3078,3182,13 do line(court,"CourtPanelJoint",x,381,x,445,.09,.177,C.joint)end
 for z=381,445,8 do line(court,"CourtPanelJoint",3078,z,3182,z,.09,.178,C.joint)end
 for _,x in ipairs({3078.35,3181.65})do line(court,"CourtBorder",x,381,x,445,.55,.184,C.edge,Enum.Material.Concrete)end
 for _,z in ipairs({381.35,444.65})do line(court,"CourtBorder",3078,z,3182,z,.55,.184,C.edge,Enum.Material.Concrete)end
 -- Actual rear staff ribbon stays in place; this finish only gives its surface a readable material.
 local staff=group(l,"Rear_Staff_Crossing","SUPPORT","DEDICATED","Marked service walk -> durable staff circulation band")
 part(staff,"StaffWalkConcrete",3130,.186,397,216,.024,6,Color3.fromRGB(159,154,135),Enum.Material.Concrete)
 for _,z in ipairs({394.2,399.8})do line(staff,"StaffEdgePaint",3022,z,3238,z,.13,.209,C.paint)end
 local drainage=group(l,"Stormwater_Channels_And_Cleanouts","UTILITY","DEDICATED","Isolated drainage patch -> maintained campus collection points")
 drainage:SetAttribute("SystemBinding","VISUAL_DRAINAGE_PROVISION_NOT_HYDRAULIC_SIMULATION")
 for _,z in ipairs({133,193,258,325})do drain(drainage,3113.2,z,12,false);drain(drainage,3146.8,z,12,false)end
 drain(drainage,3130,380,10,true)
 for _,x in ipairs({3026,3238})do
  part(drainage,"AccessCoverFrame",x,.183,405,2.3,.026,2.3,C.edge,Enum.Material.Metal)
  part(drainage,"RemovableCover",x,.207,405,1.95,.018,1.95,C.steel,Enum.Material.DiamondPlate)
  for _,dx in ipairs({-.5,.5})do part(drainage,"CoverLiftingSlot",x+dx,.222,405,.2,.012,.45,C.void,Enum.Material.SmoothPlastic)end
 end
 local history=group(l,"Repaired_Slabs_And_Controlled_Wear","STORY","BIRTH","First work slab repairs remain legible within maintained concrete")
 for _,v in ipairs({{3089,177,3.8,17},{3089,244,3.8,12},{3171,311,3.8,10},{3042,393,10,9}})do
  part(history,"OlderConcreteRepair",v[1],.141,v[2],v[3],.024,v[4],Color3.fromRGB(114,112,100),Enum.Material.Concrete)
  for _,dx in ipairs({-v[3]/2,v[3]/2})do line(history,"RepairSawCut",v[1]+dx,v[2]-v[4]/2,v[1]+dx,v[2]+v[4]/2,.06,.166,C.joint)end
 end
 for _,x in ipairs({3105,3155})do for _,z in ipairs({117,181,245,316})do
  for _,dx in ipairs({-3.1,3.1})do line(history,"FaintTyreTrace",x+dx,z-3,x+dx,z+3,.34,.165,Color3.fromRGB(55,55,52),Enum.Material.Asphalt)end
 end end
 history:SetAttribute("HistoryBinding","DESIGNED_SURFACE_ANCESTRY_NOT_REAL_PLAYER_EVENT")
end
function I.Uninstall()
 local l=layer();if l then local f=l:FindFirstChild("99_Restore");if f then for _,v in f:GetChildren()do assert(v:IsA("ObjectValue")and v.Value,"Lost original surface reference");v.Value.Transparency=v:GetAttribute("Transparency")end end;l:Destroy()end
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);if p and #p:GetChildren()==0 then p:Destroy()end
 root():SetAttribute("InstitutionFidelityPhase7A1GroundStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase6CEstateStatus")=="ACCEPTED","Accepted estate identity required")
 I.Uninstall();local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE)or Instance.new("Folder");p.Name=PHASE;p.Parent=root()["10_Institution_Fidelity_R1"]
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version);l:SetAttribute("LockedDataSignature",dataSignature())
 local ok,err=pcall(function()
  for _,n in ipairs({"FrontageApron","ProductionGround","RearCampusGround"})do hide(l,root()["01_Ground_And_Road"][n])end
  for _,p in root()["01_Ground_And_Road"]:GetChildren()do if p.Name=="RoadDash"then hide(l,p)end end
  for _,n in ipairs({"02_Vehicle_Routes","04_Capacity_Sockets"})do for _,p in root()[n]:GetDescendants()do if p:IsA("BasePart")then hide(l,p)end end end
  local diagnosticNames={MaximumFunctionEnvelope=true,EquipmentAndStaffBand=true,HQEnvelope=true,LogisticsEnvelope=true,OperationsEnvelope=true,HeroCourtyard=true}
  for _,p in root()["05_Architecture_Massing"]:GetDescendants()do if p:IsA("BasePart")and diagnosticNames[p.Name]then hide(l,p)end end
  local realm=root()["09_Institution_Production_B"]["03_Estate_Identity"]["08_Campus_Identity_Public_Realm"]
  hide(l,realm.CourtyardFinish)
  for _,m in realm:GetChildren()do if m:GetAttribute("VisitorParkingSocket")then for _,p in m:GetDescendants()do if p:IsA("BasePart")then hide(l,p)end end end end
  build(l)
 end)
 if not ok then I.Uninstall();error(err)end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase7A1GroundStatus","BUILT_AWAITING_REVIEW");return I.Audit()
end
function I.Audit()
 local l=assert(layer());local out={signature=signature(l),parts=0,models=0,solids=0,issues={},missingFloor={},metadataIssues={},supportRays=0,unchangedData=dataSignature()==l:GetAttribute("LockedDataSignature")}
 if not out.unchangedData then table.insert(out.issues,"Locked geometry/collision/material/data changed")end
 local r=RaycastParams.new();r.FilterType=Enum.RaycastFilterType.Include;r.FilterDescendantsInstances={root()["01_Ground_And_Road"],l.Connectivity_Infills};r.RespectCanCollide=true
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function top(p)return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 for _,p in l:GetDescendants()do
  if p:IsA("Model")then out.models+=1;for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"})do if p:GetAttribute(k)==nil then table.insert(out.metadataIssues,p.Name..":"..k)end end
  elseif p:IsA("BasePart")then
   out.parts+=1;if p.CanCollide then out.solids+=1;if not p:GetAttribute("GroundRepair")then table.insert(out.issues,"Unexpected solid:"..p.Name)end end
   if top(p)>.35 then table.insert(out.issues,"Above ground reservation:"..p.Name)end
   if p.CanTouch or (p.CanQuery and not p:GetAttribute("GroundRepair"))then table.insert(out.issues,"Unexpected physical surface:"..p.Name)end
   for _,s in ipairs({{-1,-1},{-1,1},{1,-1},{1,1},{0,0}})do
    local v=p.CFrame:PointToWorldSpace(Vector3.new(s[1]*math.max(0,p.Size.X/2-.06),0,s[2]*math.max(0,p.Size.Z/2-.06)))
    if v.X<2980 or v.X>3280 or v.Z< -55 or v.Z>500 then table.insert(out.issues,"Outside occupied scene bounds:"..p.Name)end
    out.supportRays+=1;local hit=workspace:Raycast(Vector3.new(v.X,.65,v.Z),Vector3.new(0,-1.1,0),r)
    if not hit or top(p)-hit.Position.Y>.35 then table.insert(out.missingFloor,p.Name..":"..tostring(v))end
   end
  end
 end
 out.hiddenOriginals=0;for _,v in l["99_Restore"]:GetChildren()do out.hiddenOriginals+=1;if not v.Value or v.Value.Transparency~=1 then table.insert(out.issues,"Lost/changed hidden original:"..v.Name)end end
 -- New objects are all below the normal .88 chassis-floor threshold, including visible non-solids.
 out.protectedEnvelopes=0;for _,p in root()["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then
  out.protectedEnvelopes+=1;for _,q in workspace:GetPartBoundsInBox(p.CFrame,p.Size,params)do if q.Transparency<.98 and top(q)>.88 then table.insert(out.issues,"Vehicle envelope:"..p.Name.."/"..q.Name)end end
 end end
 assert(out.solids==2,"Exactly two documented ground repairs required")
 return out
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.missingFloor==0 and #a.metadataIssues==0,"Surface validation incomplete")
 assert(e.VisualPass and e.ActualWalkingPass and e.RegressionsPass and e.RollbackPass and e.SourceMatch and e.RenderingReviewed and e.RoutePass,"Evidence missing")
 local f=Instance.new("Folder");f.Name="98_Evidence";f.Parent=layer();for k,v in e do f:SetAttribute(k,v)end
 for _,m in layer():GetDescendants()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase7A1GroundStatus","ACCEPTED");return a
end
return I

