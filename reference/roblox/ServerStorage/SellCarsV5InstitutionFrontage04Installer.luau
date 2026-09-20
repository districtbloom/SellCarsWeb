--!nocheck
-- F04 is a staged candidate in this place, NOT permanent frontage activation.
-- Preview temporarily masks selected originals, then restores exact saved properties.
local I={Version="2026-09-08.frontage04.f2.1"}
I.PreviewAdapterVersion="2026-09-08.frontage04.f4.1"
local SS=game:GetService("ServerStorage")
local PACKAGE="SellCarsV5Frontage04Package"
local CANDIDATE="Frontage04_Architecture_Ground_Candidate"
local ROOT="SellCars_Dealership_Growth_V5"
local scopePaths={
 "09_Institution_Production_B/01_Frontage_Commercial/01_Intake_Appraisal",
 "09_Institution_Production_B/01_Frontage_Commercial/02_Sales_Delivery",
 "10_Institution_Fidelity_R1/04_Frontage_And_Owner/01_Intake",
 "10_Institution_Fidelity_R1/04_Frontage_And_Owner/02_Sales",
 "10_Institution_Fidelity_R1/07_Elevation_01/08_Intake_Waiting_Comfort",
 "10_Institution_Fidelity_R1/07_Elevation_01/09_Sales_Desk_Joinery",
 "10_Institution_Fidelity_R1/07_Elevation_01/14_Intake_Waiting_Light",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Coachworks_Gateway",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Appraisal_Waymarker",
 "10_Institution_Fidelity_R1/05_Prestige_And_Public_Realm/04_Estate_Identity/Sales_Waymarker",
 "10_Institution_Fidelity_R1/06_Atmosphere/03_Lighting_Hierarchy/Gateway_3120",
 "10_Institution_Fidelity_R1/06_Atmosphere/03_Lighting_Hierarchy/Gateway_3140",
 "10_Institution_Fidelity_R1/06_Atmosphere/07_Occupation_Frontage/SeniorAppraiser",
 "10_Institution_Fidelity_R1/06_Atmosphere/07_Occupation_Frontage/Seller",
 "10_Institution_Fidelity_R1/06_Atmosphere/07_Occupation_Frontage/SalesAdvisor",
 "10_Institution_Fidelity_R1/06_Atmosphere/07_Occupation_Frontage/Buyer",
 "10_Institution_Fidelity_R1/06_Atmosphere/07_Occupation_Frontage/DeliveryHost",
}
local function root()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 return assert(workspace:FindFirstChild(ROOT),"V5 root missing")
end
local function at(r,path)
 local p=r;for name in path:gmatch("[^/]+")do p=assert(p:FindFirstChild(name),"Missing "..path)end;return p
end
local function packageFolder()return assert(SS:FindFirstChild(PACKAGE),"Build candidate first")end
local function vehicleAdapter()
 local m=assert(SS:FindFirstChild("SellCarsV5Frontage04VehiclePreview"),"Vehicle preview source missing"):Clone()
 local ok,result=pcall(require,m);m:Destroy();assert(ok,result);return result
end
local function object(parent,name,target)
 local v=Instance.new("ObjectValue");v.Name=name;v.Value=target;v.Parent=parent;return v
end
local function props(v)
 -- Edit-only preview is visual: leave all physics flags alone to avoid native
 -- Seat TouchInterest generation. Never play this temporary masked scene.
 if v:IsA("BasePart")then return {Transparency=v.Transparency,CastShadow=v.CastShadow}
 elseif v:IsA("Decal")or v:IsA("Texture")then return {Transparency=v.Transparency}
 elseif v:IsA("Light")or v:IsA("SurfaceGui")or v:IsA("BillboardGui")or v:IsA("ParticleEmitter")or v:IsA("Beam")or v:IsA("Trail")then return {Enabled=v.Enabled}end
end
local function mask(v)
 if v:IsA("BasePart")then v.Transparency=1;v.CastShadow=false
 elseif v:IsA("Decal")or v:IsA("Texture")then v.Transparency=1
 elseif v:IsA("Light")or v:IsA("SurfaceGui")or v:IsA("BillboardGui")or v:IsA("ParticleEmitter")or v:IsA("Beam")or v:IsA("Trail")then v.Enabled=false end
end
local function inventory(m)
 local o={path=m:GetFullName(),parts=0,models=0,lights=0,carPreviews=0,actualSalesCars=0,descendants=#m:GetDescendants()}
 for _,v in m:GetDescendants()do if v:IsA("BasePart")then o.parts+=1 elseif v:IsA("Model")then o.models+=1;if v:GetAttribute("Frontage04CarPreview")then o.carPreviews+=1 end elseif v:IsA("Light")then o.lights+=1 end end
 local actual=m:FindFirstChild("06_Actual_Sales_Vehicles")
 if actual then for _,v in actual:GetChildren()do if v:IsA("Model")and v:GetAttribute("VehicleDisplay")then o.actualSalesCars+=1 end end end
 return o
end
function I.Build()
 local r=root();assert(not SS:FindFirstChild(PACKAGE),"Existing Frontage04 package preserved; no overwrite")
 local p=Instance.new("Folder");p.Name=PACKAGE;p:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local c=Instance.new("Model");c.Name=CANDIDATE;c:SetAttribute("Status","F04_2_ARCHITECTURE_CANDIDATE_NOT_ACTIVATED");c:SetAttribute("Version",I.Version);c.Parent=p
  local K=require(assert(SS:FindFirstChild("SellCarsV5Frontage04Kit")))
  require(assert(SS:FindFirstChild("SellCarsV5Frontage04Ground")))(K,c)
  require(assert(SS:FindFirstChild("SellCarsV5Frontage04Architecture")))(K,c)
  local cars=K.model(c,"90_Scale_Car_Previews","SCALE_PREVIEW_ONLY")
  local schedule={{"Ground_Display_1/SalesCar_1",3098,15,-90,1},{"Elevated_Centreline_Display_1/ElevatedSalesCar_1",3098,35,-90,2},{"Ground_Display_2/SalesCar_2",3156.5,13,90,3},{"Ground_Display_3/SalesCar_3",3098,58,-90,4},{"Elevated_Centreline_Display_2/ElevatedSalesCar_2",3156.5,32,90,5},{"Ground_Display_4/SalesCar_4",3156.5,51,90,6}}
  local originals=at(r,scopePaths[2])
  for _,row in schedule do
   local original=at(originals,row[1]);local car=assert(original:Clone());assert(#car:GetDescendants()==#original:GetDescendants(),"Incomplete car clone")
   car.Name="Preview_SalesDisplay_"..row[5];car:SetAttribute("Frontage04CarPreview",true);car:SetAttribute("OriginalPath",original:GetFullName());car:SetAttribute("PreviewOnly",true)
   local before=car:GetPivot();local box,size=car:GetBoundingBox();local bottom=box.Y-size.Y/2
   car:PivotTo(CFrame.new(row[2],.23+(before.Y-bottom),row[3])*CFrame.Angles(0,math.rad(row[4]),0))
   car.Parent=cars
  end
  object(p,"CandidateReference",c)
  p:SetAttribute("InstalledIntoLiveFrontage",false);p:SetAttribute("PreviewActive",false)
 end)
 if not ok then p:Destroy();error(err)end
 p.Parent=SS;return inventory(p[CANDIDATE])
end
function I.Preview()
 local r=root();local p=packageFolder();assert(not p:GetAttribute("PreviewActive"),"Preview already active")
 local c=assert(p.CandidateReference.Value,"Candidate missing")
 assert(c.Parent==p and c:GetAttribute("Version")==I.Version,"Candidate identity/state mismatch")
 assert(not workspace:FindFirstChild(CANDIDATE),"Same-name Workspace object preserved; resolve before preview")
 local serial=(p:GetAttribute("PreviewSerial")or 0)+1
 local state=Instance.new("Folder");state.Name="Recovery_Preview_"..serial
 local saved=Instance.new("Folder");saved.Name="ExactModifiedProperties";saved.Parent=state
 local clones=Instance.new("Folder");clones.Name="FullAffectedScopeClones";clones.Parent=state
 local items={};local seen={}
 -- Capture everything before the first mask. Original hierarchy and references stay in place.
 for i,path in scopePaths do
  local scope=at(r,path);local copy=assert(scope:Clone(),"Cannot clone "..path)
  assert(#copy:GetDescendants()==#scope:GetDescendants(),"Incomplete recovery clone "..path)
  copy.Name=string.format("Scope_%02d",i);copy:SetAttribute("OriginalPath",scope:GetFullName());copy.Parent=clones
  for _,v in {scope,unpack(scope:GetDescendants())}do if not seen[v]then seen[v]=true;if props(v)then table.insert(items,v)end end end
 end
 -- Only individually contained foreground movement paint; never hide a parent spanning Owner/campus.
 local move=at(r,"10_Institution_Fidelity_R1/06_Atmosphere/01_Movement_Surfaces")
 for _,v in move:GetDescendants()do if v:IsA("BasePart")and v.Name~="FrontageDistrict" then
  local cf,s=v.CFrame,v.Size;local hx=math.abs(cf.RightVector.X)*s.X/2+math.abs(cf.LookVector.X)*s.Z/2;local hz=math.abs(cf.RightVector.Z)*s.X/2+math.abs(cf.LookVector.Z)*s.Z/2
  if cf.Y+s.Y/2>.228 and cf.Y<.5 and cf.X-hx>=3004 and cf.X+hx<=3178 and cf.Z-hz>=-17 and cf.Z+hz<=89 then
   table.insert(items,v);local clone=v:Clone();clone.Name="ContainedGround_"..#items;clone:SetAttribute("OriginalPath",v:GetFullName());clone.Parent=clones
  end
 end end
 for i,v in items do local entry=object(saved,string.format("Record_%04d",i),v);for k,value in props(v)do entry:SetAttribute(k,value)end end
 local camera=workspace.CurrentCamera;state:SetAttribute("CameraCFrame",camera.CFrame);state:SetAttribute("CameraFocus",camera.Focus);state:SetAttribute("CameraFOV",camera.FieldOfView)
 state:SetAttribute("PreviewOnly",true);state:SetAttribute("FullPlaceBackup",false);state:SetAttribute("RecordCount",#items);state.Parent=p
 p:SetAttribute("PreviewSerial",serial);object(p,"ActiveRecovery",state);p:SetAttribute("PreviewActive",true)
 local ok,err=pcall(function()
  for _,v in items do mask(v)end;c.Parent=workspace
  if c:GetAttribute("F04SalesPreviewReady")then vehicleAdapter().Show(p,c,r,state)end
 end)
 if not ok then I.EndPreview();error(err)end
 return {candidate=inventory(c),recovery=state:GetFullName(),records=#items,status="TEMPORARY_EDIT_PREVIEW_NOT_ACTIVATED"}
end
function I.EndPreview()
 root();local p=packageFolder();assert(p:GetAttribute("PreviewActive"),"No active preview")
 local state=assert(p.ActiveRecovery.Value);local missing={}
 for _,entry in state.ExactModifiedProperties:GetChildren()do if not entry.Value then table.insert(missing,entry.Name)end end
 assert(#missing==0,"Original targets missing; preserve candidate and recovery")
 local c=assert(p.CandidateReference.Value,"Candidate identity lost")
 assert(c.Parent==workspace or c.Parent==p,"Candidate moved by another editor; preserve")
 if state:FindFirstChild("F04_VehicleSwap")then vehicleAdapter().Restore(p,c,state)end
 c.Parent=p -- remove preview contribution first; retry is safe if restoration is interrupted
 local failures={}
 for _,entry in state.ExactModifiedProperties:GetChildren()do
  for key,value in entry:GetAttributes()do
   local ok,err=pcall(function()if entry.Value[key]~=value then entry.Value[key]=value end end)
   if not ok then table.insert(failures,entry.Name.."/"..key..": "..tostring(err))end
  end
 end
 local cameraOK,cameraError=pcall(function()
  workspace.CurrentCamera.CFrame=state:GetAttribute("CameraCFrame");workspace.CurrentCamera.Focus=state:GetAttribute("CameraFocus");workspace.CurrentCamera.FieldOfView=state:GetAttribute("CameraFOV")
 end)
 if not cameraOK then table.insert(failures,tostring(cameraError))end
 assert(#failures==0,"Restoration incomplete; retained recovery supports EndPreview retry: "..table.concat(failures,"; "))
 p.ActiveRecovery:Destroy();state:SetAttribute("Restored",true);p:SetAttribute("PreviewActive",false)
 return {restored=true,records=state:GetAttribute("RecordCount"),candidate=c:GetFullName(),recovery=state:GetFullName()}
end
function I.Inventory()
 local p=packageFolder();local c=p.CandidateReference.Value
 local out=inventory(assert(c));out.previewActive=p:GetAttribute("PreviewActive");return out
end
return I

