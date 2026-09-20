--!nocheck
-- F04-3: shared customer hospitality inside the accepted 24 x 35 room.
-- Source-only, native geometry. No imported assets, lights, controllers or Seats.
-- +Z leads toward receiving. Floor top .23; the central aisle and three doors
-- remain clear. This is a furnished candidate, not an occupation implementation.
return function(K,parent)
 local C,E,V=K.C,Enum.Material,Vector3.new
 local root=K.model(parent,"03_Shared_Hospitality","F04_3")
 root:SetAttribute("AssetStatus","SOURCE_BUILT_FURNISHING_CANDIDATE")
 root:SetAttribute("SourceModule","Frontage04Hospitality")
 root:SetAttribute("Version","2026-09-08.frontage04.f3.1")
 root:SetAttribute("GroundTopY",.23)
 root:SetAttribute("EnlargedCustomerRoom",false)
 root:SetAttribute("CentralAisleXMin",3070.3)
 root:SetAttribute("CentralAisleXMax",3075.3)
 root:SetAttribute("ClearEastConnectionZMin",34)
 local floor=.23
 local bronze=Color3.fromRGB(157,122,66)
 local chalk=Color3.fromRGB(221,211,185)
 local leather=Color3.fromRGB(139,81,47)
 local stitch=Color3.fromRGB(192,145,94)
 local cream=Color3.fromRGB(213,201,176)
 local silver=Color3.fromRGB(157,166,163)
 local screen=Color3.fromRGB(75,105,106)
 local function group(name,role,x,z,yaw)
  local m=K.model(root,name,role or "F04_3")
  m:SetAttribute("FidelityBatch","F04_3")
  m:SetAttribute("AssetStatus","SOURCE_BUILT_FURNISHING_CANDIDATE")
  return m,CFrame.new(x,floor,z)*CFrame.Angles(0,yaw or 0,0)
 end
 local function box(m,cf,n,x,y,z,w,h,d,col,mat,solid)
  local p=K.box(m,n,0,0,0,w,h,d,col,mat,solid)
  p.CFrame=cf*CFrame.new(x,y,z);return p
 end
 local function bar(m,cf,n,a,b,r,col,mat)
  return K.bar(m,n,cf:PointToWorldSpace(a),cf:PointToWorldSpace(b),r,col,mat or E.Metal,false)
 end
 local function plaque(m,cf,n,text,x,y,z,w,h)
  local p=box(m,cf,n,x,y,z,w,h,.07,C.black,E.Metal,false)
  local gui=Instance.new("SurfaceGui");gui.Name="EngravedText";gui.Face=Enum.NormalId.Front
  gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=70
  gui.AlwaysOnTop=false;gui.LightInfluence=.75;gui.Parent=p
  local label=Instance.new("TextLabel");label.Name="Lettering";label.Size=UDim2.fromScale(.94,.8)
  label.Position=UDim2.fromScale(.03,.1);label.BackgroundTransparency=1
  label.Text=text;label.TextColor3=chalk;label.Font=Enum.Font.GothamMedium
  label.TextScaled=true;label.TextWrapped=false;label.Parent=gui
 end
 local function mug(m,cf,n,x,y,z)
  local g=K.model(m,n,"HOSPITALITY_DETAIL")
  bar(g,cf,"PorcelainCup",V(x,y,z),V(x,y+.48,z),.42,cream,E.SmoothPlastic)
  bar(g,cf,"OpenDarkCoffee",V(x,y+.481,z),V(x,y+.488,z),.33,C.woodDark,E.SmoothPlastic)
  bar(g,cf,"HandleTop",V(x+.19,y+.37,z),V(x+.4,y+.34,z),.075,cream,E.SmoothPlastic)
  bar(g,cf,"HandleOutside",V(x+.4,y+.34,z),V(x+.4,y+.14,z),.075,cream,E.SmoothPlastic)
  bar(g,cf,"HandleBottom",V(x+.4,y+.14,z),V(x+.2,y+.11,z),.075,cream,E.SmoothPlastic)
 end
 local function chair(m,cf,n,x,z,yaw,color)
  local g=K.model(m,n,"LOOSE_FURNITURE")
  local q=cf*CFrame.new(x,0,z)*CFrame.Angles(0,yaw or 0,0)
  box(g,q,"UnderSeatFrame",0,1.75,0,2.25,.22,2.3,C.woodDark,E.Wood,true)
  box(g,q,"UpholsteredCushion",0,2.02,-.03,2.22,.42,2.2,color or leather,E.Fabric,true)
  box(g,q,"UpholsteredBack",0,3.01,.99,2.22,1.86,.3,color or leather,E.Fabric,true)
  box(g,q,"BackTopWelting",0,3.97,.99,2.2,.045,.33,stitch,E.Fabric,false)
  for i,s in ipairs({-1,1})do
   box(g,q,"SewnCushionEdge_"..i,s*1.05,2.246,-.03,.028,.024,2.07,stitch,E.Fabric,false)
   box(g,q,"TimberArm_"..i,s*1.21,2.83,-.06,.2,.22,2.42,C.wood,E.Wood,true)
   box(g,q,"ArmPost_"..i,s*1.2,2.32,-.95,.13,.9,.13,C.steel,E.Metal,false)
   for j,d in ipairs({-.89,.87})do
    box(g,q,"Leg_"..i.."_"..j,s*.96,.87,d,.16,1.72,.16,C.black,E.Metal,true)
    box(g,q,"FloorGlide_"..i.."_"..j,s*.96,.055,d,.24,.11,.24,C.black,E.SmoothPlastic,false)
   end
  end
  return g
 end
 local function tablet(m,cf,n,x,y,z)
  box(m,cf,n.."_Foot",x,y+.035,z,.76,.07,.57,C.black,E.Metal,false)
  box(m,cf,n.."_Stand",x,y+.42,z,.13,.72,.13,bronze,E.Metal,false)
  box(m,cf,n.."_Bezel",x,y+.91,z,1.26,.81,.1,C.black,E.Metal,false)
  box(m,cf,n.."_Display",x,y+.91,z-.057,1.10,.64,.012,screen,E.SmoothPlastic,false)
  for i=1,3 do box(m,cf,n.."_DataLine_"..i,x-.16,y+.99-i*.12,z-.065,.6,.027,.012,cream,E.SmoothPlastic,false)end
 end

 -- Welcome is visibly separate from the two deal settings. The shallow desk
 -- sits west of the front door, not in its sightline or eight-stud opening.
 do
  local m,cf=group("01_Welcome_Concierge","WELCOME",3065.2,13.2)
  m:SetAttribute("StaffStandingPosition",V(3065.2,floor,16.05))
  box(m,cf,"RecessedDarkPlinth",0,.23,0,6.2,.46,2.25,C.black,E.Metal,true)
  box(m,cf,"OakCabinetCarcass",0,1.76,0,6.5,2.9,2.5,C.woodDark,E.Wood,true)
  box(m,cf,"LimestoneCountertop",0,3.34,0,6.85,.26,2.87,chalk,E.Limestone,true)
  box(m,cf,"CounterFrontShadowLine",0,3.10,-1.3,6.5,.08,.09,C.black,E.Metal,false)
  for i=1,12 do box(m,cf,"SlattedOakFront_"..i,-3.02+(i-1)*.55,1.77,-1.31,.39,2.71,.13,i%4==0 and C.woodDark or C.wood,E.Wood,false)end
  plaque(m,cf,"ConciergeName","WELCOME",0,2.03,-1.425,3.3,.52)
  for i,x in ipairs({-1.6,1.6})do
   box(m,cf,"StaffCupboard_"..i,x,1.78,1.27,3.06,2.59,.1,C.wood,E.Wood,false)
   box(m,cf,"RecessedBronzePull_"..i,x,2.78,1.34,.94,.075,.12,bronze,E.Metal,false)
  end
  tablet(m,cf,"ConciergeTablet",1.75,3.47,.2)
  box(m,cf,"BusinessCardTray",-2.0,3.52,-.3,1.15,.11,.68,C.woodDark,E.Wood,false)
  box(m,cf,"BusinessCards",-2.0,3.60,-.3,.85,.08,.45,chalk,E.SmoothPlastic,false)
  box(m,cf,"PenRest",-.45,3.51,-.63,.8,.08,.4,bronze,E.Metal,false)
  bar(m,cf,"WelcomePen",V(-.77,3.58,-.65),V(-.13,3.58,-.65),.055,C.black,E.Metal)
 end

 -- West lounge faces the show cars. A real-depth sofa and an armchair make a
 -- seating composition; the side table stays west of the circulation spine.
 do
  local m,cf=group("02_Craft_Clubhouse_Lounge","LOUNGE",3064.1,25.0,-math.pi/2)
  box(m,cf,"WovenAreaRug",0,.019,-1.52,9.7,.028,7.6,Color3.fromRGB(114,119,105),E.Fabric,false)
  box(m,cf,"LowTimberSofaBase",0,.82,0,7.75,.58,3.1,C.woodDark,E.Wood,true)
  box(m,cf,"SofaBack",0,2.99,1.37,7.7,2.12,.44,leather,E.Fabric,true)
  for i,x in ipairs({-2.45,0,2.45})do
   box(m,cf,"IndividualSeatCushion_"..i,x,1.59,-.13,2.36,.73,2.73,leather,E.Fabric,true)
   box(m,cf,"BackCushion_"..i,x,3.01,1.08,2.34,1.77,.42,leather,E.Fabric,false)
   box(m,cf,"CushionFrontWelting_"..i,x,1.91,-1.50,2.29,.04,.025,stitch,E.Fabric,false)
  end
  for i,x in ipairs({-3.88,3.88})do
   box(m,cf,"SolidOakSofaArm_"..i,x,2.13,0,.32,1.48,3.35,C.wood,E.Wood,true)
   for j,z in ipairs({-1.12,1.12})do box(m,cf,"SplayedSofaFoot_"..i.."_"..j,x*.9,.35,z,.19,.70,.19,C.black,E.Metal,true)end
  end
  -- Coffee table is east of sofa but ends at X3068.8, short of the main aisle.
  box(m,cf,"OakCoffeeTable",0,1.73,-3.78,3.7,.20,1.92,C.wood,E.Wood,true)
  box(m,cf,"CoffeeTableLowerShelf",0,.57,-3.78,3.3,.14,1.56,C.woodDark,E.Wood,true)
  for i,x in ipairs({-1.57,1.57})do for j,z in ipairs({-4.5,-3.06})do box(m,cf,"CoffeeTableLeg_"..i.."_"..j,x,.83,z,.13,1.66,.13,C.black,E.Metal,true)end end
  local issue=box(m,cf,"CustomBuildJournal",-.63,1.89,-3.8,1.04,.10,.76,C.navy,E.SmoothPlastic,false)
  issue.CFrame=issue.CFrame*CFrame.Angles(0,.13,0)
  box(m,cf,"JournalTitleBand",-.63,1.947,-3.8,.70,.014,.18,chalk,E.SmoothPlastic,false)
  mug(m,cf,"LoungeCoffee",.86,1.85,-3.74)
  -- Independent armchair is near the north-west seating edge, not the door.
  chair(m,CFrame.new(3064.6,floor,32.1)*CFrame.Angles(0,-math.pi/2,0),"CompanionArmchair",0,0,0,C.navy)
 end

 -- Two separate consultations occupy the east perimeter; modest screens and
 -- key/document trays differentiate buyer configuration from seller valuation.
 local function consultation(name,cx,cz,isBuyer)
  local m,cf=group(name,"CONSULTATION",cx,cz)
  m:SetAttribute("InteractionMeaning",isBuyer and "BUYER_LISTING_AND_DEAL" or "SELLER_VALUATION_AND_HANDOFF")
  m:SetAttribute("CustomerSeatPosition",V(cx,floor,cz-3.1))
  m:SetAttribute("StaffSeatPosition",V(cx,floor,cz+3.0))
  box(m,cf,"OakDeskTop",0,3.00,0,5.55,.23,2.43,C.wood,E.Wood,true)
  box(m,cf,"ChamferShadowUnderside",0,2.85,0,5.3,.09,2.24,C.woodDark,E.Wood,false)
  box(m,cf,"InsetWorkMat",.27,3.128,.12,2.75,.021,1.71,isBuyer and C.navy or Color3.fromRGB(99,106,82),E.Fabric,false)
  box(m,cf,"DrawerPedestal",-2.0,1.40,.07,1.26,2.67,2.04,C.woodDark,E.Wood,true)
  for i=1,3 do
   box(m,cf,"DrawerFront_"..i,-2.0,.50+(i-1)*.82,1.115,1.15,.72,.085,C.wood,E.Wood,false)
   box(m,cf,"BronzeDrawerPull_"..i,-2.0,.73+(i-1)*.82,1.19,.60,.063,.09,bronze,E.Metal,false)
  end
  for i,z in ipairs({-.88,.88})do box(m,cf,"TaperDeskLeg_"..i,2.31,1.47,z,.17,2.94,.17,C.black,E.Metal,true)end
  bar(m,cf,"UnderDeskStretcher",V(2.31,.49,-.86),V(2.31,.49,.86),.105,C.steel,E.Metal)
  tablet(m,cf,"DealScreen",1.56,3.14,.40)
  box(m,cf,"DocumentFolio",-.67,3.164,-.22,1.18,.07,.87,isBuyer and leather or C.navy,E.SmoothPlastic,false)
  box(m,cf,"FolioPaper",-.67,3.207,-.23,1.00,.016,.70,chalk,E.SmoothPlastic,false)
  bar(m,cf,"SigningPen",V(-.21,3.23,-.52),V(-.21,3.23,.06),.051,bronze,E.Metal)
  box(m,cf,"LinedKeyTray",.68,3.185,-.58,.81,.10,.41,C.woodDark,E.Wood,false)
  bar(m,cf,"KeyBlade",V(.53,3.247,-.58),V(.83,3.247,-.58),.053,silver,E.Metal)
  box(m,cf,"KeyFob",.48,3.26,-.58,.17,.068,.15,C.black,E.SmoothPlastic,false)
  plaque(m,cf,"DeskIdentifier",isBuyer and "YOUR NEXT BUILD" or "SELL WITH US",0,2.63,-1.235,3.7,.34)
  chair(m,cf,"GuestChair",0,-3.1,math.pi,isBuyer and leather or C.navy)
  chair(m,cf,"AdvisorChair",0,3.0,0,Color3.fromRGB(92,101,87))
  return m
 end
 consultation("03_Buyer_Consultation",3079.55,16.05,true)
 consultation("04_Seller_Consultation",3079.55,27.25,false)

 -- Coffee joinery sits on the west wall. Four drawers, a recognizable espresso
 -- machine, cup warmer, spouts, drip grille and cups sell hospitality at eye level.
 do
  local m,cf=group("05_Coffee_Hospitality","HOSPITALITY",3062.60,38.25,-math.pi/2)
  box(m,cf,"RecessedCabinetPlinth",0,.18,0,6.15,.36,2.0,C.black,E.Metal,true)
  box(m,cf,"CoffeeCabinet",0,1.68,0,6.4,2.85,2.33,C.woodDark,E.Wood,true)
  box(m,cf,"StoneCoffeeWorktop",0,3.17,0,6.7,.20,2.58,chalk,E.Limestone,true)
  for i,x in ipairs({-2.37,-.79,.79,2.37})do
   box(m,cf,"JoineryFront_"..i,x,1.7,-1.21,1.46,2.63,.1,C.wood,E.Wood,false)
   box(m,cf,"BronzeCabinetPull_"..i,x,2.72,-1.31,.8,.07,.12,bronze,E.Metal,false)
  end
  local z=-.02
  box(m,cf,"EspressoMachineFeet",-.96,3.35,z,2.6,.16,1.89,C.black,E.Metal,false)
  box(m,cf,"EspressoMachineHousing",-.96,4.38,z+.37,2.49,1.95,1.18,silver,E.Metal,false)
  box(m,cf,"MachineRearWaterReservoir",-.96,4.72,z+.86,1.97,1.83,.48,Color3.fromRGB(118,154,150),E.Glass,false).Transparency=.26
  box(m,cf,"MachineTopCupWarmer",-.96,5.43,z+.15,2.54,.11,1.58,C.black,E.Metal,false)
  box(m,cf,"DarkEspressoControls",-.96,4.98,z-.25,2.26,.59,.18,C.black,E.Metal,false)
  bar(m,cf,"PressureGaugeRim",V(-1.43,4.96,z-.37),V(-1.43,4.96,z-.40),.34,bronze,E.Metal)
  bar(m,cf,"PressureGaugeFace",V(-1.43,4.96,z-.405),V(-1.43,4.96,z-.413),.26,chalk,E.SmoothPlastic)
  bar(m,cf,"PressureGaugeNeedle",V(-1.43,4.96,z-.421),V(-1.36,5.04,z-.421),.023,C.black,E.Metal)
  for i,x in ipairs({-.94,-.53})do
   bar(m,cf,"ControlButton_"..i,V(x,4.98,z-.37),V(x,4.98,z-.41),.12,silver,E.Metal)
  end
  box(m,cf,"CupDripTray",-.96,3.55,z-.5,2.58,.11,1.00,C.black,E.Metal,false)
  for i=1,7 do box(m,cf,"DripTrayGrille_"..i,-2.00+(i-1)*.345,3.615,z-.5,.12,.035,.80,silver,E.Metal,false)end
  for i,x in ipairs({-1.55,-.56})do
   bar(m,cf,"GroupHead_"..i,V(x,4.63,z-.41),V(x,4.36,z-.41),.23,silver,E.Metal)
   bar(m,cf,"PortafilterHandle_"..i,V(x,4.39,z-.42),V(x,4.39,z-.89),.15,C.black,E.SmoothPlastic)
   mug(m,cf,"EspressoCup_"..i,x-.12,3.64,z-.49)
  end
  bar(m,cf,"SteamWand",V(.08,4.82,z-.4),V(.26,3.93,z-.67),.068,silver,E.Metal)
  bar(m,cf,"MilkPitcher",V(.56,3.28,-.5),V(.56,3.98,-.5),.51,silver,E.Metal)
  box(m,cf,"CondimentTray",2.1,3.32,-.04,1.29,.1,1.24,C.woodDark,E.Wood,false)
  for i,x in ipairs({1.79,2.33})do bar(m,cf,"GlassCoffeeJar_"..i,V(x,3.38,.19),V(x,4.09,.19),.40,C.woodDark,E.Glass);bar(m,cf,"JarLid_"..i,V(x,4.09,.19),V(x,4.16,.19),.44,C.black,E.Metal)end
  box(m,cf,"FoldedLinenStack",2.08,3.55,-.40,.8,.35,.49,cream,E.Fabric,false)
 end

 -- Paint, wheel and trim choices are objects, not an abstract wall label.
 -- Low joinery north-west of the aisle allows views through the room at entry.
 do
  local m,cf=group("06_Craftsmanship_And_Finish_Library","BUILD_STORY",3067.60,39.8)
  box(m,cf,"SampleCabinetBase",0,.18,0,3.65,.36,2.32,C.black,E.Metal,true)
  box(m,cf,"OakSampleCabinet",0,1.64,0,3.91,2.55,2.41,C.woodDark,E.Wood,true)
  box(m,cf,"SampleWorkSurface",0,3.03,0,4.16,.19,2.64,C.wood,E.Wood,true)
  for i=1,3 do
   box(m,cf,"FlatSampleDrawer_"..i,0,.82+(i-1)*.69,-1.27,3.64,.56,.09,C.wood,E.Wood,false)
   box(m,cf,"SampleDrawerPull_"..i,0,.91+(i-1)*.69,-1.36,.85,.055,.12,bronze,E.Metal,false)
  end
  box(m,cf,"UprightFinishRack",0,4.41,.93,3.81,2.57,.18,C.black,E.Metal,false)
  local paint={Color3.fromRGB(124,48,38),Color3.fromRGB(38,120,117),Color3.fromRGB(179,137,45),Color3.fromRGB(59,79,109),Color3.fromRGB(215,208,184),Color3.fromRGB(59,62,56)}
  for i,color in ipairs(paint)do
   local x=-1.27+((i-1)%3)*1.27;local y=4.00+math.floor((i-1)/3)*.91
   box(m,cf,"EnamelPaintPlaque_"..i,x,y,.795,.96,.63,.13,color,E.Metal,false)
   box(m,cf,"SampleHighlight_"..i,x-.33,y,.718,.065,.51,.012,cream,E.SmoothPlastic,false)
   box(m,cf,"SampleNameTab_"..i,x,y-.38,.765,.48,.1,.032,chalk,E.SmoothPlastic,false)
  end
  for i,x in ipairs({-.99,-.30,.39})do
   box(m,cf,"LeatherAndTrimSwatch_"..i,x,3.18,-.18,.59,.09,.82,i==1 and leather or (i==2 and C.navy or cream),E.Fabric,false)
   box(m,cf,"SwatchSeam_"..i,x-.18,3.232,-.18,.025,.01,.73,stitch,E.Fabric,false)
  end
  plaque(m,cf,"CraftLabel","CRAFTED TO LAST",0,5.74,.72,3.9,.37)
 end
 return root
end

