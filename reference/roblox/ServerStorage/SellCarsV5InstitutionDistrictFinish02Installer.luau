--!nocheck
-- Bounded transaction per district. No historical generator is run.
local I={Version="2026-09-08.districtfinish02.1"}
local SS=game:GetService("ServerStorage")
local NAME="SellCarsV5DistrictFinish02Recovery"
local function fresh(n)local c=assert(SS:FindFirstChild(n),n):Clone();local ok,v=pcall(require,c);c:Destroy();assert(ok,v);return v end
local function folder(p,n)local f=Instance.new("Folder");f.Name=n;f.Parent=p;return f end
local function ref(p,n,v)local a=Instance.new("ObjectValue");a.Name=n;a.Value=v;a.Parent=p;return a end
local function context()
 assert(game.PlaceId==125334614375606 and not game:GetService("RunService"):IsRunning(),"Sell Cars Tycoon / Edit required")
 local r=assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"))
 assert(r:GetAttribute("Frontage04Activated"),"Expected active Institution frontage")
 return r,r["10_Institution_Fidelity_R1"]
end
local function package()
 local r,f=context();local K=fresh("SellCarsV5DistrictFinish02Kit")
 local rec=SS:FindFirstChild(NAME)
 if not rec then
  assert(not f:FindFirstChild("13_DistrictFinish02"))
  rec=folder(SS,NAME);rec:SetAttribute("Version",I.Version);ref(rec,"Institution",r)
  local l=K.group(f,"13_DistrictFinish02","Campus","Production street and rear destination")
  ref(rec,"Layer",l);folder(rec,"Batches");folder(rec,"SourceCopies")
  for _,n in {"SellCarsV5DistrictFinish02Kit","SellCarsV5DistrictFinish02Production","SellCarsV5DistrictFinish02Rear","SellCarsV5InstitutionDistrictFinish02Installer"}do local c=SS[n]:Clone();c.Parent=rec.SourceCopies end
 end
 assert(rec.Institution.Value==r,"Different Institution; preserve")
 return r,f,K,rec,rec.Layer.Value
end
local function install(kind,fn)
 local r,f,K,rec,l=package();local id=kind.."_"..fn
 assert(not rec.Batches:FindFirstChild(id),"Existing district preserved")
 local batch=folder(rec.Batches,id);batch:SetAttribute("State","PREPARING");local records=folder(batch,"Properties")
 local out=K.group(nil,id,fn,kind.." environment finish");ref(batch,"Layer",out);ref(batch,"Destination",l)
 local seen={}
 local function change(p,props)
  local q=seen[p]
  if not q then q=ref(records,string.format("%04d",#records:GetChildren()+1),p);seen[p]=q;folder(q,"Before");folder(q,"After")end
  for k,v in props do if q.Before:GetAttribute(k)==nil then q.Before:SetAttribute(k,p[k])end;q.After:SetAttribute(k,v)end
 end
 local ok,result=pcall(function()
  if kind=="Production"then
   return fresh("SellCarsV5DistrictFinish02Production")(K,out,r["05_Architecture_Massing"]["02_Production"][fn],fn,change)
  else return fresh("SellCarsV5DistrictFinish02Rear")(K,out,f,fn,change)end
 end)
 if not ok then out.Parent=batch;batch:SetAttribute("State","BUILD_FAILED");batch:SetAttribute("Error",tostring(result));error(result)end
 -- Commit only after complete candidate construction.
 for _,q in records:GetChildren()do for k,v in q.After:GetAttributes()do q.Value[k]=v;q.After:SetAttribute(k,q.Value[k])end end
 out.Parent=l;batch:SetAttribute("State","ATTACHED");batch:SetAttribute("PartCount",result.parts)
 return result
end
function I.InstallProduction(fn)return install("Production",fn)end
function I.InstallRear(fn)return install("Rear",fn)end
function I.Detach(id)
 context();local rec=assert(SS:FindFirstChild(NAME));local b=assert(rec.Batches:FindFirstChild(id));assert(b:GetAttribute("State")=="ATTACHED")
 for _,q in b.Properties:GetChildren()do assert(q.Value,"Missing original");for k,v in q.After:GetAttributes()do assert(q.Value[k]==v,"Later property change: "..k)end end
 for _,q in b.Properties:GetChildren()do for k,v in q.Before:GetAttributes()do q.Value[k]=v end end
 b.Layer.Value.Parent=b;b:SetAttribute("State","DETACHED");return id
end
function I.Reattach(id)
 context();local rec=assert(SS:FindFirstChild(NAME));local b=assert(rec.Batches:FindFirstChild(id));assert(b:GetAttribute("State")=="DETACHED")
 for _,q in b.Properties:GetChildren()do assert(q.Value);for k,v in q.Before:GetAttributes()do assert(q.Value[k]==v,"Later property change: "..k)end end
 for _,q in b.Properties:GetChildren()do for k,v in q.After:GetAttributes()do q.Value[k]=v end end
 b.Layer.Value.Parent=b.Destination.Value;b:SetAttribute("State","ATTACHED");return id
end
return I

