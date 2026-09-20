--!nocheck
-- F04-4: six boutique listing lecterns and a prepared handover setting.
-- Native art only. K is Frontage04Kit; sourceRoot is the UNMASKED existing V5.
-- No cars, floors, routes, lights, scripts, live prices or interaction anchors.
-- Existing detailed tray / envelope joinery is copied by exact part datum;
-- the source assets are never moved, hidden, rewritten or deleted here.
return function(K,parent,sourceRoot)
 local C,E,V=K.C,Enum.Material,Vector3.new
 local root=K.model(parent,"04_Sales_And_Handover","SALES_DETAIL")
 root:SetAttribute("Version","2026-09-08.frontage04.f4.sales.3")
 root:SetAttribute("SourceModule","Frontage04Sales")
 root:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
 root:SetAttribute("GroundTopY",.23)
 root:SetAttribute("SaleDisplayCount",6)
 root:SetAttribute("LiveListingBinding",false)
 root:SetAttribute("DataPolicy","STATIC_EXAMPLE_LISTING_AND_BUILD_DATA_NOT_FINAL_DEAL_PRICE")
 root:SetAttribute("CarMigration","SEPARATE_INSTALLER_OWNS_SIX_ACTUAL_IDENTITIES")
 local bronze=Color3.fromRGB(157,122,66)
 local pale=Color3.fromRGB(218,211,190)
 local silver=Color3.fromRGB(165,172,167)
 local leather=Color3.fromRGB(135,83,49)
 local lining=Color3.fromRGB(42,61,67)
 local glass=Color3.fromRGB(166,190,187)
 local floor=.23
 local reused=0
 local function group(parent,name,role)
  local m=K.model(parent,name,role or "SALES_DETAIL")
  m:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
  m:SetAttribute("FidelityBatch","F04_4")
  m:SetAttribute("FunctionId","Sales_Delivery")
  return m
 end
 local function b(m,cf,n,x,y,z,w,h,d,col,mat,solid)
  local p=K.box(m,n,0,0,0,w,h,d,col,mat or E.Metal,solid)
  p.CFrame=cf*CFrame.new(x,y,z);return p
 end
 local function bar(m,cf,n,a,c,diam,col,mat)
  return K.bar(m,n,cf:PointToWorldSpace(a),cf:PointToWorldSpace(c),diam,col,mat or E.Metal,false)
 end
 local function textFace(p,name,text,size,color)
  local gui=Instance.new("SurfaceGui");gui.Name=name
  gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
  gui.PixelsPerStud=100;gui.LightInfluence=.65;gui.AlwaysOnTop=false;gui.Parent=p
  local t=Instance.new("TextLabel");t.Name="StaticInscription"
  t.Position=UDim2.fromScale(.07,.06);t.Size=UDim2.fromScale(.86,.88)
  t.BackgroundTransparency=1;t.TextColor3=color or pale
  t.Font=Enum.Font.GothamMedium;t.TextSize=size or 22
  t.TextWrapped=true;t.TextScaled=false;t.Text=text;t.Parent=gui
  gui:SetAttribute("VisualExampleOnly",true)
  return gui
 end
 local function plaque(m,cf,n,txt,x,y,z,w,h,col)
  local p=b(m,cf,n,x,y,z,w,h,.035,col or C.black,E.Metal,false)
  textFace(p,"Engraving",txt,math.floor(h*100*.54));return p
 end
 local finishes={
  {1,"CHERRY",Color3.fromRGB(216,57,49),"42,500",3107.3,24.0,-math.pi/2,false},
  {2,"VIOLET",Color3.fromRGB(126,88,210),"58,000",3107.3,26.5,-math.pi/2,false},
  {3,"TURQUOISE",Color3.fromRGB(38,205,220),"39,500",3168.9,17,-math.pi/2,false},
  {4,"WARM GOLD",Color3.fromRGB(236,184,55),"64,000",3107.3,65.5,0,true},
  {5,"COBALT",Color3.fromRGB(54,126,202),"71,500",3168.9,33,-math.pi/2,false},
  {6,"JADE",Color3.fromRGB(48,171,149),"56,500",3168.9,48,-math.pi/2,false},
 }
 -- First two west stands share the six-stud inter-car gap. The last west
 -- blade stays strictly Z65.2..65.8 between display4 and handover. East stands
 -- occupy the outer 3168..3170 strip, clear of cars, posts and the east walk.
 for _,s in ipairs(finishes)do
  local id,finish,tint,price,x,z,yaw,slim=table.unpack(s)
  local m=group(root,string.format("Listing_%02d_%s",id,finish:gsub(" ","_")),"LISTING_PLINTH")
  m:SetAttribute("SemanticId","SalesDisplay_"..id)
  m:SetAttribute("StaticExampleListingPrice",price)
  m:SetAttribute("StaticExampleFinish",finish)
  m:SetAttribute("LabelMeaning","LISTING_PRICE_NOT_NEGOTIATED_DEAL_PRICE")
  m:SetAttribute("FinalAssetIntent","BRASS_GLAZED_LECTERN_WITH_CRAFT_FOLIO_AND_FINISH_CHIPS")
  local cf=CFrame.new(x,floor,z)*CFrame.Angles(0,yaw,0)
  local dep=slim and .54 or 1.12
  b(m,cf,"RecessedRubberFoot",0,.035,0,1.89,.07,dep-.1,C.black,E.SmoothPlastic,false)
  b(m,cf,"FoldedSteelBase",0,.105,0,2.06,.07,dep,C.steel,E.Metal,true)
  b(m,cf,"BronzeBaseLip",0,.15,-dep/2+.025,2.03,.035,.05,bronze,E.Metal,false)
  for i,a in ipairs({-.73,.73})do
   bar(m,cf,"CountersunkFixing_"..i,V(a,.146,0),V(a,.156,0),.09,silver)
  end
  b(m,cf,"NarrowBoxSectionStem",0,1.36,0,.23,2.46,.2,C.black,E.Metal,true)
  b(m,cf,"FrontStemInlay",0,1.36,-.111,.085,2.27,.018,bronze,E.Metal,false)
  b(m,cf,"BoardMountingCleat",0,2.45,0,1.18,.16,.20,C.steel,E.Metal,false)
  b(m,cf,"OakDisplayBack",0,3.29,0,2.16,1.68,.16,C.woodDark,E.Wood,false)
  b(m,cf,"RecessedEnamelFace",0,3.29,-.088,2.02,1.54,.032,C.black,E.Metal,false)
  for i,xx in ipairs({-1.065,1.065})do b(m,cf,"BronzeFrameStile_"..i,xx,3.29,-.105,.048,1.72,.065,bronze,E.Metal,false)end
  for i,yy in ipairs({2.455,4.125})do b(m,cf,"BronzeFrameRail_"..i,0,yy,-.105,2.17,.048,.065,bronze,E.Metal,false)end
  local card=b(m,cf,"StaticBuildCard",0,3.36,-.113,1.85,1.23,.012,pale,E.SmoothPlastic,false)
  local cover=b(m,cf,"GlazedCardProtection",0,3.36,-.132,1.91,1.30,.016,glass,E.Glass,false)
  cover.Transparency=.83;cover.Reflectance=.035
  -- Keep print on the outer glazing face: a SurfaceGui behind glass was
  -- intermittently absent at close customer distance despite being Enabled.
  textFace(cover,"ExampleListing",string.format("BUILD %02d\nLISTING $%s\n%s\nCONCEPT / NOT LIVE",id,price,finish),18,C.black)
  b(m,cf,"FinishChipMount",-.52,2.70,-.134,.52,.18,.045,bronze,E.Metal,false)
  b(m,cf,"PaintFinishChip",-.52,2.70,-.160,.46,.125,.024,tint,E.SmoothPlastic,false)
  b(m,cf,"BrushedTrimChip",.12,2.70,-.155,.39,.125,.025,silver,E.Metal,false)
  b(m,cf,"SaddleTrimChip",.65,2.70,-.155,.36,.125,.025,leather,E.Fabric,false)
  if not slim then
   -- Real-depth lower document pocket: the folio and clasp are visibly nested,
   -- rather than three anonymous blocks taped onto the pole.
   b(m,cf,"FolioPocketBack",0,1.80,.14,1.40,.99,.065,C.wood,E.Wood,false)
   b(m,cf,"FolioPocketBase",0,1.36,.24,1.43,.065,.27,C.woodDark,E.Wood,false)
   for i,xx in ipairs({-.675,.675})do b(m,cf,"PocketSide_"..i,xx,1.69,.24,.075,.60,.27,C.woodDark,E.Wood,false)end
   b(m,cf,"BuildRecordLeatherFolio",0,1.86,.255,1.12,.78,.10,lining,E.Fabric,false)
   b(m,cf,"BoundRecordPages",.06,1.87,.315,.94,.65,.03,pale,E.SmoothPlastic,false)
   b(m,cf,"FolioSpine",-.54,1.86,.313,.07,.79,.045,leather,E.Fabric,false)
   b(m,cf,"DocumentRetainer",0,1.52,.365,1.40,.13,.055,bronze,E.Metal,false)
   b(m,cf,"FolioCornerPlate",.39,2.13,.34,.18,.12,.015,bronze,E.Metal,false)
  else
   -- The one-stud gap cannot carry a deep tilted menu pedestal or a storage
   -- shelf. A double-sided thin gallery blade is the intentional variation.
   local reverse=b(m,cf,"ReverseBuildNumber",0,3.29,.098,1.82,1.23,.012,C.black,E.Metal,false)
   reverse.CFrame=reverse.CFrame*CFrame.Angles(0,math.pi,0)
   textFace(reverse,"DoubleSidedLabel","BUILD 04\nCRAFT RECORD\nAT CUSTOMER LOUNGE",22,pale)
  end
 end

 -- Handover is deliberately outside the empty car rectangle and under the
 -- gallery's rear edge, not another sale position or a second consultation.
 -- The first placement clipped the intake release's turning body. This
 -- forward/right location clears that sweep without moving a display or walk.
 local h=group(root,"Handover_Console_And_Key_Ceremony","HANDOVER_EQUIPMENT")
 h:SetAttribute("OperatingPosition","SalesReveal")
 h:SetAttribute("PermanentCarOccupancy",false)
 h:SetAttribute("ReservedDetailBounds","X3099.9..3109.1 / Z80.15..82.05")
 local hc=CFrame.new(3104.5,floor,81.1)
 b(h,hc,"DarkRecessedToeKick",0,.15,.12,8.60,.30,1.35,C.black,E.Metal,true)
 b(h,hc,"ShallowOakConsole",0,1.63,.08,8.9,2.84,1.60,C.woodDark,E.Wood,true)
 b(h,hc,"HonedLimestoneCounter",0,3.15,0,9.2,.23,1.90,pale,E.Limestone,true)
 b(h,hc,"BronzeCounterReveal",0,3.005,-.83,8.92,.048,.055,bronze,E.Metal,false)
 for i,x in ipairs({-3.33,-1.11,1.11,3.33})do
  b(h,hc,"TimberCupboardPanel_"..i,x,1.69,-.744,2.11,2.50,.084,C.wood,E.Wood,false)
  for j,dx in ipairs({-.99,.99})do b(h,hc,"FittedPanelStile_"..i.."_"..j,x+dx,1.69,-.794,.08,2.39,.03,C.woodDark,E.Wood,false)end
  for j,y in ipairs({.54,2.84})do b(h,hc,"FittedPanelRail_"..i.."_"..j,x,y,-.794,2.03,.08,.03,C.woodDark,E.Wood,false)end
  b(h,hc,"RecessedBronzePull_"..i,x,2.65,-.82,.78,.055,.07,bronze,E.Metal,false)
 end
 plaque(h,hc,"DeliveryInscription","YOUR NEXT CHAPTER",0,2.05,-.844,4.15,.34)
 b(h,hc,"LeatherDocumentMat",1.94,3.28,-.02,2.55,.025,1.39,leather,E.Fabric,false)
 for i=1,3 do b(h,hc,"BoundHandoverPages_"..i,2.12,3.304+i*.019,-.03,1.55,.016,1.11,pale,E.SmoothPlastic,false)end
 b(h,hc,"FoldedBuildPassportSpine",1.28,3.36,-.03,.13,.13,1.18,lining,E.Fabric,false)
 b(h,hc,"BuildPassportBrassSeal",2.5,3.375,.25,.26,.024,.26,bronze,E.Metal,false)
 bar(h,hc,"DeliverySigningPen",V(3.52,3.31,-.43),V(3.52,3.31,.36),.06,C.black)
 b(h,hc,"SmallPenRest",3.52,3.293,-.02,.29,.04,.94,bronze,E.Metal,false)

 -- Exact useful old subassembly is retained. Reading a live masked source is
 -- intentionally not supported; caller must EndPreview before copying.
 local fidelity=assert(sourceRoot and sourceRoot:FindFirstChild("10_Institution_Fidelity_R1"),"Unmasked source fidelity root required")
 local oldSales=assert(fidelity:FindFirstChild("04_Frontage_And_Owner"),"Source frontage missing")
 oldSales=assert(oldSales:FindFirstChild("02_Sales"),"Source detailed Sales missing")
 local desk=assert(oldSales:FindFirstChild("Deal_And_Listing_Exchange"),"Source deal desk missing")
 local datum=assert(desk:FindFirstChild("KeyPresentationTray"),"Source key tray datum missing")
 assert(datum.Transparency<.99,"End visual preview before copying the handover tray")
 local oldElevation=assert(fidelity:FindFirstChild("07_Elevation_01"),"Source elevation layer missing")
 local oldTray=nil
 for _,p in ipairs(oldElevation:GetChildren())do
  if p:IsA("Model") and p:FindFirstChild("Lined_Handover_Tray")then oldTray=p.Lined_Handover_Tray;break end
 end
 assert(oldTray,"Retained detailed key-tray joinery missing")
 local tray=group(h,"Retained_Lined_Key_Presentation","REUSED_HANDOVER_DETAIL")
 tray:SetAttribute("OriginalDatumPath",datum:GetFullName())
 local target=hc:PointToWorldSpace(V(-2.76,3.35,-.05))
 local delta=target-datum.Position
 local function copyPart(p)
  assert(not p:GetAttribute("AnchorKind"),"Cannot reuse an anchor as art")
  local q=p:Clone()
  for _,d in ipairs(q:GetDescendants())do
   if not d:IsA("SurfaceGui") and not d:IsA("GuiObject") then d:Destroy()end
  end
  q:SetAttribute("OriginalPath",p:GetFullName())
  q:SetAttribute("F04RetainedDetail",true)
  q:SetAttribute("InteractionAnchor",nil);q:SetAttribute("FXSocket",nil)
  q.Anchored=true;q.CanTouch=false;q.CanCollide=false
  q.CFrame=p.CFrame+delta;q.Parent=tray;reused+=1
 end
 for _,p in ipairs(desk:GetChildren())do
  if p:IsA("BasePart") and(p.Name=="KeyPresentationTray" or p.Name=="KeyEnvelope")then copyPart(p)end
 end
 for _,p in ipairs(oldTray:GetChildren())do
  if p:IsA("BasePart")then copyPart(p)end
 end
 -- New recognizable key, stitched sleeve and split ring complete the old
 -- envelopes. Preserve the inherited lining's original fitted relationships.
 b(h,hc,"KeyFobLeatherSleeve",-2.61,3.535,-.14,.36,.11,.43,leather,E.Fabric,false)
 b(h,hc,"KeyFobInset",-2.61,3.60,-.14,.25,.025,.30,C.black,E.SmoothPlastic,false)
 b(h,hc,"KeyBlade",-2.23,3.556,-.15,.46,.045,.105,silver,E.Metal,false)
 for i=1,3 do b(h,hc,"KeyNotch_"..i,-2.06-i*.075,3.583,-.115,.04,.016,.04,C.black,E.Metal,false)end
 for i=1,12 do
  local a,c=(i-1)*math.pi/6,i*math.pi/6
  bar(h,hc,"SplitKeyRing_"..i,V(-2.87+math.cos(a)*.17,3.567,-.14+math.sin(a)*.17),V(-2.87+math.cos(c)*.17,3.567,-.14+math.sin(c)*.17),.034,silver)
 end

 -- A compact valet rack stores the reveal cloth rather than draping it over
 -- a seventh car or placing tall curtain posts inside the operating envelope.
 local rack=group(root,"Stowed_Reveal_Cover_And_Valet_Kit","STOWED_EQUIPMENT")
 rack:SetAttribute("ParkedState","COVER_ROLLED_AND_FOLDED_NOT_DEPLOYED")
 -- Staged on the east service edge, reached from the east customer walk;
 -- keeps the handover joinery and the rear intake release uncongested.
 rack:SetAttribute("ReservedDetailBounds","X3168.2..3169.9 / Z72.65..75.35")
 local rc=CFrame.new(3169.05,floor,74)*CFrame.Angles(0,math.pi/2,0)
 for i,x in ipairs({-1.13,1.13})do
  b(rack,rc,"GroundedSteelFoot_"..i,x,.09,0,.38,.18,1.70,C.black,E.Metal,true)
  bar(rack,rc,"SlimValetUpright_"..i,V(x,.18,0),V(x,4.8,0),.15,C.steel)
 end
 bar(rack,rc,"TopHangerRail",V(-1.13,4.8,0),V(1.13,4.8,0),.14,bronze)
 b(rack,rc,"FoldedCoverShelf",0,.74,.10,2.7,.12,1.48,C.woodDark,E.Wood,true)
 for i=1,5 do
  b(rack,rc,"LayeredFoldedCover_"..i,0,.88+(i-1)*.14,.11,2.31-(i%2)*.09,.14,1.13,lining:Lerp(pale,i*.025),E.Fabric,false)
  b(rack,rc,"FoldedClothFrontHem_"..i,0,.84+i*.14,-.46,2.17,.025,.05,Color3.fromRGB(135,145,141),E.Fabric,false)
 end
 for i,x in ipairs({-.67,.67})do
  bar(rack,rc,"RolledSoftCover_"..i,V(x,2.0,.07),V(x,4.03,.07),.69,i==1 and pale or lining,E.Fabric)
  for j,yy in ipairs({2.24,3.71})do
   bar(rack,rc,"LeatherRetainingStrap_"..i.."_"..j,V(x,yy-.04,.07),V(x,yy+.04,.07),.73,leather,E.Fabric)
   b(rack,rc,"BrassStrapBuckle_"..i.."_"..j,x,yy,-.316,.19,.11,.04,bronze,E.Metal,false)
  end
  -- Two shoulder arms and a hooked top make each stored roll visibly hang.
  bar(rack,rc,"ClothHangerShoulderA_"..i,V(x-.36,4.12,.07),V(x,4.36,.07),.055,silver)
  bar(rack,rc,"ClothHangerShoulderB_"..i,V(x,4.36,.07),V(x+.36,4.12,.07),.055,silver)
  bar(rack,rc,"HangerHookStem_"..i,V(x,4.36,.07),V(x,4.80,.07),.055,silver)
  bar(rack,rc,"HangerHookTop_"..i,V(x,4.80,.07),V(x+.13,4.87,.07),.055,silver)
  bar(rack,rc,"HangerHookReturn_"..i,V(x+.13,4.87,.07),V(x+.19,4.77,.07),.055,silver)
 end
 plaque(rack,rc,"ValetLabel","REVEAL / STOWED",0,.63,-.662,2.18,.23)
 root:SetAttribute("RetainedBasePartCount",reused)
 root:SetAttribute("FinalScope","SIX_STATIC_LISTINGS_HANDOVER_JOINERY_AND_STOWED_COVER_NO_CAPACITY_CHANGE")
 return root
end

