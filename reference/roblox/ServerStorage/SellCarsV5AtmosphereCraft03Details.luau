--!nocheck
-- Small named sets supported on current worktops; full occupied pockets are skipped.
return function(r,f,out)
 local V,CF,RGB=Vector3.new,CFrame.new,Color3.fromRGB
 local C={steel=RGB(154,163,159),dark=RGB(49,55,51),wood=RGB(151,112,68),paper=RGB(207,199,169),teal=RGB(80,110,106),brass=RGB(172,142,82)}
 local report={placed={},skipped={}}
 local function model(n,fn)
  local m=Instance.new("Model");m.Name=n;m.Parent=out;m:SetAttribute("BundleId","Institution.AtmosphereCraft03."..n);m:SetAttribute("FunctionId",fn);m:SetAttribute("PhaseMin","INSTITUTION");m:SetAttribute("PurchaseWired",false);m:SetAttribute("AssetStatus","NATIVE_VISUAL_PROXY");return m
 end
 local function box(m,n,cf,s,c,mat)
  local p=Instance.new("Part");p.Name=n;p.CFrame=cf;p.Size=s;p.Color=c or C.dark;p.Material=mat or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=m;return p
 end
 local function cylinder(m,n,cf,h,d,c)
  local p=box(m,n,cf*CFrame.Angles(0,0,math.pi/2),V(h,d,d),c,Enum.Material.Metal);p.Shape=Enum.PartType.Cylinder;return p
 end
 local function surface(m,n,cf,w,d,c)return box(m,n,cf,V(w,.025,d),c)end
 local function tray(m,cf)
  surface(m,"SoftServiceTray",cf,2,1.6,C.dark)
  for _,x in {-1,1}do box(m,"TrayFold",cf*CF(x,.12,0),V(.08,.24,1.6),C.dark)end
  for _,z in {-.8,.8}do box(m,"TrayEnd",cf*CF(0,.12,z),V(2,.24,.08),C.dark)end
 end
 local function kit(m,cf,kind)
  tray(m,cf)
  if kind=="service"or kind=="calibration"then
   for i=1,4 do local x=-.72+(i-1)*.46
    cylinder(m,"SortedSocket",cf*CF(x,.23,.24),.34,.26,C.steel)
    cylinder(m,"SocketRecess",cf*CF(x,.407,.24),.025,.13,C.dark)
   end
   box(m,"CaliperBeam",cf*CF(0,.12,-.42),V(1.55,.09,.13),C.steel,Enum.Material.Metal)
   for _,x in {-.66,.1}do box(m,"MeasuringJaw",cf*CF(x,.14,-.3),V(.08,.12,.37),C.steel,Enum.Material.Metal)end
   box(m,"SlidingReadout",cf*CF(.16,.17,-.45),V(.37,.18,.22),C.dark)
   box(m,"ReadoutGlass",cf*CF(.16,.264,-.45),V(.27,.012,.14),C.teal)
  elseif kind=="finish"then
   for i=1,4 do
    local col=({RGB(142,72,50),RGB(90,120,110),RGB(154,130,83),RGB(68,78,100)})[i]
    box(m,"SprayOutCard",cf*CF(-.72+(i-1)*.46,.06,0)*CFrame.Angles(0,math.rad((i-2)*7),0),V(.37,.05,1.16),C.paper)
    surface(m,"PaintedSample",cf*CF(-.72+(i-1)*.46,.091,.12)*CFrame.Angles(0,math.rad((i-2)*7),0),.31,.77,col)
   end
  elseif kind=="packing"then
   box(m,"ProtectiveWrap",cf*CF(-.4,.1,0),V(.84,.16,1.25),C.paper,Enum.Material.Fabric)
   cylinder(m,"TapeRoll",cf*CF(.45,.18,.22),.3,.60,C.brass)
   cylinder(m,"TapeCore",cf*CF(.45,.335,.22),.025,.32,C.paper)
   box(m,"PackingCutter",cf*CF(.4,.11,-.45),V(.76,.16,.23),C.teal)
   box(m,"CutterBlade",cf*CF(.84,.11,-.45),V(.2,.07,.16),C.steel,Enum.Material.Metal)
  elseif kind=="presentation"then
   for i=1,3 do surface(m,"ContactPrint",cf*CF((i-2)*.54,.05,0),.46,1.18,C.paper);surface(m,"PhotoFrame",cf*CF((i-2)*.54,.073,.14),.38,.78,({C.teal,C.wood,C.steel})[i])end
   box(m,"GreasePencil",cf*CF(0,.13,-.58),V(1.52,.08,.08),C.brass)
  else
   for i=1,3 do box(m,"FoldedMicrofibre",cf*CF(0,.09+(i-1)*.16,0),V(1.5,.14,1.08),i==2 and C.teal or C.paper,Enum.Material.Fabric)end
   for i=1,3 do box(m,"TowelHem",cf*CF(0,.12+(i-1)*.16,-.49),V(1.4,.03,.04),C.wood,Enum.Material.Fabric)end
  end
 end
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={r};op.RespectCanCollide=false
 local function free(top,x,z)
  local cf=top.CFrame*CF(x,top.Size.Y/2+.45,z)
  for _,p in workspace:GetPartBoundsInBox(cf,V(2.3,.82,1.9),op)do
   if p~=top and p.Transparency<.98 then
    -- Existing coplanar mat is occupied too; avoid making duplicate equipment sets.
    return false
   end
  end
  return true
 end
 local function onBench(scope,name,id,fn,kind)
  local top=scope:FindFirstChild(name,true);assert(top,id.." support missing")
  local chosen
  local ax=math.max(0,top.Size.X/2-1.35);local az=math.max(0,top.Size.Z/2-1.15)
  for _,p in {{ax,az},{-ax,az},{ax,-az},{-ax,-az},{0,az},{0,-az},{ax,0},{-ax,0},{0,0}}do if free(top,p[1],p[2])then chosen=p;break end end
  if not chosen then table.insert(report.skipped,id..": existing top occupied");return end
  local m=model(id,fn);local ref=Instance.new("ObjectValue");ref.Name="WorktopSupport";ref.Value=top;ref.Parent=m
  kit(m,top.CFrame*CF(chosen[1],top.Size.Y/2+.027,chosen[2]),kind)
  -- Short abrasion lines confined to the hand-contact edge, never a broad dirty decal.
  for i=1,5 do box(m,"RestrainedEdgeWear",top.CFrame*CF(-top.Size.X/2+.5+i*.27,top.Size.Y/2+.009,-top.Size.Z/2+.16),V(.19+.025*i,.012,.028),top.Color:Lerp(C.paper,.23))end
  table.insert(report.placed,id)
 end
 local gold,prod=f["01_Gold_Slices"],f["03_Remaining_Production"]
 onBench(gold.Mechanical.Tool_Bench_And_Vice,"SteelWorktop","Mechanical_Service_Set","Mechanical","service")
 onBench(gold.Paint_Exterior.Mix_Bank_And_Rare_Finishes,"SteelWorktop","Paint_Spray_Out_Set","Paint_Exterior","finish")
 onBench(gold.Paint_Exterior.Film_Cutting_And_Glass,"SteelWorktop","Exterior_Material_Set","Paint_Exterior","finish")
 onBench(prod["02_Body"].Panel_Craft_Bench_And_Tools,"CraftBenchTop","Body_Measuring_Set","Body_Restoration","service")
 onBench(prod["03_Tune"].ECU_And_Sensor_Calibration_Bench,"AntiStaticWorktop","Tune_Calibration_Set","Tune_Performance","calibration")
 onBench(prod["04_Detail"].Finish_Measurement_And_Release_Desk,"ReleaseBench","Detail_Clean_Cloths","Detail_QC","cloth")
 onBench(prod["05_Photo"].Editorial_And_Listing_Workstation,"EditorialWorktop","Photo_Contact_Sheets","Photo_Listing","presentation")
 local rear=f["02_Rear_Support"]
 onBench(rear.Parts_Logistics.Kitting_Packing_And_Dispatch,"Worktop","Parts_Packing_Set","Parts_Logistics","packing")
 onBench(rear.Parts_Logistics.Rare_Parts_Control,"Worktop","Rare_Parts_Protective_Set","Parts_Logistics","cloth")
 local owner=f["04_Frontage_And_Owner"]["03_Owner"]
 onBench(owner.Owner_Craft_Bench,"ToolBenchTop","Owner_Measuring_Set","Owner_Garage","service")
 onBench(owner.Personal_Configuration_Studio,"OakConfigurationWorktop","Owner_Finish_Selection","Owner_Garage","finish")
 -- Dry seed heads at the outside tips of planted shoulders, not the central walking path.
 local gardens=f["09_Campus03"]["01_Desert_Promenade"]
 for _,garden in gardens:GetChildren()do if garden:IsA("Model")then
  local m=model(garden.Name.."_Seasonal_Seedheads","Landscape")
  for _,bed in garden:GetChildren()do if bed:IsA("BasePart")and bed.Name:find("WarmGravelShoulder")then
   for _,zsign in {-1,1}do
    local x=bed.Name:sub(-1)=="1"and -3.8 or 3.8
    local cf=bed.CFrame*CF(x,bed.Size.Y/2, zsign*(bed.Size.Z/2-1.3))
    for j=1,4 do
     local xoff=(j-2.5)*.2;local zoff=j%2*.18;local h=1.25+(j%3)*.32
     local stem=box(m,"DryFlowerStem",cf*CF(xoff,h/2,zoff),V(.045,h,.045),RGB(135,121,72))
     local seed=box(m,"OchreSeedHead",cf*CF(xoff,h+.09,zoff),V(.21,.36,.19),RGB(173,147,85));seed.Shape=Enum.PartType.Ball
    end
   end
  end end
 end end
 return report
end

