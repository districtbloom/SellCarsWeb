--!nocheck
-- Phase 4D owns Detail/QC only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase4d.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","03_Remaining_Production","04_Detail"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Detail_QC."..n..".FidelityR1",FunctionId="Detail_QC",ZoneId="Detail_QC",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase4DDetailGeometry",true);p.Parent=m;return p
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


local Teal=Color3.fromRGB(68,128,129)
local function hose(m,n,x,y,z,r,axis)
 for j=0,9 do
  local a=j*math.pi/5;local b=(j+1)*math.pi/5
  local function v(t) if axis=="Y" then return Vector3.new(x+math.sin(t)*r,y,z+math.cos(t)*r) end;return Vector3.new(x,y+math.sin(t)*r,z+math.cos(t)*r) end
  pipe(m,n,v(a),v(b),.16,C.Rubber)
 end
end
local function caster(m,x,z)
 for _,dx in ipairs({-1.35,1.35}) do for _,dz in ipairs({-1.2,1.2}) do cyl(m,"Caster",x+dx,.92,z+dz,.35,.56,C.Rubber,"Z") end end
end
local function bottle(m,x,y,z,col)
 cyl(m,"FinishChemistryBottle",x,y,z,.85,.55,col,"Y")
 cyl(m,"BottleShoulder",x,y+.48,z,.16,.42,col,"Y")
 cyl(m,"MeteredDispensingCap",x,y+.66,z,.24,.2,C.Charcoal,"Y")
 box(m,"BatchLabel",x-.3,y,z,.03,.3,.35,C.WarmWhite,P,false)
end
local function correction(owner,index,z)
 local m=group(owner,"Correction_Light_Cell_"..index,"HERO","DEDICATED","Hand polish -> dedicated correction lights -> measured final finish")
 m:SetAttribute("BayIndex",index);m:SetAttribute("ParkedState","TOOLS_STOWED_LAMPS_FIXED_OUTSIDE_CAR_ENVELOPE")
 box(m,"CleanCorrectionFloor",3194,.62,z,34,.1,14,C.CleanPanel,Enum.Material.Concrete,false)
 for _,side in ipairs({-1,1}) do
  local zz=z+side*8.6
  for _,x in ipairs({3183,3205}) do
   box(m,"LampFrameFoot",x,1.05,zz,2.5,.5,1.4,C.Charcoal,M,true)
   box(m,"TelescopingFrame",x,5.4,zz,.55,8.4,.55,C.Steel,M,true)
   box(m,"UpperFrameInsert",x,10.05,zz,.35,1.0,.35,C.Stainless,M,false)
   cyl(m,"LampTiltPivot",x,5.2,zz,.9,.45,Teal,"Z")
   box(m,"VerticalLampHousing",x,5.6,zz-side*.42,.65,6.9,.28,C.CleanPanel,M,false)
   box(m,"DiffuseInspectionStrip",x,5.6,zz-side*.58,.34,6.5,.06,C.WarmWhite,P,false)
   for _,y in ipairs({2.3,8.8}) do box(m,"LampEndCap",x,y,zz-side*.42,.73,.24,.35,C.Charcoal,P,false) end
   local a,b=Vector3.new(x,10.25,zz),Vector3.new(x,11.2,z+side*5.8)
   local h=box(m,"ShoulderInspectionLamp",x,10.7,zz,.75,.4,(b-a).Magnitude,C.Charcoal,M,false)
   h.CFrame=CFrame.lookAt((a+b)/2,b)
   local diffuser=box(m,"ShoulderLightDiffuser",x,10.7,zz,.5,.06,(b-a).Magnitude-.2,C.WarmWhite,P,false)
   diffuser.CFrame=h.CFrame*CFrame.new(0,-.24,0)
  end
  box(m,"UpperLampSpine",3194,10.3,zz,24,.4,.4,C.Steel,M,true)
  box(m,"RakingLightHousing",3194,7.65,zz-side*.42,24,.6,.3,C.Charcoal,M,false)
  box(m,"RakingLightDiffuser",3194,7.65,zz-side*.6,23,.24,.07,C.WarmWhite,P,false)
 end
 box(m,"OverheadInspectionBridge",3194,11.3,z,1.1,.5,16,C.Steel,M,true)
 for _,zz in ipairs({z-4,z+4}) do
  local sensor=box(m,"GlossMeasurementHead",3194,10.85,zz,.8,.45,.8,C.CleanPanel,M,false)
  cyl(m,"MeasurementLens",3194,10.59,zz,.08,.42,C.Glass,"Y")
  socket(sensor,"GlossReference","FINISH_MEASUREMENT")
 end
 local x,zz=3217.8,z+8.8
 box(m,"PolishCartLowerTray",x,1.5,zz,3.6,.3,3.4,Teal,M,true)
 box(m,"PolishCartUpperTray",x,3.4,zz,3.6,.25,3.4,C.Charcoal,M,false)
 for _,dx in ipairs({-1.6,1.6}) do for _,dz in ipairs({-1.5,1.5}) do box(m,"CartUpright",x+dx,2.6,zz+dz,.18,2.8,.18,C.Steel,M,false) end end
 caster(m,x,zz)
 for _,dx in ipairs({-.9,.9}) do
  cyl(m,"FoamCorrectionPad",x+dx,3.66,zz-.6,.2,1.25,dx<0 and C.WarmWhite or Teal,"Y")
  cyl(m,"PadBacking",x+dx,3.8,zz-.6,.08,1,C.Charcoal,"Y")
 end
 box(m,"DualActionPolisherMotor",x,3.99,zz+.8,1.6,.55,.65,Teal,P,false)
 box(m,"PolisherHandle",x+.95,4.01,zz+.8,.65,.4,.4,C.Charcoal,P,false)
 cyl(m,"PolisherDriveHead",x-.85,3.82,zz+.8,.45,.4,C.Steel,"Y")
 cyl(m,"WorkingPad",x-.85,3.57,zz+.8,.15,1.05,C.WarmWhite,"Y")
 hose(m,"ParkedPowerLead",x,2.25,zz+.4,.75)
 point(m,"DetailBayOperator_"..index,3222,.6,z,"OPERATOR")
 point(m,"FinishVehicleSocket_"..index,3194,8.7,z,"FX")
 light(m,3194,z,12)
end
local function steam(owner)
 local m=group(owner,"Steam_And_Spot_Extraction_Cart","HERO","DEDICATED","Hand wiping -> controlled spot steam and extraction")
 local x,z=3240,217
 box(m,"SteamTrolley",x,1.35,z,4.8,.4,4.1,C.Charcoal,M,true)
 for _,zz in ipairs({z-1.25,z+1.25}) do for _,xx in ipairs({x-1.7,x+1.7}) do cyl(m,"SteamWheel",xx,1.05,zz,.4,.8,C.Rubber,"X") end end
 cyl(m,"SteamBoiler",x,3.25,z,3.7,3.2,C.Stainless,"Y",true)
 cyl(m,"BoilerTop",x,5.17,z,.28,3.35,C.Charcoal,"Y")
 box(m,"ControlBridge",x,5.45,z,2.8,.55,2.1,Teal,M,false)
 cyl(m,"PressureGauge",x-1.5,5.45,z,.18,.72,C.WarmWhite,"X")
 pipe(m,"GaugeNeedle",Vector3.new(x-1.61,5.45,z),Vector3.new(x-1.61,5.66,z+.2),.055,C.Red)
 cyl(m,"SteamValve",x,5.96,z-.4,.3,.45,C.Red,"Y")
 for _,zz in ipairs({z-1.7,z+1.7}) do box(m,"CartPushUpright",x+1.7,3.9,zz,.25,4.6,.25,C.Steel,M,false) end
 pipe(m,"CartPushHandle",Vector3.new(x+1.7,6.2,z-1.7),Vector3.new(x+1.7,6.2,z+1.7),.25,C.Steel)
 hose(m,"ParkedSteamHose",x-2.4,3.4,z,1.15)
 local wand=pipe(m,"SteamWand",Vector3.new(x-2.3,4.5,z),Vector3.new(x-2.5,6.5,z+1.2),.21,C.Charcoal)
 socket(wand,"SteamOutlet","PARKED_HAND_STEAM")
 point(m,"SteamOperator",3235,.6,217,"OPERATOR")
end
local function vacuum(owner)
 local m=group(owner,"Filtered_Wet_Dry_Vacuum","HERO","WORKING","Portable vacuum -> controlled clean-up and filtration")
 local x,z=3240,229
 box(m,"VacuumCasterBase",x,1.23,z,4.5,.5,4.2,C.Charcoal,M,true);caster(m,x,z)
 cyl(m,"StainlessCollectionDrum",x,3.2,z,3.45,3.7,C.Stainless,"Y",true)
 cyl(m,"DrumLid",x,5,z,.42,3.9,C.Charcoal,"Y")
 cyl(m,"VacuumMotorHead",x,5.7,z,1.25,2.25,Teal,"Y")
 for i=0,5 do box(m,"MotorCoolingLouvre",x-1.16,5.36+i*.15,z,.08,.055,1.3,C.Charcoal,P,false) end
 cyl(m,"VacuumHosePort",x-2.06,3.45,z,.45,.75,C.Rubber,"X")
 hose(m,"CoiledVacuumHose",x-2.65,3.2,z,1.18)
 for _,zz in ipairs({z-1.5,z+1.5}) do box(m,"DrumRetainingLatch",x-1.65,4.8,zz,.35,.8,.18,C.Steel,M,false) end
 local wand=pipe(m,"ParkedVacuumWand",Vector3.new(x+1.4,1.7,z+1),Vector3.new(x+1.7,6.9,z+1.3),.26,C.Stainless)
 box(m,"FloorSuctionHead",x+1.4,1.5,z+1,1,.3,2.1,C.Charcoal,P,false)
 socket(wand,"VacuumToolSocket","PARKED_VACUUM")
 point(m,"VacuumOperator",3234.5,.6,229,"OPERATOR")
end
local function consumables(owner)
 local m=group(owner,"Clean_Towels_Pads_And_Finish_Tools","SUPPORT","DEDICATED","Shared cloth box -> clean colour-separated consumables")
 local x,z=3244,241.5
 for _,xx in ipairs({3241,3247}) do for _,zz in ipairs({237,246}) do box(m,"CleanRackPost",xx,4.1,zz,.3,7,.3,C.Stainless,M,true) end end
 for _,y in ipairs({1.15,3.55,5.95,7.7}) do box(m,"CleanShelf",x,y,z,6.8,.2,9.6,C.CleanPanel,M,true) end
 for row=0,2 do for col=0,2 do
  local zz=238.5+col*3;local y=1.7+row*2.4
  local shade=({C.WarmWhite,Teal,C.Galvanized})[col+1]
  for layer=0,2 do
   box(m,"FoldedMicrofibre",3243.1,y+layer*.21,zz,3.9,.2,2.1,shade,Enum.Material.Fabric,false)
   box(m,"TowelFoldEdge",3241.2,y+layer*.21,zz,.15,.16,1.9,shade,Enum.Material.Fabric,false)
  end
 end end
 for i=0,3 do cyl(m,"ProtectedPolishingPad",3247.45,2+i*1.2,244.8,.3,1.0,i%2==0 and C.WarmWhite or Teal,"X") end
 box(m,"ClosedUsedClothBin",3239.2,2,245,2.7,2.6,2.5,C.Steel,M,true)
 box(m,"BinFootPedal",3237.7,.93,245,.55,.18,1.0,C.Charcoal,P,false)
 point(m,"ConsumablesOperator",3235,.6,242,"OPERATOR")
end
local function chemistry(owner)
 local m=group(owner,"Finish_Chemistry_And_Dilution_Control","SUPPORT","PROFESSIONAL","Loose compounds -> controlled chemistry and clean dispensing")
 local x,z=3243.7,253
 box(m,"ChemistryCabinet",x,3.35,z,6.4,5.7,6.4,Teal,M,true)
 for _,zz in ipairs({251.3,254.7}) do
  box(m,"CabinetDoor",3240.45,3.4,zz,.14,4.95,3.05,C.CleanPanel,M,false)
  pipe(m,"DoorPull",Vector3.new(3240.23,3.1,zz-.8),Vector3.new(3240.23,4.05,zz-.8),.13,C.Charcoal)
 end
 box(m,"BundedDispensingTop",x,6.33,z,6.7,.3,6.7,C.Stainless,M,false)
 for i=0,2 do for j=0,1 do bottle(m,3242.3+j*2.5,7,251+i*1.8,({C.WarmWhite,Teal,C.Galvanized})[i+1]) end end
 box(m,"DilutionMeasureTray",3240.8,6.58,253,1.1,.17,4.5,C.Charcoal,P,false)
 cyl(m,"MeasuringBeaker",3240.8,7.08,252,.85,.6,C.CleanPanel,"Y")
 cyl(m,"LiddedChemicalWaste",3248.2,2.1,254.4,2.8,2.05,C.Steel,"Y",true)
 point(m,"ChemistryOperator",3235,.6,253,"OPERATOR")
end
local function qc(owner)
 local m=group(owner,"Finish_Measurement_And_Release_Desk","HERO","PROFESSIONAL","Visual pre-sale check -> measured finish quality and release record")
 box(m,"ReleaseBench",3241,3.45,262,7,.3,5.1,C.Timber,Enum.Material.Wood,true)
 for _,xx in ipairs({3238.1,3243.9}) do for _,zz in ipairs({260,264}) do box(m,"BenchLeg",xx,1.95,zz,.5,3,.5,C.Steel,M,true) end end
 box(m,"InspectionInstrumentCase",3241.3,3.83,262.8,3,.4,2.2,C.Charcoal,P,false)
 box(m,"CaseFoam",3241.3,4.08,262.8,2.7,.12,1.9,C.Rubber,P,false)
 box(m,"GlossMeter",3240.5,4.37,262.8,1.1,.5,.7,C.CleanPanel,P,false)
 box(m,"PaintThicknessGauge",3242.1,4.35,262.7,.75,.5,.9,Teal,P,false)
 box(m,"GaugeDisplay",3242.1,4.62,262.7,.45,.04,.48,C.Navy,P,false)
 local torch=cyl(m,"InspectionTorch",3241,4.03,260.8,1.5,.32,C.Charcoal,"Z")
 socket(torch,"FinishInspectionLight","HAND_INSPECTION")
 box(m,"ReleaseTabletStand",3243.6,4.25,261,.3,1.4,.4,C.Steel,M,false)
 box(m,"ReleaseTablet",3243.5,5.15,261,.18,1.6,2,C.Charcoal,P,false)
 box(m,"ReleaseScreen",3243.39,5.15,261,.04,1.32,1.72,C.Navy,P,false)
 for i=0,2 do box(m,"QCRecordLine",3243.35,4.77+i*.35,261,.035,.08,1.35,C.WarmWhite,P,false) end
 box(m,"ReleaseRecord",3239,3.65,260.8,1.3,.04,1.8,C.WarmWhite,P,false)
 point(m,"QCReleaseOperator",3235,.6,262,"OPERATOR")
end
local function finish(owner)
 local m=group(owner,"Detail_Clean_Floor_And_Service_Edge","ARCHITECTURE","WORKING","Pre-sale yard corner -> clean final-finish workshop")
 for _,z in ipairs({227,251}) do
  box(m,"RestrainedPortalCap",3169,12.4,z,1.48,1.38,16.8,C.Charcoal,M,true)
  box(m,"PaintedTealInset",3168.23,12.4,z,.08,.25,12,Teal,M,false)
  for _,x in ipairs({3178,3210}) do box(m,"PlainPositionEnd",x,.71,z,.14,.04,12.6,C.Galvanized,P,false) end
 end
 box(m,"StaffNonSlipWalk",3229,.64,239,6,.12,52,C.Concrete,Enum.Material.Concrete,false)
 box(m,"WetToolServiceMat",3240,.68,222,10,.1,19,C.Charcoal,Enum.Material.DiamondPlate,false)
 for i=0,7 do box(m,"WetToolDrainSlot",3246.6,.76,215+i*1.8,.8,.04,.12,C.Steel,M,false) end
 for _,z in ipairs({231.8,247,257}) do box(m,"WetDryThreshold",3242,.72,z,13,.045,.13,C.Galvanized,P,false) end
 for _,z in ipairs({218,234,250,263}) do box(m,"WorkshopWallJoint",3251.9,6,z,.08,9,.05,C.Steel,M,false) end
 light(m,3240,239,21)
 path(owner,"ContinuousStaffAccess",{{3229,213},{3229,265}})
 path(owner,"Bay1OperatorApproach",{{3229,227},{3222,227}})
 path(owner,"Bay2OperatorApproach",{{3229,251},{3222,251}})
 for _,pair in ipairs({{217,3235},{229,3234.5},{242,3235},{253,3235},{262,3235}}) do path(owner,"ServiceApproach_"..pair[1],{{3229,pair[1]},{pair[2],pair[1]}}) end
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
 root():SetAttribute("InstitutionFidelityPhase4DDetailStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["08_Institution_Production_A"].Detail_QC
  for _,c in ipairs(old:GetChildren()) do if c.Name~="08_Staff_Aisle_and_Occupation" then suppress(l,c) end end
  suppress(l,old["08_Staff_Aisle_and_Occupation"].ProtectedStaffAisle)
  local mass=root()["05_Architecture_Massing"]["02_Production"].Detail_QC
  for _,n in ipairs({"MaximumFunctionEnvelope","EquipmentAndStaffBand"}) do suppress(l,mass[n]) end
  for i=1,2 do suppress(l,mass["OpenPortal_"..i].PortalHeader);suppress(l,root()["04_Capacity_Sockets"]["Detail_QC_Bay_"..i]) end
  correction(l,1,227);correction(l,2,251);steam(l);vacuum(l);consumables(l);chemistry(l);qc(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase4DDetailStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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
 check("DetailSixStudStaffAisle",CFrame.new(3229,4.5,239),Vector3.new(6,7.5,52))
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
    if v.X<3168 or v.X>3252 or v.Z<212 or v.Z>266 or v.Y>13.85 then outside=true end
   end end end
   if outside then table.insert(issues,"DetailFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase4DDetailStatus","ACCEPTED");return a
end
return I

