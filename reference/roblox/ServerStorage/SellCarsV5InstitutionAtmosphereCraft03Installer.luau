--!nocheck
-- Two reversible batches, one existing preset hook. No heartbeat or per-prop scripts.
local I={Version="2026-09-08.atmospherecraft03.1"}
local SS=game:GetService("ServerStorage")
local NAME="SellCarsV5AtmosphereCraft03Recovery"
local function fresh(n)local c=assert(SS:FindFirstChild(n),n):Clone();local ok,v=pcall(require,c);c:Destroy();assert(ok,v);return v end
local function folder(p,n)local m=Instance.new("Folder");m.Name=n;m.Parent=p;return m end
local function ref(p,n,v)local m=Instance.new("ObjectValue");m.Name=n;m.Value=v;m.Parent=p;return m end
local function context()
 assert(game.PlaceId==125334614375606,"Wrong place")
 local r=assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"));assert(r:GetAttribute("Frontage04Activated"))
 return r,r["10_Institution_Fidelity_R1"]
end
local function setup()
 assert(not game:GetService("RunService"):IsRunning(),"Edit required")
 local r,f=context();local rec=SS:FindFirstChild(NAME)
 if not rec then
  assert(not f:FindFirstChild("14_AtmosphereCraft03"));rec=folder(SS,NAME);ref(rec,"Institution",r);folder(rec,"Batches");folder(rec,"SourceCopies")
  local l=Instance.new("Model");l.Name="14_AtmosphereCraft03";l:SetAttribute("PhaseMin","INSTITUTION");l:SetAttribute("PurchaseWired",false);l.Parent=f;ref(rec,"Layer",l)
  for _,n in {"SellCarsV5AtmosphereCraft03Materials","SellCarsV5AtmosphereCraft03Details","SellCarsV5InstitutionAtmosphereCraft03Installer"}do SS[n]:Clone().Parent=rec.SourceCopies end
 end
 assert(rec.Institution.Value==r);return r,f,rec
end
local function record(batch,p,props)
 local q
 for _,v in batch.Properties:GetChildren()do if v.Value==p then q=v;break end end
 if not q then q=ref(batch.Properties,string.format("%04d",#batch.Properties:GetChildren()+1),p);folder(q,"Before");folder(q,"After")end
 for k,v in props do if q.Before:GetAttribute(k)==nil then q.Before:SetAttribute(k,p[k])end;q.After:SetAttribute(k,v)end
 return q
end
local function put(q,values)
 for k,v in values do q.Value[k]=v;q.After:SetAttribute(k,q.Value[k])end
end
function I.ApplyLighting(preset)
 assert(preset=="Day"or preset=="Night");local rec=SS:FindFirstChild(NAME);if not rec then return end
 local b=rec.Batches:FindFirstChild("A_Materials_And_Light");if not b or b:GetAttribute("State")~="ATTACHED"then return end
 local day=preset=="Day"
 for _,q in b.Properties:GetChildren()do
  local kind=q:GetAttribute("LightKind")
  if kind then
   local bright=kind=="Support"and(day and 1.55 or 1.35)or kind=="Production"and(day and 1.3 or 1.30)or(day and 1.15 or .98)
   local range=kind=="Support"and 28 or math.min(25,q.Before:GetAttribute("Range")+3)
   put(q,{Brightness=bright,Range=range,Color=(kind=="Production"or kind=="Support")and Color3.fromRGB(239,238,225)or q.Before:GetAttribute("Color")})
  elseif q:GetAttribute("GlobalBalance")then
   put(q,{Ambient=day and Color3.fromRGB(81,79,72)or Color3.fromRGB(68,73,84),EnvironmentSpecularScale=day and .55 or .65})
  end
 end
 b:SetAttribute("Preset",preset)
end
function I.Install(id)
 assert(id=="A_Materials_And_Light"or id=="B_Lived_In_Craft")
 local r,f,rec=setup();assert(not rec.Batches:FindFirstChild(id),"Existing batch preserved")
 local b=folder(rec.Batches,id);folder(b,"Properties");b:SetAttribute("State","PREPARING")
 local out=Instance.new("Model");out.Name=id;out:SetAttribute("BundleId","Institution.AtmosphereCraft03."..id);out:SetAttribute("PhaseMin","INSTITUTION");out:SetAttribute("PurchaseWired",false);ref(b,"Layer",out);ref(b,"Destination",rec.Layer.Value)
 local ok,result=pcall(function()
  if id=="A_Materials_And_Light"then
   fresh("SellCarsV5AtmosphereCraft03Materials")(r,f,out,function(p,props)record(b,p,props)end,function(p,kind)
    local q=record(b,p,{Brightness=p.Brightness,Range=p.Range,Color=p.Color});q:SetAttribute("LightKind",kind)
   end)
   local q=record(b,game.Lighting,{Ambient=game.Lighting.Ambient,EnvironmentSpecularScale=game.Lighting.EnvironmentSpecularScale});q:SetAttribute("GlobalBalance",true)
  else return fresh("SellCarsV5AtmosphereCraft03Details")(r,f,out)end
 end)
 if not ok then out.Parent=b;b:SetAttribute("State","BUILD_FAILED");error(result)end
 for _,q in b.Properties:GetChildren()do put(q,q.After:GetAttributes())end
 out.Parent=rec.Layer.Value;b:SetAttribute("State","ATTACHED")
 if id=="A_Materials_And_Light"then I.ApplyLighting("Day")end
 return {batch=id,descendants=#out:GetDescendants(),properties=#b.Properties:GetChildren(),detailReport=result}
end
function I.Detach(id)
 setup();local rec=SS[NAME];local b=assert(rec.Batches:FindFirstChild(id));assert(b:GetAttribute("State")=="ATTACHED")
 assert(game.Lighting.ClockTime>15.59 and game.Lighting.ClockTime<15.61,"Restore Day preset before recovery")
 for _,q in b.Properties:GetChildren()do assert(q.Value);for k,v in q.After:GetAttributes()do assert(q.Value[k]==v,"Later property change preserved: "..k)end end
 for _,q in b.Properties:GetChildren()do for k,v in q.Before:GetAttributes()do q.Value[k]=v end end
 b.Layer.Value.Parent=b;b:SetAttribute("State","DETACHED");return id
end
function I.Reattach(id)
 setup();local b=SS[NAME].Batches[id];assert(b:GetAttribute("State")=="DETACHED")
 assert(game.Lighting.ClockTime>15.59 and game.Lighting.ClockTime<15.61,"Day required")
 for _,q in b.Properties:GetChildren()do for k,v in q.Before:GetAttributes()do assert(q.Value[k]==v,"Later property change preserved")end end
 for _,q in b.Properties:GetChildren()do put(q,q.After:GetAttributes())end
 b.Layer.Value.Parent=b.Destination.Value;b:SetAttribute("State","ATTACHED");if id=="A_Materials_And_Light"then I.ApplyLighting("Day")end;return id
end
return I

