--!nocheck
-- Phase 2: source-owned Mechanical / Paint gold slices. No recurring runtime.
local I = {Version = "2026-09-06.phase2.4"}
local Kit = require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C = Kit.Colors
local ROOT, LAYER = "SellCars_Dealership_Growth_V5", "01_Gold_Slices"
local M, P = Enum.Material.Metal, Enum.Material.SmoothPlastic
local function root() return assert(workspace:FindFirstChild(ROOT), "V5 missing") end
local function layer() return root()["10_Institution_Fidelity_R1"]:FindFirstChild(LAYER) end

local function group(parent, name, fn, role, first, ancestor)
 local m=Instance.new("Model"); m.Name=name
 local a={BundleId="Institution."..fn.."."..name..".FidelityR1",FunctionId=fn,ZoneId=fn,
 FidelityRole=role,PhaseMin=first,InheritanceRule="UPGRADE",Ancestor=ancestor,
 AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}
 for k,v in pairs(a) do m:SetAttribute(k,v) end
 m.Parent=parent; return m
end
local function box(m,n,pos,size,col,mat,solid,rot)
 local p=Instance.new("Part"); p.Name=n;p.Anchored=true;p.Size=size
 p.CFrame=CFrame.new(pos)*(rot or CFrame.identity);p.Color=col or C.Steel;p.Material=mat or M
 p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true
 p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("Phase2Geometry",true)
 p:SetAttribute("V5Blocker",solid==true)
 p.Parent=m;return p
end
local function cyl(m,n,pos,length,diam,col,axis,solid)
 local r=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
 local p=box(m,n,pos,Vector3.new(length,diam,diam),col,M,solid,r);p.Shape=Enum.PartType.Cylinder;return p
end
local function bar(m,n,a,b,width,col)
 local p=box(m,n,(a+b)/2,Vector3.new(width,width,(b-a).Magnitude),col,M,false)
 p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function point(m,n,pos,kind)
 local p=box(m,n,pos,Vector3.new(.15,.15,.15),C.Green,P,false)
 p.Transparency=1;p.CanQuery=false
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=p
 p:SetAttribute("AnchorKind",kind);m:SetAttribute(kind=="FX" and "FXSocket" or "InteractionAnchor",n)
 return p
end
local function adapt(m,fn,first,ancestor)
 for _,d in ipairs({m,table.unpack(m:GetDescendants())}) do
  if d:IsA("Model") then
   d:SetAttribute("FunctionId",fn);d:SetAttribute("ZoneId",fn)
   d:SetAttribute("PhaseMin",first);d:SetAttribute("Ancestor",ancestor)
   d:SetAttribute("AssetStatus","PROXY")
  elseif d:IsA("BasePart") then
   d:SetAttribute("Phase2Geometry",true);d:SetAttribute("V5Blocker",d.CanCollide)
   d.CanQuery=d.Transparency<1;d.CastShadow=d.CanCollide
  end
 end
 -- Shared reel declares this contract; resolve it on each placed connector.
 if m.Name=="Hose_Air_Reel" and not m:FindFirstChild("Utility_Active_Socket",true) then
  local a=Instance.new("Attachment");a.Name="Utility_Active_Socket";a.Parent=assert(m:FindFirstChild("QuickConnector"))
 end
 return m
end
local function serviceCF(x,z,side) return CFrame.new(x,.35,z)*CFrame.Angles(0,side*math.pi/2,0) end
local function taskLight(m,pos,length)
 local p=box(m,"ShieldedTaskLight",pos,Vector3.new(1.1,.3,length),C.WarmWhite,Enum.Material.Neon,false)
 local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Brightness=1.4;l.Range=17
 l.Angle=100;l.Shadows=false;l.Color=C.WarmWhite;l.Parent=p
end
local function drawers(m,x,z,side,width,count)
 for i=1,count do
  box(m,"Drawer",Vector3.new(x,1+i*.7,z),Vector3.new(4.8,.57,width),C.Navy,M,true)
  box(m,"Pull",Vector3.new(x-side*2.52,1+i*.7,z),Vector3.new(.17,.12,width*.55),C.Stainless,M,false)
 end
end
local function bench(m,x,z,side,width)
 box(m,"SteelWorktop",Vector3.new(x,4.85,z),Vector3.new(6.5,.4,width),C.Stainless,M,true)
 for _,dz in ipairs({-width/2+.5,width/2-.5}) do
  box(m,"BenchLeg",Vector3.new(x,2.6,z+dz),Vector3.new(5.8,4.5,.35),C.Charcoal,M,true)
 end
 box(m,"LowerShelf",Vector3.new(x,1,z),Vector3.new(5.8,.25,width-1),C.Steel,M,false)
 point(m,"BenchOperator",Vector3.new(x-side*5.8,.5,z),"OPERATOR")
end
local function floor(m,fn,x,z,col)
 local g=group(m,"01_Service_Floors",fn,"ARCHITECTURE","BIRTH","Original work slab")
 for i,off in ipairs({-12,12}) do
  box(g,"SealedDeck_"..i,Vector3.new(x,.64,z+off),Vector3.new(33,.12,14),col,Enum.Material.Concrete,false)
  for _,edge in ipairs({-7.25,7.25}) do
   box(g,"PaintedEdge",Vector3.new(x,.73,z+off+edge),Vector3.new(32,.03,.15),C.WarmWhite,P,false)
  end
 end
end
local function lift(parent,x,z,index)
 local m=group(parent,"Lift_"..index,"Mechanical","HERO","WORKING","Jack and portable tools -> Dedicated lift")
 for _,edge in ipairs({-8.65,8.65}) do
  box(m,"AnchoredFoot",Vector3.new(x,.8,z+edge),Vector3.new(3,.35,2.25),C.Steel,M,true)
  for _,dx in ipairs({-1,1}) do for _,dz in ipairs({-.75,.75}) do
   cyl(m,"AnchorNut",Vector3.new(x+dx,1.02,z+edge+dz),.16,.27,C.Galvanized,"Y")
  end end
  box(m,"ColumnChannel",Vector3.new(x,6.05,z+edge),Vector3.new(1.6,10.2,1.15),C.Red,M,true)
  for _,dx in ipairs({-.88,.88}) do box(m,"ColumnFlange",Vector3.new(x+dx,6.05,z+edge),Vector3.new(.22,10.2,1.5),C.Charcoal,M,false) end
  box(m,"SlideCarriage",Vector3.new(x,2.5,z+edge),Vector3.new(2.05,2.1,1.4),C.Steel,M,true)
  cyl(m,"HydraulicRam",Vector3.new(x+.5,6.2,z+edge),6.8,.26,C.Stainless,"Y")
  for _,dx in ipairs({-3.6,3.6}) do
   box(m,"ArmParked",Vector3.new(x+dx,1.12,z+edge),Vector3.new(5.4,.38,.6),C.Charcoal,M,false)
   box(m,"TelescopicExtension",Vector3.new(x+dx*1.55,1.13,z+edge),Vector3.new(2.5,.27,.45),C.Galvanized,M,false)
   cyl(m,"RubberContactPad",Vector3.new(x+dx*1.85,1.4,z+edge),.18,.72,C.Rubber,"Y")
  end
  bar(m,"HydraulicLine",Vector3.new(x-.5,2.5,z+edge-.4),Vector3.new(x-.5,10.8,z+edge-.4),.12,C.Rubber)
 end
 box(m,"EqualizerBridge",Vector3.new(x,11.4,z),Vector3.new(2.1,.65,18.5),C.Charcoal,M,true)
 box(m,"SafetyShutoffBar",Vector3.new(x,10.88,z),Vector3.new(.3,.2,15.4),C.Amber,M,false)
 box(m,"PumpReservoir",Vector3.new(x+1.55,4.1,z-8.7),Vector3.new(1.1,2.4,.8),C.Navy,M,true)
 cyl(m,"PumpMotor",Vector3.new(x+1.55,5.7,z-8.7),.9,.75,C.Steel,"Y")
 cyl(m,"RaiseButton",Vector3.new(x+2.15,4.3,z-8.7),.12,.28,C.Green,"X")
 m:SetAttribute("ParkedState","ARMS_FOLDED_OUTSIDE_VEHICLE_ENVELOPE")
 point(m,"LiftOperator",Vector3.new(x+4.2,.5,z-10.1),"OPERATOR")
 point(m,"LiftServiceFX",Vector3.new(x,3,z),"FX")
 taskLight(m,Vector3.new(x,11.05,z),10)
end

local function mechanical(parent)
 local fn="Mechanical";local d=group(parent,fn,fn,"ARCHITECTURE","BIRTH","Original shared repair yard")
 floor(d,fn,3066,175,C.OldConcrete)
 lift(d,3066,163,1);lift(d,3066,187,2)
 -- Working utilities occupy the outer service strip, facing the staff spine.
 local air=group(d,"Compressor_And_Air",fn,"UTILITY","WORKING","Portable compressor and airline")
 cyl(air,"Receiver",Vector3.new(3018,2.6,151),8,3.6,C.Navy,"Z",true)
 for _,z in ipairs({148.2,153.8}) do box(air,"ReceiverFoot",Vector3.new(3018,.85,z),Vector3.new(3.8,.5,.5),C.Steel,M,true) end
 cyl(air,"Motor",Vector3.new(3018,5.1,149.3),2.5,1.7,C.Steel,"Z")
 for _,dx in ipairs({-.7,.7}) do
  cyl(air,"PumpCylinder",Vector3.new(3018+dx,5.4,152),1.5,.8,C.Galvanized,"Y")
  for y=5,5.9,.3 do box(air,"CoolingFin",Vector3.new(3018+dx,y,152),Vector3.new(1,.1,1),C.Charcoal,M,false) end
 end
 cyl(air,"BeltGuard",Vector3.new(3018,5.25,151),.25,2.4,C.Charcoal,"Z")
 cyl(air,"PressureGauge",Vector3.new(3020,4.15,151),.25,.85,C.WarmWhite,"X")
 bar(air,"AirRiser",Vector3.new(3014,3,152),Vector3.new(3014,11,152),.23,C.Galvanized)
 bar(air,"AirMain",Vector3.new(3014,11,152),Vector3.new(3014,11,201),.23,C.Galvanized)
 for _,z in ipairs({166,188}) do
  bar(air,"ReelBranch",Vector3.new(3014,11,z),Vector3.new(3014,7,z),.16,C.Galvanized)
  adapt(Kit.CreateHoseReel(d,serviceCF(3014,z,-1),C.Red,"Institution.Mechanical.AirReel"..z..".FidelityR1"),fn,"WORKING","Portable airline")
 end
 point(air,"RegulatorAccess",Vector3.new(3023,.5,151),"OPERATOR")

 local scan=adapt(Kit.CreateToolCart(d,serviceCF(3021,162,-1),C.Red,"Institution.Mechanical.DiagnosticCart.FidelityR1"),fn,"WORKING","Handheld code reader")
 scan.Name="Diagnostic_Trolley"
 box(scan,"LaptopBase",Vector3.new(3021,5.5,162),Vector3.new(2.7,.16,3.4),C.Stainless,M,false)
 box(scan,"MonitorHousing",Vector3.new(3020,6.5,162),Vector3.new(.25,2,3.4),C.Charcoal,M,false)
 box(scan,"MonitorGlass",Vector3.new(3020.15,6.5,162),Vector3.new(.04,1.6,2.9),C.Navy,P,false)
 for i=1,5 do box(scan,"DiagnosticTrace",Vector3.new(3020.2,6.1+i*.16,161.8),Vector3.new(.04,.06,1.2+i*.19),C.Green,P,false) end
 bar(scan,"OBDLead",Vector3.new(3022,5.5,163),Vector3.new(3023,2.3,163.5),.13,C.Rubber)

 local engine=group(d,"Engine_Rebuild_Stand",fn,"HERO","DEDICATED","Manual service bench and rotating stand")
 for _,z in ipairs({173,179}) do
  box(engine,"StandFoot",Vector3.new(3020,.9,z),Vector3.new(6,.35,.6),C.Red,M,true)
  for _,x in ipairs({3017.5,3022.5}) do cyl(engine,"Caster",Vector3.new(x,.75,z),.35,.7,C.Rubber,"X") end
 end
 box(engine,"StandSpine",Vector3.new(3018.5,1.1,176),Vector3.new(.7,.7,6.5),C.Red,M,true)
 box(engine,"RotatingUpright",Vector3.new(3018.5,3,176),Vector3.new(.85,4.2,.85),C.Red,M,true)
 cyl(engine,"RotisserieHead",Vector3.new(3019.2,4.8,176),2,.7,C.Galvanized,"X")
 box(engine,"CastCrankcase",Vector3.new(3021,4.8,176),Vector3.new(3.2,1.8,4.5),C.Steel,M,true)
 box(engine,"Sump",Vector3.new(3021,3.65,176),Vector3.new(2.7,.6,4.1),C.Charcoal,M,false)
 for _,dx in ipairs({-1.1,1.1}) do
  box(engine,"CylinderHead",Vector3.new(3021+dx,5.8,176),Vector3.new(1.5,1.25,4.3),C.Galvanized,M,false,CFrame.Angles(0,0,dx*.3))
  box(engine,"RibbedValveCover",Vector3.new(3021+dx,6.55,176),Vector3.new(1.3,.3,4.1),C.Red,M,false)
  for z=174.6,177.4,.7 do
   box(engine,"CoverRib",Vector3.new(3021+dx,6.75,z),Vector3.new(1.1,.1,.09),C.Stainless,M,false)
   bar(engine,"ExhaustPrimary",Vector3.new(3021+dx,5.3,z),Vector3.new(3021+dx*1.8,4.3,z+.15),.25,C.Bronze)
  end
 end
 cyl(engine,"CrankPulley",Vector3.new(3021,4.8,173.5),.35,1.55,C.Charcoal,"Z")
 cyl(engine,"Alternator",Vector3.new(3022.5,5.3,173.6),.85,.95,C.Galvanized,"Z")
 box(engine,"IntakePlenum",Vector3.new(3021,6.2,176),Vector3.new(.8,.8,3.6),C.Charcoal,M,false)
 point(engine,"EngineWorkside",Vector3.new(3026,.5,176),"OPERATOR")

 local tools=group(d,"Tool_Bench_And_Vice",fn,"SUPPORT","BIRTH","Tool crate -> mobile chest -> fitted bench")
 bench(tools,3019,193,-1,11);drawers(tools,3019,193,-1,9,4)
 box(tools,"ToolBackboard",Vector3.new(3014.5,7.2,193),Vector3.new(.35,4.5,12),C.Charcoal,M,true)
 for i=1,7 do
  local z=188.5+i*1.05
  bar(tools,"WrenchShank",Vector3.new(3014.9,6.2,z),Vector3.new(3014.9,8.1-(i%3)*.22,z),.17,C.Stainless)
  cyl(tools,"WrenchHead",Vector3.new(3014.9,8.25-(i%3)*.22,z),.16,.48,C.Stainless,"X")
 end
 box(tools,"ViceBase",Vector3.new(3020,5.2,197),Vector3.new(2,.35,2),C.Steel,M,false)
 for _,z in ipairs({196.5,197.5}) do box(tools,"ViceJaw",Vector3.new(3020,5.65,z),Vector3.new(1.8,.65,.3),C.Galvanized,M,false) end
 cyl(tools,"ViceScrew",Vector3.new(3020,5.5,197.7),1.8,.18,C.Stainless,"Z")
 box(tools,"HardwareTray",Vector3.new(3019,5.2,190),Vector3.new(2.5,.2,3),C.Charcoal,M,false)
 for i=1,4 do cyl(tools,"Socket",Vector3.new(3019,5.5,188.7+i*.45),.4,.25+i*.03,C.Stainless,"Y") end

 local fluids=group(d,"Contained_Fluids",fn,"UTILITY","WORKING","Drain pan -> contained fluid collection")
 box(fluids,"BundedTray",Vector3.new(3020,.9,201),Vector3.new(9,.5,4),C.Charcoal,M,true)
 for _,x in ipairs({3017.5,3021.8}) do
  cyl(fluids,"WasteReceiver",Vector3.new(x,2.8,201),3.6,2.6,C.Steel,"Y",true)
  cyl(fluids,"DrainStem",Vector3.new(x,5.1,201),2.8,.2,C.Galvanized,"Y")
  cyl(fluids,"DrainBowl",Vector3.new(x,6.5,201),.3,2.7,C.Charcoal,"Y")
 end
 point(fluids,"FluidWorkside",Vector3.new(3026,.5,201),"OPERATOR")
 local cooling=group(d,"Cooling_Pressure_Test_Trolley",fn,"SUPPORT","WORKING","Coolant jug and manual pressure test -> contained service trolley")
 box(cooling,"WheeledCradle",Vector3.new(3040,1.1,175),Vector3.new(5,.4,7),C.Red,M,true)
 for _,x in ipairs({3038,3042}) do for _,z in ipairs({172.2,177.8}) do
  cyl(cooling,"Caster",Vector3.new(x,.85,z),.35,.85,C.Rubber,"X")
 end end
 box(cooling,"RadiatorCore",Vector3.new(3040,4,175),Vector3.new(.8,4.5,5.8),C.Charcoal,M,true)
 for _,z in ipairs({171.8,178.2}) do box(cooling,"HeaderTank",Vector3.new(3040,4,z),Vector3.new(1.2,4.9,.6),C.Navy,M,true) end
 for y=2,6,.35 do box(cooling,"CoolingFin",Vector3.new(3040.5,y,175),Vector3.new(.12,.10,5.7),C.Galvanized,M,false) end
 cyl(cooling,"PressureCap",Vector3.new(3040,6.6,171.8),.3,.65,C.Bronze,"Y")
 cyl(cooling,"TestGauge",Vector3.new(3040.9,6.7,173),.22,1,C.WarmWhite,"X")
 bar(cooling,"GaugeNeedle",Vector3.new(3041.03,6.7,173),Vector3.new(3041.03,6.95,172.75),.065,C.Charcoal)
 bar(cooling,"TestHose",Vector3.new(3040.8,6.5,173),Vector3.new(3040,6.7,171.8),.15,C.Rubber)
 cyl(cooling,"RecoveryBottle",Vector3.new(3041.6,2.3,177),1.9,1.3,C.CleanPanel,"Y")
 point(cooling,"CoolingOperator",Vector3.new(3044,.5,175),"OPERATOR")
 point(cooling,"CoolantServiceFX",Vector3.new(3040,6.7,171.8),"FX")
 taskLight(tools,Vector3.new(3020,10.4,190),10)
 adapt(Kit.CreateSafetyStation(d,serviceCF(3014,183,-1),C.Red,"Institution.Mechanical.Safety.FidelityR1"),fn,"WORKING","Portable extinguisher and PPE")
 return d
end

local function finishCell(d,x,z,index)
 local fn="Paint_Exterior"
 local m=group(d,"Filtered_Finish_Cell_"..index,fn,"HERO","DEDICATED","Basic controlled booth -> filtered finish cell")
 for _,dz in ipairs({-8.65,8.65}) do
  box(m,"WashableLowerPanel",Vector3.new(x,1.9,z+dz),Vector3.new(32,2.3,.45),C.CleanPanel,M,true)
  box(m,"UpperPanel",Vector3.new(x,10.2,z+dz),Vector3.new(32,2.0,.45),C.CleanPanel,M,true)
  for _,dx in ipairs({-15.7,-5.3,5.3,15.7}) do box(m,"PanelFrame",Vector3.new(x+dx,6,z+dz),Vector3.new(.32,10.7,.7),C.Navy,M,true) end
  for _,dx in ipairs({-10.5,0,10.5}) do
   local glass=box(m,"ObservationGlass",Vector3.new(x+dx,6.05,z+dz),Vector3.new(10,6,.16),C.Glass,Enum.Material.Glass,false)
   glass.Transparency=.7
  end
  for _,dx in ipairs({-9,9}) do box(m,"ColourCheckLamp",Vector3.new(x+dx,8.4,z+dz*.97),Vector3.new(4,.26,.25),C.WarmWhite,Enum.Material.Neon,false) end
 end
 -- The access end remains completely open in the route proof.
 box(m,"RearFilterFrame",Vector3.new(x+18.2,6,z),Vector3.new(1.1,10.7,17.5),C.Navy,M,true)
 for i=-2,2 do
  box(m,"ExtractionFilterCassette",Vector3.new(x+17.57,5.8,z+i*3.15),Vector3.new(.22,8.4,2.9),C.WarmWhite,Enum.Material.Fabric,false)
  for y=2.4,9.2,1.7 do box(m,"CassetteCrossbar",Vector3.new(x+17.35,y,z+i*3.15),Vector3.new(.18,.12,2.9),C.Galvanized,M,false) end
 end
 for _,dx in ipairs({-10,0,10}) do
  box(m,"CeilingSupplyCassette",Vector3.new(x+dx,11.25,z),Vector3.new(9.7,.65,17.7),C.CleanPanel,M,true)
  for _,dz in ipairs({-4.1,4.1}) do
   box(m,"CeilingFilter",Vector3.new(x+dx,10.88,z+dz),Vector3.new(8.6,.08,6.7),C.WarmWhite,Enum.Material.Fabric,false)
  end
 end
 box(m,"EntranceHeader",Vector3.new(x-16,11.7,z),Vector3.new(.7,.65,18),C.Navy,M,true)
 box(m,"FlushContaminationThreshold",Vector3.new(x-16,.75,z),Vector3.new(2,.06,14),C.OldConcrete,P,false)
 for i=-5,5 do box(m,"ThresholdGrate",Vector3.new(x-16,.8,z+i*1.2),Vector3.new(1.8,.04,.12),C.Galvanized,M,false) end
 m:SetAttribute("DoorState","OPEN_FOR_VEHICLE_ACCESS")
 m:SetAttribute("ProcessState","IDLE_REVIEW_NO_SPRAY")
 point(m,"PaintCarFX",Vector3.new(x,4,z),"FX")
 taskLight(m,Vector3.new(x,10.72,z),10)
 local c=adapt(Kit.CreateControlStation(d,serviceCF(x+23,z,1),C.Green,"Institution.Paint_Exterior.CellControl"..index..".FidelityR1"),fn,"DEDICATED","Basic booth controls")
 c.Name="Cell_Control_"..index
 return m
end
local function paint(parent)
 local fn="Paint_Exterior";local d=group(parent,fn,fn,"ARCHITECTURE","WORKING","Outdoor touch-up -> controlled finish")
 floor(d,fn,3194,307,Color3.fromRGB(159,164,160))
 finishCell(d,3194,295,1);finishCell(d,3194,319,2)
 local mix=group(d,"Mix_Bank_And_Rare_Finishes",fn,"HERO","DEDICATED","Basic mixing -> professional matching -> rare finishes")
 bench(mix,3240,285,1,17)
 box(mix,"MixerBack",Vector3.new(3246.8,7,285),Vector3.new(.45,5,18),C.Navy,M,true)
 for level=0,1 do
  box(mix,"TinterShelf",Vector3.new(3245,5.6+level*2,285),Vector3.new(3.6,.15,17),C.Stainless,M,false)
  for i=0,5 do
   local z=278+i*2.7
   cyl(mix,"TinterCan",Vector3.new(3245,6.4+level*2,z),1.45,1.15,C.CleanPanel,"Y")
   cyl(mix,"AgitatorLid",Vector3.new(3245,7.2+level*2,z),.2,1.25,C.Charcoal,"Y")
   box(mix,"PourSpout",Vector3.new(3244.2,7+level*2,z),Vector3.new(.75,.18,.28),C.Stainless,M,false)
  end
 end
 box(mix,"PrecisionScale",Vector3.new(3239,5.22,283),Vector3.new(2.5,.4,2.8),C.Navy,M,false)
 cyl(mix,"ScalePan",Vector3.new(3239,5.51,283),.13,2,C.Stainless,"Y")
 cyl(mix,"MixingCup",Vector3.new(3239,6.1,283),1.05,1.2,C.WarmWhite,"Y")
 for i=0,5 do
  local col=({C.Bronze,C.Red,C.Navy,C.Green,C.WarmWhite,C.Glass})[i+1]
  local sw=box(mix,"CurvedFinishSample",Vector3.new(3246.3,10.5,278+i*2.7),Vector3.new(.28,1.65,2.1),col,M,false,CFrame.Angles(0,0,math.rad(-9)))
  sw:SetAttribute("FinishFamily",({"Candy","Heritage","Metallic","Pearl","Solid","Iridescent"})[i+1])
 end
 local shaker=group(d,"Paint_Shaker_And_Match",fn,"SUPPORT","PROFESSIONAL","Manual mix and colour cards")
 box(shaker,"IsolatedBase",Vector3.new(3241,1,299),Vector3.new(6,.6,6),C.Charcoal,M,true)
 for _,z in ipairs({296.6,301.4}) do box(shaker,"SideHousing",Vector3.new(3241,3.7,z),Vector3.new(5.2,5,.35),C.CleanPanel,M,true) end
 box(shaker,"BackHousing",Vector3.new(3243.5,3.7,299),Vector3.new(.35,5,4.8),C.Navy,M,true)
 for _,y in ipairs({1.7,5.8}) do box(shaker,"ClampFrame",Vector3.new(3241,y,299),Vector3.new(5.2,.7,5),C.CleanPanel,M,true) end
 cyl(shaker,"PaintCan",Vector3.new(3240.6,3.7,299),2.6,2.2,C.Galvanized,"Y",true)
 for _,y in ipairs({2.3,5.1}) do cyl(shaker,"PressurePlate",Vector3.new(3240.6,y,299),.28,2.8,C.Charcoal,"Y") end
 for _,z in ipairs({297.25,300.75}) do cyl(shaker,"ClampGuide",Vector3.new(3240.6,3.7,z),3.2,.25,C.Stainless,"Y") end
 local window=box(shaker,"GuardWindow",Vector3.new(3238.3,3.7,299),Vector3.new(.12,3.4,4.1),C.Glass,Enum.Material.Glass,false);window.Transparency=.72
 box(shaker,"OperatorHandle",Vector3.new(3238,4.6,300.8),Vector3.new(.2,1.1,.2),C.Stainless,M,false)
 cyl(shaker,"StartButton",Vector3.new(3238.26,5.8,298.5),.12,.3,C.Green,"X")
 cyl(shaker,"EmergencyStop",Vector3.new(3238.26,5.8,299.5),.17,.35,C.Red,"X")
 point(shaker,"MixOperator",Vector3.new(3235,.5,299),"OPERATOR")

 local guns=group(d,"Spray_Gun_Service",fn,"UTILITY","DEDICATED","Portable spray gun and protected air")
 box(guns,"SinkCabinet",Vector3.new(3242,2.4,307),Vector3.new(6.5,3.2,5),C.Stainless,M,true)
 box(guns,"RecessedBasin",Vector3.new(3242,4.1,307),Vector3.new(6.5,.2,5),C.Charcoal,M,false)
 for _,z in ipairs({304.35,309.65}) do box(guns,"BasinEnd",Vector3.new(3242,4.55,z),Vector3.new(7,1,.25),C.Stainless,M,true) end
 for _,x in ipairs({3238.65,3245.35}) do box(guns,"BasinSide",Vector3.new(x,4.55,307),Vector3.new(.25,1,5.5),C.Stainless,M,true) end
 cyl(guns,"DrainStrainer",Vector3.new(3242,4.22,307),.1,.65,C.Galvanized,"Y")
 bar(guns,"TapRiser",Vector3.new(3245,4.8,307),Vector3.new(3245,5.8,307),.22,C.Stainless)
 bar(guns,"TapSpout",Vector3.new(3245,5.8,307),Vector3.new(3243.6,5.8,307),.22,C.Stainless)
 for _,z in ipairs({304.8,309.2}) do bar(guns,"RackBracket",Vector3.new(3244,4.8,z),Vector3.new(3244,6.4,z),.2,C.Navy) end
 bar(guns,"GunRack",Vector3.new(3244,6.1,304.8),Vector3.new(3244,6.1,309.2),.3,C.Navy)
 for _,z in ipairs({305.7,308.3}) do
  bar(guns,"SprayBarrel",Vector3.new(3243,6.3,z),Vector3.new(3241.2,6.3,z),.25,C.Galvanized)
  bar(guns,"GunGrip",Vector3.new(3242.5,6.3,z),Vector3.new(3242.8,5.55,z),.25,C.Charcoal)
  cyl(guns,"GravityCup",Vector3.new(3242.2,7.15,z),1.1,.9,C.WarmWhite,"Y")
  cyl(guns,"AirConnector",Vector3.new(3242.8,5.45,z),.3,.25,C.Bronze,"Y")
  bar(guns,"GunHolster",Vector3.new(3244,6.1,z),Vector3.new(3242.8,6.1,z),.18,C.Stainless)
 end
 adapt(Kit.CreateHoseReel(d,serviceCF(3246,314,1),C.Green,"Institution.Paint_Exterior.FilteredAir.FidelityR1"),fn,"DEDICATED","Portable clean-air supply")
 local duct=group(d,"Filtered_Air_And_Extraction",fn,"UTILITY","DEDICATED","Basic booth ventilation")
 box(duct,"ServicePlenum",Vector3.new(3242,12,307),Vector3.new(7,2,45),C.Galvanized,M,true)
 for _,z in ipairs({295,319}) do
  box(duct,"ExtractionDuct",Vector3.new(3229,12,z),Vector3.new(25,1.9,3),C.Galvanized,M,true)
  box(duct,"AccessPanel",Vector3.new(3242,13.1,z),Vector3.new(5,.12,4),C.Steel,M,false)
 end
 point(duct,"AirflowSocket",Vector3.new(3242,12,307),"FX")

 local film=group(d,"Film_Cutting_And_Glass",fn,"SUPPORT","DEDICATED","Manual wrap/tint -> organized cutting")
 bench(film,3240,321,1,10)
 local glass=box(film,"PaddedGlassTemplate",Vector3.new(3240,5.16,321),Vector3.new(5.2,.12,8.3),C.Glass,Enum.Material.Glass,false)
 glass.Transparency=.25
 box(film,"TintFilmSheet",Vector3.new(3239.7,5.27,321),Vector3.new(4.1,.05,6.2),C.Navy,P,false)
 box(film,"CuttingRail",Vector3.new(3242.5,5.4,321),Vector3.new(.25,.2,8.8),C.Stainless,M,false)
 box(film,"Squeegee",Vector3.new(3238.5,5.42,324.5),Vector3.new(1.2,.14,.6),C.Amber,P,false)
 cyl(film,"HeatGunBarrel",Vector3.new(3241,5.7,324.5),1.3,.5,C.Charcoal,"Z")
 box(film,"HeatGunGrip",Vector3.new(3241,5.35,325),Vector3.new(.35,.6,.4),C.Navy,P,false)
 local rolls=group(d,"Wrap_And_Tint_Roll_Rack",fn,"SUPPORT","DEDICATED","Hand-applied vinyl rolls")
 for _,z in ipairs({329,337}) do box(rolls,"RackUpright",Vector3.new(3245,4.7,z),Vector3.new(.4,8,.4),C.Charcoal,M,true) end
 for i=0,3 do
  local y=1.5+i*1.8
  bar(rolls,"RollAxle",Vector3.new(3245,y,328.7),Vector3.new(3245,y,337.3),.2,C.Galvanized)
  cyl(rolls,"FilmRoll",Vector3.new(3245,y,333),7.5,1.0,({C.Navy,C.Glass,C.WarmWhite,C.Bronze})[i+1],"Z")
  cyl(rolls,"CardboardCore",Vector3.new(3245,y,329),.35,.36,C.Timber,"Z")
 end
 local cure=group(d,"Parked_IR_Curing_Lamp",fn,"UTILITY","PROFESSIONAL","Air drying -> directed curing")
 box(cure,"WheeledBase",Vector3.new(3238,1,333),Vector3.new(5,.4,4),C.Charcoal,M,true)
 cyl(cure,"TelescopicMast",Vector3.new(3238,4,333),6,.4,C.Stainless,"Y")
 for _,z in ipairs({331.8,333,334.2}) do
  box(cure,"ReflectorHousing",Vector3.new(3237.7,7,z),Vector3.new(.75,3,1.05),C.Navy,M,true)
  box(cure,"IRReflector",Vector3.new(3237.25,7,z),Vector3.new(.1,2.6,.85),C.Bronze,M,false)
 end
 cure:SetAttribute("ParkedState","STOWED_OUTSIDE_STAFF_AISLE")
 point(cure,"CureOperator",Vector3.new(3234.5,.5,333),"OPERATOR")
 adapt(Kit.CreateSafetyStation(d,serviceCF(3246,275.5,1),C.Amber,"Institution.Paint_Exterior.PPE.FidelityR1"),fn,"DEDICATED","Respirator and portable fire station")
 local chemicals=group(d,"Contained_Chemical_Cabinet",fn,"UTILITY","DEDICATED","Sealed consumables -> ventilated chemical storage")
 box(chemicals,"BundedPlinth",Vector3.new(3238,.8,275.5),Vector3.new(5.5,.5,4),C.Charcoal,M,true)
 box(chemicals,"DoubleSkinCabinet",Vector3.new(3238,3.5,275.5),Vector3.new(4.6,5,3.5),C.Amber,M,true)
 for _,z in ipairs({274.65,276.35}) do
  box(chemicals,"DoorInset",Vector3.new(3235.62,3.55,z),Vector3.new(.14,4.6,1.55),C.CleanPanel,M,false)
  box(chemicals,"Latch",Vector3.new(3235.5,3.6,z),Vector3.new(.2,.65,.13),C.Charcoal,M,false)
 end
 for y=4.7,5.5,.25 do box(chemicals,"VentLouvre",Vector3.new(3235.45,y,275.5),Vector3.new(.1,.09,2.6),C.Charcoal,M,false) end
 point(chemicals,"ChemicalAccess",Vector3.new(3234,.5,275.5),"OPERATOR")
 taskLight(mix,Vector3.new(3240,11.5,285),13)
 return d
end

-- Saved property state lives inside the owned layer, survives module reloads.
local function suppress(owner,target)
 local records=owner:FindFirstChild("90_Restoration") or Instance.new("Folder")
 records.Name="90_Restoration";records.Parent=owner
 local list=target:GetDescendants();table.insert(list,1,target)
 for _,o in ipairs(list) do
  if o:IsA("BasePart") or o:IsA("Light") or o:IsA("SurfaceGui") or o:IsA("BillboardGui") then
   local r=Instance.new("ObjectValue");r.Name="Saved_"..o.Name;r.Value=o;r.Parent=records
   if o:IsA("BasePart") then
    for _,k in ipairs({"Transparency","CanCollide","CanTouch","CanQuery","CastShadow"}) do r:SetAttribute(k,o[k]) end
    o.Transparency=1;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
   else r:SetAttribute("Enabled",o.Enabled);o.Enabled=false end
  end
 end
end
local function restore(owner)
 local rs=owner:FindFirstChild("90_Restoration")
 if rs then for _,r in ipairs(rs:GetChildren()) do
  if r:IsA("ObjectValue") and r.Value then for k,v in pairs(r:GetAttributes()) do r.Value[k]=v end end
 end end
end
local function signature(m)
 local rows={}
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then
  local cf={p.CFrame:GetComponents()}
  local vals={}
  for _,v in ipairs(cf) do table.insert(vals,string.format("%.3f",v)) end
  table.insert(rows,p:GetFullName().."|"..table.concat(vals,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.Transparency))
 end end
 table.sort(rows);local h=5381
 for _,s in ipairs(rows) do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end
 return string.format("%08x",h)
end
function I.Uninstall()
 local l=layer();if l then restore(l);l:Destroy() end
 root():SetAttribute("InstitutionFidelityPhase2Status",nil)
 return true
end
function I.Install()
 I.Uninstall()
 assert(root():GetAttribute("InstitutionFidelityPhase1Status")=="ACCEPTED","Shared kit gate required")
 local f=root()["10_Institution_Fidelity_R1"]
 local l=Instance.new("Model");l.Name=LAYER;l.Parent=f
 l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW")
 local ok,err=pcall(function()
  for _,fn in ipairs({"Mechanical","Paint_Exterior"}) do
   local d=root()["08_Institution_Production_A"][fn]
   for _,child in ipairs(d:GetChildren()) do
    if child.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,child) end
   end
   suppress(l,d["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  end
  local proof=f["00_Shared_Kit"]:FindFirstChild("01_Proof_Rack");if proof then suppress(l,proof) end
  mechanical(l);paint(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("GeometrySignature",signature(l))
 root():SetAttribute("InstitutionFidelityPhase2Status","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local parts,solids,models,lights=0,0,0,0;local issues={};local metadataIssues={};local ids={}
 local protected={}
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do
  if p:IsA("BasePart") then table.insert(protected,{cf=p.CFrame,size=p.Size,name=p.Name}) end
 end
 for _,r in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if r:IsA("BasePart") then
  table.insert(protected,{cf=r.CFrame+Vector3.new(0,4.2,0),size=Vector3.new(r.Size.X,7,r.Size.Z),name=r.Name})
 end end
 table.insert(protected,{cf=CFrame.new(3031,4.5,175),size=Vector3.new(6,7.5,52),name="MechanicalStaffAisle"})
 table.insert(protected,{cf=CFrame.new(3229,4.5,307),size=Vector3.new(6,7.5,62),name="PaintStaffAisle"})
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 for _,e in ipairs(protected) do
  for _,p in ipairs(workspace:GetPartBoundsInBox(e.cf,e.size,params)) do
   if p:IsA("BasePart") and p.Transparency<.98 and p.Position.Y+p.Size.Y/2>.88 then
    table.insert(issues,e.name..": "..p:GetFullName())
   end
  end
 end
 local functions={}
 for _,fn in ipairs({"Mechanical","Paint_Exterior"}) do
  local dp,dm=0,0
  for _,p in ipairs(l[fn]:GetDescendants()) do if p:IsA("BasePart") then dp+=1 elseif p:IsA("Model") then dm+=1 end end
  functions[fn]={parts=dp,assemblies=dm}
 end
 for _,p in ipairs(l:GetDescendants()) do
  if p:IsA("BasePart") then parts+=1;if p.CanCollide then solids+=1 end
  elseif p:IsA("Model") then
   models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket","Ancestor"}) do
    if p:GetAttribute(k)==nil then table.insert(metadataIssues,p.Name..": missing "..k) end
   end
   local id=p:GetAttribute("BundleId")
   if id then if ids[id] then table.insert(metadataIssues,"Duplicate bundle: "..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do
    local n=p:GetAttribute(k)
    if n and n~="" and not p:FindFirstChild(n,true) then table.insert(metadataIssues,p.Name..": unresolved "..n) end
   end
  elseif p:IsA("Light") then lights+=1 end
 end
 l:SetAttribute("StaticConflicts",#issues);l:SetAttribute("Parts",parts)
 return {parts=parts,solids=solids,models=models,lights=lights,issues=issues,metadataIssues=metadataIssues,functions=functions,signature=signature(l)}
end
function I.Accept(evidence)
 local l=assert(layer());local audit=I.Audit();assert(#audit.issues==0,"Static conflicts remain")
 assert(#audit.metadataIssues==0,"Metadata or attachment contracts unresolved")
 assert(evidence.VisualPass and evidence.RoutePass and evidence.RollbackPass,"Required evidence missing")
 local folder=l:FindFirstChild("99_Evidence") or Instance.new("Folder");folder.Name="99_Evidence";folder.Parent=l
 for k,v in pairs(evidence) do folder:SetAttribute(k,v) end
 for _,m in ipairs(l:GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 l:SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase2Status","ACCEPTED")
 return audit
end
return I

