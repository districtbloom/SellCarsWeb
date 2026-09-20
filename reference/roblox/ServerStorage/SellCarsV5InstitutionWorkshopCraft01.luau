--!nocheck
-- Two small environment-only upgrade bundles; no purchase/economy wiring.
local I={Version="2026-09-08.workshopcraft01.1"}
local SS=game:GetService("ServerStorage")
local NAME="SellCarsV5WorkshopCraft01Recovery"
local function context()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 local r=assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"))
 assert(r:GetAttribute("Frontage04Activated"),"Expected integrated Institution")
 return r,r["10_Institution_Fidelity_R1"],r["05_Architecture_Massing"]["02_Production"].Mechanical
end
local function ref(parent,name,value)local r=Instance.new("ObjectValue");r.Name=name;r.Value=value;r.Parent=parent;return r end
local function folder(p,n)local f=Instance.new("Folder");f.Name=n;f.Parent=p;return f end
local function bundle(parent,name,role)
 local m=Instance.new("Model");m.Name=name;m.Parent=parent
 m:SetAttribute("BundleId","Institution.Mechanical.WorkshopCraft01."..role)
 m:SetAttribute("FunctionId","Mechanical");m:SetAttribute("PhaseMin","INSTITUTION")
 m:SetAttribute("UpgradeIntent",role);m:SetAttribute("PurchaseWired",false)
 m:SetAttribute("Ancestor","Existing fixed Mechanical workshop envelope; exact earlier-chapter purchase mapping deferred")
 m:SetAttribute("SourceVersion",I.Version);return m
end
local function box(p,n,x,y,z,w,h,d,c,mat)
 local v=Instance.new("Part");v.Name=n;v.Size=Vector3.new(w,h,d);v.CFrame=CFrame.new(x,y,z)
 v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=true
 v.Color=c;v.Material=mat or Enum.Material.Metal;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=p;return v
end
local RGB=Color3.fromRGB
local charcoal=RGB(43,46,43);local edge=RGB(53,56,50);local wood=RGB(155,112,71)
function I.Install()
 local r,f,m=context();assert(not SS:FindFirstChild(NAME),"Existing craft recovery preserved")
 assert(not f:FindFirstChild("12_WorkshopCraft01"),"Existing layer preserved")
 local roof=assert(m:FindFirstChild("OpenCanopy"));assert((roof.Position-Vector3.new(3048,14.5,175)).Magnitude<.01 and (roof.Size-Vector3.new(84,1.2,56)).Magnitude<.01,"Unexpected roof")
 local rec=folder(SS,NAME);rec:SetAttribute("State","PREPARING");rec:SetAttribute("Version",I.Version)
 local before=ref(rec,"Roof",roof);for _,k in {"Color","Material","Reflectance","Transparency"}do before:SetAttribute(k,roof[k])end
 local root=bundle(nil,"12_WorkshopCraft01","Mechanical mature workshop finish")
 ref(rec,"Layer",root);ref(rec,"Destination",f)
 local shell=bundle(root,"01_Envelope_Finish","Envelope finish")
 local identity=bundle(root,"02_Department_Identity","Department wayfinding")
 -- Standing seams cross the existing roof; thin trim, not new roof massing.
 for z=148,202,4.5 do
  box(shell,"StandingSeam",3048,15.145,z,83.6,.09,.085,edge)
 end
 for _,z in {147.06,202.94}do box(shell,"FoldedSideFlashing",3048,14.6,z,83.9,.92,.10,edge)end
 box(shell,"FrontTopDrip",3089.97,15.04,175,.12,.16,55.8,edge)
 box(shell,"RearTopDrip",3006.03,15.04,175,.12,.16,55.8,edge)
 -- Timber soffit strip is confined to the front roof edge, not the working bay.
 for z=149,201,4 do
  box(shell,"WarmFasciaBoard",3090.045,14.43,z,.09,.76,3.86,wood,Enum.Material.Wood)
  box(shell,"WarmSoffitReturn",3088.9,13.87,z,2.15,.06,3.86,wood,Enum.Material.Wood)
 end
 -- Edge seams read as deliberate folded-metal joints, not surface noise.
 for _,z in {147.3,175,202.7}do box(shell,"FasciaJointCover",3090.105,14.44,z,.06,.8,.10,charcoal)end
 local labels={{163,"MECHANICAL","ENGINE  /  COOLING  /  FLUIDS"},{187,"MECHANICAL","SECOND SERVICE POSITION"}}
 for _,d in labels do
  local board=box(identity,"BayIdentity_"..d[1],3091.805,12.4,d[1],.08,1.05,13.2,charcoal)
  local gui=Instance.new("SurfaceGui");gui.Name="DepartmentPrint";gui.Face=Enum.NormalId.Right;gui.CanvasSize=Vector2.new(1320,105);gui.LightInfluence=1;gui.Parent=board
  local title=Instance.new("TextLabel");title.Name="Title";title.Size=UDim2.fromScale(1,.62);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamMedium;title.Text=d[2];title.TextSize=49;title.TextColor3=RGB(224,216,193);title.Parent=gui
  local sub=Instance.new("TextLabel");sub.Name="Function";sub.Position=UDim2.fromScale(0,.64);sub.Size=UDim2.fromScale(1,.32);sub.BackgroundTransparency=1;sub.Font=Enum.Font.Gotham;sub.Text=d[3];sub.TextSize=23;sub.TextColor3=RGB(187,160,125);sub.Parent=gui
 end
 roof.Color=charcoal;roof.Material=Enum.Material.Metal;roof.Reflectance=.025
 -- Original transparency, CFrame, footprint, portal headers and K cleats retained.
 root.Parent=f;rec:SetAttribute("State","ATTACHED")
 local count=0;for _,v in root:GetDescendants()do if v:IsA("BasePart")then count+=1 end end
 return {parts=count,descendants=#root:GetDescendants(),state="ATTACHED",bundles=2}
end
function I.Detach()
 context();local rec=assert(SS:FindFirstChild(NAME));assert(rec:GetAttribute("State")=="ATTACHED")
 local roof=assert(rec.Roof.Value);for _,k in {"Color","Material","Reflectance","Transparency"}do roof[k]=rec.Roof:GetAttribute(k)end
 rec.Layer.Value.Parent=rec;rec:SetAttribute("State","DETACHED");return "DETACHED"
end
function I.Reattach()
 context();local rec=assert(SS:FindFirstChild(NAME));assert(rec:GetAttribute("State")=="DETACHED")
 local roof=assert(rec.Roof.Value);roof.Color=charcoal;roof.Material=Enum.Material.Metal;roof.Reflectance=.025
 rec.Layer.Value.Parent=rec.Destination.Value;rec:SetAttribute("State","ATTACHED");return "ATTACHED"
end
return I

