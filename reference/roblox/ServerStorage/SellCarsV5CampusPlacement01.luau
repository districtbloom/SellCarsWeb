--!nocheck
-- Runtime coordinate adapter. Geometry is authoritative; old authoring coordinates
-- are transformed exactly once before occupation timelines are constructed.
local I={Version="2026-09-08.placement01"}
function I.Offset()
 local r=workspace:FindFirstChild("SellCars_Dealership_Growth_V5")
 return r and r:GetAttribute("CampusRuntimeOffset") or Vector3.zero
end
function I.ApplyOccupation(defs)
 local delta=I.Offset()
 for _,d in ipairs(defs) do
  assert(not d._CampusPlacement01,"Occupation definitions already transformed")
  for _,k in {"home","target","center","destinationPoint","destinationTarget"} do
   if typeof(d[k])=="Vector3" then d[k]+=delta end
  end
  if d.route then for i,p in ipairs(d.route) do d.route[i]=p+delta end end
  if type(d.anchorY)=="number" then d.anchorY+=delta.Y end
  d._CampusPlacement01=true
 end
end
return I

