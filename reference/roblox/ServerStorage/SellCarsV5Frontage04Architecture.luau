--!nocheck
-- F04-2: source-owned, single-storey institutional frontage architecture.
-- Geometry follows Frontage04Layout.json. +Z is toward campus; floor top is Y0.23.
-- This module creates architecture only: no vehicles, furniture, light instances,
-- controllers, historical installers or changes to existing project instances.
-- Roof undersides remain above vehicle clearances; columns have deliberately
-- asymmetric positions so they never consume a measured car or walking reserve.
return function(K, parent)
 local C, V, E = K.C, Vector3.new, Enum.Material
 local Y = .23
 local root = K.model(parent,"01_Architecture","ARCHITECTURE")
 root:SetAttribute("LayoutVersion","F04-1-contained-release-2026-09-08")
 root:SetAttribute("GroundTopY",Y)
 root:SetAttribute("ArchitectureOnly",true)
 local roofColor = Color3.fromRGB(40,49,50)
 local paleStone = Color3.fromRGB(207,198,174)
 local bronze = Color3.fromRGB(157,122,66)
 local glassColor = Color3.fromRGB(159,193,188)
 local jointColor = Color3.fromRGB(116,113,100)
 local function box(m,n,x,y,z,w,h,d,col,mat,solid)
  return K.box(m,n,x,y,z,w,h,d,col,mat,solid)
 end
 local function sign(m,n,text,x,y,z,w,h)
  local g=K.model(m,n,"WAYFINDING")
  box(g,"BronzeBackEdge",x,y,z,w+.18,h+.14,.15,bronze,E.Metal,false)
  local p=box(g,"EnamelFace",x,y,z-.1,w,h,.09,C.black,E.Metal,false)
  local gui=Instance.new("SurfaceGui");gui.Name="Lettering";gui.Face=Enum.NormalId.Front
  gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=50
  gui.LightInfluence=.15;gui.AlwaysOnTop=false;gui.Parent=p
  local label=Instance.new("TextLabel");label.Name="Inscription";label.Size=UDim2.fromScale(.94,.85)
  label.Position=UDim2.fromScale(.03,.075);label.BackgroundTransparency=1
  label.Text=text;label.TextColor3=C.paper;label.Font=Enum.Font.GothamMedium
  label.TextScaled=false;label.TextWrapped=false
  label.TextSize=math.floor(h*50*.68);label.Parent=gui
  return g
 end
 local function column(m,n,x,z,top,foot,shaft)
  local g=K.model(m,n,"STRUCTURE")
  box(g,"GroutedFoot",x,Y+.045,z,foot,.09,foot,paleStone,E.Concrete,true)
  box(g,"SteelBasePlate",x,Y+.115,z,foot*.9,.05,foot*.9,C.steel,E.Metal,true)
  box(g,"BoxSection",x,(Y+.14+top)/2,z,shaft,top-Y-.14,shaft,C.black,E.Metal,true)
  box(g,"TopConnection",x,top-.18,z,shaft+.18,.36,shaft+.18,C.steel,E.Metal,false)
  for i,offset in ipairs({{-.26,-.26},{.26,.26}})do
   box(g,"AnchorHead_"..i,x+offset[1]*foot,Y+.162,z+offset[2]*foot,.095,.045,.095,bronze,E.Metal,false)
  end
  return g
 end
 -- Seamed metal roofs carry a warm soffit, real-depth fascias, folded gutters
 -- and differentiated corner joints. Soffit boards are broad buildable modules,
 -- not thousands of decorative fragments. All roof parts are non-colliding.
 local function roof(m,n,x0,z0,x1,z1,top,soffitAxis)
  local g=K.model(m,n,"ROOF")
  local w,d,x,z=x1-x0,z1-z0,(x0+x1)/2,(z0+z1)/2
  box(g,"StructuralDeck",x,top-.35,z,w,.4,d,C.steel,E.Metal,false)
  local panels=math.ceil(w/3.3)
  for i=1,panels do
   local px=x0+(i-.5)*w/panels
   box(g,"StandingSeamPanel_"..i,px,top-.11,z,w/panels-.045,.11,d-.1,i%4==0 and C.steel or roofColor,E.Metal,false)
   if i<panels then box(g,"FoldedSeam_"..i,x0+i*w/panels,top+.015,z,.055,.18,d-.12,C.black,E.Metal,false)end
  end
  local boards=math.ceil((soffitAxis=="X" and w or d)/2.4)
  for i=1,boards do
   if soffitAxis=="X" then
    box(g,"TimberSoffit_"..i,x0+(i-.5)*w/boards,top-.61,z,w/boards-.08,.12,d-.45,i%4==0 and C.woodDark or C.wood,E.Wood,false)
   else
    box(g,"TimberSoffit_"..i,x,top-.61,z0+(i-.5)*d/boards,w-.45,.12,d/boards-.08,i%4==0 and C.woodDark or C.wood,E.Wood,false)
   end
  end
  for i,px in ipairs({x0+.07,x1-.07})do
   box(g,"LongFoldedFascia_"..i,px,top-.3,z,.14,.64,d,C.black,E.Metal,false)
   box(g,"LongBronzeReveal_"..i,px+(i==1 and -.076 or .076),top-.5,z,.035,.065,d-.25,bronze,E.Metal,false)
  end
  for i,pz in ipairs({z0+.07,z1-.07})do
   box(g,"EndFoldedFascia_"..i,x,top-.3,pz,w,.64,.14,C.black,E.Metal,false)
   box(g,"EndBronzeReveal_"..i,x,top-.5,pz+(i==1 and -.076 or .076),w-.25,.065,.035,bronze,E.Metal,false)
  end
  box(g,"RearBoxGutter",x,top-.24,z1-.32,w-.35,.23,.32,C.steel,E.Metal,false)
  for i,px in ipairs({x0+.42,x1-.42})do
   box(g,"GutterCollector_"..i,px,top-.44,z1-.35,.44,.55,.5,C.black,E.Metal,false)
  end
  return g
 end

 -- RECEIVING. All low supports sit just north of the 8-stud terrace and in
 -- the inter-car strips, not behind the cars or inside the rear release sweep.
 do
  local m=K.model(root,"01_Receiving_Cantilever_Canopy","ARCHITECTURE")
  m:SetAttribute("MinimumRoofClearance",18.2)
  m:SetAttribute("ProtectedReleaseStartsZ",76)
  local xs={3004.45,3023.5,3042.5,3058.9}
  for i,x in ipairs(xs)do
   -- Last support is forward of the parked rectangle; all footings end Z52.49.
   local g=column(m,"FrontCantileverColumn_"..i,x,52.245,20.18,.48,.32)
   box(g,"HighCantileverWeb",x,19.58,64,.26,1.18,23.8,C.steel,E.Metal,false)
   box(g,"CantileverTopFlange",x,20.16,64,.72,.12,23.8,C.black,E.Metal,false)
   box(g,"CantileverLowerFlange",x,19.0,64,.56,.12,23.8,C.black,E.Metal,false)
   K.bar(g,"TaperBrace",V(x,18.7,53.2),V(x,19.62,62.2),.14,bronze,E.Metal,false)
  end
  box(m,"FrontContinuousBoxBeam",3031.5,19.88,52.25,55,.64,.46,C.black,E.Metal,false)
  box(m,"RearContinuousBoxBeam",3031.5,19.88,75.5,55,.64,.46,C.black,E.Metal,false)
  roof(m,"SeamedReceivingRoof",3004,51.95,3059,76,20.9,"X")
  sign(m,"ReceivingIdentification","RECEIVING",3032,19.17,51.95,14,1.15)
  -- A tall clear service portal establishes the uncommon-car / transporter edge.
  local gate=K.model(m,"SpecialServicePortal","STRUCTURE")
  gate:SetAttribute("ClearOpeningXMin",3004)
  gate:SetAttribute("ClearOpeningXMax",3030)
  -- The opening, not the outside of its jambs, is 26 clear. The west pier
  -- reaches 0.85 stud beyond the apron edge but remains inside the parcel.
  for i,x in ipairs({3003.5,3030.5})do
   column(gate,"ServiceJamb_"..i,x,-1.55,19.2,.7,.42)
   box(gate,"GroundedPierFoundation_"..i,x,.1,-1.55,.7,.26,.7,paleStone,E.Concrete,true)
  end
  box(gate,"ClearanceHeader",3017,18.92,-1.55,27.7,.62,.56,C.black,E.Metal,false)
  box(gate,"TimberHeaderFace",3017,18.91,-1.89,26.6,.36,.09,C.wood,E.Wood,false)
  sign(gate,"SpecialReceivingIdentification","SPECIAL RECEIVING",3017,18.92,-1.96,16,.84)
 end

 -- CUSTOMER ROOM. Open front entry X3068..3076, east connection Z34..42.4,
 -- and north connection X3072..3082. No invisible glass across those openings.
 do
  local m=K.model(root,"02_Shared_Customer_Room","ARCHITECTURE")
  m:SetAttribute("FrontDoorClearWidth",8)
  m:SetAttribute("EastDoorClearWidth",8.4)
  m:SetAttribute("NorthDoorClearWidth",10)
  local function glazedWall(n,axis,fixed,lo,hi)
   local g=K.model(m,n,"ENVELOPE")
   local len=hi-lo
   if len<.7 then return g end
   local function q(name,y,height,depth,color,mat,solid,start,finish)
    start,finish=start or lo,finish or hi
    if axis=="X" then return box(g,name,(start+finish)/2,y,fixed,finish-start,height,depth,color,mat,solid)
    else return box(g,name,fixed,y,(start+finish)/2,depth,height,finish-start,color,mat,solid)end
   end
   q("LimestonePlinth",Y+1.02,2.04,.44,paleStone,E.Limestone,true)
   q("DarkStoneSill",Y+2.10,.12,.5,C.stone,E.Slate,true)
   local panels=math.ceil(len/5.5)
   for i=1,panels do
    local a,b=lo+(i-1)*len/panels,lo+i*len/panels
    local p=q("ClearGlazing_"..i,7.35,10.0,.13,glassColor,E.Glass,true,a+.09,b-.09)
    p.Transparency=.57;p.Reflectance=.025
    q("WindowMullion_"..i,7.25,10.35,.26,C.steel,E.Metal,true,b-.11,b)
    if i<panels then q("StoneVerticalJoint_"..i,1.22,1.9,.455,jointColor,E.Concrete,false,b-.036,b)end
   end
   q("TransomRail",12.58,.2,.27,C.black,E.Metal,true)
   q("TimberClerestory",13.28,1.13,.24,C.wood,E.Wood,true)
   q("SoffitShadowGap",14.03,.13,.34,C.black,E.Metal,false)
   for i,y in ipairs({.89,1.57})do q("LimestoneBedJoint_"..i,y,.018,.454,jointColor,E.Concrete,false)end
   return g
  end
  glazedWall("SouthLeftWelcomeWindow","X",8.24,3060.24,3068)
  glazedWall("SouthRightWelcomeWindow","X",8.24,3076,3083.76)
  glazedWall("WestGardenFacade","Z",3060.24,8.24,42.76)
  glazedWall("EastConsultationFacade","Z",3083.76,8.24,34)
  glazedWall("NorthReceivingFacade","X",42.76,3060.24,3072)
  glazedWall("NorthReturnPier","X",42.76,3082,3083.76)
  for i,q in ipairs({{3060.48,8.48},{3083.52,8.48},{3060.48,42.52}})do
   column(m,"RoomCorner_"..i,q[1],q[2],14.65,.64,.4)
  end
  column(m,"RoomCorner_4",3083.6,42.7,14.65,.4,.28)
  local entries={{"FrontEntry","X",8.24,3068,3076},{"EastGalleryEntry","Z",3083.76,34,42.4},{"NorthReceivingEntry","X",42.76,3072,3082}}
  for _,e in ipairs(entries)do
   local g=K.model(m,e[1],"OPEN_ENTRY")
   g:SetAttribute("ClearOpening",true)
   local axis,fixed,a,b=e[2],e[3],e[4],e[5]
   local function q(name,along,y,w,h,d,col,mat)
    if axis=="X" then return box(g,name,along,y,fixed,w,h,d,col,mat,true)
    else return box(g,name,fixed,y,along,d,h,w,col,mat,true)end
   end
   -- Jambs are placed outside the nominal opening, preserving the clear width.
   q("LeftRecessedJamb",a-.075,5.28,.15,10.1,.38,C.black,E.Metal)
   q("RightRecessedJamb",b+.075,5.28,.15,10.1,.38,C.black,E.Metal)
   q("TimberEntryLintel",(a+b)/2,10.48,b-a+.3,.32,.42,C.wood,E.Wood)
   local p=q("HighClearTransom",(a+b)/2,12.04,b-a,2.78,.11,glassColor,E.Glass)
   p.Transparency=.64;p.Reflectance=.015
   q("UpperPortalRail",(a+b)/2,13.51,b-a+.3,.2,.32,C.black,E.Metal)
  end
  for i,x in ipairs({3060.42,3083.58})do box(m,"LongRoofBeam_"..i,x,14.45,25.5,.48,.6,34.7,C.black,E.Metal,false)end
  for i,z in ipairs({8.42,42.58})do box(m,"CrossRoofBeam_"..i,3072,14.45,z,23.4,.6,.48,C.black,E.Metal,false)end
  roof(m,"CustomerRoomRoof",3059.7,7.55,3084.3,43.55,15.45,"Z")
  -- Front door receives its own modest canopy instead of another box lobby.
  roof(m,"WelcomeEyebrow",3066.9,5.65,3077.1,8.05,11.08,"X")
  sign(m,"LoungeIdentification","CUSTOMER LOUNGE",3072,13.63,7.47,18.5,.9)
  local fins=K.model(m,"WestTimberSolarScreen","ENVELOPE")
  for i=1,8 do
   box(fins,"TimberBlade_"..i,3060.63,7.36,18.2+(i-1)*1.38,.3,9.6,.45,i%3==0 and C.woodDark or C.wood,E.Wood,false)
  end
  box(fins,"UpperScreenRail",3060.73,12.21,23.03,.27,.18,10.5,C.black,E.Metal,false)
  box(fins,"LowerScreenRail",3060.73,2.5,23.03,.27,.18,10.5,C.black,E.Metal,false)
 end

 -- SALES. The west roof is supported primarily from its rear strip, leaving
 -- the full customer link Z43..51 clear. East court-side posts use the 5-stud
 -- gaps, never the Z39.5..43.5 pedestrian branch. No glazing hides the cars.
 local function salesColonnade(name,x0,x1,positions,signText)
  local m=K.model(root,name,"ARCHITECTURE")
  m:SetAttribute("MinimumRoofClearance",14.05)
  for i,q in ipairs(positions)do
   column(m,"GalleryColumn_"..i,q[1],q[2],15.92,q[3],q[4])
  end
  for i,x in ipairs({x0+.25,x1-.25})do
   box(m,"LongitudinalWeb_"..i,x,15.12,43.5,.19,1.65,74.4,C.steel,E.Metal,false)
   box(m,"TopBeamFlange_"..i,x,15.92,43.5,.56,.12,74.4,C.black,E.Metal,false)
   box(m,"LowerBeamFlange_"..i,x,14.34,43.5,.5,.12,74.4,C.black,E.Metal,false)
  end
  for i,z in ipairs({7,25,43,61,79.7})do
   box(m,"TransverseRoofRib_"..i,(x0+x1)/2,15.71,z,x1-x0-.75,.32,.18,C.black,E.Metal,false)
  end
  roof(m,"CraftedSalesRoof",x0,6,x1,81,16.39,"Z")
  sign(m,"StreetIdentification",signText,(x0+x1)/2,15.05,5.96,x1-x0-4,1.02)
  -- Discrete below-roof bronze datum connects the separate pavilions visually.
  box(m,"FrontTimberFascia",(x0+x1)/2,15.36,6.1,x1-x0-.6,.28,.12,C.wood,E.Wood,false)
  return m
 end
 salesColonnade("03_West_Sales_Colonnade",3085,3110,{
  {3085.66,6.7,.58,.32},{3085.66,25,.58,.32},{3085.66,57,.58,.32},
  {3085.66,73,.58,.32},{3085.66,80.63,.58,.32},
  {3109.62,6.7,.58,.32},{3109.62,25,.58,.32},{3109.62,80.63,.58,.32},
 },"SELECT MOTOR CARS")
 salesColonnade("04_East_Sales_Colonnade",3145,3170,{
  {3169.35,7,.7,.36},{3169.35,22.5,.7,.36},{3169.35,52,.7,.36},
  {3169.35,60.5,.7,.36},{3169.35,79.7,.7,.36},
  {3145.5,22.5,.76,.38},{3145.5,60.5,.76,.38},{3145.5,79.7,.76,.38},
 },"SALES / DELIVERY")

 -- STREET GATE. Only the lightweight crown crosses the central axis; the
 -- clear opening remains wider than the reserved 27-stud vehicle court.
 do
  local m=K.model(root,"05_Desert_Customs_Street_Gateway","ARCHITECTURE")
  m:SetAttribute("ClearVehicleOpeningXMin",3118)
  m:SetAttribute("ClearVehicleOpeningXMax",3145)
  m:SetAttribute("MinimumHeaderClearance",20.2)
  for i,x in ipairs({3116.6,3146.4})do
   column(m,"GatewayPier_"..i,x,-11,22.03,1.08,.6)
   box(m,"PierTimberInlay_"..i,x,11.68,-11.34,.32,18.8,.07,C.wood,E.Wood,false)
   box(m,"PierBronzeCollar_"..i,x,1.03,-11,.67,.22,.67,bronze,E.Metal,false)
  end
  box(m,"CrownStructuralBeam",3131.5,21.3,-11,32.6,1.5,1.0,C.black,E.Metal,false)
  box(m,"TimberCrownFace",3131.5,21.3,-11.54,31.2,1.18,.14,C.woodDark,E.Wood,false)
  box(m,"CrownUpperCap",3131.5,22.12,-11,33.3,.2,1.32,C.black,E.Metal,false)
  box(m,"CrownBronzeDrip",3131.5,20.48,-11.62,32.6,.07,.07,bronze,E.Metal,false)
  sign(m,"DesertCustomsIdentity","DESERT CUSTOMS",3131.5,21.3,-11.67,26,1.44)
  -- Short stone bases identify the entrance without boxing in either side.
  for i,x in ipairs({3116.6,3146.4})do
   box(m,"PierStoneSock_"..i,x,.64,-11,1.3,.82,1.3,paleStone,E.Limestone,true)
   box(m,"SockShadowCourse_"..i,x,.89,-11,1.31,.018,1.31,jointColor,E.Concrete,false)
  end
 end
 return root
end

