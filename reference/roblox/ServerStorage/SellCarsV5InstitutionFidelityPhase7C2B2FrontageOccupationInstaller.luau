--!nocheck
-- 7C2B2: seven frontage/courtyard occupation proxies and finite, staggered local tasks.
local I={Version="2026-09-07.phase7c2b2.1"}
local RS=game:GetService("RunService")
local ROOT="SellCars_Dealership_Growth_V5"
local NAME="07_Occupation_Frontage"
local MODULE="SellCarsV5InstitutionFidelityPhase7C2B2FrontageOccupationInstaller"
local DRIVER_NAME="SellCarsV5InstitutionFrontageOccupationServer"
local DRIVER=[[-- Persistent host owns occupation callback lifetime. No per-person scripts.
local api=require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C2B2FrontageOccupationInstaller)
local bridge=Instance.new("BindableFunction");bridge.Name="RuntimeDispatch"
bridge.OnInvoke=function(method,...)
 if method=="Start" then return api._Start(...)
 elseif method=="Stop" then return api._Stop(...)
 elseif method=="Trigger" then return api._Trigger(...)
 elseif method=="SetEnabled" then return api._SetEnabled(...)
 elseif method=="SetAmbient" then return api._SetAmbient(...)
 elseif method=="GetState" then return api._GetState(...)
 else error("Unknown occupation command") end
end
bridge.Parent=script
api._Start()
script.Destroying:Connect(function() api._Stop() end)
]]
local function root(edit)
 assert(game.PlaceId==125334614375606,"Wrong place")
 if edit then assert(not RS:IsRunning(),"Edit only") end
 return assert(workspace:FindFirstChild(ROOT),"V5 missing")
end
local function layer()
 local r=workspace:FindFirstChild(ROOT);local f=r and r:FindFirstChild("10_Institution_Fidelity_R1")
 local a=f and f:FindFirstChild("06_Atmosphere");return a and a:FindFirstChild(NAME)
end
local function resolve(path)
 local p=root(false)["10_Institution_Fidelity_R1"]
 for n in path:gmatch("[^/]+") do p=assert(p:FindFirstChild(n),"Missing dependency "..path) end
 return p
end
local V=Vector3.new
local C=Color3.fromRGB
local defs={
 {id="SeniorAppraiser",zone="Intake_Appraisal",role="Review condition records at the acquisition counter",first="WORKING",kind="TABLET",
 anchor="04_Frontage_And_Owner/01_Intake/Shared_Valuation_And_Seller_Handoff/SeniorAppraiser",
 home=V(3084,.715,48),target=V(3084,.715,40.5),anchorY=.6,
 floor="04_Frontage_And_Owner/01_Intake/Seller_Public_Exchange/CustomerWalkInset",
 shirt=C(111,124,107),skin=C(171,120,82),hair=C(39,31,25)},
 {id="Seller",zone="Intake_Appraisal",role="Check the key and title packet with the appraiser",first="WORKING",kind="KEYS",visitor=true,
 anchor="04_Frontage_And_Owner/01_Intake/Seller_Public_Exchange/SellerCounterPosition",
 home=V(3084,.715,40.5),target=V(3084,.715,48),anchorY=.6,
 floor="04_Frontage_And_Owner/01_Intake/Seller_Public_Exchange/CustomerWalkInset",
 shirt=C(174,117,77),skin=C(212,172,135),hair=C(66,43,32),cap=true},
 {id="SalesAdvisor",zone="Sales_Delivery",role="Review the documented offer at the customer exchange",first="WORKING",kind="FOLIO",
 anchor="04_Frontage_And_Owner/02_Sales/Deal_And_Listing_Exchange/SalesAdvisor",
 home=V(3160,.605,79),target=V(3157,.605,70.5),anchorY=.6,
 floor="04_Frontage_And_Owner/02_Sales/Sales_Floor_And_Customer_Approaches/ShowroomPaving",
 shirt=C(99,122,133),skin=C(132,89,65),hair=C(28,27,24)},
 {id="Buyer",zone="Sales_Delivery",role="Read the build and delivery folio with the advisor",first="WORKING",kind="FOLIO",visitor=true,
 anchor="04_Frontage_And_Owner/02_Sales/Deal_And_Listing_Exchange/CustomerNegotiation",
 home=V(3157,.605,70.5),target=V(3160,.605,79),anchorY=.6,
 floor="04_Frontage_And_Owner/02_Sales/Sales_Floor_And_Customer_Approaches/ShowroomPaving",
 shirt=C(183,172,142),skin=C(196,147,113),hair=C(52,42,34)},
 {id="DeliveryHost",zone="Sales_Delivery",role="Verify the release key packet beside the protected handover space",first="DEDICATED",kind="KEYS",
 anchor="04_Frontage_And_Owner/02_Sales/Protected_Handover_And_Staging/HandoverPresenter",
 home=V(3159,.605,84),target=V(3144,.605,84),anchorY=.6,
 floor="04_Frontage_And_Owner/02_Sales/Sales_Floor_And_Customer_Approaches/ShowroomPaving",
 shirt=C(143,129,102),skin=C(220,175,135),hair=C(80,66,49)},
 {id="YardVisitor",zone="Campus_Public_Realm",role="Study the preserved original-yard sign",first="PROFESSIONAL",kind="VIEW",visitor=true,
 anchor="05_Prestige_And_Public_Realm/04_Estate_Identity/Original_Yard_Sign_Study/RelicView",
 home=V(3100,.168,383.7),target=V(3100,.168,388),anchorY=.095,
 floor="06_Atmosphere/01_Movement_Surfaces/Limestone_Craft_Court/WarmCourtBase",
 shirt=C(102,124,140),skin=C(177,126,94),hair=C(41,31,25),cap=true},
 {id="CourtVisitor",zone="Campus_Public_Realm",role="Pause beside the seating to view the transformation sculpture",first="PROFESSIONAL",kind="VIEW",visitor=true,
 anchor="05_Prestige_And_Public_Realm/04_Estate_Identity/Courtyard_East_Seat/SeatingApproach",
 home=V(3167.9,.168,391.2),target=V(3130,.168,388),anchorY=.095,
 floor="06_Atmosphere/01_Movement_Surfaces/Limestone_Craft_Court/WarmCourtBase",
 shirt=C(169,129,103),skin=C(135,92,72),hair=C(32,27,24)},
}
local f04Adapter=game.ServerStorage:FindFirstChild("SellCarsV5Frontage04Runtime")
if f04Adapter then
 local copy=f04Adapter:Clone();local ok,adapter=pcall(require,copy);copy:Destroy();assert(ok,adapter)
 adapter.ApplyOccupation(defs)
end
-- Placement01: apply after frontage overrides and before cached timelines.
local placementSource=game.ServerStorage:FindFirstChild("SellCarsV5CampusPlacement01")
if placementSource then
 local copy=placementSource:Clone();local ok,api=pcall(require,copy);copy:Destroy();assert(ok,api)
 api.ApplyOccupation(defs)
end
local byId={};for _,d in defs do byId[d.id]=d end
local function face(a,b) return CFrame.lookAt(a,V(b.X,a.Y,b.Z)) end
local function ease(t) return t*t*(3-2*t) end
local function timeline(d)
 local s={};local cf=face(d.home,d.target);local total=0
 local function add(dt,to,kind)
  table.insert(s,{at=total,duration=dt,from=cf,to=to,kind=kind});total+=dt;cf=to
 end
 if d.route then
  add(1,cf,"ATTEND");add(3,cf,"CHECK_PICKLIST");add(1,cf,"LOWER")
  for i=2,#d.route do
   local a,b=d.route[i-1],d.route[i];add(.6,face(a,b),"TURN");add((b-a).Magnitude/3.5,face(b,b+(b-a)),"WALK")
  end
  add(.6,face(d.route[#d.route],d.destinationTarget),"TURN");add(1,cf,"ATTEND");add(4,cf,"VERIFY_KIT");add(1,cf,"LOWER")
  for i=#d.route-1,1,-1 do
   local a,b=d.route[i+1],d.route[i];add(.6,face(a,b),"TURN");add((b-a).Magnitude/3.5,face(b,b+(b-a)),"WALK")
  end
  add(.6,face(d.home,d.target),"TURN");add(1,cf,"ATTEND");add(2,cf,"FILE_PICKLIST");add(1,cf,"LOWER")
 else add(1,cf,"ATTEND");add(6,cf,d.kind);add(1,cf,"LOWER") end
 return s,total
end
for _,d in defs do d.steps,d.duration=timeline(d) end
local function stateAt(d,t)
 if not t then return face(d.home,d.target),"IDLE",0 end
 for _,s in d.steps do
  if t<s.at+s.duration then
   local u=math.clamp((t-s.at)/s.duration,0,1)
   return s.from:Lerp(s.to,s.kind=="TURN" and ease(u) or u),s.kind,u
  end
 end
 return face(d.home,d.target),"IDLE",0
end
-- Anatomical proxy sizes in studs. Exact same function drives runtime and swept tests.
local function geometry(d,t)
 local cf,kind,u=stateAt(d,t);local result={}
 local function p(n,size,localcf,col,mat,shape)
  result[n]={size=size,cf=cf*localcf,col=col,mat=mat or Enum.Material.SmoothPlastic,shape=shape}
 end
 local skin=d.skin;local dark=C(37,40,43);local pants=C(52,57,59)
 local active=kind~="IDLE" and kind~="LOWER" and kind~="TURN" and kind~="WALK"
 local blend=active and (kind=="ATTEND" and ease(u) or 1) or (kind=="LOWER" and 1-ease(u) or 0)
 local gait=kind=="WALK" and math.sin((t or 0)*8)*math.min(u*5,(1-u)*5,1) or 0
 local stride=gait*.52
 local headYaw=active and math.sin((t or 0)*.8)*.11 or 0
 if d.kind=="VIEW" then headYaw=blend*(.15+.35*math.sin((t or 0)*.7)) end
 p("Torso",V(1.78,1.7,.88),CFrame.new(0,3.3,0),d.shirt,Enum.Material.Fabric)
 p("Waist",V(1.6,.5,.82),CFrame.new(0,2.3,0),pants,Enum.Material.Fabric)
 p("Belt",V(1.65,.14,.87),CFrame.new(0,2.51,0),dark)
 p("Buckle",V(.26,.17,.06),CFrame.new(0,2.51,-.465),C(139,140,130),Enum.Material.Metal)
 p("Neck",V(.52,.28,.52),CFrame.new(0,4.26,0),skin)
 local h=CFrame.new(0,4.99,0)*CFrame.Angles(-blend*.07,headYaw,0)
 p("Head",V(1.25,1.25,1.18),h,skin,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 p("Hair",V(1.24,.24,1.13),h*CFrame.new(0,.49,.02),d.hair)
 for _,x in {-.23,.23} do p("Eye"..x,V(.09,.105,.06),h*CFrame.new(x,.04,-.576),C(31,29,28)) end
 p("Mouth",V(.22,.035,.045),h*CFrame.new(0,-.23,-.57),C(93,62,48))
 if d.cap then
  p("Cap",V(1.34,.18,1.2),h*CFrame.new(0,.65,0),d.shirt,Enum.Material.Fabric)
  p("CapBill",V(.97,.08,.57),h*CFrame.new(0,.53,-.77),d.shirt)
 end
 p("ChestPocket",V(.49,.49,.045),CFrame.new(-.43,3.5,-.467),d.shirt,Enum.Material.Fabric)
 if not d.visitor then p("IdentityPatch",V(.37,.18,.05),CFrame.new(.44,3.67,-.47),C(205,190,153),Enum.Material.Fabric) end
 local function limb(n,a,b,w,col)
  local delta=b-a
  p(n,V(w,delta.Magnitude,w),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),col,Enum.Material.Fabric)
 end
 local hands={}
 for _,side in {-1,1} do
  local n=side==-1 and "L" or "R"
  local lift=math.max(0,gait*side)*.16
  local hip=V(side*.46,2.14,0);local knee=V(side*.46,1.2+lift*.5,-stride*side*.5)
  local ankle=V(side*.46,.44+lift,stride*side)
  limb("Thigh"..n,hip,knee,.65,pants);limb("Shin"..n,knee,ankle,.57,pants)
  p("Boot"..n,V(.7,.42,1.05),CFrame.new(ankle.X,.215+lift,ankle.Z-.18),dark)
  local shoulder=V(side*1.08,3.92,0)
  local elbow=V(side*1.18,3.04,-.08)
  local hand=V(side*1.12,2.35,-.12)
  if d.kind~="VIEW" and side==-1 then
   elbow=V(-1.13,3.12,-.45);hand=V(-.68,3.22,-1.06)
  end
  if side==1 and blend>0 then
   if d.kind=="RADIO" then hand=hand:Lerp(V(.73,4.65,-.52),blend);elbow=elbow:Lerp(V(1.4,3.7,-.2),blend)
   else hand=hand:Lerp(V(.24,3.42,-1.1),blend);elbow=elbow:Lerp(V(1.04,3.06,-.55),blend) end
  end
  if kind=="WALK" and side==1 then hand+=V(0,0,-stride*.65);elbow+=V(0,0,-stride*.3) end
  limb("UpperArm"..n,shoulder,elbow,.54,d.shirt);limb("Forearm"..n,elbow,hand,.45,d.shirt)
  p("Hand"..n,V(.43,.42,.43),CFrame.new(hand),skin);hands[n]=hand
 end
 if d.kind~="VIEW" then
  local board=CFrame.new(hands.L+V(.36,.14,-.03))*CFrame.Angles(math.rad(63),0,0)
  local col=d.kind=="TABLET" and dark or C(115,83,57)
  p("HeldBoard",V(1.0,.08,1.22),board,col)
  p("HeldPage",V(.9,.025,1.08),board*CFrame.new(0,.055,0),d.kind=="TABLET" and C(82,110,119) or C(218,207,178))
  for i=1,3 do p("HeldRecord"..i,V(.61,.012,.035),board*CFrame.new(0,.075,-.38+i*.18),C(91,91,81)) end
 end
 if d.kind=="KEYS" then
  local hp=CFrame.new(hands.R+V(0,.05,-.19))
  p("KeyEnvelope",V(.6,.75,.06),hp,C(212,199,159))
  p("KeyFob",V(.24,.37,.15),hp*CFrame.new(.05,-.14,-.10),dark)
  p("KeyBlade",V(.09,.32,.04),hp*CFrame.new(.05,-.47,-.10),C(168,171,167),Enum.Material.Metal)
 end
 if d.kind=="RADIO" or d.kind=="PICKLIST" then
  local hp=CFrame.new(hands.R+V(0,.17,0))
  p("Handset",V(.29,.62,.28),hp,dark)
  p("HandsetHead",V(.38,.2,.35),hp*CFrame.new(0,.37,-.02),dark)
  if d.kind=="RADIO" then p("Antenna",V(.055,.42,.055),hp*CFrame.new(.09,.68,0),dark) end
 end
 return result,cf,kind
end
local function metadata(m,d)
 for k,v in {BundleId="Institution.Occupation."..d.id..".FidelityR1",FunctionId=d.zone,ZoneId=d.zone,
  FidelityRole="STORY",PhaseMin=d.first,Ancestor=d.visitor and "Roadside seller/buyer -> sheltered exchange -> institutional customer care" or "Player-operated exchange -> staffed counter -> institutional specialist",
  InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="NONE",InteractionAnchor="ExistingWorkAnchor",FXSocket="",
  OccupationRole=d.role,DesignedOccupation=true,NoGameplayEconomy=true} do m:SetAttribute(k,v) end
end
local function anchorValid(d,m)
 local ref=m:FindFirstChild("ExistingWorkAnchor")
 if not ref or not ref.Value or not ref.Value:IsDescendantOf(root(false)) then return false end
 local p=ref.Value.Position
 if math.abs(p.X-d.home.X)>.02 or math.abs(p.Z-d.home.Z)>.02 or math.abs(p.Y-d.anchorY)>.03 then return false end
 if d.destination then
  local r=m:FindFirstChild("ExistingDestination");local p2=r and r.Value
  if not p2 or not p2:IsDescendantOf(root(false)) or (p2.Position-d.destinationPoint).Magnitude>.03 then return false end
 end
 return true
end
local function render(m,d,t)
 local g,cf,kind=geometry(d,t)
 for n,v in g do local p=m:FindFirstChild(n);if p and p:IsA("BasePart") then p.CFrame=v.cf;p.Size=v.size end end
 m:SetAttribute("FootCFrame",cf);m:SetAttribute("Action",kind)
end
local function restore(l,check)
 for _,ref in l.Restoration:GetChildren() do
  local p=assert(ref.Value,"Missing original customer; preserve layer")
  if check then assert(p.Transparency==1 and p.CanCollide==ref:GetAttribute("OriginalCanCollide") and p.CanQuery==ref:GetAttribute("OriginalCanQuery") and p.CanTouch==ref:GetAttribute("OriginalCanTouch"),"Original customer edited; preserve layer")
  else p.Transparency=ref:GetAttribute("Transparency") end
 end
end
function I.Install()
 root(true)
 if layer() then assert(layer():GetAttribute("SourceVersion")==I.Version,"Unexpected occupation version");return {alreadyInstalled=true} end
 assert(not game.ServerScriptService:FindFirstChild(DRIVER_NAME),"Unowned bootstrap name")
 local targets={}
 for _,n in {"Courtyard_Customer_A","Courtyard_Customer_B"} do
  local m=assert(root(false)["09_Institution_Production_B"]["03_Estate_Identity"]["08_Campus_Identity_Public_Realm"]:FindFirstChild(n))
  assert(m:GetAttribute("OccupationPrototype"),"Unexpected original")
  for _,p in m:GetDescendants() do if p:IsA("BasePart") then assert(not p.CanCollide,"Unexpected original collision");table.insert(targets,p) end end
 end
 assert(#targets==6,"Original customer count changed")
 local a=root(false)["10_Institution_Fidelity_R1"]["06_Atmosphere"]
 assert(a:FindFirstChild("06_Occupation_Production"),"7C2B1 baseline required")
 local l=Instance.new("Folder");l.Name=NAME;l:SetAttribute("SourceVersion",I.Version);l:SetAttribute("Status","CANDIDATE")
 l:SetAttribute("Enabled",true);l:SetAttribute("AmbientEnabled",true);l:SetAttribute("MaxActive",2);l:SetAttribute("UpdateHz",20);l.Parent=a
 local restoration=Instance.new("Folder");restoration.Name="Restoration";restoration.Parent=l
 local ok,err=pcall(function()
  for i,p in targets do local ref=Instance.new("ObjectValue");ref.Name="CustomerPart_"..i;ref.Value=p;ref:SetAttribute("Transparency",p.Transparency);ref:SetAttribute("OriginalCanCollide",p.CanCollide);ref:SetAttribute("OriginalCanQuery",p.CanQuery);ref:SetAttribute("OriginalCanTouch",p.CanTouch);ref.Parent=restoration;p.Transparency=1 end
  for i,d in defs do
   local m=Instance.new("Model");m.Name=d.id;metadata(m,d);m.Parent=l
   local ref=Instance.new("ObjectValue");ref.Name="ExistingWorkAnchor";ref.Value=resolve(d.anchor);ref.Parent=m
   if d.destination then local r=Instance.new("ObjectValue");r.Name="ExistingDestination";r.Value=resolve(d.destination);r.Parent=m end
   assert(anchorValid(d,m),"Anchor changed")
   for n,v in geometry(d,nil) do
    local p=Instance.new("Part");p.Name=n;p.Size=v.size;p.CFrame=v.cf;p.Color=v.col;p.Material=v.mat
    p.Shape=v.shape or Enum.PartType.Block;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
   end
   m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0);m:SetAttribute("CompletedCycles",0);m:SetAttribute("TaskDuration",d.duration);render(m,d,nil)
  end
  local s=Instance.new("Script");s.Name=DRIVER_NAME;s.Source=DRIVER;s:SetAttribute("Owner","Institution7C2B2");s.Parent=game.ServerScriptService
 end)
 if not ok then if l then restore(l,false);l:Destroy() end;error(err) end
 return {actors=#defs,hiddenParts=#targets}
end
function I.Uninstall()
 root(true);local l=layer();if not l then return true end
 restore(l,true)
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 if s then assert(s:GetAttribute("Owner")=="Institution7C2B2" and s.Source==DRIVER,"Bootstrap edited; preserve it") end
 restore(l,false);if s then s:Destroy() end;l:Destroy();return true
end
local function overlapParams()
 local p=OverlapParams.new();p.FilterType=Enum.RaycastFilterType.Exclude;p.FilterDescendantsInstances={layer()};p.RespectCanCollide=false;return p
end
local function worldTop(p)
 local c=p.CFrame;return p.Position.Y+(math.abs(c.RightVector.Y)*p.Size.X+math.abs(c.UpVector.Y)*p.Size.Y+math.abs(c.LookVector.Y)*p.Size.Z)/2
end
local function clearPose(d,t,params,full)
 local g,cf=geometry(d,t);local r=root(false);local hits={}
 local function check(n,c,s)
  for _,p in workspace:GetPartBoundsInBox(c,s,params) do
   if p:IsDescendantOf(r) and p.Transparency<.95 and worldTop(p)>cf.Position.Y+.08 then table.insert(hits,n..": "..p:GetFullName()) end
  end
 end
 if full then for n,v in g do check(n,v.cf,v.size-V(.012,.012,.012)) end
 else check("StandingSweep",cf*CFrame.new(0,3.1,0),V(3.15,5.85,3.15)) end
 local floor=resolve(d.floor)
 local fp=floor.CFrame:PointToObjectSpace(cf.Position)
 if floor.Transparency>=.95 or math.abs(worldTop(floor)+.005-cf.Position.Y)>.025 or math.abs(fp.X)>floor.Size.X/2 or math.abs(fp.Z)>floor.Size.Z/2 then table.insert(hits,"Visible supporting surface changed") end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
 local f=workspace:Raycast(cf.Position+V(0,.25,0),V(0,-1.3,0),rp)
 if not f or cf.Position.Y-f.Position.Y>1 then table.insert(hits,"Underlying collision support missing") end
 return hits,cf,g
end
local conn,records,accumulator,clock=nil,nil,0,0
local stats={ticks=0,started=0,completed=0,blocked=0,maxActive=0}
function I._GetState()
 local rows={};local active=0
 if records then for _,r in records do
  if r.m.Parent then
   local a=r.m:GetAttribute("TaskActive");if a then active+=1 end
   table.insert(rows,{id=r.d.id,active=a,time=r.m:GetAttribute("TaskTime"),action=r.m:GetAttribute("Action"),completed=r.m:GetAttribute("CompletedCycles"),blocked=r.m:GetAttribute("Blocked")})
  end
 end end
 local counters={};for k,v in stats do counters[k]=v end
 return {running=conn~=nil,connections=conn and 1 or 0,clock=clock,active=active,actors=rows,counters=counters,retainedRecords=records and #records or 0}
end
function I._Stop()
 if conn then conn:Disconnect();conn=nil end
 records=nil;accumulator=0
end
function I._SetEnabled(value)
 assert(type(value)=="boolean");local l=assert(layer());l:SetAttribute("Enabled",value);return value
end
function I._SetAmbient(value)
 assert(type(value)=="boolean");assert(layer()):SetAttribute("AmbientEnabled",value);return value
end
function I._Trigger(id)
 if not records or not conn or not byId[id] then return false,"INACTIVE_OR_UNKNOWN" end
 local l=layer();if not l or not l:GetAttribute("Enabled") or root(false):GetAttribute("ProgressionState")~="INSTITUTION" then return false,"DISABLED" end
 local active=0;local selected
 for _,r in records do
  if r.m.Parent and r.m:GetAttribute("TaskActive") then active+=1 end
  if r.d.id==id then selected=r end
 end
 if not selected or not selected.m:IsDescendantOf(l) or not anchorValid(selected.d,selected.m) then return false,"MISSING_ANCHOR" end
 if selected.m:GetAttribute("TaskActive") then
  if selected.m:GetAttribute("Blocked") then selected.m:SetAttribute("Blocked",false);return true,"RESUME_BLOCKED" end
  return false,"BUSY"
 end
 if active>=2 then return false,"CAPACITY" end
 selected.m:SetAttribute("TaskActive",true);selected.m:SetAttribute("TaskTime",0);stats.started+=1;return true
end
local function tick(dt)
 clock+=dt;stats.ticks+=1
 local l=layer()
 if not l or not l:IsDescendantOf(workspace) then I._Stop();return end
 -- Release removed actors even while disabled; never keep updating an unowned model.
 for i=#records,1,-1 do if not records[i].m:IsDescendantOf(l) then table.remove(records,i) end end
 local permitted=l:GetAttribute("Enabled") and root(false):GetAttribute("ProgressionState")=="INSTITUTION"
 if not permitted then return end
 local active=0;local params=overlapParams()
 for _,r in records do
  local m,d=r.m,r.d
  if not m.Parent then continue end
  if m:GetAttribute("TaskActive") then
   active+=1
   if not anchorValid(d,m) then m:SetAttribute("Blocked",true);m:SetAttribute("Action","MISSING_ANCHOR");continue end
   if m:GetAttribute("Blocked") then continue end
   local t=math.min(m:GetAttribute("TaskTime")+math.min(dt,.15),d.duration)
   local issues=clearPose(d,t,params,false)
   -- Broad standing boxes can include a lectern beside (not inside) the body.
   -- Confirm potential hits using all the actual posed pieces before blocking.
   if #issues>0 then issues=clearPose(d,t,params,true) end
   if #issues>0 then m:SetAttribute("Blocked",true);m:SetAttribute("Action","BLOCKED");stats.blocked+=1;continue end
   render(m,d,t);m:SetAttribute("TaskTime",t)
   if t>=d.duration then
    m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0);m:SetAttribute("CompletedCycles",m:GetAttribute("CompletedCycles")+1)
    stats.completed+=1;r.nextAt=clock+55+r.index*4
   end
  elseif l:GetAttribute("AmbientEnabled") and clock>=r.nextAt then
   local ok=I._Trigger(d.id);if ok then r.nextAt=math.huge end
  end
 end
 stats.maxActive=math.max(stats.maxActive,active)
end
function I._Start()
 assert(RS:IsRunning() and RS:IsServer(),"Server runtime only")
 if conn then return I._GetState() end
 local l=assert(layer(),"Install7C2B2 first");records={};clock=0;accumulator=0
 for i,d in defs do
  local m=l:FindFirstChild(d.id);if m then table.insert(records,{m=m,d=d,index=i,nextAt=3+(i-1)*9}) end
 end
 conn=RS.Heartbeat:Connect(function(dt)
  accumulator+=dt;if accumulator<.05 then return end
  local elapsed=accumulator;accumulator=0
  local ok,err=pcall(tick,elapsed);if not ok then I._Stop();warn("Frontage occupation stopped safely: "..tostring(err)) end
 end)
 return I._GetState()
end
local function dispatch(method,...)
 assert(RS:IsRunning() and RS:IsServer(),"Server runtime only")
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME);local b=s and s:FindFirstChild("RuntimeDispatch")
 if not b then return false,"BOOTSTRAP_NOT_READY" end
 return b:Invoke(method,...)
end
function I.Start() return dispatch("Start") end
function I.Stop() return dispatch("Stop") end
function I.Trigger(id) return dispatch("Trigger",id) end
function I.SetEnabled(v) return dispatch("SetEnabled",v) end
function I.SetAmbient(v) return dispatch("SetAmbient",v) end
function I.GetState() return dispatch("GetState") end
function I.Preview(id,t)
 root(true);local d=assert(byId[id]);assert(type(t)=="number" and t>=0 and t<=d.duration);render(assert(layer()[id]),d,t)
end
function I.ResetPreview()
 root(true);for _,d in defs do render(layer()[d.id],d,nil) end
end
function I.Audit(sweep)
 local l=assert(layer());local out={issues={},actors=0,parts=0,poseSamples=0,partChecks=0,anchorChecks=0,maxDuration=0,vehicleReservationChecks=0,actorSeparationChecks=0}
 local params=overlapParams()
 local nonQuery={}
 for _,p in root(false):GetDescendants() do
  if p:IsA("BasePart") and not p.CanQuery and p.Transparency<.95 and not p:IsDescendantOf(l) then table.insert(nonQuery,p) end
 end
 out.nonQueryGeometryChecks=0
 out.restorationRecords=#l.Restoration:GetChildren()
 if out.restorationRecords~=6 then table.insert(out.issues,"Restoration count changed") end
 for _,ref in l.Restoration:GetChildren() do local p=ref.Value
  if not p or p.Transparency~=1 or p.CanCollide~=ref:GetAttribute("OriginalCanCollide") or p.CanQuery~=ref:GetAttribute("OriginalCanQuery") or p.CanTouch~=ref:GetAttribute("OriginalCanTouch") then table.insert(out.issues,"Legacy suppression changed") end
 end
 local reservations={};for _,p in root(false)["03_Protected_Clearances"]:GetChildren() do if p:IsA("BasePart") then table.insert(reservations,p) end end
 out.vehicleReservations=#reservations
 local extraReservations={}
 local function reserve(n,cf,size) table.insert(extraReservations,{Name=n,CFrame=cf,Size=size}) end
 reserve("LargeArrivalApproach",CFrame.new(3027,3.5,-9),V(12,7,164.5))
 for i,x in {3019,3044,3069} do
  reserve("IntakeApproach"..i,CFrame.new(x,3.2,5),V(10.58,6.4,172.94))
  local minX=math.min(x,3066)-9.47;local maxX=math.max(x,3066)+9.47
  reserve("IntakeMerge"..i,CFrame.new((minX+maxX)/2,3.2,82),V(maxX-minX,6.4,10.58))
 end
 reserve("WashParallelPairLaunch",CFrame.new(3105,3.2,97),V(10.58,6.4,40.94))
 for i,p in {{3104,30},{3156,30},{3104,56},{3156,56},{3144,84},{3116,84}} do reserve("SalesCar"..i,CFrame.new(p[1],4.1,p[2]),V(10.58,6.4,18.94)) end
 for _,z in {30,56} do reserve("ElevatedDisplay"..z,CFrame.new(3130,12.5,z),V(10.9,3.6,17.9)) end
 for _,p in root(false)["02_Vehicle_Routes"]:GetDescendants() do if p:IsA("BasePart") then reserve("Route:"..p.Name,p.CFrame+V(0,4.2,0),V(p.Size.X,7,p.Size.Z)) end end
 out.extraVehicleVolumes=#extraReservations;out.extraVehicleChecks=0

 local bounds={}
 for _,d in defs do
  local lo,hi=d.home,d.home
  for _,p in d.route or {} do lo=lo:Min(p);hi=hi:Max(p) end
  lo-=V(2,0,2);hi+=V(2,6.5,2)
  bounds[d.id]={cf=CFrame.new((lo+hi)/2),size=hi-lo}
 end
 -- Conservative projection; no CanQuery/CanCollide dependency. A clear result
 -- proves visible body pieces cannot intersect a car reservation or other actor.
 local function projected(v,cf)
  local q=cf:ToObjectSpace(v.cf);local h=v.size/2
  local e=V(math.abs(q.RightVector.X)*h.X+math.abs(q.UpVector.X)*h.Y+math.abs(q.LookVector.X)*h.Z,
   math.abs(q.RightVector.Y)*h.X+math.abs(q.UpVector.Y)*h.Y+math.abs(q.LookVector.Y)*h.Z,
   math.abs(q.RightVector.Z)*h.X+math.abs(q.UpVector.Z)*h.Y+math.abs(q.LookVector.Z)*h.Z)
  return q.Position:Abs(),e
 end
 local function intersects(v,cf,size)
  local p,e=projected(v,cf);local h=size/2+e
  return p.X<h.X and p.Y<h.Y and p.Z<h.Z
 end
 for _,d in defs do
  local m=l:FindFirstChild(d.id)
  if not m then table.insert(out.issues,"Missing "..d.id);continue end
  out.actors+=1;out.anchorChecks+=1;out.maxDuration=math.max(out.maxDuration,d.duration)
  if not anchorValid(d,m) then table.insert(out.issues,d.id..":anchor mismatch") end
  for _,p in m:GetChildren() do if p:IsA("BasePart") then
   out.parts+=1;if p.CanCollide or p.CanTouch or p.CanQuery or p.CastShadow or not p.Anchored then table.insert(out.issues,d.id..":unexpected physics "..p.Name) end
  end end
  local nearby={}
  for _,p in nonQuery do
   if worldTop(p)>d.home.Y+.08 and (p.Position-d.home).Magnitude<p.Size.Magnitude/2+7 then table.insert(nearby,p) end
  end
  local times={-1};if sweep then for t=0,d.duration,.25 do table.insert(times,t) end;table.insert(times,d.duration) end
  for _,t in times do
   local issues,cf,g=clearPose(d,t>=0 and t or nil,params,true);out.poseSamples+=1
   for n,v in g do
    out.partChecks+=1
    for _,p in nearby do
     out.nonQueryGeometryChecks+=1
     if intersects(v,p.CFrame,p.Size) and #out.issues<60 then table.insert(out.issues,d.id..":visible nonquery geometry:"..p:GetFullName()) end
    end
    local own=bounds[d.id];local p,e=projected(v,own.cf);local limit=own.size/2+V(.02,.02,.02)
    if (p+e).X>limit.X or (p+e).Y>limit.Y or (p+e).Z>limit.Z then table.insert(out.issues,d.id..":outside actor swept bounds:"..n) end
    for _,reserved in extraReservations do
     out.extraVehicleChecks+=1
     if intersects(v,reserved.CFrame,reserved.Size) and #out.issues<60 then table.insert(out.issues,d.id..":extra vehicle reservation:"..reserved.Name) end
    end
    for _,reserved in reservations do
     out.vehicleReservationChecks+=1
     if intersects(v,reserved.CFrame,reserved.Size) then table.insert(out.issues,d.id..":vehicle reservation:"..reserved.Name) end
    end
    for id,b in bounds do if id~=d.id then
     out.actorSeparationChecks+=1
     if intersects(v,b.cf,b.size) then table.insert(out.issues,d.id..":actor path overlap:"..id) end
    end end
   end
   for _,s in issues do if #out.issues<60 then table.insert(out.issues,d.id.."@"..t..":"..s) end end
  end
 end
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 if not s or s:GetAttribute("Owner")~="Institution7C2B2" then table.insert(out.issues,"Missing bootstrap")
 elseif not RS:IsRunning() and s.Source~=DRIVER then table.insert(out.issues,"Unexpected bootstrap Source") end
 out.sourceVerification=RS:IsRunning() and "EDIT_ONLY_RUNTIME_METADATA_CHECK" or "EXACT_EDIT_SOURCE"
 return out
end

function I.Accept()
 root(true);local a=I.Audit(true);assert(#a.issues==0,"Audit must pass");layer():SetAttribute("Status","ACCEPTED_FRONTAGE_OCCUPATION_PROXY");return a
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

