-- GE01 / GE03: visual-only, cars/sockets/controllers deliberately excluded.
local M={Version='GE03'}
local E=require(game.ServerStorage.SellCarsV5FullJourneyExtras)
local V=Vector3.new
local palette={earth=Color3.fromRGB(151,125,91),gravel=Color3.fromRGB(183,159,119),stone=Color3.fromRGB(187,175,151),graphite=Color3.fromRGB(49,58,61),cream=Color3.fromRGB(215,206,180),oxide=Color3.fromRGB(153,66,43),sage=Color3.fromRGB(116,122,76)}
local function part(m,n,x,y,z,w,h,d,c,mat)
 local p=E.Box(m,n,x,y,z,w,h,d,'steel',mat or Enum.Material.Metal);p.Color=palette[c]or c or palette.graphite;return p
end
local function rod(m,n,a,b,w,c)
 local p=part(m,n,0,0,0,w,w,(b-a).Magnitude,c);p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function group(root,batch,n,name,retire,reg,ids,fn)
 local folder=root:FindFirstChild(batch);if not folder then folder=Instance.new('Model');folder.Name=batch;folder.Parent=root end
 local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);assert(not folder:FindFirstChild(m.Name),'Already built');m.Parent=folder
 m:SetAttribute('GE_Batch',batch);if n>0 then m:SetAttribute('PurchaseId',ids[n])end;fn(m)
 for _,p in m:GetDescendants()do if p:IsA('BasePart')then
  reg(p,{first=n,finish=n,retire=retire or 999,kind='extra'});p:SetAttribute('GE_Batch',batch)
  local names={};local o=p;while o~=root do table.insert(names,1,o.Name);o=o.Parent end;p:SetAttribute('FJ_Path',table.concat(names,'/'))
 end end;return m
end
local function sign(m,txt,x,y,z,w)
 E.Sign(m,txt,x,y,z,w)
end
local function scrub(m,x,z,scale)
 local rock=part(m,'WeatheredLimestone',x,1.6+.35*scale,z,1.2*scale,.7*scale,.9*scale,'stone',Enum.Material.Rock);rock.Shape=Enum.PartType.Ball
 for i=1,7 do local a=i*math.pi*2/7;rod(m,'DryBunchgrass',V(x+1.6*scale,1.55,z),V(x+(1.6+math.cos(a)*.55)*scale,1.6+(.7+(i%3)*.2)*scale,z+math.sin(a)*.55*scale),.075,'sage')end
end
function M.GE01(root,reg,ids)
 local function G(n,name,retire,fn)return group(root,'GE01_Early_Property',n,name,retire,reg,ids,fn)end
 G(0,'Undeveloped_Parcel_Edges',65,function(m)
  for _,x in {2977.3,3232.5}do for i=1,7 do scrub(m,x,182+i*43, .8+(i%3)*.15)end end
 end)
 G(1,'Roadside_Workyard_Approach',34,function(m)
  part(m,'CompactedArrivalTrack',3078,1.57,34,16,.08,60,'gravel',Enum.Material.Pebble)
  for _,x in {3072.5,3083.5}do part(m,'WornWheelTrack',x,1.622,35,2,.025,54,'earth',Enum.Material.Ground)end
  part(m,'CustomerFootApproach',3065,1.6,37,4,.08,55,'stone',Enum.Material.Pebble)
  for _,z in {13,25,37,49}do part(m,'FootwayGuideStake',3062.5,2.15,z,.16,1.1,.16,'cream',Enum.Material.Wood)end
 end)
 G(6,'Handmade_Roadside_Identity',30,function(m)
  for _,x in {3055,3061}do part(m,'SignTimberUpright',x,4.2,9,.3,5.4,.3,'earth',Enum.Material.Wood)end
  part(m,'PaintedTimberSign',3058,5.8,9,7,2.5,.22,'cream',Enum.Material.Wood)
  sign(m,'SELL CARS / REPAIR & RESALE',3058,5.95,8.82,6.6)
  sign(m,'OWNER OPERATED',3058,4.9,8.82,5.9)
  rod(m,'SignDiagonalBrace',V(3055,2,9),V(3058,5.7,9),.15,'earth')
 end)
 G(20,'Open_Ended_Yard_Boundary',35,function(m)
  -- Existing side fences stay; this rear edge ends before the service-lane exit.
  for x=2984,3056,12 do part(m,'RearBoundaryPost',x,3,158,.3,3,.3,'earth',Enum.Material.Wood)end
  for _,y in {2.5,3.5}do part(m,'RearBoundaryRail',3020,y,158,72,.15,.18,'earth',Enum.Material.Wood)end
  for _,x in {2986,3008,3034}do scrub(m,x,160.5,.8)end
 end)
 G(21,'Practical_Customer_Threshold',58,function(m)
  -- Existing owner rest bench at3001/110 is retained; furnish its ground, not another bench.
  part(m,'RestCornerGravel',3001,1.84,110,11,.03,6,'gravel',Enum.Material.Pebble)
  for _,z in {107,113}do part(m,'SalvagedGroundEdging',3001,1.91,z,11,.12,.16,'earth',Enum.Material.Wood)end
  part(m,'BootScraperTray',3008,1.92,110,1.4,.2,2,'graphite')
  for i=1,5 do part(m,'ScraperBar',3007.4+i*.2,2.05,110,.07,.08,1.8,'stone')end
 end)
end
function M.GE03(root,reg,ids)
 local function G(n,name,fn)return group(root,'GE03_Mechanical_Art_Reference',n,name,999,reg,ids,fn)end
 G(157,'Professional_Service_Composition',function(m)
  -- Workside strip stops before the vehicle working floor (minX3024.5).
  part(m,'SealedServiceWalk',3008,1.88,186,26,.06,25,'stone',Enum.Material.Concrete)
  for _,x in {2995.2,3020.8}do part(m,'ServiceWalkEdge',x,1.925,186,.14,.025,25,'graphite',Enum.Material.SmoothPlastic)end
  for _,z in {175,181,187,193,198}do part(m,'ControlJoint',3008,1.923,z,25.5,.025,.055,'graphite',Enum.Material.SmoothPlastic)end
  for _,z in {176.8,198}do
   part(m,'RoofServiceRail',3008,14.96,z,48,.3,.32,'graphite')
   for _,x in {2985,3008,3031}do rod(m,'RoofHanger',V(x,15.43,z),V(x,15.06,z),.12,'stone')end
  end
  -- Local light over the tool/service strip, not global environment changes.
  for _,z in {180,194}do
   part(m,'TaskLuminaireHousing',3003,14.35,z,13,.35,1.2,'graphite')
   local lens=part(m,'DiffusedTaskLens',3003,14.14,z,12.5,.08,.8,'cream',Enum.Material.Neon)
   local light=Instance.new('SurfaceLight');light.Name='MechanicalWorksideLight';light.Face=Enum.NormalId.Bottom;light.Angle=100;light.Brightness=.65;light.Range=18;light.Color=Color3.fromRGB(255,231,201);light.Shadows=true;light.Parent=lens
   for _,x in {2997.5,3008.5}do rod(m,'LuminaireSuspension',V(x,15.4,z),V(x,14.55,z),.07,'graphite')end
  end
  -- An unobstructed vertical band above existing equipment; lettering faces inward.
  local plaque=Instance.new('Model');plaque.Name='MechanicalCraftPlaque';plaque.Parent=m
  part(plaque,'Backplate',2983.32,11.55,187,.18,2.4,17,'graphite')
  local letters=Instance.new('Model');letters.Name='Identity';letters.Parent=plaque
  sign(letters,'MECHANICAL / ENGINE & COOLING',2983.45,11.75,187,16)
  local pivot=CFrame.new(2983.45,11.75,187);letters:PivotTo(pivot*CFrame.Angles(0,-math.pi/2,0)*pivot:Inverse()*letters:GetPivot())
  part(plaque,'OxideIdentityInlay',2983.46,10.65,187,.08,.12,16.4,'oxide')
 end)
 G(207,'Institution_Craft_Finish',function(m)
  -- Fitted framing and fasteners, not a second anonymous prop kit.
  for _,z in {178.35,195.65}do
   part(m,'LiftColumnWearStrip',3042.03,7.58,z,.06,8.8,.65,'stone')
   for _,y in {3.7,7.6,11.5}do
    local bolt=part(m,'ColumnTrimFastener',3042.09,y,z,.05,.16,.16,'graphite');bolt.Shape=Enum.PartType.Cylinder
   end
  end
  for _,z in {174,182,190,198}do
   part(m,'BackwallPanelJoint',2983.21,7.1,z,.07,8.5,.06,'graphite')
   for _,y in {3.1,11.1}do local p=part(m,'PanelFixing',2983.28,y,z,.06,.13,.13,'graphite');p.Shape=Enum.PartType.Cylinder end
  end
  part(m,'WallKickPlate',2983.22,2.28,186,.13,1.2,26,'graphite')
  for i=1,5 do
   -- Small fitted index tabs on the retained diagnostic trolley drawer fronts.
   part(m,'DrawerIndexFrame',2999.5,2.88+i*.63,185.885,.72,.24,.06,'stone')
   part(m,'DrawerIndexInsert',2999.5,2.88+i*.63,185.845,.55,.14,.025,'graphite')
  end
  local plaque=Instance.new('Model');plaque.Name='CraftStandardPlate';plaque.Parent=m
  sign(plaque,'CHECK / RECORD / RELEASE',2983.5,11.55,202,10)
  local pivot=CFrame.new(2983.5,11.55,202);plaque:PivotTo(pivot*CFrame.Angles(0,-math.pi/2,0)*pivot:Inverse()*plaque:GetPivot())
 end)
end
function M.MaterialTargets(root)
 local out={}
 for _,o in root:GetDescendants()do if o:IsA('BasePart') and o:GetAttribute('FJ_First')~=nil then
  local full=o:GetFullName();local cf=o:GetAttribute('FJ_CF');local color,material
  if full:find('01_Gold_Slices.Mechanical.',1,true) and cf and cf.Z<=200 then
   local name=o.Name
   if name=='ColumnChannel'or name=='ColumnFlange'or name=='ArmParked'or name=='StandFoot'or name=='WheeledCradle'then color=palette.oxide;material='Metal'
   elseif name=='CartBody'or name:find('DrawerFace',1,true)or name=='MonitorHousing'or name=='RadiatorCore'then color=Color3.fromRGB(64,75,78);material='Metal'
   elseif name=='SealedDeck_1'then color=Color3.fromRGB(145,147,137);material='Concrete'
   elseif name=='RubberContactPad'or name=='TestHose'or name=='OBDLead'then color=Color3.fromRGB(37,40,38);material='SmoothPlastic'
   elseif name=='Worktop'then color=palette.stone;material='Metal'
   elseif name:find('DrawerPull',1,true)or name=='TelescopicExtension'or name=='HeaderTank'then color=Color3.fromRGB(181,184,171);material='Metal' end
  elseif full:find('Production_Mechanical.03_Service_Wall_Finish',1,true) and o.Size.Y>3 then color=Color3.fromRGB(199,190,166);material='Concrete' end
  if color then table.insert(out,{part=o,first=157,color=color,material=material})end
 end end;return out
end
function M.ApplyMaterials(root,save)
 for _,r in M.MaterialTargets(root)do
  for key,value in {FJ_ArtFirst=r.first,FJ_ArtColor=r.color,FJ_ArtMaterial=r.material}do
   if save then save(r.part,key)end;r.part:SetAttribute(key,value)
  end
 end
end
function M.Build(root,reg,ids)M.GE01(root,reg,ids);M.GE03(root,reg,ids);M.ApplyMaterials(root)end
return M

