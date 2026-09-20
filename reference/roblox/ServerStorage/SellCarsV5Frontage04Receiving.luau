--!nocheck
-- F04-3: compact, richly equipped receiving. Geometry-only candidate copies.
-- Original assets stay untouched. F04-5 must reconcile lights/actors/anchors.
-- K is Frontage04Kit; sourceRoot must be the UNMASKED existing V5 root.
return function(K, parent, sourceRoot)
 local E, V, C = Enum.Material, Vector3.new, K.C
 local root=K.model(parent,"04_Receiving_Fitout","RECEIVING_DETAIL")
 root:SetAttribute("Version","2026-09-08.frontage04.f3.receiving.1")
 root:SetAttribute("PreviewOnly",true)
 root:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
 root:SetAttribute("OperatingCapacity",3)
 root:SetAttribute("SpecialCapacity","ONE_RARE_OR_TOW_POSITION")
 root:SetAttribute("ReferenceMigration","PENDING_F04_5")
 root:SetAttribute("GroundTopY",.23)
 local intake=assert(sourceRoot:FindFirstChild("10_Institution_Fidelity_R1"),"Fidelity root missing")
 intake=assert(intake:FindFirstChild("04_Frontage_And_Owner"),"Frontage fidelity missing")
 intake=assert(intake:FindFirstChild("01_Intake"),"Existing detailed Intake missing")
 local bronze=Color3.fromRGB(160,123,65)
 local rubber=Color3.fromRGB(35,38,36)
 local slate=Color3.fromRGB(71,99,103)
 local cream=Color3.fromRGB(223,216,191)
 local amber=Color3.fromRGB(217,157,63)
 local steel=Color3.fromRGB(154,163,158)
 local reused, disabledLights=0,0
 local function group(p,n,role)
  local m=K.model(p,n,role or "EQUIPMENT")
  m:SetAttribute("PreviewOnly",true)
  m:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
  m:SetAttribute("FunctionId","Intake_Appraisal")
  return m
 end
 local function b(m,n,x,y,z,w,h,d,col,mat,solid)
  return K.box(m,n,x,y,z,w,h,d,col or C.steel,mat or E.Metal,solid)
 end
 local function plaque(m,n,txt,x,y,z,w,h)
  local p=b(m,n,x,y,z,w,h,.08,C.black,E.Metal,false)
  local gui=Instance.new("SurfaceGui");gui.Name="StaticLettering"
  gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
  gui.PixelsPerStud=48;gui.LightInfluence=.7;gui.AlwaysOnTop=false;gui.Parent=p
  local t=Instance.new("TextLabel");t.Name="Inscription";t.Size=UDim2.fromScale(.94,.86)
  t.Position=UDim2.fromScale(.03,.07);t.BackgroundTransparency=1
  t.Font=Enum.Font.GothamMedium;t.Text=txt;t.TextColor3=C.paper
  t.TextScaled=true;t.Parent=gui;return p
 end
 local function names(list)
  local out={};for _,n in ipairs(list)do out[n]=true end;return out
 end
 local function source(n) return assert(intake:FindFirstChild(n),"Reusable Intake assembly missing: "..n) end
 -- Clone only explicitly selected direct geometry children. No historical
 -- masks, complete departments, old rooms/floors, scripts, actors or anchors.
 local function copyParts(p,n,old,allowed)
  local m=group(p,n,"REUSED_EQUIPMENT")
  m:SetAttribute("OriginalPath",old:GetFullName())
  local occurrences={}
  for _,part in ipairs(old:GetChildren())do
   if part:IsA("BasePart") and allowed[part.Name] then
    assert(not part:GetAttribute("AnchorKind"),"Anchor selected: "..part.Name)
    occurrences[part.Name]=(occurrences[part.Name] or 0)+1
    local q=part:Clone()
    for _,d in ipairs(q:GetDescendants())do
     if d:IsA("LuaSourceContainer") or d:IsA("ValueBase") or d:IsA("Attachment")
      or d:IsA("Constraint") or d:IsA("JointInstance") or d:IsA("TouchTransmitter")
      or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then d:Destroy()
     elseif d:IsA("Light") then
      d:SetAttribute("OriginalEnabled",d.Enabled);d.Enabled=false
      d:SetAttribute("OriginalPath",part:GetFullName().."/"..d.Name)
      d:SetAttribute("ReferenceMigration","PENDING_F04_5");disabledLights+=1
     elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then d.Enabled=false
     elseif d:IsA("Sound") then d:Destroy() end
    end
    q:SetAttribute("PreviewOnly",true);q:SetAttribute("OriginalPath",part:GetFullName())
    q:SetAttribute("OriginalNameOrdinal",occurrences[part.Name])
    q:SetAttribute("InteractionAnchor",nil);q:SetAttribute("FXSocket",nil)
    q.Anchored=true;q.CanTouch=false;q.Parent=m;reused+=1
   end
  end
  assert(#m:GetChildren()>0,"No reusable geometry selected for "..n)
  return m
 end
 local function shift(m,delta)
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart") then p.CFrame=p.CFrame+delta end end
 end
 -- Place by a real named asset datum and measured bottom, never by old Model
 -- pivot assumptions. All original local relationships and asset scales survive.
 local function place(m,datumName,x,z,bottomY)
  local datum=assert(m:FindFirstChild(datumName),"Asset datum missing: "..datumName)
  local cf,sz=m:GetBoundingBox()
  shift(m,V(x-datum.Position.X,bottomY-(cf.Position.Y-sz.Y/2),z-datum.Position.Z))
 end
 local cartNames=names({"LippedTrolleyTray","CartUpright","SwivelCaster","CartHandle",
  "TabletStand","ConditionTablet_Frame","ConditionTablet_Display","ConditionCategoryRow",
  "ConditionStateRow","DocumentClipTray","RecordCameraCase","CaseLatch"})
 for index,spec in ipairs({{3023.5,3033},{3042.5,3052}})do
  local m=group(root,"Ordinary_Receiving_"..index,"HERO_EQUIPMENT")
  m:SetAttribute("CapacitySocket","Intake_"..index)
  m:SetAttribute("CarReserve",string.format("X%.1f..%.1f / Z52.5..75.5",spec[2]-7,spec[2]+7))
  m:SetAttribute("DataContract","TRANSPARENT_CONDITION_AND_ASKING_PRICE_NOT_INSPECTION_REVEAL")
  local old=source("Ordinary_Condition_Station_"..index)
  local cart=copyParts(m,"Retained_Condition_Cart",old,cartNames)
  place(cart,"TabletStand",spec[1],56.5,.23)
  cart:SetAttribute("ReservedDetailBounds",string.format("X%.2f..%.2f / Z55..58",spec[1]-1.55,spec[1]+1.55))
  -- Two optical fixtures and one arrival-record camera read as real car-side
  -- equipment without turning the transparent intake into an inspection step.
  local rig=copyParts(m,"Retained_Optical_Equipment",old,names({"ShieldedConditionLight",
   "ConditionDiffuser","RecordCameraBracket","VehicleRecordCamera","CameraOptic"}))
  local fixtures={};local diffusers={}
  for _,p in ipairs(rig:GetChildren())do
   if p.Name=="ShieldedConditionLight"then table.insert(fixtures,p)
   elseif p.Name=="ConditionDiffuser"then table.insert(diffusers,p)end
  end
  assert(#fixtures==2 and #diffusers==2,"Expected two condition fixtures per ordinary station")
  table.sort(fixtures,function(a,b)return a.Position.X<b.Position.X end)
  table.sort(diffusers,function(a,b)return a.Position.X<b.Position.X end)
  for i,fixture in ipairs(fixtures)do
   local dx=i==1 and -5.35 or 5.35
   local delta=V(spec[2]+dx,14.0,64)-fixture.Position
   fixture.CFrame=fixture.CFrame+delta;diffusers[i].CFrame=diffusers[i].CFrame+delta
   K.bar(rig,"FixturePendant_"..i,V(spec[2]+dx,14.3,64),V(spec[2]+dx,20.19,64),.12,C.steel,E.Metal,false)
   b(rig,"FixtureCeilingMount_"..i,spec[2]+dx,20.20,64,.4,.14,.55,C.black,E.Metal,false)
  end
  local camera=assert(rig:FindFirstChild("VehicleRecordCamera"))
  local delta=V(spec[2],13.9,64)-camera.Position
  for _,name in ipairs({"RecordCameraBracket","VehicleRecordCamera","CameraOptic"})do
   local p=rig:FindFirstChild(name);p.CFrame=p.CFrame+delta
  end
  K.bar(rig,"CameraPendant",V(spec[2],14.65,64),V(spec[2],20.19,64),.12,C.steel,E.Metal,false)
  b(rig,"CameraCeilingMount",spec[2],20.20,64,.4,.14,.55,C.black,E.Metal,false)
  rig:SetAttribute("MinimumVisualHeight",13.3)
  rig:SetAttribute("LightPolicy","COPIED_DISABLED_UNTIL_F04_5")
  -- Small use-worn objects are grounded on the retained cart, not floating
  -- generic cubes. These are static proxy indicators, not invented gameplay.
  local top=-math.huge
  for _,p in ipairs(cart:GetChildren())do if p.Name=="LippedTrolleyTray"then top=math.max(top,p.Position.Y+p.Size.Y/2)end end
  local details=group(m,"Acquisition_Work_Details","STORY_DETAIL")
  b(details,"PaintDepthMeterCase",spec[1]+.66,top+.22,57.02,.66,.43,.76,C.navy,E.SmoothPlastic,false)
  b(details,"MeterRecess",spec[1]+.66,top+.45,57.02,.39,.035,.43,C.black,E.SmoothPlastic,false)
  b(details,"PocketMeterScreen",spec[1]+.66,top+.477,56.94,.22,.018,.19,slate,E.Glass,false)
  b(details,"DocumentClip",spec[1]-.55,top+.13,55.65,.18,.05,.3,steel,E.Metal,false)
  b(details,"KeyIntakeSleeve",spec[1]-.63,top+.17,57.1,.5,.05,.85,cream,E.SmoothPlastic,false)
  b(details,"BrassTag",spec[1]-.63,top+.203,57.1,.27,.018,.37,bronze,E.Metal,false)
  plaque(details,"CartNumber","RECEIVING 0"..index,spec[1],1.83,54.99,2.2,.4)
 end

 -- Recovery hardware stays BETWEEN the special and first ordinary car, not
 -- in the protected truck approach. Existing bench is 4.8 wide in a 5-wide strip.
 do
  local old=source("Special_Receiving_And_Recovery_Kit")
  local m=group(root,"Special_Receiving_Recovery","HERO_EQUIPMENT")
  m:SetAttribute("CapacitySocket","Intake_3")
  m:SetAttribute("ParkedState","RAMPS_SKATES_AND_STRAPS_STOWED")
  local bench=copyParts(m,"Retained_Recovery_Bench",old,names({"RecoveryEquipmentBench",
   "RecoveryBenchFrame","RecoveryBenchLeg","WheelSkateCradle","SkateRoller",
   "SkateAdjustingScrew","SkateScrewHandle","StowedLowClearanceRamp","RampTread",
   "StrapAndSoftSlingRack","SlingHook","FoldedSoftSling","RatchetBuckle"}))
  place(bench,"RecoveryEquipmentBench",3023.5,65.5,.23)
  bench:SetAttribute("ReservedDetailBounds","X3021.1..3025.9 / Z60.5..70.65")
  plaque(m,"RecoveryIdentification","RECOVERY KIT",3023.5,8.08,70.21,3.4,.54)
  local locker=copyParts(m,"Retained_Spill_Locker",old,names({"RecoverySpillLocker","SpillLockerHandle"}))
  place(locker,"RecoverySpillLocker",3063.4,70.5,.23)
  local bottle=copyParts(m,"Retained_Fire_Equipment",old,names({"FireBottleMount","BottleFoot",
   "FireBottle","BottleNeck","BottleHandle","PressureGauge","ParkedBottleHose"}))
  place(bottle,"BottleFoot",3066.2,71.25,.23)
  b(m,"RecoveryLockerBrassLabel",3063.4,1.05,68.53,1.35,.24,.07,bronze,E.Metal,false)
  -- Dedicated wheel-chock nest, visibly stowed rather than placed in car paths.
  local nest=group(m,"Stowed_Chock_And_Tow_Eyes","SUPPORT_EQUIPMENT")
  b(nest,"FoldedSteelBin",3063.1,.57,63.8,3.2,.68,2.8,C.black,E.Metal,true)
  b(nest,"BinLippedTray",3063.1,.94,63.8,3.35,.12,2.95,steel,E.Metal,false)
  for i=1,3 do
   local x=3062.03+(i-1)*1.06
   local p=b(nest,"RubberWheelChock_"..i,x,1.3,63.7,.75,.6,1.75,rubber,E.SmoothPlastic,false)
   for j=1,3 do b(nest,"ChockTread_"..i.."_"..j,x,1.615,63.08+j*.31,.73,.04,.075,C.steel,E.Metal,false)end
   K.bar(nest,"PullLoop_"..i,V(x-.16,1.03,64.79),V(x+.16,1.03,64.79),.075,steel,E.Metal,false)
  end
  plaque(nest,"StowLabel","TOW / STOWED",3063.1,.62,62.36,2.1,.3)
 end

 -- Shared acquisition work is one equipment edge, not an extra department or
 -- another lobby. The staff walk X3077..3085 and terrace Z44..52 remain empty.
 do
  local m=group(root,"Shared_Valuation_And_Records","SUPPORT_EQUIPMENT")
  m:SetAttribute("ReservedDetailBounds","X3060..3076 / Z53..74")
  m:SetAttribute("DataContract","ASKING_AND_ACQUISITION_PRICE_SEPARATE_FROM_SALE")
  local old=source("Shared_Valuation_And_Seller_Handoff")
  local desk=copyParts(m,"Retained_Valuation_Desk",old,names({"HandoffWorktop","CounterPlinth",
   "CounterTimberSlat","DualDisplayPost","NegotiationDisplay_Frame","NegotiationDisplay_Display",
   "SellerFacingDisplay","OfferComparisonField","DocumentSigningMat","TitleTransferSheet",
   "CounterPen","KeyTransferTray","KeyRing","KeyFob","RecordPrinter","PrinterPaper"}))
  place(desk,"HandoffWorktop",3066,55.8,.23)
  desk:SetAttribute("ReferenceMigration","SENIOR_APPRAISER_AND_SELLER_ANCHORS_PENDING_F04_5")
  plaque(m,"ValuationDeskIdentity","ACQUISITIONS",3066,1.75,54.36,4.6,.46)
  local records=copyParts(m,"Retained_Key_And_Provenance_Records",source("Provenance_And_Key_Records"),
   names({"RecordsCounter","RecordsCounterLeg","KeysCabinet","KeyHook","KeyTag",
    "TitleFolder","RecordsKeyboard","SecureDropSlot"}))
  place(records,"RecordsCounter",3073.7,69.3,.23)
  local detail=group(m,"Records_And_Acquisition_Specialism","STORY_DETAIL")
  b(detail,"DocumentArchiveCabinet",3073.55,1.67,63.3,4.0,2.88,3.1,C.navy,E.Metal,true)
  b(detail,"ArchiveTimberTop",3073.55,3.19,63.3,4.15,.16,3.25,C.wood,E.Wood,false)
  for i=0,2 do
   b(detail,"ArchiveDrawer_"..i,3073.55,.77+i*.88,61.71,3.77,.79,.07,C.steel,E.Metal,false)
   b(detail,"DrawerPull_"..i,3073.55,.87+i*.88,61.59,.9,.09,.12,bronze,E.Metal,false)
   b(detail,"DocumentIndex_"..i,3074.66,.71+i*.88,61.64,.7,.18,.025,cream,E.SmoothPlastic,false)
  end
  for i=0,2 do
   b(detail,"ProvenanceBinder_"..i,3072.35+i*.36,3.72,63.58,.28,.92,1.4,i==1 and C.woodDark or C.navy,E.Fabric,false)
   b(detail,"BinderSpineTitle_"..i,3072.35+i*.36,3.86,62.865,.16,.27,.022,cream,E.SmoothPlastic,false)
  end
  b(detail,"DocumentScannerBody",3074.15,3.42,63.25,1.35,.32,1.5,steel,E.SmoothPlastic,false)
  b(detail,"ScannerGlass",3074.15,3.593,63.25,1.06,.025,1.13,slate,E.Glass,false)
  b(detail,"ScannerFeedSlot",3074.15,3.62,63.86,1.03,.04,.1,C.black,E.SmoothPlastic,false)
  local recordLabel=plaque(detail,"RecordsIdentity","KEYS / HISTORY",3074.84,7.23,69.3,4.6,.48)
  recordLabel.CFrame=recordLabel.CFrame*CFrame.Angles(0,math.pi/2,0)
  -- A small wall-free literature stand completes the second car-side station.
  local stand=group(m,"Receiving_Reference_Stand","SUPPORT_EQUIPMENT")
  b(stand,"WeightedStandFoot",3042.5,.31,67,2.4,.16,2.6,C.black,E.Metal,true)
  b(stand,"FormedPedestal",3042.5,2.37,67,.22,3.96,.28,C.steel,E.Metal,false)
  local tray=b(stand,"AngledReferenceTray",3042.5,4.32,66.85,2.9,.12,2.0,C.wood,E.Wood,false)
  tray.CFrame=tray.CFrame*CFrame.Angles(math.rad(-12),0,0)
  for i=0,2 do
   local p=b(stand,"ConditionGuide_"..i,3041.62+i*.88,4.43,66.79,.73,.07,1.55,i==0 and cream or C.navy,E.SmoothPlastic,false)
   p.CFrame=p.CFrame*CFrame.Angles(math.rad(-12),0,0)
  end
  plaque(stand,"CarSideGuide","ARRIVAL RECORD",3042.5,3.26,66.76,2.2,.37)
 end
 root:SetAttribute("ReusedGeometryParts",reused)
 root:SetAttribute("ClonedDisabledLights",disabledLights)
 root:SetAttribute("NewActiveLights",0)
 root:SetAttribute("LiveInteractionAnchors",0)
 root:SetAttribute("PlacementPolicy","MEASURED_ASSET_BOTTOM_AT_Y_0_23")
 root:SetAttribute("ExcludedGeometry","FLOORS_ROOFS_OLD_PORTALS_90_RESTORATION_98_ACCESS_PATHS")
 return root
end

