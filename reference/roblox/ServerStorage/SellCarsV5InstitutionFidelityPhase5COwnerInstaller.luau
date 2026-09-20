--!nocheck
-- Phase 5C owns Owner Garage only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase5c.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","04_Frontage_And_Owner","03_Owner"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Owner_Garage."..n..".FidelityR1",FunctionId="Owner_Garage",ZoneId="Owner_Garage",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase5COwnerGeometry",true);p.Parent=m;return p
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






local function station(m,left,z)
 local cf=CFrame.new(left and 3185.4 or 3250.6,0,z)*CFrame.Angles(0,left and -math.pi/2 or math.pi/2,0)
 local function B(n,x,y,z,w,h,d,c,mat,solid,rot)
  local v=cf:PointToWorldSpace(Vector3.new(x,y,z))
  return box(m,n,v.X,v.Y,v.Z,w,h,d,c,mat,solid,cf.Rotation*(rot or CFrame.identity))
 end
 local function CY(n,x,y,z,len,diam,c,axis,solid)
  local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
  local p=B(n,x,y,z,len,diam,diam,c,M,solid,rot);p.Shape=Enum.PartType.Cylinder;return p
 end
 local function PIPE(n,a,b,d,c) return pipe(m,n,cf:PointToWorldSpace(a),cf:PointToWorldSpace(b),d,c) end
 return B,CY,PIPE
end
local function panel(m,n,x,y,z,w,h,value)
 local p=box(m,n,x,y,z,w,h,.16,C.Charcoal,M,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(720,140);g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.Text=value;t.TextScaled=true;t.TextColor3=C.WarmWhite;t.Parent=g
 return p
end
local function shell(l)
 local m=group(l,"Personal_Workshop_Shell","ARCHITECTURE","DEDICATED","Secure private bay -> permanent personal workshop with crafted shade")
 box(m,"OwnerRoof",3218,15,54,74,1.2,94,C.Charcoal,M,false)
 for x=3184,3252,8 do box(m,"StandingRoofSeam",x,15.67,54,.12,.1,93,C.Steel,M,false) end
 for _,z in ipairs({10,43,71,98}) do
  box(m,"RoofBeamWeb",3218,14,z,73,.7,.22,C.Steel,M,false)
  for _,y in ipairs({13.62,14.38}) do box(m,"BeamFlange",3218,y,z,73,.12,.8,C.Charcoal,M,false) end
 end
 for _,x in ipairs({3182,3254}) do
  box(m,"RetainedBrickPlinth",x,2.5,54,1.2,4.2,92,C.Brick,Enum.Material.Brick,true)
  box(m,"WorkshopWallPanel",x,7.8,54,1.2,6.4,92,C.CleanPanel,P,true)
  local pane=box(m,"ClerestoryGlass",x,12.75,54,.3,3.4,90,C.Galvanized,Enum.Material.Glass,false);pane.Transparency=.76
  for _,z in ipairs({9,25,43,59,75,99}) do
   box(m,"WallStructure",x,7.5,z,1.3,15,.35,C.Steel,M,true)
   local inside=x<3218 and x+.72 or x-.72
   box(m,"PanelJoint",inside,7.8,z,.06,6.35,.07,C.OldConcrete,P,false)
   box(m,"RoofKneePlate",inside,13.9,z,.15,.8,1.8,C.Galvanized,M,false)
  end
  box(m,"ClerestoryHead",x,14.6,54,.9,.25,92,C.Steel,M,false)
  box(m,"WindowSill",x,11.08,54,1.3,.16,92,C.Galvanized,M,false)
  box(m,"EavesGutter",x,15,54,.8,.45,94,C.Galvanized,M,false)
 end
 for _,s in ipairs({{3198,31},{3240,27}}) do
  box(m,"RearBrickPlinth",s[1],2.5,100,s[2],4.2,1,C.Brick,Enum.Material.Brick,true)
  box(m,"RearCleanPanel",s[1],9.5,100,s[2],9.8,1,C.CleanPanel,P,true)
 end
 -- Original rear pedestrian gap3213.5..3226.5 remains a real opening.
 box(m,"RearDoorHeader",3220,14,100,13,1.2,1,C.Steel,M,false)
 box(m,"RoadHeader",3218,12.4,9,60,4,1.1,C.Charcoal,M,false)
 for x=3190,3246,2.8 do box(m,"RoadHeaderTimber",x,12.4,8.36,2.1,2.8,.13,C.Timber,Enum.Material.Wood,false) end
 panel(m,"PrivateWorkshopIdentity",3218,12.4,8.1,24,1.9,"DESERT CUSTOMS  /  PRIVATE WORKSHOP")
 for _,x in ipairs({3191,3245}) do
  local p=box(m,"DiffuseWorkshopRail",x,13.5,55,1.2,.15,82,C.WarmWhite,Enum.Material.Neon,false)
  local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Range=21;light.Brightness=1.5;light.Color=C.WarmWhite;light.Shadows=false;light.Parent=p
 end
 point(m,"OwnerWorkshopAmbience",3218,13.1,60,"FX")
end
local function fleet(l,index,x,z)
 local m=group(l,"Personal_Fleet_Setting_"..index,"HERO","PROFESSIONAL","One kept car with hand tools -> dedicated personal fleet setting")
 m:SetAttribute("ExistingCarRetained",true);m:SetAttribute("OwnerPosition",index);m:SetAttribute("DealerInventoryAccepted",false)
 box(m,"PersonalFloorInset",x,.65,z,13.5,.12,21.5,C.OldConcrete,Enum.Material.Slate,false)
 for _,dx in ipairs({-6.6,6.6}) do box(m,"BrassFloorInlay",x+dx,.73,z,.07,.03,21,C.Bronze,M,false) end
 box(m,"ShieldedPersonalLight",x,14.1,z,9,.15,.75,C.WarmWhite,Enum.Material.Neon,false)
 for _,dx in ipairs({-4.1,4.1}) do pipe(m,"FixtureSuspension",Vector3.new(x+dx,14.15,z),Vector3.new(x+dx,14.4,z),.1,C.Steel) end
 local left=x<3218;local B,CY,PIPE=station(m,left,z-9)
 B("TenderServiceBackplate",0,4.6,1.5,3,4.8,.14,C.Steel,M,false)
 B("BatteryTenderHousing",0,5.3,1,2.3,1.8,.7,C.Charcoal,P,false)
 B("TenderDisplay",0,5.6,.59,1.1,.45,.035,C.Galvanized,P,false)
 for i=-1,1 do B("ChargeStateIndicator",i*.4,5.05,.56,.15,.13,.025,i==0 and C.Green or C.Steel,P,false) end
 CY("TenderCableDrum",0,3.25,1,.7,1.7,C.Charcoal,"Z")
 for i=0,9 do local a=math.pi*2*i/10;local b=math.pi*2*(i+1)/10
  PIPE("ParkedCableLoop",Vector3.new(math.cos(a)*.69,3.25+math.sin(a)*.69,.58),Vector3.new(math.cos(b)*.69,3.25+math.sin(b)*.69,.58),.10,C.Rubber)
 end
 B("ParkedTenderConnector",1.1,3.1,.7,.35,.9,.5,C.Bronze,P,false)
 PIPE("FixedElectricalFeed",Vector3.new(0,6.3,1.2),Vector3.new(0,10,1.2),.13,C.Galvanized)
 B("SocketIsolator",0,9.5,1.1,.7,1,.4,C.CleanPanel,P,false)
 point(m,"TenderOperator_"..index,left and 3191.5 or 3244.5,.6,z-9,"OPERATOR")
 point(m,"TenderSocket_"..index,left and 3187 or 3249,4.0,z-9,"FX")
 m:SetAttribute("ParkedState","CABLE_AND_CONNECTOR_STOWED_NO_LIVE_CHARGING")
end
local function configuration(l)
 local m=group(l,"Personal_Configuration_Studio","HERO","PROFESSIONAL","Personal setup desk -> curated wheel colour and build configuration")
 local B,CY,PIPE=station(m,true,86)
 B("OakConfigurationWorktop",0,3.6,0,17,.35,4.5,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({-6.4,6.4}) do
  B("DrawerPedestal",x,2.15,.2,3,2.5,3.9,C.Charcoal,M,true)
  for y=1.3,3,.65 do B("DrawerFront",x,y,-1.81,2.7,.52,.12,C.Steel,M,false);B("DrawerPull",x,y,-1.97,1.5,.1,.18,C.Stainless,M,false) end
 end
 B("ConfigurationScreenFrame",-2,5.8,.6,5.3,3,.28,C.Charcoal,P,false)
 local screen=B("ConfigurationPreview",-2,5.8,.43,4.9,2.6,.03,Color3.fromRGB(55,74,78),P,false)
 screen:SetAttribute("DataBindingKey","OWNER_GARAGE_CONFIG_AND_RARE_PARTS");screen:SetAttribute("RuntimeBinding","PENDING")
 B("ScreenSupport",-2,4.2,.6,.45,1.4,.3,C.Steel,M,false)
 B("Keyboard",-2,3.84,-1.1,3.3,.13,1.15,C.Charcoal,P,false)
 for row=0,2 do B("KeyRows",-2,3.92,-1.5+row*.3,2.9,.045,.16,C.Galvanized,P,false) end
 B("TrackControl",.4,3.86,-1.1,.7,.15,1.05,C.Charcoal,P,false)
 for i,c in ipairs({C.CleanPanel,C.Brick,C.Navy,C.Bronze,C.Cyan}) do
  B("FinishSampleTray",1.1+i*.9,3.86,.2,.8,.13,1.6,C.Charcoal,P,false)
  B("FinishSample",1.1+i*.9,4.03,.2,.65,.14,1.3,c,M,false)
 end
 for i,x in ipairs({-5.4,4.8}) do
  local y=8.7
  CY("WheelTyreSample",x,y,1,.6,3.9,C.Rubber,"Z")
  CY("MachinedRimLip",x,y,.65,.12,3.0,C.Stainless,"Z")
  CY("DarkRimBarrel",x,y,.55,.10,2.65,C.Charcoal,"Z")
  for j=0,7 do
   local a=j*math.pi/4
   PIPE("MachinedWheelSpoke",Vector3.new(x+math.sin(a)*.32,y+math.cos(a)*.32,.42),Vector3.new(x+math.sin(a)*1.28,y+math.cos(a)*1.28,.42),.22,i==1 and C.Stainless or C.Bronze)
  end
  CY("WheelCenterLock",x,y,.33,.16,.64,C.Stainless,"Z")
  B("WallSampleBracket",x,y,1.6,3.2,.22,1.1,C.Steel,M,false)
 end
 B("BuildPortfolio",5.2,3.86,-1.0,2.2,.14,1.8,C.Navy,P,false)
 point(m,"OwnerConfiguration",3191.5,.6,86,"OPERATOR")
end
local function craft(l)
 local m=group(l,"Owner_Craft_Bench","SUPPORT","DEDICATED","Portable personal tools -> private setup and maintenance workbench")
 local B,CY,PIPE=station(m,true,58)
 B("ToolBenchTop",0,3.45,0,12,.35,4.5,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({-4.6,4.6}) do B("WorkbenchSteelLeg",x,2,0,.5,2.6,3.5,C.Charcoal,M,true) end
 B("LowerToolShelf",0,1.05,0,11,.16,3.6,C.Steel,M,false)
 for x=-4,4,2 do B("StackedPartsBin",x,1.65,0,1.6,1.0,2,C.Navy,P,false) end
 B("PegToolBoard",0,6.5,1.8,11.5,4.5,.15,C.Steel,M,false)
 for x=-5,5,1 do for y=4.8,8.3,.7 do CY("PegboardHole",x,y,1.69,.025,.06,C.Charcoal,"Z") end end
 for x=-4.5,.5,1.2 do
  PIPE("WrenchHandle",Vector3.new(x,5.2,1.43),Vector3.new(x,6.9,1.43),.14,C.Stainless)
  B("WrenchJawLeft",x-.22,7.05,1.43,.13,.55,.16,C.Stainless,M,false)
  B("WrenchJawRight",x+.22,7.05,1.43,.13,.55,.16,C.Stainless,M,false)
  B("WrenchJawBridge",x,6.85,1.43,.48,.14,.16,C.Stainless,M,false)
 end
 B("MalletHead",3.3,7.2,1.4,1.5,.5,.5,C.Rubber,P,false)
 B("MalletHandle",3.3,6.2,1.4,.18,1.7,.2,C.Timber,Enum.Material.Wood,false)
 B("BenchViseBase",-3.2,3.9,-.9,1.8,.4,1.7,C.Charcoal,M,false)
 B("ViseFixedJaw",-3.2,4.6,-.35,1.7,.6,.6,C.Bronze,M,false)
 B("ViseSlidingJaw",-3.2,4.6,-1.6,1.7,.6,.6,C.Bronze,M,false)
 CY("ViseLeadScrew",-3.2,4.2,-1.2,2.2,.22,C.Stainless,"Z")
 PIPE("ViseTommyBar",Vector3.new(-3.8,4.2,-2.3),Vector3.new(-2.6,4.2,-2.3),.13,C.Stainless)
 B("SocketSetCase",2,3.84,-.7,3.1,.32,1.8,C.Charcoal,P,false)
 for x=1,3,.4 do CY("SocketSetCylinder",x,4.1,-.7,.32,.25,C.Stainless,"Y") end
 B("BenchPowerStrip",0,4.15,1.45,3,.38,.35,C.CleanPanel,P,false)
 B("BrakeRotorStand",5.0,4.0,.25,.3,.8,.6,C.Steel,M,false)
 CY("VentilatedBrakeRotor",5.0,5.25,.1,.15,2.2,C.Stainless,"Z")
 for j=0,9 do local a=j*math.pi/5;CY("RotorVent",5+math.sin(a)*.75,5.25+math.cos(a)*.75,-.01,.03,.13,C.Charcoal,"Z") end
 B("BrakeCaliperSample",5.95,5.25,-.1,.5,1.2,.55,C.Red,M,false)
 point(m,"OwnerCraftOperator",3191.5,.6,58,"OPERATOR")
 point(m,"BenchAirAndPower",3187,4,58,"FX")
end
local function rare(l)
 local m=group(l,"Secure_Performance_Parts","HERO","PROFESSIONAL","Personal parts order -> protected rare-component sourcing and customization")
 local B,CY,PIPE=station(m,false,86)
 B("RarePartsLowerCabinet",0,2.2,.15,15,3.1,3.5,C.Charcoal,M,true)
 B("ComponentDisplayShelf",0,4,0,15.2,.2,3.8,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({-7.3,7.3}) do B("DisplayFrame",x,6,1.6,.25,4,3.6,C.Steel,M,true) end
 B("DisplayBack",0,6,1.9,15,4,.16,C.CleanPanel,P,false)
 B("DisplayCanopy",0,8.1,0,15.5,.2,4,C.Charcoal,M,false)
 local pane=B("ClearSecureFront",0,6,-1.9,14.8,3.8,.10,C.Galvanized,Enum.Material.Glass,false);pane.Transparency=.86
 B("CaseLock",0,4.5,-2.03,.4,.5,.1,C.Bronze,M,false)
 -- Compressor housing, visible impeller, wastegate and inlet make this a turbo, not a gold block.
 CY("TurboTurbineHousing",-4,5.3,.2,1.6,2.3,C.Steel,"Z")
 CY("TurboCompressorVolute",-4,5.3,-.7,.45,2.55,C.Stainless,"Z")
 CY("TurboIntakeBore",-4,5.3,-.97,.08,1.55,C.Charcoal,"Z")
 for i=0,6 do local a=i*math.pi*2/7
  PIPE("CompressorImpellerBlade",Vector3.new(-4+math.cos(a)*.2,5.3+math.sin(a)*.2,-1.06),Vector3.new(-4+math.cos(a+.35)*.67,5.3+math.sin(a+.35)*.67,-1.06),.14,C.Galvanized)
 end
 CY("TurboCenterShaft",-4,5.3,-1.1,.12,.32,C.Stainless,"Z")
 PIPE("CompressorOutlet",Vector3.new(-3,5.8,.0),Vector3.new(-2,6.6,.0),.58,C.Stainless)
 CY("WastegateActuator",-5.2,6.6,.3,.7,.65,C.Galvanized,"Z")
 PIPE("WastegateLinkage",Vector3.new(-5.2,6.2,.1),Vector3.new(-4.7,5.4,.1),.11,C.Stainless)
 B("TurboMountingCradle",-4,4.35,.2,3,.4,2.7,C.Navy,P,false)
 B("IntakeManifoldPlenum",2.2,5.65,.7,4.2,1.3,1.2,C.Stainless,M,false)
 for x=.7,3.7,1 do
  PIPE("IntakeRunner",Vector3.new(x,5.4,.6),Vector3.new(x,4.6,-.5),.55,C.Stainless)
  B("RunnerMountFlange",x,4.55,-.5,.85,.18,.85,C.Galvanized,M,false)
 end
 B("ProtectiveFoamTray",2.2,4.25,0,5,.2,2.8,C.Navy,P,false)
 B("PartsOrderingTerminal",5.8,6.3,.4,1.8,2,.25,C.Charcoal,P,false)
 local screen=B("RareOrderPreview",5.8,6.3,.24,1.55,1.7,.03,C.Galvanized,P,false);screen:SetAttribute("RuntimeBinding","PENDING");screen:SetAttribute("DataBindingKey","OWNER_RARE_PARTS_ORDERING")
 for x=-5.7,5.7,3.8 do B("PackingDrawer",x,2.2,-1.67,3.4,2.5,.13,C.Steel,M,false);B("CabinetPull",x,3,-1.8,1,.12,.2,C.Stainless,M,false) end
 point(m,"RarePartsSelection",3244.5,.6,86,"OPERATOR")
end
local function history(l)
 local m=group(l,"Personal_Build_History_And_Rest","STORY","DEDICATED","First owned car and keepsakes -> private custom-car clubhouse")
 local B,CY,PIPE=station(m,false,37)
 B("PersonalSeatBase",0,1.25,0,7.5,.6,3.3,C.Timber,Enum.Material.Wood,true)
 B("PersonalSeatCushion",0,2,0,7,.65,3.1,C.Navy,Enum.Material.Fabric,true)
 B("PersonalSeatBack",0,3.1,1.45,7,2,.5,C.Navy,Enum.Material.Fabric,true)
 for _,x in ipairs({-3.7,3.7}) do B("SeatArm",x,2.8,0,.35,1.2,3.3,C.Timber,Enum.Material.Wood,true) end
 B("SideTable",5.7,2.8,0,2.3,.25,2.6,C.Timber,Enum.Material.Wood,true)
 B("TableBase",5.7,1.65,0,1.5,2.0,1.8,C.Charcoal,M,true)
 CY("PersonalCoffeeCup",5.7,3.25,0,.65,.5,C.WarmWhite,"Y")
 B("BuildAlbum",5.7,3.02,.75,1.5,.12,1.1,C.Bronze,P,false)
 for i,x in ipairs({-2.5,2.5}) do
  B("BuildHistoryFrame",x,7,1.65,3.5,2.6,.18,C.Timber,Enum.Material.Wood,false)
  local p=B("PersonalBuildRecord",x,7,1.51,3.15,2.25,.04,C.WarmWhite,P,false);p:SetAttribute("RuntimeBinding","PENDING_OWNER_BUILD_HISTORY")
  B("CarDrawingBody",x,6.95,1.46,2.5,.4,.03,C.Charcoal,P,false)
  B("CarDrawingCabin",x+.2,7.35,1.46,1.3,.4,.03,C.Steel,P,false)
  for _,dx in ipairs({-.8,.8}) do CY("CarDrawingWheel",x+dx,6.65,1.42,.025,.36,C.Charcoal,"Z") end
 end
 point(m,"OwnerPersonalRest",3244.5,.6,37,"OPERATOR")
end
local function finish(l)
 local m=group(l,"Owner_Floor_And_Circulation","ARCHITECTURE","DEDICATED","Personal yard patch -> organized private-workshop floor")
 box(m,"OwnerConcreteFloor",3218,.55,54,71,.10,91,C.Concrete,Enum.Material.Concrete,false)
 for _,x in ipairs({3191.5,3244.5}) do box(m,"OuterWalkingBand",x,.63,54,4,.10,90,C.CleanPanel,Enum.Material.Concrete,false) end
 box(m,"CentralDriveFinish",3218,.63,54,12,.10,90,C.OldConcrete,Enum.Material.Concrete,false)
 for _,z in ipairs({14,42,70,98}) do box(m,"SlabJoint",3218,.61,z,70,.02,.045,C.OldConcrete,P,false) end
 for _,x in ipairs({3191.5,3244.5}) do path(l,"OuterStaffWalk_"..x,{{x,12},{x,95}}) end
 path(l,"RearPedestrianLink",{{3191.5,95},{3191.5,97.9},{3220,97.9},{3220,103}})
 path(l,"RightRearPedestrianLink",{{3244.5,95},{3244.5,97.9},{3220,97.9}})
 for i,p in ipairs({{3191.5,19},{3244.5,19},{3191.5,47},{3244.5,47},{3191.5,75},{3244.5,75},{3191.5,58},{3191.5,86},{3244.5,86},{3244.5,37}}) do
  path(l,"WorkstationApproach_"..i,{{p[1],p[2]-3},{p[1],p[2]}})
 end
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
 root():SetAttribute("InstitutionFidelityPhase5COwnerStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 assert(root():GetAttribute("InstitutionFidelityPhase5BSalesStatus")=="ACCEPTED","Sales gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()

  local old=root()["09_Institution_Production_B"]["01_Frontage_Commercial"]["03_Owner_Garage"]
  local function hideExceptCars(target)
   if target:IsA("Model") and target:GetAttribute("VehicleDisplay") then return end
   if target:IsA("BasePart") then suppress(l,target);return end
   for _,c in ipairs(target:GetChildren()) do hideExceptCars(c) end
  end
  for _,c in ipairs(old:GetChildren()) do if c.Name~="FrontColumn" then hideExceptCars(c) end end
  local mass=root()["05_Architecture_Massing"]["01_Frontage"]:FindFirstChild("OwnerGarageEnvelope")
  if mass then suppress(l,mass) end
  local label=root()["05_Architecture_Massing"]["01_Frontage"]:FindFirstChild("OwnerLabel")
  if label then suppress(l,label) end
  for i=1,6 do suppress(l,root()["04_Capacity_Sockets"]["OwnerCar_"..i]) end
  shell(l)
  for i,p in ipairs({{3203,28},{3233,28},{3203,56},{3233,56},{3203,84},{3233,84}}) do fleet(l,i,p[1],p[2]) end
  configuration(l);craft(l);rare(l);history(l);finish(l)

 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase5COwnerStatus","BUILT_AWAITING_REVIEW");return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,metadata,ids={},{},{}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function check(n,cf,size,ignoreOccupation)
  for _,p in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
   local occupied=false
   if ignoreOccupation then local a=p.Parent;while a and a~=root() do if a:GetAttribute("OccupationPrototype") then occupied=true;break end;a=a.Parent end end
   -- Rotated cylinder floors have local Y=diameter; use actual world-space top.
   local top=p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2
   if not occupied and p.Transparency<.98 and top>.88 then table.insert(issues,n..": "..p:GetFullName()) end
  end
 end
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size) end end
 for _,p in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z)) end end



 for i,p in ipairs({{3203,28},{3233,28},{3203,56},{3233,56},{3203,84},{3233,84}}) do
  check("OwnerParkedCar_"..i,CFrame.new(p[1],3.6,p[2]),Vector3.new(13.3001,6.4,19.94))
 end
 -- Vehicle aisle ends at Z99 before the rear wall; Z100 opening is pedestrian only.
 -- Full car reverse/S-curve sweeps are separately checked by the maneuver inspector.
 check("OwnerCentralDrive",CFrame.new(3218,3.6,54),Vector3.new(13.3001,6.4,90))
 check("OwnerRearDoor",CFrame.new(3220,3.5,100),Vector3.new(3,5.5,4))
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
    if v.X<3180.8 or v.X>3255.2 or v.Z<7 or v.Z>101 or v.Y>15.85 then outside=true end
   end end end
   if outside then table.insert(issues,"OwnerFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.ManeuverPass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase5COwnerStatus","ACCEPTED");return a
end
return I

