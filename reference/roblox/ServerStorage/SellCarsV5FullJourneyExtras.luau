-- Readable native-part predecessors and distinct specialist apparatus.
-- Geometry only: no economic effects, inventory ownership or production simulation.
local E={};local V=Vector3.new
local C={steel=Color3.fromRGB(58,68,70),silver=Color3.fromRGB(163,173,169),wood=Color3.fromRGB(138,102,65),cream=Color3.fromRGB(219,211,186),red=Color3.fromRGB(153,57,42),blue=Color3.fromRGB(61,112,125),dark=Color3.fromRGB(30,34,34),green=Color3.fromRGB(80,115,74)}
local function box(m,n,x,y,z,a,b,c,color,material)
 local p=Instance.new('Part');p.Name=n;p.Anchored=true;p.Size=V(a,b,c);p.CFrame=CFrame.new(x,y,z);p.Color=C[color or 'steel'];p.Material=material or Enum.Material.Metal;p.CanCollide=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
end
local function cyl(m,n,x,y,z,h,d,color)
 local p=box(m,n,x,y,z,h,d,d,color);p.Shape=Enum.PartType.Cylinder;p.CFrame*=CFrame.Angles(0,0,math.pi/2);return p
end
local function beam(m,n,a,b,w,color)
 local p=box(m,n,0,0,0,w,w,(b-a).Magnitude,color);p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function sign(m,text,x,y,z,w)
 local p=box(m,'Identification',x,y,z,w or 5,1,.12,'dark');local s=Instance.new('SurfaceGui');s.Face=Enum.NormalId.Front;s.PixelsPerStud=35;s.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;s.Parent=p
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.TextColor3=C.cream;t.Text=text;t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=s
end
local function tablekit(m,x,z,w,d)
 box(m,'Worktop',x,4.7,z,w,.3,d,'wood',Enum.Material.Wood)
 for _,dx in {-w/2+.3,w/2-.3}do for _,dz in {-d/2+.3,d/2-.3}do box(m,'FrameLeg',x+dx,3.2,z+dz,.25,2.7,.25)end end
 box(m,'LowerTray',x,2.3,z,w-.4,.15,d-.4)
end
local function tools(m,x,z)
 for i=1,5 do box(m,'ToolHandle',x-1.5+i*.5,4.98,z,.16,.13,1,'red');box(m,'ToolHead',x-1.5+i*.5,5,z-.6,.3,.16,.35,'silver')end
end
local function shelf(m,x,z,kind)
 for _,dx in {-2.8,2.8}do for _,dz in {-1,1}do box(m,'RackUpright',x+dx,4.6,z+dz,.18,5.6,.18)end end
 for _,y in {2.1,3.8,5.5}do
  box(m,'Shelf',x,y,z,6,.16,2.4)
  for i=1,4 do box(m,kind=='archive'and'BoundBuildRecord'or'LabelledJobTote',x-2.6+i*1.05,y+.65,z,.85,1.1,1.5,kind=='archive'and'cream'or'blue');box(m,'IndexTab',x-2.6+i*1.05,y+.7,z-.77,.45,.2,.04,'cream')end
 end
end
local function lamp(m,x,z)
 box(m,'TaskMast',x,5,z,.18,6.3,.18,'silver');local p=box(m,'WorkLamp',x,8.2,z,2,.6,.5)
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,222,183);l.Brightness=.5;l.Range=14;l.Parent=p
 box(m,'LampLens',x,8.2,z-.27,1.7,.38,.05,'cream')
end
local function wheel(m,x,z)
 local p=box(m,'StoredWheel',x,3,z,1,2.4,2.4,'dark');p.Shape=Enum.PartType.Cylinder
 p=box(m,'WheelHub',x+.52,3,z,.06,1.6,1.6,'silver');p.Shape=Enum.PartType.Cylinder
end
local function kit(m,kind,x,z)
 if kind=='panel'then
  tablekit(m,x,z,6,3);tools(m,x,z);for i=1,3 do cyl(m,'FormingDolly',x-2+i,5,z+.6,.35,.65,'silver')end
  box(m,'SupportedBodyPanel',x,5.6,z+.9,5,1.5,.15,'silver');box(m,'ClampingJaw',x+2,5.1,z-.9,.6,.6,.8,'red')
 elseif kind=='paint'then
  tablekit(m,x,z,6,3);for i=1,5 do cyl(m,'SealedFinishTin',x-2.4+i*.75,5.2,z+.6,.7,.5,'cream')end
  box(m,'SprayGunBody',x+1,5,z-.4,.8,.2,.22,'silver');cyl(m,'SprayCup',x+1,5.45,z-.4,.6,.4,'silver')
  for i=1,3 do box(m,'SprayOutCard',x-2+i*.55,4.92,z-.6,.45,.05,.7,i==2 and'red'or'blue')end
  box(m,'MaskingRoll',x-2.3,3,z,1.1,1.1,1.8,'cream')
 elseif kind=='setup'then
  tablekit(m,x,z,6,3);tools(m,x,z);wheel(m,x-2,z+3);wheel(m,x+1,z+3)
  for _,dx in {-1.5,1.5}do box(m,'AlignmentPlate',x+dx,4.9,z,1.2,.08,1.4,'silver');box(m,'ToeGauge',x+dx,5.2,z,.1,.6,1.5,'blue')end
 elseif kind=='fluid'then
  cyl(m,'RecoveryTank',x,3,z,2.2,1.8,'blue');cyl(m,'DrainFunnel',x,5.1,z,.35,2.4,'silver');box(m,'DrainRiser',x,4.4,z,.2,1.4,.2,'silver')
  tablekit(m,x+3,z,3,2);for i=1,3 do cyl(m,'ContainedFluidBottle',x+2+i*.5,5.2,z,.6,.35,'cream')end
  for i=0,7 do local a=i*math.pi/4;local b=(i+1)*math.pi/4;beam(m,'RecoveryHose',V(x+math.cos(a),2,z+2+math.sin(a)),V(x+math.cos(b),2,z+2+math.sin(b)),.12,'dark')end
 elseif kind=='finish'then
  tablekit(m,x,z,5,2.5);box(m,'Polisher',x,5,z,1.4,.3,.4,'blue');cyl(m,'PolishingPad',x+.6,5.1,z,.16,.7,'cream')
  for i=1,4 do box(m,'FoldedCloth',x-1.5,4.94+i*.1,z,.8,.09,.8,'cream',Enum.Material.Fabric)end
  lamp(m,x+3,z);box(m,'SegregatedClothBin',x,2.8,z,3,.8,1.8,'blue')
 elseif kind=='wash'then
  box(m,'PressureWasherFrame',x,2.5,z,3.5,.3,2.3);box(m,'PumpMotor',x,3.3,z,2.7,1.3,1.7,'blue');box(m,'TransportHandle',x,4.7,z+1,2.8,.18,.18,'silver')
  for _,dx in {-1.4,1.4}do local w=box(m,'TransportWheel',x+dx,2.4,z,.35,.9,.9,'dark');w.Shape=Enum.PartType.Cylinder;box(m,'HandleUpright',x+dx,3.7,z+1,.15,2,.15,'silver')end
  beam(m,'WashLance',V(x+2,2.2,z),V(x+2,6,z),.16,'silver');box(m,'LanceGrip',x+2,5.5,z,.35,.8,.3,'dark');for i=0,11 do local a=i*math.pi/6;local b=(i+1)*math.pi/6;beam(m,'PressureHose',V(x+math.cos(a)*1.5,2,z+3+math.sin(a)*1.5),V(x+math.cos(b)*1.5,2,z+3+math.sin(b)*1.5),.12,'dark')end
 elseif kind=='air'then
  local p=cyl(m,'PressureVessel',x,3,z,4,2,'blue');p.CFrame=CFrame.new(x,3,z)
  box(m,'CompressorMotor',x,4.5,z,2,.9,1.4);cyl(m,'RegulatorGauge',x+1,4.7,z,.2,.6,'cream');beam(m,'AirOutlet',V(x+1,4,z),V(x+2.6,4,z),.12,'silver')
  for _,dx in {-1.5,1.5}do box(m,'VibrationFoot',x+dx,2,z,1,.35,2,'dark')end
 elseif kind=='power'then
  box(m,'ProtectedGenerator',x,3.2,z,4,2.5,2.5,'blue');box(m,'ServiceGrille',x,3.2,z-1.3,2.6,1.5,.1)
  for i=1,8 do box(m,'CoolingSlot',x-1.4+i*.3,3.2,z-1.37,.1,1.2,.05,'dark')end
  box(m,'DistributionBoard',x+3,4,z,1.4,3,.6);for i=1,4 do box(m,'Isolator',x+2.6+i*.17,4,z-.4,.12,.4,.12,'red')end
 elseif kind=='safety'then
  shelf(m,x,z,'stock');cyl(m,'Extinguisher',x-3.6,3,z,2,.75,'red');box(m,'SpillContainer',x+3.5,2.7,z,1.8,1.5,1.8,'cream');sign(m,'FIRE / SPILL / WASTE',x,7.1,z,6)
 elseif kind=='desk'or kind=='archive'or kind=='source'then
  tablekit(m,x,z,6,3);box(m,'RecordsFolio',x-1,4.95,z,1.3,.16,1,'cream');box(m,'KeyCompartments',x+1.5,5.2,z+.5,1.7,.7,.6,'blue')
  for i=1,4 do box(m,'Divider',x+.65+i*.33,5.2,z+.15,.05,.65,.7,'silver')end
  box(m,'ChairSeat',x,3.4,z-2.8,2,.3,2,'wood');box(m,'ChairBack',x,4.5,z-3.6,2,1.7,.2,'wood');for _,dx in {-.8,.8}do box(m,'ChairLeg',x+dx,2.7,z-2.8,.2,1.5,1.6)end
  if kind~='desk'then shelf(m,x,z+3,'archive')end
 elseif kind=='shelf'then shelf(m,x,z,'stock')
 elseif kind=='rest'then
  for i=1,4 do box(m,'BenchSlat',x,3.2,z-1+i*.45,6,.2,.38,'wood',Enum.Material.Wood)end
  for _,dx in {-2.2,2.2}do box(m,'BenchFrame',x+dx,2.6,z,.3,1.2,2)end
  box(m,'Planter',x+4.5,2.5,z,2.8,1.5,2.8,'wood');for i=1,6 do local a=i*math.pi/3;beam(m,'DesertLeaf',V(x+4.5,3,z),V(x+4.5+math.cos(a),4.6,z+math.sin(a)),.25,'green')end
 elseif kind=='tow'then
  for _,dx in {-3,3}do box(m,'RecoveryRamp',x+dx,1.95,z,1.4,.25,10,'silver');for j=1,10 do box(m,'RampGrip',x+dx,2.1,z-5+j,.9,.06,.12)end end
  box(m,'WinchCradle',x,2.7,z+6,4,1.5,2,'blue');cyl(m,'WinchDrum',x,3,z+6,2,1,'silver');sign(m,'RARE / TOW HOLD',x,6,z+7,8)
 elseif kind=='hut'then
  local floor=box(m,'RetainedOfficeSlab',x,1.7,z,12,.35,10,'cream',Enum.Material.Concrete);floor.CanCollide=true
  for _,dx in {-5.5,5.5}do box(m,'GroundedPost',x+dx,6,z-4.5,.4,8.6,.4,'wood');box(m,'GroundedPost',x+dx,6,z+4.5,.4,8.6,.4,'wood')end
  box(m,'WeatherRoof',x,10.4,z,13,.35,11);box(m,'RearCladding',x,6,z+4.8,11,8.3,.3,'wood',Enum.Material.WoodPlanks)
  tablekit(m,x,z+1,6,3);tools(m,x,z+1);lamp(m,x+4,z+2)
 elseif kind=='crane'then
  for _,dx in {-2,2}do box(m,'Outrigger',x+dx,2.1,z,0.5,.4,5,'red');for _,dz in {-2,2}do cyl(m,'Caster',x+dx,2,z+dz,.3,.45,'dark')end end
  box(m,'CraneMast',x,5.2,z+2,.65,6.4,.65,'red');beam(m,'HydraulicRam',V(x,3,z+1),V(x,6.8,z-1),.35,'silver');beam(m,'LiftingBoom',V(x,8.3,z+2),V(x,8.3,z-3),.45,'red');beam(m,'LiftingChain',V(x,8.3,z-3),V(x,6.4,z-3),.12,'silver');box(m,'RatedHook',x,6.2,z-3,.5,.5,.25,'silver')
 elseif kind=='rotisserie'then
  for _,dz in {-3,3}do box(m,'RotisserieFoot',x,2,z+dz,5,.35,1,'red');box(m,'AdjustableUpright',x,4.4,z+dz,.55,4.7,.55,'red');cyl(m,'RotationBearing',x,6.7,z+dz,.4,.8,'silver');box(m,'BodyMountYoke',x,6.7,z+dz,4,.35,.35,'silver')end
  beam(m,'SpineBrace',V(x,2.3,z-3),V(x,2.3,z+3),.3,'red');box(m,'StoredShellFixture',x,5.4,z,4,.35,4,'silver')
 elseif kind=='chassis'then
  tablekit(m,x,z,6,3);for _,dx in {-1.7,1.7}do for _,dz in {-.65,.65}do box(m,'CornerWeightScale',x+dx,4.96,z+dz,1.1,.18,1.1,'silver')end end
  box(m,'ScaleReadout',x,5.5,z+.6,1.5,1,.4,'blue');beam(m,'AlignmentReference',V(x-2.5,5,z-1),V(x+2.5,5,z-1),.1,'silver')
 elseif kind=='development'then
  tablekit(m,x,z,6,3);cyl(m,'FuelPressureReservoir',x-1.8,5.6,z,1.4,.8,'silver');box(m,'ThermalTestBlock',x+.5,5.4,z,2,1,1.4,'silver')
  for i=1,4 do cyl(m,'SensorPort',x-.6+i*.4,6,z,.2,.18,'blue')end
  box(m,'DAQConsole',x+2,5.7,z+.5,1,1.5,.6,'blue');for i=1,3 do box(m,'RecordedChannel',x+2,5.2+i*.3,z+.15,.75,.16,.05,'cream')end
 elseif kind=='vault'then
  box(m,'InsulatedCabinet',x,4.9,z,5,6,3,'cream');box(m,'SealedDoor',x,4.9,z-1.55,4.6,5.6,.15,'blue');box(m,'DoorGasket',x,4.9,z-1.65,4.2,5.2,.08,'dark');box(m,'Window',x,5.1,z-1.71,3.7,4.5,.08,'silver')
  box(m,'ConditioningUnit',x+3.1,5,z,1.2,3,2);for i=1,6 do box(m,'FilterGrille',x+3.75,4.2+i*.24,z,.08,.08,1.6,'silver')end
  box(m,'HumidityController',x-1.5,7.6,z-1.6,1.3,.6,.2,'dark');box(m,'SealHandle',x+1.6,4.9,z-1.8,.15,1,.2,'silver');sign(m,'CONTROLLED MATERIALS',x,8.6,z-1.6,6)
 elseif kind=='metrology'or kind=='precision'then
  tablekit(m,x,z,6,3.5);box(m,'GraniteReferencePlate',x,5,z,5.5,.35,3,'dark',Enum.Material.Granite)
  for _,dx in {-2,2}do box(m,'MeasuringColumn',x+dx,6.5,z,.25,3,.25,'silver')end
  box(m,'ComparatorBridge',x,8,z,4.4,.25,.3,'silver');box(m,'DigitalProbe',x+.5,6.6,z,.25,2.5,.25,'blue')
  for i=1,4 do box(m,'DatumBlock',x-1.8+i*.7,5.35,z-.7,.5,.35,.5,'silver')end;box(m,'CalibrationCase',x,2.8,z,4,.7,2,'blue')
 elseif kind=='buck'then
  for _,dx in {-2.2,2.2}do box(m,'BuckBaseRail',x+dx,2.2,z,.35,.4,6,'blue')end
  for i=1,5 do local dz=-3+i;local h=2.6+math.sin(i*.55)*1.2;box(m,'AdjustableStation',x,2.8,z+dz,4,.25,.4,'silver');box(m,'ProfileRib',x,3+h/2,z+dz,4.5,h,.18,'wood',Enum.Material.Wood);box(m,'DatumSpine',x,3,z+dz,.2,.2,.8,'silver')end
 elseif kind=='finishlab'then
  tablekit(m,x,z,6,3);box(m,'ComparisonCabinetBack',x,6.4,z+1,6,3,.2,'cream');for _,dx in {-2.9,2.9}do box(m,'LightBoothSide',x+dx,6.4,z,.2,3,2.2,'cream')end
  box(m,'LightBoothHood',x,8,z,6,.2,2.2,'cream');for i=1,5 do box(m,'HistoricReferencePanel',x-2.5+i*.8,5.3,z,.65,1,.12,i%2==0 and'red'or'blue')end;lamp(m,x+3.7,z)
 elseif kind=='concours'then
  tablekit(m,x,z,6,3);for _,dx in {-2.8,2.8}do box(m,'ControlledCheckMast',x+dx,6,z,.2,7.7,.2);box(m,'HighCRIInspectionBar',x+dx,6,z-.2,.18,5,.12,'cream')end
  box(m,'GlossMeter',x-.8,5,z,1.1,.4,.6,'blue');box(m,'FilmGauge',x+.8,5,z,.6,.5,.5,'silver');for i=1,4 do cyl(m,'PreservationMaterial',x-2+i*.8,5.2,z+.7,.7,.35,'cream')end
 elseif kind=='fabrication'then
  tablekit(m,x,z,6,4);box(m,'FixturePlate',x,4.95,z,5.5,.18,3.5,'silver')
  for i=1,6 do for j=1,3 do cyl(m,'FixtureBore',x-2.4+i*.65,5.05,z-1.5+j*.65,.04,.12,'dark')end end
  for _,dx in {-2,2}do box(m,'AdjustableClamp',x+dx,5.5,z,.45,.8,1,'red');box(m,'ClampScrew',x+dx,6,z,.1,.7,.1,'silver')end
  box(m,'BenchPressUpright',x,6.5,z+1,.5,3,.5,'blue');box(m,'PressArm',x,8,z+.4,2,.4,1.5,'blue')
 elseif kind=='frame_measurement'then
  tablekit(m,x,z,6,3);for _,dx in {-2,2}do box(m,'TelescopicDatumMast',x+dx,6.2,z,.2,3,.2,'silver');box(m,'SlidingTarget',x+dx,6.8,z,.7,.7,.12,'cream')end
  box(m,'CrossMeasurementRail',x,6,z,4.5,.2,.2,'blue');for i=1,4 do box(m,'ChainHook',x-2+i*.8,3.8,z-1.4,.25,.5,.2,'silver');beam(m,'StowedPullChain',V(x-2+i*.8,3.6,z-1.4),V(x-2+i*.8,2.2,z-1.4),.14,'dark')end
 elseif kind=='ventilation'or kind=='airplant'then
  box(m,'FilterServiceCabinet',x,5,z,4,6,3,'cream');box(m,'ServiceDoor',x,5,z-1.55,3.6,5.5,.12,'blue')
  for i=1,10 do box(m,'IntakeLouvre',x,3+i*.36,z-1.65,3,.12,.08,'steel')end
  cyl(m,'RoundOutletDuct',x,9,z,2.4,1.6,'silver');box(m,'ServiceIsolator',x+2.2,5,z,.4,1,.6,'red');box(m,'PressureReadout',x,7.1,z-1.7,1.4,.6,.15,'dark')
 elseif kind=='academy'then
  tablekit(m,x,z,7,4);box(m,'TeachingFixture',x,5.7,z,3,1.7,1.8,'silver');for i=1,3 do cyl(m,'CutawayCylinder',x-1.4+i*.7,6.8,z,.7,.55,'blue')end
  sign(m,'MASTER CRAFT / DATUM & TOLERANCE',x,8.3,z+1.6,8)
  for _,dx in {-2.5,2.5}do box(m,'TeachingStool',x+dx,3,z-3.5,1.7,.3,1.7,'wood');box(m,'StoolStem',x+dx,2.4,z-3.5,.3,1.3,.3)end
 end
end
-- Each entry is a specific workstation, not a generic box per purchase.
E.Specs={
 {7,'panel',3015,116,87,46,0,135},{8,'paint',3059,116,50,49,145,203},{9,'setup',3015,147,94,51,-5,172},
 {10,'fluid',3012,140,80},{11,'finish',3063,147,105,44,142,116},{12,'shelf',3001,132,38},
 {15,'air',3001,141,53},{16,'power',2993,143,53},{17,'safety',2993,130,69},{18,'hut',3020,65,54},
 {21,'rest',3001,110,58},{23,'archive',3020,67,64},{24,'panel',3164,42,63},
 {26,'desk',3040,86,142},{30,'hut',3047,48,118},{36,'fluid',3009,203,160},{41,'wash',3060,145,73},
 {58,'rest',3039,32,148},{61,'desk',3210,180,108},{64,'archive',3192,474,122},
 {83,'desk',3012,176,159},{86,'frame_measurement',3009,259,999},{92,'ventilation',2988,335,999},{98,'airplant',3204,335,999},{110,'chassis',3040,93,142},{111,'tow',2989,88,999},
 {122,'archive',3150,395,190},{151,'source',3035,480,999},
 -- Missing specialist endpoint apparatus, explicitly authored rather than relabelled.
 {158,'crane',3009,221,999},{164,'rotisserie',3009,237,999},{167,'chassis',3009,306,999},{168,'development',2998,353,999},
 {200,'vault',3041.60498046875,484.1999816894531,999},{201,'metrology',3009,485,999},{206,'precision',2990,182,999},
 {209,'buck',3009,288,999},{213,'finishlab',3201,360,999},{216,'concours',3208,286,999},
 {225,'fabrication',3166,118,999},{234,'academy',3212,486.17498779296877,999},
}
function E.Build(root,register,ids)
 local parent=Instance.new('Model');parent.Name='Journey_Predecessors_And_Specialists';parent.Parent=root
 local groups={}
 for _,s in E.Specs do local n,kind,x,z,retire=table.unpack(s);local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,kind);m.Parent=parent;kit(m,kind,x,z);m:SetAttribute('PurchaseId',ids[n]);groups[n]=m
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then register(p,{first=n,finish=n,retire=retire,moveAt=s[6],move=V(s[7]or 0,0,s[8]or 0),kind='extra'})end end
 end
 return groups,parent
end
E.Box=box;E.Sign=sign;E.Kit=kit
return E

