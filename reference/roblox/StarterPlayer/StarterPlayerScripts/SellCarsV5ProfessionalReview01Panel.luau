if not game:GetService("RunService"):IsStudio() or game.PlaceId~=125334614375606 then return end
local player=game.Players.LocalPlayer
-- Render controls even if Studio's server starts slowly. Never silently abandon
-- the panel because the review remote missed a short startup timeout.
local remote=game.ReplicatedStorage:FindFirstChild("SellCarsV5ProfessionalReview01")
local root=workspace:WaitForChild("SellCars_Dealership_Growth_V5")
local gui=Instance.new("ScreenGui");gui.Name="SellCarsV5ChapterReview";gui.ResetOnSpawn=false;gui.DisplayOrder=80;gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame");panel.Size=UDim2.fromOffset(302,205);panel.Position=UDim2.new(1,-318,0,78);panel.BackgroundColor3=Color3.fromRGB(25,33,39);panel.BackgroundTransparency=.08;panel.BorderSizePixel=0;panel.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=panel
local function label(text,y,size,color)
 local t=Instance.new("TextLabel");t.Text=text;t.Size=UDim2.new(1,-24,0,size);t.Position=UDim2.fromOffset(12,y);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.TextSize=size==20 and 14 or 11;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextColor3=color or Color3.fromRGB(225,222,210);t.TextWrapped=true;t.Parent=panel;return t
end
label("DEALERSHIP / CHAPTER REVIEW",12,20)
local status=label("",38,20,Color3.fromRGB(213,186,124))
local function button(text,x,y,w,fn)
 local b=Instance.new("TextButton");b.Text=text;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,32);b.BackgroundColor3=Color3.fromRGB(59,74,82);b.BorderSizePixel=0;b.Font=Enum.Font.GothamMedium;b.TextSize=11;b.TextColor3=Color3.fromRGB(235,233,224);b.Parent=panel
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b;b.Activated:Connect(fn);return b
end
local function requestChapter(chapter)
 remote=game.ReplicatedStorage:FindFirstChild("SellCarsV5ProfessionalReview01")
 if not remote then status.Text="Connecting to chapter controls…";return end
 remote:FireServer(chapter)
end
button("PROFESSIONAL",12,64,135,function()requestChapter("PROFESSIONAL")end)
button("INSTITUTION",155,64,135,function()requestChapter("INSTITUTION")end)
local views={FRONT={Vector3.new(3105,18,-44),Vector3.new(3105,9,50)},WORKSHOP={Vector3.new(3053,10,166),Vector3.new(3008,7,197)},CAMPUS={Vector3.new(3190,95,180),Vector3.new(3105,12,350)}}
for i,name in {"FRONT","WORKSHOP","CAMPUS"} do button(name,12+(i-1)*94,104,88,function()
 local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=CFrame.lookAt(views[name][1],views[name][2])
end) end
button("WALK",12,143,88,function()workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end)
label("Visual review only · earlier chapters unbuilt\nTwo bays / six sales · no purchase logic",178,24)
local function refresh()status.Text=root:GetAttribute("VisualReviewChapter") or "INSTITUTION" end
root:GetAttributeChangedSignal("VisualReviewChapter"):Connect(refresh);refresh()
task.spawn(function()
 remote=game.ReplicatedStorage:WaitForChild("SellCarsV5ProfessionalReview01")
 remote.OnClientEvent:Connect(function(ok,result)if not ok then status.Text="Review paused — edited target";warn(result)else refresh()end end)
 refresh()
end)

