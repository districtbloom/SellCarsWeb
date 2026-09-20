--!nocheck
-- Phase 6B2 owns HQ art only; accepted circulation and other districts are read-only.
local I={Version="2026-09-07.phase6b2.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","05_Prestige_And_Public_Realm","03_HQ_Art"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.HQ_Art."..n..".FidelityR1",FunctionId="HQ_Art",ZoneId="HQ_Art",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase6B2HQGeometry",true);p.Parent=m;return p
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
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],v[2],v[3]);a.Parent=p end
end




local function textFace(p,words,face)
 local g=Instance.new("SurfaceGui");g.Name="Face";g.Face=face or Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=35;g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=words;t.TextColor3=C.WarmWhite;t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=g
end
local function light(m,n,x,y,z,w,range,brightness)
 local p=box(m,n,x,y,z,w,.16,.6,C.WarmWhite,Enum.Material.Neon,false)
 local a=Instance.new("SurfaceLight");a.Name="TaskIllumination";a.Face=Enum.NormalId.Bottom;a.Angle=110;a.Range=range;a.Brightness=brightness;a.Shadows=false;a.Color=C.WarmWhite;a.Parent=p
 return p
end
local function desk(m,n,x,y,z,w)
 box(m,n.."TimberTop",x,y+3.4,z,w,.35,4,C.Timber,Enum.Material.Wood,true)
 for _,dx in ipairs({-w/2+.7,w/2-.7}) do
  box(m,n.."Trestle",x+dx,y+1.65,z,.35,3.3,3.5,C.Charcoal,M,true)
  box(m,n.."Foot",x+dx,y+.16,z,1.5,.3,3.8,C.Steel,M,false)
 end
 box(m,n.."CableTray",x,y+2.9,z-.6,w-2,.24,.7,C.Steel,M,false)
 local mx=x+(w>12 and 4 or 0)
 box(m,n.."MonitorFoot",mx,y+3.63,z-.7,2,.14,1.2,C.Charcoal,M,false)
 box(m,n.."MonitorStem",mx,y+4.3,z-1,.25,1.4,.25,C.Steel,M,false)
 local monitor=box(m,n.."Monitor",mx,y+5.1,z-1,3.8,2.25,.24,C.Charcoal,P,false)
 local screen=box(m,n.."Screen",mx,y+5.1,z-.86,3.5,1.9,.02,C.Navy,P,false);screen:SetAttribute("DataBinding","PENDING_CAR_WORK_LEDGER")
 for i=1,3 do box(m,n.."InterfaceLine",mx-.25,y+5.65-i*.4,z-.845,2.5-i*.35,.08,.025,i==1 and C.Galvanized or C.Steel,P,false) end
 box(m,n.."Keyboard",mx,y+3.66,z+.85,2.5,.15,.85,C.Steel,P,false)
 box(m,n.."Mouse",mx+1.9,y+3.68,z+.8,.45,.18,.65,C.Charcoal,P,false)
 box(m,n.."DocumentTray",x-w/2+1.5,y+3.65,z,1.8,.16,2.6,C.Galvanized,M,false)
 box(m,n.."PaperStack",x-w/2+1.5,y+3.78,z,1.5,.1,2.3,C.WarmWhite,P,false)
end
local function chair(m,n,x,y,z,yaw)
 local cf=CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
 local function p(k,dx,dy,dz,w,h,d,col,mat,solid)
  local v=cf:PointToWorldSpace(Vector3.new(dx,dy,dz));local a=box(m,n..k,v.X,v.Y,v.Z,w,h,d,col,mat,solid);a.CFrame=cf*CFrame.new(dx,dy,dz);return a
 end
 local upholstery=n=="TaskChair" and C.Steel or C.Timber
 p("Cushion",0,2.1,0,3.1,.55,3,upholstery,Enum.Material.Fabric,true)
 p("Back",0,3.55,1.3,3.1,2.5,.55,upholstery,Enum.Material.Fabric,true)
 if n=="TaskChair" then
  p("GasLift",0,1,0,.35,1.7,.35,C.Stainless,M,false)
  for i=1,5 do local a=i*math.pi*2/5;local dx,dz=math.cos(a),math.sin(a)
   local spoke=p("CastorSpoke",dx*.65,.36,dz*.65,.17,.18,1.4,C.Charcoal,M,false);spoke.CFrame=cf*CFrame.new(dx*.65,.36,dz*.65)*CFrame.Angles(0,math.pi/2-a,0)
   p("Castor",dx*1.3,.25,dz*1.3,.42,.45,.42,C.Rubber,P,false)
  end
 else
  for _,dx in ipairs({-1.15,1.15}) do for _,dz in ipairs({-1.05,1.05}) do p("Leg",dx,.9,dz,.18,1.8,.18,C.Charcoal,M,false) end end
 end
 for _,dx in ipairs({-1.65,1.65}) do p("Arm",dx,2.9,0,.2,.2,2.5,C.Bronze,M,false) end
end
local function cabinet(m,n,x,y,z,w)
 box(m,n.."Body",x,y+2.2,z,w,4.4,2.4,C.Charcoal,M,true)
 box(m,n.."Cap",x,y+4.5,z,w+.15,.2,2.6,C.Timber,Enum.Material.Wood,false)
 local count=math.max(2,math.floor(w/3))
 for i=1,count do local px=x-w/2+(i-.5)*w/count
  box(m,n.."Door",px,y+2.3,z-1.24,w/count-.12,3.9,.12,C.Steel,M,false)
  box(m,n.."Pull",px+w/count/2-.5,y+2.7,z-1.4,.1,.85,.18,C.Stainless,M,false)
 end
end
local function lampRail(m,n,x,y,z,w,ceiling,count)
 box(m,n.."Rail",x,y,z,w,.3,.4,C.Charcoal,M,false)
 for _,dx in ipairs({-w/2+.5,w/2-.5}) do box(m,n.."Drop",x+dx,(ceiling+y)/2,z,.12,ceiling-y,.12,C.Steel,M,false) end
 for i=1,count do light(m,n.."Emitter",x-w/2+(i-.5)*w/count,y-.3,z,2.6,24,1.15) end
end
local function roomFinishes(l)
 local m=group(l,"HQ_Material_And_Ceiling_Kit","ARCHITECTURE","PROFESSIONAL","Repaired office slab and sheet lining -> warm stone, acoustic soffit and crafted joinery")
 local circ=root()["10_Institution_Fidelity_R1"][PHASE]["02_HQ_Circulation"]
 local source=root()["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]["07_Institution_Headquarters"]
 local slabs={source.HQFloor1};for _,p in ipairs(circ.HQ_Cut_Floor_Decks:GetChildren()) do if p:IsA("BasePart") and p:GetAttribute("WalkSurface") then table.insert(slabs,p) end end
 for _,p in slabs do
  local f=box(m,"StoneFloorFinish",p.Position.X,p.Position.Y+p.Size.Y/2+.03,p.Position.Z,p.Size.X-.1,.06,p.Size.Z-.1,C.CleanPanel,Enum.Material.Limestone,false)
  f:SetAttribute("FloorFinish",true)
 end
 -- Linear soffits expose a consistent steel rib rhythm and never bridge the stair apertures.
 for _,v in ipairs({{3141,15.5,479,51,35},{3141,27.75,482,43,29},{3130,55.28,482,60,28}}) do
  box(m,"AcousticSoffit",v[1],v[2],v[3],v[4],.16,v[5],C.WarmWhite,Enum.Material.Plaster,false)
 end
 for x=3105,3155,10 do box(m,"CrownCeilingRib",x,54.7,482,.55,.9,28,C.Timber,Enum.Material.Wood,false) end
 for _,v in ipairs({{3174.35,8,472,1,15,48},{3168.35,22.2,480,1,11.5,35},{3160.35,42,482,.35,25,28}}) do
  box(m,"WarmInnerLining",v[1],v[2],v[3],v[4],v[5],v[6],C.WarmWhite,Enum.Material.Plaster,false)
 end
 for _,v in ipairs({{.76,495.95,90},{16.56,497.3,76},{28.86,496.25,61}}) do
  box(m,"RearTimberDado",3130,v[1]+2.3,v[2],v[3]-.8,4.6,.3,C.Timber,Enum.Material.Wood,false)
 end
end
local function reception(l)
 local m=group(l,"Reception_And_Records","HERO","WORKING","Player's rough office table -> permanent reception, records and material consultation")
 desk(m,"Reception",3130,.76,459,20)
 box(m,"ReceptionStoneFront",3130,2.45,456.92,20,3.3,.35,C.WarmWhite,Enum.Material.Limestone,true)
 for x=3121,3139,2 do box(m,"CounterReed",x,2.3,456.68,.08,2.5,.08,C.Bronze,M,false) end
 cabinet(m,"Records",3130,.76,490,16)
 point(m,"ReceptionOperator",3130,.76,463,"OPERATOR")
 point(m,"ReceptionVisitor",3130,.76,454,"VIEWING")
 local name=box(m,"ReceptionDeskPlate",3137,4.6,458,3.5,.7,.1,C.Charcoal,M,false);textFace(name,"DESERT CUSTOMS",Enum.NormalId.Front)
 lampRail(m,"LobbyTaskRail",3135,13.7,463,28,15.3,2)
 path(l,"ReceptionVisit",{{3130,.76,451},{3130,.76,454}})
 path(l,"ReceptionStaff",{{3130,.76,451},{3143,.76,451},{3143,.76,463},{3130,.76,463}})
 path(l,"RecordsApproach",{{3143,.76,463},{3143,.76,485},{3130,.76,485}})
 point(m,"RecordsOperator",3130,.76,485,"OPERATOR")
end
local function waitingAndMaterials(l)
 local m=group(l,"Consultation_Lounge_And_Materials","SUPPORT","DEDICATED","A pair of visitor chairs and paint chips -> complete project consultation setting")
 for _,x in ipairs({3152,3157,3162}) do chair(m,"Waiting",x,.76,469,0) end
 box(m,"SharedCoffeeTable",3157,2.4,461,11,.3,3,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({3153,3161}) do box(m,"CoffeeTableLeg",x,1.45,461,.3,1.9,2,C.Charcoal,M,false) end
 for i=1,3 do box(m,"FinishCatalogue",3153+i*1.8,2.65,461,1.5,.15,2.2,i==2 and C.Brick or C.CleanPanel,P,false) end
 cabinet(m,"MaterialLibrary",3153,.76,494.5,34)
 for i=1,9 do
  local x=3138+(i-1)*3.6
  box(m,"SampleBack",x,8.3,495.7,3,4.7,.15,C.Charcoal,M,false)
  box(m,"FinishSpecimen",x,8.3,495.56,2.6,4.3,.15,({C.Brick,C.Steel,C.Cyan,C.CleanPanel,C.Timber,C.Bronze,C.Navy,C.Red,C.WarmWhite})[i],i==5 and Enum.Material.Wood or M,false)
 end
 point(m,"WaitingVisitor",3157,.76,465,"VIEWING")
 point(m,"MaterialConsultation",3153,.76,490,"OPERATOR")
 path(l,"WaitingApproach",{{3143,.76,463},{3147,.76,465},{3157,.76,465}})
 path(l,"MaterialLibraryApproach",{{3143,.76,463},{3143,.76,487},{3153,.76,487},{3153,.76,490}})
 lampRail(m,"MaterialLight",3153,13.7,490,26,15.3,1)
end
local function toolCraft(l)
 local m=group(l,"Founding_Craft_Specimens","STORY","BIRTH","Hand tools at the first workbench -> preserved craft specimens, pending actual player-history binding")
 box(m,"ReclaimedBench",3090,3.7,479,4.8,.5,11,C.Timber,Enum.Material.Wood,true)
 for _,z in ipairs({475,483}) do box(m,"BenchTrestle",3090,2.25,z,4,.35,.55,C.Steel,M,false);for _,x in ipairs({3088.2,3091.8}) do box(m,"BenchLeg",x,2.05,z,.3,3.3,.3,C.Charcoal,M,true) end end
 box(m,"PanelFormerBase",3090,4.15,477,2.2,.4,2.5,C.Steel,M,false)
 box(m,"SmallAnvil",3090,4.9,477,2.8,1.1,1,C.Steel,M,false)
 box(m,"HammerHandle",3089.5,4.1,481,.2,.2,2.4,C.Timber,Enum.Material.Wood,false)
 box(m,"HammerHead",3089.5,4.35,480,.9,.6,.6,C.Steel,M,false)
 local sample=box(m,"FormedPanelSpecimen",3091,5.7,482,.2,2.8,2.2,C.Bronze,M,false,CFrame.Angles(0,0,math.rad(12)));sample:SetAttribute("HistoryBinding","PENDING_PLAYER_RECORD")
 point(m,"CraftViewing",3096,.76,479,"VIEWING")
 path(l,"CraftViewingApproach",{{3104,.76,451},{3096,.76,451},{3096,.76,479}})
end
local function operations(l)
 local m=group(l,"HQ_Analytics_And_Management","HERO","PROFESSIONAL","Paper bookkeeping -> coordinated financial and production-quality desks")
 for _,x in ipairs({3126,3153}) do
  desk(m,"Analytics",x,16.56,478,10);chair(m,"TaskChair",x,16.56,486,0)
  point(m,"Analyst_"..x,x,16.56,482,"OPERATOR")
  path(l,"AnalystApproach_"..x,{{3130,16.56,460},{3140,16.56,460},{3140,16.56,482},{x,16.56,482}})
 end
 cabinet(m,"OfficeArchive",3128,16.56,495.5,17)
 box(m,"JobBoardFrame",3152,22.4,497.05,23,7,.22,C.Bronze,M,false)
 local board=box(m,"JobBoard",3152,22.4,496.89,22.5,6.5,.12,C.Charcoal,P,false);board:SetAttribute("DataBinding","PENDING_CAR_WORK_LEDGER")
 for i=1,5 do local x=3143+(i-1)*4.5
  box(m,"BoardColumn",x,22.4,496.78,.06,5.8,.02,C.Steel,M,false)
  for j=1,2 do box(m,"BlankJobCard",x+1.5,23.8-j*1.5,496.7,2.5,.8,.06,C.CleanPanel,P,false) end
 end
 point(m,"ManagerBoard",3152,16.56,491,"OPERATOR")
 path(l,"ManagementApproach",{{3140,16.56,482},{3140,16.56,491},{3152,16.56,491}})
 lampRail(m,"OfficeLight",3140,26.6,480,34,27.65,2)
end
local function crown(l)
 local m=group(l,"Crown_Project_Room","HERO","INSTITUTION","Small owner/manager review desk -> tall project-review room overlooking the legacy gallery")
 box(m,"MeetingSlab",3127,32.45,481,12,.5,6,C.Timber,Enum.Material.Wood,true)
 for _,x in ipairs({3123,3131}) do box(m,"MeetingTrestle",x,30.45,481,.45,3.1,5,C.Charcoal,M,true) end
 for _,x in ipairs({3123,3131}) do chair(m,"MeetingChair",x,28.86,475,180);chair(m,"MeetingChair",x,28.86,487,0) end
 for _,x in ipairs({3124,3130}) do box(m,"ProjectPortfolio",x,32.8,481,2,.14,2.8,C.Charcoal,P,false);box(m,"SamplePage",x,32.9,481,1.8,.06,2.5,C.WarmWhite,P,false) end
 point(m,"ProjectReview",3137,28.86,481,"OPERATOR")
 path(l,"ProjectReviewApproach",{{3140,28.86,473},{3140,28.86,481},{3137,28.86,481}})
 local s=group(l,"Crown_Hospitality_And_Craft","SUPPORT","PROFESSIONAL","Break-room tray and remembered repair work -> restrained hospitality and craft archive")
 cabinet(s,"Hospitality",3153,28.86,493.5,10)
 box(s,"CoffeeMachine",3154,34.2,493.5,2.2,1.8,1.8,C.Stainless,M,false)
 box(s,"CoffeeFace",3154,34.2,492.53,1.8,1.4,.15,C.Charcoal,P,false)
 box(s,"CupTray",3151,33.65,493.5,2.8,.12,1.8,C.Steel,M,false)
 for i=1,3 do cyl(s,"Cup",3149.8+i*.65,34,493.5,.6,.42,C.WarmWhite,"Y",false) end
 box(s,"DripTray",3154,33.4,492.5,1.9,.12,.9,C.Steel,M,false)
 for _,x in ipairs({3153.6,3154.4}) do cyl(s,"CoffeeDial",x,34.65,492.4,.1,.24,C.Bronze,"Z",false);box(s,"CoffeeSpout",x,33.95,492.32,.13,.35,.24,C.Stainless,M,false) end
 local reservoir=box(s,"WaterReservoir",3155.3,34.2,493.6,.4,1.7,1.5,C.Galvanized,Enum.Material.Glass,false);reservoir.Transparency=.5
 point(s,"HospitalityOperator",3153,28.86,489,"OPERATOR")
 path(l,"HospitalityApproach",{{3140,28.86,487},{3146,28.86,489},{3153,28.86,489}})
 box(s,"CraftWallBacking",3128,40.5,496.1,28,20,.22,C.Timber,Enum.Material.Wood,false)
 for _,x in ipairs({3119,3128,3137}) do
  box(s,"ArchiveFrame",x,37,495.87,7,8,.3,C.Bronze,M,false)
  box(s,"ArchiveBacking",x,37,495.65,6.6,7.6,.16,C.Charcoal,P,false)
  if x==3119 then
   for i=-1,1 do box(s,"HandFormedPanel",x+i*1.3,37,495.25-math.abs(i)*.15,1.4,3.5,.2,C.Stainless,M,false,CFrame.Angles(0,math.rad(i*18),0)) end
   box(s,"FoldedPanelFlange",x,35.2,495.1,4.1,.22,.6,C.Steel,M,false)
  elseif x==3128 then
   for i=1,3 do box(s,"RepairProcessCoupon",x+(i-2)*1.6,37,495.3,1.45,3.5,.2,({C.Brick,C.Steel,C.CleanPanel})[i],i==1 and Enum.Material.CorrodedMetal or M,false) end
   for i=1,5 do cyl(s,"WeldBead",x+.78,35.8+i*.43,495.14,.12,.2,C.Bronze,"Z",false) end
  else
   cyl(s,"WheelSectionOuter",x,37,495.3,.35,4.5,C.Stainless,"Z",false)
   cyl(s,"WheelSectionRecess",x,37,495.04,.16,3.85,C.Charcoal,"Z",false)
   for i=1,5 do local a=i*math.pi*2/5;box(s,"ForgedSpoke",x+math.cos(a)*1.1,37+math.sin(a)*1.1,494.89,2.2,.26,.15,C.Stainless,M,false,CFrame.Angles(0,0,a)) end
   cyl(s,"WheelHub",x,37,494.72,.2,.9,C.Bronze,"Z",false)
  end
 end
 point(s,"CrownArchiveViewing",3128,28.86,491.5,"VIEWING")
 path(l,"CrownArchiveApproach",{{3140,28.86,487},{3140,28.86,491.5},{3128,28.86,491.5}})
 lampRail(s,"CrownMeetingLight",3127,40.8,481,18,55.2,2)
 lampRail(s,"CrownArchiveLight",3133,41,492,34,55.2,2)
end
local function facade(l)
 local m=group(l,"HQ_Framed_And_Shaded_Facade","ARCHITECTURE","PROFESSIONAL","Simple framed office -> stepped masonry, clear glass and a deep shade crown")
 local glass=box(m,"ClearCrownGlazing",3130,42,467,60,25,.35,C.Galvanized,Enum.Material.Glass,true);glass.Transparency=.82
 for x=3100,3160,10 do
  box(m,"CrownMullion",x,42,466.72,.35,25,.55,C.Charcoal,M,true)
  box(m,"CrownShadeFin",x,42,465.8,.22,25,2.1,C.Bronze,M,false)
 end
 for _,y in ipairs({29.5,42,54.5}) do box(m,"CrownTransom",3130,y,466.72,60,.32,.55,C.Charcoal,M,false) end
 for _,v in ipairs({{3130,15.5,447.5,90},{3130,28.4,456,78},{3130,56,465.5,68}}) do
  box(m,"FacadeFascia",v[1],v[2],v[3],v[4],.65,1.4,C.Bronze,M,false)
 end
 -- Short supported shade over the original ground-floor front strip.
 box(m,"LobbyCanopy",3130,15.45,451,88,.35,8,C.Charcoal,M,true)
 for _,x in ipairs({3087,3117,3143,3173}) do box(m,"LobbyStructuralPost",x,7.8,447.6,.45,14.6,.55,C.Charcoal,M,true) end
 for x=3089,3171,4 do box(m,"LobbySoffitBatten",x,15.15,451,.5,.22,7.5,C.Timber,Enum.Material.Wood,false) end
 for _,x in ipairs({3085.7,3174.3}) do
  for z=452,492,10 do box(m,"GroundMasonryPanel",x,7.8,z,.3,14.5,9.7,C.WarmWhite,Enum.Material.Limestone,false) end
 end
 for _,x in ipairs({3091.7,3168.3}) do
  for z=461,491,10 do box(m,"OfficeMetalPanel",x,22.2,z,.25,11,9.7,C.Steel,M,false) end
 end
 for _,x in ipairs({3121,3139}) do box(m,"IdentityStandOff",x,51.3,465.35,.2,.2,1.7,C.Charcoal,M,false) end
 local sign=box(m,"CrownIdentity",3130,51.3,464.45,23,2.3,.2,C.Charcoal,M,false);textFace(sign,"DESERT CUSTOMS",Enum.NormalId.Front)
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
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);if p and #p:GetChildren()==0 then p:Destroy() end
 root():SetAttribute("InstitutionFidelityPhase6B2HQStatus",nil);return true
end



function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase6B1HQStatus")=="ACCEPTED_CIRCULATION","Accepted HQ circulation required")
 I.Uninstall();local p=root()["10_Institution_Fidelity_R1"][PHASE];local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local h=root()["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]["07_Institution_Headquarters"]
  for _,d in ipairs(h:GetChildren()) do
   local hide=d:IsA("Model") or d.Name=="AnalyticsPanel" or d.Name=="HQCrownGlass" or d.Name=="BrandHistoryWall" or d.Name=="InstitutionCrest" or d.Name=="LobbyLight" or d.Name=="CrownLight" or d.Name=="FacadeMullion1"
   local visible=false;local list=d:GetDescendants();table.insert(list,d);for _,v in list do if v:IsA("BasePart") and v.Transparency<.98 then visible=true end end
   if hide and visible then suppress(l,d) end
  end
  roomFinishes(l);reception(l);waitingAndMaterials(l);toolCraft(l);operations(l);crown(l);facade(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase6B2HQStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,missing,meta,ids={},{},{},{}
 local stats={parts=0,models=0,lights=0,solids=0,paths=0,standingVolumes=0,bodySamples=0,floorSamples=0,issues=issues,missingFloor=missing,metadataIssues=meta,signature=signature(l)}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function top(p)return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 local function check(n,cf,size,feet)
  for _,p in workspace:GetPartBoundsInBox(cf,size,params) do if p.Transparency<.98 and top(p)>feet+.55 then table.insert(issues,n..": "..p:GetFullName()) end end
 end
 for _,p in root()["03_Protected_Clearances"]:GetChildren() do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size,0) end end
 for _,p in root()["02_Vehicle_Routes"]:GetDescendants() do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),0) end end
 params.FilterDescendantsInstances={root()};local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={root()};rays.RespectCanCollide=true
 for _,route in l["98_Access_Paths"]:GetChildren() do
  stats.paths+=1;local points=route:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value;local d=b-a;local side=Vector3.new(d.Z,0,-d.X).Unit;local count=math.max(1,math.ceil(d.Magnitude/.6))
   for j=0,count do local v=a:Lerp(b,j/count);stats.bodySamples+=1
    check(route.Name,CFrame.lookAt(v+Vector3.new(0,3.3,0),v+Vector3.new(0,3.3,0)+d),Vector3.new(3,5.8,.4),v.Y)
    for _,dx in ipairs({-1,0,1}) do stats.floorSamples+=1;local q=v+side*dx;local hit=workspace:Raycast(q+Vector3.new(0,.65,0),Vector3.new(0,-1.4,0),rays);if not hit or math.abs(hit.Position.Y-v.Y)>.55 then table.insert(missing,route.Name..":"..tostring(q)) end end
   end
  end
 end
 for _,m in l:GetDescendants() do
  if m:IsA("Model") then stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"}) do if m:GetAttribute(k)==nil then table.insert(meta,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(meta,"Duplicate:"..id) end;ids[id]=true end
  elseif m:IsA("BasePart") then
   stats.parts+=1;if m.CanCollide then stats.solids+=1 end
   if m:GetAttribute("AnchorKind")=="OPERATOR" or m:GetAttribute("AnchorKind")=="VIEWING" then stats.standingVolumes+=1;check(m.Name,CFrame.new(m.Position+Vector3.new(0,3.3,0)),Vector3.new(3,5.8,3),m.Position.Y) end
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2)
    if v.X<3084 or v.X>3176 or v.Z<444.8 or v.Z>498.5 or v.Y>56.7 then table.insert(issues,"HQEnvelope:"..m:GetFullName()) end
   end end end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 local function auditSibling(name)
  local c=game.ServerStorage[name]:Clone();c.Parent=game.ServerStorage;local ok,a=pcall(function()return require(c).Audit()end);c:Destroy();assert(ok,a);return a
 end
 stats.circulation=auditSibling("SellCarsV5InstitutionFidelityPhase6B1HQCirculationInstaller")
 stats.collector=auditSibling("SellCarsV5InstitutionFidelityPhase6ACollectorInstaller")
 return stats
end
function I.Accept(e)
 local a=I.Audit();for _,s in ipairs({a,a.circulation,a.collector}) do assert(#s.issues==0 and #s.missingFloor==0 and #s.metadataIssues==0,"Unresolved HQ/Collector audit") end
 assert(e.VisualPass and e.ActualWalkingPass and e.RollbackPass and e.SourceMatch and e.RenderingReviewed,"Evidence missing")
 local f=Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in layer():GetDescendants() do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED");root():SetAttribute("InstitutionFidelityPhase6B2HQStatus","ACCEPTED")
 return a
end
return I

