-- Studio-only guided comparison. Existing scene API remains sole geometry writer.
if not game.RunService:IsStudio()or game.PlaceId~=125334614375606 then return end
local Players=game:GetService('Players');local UIS=game:GetService('UserInputService');local TweenService=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local data=require(game.ReplicatedStorage:WaitForChild('SellCarsV5GuidedTourData'))
local remote=game.ReplicatedStorage:WaitForChild('SellCarsV5GuidedTour')
local gui=Instance.new('ScreenGui');gui.Name='SellCarsV5GuidedTour';gui.ResetOnSpawn=false;gui.DisplayOrder=95;gui.Parent=pg
local frame=Instance.new('Frame');frame.Name='TourBar';frame.AnchorPoint=Vector2.new(.5,1);frame.Position=UDim2.new(.5,0,1,-16);frame.Size=UDim2.new(1,-32,0,158);frame.BackgroundColor3=Color3.fromRGB(24,31,33);frame.BackgroundTransparency=.08;frame.BorderSizePixel=0;frame.Parent=gui
local constraint=Instance.new('UISizeConstraint');constraint.MaxSize=Vector2.new(1000,158);constraint.Parent=frame
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=frame
local function label(name,y,h,size)
 local t=Instance.new('TextLabel');t.Name=name;t.Position=UDim2.fromOffset(18,y);t.Size=UDim2.new(1,-36,0,h);t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(237,233,219);t.TextXAlignment=Enum.TextXAlignment.Left;t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.Parent=frame;return t
end
local scope=label('Scope',7,16,10);scope.Text='COLLECTOR CHANGE TOUR · 3 changes + overview · other departments unchanged'
local heading=label('Heading',26,22,16)
local caption=label('Caption',51,28,12);caption.TextWrapped=true;caption.TextYAlignment=Enum.TextYAlignment.Top
local phase=label('Phase',81,17,11)
local track=Instance.new('Frame');track.Name='StepSlider';track.Position=UDim2.fromOffset(18,105);track.Size=UDim2.new(1,-36,0,5);track.BackgroundColor3=Color3.fromRGB(89,103,104);track.BorderSizePixel=0;track.Active=true;track.Parent=frame
local knob=Instance.new('Frame');knob.Name='Handle';knob.Size=UDim2.fromOffset(12,15);knob.Position=UDim2.new(0,-6,0,-5);knob.BackgroundColor3=Color3.fromRGB(229,193,117);knob.BorderSizePixel=0;knob.Parent=track
local sliderHit=Instance.new('Frame');sliderHit.Name='SliderHitArea';sliderHit.Position=UDim2.new(0,0,0,-10);sliderHit.Size=UDim2.new(1,0,0,24);sliderHit.BackgroundTransparency=1;sliderHit.Active=true;sliderHit.ZIndex=3;sliderHit.Parent=track
for i=1,#data.Steps do local tick=Instance.new('Frame');tick.Size=UDim2.fromOffset(2,9);tick.Position=UDim2.new((i-1)/(#data.Steps-1),-1,0,-2);tick.BackgroundColor3=Color3.fromRGB(162,173,165);tick.BorderSizePixel=0;tick.Parent=track end
local controls=Instance.new('Frame');controls.Position=UDim2.fromOffset(14,120);controls.Size=UDim2.new(1,-28,0,30);controls.BackgroundTransparency=1;controls.Parent=frame
local layout=Instance.new('UIListLayout');layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(0,6);layout.Parent=controls
local function button(text,fn)
 local b=Instance.new('TextButton');b.Text=text;b.Size=UDim2.new(1/7,-6,1,0);b.BackgroundColor3=Color3.fromRGB(52,67,70);b.TextColor3=Color3.fromRGB(237,233,219);b.Font=Enum.Font.GothamMedium;b.TextSize=11;b.BorderSizePixel=0;b.Parent=controls
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,5);c.Parent=b;b.Activated:Connect(fn);return b
end
local launcher=Instance.new('TextButton');launcher.Name='OpenChangeTour';launcher.Text='CHANGE TOUR';launcher.Size=UDim2.fromOffset(142,32);launcher.Position=UDim2.new(1,-320,0,16);launcher.BackgroundColor3=Color3.fromRGB(105,83,46);launcher.TextColor3=Color3.fromRGB(255,239,199);launcher.Font=Enum.Font.GothamMedium;launcher.TextSize=12;launcher.BorderSizePixel=0;launcher.Parent=gui
local lc=Instance.new('UICorner');lc.CornerRadius=UDim.new(0,7);lc.Parent=launcher
local selected=1;local token=0;local generation=0;local ready=false;local autoplay=false;local manual=nil;local tween=nil;local highlights={}
local choose,leave;local autoButton
local function setPhase(name,text)
 gui:SetAttribute('Phase',name);phase.Text=text
 phase.TextColor3=name=='AFTER'and Color3.fromRGB(154,218,187)or Color3.fromRGB(239,206,144)
end
local function clearHighlights()for _,h in highlights do h:Destroy()end;highlights={}end
local function cancel()
 token+=1;generation+=1;ready=false;remote:FireServer('CANCEL',token)
 if tween then tween:Cancel();tween=nil end;clearHighlights()
end
local function stopAuto()autoplay=false;if autoButton then autoButton.Text='PLAY TOUR'end end
local function highlight()
 clearHighlights();local root=workspace:FindFirstChild('SellCars_Dealership_Growth_V5');if not root then return end
 local f=root:FindFirstChild('10_Institution_Fidelity_R1');local col=f and f['05_Prestige_And_Public_Realm']['01_Collector'];if not col then return end
 local targets={};local focus=data.Steps[selected].Focus
 if focus=='Exhibits'then local base=root['09_Institution_Production_B']['02_Rear_Operations_And_Prestige']['06_Collector_Hall'];targets={base.Legacy_Snapshot_2,base.Legacy_Snapshot_5}
 elseif focus=='Roof'then for _,p in col.Craft_Gallery_Shell:GetChildren()do if p.Name=='RetainedSplitRoof'or p.Name=='LanternGlass'then table.insert(targets,p)end end
 elseif focus=='Materials'then for _,p in col.Craft_Gallery_Shell:GetChildren()do if p.Name=='WarmStoneFloor'or p.Name=='TimberSoffit'then table.insert(targets,p)end end
 else targets={col.Craft_Gallery_Shell}end
 for _,target in targets do local h=Instance.new('Highlight');h.Name='TourOnly_ChangedObject';h.Adornee=target;h.FillTransparency=1;h.OutlineTransparency=.1;h.OutlineColor=Color3.fromRGB(244,198,93);h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=gui;table.insert(highlights,h)end
 local mine=generation;task.delay(1.8,function()if generation==mine then clearHighlights()end end)
end
local function hideAdvanced()local a=pg:FindFirstChild('SellCarsV5JourneyReview');if a then a.Enabled=false end end
choose=function(index,wanted)
 cancel();selected=math.clamp(math.floor(index),1,#data.Steps);manual=wanted;frame.Visible=true;hideAdvanced()
 gui:SetAttribute('Step',selected);gui:SetAttribute('RequestToken',token)
 heading.Text=string.format('%d / %d   %s',selected,#data.Steps,data.Steps[selected].Title)
 caption.Text=data.Steps[selected].Caption;knob.Position=UDim2.new((selected-1)/(#data.Steps-1),-6,0,-5)
 setPhase('LOADING','Preparing the BEFORE state…')
 remote:FireServer('PREPARE',token,selected)
end
leave=function()
 stopAuto();cancel();frame.Visible=false;setPhase('PAUSED','Tour paused')
 workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then workspace.CurrentCamera.CameraSubject=h end
end
button('‹ PREVIOUS',function()stopAuto();choose(math.max(1,selected-1))end)
button('NEXT ›',function()stopAuto();choose(math.min(#data.Steps,selected+1))end)
button('REPLAY',function()stopAuto();choose(selected)end)
local function show(side)
 stopAuto();generation+=1;clearHighlights();manual=side
 if not ready or gui:GetAttribute('Phase')=='FRAMING'then choose(selected,side)else remote:FireServer('SHOW',token,selected,side)end
end
button('BEFORE',function()show('BEFORE')end);button('AFTER',function()show('AFTER')end)
autoButton=button('PLAY TOUR',function()if autoplay then stopAuto();generation+=1;manual='BEFORE';setPhase('PAUSED','Tour paused · Replay resumes this change')else autoplay=true;autoButton.Text='PAUSE';choose(selected)end end)
button('WALK / HIDE',leave)
launcher.Activated:Connect(function()stopAuto();choose(selected)end)
-- Local actions also provide an explicit smoke-check surface without virtual mouse injection.
local action=Instance.new('BindableEvent');action.Name='ReviewAction';action.Parent=gui
action.Event:Connect(function(name,value)if name=='SELECT'then stopAuto();choose(tonumber(value)or 1)elseif name=='BEFORE'or name=='AFTER'then show(name)elseif name=='WALK'then leave()elseif name=='OPEN'then choose(selected)end end)
local dragging=false;local draft=1
local function drag(x)
 draft=math.clamp(math.floor((x-track.AbsolutePosition.X)/track.AbsoluteSize.X*(#data.Steps-1)+1.5),1,#data.Steps)
 knob.Position=UDim2.new((draft-1)/(#data.Steps-1),-6,0,-5)
 phase.Text='Release to preview: '..data.Steps[draft].Title
end
sliderHit.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then stopAuto();cancel();dragging=true;drag(input.Position.X);gui:SetAttribute('Phase','SCRUBBING')end
end)
UIS.InputChanged:Connect(function(input)if dragging and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then drag(input.Position.X)end end)
UIS.InputEnded:Connect(function(input)if dragging and(input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch)then dragging=false;choose(draft)end end)
remote.OnClientEvent:Connect(function(kind,id,index,result)
 if id~=token then return end
 if kind=='CANCELLED'then leave();return end
 if index~=selected then return end
 if kind=='ERROR'then stopAuto();generation+=1;setPhase('ERROR','Could not apply this view: '..tostring(result):sub(-140));return end
 if result then gui:SetAttribute('ShownLevel',result.collectorLevel)end
 if kind=='READY'then
  ready=true;local mine=token;local gen=generation;setPhase('FRAMING','BEFORE · moving to the changed area…')
  local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable
  tween=TweenService:Create(cam,TweenInfo.new(data.MoveSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{CFrame=CFrame.lookAt(data.Steps[selected].Camera,data.Steps[selected].LookAt)})
  tween.Completed:Once(function(playback)
   if token~=mine or generation~=gen or playback~=Enum.PlaybackState.Completed then return end;tween=nil
   if manual then remote:FireServer('SHOW',token,selected,manual);return end
   local started=os.clock();gui:SetAttribute('BeforeHoldStarted',started);setPhase('BEFORE_HOLD','BEFORE · take a moment to look')
   task.spawn(function()
    while os.clock()-started<data.BeforeSeconds do
     if token~=mine or generation~=gen or not frame.Visible then return end
     phase.Text=string.format('BEFORE · change appears in %.1fs',math.max(0,data.BeforeSeconds-(os.clock()-started)));task.wait(.1)
    end
    if token==mine and generation==gen and frame.Visible then setPhase('REVEALING','Applying the change…');remote:FireServer('SHOW',token,selected,'AFTER')end
   end)
  end)
  tween:Play()
 elseif kind=='BEFORE'then setPhase('BEFORE','BEFORE · held here until you choose After or Replay')
 elseif kind=='AFTER'then
  gui:SetAttribute('LastRevealAt',os.clock());setPhase('AFTER','AFTER · same camera angle · Replay to watch again');highlight()
  if autoplay then local mine=token;local gen=generation;task.delay(data.AfterSeconds,function()
   if token~=mine or generation~=gen or not autoplay then return end
   if selected<#data.Steps then choose(selected+1)else stopAuto();setPhase('AFTER','Tour complete · Replay or walk around')end
  end)end
 end
end)
task.spawn(function()
 local advanced=pg:WaitForChild('SellCarsV5JourneyReview',10)
 if advanced then advanced:GetPropertyChangedSignal('Enabled'):Connect(function()if advanced.Enabled and frame.Visible then leave()end end)end
end)
-- Start with the previous state, not an already-upgraded object.
choose(1)

