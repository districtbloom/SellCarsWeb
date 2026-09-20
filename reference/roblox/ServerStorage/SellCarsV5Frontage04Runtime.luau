--!nocheck
-- F04-5 compatibility adapter. Called by the existing shared occupation/light
-- controllers; no new connection, actor script, purchase logic or global rewrite.
local I={Version="2026-09-08.frontage04.f5.1"}
local ROOT="SellCars_Dealership_Growth_V5"
local FIDELITY="10_Institution_Fidelity_R1"
local FRONTAGE="11_Frontage04"
local V=Vector3.new

local function active()
 if game.PlaceId~=125334614375606 then return nil end
 local r=workspace:FindFirstChild(ROOT)
 local f=r and r:FindFirstChild(FIDELITY)
 local c=f and f:FindFirstChild(FRONTAGE)
 if not c or c:GetAttribute("Frontage04Activated")~=true then return nil end
 return c
end

-- Fresh data every call: installers can make exact anchors/recovery independently
-- without changing a module-cached table or requiring an already-active candidate.
function I.ActorLayout()
 local anchor=FRONTAGE.."/08_Integration_Anchors/"
 local floor=FRONTAGE.."/01_Unified_Frontage_Ground/Continuous_Physical_Finish/Main_Joined_Substrate"
 local list={
  {id="SeniorAppraiser",home=V(3066,.235,59.3),target=V(3066,.235,52.4)},
  {id="Seller",home=V(3066,.235,52.4),target=V(3066,.235,59.3)},
  {id="SalesAdvisor",home=V(3074.8,.235,16.05),target=V(3079.55,.235,16.05)},
  {id="Buyer",home=V(3074.8,.235,21.3),target=V(3074.8,.235,16.05)},
  {id="DeliveryHost",home=V(3112,.235,81.3),target=V(3104.5,.235,81.1)},
 }
 for _,d in ipairs(list)do d.anchor=anchor..d.id;d.anchorY=.23;d.floor=floor end
 return list
end

-- Must be called BEFORE byId and timeline construction in the shared installer.
-- The original five roles remain finite stationary tasks facing their work; no
-- new walk route is invented. YardVisitor and CourtVisitor are never touched.
function I.ApplyOccupation(defs)
 if not active()then return false,0 end
 assert(type(defs)=="table","Frontage occupation definitions missing")
 local layout=I.ActorLayout()
 -- Validate the existing contract before changing any table entries.
 for i,d in ipairs(layout)do
  assert(type(defs[i])=="table" and defs[i].id==d.id,"Unexpected frontage occupation order at "..i)
  assert(defs[i].route==nil,"Existing frontage actor route changed; review before overriding spatial data")
 end
 for i,d in ipairs(layout)do
  local target=defs[i]
  target.home=d.home;target.target=d.target;target.anchor=d.anchor
  target.anchorY=d.anchorY;target.floor=d.floor
 end
 return true,#layout
end

-- Shared 7B ApplyPreset calls this LAST, after its retained baseline records.
-- Only new frontage-managed fixtures are overridden, so source baseline recovery
-- and unrelated production/campus light policies stay with their old controller.
function I.ApplyLighting(name)
 local c=active();if not c then return false,0 end
 assert(name=="Day" or name=="Night","Frontage lighting preset must be Day or Night")
 local root=assert(c:FindFirstChild("07_Frontage_Warm_Lighting"),"Active frontage lighting layer missing")
 local color=root:GetAttribute("WarmColor") or Color3.fromRGB(255,224,177)
 local pending={}
 for _,light in ipairs(root:GetDescendants())do
  if light:IsA("Light") and light:GetAttribute("SharedPresetManaged")==true then
   local brightness=light:GetAttribute(name.."Brightness")
   local range=light:GetAttribute("ManagedRange")
   assert(type(brightness)=="number" and brightness>=0,"Invalid frontage fixture brightness: "..light:GetFullName())
   assert(type(range)=="number" and range>0 and range<=32,"Invalid bounded frontage fixture range: "..light:GetFullName())
   table.insert(pending,{light=light,brightness=brightness,range=range})
  end
 end
 for _,d in ipairs(pending)do
  d.light.Color=color;d.light.Range=d.range;d.light.Brightness=d.brightness
  d.light.Shadows=false;d.light.Enabled=d.brightness>0
 end
 root:SetAttribute("Preset",name)
 return true,#pending
end

return I

