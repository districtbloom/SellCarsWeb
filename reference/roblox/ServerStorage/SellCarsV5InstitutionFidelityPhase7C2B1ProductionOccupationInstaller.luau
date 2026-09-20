--!nocheck
-- 7C2B1: fourteen anchored specialists; finite occupied-bay episodes.
local I={Version="2026-09-07.phase7c2b1.2"}
local RS=game:GetService("RunService")
local ROOT="SellCars_Dealership_Growth_V5"
local NAME="06_Occupation_Production"
local DRIVER_NAME="SellCarsV5InstitutionProductionOccupationServer"
local DRIVER=[=[-- Persistent shared host; never attach callbacks to a temporary tool caller.
local api=require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C2B1ProductionOccupationInstaller)
local b=Instance.new("BindableFunction");b.Name="RuntimeDispatch"
b.OnInvoke=function(method,...)
 if method=="Start" then return api._Start(...)
 elseif method=="Stop" then return api._Stop(...)
 elseif method=="SetJob" then return api._SetJob(...)
 elseif method=="Cancel" then return api._Cancel(...)
 elseif method=="SetEnabled" then return api._SetEnabled(...)
 elseif method=="GetState" then return api._GetState(...)
 else error("Unknown production occupation command") end
end
b.Parent=script
api._Start()
script.Destroying:Connect(function() api._Stop() end)
]=]
local V=Vector3.new
local C=Color3.fromRGB
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
local defs={
{id="Wash_1",zone="Wash",bay=1,first="DEDICATED",kind="TOOL",tool="PENDANT",role="Meter the occupied rinse cell",anchor="03_Remaining_Production/01_Wash/Tracked_Wash_Cell_1/BayOperator_1",anchorY=0.6,home=V(3031,.685,105),target=V(3042,.685,105),center=V(3066,2.2,108),shirt=C(65,97,114),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=true},
{id="Wash_2",zone="Wash",bay=2,first="DEDICATED",kind="TOOL",tool="PENDANT",role="Meter the occupied rinse cell",anchor="03_Remaining_Production/01_Wash/Tracked_Wash_Cell_2/BayOperator_2",anchorY=0.6,home=V(3031,.685,135),target=V(3042,.685,135),center=V(3066,2.2,132),shirt=C(65,97,114),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=true},
{id="Mechanical_1",zone="Mechanical",bay=1,first="DEDICATED",kind="TOOL",tool="DIAGNOSTIC",role="Check lift diagnostics and service readings",anchor="01_Gold_Slices/Mechanical/Lift_1/LiftOperator",anchorY=0.5,home=V(3070.2,.1,152.9),target=V(3068.15,.1,154.3),center=V(3066,2.2,163),shirt=C(111,84,75),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Mechanical_2",zone="Mechanical",bay=2,first="DEDICATED",kind="TOOL",tool="DIAGNOSTIC",role="Check lift diagnostics and service readings",anchor="01_Gold_Slices/Mechanical/Lift_2/LiftOperator",anchorY=0.5,home=V(3070.2,.1,176.9),target=V(3068.15,.1,178.3),center=V(3066,2.2,187),shirt=C(111,84,75),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false},
{id="Body_Restoration_1",zone="Body_Restoration",bay=1,first="DEDICATED",kind="TOOL",tool="RULE",role="Cross-check frame dimensions against the work order",anchor="03_Remaining_Production/02_Body/Frame_Straightening_Cell_1/BodyBayOperator_1",anchorY=0.6,home=V(3038,.1,227),target=V(3050,.1,227),center=V(3066,2.2,227),shirt=C(162,124,87),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Body_Restoration_2",zone="Body_Restoration",bay=2,first="DEDICATED",kind="TOOL",tool="RULE",role="Cross-check frame dimensions against the work order",anchor="03_Remaining_Production/02_Body/Frame_Straightening_Cell_2/BodyBayOperator_2",anchorY=0.6,home=V(3038,.1,251),target=V(3050,.1,251),center=V(3066,2.2,251),shirt=C(162,124,87),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false},
{id="Tune_Performance_1",zone="Tune_Performance",bay=1,first="DEDICATED",kind="TOOL",tool="DYNO",role="Observe dynamometer and calibration readings",anchor="03_Remaining_Production/03_Tune/Recessed_Rolling_Road_Cell_1/TuneBayOperator_1",anchorY=0.6,home=V(3037,.1,295),target=V(3023,.1,295),center=V(3066,2.2,295),shirt=C(73,98,126),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Tune_Performance_2",zone="Tune_Performance",bay=2,first="DEDICATED",kind="TOOL",tool="DYNO",role="Observe dynamometer and calibration readings",anchor="03_Remaining_Production/03_Tune/Recessed_Rolling_Road_Cell_2/TuneBayOperator_2",anchorY=0.6,home=V(3037,.1,319),target=V(3023,.1,319),center=V(3066,2.2,319),shirt=C(73,98,126),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false},
{id="Paint_Exterior_1",zone="Paint_Exterior",bay=1,first="DEDICATED",kind="TOOL",tool="SWATCH",role="Verify the selected finish against the booth programme",anchor="01_Gold_Slices/Paint_Exterior/Mix_Bank_And_Rare_Finishes/BenchOperator",anchorY=0.5,home=V(3234.2,.1,285),target=V(3240,.1,285),center=V(3194,2.2,295),shirt=C(193,190,172),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Paint_Exterior_2",zone="Paint_Exterior",bay=2,first="DEDICATED",kind="TOOL",tool="SWATCH",role="Verify the selected finish against the booth programme",anchor="01_Gold_Slices/Paint_Exterior/Film_Cutting_And_Glass/BenchOperator",anchorY=0.5,home=V(3234.2,.1,321),target=V(3240,.1,321),center=V(3194,2.2,319),shirt=C(193,190,172),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false},
{id="Detail_QC_1",zone="Detail_QC",bay=1,first="DEDICATED",kind="TOOL",tool="LIGHT",role="Check the inspection light and finish checklist",anchor="03_Remaining_Production/04_Detail/Correction_Light_Cell_1/DetailBayOperator_1",anchorY=0.6,home=V(3222,.1,227),target=V(3212,.1,227),center=V(3194,2.2,227),shirt=C(102,119,93),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Detail_QC_2",zone="Detail_QC",bay=2,first="DEDICATED",kind="TOOL",tool="LIGHT",role="Check the inspection light and finish checklist",anchor="03_Remaining_Production/04_Detail/Correction_Light_Cell_2/DetailBayOperator_2",anchorY=0.6,home=V(3222,.1,251),target=V(3212,.1,251),center=V(3194,2.2,251),shirt=C(102,119,93),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false},
{id="Photo_Listing_1",zone="Photo_Listing",bay=1,first="DEDICATED",kind="TOOL",tool="REMOTE",role="Review capture and trigger the fixed studio remotely",anchor="03_Remaining_Production/05_Photo/Editorial_Turntable_Studio_1/PhotoBayOperator_1",anchorY=0.6,home=V(3222,.1,163),target=V(3234,.1,158),center=V(3194,2.2,163),shirt=C(81,84,94),skin=C(184,135,97),hair=C(43,35,29),duration=6,cap=false},
{id="Photo_Listing_2",zone="Photo_Listing",bay=2,first="DEDICATED",kind="TOOL",tool="REMOTE",role="Review capture and trigger the fixed studio remotely",anchor="03_Remaining_Production/05_Photo/Editorial_Turntable_Studio_2/PhotoBayOperator_2",anchorY=0.6,home=V(3222,.1,187),target=V(3234,.1,182),center=V(3194,2.2,187),shirt=C(81,84,94),skin=C(215,172,137),hair=C(43,35,29),duration=6,cap=false}
}
-- Placement01: apply after frontage overrides and before cached timelines.
local placementSource=game.ServerStorage:FindFirstChild("SellCarsV5CampusPlacement01")
if placementSource then
 local copy=placementSource:Clone();local ok,api=pcall(require,copy);copy:Destroy();assert(ok,api)
 api.ApplyOccupation(defs)
end
local byId={};for _,d in defs do byId[d.id]=d end
local function face(a,b) return CFrame.lookAt(a,V(b.X,a.Y,b.Z)) end
local function ease(t) return t*t*(3-2*t) end
local function stateAt(d,t)
 local cf=face(d.home,d.target)
 if not t or t>=6 then return cf,"IDLE",0 end
 if t<1 then return cf,"ATTEND",t end
 if t<5 then return cf,"VERIFY",t-1 end
 return cf,"LOWER",t-5
end
local function geometry(d,t,overrideBlend)
 local cf,kind,u=stateAt(d,t);local result={}
 local function p(n,size,localcf,col,mat,shape)
  result[n]={size=size,cf=cf*localcf,col=col,mat=mat or Enum.Material.SmoothPlastic,shape=shape}
 end
 local skin=d.skin;local dark=C(37,40,43);local pants=d.zone=="Paint_Exterior" and d.shirt or C(52,57,59)
 local active=kind~="IDLE" and kind~="LOWER" and kind~="TURN" and kind~="WALK"
 local blend=active and (kind=="ATTEND" and ease(u) or 1) or (kind=="LOWER" and 1-ease(u) or 0)
 blend=overrideBlend or blend
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
 p("IdentityPatch",V(.37,.18,.05),CFrame.new(.44,3.67,-.47),C(205,190,153),Enum.Material.Fabric)
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

 -- Tool silhouettes share the held-hand attachment, not the rear clipboard assets.
 local held=CFrame.new(hands.L+V(.25,.18,-.03))*CFrame.Angles(math.rad(58),0,0)
 if d.tool=="RULE" then
  p("MeasuringRule",V(1.85,.08,.26),held,C(167,167,149),Enum.Material.Metal)
  p("CaliperJaw",V(.1,.12,.62),held*CFrame.new(-.68,0,.14),dark,Enum.Material.Metal)
  for i=1,5 do p("RuleTick"..i,V(.025,.016,.15),held*CFrame.new(-.5+i*.26,.06,0),dark) end
 elseif d.tool=="SWATCH" then
  for i,col in {C(170,74,52),C(58,88,98),C(196,161,94)} do
   p("FinishSwatch"..i,V(.42,.05,1),held*CFrame.new((i-2)*.24,.035*i,0)*CFrame.Angles(0,(i-2)*.21,0),col,Enum.Material.Metal)
  end
  p("SwatchRivet",V(.12,.19,.12),held*CFrame.new(0,.11,.32),dark)
 elseif d.tool=="LIGHT" then
  p("InspectionLightGrip",V(.28,.18,.8),held,dark)
  p("InspectionLightFace",V(.24,.055,.56),held*CFrame.new(0,.12,-.05),C(215,218,195))
  p("FoldedMicrofibre",V(.8,.08,.61),CFrame.new(hands.R+V(.1,.18,0)),C(185,157,104),Enum.Material.Fabric)
 else
  local w=d.tool=="REMOTE" and .48 or .88
  p("HandheldControl",V(w,.15,1.03),held,dark)
  p("Readout",V(w*.72,.025,.49),held*CFrame.new(0,.095,-.15),C(99,142,145))
  for i=1,3 do p("ControlKey"..i,V(.1,.035,.1),held*CFrame.new((i-2)*w*.22,.1,.28),i==3 and C(167,87,65) or C(161,162,149)) end
  if d.tool=="PENDANT" then p("SafetyStop",V(.23,.1,.23),held*CFrame.new(0,.16,.06),C(163,62,43)) end
 end
 if d.zone=="Wash" then p("WaterproofApron",V(1.55,2.05,.06),CFrame.new(0,2.89,-.49),C(48,74,85)) end
 if d.zone=="Tune_Performance" or d.zone=="Body_Restoration" then
  for _,x in {-1,1} do p("HearingProtection"..x,V(.25,.59,.47),h*CFrame.new(x*.68,.08,0),C(61,65,67)) end
  p("HearingBand",V(1.42,.12,.16),h*CFrame.new(0,.68,0),dark)
 end
 if d.zone=="Body_Restoration" or d.zone=="Mechanical" then
  p("SafetySpectacles",V(.98,.22,.08),h*CFrame.new(0,.04,-.61),C(113,131,130))
 end
 return result,cf,kind,blend
end

local function anchorValid(d,m)
 local ref=m:FindFirstChild("ExistingWorkAnchor");local a=ref and ref.Value
 return a and a:IsDescendantOf(root(false)) and math.abs(a.Position.X-d.home.X)<.02 and math.abs(a.Position.Z-d.home.Z)<.02 and math.abs(a.Position.Y-d.anchorY)<.03
end
local function render(m,d,t,blend)
 local g,cf,kind,w=geometry(d,t,blend)
 for n,v in g do local p=m:FindFirstChild(n);if p and p:IsA("BasePart") then p.CFrame=v.cf;p.Size=v.size end end
 m:SetAttribute("FootCFrame",cf);m:SetAttribute("Action",kind);m:SetAttribute("PoseBlend",w)
end
local function restore(l,check)
 for _,ref in l.Restoration:GetChildren() do
  local p=assert(ref.Value,"Missing original staff part; preserve layer")
  if check then assert(p.Transparency==1,"Original staff part edited; preserve layer")
  else p.Transparency=ref:GetAttribute("Transparency") end
 end
end
function I.Install()
 root(true)
 if layer() then assert(layer():GetAttribute("SourceVersion")==I.Version,"Unexpected version");return {alreadyInstalled=true} end
 assert(not game.ServerScriptService:FindFirstChild(DRIVER_NAME),"Unowned bootstrap")
 local targets={}
 for _,d in defs do
  resolve(d.anchor)
  local n=string.format("Staff_%02d_%s_%s",d.bay,d.zone,d.bay==1 and "LEAD" or "TECH")
  local m=assert(root(false)["08_Institution_Production_A"][d.zone]["08_Staff_Aisle_and_Occupation"]:FindFirstChild(n),"Legacy worker missing")
  assert(m:GetAttribute("OccupationPrototype"),"Unowned original model")
  for _,p in m:GetDescendants() do if p:IsA("BasePart") then assert(not p.CanCollide,"Unexpected original collision");table.insert(targets,p) end end
 end
 assert(#targets==56,"Expected fourteen four-part legacy figures")
 local a=root(false)["10_Institution_Fidelity_R1"]["06_Atmosphere"]
 assert(a:FindFirstChild("05_Occupation_Rear"),"7C2A dependency")
 local l=Instance.new("Folder");l.Name=NAME;l:SetAttribute("SourceVersion",I.Version);l:SetAttribute("Status","CANDIDATE")
 l:SetAttribute("Enabled",true);l:SetAttribute("MaxActive",14);l:SetAttribute("UpdateHz",10);l.Parent=a
 local f=Instance.new("Folder");f.Name="Restoration";f.Parent=l
 local ok,err=pcall(function()
  for i,p in targets do
   local v=Instance.new("ObjectValue");v.Name=string.format("StaffPart_%02d",i);v.Value=p;v:SetAttribute("Transparency",p.Transparency)
   v:SetAttribute("OriginalCanCollide",p.CanCollide);v:SetAttribute("OriginalCanQuery",p.CanQuery);v:SetAttribute("OriginalCanTouch",p.CanTouch);v.Parent=f;p.Transparency=1
  end
  for _,d in defs do
   local m=Instance.new("Model");m.Name=d.id;m.Parent=l
   for k,v in {BundleId="Institution.ProductionOccupation."..d.id,FunctionId=d.zone,ZoneId=d.zone,FidelityRole="STORY",PhaseMin=d.first,
    Ancestor="Player-operated tool -> Dedicated operator -> Institution specialist",InheritanceRule="UPGRADE",AssetStatus="PROXY",
    CollisionClass="NONE",InteractionAnchor="ExistingWorkAnchor",FXSocket="",OccupationRole=d.role,BayIndex=d.bay,NoGameplayEconomy=true} do m:SetAttribute(k,v) end
   local ref=Instance.new("ObjectValue");ref.Name="ExistingWorkAnchor";ref.Value=resolve(d.anchor);ref.Parent=m
   assert(anchorValid(d,m),"Changed anchor")
   for n,v in geometry(d,nil) do
    local p=Instance.new("Part");p.Name=n;p.Size=v.size;p.CFrame=v.cf;p.Color=v.col;p.Material=v.mat;p.Shape=v.shape or Enum.PartType.Block
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m
   end
   m:SetAttribute("BayCenter",d.center);m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0);m:SetAttribute("CompletedCycles",0)
   render(m,d,nil)
  end
  local s=Instance.new("Script");s.Name=DRIVER_NAME;s.Source=DRIVER;s:SetAttribute("Owner","Institution7C2B1");s.Parent=game.ServerScriptService
 end)
 if not ok then restore(l,false);l:Destroy();error(err) end
 return {actors=#defs,hiddenParts=#targets}
end
function I.Uninstall()
 root(true);local l=layer();if not l then return true end
 restore(l,true)
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 if s then assert(s:GetAttribute("Owner")=="Institution7C2B1" and s.Source==DRIVER,"Bootstrap edited; preserve it") end
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
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=false
 local f=workspace:Raycast(cf.Position+V(0,.25,0),V(0,-.6,0),rp)
 if not f or math.abs(f.Position.Y-cf.Position.Y)>.12 then table.insert(hits,"Unsupported foot position") end
 return hits,cf,g
end

local function eligible(d,car)
 if typeof(car)~="Instance" or not car:IsA("Model") or not car:IsDescendantOf(root(false)) or not car.PrimaryPart or not car.PrimaryPart:IsDescendantOf(car) or car:GetAttribute("LargeArrival") then return false end
 if car:GetAttribute("V5TrafficProxy")~=true and car:GetAttribute("V5AtmosphereEligible")~=true then return false end
 local p=car.PrimaryPart.Position
 return math.abs(p.X-d.center.X)<2 and math.abs(p.Z-d.center.Z)<2 and p.Y>.8 and p.Y<5
end
local function proofState(d,car)
 local state=car:GetAttribute("JourneyState")
 return state=="SERVICING_"..d.zone.."_BAY_"..d.bay or (state=="PARALLEL_OCCUPIED_BAY_"..d.bay and car:GetAttribute("RequiredFunctions")==d.zone)
end
local conn,currentLayer,records
local jobs,seen={},{}
local clock,accumulator=0,0
local counts={started=0,completed=0,cancelled=0,blocked=0,ticks=0,maxActive=0}
local function permitted()
 return currentLayer and currentLayer:IsDescendantOf(workspace) and currentLayer:GetAttribute("Enabled") and root(false):GetAttribute("ProgressionState")=="INSTITUTION"
end
function I._GetState()
 local actors={};local active,releasing,refs=0,0,0
 for _,d in defs do
  local m=records and records[d.id];local j=jobs[d.id]
  if m and m.Parent then table.insert(actors,{id=d.id,active=j~=nil,action=m:GetAttribute("Action"),time=m:GetAttribute("TaskTime"),completed=m:GetAttribute("CompletedCycles"),blocked=m:GetAttribute("Blocked")}) end
 end
 for _,j in jobs do if j.car then active+=1 else releasing+=1 end end
 for _ in seen do refs+=1 end
 local c={};for k,v in counts do c[k]=v end
 local rc=0;if records then for _ in records do rc+=1 end end
 return {running=conn~=nil,connections=conn and 1 or 0,clock=clock,activeJobs=active,releasing=releasing,proofReferences=refs,retainedRecords=rc,actors=actors,counters=c}
end
function I._SetJob(id,car,duration)
 local d=byId[id];local m=records and records[id]
 if not conn or not d or not m or not m:IsDescendantOf(currentLayer) then return false,"INACTIVE_OR_UNKNOWN" end
 if not permitted() then return false,"DISABLED" end
 if not anchorValid(d,m) then return false,"MISSING_ANCHOR" end
 if not eligible(d,car) then return false,"INELIGIBLE_OR_WRONG_BAY" end
 if type(duration)~="number" or duration~=duration or duration<=0 or duration==math.huge then return false,"INVALID_DURATION" end
 if jobs[id] then return false,"BUSY" end
 jobs[id]={car=car,t=0,duration=math.min(duration,6)}
 m:SetAttribute("TaskActive",true);m:SetAttribute("Blocked",false);m:SetAttribute("TaskTime",0)
 counts.started+=1;return true
end
function I._Cancel(id)
 local j=jobs[id];local m=records and records[id]
 if j and j.car then
  j.car=nil;j.proof=nil;j.release=0;j.from=m and m:GetAttribute("PoseBlend") or 0;counts.cancelled+=1
 end
 return j~=nil
end
local function clearAll()
 for id in jobs do
  local m=records and records[id];if m and m.Parent then render(m,byId[id],nil);m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0) end
 end
 jobs={};seen={}
end
function I._Stop()
 if conn then conn:Disconnect();conn=nil end
 clearAll();records=nil;currentLayer=nil;accumulator=0
end
function I._SetEnabled(v)
 assert(type(v)=="boolean");local l=assert(layer());l:SetAttribute("Enabled",v)
 if not v then clearAll() end
 return v
end
local function observe()
 local p=root(false):FindFirstChild("07_Dynamic_Route_Proof");local f=p and p:FindFirstChild("Traffic_Proxies");local alive={}
 if f then for _,car in f:GetChildren() do
  if car:IsA("Model") then
   alive[car]=true;local state=car:GetAttribute("JourneyState")
   if seen[car]~=state then
    local matched,accepted=false,false
    for _,d in defs do if proofState(d,car) then matched=true;local ok=I._SetJob(d.id,car,6);if ok then jobs[d.id].proof=true;accepted=true end end end
    if not matched or accepted then seen[car]=state end
   end
  end
 end end
 for car in seen do if not alive[car] then seen[car]=nil end end
end
local function tick(dt)
 clock+=dt;counts.ticks+=1
 if not currentLayer or not currentLayer:IsDescendantOf(workspace) then I._Stop();return end
 for id,m in records do if not m:IsDescendantOf(currentLayer) then records[id]=nil;jobs[id]=nil end end
 if not permitted() then clearAll();return end
 observe()
 local params=overlapParams();local active=0
 for id,j in jobs do
  local d=byId[id];local m=records[id]
  if not anchorValid(d,m) then
   m:SetAttribute("Blocked",true);m:SetAttribute("Action","MISSING_ANCHOR");m:SetAttribute("TaskActive",false);jobs[id]=nil;continue
  end
  if j.car and (not eligible(d,j.car) or (j.proof and not proofState(d,j.car))) then I._Cancel(id) end
  local t,blend,done
  if j.car then j.t+=math.min(dt,.15);t=math.min(6,j.t/j.duration*6);done=t>=6;active+=1
  else j.release+=math.min(dt,.15);t=5+math.clamp(j.release/.6,0,1);blend=j.from*(1-ease(math.clamp(j.release/.6,0,1)));done=j.release>=.6 end
  local issues=clearPose(d,t,params,false)
  if #issues>0 then issues=clearPose(d,t,params,true) end
  if #issues>0 then m:SetAttribute("Blocked",true);m:SetAttribute("Action","BLOCKED");m:SetAttribute("TaskActive",false);jobs[id]=nil;counts.blocked+=1;continue end
  render(m,d,t,blend);m:SetAttribute("TaskTime",j.t)
  if done then
   if j.car then counts.completed+=1;m:SetAttribute("CompletedCycles",m:GetAttribute("CompletedCycles")+1) end
   jobs[id]=nil;m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0);render(m,d,nil)
  end
 end
 counts.maxActive=math.max(counts.maxActive,active)
end
function I._Start()
 assert(RS:IsRunning() and RS:IsServer(),"Server runtime only")
 if conn then return I._GetState() end
 currentLayer=assert(layer(),"Install7C2B1 first");records={};jobs={};seen={};clock=0;accumulator=0
 for _,d in defs do local m=currentLayer:FindFirstChild(d.id);if m then records[d.id]=m;render(m,d,nil);m:SetAttribute("TaskActive",false);m:SetAttribute("TaskTime",0) end end
 conn=RS.Heartbeat:Connect(function(dt)
  accumulator+=dt;if accumulator<.1 then return end
  local elapsed=accumulator;accumulator=0
  local ok,err=pcall(tick,elapsed);if not ok then I._Stop();warn("Production occupation stopped safely: "..tostring(err)) end
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
function I.SetJob(id,car,duration) return dispatch("SetJob",id,car,duration) end
function I.Cancel(id) return dispatch("Cancel",id) end
function I.SetEnabled(v) return dispatch("SetEnabled",v) end
function I.GetState() return dispatch("GetState") end
function I.Preview(id,t)
 root(true);local d=assert(byId[id]);assert(type(t)=="number" and t>=0 and t<=6);render(assert(layer()[id]),d,t)
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
 if out.restorationRecords~=56 then table.insert(out.issues,"Restoration count changed") end
 for _,ref in l.Restoration:GetChildren() do local p=ref.Value
  if not p or p.Transparency~=1 or p.CanCollide~=ref:GetAttribute("OriginalCanCollide") or p.CanQuery~=ref:GetAttribute("OriginalCanQuery") or p.CanTouch~=ref:GetAttribute("OriginalCanTouch") then table.insert(out.issues,"Legacy suppression changed") end
 end
 local reservations={};for _,p in root(false)["03_Protected_Clearances"]:GetChildren() do if p:IsA("BasePart") then table.insert(reservations,p) end end
 out.vehicleReservations=#reservations
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
 if not s or s:GetAttribute("Owner")~="Institution7C2B1" then table.insert(out.issues,"Missing bootstrap")
 elseif not RS:IsRunning() and s.Source~=DRIVER then table.insert(out.issues,"Unexpected bootstrap Source") end
 out.sourceVerification=RS:IsRunning() and "EDIT_ONLY_RUNTIME_METADATA_CHECK" or "EXACT_EDIT_SOURCE"
 return out
end

function I.Accept()
 root(true);local a=I.Audit(true);assert(#a.issues==0,"Audit must pass");layer():SetAttribute("Status","ACCEPTED_PRODUCTION_OCCUPATION_PROXY");return a
end
return I

