--!nocheck
-- Additions fit existing surfaces; original equipment, exhibition cars and routes stay.
return function(K,out,f,fn,change)
 local C,V=K.C,Vector3.new
 local support=f["02_Rear_Support"]
 local prestige=f["05_Prestige_And_Public_Realm"]
 local function find(m,n)return assert(m:FindFirstChild(n,true),n)end
 local function named(m,n)local list={};for _,v in m:GetDescendants()do if v:IsA("BasePart")and v.Name==n then table.insert(list,v)end end;return list end
 local function overlay(parent,base,words,sub)
  local p=K.box(parent,base.Name.."_Print",base.CFrame*CFrame.new(0,0,-base.Size.Z/2-.026),V(base.Size.X-.08,base.Size.Y-.08,.04),C.ink,Enum.Material.SmoothPlastic)
  K.text(p,words,sub);return p
 end
 local function roofEdge(parent,roof)
  change(roof,{Color=C.charcoal,Reflectance=.02})
  local w,d=roof.Size.X,roof.Size.Z
  for _,x in {-w/2+.04,w/2-.04}do K.box(parent,"FoldedRoofEdge",roof.CFrame*CFrame.new(x,.15,0),V(.08,.6,d-.12),C.edge)end
  for _,z in {-d/2+.04,d/2-.04}do K.box(parent,"RoofEndFlash",roof.CFrame*CFrame.new(0,.15,z),V(w-.1,.6,.08),C.edge)end
 end
 if fn=="Staff_Operations"or fn=="Parts_Logistics"then
  local district=support[fn];local shell=district.Retained_Shell_And_Low_Annex
  local finish=K.group(out,"01_Wing_Envelope",fn,"Mature support-wing facade and shaded threshold")
  for _,n in {"OriginalRoof","AnnexRoof","FrontCanopy"}do roofEdge(finish,shell[n])end
  local canopy=shell.FrontCanopy;local w,d=canopy.Size.X,canopy.Size.Z
  for x=-w/2+1,w/2-1,3.4 do
   K.box(finish,"TimberSoffitBatten",canopy.CFrame*CFrame.new(x,-canopy.Size.Y/2-.07,0),V(1.8,.12,d-.35),C.wood,Enum.Material.Wood)
  end
  change(shell.CanopyFascia,{Color=C.wood,Material=Enum.Material.Wood})
  for _,n in {"RearUpperPanel","OuterUpperWall","OriginalInnerWall","AnnexRearScreen"}do change(shell[n],{Color=Color3.fromRGB(69,75,71)})end
  local board=find(district,"SmallDepartmentSign")
  overlay(finish,board,fn=="Staff_Operations"and"SERVICE OPERATIONS"or"PARTS & RECEIVING",fn=="Staff_Operations"and"PEOPLE  /  STANDARDS  /  FLOW"or"RECEIVE  /  PREPARE  /  DISPATCH")
  local story=K.group(out,"02_Working_Story",fn,"Readable work records and supported desk details")
  if fn=="Staff_Operations"then
   local dispatch=district.Dispatch_ServiceWriter_And_Radio
   local main=find(dispatch,"SuspendedDispatchBoard")
   local title=K.box(story,"DispatchBoardTitle",main.CFrame*CFrame.new(0,main.Size.Y/2+.53,0),V(main.Size.X, .85,.14),C.ink)
   K.text(title,"TODAY IN THE WORKSHOP","SERVICE COORDINATION")
   local cards=named(dispatch,"WorkCard");table.sort(cards,function(a,b)if math.abs(a.Position.Y-b.Position.Y)>.1 then return a.Position.Y>b.Position.Y end;return a.Position.X<b.Position.X end)
   local words={"RECEIVING","PARTS READY","ON THE BAY","FINAL CHECK"}
   for i,p in cards do overlay(story,p,words[(i-1)%4+1])end
   local tops=named(dispatch,"DeskTop")
   for i,p in tops do K.book(story,p.CFrame*CFrame.new(-p.Size.X/2+1.1,p.Size.Y/2+.1,.3),i==1 and C.bronze or C.ink,1.4)end
   local training=district.Training_And_Standards;local white=find(training,"TrainingWhiteboard")
   local strip=K.box(story,"TrainingBoardCaption",white.CFrame*CFrame.new(0,white.Size.Y/2-.5,-.14),V(white.Size.X-.6,.7,.08),C.ink)
   K.text(strip,"CRAFT STANDARD  /  EVERY CAR")
   local porch=K.group(out,"03_Covered_Shift_Threshold",fn,"Warm covered staff arrival")
   for _,x in {-w*.3,w*.3}do K.light(porch,canopy.CFrame*CFrame.new(x,-canopy.Size.Y/2-.26,-d/2+2),5.2)end
  else
   local kit=district.Kitting_Packing_And_Dispatch
   local top=find(kit,"Worktop")
   K.book(story,top.CFrame*CFrame.new(-top.Size.X/2+1.1,top.Size.Y/2+.1,1.1),C.bronze,1.4)
   local trays=named(kit,"OpenKitTray")
   for i,p in trays do
    local tag=K.box(story,"PreparedJobTag",p.CFrame*CFrame.new(0,.38,-p.Size.Z/2-.11),V(p.Size.X-.3,.55,.05),C.ink)
    K.text(tag,i==1 and"FILTER / FLUID SERVICE"or"READY FOR WORKSHOP")
   end
   local rare=district.Rare_Parts_Control;local header=find(rare,"CageHeader")
   local label=K.box(story,"RarePartsCaption",header.CFrame*CFrame.new(0,-.66,-.25),V(10,1,.1),C.ink);K.text(label,"RARE PARTS","CONTROLLED STORAGE")
   local stores={{"Service_Parts_Stock","SERVICE STOCK"},{"Restoration_Consumables","RESTORATION"},{"Outbound_Job_Kits","JOB KITS"}}
   for _,dta in stores do
    local rack=district[dta[1]];local cf,sz=rack:GetBoundingBox()
    -- Rack-mounted identifier; no shelf contents are moved.
    local tag=K.box(story,dta[1].."_Identity",CFrame.new(cf.Position+V(0,sz.Y/2+.45,0))*cf.Rotation,V(4,.65,.10),C.ink)
    K.box(story,dta[1].."_LabelMount",CFrame.new(cf.Position+V(0,sz.Y/2+.15,0))*cf.Rotation,V(.18,.5,.14),C.edge)
    K.text(tag,dta[2])
   end
   local threshold=K.group(out,"03_Receiving_Threshold",fn,"Covered handling station, no freight-lane clutter")
   for _,x in {-w*.3,w*.3}do K.light(threshold,canopy.CFrame*CFrame.new(x,-canopy.Size.Y/2-.26,-d/2+2),5.2)end
  end
 elseif fn=="Collector_Hall"then
  local district=prestige["01_Collector"];local shell=district.Craft_Gallery_Shell
  local finish=K.group(out,"01_Gallery_Envelope",fn,"Quiet institutional gallery edge")
  for _,roof in named(shell,"RetainedSplitRoof")do roofEdge(finish,roof)end
  -- The large gold-marble structural underside is the actual plaza ceiling.
  -- Keep its physics and upper gallery finish; dress its underside as a ceiling.
  local massing=f.Parent["05_Architecture_Massing"]["03_Rear_Campus"].Elevated_Collector_Hall
  local deck=massing.CollectorFloor
  change(deck,{Color=C.stone,Material=Enum.Material.Limestone,Reflectance=0})
  local ceiling=K.group(out,"03_Covered_Craft_Plaza",fn,"Framed gallery underside and warm public threshold")
  local w,d=deck.Size.X,deck.Size.Z;local y=-deck.Size.Y/2
  for ix=1,4 do for iz=1,4 do
   local x=-w/2+(ix-.5)*w/4;local z=-d/2+(iz-.5)*d/4
   K.box(ceiling,"AcousticCeilingPanel",deck.CFrame*CFrame.new(x,y-.025,z),V(w/4-.42,.05,d/4-.42),Color3.fromRGB(182,171,148),Enum.Material.Plaster)
  end end
  for ix=0,4 do K.box(ceiling,"CeilingTimberRib",deck.CFrame*CFrame.new(-w/2+ix*w/4,y-.11,0),V(.3,.18,d),C.wood,Enum.Material.Wood)end
  for iz=0,4 do K.box(ceiling,"CeilingCrossBatten",deck.CFrame*CFrame.new(0,y-.11,-d/2+iz*d/4),V(w,.18,.3),C.wood,Enum.Material.Wood)end
  for _,x in {-w*.3,w*.3}do for _,z in {-d*.28,d*.28}do K.light(ceiling,deck.CFrame*CFrame.new(x,y-.26,z),4.8,24)end end
  -- Break the unmodulated fascia with fitted stone/bronze end pieces, not a larger sign.
  local fascia=shell.GalleryFascia;change(fascia,{Color=C.charcoal})
  for _,x in {-fascia.Size.X/2+.7,fascia.Size.X/2-.7}do
   K.box(finish,"GalleryFasciaEnd",fascia.CFrame*CFrame.new(x,0,-.19),V(.3,fascia.Size.Y-.2,.15),C.bronze)
  end
  local records=K.group(out,"02_Curated_Records",fn,"Craft themes and preservation work, static environmental content")
  local captions={"ENGINE CRAFT","BODY RESTORATION","FINISH & COLOUR","RUNNING GEAR","LIGHT & FORM","DETAIL & PRESENTATION"}
  for i=1,6 do
   local e=district["Legacy_Exhibit_"..i];local lect=find(e,"ProvenanceLectern")
   local plate=K.box(records,"ArchiveIndex_"..i,lect.CFrame*CFrame.new(0,lect.Size.Y/2+.055,-.92),V(1.8,.035,.28),C.bronze)
   K.text(plate,string.format("%02d  /  ARCHIVE",i),nil,Enum.NormalId.Top)
   plate:SetAttribute("Theme",captions[i])
  end
  for _,name in {"Craft_Specimen_Engine","Craft_Specimen_Panel","Craft_Specimen_Wheel","Craft_Specimen_Paint"}do
   local specimen=district[name];local base=find(specimen,"OakSpecimenBack")
   for _,x in {-base.Size.X/2+.04,base.Size.X/2-.04}do
    K.box(records,"SpecimenFrameUpright",base.CFrame*CFrame.new(x,0,-.12),V(.09,base.Size.Y+.12,.12),C.bronze)
   end
   K.box(records,"SpecimenFrameHead",base.CFrame*CFrame.new(0,base.Size.Y/2+.03,-.12),V(base.Size.X+.1,.1,.12),C.bronze)
  end
 elseif fn=="Headquarters"then
  local district=prestige["03_HQ_Art"]
  local finish=K.group(out,"01_Stepped_HQ_Finish",fn,"Stepped institutional facade and crafted interior lining")
  local facade=district.HQ_Framed_And_Shaded_Facade
  for _,p in named(facade,"FacadeFascia")do
   change(p,{Color=C.wood,Material=Enum.Material.Wood})
   K.box(finish,"FasciaMetalLip",p.CFrame*CFrame.new(0,p.Size.Y/2+.035,-p.Size.Z/2+.03),V(p.Size.X,.07,.12),C.edge)
  end
  local walls=district.Crown_Hospitality_And_Craft;local back=find(walls,"CraftWallBacking")
  for x=-back.Size.X/2+.5,back.Size.X/2-.5,2 do
   K.box(finish,"ArchiveWallReed",back.CFrame*CFrame.new(x,6.5,-.13),V(.15,6.4,.14),C.wood,Enum.Material.Wood)
  end
  local story=K.group(out,"02_Management_And_Craft_Records",fn,"Material consultation, production quality and project review")
  local materials=district.Consultation_Lounge_And_Materials
  local specimens=named(materials,"FinishSpecimen");table.sort(specimens,function(a,b)return a.Position.X<b.Position.X end)
  local names={"HERITAGE","BRUSHED","COLOUR","PORCELAIN","TIMBER","BRONZE","MIDNIGHT","SIGNATURE","PEARL"}
  for i,p in specimens do
   local tag=K.box(story,"MaterialCaption_"..i,p.CFrame*CFrame.new(0,-p.Size.Y/2-.34,-.13),V(p.Size.X,.48,.08),C.ink);K.text(tag,names[i])
  end
  local management=district.HQ_Analytics_And_Management;local board=find(management,"JobBoard")
  local title=K.box(story,"QualityBoardTitle",board.CFrame*CFrame.new(0,board.Size.Y/2+.62,0),V(board.Size.X, .9,.14),C.ink);K.text(title,"QUALITY  /  CAPACITY  /  REPUTATION")
  local cards=named(management,"BlankJobCard");table.sort(cards,function(a,b)if math.abs(a.Position.X-b.Position.X)>.1 then return a.Position.X<b.Position.X end;return a.Position.Y>b.Position.Y end)
  local phases={"ARRIVAL","WORKSHOP","FINISH","LISTING","HANDOVER"}
  for i,p in cards do overlay(story,p,phases[math.ceil(i/2)])end
  local crown=district.Crown_Project_Room
  local tableTop=find(crown,"MeetingSlab")
  K.book(story,tableTop.CFrame*CFrame.new(-tableTop.Size.X/2+1.5,tableTop.Size.Y/2+.12,-1.35),C.bronze,1.6)
  local reception=district.Reception_And_Records
  local top=find(reception,"ReceptionTimberTop")
  K.book(story,top.CFrame*CFrame.new(-3,top.Size.Y/2+.10,.7),C.ink,1.5)
  local header=K.box(story,"CraftArchiveTitle",back.CFrame*CFrame.new(0,5.9,-.26),V(22,1.8,.13),C.ink)
  K.text(header,"BUILT ON CRAFT","FROM THE FIRST WORKBENCH TO DESERT CUSTOMS")
 else error("Unknown rear district "..fn)end
 return K.stats(out)
end

