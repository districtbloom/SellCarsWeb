-- VA01–VA07: native art direction on the existing environment-only preview.
local M={Version='PX04'}
local SS=game.ServerStorage
local E=require(SS.SellCarsV5FullJourneyExtras)
local H=game:GetService('HttpService')
local C=Color3.fromRGB
local pal={steel=C(172,181,177),dark=C(43,50,52),rubber=C(34,37,36),cream=C(218,212,194),timber=C(157,112,69),oxide=C(155,73,48),teal=C(58,117,119),violet=C(107,90,124),sage=C(112,133,113),neutral=C(208,209,202)}
M.Departments={
 {id='VA01_Wash',alias='01_Wash',dept='Wash',pro=175,final=204,z=144,west=true,accent='teal',title='WASH / RECLAIM & RINSE',process='PREWASH  /  RECOVER  /  DRY',
  steel={'Crosshead','CrossheadFace','UprightChannel','AirKnifeDuct','AirPlenum','CartridgeFilter','FilterClamp','PumpSkidRails','ChemistryManifold'},
  dark={'DriveMotor','BrushMotor','CentrifugalBlowerCase','RibbedPumpMotor'},accentNames={'AccessCover','DosingPanelBack','ControlPedestal'},floor={'SealedWashDeck','NonSlipServiceWalk'},wall={'WashableWallLiner'},rubber={'CoiledPressureHose','HoseLead'},fit={'AccessCover','DosingPanelBack'}},
 {id='VA02_Body',alias='02_Body',dept='Body_Restoration',pro=161,final=208,z=263,west=true,accent='oxide',title='BODY / METAL & FORM',process='STRAIGHTEN  /  FORM  /  FINISH',
  steel={'UpperMachinedRailFace','UpperClampJaw','RamPiston','PolishedUpperWheel','LowerAnvilWheel','AluminiumWorkpiece','ContouredDolly'},
  dark={'WeldingPowerSupply','DustCollectorCabinet','TransformerHousing'},accentNames={'BenchStructuralRail','TowerUChannel','CFrameBackbone','CFrameUpperArm','CFrameLowerArm'},floor={'RepairConcretePad','FlushInsetBenchDeck'},timber={'CraftBenchTop'},rubber={'ParkedHydraulicHose','CoiledTorchLead'},fit={'FilterAccess','ControlHead'}},
 {id='VA03_Tune',alias='03_Tune',dept='Tune_Performance',pro=165,final=211,z=331,west=true,accent='violet',title='TUNE / CALIBRATION LAB',process='MEASURE  /  CALIBRATE  /  RECORD',
  steel={'MachinedDynoDrum','BalancerSpindle','ClampingTurntable','WheelClampingJaw','ExhaustSilencer'},dark={'CoolingFanShroud','TelemetryRack','DeskPedestal','BalancerCabinet','TyreMachineBase'},accentNames={'FanControlPod','BalancerScreenSupport','ChangerRearColumn'},floor={'DynoConcreteSurround','FlushDynoServiceDeck'},rubber={'AbsorberFabricPanel','ESDMat','ParkedExhaustDrop'},fit={'TelemetryRack','OscilloscopeHousing'}},
 {id='VA04_Paint',alias='Paint_Exterior',gold=true,dept='Paint_Exterior',pro=170,final=214,z=331,west=false,accent='oxide',title='PAINT / COLOUR & FINISH',process='MATCH  /  MIX  /  APPLY',
  steel={'SteelWorktop','RecessedBasin','ExtractionDuct','RearFilterFrame','DoorHandle','RollAxle','ScalePan','ClampGuide'},dark={'CabinetBody','BackHousing','SideHousing','SinkCabinet','ServicePlenum'},accentNames={'RecessedDoor','MixerBack','RackUpright'},wall={'WashableLowerPanel','UpperPanel','CeilingSupplyCassette','ExtractionFilterCassette','DoubleSkinCabinet'},floor={'SealedDeck_1','SealedDeck_2'},fit={'RecessedDoor','AccessPanel'}},
 {id='VA05_Detail',alias='04_Detail',dept='Detail_QC',pro=177,final=215,z=263,west=false,accent='sage',title='DETAIL / FINISH ASSURANCE',process='CORRECT  /  MEASURE  /  RELEASE',
  steel={'StainlessCollectionDrum','SteamBoiler','BoilerTop','ReleaseBench','CleanShelf','DoorPull'},dark={'VacuumMotorHead','PolishCartLowerTray','ChemistryCabinet','InspectionInstrumentCase'},accentNames={'PolishCartUpperTray','CleanRackPost','CabinetDoor'},floor={'CleanCorrectionFloor','StaffNonSlipWalk'},rubber={'CaseFoam','ParkedSteamHose','CoiledVacuumHose'},fit={'CabinetDoor','InspectionInstrumentCase'}},
 {id='VA06_Photo',alias='05_Photo',dept='Photo_Listing',pro=180,final=218,z=199,west=false,accent='teal',title='PHOTO / EDITORIAL STUDIO',process='CAPTURE  /  PRESENT  /  LIST',
  steel={'CaseLatch','CameraTravelRail','MonitorArm','MonitorArmFoot'},dark={'StudioCameraBody','CameraLensBarrel','SoftboxEdge','GripStandFoot','TelescopicGripStand','CameraTransitCase','EquipmentRackPost'},accentNames={'DrawerFront','TurntableDriveCabinet'},wall={'CycloramaVerticalSweep','CurvedCycloramaCove','SoftboxFabricDiffuser','OverheadDiffusionSail'},floor={'CycloramaFloorApron','FullCarTurntableDeck','StudioEntryApron'},timber={'EditorialWorktop'},rubber={'FocusRing','LensGripRing','DocumentMat'},fit={'TurntableDriveCabinet','CameraTransitCase'}},
}
local function setof(t)local s={}for _,v in t or{}do s[v]=true end;return s end
local function native(m,name,cf,size,color,mat)
 local p=E.Box(m,name,0,0,0,size.X,size.Y,size.Z,'steel',mat or Enum.Material.Metal)
 p.CFrame=cf;p.Color=color;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;return p
end
local function findEquipment(root,d)
 if d.gold then return root['10_Institution_Fidelity_R1']['01_Gold_Slices'][d.alias]end
 return root['10_Institution_Fidelity_R1']['03_Remaining_Production'][d.alias]
end
local function attr(p,k,v,save)if save then save(p,k)end;p:SetAttribute(k,v)end
local function group(root,d,n,suffix,reg,ids,fn)
 local folder=root:FindFirstChild(d.id)
 if not folder then folder=Instance.new('Model');folder.Name=d.id;folder.Parent=root end
 local name=string.format('P%03d_%s',n,suffix);assert(not folder:FindFirstChild(name),'Batch already built: '..name)
 local m=Instance.new('Model');m.Name=name;m.Parent=folder;m:SetAttribute('PurchaseId',ids[n]);m:SetAttribute('VA_Batch',d.id);fn(m)
 for _,p in m:GetDescendants()do if p:IsA('BasePart')then
  reg(p,{first=n,finish=n,kind='extra'});p:SetAttribute('VA_Batch',d.id)
  local path={};local o=p;while o~=root do table.insert(path,1,o.Name);o=o.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'))
 end end
end
local function wallText(m,d,text,y,z,width)
 local x=d.west and 2983.6 or 3226.4
 local letters=Instance.new('Model');letters.Name='ProcessIdentification';letters.Parent=m
 E.Sign(letters,text,x,y,z,width)
 local pivot=CFrame.new(x,y,z);letters:PivotTo(pivot*CFrame.Angles(0,d.west and -math.pi/2 or math.pi/2,0)*pivot:Inverse()*letters:GetPivot())
end
function M.Department(root,d,reg,ids,save)
 local equipment=findEquipment(root,d);assert(equipment,'Missing equipment '..d.dept)
 local sets={};for _,k in {'steel','dark','accentNames','floor','wall','timber','rubber'}do sets[k]=setof(d[k])end
 local count=0
 for _,p in equipment:GetDescendants()do if p:IsA('BasePart') and p:GetAttribute('FJ_First') and(p:GetAttribute('FJ_Transparency')or 1)<1 then
  local color,mat
  if sets.steel[p.Name]then color=pal.steel;mat='Metal'
  elseif sets.dark[p.Name]then color=pal.dark;mat='Metal'
  elseif sets.accentNames[p.Name]then color=pal[d.accent];mat='Metal'
  elseif sets.floor[p.Name]then color=d.dept=='Photo_Listing'and pal.neutral or C(163,168,158);mat=d.dept=='Photo_Listing'and'SmoothPlastic'or'Concrete'
  elseif sets.wall[p.Name]then color=d.dept=='Photo_Listing'and pal.neutral or pal.cream;mat='SmoothPlastic'
  elseif sets.timber[p.Name]then color=pal.timber;mat='Wood'
  elseif sets.rubber[p.Name]then color=pal.rubber;mat='SmoothPlastic'end
  if color then
   assert(p:GetAttribute('FJ_ArtFirst')==nil,'Existing art ownership '..p:GetFullName())
   attr(p,'FJ_ArtFirst',math.max(d.pro,p:GetAttribute('FJ_First')),save);attr(p,'FJ_ArtColor',color,save);attr(p,'FJ_ArtMaterial',mat,save);count+=1
  end
 end end
 local wallX=d.west and 2983.3 or 3226.7
 group(root,d,d.pro,'Workspace_Identity',reg,ids,function(m)
  native(m,'HighServiceIdentityBand',CFrame.new(wallX,11.65,d.z-8),Vector3.new(.16,2.35,24),pal.dark)
  wallText(m,d,d.title,11.9,d.z-8,22)
  native(m,'DepartmentInlay',CFrame.new(wallX+(d.west and .12 or -.12),10.65,d.z-8),Vector3.new(.07,.13,23),pal[d.accent])
  -- Supported under-roof workside lighting, kept clear of car and staff floor space.
  local x=d.west and 2991 or 3219
  for _,z in {d.z-15,d.z+9}do
   native(m,'TaskLightBracket',CFrame.new(x,15,z),Vector3.new(.16,.8,.18),pal.dark)
   native(m,'ShieldedTaskHousing',CFrame.new(x,14.5,z),Vector3.new(10,.32,1.05),pal.dark)
   local lens=native(m,'TaskDiffuser',CFrame.new(x,14.3,z),Vector3.new(9.7,.06,.7),C(188,190,182),Enum.Material.Neon)
   local l=Instance.new('SurfaceLight');l.Name='WorksideTaskLight';l.Face=Enum.NormalId.Bottom;l.Range=24;l.Angle=120;l.Brightness=1.1
   -- Explicit neutral inspection/capture light; warm fabrication and service light.
   l.Color=(d.dept=='Paint_Exterior'or d.dept=='Photo_Listing'or d.dept=='Detail_QC')and C(244,245,237)or C(255,235,207);l.Shadows=true;l.Parent=lens
  end
 end)
 group(root,d,d.final,'Fitted_Craft_Details',reg,ids,function(m)
  wallText(m,d,d.process,9.8,d.z+10,18)
  local fit=setof(d.fit);local fitted=0
  for _,p in equipment:GetDescendants()do if p:IsA('BasePart')and fit[p.Name]and fitted<6 and(p:GetAttribute('FJ_Transparency')or 1)<1 then
   local cf=p:GetAttribute('FJ_CF')or p.CFrame;local sz=p:GetAttribute('FJ_Size')or p.Size
   if sz.X>.6 and sz.Y>.6 then
    for _,sx in {-1,1}do for _,sy in {-1,1}do
     native(m,'CaptivePanelFastener',cf*CFrame.new(sx*(sz.X/2-.16),sy*(sz.Y/2-.16),-sz.Z/2-.035),Vector3.new(.1,.1,.045),pal.steel)
    end end
    native(m,'EquipmentIndexPlate',cf*CFrame.new(0,-sz.Y/2+.25,-sz.Z/2-.035),Vector3.new(math.min(1.2,sz.X*.55),.19,.05),pal[d.accent]);fitted+=1
   end
  end end
 end)
 return {department=d.dept,materials=count}
end
function M.Architecture(root,save)
 local rules=require(SS.SellCarsV5FullJourneyRules);local count=0
 local wallNames=setof({'OuterWall','WorkshopWallPanel','OuterUpperWall','RearUpperPanel','OriginalInnerWall','InnerInteriorLiner','OuterInteriorLiner','RearInteriorLiner','OfficeMetalPanel','GroundMasonryPanel'})
 local roofNames=setof({'OpenCanopy','OriginalRoof','OwnerRoof','RoofSeam','StandingRoofSeam'})
 local woodNames=setof({'CanopyFascia','RoadHeaderTimber','LobbySoffitBatten','FacadeFascia'})
 local frameNames=setof({'OuterCornerColumn','WallStructure','AnnexSteelPost','ExpressedWallPost','LobbyStructuralPost','BoxSection','CantileverTopFlange','CantileverLowerFlange','HighCantileverWeb'})
 for _,p in root:GetDescendants()do if p:IsA('BasePart')and p:GetAttribute('FJ_First')and(p:GetAttribute('FJ_Transparency')or 1)<1 then
  local kind=p:GetAttribute('FJ_Kind');local d=rules.Departments[p:GetAttribute('FJ_Department')or''];local first=p:GetAttribute('FJ_First')
  if kind=='productionShell'or kind=='wing'or kind=='owner'or kind=='hq'or kind=='receiving'then
   local role=wallNames[p.Name]and'wall'or roofNames[p.Name]and'roof'or woodNames[p.Name]and'wood'or frameNames[p.Name]and'frame'
   if role then
    local dedicated=d and d.shell or(kind=='owner'and 120 or kind=='wing'and(p:GetFullName():find('Parts_Logistics',1,true)and 112 or 115)or 141)
    local pro=d and d.pro or(kind=='owner'and 183 or kind=='wing'and 192 or kind=='hq'and 153 or 141)
    local final=d and d.final or(kind=='owner'and 226 or kind=='wing'and 236 or kind=='hq'and 235 or 197)
    local stages={}
    local function add(n,c,mat)if n>=first then table.insert(stages,{step=n,color={c.R*255,c.G*255,c.B*255},material=mat})end end
    if first<=64 then add(first,C(123,117,100),role=='roof'and'CorrodedMetal'or'Concrete')end
    add(math.max(first,dedicated),role=='wall'and C(162,163,149)or C(101,111,109),role=='wall'and'Concrete'or'Metal')
    add(math.max(first,pro),role=='wall'and C(194,190,174)or role=='wood'and C(142,140,128)or C(65,77,81),(role=='wall'or role=='wood')and'Concrete'or'Metal')
    add(math.max(first,final),role=='wall'and C(211,204,181)or role=='wood'and pal.timber or role=='roof'and C(49,57,61)or C(55,61,59),role=='wood'and'Wood'or(p:GetAttribute('FJ_Material')=='Limestone'and'Limestone'or role=='wall'and'Concrete'or'Metal'))
    -- Fold equal-stage records in insertion order before sorting.
    local byStep={}for _,s in stages do byStep[s.step]=s end
    local clean={}for _,s in stages do if byStep[s.step]==s then table.insert(clean,s)end end
    table.sort(clean,function(a,b)return a.step<b.step end)
    attr(p,'FJ_StagePalette',H:JSONEncode(clean),save);count+=1
   end
  end
 end end;return count
end
function M.Build(root,reg,ids,save)
 local out={}for _,d in M.Departments do table.insert(out,M.Department(root,d,reg,ids,save))end
 return out,M.Architecture(root,save)
end
return M

