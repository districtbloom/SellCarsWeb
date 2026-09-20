if not game.RunService:IsStudio() or game.PlaceId~=125334614375606 then return end
local Players=game:GetService('Players');local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='SellCarsV5JourneyReview';gui.ResetOnSpawn=false;gui.DisplayOrder=90;gui.Parent=player:WaitForChild('PlayerGui')
gui.Enabled=false -- The guided change tour is the default view; advanced controls stay available from the launcher.
local panel=Instance.new('Frame');panel.Size=UDim2.fromOffset(368,450);panel.Position=UDim2.new(1,-380,0,62);panel.BackgroundColor3=Color3.fromRGB(28,34,35);panel.BorderSizePixel=0;panel.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=panel
local function text(value,y,h,size,color)
 local l=Instance.new('TextLabel');l.Text=value;l.Position=UDim2.fromOffset(16,y);l.Size=UDim2.new(1,-32,0,h);l.BackgroundTransparency=1;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Top;l.TextColor3=color or Color3.fromRGB(225,221,207);l.Font=Enum.Font.GothamMedium;l.TextSize=size or 12;l.Parent=panel;return l
end
text('DEALERSHIP / PURCHASE JOURNEY',15,24,15)
local state=text('Connecting…',44,22,12,Color3.fromRGB(214,187,126))
local title=text('Starting yard',77,44,16)
local delta=text('Loading purchase descriptions…',125,104,12)
local note=text('Built: first 6 / Planned: 240 · visual proxy only',238,24,11)
local data,remote;local selected=6;local applied=6;local compact=false;local collectorStudy=false
-- Independent ScreenGui survives dismissal of the main review ScreenGui.
local launcherGui=Instance.new('ScreenGui');launcherGui.Name='SellCarsV5JourneyLauncher';launcherGui.ResetOnSpawn=false;launcherGui.DisplayOrder=91;launcherGui.Parent=player:WaitForChild('PlayerGui')
local reopen=Instance.new('TextButton');reopen.Name='ReopenDealershipPanel';reopen.Text='DEALERSHIP PANEL';reopen.Size=UDim2.fromOffset(156,32);reopen.Position=UDim2.new(1,-168,0,16);reopen.BackgroundColor3=Color3.fromRGB(61,74,76);reopen.TextColor3=Color3.fromRGB(235,229,208);reopen.Font=Enum.Font.GothamMedium;reopen.TextSize=12;reopen.BorderSizePixel=0;reopen.Parent=launcherGui
local reopenCorner=Instance.new('UICorner');reopenCorner.CornerRadius=UDim.new(0,7);reopenCorner.Parent=reopen
local function setPanelOpen(open)
 compact=false;gui.Enabled=open;panel.Visible=true;panel.Size=UDim2.fromOffset(368,568)
 for _,o in panel:GetChildren()do if o:IsA('GuiObject')then o.Visible=true end end
 if open and remote then remote:FireServer('STATUS')end
end
reopen.Activated:Connect(function()setPanelOpen(true)end)
-- Keep the restore control available even if the main ScreenGui is disabled elsewhere.
local reopenAction=Instance.new('BindableEvent');reopenAction.Name='OpenPanel';reopenAction.Parent=launcherGui;reopenAction.Event:Connect(function()setPanelOpen(true)end)
local function button(label,x,y,w,fn)
 local b=Instance.new('TextButton');b.Text=label;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,28);b.BackgroundColor3=Color3.fromRGB(61,74,76);b.BorderSizePixel=0;b.Font=Enum.Font.GothamMedium;b.TextSize=11;b.TextColor3=Color3.fromRGB(235,229,208);b.Parent=panel;b.Activated:Connect(fn);return b
end
local function showSelected()
 local e=data and data.Entries[selected]
 title.Text=selected==0 and '000 / Unclaimed ground' or string.format('%03d / %s',selected,e and e.title or 'Loading…')
 delta.Text=e and e.delta or 'Supported starting ground. No purchased work setting yet.'
 if selected>6 then note.Text='PLANNED / NOT BUILT — current scene is unchanged' else note.Text='Built steps 0–6 · environment preview, not purchases' end
end
local function request(action,value)
 if not remote then state.Text='Connecting to Studio preview…';return end
 remote:FireServer(action,value)
end
local function choose(n,apply)
 selected=math.clamp(math.floor(n+.5),0,240);showSelected()
 if apply and selected<=6 then request('STEP',selected)end
end
local function slider(y,maxValue,caption)
 text(caption,y-18,18,11)
 local bar=Instance.new('Frame');bar.Size=UDim2.fromOffset(332,8);bar.Position=UDim2.fromOffset(18,y);bar.BackgroundColor3=Color3.fromRGB(84,92,89);bar.BorderSizePixel=0;bar.Active=true;bar.Parent=panel
 local knob=Instance.new('Frame');knob.Size=UDim2.fromOffset(10,18);knob.Position=UDim2.new(math.min(selected,maxValue)/maxValue,-5,0,-5);knob.BackgroundColor3=Color3.fromRGB(215,185,120);knob.BorderSizePixel=0;knob.Parent=bar
 local dragging=false
 local function move(x) local v=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1);knob.Position=UDim2.new(v,-5,0,-5);choose(v*maxValue,false)end
 bar.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;move(input.Position.X)end end)
 UIS.InputChanged:Connect(function(input)if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then move(input.Position.X)end end)
 UIS.InputEnded:Connect(function(input)if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch)then dragging=false;choose(selected,true)end end)
 return function(n)knob.Position=UDim2.new(math.clamp(n/maxValue,0,1),-5,0,-5)end
end
local updateBuilt=slider(286,6,'BUILT SLICE  /  0–6')
local updateAll=slider(332,240,'WHOLE JOURNEY  /  0–240  ·  later steps are plan only')
button('PREVIOUS',16,355,83,function()choose(math.max(0,(applied==-1 and 6 or applied)-1),true)end)
button('NEXT',105,355,66,function()choose(math.min(6,(applied==-1 and 0 or applied)+1),true)end)
button('BIRTH 6',177,355,74,function()choose(6,true)end)
button('INSTITUTION',257,355,95,function()request('STEP','INSTITUTION')end)
local function camera(mode)
 local cam=workspace.CurrentCamera
 if mode=='WALK' then cam.CameraType=Enum.CameraType.Custom;return end
 cam.CameraType=Enum.CameraType.Scriptable
 if applied==-1 and (collectorStudy or mode=='TOOLS')then cam.CFrame=CFrame.lookAt(Vector3.new(3190,65,357),Vector3.new(3105,28,431))
 elseif applied==-1 then cam.CFrame=CFrame.lookAt(Vector3.new(3190,95,180),Vector3.new(3105,12,350))
 elseif mode=='YARD' then cam.CFrame=CFrame.lookAt(Vector3.new(3126,100,37),Vector3.new(3038,2,111))
 else cam.CFrame=CFrame.lookAt(Vector3.new(3058,9,109),Vector3.new(3033,4,130))end
end
button('YARD',16,389,63,function()camera('YARD')end);button('TOOLS',85,389,63,function()camera('TOOLS')end);button('WALK',154,389,63,function()camera('WALK')end)
button('CAR: WORK',223,389,129,function()request('CAR','WORK')end)
button('CAR: INTAKE',16,423,106,function()request('CAR','INTAKE')end);button('CAR: SALES',128,423,106,function()request('CAR','SALES')end)
button('HIDE',240,423,112,function()setPanelOpen(false)end)
for i,v in ipairs({{'B24',24},{'W64',64},{'D140',140},{'P196',196},{'I240',240}})do button(v[1],16+(i-1)*68,465,62,function()choose(v[2],false);updateAll(selected)end)end
text('Chapter jumps above read the unbuilt plan.',496,12,10)
button('PRO: COLLECTOR STUDY',16,514,336,function()request('STEP','PRO_COLLECTOR')end)
text('Collector only · remaining campus stays Institution',548,14,10)
-- Close hides only this panel; the separate launcher remains available.
local expand=Instance.new('TextButton');expand.Size=UDim2.fromOffset(34,24);expand.Position=UDim2.new(1,-40,0,10);expand.Text='×';expand.TextSize=18;expand.BackgroundTransparency=1;expand.TextColor3=Color3.new(1,1,1);expand.Parent=panel
expand.Activated:Connect(function()setPanelOpen(false)end)
panel.Size=UDim2.fromOffset(368,568)
task.spawn(function()
 data=require(game.ReplicatedStorage:WaitForChild('SellCarsV5JourneyData'));showSelected()
 remote=game.ReplicatedStorage:WaitForChild('SellCarsV5JourneyPreview')
 remote.OnClientEvent:Connect(function(ok,result,fallback)
  local s=ok and result or fallback
  if s then
   collectorStudy=s.collectorStudy==true;applied=s.step;state.Text=collectorStudy and 'PROFESSIONAL / COLLECTOR STUDY ONLY' or applied==-1 and 'INSTITUTION BENCHMARK / static comparison' or string.format('SHOWING STEP %03d / 006 BUILT',applied);updateBuilt(math.max(applied,0));updateAll(selected)
   if collectorStudy and s.collectorLevel and s.collectorLevel>0 then title.Text='COLLECTOR / intermediate tour state';delta.Text='An intermediate guided comparison is active. Use Change Tour for the before/after sequence, or Institution for the complete endpoint.';note.Text='Guided comparison · not a full Professional chapter'
   elseif collectorStudy then title.Text='Same gallery / earlier architecture';delta.Text='Four exhibits, lower glazing and roof, a closed roof cassette instead of the raised lantern, concrete and coated metal. Original deck, column bases and access remain. Other departments are still Institution.';note.Text='Scoped structural/material proof · not full Professional'
   elseif applied==-1 then title.Text='INSTITUTION / protected reference';delta.Text='The complete existing dealership, restored intact for comparison. This does not mean the 240-purchase construction sequence is built.';note.Text='Static benchmark · original traffic/occupation paused'
   else showSelected()end
   if workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then camera('YARD')end
  end
  if not ok then note.Text='Not applied: '..tostring(result):match('[^\n]+$')end
 end)
 request('STATUS')
end)

