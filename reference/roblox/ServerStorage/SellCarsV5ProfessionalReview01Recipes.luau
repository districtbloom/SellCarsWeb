--!nocheck
-- Explicit, source-owned Professional predecessors. Original geometry is never
-- regenerated or removed. Safety, staff, routes, portals and cars persist.
local I={}
local V=Vector3.new;local C=Color3.fromRGB
local steel=C(79,91,96);local paper=C(213,205,181);local ink=C(43,56,63)
local function selected(m,name)
 local out={};for _,p in m:GetDescendants() do if p.Name==name then table.insert(out,p) end end;return out
end
local function coating(api,g,m)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 and (p.Name:find("Housing") or p.Name:find("Cabinet") or p.Name:find("CartBody") or p.Name:find("BenchLeg") or p.Name:find("Backplate")) then
  api.set(g,p,"Color",steel);api.set(g,p,"Material",Enum.Material.Metal);api.set(g,p,"Reflectance",0)
 end end
end
local function jobCard(api,g,position,title)
 local p=api.part(g,"Workshop_Job_Folio",V(1.8,.055,2.4),CFrame.new(position),paper)
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Top;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=70;gui.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(.9,.9);t.Position=UDim2.fromScale(.05,.05);t.BackgroundTransparency=1;t.Text=title.."\nJOB RECORD\nCHECK / SIGN / FILE";t.Font=Enum.Font.Gotham;t.TextColor3=ink;t.TextScaled=true;t.Parent=gui
 api.part(g,"Folio_Binding",V(.13,.08,2.4),p.CFrame*CFrame.new(-.84,.015,0),ink)
end
function I.Build(api,f)
 -- A: complete working production. Preserve specialist silhouettes and all bays.
 local specs={
  {"Wash_Control","03_Remaining_Production/01_Wash/Reclaim_Filtration_And_Pump_Skid","Maintained reclaim system with practical coated pump enclosures; drainage, dosing and both cells persist."},
  {"Mechanical_Diagnostics","01_Gold_Slices/Mechanical/Diagnostic_Trolley","Rugged handheld scan unit on the existing service trolley replaces the Institution trace monitor."},
  {"Body_Workshop","03_Remaining_Production/02_Body/MIG_Welding_And_Gas_Trolley","Recognizable workshop welding equipment; frame cells, extraction, forming tools and sorted panels persist."},
  {"Tune_Calibration","03_Remaining_Production/03_Tune/ECU_And_Sensor_Calibration_Bench","General workshop electronics bench; retain real ECU, leads, supply and scope."},
  {"Paint_Standard_Finishes","01_Gold_Slices/Paint_Exterior/Mix_Bank_And_Rare_Finishes","Standard factory-style finish range precedes bespoke Institution rare finishes; complete mix bank persists."},
  {"Detail_Release","03_Remaining_Production/04_Detail/Finish_Measurement_And_Release_Desk","Physical sign-off board precedes digital release presentation; thickness/finish tools persist."},
  {"Photo_Listing","03_Remaining_Production/05_Photo/Provenance_Capture_And_Build_Record","Working listing documentation precedes curated institutional provenance; studio and capture equipment persist."},
 }
 for _,d in specs do
  local m=api.resolve(d[2]);local g=api.group(d[1],m:GetAttribute("BundleId") or d[2],d[3]);coating(api,g,m)
  if d[1]=="Wash_Control" then
   for _,p in m:GetDescendants() do
    if p:IsA("BasePart") and (p.Name:find("ReclaimVessel") or p.Name=="TankAccessLid") then api.set(g,p,"Color",C(130,143,144));api.set(g,p,"Material",Enum.Material.Metal)
    elseif p:IsA("BasePart") and (p.Name=="RibbedPumpMotor" or p.Name=="CouplingGuard") then api.set(g,p,"Color",C(63,91,113)) end
   end
  elseif d[1]=="Body_Workshop" then
   for _,p in m:GetDescendants() do
    if p:IsA("BasePart") and (p.Name=="WeldingPowerSupply" or p.Name=="WelderTrolley") then api.set(g,p,"Color",C(113,125,124))
    elseif p:IsA("BasePart") and p.Name=="RecessedControlFace" then api.set(g,p,"Color",C(194,191,174))
    elseif p:IsA("BasePart") and p.Name=="CurrentReadout" then api.set(g,p,"Color",C(118,145,120)) end
   end
  elseif d[1]=="Mechanical_Diagnostics" then
   local base=assert(m:FindFirstChild("LaptopBase",true))
   for _,p in m:GetDescendants() do if p.Name=="LaptopBase" or p.Name=="MonitorHousing" or p.Name=="MonitorGlass" or p.Name=="DiagnosticTrace" then api.hide(g,p) end end
   local cf=CFrame.new(base.Position+V(.3,.35,0))*CFrame.Angles(0,math.pi/2,0)
   api.part(g,"Rugged_OBD_Reader",V(1.65,.55,2.4),cf,ink)
   api.part(g,"Rubber_Protective_Boot",V(1.85,.22,2.6),cf*CFrame.new(0,-.25,0),C(57,66,64))
   local screen=api.part(g,"OBD_LCD",V(1.25,.025,1.0),cf*CFrame.new(0,.287,-.42),C(133,152,117))
   for x=-1,1 do for z=0,1 do api.part(g,"Membrane_Key",V(.28,.08,.26),cf*CFrame.new(x*.43,.31,.35+z*.4),C(158,162,147)) end end
   api.part(g,"Reader_Cable_Plug",V(.28,.22,.48),cf*CFrame.new(0,0,-1.42),C(30,32,33))
  elseif d[1]=="Paint_Standard_Finishes" then
   local swatches=selected(m,"CurvedFinishSample");table.sort(swatches,function(a,b)return a.Position.Z<b.Position.Z end)
   local colors={C(211,210,199),C(119,127,132),C(46,49,52),C(124,43,34),C(41,72,95),C(163,153,128)}
   for i,p in swatches do api.set(g,p,"Color",colors[(i-1)%#colors+1]);api.set(g,p,"Reflectance",0) end
  elseif d[1]=="Detail_Release" then
   local board=m:FindFirstChild("ReleaseScreen",true)
   api.set(g,board,"Color",paper)
   for _,p in selected(m,"QCRecordLine") do api.set(g,p,"Color",ink) end
   api.set(g,m:FindFirstChild("ReleaseTablet",true),"Color",C(105,84,62))
  end
 end
 -- B: broad but bounded architectural finish lineage. Materials differ, positions don't.
 local finishScopes={
  {"Production_Architecture","13_DistrictFinish02","Practical coated-metal fascias precede crafted timber edging; retain lighting and departmental identity."},
  {"Customer_Frontage","11_Frontage04/01_Architecture","Complete customer-facing frontage in painted metal and plaster; mature brass/timber finish is reserved for Institution."},
  {"Rear_Campus","09_Campus03","Maintained concrete courts and practical pergolas; keep all planting, seating, logistics and shade."},
  {"Collector_Gallery","05_Prestige_And_Public_Realm/01_Collector/Craft_Gallery_Shell","Finished working gallery on the same structure; concrete and powder-coated frames precede the limestone presentation."},
  {"HQ_Envelope","05_Prestige_And_Public_Realm/03_HQ_Art/HQ_Framed_And_Shaded_Facade","Occupied management building with the fixed crown and access; simpler coated architectural finish."},
 }
 for _,d in finishScopes do
  local m=api.resolve(d[2]);local g=api.group(d[1],d[2],d[3])
  for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
   local n=p.Name:lower()
   if (p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks) and (n:find("fascia") or n:find("slat") or n:find("trim") or n:find("screen") or n:find("beam")) then
    api.set(g,p,"Material",Enum.Material.Metal);api.set(g,p,"Color",steel);api.set(g,p,"Reflectance",0)
   elseif p.Material==Enum.Material.Limestone and not n:find("rock") and not n:find("boulder") then
    api.set(g,p,"Material",Enum.Material.Concrete);api.set(g,p,"Color",C(159,160,149));api.set(g,p,"Reflectance",0)
   elseif (n:find("brass") or n:find("bronze") or n:find("gold")) then
    api.set(g,p,"Material",Enum.Material.Metal);api.set(g,p,"Color",C(121,130,132));api.set(g,p,"Reflectance",0)
   end
  end end
 end
 -- C: replace meaningful prestige scenes, not arbitrary clutter.
 local room=api.resolve("05_Prestige_And_Public_Realm/03_HQ_Art/Crown_Project_Room")
 local office=api.group("Project_Office",room:GetAttribute("BundleId"),"Practical design/project office precedes the executive material-review room. Floor, access, chairs and table persist.")
 local tableTop=assert(room:FindFirstChild("MeetingSlab",true))
 api.set(office,tableTop,"Material",Enum.Material.SmoothPlastic);api.set(office,tableTop,"Color",C(155,151,133))
 for _,p in room:GetDescendants() do
  if p.Name=="ProjectPortfolio" or p.Name=="SamplePage" then api.hide(office,p)
  elseif p.Name=="MeetingChairCushion" or p.Name=="MeetingChairBack" then api.set(office,p,"Color",C(81,95,96)) end
 end
 local y=tableTop.Position.Y+tableTop.Size.Y/2
 local sheet=api.part(office,"Vehicle_Design_Plan",V(6,.04,3.8),CFrame.new(tableTop.Position.X,y+.035,tableTop.Position.Z),C(170,192,193))
 for x=-1,1 do
  api.part(office,"Plan_Chassis_Rail",V(.065,.016,2.5),sheet.CFrame*CFrame.new(x*.7,.031,0),ink)
  for z=-1,1 do api.part(office,"Plan_Wheel",V(.5,.018,.65),sheet.CFrame*CFrame.new(x*1.05,.033,z*.9),ink) end
 end
 api.part(office,"Plan_Centreline",V(.025,.014,3.3),sheet.CFrame*CFrame.new(0,.04,0),C(241,235,206))
 jobCard(api,office,V(tableTop.Position.X+4,y+.04,tableTop.Position.Z),"BUILD ESTIMATE")
 for i=1,3 do api.part(office,"Rolled_Drawings",V(.32,.32,2.7),CFrame.new(tableTop.Position.X-4+i*.38,y+.18,tableTop.Position.Z),paper,Enum.Material.SmoothPlastic).Shape=Enum.PartType.Cylinder end
 local sculpture=api.resolve("05_Prestige_And_Public_Realm/04_Estate_Identity/Rough_To_Remarkable_Sculpture")
 local court=api.group("Craft_Court_Identity",sculpture:GetAttribute("BundleId"),"A modest removable shop-identity sign uses the reserved monument plinth; Institution adds its transformation sculpture.")
 for _,p in sculpture:GetDescendants() do
  if p:IsA("BasePart") and p.Name~="RetainedSocketPlinth" and p.Name~="PlinthCap" then api.hide(court,p)
  elseif p:IsA("SurfaceGui") then api.hide(court,p) end
 end
 local plinth=sculpture:FindFirstChild("RetainedSocketPlinth",true)
 api.set(court,plinth,"Material",Enum.Material.Concrete);api.set(court,plinth,"Color",C(151,153,142))
 local cf=CFrame.new(plinth.Position+V(0,3.05,0))
 local sign=api.part(court,"Workshop_Identity_Sign",V(5.2,4,.35),cf,steel,Enum.Material.Metal)
 api.label(sign,"DESERT CUSTOMS\nCUSTOM WORKSHOP")
 for _,x in {-2.1,2.1} do api.part(court,"Removable_Sign_Bracket",V(.22,1.6,.6),cf*CFrame.new(x,-2.3,0),ink,Enum.Material.Metal) end
 -- D: preserve personal/rear functions with explicitly different everyday finishes.
 local rear={
  {"Owner_Workshop","04_Frontage_And_Owner/03_Owner"},
  {"Parts_Receiving","02_Rear_Support/Parts_Logistics"},
  {"Staff_Operations","02_Rear_Support/Staff_Operations"},
  {"Client_Hospitality","11_Frontage04/03_Hospitality_And_Receiving"},
 }
 for _,d in rear do
  local m=api.resolve(d[2]);local g=api.group(d[1],d[2],"Complete operational scene retained, using practical workshop/customer furnishings before the Institution finish.")
  for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
   local n=p.Name:lower()
   if (p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks) and (n:find("worktop") or n:find("counter") or n:find("shelf") or n:find("desk")) then
    api.set(g,p,"Material",Enum.Material.SmoothPlastic);api.set(g,p,"Color",C(144,143,125))
   elseif p.Material==Enum.Material.Fabric and (n:find("cushion") or n:find("seat") or n:find("back")) then api.set(g,p,"Color",C(91,112,115)) end
  end end
 end
 local identity=api.group("Chapter_Identity","Institution.HQ.CrownBlade + explicit chapter captions","Retain the fixed crown silhouette with a painted workshop marker; reserve the gold institutional finish and wording.")
 local crown=f.Parent["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]["07_Institution_Headquarters"].CrownBlade
 api.set(identity,crown,"Color",steel);api.set(identity,crown,"Material",Enum.Material.Metal)
 for _,v in f:GetDescendants() do if v:IsA("TextLabel") and v.Text:find("INSTITUTION",1,true) then api.set(identity,v,"Text",(v.Text:gsub("INSTITUTION","PROFESSIONAL"))) end end
 -- Perennial planting and all furniture persist. Only the late seasonal flowering
 -- garnish steps back, preserving substantial landscape volume.
 local seasonal=api.group("Perennial_Landscape","14_AtmosphereCraft03/B_Lived_In_Craft","Maintained perennial desert gardens precede the Institution seasonal seedhead accents.")
 local atmosphere=f:FindFirstChild("14_AtmosphereCraft03")
 if atmosphere then for _,m in atmosphere:GetDescendants() do if m:IsA("Model") and m.Name:find("Seasonal_Seedheads") then for _,p in m:GetDescendants() do api.hide(seasonal,p) end end end end
end
return I

