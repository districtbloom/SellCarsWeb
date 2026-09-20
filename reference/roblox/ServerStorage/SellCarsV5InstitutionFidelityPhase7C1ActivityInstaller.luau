--!nocheck
-- 7C1: finite activity leases and two Wash rinse cells. No audio assets or machine motion.
local I = {Version = "2026-09-07.phase7c1.2"}
local RS = game:GetService("RunService")
local ROOT = "SellCars_Dealership_Growth_V5"
local NAME = "04_Activity_Wash"
local DRIVER_NAME = "SellCarsV5InstitutionAtmosphereServer"
local MODULE_NAME = "SellCarsV5InstitutionFidelityPhase7C1ActivityInstaller"
local DRIVER = [[-- Source owned by Institution 7C1. This persistent host owns callback lifetimes.
local api = require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C1ActivityInstaller)
local bridge = Instance.new("BindableFunction")
bridge.Name = "RuntimeDispatch"
bridge.OnInvoke = function(method, ...)
 if method == "Start" then return api._Start(...)
 elseif method == "Stop" then return api._Stop(...)
 elseif method == "SetJob" then return api._SetJob(...)
 elseif method == "Cancel" then return api._Cancel(...)
 elseif method == "GetState" then return api._GetState(...)
 else error("Unknown Institution activity request") end
end
bridge.Parent = script
api._Start()
script.Destroying:Connect(function() api._Stop() end)
]]
local connection, currentLayer, channels
local jobs, seenProof = {}, {}
local clock, accumulator = 0, 0
local counts = {accepted=0,rejected=0,completed=0,cancelled=0,maxActive=0,ticks=0}
local function root(edit)
 assert(game.PlaceId == 125334614375606, "Wrong place")
 if edit then assert(not RS:IsRunning(), "Edit only") end
 return assert(workspace:FindFirstChild(ROOT), "V5 missing")
end
local function layer()
 local r = workspace:FindFirstChild(ROOT)
 local f = r and r:FindFirstChild("10_Institution_Fidelity_R1")
 local a = f and f:FindFirstChild("06_Atmosphere")
 return a and a:FindFirstChild(NAME)
end
local function metadata(m, n, role)
 for k,v in {BundleId="Institution.Activity."..n..".FidelityR1",FunctionId="Wash",ZoneId="Wash",FidelityRole=role,
 PhaseMin="DEDICATED",Ancestor="Manual wash -> controlled rinse -> occupied-bay metered rinse",
 InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="NONE",InteractionAnchor="",FXSocket="ReadOnlyNozzleReferences"} do m:SetAttribute(k,v) end
end
local function findWash()
 return root(false)["10_Institution_Fidelity_R1"]["03_Remaining_Production"]["01_Wash"]
end
local function makeCell(parent, bay)
 local m = Instance.new("Model"); m.Name="Wash_"..bay; metadata(m,m.Name,"UTILITY"); m:SetAttribute("BayIndex",bay); m.Parent=parent
 local z = bay == 1 and 108 or 132
 m:SetAttribute("BayCenter",Vector3.new(3066,2.2,z))
 m:SetAttribute("MaxLeaseSeconds",20);m:SetAttribute("State","IDLE")
 m:SetAttribute("AllowedMin",Vector3.new(3050,.6,z-9));m:SetAttribute("AllowedMax",Vector3.new(3082,12,z+9))
 local host=Instance.new("Part");host.Name="InvisibleSocketHost";host.Size=Vector3.new(.1,.1,.1);host.Position=Vector3.new(3057,8.4,z)
 host.Anchored=true;host.Transparency=1;host.CanCollide=false;host.CanTouch=false;host.CanQuery=false;host.CastShadow=false;host.Parent=m
 local gantry=findWash()["Tracked_Wash_Cell_"..bay]
 local nozzleList={}
 for _,v in gantry:GetDescendants() do if v:IsA("Attachment") and v:GetAttribute("EffectKind")=="RINSE_SPRAY" then table.insert(nozzleList,v) end end
 table.sort(nozzleList,function(a,b) return a.Name<b.Name end)
 assert(#nozzleList==11,"Expected six side and five top rinse nozzles")
 for i,source in nozzleList do
  local last=tonumber(source.Name:match("_([%-%.%d]+)$"))
  local selected=(source.Name:sub(1,3)=="Top" and math.abs(last)<=1) or (source.Name:sub(1,4)=="Side" and last==4.8)
  if not selected then continue end -- Five readable jets per bay; eleven physical nozzles remain available.
  local a=Instance.new("Attachment");a.Name=string.format("Nozzle_%02d",i);a.Parent=host;a.WorldCFrame=source.WorldCFrame
  for strand=2,2 do
   local b=Instance.new("Attachment");b.Name=string.format("End_%02d_%d",i,strand);b.Parent=host;b.WorldPosition=source.WorldPosition
   local beam=Instance.new("Beam");beam.Name=string.format("Rinse_%02d_%d",i,strand);beam.Attachment0=a;beam.Attachment1=b
   beam.Texture="";beam.Enabled=false;beam.FaceCamera=true;beam.Segments=2;beam.Width0=.035;beam.Width1=.18
   beam.Color=ColorSequence.new(Color3.fromRGB(192,217,223));beam.Transparency=NumberSequence.new(.64)
   beam.LightEmission=0;beam.LightInfluence=.75;beam:SetAttribute("Strand",strand);beam:SetAttribute("NozzleIndex",i)
   local ref=Instance.new("ObjectValue");ref.Name="NozzleReference";ref.Value=source;ref.Parent=beam;beam.Parent=host
  end
 end
end
local function silentContracts(parent)
 local f=Instance.new("Folder");f.Name="Audio_Requirements";f.Parent=parent
 for _,row in {{"Pump","PumpHumSocket",32,.12},{"Rinse","WashCycleFX_1",26,.2},{"Dryer","DryerAirSocket_1",30,.16}} do
  local c=Instance.new("Configuration");c.Name=row[1];c:SetAttribute("Status","ASSET_PENDING");c:SetAttribute("AssetId","")
  c:SetAttribute("SuggestedMaxDistance",row[3]);c:SetAttribute("SuggestedVolume",row[4]);c:SetAttribute("PlaybackShipped",false)
  local r=Instance.new("ObjectValue");r.Name="ExistingSocket";r.Value=assert(findWash():FindFirstChild(row[2],true));r.Parent=c;c.Parent=f
 end
end
local function resetCell(cell)
 cell:SetAttribute("State","IDLE")
 cell:SetAttribute("ActiveStrands",0)
 for _,v in cell:GetDescendants() do if v:IsA("Beam") then v.Enabled=false;if v.Attachment0 and v.Attachment1 then v.Attachment1.WorldPosition=v.Attachment0.WorldPosition end end end
end
function I.Install()
 root(true)
 local prior=layer()
 if prior then assert(prior:GetAttribute("SourceVersion")==I.Version,"Unexpected activity version"); return I.Audit() end
 assert(not game.ServerScriptService:FindFirstChild(DRIVER_NAME),"Unowned runtime name already exists")
 local parent=root(false)["10_Institution_Fidelity_R1"]["06_Atmosphere"]
 assert(parent:FindFirstChild("03_Lighting_Hierarchy"),"7B required")
 local l=Instance.new("Folder");l.Name=NAME;l:SetAttribute("SourceVersion",I.Version);l:SetAttribute("Status","CANDIDATE")
 l:SetAttribute("ActivityEnabled",true);l:SetAttribute("AudioStatus","ASSET_PENDING");l:SetAttribute("UpdateHz",10)
 l:SetAttribute("MaximumConcurrentCells",2);l:SetAttribute("MaximumStrands",10);l.Parent=parent
 local ok,err=pcall(function()
  for bay=1,2 do makeCell(l,bay) end
  silentContracts(l)
  local s=Instance.new("Script");s.Name=DRIVER_NAME;s.Source=DRIVER;s:SetAttribute("Owner","Institution7C1");s.Parent=game.ServerScriptService
 end)
 if not ok then l:Destroy();error(err) end
 return I.Audit()
end
function I.Uninstall()
 root(true)
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 if s then assert(s:GetAttribute("Owner")=="Institution7C1" and s.Source==DRIVER,"Runtime was edited; preserve it");s:Destroy() end
 local l=layer();if l then l:Destroy() end
 return {removedLayer=layer()==nil,removedRuntime=game.ServerScriptService:FindFirstChild(DRIVER_NAME)==nil}
end
function I.Accept()
 root(true);local a=I.Audit();assert(#a.issues==0,"Audit must pass");layer():SetAttribute("Status","ACCEPTED_CONTROL_AND_RINSE_PROXY");return a
end
local function eligible(car)
 return typeof(car)=="Instance" and car:IsA("Model") and car:IsDescendantOf(root(false))
 and car.PrimaryPart and car.PrimaryPart:IsDescendantOf(car) and not car:GetAttribute("LargeArrival")
 and (car:GetAttribute("V5AtmosphereEligible")==true or car:GetAttribute("V5TrafficProxy")==true)
end
local function occupied(cell,car)
 if not eligible(car) then return false end
 local p=car.PrimaryPart.Position;local c=cell:GetAttribute("BayCenter")
 return math.abs(p.X-c.X)<2 and math.abs(p.Z-c.Z)<2 and p.Y>c.Y-1.4 and p.Y<c.Y+2.8
end
function I._SetJob(bay,car,duration)
 if not connection or not channels or (bay~=1 and bay~=2) or not occupied(channels[bay],car) then counts.rejected+=1;return false,"INACTIVE_OR_WRONG_OCCUPANCY" end
 if type(duration)~="number" or duration~=duration or duration<=0 or duration==math.huge then counts.rejected+=1;return false,"INVALID_DURATION" end
 if currentLayer:GetAttribute("ActivityEnabled")==false or root(false):GetAttribute("ProgressionState")~="INSTITUTION" then counts.rejected+=1;return false,"DISABLED" end
 if jobs[bay] then counts.rejected+=1;return false,"BUSY" end
 jobs[bay]={car=car,untilTime=clock+math.min(duration,20),started=clock}
 counts.accepted+=1;return true
end
function I._Cancel(bay)
 if jobs[bay] then jobs[bay]=nil;counts.cancelled+=1 end
 if channels and channels[bay] then resetCell(channels[bay]) end
end
local function clearAll()
 for bay=1,2 do I._Cancel(bay) end
end
function I._Stop()
 if connection then connection:Disconnect();connection=nil end
 clearAll();jobs={};seenProof={};channels=nil;currentLayer=nil
end
local function proofState(car,bay)
 local state=car:GetAttribute("JourneyState")
 return state=="SERVICING_Wash_BAY_"..bay or (state=="PARALLEL_OCCUPIED_BAY_"..bay and car:GetAttribute("RequiredFunctions")=="Wash")
end
local function observeProof()
 local r=root(false);local p=r:FindFirstChild("07_Dynamic_Route_Proof");local folder=p and p:FindFirstChild("Traffic_Proxies")
 local alive={}
 if folder then for _,car in folder:GetChildren() do
  alive[car]=true;local state=car:GetAttribute("JourneyState")
  if seenProof[car]~=state then
   seenProof[car]=state
   for bay=1,2 do if proofState(car,bay) and occupied(channels[bay],car) then
    local ok=I._SetJob(bay,car,20);if ok then jobs[bay].proof=true end
   end end
  end
 end end
 for car in seenProof do if not alive[car] then seenProof[car]=nil end end
end
local function renderCell(cell,job)
 local car=job.car
 local visible={}
 for _,p in car:GetDescendants() do if p:IsA("BasePart") and p.Transparency<.95 and p.CanQuery then table.insert(visible,p) end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=visible
 local equipment=RaycastParams.new();equipment.FilterType=Enum.RaycastFilterType.Include;equipment.FilterDescendantsInstances={findWash()}
 local center=cell:GetAttribute("BayCenter")
 local count=0
 for _,beam in cell.InvisibleSocketHost:GetChildren() do if beam:IsA("Beam") then
  local source=beam.NozzleReference.Value
  if not source or not source:IsDescendantOf(root(false)) or source.Parent.Transparency>=.95 then beam.Enabled=false;continue end
  local pos=source.WorldPosition
  local strand=beam:GetAttribute("Strand")-2
  -- Directed into the near portion of the car from each real fixed nozzle.
  local targetX=pos.Y<3 and 3057 or 3059.5
  local target=Vector3.new(targetX+strand*.28,math.min(pos.Y,car.PrimaryPart.Position.Y+1),center.Z+(pos.Z-center.Z)*.42+strand*.24)
  local direction=target-pos
  local hit=workspace:Raycast(pos,direction,params)
  if hit then
   local d=hit.Position-pos;local start=pos+d.Unit*.32
   if workspace:Raycast(start,hit.Position-start-d.Unit*.04,equipment) then hit=nil end
  end
  if hit then
   beam.Attachment0.WorldCFrame=source.WorldCFrame;beam.Attachment1.WorldPosition=hit.Position
   beam.Width1=.16+.03*math.sin(clock*13+beam:GetAttribute("NozzleIndex")+strand)
   beam.Transparency=NumberSequence.new(.59+.13*math.sin(clock*11+strand*2))
   beam.Enabled=true;count+=1
  else beam.Enabled=false end
 end end
 cell:SetAttribute("State",count>0 and "RINSING" or "NO_VISIBLE_TARGET")
 cell:SetAttribute("ActiveStrands",count)
end
local function tick(dt)
 clock+=dt;counts.ticks+=1
 if not currentLayer or not currentLayer:IsDescendantOf(workspace) or not workspace:FindFirstChild(ROOT) then I._Stop();return end
 if currentLayer:GetAttribute("ActivityEnabled")==false or root(false):GetAttribute("ProgressionState")~="INSTITUTION" then clearAll();return end
 observeProof()
 local active=0
 for bay=1,2 do
  local job=jobs[bay];local cell=channels[bay]
  if job then
   if clock>=job.untilTime then jobs[bay]=nil;counts.completed+=1;resetCell(cell)
   elseif not occupied(cell,job.car) or (job.proof and not proofState(job.car,bay)) then I._Cancel(bay)
   else renderCell(cell,job);active+=1 end
  end
 end
 counts.maxActive=math.max(counts.maxActive,active)
end
function I._Start()
 assert(RS:IsRunning() and RS:IsServer(),"Server runtime only")
 if connection then return I._GetState() end
 currentLayer=assert(layer(),"Install7C1 first");channels={currentLayer.Wash_1,currentLayer.Wash_2}
 jobs={};seenProof={};clock=0;accumulator=0
 for _,c in channels do resetCell(c) end
 connection=RS.Heartbeat:Connect(function(dt)
  accumulator+=dt
  if accumulator<.1 then return end
  local elapsed=accumulator;accumulator=0
  local ok,err=pcall(tick,elapsed)
  if not ok then I._Stop();warn("Institution atmosphere stopped safely: "..tostring(err)) end
 end)
 return I._GetState()
end
function I._GetState()
 local l=layer();local active,beams,refs=0,0,0
 for _ in jobs do active+=1 end
 for _ in seenProof do refs+=1 end
 if l then for _,v in l:GetDescendants() do if v:IsA("Beam") and v.Enabled then beams+=1 end end end
 local c={};for k,v in counts do c[k]=v end
 return {running=connection~=nil,connections=connection and 1 or 0,activeJobs=active,enabledStrands=beams,proofReferences=refs,counters=c,clock=clock}
end

-- A persistent bootstrap owns the callbacks. Callers (including Studio's separate
-- module cache) use this one server-only bridge; their destruction cannot kill the timer.
local function dispatch(method,...)
 assert(RS:IsRunning() and RS:IsServer(),"Server runtime only")
 local host=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 local bridge=host and host:FindFirstChild("RuntimeDispatch")
 if not bridge then
  if method=="GetState" then return {running=false,connections=0,activeJobs=0,enabledStrands=0,proofReferences=0,bootstrapReady=false} end
  return false,"BOOTSTRAP_NOT_READY"
 end
 return bridge:Invoke(method,...)
end
function I.Start() return dispatch("Start") end
function I.Stop() return dispatch("Stop") end
function I.SetJob(bay,car,duration) return dispatch("SetJob",bay,car,duration) end
function I.Cancel(bay) return dispatch("Cancel",bay) end
function I.GetState() return dispatch("GetState") end

function I.Audit()
 local l=assert(layer());local out={issues={},parts=0,visibleParts=0,solids=0,beams=0,sourceReferences=0,endpointChecks=0,missingAudio=3,scripts=0}
 for _,v in l:GetDescendants() do
  if v:IsA("BasePart") then out.parts+=1;if v.Transparency<1 then out.visibleParts+=1 end;if v.CanCollide or v.CanTouch or v.CanQuery then out.solids+=1 end end
  if v:IsA("Sound") or v:IsA("ParticleEmitter") or v:IsA("Light") or v:IsA("BaseScript") then table.insert(out.issues,"Unexpected "..v.ClassName) end
  if v:IsA("Beam") then
   out.beams+=1;local source=v:FindFirstChild("NozzleReference") and v.NozzleReference.Value
   if not source or not source:IsDescendantOf(findWash()) then table.insert(out.issues,"Missing nozzle "..v.Name) else out.sourceReferences+=1 end
   if v.Texture~="" or v.LightEmission~=0 or v.Width0>.04 or v.Width1>.2 then table.insert(out.issues,"Unbounded beam "..v.Name) end
   for _,a in {v.Attachment0,v.Attachment1} do
    if not a then table.insert(out.issues,"Missing endpoint "..v.Name) else
     local cell=v.Parent.Parent;local p=a.WorldPosition;local lo,hi=cell:GetAttribute("AllowedMin"),cell:GetAttribute("AllowedMax")
     out.endpointChecks+=1
     if p.X<lo.X or p.Y<lo.Y or p.Z<lo.Z or p.X>hi.X or p.Y>hi.Y or p.Z>hi.Z then table.insert(out.issues,"Outside wet cell "..v.Name) end
    end
   end
  end
 end
 local s=game.ServerScriptService:FindFirstChild(DRIVER_NAME)
 if s and s:GetAttribute("Owner")=="Institution7C1" then
  out.scripts=1
  if RS:IsRunning() then out.sourceVerification="EDIT_ONLY_RUNTIME_METADATA_CHECK"
  elseif s.Source~=DRIVER then table.insert(out.issues,"Bootstrap edited")
  else out.sourceVerification="EXACT_EDIT_SOURCE" end
 else table.insert(out.issues,"Bootstrap missing or unowned") end
 if out.beams~=10 or out.sourceReferences~=10 or out.parts~=2 or out.visibleParts~=0 or out.solids~=0 then table.insert(out.issues,"Unexpected installed counts") end
 return out
end
return I

