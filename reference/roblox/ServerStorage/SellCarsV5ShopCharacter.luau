-- ST01–ST05. Authored, fictional shop folklore. Additive to the full journey only.
-- No cars, economy, production controller, NPC AI or third-party assets.
local M={Version='2026-09-08.ST05',RootName='ST_Character'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local E=Enum.Material
local P={ink=C(30,39,40),steel=C(111,130,130),silver=C(183,190,179),cream=C(228,212,172),rust=C(133,64,39),red=C(173,57,38),teal=C(48,126,128),gold=C(213,157,58),wood=C(132,91,52),pink=C(212,104,132),blue=C(64,91,138),rubber=C(34,32,29),paper=C(216,204,164)}
local function model(parent,n)local m=Instance.new('Model');m.Name=n;m.Parent=parent;return m end
local function part(m,cf,n,x,y,z,w,h,d,col,mat,rot)
 local p=Instance.new('Part');p.Name=n;p.Size=V(w,h,d);p.CFrame=cf*CF(x,y,z)*(rot or CFrame.identity);p.Color=P[col]or col or P.ink;p.Material=mat or E.Metal
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.max(w,h,d)>1.5 and math.min(w,h,d)>.2;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local function cyl(m,cf,n,x,y,z,length,diam,col,axis)
 local p=part(m,cf,n,x,y,z,length,diam,diam,col,E.Metal,axis=='Y'and CFrame.Angles(0,0,math.pi/2)or axis=='Z'and CFrame.Angles(0,math.pi/2,0)or CFrame.identity);p.Shape=Enum.PartType.Cylinder;return p
end
local function rod(m,cf,n,a,b,d,col)
 local p=part(m,cf,n,0,0,0,d,d,(b-a).Magnitude,col);p.CFrame=cf*CFrame.lookAt((a+b)/2,b);return p
end
local function ring(m,cf,n,x,y,z,r,d,col)
 for i=0,11 do local a=i*math.pi/6;local b=(i+1)*math.pi/6;rod(m,cf,n,V(x+r*math.cos(a),y+r*math.sin(a),z),V(x+r*math.cos(b),y+r*math.sin(b),z),d,col)end
end
local function label(p,txt,color,font)
 local g=Instance.new('SurfaceGui');g.Name='ShopLettering';g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=38;g.LightInfluence=.7;g.MaxDistance=0;g.Parent=p -- Native edit-capture camera does not update finite-distance GUI culling reliably.
 local t=Instance.new('TextLabel');t.Name='Lettering';t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.94,.88);t.Position=UDim2.fromScale(.03,.06);t.Text=txt;t.TextColor3=P[color]or P.cream;t.TextScaled=true;t.TextWrapped=true;t.Font=font or Enum.Font.GothamBold;t.Parent=g;return t
end
local function sign(m,cf,n,txt,x,y,z,w,h,col,ink,tilt)
 local p=part(m,cf,n,x,y,z,w,h,.1,col or'ink',E.Metal,CFrame.Angles(0,0,tilt or 0));label(p,txt,ink);return p
end
local function wheel(m,cf,x,y,z,r)
 cyl(m,cf,'SalvagedTyre',x,y,z,.65,r*2,'rubber','Z');ring(m,cf,'RolledRimLip',x,y,z-.39,r*.69,.1,'silver')
 for i=0,4 do local a=i*math.pi*2/5;rod(m,cf,'CastSpoke',V(x,y,z-.42),V(x+math.cos(a)*r*.62,y+math.sin(a)*r*.62,z-.42),.12,'silver')end
 cyl(m,cf,'HubNut',x,y,z-.5,.12,r*.25,'gold','Z')
end
local function scars(m,cf,x,y,z,w)
 for i=1,5 do part(m,cf,'WornPaintEdge',x-w*.45+i*w*.15,y+((i%3)-1)*.17,z,.16+(i%2)*.24,.035,.015,'rust',E.SmoothPlastic,CFrame.Angles(0,0,i*.4))end
end
local function hood(m,cf,x,y,z,col,scale)
 local s=scale or 1
 part(m,cf,'SalvagedBonnet',x,y,z,5*s,3*s,.19,col,E.Metal,CFrame.Angles(0,0,.04))
 part(m,cf,'RaisedBonnetCowl',x,y+.2*s,z-.2*s,1.1*s,2*s,.35*s,col)
 for _,side in {-1,1}do for j=1,4 do part(m,cf,'StampedVentSlot',x+side*1.4*s,y-.4*s+j*.24*s,z-.13*s,.7*s,.07*s,.04*s,'ink')end end
 for _,side in {-1,1}do rod(m,cf,'PressedBonnetRidge',V(x+side*1.65*s,y-1.35*s,z-.12),V(x+side*1.1*s,y+1.3*s,z-.12),.07,'silver')
  for j=0,2 do rod(m,cf,'HandPulledPinstripe',V(x+side*(.15+j*.15)*s,y-1.25*s,z-.15),V(x+side*(1.2+j*.1)*s,y+(.2+j*.35)*s,z-.15),.045,j==1 and'gold'or'cream')end
 end
 scars(m,cf,x,y-1.1*s,z-.14,4*s)
end
local function engine(m,cf,x,y,z,s)
 s=s or 1;local f=cf*CF(x,y,z)*CFrame.Angles(0,.1,0)
 part(m,f,'CastEngineBlock',0,0,0,3.2*s,1.5*s,2*s,'steel');part(m,f,'SumpPan',0,-.9*s,0,2.6*s,.45*s,1.6*s,'ink')
 for _,side in {-1,1}do
  part(m,f,'FinnedValveCover',side*.95*s,.85*s,0,1.2*s,.5*s,2.35*s,'red',E.Metal,CFrame.Angles(0,0,side*.25))
  for i=1,4 do part(m,f,'CoverCoolingRib',side*.95*s,1.14*s,(-1.05+i*.42)*s,1*s,.09*s,.055*s,'silver')
   rod(m,f,'HeaderPrimary',V(side*1.5*s,.1*s,(-1.1+i*.45)*s),V(side*2.1*s,-.6*s,(-.8+i*.4)*s),.2*s,'rust')end
 end
 cyl(m,f,'AirCleanerBase',0,1.28*s,0,.15*s,1.5*s,'silver','Y');cyl(m,f,'AirCleanerLid',0,1.48*s,0,.12*s,1.7*s,'gold','Y')
 cyl(m,f,'CrankPulley',0,-.1*s,-1.2*s,.2*s,1.05*s,'ink','Z');ring(m,f,'DriveBelt',0,-.02*s,-1.34*s,.52*s,.06*s,'rubber')
end
local function fan(m,cf,x,y,z)
 local f=cf*CF(x,y,z);ring(m,f,'FanGuard',0,0,0,1.5,.08,'steel');cyl(m,f,'Motor',0,0,.4,.7,.55,'ink','Z')
 for i=0,3 do local p=part(m,f,'FanBlade',0,.65,0,.45,1.3,.07,'silver');p.CFrame=f*CFrame.Angles(0,0,i*math.pi/2)*CF(0,.65,0);p:SetAttribute('ST_Motion','SPIN');p:SetAttribute('ST_MotionPivot',f);p:SetAttribute('ST_Speed',1.8)end
 for _,side in {-1,1}do rod(m,f,'GuardCross',V(side*-1.45,-1.45,0),V(side*1.45,1.45,0),.045,'steel')end
end
local function fieldBoard(m,cf,title,lines,x,y,z,w,h)
 sign(m,cf,'HandPaintedBoard',title..'\n'..table.concat(lines,'\n'),x,y,z,w,h,'ink','cream',-.025)
 for _,sx in {-1,1}do for _,sy in {-1,1}do cyl(m,cf,'BoardFixing',x+sx*(w/2-.12),y+sy*(h/2-.12),z-.08,.04,.1,'gold','Z')end end
end
local function stamp(p,n,root)
 for k,v in {FJ_First=n,FJ_Finish=n,FJ_Mid=0,FJ_Kind='extra',FJ_Retire=999,FJ_MoveAt=999,FJ_Move=V(),FJ_CF=p.CFrame,FJ_Size=p.Size,FJ_Color=p.Color,FJ_Material=p.Material.Name,FJ_Transparency=p.Transparency,FJ_Collide=false,FJ_Query=false,FJ_Touch=false}do p:SetAttribute(k,v)end
 local path={};local o=p;while o~=root do table.insert(path,1,o.Name);o=o.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'))
 for _,e in p:GetDescendants()do if e:IsA('LayerCollector')or e:IsA('Light')then e:SetAttribute('FJ_Enabled',e.Enabled)end end
end
local function saveAttr(recovery,p,key,value)
 local v=Instance.new('ObjectValue');v.Name=string.format('%04d',#recovery:GetChildren()+1);v.Value=p;v:SetAttribute('Key',key);v:SetAttribute('HadValue',p:GetAttribute(key)~=nil);v:SetAttribute('Before',p:GetAttribute(key));v.Parent=recovery;p:SetAttribute(key,value)
end
function M.Build(root,recovery)
 assert(game.RunService:IsStudio()and game.PlaceId==125334614375606,'Correct Studio only');assert(not root:FindFirstChild(M.RootName),'Story layer already exists')
 local owner=model(root,M.RootName);owner:SetAttribute('Version',M.Version);owner:SetAttribute('Source','greybox/v5/journey/ShopCharacter.lua');local ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries
 local manifest={};local function G(n,name,zone,story,cf,fn,camera,look)
  local m=model(owner,string.format('P%03d_%s',n,name));m:SetAttribute('StoryId','ST_'..name);m:SetAttribute('PurchaseId',ids[n].id);m:SetAttribute('FirstStep',n);m:SetAttribute('Department',zone);m:SetAttribute('Story',story);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY');m:SetAttribute('ReplacementPivot',cf);m:SetAttribute('SourceVersion',M.Version)
  m.WorldPivot=cf;fn(m,cf)
  local count=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then stamp(p,n,root);count+=1 end end
  local bounds,size=m:GetBoundingBox();m:SetAttribute('ReplacementBounds',size);m:SetAttribute('ReviewCamera',camera or cf:PointToWorldSpace(V(12,10,-22)));m:SetAttribute('ReviewLook',look or bounds.Position)
  table.insert(manifest,{step=n,id=ids[n].id,storyId='ST_'..name,model=m.Name,department=zone,story=story,parts=count,pivot={cf:GetComponents()},bounds={size.X,size.Y,size.Z}});return m
 end
 -- ST02: a founder's recognisable, retained possessions. These stay as the shell grows.
 G(24,'First_Handmade_Sign','Owner','The first sign survives every renovation. Success does not erase the beginning.',CF(3158,2.2,51)*CFrame.Angles(0,-math.pi/2,0),function(m,f)
  sign(m,f,'FoundingTimberSign','DESERT CUSTOMS\nONE BAY. BIG IDEAS.',0,7,0,12,3.5,'wood','cream',.035)
  for _,x in {-4.8,4.8}do rod(m,f,'WireHanger',V(x,8.7,0),V(x,10,0),.045,'steel')end
  sign(m,f,'KeepThisNote','KEEP THIS ONE',4.5,5,-.14,2.8,.7,'gold','ink',-.09);scars(m,f,0,5.8,-.07,10)
 end)
 local fridge=G(63,'Fridge_And_Analog_Radio','Owner','The battered shop fridge and homebuilt stereo were never traded in.',CF(3226,2.2,55)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  part(m,f,'FridgeBody',0,2.5,0,3.2,5,2,'cream');part(m,f,'MismatchedFreezerDoor',0,4.25,-1.04,3,.95,.12,'teal');part(m,f,'FridgeDoor',0,2,-1.05,3,3.2,.14,'cream')
  part(m,f,'SalvagedDoorHandle',-1.1,2.8,-1.25,.12,1.5,.18,'silver')
  for i,txt in {'NO BORING CARS','87','CREW FUEL','NO PARTS IN HERE'}do sign(m,f,'FridgeSticker_'..i,txt,(i%2-.5)*1.4,1.2+i*.65,-1.15,1.25,.55,i%2==0 and'red'or'ink','cream',(i-2)*.07)end
  scars(m,f,0,.8,-1.14,2.8)
  part(m,f,'HomebuiltSpeakerCabinet',4.1,1.8,0,3,3.6,1.8,'wood',E.Wood);for _,y in {1,2.5}do cyl(m,f,'SpeakerCone',4.1,y,-.95,.14,1.1,'ink','Z');ring(m,f,'SpeakerTrim',4.1,y,-1.04,.55,.045,'gold')end
  part(m,f,'TurntableCase',4.1,3.8,0,3.1,.35,1.9,'ink');local disc=cyl(m,f,'VinylRecord',4.1,4.03,0,.04,1.5,'rubber','Y');local center=CF(disc.Position);disc:SetAttribute('ST_Motion','RECORD');disc:SetAttribute('ST_MotionPivot',center);disc:SetAttribute('ST_Speed',.7)
  part(m,f,'RecordLabel',4.1,4.06,0,.5,.02,.5,'gold');rod(m,f,'ToneArm',V(5.25,4.15,.55),V(4.55,4.15,-.25),.07,'silver');sign(m,f,'MixtapeLabel','SIDE B / AFTER HOURS',4.1,3.82,-1,2.6,.25,'cream','ink')
 end)
 for _,p in fridge:GetDescendants()do if p:IsA('BasePart')then p:SetAttribute('FJ_MoveAt',120);p:SetAttribute('FJ_Move',V(0,0,34))end end
 G(185,'Unfinished_Ideas_Wall','Owner','Sketches, colour trials and a beautifully unfinished obsession, not a generic office.',CF(3227,2.2,80)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  hood(m,f,0,7,0,'teal',1.45)
  fieldBoard(m,f,'NEXT BUILD',{'LOWER. LOUDER. BETTER.','ALMOST DONE SINCE FOREVER'},-7,7,0,6,3.8)
  for i=1,3 do sign(m,f,'FoldedBuildSketch_'..i,'BUILD '..i..'\n___/____/___\nO           O',5.5+(i%2)*1.8,4.5+i*1.25,-.05,2.2,1.6,'paper','ink',i*.08)end
  fan(m,f,7,10,0)
 end)
 G(186,'Founder_Memory_Shelf','Owner','Scraps worth more to the owner than the polished trophies.',CF(3227,2.2,58)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  part(m,f,'MemoryShelf',0,8,0,11,.18,1.5,'wood',E.Wood);wheel(m,f,-3.8,9.2,-.25,.95)
  for i=1,4 do sign(m,f,'SavedRacePlate_'..i,tostring(20+i*17),-1.7+i*1.45,9.1,-.25,1.2,.85,i%2==0 and'red'or'cream',i%2==0 and'cream'or'ink',i*.025)end
  sign(m,f,'MemoryCaption','FIRST WINS. FIRST MISTAKES. SAME CREW.',0,7.25,-.2,10,.6,'ink')
 end)
 local court=root['10_Institution_Fidelity_R1']['08_Courtyard02']
 for _,name in {'03_Main_Garden_Bench','05_Coachbuilder_Review_Table','06_Design_Chair_A','07_Design_Chair_B'}do local old=assert(court:FindFirstChild(name),name);for _,p in old:GetDescendants()do if p:IsA('BasePart')then saveAttr(recovery,p,'FJ_Retire',228)end end end
 G(228,'Tailgate_Social_Club','Owner_Yard','The crew built the seating from salvaged truck parts. The hangout belongs to this shop.',CF(3177,1.65,155)*CFrame.Angles(0,math.pi,0),function(m,f)
  for i,x in {-4,4}do
   local c=i==1 and'teal'or'red';part(m,f,'TailgateBack_'..i,x,2.9,.6,7.1,2.4,.35,c)
   part(m,f,'TruckBedSeat_'..i,x,1.65,-.25,7.1,.25,2.1,'wood',E.Wood)
   for _,sx in {-2.65,2.65}do part(m,f,'AxleSeatLeg',x+sx,.8,.1,.23,1.6,.35,'ink');part(m,f,'RedTailLamp',x+sx,2.8,.37,.4,.75,.1,'red',E.Glass)end
   for k=1,5 do part(m,f,'StampedGateRib',x-3+k,2.9,.4,.08,1.7,.1,'silver')end
   sign(m,f,'TailgateBadge',i==1 and'NO BORING CARS'or'BUILT NOT BOUGHT',x,3.25,.17,4,.5,c,'cream');scars(m,f,x,2.1,.37,6)
  end
 end,V(3192,11,174),V(3176,4,151))
 G(228,'Engine_Block_Design_Table','Owner_Yard','The old motor now holds new ideas; salvaged bucket seats complete the outdoor design corner.',CF(3161,1.65,149)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  engine(m,f,0,1.6,0,.8);part(m,f,'ReclaimedDesignTop',0,3.4,0,10,.22,3.4,'wood',E.Wood)
  for _,x in {-1.2,1.2}do for _,z in {-.6,.6}do part(m,f,'EngineTableFoot',x,.45,z,.22,.9,.22,'steel');part(m,f,'TableTopStandOff',x,2.9,z,.12,.8,.12,'silver')end end
  part(m,f,'DrawingMat',0,3.55,0,4.5,.035,2.5,'teal');part(m,f,'PinnedBlueprint',-.6,3.59,0,2.8,.02,2,'paper');for i=1,3 do part(m,f,'SampleSwatch',2.5,3.59,-.7+i*.45,.8,.04,.35,({'red','cream','blue'})[i])end
  for _,x in {-3,3}do
   part(m,f,'BucketSeatBase',x,1.65,4.2,2.3,.35,2.2,'rubber',E.Fabric);part(m,f,'BucketSeatBack',x,2.65,5.15,2.3,2.5,.35,'red',E.Fabric,CFrame.Angles(-.1,0,0));part(m,f,'HeadRest',x,4.1,5.25,1.3,.6,.4,'rubber',E.Fabric)
   for _,side in {-1,1}do part(m,f,'SeatBolster',x+side*1.0,2.1,4.2,.25,.5,2.3,'ink');rod(m,f,'WeldedSeatFrame',V(x+side*.8,.1,4),V(x+side*.8,1.5,4.5),.2,'steel')end
  end
 end,V(3176,10,163),V(3161,4,149))
 G(228,'Yard_Exhaust_Cactus','Owner_Yard','A crew-made cactus welded from retired exhausts, tucked into the planted edge.',CF(3219,2.85,153),function(m,f)
  cyl(m,f,'ScrapSteelFoot',0,.2,0,.4,3,'rust','Y');rod(m,f,'ExhaustTrunk',V(0,.4,0),V(0,8,0),.48,'silver')
  for i,side in {-1,1}do rod(m,f,'ExhaustArm',V(0,3+i,0),V(side*1.8,3+i,0),.38,'steel');rod(m,f,'UpturnedTailPipe',V(side*1.8,3+i,0),V(side*1.8,6+i,0),.38,'silver');cyl(m,f,'OpenPipeEnd',side*1.8,6+i+.01,0,.02,.24,'ink','Y')end
  sign(m,f,'CactusTag','WATER WITH HORSEPOWER',0,1.3,-1.1,4,.7,'gold','ink',-.06)
 end)
 -- ST03: distinct craft evidence at the workside wall, not on car floors.
 local depts={
  {step=77,later=176,id='Wash',z=145,west=true,title='MUD CLUB',line='DIRT IN. PRIDE OUT.',color='teal'},
  {step=83,later=158,id='Mechanical',z=203,west=true,title='WARRANTY EXPIRED',line='WE LEARNED SOMETHING.',color='red'},
  {step=89,later=162,id='Body',z=284.5,west=true,title='METAL HAS MEMORY',line='SO DO WE.',color='rust'},
  {step=95,later=169,id='Tune',z=347,west=true,title='ONE MORE RUN',line='THAT WAS THE LAST RUN.',color='blue'},
  {step=101,later=172,id='Paint',z=351,west=false,title='COLOUR OUTSIDE THE LINES',line='MASK INSIDE THE BOOTH.',color='pink'},
  {step=105,later=178,id='Detail',z=279,west=false,title='THE LAST ONE PERCENT',line='YES, WE SAW THAT.',color='teal'},
  {step=109,later=181,id='Photo',z=217,west=false,title='BUILT HERE. SHOT HERE.',line='NO STOCK PHOTOS.',color='gold'},
 }
 for _,d in depts do
  local cf=CF(d.id=='Body'and 2995.05 or d.west and 2984 or 3226,1.85,d.z)*CFrame.Angles(0,d.west and -math.pi/2 or math.pi/2,0)
  local earlyZ=({Wash=133,Mechanical=187,Body=249,Tune=317,Paint=317,Detail=249,Photo=185})[d.id]
  local relocation=V(d.id=='Body'and 11.05 or 0,0,d.z-earlyZ)
  local crew=G(d.step,d.id..'_Crew_Sign',d.id,d.line,cf-relocation,function(m,f)
   sign(m,f,'HandLetteredShopMotto',d.title,0,7.6,0,12,1.8,d.color,'cream',-.018)
   sign(m,f,'CrewFootnote',d.line,0,6.2,-.04,10,.6,'ink');scars(m,f,0,7,-.08,10)
  end)
  for _,p in crew:GetDescendants()do if p:IsA('BasePart')then p:SetAttribute('FJ_MoveAt',d.later);p:SetAttribute('FJ_Move',relocation)end end
  G(d.later,d.id..'_Craft_Obsession',d.id,'Specific signs of the people and craft behind '..d.id..'.',cf,function(m,f)
   part(m,f,'HandmadeDisplayLedge',0,4.4,-.7,12,.2,1.6,'wood',E.Wood)
   if d.id=='Mechanical'then
    engine(m,f,0,5.3,-1,.65);sign(m,f,'FailedBuildTag','DO NOT FIX / IT IS A TROPHY',0,3.8,-1.5,7,.6,'gold','ink')
    for i=1,3 do cyl(m,f,'RetiredPiston',-4.5+i*.8,5.25,-.6,.45,.6,'silver','Y');rod(m,f,'BentConnectingRod',V(-4.5+i*.8,4.5,-.6),V(-4.6+i*.8,5,-.6),.12,'rust')end
   elseif d.id=='Body'then
    for i=1,4 do local q=f*CF(-5+i*2,5.3,-.5)*CFrame.Angles(0,0,(i-2)*.12);part(m,q,'HammeredPanelStudy',0,0,0,1.5,1.5,.15,i==4 and'red'or'silver');for j=1,3 do rod(m,q,'FormedCrease',V(-.6,-.6+j*.3,-.11),V(.6,-.5+j*.3,-.11),.04,'steel')end end
    hood(m,f,0,10,-.1,'rust',.75)
   elseif d.id=='Tune'then
    cyl(m,f,'FabricatedPlenum',0,5.2,-.5,5,.8,'silver','X');for i=1,4 do rod(m,f,'EqualLengthRunner',V(-2+i*.85,5.2,-.5),V(-2+i*.85,4.55,-1.4),.3,'silver')end
    fieldBoard(m,f,'PERSONAL BEST',{'NOT A LIMIT. A CHALLENGE.','RUN 07  /  KEEP THE CHART'},0,10,0,11,2.5);fan(m,f,8,9,0)
   elseif d.id=='Paint'then
    for i=1,8 do local q=f*CF(-5.5+i*1.25,5.3,-.7)*CFrame.Angles(0,0,(i-4)*.04);part(m,q,'SprayOutPanel',0,0,0,1,1.5,.06,({'red','gold','teal','pink','blue','cream','rust','silver'})[i]);part(m,q,'MaskedSampleEdge',0,-.6,-.045,.95,.18,.015,'paper')end
    hood(m,f,0,10,-.1,'pink',.82)
   elseif d.id=='Detail'then
    part(m,f,'CorrectionTrialLeft',-2,5.3,-.4,3.5,1.4,.14,'steel');part(m,f,'CorrectionTrialRight',2,5.3,-.4,3.5,1.4,.14,'teal')
    for i=1,7 do rod(m,f,'TrialScratch',V(-3.4+i*.4,4.8,-.49),V(-3+i*.4,5.75,-.49),.018,'cream')end
    sign(m,f,'FiftyFiftyLabel','BEFORE  |  AFTER',0,3.8,-1.5,8,.6,'ink');for i=1,3 do part(m,f,'FoldedMicrofibre',4.8,4.65+i*.13,-.8,1.1,.12,1,'cream',E.Fabric)end
   elseif d.id=='Photo'then
    for i=1,5 do local q=f*CF(-6+i*2,5.3,-.1)*CFrame.Angles(0,0,(i%2==0 and .04 or -.06));sign(m,q,'EditorialCover','DESERT\nCUSTOMS\nBUILD '..i,0,0,0,1.6,2.1,i%2==0 and'teal'or'rust');part(m,q,'MagazineSpine',-.76,0,.06,.07,2.1,.08,'cream')end
    fieldBoard(m,f,'TODAY IN THE STUDIO',{'LOW ANGLE / LONG SHADOW','LET THE BUILD DO THE TALKING'},0,10,0,11,2.5)
   else
    -- A tiny welded duck: wash mascot, not another anonymous chemistry box.
    local body=part(m,f,'WeldedDuckBody',-2,5.1,-.6,1.8,.95,1,'gold');body.Shape=Enum.PartType.Ball
    local head=part(m,f,'DuckHead',-1.45,5.8,-.6,.85,.85,.85,'gold');head.Shape=Enum.PartType.Ball
    part(m,f,'DuckBill',-.96,5.65,-.65,.5,.2,.4,'rust');cyl(m,f,'DuckEye',-1.4,5.95,-1.03,.06,.1,'ink','Z')
    for i=1,4 do sign(m,f,'RecoveredPlate_'..i,'TX / '..(28+i*13),1+i*1.1,5.2,-.2,.95,.55,i%2==0 and'cream'or'teal','ink',i*.035)end
    sign(m,f,'MascotTag','FOUND IN A TRADE-IN. PROMOTED.',0,3.8,-1.5,10,.6,'ink')
   end
  end)
 end
 G(214,'Paint_Pinstripe_Flagship','Paint','A giant custom-painted hood is the painter’s calling card.',CF(3226,4.35,318)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  hood(m,f,0,8,0,'red',1.7);sign(m,f,'PainterSignature','COLOUR DEPARTMENT / NO FEAR',0,4.65,-.1,11,.7,'ink')
 end)
 -- ST04: public-facing showmanship and back-of-house personality.
 G(145,'Customer_Club_Pitboard','Sales','A welcoming custom-car clubhouse, not an anonymous waiting room.',CF(3033,1.8,50)*CFrame.Angles(0,-math.pi/2,0),function(m,f)
  fieldBoard(m,f,'GOOD CARS. GOOD COMPANY.',{'COFFEE IS ON. COME TALK BUILDS.','SATURDAY / SHOP STORIES'},0,7.4,0,13,3.5)
  for _,x in {-6,6}do for i=1,4 do part(m,f,'CheckerboardTile',x,5.2+i*.45,-.09,.45,.45,.03,i%2==0 and'cream'or'ink')end end
  wheel(m,f,8.3,7.8,-.1,1.2)
 end,V(3048,9,42),V(3033,8,50))
 G(219,'Commission_Pitboard','Sales','A handwritten-style celebration of builds; no fabricated live sale or price.',CF(3087,1.8,108),function(m,f)
  fieldBoard(m,f,'NEXT LEGEND',{'YOUR BUILD. YOUR STORY.','CRAFT / COLOUR / CHARACTER'},0,3.3,0,6,4)
  for _,x in {-2.6,2.6}do part(m,f,'PitboardStand',x,1.5,.3,.18,3,.3,'steel');rod(m,f,'StandRearBrace',V(x,.1,1.5),V(x,2.4,.3),.15,'steel')end
 end)
 G(151,'Parts_Of_Unknown_Origin','Parts','A lovingly indexed collection of strange donor components. There is a system.',CF(2983,1.8,475)*CFrame.Angles(0,-math.pi/2,0),function(m,f)
  fieldBoard(m,f,'WE KNOW WHERE IT IS',{'ASK BEFORE RE-ORGANISING','RARE / WEIRD / PROBABLY USEFUL'},0,9,0,15,3)
  for _,y in {4.7,6.4}do part(m,f,'ImprovisedOdditiesShelf',0,y,-.5,14,.16,1.3,'wood',E.Wood)end
  for i=1,5 do local x=-6+i*2;wheel(m,f,x,5.4,-.5,.6);sign(m,f,'DonorInventoryTag','BIN '..(i*17)..'?',x,4.3,-1.15,1.4,.35,'gold','ink')end
  for i=1,4 do cyl(m,f,'OddCamshaft',-5+i*2.5,7,-.5,1.7,.25,'silver','X');for j=1,3 do cyl(m,f,'CamLobe',-5+i*2.5-.6+j*.3,7,-.5,.12,.5,'rust','X')end end
 end,V(3006,11,463),V(2985,8,475))
 G(202,'Long_Way_Home_Crate','Parts','Special components arrive with a history; packing is treated as part of the craft.',CF(2997,1.8,439),function(m,f)
  part(m,f,'ShippingCrate',0,1.7,0,5,3.4,3,'wood',E.Wood);for _,x in {-2,2}do part(m,f,'StrappedCrateCorner',x,1.7,-1.55,.22,3.4,.08,'steel')end
  sign(m,f,'TravelStamps','FRAGILE / NOT ORDINARY\nHANDLE LIKE IT IS YOURS',0,2,-1.57,4.1,1.3,'paper','ink',-.04)
  sign(m,f,'OldShippingLabel','LONG WAY HOME',1,.7,-1.59,2,.45,'teal','cream',.09)
 end)
 G(156,'Crew_Wall_Of_Fame','Operations','The workshop celebrates its people, not just its output.',CF(3223.2,1.8,475)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  fieldBoard(m,f,'THE CREW MADE THIS',{'TEACH THE TRICK. SHARE THE TOOLS.','LEAVE YOUR EGO AT THE GATE.'},0,9,0,15,3)
  for i=1,5 do sign(m,f,'CrewLockerPatch','CREW\n0'..i,-7+i*2.4,5.8,-.1,1.9,2.4,({'red','teal','blue','gold','rust'})[i],'cream',i*.025)end
  fan(m,f,10,9,0)
 end,V(3204,11,463),V(3225,8,475))
 G(238,'After_Hours_Club','Operations_Court','A handbuilt gathering place carries the same workshop humour into the evening.',CF(3196,1.8,417),function(m,f)
  sign(m,f,'CrewNightBanner','CLOCKED OUT. STILL HERE.',0,9.6,0,18,1.6,'red','cream',-.025)
  rod(m,f,'BannerSupport',V(-10,10,.1),V(10,10,.1),.09,'steel')
  for i=1,9 do local x=-9+i*1.8;local p=part(m,f,'CrewPennant',x,8.35,-.01,1.2,1.1,.045,i%2==0 and'gold'or'teal');p:SetAttribute('ST_Motion','SWAY');p:SetAttribute('ST_MotionPivot',p.CFrame*CF(0,.55,0));p:SetAttribute('ST_Speed',.8+i*.06)end
 end)
 G(232,'Founding_Spanner_Exhibit','Collector','A cheap first tool is honoured alongside the best builds.',CF(3064,2.23,510),function(m,f)
  part(m,f,'ToolDisplayPlinth',0,1.3,0,3,2.6,2.4,'ink');rod(m,f,'FirstSpannerHandle',V(0,2.8,0),V(0,5.5,0),.35,'steel');ring(m,f,'SpannerRing',0,5.85,0,.48,.16,'steel')
  sign(m,f,'FoundingToolLabel','THE FIRST TOOL\nEVERYTHING ELSE CAME LATER.',0,1.8,-1.24,2.8,1.1,'ink','cream')
 end)
 G(225,'Garage_Yard_Shop_Mural','Owner_Yard','A giant hand-built winged piston marks the private workshop: an emblem made out of its own craft.',CF(3178,2.2,124.65)*CFrame.Angles(0,math.pi,0),function(m,f)
  part(m,f,'PaintedShopPatch',0,7,0,23,6.8,.09,'ink')
  cyl(m,f,'PistonCrown',0,8,-1.2,2.5,2.2,'silver','X');part(m,f,'PistonSkirt',0,6.9,-.4,2.5,1.2,.4,'steel')
  ring(m,f,'ConnectingRodEye',0,4.6,-.4,.6,.17,'gold');rod(m,f,'ConnectingRodShaft',V(0,5.2,-.4),V(0,7,-.4),.32,'silver')
  for _,side in {-1,1}do for i=1,5 do rod(m,f,'FabricatedWingFeather',V(side*(1.5+i*.3),6.1+i*.28,-.3),V(side*(8.4-i*.65),9.5-i*.42,-.3),.18,i%2==0 and'gold'or'teal')end end
  sign(m,f,'AfterHoursShopSign','NEVER FINISHED. ALWAYS OURS.',0,3.2,-.14,20,1,'ink','cream')
 end,V(3196,10,144),V(3178,9,125))
 G(240,'Shop_Built_Windmill','Plaza','An unmistakable scrap-metal star: shop-made public art celebrates the craft.',CF(3091,1.8,359),function(m,f)
  cyl(m,f,'SalvageSculpturePlinth',0,.25,0,.5,3.6,'rust','Y');rod(m,f,'SculptureMast',V(0,.5,0),V(0,10,0),.42,'steel')
  for _,x in {-1.6,1.6}do rod(m,f,'TriangulatedMast',V(x,.5,.8),V(0,8,0),.2,'rust')end
  local pivot=f*CF(0,10,0);ring(m,pivot,'WheelRim',0,0,0,2.4,.14,'silver')
  for i=0,7 do local a=i*math.pi/4;local p=part(m,pivot,'SalvagedFanVane',0,1.3,0,.8,2.2,.14,i%2==0 and'teal'or'gold');p.CFrame=pivot*CFrame.Angles(0,0,a)*CF(0,1.3,0);p:SetAttribute('ST_Motion','SPIN');p:SetAttribute('ST_MotionPivot',pivot);p:SetAttribute('ST_Speed',.18)end
  cyl(m,pivot,'WheelHub',0,0,-.15,.3,.65,'rust','Z');sign(m,f,'SculpturePlaque','BUILT FROM WHAT WE KEPT',0,2,-1.4,5.5,.7,'ink')
 end,V(3118,15,346),V(3091,8,359))
 owner:SetAttribute('GroupCount',#manifest);owner:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return manifest
end
return M

