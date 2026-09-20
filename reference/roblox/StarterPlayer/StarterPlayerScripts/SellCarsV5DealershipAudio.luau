-- SND01: local spatial soundscape + explicit listening/audition route. No gameplay writes.
if not game.RunService:IsStudio()or game.PlaceId~=125334614375606 then return end
local player=game.Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local journey=pg:WaitForChild('SellCarsV5FullJourney',30);local life=pg:WaitForChild('SellCarsV5EverydayLife',30)
local scene=workspace:WaitForChild('SellCars_Dealership_FullJourney',30)
if not journey or not life or not scene then return end
local map=require(game.ReplicatedStorage:WaitForChild('SellCarsV5SoundMap'))
local V,CF=Vector3.new,CFrame.new
local folder=Instance.new('Folder');folder.Name='ACA_LocalAudio';folder.Parent=workspace
local listener=Instance.new('AudioListener');listener.Name='ACA_Listener';listener.AudioInteractionGroup='SellCarsSND01';listener.Parent=workspace.CurrentCamera
local output=Instance.new('AudioDeviceOutput');output.Name='ACA_Output';output.Player=player;output.Parent=folder
local function wire(a,b)local w=Instance.new('Wire');w.SourceInstance=a;w.TargetInstance=b;w.Parent=folder;return w end
wire(listener,output);local meter=Instance.new('AudioAnalyzer');meter.Name='ACA_MixMeter';meter.Parent=folder;wire(listener,meter)
local ui=Instance.new('ScreenGui');ui.Name='SellCarsV5Audio';ui.ResetOnSpawn=false;ui.DisplayOrder=105;ui.Parent=pg
local enabled,focused,music=true,true,false;local amb,fx=.25,.35;local records,seen,missing={},{},{};local routeIndex=1;local savedCamera;local cue;local elapsed,rescan=0,6;local serial=0
-- OPT02: batch initial indexing; steady-state discovery traverses only named candidates.
local candidateNames={BroadFanBlade=true,RinseEmitter=true,OuterLimestoneEdge_1=true,RecessedSpeakerCone=true,SalvagedBrakeRotorFoot=true}
local candidates={};local indexed=false;local indexing=false;local alive=true;local fullScans=0;local sourceDirty=true
local function observe(p)if p:IsA('BasePart')and candidateNames[p.Name]then candidates[p]=true;sourceDirty=true end end
local function indexSources()
 if indexing or not alive then return end;indexing=true;indexed=false;fullScans+=1
 task.spawn(function()
  local all=scene:GetDescendants();local chunkStart=os.clock();local maxChunk=0
  for i,p in all do if not alive then return end;if p:IsDescendantOf(scene)then observe(p)end
   if i%300==0 then maxChunk=math.max(maxChunk,(os.clock()-chunkStart)*1000);task.wait();chunkStart=os.clock()end
  end
  maxChunk=math.max(maxChunk,(os.clock()-chunkStart)*1000);indexed=true;indexing=false;sourceDirty=true
  ui:SetAttribute('AudioIndexFullScans',fullScans);ui:SetAttribute('AudioIndexMaxChunkMs',maxChunk)
 end)
end
local sourceAdded=scene.DescendantAdded:Connect(function(p)observe(p);if p:IsA('BasePart')then sourceDirty=true end end)
local sourceRemoved=scene.DescendantRemoving:Connect(function(p)candidates[p]=nil;if p:IsA('BasePart')then sourceDirty=true end end)
indexSources()
local function button(parent,name,text,x,y,w,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Text=text;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,28);b.BackgroundColor3=Color3.fromRGB(48,65,59);b.TextColor3=Color3.fromRGB(230,218,188);b.Font=Enum.Font.GothamBold;b.TextSize=11;b.Parent=parent;b.Activated:Connect(fn);return b
end
local panel=Instance.new('Frame');panel.Name='MixPanel';panel.Position=UDim2.fromOffset(660,90);panel.Size=UDim2.fromOffset(260,198);panel.BackgroundColor3=Color3.fromRGB(25,34,32);panel.Visible=false;panel.Parent=ui
local status=Instance.new('TextLabel');status.Name='ListeningStatus';status.Size=UDim2.fromOffset(450,48);status.Position=UDim2.fromOffset(16,124);status.TextWrapped=true;status.TextColor3=Color3.fromRGB(240,225,193);status.BackgroundColor3=Color3.fromRGB(25,34,32);status.TextSize=13;status.Visible=false;status.Parent=ui
local function message(s)ui:SetAttribute('LastAction',s);status.Text=s end
local function stopCue()if cue then cue.player:Stop();cue.player.Volume=0;cue=nil end end
local function hardStop()stopCue();for _,r in records do r.player.Volume=0;r.player:Stop();r.audible=false end end
local toggle,ab,fb,mb
local function labels()toggle.Text=enabled and'AUDIO: ON'or'AUDIO: OFF';ab.Text='AMBIENCE '..math.floor(amb*100)..'%';fb.Text='EFFECTS '..math.floor(fx*100)..'%';mb.Text=music and'OWNER RADIO: ON (15%)'or'OWNER RADIO: OFF';ui:SetAttribute('Enabled',enabled);ui:SetAttribute('MusicEnabled',music)end
toggle=button(ui,'ToggleAudio','AUDIO: ON',660,56,102,function()enabled=not enabled;if not enabled then hardStop()end;labels()end)
button(ui,'OpenMix','MIX',766,56,42,function()panel.Visible=not panel.Visible end)
ab=button(panel,'Ambience','',6,6,248,function()amb=amb==.25 and .5 or amb==.5 and 0 or .25;labels()end)
fb=button(panel,'Effects','',6,37,248,function()fx=fx==.35 and .6 or fx==.6 and 0 or .35;labels()end)
mb=button(panel,'Music','',6,68,248,function()music=not music;if not music then for _,r in records do if r.mode=='MUSIC'then r.player:Stop();r.player.Volume=0 end end end;labels()end)
local function route(n)
 if not savedCamera then local c=workspace.CurrentCamera;savedCamera={camera=c,cf=c.CFrame,kind=c.CameraType,subject=c.CameraSubject,fov=c.FieldOfView}end
 stopCue();routeIndex=(n-1)%#map.Route+1;local v=map.Route[routeIndex];local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.FieldOfView=64;c.CFrame=CFrame.lookAt(v[2],v[3]);status.Visible=true
 message(string.format('%02d/%02d · %s\nCurrent pad retained · AUDITION is a preview, not a gameplay action.',routeIndex,#map.Route,v[1]));ui:SetAttribute('RouteIndex',routeIndex);ui:SetAttribute('RouteActive',true)
end
local function closeRoute()
 stopCue();if savedCamera then local c=workspace.CurrentCamera;c.CameraType=savedCamera.kind;c.CameraSubject=savedCamera.subject;c.CFrame=savedCamera.cf;c.FieldOfView=savedCamera.fov;savedCamera=nil end
 status.Visible=false;ui:SetAttribute('RouteActive',false)
end
local function add(key,p,asset,zone,mode,gain,radius,first,position)
 if seen[key]then return end;seen[key]=true;serial+=1
 local anchor=Instance.new('Part');anchor.Name='SND_'..key;anchor.Size=V(.05,.05,.05);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CFrame=CF(position or p.Position);anchor.Parent=folder
 local emitter=Instance.new('AudioEmitter');emitter.AudioInteractionGroup='SellCarsSND01';emitter:SetDistanceAttenuation({[0]=1,[4]=1,[radius*.5]=.45,[radius]=0});emitter.Parent=anchor
 local ap=Instance.new('AudioPlayer');ap.Name=key;ap.Asset='rbxassetid://'..map.Assets[asset];ap.Volume=0;ap.Looping=mode~='CUE'and mode~='FOLIAGE';ap.Parent=folder;local connection=wire(ap,emitter)
 local r={key=key,p=p,player=ap,a=anchor,wire=connection,zone=zone,mode=mode,gain=gain,radius=radius,first=first or(p and p:GetAttribute('FJ_First'))or 1,fixed=position,previous=p and p.CFrame,next=12+serial*.63,audible=false};records[#records+1]=r
end
local function discover()
 local started=os.clock();local visited=0
 for i=#records,1,-1 do local r=records[i];if r.p and not r.p:IsDescendantOf(scene)then
  if cue==r then stopCue()end;r.player:Stop();r.wire:Destroy();r.player:Destroy();r.a:Destroy();seen[r.key]=nil;table.remove(records,i)
 end end
 missing={}
 local fid=scene:FindFirstChild('10_Institution_Fidelity_R1');if not fid then return end
 for _,s in map.Targets do if not seen[s.key]then local m=fid:FindFirstChild(s.model,true);local p=m and m:FindFirstChild(s.part,true);if p and p:IsA('BasePart')then add(s.key,p,s.asset,s.zone,s.mode,s.gain,s.radius)else missing[s.key]=true end end end
 for p in candidates do if p:IsDescendantOf(scene)then visited+=1
  if p.Name=='BroadFanBlade'and p:GetAttribute('OC_Motion')=='FAN'then add('TUNE_FAN_'..p.Parent.Name,p,'fan','TUNE','FAN',.21,30)
  elseif p.Name=='RinseEmitter'and math.abs(p.Position.Z-132)<.1 then add('WASH_RINSE_1',p,'water','WASH','WATER',.42,30)
  elseif p.Name=='RinseEmitter'and math.abs(p.Position.Z-156)<.1 then add('WASH_RINSE_2',p,'water','WASH','WATER',.42,30)
  elseif p.Name=='OuterLimestoneEdge_1'and p.Parent.Parent.Name=='01_Desert_Promenade'then add('GARDEN_'..p.Parent.Name,p,'wind','GARDENS','BED',.22,48)
  elseif p.Name=='RecessedSpeakerCone'and p.Parent.Name=='P185_Handbuilt_Listening_Cabinet'then add('OWNER_RADIO',p,'music','OWNER','MUSIC',.15,27)
  elseif p.Name=='SalvagedBrakeRotorFoot'and p:IsDescendantOf(scene:FindFirstChild('ACA_ArtCulture')or folder)then add('OWNER_FOLIAGE',p,'foliage','OWNER','FOLIAGE',.2,20)
  end
 end end
 -- Site wind is environmental, not a purchased prop. Its location remains fixed through chapters.
 add('ROADSIDE_AIR',nil,'wind','FRONT','BED',.16,82,1,V(3080,4,48))
 ui:SetAttribute('MissingTargets',game.HttpService:JSONEncode(missing))
 ui:SetAttribute('AudioDiscoveryCandidates',visited);ui:SetAttribute('AudioDiscoveryMs',(os.clock()-started)*1000)
 ui:SetAttribute('AudioDiscoveryRuns',(ui:GetAttribute('AudioDiscoveryRuns')or 0)+1)
end
local function running()return enabled and focused and journey:GetAttribute('Phase')=='AFTER'end
local function valid(r,step)
 return step>=(r.p and r.p:GetAttribute('FJ_First')or r.first)and(not r.p or r.p:IsDescendantOf(scene)and step<(r.p:GetAttribute('FJ_Retire')or 999))
end
local function audition(key)
 stopCue();if not running()then message('Audio needs ON, focused Studio and AFTER phase.');return end
 key=key or map.Route[routeIndex][5];if not key then message('This stop has no invented action cue; listen to its ambient mix.');return end
 for _,r in records do if r.key==key and r.mode=='CUE'then
  if not valid(r,journey:GetAttribute('ShownStep')or 0)then message('Locked: audition available from pad '..(r.p and r.p:GetAttribute('FJ_First')or r.first));return end
  if(workspace.CurrentCamera.CFrame.Position-r.a.Position).Magnitude>r.radius then message('Move closer to the source or use its LISTEN stop.');return end
  if not r.player.IsReady then message('Recording is still loading or unavailable.');return end
  cue=r;r.deadline=os.clock()+46;r.player.TimePosition=0;r.player.Volume=r.gain*fx;r.player:Play();message('AUDITION ONLY · '..key..' · STOP CUE interrupts immediately.');return
 end end
end
button(ui,'ListenRoute','LISTEN',812,56,90,function()route(routeIndex)end)
button(panel,'PreviousStop','PREVIOUS',6,99,120,function()route(routeIndex-1)end)
button(panel,'NextStop','NEXT STOP',134,99,120,function()route(routeIndex+1)end)
button(panel,'Audition','AUDITION CUE',6,130,120,function()audition()end)
button(panel,'StopCue','STOP CUE',134,130,120,stopCue)
button(panel,'ExitRoute','EXIT / RESTORE CAMERA',6,161,248,closeRoute)
local qa=Instance.new('BindableEvent');qa.Name='AudioAction';qa.Parent=ui
qa.Event:Connect(function(cmd,n)
 if cmd=='OFF'then enabled=false;hardStop()elseif cmd=='ON'then enabled=true
 elseif cmd=='MUSIC_ON'then music=true elseif cmd=='MUSIC_OFF'then music=false;for _,r in records do if r.mode=='MUSIC'then r.player:Stop();r.player.Volume=0 end end
 elseif cmd=='ROUTE'then route(tonumber(n)or 1)elseif cmd=='CLOSE'then closeRoute()elseif cmd=='AUDITION'then audition(n)elseif cmd=='RATCHET'then audition('MECHANICAL')elseif cmd=='STOP'then stopCue()elseif cmd=='RESCAN'then indexSources()end;labels()
end)
labels();ui:SetAttribute('Scope','SND01_WHOLE_MAP');ui:SetAttribute('ListeningApproval','PENDING_HUMAN');ui:SetAttribute('MusicStatus','OPTIONAL_TOOLBOX_APM')
local c1=game.UserInputService.WindowFocused:Connect(function()focused=true end)
local c2=game.UserInputService.WindowFocusReleased:Connect(function()focused=false;hardStop()end)
local c3=journey:GetAttributeChangedSignal('Phase'):Connect(function()if journey:GetAttribute('Phase')~='AFTER'then hardStop()end end)
local c4=journey:GetAttributeChangedSignal('WalkingJourney'):Connect(function()if savedCamera and journey:GetAttribute('WalkingJourney')then closeRoute()end end)
local hb=game.RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;rescan+=dt;if elapsed<.1 then return end;local tick=elapsed;elapsed=0;if listener.Parent~=workspace.CurrentCamera then listener.Parent=workspace.CurrentCamera end
 if indexed and(rescan>=6 or sourceDirty and rescan>=1)then discover();rescan=0;sourceDirty=false end
 local step=journey:GetAttribute('ShownStep')or 0;local cam=workspace.CurrentCamera;local zone=map.Zone(cam.CFrame.Position);local run=running();local story=pg:FindFirstChild('SellCarsV5ShopStories');local motion=life:GetAttribute('Enabled')~=false and(not story or story:GetAttribute('MotionEnabled')~=false)
 local near={};local ready,playing=0,0
 for _,r in records do
  if r.p and r.p:IsDescendantOf(scene)then r.a.CFrame=r.p.CFrame end
  local d=(cam.CFrame.Position-r.a.Position).Magnitude;local on=run and valid(r,step)and d<r.radius;local moving=false
  if r.p and r.previous then moving=r.previous.LookVector:Dot(r.p.CFrame.LookVector)<.99999 or r.previous.UpVector:Dot(r.p.CFrame.UpVector)<.99999;r.previous=r.p.CFrame end
  if r.mode=='FAN'then on=on and motion and moving elseif r.mode=='WATER'then local b=r.p:FindFirstChild('BoundedRinse');on=on and motion and b and b.Enabled elseif r.mode=='MUSIC'then on=on and music elseif r.mode=='FOLIAGE'then on=on and not cue end
  local bleed=map.Bleed(r.zone,zone,step);local score=r.gain*(1-d/r.radius)*bleed*(r.audible and 1.18 or 1);table.insert(near,{r=r,on=on,bleed=bleed,score=score})
 end
 table.sort(near,function(a,b)return a.score>b.score end)
 local beds,fxVoices,foliage=0,0,0;local active={}
 for _,v in near do local r=v.r;local ap=r.player;if ap.IsReady then ready+=1 end
  local on=v.on
  if r.mode=='BED'and on then beds+=1;on=beds<=1 elseif(r.mode=='FAN'or r.mode=='WATER')and on then fxVoices+=1;on=fxVoices<=2 elseif r.mode=='FOLIAGE'and on then foliage+=1;on=foliage<=1 end
  if r.mode=='CUE'then
   if r==cue then if not on or os.clock()>r.deadline then stopCue()elseif not ap.IsPlaying then cue=nil else ap.Volume=r.gain*fx*v.bleed end end
  else
   local mix=r.mode=='MUSIC'and 1 or(r.mode=='BED'or r.mode=='FOLIAGE')and amb or fx
   local target=on and r.gain*mix*v.bleed or 0
   if not run then ap.Volume=0;ap:Stop()else ap.Volume+=(target-ap.Volume)*math.min(1,tick*(r.mode=='WATER'and 12 or 4))end
   if on and target>.0002 and ap.IsReady then
    if r.mode=='FOLIAGE'then r.next-=tick;if r.next<=0 and not ap.IsPlaying then ap:Play();r.next=21 end
    elseif not ap.IsPlaying then ap:Play()end
   elseif ap.Volume<.001 then ap:Stop()end
   r.audible=on
  end
  if ap.IsPlaying then playing+=1;active[#active+1]=r.key end
 end
 ui:SetAttribute('Zone',zone);ui:SetAttribute('TrackedSources',#records);ui:SetAttribute('ReadySources',ready);ui:SetAttribute('PlayingSources',playing);ui:SetAttribute('ActiveSources',table.concat(active,','));ui:SetAttribute('MixRMS',meter.RmsLevel);ui:SetAttribute('Focused',focused)
end)
ui.Destroying:Connect(function()alive=false;sourceAdded:Disconnect();sourceRemoved:Disconnect();hb:Disconnect();c1:Disconnect();c2:Disconnect();c3:Disconnect();c4:Disconnect();closeRoute();hardStop();listener:Destroy();folder:Destroy()end)

