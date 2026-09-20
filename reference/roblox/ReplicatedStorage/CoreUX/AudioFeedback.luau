local SoundService = game:GetService("SoundService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")

local AudioFeedback = {}
AudioFeedback.__index = AudioFeedback

local PALETTE = {
	Click = {
		group = "UI", channel = "ui", cooldown = 0.035,
		layers = { { id = "rbxassetid://88442833509532", volume = 0.18, speed = 1.08, maxDuration = 0.12 } },
	},
	Preview = {
		group = "UI", channel = "preview", cooldown = 0.16,
		layers = { { id = "rbxassetid://87681552750899", volume = 0.14, speed = 1.28, maxDuration = 0.34 } },
	},
	PadPreview = {
		group = "World", channel = "padPreview", cooldown = 0.22,
		layers = { { id = "rbxassetid://87681552750899", volume = 0.18, speed = 1.12, maxDuration = 0.42 } },
	},
	Confirm = {
		group = "UI", channel = "confirm", cooldown = 0.12,
		layers = {
			{ id = "rbxassetid://88442833509532", volume = 0.18, speed = 0.94, maxDuration = 0.12 },
			{ id = "rbxassetid://87681552750899", volume = 0.12, speed = 1.16, delay = 0.025, maxDuration = 0.32 },
		},
	},
	PadCommit = {
		group = "World", channel = "worldAction", cooldown = 0.28, interrupt = true,
		layers = {
			{ id = "rbxassetid://88442833509532", volume = 0.20, speed = 0.82, maxDuration = 0.12 },
			{ id = "rbxassetid://87681552750899", volume = 0.13, speed = 0.92, delay = 0.03, maxDuration = 0.36 },
		},
	},
	Notify = {
		group = "UI", channel = "notify", cooldown = 0.22, interrupt = true,
		layers = { { id = "rbxassetid://87681552750899", volume = 0.20, speed = 1.13, maxDuration = 0.52 } },
	},
	NotifyGood = {
		group = "UI", channel = "notify", cooldown = 0.22, interrupt = true,
		layers = { { id = "rbxassetid://87681552750899", volume = 0.21, speed = 1.28, maxDuration = 0.55 } },
	},
	Success = {
		group = "UI", channel = "reward", cooldown = 0.65, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://87681552750899", volume = 0.18, speed = 1.22, maxDuration = 0.50 },
			{ id = "rbxassetid://1839881844", volume = 0.18, speed = 1.05, delay = 0.06, maxDuration = 1.45 },
		},
	},
	Error = {
		group = "UI", channel = "notify", cooldown = 0.28, interrupt = true,
		layers = {
			{ id = "rbxassetid://88442833509532", volume = 0.24, speed = 0.68, maxDuration = 0.12 },
			{ id = "rbxassetid://87681552750899", volume = 0.10, speed = 0.72, delay = 0.04, maxDuration = 0.35 },
		},
	},
	Spend = {
		group = "UI", channel = "money", cooldown = 0.30,
		layers = { { id = "rbxassetid://1319346243", volume = 0.26, speed = 0.82, maxDuration = 0.80 } },
	},
	Cash = {
		group = "UI", channel = "money", cooldown = 0.42,
		layers = { { id = "rbxassetid://1319346243", volume = 0.32, speed = 1.06, maxDuration = 1.15 } },
	},
	Profit = {
		group = "UI", channel = "reward", cooldown = 0.65, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://1319346243", volume = 0.38, speed = 1.08, maxDuration = 1.18 },
			{ id = "rbxassetid://1839881844", volume = 0.16, speed = 1.12, delay = 0.10, maxDuration = 1.35 },
		},
	},
	RepairBody = {
		group = "World", channel = "repair", cooldown = 0.30, interrupt = true,
		layers = {
			{ id = "rbxassetid://9118043348", volume = 0.32, speed = 0.88, maxDuration = 0.82 },
			{ id = "rbxassetid://9116654531", volume = 0.11, speed = 0.82, delay = 0.05, maxDuration = 0.48 },
		},
	},
	RepairWheels = {
		group = "World", channel = "repair", cooldown = 0.30, interrupt = true,
		layers = {
			{ id = "rbxassetid://9118043348", volume = 0.31, speed = 1.00, maxDuration = 0.82 },
			{ id = "rbxassetid://9116654531", volume = 0.10, speed = 0.96, delay = 0.05, maxDuration = 0.45 },
		},
	},
	RepairEngine = {
		group = "World", channel = "repair", cooldown = 0.30, interrupt = true,
		layers = {
			{ id = "rbxassetid://9118043348", volume = 0.31, speed = 1.12, maxDuration = 0.82 },
			{ id = "rbxassetid://9116654531", volume = 0.10, speed = 1.08, delay = 0.04, maxDuration = 0.42 },
		},
	},
	Repair = {
		group = "World", channel = "repair", cooldown = 0.30, interrupt = true,
		layers = { { id = "rbxassetid://9118043348", volume = 0.32, speed = 1.00, maxDuration = 0.82 } },
	},
	Build = {
		group = "World", channel = "worldAction", cooldown = 0.55, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://9120888261", volume = 0.36, speed = 0.98, maxDuration = 1.14 },
			{ id = "rbxassetid://9116654531", volume = 0.13, speed = 0.90, delay = 0.08, maxDuration = 0.55 },
		},
	},
	Hire = {
		group = "UI", channel = "reward", cooldown = 0.65, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://88442833509532", volume = 0.18, speed = 0.92, maxDuration = 0.12 },
			{ id = "rbxassetid://1839881844", volume = 0.17, speed = 1.10, delay = 0.07, maxDuration = 1.28 },
		},
	},
	Phone = {
		group = "UI", channel = "phone", cooldown = 1.4, interrupt = true,
		layers = { { id = "rbxassetid://9117305259", volume = 0.25, speed = 1.04, maxDuration = 2.10 } },
	},
	Engine = {
		group = "World", channel = "vehicle", cooldown = 1.1, interrupt = true,
		layers = { { id = "rbxassetid://269606471", volume = 0.32, speed = 1.00, maxDuration = 1.95 } },
	},
	Rare = {
		group = "UI", channel = "cinematic", cooldown = 1.2, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://1844016113", volume = 0.30, speed = 1.00, maxDuration = 2.55 },
			{ id = "rbxassetid://87681552750899", volume = 0.13, speed = 0.82, delay = 0.08, maxDuration = 0.48 },
		},
	},
	Deal = {
		group = "UI", channel = "deal", cooldown = 0.75, interrupt = true, duckNotify = true,
		layers = {
			{ id = "rbxassetid://88442833509532", volume = 0.20, speed = 0.76, maxDuration = 0.12 },
			{ id = "rbxassetid://87681552750899", volume = 0.16, speed = 0.92, delay = 0.04, maxDuration = 0.48 },
			{ id = "rbxassetid://1839881844", volume = 0.13, speed = 0.96, delay = 0.12, maxDuration = 1.12 },
		},
	},
}

local function resolveEmitter(anchor)
	if typeof(anchor) ~= "Instance" then return SoundService end
	if anchor:IsA("SoundService") or anchor:IsA("BasePart") or anchor:IsA("Attachment") then return anchor end
	if anchor:IsA("ProximityPrompt") then return resolveEmitter(anchor.Parent) end
	if anchor:IsA("Model") then
		return anchor.PrimaryPart or anchor:FindFirstChildWhichIsA("BasePart", true) or SoundService
	end
	return anchor:FindFirstAncestorWhichIsA("BasePart") or SoundService
end

function AudioFeedback.new()
	local self = setmetatable({
		lastPlayed = {},
		connections = {},
		activeByChannel = {},
		activeSounds = {},
		quietNotifyUntil = 0,
		destroyed = false,
	}, AudioFeedback)

	local function soundGroup(name, volume)
		local group = SoundService:FindFirstChild(name)
		if not group then
			group = Instance.new("SoundGroup")
			group.Name = name
			group.Parent = SoundService
		end
		group.Volume = volume
		return group
	end
	self.groups = {
		UI = soundGroup("CoreUX_UI", 0.76),
		World = soundGroup("CoreUX_World", 0.72),
	}

	-- Prime the small SFX palette off the main thread so first-use cues do not arrive late.
	task.spawn(function()
		local staged, seen = {}, {}
		for _, definition in pairs(PALETTE) do
			for _, layer in ipairs(definition.layers or {}) do
				if layer.id and not seen[layer.id] then
					seen[layer.id] = true
					local sound = Instance.new("Sound")
					sound.Name = "CoreUX_Preload"
					sound.SoundId = layer.id
					sound.Volume = 0
					sound.Parent = SoundService
					table.insert(staged, sound)
				end
			end
		end
		pcall(function() ContentProvider:PreloadAsync(staged) end)
		for _, sound in ipairs(staged) do sound:Destroy() end
	end)

	table.insert(self.connections, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		local world = workspace:FindFirstChild("CoreUXPrototype")
		if world and prompt:IsDescendantOf(world) then
			self:PlayAt("Preview", prompt)
		end
	end))
	table.insert(self.connections, ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local world = workspace:FindFirstChild("CoreUXPrototype")
		if world and prompt:IsDescendantOf(world) then
			self:PlayAt("Confirm", prompt)
		end
	end))

	return self
end

function AudioFeedback:_unregister(sound, channel)
	for index = #self.activeSounds, 1, -1 do
		if self.activeSounds[index] == sound then table.remove(self.activeSounds, index) end
	end
	local channelSounds = self.activeByChannel[channel]
	if channelSounds then
		for index = #channelSounds, 1, -1 do
			if channelSounds[index] == sound then table.remove(channelSounds, index) end
		end
	end
end

function AudioFeedback:_stopChannel(channel)
	local sounds = self.activeByChannel[channel] or {}
	self.activeByChannel[channel] = {}
	for index = #sounds, 1, -1 do
		local sound = sounds[index]
		if sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
		self:_unregister(sound, channel)
	end
end

function AudioFeedback:_spawnLayer(name, definition, layer, channel, anchor)
	local function spawnSound()
		if self.destroyed then return end
		while #self.activeSounds >= 9 do
			local oldest = table.remove(self.activeSounds, 1)
			if oldest and oldest.Parent then oldest:Stop() oldest:Destroy() end
		end

		local sound = Instance.new("Sound")
		sound.Name = "CoreUX_" .. name
		sound.SoundId = layer.id
		sound.Volume = layer.volume or 0.3
		local jitter = layer.jitter or definition.jitter or 0
		sound.PlaybackSpeed = (layer.speed or 1) * (1 + ((math.random() * 2 - 1) * jitter))
		sound.SoundGroup = self.groups[definition.group or "UI"]
		local emitter = resolveEmitter(anchor)
		if emitter ~= SoundService then
			sound.RollOffMode = Enum.RollOffMode.Inverse
			sound.RollOffMinDistance = 6
			sound.RollOffMaxDistance = 55
			sound.EmitterSize = 5
		end
		sound.Parent = emitter

		self.activeByChannel[channel] = self.activeByChannel[channel] or {}
		table.insert(self.activeByChannel[channel], sound)
		table.insert(self.activeSounds, sound)
		local endedConnection
		endedConnection = sound.Ended:Connect(function()
			if endedConnection then endedConnection:Disconnect() endedConnection = nil end
			self:_unregister(sound, channel)
			if sound.Parent then sound:Destroy() end
		end)
		sound:Play()

		local maxDuration = layer.maxDuration or definition.maxDuration
		if maxDuration then
			task.delay(maxDuration, function()
				if sound.Parent then
					sound:Stop()
					self:_unregister(sound, channel)
					sound:Destroy()
				end
			end)
		end
		Debris:AddItem(sound, math.max(4, (maxDuration or 3) + 1))
	end

	if (layer.delay or 0) > 0 then task.delay(layer.delay, spawnSound) else spawnSound() end
end

function AudioFeedback:_play(name, anchor)
	local definition = PALETTE[name]
	if not definition or self.destroyed then return false end
	local now = os.clock()
	if (name == "Notify" or name == "NotifyGood") and now < self.quietNotifyUntil then return false end
	local channel = definition.channel or name
	if now - (self.lastPlayed[channel] or -math.huge) < (definition.cooldown or 0) then return false end
	self.lastPlayed[channel] = now
	if definition.interrupt then self:_stopChannel(channel) end
	if definition.duckNotify then self.quietNotifyUntil = now + 0.48 end
	for _, layer in ipairs(definition.layers or {}) do
		self:_spawnLayer(name, definition, layer, channel, anchor)
	end
	return true
end

function AudioFeedback:Play(name)
	return self:_play(name, nil)
end

function AudioFeedback:PlayAt(name, anchor)
	return self:_play(name, anchor)
end

function AudioFeedback:Destroy()
	self.destroyed = true
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	table.clear(self.connections)
	for _, sound in ipairs(self.activeSounds) do
		if sound.Parent then sound:Stop() sound:Destroy() end
	end
	table.clear(self.activeSounds)
	table.clear(self.activeByChannel)
end

return AudioFeedback


