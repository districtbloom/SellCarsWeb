--!nocheck
-- Phase 4A owns Wash only. All machines are parked; no independent runtime.
local I={Version="2026-09-06.phase4a.2"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Production","01_Wash"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Wash."..n..".FidelityR1",FunctionId="Wash",ZoneId="Wash",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase4AWashGeometry",true);p.Parent=m;return p
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
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],3.5,v[2]);a.Parent=p end
end
local function taskLight(m,x,z,length)
 local p=box(m,"ShieldedWetRatedLight",x,12.65,z,.8,.22,length,C.WarmWhite,Enum.Material.Neon,false)
 local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Brightness=1.3;l.Range=18;l.Angle=100;l.Color=C.WarmWhite;l.Shadows=false;l.Parent=p
end
local function gauge(m,x,y,z)
 cyl(m,"PressureGaugeBody",x,y,z,.4,1,C.Charcoal,"X")
 cyl(m,"GaugeFace",x+.23,y,z,.06,.82,C.WarmWhite,"X")
 box(m,"GaugeNeedle",x+.28,y+.08,z-.05,.04,.06,.52,C.Charcoal,M,false,CFrame.Angles(math.rad(35),0,0))
end
local function valve(m,x,y,z)
 cyl(m,"ValveBody",x,y,z,.65,.55,C.Bronze,"Y")
 pipe(m,"ValveStem",Vector3.new(x,y,z),Vector3.new(x+.65,y,z),.15,C.Stainless)
 box(m,"IsolationHandle",x+.7,y,z,.12,.18,1.1,C.Cyan,M,false)
end
local function brush(m,n,cf,length)
 local function lp(name,dx,y,dz,w,h,d,col,mat,rot)
  local v=cf:PointToWorldSpace(Vector3.new(dx,y,dz));return box(m,n..name,v.X,v.Y,v.Z,w,h,d,col,mat,false,cf.Rotation*(rot or CFrame.identity))
 end
 local core=lp("Hub",0,0,0,length,.85,.85,C.Charcoal,M,CFrame.Angles(0,0,math.pi/2));core.Shape=Enum.PartType.Cylinder
 for i=0,11 do
  local a=i*math.pi/6
  lp("SoftClothStrip",math.sin(a)*.77,0,math.cos(a)*.77,.13,length-.2,.73,i%3==0 and C.Navy or C.Cyan,Enum.Material.Fabric,CFrame.Angles(0,a,0))
 end
 for _,y in ipairs({-length/2,length/2}) do
  local cap=lp("EndCollar",0,y,0,.24,1.35,1.35,C.Stainless,M,CFrame.Angles(0,0,math.pi/2));cap.Shape=Enum.PartType.Cylinder
 end
 local v=cf:PointToWorldSpace(Vector3.new(0,length/2+.2,0));local a=Instance.new("Attachment");a.Name=n.."RotationSocket";a.Parent=core;a.WorldCFrame=CFrame.new(v)*cf.Rotation
end
local function gantry(owner,index,z)
 local m=group(owner,"Tracked_Wash_Cell_"..index,"HERO","WORKING","Manual pressure lance -> Dedicated controlled wash -> tracked automated cell")
 m:SetAttribute("BayIndex",index);m:SetAttribute("ParkedState","BRUSHES_RETRACTED_TOP_ABOVE_8_STUD_CLEARANCE");m:SetAttribute("TravelAxis","X");m:SetAttribute("TravelMinX",3054);m:SetAttribute("TravelMaxX",3079)
 local x=3057
 for _,off in ipairs({-8.6,8.6}) do
  local zz=z+off
  box(m,"FlushTravelTrack",3066,.7,zz,28,.12,.6,C.Stainless,M,false)
  for _,xx in ipairs({3052.5,3079.5}) do box(m,"TravelStop",xx,1,zz,.65,.5,.8,C.Charcoal,M,true) end
  box(m,"GantryBogie",x,1.2,zz,3.6,.55,1.5,C.Navy,M,true)
  for _,xx in ipairs({x-1.1,x+1.1}) do cyl(m,"FlangedTravelWheel",xx,.95,zz,.65,.65,C.Steel,"Z") end
  box(m,"UprightChannel",x,6.2,zz,1.3,9.6,1.1,C.CleanPanel,M,true)
  box(m,"AccessCover",x+.71,5.5,zz,.12,7.8,.84,C.Stainless,M,false)
  box(m,"AccentInset",x+.79,8.2,zz,.07,1.8,.63,C.Cyan,M,false)
  cyl(m,"DriveMotor",x,2.2,zz+.6,1.1,.8,C.Charcoal,"Z")
  box(m,"BrushSwingArm",x+1.1,8.15,zz,2.4,.35,.5,C.Navy,M,true)
  cyl(m,"BrushMotor",x+2,8.6,zz,1,.95,C.Steel,"Y")
  brush(m,"SideBrush_"..tostring(off),CFrame.new(x+2,4.9,zz),6.2)
  pipe(m,"SprayRiser",Vector3.new(x-.7,1.7,zz),Vector3.new(x-.7,10.8,zz),.22,C.Stainless)
  for _,yy in ipairs({2.5,4.8,7.1}) do
   local nz=zz-math.sign(off)*.53
   local nozzle=cyl(m,"FanSprayNozzle",x-.7,yy,nz,.45,.25,C.Bronze,"Z")
   local at=Instance.new("Attachment");at.Name="SideSpraySocket_"..index.."_"..off.."_"..yy;at.Parent=nozzle;at.WorldCFrame=CFrame.lookAt(nozzle.Position,Vector3.new(nozzle.Position.X,yy,z));at:SetAttribute("EffectKind","RINSE_SPRAY")
  end
 end
 box(m,"Crosshead",x,11.5,z,2.2,1.2,18.3,C.Navy,M,true)
 box(m,"CrossheadFace",x+1.14,11.5,z,.14,.85,16.9,C.CleanPanel,M,false)
 for _,off in ipairs({-7.35,7.35}) do
  box(m,"TopRollerYoke",x+2,10.35,z+off,.5,1.8,.35,C.Stainless,M,false)
  cyl(m,"TopRollerBearing",x+2,9.6,z+off,.45,.65,C.Charcoal,"Z")
 end
 brush(m,"TopBrush",CFrame.new(x+2,9.6,z)*CFrame.Angles(math.pi/2,0,0),14.3)
 pipe(m,"TopRinseBar",Vector3.new(x-1.4,10.1,z-7),Vector3.new(x-1.4,10.1,z+7),.25,C.Stainless)
 for i=-2,2 do
  local nozzle=cyl(m,"TopFanNozzle",x-1.4,9.9,z+i*2.7,.45,.25,C.Bronze,"Y")
  local a=Instance.new("Attachment");a.Name="TopSpraySocket_"..index.."_"..i;a.Parent=nozzle;a.WorldCFrame=CFrame.lookAt(nozzle.Position,nozzle.Position-Vector3.yAxis,Vector3.xAxis);a:SetAttribute("EffectKind","RINSE_SPRAY")
 end
 box(m,"OpticalStopSensor",x+1.05,3,z+8.6,.3,.7,.7,C.Charcoal,M,false)
 cyl(m,"SensorLens",x+1.25,3,z+8.6,.1,.32,C.Glass,"X")
 point(m,"WashCycleFX_"..index,x,8.4,z,"FX")
 point(m,"BayOperator_"..index,3031,.6,z+(index==1 and -3 or 3),"OPERATOR")
 taskLight(m,3067,z,12)
 return m
end
local function dryer(owner,index,z)
 local m=group(owner,"Dryer_Head_"..index,"HERO","DEDICATED","Manual dry-off -> powered controlled drying")
 local x=3075.5
 for _,off in ipairs({-8.6,8.6}) do
  box(m,"DryerFoot",x,.85,z+off,1.8,.4,1.5,C.Steel,M,true)
  box(m,"DryerUpright",x,5.6,z+off,.85,9.6,.8,C.Stainless,M,true)
 end
 box(m,"AirPlenum",x,10.85,z,2.5,1.5,17.6,C.CleanPanel,M,true)
 for _,off in ipairs({-5,0,5}) do
  cyl(m,"CentrifugalBlowerCase",x+.2,11.1,z+off,2.3,2.1,C.Navy,"X")
  cyl(m,"IntakeRecess",x+1.4,11.1,z+off,.08,1.75,C.Charcoal,"X")
  for i=0,3 do box(m,"FanBlade",x+1.47,11.1,z+off,.06,.18,1.55,C.Galvanized,M,false,CFrame.Angles(i*math.pi/4,0,0)) end
  cyl(m,"FanHub",x+1.53,11.1,z+off,.1,.35,C.Stainless,"X")
  for _,dz in ipairs({-.48,0,.48}) do box(m,"FixedIntakeGuard",x+1.65,11.1,z+off+dz,.06,1.5,.055,C.Stainless,M,false) end
 end
 box(m,"AirKnifeDuct",x,9.7,z,1.4,.6,13.8,C.Stainless,M,false)
 box(m,"AirKnifeMouth",x,9.35,z,.4,.12,13.4,C.Charcoal,M,false)
 point(m,"DryerAirSocket_"..index,x,9.2,z,"FX")
 m:SetAttribute("ParkedState","OFF_CLEAR_FOR_ENTRY")
end
local function floors(owner)
 local m=group(owner,"Wet_Floors_And_Trench_Drains","ARCHITECTURE","WORKING","Rough wash pad -> drained service slab -> sealed wet-process floor")
 for _,z in ipairs({108,132}) do
  box(m,"SealedWashDeck",3066,.64,z,34,.12,14,C.OldConcrete,Enum.Material.Concrete,false)
  for _,off in ipairs({-6.35,6.35}) do
   box(m,"DrainRecess",3066,.72,z+off,27,.08,1,C.Charcoal,M,false)
   for i=0,17 do box(m,"LoadRatedGrateSlat",3053.2+i*1.5,.78,z+off,.24,.05,.94,C.Galvanized,M,false) end
   for _,edge in ipairs({-.53,.53}) do box(m,"DrainFrame",3066,.77,z+off+edge,27,.1,.08,C.Stainless,M,false) end
  end
  for _,xx in ipairs({3050,3082}) do box(m,"PlainBayEndMark",xx,.72,z,.12,.025,11,C.WarmWhite,P,false) end
 end
 box(m,"NonSlipServiceWalk",3031,.62,120,6,.12,38,C.Concrete,Enum.Material.Concrete,false)
 box(m,"FlushSumpCover",3039,.7,120,3,.12,3,C.Charcoal,M,false)
 for i=-2,2 do box(m,"SumpGrate",3039+i*.5,.78,120,.17,.04,2.8,C.Galvanized,M,false) end
 point(m,"DrainService",3036,.6,120,"OPERATOR")
end
local function waterPlant(owner)
 local m=group(owner,"Reclaim_Filtration_And_Pump_Skid","UTILITY","WORKING","Portable supply -> contained collection -> filtered recirculation")
 for i,z in ipairs({105.5,113}) do
  cyl(m,"ReclaimVessel_"..i,3015,4.1,z,6.2,4.6,C.CleanPanel,"Y",true)
  cyl(m,"TankBaseRing",3015,1.05,z,.28,4.85,C.Steel,"Y")
  cyl(m,"TankAccessLid",3015,7.3,z,.28,2.6,C.Stainless,"Y")
  box(m,"LidGrip",3015,7.6,z,1.2,.25,.3,C.Charcoal,M,false)
  pipe(m,"SightGlassBacking",Vector3.new(3017.34,2,z),Vector3.new(3017.34,6.2,z),.28,C.Charcoal)
  pipe(m,"LevelTube",Vector3.new(3017.52,2.2,z),Vector3.new(3017.52,6,z),.14,C.Glass)
  pipe(m,"TankOutlet",Vector3.new(3015,1.8,z),Vector3.new(3019,1.8,z),.35,C.Stainless);valve(m,3018.6,1.8,z)
 end
 pipe(m,"TankBalanceLink",Vector3.new(3012.8,2.3,105.5),Vector3.new(3012.8,2.3,113),.35,C.Stainless)
 pipe(m,"DrainReturnRiser",Vector3.new(3012.3,.35,105.5),Vector3.new(3012.3,3.4,105.5),.36,C.Stainless)
 pipe(m,"DrainReturnConnection",Vector3.new(3012.3,3.4,105.5),Vector3.new(3013.1,3.4,105.5),.36,C.Stainless)
 m:SetAttribute("DrainConnection","RETURN_STUB_TO_BURIED_SUMP_LINE")
 box(m,"PumpSkidRails",3022,1.1,116,7,.45,11,C.Navy,M,true)
 for _,z in ipairs({112.5,116.5}) do
  cyl(m,"RibbedPumpMotor",3021.5,2.35,z,3,1.7,C.Steel,"X")
  for x=3020.4,3022.6,.44 do cyl(m,"MotorCoolingRing",x,2.35,z,.12,1.86,C.Charcoal,"X") end
  cyl(m,"PumpVolute",3023.9,2.35,z,.95,2,C.Stainless,"X")
  cyl(m,"CouplingGuard",3023.3,2.35,z,.75,.9,C.Navy,"X")
  box(m,"MotorFoot",3021.5,1.5,z,3.3,.35,1.7,C.Stainless,M,false)
  pipe(m,"PumpDischarge",Vector3.new(3024.2,2.35,z),Vector3.new(3024.2,5,z),.3,C.Stainless);gauge(m,3024.4,4.1,z)
 end
 for _,pair in ipairs({{105.5,112.5},{113,116.5}}) do
  pipe(m,"PumpSuctionBranch",Vector3.new(3019,1.8,pair[1]),Vector3.new(3019,1.8,pair[2]),.34,C.Stainless)
  pipe(m,"PumpSuctionBranch",Vector3.new(3019,1.8,pair[2]),Vector3.new(3024.2,1.8,pair[2]),.34,C.Stainless)
  pipe(m,"PumpSuctionElbow",Vector3.new(3024.2,1.8,pair[2]),Vector3.new(3024.2,2.35,pair[2]),.34,C.Stainless)
 end
 pipe(m,"PressureCollectionHeader",Vector3.new(3024.2,5,112.5),Vector3.new(3024.2,5,116.5),.3,C.Stainless)
 pipe(m,"FilterFeed",Vector3.new(3024.2,5,116.5),Vector3.new(3018,5,116.5),.3,C.Stainless)
 pipe(m,"FilterFeed",Vector3.new(3018,5,116.5),Vector3.new(3018,2.3,116.5),.3,C.Stainless)
 pipe(m,"FilterFeedManifold",Vector3.new(3018,2.3,116.5),Vector3.new(3018,2.3,123.2),.3,C.Stainless)
 for _,z in ipairs({119.3,123.2}) do
  cyl(m,"CartridgeFilter",3016,4,z,5.2,2,C.Stainless,"Y",true)
  cyl(m,"FilterClamp",3016,5.8,z,.2,2.3,C.Charcoal,"Y")
  box(m,"FilterMount",3015,3,z,1.2,4.5,2.6,C.Steel,M,true)
  pipe(m,"FilterOutlet",Vector3.new(3016,5.8,z),Vector3.new(3020,5.8,z),.28,C.Stainless)
  pipe(m,"FilterInlet",Vector3.new(3018,2.3,z),Vector3.new(3016,2.3,z),.28,C.Stainless)
 end
 pipe(m,"FilteredWaterHeader",Vector3.new(3020,5.8,119.3),Vector3.new(3020,5.8,123.2),.3,C.Stainless)
 pipe(m,"SupplyRiser",Vector3.new(3020,5.8,120),Vector3.new(3020,12.5,120),.35,C.Stainless)
 pipe(m,"OverheadWaterMain",Vector3.new(3020,12.5,120),Vector3.new(3057,12.5,120),.35,C.Stainless)
 pipe(m,"ParallelPowerConduit",Vector3.new(3012,12.8,120.6),Vector3.new(3075.5,12.8,120.6),.2,C.Charcoal)
 for _,z in ipairs({108,132}) do
  pipe(m,"CellSupplyBranch",Vector3.new(3057,12.5,120),Vector3.new(3057,12.5,z),.25,C.Stainless)
  pipe(m,"RinseFeedDrop",Vector3.new(3057,12.5,z),Vector3.new(3055.6,10.1,z),.18,C.Rubber)
  pipe(m,"DryerPowerBranch",Vector3.new(3075.5,12.8,120.6),Vector3.new(3075.5,12.8,z),.16,C.Charcoal)
 end
 for i=0,3 do
  local x=3040+i*4
  pipe(m,"ParkedSupplyFestoon",Vector3.new(x,12.5,120),Vector3.new(x+2,11.4,120),.18,C.Rubber)
  pipe(m,"ParkedSupplyFestoon",Vector3.new(x+2,11.4,120),Vector3.new(x+4,12.5,120),.18,C.Rubber)
 end
 point(m,"WaterPlantOperator",3031,.6,120,"OPERATOR");point(m,"PumpHumSocket",3022,3,116,"FX")
 taskLight(m,3020,118,15)
end
local function chemistry(owner)
 local m=group(owner,"Bunded_Chemistry_And_Dosing","UTILITY","WORKING","Sealed soap container -> contained chemistry -> metered application")
 box(m,"SpillBundBase",3018.5,.85,133.2,12,.35,10,C.Charcoal,M,true)
 for _,x in ipairs({3012.7,3024.3}) do box(m,"BundSideLip",x,1.15,133.2,.3,.5,10,C.Steel,M,true) end
 for _,z in ipairs({128.35,138.05}) do box(m,"BundEndLip",3018.5,1.15,z,12,.5,.3,C.Steel,M,true) end
 for i,z in ipairs({130.4,135.1}) do
  for _,x in ipairs({3016,3021}) do
   box(m,"ChemicalCan",x,2.9,z,2.5,3.4,2.8,i==1 and C.Cyan or C.CleanPanel,P,true)
   cyl(m,"ScrewCap",x,4.75,z,.3,.65,C.Charcoal,"Y")
   box(m,"CarryHandle",x,4.65,z+1,.95,.28,.25,C.Charcoal,M,false)
   pipe(m,"DosingPickup",Vector3.new(x,4.9,z),Vector3.new(3013.3,6.7,z),.12,C.Rubber)
  end
 end
 box(m,"DosingPanelBack",3012.6,7,133.2,.25,4.4,8,C.CleanPanel,M,true)
 for _,z in ipairs({130.5,133.2,135.9}) do
  cyl(m,"MeteringPump",3013.1,7.1,z,.75,1,C.Charcoal,"X")
  cyl(m,"DoseDial",3013.55,7.1,z,.12,.55,C.Cyan,"X")
  pipe(m,"MeteringTube",Vector3.new(3013.25,6.3,z),Vector3.new(3013.25,8.9,z),.13,C.Stainless)
 end
 pipe(m,"ChemistryManifold",Vector3.new(3013.25,8.9,130.5),Vector3.new(3013.25,8.9,135.9),.2,C.Stainless)
 pipe(m,"DosedSupplyLine",Vector3.new(3013.25,8.9,133.2),Vector3.new(3013.25,12.5,133.2),.16,C.Stainless)
 pipe(m,"DosedSupplyLine",Vector3.new(3013.25,12.5,133.2),Vector3.new(3020,12.5,120),.16,C.Stainless)
 point(m,"ChemicalOperator",3031,.6,138.1,"OPERATOR")
end
local function lanceAndSafety(owner)
 local m=group(owner,"Prewash_Lance_Control_And_Safety","SUPPORT","WORKING","Handheld lance and PPE -> attended cell -> automated job control")
 box(m,"LanceMastFoot",3042,.9,120,1.8,.45,1.8,C.Steel,M,true)
 cyl(m,"LanceMast",3042,5.5,120,9.1,.48,C.Stainless,"Y",true)
 pipe(m,"ParkedBoomArm",Vector3.new(3042,10,120),Vector3.new(3047,10,120),.35,C.Stainless)
 pipe(m,"HoseLead",Vector3.new(3047,9.8,120),Vector3.new(3043,5.9,120.5),.17,C.Rubber)
 for i=0,11 do
  local a=i*math.pi/6;local b=(i+1)*math.pi/6
  pipe(m,"CoiledPressureHose",Vector3.new(3042.35,4.6+math.sin(a)*1.15,120+math.cos(a)*1.15),Vector3.new(3042.35,4.6+math.sin(b)*1.15,120+math.cos(b)*1.15),.15,C.Rubber)
 end
 box(m,"TriggerGrip",3042.5,4.8,121.8,.3,.8,.8,C.Charcoal,M,false)
 pipe(m,"ParkedLance",Vector3.new(3042.5,4.5,121.8),Vector3.new(3042.5,1.5,122.3),.16,C.Stainless)
 box(m,"ControlPedestal",3043.5,2.5,120,1,3.5,1,C.Navy,M,true)
 box(m,"WetRatedControlFace",3043.5,4.6,120,1.3,1.3,.3,C.CleanPanel,M,false)
 box(m,"JobDisplay",3043.5,4.8,119.8,.9,.45,.08,C.Navy,P,false)
 cyl(m,"EmergencyStop",3043.2,4.15,119.75,.18,.35,C.Red,"Z")
 cyl(m,"CycleReadyButton",3043.75,4.15,119.75,.13,.22,C.Green,"Z")
 point(m,"AttendedControl",3043.5,.6,117,"OPERATOR");point(m,"PressureLanceFX",3042.5,1.5,122.3,"FX")
 -- Eye rinse and spill tools stay in the utility strip, not in the six-stud staff aisle.
 m=group(owner,"Eye_Rinse_And_Spill_Response","SUPPORT","DEDICATED","Portable PPE -> fixed rinse and contained spill-response point")
 cyl(m,"EyeRinsePedestal",3013,2.8,125.6,4.2,.28,C.Stainless,"Y")
 cyl(m,"EyeRinseBowl",3013,4.85,125.6,.3,1.5,C.Stainless,"Y")
 cyl(m,"RecessedBowl",3013,5.015,125.6,.035,1.12,C.Steel,"Y")
 for i=0,7 do local a=i*math.pi/4;local b=(i+1)*math.pi/4
  pipe(m,"BowlRim",Vector3.new(3013+math.sin(a)*.64,5.08,125.6+math.cos(a)*.64),Vector3.new(3013+math.sin(b)*.64,5.08,125.6+math.cos(b)*.64),.13,C.Stainless)
 end
 for _,z in ipairs({125.25,125.95}) do pipe(m,"RinseSpout",Vector3.new(3013,4.9,z),Vector3.new(3013.4,5.25,z),.14,C.Stainless) end
 box(m,"SpillKitBin",3025.5,2.15,136.7,2.1,2.8,2.1,C.Amber,P,true)
 box(m,"SpillKitLid",3025.5,3.65,136.7,2.2,.25,2.2,C.Charcoal,M,false)
 pipe(m,"SqueegeeHandle",Vector3.new(3013,1.2,138.3),Vector3.new(3013,6.3,138.3),.16,C.Stainless)
 box(m,"SqueegeeBlade",3013,1.1,138.3,1.7,.25,.3,C.Rubber,M,false)
 point(m,"EyeRinseOperator",3016,.6,126.2,"OPERATOR")
 path(owner,"EyeRinseApproach",{{3031,126.2},{3016,126.2}})
 path(owner,"WashStaffAisle",{{3031,100},{3031,140}})
 path(owner,"LanceControlApproach",{{3031,120},{3037,120},{3037,117},{3043.5,117}})
 path(owner,"SumpMaintenanceApproach",{{3031,120},{3036,120}})
end
local function finish(owner)
 local m=group(owner,"Wash_Process_Finishes","ARCHITECTURE","WORKING","Covered manual pad -> durable wet-process department")
 for _,z in ipairs({108,132}) do
  box(m,"RetainedPortalHeader",3091,12.4,z,1.5,1.4,16.9,C.Navy,M,false)
  box(m,"RestrainedPortalAccent",3091.8,12.45,z,.08,.16,13.8,C.Cyan,M,false)
 end
 box(m,"WashableWallLiner",3008.1,7,120,.16,7.4,37,C.CleanPanel,M,false)
 box(m,"WallBaseProtection",3008.2,1.9,120,.16,2.7,37,C.Galvanized,M,false)
 for _,z in ipairs({102,111,120,129,138}) do box(m,"PanelSeam",3008.22,7,z,.05,7.35,.05,C.Steel,M,false) end
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
  local cf={};for _,v in ipairs({p.CFrame:GetComponents()}) do table.insert(cf,string.format("%.3f",v)) end
  table.insert(rows,p:GetFullName().."|"..table.concat(cf,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.Transparency))
 end end;table.sort(rows);local h=5381;for _,s in ipairs(rows) do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
function I.Uninstall()
 local l=layer();if l then
  local rs=l:FindFirstChild("90_Restoration");if rs then for _,r in ipairs(rs:GetChildren()) do if r.Value then for k,v in pairs(r:GetAttributes()) do r.Value[k]=v end end end end
  l:Destroy()
 end
 root():SetAttribute("InstitutionFidelityPhase4AWashStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["08_Institution_Production_A"].Wash
  for _,c in ipairs(old:GetChildren()) do if c.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,c) end end
  suppress(l,old["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  local mass=root()["05_Architecture_Massing"]["02_Production"].Wash
  for _,n in ipairs({"MaximumFunctionEnvelope","EquipmentAndStaffBand"}) do suppress(l,mass[n]) end
  for i=1,2 do suppress(l,mass["OpenPortal_"..i].PortalHeader);suppress(l,root()["04_Capacity_Sockets"]["Wash_Bay_"..i]) end
  floors(l);gantry(l,1,108);gantry(l,2,132);dryer(l,1,108);dryer(l,2,132);waterPlant(l);chemistry(l);lanceAndSafety(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase4AWashStatus","BUILT_AWAITING_REVIEW");return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,metadata,ids={},{},{}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function check(n,cf,size,ignoreOccupation)
  for _,p in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
   local occupied=false
   if ignoreOccupation then local a=p.Parent;while a and a~=root() do if a:GetAttribute("OccupationPrototype") then occupied=true;break end;a=a.Parent end end
   if not occupied and p.Transparency<.98 and p.Position.Y+p.Size.Y/2>.88 then table.insert(issues,n..": "..p:GetFullName()) end
  end
 end
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size) end end
 for _,p in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z)) end end
 check("WashSixStudStaffAisle",CFrame.new(3031,4.5,120),Vector3.new(6,7.5,38))
 local stats={parts=0,solids=0,lights=0,models=0,accessPaths=0,standingVolumes=0,floorSamples=0,missingFloor={},issues=issues,metadataIssues=metadata,signature=signature(l)}
 params.FilterDescendantsInstances={root()}
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={root()};rays.RespectCanCollide=true
 for _,route in ipairs(l["98_Access_Paths"]:GetChildren()) do
  stats.accessPaths+=1;local points=route:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value
   -- Occupant figures are not architecture; all other active scene geometry is included.
   check(route.Name,CFrame.lookAt((a+b)/2,b),Vector3.new(3,5.5,(b-a).Magnitude+1),true)
   local steps=math.ceil((b-a).Magnitude/2);for j=0,steps do local v=a:Lerp(b,j/steps);stats.floorSamples+=1
    if not workspace:Raycast(Vector3.new(v.X,2.5,v.Z),Vector3.new(0,-4,0),rays) then table.insert(stats.missingFloor,route.Name..":"..tostring(v)) end
   end
  end
 end
 for _,m in ipairs(l:GetDescendants()) do
  if m:IsA("Model") then
   stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"}) do if m:GetAttribute(k)==nil then table.insert(metadata,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(metadata,"Duplicate: "..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do local n=m:GetAttribute(k);if n and n~="" then
    local a=m:FindFirstChild(n,true)
    if not a then table.insert(metadata,m.Name..": unresolved "..n)
    elseif k=="InteractionAnchor" and a:IsA("BasePart") then stats.standingVolumes+=1;check(m.Name.."_Standing",CFrame.new(a.Position.X,3.5,a.Position.Z),Vector3.new(3,5.5,3)) end
   end end
  elseif m:IsA("BasePart") then
   stats.parts+=1;if m.CanCollide then stats.solids+=1 end
   local outside=false
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
    local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2)
    if v.X<3008 or v.X>3092 or v.Z<98 or v.Z>142 or v.Y>13.85 then outside=true end
   end end end
   if outside then table.insert(issues,"WashFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase4AWashStatus","ACCEPTED");return a
end
return I

