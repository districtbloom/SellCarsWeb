-- BW01: readable early equipment, retaining existing purchase and transfer contracts.
-- Studio geometry only. No new capacity, economy, staff, signs or car assets.
local M={Version='2026-09-09.BW01',RootName='BW_EarlyCraft'}
local V,CF,A=Vector3.new,CFrame.new,CFrame.Angles
local E=Enum.Material
local C={steel=Color3.fromRGB(67,77,77),silver=Color3.fromRGB(174,182,176),wood=Color3.fromRGB(131,96,62),cream=Color3.fromRGB(212,201,165),red=Color3.fromRGB(143,62,44),blue=Color3.fromRGB(59,102,115),dark=Color3.fromRGB(29,33,32),green=Color3.fromRGB(88,107,70),gold=Color3.fromRGB(176,133,66)}
local function box(m,f,n,x,y,z,w,h,d,col,mat,rot)
 local p=Instance.new('Part');p.Name=n;p.Size=V(w,h,d);p.CFrame=f*CF(x,y,z)*(rot or CFrame.identity);p.Color=C[col or 'steel'];p.Material=mat or E.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(w,h,d)>.1;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local function cyl(m,f,n,x,y,z,h,d,col,axis)
 local p=box(m,f,n,x,y,z,h,d,d,col,E.Metal,axis=='X'and CFrame.identity or axis=='Z'and A(0,math.pi/2,0)or A(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder;return p
end
local function rod(m,f,n,a,b,d,col)
 local p=box(m,f,n,0,0,0,d,d,(b-a).Magnitude,col);p.CFrame=f*CFrame.lookAt((a+b)/2,b);return p
end
local function loop(m,f,n,x,y,z,r,col,flat)
 for i=0,11 do local a,b=i*math.pi/6,(i+1)*math.pi/6
  rod(m,f,n,V(x+math.cos(a)*r,y+(flat and 0 or math.sin(a)*r),z+(flat and math.sin(a)*r or 0)),V(x+math.cos(b)*r,y+(flat and 0 or math.sin(b)*r),z+(flat and math.sin(b)*r or 0)),.065,col)
 end
end
local function caster(m,f,x,z)
 box(m,f,'CasterFork',x,.5,z,.18,.35,.48,'silver');cyl(m,f,'RubberCaster',x,.27,z,.3,.48,'dark','X');cyl(m,f,'CasterAxle',x+.16,.27,z,.035,.15,'silver','X')
end
local function bench(m,f,w,d)
 for _,x in {-w/2+.35,w/2-.35}do
  for _,z in {-d/2+.25,d/2-.25}do rod(m,f,'SplayedTrestle',V(x,.05,z),V(x,2.65,z*.55),.2,'steel')end
  rod(m,f,'TrestleCrossBrace',V(x,.55,-d/2+.25),V(x,.55,d/2-.25),.16,'steel')
 end
 for i=1,3 do box(m,f,'ScarredTimberTop',0,2.8,-d/2+(i-.5)*d/3,w,.25,d/3-.035,'wood',E.Wood)end
 box(m,f,'LowerToolShelf',0,1.05,0,w-.5,.12,d-.4,'steel')
 for _,x in {-w/2+.35,w/2-.35}do for _,z in {-d/2+.3,d/2-.3}do cyl(m,f,'CountersunkBolt',x,2.94,z,.025,.12,'silver')end end
end
local function mallet(m,f,x,y,z)
 rod(m,f,'AshMalletHandle',V(x-.65,y,z),V(x+.55,y,z),.12,'wood');cyl(m,f,'RawhideMalletHead',x+.6,y,z,.62,.36,'cream','Z')
end
local function vice(m,f,x,y,z)
 box(m,f,'ViceMount',x,y,z,.95,.12,.8,'red');box(m,f,'ViceBody',x,y+.25,z,.6,.4,.65,'red')
 for _,dx in {-.3,.3}do box(m,f,'ViceJaw',x+dx,y+.55,z,.14,.3,.7,'silver')end
 rod(m,f,'ViceLeadScrew',V(x-.8,y+.3,z),V(x+.65,y+.3,z),.1,'silver');rod(m,f,'SlidingViceHandle',V(x-.8,y-.05,z),V(x-.8,y+.7,z),.07,'silver')
end
local function cabinet(m,f,w,d,col)
 for _,x in {-w/2+.35,w/2-.35}do for _,z in {-d/2+.3,d/2-.3}do caster(m,f,x,z)end end
 box(m,f,'RepairedSteelCabinet',0,1.65,0,w,2,d,col)
 for i=1,3 do box(m,f,'DrawerFront',0,.75+i*.53,-d/2-.035,w-.2,.45,.07,col);box(m,f,'DrawerPull',0,.75+i*.53,-d/2-.14,w*.52,.07,.16,'silver')end
 box(m,f,'RubberWorktop',0,2.75,0,w+.15,.18,d+.1,'dark',E.SmoothPlastic)
 box(m,f,'CornerWearPatch',-w/2+.25,1.75,-d/2-.078,.32,.56,.025,'silver')
end
local function gauge(m,f,x,y,z)
 cyl(m,f,'PressureGaugeRim',x,y,z,.18,.55,'silver','Z');cyl(m,f,'PressureGaugeFace',x,y,z-.1,.02,.44,'cream','Z')
 rod(m,f,'GaugeNeedle',V(x-.04,y-.12,z-.12),V(x+.1,y+.14,z-.12),.025,'dark')
end
local function bottle(m,f,x,y,z,col)
 box(m,f,'ServiceBottle',x,y+.35,z,.42,.7,.35,col);cyl(m,f,'BottleCap',x,y+.76,z,.14,.18,'dark');box(m,f,'BottleIdentificationPatch',x,y+.35,z-.185,.22,.24,.015,'cream')
end
local builders={}
function builders.panel(m,f)
 bench(m,f,6,3);vice(m,f,2,3,-.6)
 box(m,f,'LeatherShotBag',-1.8,3.15,.25,1.45,.42,1.4,'red',E.Fabric);mallet(m,f,-.3,3.12,-.7)
 for i=0,5 do box(m,f,'CurvedRepairPanel',-1.1+i*.55,3.35+math.sin(i*.5)*.6,.95,.6,.07,.9,'silver',E.Metal,A(0,0,math.cos(i*.5)*.35))end
 for i=1,3 do cyl(m,f,'FormingDolly',-.8+i*.65,3.1,.15,.32,.42,'silver')end
 box(m,f,'UsedAbrasiveSheets',0,1.17,0,1.5,.12,1,'cream');box(m,f,'ToolRoll',-1.8,1.25,0,1.3,.25,1.3,'green',E.Fabric)
end
function builders.paint(m,f)
 cabinet(m,f,4.6,2.6,'blue')
 for _,x in {-2.25,2.25}do box(m,f,'FoldUpSplashWing',x,3.5,.9,.08,1.3,1.1,'cream')end
 box(m,f,'WipeCleanBack',0,3.5,1.22,4.5,1.35,.08,'cream')
 for i=1,3 do local x=-1.5+(i-1)*.7;cyl(m,f,'MixingTin',x,3.2,.55,.6,.5,'silver');cyl(m,f,'OpenTouchUpPaint',x,3.515,.55,.03,.4,({'red','blue','cream'})[i]);rod(m,f,'StirringStick',V(x,3.25,.55),V(x+.08,3.95,.55),.055,'wood');box(m,f,'SprayOutCoupon',x,2.88,-.4,.5,.035,.7,({'red','blue','cream'})[i])end
 box(m,f,'SmallSprayGun',1.3,3.2,-.35,.7,.2,.22,'silver');rod(m,f,'SprayGunGrip',V(1.15,3.15,-.35),V(1.05,2.9,-.35),.12,'dark');cyl(m,f,'GravityCup',1.45,3.5,-.35,.55,.4,'cream');cyl(m,f,'MaskingPaperRoll',1.6,3.15,.55,.6,.65,'cream','X');cyl(m,f,'PaperRollCore',1.91,3.15,.55,.03,.25,'dark','X')
end
function builders.setup(m,f)
 for _,x in {-2.5,2.5}do box(m,f,'RackFoot',x,.2,0,.65,.25,2.6,'steel');rod(m,f,'RackUpright',V(x,.3,.8),V(x,4,.8),.2,'steel')end
 box(m,f,'PegToolBack',0,2.75,.9,5,2.6,.12,'blue');box(m,f,'SetupShelf',0,1.05,0,5.5,.15,2.1,'steel')
 for i=1,4 do local x=-2.1+i*.65;rod(m,f,'CombinationSpanner',V(x,2,.72),V(x,3.25,.72),.1,'silver');loop(m,f,'SpannerRing',x,3.35,.72,.12,'silver')end
 rod(m,f,'LongTorqueWrench',V(1.6,1.65,.7),V(1.6,3.75,.7),.14,'silver');box(m,f,'TorqueGrip',1.6,1.95,.7,.2,.65,.2,'dark');cyl(m,f,'RatchetHead',1.6,3.78,.68,.17,.35,'silver','Z')
 for _,x in {-1.8,1.1}do cyl(m,f,'RubberRoadWheel',x,1.2,3,.65,2.3,'dark','X');cyl(m,f,'UsedSteelRim',x+.34,1.2,3,.04,1.6,'silver','X');cyl(m,f,'RimHub',x+.37,1.2,3,.06,.5,'dark','X')end
 for _,x in {-1.3,1.3}do box(m,f,'ToePlate',x,1.22,-.3,1.7,.16,1.1,'silver');box(m,f,'RaisedToeReference',x,1.53,.1,1.7,.55,.06,'silver')end
 box(m,f,'TapeMeasure',0,1.42,-.6,.5,.4,.5,'gold')
end
local function fluid(m,f,underbody)
 box(m,f,'ReceiverRollingBase',0,.38,0,2.15,.2,1.9,'steel')
 for _,x in {-.8,.8}do for _,z in {-.65,.65}do caster(m,f,x,z)end end
 cyl(m,f,'UsedFluidReceiver',0,1.45,0,1.9,1.5,'blue');cyl(m,f,'ReceiverTop',0,2.43,0,.1,1.45,'silver');cyl(m,f,'DrainRiser',0,3.03,0,1.15,.16,'silver');cyl(m,f,'WideDrainFunnel',0,3.65,0,.2,2.05,'silver');cyl(m,f,'FunnelDarkWell',0,3.76,0,.02,1.7,'dark')
 gauge(m,f,.53,2.6,-.5);rod(m,f,'TankPushHandle',V(-.9,2.1,.65),V(.9,2.1,.65),.13,'steel');loop(m,f,'StowedRecoveryHose',0,1.35,-.94,.6,'dark')
 if underbody then
  box(m,f,'UprightCreeperBoard',3.05,1.85,.6,1.55,3.25,.18,'wood',E.Wood,A(-.14,0,0));box(m,f,'CreeperHeadPad',3.05,3.1,.22,1.35,.6,.2,'red',E.Fabric)
  for _,x in {2.42,3.68}do for _,y in {.55,2.55}do cyl(m,f,'CreeperWheel',x,y,.92,.18,.32,'dark','X')end end
  box(m,f,'CreeperWallCradle',3.05,.26,.5,2.1,.3,1.5,'steel');box(m,f,'StowedDripPan',3,.52,-.8,1.8,.3,.9,'silver')
 else
  box(m,f,'BundedBottleTray',3,.22,0,2.3,.35,1.75,'steel');for i=1,3 do bottle(m,f,2.2+i*.42,.42,0,i==2 and'red'or'cream')end
  box(m,f,'PressureTestCase',2.95,1.5,.65,2,.22,1.1,'dark');for _,x in {2.2,3.7}do box(m,f,'CaseStand',x,.9,.65,.16,1.2,.9,'steel')end
  rod(m,f,'CoolingTestHandPump',V(2.3,1.7,.6),V(3.25,1.7,.6),.18,'silver');rod(m,f,'PumpTHandle',V(3.35,1.7,.3),V(3.35,1.7,.9),.1,'dark');gauge(m,f,2.55,1.98,.38)
 end
end
function builders.fluid(m,f)fluid(m,f,false)end
function builders.underbody(m,f)fluid(m,f,true)end
function builders.finish(m,f)
 cabinet(m,f,4.3,2.3,'cream')
 for i=1,3 do cyl(m,f,'FoamCorrectionPad',-1.4+(i-1)*.9,2.98,.6,.27,.65,({'cream','gold','red'})[i])end
 box(m,f,'OrbitalPolisherMotor',-.3,3.25,-.45,1.3,.4,.4,'blue');box(m,f,'PolisherGrip',-1.05,3.2,-.45,.45,.2,.22,'dark');cyl(m,f,'PolisherBackingPlate',.25,3,-.45,.14,.7,'dark')
 for i=1,3 do box(m,f,'FoldedCleanCloth',1.45,2.87+i*.09,-.3,.6,.08,.85,'cream',E.Fabric)end
 rod(m,f,'TelescopicLampMast',V(3,.15,0),V(3,5.8,0),.13,'silver');for _,z in {-1,1}do rod(m,f,'LampFoot',V(3,.18,0),V(2.6,.1,z),.15,'steel')end
 for _,dx in {-.7,.7}do local p=box(m,f,'HalogenInspectionHead',3+dx,5.9,0,1.1,.75,.35,'blue',E.Metal,A(0,dx*.2,0));box(m,f,'InspectionLens',3+dx,5.9,-.2,.9,.52,.04,'cream');rod(m,f,'LampYoke',V(3,5.5,0),V(3+dx,5.5,0),.1,'steel')end
end
function builders.shelf(m,f)
 for _,x in {-2.8,2.8}do for _,z in {-1,1}do box(m,f,'BoltedRackAngle',x,2.8,z,.14,5.6,.14,'steel');for _,y in {.4,2.1,3.7,5.2}do cyl(m,f,'RackBolt',x,y,z-.09,.04,.12,'silver','Z')end end end
 rod(m,f,'RearCrossBrace',V(-2.8,.2,1),V(2.8,5.3,1),.09,'steel');rod(m,f,'RearCrossBrace',V(2.8,.2,1),V(-2.8,5.3,1),.09,'steel')
 for _,y in {.25,1.95,3.65}do box(m,f,'GalvanisedShelf',0,y,0,6,.13,2.4,'silver')end
 for i=1,3 do local x=-2+(i-1)*2;box(m,f,'ReusableOpenJobBin',x,.75,0,1.7,.85,1.75,'blue');box(m,f,'BinDarkOpening',x,1.18,0,1.48,.02,1.5,'dark');box(m,f,'BinGrip',x,.9,-.9,.6,.18,.05,'silver')end
 for i=1,4 do cyl(m,f,'OilFilter',-2.2+(i-1)*.6,2.45,-.4,.85,.43,i%2==0 and'cream'or'red')end
 for i=1,3 do box(m,f,'PleatedAirFilter',1.7,2.05+i*.2,0,1.5,.15,1.55,'cream');for j=1,5 do box(m,f,'AirFilterPleat',1.1+j*.2,2.14+i*.2,0,.06,.035,1.3,'gold')end end
 for _,x in {-1.7,0}do loop(m,f,'ReplacementDriveBelt',x,4.45,0,.57,'dark')end
 box(m,f,'UsedMetalPartsTin',1.8,4.04,0,1.25,.65,1.45,'red');box(m,f,'TinLatch',1.8,4.04,-.76,.25,.28,.06,'silver')
end
function builders.rest(m,f)
 for _,x in {-2.35,2.35}do rod(m,f,'RepairedSeatFrame',V(x,.1,-.7),V(x,1.4,.7),.18,'steel');rod(m,f,'RepairedSeatFrame',V(x,.1,.7),V(x,1.4,-.7),.18,'steel')end
 for i=1,3 do box(m,f,'MismatchedSeatPlank',0,1.45,-.7+i*.4,5.3,.18,.35,i==2 and'cream'or'wood',E.Wood)end
 rod(m,f,'SeatBackUpright',V(-2.35,1.4,.7),V(-2.35,2.8,.9),.15,'steel');rod(m,f,'SeatBackUpright',V(2.35,1.4,.7),V(2.35,2.8,.9),.15,'steel');box(m,f,'SalvagedBackrest',0,2.5,.9,5.2,.65,.16,'wood',E.Wood)
 box(m,f,'FoldedWorkJacket',-1.7,1.69,0,1.1,.28,.85,'blue',E.Fabric)
 box(m,f,'ScuffedCooler',4.15,.75,0,2.1,1.5,1.65,'red');box(m,f,'CoolerLid',4.15,1.56,0,2.15,.17,1.7,'cream');box(m,f,'CoolerLatch',4.15,1.16,-.88,.25,.5,.08,'silver');cyl(m,f,'CoffeeThermos',4.3,2.1,0,.9,.4,'silver');cyl(m,f,'ThermosCup',4.3,2.6,0,.15,.42,'dark')
end
function builders.desk(m,f)
 bench(m,f,6,3);box(m,f,'LockableKeyCabinet',1.5,4,.97,2.15,2,.5,'blue');box(m,f,'KeyCabinetOpenInterior',1.5,4,.69,1.9,1.8,.05,'dark')
 for i=1,4 do local x=.6+i*.36;rod(m,f,'KeyHook',V(x,4.55,.62),V(x,4.55,.39),.045,'silver');loop(m,f,'KeyRing',x,4.4,.38,.09,'silver');box(m,f,'NumberlessKeyTag',x,4.1,.38,.21,.35,.04,i%2==0 and'cream'or'red')end
 box(m,f,'FilingCrate',-1.25,3.18,.6,2,.5,1.4,'steel');for i=1,6 do box(m,f,'JobFolder',-2.1+i*.25,3.5,.6,.14,.6,1.15,i%2==0 and'cream'or'wood')end
 box(m,f,'OpenConditionLedger',-.7,2.97,-.65,1.5,.07,.8,'cream');rod(m,f,'Pencil',V(.3,3,-.9),V(.8,3,-.5),.04,'gold')
 box(m,f,'WeatheredChairSeat',0,1.65,-2.8,1.9,.2,1.8,'wood',E.Wood);box(m,f,'WeatheredChairBack',0,2.6,-3.55,1.9,1.5,.15,'wood',E.Wood)
 for _,x in {-.75,.75}do for _,z in {-3.45,-2.15}do box(m,f,'ChairLeg',x,.8,z,.13,1.6,.13,'steel')end end
end
function builders.wash(m,f)
 for _,x in {-1.25,1.25}do cyl(m,f,'PneumaticTransportWheel',x,.55,0,.4,1,'dark','X');cyl(m,f,'WheelHub',x+(x>0 and .22 or -.22),.55,0,.04,.35,'silver','X');rod(m,f,'TubularFrame',V(x,.55,-.9),V(x,2.95,1),.16,'steel')end
 rod(m,f,'TransportHandle',V(-1.25,2.95,1),V(1.25,2.95,1),.18,'dark');box(m,f,'PumpCradle',0,.65,0,2.4,.15,2.1,'steel');box(m,f,'SmallEngineBlock',-.3,1.15,0,1.3,.9,1.35,'steel');box(m,f,'FuelTank',-.3,1.8,0,1.55,.4,1.3,'red');cyl(m,f,'FuelCap',-.4,2.06,0,.13,.3,'dark')
 for i=1,6 do box(m,f,'CoolingFin',-.3,.85+i*.13,-.75,1.3,.06,.16,'silver')end
 cyl(m,f,'RecoilStarter',-.3,1.15,-.88,.12,.62,'dark','Z');box(m,f,'BrassPumpHead',.9,1.14,0,.65,.65,.85,'gold');gauge(m,f,.88,1.67,-.3)
 for _,x in {-.75,.75}do cyl(m,f,'HoseReelCheek',x,2.05,1.2,.1,1.3,'blue','X')end
 for i=1,6 do cyl(m,f,'WoundPressureHose',-.7+i*.2,2.05,1.2,.16,1.05,'dark','X')end
 rod(m,f,'LanceHolder',V(1.65,.2,0),V(1.65,3.5,0),.12,'silver');box(m,f,'TriggerGun',1.65,2.9,0,.28,.75,.25,'dark');rod(m,f,'SprayNozzle',V(1.65,3.45,0),V(1.5,3.85,-.25),.09,'gold');loop(m,f,'LooseSupplyHose',0,.09,3,1.3,'dark',true)
end
M.Specs={{7,'panel',3015,116},{8,'paint',3059,116},{9,'setup',3015,147},{10,'fluid',3012,140},{11,'finish',3063,147},{12,'shelf',3001,132},{21,'rest',3001,110},{26,'desk',3040,86},{36,'underbody',3009,203},{41,'wash',3060,145}}
function M.Build(root,register,ids,recovery)
 assert(game.RunService:IsStudio()and not game.RunService:IsRunning()and game.PlaceId==125334614375606,'Correct Edit only')
 assert(not root:FindFirstChild(M.RootName),'BW already built');assert(recovery,'Exact recovery folder required')
 local layer=Instance.new('Model');layer.Name=M.RootName;layer:SetAttribute('Version',M.Version);layer.Parent=root;local manifest={}
 for _,s in M.Specs do
  local n,kind,x,z=table.unpack(s);local oldName=string.format('P%03d_%s',n,kind=='underbody'and'fluid'or kind)
  local old=assert(root.Journey_Predecessors_And_Specialists:FindFirstChild(oldName),oldName);local source=assert(old:FindFirstChildWhichIsA('BasePart',true))
  local gate={first=source:GetAttribute('FJ_First'),finish=source:GetAttribute('FJ_Finish'),retire=source:GetAttribute('FJ_Retire'),moveAt=source:GetAttribute('FJ_MoveAt'),move=source:GetAttribute('FJ_Move'),kind='extra'}
  assert(gate.first==n and gate.retire>n,'Unexpected existing gates')
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,kind);m.Parent=layer;local f=CF(x,1.85,z);m.WorldPivot=f;m:SetAttribute('PurchaseId',ids[n]);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY');m:SetAttribute('ReplacementPivot',f);m:SetAttribute('FirstStep',n);m:SetAttribute('RetireStep',gate.retire);m:SetAttribute('MoveAt',gate.moveAt);m:SetAttribute('MoveVector',gate.move)
  builders[kind](m,f);local count=0
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then register(p,gate);p:SetAttribute('FJ_Path',M.RootName..'/'..m.Name..'/'..p.Name);count+=1 end end
  local retired=0
  for _,p in old:GetDescendants()do if p:IsA('BasePart')then
   local v=Instance.new('ObjectValue');v.Name=string.format('%04d',#recovery:GetChildren()+1);v.Value=p;v:SetAttribute('Key','FJ_Retire');v:SetAttribute('Before',p:GetAttribute('FJ_Retire'));v:SetAttribute('HadValue',p:GetAttribute('FJ_Retire')~=nil);v.Parent=recovery;p:SetAttribute('FJ_Retire',0);retired+=1
  end end
  local _,sz=m:GetBoundingBox();m:SetAttribute('ReplacementBounds',sz)
  table.insert(manifest,{name=m.Name,step=n,id=ids[n],parts=count,replacedParts=retired,retire=gate.retire,moveAt=gate.moveAt,move={gate.move.X,gate.move.Y,gate.move.Z},pivot={f:GetComponents()},bounds={sz.X,sz.Y,sz.Z}})
 end
 return manifest
end
return M

