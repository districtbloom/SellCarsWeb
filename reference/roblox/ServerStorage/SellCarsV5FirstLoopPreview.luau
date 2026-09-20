--!nocheck
local API={Version='2026-09-08.FJ03.first-loop.1'}
local SS=game:GetService('ServerStorage')
local PKG='SellCarsV5JourneyPreviewPackage'
local function check()
 assert(game.PlaceId==125334614375606 and game.RunService:IsStudio(),'Studio review only')
 return assert(SS:FindFirstChild(PKG),'Install first-loop preview first')
end
local function ref(parent,name,obj)
 local v=Instance.new('ObjectValue');v.Name=name;v.Value=obj;v.Parent=parent;return v
end
local function poseCar(pkg,location)
 local step=pkg:GetAttribute('Step');assert(step>=2,'Car reference requires Intake')
 assert(location=='INTAKE' or location=='WORK' or location=='SALES','Unknown car location')
 assert(location~='WORK' or step>=3,'Repair not built');assert(location~='SALES' or step>=6,'Sale setting not built')
 local car=pkg.Car.Value;local points={INTAKE=Vector3.new(3008,1.83,88),WORK=Vector3.new(3041,1.99,132),SALES=Vector3.new(3073,1.83,82)}
 local p=points[location];local yaw=location=='INTAKE' and math.pi or math.pi/2
 car:PivotTo(CFrame.new(p+Vector3.new(0,pkg:GetAttribute('CarHalfHeight'),0))*CFrame.Angles(0,yaw,0)*pkg:GetAttribute('CarPivotOffset'))
 car.Parent=pkg.Preview.Value;pkg:SetAttribute('CarLocation',location)
end
function API.Status()
 local p=check();local study=SS:FindFirstChild('SellCarsV5CollectorBackward01Package');return {step=p:GetAttribute('Step'),builtMax=6,total=240,car=p:GetAttribute('CarLocation'),active=p:GetAttribute('Active'),collectorStudy=study and study:GetAttribute('Applied')or false,collectorLevel=study and study:GetAttribute('TourLevel')}
end
function API.SetTourLevel(level)
 local p=check();assert(p:GetAttribute('Active'),'Preview deactivated')
 assert(type(level)=='number'and level%1==0 and level>=0 and level<=3,'Tour level0–3 only')
 for _,r in p.SuspendedScripts:GetChildren()do assert(r.Value and r.Value.Disabled,'Conflicting scene controller')end
 if p:GetAttribute('Step')~=-1 then API.SetStep('INSTITUTION')end
 require(SS.SellCarsV5CollectorBackward01).SetLevel(level);return API.Status()
end
function API.SetStep(step)
 local pkg=check();assert(pkg:GetAttribute('Active'),'Preview deactivated')
 if step=='PRO_COLLECTOR' then
  assert(SS:FindFirstChild('SellCarsV5CollectorBackward01Package'),'Collector study not installed')
  API.SetStep('INSTITUTION');require(SS.SellCarsV5CollectorBackward01).Set(true);return API.Status()
 end
 local benchmark=step=='INSTITUTION'
 assert(benchmark or (type(step)=='number' and step%1==0 and step>=0 and step<=6),'Only steps0–6 are built; planned entry does not change scene')
 local study=SS:FindFirstChild('SellCarsV5CollectorBackward01Package')
 if study and study:GetAttribute('Applied')then require(SS.SellCarsV5CollectorBackward01).Set(false)end
 local original=assert(pkg.Institution.Value);local preview=assert(pkg.Preview.Value);local spawn=assert(pkg.Spawn.Value)
 assert(original.Parent==workspace or original.Parent==pkg,'Institution ownership changed')
 assert(preview.Parent==workspace or preview.Parent==pkg,'Preview ownership changed')
 assert(#original:GetDescendants()==pkg:GetAttribute('InstitutionCount'),'Institution content changed; preserve and reconcile before switching')
 local expected=pkg:GetAttribute('Step')==-1 and pkg:GetAttribute('OriginalSpawn') or pkg:GetAttribute('PreviewSpawn')
 assert(spawn.CFrame==expected,'Spawn edited outside preview; reconcile before switching')
 for _,r in pkg.BundleRefs:GetChildren()do assert(r.Value and (r.Value.Parent==preview or r.Value.Parent==pkg.ParkedBundles),'Preview bundle ownership changed')end
 assert(pkg.Car.Value and (pkg.Car.Value.Parent==preview or pkg.Car.Value.Parent==pkg.ParkedBundles),'Car reference ownership changed')
 for _,r in pkg.SuspendedScripts:GetChildren()do assert(r.Value and r.Value.Disabled,'A suspended controller was re-enabled; preserve sole scene ownership')end
 -- All targets preflighted. Parking preserves exact Institution descendants/properties.
 if benchmark then
  preview.Parent=pkg;original.Parent=workspace;spawn.CFrame=pkg:GetAttribute('OriginalSpawn');pkg:SetAttribute('Step',-1)
 else
  original.Parent=pkg
  for _,r in pkg.BundleRefs:GetChildren()do r.Value.Parent=tonumber(r.Name)<=step and preview or pkg.ParkedBundles end
  if step<2 then pkg.Car.Value.Parent=pkg.ParkedBundles end
  preview.Parent=workspace;spawn.CFrame=pkg:GetAttribute('PreviewSpawn');pkg:SetAttribute('Step',step)
  if step>=2 then poseCar(pkg,step>=3 and 'WORK' or 'INTAKE')end
 end
 return API.Status()
end
function API.PlaceCar(location)
 local pkg=check();assert(pkg:GetAttribute('Step')~=-1,'Car marker only in Birth preview');poseCar(pkg,location);return API.Status()
end
function API.Install()
 assert(game.PlaceId==125334614375606 and game.RunService:IsStudio() and not game.RunService:IsRunning(),'Install in correct Edit model')
 assert(not SS:FindFirstChild(PKG),'Already installed; do not overwrite the preview package')
 local original=assert(workspace:FindFirstChild('SellCars_Dealership_Growth_V5'))
 assert(original:GetAttribute('VisualReviewChapter')=='INSTITUTION','Restore old reviewer to Institution first')
 local spawn=assert(workspace:FindFirstChild('SellCars_V5_PlayerSpawn'))
 local data=require(game.ReplicatedStorage.SellCarsV5JourneyData)
 local geometry=require(SS.SellCarsV5FirstLoopGeometry)
 local pkg=Instance.new('Folder');pkg.Name=PKG
 local scripts=Instance.new('Folder');scripts.Name='SuspendedScripts';scripts.Parent=pkg
 local parked=Instance.new('Folder');parked.Name='ParkedBundles';parked.Parent=pkg
 local refs=Instance.new('Folder');refs.Name='BundleRefs';refs.Parent=pkg
 local ok,err=pcall(function()
  local ids={};for n=1,6 do ids[n]=data.Entries[n].id end
  local preview,bundles=geometry.Build(pkg,ids);ref(pkg,'Preview',preview)
  for n,m in ipairs(bundles)do ref(refs,tostring(n),m)end
  local source=original['10_Institution_Fidelity_R1']['11_Frontage04']['06_Actual_Sales_Vehicles'].SalesCar_3
  local car=source:Clone();car.Name='Scale_Reference_Not_Inventory';car:SetAttribute('PreviewOnly',true)
  for _,p in car:GetDescendants()do assert(p:IsA('BasePart'),'Unexpected car content');p.Anchored=true;p.CanCollide=false;p.CanTouch=false end
  local cf,size=car:GetBoundingBox();pkg:SetAttribute('CarHalfHeight',size.Y/2);pkg:SetAttribute('CarPivotOffset',cf:ToObjectSpace(car:GetPivot()))
  car.Parent=parked;ref(pkg,'Car',car)
  -- Exact, observed enabled sources only. No prefix-based blanket suspension.
  local targets={game.ServerScriptService.SellCarsV5InstitutionAtmosphereServer,game.ServerScriptService.SellCarsV5InstitutionRearOccupationServer,game.ServerScriptService.SellCarsV5InstitutionProductionOccupationServer,game.ServerScriptService.SellCarsV5InstitutionFrontageOccupationServer,game.ServerScriptService.SellCarsV5ProfessionalReview01Server,game.StarterPlayer.StarterPlayerScripts.SellCarsV5ProfessionalReview01Panel}
  for _,s in ipairs(targets)do assert(s:IsA('BaseScript') and not s.Disabled,'Controller state changed: '..s.Name);local r=ref(scripts,s.Name,s);r:SetAttribute('BeforeDisabled',s.Disabled)end
  ref(pkg,'Institution',original);ref(pkg,'Spawn',spawn)
  pkg:SetAttribute('InstitutionCount',#original:GetDescendants());pkg:SetAttribute('OriginalSpawn',spawn.CFrame)
  pkg:SetAttribute('PreviewSpawn',CFrame.lookAt(Vector3.new(3047,1.49,107),Vector3.new(3041,1.49,132)))
  pkg:SetAttribute('Step',-1);pkg:SetAttribute('Version',API.Version);pkg:SetAttribute('Active',true)
 end)
 if not ok then pkg:Destroy();error(err)end
 -- Commit only after building/inspecting every new owned object and recovery record.
 pkg.Parent=SS
 for _,r in scripts:GetChildren()do r.Value.Disabled=true end
 return API.SetStep(6)
end
function API.Deactivate()
 assert(not game.RunService:IsRunning(),'Deactivate in Edit to restore original startup scripts safely')
 local p=check();API.SetStep('INSTITUTION')
 for _,r in p.SuspendedScripts:GetChildren()do r.Value.Disabled=r:GetAttribute('BeforeDisabled')end
 for _,s in {game.ServerScriptService:FindFirstChild('SellCarsV5JourneyPreviewServer'),game.StarterPlayer.StarterPlayerScripts:FindFirstChild('SellCarsV5JourneyPreviewPanel'),game.StarterPlayer.StarterPlayerScripts:FindFirstChild('SellCarsV5GuidedTourPanel')}do if s then s.Disabled=true end end
 p:SetAttribute('Active',false);return {institutionRestored=true,originalControllersRestored=true,previewParked=true}
end
return API

