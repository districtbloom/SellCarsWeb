--!nocheck
-- Institution7A2 owns low landscape/public comfort only; all baseline geometry stays fixed.
local I={Version="2026-09-07.phase7a2.1"}
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","06_Atmosphere","02_Landscape_And_Comfort"
local C={steel=Color3.fromRGB(46,49,44),rust=Color3.fromRGB(125,76,47),edge=Color3.fromRGB(151,106,66),stone=Color3.fromRGB(156,140,111),dark=Color3.fromRGB(51,45,33),sage=Color3.fromRGB(96,113,87),blue=Color3.fromRGB(92,127,119),tip=Color3.fromRGB(125,146,114),straw=Color3.fromRGB(146,132,92),timber=Color3.fromRGB(139,103,64),metal=Color3.fromRGB(120,124,112),black=Color3.fromRGB(29,32,29),white=Color3.fromRGB(192,185,164)}
local function root()
 assert(game.PlaceId==125334614375606,"Wrong place")
 assert(not game:GetService("RunService"):IsRunning(),"Edit only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function layer()return root()["10_Institution_Fidelity_R1"][PHASE]:FindFirstChild(NAME)end
local function hash(rows)
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
local function signature(l)
 local rows={};for _,p in l:GetDescendants()do if p:IsA("BasePart")then
  local cf={};for _,v in {p.CFrame:GetComponents()}do local s=string.format("%.3f",v);if s=="-0.000"then s="0.000"end;table.insert(cf,s)end
  table.insert(rows,p:GetFullName().."|"..p.ClassName.."|"..table.concat(cf,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.CanCollide).."|"..tostring(p.Transparency))
 end end;return hash(rows)
end
local function group(l,n,role,first,ancestor,mn,mx)
 local m=Instance.new("Model");m.Name=n;m.Parent=l
 for k,v in {BundleId="Institution.Landscape."..n..".FidelityR1",FunctionId="EstateLandscape",ZoneId=n,FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="DECORATIVE",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY",AllowedMin=Vector3.new(unpack(mn)),AllowedMax=Vector3.new(unpack(mx))}do m:SetAttribute(k,v)end
 return m
end
local function part(m,n,x,y,z,w,h,d,c,mat,solid,rot,cls)
 local p=Instance.new(cls or "Part");p.Name=n;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity);p.Anchored=true
 p.Material=mat or Enum.Material.Metal;p.Color=c or C.steel;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0;p:SetAttribute("Phase7A2Geometry",true);p.Parent=m;return p
end
local function tube(m,n,a,b,diam,c,mat,solid)
 local p=part(m,n,(a.X+b.X)/2,(a.Y+b.Y)/2,(a.Z+b.Z)/2,(b-a).Magnitude,diam,diam,c,mat,solid)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
local function point(m,n,x,y,z)
 local p=part(m,n,x,y,z,.1,.1,.1,C.sage,Enum.Material.SmoothPlastic);p.Transparency=1;p.CanQuery=false;p:SetAttribute("AnchorKind","OPERATOR")
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=p;m:SetAttribute("InteractionAnchor",n);return p
end
local function path(l,n,pts)
 local f=l:FindFirstChild("98_Access_Paths")or Instance.new("Folder");f.Name="98_Access_Paths";f.Parent=l;local r=Instance.new("Folder");r.Name=n;r.Parent=f
 for i,v in pts do local p=Instance.new("Vector3Value");p.Name=string.format("%02d",i);p.Value=Vector3.new(unpack(v));p.Parent=r end
end
local function leaf(m,a,b,w,c)
 -- Thin triangular width silhouette, rather than a rectangular neon stalk.
 for _,sign in {-1,1}do
  local p=part(m,"TaperedLeaf",(a.X+b.X)/2,(a.Y+b.Y)/2,(a.Z+b.Z)/2,.055,w/2,(b-a).Magnitude,c,Enum.Material.SmoothPlastic,false,nil,"WedgePart")
  p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,sign*math.pi/2)*CFrame.new(0,w/4,0)
 end
end
local function rosette(m,x,y,z,s,phase)
 tube(m,"RosetteHeart",Vector3.new(x,y+.05*s,z),Vector3.new(x,y+.65*s,z),.28*s,C.sage,Enum.Material.SmoothPlastic,false)
 for i=1,7 do
  local a=i*math.pi*2/7+phase;local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local base=Vector3.new(x,y+.15*s,z)+dir*.08*s
  local bend=Vector3.new(x,y+(1.13+.12*math.sin(i))*s,z)+dir*.78*s
  local tip=Vector3.new(x,y+(.72+.15*math.cos(i))*s,z)+dir*1.42*s
  leaf(m,bend,base,.46*s,i%3==0 and C.sage or C.blue);leaf(m,bend,tip,.46*s,C.blue)
 end
 for i=1,3 do local a=i*2.094+phase
  leaf(m,Vector3.new(x,y+.25*s,z),Vector3.new(x+math.cos(a)*.43*s,y+1.72*s,z+math.sin(a)*.43*s),.28*s,C.tip)
 end
end
local function grass(m,x,z,s,phase)
 for i=1,5 do local a=i*1.256+phase
  leaf(m,Vector3.new(x,.2,z),Vector3.new(x+math.cos(a)*.8*s,.2+(1.1+.15*math.sin(i))*s,z+math.sin(a)*.8*s),.17*s,i%2==0 and C.straw or C.sage)
 end
end
local function stone(m,x,z,s,angle,ybase)
 local y=(ybase or .18)+.35*s
 part(m,"LocalLimestone",x,y,z,s,.45*s,.65*s,C.stone,Enum.Material.Limestone,false,CFrame.Angles(.08,angle,.08),"WedgePart")
 part(m,"LimestoneBrokenFace",x+.09*s,y-.04*s,z+.04*s,.8*s,.34*s,.72*s,C.stone,Enum.Material.Limestone,false,CFrame.Angles(.06,angle+.7,-.07),"WedgePart")
end
local function bed(l,n,z1,z2,index)
 local m=group(l,n,"STORY","PROFESSIONAL","Retained scrub and movable pots -> irrigated low desert planting in permanent gravel reserve",{3115.4,.08,z1},{3144.6,3.65,z2})
 local z=z1+(z2-z1)*.5
 rosette(m,3120.4,.18,z-4,1.5,.27*index);rosette(m,3140,.18,z+4,1.4,1.2+.4*index)
 rosette(m,3123,.18,z-1.2,.7,.8*index);rosette(m,3137.6,.18,z+7,.65,1.3*index)
 for _,v in {{3119,z+8,.8},{3122,z-10,.65},{3141,z-8,.7},{3139,z+11,.6}}do grass(m,v[1],v[2],v[3],index)end
 for i=1,5 do local x=i<4 and 3120+i*.7 or 3138+(i-4)*1.2;local zz=i<4 and z-7.5+i*.35 or z+1+i*.3;stone(m,x,zz,.7+(i%3)*.25,.4*i+index)end
 for _,x in {3118,3142.2}do
  part(m,"IrrigationCleanout",x,.25,z,1.2,.14,1.1,C.steel,Enum.Material.Metal)
  part(m,"CleanoutLiftSlot",x,.329,z,.4,.018,.08,C.black)
 end
 m:SetAttribute("OpenAxisMinX",3126);m:SetAttribute("OpenAxisMaxX",3134);m:SetAttribute("BotanicalIntent","LOW_ROSETTE_SAGE_GRASS_PROXY_NOT_FINAL_BOTANICAL_ASSET")
end
local function planter(l,x,z,size,court)
 local n="Planter_"..x.."_"..z
 local m=group(l,n,"SUPPORT","WORKING","Improvised planter -> rolled weathering-steel pot with low sculpted desert foliage",{x-size/2,-.05,z-size/2},{x+size/2,4.55,z+size/2})
 local h=court and 1.495 or 1.43
 part(m,"WeatheredPotBody",x,h/2,z,size-.08,h,size-.08,C.rust,Enum.Material.CorrodedMetal,false)
 part(m,"SoilRecess",x,h+.025,z,size-.33,.055,size-.33,C.dark,Enum.Material.Ground)
 for _,sign in {-1,1}do
  part(m,"RolledPotRim",x+sign*(size/2-.075),h+.06,z,.12,.14,size,C.edge)
  part(m,"RolledPotRim",x,h+.06,z+sign*(size/2-.075),size-.12,.14,.12,C.edge)
 end
 rosette(m,x,h+.08,z,1.08,(x+z)*.17)
 for i=1,3 do stone(m,x+math.cos(i*2.09)*1.18,z+math.sin(i*2.09)*1.18,.22,i,h+.06)end
 -- Pot keeps the exact original collider. No hollow visible pot invites player occupation.
 m:SetAttribute("RetainedOriginalCollision",true)
 m:SetAttribute("BotanicalIntent","TAPERED_BLUE_GREEN_ROSETTE")
end
local function litter(l,x,n)
 local m=group(l,n,"UTILITY","WORKING","Single rough litter bin -> separated courtyard litter and recycling station",{x-1.65,.08,390.4},{x+1.65,4.6,392.6})
 m:SetAttribute("CollisionClass","EQUIPMENT")
 part(m,"RaisedSteelFoot",x,.27,391.5,2.85,.35,1.6,C.steel,nil,true)
 part(m,"TwinLinerBody",x,1.92,391.5,3,3.1,1.7,C.steel,nil,true)
 for _,dx in {-1.48,0,1.48}do part(m,"ServiceDoorJoint",x+dx,1.85,392.38,.055,2.65,.035,C.black)end
 for _,dx in {-.75,.75}do
  part(m,"DepositShadow",x+dx,3.34,392.38,1.2,.65,.07,C.black)
  part(m,"AngledDepositFlap",x+dx,3.35,392.44,1.02,.33,.07,dx<0 and C.metal or C.sage,nil,false,CFrame.Angles(-.22,0,0))
  part(m,"Latch",x+dx+.35,1.9,392.41,.12,.32,.09,C.metal)
 end
 for _,dx in {-1.4,1.4}do part(m,"HoodSupport",x+dx,3.6,391.5,.15,.5,1.65,C.steel)end
 part(m,"RearHoodSupport",x,3.6,390.7,2.8,.5,.12,C.steel)
 part(m,"RainCap",x,3.89,391.5,3.2,.18,2.1,C.metal)
 part(m,"CapFall",x,3.95,391.5,3.1,.06,1.9,C.steel,nil,false,CFrame.Angles(.04,0,0))
 for _,dx in {-1.1,1.1}do for _,z in {390.9,392.1}do part(m,"BaseFastener",x+dx,.47,z,.18,.09,.18,C.metal)end end
 point(m,"DepositApproach",x,.095,394.5)
 path(l,n.."Approach",{{x,.095,399},{x,.095,394.5}})
 m:SetAttribute("ShadeOwner","Existing Elevated_Collector_Hall overhang; no new canopy")
end
local function service(l)
 local m=group(l,"Screened_Recycling_And_Service_Store","UTILITY","DEDICATED","Loose covered waste containers -> sorted screened service collection",{3215.8,.08,479.8},{3234.2,6.6,488.2})
 m:SetAttribute("CollisionClass","EQUIPMENT")
 part(m,"ContainedServiceSlab",3225,.23,484,18,.2,8,C.stone,Enum.Material.Concrete,true)
 for _,x in {3216.2,3233.8}do
  for _,z in {480.2,487.7}do
   part(m,"ScreenPost",x,2.65,z,.32,5,.32,C.steel,nil,true)
   part(m,"PostBase",x,.43,z,.65,.12,.65,C.metal)
  end
  for y=.8,4.7,.55 do part(m,"SideTimberLouvre",x,y,484,.18,.38,7.4,C.timber,Enum.Material.WoodPlanks,false,CFrame.Angles(0,0,.17))end
 end
 for y=.8,4.7,.55 do part(m,"BackTimberLouvre",3225,y,480.2,17.6,.38,.18,C.timber,Enum.Material.WoodPlanks,false,CFrame.Angles(.17,0,0))end
 for _,x in {3219.2,3225,3230.8}do
  local col=x==3225 and C.sage or C.steel
  part(m,"WheeledContainer",x,2.2,483.7,3.6,3.35,3.2,col,nil,true)
  part(m,"LiddedContainerTop",x,4,483.7,3.9,.22,3.5,C.black)
  tube(m,"LidHinge",Vector3.new(x-1.7,4.15,482.2),Vector3.new(x+1.7,4.15,482.2),.17,C.metal)
  for _,dx in {-1.84,1.84}do for _,z in {482.7,484.9}do
   tube(m,"AxleWheel",Vector3.new(x+dx-.14,.78,z),Vector3.new(x+dx+.14,.78,z),.9,C.black,nil,false)
  end end
  tube(m,"PullHandle",Vector3.new(x-1.1,3.7,485.4),Vector3.new(x+1.1,3.7,485.4),.15,C.metal)
  for _,dx in {-.85,.85}do part(m,"PressedContainerRib",x+dx,2.2,485.33,.1,2.2,.045,C.metal)end
 end
 part(m,"StowedLongHandle",3217.1,3,484,.13,5,.13,C.timber,Enum.Material.Wood)
 part(m,"BroomHead",3217.1,.58,484,1,.3,.4,C.straw)
 point(m,"CollectionServiceApproach",3225,.095,490)
 path(l,"RearServiceApproach",{{3182,.095,399},{3182,.095,440},{3182,.095,490},{3225,.095,490}})
 for i,x in {3219.2,3225,3230.8}do
  point(m,"ContainerService_"..i,x,.33,487.8)
  path(l,"ContainerService_"..i,{{x,.095,490},{x,.33,487.8}})
 end
 m:SetAttribute("VehicleCollectionRoute","NOT_PROVIDED_PEDESTRIAN_ONLY")
end
local function build(l)
 for i,p in {{104.5,137.5},{154.5,202.5},{219.5,267.5},{284.5,339.5}}do bed(l,"Desert_Bed_"..i,p[1],p[2],i)end
 -- Two inherited front boundary pots overlap accepted walls/bollards. Leave those
 -- originals untouched until their collider ownership is reconciled; do not copy
 -- the clash into a new asset or leave an invisible collider after relocating it.
 for _,p in {{3007,350},{3253,350},{3010,493},{3250,493}}do planter(l,p[1],p[2],3.52,false)end
 planter(l,3082,387,3.68,true);planter(l,3178,387,3.68,true)
 litter(l,3082,"West_Public_Litter");litter(l,3178,"East_Public_Litter");service(l)
end
function I.Uninstall()
 local l=layer();if l then
  local f=l:FindFirstChild("99_Restore");if f then for _,v in f:GetChildren()do assert(v.Value,"Lost original planter");v.Value.Transparency=v:GetAttribute("Transparency")end end;l:Destroy()
 end
 root():SetAttribute("InstitutionFidelityPhase7A2LandscapeStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase7A1GroundStatus")=="ACCEPTED","Accepted ground required")
 I.Uninstall();local l=Instance.new("Model");l.Name=NAME;l.Parent=root()["10_Institution_Fidelity_R1"][PHASE];l:SetAttribute("Version",I.Version)
 local f=Instance.new("Folder");f.Name="99_Restore";f.Parent=l
 local ok,err=pcall(function()
  local realm=root()["09_Institution_Production_B"]["03_Estate_Identity"]["08_Campus_Identity_Public_Realm"]
  for _,m in realm:GetChildren()do if (m.Name=="BoundaryLandscape" and m:FindFirstChild("Planter").Position.Z>300)or m.Name=="CourtyardPlant"then for _,p in m:GetDescendants()do if p:IsA("BasePart")then
   assert(p.Transparency<.98,"Selected plant already hidden; ownership conflict")
   local v=Instance.new("ObjectValue");v.Name=string.format("Original_%02d",#f:GetChildren()+1);v.Value=p;v:SetAttribute("Transparency",p.Transparency);v.Parent=f;p.Transparency=1
  end end end end
  assert(#f:GetChildren()==36,"Unexpected original plant scope");build(l)
 end)
 if not ok then I.Uninstall();error(err)end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase7A2LandscapeStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local a={signature=signature(l),parts=0,solids=0,models=0,lights=0,issues={},missingFloor={},metadataIssues={},paths=0,bodySamples=0,floorSamples=0,standingVolumes=0,pocketCorners=0}
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={l};op.RespectCanCollide=false
 local function top(p)return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 local function check(n,cf,s,feet)
  for _,p in workspace:GetPartBoundsInBox(cf,s,op)do if p.Transparency<.98 and top(p)>feet+.55 then table.insert(a.issues,n..":"..p:GetFullName())end end
 end
 a.protectedEnvelopes=0;for _,p in root()["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedEnvelopes+=1;check(p.Name,p.CFrame,p.Size,0)end end
 a.originalRoutes=0;for _,p in root()["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.originalRoutes+=1;check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),0)end end
 for _,z in {121,178.5,243.5,312}do check("CentralOpenAxis",CFrame.new(3130,3.4,z),Vector3.new(8,6,33),0)end
 check("WashLaunch",CFrame.new(3105,3.2,97),Vector3.new(10.58,6.4,40.94),0)
 check("OwnerDrive",CFrame.new(3218,3.6,54),Vector3.new(13.3001,6.4,90),0)
 for _,x in {3092,3168}do check("ExistingCustomer",CFrame.new(x,3.3,387),Vector3.new(4,5.8,2),.095)end
 op.FilterDescendantsInstances={root()}
 -- Visual geometry is checked against all existing visible geometry, including
 -- non-collidable wall finishes; a clear traffic envelope alone is insufficient.
 a.externalPropChecks=0
 for _,p in l:GetDescendants()do if p:IsA("BasePart") and p.Transparency<.98 then
  a.externalPropChecks+=1
  for _,v in workspace:GetPartBoundsInBox(p.CFrame,p.Size,op)do
   if not v:IsDescendantOf(l) and v.Transparency<.98 and top(v)>.65 then
    table.insert(a.issues,"ExternalPropOverlap:"..p:GetFullName()..":"..v:GetFullName())
   end
  end
 end end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={root()};rp.RespectCanCollide=true
 local function floor(n,v)
  a.floorSamples+=1;local hit=workspace:Raycast(v+Vector3.new(0,.55,0),Vector3.new(0,-1.4,0),rp)
  if not hit or math.abs(hit.Position.Y-v.Y)>.55 then table.insert(a.missingFloor,n..":"..tostring(v))end
 end
 for _,route in l["98_Access_Paths"]:GetChildren()do
  a.paths+=1;local pts=route:GetChildren();table.sort(pts,function(a,b)return a.Name<b.Name end)
  for i=1,#pts-1 do local v,w=pts[i].Value,pts[i+1].Value;local d=w-v;local side=Vector3.new(d.Z,0,-d.X).Unit;local count=math.max(1,math.ceil(d.Magnitude/.6))
   for j=0,count do local p=v:Lerp(w,j/count);a.bodySamples+=1;check(route.Name,CFrame.lookAt(p+Vector3.new(0,3.3,0),p+Vector3.new(0,3.3,0)+d),Vector3.new(3,5.8,.4),p.Y);for _,dx in {-1,0,1}do floor(route.Name,p+side*dx)end end
  end
 end
 local ids={}
 for _,m in l:GetDescendants()do
  if m:IsA("Model")then
   a.models+=1;for _,k in {"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","AllowedMin","AllowedMax"}do if m:GetAttribute(k)==nil then table.insert(a.metadataIssues,m.Name..":"..k)end end
   local id=m:GetAttribute("BundleId");if ids[id]then table.insert(a.metadataIssues,"Duplicate:"..id)end;ids[id]=true
   local mn,mx=m:GetAttribute("AllowedMin"),m:GetAttribute("AllowedMax")
   for _,sx in {mn.X,mx.X}do for _,sz in {mn.Z,mx.Z}do floor(m.Name,Vector3.new(sx,.095,sz))end end
  elseif m:IsA("BasePart")then
   a.parts+=1;if m.CanCollide then a.solids+=1 end
   if m:GetAttribute("AnchorKind")=="OPERATOR"then a.standingVolumes+=1;check(m.Name,CFrame.new(m.Position+Vector3.new(0,3.3,0)),Vector3.new(3,5.8,3),m.Position.Y);floor(m.Name,m.Position)end
   if m.Transparency<.98 then
    local mn,mx=m.Parent:GetAttribute("AllowedMin"),m.Parent:GetAttribute("AllowedMax")
    for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
     a.pocketCorners+=1;local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2)
     if v.X<mn.X-.015 or v.X>mx.X+.015 or v.Y<mn.Y-.015 or v.Y>mx.Y+.015 or v.Z<mn.Z-.015 or v.Z>mx.Z+.015 then table.insert(a.issues,"OutsidePocket:"..m:GetFullName())end
    end end end
   end
  elseif m:IsA("Light")then a.lights+=1 end
 end
 a.hiddenOriginals=0;for _,v in l["99_Restore"]:GetChildren()do a.hiddenOriginals+=1;if not v.Value or v.Value.Transparency~=1 then table.insert(a.issues,"RestorationReference")end end
 local mod=game.ServerStorage.SellCarsV5InstitutionFidelityPhase7A1GroundInstaller:Clone();a.ground=require(mod).Audit();mod:Destroy()
 assert(a.lights==0,"No active lights in landscape batch")
 return a
end
function I.Accept(e)
 local a=I.Audit();for _,v in {a,a.ground}do assert(#v.issues==0 and #v.missingFloor==0 and #v.metadataIssues==0,"Landscape audit incomplete")end
 assert(e.VisualPass and e.ActualWalkingPass and e.RegressionsPass and e.RollbackPass and e.SourceMatch and e.RenderingReviewed and e.RoutePass,"Evidence missing")
 local f=Instance.new("Folder");f.Name="97_Evidence";f.Parent=layer();for k,v in e do f:SetAttribute(k,v)end
 for _,m in layer():GetDescendants()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase7A2LandscapeStatus","ACCEPTED");return a
end
return I

