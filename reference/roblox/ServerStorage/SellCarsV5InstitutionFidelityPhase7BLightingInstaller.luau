--!nocheck
-- Institution7B: one reversible controller; no per-prop scripts or automatic clock loop.
local I={Version="2026-09-07.phase7b.1"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","03_Lighting_Hierarchy"
local L=game:GetService("Lighting")
local RGB=Color3.fromRGB
local GLOBAL={"ClockTime","Brightness","Ambient","OutdoorAmbient","ExposureCompensation","EnvironmentDiffuseScale","EnvironmentSpecularScale","GeographicLatitude","GlobalShadows","ShadowSoftness"}
local AP={"Density","Offset","Color","Decay","Haze","Glare"}
local BP={"Enabled","Intensity","Threshold","Size"}
local SP={"Enabled","Intensity","Spread"}
local LP={"Enabled","Brightness","Range","Color","Shadows"}
local C={steel=RGB(39,44,44),bronze=RGB(151,119,65),lens=RGB(220,221,209),cool=RGB(222,234,240),public=RGB(255,224,177),prestige=RGB(255,225,170)}
local PRESETS={
 Day={ClockTime=15.6,Brightness=2.6,Ambient=RGB(65,62,56),OutdoorAmbient=RGB(100,104,111),ExposureCompensation=0,EnvironmentDiffuseScale=.8,EnvironmentSpecularScale=.85,GeographicLatitude=31,GlobalShadows=true,ShadowSoftness=.28,
  atmosphere={Density=.20,Offset=.18,Color=RGB(212,197,168),Decay=RGB(120,134,150),Haze=.7,Glare=.05},
  grade={Contrast=.045,Saturation=-.025,TintColor=RGB(255,249,240),Brightness=0}},
 Night={ClockTime=21.1,Brightness=2.2,Ambient=RGB(68,73,84),OutdoorAmbient=RGB(90,100,120),ExposureCompensation=.18,EnvironmentDiffuseScale=.8,EnvironmentSpecularScale=.8,GeographicLatitude=31,GlobalShadows=true,ShadowSoftness=.28,
  atmosphere={Density=.16,Offset=.12,Color=RGB(133,152,178),Decay=RGB(45,59,85),Haze=.45,Glare=.05},
  grade={Contrast=.02,Saturation=-.03,TintColor=RGB(247,250,255),Brightness=0}},
}
local function root(edit)
 assert(game.PlaceId==125334614375606,"Wrong place")
 if edit then assert(not game:GetService("RunService"):IsRunning(),"Edit only")end
 return assert(workspace:FindFirstChild(ROOT))
end
local function layer()return root(false)["10_Institution_Fidelity_R1"]["06_Atmosphere"]:FindFirstChild(NAME)end
local function props(record,target,names)
 for _,p in names do record:SetAttribute(p,target[p])end
end
local function restoreProps(record,target)
 assert(target,"Lost baseline reference: "..record.Name)
 for p,v in record:GetAttributes()do if p~="Role" then target[p]=v end end
end
local function record(parent,n,target,names,object)
 local v=Instance.new(object and "ObjectValue" or "Folder");v.Name=n
 if object then v.Value=target end
 props(v,target,names);v.Parent=parent;return v
end
local function role(p)
 if string.find(p,"03_Estate_Identity",1,true)then return "Exterior"end
 if string.find(p,"01_Collector",1,true)or string.find(p,"HQ",1,true)then return "Prestige"end
 if string.find(p,"04_Frontage_And_Owner",1,true)then return "Public"end
 if string.find(p,"02_Rear_Support",1,true)then return "Support"end
 return "Production"
end
local function part(m,n,p,size,c,mat)
 local v=Instance.new("Part");v.Name=n;v.Anchored=true;v.Size=size;v.Position=p
 v.Material=mat or Enum.Material.Metal;v.Color=c or C.steel
 v.CanCollide=false;v.CanTouch=false;v.CanQuery=true;v.CastShadow=false;v.TopSurface=0;v.BottomSurface=0;v.Parent=m;return v
end
local function model(l,n,mount,p,size)
 local m=Instance.new("Model");m.Name=n;m.Parent=l
 for k,v in {BundleId="Institution.Lighting."..n..".FidelityR1",FunctionId="EstateLighting",ZoneId=n,FidelityRole="UTILITY",PhaseMin="PROFESSIONAL",Ancestor="Basic overhead work lamp -> shielded state-aware architectural fixture",InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass="OVERHEAD_DECORATIVE",InteractionAnchor="",FXSocket=n.."_Socket",AllowedMin=p-size/2,AllowedMax=p+size/2}do m:SetAttribute(k,v)end
 local ref=Instance.new("ObjectValue");ref.Name="MountReference";ref.Value=mount;ref.Parent=m;return m
end
local function fixture(l,n,mount,x,y,z,tiltZ,tiltX,r,b,kind)
 local m=model(l,n,mount,Vector3.new(x,y-.5,z),Vector3.new(4,2.7,4))
 -- Mount plate touches the underside of an existing roof/beam. No new ground obstruction.
 local plate=part(m,"MountPlate",Vector3.new(x,y-.045,z),Vector3.new(1.2,.09,1),C.steel)
 part(m,"ShortDrop",Vector3.new(x,y-.27,z),Vector3.new(.24,.5,.24),C.steel)
 local cf=CFrame.new(x,y-.60,z)*CFrame.Angles(math.rad(tiltX or 0),0,math.rad(tiltZ or 0))
 local hood=part(m,"CutoffHousing",cf.Position,Vector3.new(2.6,.3,2.2),C.steel);hood.CFrame=cf
 local lens=part(m,"RecessedLens",cf:PointToWorldSpace(Vector3.new(0,-.16,0)),Vector3.new(2.13,.04,1.72),C.lens,Enum.Material.Glass);lens.CFrame=cf*CFrame.new(0,-.16,0)
 for _,dx in {-1.18,1.18}do local p=part(m,"SideShield",cf.Position,Vector3.new(.14,.26,2.18),C.steel);p.CFrame=cf*CFrame.new(dx,-.17,0)end
 local lip=part(m,"GlareLip",cf.Position,Vector3.new(2.3,.22,.14),C.steel);lip.CFrame=cf*CFrame.new(0,-.17,1)
 local lamp=Instance.new("SurfaceLight");lamp.Name="ManagedLight";lamp.Face=Enum.NormalId.Bottom;lamp.Angle=120;lamp.Range=r;lamp.Brightness=b;lamp.Shadows=false;lamp.Parent=lens
 lamp:SetAttribute("Role",kind);lamp:SetAttribute("NightBrightness",b);lamp:SetAttribute("ManagedRange",r)
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=plate
end
local function trim(l,p,n,color)
 local m=model(l,n,p,p.Position,p.Size+Vector3.new(.12,.12,.12))
 m:SetAttribute("FidelityRole","IDENTITY");m:SetAttribute("PhaseMin","DEDICATED")
 local panel=part(m,"MattePortalHeader",p.Position,p.Size,C.steel);panel.CFrame=p.CFrame
 local inwards=p.Position.X<3130 and 1 or -1
 local band=part(m,"DepartmentEnamelInset",p.Position+Vector3.new(inwards*(p.Size.X/2+.016),0,0),Vector3.new(.027,.22,p.Size.Z-1.2),color)
 band:SetAttribute("NonEmissive",true)
end
local function saveBaseline(l)
 local b=Instance.new("Folder");b.Name="99_Baseline";b.Parent=l
 record(b,"Lighting",L,GLOBAL,false)
 for _,v in {{"Atmosphere",AP},{"Bloom",BP},{"SunRays",SP}}do
  local t=assert(L:FindFirstChild(v[1]),"Missing baseline "..v[1]);record(b,v[1],t,v[2],true)
 end
 local lights=Instance.new("Folder");lights.Name="Lights";lights.Parent=b
 local active={};for _,v in root(true):GetDescendants()do if v:IsA("Light") and v.Enabled then table.insert(active,v)end end
 table.sort(active,function(a,b)
  return a:GetFullName()..tostring(a.Parent.Position)<b:GetFullName()..tostring(b.Parent.Position)
 end)
 assert(#active==57,"Unexpected active light baseline; inspect before installing")
 for i,v in active do local q=record(lights,string.format("%03d",i),v,LP,true);q:SetAttribute("Role",role(v:GetFullName()))end
 local headers=Instance.new("Folder");headers.Name="Headers";headers.Parent=b
 local production=root(true)["05_Architecture_Massing"]["02_Production"]
 for _,v in {{"Mechanical",RGB(135,58,44)},{"Paint_Exterior",RGB(117,96,120)}}do for i=1,2 do
  local p=production[v[1]]["OpenPortal_"..i].PortalHeader
  record(headers,v[1]..i,p,{"Transparency"},true);p.Transparency=1
  trim(l,p,v[1].."_Matte_Header_"..i,v[2])
 end end
end
function I.ApplyPreset(name)
 local spec=assert(PRESETS[name],"Use Day or Night");local l=assert(layer(),"Install7B first")
 for _,p in GLOBAL do L[p]=spec[p]end
 for p,v in spec.atmosphere do l["99_Baseline"].Atmosphere.Value[p]=v end
 local bloom=l["99_Baseline"].Bloom.Value;bloom.Enabled=true;bloom.Intensity=.14;bloom.Threshold=2.3;bloom.Size=20
 local rays=l["99_Baseline"].SunRays.Value;rays.Enabled=name=="Day";rays.Intensity=.005;rays.Spread=.1
 local grade=assert(L:FindFirstChild("SellCarsV5Institution7BGrade"));grade.Enabled=true
 for p,v in spec.grade do grade[p]=v end
 for _,v in l["99_Baseline"].Lights:GetChildren()do
  local light=assert(v.Value);local kind=v:GetAttribute("Role")
  light.Shadows=false;light.Range=v:GetAttribute("Range")
  light.Color=kind=="Prestige" and C.prestige or kind=="Public" and C.public or kind=="Exterior" and C.public or C.cool
  local factor=name=="Day" and .65 or (kind=="Production" and 1.05 or kind=="Support" and 1.1 or .9)
  light.Brightness=v:GetAttribute("Brightness")*factor
  light.Enabled=kind~="Exterior" or name=="Night"
 end
 for _,v in l:GetDescendants()do if v:IsA("Light")then
  v.Enabled=name=="Night";v.Color=v:GetAttribute("Role")=="Production" and C.cool or C.public
  v.Brightness=v:GetAttribute("NightBrightness")
 end end
 local f04Adapter=game.ServerStorage:FindFirstChild("SellCarsV5Frontage04Runtime")
 if f04Adapter then
  local copy=f04Adapter:Clone();local ok,adapter=pcall(require,copy);copy:Destroy();assert(ok,adapter)
  adapter.ApplyLighting(name)
 end
 -- AtmosphereCraft03: narrow optional override, inert when its batch is detached.
 local craft=game.ServerStorage:FindFirstChild("SellCarsV5InstitutionAtmosphereCraft03Installer")
 if craft then
  local copy=craft:Clone();local ok,adapter=pcall(require,copy);copy:Destroy();assert(ok,adapter)
  adapter.ApplyLighting(name)
 end
 l:SetAttribute("Preset",name);return name
end
function I.Install()
 root(true);if layer()then return I.Audit()end
 assert(not L:FindFirstChild("SellCarsV5Institution7BGrade"),"Unexpected7B grade without layer")
 local l=Instance.new("Folder");l.Name=NAME;l.Parent=root(true)["10_Institution_Fidelity_R1"]["06_Atmosphere"];l:SetAttribute("Version",I.Version);l:SetAttribute("Status","REVIEW")
 local ok,err=pcall(function()
 saveBaseline(l)
 local grade=Instance.new("ColorCorrectionEffect");grade.Name="SellCarsV5Institution7BGrade";grade.Parent=L
 local prod=root(true)["05_Architecture_Massing"]["02_Production"]
 for _,v in {{"Wash",120,-1},{"Mechanical",175,-1},{"Body_Restoration",239,-1},{"Tune_Performance",307,-1},{"Photo_Listing",175,1},{"Detail_QC",239,1},{"Paint_Exterior",307,1}}do
  local left=v[3]==-1;fixture(l,v[1].."_Eave",prod[v[1]].OpenCanopy,left and 3089.4 or 3170.6,13.9,v[2],left and 25 or -25,0,32,1.15,"Production")
 end
 local estate=root(true)["10_Institution_Fidelity_R1"]["05_Prestige_And_Public_Realm"]
 local gate
 for _,p in estate:GetDescendants()do if p.Name=="BeamFlange" and math.abs(p.Position.Y-16.55)<.1 then gate=p end end
 -- Explicit geometric identity avoids ambiguous duplicated fixture/beam paths.
 if not gate then for _,p in estate:GetDescendants()do if p:IsA("BasePart") and math.abs(p.Position.Y-16.55)<.1 and p.Size.X>40 and p.Position.Z<0 then gate=p;break end end end
 assert(gate,"Gateway lower beam not found")
 for _,x in {3120,3140}do fixture(l,"Gateway_"..x,gate,x,16.475,-16,0,25,24,1.3,"Public")end
 local ceiling=root(true)["05_Architecture_Massing"]["03_Rear_Campus"].Elevated_Collector_Hall.CollectorFloor
 for _,x in {3102,3158}do fixture(l,"Court_"..x,ceiling,x,19.3,381,0,0,27,1.15,"Prestige")end
 I.ApplyPreset("Day")
 end)
 if not ok then I.Uninstall();error(err)end
 return I.Audit()
end
function I.Uninstall()
 root(true);local l=layer();if not l then return "Not installed"end
 local b=l:FindFirstChild("99_Baseline")
 if b then
  if b:FindFirstChild("Lighting")then restoreProps(b.Lighting,L)end
  for _,n in {"Atmosphere","Bloom","SunRays"}do if b:FindFirstChild(n)then restoreProps(b[n],b[n].Value)end end
  for _,n in {"Lights","Headers"}do if b:FindFirstChild(n)then for _,v in b[n]:GetChildren()do restoreProps(v,v.Value)end end end
 end
 local g=L:FindFirstChild("SellCarsV5Institution7BGrade");if g then g:Destroy()end
 l:Destroy();return "Original service,light,header state restored"
end
local function near(a,b)
 if typeof(a)=="number"then return math.abs(a-b)<.0001 end
 if typeof(a)=="Color3"then return (Vector3.new(a.R,a.G,a.B)-Vector3.new(b.R,b.G,b.B)).Magnitude<.0001 end
 return a==b
end
function I.Audit()
 local r=root(false);local l=assert(layer());local a={issues={},parts=0,models=0,newLights=0,shadowLights=0,activeLights=0,originalRefs=0,protectedEnvelopes=0,routeRibbons=0,mounts=0,externalChecks=0,pocketCorners=0,preset=l:GetAttribute("Preset")}
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={l};op.RespectCanCollide=false
 local function check(n,cf,s)for _,v in workspace:GetPartBoundsInBox(cf,s,op)do if v.Transparency<.98 then table.insert(a.issues,n..":"..v:GetFullName())end end end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedEnvelopes+=1;check(p.Name,p.CFrame,p.Size)end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeRibbons+=1;check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z))end end
 op.FilterDescendantsInstances={r}
 local rows={}
 for _,m in l:GetChildren()do if m:IsA("Model")then
  a.models+=1;local mount=m.MountReference.Value;assert(mount,"Lost mount");a.mounts+=1
  local mn,mx=m:GetAttribute("AllowedMin"),m:GetAttribute("AllowedMax")
  for _,p in m:GetChildren()do if p:IsA("BasePart")then
   a.parts+=1;assert(not p.CanCollide and not p.CanTouch,"No new collision")
   for _,sx in {-1,1}do for _,sy in {-1,1}do for _,sz in {-1,1}do
    a.pocketCorners+=1;local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(sx,sy,sz)/2)
    if v.X<mn.X-.01 or v.X>mx.X+.01 or v.Y<mn.Y-.01 or v.Y>mx.Y+.01 or v.Z<mn.Z-.01 or v.Z>mx.Z+.01 then table.insert(a.issues,"Pocket:"..p:GetFullName())end
   end end end
   a.externalChecks+=1
   for _,v in workspace:GetPartBoundsInBox(p.CFrame,p.Size,op)do
    -- Exact original header/post lap joints are mounting contacts, not new obstructions.
    local headerJoint=p.Name=="MattePortalHeader" and v.Parent==mount.Parent and (v.Name=="PortalPostA" or v.Name=="PortalPostB")
    if not v:IsDescendantOf(l) and v~=mount and not headerJoint and v.Transparency<.98 then table.insert(a.issues,"External:"..p:GetFullName()..":"..v:GetFullName())end
   end
   table.insert(rows,p:GetFullName().."|"..tostring(p.CFrame).."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name)
  end end
  local plate=m:FindFirstChild("MountPlate")
  if plate then
   local top=plate.Position+Vector3.new(0,plate.Size.Y/2,0)
   local lp=mount.CFrame:PointToObjectSpace(top)
   if math.abs(lp.X)>mount.Size.X/2+.02 or math.abs(lp.Z)>mount.Size.Z/2+.02 or math.abs(lp.Y+mount.Size.Y/2)>.02 then table.insert(a.issues,"UnsupportedMount:"..m.Name)end
  end
 end end
 for _,v in r:GetDescendants()do if v:IsA("Light")then if v.Enabled then a.activeLights+=1 end;if v.Shadows then a.shadowLights+=1 end;if v:IsDescendantOf(l)then a.newLights+=1 end end end
 for _,v in l["99_Baseline"].Lights:GetChildren()do a.originalRefs+=1;if not v.Value then table.insert(a.issues,"Lost light "..v.Name)end end
 for _,v in l["99_Baseline"].Headers:GetChildren()do if not v.Value or v.Value.Transparency~=1 then table.insert(a.issues,"HeaderRestore "..v.Name)end end
 local spec=assert(PRESETS[a.preset]);for _,p in GLOBAL do if not near(L[p],spec[p])then table.insert(a.issues,"GlobalDrift:"..p)end end
 for p,v in spec.atmosphere do if not near(l["99_Baseline"].Atmosphere.Value[p],v)then table.insert(a.issues,"AtmosphereDrift:"..p)end end
 local grade=L:FindFirstChild("SellCarsV5Institution7BGrade")
 if not grade or not grade.Enabled then table.insert(a.issues,"MissingOwnedGrade")else for p,v in spec.grade do if not near(grade[p],v)then table.insert(a.issues,"GradeDrift:"..p)end end end
 for _,rec in l["99_Baseline"].Lights:GetChildren()do if rec.Value then
  local v=rec.Value;local kind=rec:GetAttribute("Role")
  local factor=a.preset=="Day" and .65 or (kind=="Production" and 1.05 or kind=="Support" and 1.1 or .9)
  local col=kind=="Prestige" and C.prestige or kind=="Public" and C.public or kind=="Exterior" and C.public or C.cool
  if v.Enabled~=(kind~="Exterior" or a.preset=="Night")or not near(v.Brightness,rec:GetAttribute("Brightness")*factor)or not near(v.Range,rec:GetAttribute("Range"))or not near(v.Color,col)or v.Shadows then table.insert(a.issues,"ManagedLightDrift:"..rec.Name)end
 end end
 for _,v in l:GetDescendants()do
  if v:IsA("Light") and (v.Enabled~=(a.preset=="Night")or v.Shadows or not near(v.Range,v:GetAttribute("ManagedRange"))or not near(v.Brightness,v:GetAttribute("NightBrightness")))then table.insert(a.issues,"FixtureDrift:"..v:GetFullName())end
  if v:IsA("LuaSourceContainer")then table.insert(a.issues,"UnexpectedPerPropScript")end
 end
 if a.activeLights~=(a.preset=="Day" and 51 or 68)then table.insert(a.issues,"ActiveCountDrift")end
 assert(a.newLights<=12 and a.originalRefs==57,"Light ownership/count changed")
 table.sort(rows);local h=5381;for _,s in rows do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;a.signature=string.format("%08x",h)
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0,"Unresolved lighting geometry/state")
 for _,k in {"DayVisualPass","NightVisualPass","RenderingReviewed","RegressionsPass","RoutePass","RollbackPass","SourceMatch"}do assert(e[k],"Missing "..k)end
 local l=layer();local f=l:FindFirstChild("97_Evidence")or Instance.new("Folder");f.Name="97_Evidence";f.Parent=l
 for k,v in e do f:SetAttribute(k,v)end;l:SetAttribute("Status","ACCEPTED")
 for _,v in l:GetChildren()do if v:IsA("Model")then v:SetAttribute("AssetStatus","MODELER_READY")end end
 return a
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

