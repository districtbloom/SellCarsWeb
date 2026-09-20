-- PI02–PI04 additive, independently removable progression craftsmanship.
-- Display-order gates are translated to the composer's historical source order.
local M={Version='PI04'}
local V=Vector3.new
local E=require(game.ServerStorage.SellCarsV5FullJourneyExtras)
local B=E.Box
local function source(n)if n==229 then return 233 elseif n>=230 and n<=233 then return n-1 end;return n end
local function path(root,o)local a={};while o~=root do table.insert(a,1,o.Name);o=o.Parent end;return table.concat(a,'/')end
local function group(root,batch,step,name,retire,reg,ids,fn)
 local parent=root:FindFirstChild(batch)
 if not parent then parent=Instance.new('Model');parent.Name=batch;parent.Parent=root end
 local key=string.format('P%03d_%s',step,name);assert(not parent:FindFirstChild(key),'Already built '..key)
 local m=Instance.new('Model');m.Name=key;m:SetAttribute('PurchaseId',ids[source(step)]);m:SetAttribute('PI_Batch',batch);m.Parent=parent
 fn(m)
 for _,o in m:GetDescendants()do if o:IsA('BasePart')then
  reg(o,{first=source(step),finish=source(step),retire=source(retire or 999),kind='extra'})
  o:SetAttribute('FJ_Path',path(root,o));o:SetAttribute('PI_Batch',batch)
 end end
 return m
end
local function surface(m,n,x,z,w,d,color,y,material)
 return B(m,n,x,y or 1.79,z,w,.045,d,color or'cream',material or Enum.Material.Concrete)
end
local function rod(m,n,a,b,w,color)
 local p=B(m,n,0,0,0,w,w,(b-a).Magnitude,color or'silver');p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function disc(m,n,x,y,z,diam,depth,color,axis)
 local p=B(m,n,x,y,z,depth,diam,diam,color);p.Shape=Enum.PartType.Cylinder
 if axis=='Y'then p.CFrame*=CFrame.Angles(0,0,math.pi/2)elseif axis=='Z'then p.CFrame*=CFrame.Angles(0,math.pi/2,0)end;return p
end
local function label(m,text,x,y,z,w,angle)
 local f=Instance.new('Model');f.Name='Label_'..text:gsub('[^%w]+','_');f.Parent=m;E.Sign(f,text,x,y,z,w)
 if angle then f:PivotTo(CFrame.new(x,y,z)*CFrame.Angles(0,angle,0)*(CFrame.new(x,y,z):Inverse()*f:GetPivot()))end
end
local function bench(m,x,y,z)
 for i=1,4 do B(m,'TimberSeatSlat',x,y+1.55,z-.8+i*.35,6,.17,.29,'wood',Enum.Material.Wood)end
 for _,dx in {-2.2,2.2}do B(m,'BenchLeg',x+dx,y+.75,z,.25,1.5,1.6,'steel');B(m,'BackUpright',x+dx,y+2.1,z+.8,.18,2,.18,'steel')end
 for _,h in {2.2,2.65}do B(m,'BackSlat',x,y+h,z+.8,6,.32,.16,'wood',Enum.Material.Wood)end
end
local function planter(m,x,y,z)
 B(m,'PlanterBase',x,y+.75,z,3,1.5,3,'steel');B(m,'GravelMulch',x,y+1.52,z,2.75,.09,2.75,'cream',Enum.Material.Pebble)
 for i=1,9 do local a=i*math.pi*2/9;rod(m,'YuccaLeaf',V(x,y+1.6,z),V(x+math.cos(a)*1.4,y+2.8+(i%2)*.6,z+math.sin(a)*1.4),.18,'green')end
end
function M.PI02(root,reg,ids)
 local function G(n,name,retire,fn)return group(root,'PI02_Connected_Early_Dealership',n,name,retire,reg,ids,fn)end
 G(34,'Working_Connection',66,function(m)
  surface(m,'CompactedServiceTrack',3080,245,16,256,'steel',1.71,Enum.Material.Pebble)
  for z=130,366,8 do surface(m,'IncrementalPedestrianPaver',3105,z,5,7.6,'cream')end
 end)
 local departments={{35,'MECHANICAL',3023,199,78},{41,'WASH',3023,144,72},{43,'DETAIL',3187,263,102},{46,'BODY',3023,263,84},{49,'PAINT',3187,331,96},{51,'TUNE',3023,331,90},{60,'PHOTO',3187,199,106}}
 for _,d in departments do
  local n,title,x,z,finish=table.unpack(d);local edge=x<3105 and 3061 or 3149;local side=x<3105 and-1 or 1
  G(n,title..'_Working_Threshold',finish,function(m)
   surface(m,'FlushServiceThreshold',edge,z-12,6,21,'cream')
   surface(m,'ThresholdSafetyEdge',edge-side*2.7,z-12,.16,21,'cream',1.825)
   B(m,'RemovableSignPost',edge,3.5,z-23,.22,3.5,.22,'steel')
   label(m,title..' / 01',edge,5.4,z-23,6,side*math.pi/2)
   for _,dz in {-20,-4}do rod(m,'ShelterDiagonalBrace',V(x-side*36,7.8,z+dz),V(x-side*33,11.2,z+dz),.16,'silver')end
  end)
  G(math.max(53,n),title..'_UtilityDrop',finish+1,function(m)
   local sx=x+side*39
   B(m,'ServiceIsolator',sx,5.2,z-8,.65,1.8,1.4,'steel')
   B(m,'RedIsolatorHandle',sx-side*.4,5.2,z-8,.2,.6,.45,'red')
   rod(m,'ProtectedConduit',V(sx,2,z-8),V(sx,10.2,z-8),.13,'silver')
   B(m,'SocketCover',sx-side*.4,4.7,z-8,.15,.3,.3,'cream')
  end)
 end
 for _,d in {{38,3007,112,'PARTS'},{54,3203,115,'OPERATIONS'}}do
  local n,x,permanent,title=table.unpack(d)
  G(n,title..'_Small_Shelter',permanent,function(m)
   surface(m,'InterimRearSlab',x,479,50,35,'steel',1.735)
   for _,dx in {-24,24}do B(m,'RetainedFrontColumn',x+dx,6.8,462,.6,10.2,.6,'steel')end
   B(m,'FrontTieBeam',x,11.75,462,49,.4,.45,'steel')
   label(m,title,x,10.3,461.65,10)
  end)
  G(permanent,title..'_Permanent_Leading_Frame',192,function(m)
   for _,dx in {-24,24}do B(m,'RetainedFrontColumn',x+dx,9.8,462,.6,16.3,.6,'steel')end
   B(m,'FrontTieBeam',x,18.1,462,49,.4,.45,'steel')
   label(m,title,x,15.5,461.65,10)
  end)
  G(n,title..'_GroundConnection',66,function(m)
   if n==38 then surface(m,'RearPathSpine',3105,420,5,94,'cream')end
   surface(m,'RearPathBranch', (3105+x)/2,462,math.abs(3105-x),5,'cream')
   surface(m,'CoveredWorkApproach',x,457,10,10,'cream')
  end)
 end
 G(123,'Dedicated_Intentional_Courts',193,function(m)
  for _,d in {{145,30},{202.5,45},{267.5,45},{336,51}}do
   local z,length=table.unpack(d)
   surface(m,'SimpleCourtWalk',3105,z,6,length,'cream',1.81)
   for _,x in {3091,3119}do surface(m,'GravelEdge',x,z,.18,length,'steel',1.83)end
   for _,dz in {-length/2,length/2}do surface(m,'CourtEnd',3105,z+dz,28,.18,'steel',1.83)end
   -- Compact furnishing at the edge, clear of roads and the central walk.
   bench(m,3096,1.82,z);planter(m,3114,1.82,z+length/2-4)
  end
 end)
end
function M.PI03(root,reg,ids)
 local function G(n,name,retire,fn)return group(root,'PI03_Professional_Identity',n,name,retire,reg,ids,fn)end
 G(153,'HQ_TwoStorey_Weathering',235,function(m)
  for _,x in {3065,3145}do
   B(m,'RoofEdgeCoping',x,29.9,501,.32,.2,44,'silver')
   B(m,'GutterOutlet',x,29.35,520,.7,.4,.7,'steel')
   rod(m,'RainwaterDownpipe',V(x,2,521),V(x,29.3,521),.22,'steel')
  end
  for x=3070,3140,7 do B(m,'RoofSeam',x,29.87,501,.075,.1,43,'silver')end
 end)
 G(144,'Professional_Client_Shade',221,function(m)
  -- Retained west glazing, modest coated-metal shading; Institution earns timber blades.
  B(m,'WestWindowSunHood',3034.7,13.7,47.6,2.6,.18,14,'steel')
  for _,z in {41.2,47.6,54}do rod(m,'WindowShadeBrace',V(3035.15,12.1,z),V(3033.5,13.6,z),.11,'silver')end
 end)
 G(188,'Furnished_Gallery_Viewing_Landing',999,function(m)
  -- Existing floor top22.46, front glass402, front exhibit noses408.18.
  -- All furnishings stay in the shallow clear strip, not in the vehicle displays.
  for _,x in {3085,3125}do bench(m,x,22.47,405.2)end
  B(m,'VisitorOrientationPlinth',3105,23.8,404.3,3.6,2.65,1.25,'steel')
  local top=B(m,'GalleryMapFace',3105,25.2,404.3,3.7,.18,1.4,'cream');top.CFrame*=CFrame.Angles(math.rad(-12),0,0)
  for i=1,6 do B(m,'SixExhibitMapMarker',3103.7+i*.36,25.36,404.3,.19,.06,.45,'wood')end
  label(m,'THE BUILD COLLECTION',3105,24.25,403.64,3.25)
  for _,x in {3097,3113}do
   B(m,'LowVisitorTable',x,23.75,404.8,2, .2,1.6,'wood',Enum.Material.Wood)
   B(m,'TablePedestal',x,23.05,404.8,.4,1.2,.4,'steel')
   B(m,'BuildStoryFolio',x,23.95,404.8,1.3,.16,1,'cream')
  end
 end)
 G(193,'Professional_Court_Paving',240,function(m)
  for _,d in {{145,30},{202.5,45},{267.5,45},{336,51}}do
   local z,length=table.unpack(d)
   for dz=-length/2+2,length/2-1,4 do surface(m,'JointedCourtPaver',3105,z+dz,6,3.88,'cream',1.82)end
   for _,x in {3091,3119}do surface(m,'RecessedStoneBorder',x,z,.45,length,'silver',1.84)end
   bench(m,3096,1.82,z-5);bench(m,3114,1.82,z+5)
   for _,dz in {-length/2+3,length/2-3}do
    surface(m,'GravelPlantingPocket',3096,z+dz,4,4,'cream',1.84,Enum.Material.Pebble)
   end
  end
 end)
 G(194,'Professional_Court_Planting',240,function(m)
  for _,z in {145,202.5,267.5,336}do planter(m,3114,1.83,z-13)end
 end)
end
function M.PI04(root,reg,ids)
 local function G(n,name,fn)return group(root,'PI04_Connected_Equipment_Craft',n,name,999,reg,ids,fn)end
 G(37,'Cooling_Test_Pump_And_Adapters',function(m)
  B(m,'CradleAdapterTray',3017,4.3,197.2,1.8,.18,2.2,'steel')
  rod(m,'TrayBracket',V(3017,2.8,197.2),V(3017,4.2,197.2),.15)
  disc(m,'HandPumpBarrel',3017.15,5.1,197.2,.42,1.35,'silver','Y')
  rod(m,'PumpPiston',V(3017.15,5.7,197.2),V(3017.15,6.4,197.2),.1)
  B(m,'PumpHandle',3017.15,6.45,197.2,.85,.17,.2,'dark')
  for i=1,3 do disc(m,'PressureCapAdapter',3016.5,4.6,196.4+i*.46,.32,.36,'silver','Y')end
  rod(m,'PressureTestConnection',V(3017.15,4.6,197.2),V(3017.8,4.8,197.2),.11,'dark')
  rod(m,'PressureTestConnection',V(3017.8,4.8,197.2),V(3017.8,7.5,197),.11,'dark')
  rod(m,'PressureTestConnection',V(3017.8,7.5,197),V(3015.9,8.1,197),.11,'dark')
 end)
 G(47,'Weld_Setup_And_Return_Lead',function(m)
  B(m,'CouponBenchTop',2992,4.9,243.8,4,.2,1.7,'steel')
  for _,x in {2990.5,2993.5}do B(m,'BenchLeg',x,3.3,243.8,.22,3,1.4,'steel')end
  B(m,'CeramicHotWorkTile',2992,5.08,243.8,3.4,.12,1.3,'cream',Enum.Material.Concrete)
  for i=1,3 do
   B(m,'WeldTestCoupon',2990.6+i*.75,5.23,243.8,.6,.1,.9,'silver')
   for j=1,5 do disc(m,'VisibleWeldBead',2990.6+i*.75,5.31,243.4+j*.12,.085,.05,'steel','Y')end
  end
  B(m,'EarthClampJaw',2993.6,5.15,243.8,.55,.22,.5,'red')
  rod(m,'EarthReturnLead',V(2993.6,5.2,243.8),V(2995.8,3.1,242),.12,'dark')
  rod(m,'EarthReturnLead',V(2995.8,3.1,242),V(2995.35,3.8,239.9),.12,'dark')
  B(m,'WeldingHelmetShell',2990.65,5.75,243.8,.85,1.1,.8,'dark')
  B(m,'HelmetVisionWindow',2990.65,5.88,243.36,.6,.35,.045,'blue')
 end)
 G(94,'Tyre_Changer_Spindle_And_Air',function(m)
  rod(m,'SlidingToolSpindle',V(2992.9,7.18,333),V(2992.9,10.8,333),.22,'silver')
  disc(m,'SpindleLockCollar',2992.9,9.6,333,.45,.35,'steel','Y')
  B(m,'SpindleLockLever',2993.25,9.6,333,.7,.12,.15,'red')
  B(m,'AirRegulatorBracket',2994.5,4.2,335.2,.35,1.4,.4,'steel')
  disc(m,'RegulatorBowl',2994.5,4.35,335.2,.45,.8,'silver','Y')
  disc(m,'RegulatorDial',2994.8,4.8,335.2,.65,.15,'cream','X')
  rod(m,'GaugeNeedle',V(2994.89,4.8,335.2),V(2994.89,5,335.34),.035,'dark')
  rod(m,'ProtectedMachineAirLine',V(2994.5,4,335.2),V(2994.5,3.1,334.6),.1,'dark')
  rod(m,'ProtectedMachineAirLine',V(2994.5,3.1,334.6),V(2993.9,3.1,333),.1,'dark')
 end)
 G(100,'Spray_Service_Nozzles_And_Air',function(m)
  B(m,'NozzleServiceBackboard',3220.65,8.35,331,.16,2.9,4.7,'steel')
  for i=1,5 do
   local z=328.9+i*.7
   disc(m,'IndexedAirCap',3220.5,8.75,z,.4,.2,'silver','X')
   disc(m,'AirCapOrifice',3220.38,8.75,z,.09,.035,'dark','X')
   rod(m,'CleaningBrushStem',V(3220.44,7.3,z),V(3220.44,8.15,z),.07,'silver')
   B(m,'CleaningBrushBristles',3220.44,7.35,z,.14,.4,.14,'cream')
  end
  for _,z in {329.7,332.3}do
   rod(m,'GunServiceAirLead',V(3217.8,6.98,z),V(3218.8,6.65,z),.08,'dark')
   rod(m,'GunServiceAirLead',V(3218.8,6.65,z),V(3220.1,6.65,z),.08,'dark')
   B(m,'AirShutoffHandle',3220.15,6.8,z,.2,.3,.5,'blue')
  end
 end)
 G(103,'Vacuum_Service_Accessories',function(m)
  B(m,'AccessoryCarrier',3217.2,4.3,252.6,.65,.18,2.2,'steel')
  rod(m,'CarrierBracket',V(3216.8,2.9,252.6),V(3217.2,4.2,252.6),.13)
  for i=1,3 do
   disc(m,'CreviceToolSocket',3217.2,4.5,251.5+i*.5,.28,.35,'dark','Y')
   rod(m,'CreviceToolNeck',V(3217.2,4.5,251.5+i*.5),V(3217.2,5.3+i*.15,251.5+i*.5),.14,'dark')
   B(m,'NarrowSuctionTip',3217.2,5.35+i*.15,251.5+i*.5,.22,.3,.09,'dark')
  end
  B(m,'WetDrySelectorFace',3213.78,7.1,252.05,.07,.6,.5,'steel')
  disc(m,'WetDrySelector',3213.72,7.1,252.05,.24,.08,'blue','X')
 end)
 G(109,'Photo_Optics_And_Calibration',function(m)
  for _,z in {210,214,218}do
   disc(m,'LensFrontRim',3217.89,6.28,z,1.16,.14,'dark','X')
   local glass=disc(m,'CoatedOpticalElement',3217.8,6.28,z,.94,.05,'blue','X');glass.Material=Enum.Material.Glass;glass.Transparency=.15
   disc(m,'LensAperture',3217.76,6.28,z,.45,.025,'dark','X')
   for i=1,6 do local a=i*math.pi/3;B(m,'LensWitnessMark',3218.05,6.28+math.cos(a)*.58,z+math.sin(a)*.58,.18,.04,.04,'cream')end
  end
  B(m,'FoldedCalibrationBoard',3215.48,8.8,212,.15,1.25,2.4,'steel')
  for i=1,6 do B(m,'NeutralCalibrationPatch',3215.38,8.8,210.95+i*.3,.035,.8,.27,i%2==0 and'cream'or'dark')end
  for _,z in {211.2,212.8}do rod(m,'CalibrationBoardHanger',V(3215.6,9.93,z),V(3215.48,9.3,z),.065,'steel')end
 end)
 G(203,'Filter_Differential_Pressure_Bridge',function(m)
  B(m,'GaugeBridge',2992.4,7.45,147.2,.25,.2,2.6,'silver')
  rod(m,'BridgeMount',V(2992,6.1,147.2),V(2992.4,7.4,147.2),.15)
  for _,z in {146.4,148}do
   disc(m,'FilterPressureGauge',2992.55,7.95,z,.9,.2,'steel','X')
   disc(m,'GaugeFace',2992.67,7.95,z,.72,.035,'cream','X')
   rod(m,'GaugeNeedle',V(2992.71,7.95,z),V(2992.71,8.15,z+.18),.035,'dark')
   rod(m,'ImpulseTube',V(2992.4,7.75,z),V(2992.4,z<147 and 6.6 or 4.3,z),.065,'silver')
   rod(m,'ImpulseTube',V(2992.4,z<147 and 6.6 or 4.3,z),V(2991.9,z<147 and 6.6 or 4.3,147.2),.065,'silver')
   disc(m,'IsolationHandwheel',2992.5,6.8,z,.55,.07,'blue','X')
  end
 end)
end
function M.Build(root,reg,ids)M.PI02(root,reg,ids);M.PI03(root,reg,ids);M.PI04(root,reg,ids)end
return M

