--!nocheck
-- Phase 6C owns estate identity only; accepted districts and circulation are read-only.
local I={Version="2026-09-07.phase6c.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","05_Prestige_And_Public_Realm","04_Estate_Identity"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.EstateIdentity."..n..".FidelityR1",FunctionId="CampusIdentity",ZoneId="EstateIdentity",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase6CEstateGeometry",true);p.Parent=m;return p
end
local function cyl(m,n,x,y,z,length,diam,col,axis,solid)
 local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
 local p=box(m,n,x,y,z,length,diam,diam,col,M,solid,rot);p.Shape=Enum.PartType.Cylinder;return p
end
local function pipe(m,n,a,b,diam,col)
 local d=b-a;local p=box(m,n,(a.X+b.X)/2,(a.Y+b.Y)/2,(a.Z+b.Z)/2,d.Magnitude,diam,diam,col,M,false)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
local function point(m,n,x,y,z,kind)
 local p=box(m,n,x,y,z,.1,.1,.1,C.Green,P,false);p.Transparency=1;p.CanQuery=false;p:SetAttribute("AnchorKind",kind)
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=p;m:SetAttribute(kind=="FX" and "FXSocket" or "InteractionAnchor",n);return p
end
local function path(owner,n,points)
 local f=owner:FindFirstChild("98_Access_Paths") or Instance.new("Folder");f.Name="98_Access_Paths";f.Parent=owner
 local p=Instance.new("Folder");p.Name=n;p.Parent=f
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],v[2],v[3]);a.Parent=p end
end




local function textFace(p,words,face)
 local g=Instance.new("SurfaceGui");g.Name="Face";g.Face=face or Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=35;g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=words;t.TextColor3=C.WarmWhite;t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=g
end
local function light(m,n,x,y,z,w,range,brightness)
 local p=box(m,n,x,y,z,w,.16,.6,C.WarmWhite,Enum.Material.Neon,false)
 local a=Instance.new("SurfaceLight");a.Name="TaskIllumination";a.Face=Enum.NormalId.Bottom;a.Angle=110;a.Range=range;a.Brightness=brightness;a.Shadows=false;a.Color=C.WarmWhite;a.Parent=p
 return p
end

local function bounded(m,x1,x2,z1,z2,y2)
 m:SetAttribute("AllowedMin",Vector3.new(x1,-.2,z1));m:SetAttribute("AllowedMax",Vector3.new(x2,y2,z2));return m
end
local function bolt(m,x,y,z)
 cyl(m,"AnchorWasher",x,y,z,.08,.3,C.Galvanized,"Y",false)
 cyl(m,"AnchorNut",x,y+.11,z,.18,.17,C.Steel,"Y",false)
end
local function gateway(l)
 local m=bounded(group(l,"Coachworks_Gateway","ARCHITECTURE","WORKING","Roadside timber sign -> steel entry frame -> formed coachworks gateway"),3108,3152,-17.85,-14,18.15)
 for _,x in ipairs({3109,3151}) do
  box(m,"ColumnWeb",x,9,-16,.3,18,2.4,C.Charcoal,M,true)
  for _,dx in ipairs({-.7,.7}) do box(m,"ColumnFlange",x+dx,9,-16,.25,18,2.5,C.Charcoal,M,true) end
  box(m,"BasePlate",x,.18,-16,2,.22,3,C.Steel,M,false)
  for _,dx in ipairs({-.72,.72}) do for _,dz in ipairs({-1.13,1.13}) do bolt(m,x+dx,.34,-16+dz) end end
  for _,z in ipairs({-17.27,-14.73}) do
   box(m,"ColumnConnectionPlate",x,16.6,z,1.6,2.6,.12,C.Steel,M,false)
   for _,dy in ipairs({-.8,0,.8}) do
    local b=cyl(m,"ConnectionBolt",x,16.6+dy,z,.15,.2,C.Stainless,"Z",false)
   end
  end
 end
 for _,y in ipairs({16.55,18.05}) do box(m,"BeamFlange",3130,y,-16,44,.15,3,C.Charcoal,M,false) end
 box(m,"BeamWeb",3130,17.3,-16,42,1.35,.3,C.Bronze,M,false)
 for _,x in ipairs({3117,3130,3143}) do box(m,"BeamStiffener",x,17.3,-16,.16,1.35,2.7,C.Steel,M,false) end
 for _,x in ipairs({3121,3139}) do box(m,"SignHanger",x,15.7,-17.62,.14,1.5,.14,C.Steel,M,false) end
 local sign=box(m,"CoachworksWordmark",3130,14.9,-17.63,25,2,.22,C.Charcoal,M,false)
 textFace(sign,"DESERT CUSTOMS",Enum.NormalId.Front)
 box(m,"WordmarkLowerEdge",3130,13.86,-17.6,25.2,.14,.3,C.Bronze,M,false)
 point(m,"GatewayFixtureSocket",3130,17.9,-16,"FX")
 m:SetAttribute("VisitorParkingBoundary","EXISTING_PIER_CORNER_OVERLAP_PENDING_PHASE8")
end
local function tower(l)
 local m=bounded(group(l,"Roadside_Coachworks_Pylon","ARCHITECTURE","DEDICATED","Roadside painted nameplate -> permanent framed status pylon"),3255.4,3259.6,-2.1,6.1,28.5)
 box(m,"StoneFooting",3257.5,.55,2,3,1.1,7,C.Concrete,Enum.Material.Limestone,true)
 for _,x in ipairs({3256.15,3258.85}) do
  box(m,"SteelUpright",x,14.5,2,.35,27,6.6,C.Charcoal,M,true)
  for _,z in ipairs({-.5,4.5}) do bolt(m,x,1.16,z) end
 end
 box(m,"PylonBackWeb",3257.5,13,2,2.4,23,.35,C.Steel,M,true)
 for _,y in ipairs({5,11,17}) do
  box(m,"CladdingPanel",3255.64,y,2,.25,5.65,6.5,C.Steel,M,false)
  box(m,"BronzePanelJoint",3255.47,y-2.87,2,.12,.12,6.5,C.Bronze,M,false)
 end
 for _,y in ipairs({2.5,3.1,3.7}) do box(m,"LowerVent",3255.46,y,2,.1,.18,3.5,C.Charcoal,M,false) end
 box(m,"ServiceHatch",3259.02,3.4,2,.14,3.5,2.6,C.Charcoal,M,false)
 box(m,"ServiceLatch",3259.13,3.4,3,.16,.7,.15,C.Stainless,M,false)
 box(m,"TopCassette",3257.5,23.8,2,3.6,8.6,7.7,C.Charcoal,M,true)
 box(m,"DripCap",3257.5,28.25,2,4.1,.25,8.1,C.Bronze,M,false)
 -- Open wheel crest built on the west face, readable without a luminous block.
 local cy,cz=23.8,2
 for i=1,20 do local a=(i-.5)*math.pi*2/20
  local p=box(m,"CrestRim",3255.62,cy+math.cos(a)*2.8,cz+math.sin(a)*2.8,.2,.32,.9,C.Bronze,M,false)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(a,0,0)
 end
 cyl(m,"CrestHub",3255.58,cy,cz,.25,.9,C.Galvanized,"X",false)
 for i=1,5 do local a=i*math.pi*2/5
  pipe(m,"CrestSpoke",Vector3.new(3255.58,cy+math.cos(a)*.55,cz+math.sin(a)*.55),Vector3.new(3255.58,cy+math.cos(a)*2.4,cz+math.sin(a)*2.4),.18,C.Galvanized)
 end
 local plaque=box(m,"RoadMonogram",3257.5,13.4,-1.48,2.7,3.5,.18,C.Charcoal,M,false)
 textFace(plaque,"DC",Enum.NormalId.Front)
 local nameplate=box(m,"WestNameplate",3255.46,12.4,2,.1,1.7,6.1,C.Charcoal,M,false)
 textFace(nameplate,"DESERT CUSTOMS",Enum.NormalId.Left)
 point(m,"PylonFixtureSocket",3257.5,27.8,2,"FX")
end
local function bench(l,n,x,yaw)
 local m=bounded(group(l,n,"SUPPORT","WORKING","Rough timber waiting bench -> repaired slatted steel-and-timber courtyard seat"),x-4,x+4,383.5,392.9,5.2)
 local cf=CFrame.new(x,.095,388)*CFrame.Angles(0,math.rad(yaw),0)
 local function p(k,dx,dy,dz,w,h,d,c,mat,solid)
  local v=cf:PointToWorldSpace(Vector3.new(dx,dy,dz+.4));local o=box(m,k,v.X,v.Y,v.Z,w,h,d,c,mat,solid);o.CFrame=cf*CFrame.new(dx,dy,dz+.4);return o
 end
 for _,dx in ipairs({-2.6,2.6}) do
  p("CastFoot",dx,.13,0,1.2,.26,2.7,C.Charcoal,M,false)
  p("BenchLeg",dx,1.1,0,.35,2,1.7,C.Charcoal,M,true)
  p("BackBracket",dx,2.6,1.05,.22,3,.3,C.Steel,M,true)
 end
 for z=-.95,.96,.38 do p("SeatSlat",0,2.05,z,7,.28,.3,C.Timber,Enum.Material.Wood,true) end
 for y=2.55,3.66,.5 do p("BackSlat",0,y,1.13,7,.35,.25,C.Timber,Enum.Material.Wood,true) end
 for _,dx in ipairs({-3.1,3.1}) do
  p("ArmPost",dx,2.35,.2,.14,1.2,.14,C.Bronze,M,false)
  p("ArmRail",dx,2.95,0,.18,.18,2.1,C.Bronze,M,false)
 end
 point(m,"SeatingApproach",x+(x<3130 and 3.1 or -3.1),.095,391.2,"VIEWING")
 path(l,n.."Approach",{{x,.095,393.5},{x+(x<3130 and 3.1 or -3.1),.095,393.5},{x+(x<3130 and 3.1 or -3.1),.095,391.2}})
end
local function sculpture(l)
 local m=bounded(group(l,"Rough_To_Remarkable_Sculpture","STORY","INSTITUTION","Original repaired wheel and formed panel -> permanent public craft sculpture"),3126.5,3133.5,384.5,391.5,9.5)
 m:SetAttribute("InheritanceRule","NEW");m:SetAttribute("NarrativeBinding","CRAFT_STUDY_NOT_ACTUAL_SOLD_CAR")
 box(m,"RetainedSocketPlinth",3130,.65,388,7,1.1,7,C.Concrete,Enum.Material.Limestone,true)
 box(m,"PlinthCap",3130,1.23,388,6.8,.12,6.8,C.Charcoal,M,false)
 for _,x in ipairs({3128.6,3131.4}) do
  box(m,"WheelStand",x,2.1,388,.25,1.7,2.4,C.Steel,M,true)
  for _,z in ipairs({387.15,388.85}) do bolt(m,x,1.34,z) end
 end
 local cx,cy,cz=3130,4.75,388
 for i=1,24 do local a=(i-.5)*math.pi*2/24
  local left=math.cos(a)<0
  local p=box(m,"TireSegment",cx+math.cos(a)*2.65,cy+math.sin(a)*2.65,cz,.72,.5,1.35,C.Rubber,P,false)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,0,a+math.pi/2)
  local rim=box(m,"RimSegment",cx+math.cos(a)*2.15,cy+math.sin(a)*2.15,cz-.75,.57,.22,.18,left and C.OldConcrete or C.Stainless,left and Enum.Material.CorrodedMetal or M,false)
  rim.CFrame=CFrame.new(rim.Position)*CFrame.Angles(0,0,a+math.pi/2)
 end
 cyl(m,"WheelHub",cx,cy,cz-.85,.32,1.0,C.Bronze,"Z",false)
 for i=1,5 do local a=i*math.pi*2/5
  local c=math.cos(a)<0 and C.Steel or C.Stainless
  pipe(m,"WheelSpoke",Vector3.new(cx+math.cos(a)*.55,cy+math.sin(a)*.55,cz-.77),Vector3.new(cx+math.cos(a)*1.95,cy+math.sin(a)*1.95,cz-.77),.28,c)
  cyl(m,"HubFastener",cx+math.cos(a)*.35,cy+math.sin(a)*.35,cz-1.05,.1,.12,C.Stainless,"Z",false)
 end
 for i=1,14 do local a=math.pi*(i-.5)/14
  local p=box(m,"FormedFender",cx+math.cos(a)*3.07,cy+math.sin(a)*3.07,cz+.5,.75,.23,1.6,math.cos(a)<-.15 and C.Brick or C.Red,math.cos(a)<-.15 and Enum.Material.CorrodedMetal or M,false)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,0,a+math.pi/2)
 end
 local plaque=box(m,"CraftCaption",3130,1.75,384.73,5.7,.85,.12,C.Charcoal,M,false);textFace(plaque,"ROUGH TO REMARKABLE")
 point(m,"SculptureView",3130,.095,382.7,"VIEWING")
 path(l,"SculptureApproach",{{3118,.095,382.7},{3130,.095,382.7}})
end
local function legacy(l)
 local m=bounded(group(l,"Original_Yard_Sign_Study","STORY","BIRTH","First hand-painted roadside board retained as a courtyard relic"),3097,3103,385.9,390.1,6.5)
 m:SetAttribute("InheritanceRule","LEGACY");m:SetAttribute("HistoricalSource","DESIGN_ANCESTOR_NOT_LIVE_PLAYER_RECORD")
 box(m,"RelicStoneBase",3100,.35,388,6,.5,4,C.Concrete,Enum.Material.Limestone,true)
 for _,x in ipairs({3097.5,3102.5}) do box(m,"OriginalTimberPost",x,3,388,.35,5.5,.4,C.Timber,Enum.Material.Wood,true) end
 local face=box(m,"SalvagedPaintedBoard",3100,4.3,387.7,5.7,2.5,.18,C.Brick,Enum.Material.CorrodedMetal,false)
 textFace(face,"SELL CARS")
 for _,x in ipairs({3097.3,3102.7}) do for _,y in ipairs({3.35,5.25}) do cyl(m,"OldBoardFixing",x,y,387.55,.13,.17,C.Steel,"Z",false) end end
 for _,z in ipairs({387.3,388.7}) do box(m,"NewConservationRail",3100,2.25,z,5.7,.17,.2,C.Charcoal,M,false) end
 local caption=box(m,"RelicCaption",3100,1.2,386.1,5,.65,.12,C.Charcoal,M,false);textFace(caption,"THE ROADSIDE BEGINNING")
 point(m,"RelicView",3100,.095,383.7,"VIEWING")
 path(l,"RelicApproach",{{3110,.095,383.7},{3100,.095,383.7}})
end
local function marker(l,n,x,z,label)
 local m=bounded(group(l,n,"SUPPORT","WORKING","Handwritten direction board -> compact framed estate marker"),x-3.7,x+3.7,z-5,z+.65,5.8)
 box(m,"SignFoot",x,.22,z,.8,.25,.8,C.Charcoal,M,false)
 box(m,"SignPost",x,2.4,z,.3,4.6,.35,C.Steel,M,true)
 box(m,"MarkerFrame",x,4.5,z,7,1.9,.3,C.Bronze,M,false)
 local panel=box(m,"DirectionFace",x,4.5,z-.18,6.65,1.55,.08,C.Charcoal,M,false);textFace(panel,label)
 box(m,"MarkerCap",x,5.5,z,7.2,.12,.55,C.Charcoal,M,false)
 point(m,"DirectionView",x,.095,z-3.1,"VIEWING")
 path(l,n.."Approach",{{x-3,.095,z-3.1},{x,.095,z-3.1}})
end
local function build(l)
 gateway(l);tower(l);bench(l,"Courtyard_West_Seat",3089,-90);bench(l,"Courtyard_East_Seat",3171,90);sculpture(l);legacy(l)
 marker(l,"Appraisal_Waymarker",3084,6.5,"APPRAISAL")
 marker(l,"Sales_Waymarker",3144,6.5,"SALES / DELIVERY")
 marker(l,"Owner_Waymarker",3248,6.5,"PRIVATE GARAGE")
 marker(l,"Parts_Waymarker",3009,407,"PARTS / RECEIVING")
 marker(l,"Operations_Waymarker",3250,407,"STAFF / OPERATIONS")
end
local function suppress(owner,target)
 local rs=owner:FindFirstChild("90_Restoration") or Instance.new("Folder");rs.Name="90_Restoration";rs.Parent=owner
 local list=target:GetDescendants();table.insert(list,1,target)
 for _,o in ipairs(list) do if o:IsA("BasePart") or o:IsA("Light") or o:IsA("SurfaceGui") or o:IsA("BillboardGui") then
  local r=Instance.new("ObjectValue");r.Name="Saved_"..o.Name;r.Value=o;r.Parent=rs
  if o:IsA("BasePart") then
   for _,k in ipairs({"Transparency","CanCollide","CanTouch","CanQuery","CastShadow"}) do r:SetAttribute(k,o[k]) end
   o.Transparency=1;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
  else r:SetAttribute("Enabled",o.Enabled);o.Enabled=false end
 end end
end
local function signature(l)
 local rows={};for _,p in ipairs(l:GetDescendants()) do if p:IsA("BasePart") then
  local cf={};for _,v in ipairs({p.CFrame:GetComponents()}) do local n=string.format("%.3f",v);if n=="-0.000" then n="0.000" end;table.insert(cf,n) end
  table.insert(rows,p:GetFullName().."|"..table.concat(cf,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.Transparency))
 end end;table.sort(rows);local h=5381;for _,s in ipairs(rows) do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
function I.Uninstall()
 local l=layer();if l then
  local rs=l:FindFirstChild("90_Restoration");if rs then for _,r in ipairs(rs:GetChildren()) do if r.Value then for k,v in pairs(r:GetAttributes()) do r.Value[k]=v end end end end
  l:Destroy()
 end
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);if p and #p:GetChildren()==0 then p:Destroy() end
 root():SetAttribute("InstitutionFidelityPhase6CEstateStatus",nil);return true
end




function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase6B2HQStatus")=="ACCEPTED","Accepted HQ art required")
 I.Uninstall();local p=root()["10_Institution_Fidelity_R1"][PHASE];local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local realm=root()["09_Institution_Production_B"]["03_Estate_Identity"]["08_Campus_Identity_Public_Realm"]
  local names={GatewayPier=true,GatewayBeam=true,GatewaySign=true,LandmarkTower=true,TowerBlade=true,TowerCrest=true,Transformation_Sculpture=true,CourtyardBench=true,Wayfinding=true}
  for _,d in realm:GetChildren() do if names[d.Name] then suppress(l,d) end end
  build(l)
 end)
 if not ok then I.Uninstall();error(err)end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase6CEstateStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,missing,meta,ids={},{},{},{}
 local stats={parts=0,models=0,lights=0,solids=0,paths=0,standingVolumes=0,bodySamples=0,floorSamples=0,issues=issues,missingFloor=missing,metadataIssues=meta,signature=signature(l)}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function top(p)return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 local function check(n,cf,size,feet)
  for _,p in workspace:GetPartBoundsInBox(cf,size,params) do if p.Transparency<.98 and top(p)>feet+.55 then table.insert(issues,n..": "..p:GetFullName()) end end
 end
 for _,p in root()["03_Protected_Clearances"]:GetChildren() do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size,0) end end
 for _,p in root()["02_Vehicle_Routes"]:GetDescendants() do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),0) end end
 check("WashParallelPairLaunch",CFrame.new(3105,3.2,97),Vector3.new(10.58,6.4,40.94),0)
 for i,p in ipairs({{3104,30},{3156,30},{3104,56},{3156,56},{3144,84},{3116,84}}) do check("SalesCar"..i,CFrame.new(p[1],4.1,p[2]),Vector3.new(10.58,6.4,18.94),0)end
 for i,p in ipairs({{3203,28},{3233,28},{3203,56},{3233,56},{3203,84},{3233,84}}) do check("OwnerCar"..i,CFrame.new(p[1],3.6,p[2]),Vector3.new(13.3001,6.4,19.94),0)end
 check("OwnerDrive",CFrame.new(3218,3.6,54),Vector3.new(13.3001,6.4,90),0)
 for _,x in ipairs({3092,3168}) do check("ExistingCourtyardCustomer",CFrame.new(x,3.3,387),Vector3.new(4,5.8,2),.095)end
 params.FilterDescendantsInstances={root()};local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={root()};rays.RespectCanCollide=true
 for _,route in l["98_Access_Paths"]:GetChildren() do
  stats.paths+=1;local points=route:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value;local d=b-a;local side=Vector3.new(d.Z,0,-d.X).Unit;local count=math.max(1,math.ceil(d.Magnitude/.6))
   for j=0,count do local v=a:Lerp(b,j/count);stats.bodySamples+=1
    check(route.Name,CFrame.lookAt(v+Vector3.new(0,3.3,0),v+Vector3.new(0,3.3,0)+d),Vector3.new(3,5.8,.4),v.Y)
    for _,dx in ipairs({-1,0,1}) do stats.floorSamples+=1;local q=v+side*dx;local hit=workspace:Raycast(q+Vector3.new(0,.65,0),Vector3.new(0,-1.4,0),rays);if not hit or math.abs(hit.Position.Y-v.Y)>.55 then table.insert(missing,route.Name..":"..tostring(q)) end end
   end
  end
 end
 for _,m in l:GetDescendants() do
  if m:IsA("Model") then stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","AllowedMin","AllowedMax"}) do if m:GetAttribute(k)==nil then table.insert(meta,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(meta,"Duplicate:"..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do local n=m:GetAttribute(k);if n and n~="" and not m:FindFirstChild(n,true) then table.insert(meta,m.Name..":"..k.." unresolved")end end
  elseif m:IsA("BasePart") then
   stats.parts+=1;if m.CanCollide then stats.solids+=1 end
   local anchor=m:GetAttribute("AnchorKind")
   if anchor=="OPERATOR" or anchor=="VIEWING" then stats.standingVolumes+=1;check(m.Name,CFrame.new(m.Position+Vector3.new(0,3.3,0)),Vector3.new(3,5.8,3),m.Position.Y) end
   local a=m.Parent;while a and not a:GetAttribute("AllowedMin") do a=a.Parent end
   if a then local mn,mx=a:GetAttribute("AllowedMin"),a:GetAttribute("AllowedMax")
    -- Invisible occupation/socket points may lie just outside their object's geometry pocket.
    if m.Transparency<.98 then for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2)
     if v.X<mn.X-.01 or v.X>mx.X+.01 or v.Y<mn.Y-.01 or v.Y>mx.Y+.01 or v.Z<mn.Z-.01 or v.Z>mx.Z+.01 then table.insert(issues,"ObjectPocket:"..m:GetFullName())end
    end end end end
   else table.insert(meta,m.Name..": missing geometry pocket")end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 local function sibling(n)local c=game.ServerStorage[n]:Clone();c.Parent=game.ServerStorage;local ok,a=pcall(function()return require(c).Audit()end);c:Destroy();assert(ok,a);return a end
 stats.hq=sibling("SellCarsV5InstitutionFidelityPhase6B2HQArtInstaller")
 stats.sales=sibling("SellCarsV5InstitutionFidelityPhase5BSalesInstaller")
 stats.owner=sibling("SellCarsV5InstitutionFidelityPhase5COwnerInstaller")
 return stats
end
function I.Accept(e)
 local a=I.Audit()
 for _,s in ipairs({a,a.hq,a.hq.circulation,a.hq.collector,a.sales,a.owner})do assert(#s.issues==0 and #s.missingFloor==0 and #s.metadataIssues==0,"Unresolved estate audit")end
 assert(e.VisualPass and e.ActualWalkingPass and e.RollbackPass and e.SourceMatch and e.RenderingReviewed and e.RoutePass,"Evidence missing")
 local f=Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e)do f:SetAttribute(k,v)end
 for _,m in layer():GetDescendants() do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase6CEstateStatus","ACCEPTED");return a
end
return I

