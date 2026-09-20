local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Motion = {}
local reducedMotion = false

local function duration(seconds)
	if reducedMotion then
		return math.min(seconds, 0.06)
	end
	return seconds
end

function Motion.SetReducedMotion(enabled)
	reducedMotion = enabled == true
end

function Motion.IsReducedMotion()
	return reducedMotion
end

function Motion.Tween(object, seconds, properties, style, direction)
	local tween = TweenService:Create(object, TweenInfo.new(
		duration(seconds),
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	), properties)
	tween:Play()
	return tween
end

function Motion.AttachPress(button, options)
	if button:GetAttribute("FlatWorkshopPressAttached") then return end
	button:SetAttribute("FlatWorkshopPressAttached", true)
	options = options or {}

	local pressedScale = options.pressedScale or 0.97
	local scale = button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = button
	end

	local function press()
		Motion.Tween(scale, options.pressIn or 0.07, { Scale = pressedScale }, Enum.EasingStyle.Quad)
	end

	local function release()
		Motion.Tween(scale, options.pressOut or 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			press()
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			release()
		end
	end)

	if UserInputService.MouseEnabled then
		button.MouseEnter:Connect(function()
			Motion.Tween(button, 0.12, { BackgroundTransparency = math.max(0, button.BackgroundTransparency - 0.04) })
		end)
		button.MouseLeave:Connect(function()
			release()
		end)
	end
end

function Motion.Pulse(scale, amount)
	local token = (scale:GetAttribute("PulseToken") or 0) + 1
	scale:SetAttribute("PulseToken", token)
	Motion.Tween(scale, 0.10, { Scale = amount or 1.08 }, Enum.EasingStyle.Back)
	task.delay(duration(0.12), function()
		if scale.Parent and scale:GetAttribute("PulseToken") == token then
			Motion.Tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
end

return Motion


