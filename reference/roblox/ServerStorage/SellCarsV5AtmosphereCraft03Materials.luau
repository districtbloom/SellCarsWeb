--!nocheck
-- Existing-surface finish only. No car parts, routes, physical extents or extra lights.
return function(r,f,out,change,light)
 local RGB=Color3.fromRGB
 local function group(n)local m=Instance.new("Model");m.Name=n;m:SetAttribute("FunctionId",n);m:SetAttribute("PhaseMin","INSTITUTION");m:SetAttribute("PurchaseWired",false);m.Parent=out;return m end
 group("01_Material_Balance");group("02_Existing_Task_Light_Balance")
 local prod=r["05_Architecture_Massing"]["02_Production"]
 for _,m in prod:GetChildren()do if m:FindFirstChild("OpenCanopy")then change(m.OpenCanopy,{Reflectance=0})end end
 -- Sparse, low-contrast seams retain open-roof visibility; archived by property, not deleted.
 for _,layer in {f["12_WorkshopCraft01"],f["13_DistrictFinish02"]}do
  for _,m in layer:GetDescendants()do if m:IsA("Model")and m.Name:find("Envelope_Finish")then
   local seams={};for _,p in m:GetChildren()do if p.Name=="StandingSeam"then table.insert(seams,p)end end
   table.sort(seams,function(a,b)return a.Position.Z<b.Position.Z end)
   for i,p in seams do change(p,{Transparency=i%2==0 and 1 or .45,CastShadow=false,CanQuery=i%2~=0,Material=Enum.Material.SmoothPlastic,Color=RGB(67,72,69),Reflectance=0})end
  end end
 end
 local glass={GalleryGlazing=true,SideGlazing=true,ClearCrownGlazing=true,ClerestoryGlass=true,HighClearTransom=true}
 for _,m in {f["04_Frontage_And_Owner"],f["05_Prestige_And_Public_Realm"],f["11_Frontage04"]["01_Architecture"]}do
  for _,p in m:GetDescendants()do if p:IsA("BasePart")and glass[p.Name]and p.Transparency<1 then change(p,{Reflectance=0,Color=RGB(180,197,191)})end end
 end
 local worktops={SteelWorktop=true,AntiStaticWorktop=true,TelemetryWorktop=true,ToolBenchTop=true,CraftBenchTop=true,EditorialWorktop=true,ReleaseBench=true,OakConfigurationWorktop=true}
 local ground={OriginalSlab=true,AnnexSlab=true,OwnerConcreteFloor=true}
 local scopes={f["01_Gold_Slices"],f["03_Remaining_Production"],f["02_Rear_Support"].Parts_Logistics,f["02_Rear_Support"].Staff_Operations,f["04_Frontage_And_Owner"]["03_Owner"],f["05_Prestige_And_Public_Realm"]["03_HQ_Art"]}
 for i,m in scopes do
  for _,p in m:GetDescendants()do
   if p:IsA("BasePart")and p.Transparency<1 then
    if worktops[p.Name]then
     if p.Material==Enum.Material.Metal then change(p,{Reflectance=.025,Color=p.Color:Lerp(RGB(157,162,153),.20)})
     else change(p,{Reflectance=0,Material=Enum.Material.Wood,Color=p.Color:Lerp(RGB(155,120,78),.22)})end
    elseif ground[p.Name]then change(p,{Color=RGB(148,145,133),Reflectance=0,Material=Enum.Material.Concrete})end
   elseif p:IsA("Light")and p.Enabled then
    local kind=i<=2 and"Production"or i<=4 and"Support"or i==5 and"Owner"or"Prestige"
    light(p,kind)
   end
  end
 end
 -- Existing paving already has real joints: slight panel variation, no extra floor skins.
 local panels=f["11_Frontage04"]["01_Unified_Frontage_Ground"].Warm_Stone_And_Joined_Concrete
 local list={};for _,p in panels:GetDescendants()do if p:IsA("BasePart")and p.Name:match("^Panel_")then table.insert(list,p)end end
 table.sort(list,function(a,b)return a:GetFullName()<b:GetFullName()end)
 for i,p in list do change(p,{Color=p.Color:Lerp(RGB(182,174,156),.035*(i%4)),Reflectance=0})end
 -- Calm the blue-green repetition into a desert sage family without rebuilding plants.
 for _,p in f["09_Campus03"]:GetDescendants()do if p:IsA("BasePart")and p.Transparency<1 then
  local n=p.Parent.Name
  if (n:find("Agave")or n:find("SageMass"))and p.Color.G>p.Color.R then change(p,{Color=p.Color:Lerp(RGB(113,136,115),.28),Reflectance=0})end
 end end
end

