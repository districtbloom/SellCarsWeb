--!nocheck
-- Phase 4E owns Photo/Listing only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase4e.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Production","05_Photo"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Photo_Listing."..n..".FidelityR1",FunctionId="Photo_Listing",ZoneId="Photo_Listing",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase4EPhotoGeometry",true);p.Parent=m;return p
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



local Blue=Color3.fromRGB(73,105,131)
local function screen(m,n,x,y,z,w,h,channel)
 local p=box(m,n,x,y,z,.26,h,w,C.Charcoal,P,false)
 local face=box(m,n.."_DarkFace",x-.16,y,z,.045,h-.22,w-.22,C.Navy,P,false)
 face:SetAttribute("DataBindingKey",channel);return face
end
local function studioCell(owner,index,z)
 local m=group(owner,"Editorial_Turntable_Studio_"..index,"HERO","PROFESSIONAL","Yard photos -> fixed backdrop -> calibrated editorial turntable")
 m:SetAttribute("BayIndex",index);m:SetAttribute("ParkedState","TURNTABLE_LOCKED_CAMERA_FIXED_NO_LIVE_ROTATION")
 m:SetAttribute("FutureRotationDiameter",math.sqrt(18.94^2+10.58^2))
 cyl(m,"FlushTurntableFoundation",3194,.61,z,.1,23.2,C.Charcoal,"Y")
 local tableTop=cyl(m,"FullCarTurntableDeck",3194,.7,z,.13,22.6,C.CleanPanel,"Y")
 socket(tableTop,"TurntableAxis_"..index,"FUTURE_ROTATION_AXIS")
 cyl(m,"CentralServiceCap",3194,.79,z,.045,.7,C.Galvanized,"Y")
 for j=0,23 do local a=j*math.pi/12
  local p=box(m,"FlushIndexMark",3194+math.cos(a)*11.4,.79,z+math.sin(a)*11.4,.34,.04,.1,C.Galvanized,P,false)
  p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,-a,0)
 end
 for _,x in ipairs({3186,3202}) do box(m,"PlainTyreAlignmentMark",x,.79,z,.08,.025,9.5,C.Galvanized,P,false) end
 -- Curve starts beyond the protected parked-car end, never across its entrance.
 box(m,"CycloramaFloorApron",3209.3,.63,z,12.4,.12,22.8,C.CleanPanel,P,false)
 local radius=2.4;local startX=3213.1
 for j=0,7 do
  local a=j*math.pi/16;local b=(j+1)*math.pi/16;local mid=(a+b)/2
  local x=startX+radius*math.sin(mid);local y=.69+radius*(1-math.cos(mid))
  local p=box(m,"CurvedCycloramaCove",x,y,z,radius*(b-a)+.04,.16,22.8,C.CleanPanel,P,false,CFrame.Angles(0,0,mid))
 end
 box(m,"CycloramaVerticalSweep",3215.5,6.35,z,.22,6.55,22.8,C.CleanPanel,P,true)
 for _,zz in ipairs({z-11.25,z+11.25}) do box(m,"BackdropRearUpright",3216.05,5.4,zz,.4,9.6,.4,C.Steel,M,true) end
 box(m,"BackdropTopRail",3216.05,10.2,z,.5,.35,23,C.Steel,M,true)
 for _,side in ipairs({-1,1}) do
  local zz=z+side*11.8
  box(m,"GripStandFoot",3185.8,1.0,zz,4,.5,.5,C.Charcoal,M,true)
  box(m,"TelescopicGripStand",3185.8,4.9,zz,.4,7.3,.4,C.Steel,M,true)
  cyl(m,"GripKnuckle",3185.8,6.8,zz,.55,.72,C.Stainless,"Z")
  pipe(m,"ShortBoom",Vector3.new(3185.8,7.2,zz),Vector3.new(3188,8.3,zz),.24,C.Steel)
  local lightbox=box(m,"ArticulatedSoftbox",3188,8.3,zz,4.6,3.1,.45,C.Charcoal,M,false)
  local face=box(m,"SoftboxFabricDiffuser",3188,8.3,zz-side*.27,4.2,2.7,.06,C.WarmWhite,Enum.Material.Fabric,false)
  for _,xx in ipairs({3186,3190}) do box(m,"SoftboxEdge",xx,8.3,zz-side*.28,.09,2.7,.09,C.Steel,M,false) end
  socket(face,"SoftboxSocket_"..side,"CONTROLLED_EDITORIAL_LIGHT")
  box(m,"GripCounterweight",3184.6,2.2,zz,.8,1.4,.5,C.Charcoal,M,false)
 end
 local sail=box(m,"OverheadDiffusionSail",3196,11.75,z,13,.35,14,C.WarmWhite,Enum.Material.Fabric,false)
 for _,zz in ipairs({z-7.2,z+7.2}) do box(m,"SailEdgeFrame",3196,11.9,zz,13.6,.24,.22,C.Charcoal,M,false) end
 for _,xx in ipairs({3190,3202}) do pipe(m,"SailSuspension",Vector3.new(xx,12.0,z),Vector3.new(xx,13.7,z),.1,C.Steel) end
 local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Color=C.WarmWhite;light.Brightness=1.1;light.Range=19;light.Angle=105;light.Shadows=false;light.Parent=sail
 box(m,"CameraTravelRail",3192,12.6,z,27,.4,.6,C.Steel,M,true)
 box(m,"CameraRailCarriage",3180,12.2,z,1.8,.45,1.4,C.Charcoal,M,false)
 for _,zz in ipairs({z-.85,z+.85}) do cyl(m,"CarriageWheel",3180,12.45,zz,.24,.42,C.Rubber,"Z") end
 box(m,"CameraSuspensionStem",3180,11.4,z,.4,1.3,.4,C.Stainless,M,false)
 cyl(m,"PanTiltHead",3180,10.6,z,.45,1.15,C.Charcoal,"Y")
 box(m,"StudioCameraBody",3180,9.95,z,1.85,1.2,1.45,C.Charcoal,P,false)
 cyl(m,"CameraLensBarrel",3181.3,9.8,z,1.1,.85,C.Steel,"X")
 cyl(m,"FocusRing",3181.3,9.8,z,.15,.95,C.Charcoal,"X")
 local lens=cyl(m,"CameraFrontElement",3181.9,9.8,z,.08,.7,C.Glass,"X")
 socket(lens,"EditorialCapture_"..index,"CAPTURE_VEHICLE_LISTING")
 box(m,"CameraTopHandle",3180,10.7,z,1.6,.18,.3,C.Steel,M,false)
 box(m,"CameraCableChain",3185,12.23,z-.65,8,.2,.24,C.Charcoal,P,false)
 box(m,"TurntableDriveCabinet",3219,2.7,z+8.9,2.6,4.0,2.5,Blue,M,true)
 for j=0,4 do box(m,"DriveCoolingVent",3220.35,1.6+j*.43,z+8.9,.08,.09,1.7,C.Charcoal,P,false) end
 cyl(m,"LockedDriveKey",3220.4,4,z+8.9,.12,.3,C.Red,"X")
 point(m,"PhotoBayOperator_"..index,3222,.6,z,"OPERATOR")
 point(m,"VehicleCaptureOrigin_"..index,3194,8.9,z,"FX")
end
local function editorial(owner)
 local m=group(owner,"Editorial_And_Listing_Workstation","HERO","DEDICATED","Phone listing -> edited imagery -> Institution listing-quality control")
 box(m,"EditorialWorktop",3241,3.6,158,7.3,.3,12.5,C.Timber,Enum.Material.Wood,true)
 for _,z in ipairs({153.4,162.6}) do
  box(m,"DeskPedestal",3243,2.0,z,3.5,3,2.1,C.Charcoal,M,true)
  for i=0,2 do box(m,"DrawerFront",3241.2,1.1+i*.87,z,.12,.7,1.85,C.Steel,M,false);box(m,"DrawerPull",3241.09,1.1+i*.87,z,.1,.1,.7,C.Galvanized,M,false) end
 end
 for _,z in ipairs({155.3,159.5}) do
  box(m,"MonitorArmFoot",3242.1,3.95,z,1.1,.25,1.5,C.Charcoal,M,false)
  pipe(m,"MonitorArm",Vector3.new(3242.1,4.0,z),Vector3.new(3242.1,5.3,z),.2,C.Steel)
  local s=screen(m,"EditingMonitor",3242.1,6.0,z,3.5,2.4,"LISTING_MEDIA")
  box(m,"ImagePreviewField",3241.9,6.0,z,.025,1.65,2.6,C.Galvanized,P,false)
  box(m,"PreviewCarSilhouette",3241.87,5.88,z,.03,.45,1.6,Blue,P,false)
  for _,zz in ipairs({z-.55,z+.55}) do cyl(m,"PreviewWheel",3241.84,5.57,zz,.04,.26,C.Charcoal,"X") end
 end
 box(m,"EditingKeyboard",3239,3.83,157,.8,.12,2.5,C.Charcoal,P,false)
 for i=0,3 do box(m,"KeyboardKeys",3239,3.91,156.1+i*.58,.55,.04,.36,C.Steel,P,false) end
 box(m,"PenTablet",3239,3.84,160.8,1.5,.12,2.0,C.Charcoal,P,false)
 pipe(m,"Stylus",Vector3.new(3238.6,4,161),Vector3.new(3239.1,4,161.6),.08,C.Stainless)
 local out=screen(m,"ListingPriceOutput",3242.4,5.5,163.0,1.85,1.3,"LISTING_PRICE")
 out:SetAttribute("RuntimeBinding","PENDING_NO_ECONOMY_IMPLEMENTATION")
 box(m,"PendingPriceField",3242.2,5.4,163.0,.035,.12,1.2,C.WarmWhite,P,false)
 point(m,"EditorialOperator",3235,.6,158,"OPERATOR")
end
local function provenance(owner)
 local m=group(owner,"Provenance_Capture_And_Build_Record","STORY","PROFESSIONAL","Seller note -> documented build -> repeatable before/after provenance")
 box(m,"DocumentCaptureBench",3241,3.5,173,7,.3,9,C.CleanPanel,M,true)
 for _,xx in ipairs({3238.2,3243.8}) do for _,z in ipairs({169.5,176.5}) do box(m,"CaptureBenchLeg",xx,2,z,.45,3,.45,C.Steel,M,true) end end
 box(m,"DocumentMat",3240,3.69,172.3,3.6,.06,4.4,C.Charcoal,P,false)
 for _,z in ipairs({171,174}) do box(m,"SampleBuildRecord",3240,3.74,z,2.6,.03,1.7,C.WarmWhite,P,false) end
 box(m,"CopyStandColumn",3243.6,5.5,172,.3,4.1,.3,C.Steel,M,false)
 box(m,"CopyStandArm",3241.8,7.6,172,3.8,.3,.3,C.Steel,M,false)
 local camera=box(m,"DocumentCamera",3240,7.1,172,.9,.8,1.3,C.Charcoal,P,false)
 cyl(m,"DocumentCameraLens",3240,6.59,172,.28,.6,C.Glass,"Y")
 socket(camera,"ProvenanceCapture","DOCUMENT_BUILD_RECORD")
 for row=0,1 do for col=0,3 do
  local card=box(m,"CalibrationColourPatch",3245.6,5.1+row*.75,170.8+col*.9,.08,.55,.65,({C.WarmWhite,C.Charcoal,C.Red,Blue})[col+1],P,false)
  card:SetAttribute("ReferenceOnly",true)
 end end
 box(m,"ProvenanceArchive",3245.5,3.15,177.3,3.3,5.0,2.3,C.Navy,M,true)
 for i=0,3 do box(m,"RecordDrawer",3243.8,1.4+i*1.1,177.3,.13,.9,2,C.Steel,M,false);box(m,"RecordIndexSlot",3243.7,1.4+i*1.1,177.3,.05,.24,.65,C.WarmWhite,P,false) end
 point(m,"ProvenanceOperator",3235,.6,173,"OPERATOR")
end
local function gripStore(owner)
 local m=group(owner,"Camera_Grip_And_Calibration_Store","SUPPORT","DEDICATED","Camera bag -> lens/lighting cases -> calibrated capture kit")
 for _,x in ipairs({3241,3247}) do for _,z in ipairs({184,196}) do box(m,"EquipmentRackPost",x,4.7,z,.35,8,.35,C.Steel,M,true) end end
 for _,y in ipairs({1.1,3.8,6.5,8.4}) do box(m,"EquipmentShelf",3244,y,190,6.7,.25,12.7,C.Galvanized,M,true) end
 for _,z in ipairs({186,190,194}) do
  box(m,"CameraTransitCase",3243.7,2.1,z,4.9,1.7,3,C.Charcoal,P,false)
  for _,zz in ipairs({z-.95,z+.95}) do box(m,"CaseLatch",3241.19,2.1,zz,.12,.4,.3,C.Stainless,M,false) end
  box(m,"CaseCarryHandle",3241.07,2.4,z,.15,.3,.9,C.Steel,M,false)
  cyl(m,"ProtectedLensBody",3243.8,4.75,z,1.7,1.2,C.Charcoal,"Y")
  cyl(m,"LensGripRing",3243.8,4.8,z,.16,1.32,C.Steel,"Y")
  cyl(m,"LensCap",3243.8,5.67,z,.12,1.25,C.Charcoal,"Y")
 end
 for i=0,2 do box(m,"FoldedReflector",3243.7,7.1+i*.3,190,4.2,.25,10,C.WarmWhite,Enum.Material.Fabric,false) end
 for _,z in ipairs({186,191,196}) do
  pipe(m,"ParkedLightStand",Vector3.new(3238.6,1.0,z),Vector3.new(3238.6,7.4,z),.24,C.Steel)
  for _,dx in ipairs({-.7,.7}) do pipe(m,"FoldedStandLeg",Vector3.new(3238.6,3,z),Vector3.new(3238.6+dx,1,z+.5),.16,C.Charcoal) end
 end
 point(m,"GripEquipmentOperator",3235,.6,190,"OPERATOR")
end
local function prepCart(owner)
 local m=group(owner,"Capture_Preparation_Trolley","SUPPORT","DEDICATED","Last cloth wipe -> consistent studio presentation")
 for _,y in ipairs({1.4,3.4}) do box(m,"PrepTray",3221,y,175,3.7,.3,3.7,C.Charcoal,M,y<2) end
 for _,x in ipairs({3219.4,3222.6}) do for _,z in ipairs({173.4,176.6}) do
  box(m,"PrepCartPost",x,2.6,z,.18,2.9,.18,C.Steel,M,false)
  cyl(m,"PrepCaster",x,.95,z,.3,.55,C.Rubber,"Z")
 end end
 for i=0,2 do box(m,"CleanStudioCloth",3221,3.68+i*.18,175,2.6,.16,2.4,C.WarmWhite,Enum.Material.Fabric,false) end
 box(m,"NumberPlateBlank",3221,1.63,175,2.8,.1,.8,C.Galvanized,P,false)
 point(m,"PreparationOperator",3224.5,.6,175,"OPERATOR")
end
local function finish(owner)
 local m=group(owner,"Editorial_Floor_And_Service_Edge","ARCHITECTURE","WORKING","Yard listing corner -> controlled studio floor")
 for _,z in ipairs({163,187}) do
  box(m,"StudioEntryApron",3178,.64,z,15,.1,14,C.OldConcrete,Enum.Material.Concrete,false)
  box(m,"RestrainedPortalCap",3169,12.4,z,1.48,1.38,16.8,C.Charcoal,M,true)
  box(m,"EditorialBlueInset",3168.23,12.4,z,.08,.25,12,Blue,M,false)
 end
 box(m,"StaffNonSlipWalk",3229,.64,175,6,.12,48,C.Concrete,Enum.Material.Concrete,false)
 for _,z in ipairs({153,167,182,197}) do box(m,"StudioWallJoint",3251.9,6,z,.08,9,.05,C.Steel,M,false) end
 light(m,3240,175,18)
 path(owner,"ContinuousStaffAccess",{{3229,151},{3229,199}})
 path(owner,"Bay1OperatorApproach",{{3229,163},{3222,163}})
 path(owner,"Bay2OperatorApproach",{{3229,187},{3222,187}})
 path(owner,"EditorialApproach",{{3229,158},{3235,158}})
 path(owner,"ProvenanceApproach",{{3229,173},{3235,173}})
 path(owner,"GripStoreApproach",{{3229,190},{3235,190}})
 path(owner,"PreparationApproach",{{3229,175},{3224.5,175}})
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
 root():SetAttribute("InstitutionFidelityPhase4EPhotoStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["08_Institution_Production_A"].Photo_Listing
  for _,c in ipairs(old:GetChildren()) do if c.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,c) end end
  suppress(l,old["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  local mass=root()["05_Architecture_Massing"]["02_Production"].Photo_Listing
  for _,n in ipairs({"MaximumFunctionEnvelope","EquipmentAndStaffBand"}) do suppress(l,mass[n]) end
  for i=1,2 do suppress(l,mass["OpenPortal_"..i].PortalHeader);suppress(l,root()["04_Capacity_Sockets"]["Photo_Listing_Bay_"..i]) end
  studioCell(l,1,163);studioCell(l,2,187);editorial(l);provenance(l);gripStore(l);prepCart(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase4EPhotoStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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
 check("PhotoSixStudStaffAisle",CFrame.new(3229,4.5,175),Vector3.new(6,7.5,48))
 local stats={parts=0,solids=0,lights=0,models=0,accessPaths=0,standingVolumes=0,floorSamples=0,missingFloor={},issues=issues,metadataIssues=metadata,signature=signature(l)}
 params.FilterDescendantsInstances={root()}
 stats.rotationSamples=0
 for _,z in ipairs({163,187}) do for deg=0,355,5 do
  stats.rotationSamples+=1
  check("PhotoFullCarRotation_"..z.."_"..deg,CFrame.new(3194,4.1,z)*CFrame.Angles(0,math.rad(deg),0),Vector3.new(18.94,6.4,10.58))
 end end
 stats.adjacentRotationCircleGap=24-math.sqrt(18.94^2+10.58^2)
 if stats.adjacentRotationCircleGap<=0 then table.insert(issues,"Adjacent car rotation circles overlap") end
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
    if v.X<3168 or v.X>3252 or v.Z<150 or v.Z>200 or v.Y>13.85 then outside=true end
   end end end
   if outside then table.insert(issues,"PhotoFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase4EPhotoStatus","ACCEPTED");return a
end
return I

