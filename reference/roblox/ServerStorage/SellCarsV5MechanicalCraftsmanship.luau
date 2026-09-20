-- CC01: a fitted Mechanical reference; native modelling handoff, not live machinery.
local M={Version='2026-09-09.CC01',RootName='CC01_MechanicalCraftsmanship'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local P={iron=C(73,81,79),steel=C(148,158,154),silver=C(194,200,185),black=C(29,35,34),oxide=C(145,65,39),gold=C(169,133,66),stone=C(171,161,139),cream=C(218,208,181),blue=C(73,103,112)}
local function part(m,n,f,s,c,mat)
 local p=Instance.new('Part');p.Name=n;p.Size=s;p.CFrame=f;p.Color=P[c]or c;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(s.X,s.Y,s.Z)>.12;p.Parent=m;return p
end
local function rod(m,n,a,b,d,c)
 local p=part(m,n,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),V((b-a).Magnitude,d,d),c);p.Shape=Enum.PartType.Cylinder;return p
end
local function disc(m,n,f,d,h,c)
 local p=part(m,n,f*CFrame.Angles(0,math.pi/2,0),V(h,d,d),c);p.Shape=Enum.PartType.Cylinder;return p
end
local function ring(m,n,f,r,d,c,segments)
 segments=segments or 16
 for i=0,segments-1 do local a=i*math.pi*2/segments;local b=(i+1)*math.pi*2/segments;rod(m,n,f:PointToWorldSpace(V(r*math.cos(a),r*math.sin(a),0)),f:PointToWorldSpace(V(r*math.cos(b),r*math.sin(b),0)),d,c)end
end
local function save(rec,p,k,value)
 local v=Instance.new('ObjectValue');v.Name=string.format('%04d',#rec:GetChildren()+1);v.Value=p;v:SetAttribute('Key',k);v:SetAttribute('HadValue',p:GetAttribute(k)~=nil);v:SetAttribute('Before',p:GetAttribute(k));v.Parent=rec;p:SetAttribute(k,value)
end
local function retire(rec,m,n,fn)for _,p in m:GetDescendants()do if p:IsA('BasePart')and(not fn or fn(p))then save(rec,p,'FJ_Retire',n)end end end
function M.Build(root,reg,_,rec)
 assert(not root:FindFirstChild(M.RootName),'CC01 already built')
 local owner=Instance.new('Model');owner.Name=M.RootName;owner.Parent=root;owner:SetAttribute('Version',M.Version)
 local manifest={};local ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries
 local function group(n,name,support,fn)
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',n,name);m.Parent=owner;m:SetAttribute('FirstStep',n);m:SetAttribute('PurchaseId',ids[n].id);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY')
  local link=Instance.new('ObjectValue');link.Name='ExistingSupport';link.Value=support;link.Parent=m;fn(m)
  local count=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=n,finish=n,kind='extra'});local path={};local a=p;while a~=root do table.insert(path,1,a.Name);a=a.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'));count+=1 end end
  local f,s=m:GetBoundingBox();m.WorldPivot=f;m:SetAttribute('ReplacementPivot',f);m:SetAttribute('ReplacementBounds',s)
  table.insert(manifest,{name=m.Name,step=n,id=ids[n].id,parts=count,pivot={f:GetComponents()},bounds={s.X,s.Y,s.Z},support=support:GetFullName()});return m
 end
 local gold=root['10_Institution_Fidelity_R1']['01_Gold_Slices'].Mechanical;local engine=gold.Engine_Rebuild_Stand
 local keep={StandSpine=true,StandFoot=true,Caster=true,RotatingUpright=true,RotisserieHead=true,EngineWorkside=true}
 retire(rec,engine,158,function(p)return not keep[p.Name]end)
 local base=CF(2996,6.33,200)
 group(158,'Powertrain_Teardown_Assembly',engine,function(m)
  part(m,'CastLowerCrankcase',base*CF(0,-.4,0),V(2.4,1.1,4.25),'iron')
  part(m,'SumpGasketFlange',base*CF(0,-1.03,0),V(2.7,.14,4.5),'silver')
  part(m,'PressedOilPan',base*CF(0,-1.37,0),V(2.25,.6,3.95),'black')
  for _,x in {-1.22,1.22}do for i=0,5 do disc(m,'SumpFlangeBolt',base*CF(x,-1.12,-1.9+i*.76)*CFrame.Angles(math.pi/2,0,0),.13,.11,'steel')end end
  for _,side in {-1,1}do
   local bank=base*CF(side*.77,.45,0)*CFrame.Angles(0,0,-side*.5)
   part(m,'AngledCylinderBank',bank,V(1.23,1.3,4.1),'iron')
   local face=bank*CF(0,.72,0)
   part(m,'MachinedGasketDeck',face,V(1.33,.14,4.2),'silver')
   for i=0,3 do local f=face*CF(0,.09,-1.5+i)*CFrame.Angles(math.pi/2,0,0)
    disc(m,'OpenCylinderBore',f,.89,.025,'black');ring(m,'MachinedBoreLip',f*CF(0,0,-.025),.435,.045,'steel',12)
    if side==-1 then disc(m,'RecessedPistonCrown',f*CF(0,0,.006),.58,.015,'iron')end
   end
   for _,x in {-.55,.55}do for i=0,4 do disc(m,'CylinderHeadStud',face*CF(x,.15,-1.8+i*.9)*CFrame.Angles(math.pi/2,0,0),.105,.16,'gold')end end
   if side==1 then
    part(m,'FittedCylinderHead',bank*CF(0,1.02,0),V(1.45,.5,4.35),'steel')
    part(m,'OxideCamCover',bank*CF(0,1.4,0),V(1.3,.28,4.15),'oxide')
    for j=0,3 do part(m,'CastCoverRib',bank*CF(-.45+j*.3,1.565,0),V(.06,.07,3.85),'silver')end
    disc(m,'OilFillerCap',bank*CF(0,1.62,-1.1)*CFrame.Angles(math.pi/2,0,0),.4,.12,'black')
   end
  end
  part(m,'TimingCase',base*CF(0,0,-2.2),V(2.1,1.75,.23),'steel')
  for _,x in {-.83,.83}do for _,y in {-.63,.62}do disc(m,'TimingCoverFastener',base*CF(x,y,-2.35),.13,.09,'gold')end end
  for _,spec in {{0,-.2,.77},{1.2,.82,.4},{-.95,.73,.32}}do
   local x,y,r=table.unpack(spec);local f=base*CF(x,y,-2.46);disc(m,'AccessoryPulley',f,r*2,.17,'black');ring(m,'PulleyMachinedRim',f*CF(0,0,-.11),r*.86,.05,'steel',14);disc(m,'PulleyCentreBolt',f*CF(0,0,-.15),.16,.12,'gold')
  end
  disc(m,'AlternatorBody',base*CF(1.2,.82,-1.95),.92,.73,'iron')
  for i=0,7 do local a=i*math.pi/4;rod(m,'AlternatorCoolingRib',base:PointToWorldSpace(V(1.2+.43*math.cos(a),.82+.43*math.sin(a),-2.28)),base:PointToWorldSpace(V(1.2+.43*math.cos(a),.82+.43*math.sin(a),-1.63)),.06,'silver')end
  local belt={V(-.28,-.86,-2.57),V(.58,-.74,-2.57),V(1.58,.65,-2.57),V(1.38,1.19,-2.57),V(-1.12,1.02,-2.57),V(-1.28,.64,-2.57),V(-.7,-.54,-2.57)}
  for i,a in belt do rod(m,'TensionedAccessoryBelt',base:PointToWorldSpace(a),base:PointToWorldSpace(belt[i%#belt+1]),.075,'black')end
  -- The head-off bank and retained stand identify this as a static rebuild in progress.
  part(m,'ValleyGasket',base*CF(0,.83,0),V(.46,.08,3.7),'black')
  for _,z in {-1.4,-.4,.6,1.6}do rod(m,'IntakeRunner',base:PointToWorldSpace(V(.17,1.04,z)),base:PointToWorldSpace(V(.65,1.42,z)),.25,'steel')end
 end)
 group(207,'Master_Engine_Dressing',engine,function(m)
  for i=0,3 do
   local z=-1.45+i*.95;local pts={V(1.62,.56,z),V(2,.38,z),V(2.05,-.45,z+.24),V(1.65,-.8,1.9)}
   for k=1,#pts-1 do rod(m,'FormedExhaustPrimary',base:PointToWorldSpace(pts[k]),base:PointToWorldSpace(pts[k+1]),.18,'steel')end
   local plug=base*CF(1.28,1.2,z);disc(m,'SparkPlugBoot',plug*CFrame.Angles(0,math.pi/2,0),.14,.2,'black')
   rod(m,'IgnitionLead',plug.Position,base:PointToWorldSpace(V(.35,1.95,z+.25)),.047,'blue')
  end
  disc(m,'HeaderCollectorFlange',base*CF(1.65,-.8,2.05),.5,.13,'gold')
  for i=0,4 do part(m,'RebuildStandIndexNotch',CF(2993.42,6.65,199.55+i*.22),V(.035,.18,.055),'silver')end
  rod(m,'StandLockingHandle',V(2993.15,6.38,200.5),V(2993.15,6.38,201.2),.12,'black')
 end)
 -- Replace mature caption dominance with actual part silhouettes, preserving earlier history.
 retire(rec,root.ST_Character.P083_Mechanical_Crew_Sign,157)
 retire(rec,root.ST_Character.P158_Mechanical_Craft_Obsession,207,function(p)return p.Name=='FailedBuildTag'end)
 local wall=root['05_Architecture_Massing']['02_Production'].Mechanical.OuterWall
 group(157,'Framed_Mechanical_Service_Wall',wall,function(m)
  for _,z in {174,183,194,209,224}do
   part(m,'ServiceWallUpright',CF(2983.36,8,z),V(.24,12.7,.26),'iron')
   for _,y in {2.4,13.7}do part(m,'BoltedWallConnection',CF(2983.52,y,z),V(.14,.62,.7),'steel');for _,dz in {-.22,.22}do disc(m,'WallAnchorFixing',CF(2983.63,y,z+dz)*CFrame.Angles(0,math.pi/2,0),.1,.08,'gold')end end
  end
  for _,y in {2.8,13.65}do part(m,'ContinuousFoldedServiceRail',CF(2983.35,y,199),V(.32,.22,50),'iron')end
  -- Roof-supported cable tray; no floating beam or obstructed clerestory opening.
  for _,z in {179,199,220}do rod(m,'TraySuspensionRod',V(2996,15.36,z),V(2996,13.78,z),.075,'steel')end
  for _,x in {2995.5,2996.5}do part(m,'UtilityTrayFoldedRail',CF(x,13.75,199),V(.1,.3,47),'iron')end
  for z=177,221,2 do part(m,'UtilityTrayCrossMember',CF(2996,13.65,z),V(1.05,.07,.13),'steel')end
  rod(m,'ContainedCableLoom',V(2996,13.76,176),V(2996,13.76,222),.12,'black')
 end)
 for _,reel in gold:GetChildren()do if reel.Name=='Hose_Air_Reel'then
  retire(rec,reel,157,function(p)return p.Name=='ReelSpoke'or p.Name=='ReelDisc'end)
  group(157,'Fitted_Hose_Reel_'..math.floor(reel.ReelHub.Position.Z),reel,function(m)
   local hub=reel.ReelHub.Position;local f=CF(hub)*CFrame.Angles(0,math.pi/2,0)
   for _,z in {-.36,.36}do ring(m,'RolledReelRim',f*CF(0,0,z),1.87,.12,'oxide',20)
    for i=0,5 do local a=i*math.pi/3;rod(m,'StampedRadialSpoke',f:PointToWorldSpace(V(.45*math.cos(a),.45*math.sin(a),z)),f:PointToWorldSpace(V(1.84*math.cos(a),1.84*math.sin(a),z)),.115,'iron')end
   end
   for j=0,4 do ring(m,'WoundAirHose',f*CF(0,0,-.25+j*.12),1.25,.12,'black',16)end
   disc(m,'CaptiveAxleCap',f*CF(0,0,-.49),.36,.14,'gold')
  end)
 end end
 local fluids=gold.Contained_Fluids
 retire(rec,fluids,160,function(p)return p.Name=='DrainBowl'end)
 group(160,'Contained_Fluid_Interfaces',fluids,function(m)
  for _,x in {2992.5,2996.8}do
   local f=CF(x,7.88,225)*CFrame.Angles(math.pi/2,0,0)
   disc(m,'DrainBowlBottom',f,1.8,.1,'iron');ring(m,'RolledBowlLip',f*CF(0,0,-.28),1.27,.12,'steel',20)
   for i=0,7 do disc(m,'TaperedBowlShell',CF(x,7.9+i*.038,225)*CFrame.Angles(math.pi/2,0,0),1.82+i*.088,.052,'steel')end
   disc(m,'RecessedBowlInterior',CF(x,8.182,225)*CFrame.Angles(math.pi/2,0,0),2.31,.02,'iron')
   local face=CF(x+1.33,4.9,225)*CFrame.Angles(0,-math.pi/2,0)
   disc(m,'ReceiverGaugeRim',face,.55,.12,'steel');disc(m,'ReceiverGaugeFace',face*CF(0,0,-.075),.44,.02,'cream')
   rod(m,'GaugeNeedle',face:PointToWorldSpace(V(0,0,-.095)),face:PointToWorldSpace(V(.1,.12,-.095)),.025,'black')
   rod(m,'DrainTapBody',V(x+.9,2.9,225),V(x+1.45,2.9,225),.13,'gold');part(m,'DrainTapHandle',CF(x+1.35,3.1,225),V(.18,.07,.55),'oxide')
   for _,dy in {-.95,.95}do ring(m,'ReceiverRolledBand',CF(x,4.33+dy,225)*CFrame.Angles(math.pi/2,0,0),1.32,.065,'steel',18)end
  end
 end)
 group(207,'Master_Lift_Service_Hardware',gold.Lift_1,function(m)
  for _,lift in {gold.Lift_1,gold.Lift_2}do for _,p in lift:GetChildren()do if p.Name=='ColumnChannel'then
   local x,z=p.Position.X,p.Position.Z
   for i=0,9 do part(m,'MechanicalLockRackTooth',CF(x-1.01,3.8+i*.76,z),V(.1,.11,.46),'steel')end
   part(m,'ColumnServiceAccessCover',CF(x+1.02,9.2,z),V(.1,1.35,.62),'iron')
   for _,dy in {-.52,.52}do disc(m,'AccessCoverQuarterTurn',CF(x+1.1,9.2+dy,z)*CFrame.Angles(0,math.pi/2,0),.12,.05,'gold')end
   for _,y in {4.8,8.2,11.5}do part(m,'HydraulicGuideClip',CF(x-.5,y,z-.4),V(.34,.1,.23),'steel')end
  end end end
 end)
 group(207,'Physical_Powertrain_Study',wall,function(m)
  local f=CF(2983.72,10.05,203)*CFrame.Angles(0,-math.pi/2,0)
  part(m,'ReclaimedMineralDisplayBack',f,V(10,2.85,.17),'stone',Enum.Material.Concrete)
  for _,x in {-4.6,4.6}do part(m,'FoldedDisplayEdge',f*CF(x,0,-.15),V(.1,2.7,.15),'iron')end
  -- A cutaway-like crankshaft silhouette with offset throws and rods, not another motto.
  rod(m,'SectionedCrankshaft',f:PointToWorldSpace(V(-3.8,-.35,-.48)),f:PointToWorldSpace(V(3.8,-.35,-.48)),.18,'steel')
  for i=0,3 do local x=-2.85+i*1.9
   disc(m,'CrankWeb',f*CF(x,-.35,-.52),.7,.16,'iron')
   rod(m,'ConnectingRodSection',f:PointToWorldSpace(V(x,-.12,-.68)),f:PointToWorldSpace(V(x+.3,.69,-.68)),.16,'gold')
   part(m,'SectionedPiston',f*CF(x+.3,.89,-.66),V(.72,.46,.3),'silver')
   for _,y in {.86,1.01}do part(m,'PistonRingGroove',f*CF(x+.3,y,-.83),V(.68,.04,.025),'black')end
  end
 end)
 group(207,'Mechanical_Focus_Lighting',engine,function(m)
  for _,z in {199.5,216.5}do
   local f=CF(2996,12.9,z);part(m,'FoldedTaskLuminaire',f,V(1.8,.25,4.8),'iron')
   local diffuser=part(m,'ShieldedNeutralDiffuser',f*CF(0,-.15,0),V(1.5,.035,4.3),'cream',Enum.Material.Neon)
   local light=Instance.new('SurfaceLight');light.Face=Enum.NormalId.Bottom;light.Angle=90;light.Range=13;light.Brightness=.6;light.Color=C(255,235,204);light.Shadows=true;light.Parent=diffuser
   for _,dz in {-2.2,2.2}do rod(m,'LuminaireHanger',V(2996,15.36,z+dz),V(2996,13.03,z+dz),.06,'steel')end
  end
 end)
 owner:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return manifest
end
return M

