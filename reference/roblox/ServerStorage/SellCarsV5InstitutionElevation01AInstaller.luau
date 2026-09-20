--!nocheck
-- Elevation01A: additive central craft pocket. No original geometry is suppressed.
local I={Version="2026-09-07.elevation01a.4"}
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","07_Elevation_01","01_Central_Craft_Pocket"
local C={steel=Color3.fromRGB(47,44,38),rust=Color3.fromRGB(118,68,38),timber=Color3.fromRGB(137,96,57),grain=Color3.fromRGB(104,75,46),stone=Color3.fromRGB(163,151,125),sage=Color3.fromRGB(82,116,82),blue=Color3.fromRGB(105,135,108),tip=Color3.fromRGB(153,163,117),bark=Color3.fromRGB(107,92,66),dark=Color3.fromRGB(62,67,47),bud=Color3.fromRGB(182,125,54),bolt=Color3.fromRGB(130,131,119)}
local function root()
 assert(game.PlaceId==125334614375606 and not game.RunService:IsRunning(),"Correct place / Edit only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function layer()
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE)
 return p and p:FindFirstChild(NAME)
end
local function model(l,n,role,ancestor,first)
 local m=Instance.new("Model");m.Name=n;m.Parent=l
 for k,v in {BundleId="Institution.Elevation01A."..n,FunctionId="EstateLandscape",ZoneId="Desert_Bed_2_West",FidelityRole=role,PhaseMin=first or "INSTITUTION",Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",SourceGeometry="PARAMETRIC_PROXY",SourceOwned=true,CollisionClass="DECORATIVE",InteractionAnchor="",FXSocket="",AllowedMin=Vector3.new(3115.4,.08,154.5),AllowedMax=Vector3.new(3125.8,10,202.5)}do m:SetAttribute(k,v)end
 return m
end
local function part(m,n,pos,size,col,mat,solid,cf,cls)
 local p=Instance.new(cls or "Part");p.Name=n;p.Size=size;p.CFrame=cf or CFrame.new(pos);p.Anchored=true;p.Color=col;p.Material=mat or Enum.Material.Metal
 p.CanCollide=solid==true;p.CanQuery=true;p.CanTouch=cls=="Seat";p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0;p:SetAttribute("Elevation01AOwned",true);p.Parent=m;return p
end
local function tube(m,n,a,b,d,col,mat,solid)
 local p=part(m,n,(a+b)/2,Vector3.new((b-a).Magnitude,d,d),col,mat,solid)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
local function leaf(m,a,b,w,col)
 for _,s in {-1,1}do
  local p=part(m,"TaperedLeaf",(a+b)/2,Vector3.new(.07,w/2,(b-a).Magnitude),col,Enum.Material.SmoothPlastic,false,nil,"WedgePart")
  p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,s*math.pi/2)*CFrame.new(0,w/4,0)
 end
end
local function crown(m,p,s,n,phase)
 for i=1,n do
  local a=i*math.pi*2/n+phase;local d=Vector3.new(math.cos(a),0,math.sin(a))
  local base=p+d*.13*s
  local bend=p+d*1.25*s+Vector3.new(0,(.50+.15*math.sin(i))*s,0)
  local tip=p+d*2.25*s+Vector3.new(0,(-.55+.20*math.cos(i))*s,0)
  leaf(m,bend,base,.38*s,i%3==0 and C.tip or C.blue);leaf(m,bend,tip,.38*s,C.sage)
 end
 for i=1,4 do local a=i*1.57+phase
  leaf(m,p, p+Vector3.new(math.cos(a)*.55*s,1.65*s,math.sin(a)*.55*s),.25*s,C.tip)
 end
end
local function yucca(l)
 local m=model(l,"Branching_Yucca","STORY","Retained low scrub -> maintained sculptural desert specimen in the same planted reserve","PROFESSIONAL")
 local p=Vector3.new(3118.8,.18,162.5)
 tube(m,"RootTrunk",p,p+Vector3.new(.12,4.9,.08),.8,C.bark,Enum.Material.Wood,false)
 tube(m,"MainStem",p+Vector3.new(.12,4.5,.08),p+Vector3.new(.25,6.85,.15),.57,C.bark,Enum.Material.Wood,false)
 tube(m,"Branch",p+Vector3.new(.1,3.7,.06),p+Vector3.new(-.35,5.75,.68),.42,C.bark,Enum.Material.Wood,false)
 for i=1,8 do local y=.22+i*.42;local a=i*.79
  tube(m,"RetainedLeafScar",p+Vector3.new(math.cos(a)*.35,y,math.sin(a)*.35),p+Vector3.new(math.cos(a)*.37,y+.13,math.sin(a)*.37),.11,C.dark,Enum.Material.Wood,false)
 end
 for i=1,4 do local a=i*1.57
  tube(m,"RootFlare",p+Vector3.new(math.cos(a)*.6,.08,math.sin(a)*.6),p+Vector3.new(0,.7,0),.18,C.bark,Enum.Material.Wood,false)
 end
 crown(m,p+Vector3.new(.25,6.85,.15),1.1,10,.3)
 crown(m,p+Vector3.new(-.35,5.75,.68),.75,8,1)
 m:SetAttribute("BotanicalIntent","BRANCHING_YUCCA_FORM_PROXY_FINAL_BOTANICAL_MESH_PENDING")
end
local function cactus(l)
 local m=model(l,"Flat_Pad_Cactus","STORY","Low hardy planting -> deliberately composed mature flat-pad cactus group","PROFESSIONAL")
 local origin=Vector3.new(3119.1,.18,195)
 tube(m,"RootedCactusNeck",Vector3.new(3119.1,.095,195),Vector3.new(3119.1,.75,195),.36,C.dark,Enum.Material.SmoothPlastic,false)
 local pads={{0,1.15,0,1.65,2.25,.43,0},{-.67,2.94,.05,1.40,2,.37,.32},{.66,3.11,.05,1.38,2.12,.39,-.28},{1.06,4.51,.04,1.02,1.60,.32,-.25},{-1.09,4.15,-.06,1.05,1.6,.33,.27},{0,4.9,.10,1.04,1.75,.34,-.08},{.88,1.24,.12,1.12,1.43,.33,-.6}}
 for i,v in pads do
  local cf=CFrame.new(origin+Vector3.new(v[1],v[2],v[3]))*CFrame.Angles(0,.05*(i%3),v[7])
  local p=part(m,"RoundedCactusPad_"..i,cf.Position,Vector3.new(v[4],v[5],v[6]),i%3==0 and C.blue or C.sage,Enum.Material.SmoothPlastic,false,cf);local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Name="EllipticalPadSurface";mesh.Parent=p
  for _,q in {{-.2,.22},{.2,.18},{0,-.2},{0,.55}}do
   local pos=cf:PointToWorldSpace(Vector3.new(q[1]*v[4],q[2]*v[5]*.65,-v[6]*.46))
   local a=part(m,"Areole",pos,Vector3.new(.11,.12,.035),C.tip,Enum.Material.SmoothPlastic,false,CFrame.new(pos)*cf.Rotation);a.Shape=Enum.PartType.Ball
  end
  if i>=4 and i<=6 then
   local pos=cf:PointToWorldSpace(Vector3.new(0,v[5]*.45,0))
   local bud=part(m,"DryGoldBud",pos,Vector3.new(.23,.27,.22),C.bud,Enum.Material.SmoothPlastic,false);bud.Shape=Enum.PartType.Ball
  end
 end
 m:SetAttribute("BotanicalIntent","IRREGULAR_FLAT_PAD_CACTUS_PROXY_NO_SAGUARO_AVENUE")
end
local function bench(l)
 local m=model(l,"Timber_Craft_Bench","SUPPORT","Rough yard resting plank -> permanent timber and weathering-steel garden bench","WORKING")
 m:SetAttribute("CollisionClass","FURNITURE");m:SetAttribute("InteractionAnchor","BenchApproach")
 local x,z=3123.1,187
 for i=0,1 do for j=0,3 do
  part(m,"LimestonePavingSlab",Vector3.new(3122.15+i*1.75,.135,184.03+j*1.98),Vector3.new(1.69,.09,1.91),C.stone,Enum.Material.Limestone,false)
 end end
 for _,zz in {z-2.5,z+2.5}do
  part(m,"BaseShoe",Vector3.new(x,.24,zz),Vector3.new(2.1,.15,.46),C.rust,Enum.Material.Metal,true)
  part(m,"RearSupport",Vector3.new(x-.74,.95,zz),Vector3.new(.23,1.45,.24),C.steel,nil,true)
  part(m,"FrontSupport",Vector3.new(x+.65,.92,zz),Vector3.new(.23,1.4,.24),C.steel,nil,true)
  part(m,"SeatBearing",Vector3.new(x,1.57,zz),Vector3.new(2,.2,.23),C.steel,nil,true)
  part(m,"BackUpright",Vector3.new(x-.82,2.08,zz),Vector3.new(.22,1.90,.24),C.rust,Enum.Material.Metal,true)
  for _,dx in {-.74,.65}do
   tube(m,"AnchorBolt",Vector3.new(x+dx,.32,zz),Vector3.new(x+dx,.39,zz),.16,C.bolt,Enum.Material.Metal,false)
  end
  part(m,"ArmPost",Vector3.new(x+.52,2.08,zz),Vector3.new(.18,.86,.2),C.steel,nil,true)
  part(m,"TimberArmCap",Vector3.new(x-.08,2.58,zz),Vector3.new(1.63,.20,.31),C.timber,Enum.Material.Wood,false)
 end
 for i=0,3 do
  local xx=x-.68+i*.45
  local p=part(m,i==2 and "RestSeat" or "TimberSeatSlat",Vector3.new(xx,1.77,z),Vector3.new(6.55,.23,.40),C.timber,Enum.Material.Wood,true,CFrame.lookAt(Vector3.new(xx,1.77,z),Vector3.new(xx+1,1.77,z)),i==2 and "Seat" or "Part")
  if p:IsA("Seat") then p:SetAttribute("Role","SINGLE_PLAYER_REST_SEAT_NO_NPC_CONTROLLER");p.Disabled=false end
  for _,zz in {z-2.5,z+2.5}do tube(m,"SlatPin",Vector3.new(xx,1.886,zz),Vector3.new(xx,1.914,zz),.08,C.bolt,Enum.Material.Metal,false)end
 end
 for i=0,2 do part(m,"BackSlat",Vector3.new(x-.87,2.21+i*.34,z),Vector3.new(.20,.27,6.55),i==0 and C.grain or C.timber,Enum.Material.Wood,true)end
 for _,zz in {z-3.34,z+3.34}do part(m,"EndGrainCap",Vector3.new(x-.87,2.55,zz),Vector3.new(.23,1,.10),C.grain,Enum.Material.Wood,false)end
 local p=part(m,"BenchApproach",Vector3.new(3125.8,.095,187),Vector3.new(.1,.1,.1),C.steel,nil,false);p.Transparency=1;p.CanQuery=false;p:SetAttribute("AnchorKind","OPERATOR")
 local a=Instance.new("Attachment");a.Name="SeatUse";a.Parent=p
end
local function stone(l)
 local m=model(l,"Garden_Stone_And_Edge","STORY","Loose local stones -> maintained limestone grouping beside retained irrigation","WORKING")
 for i,v in {{3117.4,164.2,1.1},{3118.4,165.1,.8},{3117.6,192.8,.95},{3120.7,197,.72}}do
  part(m,"FacetedLimestone",Vector3.new(v[1],.18+v[3]*.24,v[2]),Vector3.new(v[3],v[3]*.43,v[3]*.72),C.stone,Enum.Material.Limestone,false,CFrame.new(v[1],.18+v[3]*.24,v[2])*CFrame.Angles(.06,i*.51,-.08),"WedgePart")
 end
end
local function path(l,n,points)
 local f=l:FindFirstChild("98_Access_Paths")or Instance.new("Folder");f.Name="98_Access_Paths";f.Parent=l
 local r=Instance.new("Folder");r.Name=n;r.Parent=f
 for i,p in points do local v=Instance.new("Vector3Value");v.Name=string.format("%02d",i);v.Value=Vector3.new(unpack(p));v.Parent=r end
end
function I.Uninstall()
 local l=layer();local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE)
 if l then assert(#p:GetChildren()==1,"Uninstall newer elevation dependencies first");l:Destroy()end
 if p and #p:GetChildren()==0 then p:Destroy()end
 root():SetAttribute("InstitutionElevation01AStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase7A2LandscapeStatus")=="ACCEPTED","Accepted landscape required")
 I.Uninstall();local p=Instance.new("Folder");p.Name=PHASE;p.Parent=root()["10_Institution_Fidelity_R1"]
 local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l.Parent=p
 local ok,err=pcall(function()
  yucca(l);cactus(l);bench(l);stone(l)
  path(l,"CentralAxis",{{3130,.095,145},{3130,.095,211}})
  path(l,"BenchApproach",{{3130,.095,187},{3125.8,.095,187}})
  path(l,"BenchNorthSide",{{3130,.095,192.5},{3122,.095,192.5}})
 end)
 if not ok then I.Uninstall();error(err)end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionElevation01AStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
local function renderFormSignature(l)
 local rows={}
 for _,v in l:GetDescendants()do
  local path=v:GetFullName():sub(#l:GetFullName()+2)
  if v:IsA("BasePart")then
   local cf={};for _,n in {v.CFrame:GetComponents()}do local s=string.format("%.5f",n);if s=="-0.00000"then s="0.00000"end;table.insert(cf,s)end
   table.insert(rows,path.."|"..v.ClassName.."|"..(v:IsA("Part")and v.Shape.Name or v.ClassName).."|"..tostring(v.Size).."|"..table.concat(cf,",").."|"..tostring(v:IsA("Seat")and v.Disabled or false))
  elseif v:IsA("SpecialMesh")then
   table.insert(rows,path.."|"..v.MeshType.Name.."|"..tostring(v.Scale).."|"..tostring(v.Offset).."|"..tostring(v.VertexColor).."|"..v.MeshId.."|"..v.TextureId)
  end
 end
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end;h=(h*33+10)%4294967296 end
 return string.format("%08x",h)
end
function I.Audit()
 local r=root();local l=assert(layer());local a={parts=0,solids=0,models=0,lights=0,seats=0,primitiveMeshes=0,issues={},missingFloor={},metadataIssues={},bodySamples=0,floorRays=0,cornerChecks=0,externalChecks=0}
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={l};op.RespectCanCollide=false
 local function top(p)return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 local function check(n,cf,size,feet)
  for _,p in workspace:GetPartBoundsInBox(cf,size,op)do if (p.Transparency<.98 or p.CanCollide)and top(p)>feet+.55 then table.insert(a.issues,n..":"..p.Name)end end
 end
 a.envelopes=0;for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.envelopes+=1;check(p.Name,p.CFrame,p.Size,0)end end
 a.routes=0;for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routes+=1;check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),0)end end
 check("EightStudAxis",CFrame.new(3130,5,178.5),Vector3.new(8,10,66),0)
 for _,z in {146,211}do check("Crossover",CFrame.new(3130,4,z),Vector3.new(65,8,12),0)end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local function floor(n,p)
  a.floorRays+=1;local hit=workspace:Raycast(p+Vector3.new(0,.55,0),Vector3.new(0,-1.4,0),rp)
  if not hit or math.abs(hit.Position.Y-p.Y)>.55 then table.insert(a.missingFloor,n)end
 end
 -- Check actual candidate decoration, not only its collision subset, against all pre-existing visible geometry.
 local external=OverlapParams.new();external.FilterType=Enum.RaycastFilterType.Include;external.FilterDescendantsInstances={r};external.RespectCanCollide=false
 local ids={}
 for _,v in l:GetDescendants()do
  if v:IsA("Model")then
   a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","AllowedMin","AllowedMax"}do if v:GetAttribute(k)==nil then table.insert(a.metadataIssues,v.Name..":"..k)end end
   local id=v:GetAttribute("BundleId");if ids[id]then table.insert(a.metadataIssues,"Duplicate:"..id)end;ids[id]=true
  elseif v:IsA("BasePart")then
   a.parts+=1;if v.CanCollide then a.solids+=1 end;if v:IsA("Seat")then a.seats+=1 end
   if v.Transparency<.98 then
    a.externalChecks+=1
    for _,p in workspace:GetPartBoundsInBox(v.CFrame,v.Size,external)do if not p:IsDescendantOf(l) and (p.Transparency<.98 or p.CanCollide)and top(p)>.65 then table.insert(a.issues,"ExternalOverlap:"..v.Name..":"..p:GetFullName())end end
    local mn,mx=v.Parent:GetAttribute("AllowedMin"),v.Parent:GetAttribute("AllowedMax")
    for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
     local p=v.CFrame:PointToWorldSpace(v.Size*Vector3.new(sx,sy,sz)/2);a.cornerChecks+=1
     if p.X<mn.X-.015 or p.X>mx.X+.015 or p.Y<mn.Y-.015 or p.Y>mx.Y+.015 or p.Z<mn.Z-.015 or p.Z>mx.Z+.015 then table.insert(a.issues,"OutsidePocket:"..v.Name)end
    end end end
   end
  elseif v:IsA("SpecialMesh")then a.primitiveMeshes+=1;assert(v.MeshType==Enum.MeshType.Sphere and v.Scale==Vector3.one,"Native sphere proxy only")
  elseif v:IsA("Light")then a.lights+=1 end
 end
 op.FilterDescendantsInstances={r}
 for _,route in l["98_Access_Paths"]:GetChildren()do
  local pts=route:GetChildren();table.sort(pts,function(a,b)return a.Name<b.Name end)
  for i=1,#pts-1 do local v,w=pts[i].Value,pts[i+1].Value;local d=w-v;local side=Vector3.new(d.Z,0,-d.X).Unit;local n=math.ceil(d.Magnitude/.5)
   for j=0,n do local p=v:Lerp(w,j/n);a.bodySamples+=1;check(route.Name,CFrame.lookAt(p+Vector3.new(0,3.3,0),p+Vector3.new(0,3.3,0)+d),Vector3.new(3,5.8,.4),p.Y);for _,dx in {-1,0,1}do floor(route.Name,p+side*dx)end end
  end
 end
 a.scripts=0;for _,v in l:GetDescendants()do if v:IsA("LuaSourceContainer")then a.scripts+=1 end end
 assert(a.lights==0 and a.scripts==0,"No new lights or loops");a.renderFormSignature=renderFormSignature(l);return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.missingFloor==0 and #a.metadataIssues==0,"Audit failed")
 for _,k in {"VisualPass","ActualWalkingPass","SeatPass","RegressionsPass","RollbackPass","SourceMatch","RenderingReviewed"}do assert(e[k],"Missing evidence:"..k)end
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=layer()
 for _,m in layer():GetDescendants()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 layer():SetAttribute("Status","ACCEPTED_PROXY");root():SetAttribute("InstitutionElevation01AStatus","ACCEPTED_PROXY");return a
end
return I

