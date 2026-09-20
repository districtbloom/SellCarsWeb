-- Server-only gameplay event bus for the Sell Cars MVP.
local ServerScriptService = game:GetService("ServerScriptService")

local GameplayEvents = {}

local EVENT_NAMES = {
	"CarArrived",
	"TradeOpened",
	"CarBought",
	"PartFixed",
	"RepairCompleted",
	"CarListed",
	"OfferRequested",
	"OfferReceived",
	"TradeResolved",
	"CarSold",
	"PadPurchased",
	"MechanicHired",
	"SalesmanHired",
	"RepairBayOpened",
	"ServiceCompleted",
	"PersonalCarStarterChosen",
	"PersonalCarCustomized",
	"CustomFxOfferViewed",
	"CustomFxPurchasePrompted",
	"CustomFxEntitlementGranted",
	"CustomFxUsed",
	"PersonalCarSold",
	"PersonalCarReplaced",
	"PersonalCarEntered",
	"PersonalCarDriven60Seconds",
	"PersonalGarageExpanded",
	"TrackRunStarted",
	"TrackLapCompleted",
	"TrackRunCompleted",
	"CarPipelineTransition",
	"PipelineQueueAge",
	"SessionStarted",
}

local valid = {}
for _, name in EVENT_NAMES do
	valid[name] = true
end

local PIPELINE_TRANSITION_BY_EVENT = {
	CarBought = "acquired",
	RepairCompleted = "repair",
	ServiceCompleted = "service",
	CarListed = "listing",
	CarSold = "sold",
}

local folder = ServerScriptService:FindFirstChild("CoreGameplayEvents")
if folder == nil then
	folder = Instance.new("Folder")
	folder.Name = "CoreGameplayEvents"
	folder.Parent = ServerScriptService
end

local function eventFor(name)
	assert(valid[name] == true, ("Unknown gameplay event %q"):format(tostring(name)))
	local event = folder:FindFirstChild(name)
	if event == nil then
		event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = folder
	end
	assert(event:IsA("BindableEvent"))
	return event
end

function GameplayEvents.init()
	for _, name in EVENT_NAMES do
		eventFor(name)
	end
end

function GameplayEvents.emit(name, player, payload)
	local safePayload = if typeof(payload) == "table" then table.clone(payload) else {}
	-- Existing funnel events also act as objective transition receipts. Recording the
	-- server-authored step on them makes drop-off measurable without a duplicate event family.
	if safePayload.objectiveStep == nil and player ~= nil then
		safePayload.objectiveStep = player:GetAttribute("ProgressionObjectiveStep")
	end
	eventFor(name):Fire(player, safePayload)
	local transition = PIPELINE_TRANSITION_BY_EVENT[name]
	if transition ~= nil and typeof(safePayload.tradeId) == "string" and safePayload.tradeId ~= "" then
		local transitionPayload = table.clone(safePayload)
		transitionPayload.transition = transition
		transitionPayload.sourceEvent = name
		eventFor("CarPipelineTransition"):Fire(player, transitionPayload)
		print(string.format(
			"[CarPipeline] user=%s trade=%s transition=%s source=%s",
			if player ~= nil then tostring(player.UserId) else "unknown",
			safePayload.tradeId,
			transition,
			name
		))
	end
end

function GameplayEvents.connect(name, callback)
	return eventFor(name).Event:Connect(callback)
end

function GameplayEvents.get(name)
	return eventFor(name)
end

GameplayEvents.names = table.freeze(table.clone(EVENT_NAMES))

return GameplayEvents
