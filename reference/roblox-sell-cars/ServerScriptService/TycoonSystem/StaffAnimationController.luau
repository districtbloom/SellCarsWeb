--!strict

-- Compatibility facade for existing tycoon callers. Track ownership is centralized.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RuntimeFlags = require(ReplicatedStorage.Shared.Config.RuntimeFlags)
local NpcAnimationController = require(ServerScriptService.Systems.NPC.NpcAnimationController)

local StaffAnimationController = {}

local ANIMATION_IDS: { [string]: string } = {
	idle_working_computer = "rbxassetid://116122076689674",
	sit_legs = "rbxassetid://99092341273470",
}

local function animationId(name: string, channel: string): string?
	local id = ANIMATION_IDS[name]
	if id == nil then
		warn(("[StaffAnimationController] unknown %s animation %s"):format(channel, name))
	end
	return id
end

function StaffAnimationController.PlayBaseAnimation(rig: Model, name: string): AnimationTrack?
	if RuntimeFlags.UseCentralNpcAnimation ~= true then
		return nil
	end
	local id = animationId(name, "Base")
	if id == nil then
		return nil
	end
	local track = NpcAnimationController.playBase(rig, id, {
		priority = Enum.AnimationPriority.Action,
		looped = true,
		fadeTime = 0.15,
	})
	if track ~= nil then
		rig:SetAttribute("StaffBaseAnimation", name)
	end
	return track
end

function StaffAnimationController.PlayOverlay(rig: Model, name: string): AnimationTrack?
	if RuntimeFlags.UseCentralNpcAnimation ~= true then
		return nil
	end
	local id = animationId(name, "Overlay")
	if id == nil then
		return nil
	end
	local track = NpcAnimationController.playOverlay(rig, id, {
		priority = Enum.AnimationPriority.Action2,
		looped = true,
		fadeTime = 0.15,
	})
	if track ~= nil then
		rig:SetAttribute("StaffOverlayAnimation", name)
	end
	return track
end

function StaffAnimationController.StopOverlay(rig: Model)
	NpcAnimationController.stopOverlay(rig, 0.15)
	rig:SetAttribute("StaffOverlayAnimation", nil)
end

function StaffAnimationController.StopAll(rig: Model)
	NpcAnimationController.stopAll(rig, 0.15)
	rig:SetAttribute("StaffBaseAnimation", nil)
	rig:SetAttribute("StaffOverlayAnimation", nil)
end

return StaffAnimationController
