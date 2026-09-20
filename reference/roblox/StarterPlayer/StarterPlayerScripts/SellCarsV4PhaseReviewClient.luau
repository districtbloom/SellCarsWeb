--!strict

-- Compact, hideable checkpoint 2D controller. It exists only for the active V3
-- traffic proof and deliberately avoids the large retired review dashboards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SellCarsV3FlowStress")
local command = remotes:WaitForChild("Command") :: RemoteEvent
local status = remotes:WaitForChild("Status") :: RemoteEvent

local old = player.PlayerGui:FindFirstChild("SellCarsV3FlowStressUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SellCarsV3FlowStressUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player.PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1,0)
panel.Position = UDim2.new(1,-18,0,18)
panel.Size = UDim2.fromOffset(540,276)
panel.BackgroundColor3 = Color3.fromRGB(22,26,31)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0,14)
padding.PaddingRight = UDim.new(0,14)
padding.PaddingTop = UDim.new(0,12)
padding.PaddingBottom = UDim.new(0,12)
padding.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-44,0,26)
title.Font = Enum.Font.GothamBold
title.Text = "DEALERSHIP PHASE REVIEW"
title.TextColor3 = Color3.fromRGB(236,240,244)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local hide = Instance.new("TextButton")
hide.AnchorPoint = Vector2.new(1,0)
hide.Position = UDim2.new(1,0,0,0)
hide.Size = UDim2.fromOffset(40,26)
hide.BackgroundColor3 = Color3.fromRGB(48,57,67)
hide.Text = "F3"
hide.TextColor3 = Color3.fromRGB(220,226,232)
hide.Font = Enum.Font.GothamBold
hide.TextSize = 13
hide.Parent = panel
Instance.new("UICorner", hide).CornerRadius = UDim.new(0,7)

local scenario = Instance.new("TextLabel")
scenario.BackgroundTransparency = 1
scenario.Position = UDim2.fromOffset(0,34)
scenario.Size = UDim2.new(1,0,0,22)
scenario.Font = Enum.Font.RobotoMono
scenario.Text = "DEDICATED · V4 REVIEW · waiting"
scenario.TextColor3 = Color3.fromRGB(110,214,255)
scenario.TextSize = 14
scenario.TextXAlignment = Enum.TextXAlignment.Left
scenario.Parent = panel

local function button(text, x, y, width)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x,y)
	b.Size = UDim2.fromOffset(width,32)
	b.BackgroundColor3 = Color3.fromRGB(49,59,70)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(235,238,241)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
	return b
end

local birth = button("BIRTH",0,64,92)
local working = button("WORKING",100,64,96)
local dedicated = button("DEDICATED",204,64,100)
local professional = button("PRO",312,64,92)
local institution = button("INSTITUTION",412,64,100)
local routeContract = button("ROUTE",600,64,44)
routeContract.Visible = false
local normal = button("NORMAL",0,104,158)
local mixed = button("MIXED",166,104,158)
local capacity = button("CAPACITY",332,104,180)
local pause = button("PAUSE",0,144,158)
local speed = button("SPEED 1×",166,144,158)
local reset = button("RESET",332,144,180)

local metrics = Instance.new("TextLabel")
metrics.BackgroundTransparency = 1
metrics.Position = UDim2.fromOffset(0,185)
metrics.Size = UDim2.new(1,0,0,66)
metrics.Font = Enum.Font.RobotoMono
metrics.Text = "active 0 · complete 0\nqueue 0 · conflicts 0"
metrics.TextColor3 = Color3.fromRGB(184,195,205)
metrics.TextSize = 13
metrics.TextXAlignment = Enum.TextXAlignment.Left
metrics.TextYAlignment = Enum.TextYAlignment.Top
metrics.Parent = panel

birth.Activated:Connect(function() command:FireServer("State","BIRTH") end)
working.Activated:Connect(function() command:FireServer("State","WORKING") end)
dedicated.Activated:Connect(function() command:FireServer("State","DEDICATED") end)
professional.Activated:Connect(function() command:FireServer("State","PROFESSIONAL") end)
institution.Activated:Connect(function() command:FireServer("State","INSTITUTION") end)
routeContract.Activated:Connect(function() command:FireServer("State","ROUTE_CONTRACT") end)
normal.Activated:Connect(function() command:FireServer("Start","NORMAL") end)
mixed.Activated:Connect(function() command:FireServer("Start","MIXED") end)
capacity.Activated:Connect(function() command:FireServer("Start","CAPACITY") end)
pause.Activated:Connect(function() command:FireServer("Pause") end)
reset.Activated:Connect(function() command:FireServer("Reset") end)

local speeds = {1,2,4}
local speedIndex = 1
speed.Activated:Connect(function()
	speedIndex = speedIndex % #speeds + 1
	speed.Text = "SPEED " .. speeds[speedIndex] .. "×"
	command:FireServer("Speed",speeds[speedIndex])
end)

local visible = true
local function toggle()
	visible = not visible
	panel.Visible = visible
end
hide.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F3 then toggle() end
end)

local phaseSource = {BIRTH="V3 REF", WORKING="V4", DEDICATED="V4 REVIEW", PROFESSIONAL="V3 REF", INSTITUTION="V3 REF"}
status.OnClientEvent:Connect(function(data)
	local phase = data.progression or "DEDICATED"
	scenario.Text = string.format("%s · %s · %s · %.1f×", phase, phaseSource[phase] or "REFERENCE", data.paused and "PAUSED" or data.running and "RUNNING" or "READY", data.speed or 1)
	metrics.Text = string.format("active %d · complete %d/%d\nqueue %d · max wait %.1fs · conflicts %d\nbottleneck %s · %.1fs", data.active or 0, data.completed or 0, data.spawned or 0, data.maxQueue or 0, data.maxWait or 0, data.conflicts or 0, data.bottleneckResource or "NONE", data.bottleneckWait or 0)
	pause.Text = data.paused and "RESUME" or "PAUSE"
end)

