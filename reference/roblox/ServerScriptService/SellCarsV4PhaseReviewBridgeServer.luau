local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local v3 = workspace:WaitForChild("SellCars_Dealership_RouteGreybox_V3")
local v4 = workspace:WaitForChild("SellCars_Dealership_Growth_V4")
local dedicatedLayer = v4:WaitForChild("06_Dedicated_A_Production")
local remote = ReplicatedStorage:WaitForChild("SellCarsV3FlowStress")
local command = remote:WaitForChild("Command")

local function setEnabled(instance, enabled)
	if instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") or instance:IsA("Light") then
		instance.Enabled = enabled
	end
end

local function hideV3()
	for _, descendant in ipairs(v3:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		else
			setEnabled(descendant, false)
		end
	end
end

local function applyV4Part(part, phase)
	if phase == nil or (phase == "WORKING" and part:IsDescendantOf(dedicatedLayer)) then
		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		return
	end

	local prefix = phase == "WORKING" and "V4DedicatedSaved" or "PhaseReviewDedicated"
	local transparency = part:GetAttribute(prefix .. "Transparency")
	local canCollide = part:GetAttribute(prefix .. "CanCollide")
	local canQuery = part:GetAttribute(prefix .. "CanQuery")
	local canTouch = part:GetAttribute(prefix .. "CanTouch")
	if typeof(transparency) ~= "number" then transparency = part:GetAttribute("PhaseReviewDedicatedTransparency") end
	if typeof(canCollide) ~= "boolean" then canCollide = part:GetAttribute("PhaseReviewDedicatedCanCollide") end
	if typeof(canQuery) ~= "boolean" then canQuery = part:GetAttribute("PhaseReviewDedicatedCanQuery") end
	if typeof(canTouch) ~= "boolean" then canTouch = part:GetAttribute("PhaseReviewDedicatedCanTouch") end
	part.Transparency = typeof(transparency) == "number" and transparency or 0
	part.CanCollide = typeof(canCollide) == "boolean" and canCollide or false
	part.CanQuery = typeof(canQuery) == "boolean" and canQuery or part.Transparency < 1
	part.CanTouch = typeof(canTouch) == "boolean" and canTouch or false
	if part.Transparency >= 1 then
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
end

local function showV4(phase)
	for _, descendant in ipairs(v4:GetDescendants()) do
		if descendant:IsA("BasePart") then
			applyV4Part(descendant, phase)
		elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") or descendant:IsA("Light") then
			local enabled = false
			if phase ~= nil and not (phase == "WORKING" and descendant:IsDescendantOf(dedicatedLayer)) then
				if phase == "WORKING" and descendant:GetAttribute("V4DedicatedSavedEnabled") ~= nil then
					enabled = descendant:GetAttribute("V4DedicatedSavedEnabled") == true
				else
					enabled = descendant:GetAttribute("PhaseReviewDedicatedEnabled") == true
				end
			end
			descendant.Enabled = enabled
		end
	end
	if phase then v4:SetAttribute("ReviewPhase", phase) end
end

local function applyPhase(phase)
	if phase == "WORKING" or phase == "DEDICATED" then
		showV4(phase)
		hideV3()
		v4:SetAttribute("ReviewSource", "V4_ACTIVE_BUILD")
	else
		showV4(nil)
		v4:SetAttribute("ReviewPhase", phase)
		v4:SetAttribute("ReviewSource", "V3_PRESERVED_REFERENCE")
	end
end

command.OnServerEvent:Connect(function(_player, action, value)
	if action == "State" and typeof(value) == "string" then
		task.defer(function() applyPhase(value) end)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.delay(0.75, function()
		if player.Parent then applyPhase("DEDICATED") end
	end)
end)

task.delay(0.75, function() applyPhase("DEDICATED") end)

