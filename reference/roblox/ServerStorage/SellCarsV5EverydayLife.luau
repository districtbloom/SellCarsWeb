-- EL01–EL05: scene-derived, non-gameplay occupation and fitted everyday objects.
local M={Version='2026-09-09.EL05',RootName='EL_EverydayLife'}
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local E=Enum.Material
local P={ink=C(31,39,42),steel=C(104,117,121),silver=C(185,191,184),cream=C(223,205,163),rust=C(144,76,49),red=C(168,62,43),teal=C(49,125,125),gold=C(208,155,62),wood=C(131,92,59),rubber=C(33,33,30),blue=C(63,92,132),green=C(97,116,75)}
local function model(p,n)local m=Instance.new('Model');m.Name=n;m.Parent=p;return m end
local function part(m,f,n,x,y,z,w,h,d,col,mat,rot)
 local p=Instance.new('Part');p.Name=n;p.Size=V(w,h,d);p.CFrame=f*CF(x,y,z)*(rot or CFrame.identity);p.Color=P[col]or col or P.ink;p.Material=mat or E.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(w,h,d)>.15;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
local function cyl(m,f,n,x,y,z,h,d,col,axis)
 local p=part(m,f,n,x,y,z,h,d,d,col,E.Metal,axis=='Z'and CFrame.Angles(0,math.pi/2,0)or CFrame.Angles(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder;return p
end
local function rod(m,f,n,a,b,d,col)
 local p=part(m,f,n,0,0,0,d,d,(b-a).Magnitude,col);p.CFrame=f*CFrame.lookAt((a+b)/2,b);return p
end
local function ring(m,f,n,x,y,z,r,col)
 for i=0,11 do local a=i*math.pi/6;local b=(i+1)*math.pi/6;rod(m,f,n,V(x+r*math.cos(a),y+r*math.sin(a),z),V(x+r*math.cos(b),y+r*math.sin(b),z),.07,col)end
end
local function cup(m,f,x,z)
 cyl(m,f,'EnamelCup',x,.27,z,.5,.48,'cream');cyl(m,f,'CoffeeSurface',x,.525,z,.02,.37,'rust');ring(m,f,'CupHandle',x+.3,.3,z,.16,'cream')
end
local function stamp(p,n,root)
 for k,v in {FJ_First=n,FJ_Finish=n,FJ_Mid=0,FJ_Kind='extra',FJ_Retire=999,FJ_MoveAt=999,FJ_Move=V(),FJ_CF=p.CFrame,FJ_Size=p.Size,FJ_Color=p.Color,FJ_Material=p.Material.Name,FJ_Transparency=p.Transparency,FJ_Collide=false,FJ_Query=false,FJ_Touch=false}do p:SetAttribute(k,v)end
 local path={};local q=p;while q~=root do table.insert(path,1,q.Name);q=q.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'))
end
local function resolve(root,path)local q=root;for n in path:gmatch('[^/]+')do q=assert(q:FindFirstChild(n),'Missing '..path)end;return q end
local function extent(p)return p.CFrame.RightVector:Abs()*p.Size.X/2+p.CFrame.UpVector:Abs()*p.Size.Y/2+p.CFrame.LookVector:Abs()*p.Size.Z/2 end
local function save(recovery,o,k,v)
 local r=Instance.new('ObjectValue');r.Name=string.format('%04d',#recovery:GetChildren()+1);r.Value=o;r:SetAttribute('Key',k);r:SetAttribute('HadValue',o:GetAttribute(k)~=nil);r:SetAttribute('Before',o:GetAttribute(k));r.Parent=recovery;o:SetAttribute(k,v)
end
local function fit(root,surface,w,d,h)
 assert(math.abs(surface.CFrame.UpVector.Y)>.99,'Horizontal worktop required')
 local y=surface.Position.Y+surface.Size.Y/2+.04;local nearby={}
 for _,p in root:GetDescendants()do if p:IsA('BasePart')and p~=surface and p.Transparency<.8 and (p.Position-surface.Position).Magnitude<30 then local e=extent(p);if p.Position.Y+e.Y>y+.04 and p.Position.Y-e.Y<y+h then table.insert(nearby,{p.Position,e})end end end
 local best;local score=math.huge
 for x=-surface.Size.X/2+w/2+.08,surface.Size.X/2-w/2-.08,.5 do for z=-surface.Size.Z/2+d/2+.08,surface.Size.Z/2-d/2-.08,.5 do
  local f=surface.CFrame*CF(x,surface.Size.Y/2+.04,z);local center=f.Position+V(0,h/2,0);local e=f.RightVector:Abs()*w/2+V(0,h/2,0)+f.LookVector:Abs()*d/2;local clear=true
  for _,a in nearby do local q=(center-a[1]):Abs();if q.X<e.X+a[2].X+.02 and q.Y<e.Y+a[2].Y+.02 and q.Z<e.Z+a[2].Z+.02 then clear=false;break end end
  if clear then local s=math.abs(x)+math.abs(z)*.4;if s<score then best=f;score=s end end
 end end
 assert(best,'No clear fitted worktop space: '..surface:GetFullName());return best
end
local F='10_Institution_Fidelity_R1/'
function M.Build(root,recovery)
 assert(game.RunService:IsStudio()and not game.RunService:IsRunning()and game.PlaceId==125334614375606,'Correct Edit only')
 assert(not root:FindFirstChild(M.RootName),'Already built');local layer=model(root,M.RootName);layer:SetAttribute('Version',M.Version);layer:SetAttribute('AudioStatus','ASSET_PENDING');local ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries;local manifest={}
 local function G(n,name,zone,f,fn,support)
  local m=model(layer,string.format('P%03d_%s',n,name));m.WorldPivot=f;m:SetAttribute('LifeId',name);m:SetAttribute('FirstStep',n);m:SetAttribute('Department',zone);m:SetAttribute('PurchaseId',ids[n].id);m:SetAttribute('ReplacementPivot',f);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY');fn(m,f)
  local count=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then stamp(p,n,root);count+=1 end end
  if support then local v=Instance.new('ObjectValue');v.Name='ExistingSupport';v.Value=support;v.Parent=m;assert(n>=support:GetAttribute('FJ_First'),'Premature props')end
  local _,sz=m:GetBoundingBox();m:SetAttribute('ReplacementBounds',sz);table.insert(manifest,{name=m.Name,step=n,id=ids[n].id,zone=zone,parts=count,pivot={f:GetComponents()},bounds={sz.X,sz.Y,sz.Z}});return m
 end
 -- Reuse existing people. Derive from current registered geometry, not stale FootCFrame metadata.
 local actors={};local atmosphere=resolve(root,F..'06_Atmosphere')
 for _,m in atmosphere:GetDescendants()do if m:IsA('Model')and m:FindFirstChild('Torso')and m:FindFirstChild('UpperArmR')and(m.Torso:GetAttribute('FJ_Transparency')or 1)<1 then table.insert(actors,m)end end
 table.sort(actors,function(a,b)return a.Name<b.Name end)
 for i,m in actors do
  local kind=m.Name:find('Paint')and'SWATCH'or m.Name:find('Body')and'MEASURE'or m.Name:find('Detail')and'CHECK'or m.Name=='Dispatcher'and'RADIO'or(m.Name=='Buyer'or m.Name=='SalesAdvisor'or m.Name=='Seller'or m.Name=='SeniorAppraiser')and'CONVERSE'or m.Name:find('Visitor')and'LOOK'or'PREPARE'
  save(recovery,m,'EL_Activity',kind);save(recovery,m,'EL_Offset',i*1.37)
 end
 -- A supported seated crew member on the existing salvaged bucket seat. No walking AI.
 local visitor=assert(atmosphere['07_Occupation_Frontage']:FindFirstChild('CourtVisitor'))
 G(228,'Crew_Break','Owner_Yard',CF(3165.2,1.65,152)*CFrame.Angles(0,math.pi/2,0),function(m,f)
  local a=visitor:Clone();a.Name='CrewOnBreak';for _,q in a:GetDescendants()do if not q:IsA('BasePart')then q:Destroy()end end
  for k in a:GetAttributes()do a:SetAttribute(k,nil)end;a.Parent=m
  local old=a.Torso.CFrame*CF(0,-3.3,0)
  for _,p in a:GetChildren()do if p:IsA('BasePart')then p.CFrame=f*old:ToObjectSpace(p.CFrame);if p.Name=='Torso'or p.Name=='ChestPocket'then p.Color=P.teal end end end
  for _,side in {-1,1}do local s=side==-1 and'L'or'R';local hip=V(side*.46,2.1,0);local knee=V(side*.46,1.98,-1.45);local ankle=V(side*.46,.44,-1.4)
   for _,v in {{'Thigh'..s,hip,knee},{'Shin'..s,knee,ankle}}do local p=a[v[1]];p.Size=V(p.Size.X,(v[3]-v[2]).Magnitude,p.Size.Z);p.CFrame=f*CFrame.lookAt((v[2]+v[3])/2,v[3])*CFrame.Angles(math.pi/2,0,0)end
   a['Boot'..s].CFrame=f*CF(ankle.X,.215,ankle.Z-.18)
  end
  a:SetAttribute('EL_Activity','LOOK');a:SetAttribute('EL_Offset',4)
 end)
 local function kit(n,name,zone,path,fn,w,d,h)
  local s=resolve(root,F..path);local f,scale
  for _,v in {1,.75,.55}do local ok,result=pcall(fit,root,s,(w or 2.4)*v,(d or 2.2)*v,(h or 1.45)*v);if ok then f=result;scale=v;break end end
  assert(f,'No safe fitted space '..name)
  return G(n,name,zone,f,function(m,cf)fn(m,cf);if scale<1 then for _,p in m:GetDescendants()do if p:IsA('BasePart')then local localCF=cf:ToObjectSpace(p.CFrame);p.Size*=scale;p.CFrame=cf*(localCF.Rotation+localCF.Position*scale)end end end;m:SetAttribute('FittedScale',scale)end,s)
 end
 -- EL02: every kit has a recognisable physical purpose; no SurfaceGuis or slogans.
 G(176,'Wash_Nozzle_Care','Wash',CF(2985,2.2,153)*CFrame.Angles(0,-math.pi/2,0),function(m,f)
  part(m,f,'WallBackplate',0,4,0,3.5,3,.12,'steel');part(m,f,'DripTray',0,2.4,-.55,3.6,.15,1.2,'silver')
  for i=-1,1 do local x=i*1.1;rod(m,f,'BrushHandle',V(x,2.7,-.5),V(x,4.4,-.5),.16,'wood');part(m,f,'SoftBrushHead',x,4.7,-.5,.6,.6,.5,'cream',E.Fabric);for k=1,4 do part(m,f,'BrushBristle',x-.25+k*.1,5.05,-.5,.04,.17,.4,'rubber')end end
  for i=1,3 do cyl(m,f,'QuickReleaseNozzle',-1.4+i*.7,2.64,-.7,.3,.24,({'gold','red','blue'})[i]);cyl(m,f,'NozzleOrifice',-1.4+i*.7,2.8,-.7,.02,.1,'ink')end
 end)
 kit(158,'Mechanical_Teardown_Tray','Mechanical','01_Gold_Slices/Mechanical/Tool_Bench_And_Vice/SteelWorktop',function(m,f)
  part(m,f,'RubberLinedTray',0,.07,0,2.4,.14,2.2,'rubber');for i=1,3 do local x=-.8+(i-1)*.8;cyl(m,f,'UsedPiston',x,.4,-.3,.55,.51,'silver');for j=1,2 do cyl(m,f,'PistonRing',x,.46+j*.08,-.3,.03,.53,'ink')end;rod(m,f,'ConnectingRod',V(x,.3,-.15),V(x,.17,.65),.14,'steel');cyl(m,f,'BigEndBearing',x,.2,.72,.12,.34,'gold')end
  part(m,f,'FoldedWorkshopRag',0,.13,.98,1.5,.12,.2,'red',E.Fabric)
 end)
 kit(162,'Body_Forming_Study','Body','03_Remaining_Production/02_Body/Panel_Craft_Bench_And_Tools/BenchLowerShelf',function(m,f)
  part(m,f,'LeatherShotBag',-.35,.3,0,1.35,.6,1.5,'rust',E.Fabric)
  for i=0,4 do part(m,f,'ProgressiveMetalCurve',.55+i*.15,.32+math.sin(i*.5)*.16,-.2,.18,.06,1.6,'silver',E.Metal,CFrame.Angles(0,0,i*.13))end
  rod(m,f,'MalletHandle',V(-1,.2,.9),V(.5,.2,.9),.13,'wood');cyl(m,f,'MalletHead',.6,.25,.9,.6,.37,'cream','Z')
 end)
 kit(166,'Tune_Bench_Harness','Tune','03_Remaining_Production/03_Tune/ECU_And_Sensor_Calibration_Bench/AntiStaticWorktop',function(m,f)
  part(m,f,'OpenECUCase',-.4,.15,0,1.2,.3,1.5,'silver');part(m,f,'CircuitBoard',-.4,.32,0,1.05,.05,1.3,'green');for x=1,2 do for z=1,3 do part(m,f,'IntegratedCircuit',-.85+x*.3,.38,-.7+z*.32,.18,.06,.22,'ink')end end
  for i=1,3 do rod(m,f,'ColourCodedTestLead',V(.2,.3,-.6+i*.3),V(.75,.14,-.6+i*.3),.045,({'red','gold','blue'})[i])end
  part(m,f,'DiagnosticConnector',.9,.18,0,.35,.3,1,'ink');for i=1,4 do cyl(m,f,'ConnectorPin',.9,.34,-.4+i*.16,.04,.07,'gold')end
 end)
 kit(172,'Paint_Mixing_Study','Paint','01_Gold_Slices/Paint_Exterior/Mix_Bank_And_Rare_Finishes/SteelWorktop',function(m,f)
  part(m,f,'MixingMat',0,.035,0,2.4,.07,2.2,'rubber');for i=1,3 do local x=-.8+(i-1)*.8;cyl(m,f,'MixingCup',x,.4,-.3,.7,.54,'cream');cyl(m,f,'PaintSurface',x,.76,-.3,.025,.43,({'teal','red','gold'})[i]);rod(m,f,'StirringStick',V(x,.4,-.3),V(x+.14,1.15,-.3),.06,'wood');part(m,f,'SprayOutCard',x,.1,.6,.58,.035,.75,({'teal','red','gold'})[i])end
 end)
 kit(178,'Detail_Correction_Kit','Detail','03_Remaining_Production/04_Detail/Finish_Measurement_And_Release_Desk/ReleaseBench',function(m,f)
  part(m,f,'SoftPadMat',0,.035,0,2.4,.07,2.2,'blue',E.Fabric);for i=1,3 do cyl(m,f,'FoamPolishingPad',-.8+(i-1)*.8,.2,-.4,.28,.62,({'cream','gold','red'})[i])end
  part(m,f,'OrbitalPolisher',-.25,.5,.5,1.25,.45,.45,'teal');cyl(m,f,'PolisherBackingPlate',.3,.23,.5,.12,.75,'rubber');part(m,f,'PolisherGrip',-.9,.45,.5,.4,.22,.25,'rubber');part(m,f,'FoldedMicrofibre',.8,.2,.5,.45,.25,1,'cream',E.Fabric)
 end)
 kit(217,'Photo_Lens_And_Grip_Prep','Photo','03_Remaining_Production/05_Photo/Provenance_Capture_And_Build_Record/DocumentCaptureBench',function(m,f)
  part(m,f,'FoamCameraCase',0,.15,0,2.4,.3,2.2,'ink');part(m,f,'CameraBody',-.4,.55,0,1,.5,.6,'steel');cyl(m,f,'LensBarrel',-.4,.55,-.55,.7,.55,'rubber','Z');cyl(m,f,'LensGlass',-.4,.55,-.91,.02,.42,'teal','Z');part(m,f,'Viewfinder',-.4,.86,.05,.4,.16,.4,'ink')
  cyl(m,f,'SpareLens',.65,.55,.15,.6,.48,'rubber');for i=1,3 do part(m,f,'FilterWallet',.6,.15+i*.08,-.65,.5,.05,.5,'cream')end
 end)
 -- Everyday habitation at measured existing surfaces.
 G(202,'Unpacked_Parts_Tray','Parts',CF(2986.3,5.52,411),function(m,f)
  part(m,f,'CardboardBoxBase',0,.08,0,2.5,.16,2.2,'wood',E.SmoothPlastic);for _,x in {-1.2,1.2}do part(m,f,'OpenBoxSide',x,.55,0,.08,1,2.2,'wood',E.SmoothPlastic)end;for _,z in {-1.06,1.06}do part(m,f,'OpenBoxEnd',0,.55,z,2.5,1,.08,'wood',E.SmoothPlastic)end
  for _,x in {-1.2,1.2}do part(m,f,'FoldedOpenFlap',x*1.2,1.1,0,.6,.08,2.2,'cream',E.SmoothPlastic,CFrame.Angles(0,0,x*.4))end
  cyl(m,f,'MachinedHub',0,.7,0,.55,1.2,'silver');for i=0,4 do local a=i*math.pi*2/5;cyl(m,f,'HubStud',math.cos(a)*.4,1.06,math.sin(a)*.4,.2,.1,'steel')end
 end)
 kit(192,'Crew_Lunch_In_Progress','Operations','09_Campus03/02_Operations_Courtyard/02_Operations_Staff_Courtyard/04_Staff_Hydration_And_Pinboard/CoffeeCounterStoneTop',function(m,f)
  part(m,f,'LunchTray',0,.04,0,2.4,.08,2,'steel');part(m,f,'LunchTin',-.55,.3,0,1,.5,1.2,'red');part(m,f,'TinHandle',-.55,.63,0,.6,.15,.15,'silver');cup(m,f,.65,.2);part(m,f,'FoldedBandana',.55,.12,-.65,.9,.15,.45,'blue',E.Fabric)
 end)
 -- EL03 tactile hospitality, not explanatory boards.
 kit(145,'Welcome_Coffee','Sales','11_Frontage04/03_Hospitality_And_Receiving/03_Shared_Hospitality/01_Welcome_Concierge/LimestoneCountertop',function(m,f)
  part(m,f,'OakServingTray',0,.045,0,2.4,.09,2,'wood',E.Wood);cup(m,f,-.65,.3);cup(m,f,.6,.3);part(m,f,'FoldedLinen',0,.13,-.55,1.6,.14,.55,'cream',E.Fabric)
 end)
 kit(219,'Tactile_Commission_Samples','Consultation','05_Prestige_And_Public_Realm/03_HQ_Art/Consultation_Lounge_And_Materials/SharedCoffeeTable',function(m,f)
  part(m,f,'SampleFolio',0,.06,0,1.7,.12,1.5,'rust',E.Fabric);for i=1,3 do part(m,f,'MetalFinishSample',-.72+i*.36,.16,-.3,.3,.065,.6,({'teal','red','gold'})[i],E.Metal,CFrame.Angles(0,.05*i,0))end
  part(m,f,'LeatherSwatch',-.3,.16,.45,.7,.1,.45,'cream',E.Fabric);for i=1,4 do part(m,f,'StitchSample',-.6+i*.14,.216,.45,.04,.016,.23,'rust')end
  part(m,f,'RubberTrimSample',.55,.17,.4,.32,.12,.7,'rubber')
 end,1.75,1.5,.6)
 kit(221,'Key_Presentation','Sales','11_Frontage04/04_Sales_And_Handover/Handover_Console_And_Key_Ceremony/HonedLimestoneCounter',function(m,f)
  part(m,f,'SuedeKeyTray',0,.1,0,1.9,.2,1.25,'rust',E.Fabric);part(m,f,'KeyFob',-.25,.25,0,.5,.15,.65,'ink');rod(m,f,'CutKeyBlade',V(0,.25,0),V(.6,.25,0),.12,'silver');for i=1,3 do part(m,f,'KeyCut',.2+i*.1,.25,.1,.05,.08,.15,'silver')end;part(m,f,'DeliveryCloth',.55,.2,-.2,.6,.1,.8,'cream',E.Fabric)
 end,2,1.4,.6)
 -- EL04 verified audio is a dependency, not a fabricated claim. No blank Sound instances.
 local audio=Instance.new('Folder');audio.Name='AudioRequirements';audio.Parent=layer
 for _,v in {{'Wash_water_and_reclaim',V(3006,4,145),77,24},{'Workshop_handtools_and_ventilation',V(2995,5,215),82,28},{'Parts_carton_and_small_metal',V(2987,5.5,411),150,18},{'Customer_low_conversation_and_cups',V(3043,4,46),145,18},{'Yard_wind_and_distant_shop',V(3177,4,155),228,25}}do local a=Instance.new('Configuration');a.Name=v[1];a:SetAttribute('WorldPosition',v[2]);a:SetAttribute('FirstStep',v[3]);a:SetAttribute('RadiusStuds',v[4]);a:SetAttribute('Status','NEEDS_APPROVED_AUDIO');a.Parent=audio end
 layer:SetAttribute('ExistingActors',#actors);layer:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return {actors=#actors,groups=#manifest,manifest=manifest}
end
return M

