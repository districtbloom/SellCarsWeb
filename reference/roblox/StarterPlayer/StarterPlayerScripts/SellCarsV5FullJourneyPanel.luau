if not game:GetService('RunService'):IsStudio()or game.PlaceId~=125334614375606 then return end
local Players=game:GetService('Players');local UIS=game:GetService('UserInputService');local TS=game:GetService('TweenService')
local p=Players.LocalPlayer;local pg=p:WaitForChild('PlayerGui');local data=require(game.ReplicatedStorage:WaitForChild('SellCarsV5FullJourneyData'));local remote=game.ReplicatedStorage:WaitForChild('SellCarsV5FullJourneyRemote')
local gui=Instance.new('ScreenGui');gui.Name='SellCarsV5FullJourney';gui.ResetOnSpawn=false;gui.DisplayOrder=100;gui.Parent=pg
local frame=Instance.new('Frame');frame.Name='JourneyBar';frame.AnchorPoint=Vector2.new(.5,1);frame.Position=UDim2.new(.5,0,1,-14);frame.Size=UDim2.new(1,-32,0,192);frame.BackgroundColor3=Color3.fromRGB(24,31,33);frame.BackgroundTransparency=.06;frame.BorderSizePixel=0;frame.Parent=gui
local lim=Instance.new('UISizeConstraint');lim.MaxSize=Vector2.new(1060,192);lim.Parent=frame;local round=Instance.new('UICorner');round.CornerRadius=UDim.new(0,10);round.Parent=frame
local function text(name,y,h,size)
 local t=Instance.new('TextLabel');t.Name=name;t.Position=UDim2.fromOffset(16,y);t.Size=UDim2.new(1,-32,0,h);t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(236,229,209);t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextWrapped=true;t.Parent=frame;return t
end
local scope=text('Scope',7,15,10);scope.Text='FULL DEALERSHIP JOURNEY · 240 VISUAL BUNDLES · economy / purchases not wired'
local title=text('Title',25,23,15);local caption=text('Delta',51,38,12);caption.TextYAlignment=Enum.TextYAlignment.Top
local phase=text('Phase',91,17,11)
local track=Instance.new('Frame');track.Name='Slider';track.Size=UDim2.new(1,-128,0,5);track.Position=UDim2.fromOffset(20,119);track.BackgroundColor3=Color3.fromRGB(92,105,104);track.BorderSizePixel=0;track.Parent=frame
local knob=Instance.new('Frame');knob.Name='Handle';knob.Size=UDim2.fromOffset(12,16);knob.Position=UDim2.fromOffset(-6,-5);knob.BackgroundColor3=Color3.fromRGB(230,194,118);knob.BorderSizePixel=0;knob.Parent=track
for _,n in {0,24,64,140,196,240}do local mark=Instance.new('Frame');mark.Position=UDim2.new(n/240,-1,0,-2);mark.Size=UDim2.fromOffset(2,9);mark.BackgroundColor3=Color3.fromRGB(210,210,190);mark.BorderSizePixel=0;mark.Parent=track end
local hit=Instance.new('Frame');hit.Name='SliderHitArea';hit.Size=UDim2.new(1,0,0,24);hit.Position=UDim2.fromOffset(0,-10);hit.BackgroundTransparency=1;hit.Active=true;hit.ZIndex=3;hit.Parent=track
local input=Instance.new('TextBox');input.Name='GoToPad';input.Position=UDim2.new(1,-94,0,106);input.Size=UDim2.fromOffset(76,26);input.Text='1';input.PlaceholderText='0–240';input.ClearTextOnFocus=false;input.BackgroundColor3=Color3.fromRGB(53,66,68);input.TextColor3=Color3.fromRGB(245,236,209);input.TextSize=13;input.Font=Enum.Font.GothamMedium;input.Parent=frame
local function row(y,count)
 local r=Instance.new('Frame');r.Position=UDim2.fromOffset(12,y);r.Size=UDim2.new(1,-24,0,25);r.BackgroundTransparency=1;r.Parent=frame
 local l=Instance.new('UIListLayout');l.FillDirection=Enum.FillDirection.Horizontal;l.Padding=UDim.new(0,5);l.Parent=r
 return function(label,fn)local b=Instance.new('TextButton');b.Size=UDim2.new(1/count,-5,1,0);b.Text=label;b.TextSize=11;b.Font=Enum.Font.GothamMedium;b.TextColor3=Color3.fromRGB(239,232,214);b.BackgroundColor3=Color3.fromRGB(52,67,70);b.BorderSizePixel=0;b.Parent=r;b.Activated:Connect(fn);return b end
end
local token=0;local generation=0;local selected=1;local ready=false;local auto=false;local manual;local tween;local choose;local playButton
local walkUI
local milestonesOnly=false;local modeButton;local comparisonBefore=0;local activeMilestone
local fastPadMoveSeconds=.12 -- Individual pads reveal without the deliberate milestone BEFORE hold.
local function milestoneFor(n)for _,m in data.Milestones or{}do if n>=m.first and n<=m.last then return m end end end
local function setMode(on)milestonesOnly=on;gui:SetAttribute('ReviewMode',on and'MILESTONES'or'EACH_PAD');if modeButton then modeButton.Text=on and'VIEW: MILESTONES'or'VIEW: EACH PAD'end end
local function adjacent(direction)
 if not milestonesOnly then return selected+direction end
 if direction>0 then for _,m in data.Milestones do if m.last>selected then return m.last end end;return 240 end
 for i=#data.Milestones,1,-1 do if data.Milestones[i].last<selected then return data.Milestones[i].last end end;return 0
end
local normalFieldOfView=workspace.CurrentCamera.FieldOfView
local focusParts={};local outlines={}
local function clearOutlines()for _,h in outlines do h:Destroy()end;table.clear(outlines)end
local function highlightChange()
 clearOutlines();local mine=token;local gen=generation
 for _,part in focusParts do if typeof(part)=='Instance'and part:IsA('BasePart')and part:IsDescendantOf(workspace)and part.Transparency<1 then
  local h=Instance.new('Highlight');h.Name='JourneyChangeOutline';h.Adornee=part;h.FillTransparency=1;h.OutlineTransparency=.15;h.OutlineColor=Color3.fromRGB(247,204,109);h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=gui;table.insert(outlines,h)
 end end
 task.delay(2.2,function()if mine==token and gen==generation then clearOutlines()end end)
end
local function readableCaption(s)return(s:gsub('^A ','Adds '):gsub('^R ','Upgrades '):gsub('^P ','Preserves '):gsub('; A ','; adds '):gsub('; R ','; upgrades '):gsub('; P ','; preserves '))end
local function state(s,t)
 gui:SetAttribute('Phase',s);phase.Text=t;phase.TextColor3=s=='AFTER'and Color3.fromRGB(153,222,187)or Color3.fromRGB(235,202,145)
 if activeMilestone then
  if s=='AFTER'then caption.Text='PAYOFF · '..(activeMilestone.payoff or activeMilestone.summary)
  elseif s=='BEFORE'or s=='BEFORE_HOLD'or s=='FRAMING'then caption.Text='START · '..(activeMilestone.limitation or'')..'  BUILD · '..(activeMilestone.preparation or activeMilestone.summary)end
 end
end
local function cancel()if walkUI then walkUI.Stop()end;token+=1;generation+=1;ready=false;clearOutlines();focusParts={};if tween then tween:Cancel();tween=nil end;remote:FireServer('CANCEL',token)end
local function stop()auto=false;clearOutlines();if playButton then playButton.Text='PLAY JOURNEY'end end
choose=function(n,hold,overview)
 cancel();selected=math.clamp(math.floor(n),0,240);local milestone=milestonesOnly and not overview and milestoneFor(selected)or nil;if milestone then selected=milestone.last end;manual=hold;frame.Visible=true;gui:SetAttribute('Selected',selected)
 activeMilestone=milestone;gui:SetAttribute('PayoffAnchor',milestone and milestone.anchor or nil)
 local e=data.Entries[selected];title.Text=e and string.format('%03d / 240 · %s · %s',selected,e.chapter,e.title)or'000 / 240 · Unclaimed ground';caption.Text=e and readableCaption(e.delta)or'A supported parcel before the first purchase.'
 if milestone then title.Text=string.format('%03d–%03d / 240 · %s',milestone.first,milestone.last,milestone.title);caption.Text=milestone.summary end
 input.Text=tostring(selected);knob.Position=UDim2.new(selected/240,-6,0,-5);state('LOADING','Preparing the previous purchase state…');remote:FireServer('PREPARE',token,selected,overview and'CHAPTER'or(milestone and'MILESTONE'or nil))
end
local function walk()stop();cancel();frame.Visible=false;gui:SetAttribute('SolidRoofRecommended',true);workspace.CurrentCamera.FieldOfView=normalFieldOfView;workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then workspace.CurrentCamera.CameraSubject=h end;state('PAUSED','Walking · open JOURNEY to return')end
local function show(side)stop();generation+=1;clearOutlines();manual=side;if not ready or gui:GetAttribute('Phase')=='FRAMING'then choose(selected,side)else remote:FireServer('SHOW',token,selected,side)end end
local function payoffView()if activeMilestone and activeMilestone.anchor then local n=activeMilestone.anchor;stop();setMode(false);choose(n)end end
local buttons=row(137,8)
buttons('‹ PREVIOUS',function()stop();choose(adjacent(-1))end);buttons('NEXT ›',function()stop();choose(adjacent(1))end);buttons('REPLAY',function()stop();choose(selected)end);buttons('BEFORE',function()show('BEFORE')end);buttons('AFTER',function()show('AFTER')end)
buttons('PAYOFF DETAIL',payoffView)
playButton=buttons('PLAY JOURNEY',function()if auto then stop();generation+=1;state('PAUSED','Playback paused · Replay to repeat this upgrade')else auto=true;playButton.Text='PAUSE';choose(selected)end end);buttons('WALK / HIDE',walk)
local chapters=row(166,6);chapters('EMPTY / 0',function()stop();choose(0,'AFTER',true)end)
for i,name in {'BIRTH','WORKING','DEDICATED','PROFESSIONAL','INSTITUTION'}do local n=data.Endpoints[i];chapters(name,function()stop();choose(n,'AFTER',true)end)end
local function topButton(name,label,offset,w,fn)local b=Instance.new('TextButton');b.Name=name;b.Text=label;b.Size=UDim2.fromOffset(w,32);b.Position=UDim2.new(1,-offset,0,16);b.BackgroundColor3=Color3.fromRGB(84,70,44);b.TextColor3=Color3.fromRGB(246,233,203);b.Font=Enum.Font.GothamMedium;b.TextSize=12;b.Parent=gui;b.Activated:Connect(fn);return b end
topButton('ReopenJourney','JOURNEY',146,130,function()stop();choose(selected)end)
topButton('ProtectedBenchmark','ORIGINAL INSTITUTION',342,184,function()stop();cancel();frame.Visible=true;remote:FireServer('BENCHMARK',token,selected);state('LOADING','Restoring the protected Institution benchmark…')end)
modeButton=topButton('ReviewMode','VIEW: EACH PAD',516,162,function()stop();setMode(not milestonesOnly);choose(selected)end);modeButton.Position=UDim2.new(1,-516,0,56);setMode(false)
input.FocusLost:Connect(function(enter)if enter then local n=tonumber(input.Text);if n then stop();setMode(false);choose(n)else input.Text=tostring(selected)end end end)
local dragging=false;local draft=selected
local function drag(x)draft=math.clamp(math.floor((x-track.AbsolutePosition.X)/track.AbsoluteSize.X*240+.5),0,240);knob.Position=UDim2.new(draft/240,-6,0,-5);local e=data.Entries[draft];phase.Text=string.format('Release to review %03d · %s',draft,e and e.title or'Unclaimed ground');input.Text=tostring(draft)end
hit.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then stop();cancel();dragging=true;drag(i.Position.X);state('SCRUBBING',phase.Text)end end)
UIS.InputChanged:Connect(function(i)if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then drag(i.Position.X)end end)
UIS.InputEnded:Connect(function(i)if dragging and(i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)then dragging=false;setMode(false);choose(draft)end end)
remote.OnClientEvent:Connect(function(kind,id,index,r)
 if walkUI and walkUI.active then return end
 if id~=token then return end
 if kind=='ERROR'then stop();generation+=1;state('ERROR',tostring(r):sub(-170));return end
 if kind=='BENCHMARK'then gui:SetAttribute('SolidRoofRecommended',true);state('BENCHMARK','Protected original Institution · no preview additions');return end
 if index~=selected then return end
 gui:SetAttribute('ShownStep',r.step)
 if kind=='READY'then
  comparisonBefore=r.beforeStep or math.max(0,selected-1);gui:SetAttribute('ComparisonBefore',comparisonBefore)
  focusParts=r.review and r.review.parts or{};gui:SetAttribute('SolidRoofRecommended',r.review and r.review.solidRoof==true or false)
  if not activeMilestone and r.review and r.review.benefit then caption.Text=r.review.benefit end
  ready=true;local mine=token;local gen=generation;local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable;state('FRAMING','BEFORE · moving to this upgrade…')
  tween=TS:Create(cam,TweenInfo.new(activeMilestone and data.MoveSeconds or fastPadMoveSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{CFrame=CFrame.lookAt(r.camera,r.look,r.review and r.review.up or Vector3.yAxis),FieldOfView=r.review and r.review.fov or normalFieldOfView})
  tween.Completed:Once(function(result)
   if mine~=token or gen~=generation or result~=Enum.PlaybackState.Completed then return end;tween=nil
   if manual then remote:FireServer('SHOW',token,selected,manual);return end
   if not activeMilestone then remote:FireServer('SHOW',token,selected,'AFTER');return end
   local began=os.clock();gui:SetAttribute('BeforeHoldStarted',began);state('BEFORE_HOLD','BEFORE · take a moment to look')
   task.spawn(function()while os.clock()-began<data.BeforeSeconds do if mine~=token or gen~=generation then return end;phase.Text=string.format('BEFORE %03d · upgrade appears in %.1fs',comparisonBefore,data.BeforeSeconds-(os.clock()-began));task.wait(.1)end;if mine==token and gen==generation then remote:FireServer('SHOW',token,selected,'AFTER')end end)
  end);tween:Play()
 elseif kind=='BEFORE'then state('BEFORE','BEFORE · held at '..r.step..' · After or Replay to compare')
 elseif kind=='AFTER'then
  highlightChange()
  gui:SetAttribute('LastRevealAt',os.clock());state('AFTER','AFTER · '..selected..' / 240 · same camera angle')
  if auto then local mine=token;local gen=generation;task.delay(data.AfterSeconds,function()if mine==token and gen==generation and auto then if selected<240 then choose(adjacent(1))else stop();state('AFTER','Journey complete · compare chapters or walk around')end end end)end
 end
end)
walkUI=require(game.ReplicatedStorage:WaitForChild('SellCarsV5WalkJourneyClient')).Create({player=p,remote=remote,gui=gui,frame=frame,fov=normalFieldOfView,token=function()return token end,cancel=cancel,stopAuto=stop,review=function(n)setMode(false);choose(n,'AFTER')end})
local action=Instance.new('BindableEvent');action.Name='ReviewAction';action.Parent=gui;action.Event:Connect(function(name,n)if name=='ON_FOOT_REVEAL'then walkUI.Reveal()elseif name=='ON_FOOT_TRAVEL'then walkUI.Travel()elseif name=='ON_FOOT'then walkUI.Start(n or 0,n==nil or n==0)elseif name=='SELECT'then stop();setMode(false);choose(n)elseif name=='MILESTONE'then stop();setMode(true);choose(n)elseif name=='CHAPTER'then stop();choose(n,'AFTER',true)elseif name=='PAYOFF'then payoffView()elseif name=='BEFORE'or name=='AFTER'then show(name)elseif name=='WALK'then walk()elseif name=='OPEN'then choose(gui:GetAttribute('ShownStep')or selected)end end)
choose(1,'BEFORE')

