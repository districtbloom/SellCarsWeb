local M={RootName='CC06_CampusFinishEdit',Version='2026-09-09.CC06'}
function M.Build(root,reg,_,rec)
 local K=require(game.ServerStorage.SellCarsV5CraftsmanshipKit);local V,CF=K.V,K.CF;local g,done=K.begin(root,reg,M.RootName,M.Version)
 -- Remove only mature oversized captions; useful departmental signs and inherited objects stay.
 for _,spec in {{'P169_Tune_Craft_Obsession',211},{'P181_Photo_Craft_Obsession',217},{'P156_Crew_Wall_Of_Fame',238}}do
  local m=root.ST_Character[spec[1]];for _,p in m:GetDescendants()do if p:IsA('BasePart')and p.Name=='HandPaintedBoard'then K.retire(rec,p,spec[2])end end
 end
 local hierarchy=root['10_Institution_Fidelity_R1']['06_Atmosphere']['03_Lighting_Hierarchy']
 g(240,'Campus_Lighting_Hierarchy_Edit',hierarchy,function(m)
  for _,light in hierarchy:GetDescendants()do if light:IsA('Light')and light.Parent:IsA('BasePart')then
   local old=light.Parent;K.retire(rec,old,240)
   local q=old:Clone();q:ClearAllChildren();q.Name='CalibratedRecessedLens';q.Parent=m;q.Color=Color3.fromRGB(236,219,182);q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
   for key in q:GetAttributes()do q:SetAttribute(key,nil)end
   local new=light:Clone();new.Brightness=old.Position.Z>390 and .65 or .7;new.Color=old.Position.Z>390 and Color3.fromRGB(255,211,158)or Color3.fromRGB(239,241,230);new.Shadows=true;new.Parent=q
  end end
 end)
 return done()
end
return M

