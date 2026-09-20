--!nocheck
-- Phase 6A owns Collector Hall only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase6a.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","05_Prestige_And_Public_Realm","01_Collector"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.Collector_Hall."..n..".FidelityR1",FunctionId="Collector_Hall",ZoneId="Collector_Hall",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase6ACollectorGeometry",true);p.Parent=m;return p
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
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],23.9,v[2]);a.Parent=p end
end


local function plaque(m,n,x,y,z,w,h,words,rotation)
 local p=box(m,n,x,y,z,w,h,.14,C.Charcoal,M,false,rotation)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(w*50,h*50);g.LightInfluence=1;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.Text=words;t.TextColor3=C.WarmWhite;t.TextScaled=true;t.Parent=g
 return p
end
local function shell(l)
 local m=group(l,"Craft_Gallery_Shell","ARCHITECTURE","PROFESSIONAL","First saved transformation -> permanent elevated six-car gallery")
 box(m,"WarmStoneFloor",3130,20.82,406,92,.22,56,C.Concrete,Enum.Material.Limestone,true)
 for x=3094,3166,12 do box(m,"StoneControlJoint",x,20.94,406,.045,.015,55.8,C.OldConcrete,P,false) end
 for _,z in ipairs({382,394,406,418,430}) do box(m,"StoneControlJoint",3130,20.94,z,91.8,.015,.045,C.OldConcrete,P,false) end
 -- Collision glazing is real, split around the rear entry rather than ghosted.
 for _,x in ipairs({3084,3176}) do
  local p=box(m,"SideGlazing",x,27,406,.35,12,56,C.Galvanized,Enum.Material.Glass,true);p.Transparency=.79
  for z=378,434,14 do box(m,"SideMullion",x,27,z,.7,12.4,.35,C.Charcoal,M,true) end
  box(m,"StoneSideSkirting",x,21.6,406,.7,1.2,56,C.CleanPanel,Enum.Material.Limestone,true)
 end
 for _,v in ipairs({{3130,378,92},{3104.5,434,41},{3155.5,434,41}}) do
  local p=box(m,"GalleryGlazing",v[1],27,v[2],v[3],12,.35,C.Galvanized,Enum.Material.Glass,true);p.Transparency=.81
  box(m,"StoneSkirting",v[1],21.6,v[2],v[3],1.2,.7,C.CleanPanel,Enum.Material.Limestone,true)
 end
 for _,x in ipairs({3084,3100,3116,3130,3144,3160,3176}) do box(m,"FrontMullion",x,27,378,.35,12.4,.7,C.Charcoal,M,true) end
 for _,x in ipairs({3084,3104,3125,3135,3156,3176}) do box(m,"RearMullion",x,27,434,.35,12.4,.7,C.Charcoal,M,true) end
 box(m,"RearEntryLintel",3130,30.9,434,10,4.2,.7,C.CleanPanel,P,true)
 box(m,"RearEntryThreshold",3130,20.96,434.8,9.4,.08,1.4,C.Concrete,Enum.Material.Limestone,true)
 for _,z in ipairs({378,434}) do
  box(m,"ContinuousWindowHead",3130,33.2,z,93,.35,.8,C.Charcoal,M,false)
  box(m,"BronzeFacadeDrip",3130,20.95,z,93,.18,1,C.Bronze,M,false)
 end
 for _,x in ipairs({3098,3162}) do
  box(m,"RetainedSplitRoof",x,34,406,34,1.2,62,C.Charcoal,M,false)
  box(m,"TimberSoffit",x,33.32,406,33.6,.13,61.2,C.Timber,Enum.Material.Wood,false)
  for z=376,436,4 do box(m,"SoffitJoint",x,33.22,z,33.4,.025,.04,C.Bronze,M,false) end
  for dx=-14,14,7 do box(m,"StandingRoofSeam",x+dx,34.66,406,.14,.12,62,C.Steel,M,false) end
 end
 for _,x in ipairs({3114,3146}) do
  local p=box(m,"LanternGlass",x,37,406,1,5,54,C.Galvanized,Enum.Material.Glass,false);p.Transparency=.83
  box(m,"LanternBronzeCap",x,39.8,406,2,.8,58,C.Bronze,M,false)
  for z=380,432,13 do box(m,"LanternFrame",x,37,z,1.15,5,.25,C.Charcoal,M,false) end
 end
 -- Preserve the open central slot; the HQ crown remains the tallest object.
 box(m,"GalleryFascia",3130,19.4,376.5,56,2,.32,C.Charcoal,M,false)
 plaque(m,"QuietCollectorIdentity",3130,19.4,376.29,37,1.45,"DESERT CUSTOMS  /  LEGACY COLLECTION")
 for _,x in ipairs({3086,3174}) do
  for _,z in ipairs({381,431}) do
   box(m,"ColumnCollar",x,19.1,z,2.35,.65,2.35,C.Bronze,M,false)
  end
 end
 point(m,"CollectorAmbience",3130,31,406,"FX")
end
local stories={"ENGINE CRAFT","BODY RESTORATION","FINISH & COLOUR","RUNNING GEAR","LIGHT & FORM","DETAIL & PRESENTATION"}
local function setting(l,i,x,z)
 local m=group(l,"Legacy_Exhibit_"..i,"HERO","PROFESSIONAL","Best sold-car record -> curated transformation exhibit")
 m:SetAttribute("SnapshotCapacity",1);m:SetAttribute("LiveVehicleRoute",false);m:SetAttribute("SnapshotSelection","BEST_SOLD_TRANSFORMATION")
 m:SetAttribute("SnapshotBinding","PENDING_REAL_SOLD_HISTORY");m:SetAttribute("OriginalSnapshotRetained",true)
 box(m,"ShadowPlinth",x,21.04,z,13.5,.22,21.5,C.Charcoal,Enum.Material.Slate,false)
 for _,dx in ipairs({-6.7,6.7}) do box(m,"FineBronzePlinthEdge",x+dx,21.17,z,.055,.04,21.3,C.Bronze,M,false) end
 box(m,"FrontPlinthInlay",x,21.17,z-10.65,13.4,.04,.055,C.Bronze,M,false)
 -- Provenance stands live beside the car, not in the central viewing cross-aisle.
 local px=x-8.9
 box(m,"ProvenanceStandFoot",px,21.08,z+3,1.8,.28,2.1,C.Charcoal,M,true)
 box(m,"ProvenanceStandStem",px,22.3,z+3,.28,2.4,.32,C.Steel,M,false)
 local top=box(m,"ProvenanceLectern",px,23.6,z+3,2.1,.14,2.5,C.Timber,Enum.Material.Wood,false,CFrame.Angles(math.rad(-12),0,0))
 local page=box(m,"ProvenanceArchivePage",px,23.69,z+3,1.9,.025,2.25,C.WarmWhite,P,false,CFrame.Angles(math.rad(-12),0,0))
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Top;g.CanvasSize=Vector2.new(400,475);g.LightInfluence=1;g.Parent=page
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.Text=string.format("%02d\n%s\n\nTRANSFORMATION RECORD\nArchive binding pending",i,stories[i]);t.TextColor3=C.Charcoal;t.TextScaled=true;t.Parent=g
 top:SetAttribute("DataBindingKey","SOLD_SNAPSHOT_"..i.."_BEFORE_AFTER_VALUE_HISTORY");top:SetAttribute("RuntimeBinding","PENDING")
 point(m,"ExhibitViewing_"..i,x-11.8,20.94,z+3,"VIEWING")
 -- Shielded fixtures, not neon grids. Two real lights cover the two roof halves.
 if x==3130 then box(m,"LanternCrossTie",3130,33,z,33,.22,.4,C.Charcoal,M,false) end
 for _,dx in ipairs({-3.6,3.6}) do pipe(m,"TrackSuspension",Vector3.new(x+dx,32.2,z),Vector3.new(x+dx,33.25,z),.10,C.Bronze) end
 box(m,"ExhibitTrack",x,32.1,z,9,.22,.32,C.Charcoal,M,false)
 for _,dx in ipairs({-3,0,3}) do
  pipe(m,"FixtureStem",Vector3.new(x+dx,32.1,z),Vector3.new(x+dx,31.55,z),.12,C.Bronze)
  cyl(m,"SpotlightHousing",x+dx,31.4,z,.9,.62,C.Charcoal,"Y")
  local lens=cyl(m,"RecessedSpotLens",x+dx,30.94,z,.035,.43,C.WarmWhite,"Y");lens.Material=Enum.Material.Neon
  if dx==0 then
   local emitter=box(m,"ExhibitLightEmitter",x,30.91,z,.1,.05,.1,C.WarmWhite,P,false);emitter.Transparency=1
   local light=Instance.new("SpotLight");light.Face=Enum.NormalId.Bottom;light.Range=18;light.Angle=95;light.Brightness=1.5;light.Color=C.WarmWhite;light.Shadows=false;light.Parent=emitter
  end
 end
end
local function station(m,left,z)
 local cf=CFrame.new(left and 3085.8 or 3174.2,20.94,z)*CFrame.Angles(0,left and -math.pi/2 or math.pi/2,0)
 local function B(n,x,y,z,w,h,d,col,mat,solid,rot)
  local v=cf:PointToWorldSpace(Vector3.new(x,y,z));return box(m,n,v.X,v.Y,v.Z,w,h,d,col,mat,solid,cf.Rotation*(rot or CFrame.identity))
 end
 local function CY(n,x,y,z,len,diam,c,axis)
  local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
  local p=B(n,x,y,z,len,diam,diam,c,M,false,rot);p.Shape=Enum.PartType.Cylinder;return p
 end
 return B,CY
end
local function specimens(l,left,z,kind)
 local m=group(l,"Craft_Specimen_"..kind,"SUPPORT","DEDICATED","Workshop keepsake -> curated real-component story")
 local B,CY=station(m,left,z)
 B("OakSpecimenBack",0,5.2,.7,9,6.4,.18,C.Timber,Enum.Material.Wood,false)
 B("GalleryCaseBase",0,.45,.25,9,.9,2.6,C.CleanPanel,Enum.Material.Limestone,true)
 B("SpecimenDisplayShelf",0,2.5,.0,8.3,.18,2.2,C.Charcoal,M,false)
 local glass=B("SpecimenGuardGlass",0,4,-1.17,8.5,6,.10,C.Galvanized,Enum.Material.Glass,true);glass.Transparency=.87
 for _,x in ipairs({-4.3,4.3}) do B("VitrineFrame",x,4,-1.17,.12,6.4,.16,C.Bronze,M,false) end
 if kind=="Wheel" then
  CY("SectionedTyre",0,5,.0,.7,4.7,C.Rubber,"Z")
  CY("PolishedRim",0,5,-.45,.12,3.7,C.Stainless,"Z")
  CY("DarkWheelBarrel",0,5,-.54,.1,3.25,C.Charcoal,"Z")
  for j=0,7 do B("ForgedWheelSpoke",math.sin(j*math.pi/4)*1.1,5+math.cos(j*math.pi/4)*1.1,-.64,.20,2.0,.12,C.Bronze,M,false,CFrame.Angles(0,0,-j*math.pi/4)) end
  CY("CenterLock",0,5,-.73,.10,.62,C.Stainless,"Z")
 elseif kind=="Paint" then
  for i,c in ipairs({C.OldConcrete,C.Brick,C.CleanPanel,C.Red,C.Bronze,C.Cyan}) do
   B("ProcessCoupon", -3.4+(i-1)*1.35,5,.0,1.1,3.2,.14,c,M,false)
   B("CouponHangingClip",-3.4+(i-1)*1.35,6.8,.0,.3,.3,.3,C.Stainless,M,false)
  end
 elseif kind=="Engine" then
  B("EngineSectionCasting",0,4.3,.0,5,2.9,1.6,C.Steel,M,false)
  for i=-1,1 do
   CY("CylinderBore",i*1.5,5.0,-.86,.15,1.12,C.Charcoal,"Z")
   B("PistonCrown",i*1.5,4.72,-.98,.79,.4,.12,C.Stainless,M,false)
   for j=0,1 do B("PistonRingGroove",i*1.5,4.76-j*.14,-1.05,.80,.035,.03,C.Charcoal,P,false) end
   B("ConnectingRod",i*1.5,4.13,-.98,.18,.9,.14,C.Bronze,M,false,CFrame.Angles(0,0,(i%2==0 and .18 or -.18)))
   CY("CrankBigEnd",i*1.5,3.66,-.99,.13,.46,C.Stainless,"Z")
  end
  B("SectionCrankshaft",0,3.6,-.92,4.3,.22,.25,C.Steel,M,false)
  for x=-2.3,2.3,.92 do CY("CastingFastener",x,5.6,-.88,.12,.16,C.Stainless,"Z") end
  B("SectionSump",0,2.7,0,4.4,.5,1.45,C.Galvanized,M,false)
 else
  B("OriginalPanel", -2.1,4.5,0,3.4,3.5,.25,C.Brick,M,false)
  B("RestoredPanel", 2.1,4.5,0,3.4,3.5,.25,C.CleanPanel,M,false)
  for i=0,4 do B("RustPerforation",-3.1+i*.47,4.1+(i%2)*.7,-.15,.35,.45,.04,C.Charcoal,P,false) end
  for _,x in ipairs({-2.1,2.1}) do B("PanelBodyCrease",x,5.1,-.20,3.2,.15,.10,C.Stainless,M,false) end
 end
 local label=B("CraftCaption",0,1.6,-1.18,8,.75,.06,C.Charcoal,M,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(600,100);g.LightInfluence=1;g.Parent=label
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.Text=kind:upper().."  /  CRAFT STUDY";t.TextScaled=true;t.TextColor3=C.WarmWhite;t.Parent=g
 m:SetAttribute("ArtifactProvenance","DESIGN_SPECIMEN_NOT_CLAIMED_REAL_SOLD_CAR_PART")
 point(m,"SpecimenViewing_"..kind,left and 3090.2 or 3169.8,20.94,z,"VIEWING")
end
local function curator(l)
 local m=group(l,"Curator_Archive_Station","SUPPORT","PROFESSIONAL","Selecting a best build -> maintaining a six-car institutional archive")
 local B,CY=station(m,false,427)
 B("ArchiveWorktop",0,3.3,0,7,.28,2.9,C.Timber,Enum.Material.Wood,true)
 B("ArchiveDrawerCabinet",-2.3,1.65,.2,2.4,2.8,2.5,C.Charcoal,M,true)
 for y=.7,2.7,.65 do B("ArchiveDrawerFace",-2.3,y,-1.10,2.15,.5,.1,C.Steel,M,false);B("DrawerGrip",-2.3,y,-1.2,1.2,.09,.1,C.Stainless,M,false) end
 B("DeskTrestle",2.8,1.6,.2,.24,3,2.2,C.Steel,M,true)
 B("ArchiveScreen",.6,4.9,.4,3.0,2,.22,C.Charcoal,P,false)
 local p=B("PendingArchiveData",.6,4.9,.26,2.7,1.7,.04,Color3.fromRGB(60,76,75),P,false);p:SetAttribute("RuntimeBinding","PENDING_SOLD_SNAPSHOT_CURATOR")
 B("ScreenMount",.6,3.8,.4,.3,.8,.25,C.Steel,M,false)
 B("ArchiveKeyboard",.6,3.55,-.7,2.3,.13,.65,C.Charcoal,P,false)
 for i=0,4 do B("ArchivePortfolio",-2.7+i*.4,4.0,.4,.32,1.1,1.1,i%2==0 and C.Bronze or C.Navy,P,false) end
 B("CottonHandlingGloves",2.1,3.51,-.5,.65,.06,.8,C.WarmWhite,P,false)
 point(m,"CuratorOperator",3169.8,20.94,427,"OPERATOR")
 point(m,"ArchiveScreenFX",3173.8,25.8,427,"FX")
 m:SetAttribute("StaffBinding","PENDING_CURATOR_NO_GROUND_LEVEL_PLACEHOLDER")
end
local function circulation(l)
 local m=group(l,"Gallery_Viewing_And_Light","ARCHITECTURE","PROFESSIONAL","Standing beside a saved car -> complete visitor viewing circuit")
 for _,x in ipairs({3116,3144}) do
  box(m,"ViewingLaneInlay",x,20.96,406,2.8,.02,54,C.CleanPanel,Enum.Material.Limestone,false)
  path(l,"LongitudinalViewing_"..x,{{x,380.5},{x,432}})
 end
 for _,z in ipairs({380.5,406,432}) do path(l,"CrossViewing_"..z,{{3090.2,z},{3169.8,z}}) end
 path(l,"RearGalleryEntrance",{{3130,439},{3130,432},{3116,432}})
 for _,x in ipairs({3090.2,3169.8}) do path(l,"OuterViewing_"..x,{{x,380.5},{x,432}}) end
 for i,p in ipairs({{3102,393},{3130,393},{3158,393},{3102,419},{3130,419},{3158,419}}) do path(l,"ProvenanceApproach_"..i,{{p[1]-11.8,406},{p[1]-11.8,p[2]+3}}) end
 path(l,"CuratorApproach",{{3169.8,432},{3169.8,427}})
 for _,x in ipairs({3098,3162}) do
  local p=box(m,"DiffuseGalleryLight",x,33.05,406,20,.12,42,C.WarmWhite,Enum.Material.Neon,false)
  p.Transparency=1 -- light emitter hidden; visible fixture lenses live in exhibit assemblies.
  local s=Instance.new("SurfaceLight");s.Face=Enum.NormalId.Bottom;s.Range=18;s.Angle=110;s.Brightness=1.25;s.Color=C.WarmWhite;s.Shadows=false;s.Parent=p
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
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);if p and #p:GetChildren()==0 then p:Destroy() end
 root():SetAttribute("InstitutionFidelityPhase6ACollectorStatus",nil);return true
end

function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase5COwnerStatus")=="ACCEPTED","Phase5 gate required")
 I.Uninstall();local f=root()["10_Institution_Fidelity_R1"];local p=f:FindFirstChild(PHASE) or Instance.new("Folder");p.Name=PHASE;p.Parent=f
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version);l:SetAttribute("LiveVehicleRoute",false);l:SetAttribute("SnapshotCapacity",6)
 local ok,err=pcall(function()
  local old=root()["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]["06_Collector_Hall"]
  local function hide(target)
   if target:IsA("Model") and target:GetAttribute("VehicleDisplay") then return end
   if target:IsA("BasePart") then suppress(l,target);return end
   for _,c in ipairs(target:GetChildren()) do hide(c) end
  end
  for _,c in ipairs(old:GetChildren()) do hide(c) end
  for i=1,6 do suppress(l,root()["04_Capacity_Sockets"]["CollectorSnapshot_"..i]) end
  shell(l)
  for i,p in ipairs({{3102,393},{3130,393},{3158,393},{3102,419},{3130,419},{3158,419}}) do setting(l,i,p[1],p[2]) end
  specimens(l,true,389,"Engine");specimens(l,true,419,"Panel")
  specimens(l,false,389,"Wheel");specimens(l,false,412,"Paint")
  curator(l);circulation(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase6ACollectorStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,meta,ids={},{},{}
 local stats={parts=0,solids=0,lights=0,models=0,accessPaths=0,standingVolumes=0,floorSamples=0,missingFloor={},issues=issues,metadataIssues=meta,signature=signature(l)}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function check(n,cf,size,floorLimit)
  for _,p in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
   local top=p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2
   if p.Transparency<.98 and top>(floorLimit or 1) then table.insert(issues,n..": "..p:GetFullName()) end
  end
 end
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size,1) end end
 for _,p in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),1) end end
 for i,p in ipairs({{3102,393},{3130,393},{3158,393},{3102,419},{3130,419},{3158,419}}) do
  check("SnapshotCar_"..i,CFrame.new(p[1],24,p[2]),Vector3.new(12.3001,5.7,17.82),21.2)
 end
 params.FilterDescendantsInstances={root()}
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={root()};rays.RespectCanCollide=true
 for _,route in ipairs(l["98_Access_Paths"]:GetChildren()) do
  stats.accessPaths+=1;local points=route:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value
   check(route.Name,CFrame.lookAt((a+b)/2,b),Vector3.new(3,5.5,(b-a).Magnitude+.3),21.2)
   local steps=math.ceil((b-a).Magnitude/2)
   for j=0,steps do local v=a:Lerp(b,j/steps);stats.floorSamples+=1
    local hit=workspace:Raycast(Vector3.new(v.X,22,v.Z),Vector3.new(0,-2,0),rays)
    if not hit or math.abs(hit.Position.Y-20.94)>.25 then table.insert(stats.missingFloor,route.Name..":"..tostring(v)) end
   end
  end
 end
 for _,m in ipairs(l:GetDescendants()) do
  if m:IsA("Model") then
   stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"}) do if m:GetAttribute(k)==nil then table.insert(meta,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(meta,"Duplicate:"..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do local n=m:GetAttribute(k);if n and n~="" then
    local a=m:FindFirstChild(n,true)
    if not a then table.insert(meta,m.Name..": unresolved "..n)
    elseif k=="InteractionAnchor" and a:IsA("BasePart") then stats.standingVolumes+=1;check(m.Name.."_Standing",CFrame.new(a.Position.X,23.9,a.Position.Z),Vector3.new(3,5.5,3),21.2) end
   end end
  elseif m:IsA("BasePart") then
   stats.parts+=1;if m.CanCollide then stats.solids+=1 end
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2)
    if v.X<3080.8 or v.X>3179.2 or v.Z<374.8 or v.Z>437.2 or v.Y>40.21 or v.Y<18.3 then table.insert(issues,"GalleryEnvelope:"..m:GetFullName());break end
   end end end
  elseif m:IsA("Light") then stats.lights+=1 end
 end
 stats.EndToEndHQAccess="PENDING_PHASE6B"
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.metadataIssues==0 and #a.missingFloor==0,"Geometry/metadata/floor checks must pass")
 assert(e.VisualPass and e.RoutePass and e.LocalWalkPass and e.RollbackPass and e.SourceMatch,"Evidence missing")
 local f=layer():FindFirstChild("99_Evidence") or Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 f:SetAttribute("EndToEndHQAccess","PENDING_PHASE6B")
 for _,m in ipairs(layer():GetDescendants()) do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED_LOCAL_GALLERY");root():SetAttribute("InstitutionFidelityPhase6ACollectorStatus","ACCEPTED_LOCAL_GALLERY");return a
end
return I

