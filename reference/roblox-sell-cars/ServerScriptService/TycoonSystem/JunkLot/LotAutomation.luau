--!strict

-- Junk Spot mechanics each repair one exact W lane. The early dealer role stays merged:
-- FirstSalesman handles incoming sellers, transports one Ready W car to a free P slot and
-- unlocks post-tutorial buyer acceptance. No separate Used Cars salesman purchase is required.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonService = require(script.Parent.Parent.TycoonService)
local DealerCar = require(script.Parent.DealerCar)
local TradeService = require(script.Parent.TradeService)
local ListingTransport = require(script.Parent.ListingTransport)
local StaffDirector = require(script.Parent.StaffDirector)

local LotAutomation = {}

local BODY_DAMAGE_TEMPLATES: { [string]: boolean } = {
	Rusty = true,
	Nissho = true,
	Wronkler = true,
}

local function bodyDamageTemplate(templateId: string): boolean
	return BODY_DAMAGE_TEMPLATES[templateId] == true
end

type BusyJob = {
	tradeId: string,
	slotIndex: number,
	startedAt: number?,
}

type RepairJobs = { [number]: BusyJob }

-- Each W repair and each displayed P sale owns its own exact lane job. Physical listing
-- transport is serialized through FirstSalesman; buyer acceptance can resolve P lanes in parallel.
local repairBusy: { [Player]: RepairJobs } = {}
local listingBusy: { [Player]: BusyJob } = {}
local saleBusy: { [Player]: RepairJobs } = {}

-- Round-robin cursors stop W1/P1 from starving later listing/display lanes.
local listingCursor: { [Player]: number } = {}
local saleCursor: { [Player]: number } = {}
local onboardingUntil: { [Player]: number } = {}

local LISTING_JOB_TIMEOUT = 75

local function exactWorking(player: Player, job: BusyJob): boolean
	local car = DealerCar.active(player, job.slotIndex)
	return car ~= nil and car.tradeId == job.tradeId
end

local function exactDisplay(player: Player, job: BusyJob): boolean
	local car = DealerCar.display(player, job.slotIndex)
	return car ~= nil and car.tradeId == job.tradeId
end

local function missingParts(car: any): { string }
	local partIds: { string } = {}
	for _, part in DealerCarConfig.PARTS do
		if car.parts[part.id] ~= true then
			table.insert(partIds, part.id)
		end
	end
	return partIds
end

local function repairPadEligible(player: Player, workingIndex: number): boolean
	local padId = DealerCarConfig.autoRepairPad(workingIndex)
	return padId ~= nil and DealerCar.hasPad(player, padId)
end

local function repairJobAt(player: Player, workingIndex: number): BusyJob?
	local jobs = repairBusy[player]
	return if jobs ~= nil then jobs[workingIndex] else nil
end

local function exactRepairCandidate(player: Player, workingIndex: number): any?
	if workingIndex < 1
		or workingIndex > DealerCar.workingCapacity(player)
		or not repairPadEligible(player, workingIndex)
		or repairJobAt(player, workingIndex) ~= nil
		or DealerCar.mechanicPaused(player, workingIndex)
	then
		return nil
	end
	local car = DealerCar.active(player, workingIndex)
	local model = DealerCar.model(player, "working", workingIndex)
	if car == nil
		or model == nil
		or model.Parent == nil
		or car.tradeId == ""
		or (car.state ~= "Junk" and car.state ~= "Repairing")
		or car.atBay == true
		or DealerCar.isArriving(player, workingIndex)
		or model:GetAttribute("DealerSlot") ~= "working"
		or model:GetAttribute("WorkingSlotIndex") ~= workingIndex
		or model:GetAttribute("TradeId") ~= car.tradeId
		or model:GetAttribute("State") ~= car.state
		or model:GetAttribute("Arriving") == true
		or #missingParts(car) == 0
	then
		return nil
	end
	return car
end

local function nextListingCandidate(player: Player): (any?, number?)
	local capacity = DealerCar.workingCapacity(player)
	if capacity < 1 then
		return nil, nil
	end
	local first = ((listingCursor[player] or 0) % capacity) + 1
	for offset = 0, capacity - 1 do
		local workingIndex = ((first + offset - 1) % capacity) + 1
		local car = DealerCar.active(player, workingIndex)
		local repairJob = repairJobAt(player, workingIndex)
		local sameRepairJob = repairJob ~= nil
			and car ~= nil
			and repairJob.tradeId == car.tradeId
		if car ~= nil
			and car.state == "Ready"
			and DealerCar.isReadyForListing(car)
			and car.atBay ~= true
			and not DealerCar.isArriving(player, workingIndex)
			and DealerCar.model(player, "working", workingIndex) ~= nil
			and not sameRepairJob
		then
			listingCursor[player] = workingIndex
			return car, workingIndex
		end
	end
	return nil, nil
end

local function saleJobAt(player: Player, displayIndex: number): BusyJob?
	local jobs = saleBusy[player]
	return if jobs ~= nil then jobs[displayIndex] else nil
end

local function nextSaleCandidate(player: Player): (any?, number?)
	local capacity = DealerCar.displayCapacity(player)
	if capacity < 1 then
		return nil, nil
	end
	local first = ((saleCursor[player] or 0) % capacity) + 1
	for offset = 0, capacity - 1 do
		local displayIndex = ((first + offset - 1) % capacity) + 1
		local car = DealerCar.display(player, displayIndex)
		if car ~= nil
			and car.state == "Offer"
			and car.tradeId ~= ""
			and car.offered > 0
			and saleJobAt(player, displayIndex) == nil
		then
			saleCursor[player] = displayIndex
			return car, displayIndex
		end
	end
	return nil, nil
end

local function startRepairAt(player: Player, record, workingIndex: number)
	if os.clock() < (onboardingUntil[player] or 0) then
		return
	end
	local car = exactRepairCandidate(player, workingIndex)
	if car == nil then
		return
	end

	local jobs = repairBusy[player]
	if jobs == nil then
		jobs = {}
		repairBusy[player] = jobs
	end
	local job: BusyJob = {
		tradeId = car.tradeId,
		slotIndex = workingIndex,
	}
	jobs[workingIndex] = job

	task.spawn(function()
		local ok, err = pcall(function()
			local function currentRepairable(): any?
				local activeJobs = repairBusy[player]
				local exact = DealerCar.active(player, job.slotIndex)
				local model = DealerCar.model(player, "working", job.slotIndex)
				if activeJobs == nil
					or activeJobs[job.slotIndex] ~= job
					or TycoonService.getForPlayer(player) ~= record
					or not repairPadEligible(player, job.slotIndex)
					or exact == nil
					or model == nil
					or model.Parent == nil
					or exact.tradeId ~= job.tradeId
					or (exact.state ~= "Junk" and exact.state ~= "Repairing")
					or exact.atBay == true
					or DealerCar.isArriving(player, job.slotIndex)
					or model:GetAttribute("DealerSlot") ~= "working"
					or model:GetAttribute("WorkingSlotIndex") ~= job.slotIndex
					or model:GetAttribute("TradeId") ~= job.tradeId
					or model:GetAttribute("State") ~= exact.state
					or model:GetAttribute("Arriving") == true
				then
					return nil
				end
				return exact
			end

			local current = currentRepairable()
			if current == nil then
				return
			end
			local remaining = missingParts(current)
			if #remaining == 0 then
				return
			end

			local function waitForOwner(): any?
				while currentRepairable() ~= nil and DealerCar.mechanicPaused(player, job.slotIndex) do
					task.wait(0.5)
				end
				return currentRepairable()
			end

			StaffDirector.repairJob(record, remaining, function(partId: string)
				local exact = waitForOwner()
				if exact == nil or exact.parts[partId] == true then
					return
				end
				local repairModel = DealerCar.model(player, "working", job.slotIndex)
				local previewsRustyBody = partId == "Body"
					and bodyDamageTemplate(exact.templateId)
					and repairModel ~= nil
					and repairModel.Parent ~= nil
				local repairDuration = DealerCarConfig.AUTO_REPAIR_SECONDS
					/ TycoonConfig.repairMultiplierFor(DealerCar.pads(player), partId)
				if previewsRustyBody and repairModel ~= nil then
					repairModel:SetAttribute("BrokenRepairDuration", repairDuration)
					repairModel:SetAttribute("BrokenRepairInProgress", true)
					repairModel:SetAttribute("BrokenAmount", 0)
				end
				task.wait(repairDuration)
				exact = waitForOwner()
				if exact ~= nil and exact.parts[partId] ~= true then
					DealerCar.repairPart(player, partId, "mechanic", job.slotIndex)
				end
				if previewsRustyBody and repairModel ~= nil and repairModel.Parent ~= nil then
					repairModel:SetAttribute("BrokenRepairInProgress", false)
					repairModel:SetAttribute("BrokenRepairDuration", nil)
					if exact == nil or exact.parts.Body ~= true then
						repairModel:SetAttribute("BrokenAmount", 1)
					end
				end
			end, job.slotIndex, function(): boolean
				return currentRepairable() ~= nil
					and not DealerCar.mechanicPaused(player, job.slotIndex)
			end, {
				player = player,
				tradeId = job.tradeId,
				templateId = current.templateId,
			})
		end)
		if not ok then
			warn(string.format(
				"[LotAutomation] W%d repair failed for %s: %s",
				job.slotIndex,
				player.Name,
				tostring(err)
			))
		end
		local activeJobs = repairBusy[player]
		if activeJobs ~= nil and activeJobs[job.slotIndex] == job then
			activeJobs[job.slotIndex] = nil
			if next(activeJobs) == nil then
				repairBusy[player] = nil
			end
		end
		if player.Parent ~= nil then
			-- repairJob may reject synchronously while a rig is being handed off. A real
			-- scheduler delay prevents a zero-yield retry chain from exhausting re-entry depth.
			task.delay(0.1, LotAutomation.step, player)
		end
	end)
end

local function stepRepair(player: Player)
	local record = TycoonService.getForPlayer(player)
	if player.Parent == nil or record == nil then
		return
	end
	for workingIndex = 1, DealerCar.workingCapacity(player) do
		startRepairAt(player, record, workingIndex)
	end
end

local function stepListing(player: Player)
	if os.clock() < (onboardingUntil[player] or 0) then
		return
	end
	local record = TycoonService.getForPlayer(player)
	local heldJob = listingBusy[player]
	if heldJob ~= nil and record ~= nil then
		local age = os.clock() - (heldJob.startedAt or os.clock())
		-- Ready + no autopilot is a normal hand-off state and may be observed while a pad
		-- event fires. Only a genuinely expired lease is a softlock; treating normal Ready
		-- as orphan caused every build purchase to replay the recovery notification.
		if age >= LISTING_JOB_TIMEOUT then
			StaffDirector.cancelListing(record, heldJob.tradeId)
			ListingTransport.recoverNow(player, true)
			if listingBusy[player] == heldJob then
				listingBusy[player] = nil
			end
		end
	end
	-- ListingTransport may already have reserved the free P slot for this exact Ready car.
	-- Do not ask availableDisplayIndex here: that would treat our own reservation as "full"
	-- and prevent FirstSalesman from ever taking the wheel. beginAutopilot owns the atomic
	-- session/reservation validation and safely rejects genuinely full dealerships.
	if player.Parent == nil
		or record == nil
		or listingBusy[player] ~= nil
		or not DealerCar.hasPad(player, DealerCarConfig.AUTO_LIST_PAD)
		or not DealerCar.hasPad(player, TycoonConfig.LISTING_PAD_ID)
	then
		return
	end

	local car, workingIndex = nextListingCandidate(player)
	if car == nil or workingIndex == nil then
		return
	end
	local job: BusyJob = {
		tradeId = car.tradeId,
		slotIndex = workingIndex,
		startedAt = os.clock(),
	}
	listingBusy[player] = job

	task.spawn(function()
		local ok, err = pcall(function()
			task.wait(DealerCarConfig.AUTO_LIST_DELAY)
			local current = DealerCar.active(player, job.slotIndex)
			local model = DealerCar.model(player, "working", job.slotIndex)
			local repairJob = repairJobAt(player, job.slotIndex)
			if TycoonService.getForPlayer(player) == nil
				or current == nil
				or current.tradeId ~= job.tradeId
				or current.state ~= "Ready"
				or not DealerCar.isReadyForListing(current)
				or current.atBay == true
				or DealerCar.isArriving(player, job.slotIndex)
				or model == nil
				or (repairJob ~= nil and repairJob.tradeId == job.tradeId)
			then
				return
			end
			-- TradeService and ListingTransport own the physical move and atomic W -> P commit.
			TradeService.startAutomatedListing(player, job.slotIndex)
		end)
		if not ok then
			warn(string.format(
				"[LotAutomation] W%d listing failed for %s: %s",
				job.slotIndex,
				player.Name,
				tostring(err)
			))
			-- A staff coroutine exception can leave both the actor lease and transport
			-- reservation alive. Release both before clearing listingBusy or retrying.
			local canceled, cancelError = pcall(StaffDirector.cancelListing, record, job.tradeId)
			if not canceled then
				warn(string.format("[LotAutomation] listing staff cleanup failed trade=%s: %s", job.tradeId, tostring(cancelError)))
			end
			local recovered, recoverError = pcall(ListingTransport.recoverNow, player, true)
			if not recovered then
				warn(string.format("[LotAutomation] listing transport cleanup failed trade=%s: %s", job.tradeId, tostring(recoverError)))
			end
		end
		if listingBusy[player] == job then
			listingBusy[player] = nil
		end
		if player.Parent ~= nil then
			task.defer(LotAutomation.step, player)
			task.defer(LotAutomation.stepDisplay, player)
		end
	end)
end

local function stepDisplay(player: Player)
	if player.Parent == nil
		or TycoonService.getForPlayer(player) == nil
		or not TradeService.isBuyerAutomated(player)
	then
		return
	end

	local car, displayIndex = nextSaleCandidate(player)
	if car == nil or displayIndex == nil then
		return
	end
	local job: BusyJob = {
		tradeId = car.tradeId,
		slotIndex = displayIndex,
	}
	local jobs = saleBusy[player]
	if jobs == nil then
		jobs = {}
		saleBusy[player] = jobs
	end
	jobs[displayIndex] = job

	task.spawn(function()
		local ok, err = pcall(function()
			task.wait(DealerCarConfig.AUTO_ACCEPT_DELAY)
			local record = TycoonService.getForPlayer(player)
			if record == nil or not exactDisplay(player, job) then
				return
			end
			local current = DealerCar.display(player, job.slotIndex)
			if current == nil or current.state ~= "Offer" or current.offered <= 0 then
				return
			end

			-- The buyer lanes are independent. FirstSalesman grants the merged entitlement,
			-- but must never serialize authoritative acceptance across four P slots.
			TradeService.handleSell(player, "accept", job.tradeId)
		end)
		if not ok then
			warn(string.format(
				"[LotAutomation] P%d sale failed for %s: %s",
				job.slotIndex,
				player.Name,
				tostring(err)
			))
		end
		local activeJobs = saleBusy[player]
		if activeJobs ~= nil and activeJobs[job.slotIndex] == job then
			activeJobs[job.slotIndex] = nil
			if next(activeJobs) == nil then saleBusy[player] = nil end
		end
		if player.Parent ~= nil then
			task.defer(LotAutomation.step, player)
			task.defer(LotAutomation.stepDisplay, player)
		end
	end)
	-- Fill the next free P lane immediately; recursion stops when every offer has a job.
	task.defer(stepDisplay, player)
end

function LotAutomation.step(player: Player)
	stepRepair(player)
	stepListing(player)
end

function LotAutomation.stepDisplay(player: Player)
	stepDisplay(player)
end

function LotAutomation.forget(player: Player)
	repairBusy[player] = nil
	listingBusy[player] = nil
	saleBusy[player] = nil
	listingCursor[player] = nil
	saleCursor[player] = nil
	onboardingUntil[player] = nil
end

function LotAutomation.init()
	DealerCar.manualRepairStarted.Event:Connect(function(player: Player, workingIndex: number?)
		local resolvedIndex = workingIndex or 1
		local job = repairJobAt(player, resolvedIndex)
		if job ~= nil and exactWorking(player, job) then
			local record = TycoonService.getForPlayer(player)
			if record ~= nil then
				StaffDirector.mechanicYield(record, player, resolvedIndex)
			end
		end
	end)

	DealerCar.stateChanged.Event:Connect(function(player: Player, _state: string, _slot: string?, _slotIndex: number?)
		LotAutomation.step(player)
		LotAutomation.stepDisplay(player)
	end)
	DealerCar.arrived.Event:Connect(function(player: Player, _record, _workingIndex: number?)
		LotAutomation.step(player)
	end)
	TycoonService.padPurchased.Event:Connect(function(_record, definition, player: Player)
		if player ~= nil then
			-- A mechanic purchase is functional immediately: if a repairable W car is already
			-- parked, the newly hired worker starts walking in this same scheduling turn. Keep
			-- the short onboarding grace only for FirstSalesman's separate listing tutorial.
			if definition ~= nil and definition.id == "FirstSalesman" then
				onboardingUntil[player] = os.clock() + 4
				task.delay(4, function()
					if player.Parent ~= nil then
						onboardingUntil[player] = nil
						LotAutomation.step(player)
						LotAutomation.stepDisplay(player)
					end
				end)
			else
				LotAutomation.step(player)
				LotAutomation.stepDisplay(player)
			end
		end
	end)

	-- Safety net for a missed state event. Exact job identities make every retry idempotent.
	task.spawn(function()
		while true do
			task.wait(DealerCarConfig.AUTOMATION_INTERVAL)
			for _, player in Players:GetPlayers() do
				LotAutomation.step(player)
				LotAutomation.stepDisplay(player)
			end
		end
	end)
end

return LotAutomation
