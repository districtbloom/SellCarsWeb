--!nocheck
-- Phase 5B owns Sales/Delivery only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase5b.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","04_Frontage_And_Owner","02_Sales"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Sales_Delivery."..n..".FidelityR1",FunctionId="Sales_Delivery",ZoneId="Sales_Delivery",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase5BSalesGeometry",true);p.Parent=m;return p
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





local Slate=Color3.fromRGB(58,79,86)
local function label(m,n,x,y,z,w,h,value)
 local p=box(m,n,x,y,z,w,h,.16,C.Charcoal,M,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(720,140);g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=value;t.Font=Enum.Font.GothamMedium;t.TextScaled=true;t.TextColor3=C.WarmWhite;t.Parent=g
 return p
end
local function monitor(m,n,x,y,z,w,h)
 box(m,n.."_Housing",x,y,z,w,h,.26,C.Charcoal,P,false)
 return box(m,n.."_Display",x,y,z-.17,w-.25,h-.25,.04,Slate,P,false)
end
local function chair(m,x,z,flip)
 local cf=CFrame.new(x,0,z)*CFrame.Angles(0,flip and math.pi or 0,0)
 local function p(n,a,b,c,w,h,d,col,mat)
  local q=box(m,n,0,0,0,w,h,d,col,mat,true);q.CFrame=cf*CFrame.new(a,b,c);return q
 end
 p("UpholsteredSeat",0,2.3,0,2.7,.45,2.6,C.Navy,Enum.Material.Fabric)
 p("UpholsteredBack",0,3.45,1.0,2.7,2.0,.4,C.Navy,Enum.Material.Fabric)
 for _,a in ipairs({-1,1}) do for _,b in ipairs({-.8,.8}) do p("ChairSteelLeg",a,1.45,b,.15,1.3,.15,C.Steel,M) end end
end
local function shell(l)
 local m=group(l,"Commercial_Canopy_And_Glazing","ARCHITECTURE","DEDICATED","Sales awning -> curated open showroom with crafted shade")
 box(m,"ShowroomRoof",3130,15,54,78,1,94,C.Charcoal,M,false)
 for x=3094,3166,8 do box(m,"StandingSeam",x,15.56,54,.13,.12,93,C.Steel,M,false) end
 for _,z in ipairs({10,43,98}) do
  box(m,"RoofBeamWeb",3130,14.1,z,77,.6,.22,C.Steel,M,false)
  for _,y in ipairs({13.76,14.43}) do box(m,"RoofBeamFlange",3130,y,z,77,.10,.8,C.Charcoal,M,false) end
 end
 for _,x in ipairs({3092.4,3167.6}) do
  local west=x<3130;local centerZ=west and 47.5 or 54;local span=west and 69 or 82
  local g=box(m,"NeutralClearGlazing",x,7,centerZ,.35,12,span,C.Galvanized,Enum.Material.Glass,false);g.Transparency=.78
  for _,z in ipairs(west and {14,43,69,82} or {14,43,69,94}) do box(m,"GlassMullion",x,7,z,.5,12,.35,C.Charcoal,M,true) end
  box(m,"GlassTopRail",x,13,54,.6,.22,82,C.Steel,M,false)
  box(m,"GlassBaseChannel",x,.9,centerZ,.6,.35,span,C.Steel,M,true)
  box(m,"EavesGutter",x,14.8,54,.6,.45,94,C.Galvanized,M,false)
 end
 box(m,"RoadHeader",3130,12.4,9,76,4,1,C.Charcoal,M,false)
 for x=3095,3165,2.5 do box(m,"HeaderTimberInset",x,12.4,8.43,1.9,2.8,.13,C.Timber,Enum.Material.Wood,false) end
 label(m,"SalesIdentity",3130,12.4,8.2,29,2.2,"DESERT CUSTOMS  /  MOTOR GALLERY")
 for _,x in ipairs({3104,3156}) do
  local p=box(m,"ContinuousDiffuseCanopyLight",x,14.25,44,1.2,.2,55,C.WarmWhite,Enum.Material.Neon,false)
  local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Range=19;light.Brightness=1.1;light.Color=C.WarmWhite;light.Shadows=false;light.Parent=p
 end
 point(m,"ShowroomAmbience",3130,13.5,70,"FX")
end
local function display(l,index,x,z)
 local m=group(l,"Ground_Display_Setting_"..index,"HERO","WORKING","Yard listing slot -> curated car presentation")
 m:SetAttribute("DisplayIndex",index);m:SetAttribute("ExistingCarRetained",true)
 box(m,"DisplayStoneInset",x,.65,z,13.5,.12,21.5,C.OldConcrete,Enum.Material.Slate,false)
 for _,dx in ipairs({-6.6,6.6}) do box(m,"BronzeInlay",x+dx,.73,z,.07,.025,21,C.Bronze,M,false) end
 local sx=x<3130 and x+8.1 or x-8.1
 box(m,"ListingStandFoot",sx,.8,z-8,1.5,.28,1.5,C.Charcoal,M,true)
 pipe(m,"ListingStandStem",Vector3.new(sx,.94,z-8),Vector3.new(sx,3.9,z-8),.21,C.Steel)
 local p=monitor(m,"VehicleSpecification",sx,4.25,z-8,2.1,1.4)
 p:SetAttribute("DataBindingKey","LIVE_LISTING_PRICE_AND_BUILD_RECORD");p:SetAttribute("RuntimeBinding","PENDING")
 for i=0,2 do box(m,"ListingField",sx,4.63-i*.35,z-8.2,1.45,.10,.025,i==0 and C.Bronze or C.Galvanized,P,false) end
 -- Front/rear ends stay open for the accepted car and future display dispatch.
 point(m,"BrowseCar_"..index,sx,.6,z-4,"OPERATOR")
 point(m,"SaleDisplayTarget_"..index,x,6.5,z,"FX")
end
local function lift(l,index,z)
 local m=group(l,"Elevated_Showcase_Lift_"..index,"HERO","PROFESSIONAL","Six-car sales capacity -> vertically displayed show cars while central exit stays open")
 m:SetAttribute("ParkedState","ELEVATED_MECHANICALLY_LOCKED_NO_LIVE_LIFT")
 m:SetAttribute("RequiresClearZoneForLowering",true);m:SetAttribute("ExistingCarRetained",true)
 box(m,"ShowcaseDeck",3130,9.2,z,15,.7,21.5,C.Charcoal,Enum.Material.DiamondPlate,false)
 for _,x in ipairs({3120.8,3139.2}) do
  box(m,"LiftTower",x,4.6,z,.9,9.2,.9,C.Steel,M,true)
  box(m,"LiftAnchorFoot",x,.73,z,2,.22,2,C.Charcoal,M,true)
  for _,dx in ipairs({-.65,.65}) do for _,dz in ipairs({-.65,.65}) do cyl(m,"LiftAnchorBolt",x+dx,.92,z+dz,.14,.15,C.Stainless,"Y") end end
  box(m,"ClosedChainChannel",x,4.9,z+.55,.6,7.8,.22,C.Charcoal,M,false)
  for y=1.6,8.7,.6 do box(m,"PositiveLockRackTooth",x, y,z-.55,.6,.16,.22,C.Galvanized,M,false) end
  box(m,"LockedLiftCarriage",x,8.85,z,1.5,.8,2.0,C.Galvanized,M,true)
  box(m,"DeckCarrierArm",x<3130 and 3122 or 3138,8.9,z,2.5,.4,1.5,C.Steel,M,true)
  cyl(m,"HydraulicActuator",x,4.5,z-.9,6.8,.35,C.Stainless,"Y")
  pipe(m,"HydraulicParkedFeed",Vector3.new(x,1,z-.9),Vector3.new(x,1,z-2),.13,C.Charcoal)
 end
 for _,x in ipairs({3122.75,3137.25}) do
  box(m,"DeckWheelGuard",x,9.95,z,.12,.75,21,C.Bronze,M,false)
  box(m,"DeckSideLip",x,9.59,z,.16,.13,21.3,C.Galvanized,M,false)
 end
 for _,xx in ipairs({3125.2,3134.8}) do for _,zz in ipairs({z-5.9,z+5.9}) do
  box(m,"WheelContactPad",xx,9.67,zz,1.5,.22,3.1,C.Rubber,P,false)
 end end
 for _,zz in ipairs({z-9.8,z+9.8}) do box(m,"EndWheelRestraint",3130,9.8,zz,11,.42,.4,C.Charcoal,M,false) end
 box(m,"LiftControlPod",3140.2,3.6,z,1,1.5,.8,C.Bronze,M,false)
 cyl(m,"GuardedLiftKey",3140.2,3.7,z-.45,.08,.20,C.Charcoal,"Z")
 box(m,"KeyCover",3140.2,3.8,z-.6,.8,.6,.06,C.Charcoal,M,false)
 -- Source-owned underslung fascia has no static fake sale price.
 local p=monitor(m,"ElevatedListingOutput",3130,8.45,z-10.85,6.8,.7)
 p:SetAttribute("DataBindingKey","LIVE_LISTING_PRICE");p:SetAttribute("RuntimeBinding","PENDING")
 for _,x in ipairs({3127.5,3132.5}) do pipe(m,"ListingBoardHanger",Vector3.new(x,8.8,z-10.85),Vector3.new(x,8.9,z-10.6),.10,C.Steel) end
 box(m,"PendingListingValue",3130,8.45,z-11.05,3.8,.12,.02,C.WarmWhite,P,false)
 point(m,"LiftServiceOperator_"..index,3143,.6,z,"OPERATOR")
 point(m,"ShowcaseActuator_"..index,3139.2,8.8,z,"FX")
end
local function deal(l)
 local m=group(l,"Deal_And_Listing_Exchange","HERO","WORKING","One sales desk -> documented negotiation and delivery")
 box(m,"DealDeskTop",3162,3.45,75,11,.35,3.4,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({3158,3166}) do
  box(m,"DealDeskPedestal",x,1.95,75,1.8,2.6,2.8,C.Charcoal,M,true)
  for j=0,2 do box(m,"RecordDrawer",x,1.1+j*.75,76.46,1.6,.6,.10,C.Steel,M,false);box(m,"DrawerPull",x,1.1+j*.75,76.57,.65,.10,.10,C.Stainless,M,false) end
 end
 for _,x in ipairs({3160,3163.6}) do
  pipe(m,"MonitorArm",Vector3.new(x,3.7,75),Vector3.new(x,4.5,75),.18,C.Steel)
  local p=monitor(m,"DealMonitor",x,5.1,75,2.8,1.75);p:SetAttribute("DataBindingKey","LISTING_AND_FINAL_NEGOTIATION_SEPARATE");p:SetAttribute("RuntimeBinding","PENDING")
  for j=0,2 do box(m,"DealDataRow",x,5.55-j*.4,74.80,1.7,.1,.03,j==1 and C.Bronze or C.Galvanized,P,false) end
 end
 box(m,"SigningPad",3166,3.68,74.8,1.8,.09,2,C.Charcoal,P,false)
 box(m,"DeliveryDocument",3166,3.74,74.8,1.4,.025,1.7,C.WarmWhite,P,false)
 box(m,"KeyPresentationTray",3157.7,3.72,74.8,1.8,.17,1.5,C.Bronze,M,false)
 for i=0,1 do box(m,"KeyEnvelope",3157.4+i*.65,3.84,74.8,.5,.03,.9,C.CleanPanel,P,false) end
 chair(m,3162,71,true);chair(m,3165.5,80.5,false)
 box(m,"DocumentPrinterCabinet",3166,2.2,84,2.9,3.1,3,C.Charcoal,M,true)
 box(m,"Printer",3166,4.05,84,2.6,.6,2.6,C.Galvanized,P,false)
 box(m,"PrinterOutput",3166,4.4,83.2,1.7,.035,.7,C.WarmWhite,P,false)
 point(m,"SalesAdvisor",3160,.6,79,"OPERATOR")
 point(m,"CustomerNegotiation",3157,.6,70.5,"FX")
end
local function lounge(l)
 local m=group(l,"Customer_Lounge_And_Merchandise","STORY","DEDICATED","Waiting bench -> custom-car clubhouse welcome")
 box(m,"LoungeSeat",3098,2.2,73,8,.65,3,C.Navy,Enum.Material.Fabric,true)
 box(m,"LoungeBack",3098,3.3,74.3,8,2,.5,C.Navy,Enum.Material.Fabric,true)
 for _,x in ipairs({3094.5,3101.5}) do box(m,"SofaArm",x,2.8,73,.4,1.3,3,C.Timber,Enum.Material.Wood,true);box(m,"SofaLeg",x,1.15,73,.3,.9,2.3,C.Steel,M,true) end
 for x=3095,3101,2 do box(m,"SeatCushionSeam",x,2.55,73,.04,.025,2.7,C.Steel,P,false) end
 box(m,"CoffeeTableTop",3103.9,2.35,73,2.8,.25,4,C.Timber,Enum.Material.Wood,true)
 box(m,"CoffeeTableFoot",3103.9,1.4,73,1.7,1.5,2.5,C.Charcoal,M,true)
 box(m,"BuildPortfolioBook",3103.9,2.55,73,1.7,.14,2.4,C.Bronze,P,false)
 box(m,"ClubhouseCoffeeConsole",3096,3.4,83,6,.3,3,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({3093.7,3098.3}) do box(m,"CoffeeConsoleLeg",x,2.0,83,.35,2.6,.35,C.Steel,M,true) end
 box(m,"CoffeeMachineBody",3095,4.65,83,2.1,2.2,1.8,C.Charcoal,M,false)
 cyl(m,"BeanHopper",3095,6.1,83,.65,1.1,C.Galvanized,"Y")
 box(m,"CoffeeSpout",3095,4.8,81.96,.8,.3,.3,C.Stainless,M,false)
 box(m,"DripTray",3095,3.85,81.9,1.8,.16,.6,C.Galvanized,M,false)
 for i=0,2 do cyl(m,"Cup",3097+i*.45,3.85,82.7,.6,.35,C.WarmWhite,"Y") end
 box(m,"ClubMerchandiseShelf",3093.5,5.1,70,1.5,5.5,5,C.Charcoal,M,true)
 for _,z in ipairs({68.5,70,71.5}) do
  box(m,"FoldedClubShirt",3093.4,4.9,z,1.2,.4,1.1,C.Navy,Enum.Material.Fabric,false)
  box(m,"ClubCapCrown",3093.4,6.4,z,.8,.45,.8,C.Bronze,Enum.Material.Fabric,false)
  box(m,"ClubCapVisor",3094,6.2,z,.8,.09,.8,C.Bronze,Enum.Material.Fabric,false)
 end
 point(m,"CustomerLoungeArrival",3107,.6,72,"OPERATOR")
end
local function delivery(l)
 local m=group(l,"Protected_Handover_And_Staging","HERO","DEDICATED","Yard handover -> focused reveal and documented release")
 box(m,"RevealStoneInset",3144,.65,84,12,.12,20,C.OldConcrete,Enum.Material.Slate,false)
 box(m,"StagingSurface",3116,.65,84,11.5,.12,19,C.Concrete,Enum.Material.Concrete,false)
 for _,x in ipairs({3130,3158}) do
  box(m,"RevealLightFrameLong",x,11.6,84,.6,.4,22,C.Charcoal,M,false)
  box(m,"RevealDiffusionStrip",x,11.35,84,.4,.06,21.5,C.WarmWhite,Enum.Material.Neon,false)
 end
 for _,z in ipairs({73,95}) do
  box(m,"RevealLightFrameEnd",3144,11.6,z,28.6,.4,.6,C.Charcoal,M,false)
  box(m,"RevealDiffusionEnd",3144,11.35,z,28,.06,.4,C.WarmWhite,Enum.Material.Neon,false)
 end
 for _,x in ipairs({3132,3156}) do for _,z in ipairs({75,93}) do pipe(m,"RevealFrameHanger",Vector3.new(x,11.8,z),Vector3.new(x,14.5,z),.10,C.Steel) end end
 local p=box(m,"RevealSoftCeiling",3144,13.2,84,15,.18,13,C.WarmWhite,Enum.Material.Fabric,false)
 for _,x in ipairs({3138,3150}) do pipe(m,"SoftCeilingSuspension",Vector3.new(x,13.3,84),Vector3.new(x,14.5,84),.09,C.Steel) end
 local li=Instance.new("SurfaceLight");li.Face=Enum.NormalId.Bottom;li.Range=20;li.Brightness=1.2;li.Angle=110;li.Color=C.WarmWhite;li.Shadows=false;li.Parent=p
 -- No floor curtains/posts in the diagonal arrival or first crossover.
 cyl(m,"RolledRevealBackdrop",3144,12.4,73,20,1.0,C.Charcoal,"X")
 for _,x in ipairs({3133.5,3154.5}) do box(m,"BackdropMotorBracket",x,12.5,73,.6,1.2,1.3,C.Steel,M,false);pipe(m,"BackdropMount",Vector3.new(x,13.1,73),Vector3.new(x,14.5,73),.2,C.Steel) end
 point(m,"HandoverPresenter",3159,.6,84,"OPERATOR")
 point(m,"RevealLightingTarget",3144,8.8,84,"FX")
 m:SetAttribute("ParkedState","BACKDROP_ROLLED_CLEAR_LIGHTING_INACTIVE")
end
local function finish(l)
 local m=group(l,"Sales_Floor_And_Customer_Approaches","ARCHITECTURE","WORKING","Sales yard -> warm showroom paving with clear central drive")
 box(m,"ShowroomPaving",3130,.55,54,77,.1,93,C.Concrete,Enum.Material.Concrete,false)
 for _,x in ipairs({3115,3145}) do box(m,"PedestrianMaterialBand",x,.65,42,5,.10,61,C.CleanPanel,Enum.Material.Concrete,false) end
 for _,z in ipairs({17,43,69}) do box(m,"PavingJoint",3130,.61,z,76,.035,.045,C.OldConcrete,P,false) end
 path(l,"WestCustomerWalk",{{3116,14},{3116,70}})
 path(l,"EastCustomerWalk",{{3144,14},{3144,70}})
 for i,p in ipairs({{3112.1,26},{3147.9,26},{3112.1,52},{3147.9,52}}) do
  path(l,"DisplayBrowse_"..i,{{p[1]<3130 and 3116 or 3144,p[2]},{p[1],p[2]}})
 end
 path(l,"LoungeApproach",{{3116,70},{3107,70},{3107,72}})
 path(l,"DealAdvisorApproach",{{3144,70},{3154,70},{3154,79},{3160,79}})
 path(l,"HandoverApproach",{{3160,79},{3159,84}})
 path(l,"Lift1Service",{{3144,30},{3143,30}})
 path(l,"Lift2Service",{{3144,56},{3143,56}})
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
 root():SetAttribute("InstitutionFidelityPhase5BSalesStatus",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase3Status")=="ACCEPTED","Rear support gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local old=root()["09_Institution_Production_B"]["01_Frontage_Commercial"]["02_Sales_Delivery"]
  local function hideExceptCars(target)
   if target:IsA("Model") and target:GetAttribute("VehicleDisplay") then return end
   if target:IsA("BasePart") then suppress(l,target);return end
   for _,c in ipairs(target:GetChildren()) do hideExceptCars(c) end
  end
  for _,c in ipairs(old:GetChildren()) do if c.Name~="ShowroomColumn" then hideExceptCars(c) end end
  suppress(l,root()["05_Architecture_Massing"]["01_Frontage"].SalesEnvelope)
  for i=1,6 do suppress(l,root()["04_Capacity_Sockets"]["SalesDisplay_"..i]) end
  for _,n in ipairs({"SalesReveal","SalesStaging"}) do suppress(l,root()["04_Capacity_Sockets"][n]) end
  shell(l)
  for i,p in ipairs({{3104,30},{3156,30},{3104,56},{3156,56}}) do display(l,i,p[1],p[2]) end
  lift(l,1,30);lift(l,2,56);deal(l);lounge(l);delivery(l);finish(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase5BSalesStatus","BUILT_AWAITING_REVIEW");return I.Audit()
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


 check("WashParallelPairLaunch",CFrame.new(3105,3.2,97),Vector3.new(10.58,6.4,40.94))
 for i,p in ipairs({{3104,30},{3156,30},{3104,56},{3156,56},{3144,84},{3116,84}}) do
  check("SalesCarPosition_"..i,CFrame.new(p[1],4.1,p[2]),Vector3.new(10.58,6.4,18.94))
 end
 -- Existing elevated display bodies fit this reserved volume; final meshes need individual certification.
 for _,z in ipairs({30,56}) do
  check("ElevatedDisplayBody",CFrame.new(3130,12.5,z),Vector3.new(10.9,3.6,17.9))
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
    if v.X<3090 or v.X>3169 or v.Z<7 or v.Z>101 or v.Y>15.7 then outside=true end
   end end end
   if outside then table.insert(issues,"SalesFootprintOrRoof: "..m:GetFullName()) end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/ground checks must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase5BSalesStatus","ACCEPTED");return a
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

