--!nocheck
-- Studio-only visual chapter comparison. No gameplay, economy or phase filtering.
local I={Version="2026-09-08.professional-review01"}
local SS=game:GetService("ServerStorage")
local PACKAGE="SellCarsV5ProfessionalReview01Package"
local ROOT="SellCars_Dealership_Growth_V5"
local function check()
 assert(game.PlaceId==125334614375606 and game.RunService:IsStudio(),"Studio review only")
 return assert(workspace:FindFirstChild(ROOT))
end
local function unpackValue(v,property)
 return property=="Material" and Enum.Material[v] or v
end
local function equal(a,b)
 if typeof(a)=="number" then return math.abs(a-b)<.00001 end
 if typeof(a)=="Color3" then return (Vector3.new(a.R,a.G,a.B)-Vector3.new(b.R,b.G,b.B)).Magnitude<.00001 end
 return a==b
end
function I.SetChapter(chapter)
 local root=check();assert(chapter=="INSTITUTION" or chapter=="PROFESSIONAL","Only authored chapters are available")
 local package=assert(SS:FindFirstChild(PACKAGE),"Install ProfessionalReview01 first")
 local current=package:GetAttribute("CurrentChapter")
 local before=current=="PROFESSIONAL" and "Professional" or "Institution"
 local after=chapter=="PROFESSIONAL" and "Professional" or "Institution"
 local records={}
 for _,rec in package.Records:GetDescendants() do if rec:IsA("ObjectValue") then
  local target=assert(rec.Value,"Missing phase target");local property=rec:GetAttribute("Property")
  assert(target:IsDescendantOf(root),"Phase target left the dealership: "..target:GetFullName())
  if target:IsA("BasePart") then
   assert(target.CFrame==rec:GetAttribute("GuardCFrame") and target.Size==rec:GetAttribute("GuardSize"),"Phase target moved; reconcile fixed-position variants: "..target:GetFullName())
  end
  assert(equal(target[property],unpackValue(rec:GetAttribute(before),property)),"Edited phase property; preserve and reconcile: "..target:GetFullName().."."..property)
  table.insert(records,rec)
 end end
 -- All guards complete before any mutation. Exact object/property records only.
 for _,rec in records do rec.Value[rec:GetAttribute("Property")]=unpackValue(rec:GetAttribute(after),rec:GetAttribute("Property")) end
 local extras=assert(package.Extras.Value)
 extras.Parent=chapter=="PROFESSIONAL" and root["10_Institution_Fidelity_R1"] or package
 package:SetAttribute("CurrentChapter",chapter)
 root:SetAttribute("VisualReviewChapter",chapter)
 root:SetAttribute("VisualReviewOnly",true)
 return {chapter=chapter,properties=#records,variants=#package.Records:GetChildren(),extraParts=extras:GetAttribute("PartCount")}
end
function I.Install()
 local root=check();assert(not game.RunService:IsRunning(),"Install in Edit")
 assert(not SS:FindFirstChild(PACKAGE),"Already installed; use SetChapter")
 assert(root:GetAttribute("CampusPlacement01Applied"),"Align current placement first")
 local f=root["10_Institution_Fidelity_R1"]
 local package=Instance.new("Folder");package.Name=PACKAGE
 local records=Instance.new("Folder");records.Name="Records";records.Parent=package
 local extras=Instance.new("Model");extras.Name="15_Professional_Review01_Variants";extras.Parent=package
 local ref=Instance.new("ObjectValue");ref.Name="Extras";ref.Value=extras;ref.Parent=package
 local recipeSource=SS.SellCarsV5ProfessionalReview01Recipes
 local copy=recipeSource:Clone();local ok,recipes=pcall(require,copy);copy:Destroy();assert(ok,recipes)
 local seen={};local count=0;local partCount=0;local groups={}
 local C={}
 function C.resolve(path)
  local v=f;for segment in path:gmatch("[^/]+") do v=assert(v:FindFirstChild(segment),"Missing recipe target "..path) end;return v
 end
 function C.group(id,ancestry,why)
  assert(not groups[id],"Duplicate variant "..id)
  local g=Instance.new("Folder");g.Name=id;g:SetAttribute("VariantId","Professional."..id..".Review01")
  g:SetAttribute("InstitutionAncestry",ancestry);g:SetAttribute("Relationship","REPLACE_PRESENTATION_PERSIST_FOOTPRINT_AND_FUNCTION")
  g:SetAttribute("Reason",why);g.Parent=records;groups[id]=g
  local model=Instance.new("Model");model.Name=id;model:SetAttribute("BundleId","Professional."..id..".Review01");model:SetAttribute("Replaces",ancestry);model:SetAttribute("SourceOwner","ProfessionalReview01Recipes");model.Parent=extras
  return {records=g,model=model}
 end
 function C.set(g,target,property,value)
  if equal(target[property],value) then return end
  seen[target]=seen[target] or {};assert(not seen[target][property],"Duplicate property recipe "..target:GetFullName()..property);seen[target][property]=true
  count+=1;local rec=Instance.new("ObjectValue");rec.Name=string.format("%05d",count);rec.Value=target
  rec:SetAttribute("Property",property);rec:SetAttribute("Institution",property=="Material" and target.Material.Name or target[property])
  rec:SetAttribute("Professional",property=="Material" and value.Name or value);rec.Parent=g.records
  if target:IsA("BasePart") then rec:SetAttribute("GuardCFrame",target.CFrame);rec:SetAttribute("GuardSize",target.Size) end
 end
 function C.hide(g,target)
  if target:IsA("BasePart") and target.Transparency<1 then
   C.set(g,target,"Transparency",1)
   if target.CanCollide then C.set(g,target,"CanCollide",false) end
   if target.CanTouch then C.set(g,target,"CanTouch",false) end
   if target.CanQuery then C.set(g,target,"CanQuery",false) end
  elseif target:IsA("SurfaceGui") or target:IsA("BillboardGui") then C.set(g,target,"Enabled",false) end
 end
 function C.part(g,name,size,cf,color,material)
  partCount+=1;local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=g.model;return p
 end
 function C.label(part,text,face)
  local gui=Instance.new("SurfaceGui");gui.Name="Readable_Work_Record";gui.Face=face or Enum.NormalId.Front;gui.PixelsPerStud=60;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.Parent=part
  local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=text;t.TextColor3=Color3.fromRGB(221,218,197);t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=gui
 end
 local success,err=pcall(recipes.Build,C,f)
 if not success then package:Destroy();error(err) end
 extras:SetAttribute("PartCount",partCount);package:SetAttribute("CurrentChapter","INSTITUTION");package:SetAttribute("Version",I.Version)
 package:SetAttribute("InstitutionGeometry","9892d1b3");package:SetAttribute("Scope","Visual chapter only; no economy or capability binding")
 package.Parent=SS
 return {variants=#records:GetChildren(),properties=count,extraParts=partCount}
end
return I

