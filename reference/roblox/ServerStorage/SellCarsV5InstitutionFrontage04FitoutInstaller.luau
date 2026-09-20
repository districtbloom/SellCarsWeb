--!nocheck
-- F04-3 extends the existing candidate only. It never replaces live frontage.
local I={Version="2026-09-08.frontage04.f3.1"}
local SS=game:GetService("ServerStorage")
local NAME="03_Hospitality_And_Receiving"
local RECOVERY="F04_3_Fitout_Recovery"
local function fresh(name)
 local m=assert(SS:FindFirstChild(name),"Missing "..name):Clone()
 local ok,result=pcall(require,m);m:Destroy();assert(ok,result);return result
end
local function context()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 local p=assert(SS:FindFirstChild("SellCarsV5Frontage04Package"))
 assert(not p:GetAttribute("PreviewActive"),"EndPreview before fit-out changes")
 local c=assert(p.CandidateReference.Value)
 assert(c.Parent==p,"Candidate must be staged before changing")
 return p,c,assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"))
end
local function ref(parent,name,target)
 local o=Instance.new("ObjectValue");o.Name=name;o.Value=target;o.Parent=parent;return o
end
local function inventory(layer)
 local out={parts=0,models=0,lights=0,enabledLights=0,scripts=0,descendants=#layer:GetDescendants()}
 for _,v in layer:GetDescendants()do
  if v:IsA("BasePart")then out.parts+=1 elseif v:IsA("Model")then out.models+=1
  elseif v:IsA("Light")then out.lights+=1;if v.Enabled then out.enabledLights+=1 end
  elseif v:IsA("LuaSourceContainer")then out.scripts+=1 end
 end
 return out
end
function I.Build(expectedCampusHash)
 local p,c,r=context()
 assert(not c:FindFirstChild(NAME)and not p:FindFirstChild(RECOVERY),"Existing fit-out/recovery preserved; no overwrite")
 local G=fresh("SellCarsV5InstitutionCourtyard02Installer").GeometryHash
 assert(expectedCampusHash and G(r)==expectedCampusHash,"Campus changed; recapture current state")
 assert(#c:GetDescendants()==1142 and G(c)=="1a0de2be","F04-2 candidate changed; inspect before extension")
 local recovery=Instance.new("Folder");recovery.Name=RECOVERY
 recovery:SetAttribute("Version",I.Version);recovery:SetAttribute("FullPlaceBackup",false)
 recovery:SetAttribute("CampusBefore",G(r));recovery:SetAttribute("CandidateBefore",G(c))
 recovery:SetAttribute("CandidateStatusBefore",c:GetAttribute("Status"))
 local backup=assert(c:Clone());assert(#backup:GetDescendants()==#c:GetDescendants(),"Incomplete candidate recovery")
 backup.Name="F04_2_Candidate_Before_Fitout";backup.Parent=recovery
 local sources=Instance.new("Folder");sources.Name="ExactSources";sources.Parent=recovery
 for _,name in {"SellCarsV5Frontage04Hospitality","SellCarsV5Frontage04Receiving","SellCarsV5InstitutionFrontage04FitoutInstaller"}do
  local original=assert(SS:FindFirstChild(name));local copy=original:Clone();assert(copy.Source==original.Source);copy.Parent=sources
 end
 local layer=Instance.new("Model");layer.Name=NAME
 layer:SetAttribute("Version",I.Version);layer:SetAttribute("SourceOwned",true)
 layer:SetAttribute("FidelityBatch","F04_3");layer:SetAttribute("PhaseMin","INSTITUTION")
 layer:SetAttribute("Status","FURNISHED_CANDIDATE_NOT_ACTIVATED")
 local ok,err=pcall(function()
  local K=fresh("SellCarsV5Frontage04Kit")
  fresh("SellCarsV5Frontage04Hospitality")(K,layer)
  fresh("SellCarsV5Frontage04Receiving")(K,layer,r)
  assert(G(r)==expectedCampusHash,"A builder modified the original campus")
  local counts=inventory(layer);assert(counts.scripts==0 and counts.enabledLights==0,"No active drivers/lights in this batch")
 end)
 if not ok then layer:Destroy();recovery:Destroy();error(err)end
 recovery.Parent=p;ref(recovery,"LayerReference",layer)
 layer.Parent=c;c:SetAttribute("Status","F04_3_FURNISHED_CANDIDATE_NOT_ACTIVATED")
 recovery:SetAttribute("Attached",true)
 return {layer=inventory(layer),candidate=inventory(c),campusGeometry=G(r),recovery=recovery:GetFullName(),status="F04_3_BUILT_STAGED_NOT_ACTIVATED"}
end
function I.Detach()
 local p,c=context();local recovery=assert(p:FindFirstChild(RECOVERY));local l=assert(recovery.LayerReference.Value)
 assert(l.Parent==c,"Fit-out is not attached")
 assert(not c:GetAttribute("Frontage04Activated") and not c:GetAttribute("FitoutHasLaterDependants"),"Retire later consumers first")
 l.Parent=recovery;recovery:SetAttribute("Attached",false)
 c:SetAttribute("Status",recovery:GetAttribute("CandidateStatusBefore"))
 return {detached=l:GetFullName(),candidateDescendants=#c:GetDescendants()}
end
function I.Reattach()
 local p,c=context();local recovery=assert(p:FindFirstChild(RECOVERY));local l=assert(recovery.LayerReference.Value)
 assert(l.Parent==recovery and not c:FindFirstChild(NAME),"Fit-out destination changed")
 l.Parent=c;recovery:SetAttribute("Attached",true);c:SetAttribute("Status","F04_3_FURNISHED_CANDIDATE_NOT_ACTIVATED")
 return inventory(l)
end
return I

