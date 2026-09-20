-- ACA03. Native art-direction models: grounded replacements, not final meshes.
local M={Version='2026-09-09.ACA03',RootName='ACA_CampusArt'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local colors={teal=C(24,139,132),orange=C(202,87,36),gold=C(191,148,65),steel=C(143,158,156),dark=C(33,40,41),cream=C(226,210,171),rust=C(119,71,45),wood=C(109,74,45),blue=C(61,89,115)}
local function box(m,n,f,s,c,mat)
 local p=Instance.new('Part');p.Name=n;p.CFrame=f;p.Size=s;p.Color=colors[c]or c;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(s.X,s.Y,s.Z)>.12;p.Parent=m;return p
end
local function rod(m,n,a,b,d,c)
 local p=box(m,n,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),V((b-a).Magnitude,d,d),c);p.Shape=Enum.PartType.Cylinder;return p
end
local function disc(m,n,f,d,h,c)
 local p=box(m,n,f*CFrame.Angles(0,math.pi/2,0),V(h,d,d),c);p.Shape=Enum.PartType.Cylinder;return p
end
local function retire(rec,model,step,filter)
 for _,p in model:GetDescendants()do if p:IsA('BasePart')and(not filter or filter(p))then
  local v=Instance.new('ObjectValue');v.Name=tostring(#rec:GetChildren()+1);v.Value=p;v:SetAttribute('Key','FJ_Retire');v:SetAttribute('HadValue',p:GetAttribute('FJ_Retire')~=nil);v:SetAttribute('Before',p:GetAttribute('FJ_Retire'));v.Parent=rec;p:SetAttribute('FJ_Retire',step)
 end end
end
function M.Build(root,reg,_,rec)
 assert(not root:FindFirstChild(M.RootName),'ACA03 already built')
 local owner=Instance.new('Model');owner.Name=M.RootName;owner.Parent=root;owner:SetAttribute('Version',M.Version)
 local ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries;local manifest={}
 local function group(n,name,support,fn)
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);m.Parent=owner;m:SetAttribute('FirstStep',n);m:SetAttribute('PurchaseId',ids[n].id);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY')
  local link=Instance.new('ObjectValue');link.Name='ExistingSupport';link.Value=support;link.Parent=m;fn(m)
  local count=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=n,finish=n,kind='extra'});local path={};local q=p;while q~=root do table.insert(path,1,q.Name);q=q.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'));count+=1 end end
  local f,s=m:GetBoundingBox();m.WorldPivot=f;m:SetAttribute('ReplacementPivot',f);m:SetAttribute('ReplacementBounds',s)
  table.insert(manifest,{name=m.Name,step=n,id=ids[n].id,parts=count,pivot={f:GetComponents()},bounds={s.X,s.Y,s.Z},support=support:GetFullName()})
 end
 local front=root['10_Institution_Fidelity_R1']['11_Frontage04'];local garden=front['05_Frontage_Landscape'].Gateway_Desert_Garden_1
 retire(rec,garden.YuccaLandmark,239)
 group(239,'Folded_Finish_Ribbon',garden,function(m)
  -- Contained within existing 5.2 x 7 planter. The second yucca remains.
  local f=CF(3086,2.35,13.9)
  box(m,'ExposedMountingShoe',f*CF(0,.14,0),V(2.1,.28,1.3),'dark')
  for _,x in {-.8,.8}do for _,z in {-.42,.42}do disc(m,'AnchorBolt',f*CF(x,.32,z)*CFrame.Angles(math.pi/2,0,0),.16,.09,'steel')end end
  local function point(t)return V(1.12*math.sin(t*math.pi*1.55),.35+t*8.1,.45*math.sin(t*math.pi*2))end
  for i=0,39 do local t=i/40;local a,b=point(t),point((i+1)/40);local frame=f*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,t*1.7)
   local p=box(m,'FoldedCoachworkRibbon',frame,V(1.45,.13,(b-a).Magnitude+.025),t<.2 and'rust'or t<.43 and'steel'or'teal',t<.2 and Enum.Material.CorrodedMetal or Enum.Material.Metal);p.Reflectance=t>.43 and .16 or .03
   box(m,'GoldenFoldEdge',frame*CF(.7,-.075,0),V(.055,.055,(b-a).Magnitude+.02),'gold')
  end
 end)
 local wind=root.ST_Character.P240_Shop_Built_Windmill
 retire(rec,wind,240,function(p)return p.Name=='SalvagedFanVane'or p.Name=='WheelHub'or p.Name=='SculpturePlaque'end)
 group(240,'Salvaged_Vane_Windmill',wind,function(m)
  local pivot=CF(3091,11.8,359)
  local function moving(p)p:SetAttribute('ST_Motion','SPIN');p:SetAttribute('ST_MotionPivot',pivot);p:SetAttribute('ST_Speed',.14);return p end
  disc(m,'BearingHousing',pivot*CF(0,0,.15),.8,.6,'dark');disc(m,'BronzeHubCap',pivot*CF(0,0,-.28),.6,.12,'gold')
  for i=0,5 do local f=pivot*CFrame.Angles(0,0,i*math.pi/3)
   moving(rod(m,'RotorSpoke',f:PointToWorldSpace(V(0,.25,0)),f:PointToWorldSpace(V(0,2.1,0)),.1,'steel'))
   local v=f*CF(.12,1.62,-.02)*CFrame.Angles(0,.2,0)
   moving(box(m,'ReclaimedLouverVane',v,V(.85,1.35,.08),({'teal','steel','orange'})[i%3+1]))
   for j=1,3 do moving(box(m,'FoldedVaneRib',v*CF(0,-.65+j*.31,-.08)*CFrame.Angles(.25,0,0),V(.76,.065,.16),'cream'))end
   moving(disc(m,'VaneRivet',v*CF(0,-.5,-.14),.1,.055,'gold'))
  end
  for _,x in {-1.1,1.1}do disc(m,'FoundationFixing',CF(3091+x,2.34,359)*CFrame.Angles(math.pi/2,0,0),.22,.1,'steel')end
  for _,y in {4.2,7.2,10.2}do box(m,'MastServiceCollar',CF(3091,y,359),V(.66,.19,.65),'rust')end
 end)
 local body=root.ST_Character.P162_Body_Craft_Obsession
 retire(rec,body,162,function(p)return p.Name=='HammeredPanelStudy'or p.Name=='FormedCrease'end)
 group(162,'Metal_Shaping_Studies',body,function(m)
  local f=body:GetAttribute('ReplacementPivot')
  for j=0,3 do local base=f*CF(-3+j*2,4.53,-.7)
   box(m,'StudyMount',base,V(1.65,.13,1.2),'dark')
   for i=0,11 do local u=i/11;local a=-.73+u*1.46;local bend=(.15+j*.17)*math.sin(u*math.pi)
    box(m,'HandFormedMetalSection',base*CF(a,.78,-bend)*CFrame.Angles(0,(u-.5)*j*.32,0),V(.14,1.35,.06),j==3 and'teal'or'steel')
   end
   for _,x in {-.66,.66}do disc(m,'StudyFastener',base*CF(x,.3,-.12),.09,.04,'gold')end
  end
 end)
 local paint=root.ST_Character.P172_Paint_Craft_Obsession
 group(172,'Pinstripe_Colour_Experiments',paint,function(m)
  local f=paint:GetAttribute('ReplacementPivot')
  for _,panel in paint:GetChildren()do if panel:IsA('BasePart')and panel.Name=='SprayOutPanel'then
   local q=panel.CFrame
   for i=0,11 do local t=i/11;local a=V(-.38+.76*t,.45*math.sin(t*math.pi*2),-.047);local t2=(i+1)/11;local b=V(-.38+.76*t2,.45*math.sin(t2*math.pi*2),-.047);rod(m,'OriginalPinstripeLoop',q:PointToWorldSpace(a),q:PointToWorldSpace(b),.025,'cream')end
  end end
  local q=f*CF(5.2,4.52,-.55);box(m,'BrushRest',q,V(.7,.08,.8),'rust')
  for i=1,3 do rod(m,'FineLiningBrush',q:PointToWorldSpace(V(-.2+i*.12,.1,-.3)),q:PointToWorldSpace(V(-.2+i*.12,.12,.25)),.04,'wood')end
 end)
 local tune=root.ST_Character.P169_Tune_Craft_Obsession
 group(169,'Experimental_Audio_Bench',tune,function(m)
  local f=tune:GetAttribute('ReplacementPivot')*CF(4.25,4.52,-.7)
  box(m,'PlywoodSubTestEnclosure',f*CF(0,.8,0),V(2.25,1.6,1.2),'wood',Enum.Material.Wood)
  for i=0,5 do disc(m,'SteppedSubwooferCone',f*CF(0,.82,-.64-i*.025),1.32-i*.17,.065,i<2 and'dark'or'steel')end
  disc(m,'ConeDustCap',f*CF(0,.82,-.82),.26,.08,'dark')
  for _,x in {-.82,.82}do for _,y in {.15,1.45}do disc(m,'TemporarySpeakerScrew',f*CF(x,y,-.65),.08,.03,'gold')end end
  box(m,'ExposedCrossoverBoard',f*CF(0,1.69,0),V(1.6,.09,.7),'teal')
  for i=1,4 do disc(m,'CopperInductorTurn',f*CF(-.45,1.8+i*.045,0)*CFrame.Angles(math.pi/2,0,0),.32,.025,'gold')end
  for _,x in {.05,.4}do box(m,'CrossoverCapacitor',f*CF(x,1.85,0),V(.18,.22,.35),'blue')end
  for i=0,7 do local a=i/7*math.pi;local b=(i+1)/7*math.pi;rod(m,'LooseTestLead',f:PointToWorldSpace(V(1+.3*math.sin(a),.3+.5*math.cos(a),-.68)),f:PointToWorldSpace(V(1+.3*math.sin(b),.3+.5*math.cos(b),-.68)),.04,'orange')end
  -- A tiny handmade sound-wave trophy, not an unearned brand award.
  local t=f*CF(-8.6,0,0);box(m,'HandmadeCompetitionBase',t*CF(0,.12,0),V(1.3,.24,.9),'wood')
  for i=1,5 do rod(m,'WaveformTrophy',t:PointToWorldSpace(V(-.6+i*.2,.24,0)),t:PointToWorldSpace(V(-.6+i*.2,.5+.8*math.sin(i/6*math.pi),0)),.1,'gold')end
 end)
 local crate=root.ST_Character.P202_Long_Way_Home_Crate
 group(202,'Saved_Donor_Find',crate,function(m)
  local f=crate:GetAttribute('ReplacementPivot');local top=f*CF(0,3.45,0)
  box(m,'ProtectiveDonorBlanket',top,V(3.6,.07,2.3),'blue',Enum.Material.Fabric)
  local q=top*CF(0,.9,0);disc(m,'SalvagedTurbineHousing',q,1.65,.95,'steel');disc(m,'CompressorOpening',q*CF(0,0,-.51),1.24,.025,'dark')
  for i=0,7 do box(m,'CompressorImpeller',q*CF(0,0,-.54)*CFrame.Angles(0,0,i*math.pi/4)*CF(0,.33,0)*CFrame.Angles(0,.25,0),V(.16,.65,.12),'gold')end
  rod(m,'DonorOutlet',q:PointToWorldSpace(V(.65,.1,.1)),q:PointToWorldSpace(V(1.35,.65,.1)),.5,'rust')
  for _,x in {-1.45,1.45}do box(m,'CrateCornerRepair',f*CF(x,2,1.52),V(.14,2.7,.09),'steel')end
  -- Hand truck is stowed against the crate's side, inside its existing edge pocket.
  local t=f*CF(2.8,0,0)*CFrame.Angles(0,math.pi/2,0)
  for _,x in {-.62,.62}do rod(m,'RepairedHandTruckFrame',t:PointToWorldSpace(V(x,.35,0)),t:PointToWorldSpace(V(x,3.5,.2)),.13,'teal');disc(m,'HandTruckWheel',t*CF(x,.43,.4)*CFrame.Angles(0,math.pi/2,0),.65,.23,'dark')end
  for _,y in {1,2,3.5}do rod(m,'HandTruckCrossbar',t:PointToWorldSpace(V(-.62,y,.15)),t:PointToWorldSpace(V(.62,y,.15)),.12,'steel')end
  box(m,'HandTruckToePlate',t*CF(0,.18,-.35),V(1.5,.12,1.1),'rust')
 end)
 local coffee=front['03_Hospitality_And_Receiving']['03_Shared_Hospitality']['05_Coffee_Hospitality']
 group(219,'Crew_Made_Hospitality',coffee,function(m)
  local worktop=coffee.StoneCoffeeWorktop;local f=CF(3037.55,worktop.Position.Y+worktop.Size.Y/2,59.75)
  -- Stacked ceramic rings suggest a thrown, imperfect jug; no fabricated cultural attribution.
  for i=0,9 do local d=.48+.34*math.sin(i/9*math.pi);disc(m,'HandThrownGlazedJug',f*CF(0,.09+i*.095,0)*CFrame.Angles(math.pi/2,0,0),d,.105,i<3 and'rust'or'teal')end
  disc(m,'OpenJugMouth',f*CF(0,1.01,0)*CFrame.Angles(math.pi/2,0,0),.32,.012,'dark')
  for i=0,7 do local a=-math.pi/2+i*math.pi/7;local b=-math.pi/2+(i+1)*math.pi/7;rod(m,'LoopedCeramicHandle',f:PointToWorldSpace(V(.3+.28*math.cos(a),.55+.3*math.sin(a),0)),f:PointToWorldSpace(V(.3+.28*math.cos(b),.55+.3*math.sin(b),0)),.085,'rust')end
  -- Reclaimed timber cup tree on the actual counter, with forged branch hooks.
  local t=CF(3037.85,5.04,63.05);disc(m,'CupTreeFoot',t*CFrame.Angles(math.pi/2,0,0),.8,.08,'wood')
  rod(m,'TurnedCupTreeStem',t.Position,t:PointToWorldSpace(V(0,1.6,0)),.14,'wood')
  for _,side in {-1,1}do rod(m,'ForgedCupHook',t:PointToWorldSpace(V(0,1.2,0)),t:PointToWorldSpace(V(side*.43,1.35,0)),.07,'gold');disc(m,'HandmadeCup',t*CF(side*.4,.94,0)*CFrame.Angles(math.pi/2,0,0),.36,.42,'cream')end
 end)
 owner:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return manifest
end
return M

