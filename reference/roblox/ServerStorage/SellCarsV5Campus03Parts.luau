--!nocheck
-- Campus03 / Parts: a low outdoor preparation pavilion and an inward garden pocket.
-- Additive visual proxy. The receiving lane x3030..3056 / z378..416 stays empty.
-- The inherited staff crossing at z397 and all existing receiving equipment are untouched.
return function(K, parent)
 local V, CF = Vector3.new, CFrame.new
 local C = K.C
 local floor = .095
 local metal, wood = Enum.Material.Metal, Enum.Material.Wood
 local rubber, fabric = Enum.Material.SmoothPlastic, Enum.Material.Fabric
 local silver = Color3.fromRGB(166,173,165)
 local amber = Color3.fromRGB(190,143,65)
 local red = Color3.fromRGB(137,58,43)
 local pad = Color3.fromRGB(72,87,88)
 local owner = K.model(parent,"03_Parts_Receiving_Courtyard","SUPPORT","Parts_Logistics")
 owner:SetAttribute("DesignIntent","PREPARE_AND_INSPECT_PARTS_OUTSIDE_THE_RETAINED_RECEIVING_ROOM")
 owner:SetAttribute("RetainedFreightLane","x3030..3056 z378..416")
 owner:SetAttribute("AssetStatus","DETAILED_NATIVE_PROXY")

 local function box(m,n,x,y,z,w,h,d,c,mat,solid)
  return K.box(m,n,x,y,z,w,h,d,c or C.steel,mat or metal,solid==true)
 end
 local function cylinder(m,n,x,y,z,length,diam,col,axis)
  local p=box(m,n,x,y,z,length,diam,diam,col,metal,false)
  p.Shape=Enum.PartType.Cylinder
  if axis=="Y" then p.CFrame=CF(x,y,z)*CFrame.Angles(0,0,math.pi/2)
  elseif axis=="Z" then p.CFrame=CF(x,y,z)*CFrame.Angles(0,math.pi/2,0) end
  return p
 end
 local function caption(p,text)
  local g=Instance.new("SurfaceGui");g.Name="PreparedPartsCaption";g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(620,110);g.LightInfluence=1;g.Parent=p
  local t=Instance.new("TextLabel");t.Name="Caption";t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextColor3=C.paper;t.TextScaled=true;t.Parent=g
 end
 local function crate(m,name,x,y,z,w,h,d)
  local a=K.model(m,name,"SUPPORT","Parts_Logistics")
  box(a,"ShippingCaseBody",x,y+h/2,z,w,h,d,C.wood,wood,true)
  for _,sx in {-1,1} do
   box(a,"SteelCornerFace",x+sx*(w/2-.10),y+h/2,z-d/2-.025,.20,h,.07,silver)
   box(a,"CornerReturn",x+sx*(w/2+.025),y+h/2,z,.07,h,d+.06,silver)
  end
  for _,yy in {y+.10,y+h-.10} do
   box(a,"CaseEdgeFront",x,yy,z-d/2-.06,w,.20,.10,silver)
   box(a,"CaseEdgeRear",x,yy,z+d/2+.035,w,.20,.07,silver)
  end
  for _,dx in {-w*.27,w*.27} do
   box(a,"LidTimberBatten",x+dx,y+h+.06,z,.30,.12,d,C.woodDark,wood)
   box(a,"TransportLatch",x+dx,y+h-.40,z-d/2-.12,.30,.54,.15,C.steel)
   box(a,"LatchToggle",x+dx,y+h-.38,z-d/2-.22,.14,.27,.07,silver)
  end
  box(a,"ShippingLabel",x,y+h*.50,z-d/2-.08,w*.48,.65,.04,C.paper)
  for j=1,5 do box(a,"ManifestBarcode",x-w*.17+j*.14,y+h*.50,z-d/2-.105,.055+(j%2)*.05,.36,.012,C.black) end
  for _,dz in {-d*.33,d*.33} do box(a,"CaseFoot",x,y-.12,z+dz,w-.35,.25,.38,C.woodDark,wood,true) end
  return a
 end
 local function wheel(m,name,x,y,z,r,width)
  local a=K.model(m,name,"SUPPORT","Parts_Logistics")
  cylinder(a,"TyreCarcass",x,y,z,width,r*2,C.black,"X")
  cylinder(a,"OuterSidewall",x+width*.48,y,z,.10,r*1.83,pad,"X")
  cylinder(a,"MachinedWheelLip",x+width*.53,y,z,.14,r*1.52,silver,"X")
  cylinder(a,"WheelBarrelRecess",x+width*.63,y,z,.07,r*1.32,C.steel,"X")
  for j=0,11 do
   local a1=j*math.pi/6
   local p=box(a,"ShoulderTread",x,y+math.sin(a1)*r*.98,z+math.cos(a1)*r*.98,width*.88,.11,r*.37,C.steel,rubber)
   p.CFrame=CF(p.Position)*CFrame.Angles(-a1,0,0)
  end
  for j=0,4 do
   local a1=j*math.pi*2/5
   K.bar(a,"AlloySpoke",V(x+width*.71,y+math.sin(a1)*r*.17,z+math.cos(a1)*r*.17),V(x+width*.71,y+math.sin(a1)*r*.62,z+math.cos(a1)*r*.62),.12,silver,metal,false)
   cylinder(a,"LugBolt",x+width*.79,y+math.sin(a1)*r*.13,z+math.cos(a1)*r*.13,.06,.10,amber,"X")
  end
  cylinder(a,"WheelCentreCap",x+width*.78,y,z,.14,r*.32,silver,"X")
  return a
 end

 -- A clearly occupied pocket, not a full-width extension of the freight loading yard.
 local pavilion=K.model(owner,"01_Open_Preparation_Pavilion","ARCHITECTURE","Parts_Logistics")
 K.paving(pavilion,"PreparationPaving",3015,floor,382,18,22)
 K.pergola(pavilion,"LowCraftCanopy",3015,floor,382,17.4,21.2,10.7)
 -- Open timber slats keep the preparation work legible from the hero camera.
 box(pavilion,"WarmFrontFascia",3015,10.66,371.35,17.5,.52,.22,C.woodDark,wood)
 local header=box(pavilion,"PreparationIdentifier",3015,9.65,371.42,9.6,.90,.10,C.steel)
 caption(header,"PARTS / PREPARATION")
 -- West edge timber screen: a short intentional backdrop, not a new enclosed room.
 for z=382.5,390.5,1 do box(pavilion,"WestScreenBatten",3006.65,4.0,z,.16,7.7,.32,C.woodDark,wood,true) end
 box(pavilion,"ScreenLowerRail",3006.85,.85,386.5,.25,.35,9,C.steel,metal,true)
 box(pavilion,"ScreenUpperRail",3006.85,7.65,386.5,.25,.28,9,C.steel)
 for _,z in {377,387} do
  box(pavilion,"ShieldedTaskLight",3015,10.15,z,9,.13,.30,C.warm,Enum.Material.Neon)
 end

 local work=K.model(owner,"02_Packing_And_Inspection_Bench","HERO","Parts_Logistics")
 -- A real bench silhouette: wood top, frame, lower shelf, component mat and tools.
 for _,x in {3009.4,3020.6} do for _,z in {385.0,388.8} do
  box(work,"WorkbenchLeg",x,1.85,z,.35,3.5,.35,C.steel,metal,true)
  box(work,"AdjustableBenchFoot",x,.24,z,.6,.28,.6,silver,metal,true)
 end end
 box(work,"WorkbenchLongRail",3015,1.1,387,11.5,.3,3.85,C.steel,metal,true)
 box(work,"LowerShelf",3015,1.37,387,11.3,.14,3.65,silver)
 for j=0,6 do box(work,"HardwoodWorktopPlank",3015,3.74,384.96+j*.64,12.2,.38,.61,j%2==0 and C.wood or C.woodDark,wood,true) end
 for _,z in {384.70,389.09} do box(work,"BenchSteelLip",3015,3.61,z,12.4,.20,.12,C.steel) end
 box(work,"PaddedInspectionMat",3017.15,3.98,386.8,5.4,.08,3.25,pad,fabric)
 box(work,"FoldingManifestSheet",3011.35,3.99,386.2,2.0,.035,1.8,C.paper)
 for j=0,3 do box(work,"ManifestPrintedRule",3011.30,4.018,385.65+j*.28,1.42,.014,.045,C.steel) end
 box(work,"ShippingScannerBody",3012.75,4.18,386.3,.42,.26,.9,C.black)
 box(work,"ShippingScannerGrip",3012.75,4.04,386.7,.22,.36,.26,C.black)
 box(work,"ScannerOpticalWindow",3012.75,4.25,385.89,.26,.10,.035,C.pale)
 -- Packing roll support makes the station readable from the aerial view.
 for _,x in {3009.5,3012.7} do box(work,"PackingRollUpright",x,4.50,388.5,.20,1.2,.22,C.steel) end
 cylinder(work,"PackingPaperRoll",3011.1,4.83,388.5,2.7,.88,C.paper,"X")
 cylinder(work,"RollMandrel",3011.1,4.83,388.5,3.4,.15,silver,"X")
 box(work,"LoosePaperLeadingEdge",3011.1,4.40,388.12,2.6,.75,.035,C.paper)
 -- Disc/caliper demonstration part with radial rotor perforation, no generic colored cube.
 cylinder(work,"BrakeRotor",3017.6,4.10,386.70,.13,2.3,silver,"Y")
 cylinder(work,"BrakeRotorHat",3017.6,4.24,386.70,.19,.93,C.steel,"Y")
 for j=0,11 do local a=j*math.pi/6
  cylinder(work,"RotorDrilledOpening",3017.6+math.sin(a)*.88,4.18,386.70+math.cos(a)*.88,.02,.11,C.black,"Y")
 end
 box(work,"PowderCoatedCaliper",3018.5,4.40,386.6,.55,.5,1.10,red)
 box(work,"CaliperBridge",3018.12,4.48,386.6,.60,.22,1.10,red)
 for _,z in {386.2,387.0} do cylinder(work,"CaliperFixing",3018.46,4.57,z,.08,.14,silver,"Y") end
 crate(work,"PreparedJobKit",3018.6,1.65,387,3.2,1.6,2.6)
 box(work,"FoldedProtectiveBlanket",3013.9,1.83,387,3.1,.55,2.8,pad,fabric)
 box(work,"BlanketFold",3013.95,2.16,387,2.9,.10,2.55,C.sage,fabric)

 local wheels=K.model(owner,"03_Wheel_And_Tyre_Service_Rack","HERO","Parts_Logistics")
 for _,z in {373.25,379.15} do for _,x in {3007.2,3010.3} do
  box(wheels,"RackUpright",x,3.15,z,.22,6.1,.22,C.steel,metal,true)
 end end
 for _,y in {1.0,3.65,6.1} do
  for _,x in {3007.25,3010.25} do box(wheels,"RackLongRail",x,y,376.2,.24,.28,6.1,C.steel,metal,true) end
  for _,z in {373.25,379.15} do box(wheels,"RackEndTie",3008.75,y,z,3.2,.22,.24,silver) end
 end
 for level=0,1 do for j=0,1 do wheel(wheels,"Wheel_"..level.."_"..j,3008.8,2.12+level*2.68,374.7+j*2.9,1.12,.88) end end
 box(wheels,"RackRubberBacking",3007.30,3.4,376.2,.15,5.1,5.55,pad,fabric)

 local panels=K.model(owner,"04_Padded_Body_Panel_Cradle","HERO","Parts_Logistics")
 for _,x in {3018.45,3022.25} do
  box(panels,"CradleRunner",x,.37,376,.30,.5,6.5,C.steel,metal,true)
  for _,z in {373.7,378.3} do
   K.bar(panels,"SplayedCradleSupport",V(x,floor+.35,z),V(x-.30,5.3,z),.22,C.steel,metal,true)
   box(panels,"FoamContactPost",x-.30,4.4,z,.33,2.0,.45,pad,fabric)
  end
 end
 for _,z in {373.55,378.45} do box(panels,"CradleCrossTie",3020.35,.63,z,4.5,.25,.28,silver) end
 -- Standing hood has a formed bulge, return lips and underskin ribs.
 local hood=box(panels,"FormedReplacementHood",3019.10,3.58,375.65,.18,5.9,3.9,silver,metal)
 hood.CFrame=hood.CFrame*CFrame.Angles(0,0,math.rad(-9))
 local crown=box(panels,"HoodCentralPowerBulge",3019.22,3.75,375.65,.24,4.2,1.25,C.navy,metal)
 crown.CFrame=crown.CFrame*CFrame.Angles(0,0,math.rad(-9))
 for _,z in {373.76,377.54} do
  local rim=box(panels,"FoldedHoodEdge",3019.07,3.56,z,.24,5.86,.11,C.steel)
  rim.CFrame=rim.CFrame*CFrame.Angles(0,0,math.rad(-9))
 end
 -- A distinct door rather than a second rectangular panel: lower skin and open window frame.
 box(panels,"DoorLowerSkin",3021.10,2.60,375.8,.26,2.5,4.0,red)
 box(panels,"DoorBeltLine",3021.12,3.9,375.8,.30,.20,4.1,silver)
 for _,z in {373.87,377.73} do box(panels,"DoorWindowUpright",3021.11,4.95,z,.25,2.1,.22,red) end
 box(panels,"DoorWindowHeader",3021.11,6.02,375.8,.25,.22,4.1,red)
 box(panels,"DoorHandleRecess",3021.27,3.38,377.0,.03,.23,.76,C.black)
 box(panels,"DoorHandle",3021.33,3.39,377.0,.14,.12,.59,silver)
 for _,z in {374.4,377.1} do box(panels,"DoorUnderskinRib",3020.94,2.6,z,.10,2.2,.20,C.steel) end

 local delivery=K.model(owner,"05_Incoming_Crates_And_Component_Trolley","SUPPORT","Parts_Logistics")
 crate(delivery,"IncomingPerformanceParts",3009.0,.48,381.8,4.0,2.65,3.15)
 -- Low trolley placed beside, not in front of, the table's central working face.
 box(delivery,"TrolleyLowerTray",3021.25,.88,382,3.05,.22,3.2,C.steel,metal,true)
 for _,x in {3020.0,3022.5} do for _,z in {380.7,383.3} do
  cylinder(delivery,"TrolleyCaster",x,.47,z,.28,.62,C.black,"X")
  box(delivery,"CasterFork",x,.65,z,.40,.4,.18,silver)
 end end
 for _,z in {380.75,383.25} do box(delivery,"TrolleyHandleUpright",3022.6,1.7,z,.19,2.0,.19,C.steel) end
 K.bar(delivery,"TrolleyPushHandle",V(3022.6,2.68,380.75),V(3022.6,2.68,383.25),.20,C.steel,metal,false)
 box(delivery,"PaddedComponentCradle",3021.0,1.13,382,2.5,.30,2.5,pad,fabric)
 -- Recognisable compact transmission assembly, with bell housing and stepped rear shaft.
 cylinder(delivery,"TransmissionBellHousing",3020.5,1.95,382,.60,1.60,silver,"X")
 cylinder(delivery,"BellHousingInset",3020.18,1.95,382,.10,1.25,C.steel,"X")
 cylinder(delivery,"GearCase",3021.18,1.93,382,1.12,.95,silver,"X")
 cylinder(delivery,"TailHousing",3021.89,1.93,382,.45,.63,C.steel,"X")
 cylinder(delivery,"OutputSpline",3022.20,1.93,382,.28,.22,silver,"X")
 for j=0,5 do cylinder(delivery,"CastCaseCoolingRib",3020.85+j*.18,1.93,382,.045,1.05,C.steel,"X") end
 for j=0,5 do local a=j*math.pi/3
  cylinder(delivery,"BellHousingBolt",3020.15,1.95+math.sin(a)*.66,382+math.cos(a)*.66,.07,.12,amber,"X")
 end

 -- The second inward-facing pocket links working logistics to the public campus character.
 local garden=K.model(owner,"06_Receiving_Garden_And_Pause_Bench","LANDSCAPE","Parts_Logistics")
 K.paving(garden,"GardenPocketPaving",3068,floor,378,12,20)
 K.planter(garden,"LowLimestoneGarden",3068,floor,374,11,9,1.35)
 local rootY=floor+1.35
 K.yucca(garden,"SculpturalReceivingYucca",3068,rootY,372.5,1.1)
 K.agave(garden,"BlueAgaveWest",3064.8,rootY,375.7,1.05)
 K.agave(garden,"BlueAgaveEast",3071.0,rootY,375.4,.85)
 K.grass(garden,"DryGrassFront",3067.2,rootY,377.0,.70)
 K.grass(garden,"DryGrassRear",3071.2,rootY,371.1,.72)
 K.rock(garden,"LimestoneOutcrop",3065.0,rootY,372.1,1.2)
 K.rock(garden,"LowCompanionRock",3069.9,rootY,376.6,.65)
 K.bench(garden,"ReceivingPauseBench",3068,floor,381.8,8.7,0)
 K.light(garden,"GardenAmberBollard",3072.4,floor,386.2,13)
 K.light(pavilion,"PreparationApproachBollard",3007.0,floor,370.5,15)
 return owner
end

