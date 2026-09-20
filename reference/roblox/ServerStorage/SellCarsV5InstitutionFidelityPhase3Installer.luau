--!nocheck
-- Rear support only; accepted shell lines and other phases remain recoverable.
local I={Version="2026-09-06.phase3.2"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local NAME="02_Rear_Support"
local function root() return assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5")) end
local function layer() return root()["10_Institution_Fidelity_R1"]:FindFirstChild(NAME) end
local function model(parent,name,fn,role,first,ancestor)
 local m=Instance.new("Model");m.Name=name;m.Parent=parent
 for k,v in pairs({BundleId="Institution."..fn.."."..name..".FidelityR1",FunctionId=fn,ZoneId=fn,FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Color=col or C.Steel;p.Material=mat or M;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true
 p.TopSurface=0;p.BottomSurface=0;p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase3Geometry",true);p.Parent=m;return p
end
local function cyl(m,n,x,y,z,length,diam,col,axis,solid)
 local r=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
 local p=box(m,n,x,y,z,length,diam,diam,col,M,solid,r);p.Shape=Enum.PartType.Cylinder;return p
end
local function anchor(m,n,x,z)
 local p=box(m,n,x,.65,z,.12,.12,.12,C.Green,P,false);p.Transparency=1;p.CanQuery=false;p:SetAttribute("AnchorKind","OPERATOR")
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=p;m:SetAttribute("InteractionAnchor",n);return p
end
local function light(m,x,z,length)
 local p=box(m,"ShieldedWorkLight",x,12.5,z,length,.22,.65,C.WarmWhite,Enum.Material.Neon,false)
 local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Brightness=1.4;l.Range=24;l.Angle=100;l.Color=C.WarmWhite;l.Shadows=false;l.Parent=p
end
local function path(owner,name,points)
 local f=owner:FindFirstChild("98_Access_Paths") or Instance.new("Folder");f.Name="98_Access_Paths";f.Parent=owner
 local p=Instance.new("Folder");p.Name=name;p.Parent=f
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],3.5,v[2]);a.Parent=p end
end
local function localRack(parent,n,fn,x,z,rot,ancestor)
 local m=Kit.CreateStorageRack(parent,CFrame.new(x,.55,z)*CFrame.Angles(0,math.rad(rot),0),C.Bronze,"Institution."..fn.."."..n..".FidelityR1");m.Name=n
 for k,v in pairs({FunctionId=fn,ZoneId=fn,Ancestor=ancestor,PhaseMin="WORKING"}) do m:SetAttribute(k,v) end
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p:SetAttribute("Phase3Geometry",true);p:SetAttribute("V5Blocker",p.CanCollide);p.CanQuery=p.Transparency<1;p.CastShadow=p.CanCollide end end
 return m
end
local function sign(m,x,z,label)
 local p=box(m,"SmallDepartmentSign",x,13.7,413.45,16,1.2,.18,C.Navy,M,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(700,90);g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=label;t.Font=Enum.Font.GothamMedium;t.TextColor3=C.WarmWhite;t.TextScaled=true;t.Parent=g
end
local function shell(parent,fn,cx,inner)
 local s=model(parent,"Retained_Shell_And_Low_Annex",fn,"ARCHITECTURE","DEDICATED","Covered workbench -> first support shed -> low campus wing")
 local annex=cx+inner*33;local full=cx+inner*7
 box(s,"OriginalSlab",cx,.35,449,50,.3,46,C.Concrete,Enum.Material.Concrete,true)
 box(s,"AnnexSlab",annex,.35,449,16,.3,46,C.Concrete,Enum.Material.Concrete,true)
 box(s,"CoveredApron",full,.35,417,68,.3,18,C.OldConcrete,Enum.Material.Concrete,true)
 box(s,"RearBrickBase",cx,1.95,472,50,2.9,1,C.Brick,Enum.Material.Brick,true)
 box(s,"RearUpperPanel",cx,10,472,50,13.2,.65,C.Navy,M,true)
 local outer=cx-inner*25;local edge=cx+inner*25
 box(s,"OuterBrickBase",outer,1.95,449,1,2.9,46,C.Brick,Enum.Material.Brick,true)
 box(s,"OuterUpperWall",outer,10,449,.65,13.2,46,C.Navy,M,true)
 box(s,"OriginalInnerWallBase",edge,1.95,453,1,2.9,38,C.Brick,Enum.Material.Brick,true)
 box(s,"OriginalInnerWall",edge,10,453,.65,13.2,38,C.Navy,M,true)
 -- Light industrial liners keep the working rooms readable without changing the navy exterior.
 box(s,"RearInteriorLiner",cx,10,471.58,49,13.1,.08,C.CleanPanel,M,false)
 box(s,"OuterInteriorLiner",outer+inner*.42,10,449,.08,13.1,45,C.Galvanized,M,false)
 box(s,"InnerInteriorLiner",edge-inner*.42,10,453,.08,13.1,37,C.Galvanized,M,false)
 for _,z in ipairs({438,450,462}) do for _,x in ipairs({outer,edge}) do box(s,"ExpressedWallPost",x,9,z,1,15.5,.55,C.Charcoal,M,true) end end
 box(s,"OriginalRoof",cx,17.2,449,52,1,48,C.Navy,M,true)
 for x=cx-24,cx+24,8 do box(s,"RoofSeam",x,17.76,449,.1,.12,46,C.Steel,M,false) end
 box(s,"AnnexRoof",annex,14.2,449,16,.55,46,C.Navy,M,true)
 box(s,"FrontCanopy",full,14.2,420,68,.55,12,C.Navy,M,true)
 for _,x in ipairs({cx-24,cx+24}) do box(s,"OriginalFrontPost",x,6.5,424,1,13,1,C.Charcoal,M,true) end
 local far=cx+inner*40
 for _,z in ipairs({418,438,459,471}) do
  box(s,"AnnexSteelPost",far,7.2,z,.65,13.8,.65,C.Charcoal,M,true)
  box(s,"AnnexBaseShoe",far,.9,z,1.1,.8,1.1,C.Galvanized,M,true)
 end
 box(s,"CanopyFascia",full,13.7,414,68,1,.25,C.Bronze,M,false)
 cyl(s,"FrontGutter",full,13.7,413.7,67,.35,C.Galvanized,"X")
 for _,x in ipairs({cx-inner*24,cx+inner*39}) do cyl(s,"Downpipe",x,7,414,13.1,.3,C.Galvanized,"Y") end
 box(s,"AnnexRearScreen",annex,6.9,472,16,12.6,.5,C.Navy,M,true)
 light(s,cx,440,22);light(s,cx,461,22);light(s,annex,449,10)
 sign(s,cx,423.3,fn=="Parts_Logistics" and "PARTS / RECEIVING" or "SERVICE OPERATIONS")
 return s
end
local function bench(m,x,z,w)
 box(m,"Worktop",x,4.35,z,w,.4,5,C.Timber,Enum.Material.WoodPlanks,true)
 for _,dx in ipairs({-w/2+.5,w/2-.5}) do box(m,"FrameLeg",x+dx,2.5,z,.55,3.6,4.6,C.Charcoal,M,true) end
 box(m,"LowerShelf",x,1,z,w-.8,.25,4.4,C.Galvanized,M,false)
end
local function pallet(m,x,z,loaded)
 for _,dx in ipairs({-2.7,0,2.7}) do box(m,"PalletRunner",x+dx,.9,z,.65,.6,5,C.Timber,Enum.Material.Wood,false) end
 for i=-2,2 do box(m,"PalletSlat",x,1.3,z+i,6.8,.2,.75,C.Timber,Enum.Material.Wood,false) end
 if loaded then
  box(m,"StrappedCrate",x,2.9,z,5.8,3,4.5,C.OldConcrete,Enum.Material.WoodPlanks,true)
  for _,dx in ipairs({-1.7,1.7}) do box(m,"SteelStrap",x+dx,4.45,z,.2,.08,4.6,C.Charcoal,M,false) end
 end
end
local function logistics(owner)
 local fn="Parts_Logistics";local d=model(owner,fn,fn,"ARCHITECTURE","WORKING","Parts crate beside first workbench")
 d:SetAttribute("TemporaryVehicleCapacity",1);d:SetAttribute("PublicAccess",false);shell(d,fn,3032,1)
 local receive=model(d,"Covered_Receiving_And_Pallet_Jack",fn,"HERO","DEDICATED","Manual unloading -> covered receiving")
 box(receive,"ReceivingRollerFrame",3045,2.8,421,17,.45,5.5,C.Charcoal,M,true)
 for i=0,8 do cyl(receive,"Roller",3037.5+i*1.85,3.13,421,5,.4,C.Galvanized,"Z") end
 for _,x in ipairs({3038,3052}) do for _,z in ipairs({419,423}) do box(receive,"ConveyorLeg",x,1.7,z,.45,2.4,.45,C.Charcoal,M,true) end end
 pallet(receive,3016,421,true)
 for _,dx in ipairs({-1.6,1.6}) do box(receive,"PalletJackFork",3018+dx,1,429,1,.35,6,C.Amber,M,false);cyl(receive,"ForkWheel",3018+dx,.8,427,.55,.55,C.Rubber,"X") end
 box(receive,"JackHydraulicBody",3018,1.7,432,3.8,1.8,1.1,C.Amber,M,true)
 cyl(receive,"SteeringWheel",3018,.9,432,1.3,1.1,C.Rubber,"X")
 box(receive,"JackTiller",3018,3.5,432.5,.35,3.5,.35,C.Charcoal,M,false,CFrame.Angles(math.rad(-12),0,0))
 box(receive,"TillerGrip",3018,5.2,433,2,.3,.3,C.Rubber,M,false)
 anchor(receive,"ReceivingOperator",3032,425)
 path(owner,"PartsEntryAndReceiving",{{3024,397},{3024,419},{3032,419},{3032,425}})
 localRack(d,"Service_Parts_Stock",fn,3014,440,-90,"Portable parts bins -> organized stock")
 path(owner,"PartsPicking",{{3032,425},{3032,440},{3018,440}})
 localRack(d,"Restoration_Consumables",fn,3014,463,-90,"Replacement panels and boxed consumables")
 path(owner,"ConsumablesPicking",{{3032,440},{3032,454},{3018,454},{3018,463}})
 local tyres=model(d,"Tyre_And_Panel_Store",fn,"SUPPORT","DEDICATED","Loose tyres/panels -> protected storage")
 for _,z in ipairs({446,452}) do box(tyres,"TyreRackPost",3013,4,z,.45,7,.45,C.Charcoal,M,true) end
 for _,y in ipairs({1.6,5}) do
  box(tyres,"TyreShelf",3013,y,449,5,.3,6.5,C.Steel,M,true)
  for _,z in ipairs({447,449,451}) do cyl(tyres,"StoredTyre",3013,y+1.55,z,1.2,2.8,C.Rubber,"Z");cyl(tyres,"WheelCentre",3013,y+1.55,z-.64,.08,1.6,C.Galvanized,"Z") end
 end
 box(tyres,"PanelCradle",3023,1,463,4,.45,11,C.Charcoal,M,true)
 for _,dx in ipairs({-1.4,1.4}) do
  box(tyres,"PaddedPanelRail",3023+dx,3.7,463,.4,5.5,10,C.Rubber,M,true,CFrame.Angles(0,0,math.rad(dx*12)))
  box(tyres,"ReplacementHood",3023+dx,4.3,460,.25,5.5,4.8,C.Galvanized,M,false,CFrame.Angles(0,0,math.rad(dx*12)))
  box(tyres,"ReplacementDoor",3023+dx,4,466,.25,4.9,4.1,C.OldConcrete,M,false,CFrame.Angles(0,0,math.rad(dx*12)))
 end
 anchor(tyres,"PanelPicker",3026,454);path(owner,"PanelApproach",{{3032,450},{3026,450},{3026,454}})
 local kit=model(d,"Kitting_Packing_And_Dispatch",fn,"HERO","DEDICATED","One parts shelf -> prepared job kits")
 bench(kit,3046,437,14)
 for _,x in ipairs({3042,3047}) do
  box(kit,"OpenKitTray",x,4.7,437,3.5,.2,3.5,C.Navy,M,false)
  for _,dz in ipairs({-1.65,1.65}) do box(kit,"TrayRim",x,5,437+dz,3.5,.5,.15,C.Navy,M,false) end
  for i=1,3 do cyl(kit,"FilterElement",x-1+i*.55,5.4,437,.8,.4,C.WarmWhite,"Y") end
 end
 box(kit,"LabelPrinter",3051,5,437,2,1.1,2.2,C.Charcoal,M,false)
 box(kit,"PrintedJobTicket",3051,4.6,435.6,1.4,.04,1.2,C.WarmWhite,P,false)
 box(kit,"ScannerCradle",3039.7,4.8,437,.8,.6,1.3,C.Charcoal,M,false)
 anchor(kit,"KittingOperator",3046,442);path(owner,"KittingApproach",{{3032,425},{3032,442},{3046,442}})
 local rare=model(d,"Rare_Parts_Control",fn,"HERO","PROFESSIONAL","Locked cupboard -> secure rare-parts room")
 for _,x in ipairs({3038,3054}) do
  for _,z in ipairs({456,472}) do box(rare,"CagePost",x,5.5,z,.35,10,.35,C.Steel,M,true) end
  for _,y in ipairs({.7,10.3}) do box(rare,"CageRail",x,y,464,.35,.35,16,C.Steel,M,true) end
  for z=457,471,2 do box(rare,"CageBar",x,5.5,z,.12,9.5,.12,C.Galvanized,M,true) end
 end
 for _,x in ipairs({3040,3052}) do
  for _,dx in ipairs({-2,-.7,.7,2}) do box(rare,"EntryBar",x+dx,5.5,456,.2,10,.25,C.Steel,M,true) end
  box(rare,"EntryLowerRail",x,.7,456,4,.3,.3,C.Steel,M,true)
 end
 box(rare,"CageHeader",3046,10.4,456,16,.35,.3,C.Steel,M,true)
 box(rare,"OpenGateLeaf",3053.6,5.4,459,.2,9.8,5.4,C.Galvanized,M,true)
 box(rare,"CredentialReader",3049.9,5,455.7,.55,1,.3,C.Charcoal,M,false)
 bench(rare,3046,469,13)
 for _,x in ipairs({3043,3049}) do
  box(rare,"FoamCradle",x,4.8,469,4,.55,3.5,C.Rubber,M,false)
  cyl(rare,"PrecisionRim",x,6,469,.9,3.6,C.Galvanized,"Z");cyl(rare,"RimRecess",x,6,468.48,.12,3.15,C.Charcoal,"Z")
  for i=0,4 do local a=i*math.pi*2/5
   box(rare,"AlloySpoke",x+math.sin(a)*.73,6+math.cos(a)*.73,468.37,.25,1.5,.12,C.Galvanized,M,false,CFrame.Angles(0,0,-a))
  end
  cyl(rare,"CentreCap",x,6,468.24,.15,.6,C.Galvanized,"Z")
 end
 anchor(rare,"RarePartsCustodian",3046,463);path(owner,"RarePartsAccess",{{3032,450},{3046,450},{3046,463}})
 local returns=model(d,"Returns_Quarantine",fn,"SUPPORT","DEDICATED","Unsorted returns -> controlled quarantine")
 pallet(returns,3064,466,true)
 for _,x in ipairs({3061.5,3066.5}) do box(returns,"ReturnCrateGuard",x,2.6,466,.15,3.2,4.6,C.Amber,M,false) end
 anchor(returns,"ReturnsCheck",3064,461)
 local dispatch=localRack(d,"Outbound_Job_Kits",fn,3060,443,-90,"Hand-carried loose parts -> per-job kit shelf")
 anchor(dispatch,"DispatchPicker",3065,443)
 path(owner,"AnnexDispatchAndReturns",{{3032,425},{3032,430},{3065,430},{3065,443},{3069,443},{3069,461},{3064,461}})
 return d
end
local function chair(m,x,z,rot)
 local c=CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(rot or 0),0)
 local function p(n,dx,y,dz,w,h,d,col,mat,solid)
  local v=c:PointToWorldSpace(Vector3.new(dx,y,dz));return box(m,n,v.X,v.Y,v.Z,w,h,d,col,mat,solid,c.Rotation)
 end
 p("UpholsteredSeat",0,2,0,2.8,.55,2.7,C.Charcoal,Enum.Material.Fabric,true)
 p("ChairBack",0,3.5,1.1,2.8,2.5,.35,C.Navy,Enum.Material.Fabric,true)
 for _,dx in ipairs({-1,1}) do for _,dz in ipairs({-.9,.9}) do p("ChairLeg",dx,1.1,dz,.17,1.6,.17,C.Steel,M,false) end end
end
local function desk(m,x,z,w)
 box(m,"DeskTop",x,3.6,z,w,.35,4.5,C.Timber,Enum.Material.WoodPlanks,true)
 for _,dx in ipairs({-w/2+.7,w/2-.7}) do box(m,"Pedestal",x+dx,2.1,z,1.1,2.8,3.8,C.Navy,M,true) end
 box(m,"MonitorFoot",x,3.87,z-.7,1.8,.12,1,C.Charcoal,M,false)
 box(m,"MonitorStem",x,4.3,z-1,.18,.8,.18,C.Steel,M,false)
 box(m,"MonitorBody",x,5,z-1,3.2,1.7,.2,C.Charcoal,M,false)
 box(m,"Screen",x,5,z-.86,2.9,1.4,.05,C.Glass,P,false)
 box(m,"Keyboard",x,3.86,z+.9,2.5,.12,.75,C.Charcoal,P,false)
 box(m,"Phone",x+w/2-1.4,3.97,z,.85,.35,1.5,C.Navy,P,false)
 chair(m,x,z+4,0)
end
local function partition(m,a,b,z,door)
 for _,bounds in ipairs({{a,door-3.5},{door+3.5,b}}) do
  local mid=(bounds[1]+bounds[2])/2;local w=bounds[2]-bounds[1]
  box(m,"PartitionSill",mid,1.35,z,w,1.6,.35,C.Navy,M,true)
  local g=box(m,"OfficeGlass",mid,6,z,w,7.7,.14,C.Glass,Enum.Material.Glass,false);g.Transparency=.7
  for _,x in ipairs(bounds) do box(m,"PartitionMullion",x,5.3,z,.2,9.7,.25,C.Charcoal,M,true) end
 end
 box(m,"OpenDoorHeader",door,10.1,z,7,.3,.3,C.Charcoal,M,true)
end
local function operations(owner)
 local fn="Staff_Operations";local d=model(owner,fn,fn,"ARCHITECTURE","WORKING","First ledger desk -> staffed operations")
 d:SetAttribute("VehicleCapacity",0);shell(d,fn,3228,-1)
 local room=model(d,"Office_Rooms_And_Circulation",fn,"ARCHITECTURE","DEDICATED","Open desk corner -> separate staff rooms")
 partition(room,3204,3224,446,3214);partition(room,3232,3252,446,3241)
 partition(room,3204,3224,454,3214);partition(room,3232,3252,454,3241)
 box(room,"SupervisorSideSill",3232,1.5,431,.3,2,10,C.Navy,M,true)
 local g=box(room,"SupervisorObservationGlass",3232,6.1,431,.14,7.2,10,C.Glass,Enum.Material.Glass,false);g.Transparency=.7
 path(owner,"OperationsEntryAndHall",{{3228,397},{3228,420},{3228,450},{3228,468}})
 local dispatch=model(d,"Dispatch_ServiceWriter_And_Radio",fn,"HERO","WORKING","Notebook and telephone -> coordinated job dispatch")
 desk(dispatch,3210,433,7);desk(dispatch,3219,433,7)
 box(dispatch,"SuspendedDispatchBoard",3214,9.8,445.75,15,5.2,.12,C.Navy,M,false)
 for _,x in ipairs({3207,3221}) do box(dispatch,"BoardSuspension",x,14.5,445.75,.12,4.2,.12,C.Steel,M,false) end
 for i=0,2 do
  box(dispatch,"JobBoardRail",3214,8+i*1.5,445.55,15,.12,.18,C.Galvanized,M,false)
  for j=0,3 do box(dispatch,"WorkCard",3208.5+j*3.5,8.6+i*1.5,445.35,2.3,.85,.07,({C.WarmWhite,C.OldConcrete,C.Bronze})[i+1],P,false) end
 end
 box(dispatch,"RadioRack",3205,4,440,2.2,6,3.5,C.Charcoal,M,true)
 for y=2,6,1 do box(dispatch,"RadioUnit",3206.15,y,440,.12,.65,2.9,C.Steel,M,false);cyl(dispatch,"RadioDial",3206.27,y,439,.15,.22,C.WarmWhite,"X") end
 anchor(dispatch,"DispatchOperatorApproach",3219,441);path(owner,"DispatchAccess",{{3228,420},{3228,441},{3219,441}})
 local supervisor=model(d,"Supervisor_And_CCTV",fn,"HERO","DEDICATED","Shared office desk -> service supervision")
 desk(supervisor,3241,433,11)
 for _,z in ipairs({438,442}) do for _,y in ipairs({5,7.7}) do
  box(supervisor,"CCTVFrame",3251.5,y,z,.3,2.3,3.6,C.Charcoal,M,false)
  box(supervisor,"CCTVScreen",3251.3,y,z,.07,1.9,3.2,C.Glass,P,false)
  box(supervisor,"CameraDiagram",3251.22,y,z,.03,.1,2,C.WarmWhite,P,false)
 end end
 box(supervisor,"DocumentCabinet",3248,3,430,4,4.8,3,C.OldConcrete,M,true)
 for y=1.6,4.5,1.2 do box(supervisor,"FileDrawerPull",3248,y,431.56,1.5,.12,.16,C.Stainless,M,false) end
 anchor(supervisor,"SupervisorApproach",3241,441);path(owner,"SupervisorAccess",{{3228,420},{3228,441},{3241,441}})
 local training=model(d,"Training_And_Standards",fn,"SUPPORT","PROFESSIONAL","Shift briefing -> dedicated training corner")
 box(training,"MeetingTable",3214,3.6,462,11,.35,5,C.Timber,Enum.Material.WoodPlanks,true)
 for _,x in ipairs({3210,3218}) do box(training,"TableTrestle",x,2.1,462,.5,2.8,4.2,C.Charcoal,M,true) end
 for _,x in ipairs({3210,3218}) do chair(training,x,457,180);chair(training,x,467,0) end
 box(training,"TrainingWhiteboard",3214,7.3,471.4,15,6,.2,C.WarmWhite,P,false)
 for i=1,3 do box(training,"WorkshopDiagram",3214,5.8+i,471.25,9-i*1.8,.13,.05,C.Navy,P,false) end
 for _,x in ipairs({3210,3214,3218}) do box(training,"TrainingManual",x,3.88,462,1.5,.2,2,C.Navy,P,false) end
 anchor(training,"TrainingApproach",3222,460);path(owner,"TrainingAccess",{{3228,450},{3228,460},{3222,460}})
 local staff=model(d,"Lockers_Changing_And_Break",fn,"SUPPORT","DEDICATED","Spare chair and coat hooks -> staffed facilities")
 for i=0,3 do
  local z=456.5+i*3.5
  box(staff,"LockerCabinet",3250,4,z,3.2,6.8,3.1,C.Navy,M,true)
  box(staff,"LockerInset",3248.34,4,z,.12,6.3,2.75,C.Galvanized,M,false)
  box(staff,"LockerLatch",3248.22,4,z-1,.16,.6,.15,C.Charcoal,M,false)
  for y=5.8,6.5,.3 do box(staff,"LockerVent",3248.22,y,z,.08,.1,1.6,C.Charcoal,M,false) end
 end
 box(staff,"ChangingBench",3244,2,461,2.5,.4,10,C.Timber,Enum.Material.WoodPlanks,true)
 for _,z in ipairs({457,465}) do box(staff,"BenchTrestle",3244,1.15,z,2,.9,.35,C.Charcoal,M,true) end
 bench(staff,3237,469,7)
 box(staff,"CoffeeMachine",3237,5.3,469,2.1,1.8,1.7,C.Charcoal,M,false)
 cyl(staff,"Mug",3235,4.9,469,.7,.6,C.WarmWhite,"Y")
 box(staff,"WaterCooler",3234,2.8,456,2.6,4.5,2.6,C.CleanPanel,M,true)
 cyl(staff,"WaterBottle",3234,5.8,456,1.7,1.7,C.Glass,"Y")
 anchor(staff,"StaffRoomApproach",3240,461);path(owner,"StaffRoomAccess",{{3228,450},{3240,450},{3240,461}})
 local utilities=model(d,"Utilities_And_Maintenance_Annex",fn,"UTILITY","DEDICATED","Portable service tools -> fitted campus utilities")
 for _,z in ipairs({441,449,457}) do
  box(utilities,"UtilityEnclosure",3189.5,4,z,3,6.6,5,C.Galvanized,M,true)
  box(utilities,"ServiceDoor",3191.1,4,z,.15,5.8,4.4,C.Navy,M,false)
  box(utilities,"DoorLatch",3191.25,4,z+1.4,.15,.8,.15,C.Stainless,M,false)
  for y=5,6.4,.35 do box(utilities,"IntakeLouvre",3191.24,y,z,.12,.13,2.8,C.Charcoal,M,false) end
 end
 box(utilities,"CableTray",3189.5,10.5,449,1,.5,24,C.Steel,M,false)
 for _,z in ipairs({441,449,457}) do cyl(utilities,"PowerConduit",3189.5,8.3,z,4.1,.2,C.Galvanized,"Y") end
 anchor(utilities,"MaintenanceOperator",3195,449);path(owner,"UtilityAccess",{{3228,420},{3228,428},{3195,428},{3195,466}})
 local porch=model(d,"Low_Observation_And_Shift_Briefing",fn,"STORY","WORKING","Outside briefing bench -> covered service overlook")
 box(porch,"StandingReviewCounter",3195,3.8,420,11,.35,2.5,C.Timber,Enum.Material.WoodPlanks,true)
 for _,x in ipairs({3191,3199}) do box(porch,"CounterLeg",x,2.2,420,.4,2.9,2,C.Charcoal,M,true) end
 box(porch,"ShiftClipboard",3195,4.1,420,2,.15,1.5,C.WarmWhite,P,false)
 anchor(porch,"ObservationApproach",3195,424);path(owner,"ObservationAccess",{{3228,420},{3228,428},{3195,428},{3195,424}})
 return d
end
local function suppress(owner,target)
 local rs=owner:FindFirstChild("90_Restoration") or Instance.new("Folder");rs.Name="90_Restoration";rs.Parent=owner
 for _,o in ipairs(target:GetDescendants()) do
  if o:IsA("BasePart") or o:IsA("Light") or o:IsA("SurfaceGui") or o:IsA("BillboardGui") then
   local r=Instance.new("ObjectValue");r.Value=o;r.Name="Saved_"..o.Name;r.Parent=rs
   if o:IsA("BasePart") then
    for _,k in ipairs({"Transparency","CanCollide","CanTouch","CanQuery","CastShadow"}) do r:SetAttribute(k,o[k]) end
    o.Transparency=1;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
   else r:SetAttribute("Enabled",o.Enabled);o.Enabled=false end
  end
 end
end
local function signature(l)
 local rows={};for _,p in ipairs(l:GetDescendants()) do if p:IsA("BasePart") then
  local a={};for _,v in ipairs({p.CFrame:GetComponents()}) do table.insert(a,string.format("%.3f",v)) end
  table.insert(rows,p:GetFullName().."|"..table.concat(a,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.Transparency))
 end end;table.sort(rows);local h=5381;for _,s in ipairs(rows) do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
function I.Uninstall()
 local l=layer()
 if l then local rs=l:FindFirstChild("90_Restoration")
  if rs then for _,r in ipairs(rs:GetChildren()) do if r.Value then for k,v in pairs(r:GetAttributes()) do r.Value[k]=v end end end end
  l:Destroy()
 end
 root():SetAttribute("InstitutionFidelityPhase3Status",nil);return true
end
function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase2Status")=="ACCEPTED","Phase 2 must be accepted")
 I.Uninstall();local l=Instance.new("Model");l.Name=NAME;l.Parent=root()["10_Institution_Fidelity_R1"];l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local b=root()["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]
  suppress(l,b["04_Parts_Logistics"]);suppress(l,b["05_Staff_Operations"])
  logistics(l);operations(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase3Status","BUILT_AWAITING_REVIEW");return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,metadata,ids={},{},{}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function check(name,cf,size)
  for _,p in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
   if p.Transparency<.98 and p.Position.Y+p.Size.Y/2>.8 then table.insert(issues,name..": "..p:GetFullName()) end
  end
 end
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size) end end
 for _,p in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4,0),Vector3.new(p.Size.X,7,p.Size.Z)) end end
 check("CentralHeroVoid",CFrame.new(3130,10,422),Vector3.new(96,20,105))
 -- Pedestrian approaches are tested against the whole active V5 scene, including retained work.
 params.FilterDescendantsInstances={root()}
 local count=0
 for _,p in ipairs(l["98_Access_Paths"]:GetChildren()) do
  count+=1;local points=p:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value;check(p.Name,CFrame.lookAt((a+b)/2,b),Vector3.new(3,5.5,(b-a).Magnitude+1)) end
 end
 local stats={parts=0,solids=0,lights=0,models=0,accessPaths=count,anchorApproaches=0,functions={}}
 for _,m in ipairs(l:GetDescendants()) do
  if m:IsA("Model") then
   stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","InheritanceRule","Ancestor","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"}) do if m:GetAttribute(k)==nil then table.insert(metadata,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(metadata,"Duplicate: "..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do local n=m:GetAttribute(k);if n and n~="" and not m:FindFirstChild(n,true) then table.insert(metadata,m.Name..": unresolved "..n) end end
   local n=m:GetAttribute("InteractionAnchor");local a=n and n~="" and m:FindFirstChild(n,true)
   if a and a:IsA("BasePart") then
    stats.anchorApproaches+=1;check(m.Name.."_OperatorStandingSpace",CFrame.new(a.Position.X,3.5,a.Position.Z),Vector3.new(3,5.5,3))
   end
  elseif m:IsA("BasePart") then stats.parts+=1;if m.CanCollide then stats.solids+=1 end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 for _,fn in ipairs({"Parts_Logistics","Staff_Operations"}) do
  local n=0;local xmin,xmax=fn=="Parts_Logistics" and 3005 or 3187,fn=="Parts_Logistics" and 3073 or 3255
  for _,p in ipairs(l[fn]:GetDescendants()) do if p:IsA("BasePart") then
   n+=1
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
    local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(sx,sy,sz)/2)
    if v.X<xmin-.01 or v.X>xmax+.01 or v.Z<407.99 or v.Z>476.01 then table.insert(issues,"WingReservation: "..p:GetFullName());break end
   end end end
  end end;stats.functions[fn]=n
 end
 stats.issues=issues;stats.metadataIssues=metadata;stats.signature=signature(l);return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0,"Audit must pass")
 assert(e.VisualPass and e.RoutePass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase3Status","ACCEPTED");return a
end
return I

