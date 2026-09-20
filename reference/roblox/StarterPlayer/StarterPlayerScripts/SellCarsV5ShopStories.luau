-- Studio-only character ambience and curated finished-state story tour.
-- One 20Hz controller, <=40 authored moving pieces, no physics/server effects.
if not game.RunService:IsStudio()or game.PlaceId~=125334614375606 then return end
local player=game.Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui');local journey=pg:WaitForChild('SellCarsV5FullJourney',30);if not journey then return end
local action=journey:WaitForChild('ReviewAction',30);if not action then return end
local gui=Instance.new('ScreenGui');gui.Name='SellCarsV5ShopStories';gui.ResetOnSpawn=false;gui.DisplayOrder=103;gui.Parent=pg
local function button(parent,name,text,x,y,w,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Text=text;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,30);b.BackgroundColor3=Color3.fromRGB(99,62,39);b.TextColor3=Color3.fromRGB(240,220,175);b.Font=Enum.Font.GothamBold;b.TextSize=12;b.BorderSizePixel=0;b.Parent=parent;b.Activated:Connect(fn);return b
end
local card=Instance.new('Frame');card.Name='StoryCard';card.Position=UDim2.fromOffset(16,98);card.Size=UDim2.fromOffset(430,154);card.BackgroundColor3=Color3.fromRGB(26,36,36);card.BackgroundTransparency=.06;card.Visible=false;card.Parent=gui
local title=Instance.new('TextLabel');title.Position=UDim2.fromOffset(12,8);title.Size=UDim2.new(1,-24,0,24);title.BackgroundTransparency=1;title.TextColor3=Color3.fromRGB(234,190,104);title.Font=Enum.Font.GothamBold;title.TextSize=15;title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=card
local body=title:Clone();body.Name='Story';body.Position=UDim2.fromOffset(12,37);body.Size=UDim2.new(1,-24,0,68);body.TextSize=13;body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top;body.TextColor3=Color3.fromRGB(234,226,207);body.Parent=card
local tour={
 {'Owner / the obsession','P185_Unfinished_Ideas_Wall',Vector3.new(3212,9,85),Vector3.new(3226,8,83)},
 {'The original sign','P024_First_Handmade_Sign',Vector3.new(3173,10,54),Vector3.new(3158,9,51)},
 {'Salvaged-parts social club','P228_Tailgate_Social_Club',Vector3.new(3191,11,163),Vector3.new(3176,4.5,151)},
 {'Never finished. Always ours.','P225_Garage_Yard_Shop_Mural',Vector3.new(3193,10,140),Vector3.new(3178,9,125)},
 {'Wash / the rescued mascot','P176_Wash_Craft_Obsession',Vector3.new(2994,10,153),Vector3.new(2984,7.8,145)},
 {'Mechanical / lessons kept','P158_Mechanical_Craft_Obsession',Vector3.new(2991,10,203),Vector3.new(2984,8,203)},
 {'Body / metal as a medium','P162_Body_Craft_Obsession',Vector3.new(3007,10.5,284.5),Vector3.new(2995,9,284.5)},
 {'Tune / one more run','P169_Tune_Craft_Obsession',Vector3.new(2994,11,354),Vector3.new(2984,9,347)},
 {'Paint / fearless colour','P214_Paint_Pinstripe_Flagship',Vector3.new(3219,14,325),Vector3.new(3226,12,318)},
 {'Detail / the last one percent','P178_Detail_Craft_Obsession',Vector3.new(3215,10,285),Vector3.new(3226,8,279)},
 {'Photo / our own mythology','P181_Photo_Craft_Obsession',Vector3.new(3214,11,209),Vector3.new(3226,9,217)},
 {'Good cars. Good company.','P145_Customer_Club_Pitboard',Vector3.new(3048,9,43),Vector3.new(3033,8,50)},
 {'Parts / organised oddities','P151_Parts_Of_Unknown_Origin',Vector3.new(2995,11,468),Vector3.new(2983,9,475)},
 {'The crew made this','P156_Crew_Wall_Of_Fame',Vector3.new(3216,10,475),Vector3.new(3223,9,475)},
 {'Founding craft','P232_Founding_Spanner_Exhibit',Vector3.new(3075,8,504),Vector3.new(3064,5,510)},
 {'Shop-made public art','P240_Shop_Built_Windmill',Vector3.new(3118,15,346),Vector3.new(3091,8,359)},
}
local active=false;local starting=false;local index=1;local generation=0;local movement=true;local focused=true
local function root()local r=workspace:FindFirstChild('SellCars_Dealership_FullJourney');return r and r:FindFirstChild('ST_Character')end
local function close()generation+=1;active=false;starting=false;card.Visible=false;gui:SetAttribute('TourActive',false)end
local function view(n)
 index=(n-1)%#tour+1;local v=tour[index];local r=root();local m=r and r:FindFirstChild(v[2]);if not m then close();return end
 local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable;cam.FieldOfView=64;cam.CFrame=CFrame.lookAt(v[3],v[4]);journey:SetAttribute('SolidRoofRecommended',false)
 title.Text=string.format('%02d / %02d · %s',index,#tour,v[1]);body.Text=m:GetAttribute('Story')..'\nFinished Institution · added at pad '..m:GetAttribute('FirstStep')..'.'
 card.Visible=true;gui:SetAttribute('TourIndex',index);gui:SetAttribute('StoryId',m:GetAttribute('StoryId'));gui:SetAttribute('TourActive',true)
end
local function start()
 close();starting=true;local mine=generation;action:Fire('CHAPTER',240)
 task.spawn(function()
  local began=os.clock();while os.clock()-began<8 do
   if mine~=generation then return end
   if journey:GetAttribute('ShownStep')==240 and journey:GetAttribute('Phase')=='AFTER'then starting=false;active=true;view(1);return end
   task.wait(.05)
  end;starting=false
 end)
end
local launcher=button(gui,'OpenStories','SHOP STORIES',16,56,148,start)
button(card,'PreviousStory','‹ PREVIOUS',12,112,126,function()if active then view(index-1)end end)
button(card,'NextStory','NEXT STORY ›',146,112,142,function()if active then view(index+1)end end)
button(card,'CloseStories','CLOSE',296,112,120,close)
local motionButton;motionButton=button(gui,'ToggleMotion','MOTION: ON',172,56,124,function()movement=not movement;motionButton.Text=movement and'MOTION: ON'or'MOTION: OFF';gui:SetAttribute('MotionEnabled',movement)end);gui:SetAttribute('MotionEnabled',true)
local qa=Instance.new('BindableEvent');qa.Name='StoryAction';qa.Parent=gui;qa.Event:Connect(function(name,n)if name=='START'then start()elseif name=='NEXT'and active then view(index+1)elseif name=='VIEW'and active then view(n)elseif name=='CLOSE'then close()end end)
local connections={}
table.insert(connections,journey:GetAttributeChangedSignal('Phase'):Connect(function()if active then local phase=journey:GetAttribute('Phase');if phase=='LOADING'or phase=='PAUSED'or phase=='BENCHMARK'then close()end end end))
table.insert(connections,journey:GetAttributeChangedSignal('WalkingJourney'):Connect(function()if journey:GetAttribute('WalkingJourney')then close()end end))
table.insert(connections,game.UserInputService.WindowFocused:Connect(function()focused=true end))
table.insert(connections,game.UserInputService.WindowFocusReleased:Connect(function()focused=false end))
local tracked={};local lettering={};local knownRoot;local elapsed=0;local time=0;local totalMoving=0;local letteringTime=1;local dirty=false;local addedConnection
local function discover(r)
 if addedConnection then addedConnection:Disconnect();addedConnection=nil end
 tracked={};lettering={};knownRoot=r;dirty=false;if not r then return end
 addedConnection=r.DescendantAdded:Connect(function()dirty=true end)
 for _,g in r:GetDescendants()do if g:IsA('SurfaceGui')and g.Parent:IsA('BasePart')then table.insert(lettering,g)end end
 local candidates=r:GetDescendants();local campus=r.Parent:FindFirstChild('ACA_CampusArt');if campus then for _,p in campus:GetDescendants()do table.insert(candidates,p)end end
 for _,p in candidates do if p:IsA('BasePart')and p:GetAttribute('ST_Motion')and (p:GetAttribute('FJ_Retire')or 999)>240 and #tracked<96 then
  local pivot=p:GetAttribute('ST_MotionPivot');table.insert(tracked,{p=p,kind=p:GetAttribute('ST_Motion'),pivot=pivot,pose=pivot:ToObjectSpace(p:GetAttribute('FJ_CF')),speed=p:GetAttribute('ST_Speed')or 1})
 end end;gui:SetAttribute('TrackedMotionParts',#tracked)
end
local heartbeat=game.RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;local tick=elapsed;elapsed=0
 local r=root();if r~=knownRoot then discover(r)end
 letteringTime+=tick;if letteringTime>=1 then letteringTime=0;if dirty then discover(r)end;local camera=workspace.CurrentCamera;for _,g in lettering do if g.Parent then g.Enabled=g.Parent.Transparency<.95 and(camera.CFrame.Position-g.Parent.Position).Magnitude<140 end end end
 if not movement or not focused or journey:GetAttribute('Phase')~='AFTER'then return end;time+=tick
 local cam=workspace.CurrentCamera;local step=journey:GetAttribute('ShownStep')or 240;totalMoving=0
 for _,a in tracked do local p=a.p;if p.Parent and p.Transparency<.95 and(cam.CFrame.Position-p.Position).Magnitude<100 then
  local offset=step>=(p:GetAttribute('FJ_MoveAt')or 999)and(p:GetAttribute('FJ_Move')or Vector3.zero)or Vector3.zero
  local rot=a.kind=='SWAY'and CFrame.Angles(0,0,math.sin(time*a.speed)*.07)or a.kind=='RECORD'and CFrame.Angles(0,time*a.speed,0)or CFrame.Angles(0,0,time*a.speed)
  p.CFrame=(a.pivot+offset)*rot*a.pose;totalMoving+=1
 end end;gui:SetAttribute('ActiveMotionParts',totalMoving)
end)
gui.Destroying:Connect(function()heartbeat:Disconnect();if addedConnection then addedConnection:Disconnect()end;for _,c in connections do c:Disconnect()end end)

