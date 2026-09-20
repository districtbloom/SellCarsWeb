-- ACA02: an owner-built reference, preserving existing furniture and purchase IDs.
local M={Version='2026-09-09.ACA02',RootName='ACA_ArtCulture'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local palette={steel=C(104,120,117),silver=C(192,196,176),rust=C(132,74,42),blue=C(76,105,114),teal=C(43,118,112),gold=C(189,149,68),black=C(30,35,32),cream=C(219,203,163),wood=C(111,75,48),red=C(145,58,39)}
local function part(m,f,n,s,col,mat)
 local p=Instance.new('Part');p.Name=n;p.CFrame=f;p.Size=s;p.Color=palette[col]or col;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=math.min(s.X,s.Y,s.Z)>.15;p.Parent=m;return p
end
local function tube(m,n,a,b,d,col)
 local p=part(m,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),n,V((b-a).Magnitude,d,d),col);p.Shape=Enum.PartType.Cylinder;return p
end
local function disc(m,f,n,d,depth,col)
 local p=part(m,f*CFrame.Angles(0,math.pi/2,0),n,V(depth,d,d),col);p.Shape=Enum.PartType.Cylinder;return p
end
local function save(rec,p,k,value)
 local q=Instance.new('ObjectValue');q.Name=string.format('%04d',#rec:GetChildren()+1);q.Value=p;q:SetAttribute('Key',k);q:SetAttribute('HadValue',p:GetAttribute(k)~=nil);q:SetAttribute('Before',p:GetAttribute(k));q.Parent=rec;p:SetAttribute(k,value)
end
local function retire(rec,m,n,filter)for _,p in m:GetDescendants()do if p:IsA('BasePart')and(not filter or filter(p))then save(rec,p,'FJ_Retire',n)end end end
function M.Build(root,reg,ids,rec)
 assert(not root:FindFirstChild(M.RootName),'ACA reference already built')
 local owner=Instance.new('Model');owner.Name=M.RootName;owner.Parent=root;owner:SetAttribute('Version',M.Version)
 ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries
 local manifest={}
 local function group(name,n,support,fn)
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);m.Parent=owner;m:SetAttribute('FirstStep',n);m:SetAttribute('PurchaseId',ids[n].id);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY')
  local link=Instance.new('ObjectValue');link.Name='ExistingScene';link.Value=support;link.Parent=m
  fn(m);local count=0
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=n,finish=n,kind='extra'});local names={};local q=p;while q~=root do table.insert(names,1,q.Name);q=q.Parent end;p:SetAttribute('FJ_Path',table.concat(names,'/'));count+=1 end end
  local f,s=m:GetBoundingBox();m.WorldPivot=f;m:SetAttribute('ReplacementPivot',f);m:SetAttribute('ReplacementBounds',s)
  table.insert(manifest,{name=m.Name,step=n,id=ids[n].id,parts=count,pivot={f:GetComponents()},bounds={s.X,s.Y,s.Z},source=support:GetFullName()})
 end
 local cactus=root.ST_Character.P228_Yard_Exhaust_Cactus;retire(rec,cactus,228)
 group('Welded_Exhaust_Garden',228,cactus,function(m)
  local f=cactus:GetAttribute('ReplacementPivot')
  disc(m,f*CF(0,.16,0)*CFrame.Angles(math.pi/2,0,0),'SalvagedBrakeRotorFoot',3,.3,'rust')
  for i=0,5 do local a=i*math.pi/3;disc(m,f*CF(math.cos(a)*1.12,.34,math.sin(a)*1.12)*CFrame.Angles(math.pi/2,0,0),'AnchorNut',.15,.1,'silver')end
  local function path(points,d,col)
   for i=1,#points-1 do tube(m,'SweptExhaustTube',f:PointToWorldSpace(points[i]),f:PointToWorldSpace(points[i+1]),d,col)end
   for _,i in {2,#points-1}do if points[i+1]then
    local mid=points[i];local dir=(points[i+1]-mid).Unit
    tube(m,'HeatTintedWeldCollar',f:PointToWorldSpace(mid-dir*.055),f:PointToWorldSpace(mid+dir*.055),d+.06,'blue')
    tube(m,'WeldBead',f:PointToWorldSpace(mid-dir*.012),f:PointToWorldSpace(mid+dir*.012),d+.082,'gold')
   end end
   local endp=points[#points];local dir=(endp-points[#points-1]).Unit
   tube(m,'PolishedOutletLip',f:PointToWorldSpace(endp-dir*.14),f:PointToWorldSpace(endp),d+.065,'silver')
   tube(m,'DarkPipeBore',f:PointToWorldSpace(endp+dir*.008),f:PointToWorldSpace(endp+dir*.015),d*.76,'black')
  end
  path({V(0,.32,0),V(0,3.8,0),V(.13,6.2,0),V(.13,9.9,0)},.56,'silver')
  for _,a in {{-1,4.1,7.9,.44,'steel'},{1,5.3,9.1,.38,'silver'}}do
   local side,y,high,d,col=table.unpack(a);local pts={V(0,y,0),V(side*1.35,y,0)}
   for i=1,8 do local angle=-math.pi/2+i*math.pi/16;table.insert(pts,V(side*(1.35+.65*math.cos(angle)),y+.65+.65*math.sin(angle),0))end
   table.insert(pts,V(side*2,high,0));path(pts,d,col)
  end
  path({V(0,2.8,0),V(-.8,2.8,.6),V(-1,3.15,.65),V(-1,4.3,.65)},.26,'rust')
  part(m,f*CF(0,1.2,0),'RetainedClampBracket',V(.8,.24,.72),'steel')
  for _,x in {- .37,.37}do disc(m,f*CF(x,1.2,-.4),'BracketBolt',.13,.07,'gold')end
 end)
 local stereo=root.ST_Character.P063_Fridge_And_Analog_Radio
 retire(rec,stereo,185,function(p)return p.Name=='SpeakerCone'or p.Name=='SpeakerTrim'end)
 group('Handbuilt_Listening_Cabinet',185,stereo,function(m)
  -- The inherited cabinet moves at120; these later additions use its mature transform.
  local f=stereo:GetAttribute('ReplacementPivot')+V(0,0,34)
  for _,y in {1,2.5}do
   for i=0,5 do disc(m,f*CF(4.1,y,-.94-i*.035),'RecessedSpeakerCone',1.22-i*.14,.07,i<2 and'black'or'steel')end
   disc(m,f*CF(4.1,y,-1.17),'SpeakerDustCap',.3,.09,'black')
   for _,x in {- .6,.6}do for _,dy in {- .6,.6}do disc(m,f*CF(4.1+x,y+dy,-1.02),'DriverFixing',.07,.04,'gold')end end
  end
  for _,x in {2.68,5.52}do part(m,f*CF(x,1.8,-.91),'RecoveredSpeakerEdge',V(.12,3.5,.16),'rust')end
  for i=1,5 do disc(m,f*CF(3+i*.37,3.8,-1.02),'AmplifierKnob',.11,.07,'silver')end
  for i=0,10 do local a=i*.5;local b=(i+1)*.5;tube(m,'RepairedAudioCable',f:PointToWorldSpace(V(5.72,1.8+.6*math.sin(a),.7+.25*math.cos(a))),f:PointToWorldSpace(V(5.72,1.8+.6*math.sin(b),.7+.25*math.cos(b))),.045,'black')end
  local c=f*CF(7,.05,-.05)
  part(m,c*CF(0,.08,0),'RecordCrateBottom',V(2.1,.16,1.8),'wood',Enum.Material.Wood)
  for _,z in {-.85,.85}do for i=1,3 do part(m,c*CF(0,.15+i*.32,z),'CrateSlat',V(2.1,.24,.1),'wood',Enum.Material.Wood)end end
  for _,x in {-1,1}do part(m,c*CF(x,.65,0),'CrateEnd',V(.1,1.3,1.8),'wood',Enum.Material.Wood)end
  for i=1,6 do local cover=c*CF(0,1.03,-.64+i*.2)*CFrame.Angles(.12,0,0);part(m,cover,'OriginalRecordSleeve',V(1.6,1.6,.08),({'teal','gold','rust'})[i%3+1]);disc(m,cover*CF(0,.05,-.055),'AbstractSleeveDisc',.8,.02,'cream');part(m,cover*CF(.3,-.4,-.07),'AbstractSleeveSlash',V(.5,.06,.015),'black')end
 end)
 local tableScene=root.ST_Character.P228_Engine_Block_Design_Table
 retire(rec,tableScene,228,function(p)return p.Name=='DrawingMat'or p.Name=='PinnedBlueprint'end)
 group('Dominoes_And_Workday_Rituals',228,tableScene,function(m)
  local f=tableScene:GetAttribute('ReplacementPivot');local top=f*CF(0,3.53,0)
  part(m,top,'FadedDominoMat',V(4,.025,2.4),'teal',Enum.Material.Fabric)
  for i=1,7 do local t=top*CF(-1.65+(i-1)*.5,.07,(i%3-1)*.42)*CFrame.Angles(0,i*.16,0);part(m,t,'IvoryDomino',V(.38,.1,.64),'cream');part(m,t*CF(0,.055,0),'DominoDivider',V(.3,.012,.015),'black');for j=1,i%4+1 do disc(m,t*CF((j%2-.5)*.16,.063,j<3 and-.18 or .18)*CFrame.Angles(math.pi/2,0,0),'DominoPip',.047,.009,'black')end end
  local c=CF(3186,1.8,155.2)
  part(m,c*CF(0,.65,0),'RepairedCoolerBody',V(2.5,1.3,1.6),'teal');part(m,c*CF(0,1.36,0),'CreamCoolerLid',V(2.6,.16,1.7),'cream')
  for _,x in {- .8,.8}do part(m,c*CF(x,.95,-.84),'CoolerLatch',V(.16,.4,.08),'silver')end
  for _,x in {-1.33,1.33}do part(m,c*CF(x,.83,0),'CoolerHandle',V(.12,.15,.8),'black')end
  part(m,c*CF(.65,1.46,0),'RepairedLidPatch',V(.5,.025,1.4),'rust')
  local seat=root.ST_Character.P228_Tailgate_Social_Club.TruckBedSeat_2.CFrame
  local jacket=seat*CF(2.35,.25,0)
  part(m,jacket,'FoldedCanvasJacket',V(1.3,.2,1.3),'blue',Enum.Material.Fabric)
  for _,side in {-1,1}do part(m,jacket*CF(side*.63,-.07,.28)*CFrame.Angles(0,side*.3,0),'FoldedSleeve',V(.45,.18,1.15),'blue',Enum.Material.Fabric)end
  part(m,jacket*CF(0,.11,-.4),'JacketCollar',V(.5,.08,.22),'cream',Enum.Material.Fabric)
  for _,x in {3170.5,3171.15}do part(m,CF(x,2,155.4),'ScuffedWorkBootToe',V(.48,.36,.9),'rust');part(m,CF(x,2.34,155.65),'WorkBootUpper',V(.45,.65,.46),'wood')end
  disc(m,top*CF(1.45,.48,.8)*CFrame.Angles(math.pi/2,0,0),'SteelThermos',.32,.85,'silver');disc(m,top*CF(1.45,.92,.8)*CFrame.Angles(math.pi/2,0,0),'ThermosLid',.34,.09,'black')
 end)
 owner:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return manifest
end
return M

