--!nocheck
-- Phase 4B owns Body/Restoration only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase4b.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Production","02_Body"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Body_Restoration."..n..".FidelityR1",FunctionId="Body_Restoration",ZoneId="Body_Restoration",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase4BBodyGeometry",true);p.Parent=m;return p
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

local function light(m,x,z,len)
 local p=box(m,"ShieldedWorkshopLuminaire",x,12.8,z,.8,.2,len,C.WarmWhite,Enum.Material.Neon,false)
 local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Brightness=1.2;l.Range=18;l.Angle=105;l.Color=C.WarmWhite;l.Shadows=false;l.Parent=p
end
local function socket(p,n,kind)
 local a=Instance.new("Attachment");a.Name=n;a:SetAttribute("EffectKind",kind);a.Parent=p;return a
end
local function chain(m,x,z)
 for i=0,5 do
  local y=2.4+i*.48;local width=.38;local depth=.18
  if i%2==1 then width,depth=depth,width end
  for _,s in ipairs({-1,1}) do box(m,"ParkedChainLinkSide",x+s*width/2,y,z,.08,.5,depth,C.Steel,M,false) end
  for _,s in ipairs({-1,1}) do box(m,"ParkedChainLinkEnd",x,y+s*.22,z,width,.09,depth,C.Steel,M,false) end
 end
end
local function bench(owner,index,z)
 local m=group(owner,"Frame_Straightening_Cell_"..index,"HERO","DEDICATED","Manual dent/rust tools -> frame bench -> measured hydraulic straightening")
 m:SetAttribute("BayIndex",index);m:SetAttribute("ParkedState","CLAMPS_RETRACTED_CHAINS_HUNG_NO_CAR_CONNECTED")
 box(m,"FlushInsetBenchDeck",3066,.66,z,28,.12,13.8,C.Charcoal,Enum.Material.DiamondPlate,false)
 for _,sgn in ipairs({-1,1}) do
  local zz=z+sgn*8.5
  box(m,"BenchStructuralRail",3066,1.05,zz,27,.7,1.25,C.Steel,M,true)
  box(m,"UpperMachinedRailFace",3066,1.44,zz,27,.12,1.35,C.Galvanized,M,false)
  for j=-5,5 do cyl(m,"IndexedAnchorBushing",3066+j*2.25,1.55,zz,.1,.4,C.Charcoal,"Y") end
  for _,xx in ipairs({3058.7,3073.3}) do
   box(m,"RetractedClampCarriage",xx,1.85,zz,2.5,.55,1.8,C.Amber,M,true)
   box(m,"ClampSlide",xx,2.35,zz,.8,.6,1,C.Stainless,M,false)
   box(m,"UpperClampJaw",xx,2.77,zz,.9,.24,.9,C.Steel,M,false)
   cyl(m,"ClampLeadScrew",xx,2.2,zz,.75,.28,C.Charcoal,"Y")
   pipe(m,"ClampTHandle",Vector3.new(xx-.6,3,zz),Vector3.new(xx+.6,3,zz),.15,C.Steel)
   for _,dx in ipairs({-.75,.75}) do cyl(m,"CarriageFixing",xx+dx,2.18,zz,.12,.23,C.Stainless,"Y") end
  end
  local tx,tz=3062,z+sgn*10.25
  box(m,"TowerSlidingShoe",tx,1.06,tz,3.9,.55,2.6,C.Charcoal,M,true)
  box(m,"TowerUChannel",tx,4.5,tz,1.55,6.2,1.1,C.Amber,M,true)
  box(m,"TowerInnerGuide",tx+.82,4.5,tz,.13,5.7,.82,C.Steel,M,false)
  box(m,"AdjustablePullHead",tx+.6,5.1,tz,1.75,.72,1.5,C.Steel,M,false)
  cyl(m,"HeadPin",tx+1.15,5.1,tz,1.8,.28,C.Stainless,"Z")
  for j=0,5 do cyl(m,"TowerIndexSocket",tx+.92,2.2+j*.8,tz,.06,.18,C.Charcoal,"X") end
  cyl(m,"HydraulicRam",tx-1,2.8,tz,3.3,.7,C.Charcoal,"Y")
  cyl(m,"RamPiston",tx-1,4.6,tz,1.2,.32,C.Stainless,"Y")
  pipe(m,"RamHeadLink",Vector3.new(tx-1,5.1,tz),Vector3.new(tx+.2,5.1,tz),.32,C.Steel)
  chain(m,tx+1.5,tz)
  for j=0,6 do
   local a=j*math.pi/3;local b=(j+1)*math.pi/3
   pipe(m,"ParkedHydraulicHose",Vector3.new(tx-1.45,1.9+math.sin(a)*.7,tz+math.cos(a)*.6),Vector3.new(tx-1.45,1.9+math.sin(b)*.7,tz+math.cos(b)*.6),.11,C.Rubber)
  end
  box(m,"FootPump",tx-2.3,1.1,tz,1.7,.5,1.3,C.Navy,M,false)
 end
 for _,off in ipairs({-8.3,8.3}) do
  box(m,"MeasurementMast",3052,5.7,z+off,.65,9.8,.6,C.Galvanized,M,true)
  box(m,"MeasurementReceiver",3052.45,5.8,z+off,.5,.8,.7,C.Charcoal,M,false)
  cyl(m,"ReceiverLens",3052.74,5.8,z+off,.07,.24,C.Glass,"X")
 end
 local bridge=box(m,"MetrologyCrossbar",3052,10.8,z,1,.6,17.3,C.CleanPanel,M,true)
 socket(bridge,"AlignmentReference_"..index,"DIMENSIONAL_MEASUREMENT")
 for j=-2,2 do box(m,"RuleTick",3052.54,10.8,z+j*3,.035,.2,.055,C.Charcoal,M,false) end
 point(m,"BodyBayOperator_"..index,3038,.6,z,"OPERATOR")
 point(m,"FrameWorkSocket_"..index,3066,8.6,z,"FX")
 light(m,3067,z,12)
end
local function weld(owner)
 local m=group(owner,"MIG_Welding_And_Gas_Trolley","SUPPORT","DEDICATED","Hand repair -> attended MIG station -> controlled welding and repair")
 local x,z=3018,215
 box(m,"WelderTrolley",x,1.4,z,5,.4,4.5,C.Charcoal,M,true)
 for _,dx in ipairs({-1.8,1.8}) do for _,dz in ipairs({-1.5,1.5}) do cyl(m,"CasterWheel",x+dx,.93,z+dz,.4,.62,C.Rubber,"Z") end end
 box(m,"WeldingPowerSupply",x,2.8,z,4.3,2.5,3.6,C.Amber,M,true)
 box(m,"RecessedControlFace",x+2.19,3,z,.12,1.8,3,C.Charcoal,M,false)
 for _,dz in ipairs({-.85,.15}) do cyl(m,"CurrentAndFeedDial",x+2.32,3,z+dz,.15,.5,C.Galvanized,"X") end
 box(m,"CurrentReadout",x+2.3,3.45,z+.9,.06,.35,.72,C.Glass,P,false)
 for j=0,5 do box(m,"VentSlot",x,2.15+j*.25,z-1.85,2.6,.08,.04,C.Charcoal,M,false) end
 cyl(m,"WireSpool",x,4.7,z,1,2.1,C.Bronze,"Z")
 for _,dz in ipairs({-.58,.58}) do cyl(m,"SpoolFlange",x,4.7,z+dz,.1,2.3,C.Steel,"Z") end
 pipe(m,"TrolleyPushHandle",Vector3.new(x-2,4.6,z-1.8),Vector3.new(x-2,4.6,z+1.8),.22,C.Steel)
 for j=0,7 do local a=j*math.pi/4;local b=(j+1)*math.pi/4;pipe(m,"CoiledTorchLead",Vector3.new(x+2.6,2.5+math.sin(a)*.9,z+math.cos(a)),Vector3.new(x+2.6,2.5+math.sin(b)*.9,z+math.cos(b)),.12,C.Rubber) end
 local torch=pipe(m,"ParkedMIGTorch",Vector3.new(x+2.7,3.5,z+.5),Vector3.new(x+3.2,3.8,z+1.1),.25,C.Charcoal)
 socket(torch,"MIGTorchEffect","WELD_ARC_PARKED")
 for i,zz in ipairs({213.5,217.2}) do
  cyl(m,"ShieldingGasBottle",3013.5,3.7,zz,5.4,1.55,i==1 and C.Green or C.Steel,"Y",true)
  cyl(m,"BottleShoulder",3013.5,6.4,zz,.4,1.3,C.Steel,"Y")
  cyl(m,"ValveProtectionCap",3013.5,6.85,zz,.55,.65,C.Charcoal,"Y")
  cyl(m,"RegulatorFace",3014.37,6.2,zz,.25,.65,C.WarmWhite,"X")
  box(m,"BottleRestrainingStrap",3013.5,4.7,zz,1.65,.2,1.68,C.Charcoal,M,false)
 end
 for _,yy in ipairs({1.3,7.2}) do box(m,"WeldingScreenFrame",3011.2,yy,215,.3,.3,9,C.Steel,M,true) end
 local screen=box(m,"AmberWeldingCurtain",3011.2,4.2,215,.16,5.7,8.8,C.Bronze,P,false);screen.Transparency=.23
 for _,zz in ipairs({210.5,219.5}) do box(m,"ScreenStand",3011.2,4.2,zz,.3,6.2,.3,C.Steel,M,true) end
 point(m,"WeldingOperator",3031,.6,215,"OPERATOR")
end
local function spot(owner)
 local m=group(owner,"Resistance_Spot_Welder","HERO","PROFESSIONAL","MIG repair -> spot welding preserving panel joins")
 box(m,"WelderStand",3017,1.2,229.8,5,.65,4.2,C.Navy,M,true)
 box(m,"TransformerHousing",3015.8,3.8,229.8,2.8,5.2,3.2,C.Amber,M,true)
 for _,yy in ipairs({3.8,6.1}) do
  box(m,"CopperElectrodeArm",3018.3,yy,229.8,4.2,.55,.55,C.Bronze,M,false)
 end
 cyl(m,"UpperElectrode",3020.1,5.65,229.8,.75,.25,C.Bronze,"Y")
 cyl(m,"LowerElectrode",3020.1,4.3,229.8,.6,.25,C.Bronze,"Y")
 box(m,"FootPedal",3020.3,.95,231.5,1.6,.3,1.2,C.Charcoal,M,false)
 box(m,"ControlHead",3015.9,7,229.8,2.6,.9,3,C.CleanPanel,M,false)
 for _,zz in ipairs({229.1,230.4}) do cyl(m,"TimingControl",3017.3,7,zz,.14,.38,C.Charcoal,"X") end
 local a=point(m,"SpotWeldSocket",3020.1,5.1,229.8,"FX");socket(a,"ElectrodeContact","SPOT_WELD")
 point(m,"SpotWelderOperator",3031,.6,233,"OPERATOR")
end
local function forming(owner)
 local m=group(owner,"English_Wheel_And_Planishing","HERO","PROFESSIONAL","Hammer and dolly -> bespoke hand-formed panels")
 box(m,"EnglishWheelFoot",3016,1.15,247,7,.6,5.2,C.Navy,M,true)
 box(m,"CFrameBackbone",3013.1,4.8,247,1.5,7.1,1.6,C.Amber,M,true)
 box(m,"CFrameUpperArm",3016,8.1,247,6.8,1.2,1.6,C.Amber,M,true)
 box(m,"CFrameLowerArm",3015.7,2.6,247,6,.8,1.5,C.Amber,M,true)
 for _,zz in ipairs({246.1,247.9}) do box(m,"UpperWheelYoke",3018.2,6.9,zz,.6,2,.32,C.Steel,M,false) end
 cyl(m,"PolishedUpperWheel",3018.2,5.9,247,1.7,2.65,C.Stainless,"Z")
 cyl(m,"LowerAnvilWheel",3018.2,4.3,247,1.35,.7,C.Stainless,"Z")
 cyl(m,"AdjusterLeadScrew",3018.2,3.4,247,1.4,.3,C.Steel,"Y")
 cyl(m,"AnvilHandwheelHub",3018.2,2.1,247,.6,.5,C.Charcoal,"Y")
 for _,a in ipairs({0,math.pi/2}) do box(m,"HandwheelSpoke",3018.2,1.95,247,2,.15,.15,C.Stainless,M,false,CFrame.Angles(0,a,0)) end
 for _,zz in ipairs({246.2,247.8}) do box(m,"PanelCradle",3020,3.4,zz,1.7,.15,.2,C.Galvanized,M,false) end
 box(m,"AluminiumWorkpiece",3019.6,4.8,247,4.5,.1,2.8,C.Stainless,M,false,CFrame.Angles(0,0,math.rad(-4)))
 box(m,"AnvilStorageTray",3013.5,1.7,249,3,.2,1.2,C.Steel,M,false)
 for i=0,3 do cyl(m,"InterchangeableAnvil",3012.5+i*.7,2.1,249,.5,.58,C.Stainless,"Z") end
 point(m,"FormingOperator",3031,.6,243,"OPERATOR")
end
local function panelRack(owner)
 local m=group(owner,"Restoration_Panels_And_Templates","STORY","DEDICATED","Salvaged door -> sorted repair panels -> custom and heritage patterns")
 for _,x in ipairs({3012,3019.5}) do for _,z in ipairs({254.5,266.5}) do box(m,"RackUpright",x,4.6,z,.35,7.8,.35,C.Steel,M,true) end end
 for _,y in ipairs({1.1,4.8,8.3}) do box(m,"RackShelf",3015.75,y,260.5,8,.2,12.4,C.Galvanized,M,true) end
 for i=0,2 do
  local z=256+i*4
  box(m,"LowerDoorSkin",3018.7,3,z,.16,2.6,3.3,i==0 and C.Brick or C.CleanPanel,M,false)
  for _,dz in ipairs({-1.53,1.53}) do box(m,"WindowFrameStile",3018.7,5.5,z+dz,.18,2.6,.22,C.Galvanized,M,false) end
  box(m,"WindowFrameTop",3018.7,6.85,z,.18,.2,3.25,C.Galvanized,M,false)
  box(m,"DoorPressLine",3018.82,3.8,z,.08,.09,2.7,C.Steel,M,false)
  box(m,"DoorHandleRecess",3018.84,4.1,z+.7,.08,.25,.65,C.Charcoal,M,false)
  box(m,"RolledPanelBlank",3014.3,5.7,z,.14,1.5,2.8,C.Stainless,M,false,CFrame.Angles(0,0,math.rad(10)))
 end
 point(m,"PanelSelection",3031,.6,264,"OPERATOR")
end
local function toolsAndSafety(owner)
 local m=group(owner,"Panel_Craft_Bench_And_Tools","SUPPORT","WORKING","First hammer and dolly -> organised forming bench")
 box(m,"CraftBenchTop",3022.8,3.65,238.5,7.2,.35,5,C.Timber,Enum.Material.Wood,false)
 for _,x in ipairs({3019.8,3025.8}) do for _,z in ipairs({236.5,240.5}) do box(m,"BenchLeg",x,1.9,z,.35,3.4,.35,C.Steel,M,true) end end
 box(m,"BenchLowerShelf",3022.8,1.5,238.5,6.7,.2,4.5,C.Galvanized,M,false)
 for i=0,3 do
  local zz=236.9+i*1.0
  box(m,"HammerHandle",3022.7,3.99,zz,2.2,.18,.18,C.Timber,Enum.Material.Wood,false)
  cyl(m,"FormingHammerHead",3023.7,4.1,zz,.72,.35,C.Steel,"Z")
 end
 for _,zz in ipairs({237.2,239.3}) do box(m,"ContouredDolly",3020.4,4.1,zz,.8,.5,1.1,C.Stainless,M,false,CFrame.Angles(0,math.rad(15),0)) end
 box(m,"SoftFaceSandbag",3025,3.99,238.5,1.8,.38,2.2,C.Bronze,Enum.Material.Fabric,false)
 point(m,"HandFormingOperator",3031,.6,238.5,"OPERATOR")
 local s=group(owner,"Hot_Work_Safety_And_Extraction","UTILITY","DEDICATED","Portable fire protection -> extraction and safe hot-work support")
 cyl(s,"FireExtinguisher",3024.8,2.7,266.4,3.4,.9,C.Red,"Y",true)
 box(s,"ExtinguisherHandle",3024.8,4.5,266.4,.7,.2,.4,C.Charcoal,M,false)
 box(s,"WeldingPPEBox",3024.6,1.35,260,3,.9,2.5,C.Navy,M,true)
 local helmet=box(s,"WeldingHelmet",3024.6,2.6,260,1.5,1.6,1.4,C.Charcoal,P,false)
 box(s,"DarkHelmetVisor",3025.4,2.7,260,.06,.5,.9,C.Glass,P,false)
 box(s,"HotWorkBlanket",3024.8,4.9,266.4,.18,.75,1.3,C.WarmWhite,Enum.Material.Fabric,false)
 pipe(s,"ExtractionMain",Vector3.new(3010.6,12.4,212),Vector3.new(3010.6,12.4,264),.7,C.Galvanized)
 for _,z in ipairs({215,230}) do
  pipe(s,"ExtractSupportRiser",Vector3.new(3010.6,10.8,z),Vector3.new(3010.6,12.4,z),.65,C.Galvanized)
  pipe(s,"ArticulatedExtractArm",Vector3.new(3010.6,10.8,z),Vector3.new(3016,10.1,z),.48,C.Charcoal)
  pipe(s,"ArticulatedExtractArm",Vector3.new(3016,10.1,z),Vector3.new(3020.7,7.9,z),.48,C.Charcoal)
  cyl(s,"ExtractionElbow",3016,10.1,z,.8,.9,C.Steel,"Z")
  local hood=box(s,"ParkedFumeCaptureHood",3020.7,7.25,z,2.8,.5,2.8,C.Steel,M,false)
  box(s,"HoodMouth",3020.7,6.97,z,2.4,.08,2.4,C.Charcoal,M,false)
  socket(hood,"ExtractionSocket_"..z,"HOT_WORK_EXHAUST")
 end
 box(s,"DustCollectorCabinet",3012.1,5,241,3.7,6.8,5.2,C.CleanPanel,M,true)
 cyl(s,"FilterAccess",3014.1,5.3,241,.16,2.8,C.Galvanized,"X")
 for _,z in ipairs({239.8,242.2}) do box(s,"FilterLatch",3014.25,5.3,z,.1,1,.15,C.Charcoal,M,false) end
 pipe(s,"CollectorToMain",Vector3.new(3012.1,8.4,241),Vector3.new(3012.1,12.4,241),.65,C.Galvanized)
 pipe(s,"CollectorToMain",Vector3.new(3012.1,12.4,241),Vector3.new(3010.6,12.4,241),.65,C.Galvanized)
 point(s,"SafetyOperator",3037,.6,266,"OPERATOR")
end
local function finish(owner)
 local m=group(owner,"Restoration_Floor_And_Control_Edge","ARCHITECTURE","WORKING","Repaired work slab -> specialist restoration workshop")
 for _,z in ipairs({227,251}) do
  box(m,"RepairConcretePad",3066,.61,z,34,.1,14,C.OldConcrete,Enum.Material.Concrete,false)
  for _,xx in ipairs({3050,3082}) do box(m,"PlainParkingEnd",xx,.73,z,.14,.035,12.5,C.WarmWhite,P,false) end
  box(m,"RestrainedPortalCap",3091,12.4,z,1.48,1.38,16.8,C.Charcoal,M,true)
  box(m,"PaintedAmberInset",3091.77,12.4,z,.08,.25,12,C.Amber,M,false)
 end
 box(m,"StaffNonSlipWalk",3031,.64,239,6,.12,58,C.Concrete,Enum.Material.Concrete,false)
 for _,z in ipairs({215,232,250,264}) do box(m,"WorkshopPanelJoint",3008.1,6,z,.08,9,.05,C.Steel,M,false) end
 light(m,3023,239,19)
 path(owner,"ContinuousStaffAccess",{{3031,210},{3031,267}})
 path(owner,"Bay1ControlApproach",{{3031,232},{3038,232},{3038,227}})
 path(owner,"Bay2ControlApproach",{{3031,256},{3038,256},{3038,251}})
 path(owner,"SafetyEquipmentApproach",{{3031,266},{3037,266}})
 for i,z in ipairs({215,232,238.5,243,259,264,266}) do path(owner,"OperatorApproach_"..i,{{3031,z-2},{3031,z}}) end
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
 root():SetAttribute("InstitutionFidelityPhase4BBodyStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["08_Institution_Production_A"].Body_Restoration
  for _,c in ipairs(old:GetChildren()) do if c.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,c) end end
  suppress(l,old["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  local mass=root()["05_Architecture_Massing"]["02_Production"].Body_Restoration
  for _,n in ipairs({"MaximumFunctionEnvelope","EquipmentAndStaffBand"}) do suppress(l,mass[n]) end
  for i=1,2 do suppress(l,mass["OpenPortal_"..i].PortalHeader);suppress(l,root()["04_Capacity_Sockets"]["Body_Restoration_Bay_"..i]) end
  bench(l,1,227);bench(l,2,251);weld(l);spot(l);forming(l);panelRack(l);toolsAndSafety(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase4BBodyStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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
 check("BodySixStudStaffAisle",CFrame.new(3031,4.5,239),Vector3.new(6,7.5,58))
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
    if v.X<3008 or v.X>3092 or v.Z<209 or v.Z>269 or v.Y>13.85 then outside=true end
   end end end
   if outside then table.insert(issues,"BodyFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase4BBodyStatus","ACCEPTED");return a
end
return I

