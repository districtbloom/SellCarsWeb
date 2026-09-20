--!nocheck
-- Phase 4C owns Tune/Performance only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase4c.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Production","03_Tune"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Tune_Performance."..n..".FidelityR1",FunctionId="Tune_Performance",ZoneId="Tune_Performance",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase4CTuneGeometry",true);p.Parent=m;return p
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

local Purple=Color3.fromRGB(106,90,142)
local function ring(m,n,x,y,z,radius,diam,col,axis)
 for i=0,11 do
  local a=i*math.pi/6;local b=(i+1)*math.pi/6
  local function v(t)
   if axis=="Y" then return Vector3.new(x+math.cos(t)*radius,y,z+math.sin(t)*radius) end
   return Vector3.new(x,y+math.cos(t)*radius,z+math.sin(t)*radius)
  end
  pipe(m,n,v(a),v(b),diam,col)
 end
end
local function wheel(m,n,x,y,z,diam)
 cyl(m,n.."_Tyre",x,y,z,1.05,diam,C.Rubber,"X")
 cyl(m,n.."_Rim",x+.57,y,z,.16,diam*.7,C.Galvanized,"X")
 cyl(m,n.."_Hub",x+.69,y,z,.18,diam*.2,C.Charcoal,"X")
 for j=0,4 do local a=j*2*math.pi/5;pipe(m,n.."_Spoke",Vector3.new(x+.71,y+math.cos(a)*diam*.12,z+math.sin(a)*diam*.12),Vector3.new(x+.71,y+math.cos(a)*diam*.29,z+math.sin(a)*diam*.29),.15,C.Stainless) end
end
local function dyno(owner,index,z)
 local m=group(owner,"Recessed_Rolling_Road_Cell_"..index,"HERO","DEDICATED","Manual chassis setup -> measured rolling road -> calibrated special builds")
 m:SetAttribute("BayIndex",index);m:SetAttribute("ParkedState","ROLLERS_IDLE_RESTRAINTS_STOWED_EXTRACTION_PARKED")
 box(m,"FlushDynoServiceDeck",3066,.62,z,30,.1,13.6,C.Steel,Enum.Material.DiamondPlate,false)
 for _,axle in ipairs({-5.4,5.4}) do for _,track in ipairs({-3.8,3.8}) do
  local x,zz=3066+axle,z+track
  box(m,"RecessedRollerCartridge",x,.69,zz,3.2,.08,3.3,C.Charcoal,M,false)
  for _,roll in ipairs({-.72,.72}) do
   cyl(m,"MachinedDynoDrum",x+roll,.37,zz,2.7,.97,C.Stainless,"Z")
   for _,edge in ipairs({-1.42,1.42}) do cyl(m,"DrumBearingCap",x+roll,.38,zz+edge,.1,.76,C.Steel,"Z") end
  end
  for _,edge in ipairs({-1.6,1.6}) do box(m,"CartridgeMount",x+edge,.76,zz,.11,.07,3.3,C.Galvanized,M,false) end
 end end
 for _,side in ipairs({-1,1}) do
  local zz=z+side*8.65
  box(m,"RestraintStorageRail",3066,1.05,zz,23,.5,.8,C.Charcoal,M,true)
  for _,xx in ipairs({3058,3074}) do
   cyl(m,"TieDownAnchor",xx,1.42,zz,.12,.65,C.Galvanized,"Y")
   box(m,"ParkedRatchetStrap",xx,1.7,zz,1.7,.34,.72,Purple,Enum.Material.Fabric,false)
   box(m,"RatchetHandle",xx+.3,1.99,zz,.72,.2,.52,C.Stainless,M,false)
   box(m,"StowedWheelChock",xx+2.2,1.5,zz,1.35,.65,1.2,C.Rubber,P,false,CFrame.Angles(0,0,.14))
  end
  box(m,"AlignmentMast",3078,4.6,zz,.55,7.6,.6,C.Steel,M,true)
  box(m,"OpticalTargetHousing",3078,5.8,zz,1.2,1.4,.9,C.Charcoal,M,false)
  for i=0,1 do for j=0,1 do box(m,"TargetReference",3078.62,5.48+i*.65,zz-.23+j*.46,.05,.24,.22,(i+j)%2==0 and C.WarmWhite or C.Steel,P,false) end end
 end
 local x=3042
 box(m,"CoolingTrolleyFoot",x,1.06,z,4.8,.55,8,C.Charcoal,M,true)
 for _,zz in ipairs({z-2.8,z+2.8}) do for _,xx in ipairs({x-1.6,x+1.6}) do cyl(m,"CoolingCaster",xx,.87,zz,.35,.5,C.Rubber,"Z") end end
 for _,zz in ipairs({z-2.8,z+2.8}) do box(m,"CoolingFrameLeg",x,3.4,zz,.7,4.5,.7,C.Steel,M,true) end
 cyl(m,"CoolingFanShroud",x,5,z,2.4,6.4,C.Navy,"X",true)
 cyl(m,"FanOpening",x+1.24,5,z,.08,5.75,C.Charcoal,"X")
 for j=0,4 do
  local angle=j*2*math.pi/5
  local p=box(m,"BroadFanBlade",x+1.34,5+math.cos(angle)*1.4,z+math.sin(angle)*1.4,.12,2.8,.85,C.Galvanized,M,false)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(angle,0,0)
 end
 cyl(m,"FanHub",x+1.43,5,z,.3,1.4,C.Steel,"X")
 ring(m,"FanSafetyGuardOuter",x+1.7,5,z,2.9,.12,C.Stainless)
 ring(m,"FanSafetyGuardInner",x+1.7,5,z,1.9,.1,C.Stainless)
 for j=0,7 do local a=j*math.pi/4;pipe(m,"FanGuardRadial",Vector3.new(x+1.72,5,z),Vector3.new(x+1.72,5+math.cos(a)*2.9,z+math.sin(a)*2.9),.08,C.Stainless) end
 box(m,"FanControlPod",x,7.8,z+2.65,.9,1.1,.7,Purple,M,false)
 cyl(m,"FanEmergencyStop",x+.53,7.8,z+2.65,.14,.38,C.Red,"X")
 -- The exhaust remains hung beside the car envelope, never stretched through a moving car.
 pipe(m,"OverheadExhaustMain",Vector3.new(3009.5,12, z+9),Vector3.new(3085.5,12,z+9),.7,C.Galvanized)
 for _,xx in ipairs({3020,3045,3070}) do pipe(m,"ExhaustSuspension",Vector3.new(xx,12.2,z+9),Vector3.new(xx,13.7,z+9),.12,C.Steel) end
 pipe(m,"ParkedExhaustDrop",Vector3.new(3085.5,12,z+9),Vector3.new(3085.5,4.1,z+9),.62,C.Rubber)
 local nozzle=cyl(m,"ParkedTailpipeCup",3085.5,3.75,z+9,.7,1.0,C.Rubber,"Y")
 socket(nozzle,"TailpipeExtraction_"..index,"PARKED_EXHAUST_CONNECTION")
 point(m,"TuneBayOperator_"..index,3037,.6,z,"OPERATOR")
 point(m,"DynoVehicleSocket_"..index,3066,8.7,z,"FX")
 light(m,3067,z,12)
end
local function control(owner)
 local m=group(owner,"Acoustic_Dyno_Control_Nook","HERO","PROFESSIONAL","Manual tuning judgement -> measured power/thermal control")
 box(m,"ControlRaisedFinish",3019,.64,286,14,.12,12,C.Concrete,Enum.Material.Concrete,false)
 for _,z in ipairs({280,292}) do
  box(m,"AcousticSideBase",3019,2.45,z,14,3.4,.3,C.Navy,M,true)
  box(m,"SideGlazingFrame",3019,7.8,z,14,.25,.35,C.Steel,M,true)
  local g=box(m,"AcousticSideGlazing",3019,5.9,z,13.5,3.4,.18,C.Glass,Enum.Material.Glass,false);g.Transparency=.45
 end
 for _,z in ipairs({281.35,290.65}) do
  box(m,"ControlFrontPier",3026,4.4,z,.4,7.5,2.7,C.Charcoal,M,true)
  local g=box(m,"FrontVisionPanel",3026.24,5.8,z,.16,3.4,2.2,C.Glass,Enum.Material.Glass,false);g.Transparency=.4
 end
 box(m,"OpenControlDoorHeader",3026,9.3,286,.5,.45,5.8,C.Charcoal,M,true)
 for _,z in ipairs({280.8,283.4,286,288.6,291.2}) do
  box(m,"AbsorberFabricPanel",3012.2,5.1,z,.25,6.8,2.2,C.Charcoal,Enum.Material.Fabric,false)
 end
 box(m,"TelemetryWorktop",3016.5,3.7,286,5.8,.28,9.2,C.CleanPanel,M,true)
 for _,z in ipairs({282.4,289.6}) do box(m,"DeskPedestal",3015.5,2.1,z,3.6,3,1.8,C.Steel,M,true) end
 for i,z in ipairs({283.7,286,288.3}) do
  box(m,"MonitorPedestal",3016.4,4.5,z,.35,1.3,.4,C.Charcoal,M,false)
  box(m,"TelemetryMonitor",3016.4,5.5,z,.35,1.8,2.05,C.Charcoal,M,false)
  box(m,"ReadableDarkDisplay",3016.6,5.5,z,.045,1.5,1.8,C.Navy,P,false)
  for j=0,4 do box(m,"MeasuredGraphBar",3016.63,5.07+j*.19,z-.6+j*.25,.035,.08,.2,C.Cyan,P,false) end
 end
 box(m,"ControlKeyboard",3018.4,3.92,286,.75,.12,2.3,C.Charcoal,P,false)
 for i=0,3 do box(m,"KeyboardKeyRow",3018.4,4.0,285.2+i*.5,.55,.035,.27,C.Steel,P,false) end
 cyl(m,"MainEmergencyStop",3018.5,4.18,283.4,.3,.6,C.Red,"Y")
 box(m,"TelemetryRack",3013.9,2.7,281.6,2.3,3.8,2,C.Charcoal,M,true)
 for i=0,4 do box(m,"RackVent",3015.09,1.7+i*.46,281.6,.07,.1,1.7,C.Steel,M,false) end
 point(m,"DynoControlOperator",3022,.6,286,"OPERATOR")
end
local function ecu(owner)
 local m=group(owner,"ECU_And_Sensor_Calibration_Bench","SUPPORT","PROFESSIONAL","Setup tools -> calibration electronics and ECU programming")
 box(m,"AntiStaticWorktop",3017.4,3.7,299.2,6.6,.3,8.8,C.Charcoal,M,true)
 for _,x in ipairs({3015,3019.7}) do for _,z in ipairs({295.8,302.6}) do box(m,"BenchLeg",x,2.1,z,.45,3.2,.45,C.Steel,M,true) end end
 box(m,"ESDMat",3018,3.89,299.2,4,.06,6,C.Green,P,false)
 box(m,"ECURibbedHousing",3018.2,4.25,298,1.7,.7,2.1,C.Galvanized,M,false)
 for i=0,4 do box(m,"ECUCoolingFin",3017.6+i*.3,4.69,298,.08,.16,2.1,C.Stainless,M,false) end
 box(m,"HarnessConnector",3019.2,4.18,298,.4,.42,1.3,C.Charcoal,P,false)
 for j=0,3 do pipe(m,"BenchHarnessLead",Vector3.new(3019.4,4.12,297.6+j*.25),Vector3.new(3019.8,4.05,299.2+j*.25),.065,j%2==0 and C.Red or C.Steel) end
 box(m,"OscilloscopeHousing",3015.6,4.6,300.4,1.9,1.6,2.6,C.CleanPanel,M,false)
 box(m,"ScopeScreen",3016.61,4.75,300,.08,.95,1.4,C.Navy,P,false)
 for i=0,2 do cyl(m,"ScopeDial",3016.7,4.2+i*.42,301.2,.12,.2,C.Charcoal,"X") end
 box(m,"BenchPowerSupply",3015.6,4.4,296.6,1.7,1,1.8,C.Steel,M,false)
 cyl(m,"SupplyDial",3016.51,4.35,296.4,.12,.32,C.Charcoal,"X")
 point(m,"ElectronicsOperator",3024,.6,299.2,"OPERATOR")
 local s=point(m,"ECUProgrammingSocket",3018.4,4.7,298,"FX");socket(s,"ProgrammerDataConnection","ECU_CALIBRATION")
end
local function tyreChanger(owner)
 local m=group(owner,"Tyre_Changing_Station","HERO","DEDICATED","Manual wheel changes -> powered tyre service")
 box(m,"TyreMachineBase",3017,2,309,4.8,2.8,4.6,Purple,M,true)
 cyl(m,"ClampingTurntable",3017,3.7,309,.5,4.9,C.Galvanized,"Y")
 for j=0,3 do local a=j*math.pi/2
  box(m,"WheelClampingJaw",3017+math.cos(a)*1.65,4.05,309+math.sin(a)*1.65,.8,.4,.55,C.Charcoal,M,false,CFrame.Angles(0,-a,0))
 end
 box(m,"ChangerRearColumn",3014.8,5.3,309,1,8.2,1.2,C.Charcoal,M,true)
 box(m,"SwingArm",3016.2,9.3,309,3.7,.65,.65,C.Steel,M,false)
 cyl(m,"MountingBar",3017.7,7.3,309,3.6,.3,C.Stainless,"Y")
 box(m,"MountingDuckHead",3017.9,5.45,309,.6,.45,.8,C.Steel,M,false)
 pipe(m,"BeadBreakerArm",Vector3.new(3018.8,2.5,310.8),Vector3.new(3021.2,2.2,310.8),.45,C.Steel)
 box(m,"BeadBreakerShoe",3021.2,2.2,310.8,.4,1.3,1.6,C.Charcoal,M,false)
 for i=0,2 do box(m,"MachineFootPedal",3019.8,.95,307.8+i*.85,.9,.25,.58,C.Charcoal,P,false) end
 point(m,"TyreServiceOperator",3024.5,.6,309,"OPERATOR")
end
local function balancer(owner)
 local m=group(owner,"Wheel_Balancing_Station","HERO","DEDICATED","Wheel fitment -> measured balance and running-gear quality")
 box(m,"BalancerCabinet",3016.1,2.65,319,4.1,4.0,4.2,Purple,M,true)
 box(m,"WheelWeightTray",3016.1,4.8,319,4.5,.3,4.5,C.Charcoal,M,false)
 for i=0,3 do box(m,"TrayPocketDivider",3015+i*.7,5,319,.08,.25,3.5,C.Steel,M,false) end
 cyl(m,"BalancerSpindle",3019.1,3.6,319,3,.48,C.Stainless,"X")
 wheel(m,"CalibrationWheel",3020.2,3.6,319,4.3)
 cyl(m,"LockingCone",3021.02,3.6,319,.45,.8,C.Steel,"X")
 -- Open guard parks above/back of the spindle, never in a pedestrian reservation.
 ring(m,"RaisedWheelGuard",3019.0,5.2,319,2.35,.25,C.Charcoal)
 box(m,"BalancerScreenSupport",3014.6,6.4,319,.4,3,.4,C.Charcoal,M,false)
 box(m,"BalanceReadout",3014.7,7.8,319,.4,1.6,2.6,C.Charcoal,M,false)
 box(m,"BalanceDisplayFace",3014.93,7.8,319,.05,1.35,2.25,C.Navy,P,false)
 for _,zz in ipairs({318.4,319.6}) do box(m,"BalanceDigits",3014.97,7.8,zz,.03,.48,.7,C.Cyan,P,false) end
 point(m,"BalanceOperator",3024.7,.6,319,"OPERATOR")
end
local function performanceRack(owner)
 local m=group(owner,"Running_Gear_And_Special_Build_Hardware","SUPPORT","PROFESSIONAL","Wheel stock -> selectable suspension/exhaust/underbody-light kit")
 for _,x in ipairs({3012.8,3019.3}) do for _,z in ipairs({327,333.6}) do box(m,"RackUpright",x,4.6,z,.35,7.9,.35,C.Steel,M,true) end end
 for _,y in ipairs({1.1,4.7,8.4}) do box(m,"HardwareShelf",3016,y,330.3,7.1,.25,7.2,C.Galvanized,M,true) end
 for _,z in ipairs({328,331.5}) do
  cyl(m,"CoiloverDamper",3016.2,6.4,z,2.9,.55,C.Steel,"Y")
  for j=0,5 do cyl(m,"SpringTurn",3016.2,5.5+j*.33,z,.13,1.15,Purple,"Y") end
  box(m,"UpperStrutMount",3016.2,8,z,1.3,.25,1.3,C.Charcoal,M,false)
 end
 for i=0,1 do
  local z=328.5+i*3
  cyl(m,"ExhaustSilencer",3016,2.5,z,4.5,1.55,C.Stainless,"X")
  pipe(m,"ExhaustTail",Vector3.new(3018.3,2.5,z),Vector3.new(3019.1,2.9,z),.65,C.Galvanized)
 end
 for i=0,2 do box(m,"UnpoweredUnderbodyLightKit",3020.1,5.5+i*.72,331.8,.22,.28,3,C.CleanPanel,P,false);box(m,"AccessoryEndConnector",3020.1,5.5+i*.72,330.22,.3,.35,.22,C.Charcoal,P,false) end
 point(m,"HardwareSelection",3024.5,.6,330,"OPERATOR")
end
local function finish(owner)
 local m=group(owner,"Calibration_Floor_And_Utility_Edge","ARCHITECTURE","WORKING","Original slab -> specialist performance workshop")
 for _,z in ipairs({295,319}) do
  box(m,"DynoConcreteSurround",3066,.58,z,34,.1,14,C.OldConcrete,Enum.Material.Concrete,false)
  box(m,"RestrainedPortalCap",3091,12.4,z,1.48,1.38,16.8,C.Charcoal,M,true)
  box(m,"MutedPurpleInsert",3091.77,12.4,z,.08,.25,12,Purple,M,false)
  for _,x in ipairs({3050,3082}) do box(m,"PlainPositionEndMark",x,.73,z,.14,.035,12.6,C.WarmWhite,P,false) end
 end
 box(m,"StaffNonSlipWalk",3031,.64,307,6,.12,54,C.Concrete,Enum.Material.Concrete,false)
 for _,z in ipairs({294,305,317,332}) do box(m,"WorkshopWallJoint",3008.1,6,z,.08,9,.05,C.Steel,M,false) end
 light(m,3020,307,20)
 path(owner,"ContinuousStaffAccess",{{3031,280},{3031,334}})
 path(owner,"Bay1ControlApproach",{{3031,299},{3037,299},{3037,295}})
 path(owner,"Bay2ControlApproach",{{3031,323},{3037,323},{3037,319}})
 path(owner,"ControlDoorApproach",{{3031,286},{3022,286}})
 path(owner,"ElectronicsApproach",{{3031,299.2},{3024,299.2}})
 path(owner,"TyreMachineApproach",{{3031,309},{3024.5,309}})
 path(owner,"BalanceApproach",{{3031,319},{3024.7,319}})
 path(owner,"HardwareApproach",{{3031,330},{3024.5,330}})
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
 root():SetAttribute("InstitutionFidelityPhase4CTuneStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["08_Institution_Production_A"].Tune_Performance
  for _,c in ipairs(old:GetChildren()) do if c.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,c) end end
  suppress(l,old["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  local mass=root()["05_Architecture_Massing"]["02_Production"].Tune_Performance
  for _,n in ipairs({"MaximumFunctionEnvelope","EquipmentAndStaffBand"}) do suppress(l,mass[n]) end
  for i=1,2 do suppress(l,mass["OpenPortal_"..i].PortalHeader);suppress(l,root()["04_Capacity_Sockets"]["Tune_Performance_Bay_"..i]) end
  dyno(l,1,295);dyno(l,2,319);control(l);ecu(l);tyreChanger(l);balancer(l);performanceRack(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase4CTuneStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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
 check("TuneSixStudStaffAisle",CFrame.new(3031,4.5,307),Vector3.new(6,7.5,54))
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
    if v.X<3008 or v.X>3092 or v.Z<279 or v.Z>335 or v.Y>13.85 then outside=true end
   end end end
   if outside then table.insert(issues,"TuneFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase4CTuneStatus","ACCEPTED");return a
end
return I

