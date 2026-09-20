--!nocheck
-- F04-4 sales presentation plus reversible actual-car preview. No final activation.
local I={Version="2026-09-08.frontage04.f4.1"}
local SS=game:GetService("ServerStorage")
local LAYER="04_Sales_And_Handover"
local RECOVERY="F04_4_Sales_Recovery"
local function fresh(name)
 local m=assert(SS:FindFirstChild(name),"Missing "..name):Clone()
 local ok,result=pcall(require,m);m:Destroy();assert(ok,result);return result
end
local function context()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 local p=assert(SS:FindFirstChild("SellCarsV5Frontage04Package"))
 assert(not p:GetAttribute("PreviewActive"),"EndPreview before sales changes")
 local c=assert(p.CandidateReference.Value);assert(c.Parent==p,"Stage candidate first")
 return p,c,assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"))
end
local function ref(parent,name,target)
 local o=Instance.new("ObjectValue");o.Name=name;o.Value=target;o.Parent=parent;return o
end
local function inventory(m)
 local n={parts=0,models=0,lights=0,scripts=0,descendants=#m:GetDescendants()}
 for _,v in m:GetDescendants()do if v:IsA("BasePart")then n.parts+=1 elseif v:IsA("Model")then n.models+=1 elseif v:IsA("Light")then n.lights+=1 elseif v:IsA("LuaSourceContainer")then n.scripts+=1 end end
 return n
end
function I.Build()
 local p,c,r=context();local G=fresh("SellCarsV5InstitutionCourtyard02Installer").GeometryHash
 assert(G(r)=="fa41fccf" and #r:GetDescendants()==19104,"Original campus changed; preserve")
 assert(G(c)=="be9bcd84" and #c:GetDescendants()==1753,"F04-3 candidate changed; preserve")
 assert(not p:FindFirstChild(RECOVERY)and not c:FindFirstChild(LAYER)and not c:FindFirstChild("06_Actual_Sales_Vehicles"),"Existing sales content preserved")
 local rec=Instance.new("Folder");rec.Name=RECOVERY
 rec:SetAttribute("Version",I.Version);rec:SetAttribute("CandidateBefore",G(c));rec:SetAttribute("CampusBefore",G(r))
 rec:SetAttribute("FullPlaceBackup",false);rec:SetAttribute("PreviousStatus",c:GetAttribute("Status"))
 local snapshot=c:Clone();assert(#snapshot:GetDescendants()==#c:GetDescendants());snapshot.Name="F04_3_FurnishedCandidate_BeforeSales";snapshot.Parent=rec
 local sources=Instance.new("Folder");sources.Name="ExactSources";sources.Parent=rec
 for _,name in {"SellCarsV5Frontage04Sales","SellCarsV5Frontage04VehiclePreview","SellCarsV5InstitutionFrontage04SalesInstaller","SellCarsV5InstitutionFrontage04Installer"}do
  local original=assert(SS:FindFirstChild(name));local copy=original:Clone();assert(copy.Source==original.Source);copy.Parent=sources
 end
 local stage=Instance.new("Folder")
 local ok,result=pcall(function()
  local layer=fresh("SellCarsV5Frontage04Sales")(fresh("SellCarsV5Frontage04Kit"),stage,r)
  assert(layer and layer.Name==LAYER and layer.Parent==stage,"Unexpected sales builder output")
  assert(G(r)=="fa41fccf","Original campus changed during builder")
  local counts=inventory(layer);assert(counts.lights==0 and counts.scripts==0,"Sales art must not contain active systems")
  return layer
 end)
 if not ok then stage:Destroy();rec:Destroy();error(result)end
 rec.Parent=p;local layer=result;ref(rec,"LayerReference",layer);layer.Parent=c;stage:Destroy()
 local actual=Instance.new("Model");actual.Name="06_Actual_Sales_Vehicles"
 actual:SetAttribute("SourceOwned",true);actual:SetAttribute("GroundSalesCapacity",6);actual:SetAttribute("ElevatedSalesCapacity",0)
 actual:SetAttribute("FidelityBatch","F04_4");actual:SetAttribute("VisualPreviewOnly",true);actual.Parent=c
 ref(rec,"ActualVehiclesFolder",actual)
 c:SetAttribute("F04SalesPreviewReady",true);c:SetAttribute("FitoutHasLaterDependants",true)
 c:SetAttribute("Status","F04_4_SALES_CANDIDATE_NOT_ACTIVATED");rec:SetAttribute("Attached",true)
 return {sales=inventory(layer),candidate=inventory(c),recovery=rec:GetFullName()}
end
function I.Detach()
 local p,c=context();local rec=assert(p:FindFirstChild(RECOVERY));local layer=assert(rec.LayerReference.Value);local actual=assert(rec.ActualVehiclesFolder.Value)
 assert(not c:GetAttribute("Frontage04Activated") and not c:GetAttribute("SalesHasLaterDependants"),"Retire later consumers first")
 assert(layer.Parent==c and actual.Parent==c and #actual:GetChildren()==0,"Restore actual cars through EndPreview first")
 layer.Parent=rec;actual.Parent=rec;c:SetAttribute("F04SalesPreviewReady",nil);c:SetAttribute("FitoutHasLaterDependants",nil)
 c:SetAttribute("Status",rec:GetAttribute("PreviousStatus"));rec:SetAttribute("Attached",false)
 return {detached=true,candidateDescendants=#c:GetDescendants()}
end
function I.Reattach()
 local p,c=context();local rec=assert(p:FindFirstChild(RECOVERY));local layer=assert(rec.LayerReference.Value);local actual=assert(rec.ActualVehiclesFolder.Value)
 assert(layer.Parent==rec and actual.Parent==rec and not c:FindFirstChild(LAYER)and not c:FindFirstChild(actual.Name),"Sales destination changed")
 layer.Parent=c;actual.Parent=c;c:SetAttribute("F04SalesPreviewReady",true);c:SetAttribute("FitoutHasLaterDependants",true)
 c:SetAttribute("Status","F04_4_SALES_CANDIDATE_NOT_ACTIVATED");rec:SetAttribute("Attached",true)
 return inventory(layer)
end
return I

