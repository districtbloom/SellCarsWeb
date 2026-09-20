--!nocheck
-- Phase 5A owns Intake/Appraisal only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase5a.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","04_Frontage_And_Owner","01_Intake"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Intake_Appraisal."..n..".FidelityR1",FunctionId="Intake_Appraisal",ZoneId="Intake_Appraisal",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase5AIntakeGeometry",true);p.Parent=m;return p
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




local Slate=Color3.fromRGB(66,88,94)
local function plaque(m,n,x,y,z,w,h,text)
 local p=box(m,n,x,y,z,w,h,.16,C.Charcoal,M,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(720,140);g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextScaled=true;t.TextColor3=C.WarmWhite;t.Parent=g
 return p
end
local function monitor(m,n,x,y,z,w,h)
 box(m,n.."_Frame",x,y,z,w,h,.24,C.Charcoal,P,false)
 return box(m,n.."_Display",x,y,z-.15,w-.25,h-.25,.04,Slate,P,false)
end
local function cart(m,x,z)
 for _,y in ipairs({1.3,3.0}) do box(m,"LippedTrolleyTray",x,y,z,3.1,.25,3.0,C.Galvanized,M,y<2) end
 for _,xx in ipairs({x-1.3,x+1.3}) do for _,zz in ipairs({z-1.2,z+1.2}) do
  box(m,"CartUpright",xx,2.2,zz,.17,2.6,.17,C.Steel,M,false)
  cyl(m,"SwivelCaster",xx,.88,zz,.24,.5,C.Rubber,"Z")
 end end
 pipe(m,"CartHandle",Vector3.new(x-1.3,3.5,z+1.2),Vector3.new(x+1.3,3.5,z+1.2),.18,C.Steel)
end
local function canopy(l)
 local m=group(l,"Receiving_Canopy_Construction","ARCHITECTURE","WORKING","Roadside shade -> receiving canopy -> finely resolved institutional structure")
 -- Exact accepted roof volume, with opaque standing-seam finish instead of blue transparency.
 box(m,"CanopyRoof",3040,13.4,49,72,1,72,C.Charcoal,M,false)
 for _,x in ipairs({3005,3076}) do for _,z in ipairs({14,85}) do if not(x==3076 and z==85) then
  box(m,"ColumnBasePlate",x,.72,z,2.3,.18,2.3,C.Steel,M,true)
  for _,dx in ipairs({-.8,.8}) do for _,dz in ipairs({-.8,.8}) do cyl(m,"AnchorBolt",x+dx,.91,z+dz,.2,.17,C.Stainless,"Y") end end
  box(m,"ColumnCapital",x,12.3,z,2.0,.55,2.0,C.Steel,M,false)
 end end end
 for _,z in ipairs({14,49,84}) do
  box(m,"CanopyIBeamWeb",3040,12.3,z,71,.65,.22,C.Steel,M,false)
  for _,y in ipairs({11.9,12.7}) do box(m,"CanopyIBeamFlange",3040,y,z,71,.12,.9,C.Charcoal,M,false) end
 end
 for x=3008,3072,8 do box(m,"RoofStandingSeam",x,13.95,49,.12,.11,71,C.Steel,M,false) end
 for _,x in ipairs({3004.1,3075.9}) do box(m,"PerimeterGutter",x,13.0,49,.55,.5,71,C.Galvanized,M,false) end
 pipe(m,"WestDownpipe",Vector3.new(3004.0,12.8,14.9),Vector3.new(3004.0,1.0,14.9),.3,C.Galvanized)
 box(m,"FrontFascia",3040,11.2,14,72,3.8,1.1,C.Charcoal,M,false)
 for x=3008,3072,2 do box(m,"WarmFasciaSlat",x,11.2,13.39,1.45,2.8,.13,C.Timber,Enum.Material.Wood,false) end
 plaque(m,"BusinessIdentity",3040,11.2,13.22,25,2.0,"DESERT CUSTOMS  /  RECEIVING")
 point(m,"ReceivingAmbient",3040,12,49,"FX")
end
local function appraisal(l,index,x,cartX)
 local m=group(l,"Ordinary_Condition_Station_"..index,"HERO","WORKING","Clipboard beside parked car -> transparent condition terminal and acquisition record")
 m:SetAttribute("Capacity",1);m:SetAttribute("DataContract","TRANSPARENT_CONDITION_NOT_INSPECTION_REVEAL")
 box(m,"AppraisalFloorInset",x,.65,35,13,.12,22,C.OldConcrete,Enum.Material.Concrete,false)
 for _,xx in ipairs({x-6.15,x+6.15}) do box(m,"RestrainedParkingEdge",xx,.73,35,.10,.025,21,C.WarmWhite,P,false) end
 -- All supports are suspended above protected car and transporter volumes.
 box(m,"DocumentationBridge",x,10.75,35,20.8,.45,.8,C.Steel,M,false)
 for _,xx in ipairs({x-9,x+9}) do
  pipe(m,"BridgeSuspension",Vector3.new(xx,11.0,35),Vector3.new(xx,12.9,35),.15,C.Steel)
  box(m,"ShieldedConditionLight",xx,10.4,35,1.3,.5,7,C.CleanPanel,M,false)
  box(m,"ConditionDiffuser",xx,10.12,35,1.05,.06,6.6,C.WarmWhite,Enum.Material.Neon,false)
 end
 box(m,"RecordCameraBracket",x,10.15,35,.8,.7,.8,C.Charcoal,M,false)
 box(m,"VehicleRecordCamera",x,9.65,35,1.2,.6,1.5,C.CleanPanel,P,false)
 local p=cyl(m,"CameraOptic",x,9.28,35,.18,.56,C.Glass,"Y");socket(p,"ArrivalRecord_"..index,"RECORD_VISIBLE_START_CONDITION")
 local lum=Instance.new("SurfaceLight");lum.Face=Enum.NormalId.Bottom;lum.Range=16;lum.Brightness=.8;lum.Shadows=false;lum.Color=C.WarmWhite;lum.Parent=m.ShieldedConditionLight
 cart(m,cartX,28)
 box(m,"TabletStand",cartX,3.65,28,.18,1.2,.25,C.Steel,M,false)
 local display=monitor(m,"ConditionTablet",cartX,4.25,28,2.6,1.9)
 display:SetAttribute("DataBindingKey","VISIBLE_CONDITION_AND_ASKING_PRICE");display:SetAttribute("RuntimeBinding","PENDING")
 for i=0,3 do
  box(m,"ConditionCategoryRow",cartX-.4,4.8-i*.35,27.82,.65,.12,.025,C.WarmWhite,P,false)
  box(m,"ConditionStateRow",cartX+.6,4.8-i*.35,27.82,.62,.12,.025,i==2 and C.Amber or C.Galvanized,P,false)
 end
 box(m,"DocumentClipTray",cartX,3.18,27.2,1.8,.08,1.0,C.WarmWhite,P,false)
 box(m,"RecordCameraCase",cartX,1.86,28,2.4,.8,1.9,C.Charcoal,P,false)
 for _,xx in ipairs({cartX-.75,cartX+.75}) do box(m,"CaseLatch",xx,1.9,26.99,.14,.28,.10,C.Stainless,M,false) end
 point(m,"OrdinaryAppraiser_"..index,cartX,.6,24,"OPERATOR")
 point(m,"OrdinaryWorkTarget_"..index,x,5,35,"FX")
end
local function special(l)
 local m=group(l,"Special_Receiving_And_Recovery_Kit","HERO","DEDICATED","Tow-safe hold -> specialist protected receiving with documented provenance")
 m:SetAttribute("Capacity",1);m:SetAttribute("ArrivalModes","RARE_OR_TOW_SHARED_NOT_TWO_CARS")
 m:SetAttribute("ParkedState","SKATES_RAMPS_STRAPS_STOWED_NO_DEPLOYED_RECOVERY")
 box(m,"SpecialReceivingInset",3069,.65,62,13,.12,22,C.Concrete,Enum.Material.Concrete,false)
 for _,xx in ipairs({3062.7,3075.3}) do box(m,"SpecialPositionEdge",xx,.73,62,.10,.03,21,C.WarmWhite,P,false) end
 -- Preserve accepted portal/post coordinates; quiet bronze instead of neon gold.
 for _,x in ipairs({3059,3079}) do
  box(m,"SpecialGatePost",x,7.5,62,.9,15,.9,C.Charcoal,M,true)
  box(m,"SpecialPostFoot",x,.74,62,1.6,.2,1.6,C.Steel,M,true)
 end
 box(m,"SpecialGateHeader",3069,14.6,62,20.8,1,1.1,C.Bronze,M,false)
 plaque(m,"RareReceivingIdentity",3069,11.7,62.6,9.5,2.4,"SPECIAL RECEIVING")
 for _,x in ipairs({3065.5,3072.5}) do pipe(m,"SignHanger",Vector3.new(x,12.9,62.6),Vector3.new(x,14.3,62.6),.10,C.Steel) end
 -- All recovery hardware is on the safe east edge of the broad transporter reserve.
 box(m,"RecoveryEquipmentBench",3056,3.35,67,4.8,.3,10,C.Galvanized,M,true)
 for _,z in ipairs({63,71}) do box(m,"RecoveryBenchFrame",3056,1.95,z,4,.35,.5,C.Steel,M,true);for _,x in ipairs({3054,3058}) do box(m,"RecoveryBenchLeg",x,1.95,z,.32,2.7,.32,C.Steel,M,true) end end
 for i=0,1 do
  local z=64.2+i*3.9
  box(m,"WheelSkateCradle",3056,3.9,z,3.5,.5,2.2,C.Bronze,M,false)
  for _,dx in ipairs({-1.2,1.2}) do for _,dz in ipairs({-.7,.7}) do cyl(m,"SkateRoller",3056+dx,3.8,z+dz,.3,.45,C.Rubber,"X") end end
  box(m,"SkateAdjustingScrew",3056,4.25,z,2.5,.13,.18,C.Steel,M,false)
  cyl(m,"SkateScrewHandle",3057.3,4.25,z,.65,.12,C.Stainless,"Z")
 end
 for _,x in ipairs({3054.8,3057.2}) do
  box(m,"StowedLowClearanceRamp",x,1.25,67,1.4,.45,7.5,C.Charcoal,M,false)
  for z=64,70,1 do box(m,"RampTread",x,1.49,z,1.4,.04,.16,C.Steel,M,false) end
 end
 box(m,"StrapAndSoftSlingRack",3056,7.1,72,4.4,4.3,.3,C.Steel,M,false)
 for i=0,3 do
  local x=3054.6+i*.9
  pipe(m,"SlingHook",Vector3.new(x,8.5,71.6),Vector3.new(x,8.5,72),.12,C.Stainless)
  box(m,"FoldedSoftSling",x,6.8,71.65,.42,2.8,.18,i%2==0 and C.Amber or C.Charcoal,Enum.Material.Fabric,false)
  box(m,"RatchetBuckle",x,7.4,71.44,.5,.45,.14,C.Stainless,M,false)
 end
 box(m,"RecoverySpillLocker",3056,2.1,55.5,4.5,2.9,3.8,C.Bronze,M,true)
 box(m,"SpillLockerHandle",3056,2.4,53.51,1,.16,.16,C.Charcoal,M,false)
 box(m,"FireBottleMount",3058,1.8,51.6,.7,2.2,.14,C.Steel,M,false)
 box(m,"BottleFoot",3058,.72,51,.95,.18,.95,C.Charcoal,M,false)
 cyl(m,"FireBottle",3058,1.6,51,1.6,.75,C.Red,"Y")
 cyl(m,"BottleNeck",3058,2.49,51,.2,.25,C.Stainless,"Y")
 pipe(m,"BottleHandle",Vector3.new(3057.75,2.66,51),Vector3.new(3058.25,2.66,51),.12,C.Charcoal)
 cyl(m,"PressureGauge",3058,2.48,50.76,.12,.3,C.WarmWhite,"Z")
 pipe(m,"ParkedBottleHose",Vector3.new(3058.28,2.5,51),Vector3.new(3058.43,1.35,51),.11,C.Rubber)
 point(m,"SpecialReceivingOperator",3056,.6,59,"OPERATOR")
 point(m,"ProtectedCarRecord",3069,8.7,62,"FX")
end
local function records(l)
 local m=group(l,"Provenance_And_Key_Records","SUPPORT","PROFESSIONAL","Ledger book -> secure keys and verified arrival/build history")
 -- Existing west-edge lab envelope; open access, no added room or inspection trip.
 box(m,"RecordsCanopy",3004.5,10.4,85,8,.5,7,C.Charcoal,M,true)
 box(m,"RecordsCounter",3006.3,3.4,85,3.2,.3,5.2,C.Timber,Enum.Material.Wood,true)
 for _,z in ipairs({83,87}) do box(m,"RecordsCounterLeg",3006.7,2,z,.4,2.7,.4,C.Steel,M,true) end
 box(m,"KeysCabinet",3007.7,6.15,85,.45,3.8,5,C.Charcoal,M,true)
 for row=0,2 do for col=0,3 do
  local z=83.4+col
  box(m,"KeyHook",3007.42,5.1+row*1.05,z,.18,.1,.1,C.Stainless,M,false)
  box(m,"KeyTag",3007.26,4.95+row*1.05,z,.08,.48,.35,row==1 and C.Bronze or C.WarmWhite,P,false)
 end end
 box(m,"TitleFolder",3005.9,3.62,83.6,1.6,.10,1.6,C.Bronze,P,false)
 box(m,"RecordsKeyboard",3005.6,3.64,86.2,1.5,.12,1.0,C.Charcoal,P,false)
 box(m,"SecureDropSlot",3007.4,3.0,88,.6,1.8,.3,C.Steel,M,false)
 point(m,"RecordsCustodian",3002,.6,85,"OPERATOR")
end
local function handoff(l)
 local m=group(l,"Shared_Valuation_And_Seller_Handoff","HERO","WORKING","Deal beside car -> shared staffed acquisition counter")
 m:SetAttribute("DataContract","ASKING_AND_ACQUISITION_PRICE_SEPARATE_FROM_LATER_SALE")
 box(m,"HandoffWorktop",3084,3.45,44,8,.35,3.4,C.Timber,Enum.Material.Wood,true)
 box(m,"CounterPlinth",3084,1.9,44,7.2,2.6,2.5,C.Charcoal,M,true)
 for x=3081,3087,.6 do box(m,"CounterTimberSlat",x,1.9,42.68,.38,2.5,.09,C.Timber,Enum.Material.Wood,false) end
 box(m,"DualDisplayPost",3084,4.2,44,.25,1.2,.25,C.Steel,M,false)
 local face=monitor(m,"NegotiationDisplay",3084,5.0,44,3.1,1.9);face:SetAttribute("DataBindingKey","ACQUISITION_NEGOTIATION");face:SetAttribute("RuntimeBinding","PENDING")
 box(m,"SellerFacingDisplay",3084,5.0,44.18,2.8,1.6,.04,Slate,P,false)
 for i=0,2 do box(m,"OfferComparisonField",3084,5.5-i*.45,43.82,2,.12,.035,i==1 and C.Bronze or C.Galvanized,P,false) end
 box(m,"DocumentSigningMat",3086.7,3.67,43.8,2,.08,2.1,C.Charcoal,P,false)
 box(m,"TitleTransferSheet",3086.7,3.74,43.8,1.6,.02,1.8,C.WarmWhite,P,false)
 pipe(m,"CounterPen",Vector3.new(3087.4,3.8,43.1),Vector3.new(3087.4,3.8,44.4),.08,C.Steel)
 box(m,"KeyTransferTray",3081.2,3.72,44,1.6,.15,1.4,C.Bronze,M,false)
 cyl(m,"KeyRing",3081.2,3.85,44,.05,.35,C.Stainless,"Y")
 box(m,"KeyFob",3081.5,3.86,44,.4,.07,.25,C.Charcoal,P,false)
 box(m,"RecordPrinter",3081.5,2.3,45.7,2,1.2,1.1,C.Galvanized,P,false)
 box(m,"PrinterPaper",3081.5,2.3,46.3,1.4,.035,.35,C.WarmWhite,P,false)
 point(m,"SeniorAppraiser",3084,.6,48,"OPERATOR")
 point(m,"SellerHandoffTarget",3084,4.0,40.5,"FX")
 local s=group(l,"Seller_Public_Exchange","STORY","WORKING","Short roadside handoff -> sheltered legible public edge")
 for _,z in ipairs({35,54}) do
  box(s,"WaitingBenchSeat",3086.7,2.3,z,2.8,.3,5,C.Timber,Enum.Material.Wood,true)
  box(s,"WaitingBenchBack",3088,3.2,z,.25,2,5,C.Timber,Enum.Material.Wood,true)
  for _,zz in ipairs({z-1.8,z+1.8}) do box(s,"BenchLeg",3086.6,1.5,zz,2.3,1.3,.25,C.Steel,M,true) end
 end
 point(s,"SellerCounterPosition",3084,.6,40.5,"OPERATOR")
 -- Continuous existing east pedestrian edge is kept open; no freestanding barrier.
 box(s,"CustomerWalkInset",3082.5,.65,43,4,.12,63,C.Concrete,Enum.Material.Concrete,false)
 point(s,"PublicExchangeAmbient",3087,7,48,"FX")
end
local function finish(l)
 local m=group(l,"Receiving_Surface_And_Work_Access","ARCHITECTURE","WORKING","Rough yard -> organized receiving aprons without extra vehicle moves")
 box(m,"ReceivingApron",3040,.57,49,72,.08,72,C.Concrete,Enum.Material.Concrete,false)
 for _,z in ipairs({24,48,73}) do box(m,"SlabControlJoint",3040,.62,z,70,.025,.045,C.OldConcrete,P,false) end
 path(l,"EastPublicEntry",{{3082,16},{3082,38}})
 path(l,"SellerCounterApproach",{{3082,38},{3084,40.5}})
 path(l,"StaffCounterApproach",{{3082,50},{3084,48}})
 path(l,"EastSpecialAccess",{{3082,50},{3082,72}})
 path(l,"WestRecordsAccess",{{3002,74},{3002,85}})
 path(l,"Ordinary1Approach",{{3007,18},{3007,24}})
 path(l,"Ordinary2Approach",{{3056,18},{3056,24}})
 path(l,"SpecialOperatorApproach",{{3056,59},{3052,59},{3052,21},{3056,21},{3056,24}})
 for _,p in l["98_Access_Paths"]:GetChildren() do
  if p.Name:find("Ordinary") or p.Name=="SpecialOperatorApproach" then p:SetAttribute("MovementPolicy","PARKED_CAR_WORK_ONLY_NO_AUTOMATIC_PEDESTRIAN_ROUTE") end
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
 root():SetAttribute("InstitutionFidelityPhase5AIntakeStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["09_Institution_Production_B"]["01_Frontage_Commercial"]["01_Intake_Appraisal"]
  for _,c in ipairs(old:GetChildren()) do if c.Name~="CanopyColumn" then suppress(l,c) end end
  suppress(l,root()["05_Architecture_Massing"]["01_Frontage"].IntakeEnvelope)
  for i=1,3 do suppress(l,root()["04_Capacity_Sockets"]["Intake_"..i]) end
  canopy(l);appraisal(l,1,3019,3007);appraisal(l,2,3044,3056);special(l);records(l);handoff(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase5AIntakeStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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

 check("LargeArrivalApproach",CFrame.new(3027,3.5,-9),Vector3.new(12,7,164.5))
 for i,x in ipairs({3019,3044,3069}) do
  check("IntakeApproach"..i,CFrame.new(x,3.2,5),Vector3.new(10.58,6.4,172.94))
  local minX=math.min(x,3066)-9.47;local maxX=math.max(x,3066)+9.47
  check("IntakeMerge"..i,CFrame.new((minX+maxX)/2,3.2,82),Vector3.new(maxX-minX,6.4,10.58))
 end
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
    if v.X<3000 or v.X>3089 or v.Z<11 or v.Z>91 or v.Y>15.2 then outside=true end
   end end end
   if outside then table.insert(issues,"IntakeFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase5AIntakeStatus","ACCEPTED");return a
end
-- F04: legacy whole-layer rebuilds cannot erase an integrated frontage.
for _,method in {"Install","Uninstall"} do
 local legacy=I[method]
 I[method]=function(...)
  local current=workspace:FindFirstChild("SellCars_Dealership_Growth_V5")
  assert(not(current and current:GetAttribute("Frontage04Activated")),"Frontage04 active: use scoped integration rollback before a legacy rebuild")
  return legacy(...)
 end
end
return I

