--!strict

-- Runtime-only transport between the repaired-car pad and an available Used Cars display. The saved state
-- deliberately stays Ready until the server sees this exact model in the target.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.TycoonConfig)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TycoonService = require(script.Parent.Parent.TycoonService)
local OwnerCarPipeline = require(script.Parent.Parent.OwnerCarPipeline)
local DealerCar = require(script.Parent.DealerCar)
local LotSlots = require(script.Parent.LotSlots)
local CarVisuals = require(script.Parent.CarVisuals)
local Remotes = require(script.Parent.Remotes)

type Record = TycoonService.TycoonRecord

type Session = {
	player: Player,
	record: Record,
	car: any,
	model: Model,
	workingIndex: number,
	displayIndex: number,
	usedParkingV2: boolean,
	nativeRig: boolean,
	seat: VehicleSeat?,
	prompt: ProximityPrompt?,
	target: Part?,
	wheels: { CarVisuals.Wheel },
	throttle: number,
	steer: number,
	speed: number,
	spin: number,
	lastInput: number,
	lastPacket: number,
	wasDriven: boolean,
	manualStarted: boolean,
	manualStartedAt: number,
	longTestDrive: boolean,
	claimAnnounced: boolean,
	assistOffered: boolean,
	unoccupiedSince: number,
	recoveryDeadline: number,
	recoveryStage: number,
	warnReason: string?,
	warningOffset: number,
	autopilot: boolean,
	autopilotLocked: boolean,
	finishing: boolean,
}

local ListingTransport = {}

ListingTransport.arrived = Instance.new("BindableEvent")

-- Dealer stock is staff-controlled. `sessions` holds a car waiting for assignment while
-- `automationSessions` holds the one currently claimed by FirstSalesman.
local sessions: { [Player]: Session } = {}
local automationSessions: { [Player]: Session } = {}
local workingCursor: { [Player]: number } = {}
local returnHomeAvailable: { [Player]: boolean } = {}

local INPUT_TIMEOUT = 0.4
local MAX_FORWARD_SPEED = 21
local MAX_REVERSE_SPEED = 10
local ACCELERATION = 16
local BRAKING = 26
local TURN_RATE = math.rad(72)
local MAX_ROUTE_RADIUS = 115
local PACKET_INTERVAL = 1 / 45
local SALESMAN_TAKEOVER_RADIUS = 20
local ABANDON_DISTANCE = 12
local NEAR_ABANDON_SECONDS = 30
local FAR_ABANDON_SECONDS = 40
local OUT_OF_BOUNDS_RADIUS = 155
local WARNING_INTERVAL = 30
local MANUAL_TIMEOUT = 60
local NO_MECHANIC_MANUAL_TIMEOUT = 180
local REX_WARNING_INTERVAL = 10
local COMMIT_RECOVERY_SECONDS = 2.5
local RECOVERY_WARNING_LINES = {
	"Boss, bring the car back to the SALE SPOT.",
	"Boss, we need that car on the SALE SPOT to keep cash flowing.",
	"Boss, the lot is waiting. Return the car to the SALE SPOT.",
	"Boss, fun ride, but that car belongs on the SALE SPOT.",
	"Boss, customers can't buy it out there. Use the SALE SPOT.",
	"Boss, let's get that car back on the SALE SPOT.",
	"Boss, I still need that car parked on the SALE SPOT.",
	"Boss, wrap up the drive and return to the SALE SPOT.",
	"Boss, the car belongs on the SALE SPOT when you're done.",
	"Boss, return it to the SALE SPOT before I recover it.",
}
local REX_WARNING_LINES = {
	"Boss, Rex here. I saw the new service shop.",
	"Enjoy the test drive, but that car still belongs back on your lot.",
	"Time to turn around and bring it back to the sale spot.",
	"Last call, Boss. I\'m sending the car back to your lot now.",
}

local function saleSpotName(index: number): string
	return if index == 1 then "SALE SPOT" else "SALE SPOT " .. tostring(index)
end

local function horizontalDistance(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function exactIndex(value: unknown, capacity: number): number?
	if typeof(value) ~= "number"
		or value ~= math.floor(value)
		or value < 1
		or value > capacity
	then
		return nil
	end
	return value
end

local function sameTrade(a: any, b: any): boolean
	return a ~= nil
		and b ~= nil
		and typeof(a.tradeId) == "string"
		and typeof(b.tradeId) == "string"
		and a.tradeId ~= ""
		and a.tradeId == b.tradeId
end

-- The core W identity deliberately excludes the reserved display. It is also the only
-- identity strong enough to put a failed/invalid transport back onto its exact repair pad.
local function authoritativeWorking(session: Session): boolean
	local active = DealerCar.active(session.player, session.workingIndex)
	return active ~= nil
		and session.workingIndex == math.floor(session.workingIndex)
		and session.workingIndex >= 1
		and session.workingIndex <= DealerCar.workingCapacity(session.player)
		and sameTrade(active, session.car)
		and active.state == "Ready"
		and DealerCar.isReadyForListing(active)
		and session.player.Parent ~= nil
		and TycoonService.getForPlayer(session.player) == session.record
		and session.record.owner == session.player
		and session.model.Parent ~= nil
		and session.model:IsDescendantOf(session.record.folder)
		and DealerCar.model(session.player, "working", session.workingIndex) == session.model
		and session.model:GetAttribute("DealerSlot") == "working"
		and session.model:GetAttribute("State") == "Ready"
		and session.model:GetAttribute("TradeId") == active.tradeId
		and session.model:GetAttribute("WorkingSlotIndex") == session.workingIndex
		and session.model:GetAttribute("Arriving") ~= true
		and LotSlots.platform(session.record, session.workingIndex) ~= nil
end

local function registered(session: Session): boolean
	return sessions[session.player] == session or automationSessions[session.player] == session
end

local function sessionFor(player: Player, car: any, model: Model): Session?
	local primary = sessions[player]
	if primary ~= nil and sameTrade(primary.car, car) and primary.model == model then
		return primary
	end
	local automation = automationSessions[player]
	if automation ~= nil and sameTrade(automation.car, car) and automation.model == model then
		return automation
	end
	return nil
end

local function valid(session: Session): boolean
	return registered(session)
		and authoritativeWorking(session)
		and session.displayIndex == math.floor(session.displayIndex)
		and session.displayIndex >= 1
		and session.displayIndex <= DealerCar.displayCapacity(session.player)
		and DealerCar.display(session.player, session.displayIndex) == nil
		and DealerCar.displayReservation(session.player, session.displayIndex) == session.car.tradeId
		and LotSlots.salePlatform(session.record, session.displayIndex) ~= nil
		and session.model:GetAttribute("ListingWorkingIndex") == session.workingIndex
		and session.model:GetAttribute("ListingDisplayIndex") == session.displayIndex
end

local recoverForSalesman: ((Session, boolean?) -> ())? = nil

local function destroyTarget(session: Session)
	if session.target ~= nil then
		if session.player.Parent ~= nil then
			Remotes.ListingNotice:FireClient(session.player, {
				guideOnly = true,
				clearGuide = true,
			})
		end
		if session.target.Parent ~= nil then
			session.target:Destroy()
		end
		session.target = nil
	end
end

local function setNativeSeatAutomationLocked(session: Session, _locked: boolean)
	if not session.nativeRig or session.model.Parent == nil then
		return
	end
	local candidate = session.model:FindFirstChild("DriverSeat", true)
	if candidate == nil or not candidate:IsA("VehicleSeat") then
		return
	end
	local seat = candidate :: VehicleSeat
	-- Dealer inventory is never player-drivable. Personal vehicles will use a separate
	-- ownership/runtime path. Do not restore authored seat state after cancellation: old
	-- templates and migrated queue snapshots may have shipped with an enabled seat.
	session.model:SetAttribute("DealerDriveLocked", true)
	session.model:SetAttribute("VehicleRuntimeActive", false)
	session.model:SetAttribute("owner", nil)
	seat.CanTouch = false
	seat.Disabled = true
	local occupant = seat.Occupant
	if occupant ~= nil then
		occupant.Sit = false
	end
	for _, promptName in { "DrivePrompt", "GetInToListPrompt" } do
		local prompt = session.model:FindFirstChild(promptName, true)
		if prompt ~= nil and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = false
		end
	end
end

local function ejectSeat(session: Session): boolean
	local seat = session.seat
	local ejectedOwner = false
	if seat ~= nil then
		if seat.Parent ~= nil then
			local occupant = seat.Occupant
			if occupant ~= nil then
				local ownerHumanoid = session.player.Character
					and session.player.Character:FindFirstChildOfClass("Humanoid")
				ejectedOwner = occupant == ownerHumanoid
				occupant.Sit = false
			end
			if session.nativeRig then
				if session.prompt ~= nil then
					session.prompt.Enabled = false
				end
			else
				seat:Destroy()
			end
		end
		session.seat = nil
		session.prompt = nil
	end
	return ejectedOwner
end

local function cancelSession(session: Session)
	local player = session.player
	DealerCar.releaseDisplay(player, session.displayIndex, tostring(session.car.tradeId or ""))
	if session.model.Parent ~= nil then
		session.model:SetAttribute("ListingTransport", nil)
		session.model:SetAttribute("ListingAutopilot", nil)
		session.model:SetAttribute("ListingDisplayIndex", nil)
		session.model:SetAttribute("ListingWorkingIndex", nil)
	end
	session.autopilot = false
	session.autopilotLocked = false
	session.finishing = false
	ejectSeat(session)
	setNativeSeatAutomationLocked(session, false)
	destroyTarget(session)
	if sessions[player] == session then
		sessions[player] = nil
	end
	if automationSessions[player] == session then
		automationSessions[player] = nil
	end
end

local function cancel(player: Player)
	local primary = sessions[player]
	local automation = automationSessions[player]
	if primary ~= nil then
		cancelSession(primary)
	end
	if automation ~= nil and automation ~= primary then
		cancelSession(automation)
	end
end

ListingTransport.cancel = cancel
function ListingTransport.forget(player: Player)
	cancel(player)
	workingCursor[player] = nil
end

function ListingTransport.cancelRecord(record: Record)
	for _, session in sessions do
		if session.record == record then
			cancelSession(session)
		end
	end
	for _, session in automationSessions do
		if session.record == record then
			cancelSession(session)
		end
	end
end

local function createTarget(session: Session): Part?
	local surface = LotSlots.salePlatform(session.record, session.displayIndex)
	if surface == nil then
		return nil
	end
	local folder = LotSlots.carFolder(session.record)
	local targetName = "P" .. session.displayIndex .. "ListingTarget"
	local stale = folder:FindFirstChild(targetName)
	if stale ~= nil then
		stale:Destroy()
	end

	local target = Instance.new("Part")
	target.Name = targetName
	target.Shape = Enum.PartType.Cylinder
	target.Size = Vector3.new(0.16, 11, 11)
	local top = surface.Position + surface.CFrame.UpVector * (surface.Size.Y * 0.5 + 0.12)
	target.CFrame = CFrame.new(top) * surface.CFrame.Rotation * CFrame.Angles(0, 0, math.pi * 0.5)
	target.Color = Color3.fromRGB(50, 255, 115)
	target.Material = Enum.Material.Neon
	-- The owner client renders the generated Sale Spot outline; keep this authoritative
	-- reservation target invisible so the old solid green disc cannot fight the new marker.
	target.Transparency = 1
	target.Anchored = true
	target.CanCollide = false
	target.CanTouch = false
	target.CanQuery = false
	target.CastShadow = false
	target:SetAttribute("ListingTarget", true)
	target:SetAttribute("OwnerUserId", session.player.UserId)
	target.Parent = folder

	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = target.Color
	light.Brightness = 0
	light.Range = 18
	light.Shadows = false
	light.Parent = target

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "P" .. session.displayIndex .. "Label"
	billboard.Size = UDim2.fromOffset(190, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard:SetAttribute("PrivateOwnerUserId", session.player.UserId)
	billboard.Parent = target

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = saleSpotName(session.displayIndex) .. "\nPARK HERE"
	label.TextColor3 = Color3.fromRGB(210, 255, 220)
	label.TextStrokeColor3 = Color3.fromRGB(8, 50, 20)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard

	-- The authoritative reservation is invisible; its owner gets the generated circular
	-- marker for the complete W-to-P delivery, including normal salesman automation.
	Remotes.ListingNotice:FireClient(session.player, {
		guideOnly = true,
		guideTarget = target,
		guidePosition = target.Position,
		guideLabel = "PARK AT " .. saleSpotName(session.displayIndex),
		guideDuration = 60,
		clearGuide = false,
	})
	return target
end

local function ownerHumanoid(session: Session): Humanoid?
	local character = session.player.Character
	return if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
end

local function salesmanRig(session: Session): Model?
	local salesman = session.record.folder:FindFirstChild(TycoonConfig.SALESMAN_MODEL, true)
	if salesman ~= nil and salesman:IsA("Model") then
		return salesman
	end
	local junk = session.record.zones.junk
	local fallback = if junk ~= nil then junk:FindFirstChild(TycoonConfig.SALESMAN_MODEL, true) else nil
	return if fallback ~= nil and fallback:IsA("Model") then fallback else nil
end

local function notify(session: Session, text: string, duration: number?, guideToSale: boolean?, action: string?)
	local salesman = salesmanRig(session)
	Remotes.ListingNotice:FireClient(session.player, {
		title = "SALESMAN",
		text = text,
		duration = duration or 4.5,
		portrait = salesman,
		guideTarget = if guideToSale == true then session.target else nil,
		guidePosition = if guideToSale == true and session.target ~= nil then session.target.Position else nil,
		guideLabel = "PARK AT " .. saleSpotName(session.displayIndex),
		guideDuration = WARNING_INTERVAL + 5,
		clearGuide = guideToSale ~= true,
		action = action,
	})
end

local function notifyRex(session: Session, stage: number)
	Remotes.ListingNotice:FireClient(session.player, {
		title = "REX REDLINE",
		text = REX_WARNING_LINES[math.clamp(stage, 1, #REX_WARNING_LINES)],
		duration = 8,
		portraitKind = "rex",
		clearGuide = true,
	})
end

local function offerReturnHome(session: Session)
	returnHomeAvailable[session.player] = true
	Remotes.ListingNotice:FireClient(session.player, {
		title = "CAR RECOVERED",
		text = "Your car is back on the sale spot. Use the Home button whenever you want to return to your lot.",
		duration = 7,
		showHome = true,
		clearGuide = true,
	})
end

local function notifyAbandonCountdown(session: Session, seconds: number)
	Remotes.ListingNotice:FireClient(session.player, {
		title = `CAR RETURNS IN {seconds} SECONDS`,
		text = "Get back in to cancel. Otherwise, only the car returns to the sale spot.",
		duration = 8,
		clearGuide = true,
	})
end

local function recoveryWarningLine(session: Session): string
	local index = ((session.warningOffset + (session.recoveryStage - 1) * 3) % #RECOVERY_WARNING_LINES) + 1
	return string.gsub(RECOVERY_WARNING_LINES[index], "SALE SPOT", saleSpotName(session.displayIndex))
end

local function salesmanBubble(session: Session, text: string)
	local salesman = salesmanRig(session)
	local adornee = if salesman ~= nil
		then salesman:FindFirstChild("Head", true) or salesman:FindFirstChildWhichIsA("BasePart", true)
		else nil
	if adornee ~= nil then
		Remotes.ListingNotice:FireClient(session.player, {
			mode = "bubble",
			adornee = adornee,
			text = text,
		})
	end
end

local function isInsideTarget(session: Session): boolean
	local surface = LotSlots.salePlatform(session.record, session.displayIndex)
	if surface == nil then
		return false
	end
	local localPosition = surface.CFrame:PointToObjectSpace(session.model:GetPivot().Position)
	local snapScale = if session.player:GetAttribute("TutorialComplete") == true then 0.48 else 0.62
	local radius = math.min(surface.Size.X, surface.Size.Z) * snapScale
	return Vector2.new(localPosition.X, localPosition.Z).Magnitude <= radius
		and math.abs(localPosition.Y) <= 10
end

local function snapToSale(session: Session)
	if session.nativeRig then
		local inputs = session.model:FindFirstChild("Inputs")
		if inputs ~= nil then
			inputs:SetAttribute("throttleInput", 0)
			inputs:SetAttribute("steeringInput", 0)
			inputs:SetAttribute("handBrakeInput", true)
		end
		for _, descendant in session.model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
				descendant.Anchored = true
			end
		end
	end
	CarVisuals.resetWheels(session.model, session.wheels)
	session.model:PivotTo(LotSlots.saleCFrame(session.record, session.displayIndex))
	CarVisuals.settleOnVisibleTires(session.model, LotSlots.saleTop(session.record, session.displayIndex), 0.01)
	CarVisuals.resetWheels(session.model, session.wheels)
	CarVisuals.setRunningLights(session.model, false)
end

local function finish(session: Session)
	if not valid(session) or session.finishing then
		return
	end
	session.finishing = true
	session.throttle = 0
	session.steer = 0
	session.speed = 0
	if session.prompt ~= nil then
		session.prompt.Enabled = false
	end
	session.model:SetAttribute("ListingTransport", "Finishing")
	snapToSale(session)
	-- BindableEvent copies Luau tables at its boundary. Pass only stable Instances;
	-- TradeService re-reads the authoritative tycoon record and active car before committing.
	ListingTransport.arrived:Fire(
		session.player,
		session.model,
		session.displayIndex,
		session.workingIndex
	)
	-- A rejected or missing commit must not strand a Ready car on a display or leave this
	-- serialized session permanently Finishing. Successful commits invalidate W immediately.
	task.delay(COMMIT_RECOVERY_SECONDS, function()
		if not registered(session) or not session.finishing then
			return
		end
		if not authoritativeWorking(session) then
			cancel(session.player)
			return
		end
		local recover = recoverForSalesman
		if recover == nil then
			cancel(session.player)
			return
		end
		local ok, err = pcall(recover, session)
		if not ok then
			warn(`[ListingTransport] commit recovery failed: {err}`)
		end
		if registered(session) and (not ok or not valid(session)) then
			cancel(session.player)
		end
	end)
end

local function clearBlockedPrompt(model: Model)
	local prompt = model:FindFirstChild("SaleSpotBlockedPrompt", true)
	if prompt ~= nil then
		prompt:Destroy()
	end
end

-- Full-sale-lot state is handled by automation itself. The NPC cannot ask the
-- player to perform an impossible "sell previous car" action; legacy prompts are only removed.

function ListingTransport.sync(player: Player, record: Record, preferredWorkingIndex: number?)
	local existing = sessions[player]
	if existing ~= nil and existing.record == record and valid(existing) then
		clearBlockedPrompt(existing.model)
		if (existing.manualStarted or existing.autopilot or player:GetAttribute("TutorialComplete") == true)
			and (existing.target == nil or existing.target.Parent == nil)
		then
			existing.target = createTarget(existing)
		end
		if existing.seat ~= nil then
			ejectSeat(existing)
		end
		setNativeSeatAutomationLocked(existing, true)
		return
	end
	if existing ~= nil then
		cancelSession(existing)
	end

	local displayIndex = DealerCar.availableDisplayIndex(player)
	local hasListingPad = DealerCar.hasPad(player, TycoonConfig.LISTING_PAD_ID)
	for index = 1, DealerCar.workingCapacity(player) do
		local candidateModel = DealerCar.model(player, "working", index)
		if candidateModel ~= nil then
			clearBlockedPrompt(candidateModel)
		end
	end

	if displayIndex == nil
		or not hasListingPad
		or LotSlots.salePlatform(record, displayIndex) == nil
	then
		return
	end

	local capacity = DealerCar.workingCapacity(player)
	local selectedIndex: number? = nil
	local car: any = nil
	local model: Model? = nil
	local function consider(index: number): boolean
		if index < 1 or index > capacity then
			return false
		end
		local candidate = DealerCar.active(player, index)
		local candidateModel = DealerCar.model(player, "working", index)
		local automated = automationSessions[player]
		if candidate == nil
			or (automated ~= nil and sameTrade(automated.car, candidate))
			or candidateModel == nil
			or candidateModel.Parent == nil
			or candidate.tradeId == ""
			or candidate.state ~= "Ready"
			or not DealerCar.isReadyForListing(candidate)
			or LotSlots.platform(record, index) == nil
			or candidateModel:GetAttribute("DealerSlot") ~= "working"
			or candidateModel:GetAttribute("State") ~= "Ready"
			or candidateModel:GetAttribute("TradeId") ~= candidate.tradeId
			or candidateModel:GetAttribute("WorkingSlotIndex") ~= index
			or candidateModel:GetAttribute("Arriving") == true
		then
			return false
		end
		selectedIndex = index
		car = candidate
		model = candidateModel
		return true
	end

	local preferred: number? = nil
	if preferredWorkingIndex ~= nil then
		preferred = exactIndex(preferredWorkingIndex, capacity)
		if preferred == nil then
			return
		end
		consider(preferred)
	end
	if selectedIndex == nil then
		local cursor = workingCursor[player] or 0
		for offset = 1, capacity do
			local index = ((cursor + offset - 1) % capacity) + 1
			if consider(index) then
				break
			end
		end
	end
	if selectedIndex == nil or car == nil or model == nil then
		return
	end
	workingCursor[player] = selectedIndex
	if not DealerCar.reserveDisplay(player, displayIndex, tostring(car.tradeId or "")) then
		return
	end

	local session: Session = {
		player = player,
		record = record,
		car = car,
		model = model,
		workingIndex = selectedIndex,
		displayIndex = displayIndex,
		-- Capture the persisted car decision with the listing reservation. FirstSalesman may
		-- walk for several seconds before taking the wheel, so route selection must not read
		-- a deployment-wide flag later at drive time.
		usedParkingV2 = OwnerCarPipeline.routingFlags(car).usedParking,
		nativeRig = model:GetAttribute("DealerFullRig") == true,
		seat = nil,
		prompt = nil,
		target = nil,
		wheels = CarVisuals.wheels(model),
		throttle = 0,
		steer = 0,
		speed = 0,
		spin = 0,
		lastInput = 0,
		lastPacket = 0,
		wasDriven = false,
		manualStarted = false,
		manualStartedAt = 0,
		longTestDrive = false,
		claimAnnounced = false,
		assistOffered = false,
		unoccupiedSince = 0,
		recoveryDeadline = 0,
		recoveryStage = 0,
		warnReason = nil,
		warningOffset = math.random(0, #RECOVERY_WARNING_LINES - 1),
		autopilot = false,
		autopilotLocked = false,
		finishing = false,
	}
	sessions[player] = session
	model:SetAttribute("ListingTransport", "Ready")
	model:SetAttribute("ListingWorkingIndex", selectedIndex)
	model:SetAttribute("ListingDisplayIndex", displayIndex)
	if player:GetAttribute("TutorialComplete") == true then
		session.target = createTarget(session)
	end
	setNativeSeatAutomationLocked(session, true)
end

function ListingTransport.beginAutopilot(
	player: Player,
	record: Record,
	car: any,
	model: Model,
	workingIndex: number?
): (boolean, boolean?)
	local requestedWorkingIndex = workingIndex
		or DealerCar.workingIndexForTrade(player, tostring(car.tradeId or ""))
	local resolvedWorkingIndex = exactIndex(requestedWorkingIndex, DealerCar.workingCapacity(player))
	if resolvedWorkingIndex == nil then
		return false
	end
	ListingTransport.sync(player, record, resolvedWorkingIndex)
	local session = sessionFor(player, car, model)
	if session == nil
		or session.workingIndex ~= resolvedWorkingIndex
		or not sameTrade(session.car, car)
		or session.model ~= model
		or not valid(session)
		or session.finishing
		or session.autopilot
	then
		return false
	end
	if session.seat ~= nil and session.seat.Occupant ~= nil then
		return false
	end
	if session.manualStarted then
		local repair = LotSlots.parkedCFrame(record, session.workingIndex).Position
		if horizontalDistance(model:GetPivot().Position, repair) > SALESMAN_TAKEOVER_RADIUS then
			return false
		end
	end
	if session.target == nil or session.target.Parent == nil then
		session.target = createTarget(session)
	end
	local existingAutomation = automationSessions[player]
	if existingAutomation ~= nil and existingAutomation ~= session and valid(existingAutomation) then
		return false
	end
	session.autopilot = true
	if sessions[player] == session then
		sessions[player] = nil
	end
	automationSessions[player] = session
	-- The salesman has only accepted the job and is still walking to the Junk Spot.
	-- Keep the repaired car enterable during the approach; an owner who sits first
	-- claims the car and causes StaffDirector's autopilot identity check to abort.
	session.autopilotLocked = false
	setNativeSeatAutomationLocked(session, true)
	session.model:SetAttribute("ListingAutopilot", true)
	session.model:SetAttribute("ListingTransport", "SalesmanApproaching")
	return true, session.usedParkingV2
end

function ListingTransport.isAutopilot(player: Player, car: any, model: Model): boolean
	local session = sessionFor(player, car, model)
	return session ~= nil
		and sameTrade(session.car, car)
		and session.model == model
		and session.autopilot
		and not session.finishing
		and valid(session)
end

function ListingTransport.lockAutopilot(player: Player, car: any, model: Model): boolean
	local session = sessionFor(player, car, model)
	if session == nil
		or not sameTrade(session.car, car)
		or session.model ~= model
		or not session.autopilot
		or session.finishing
		or not valid(session)
		or (session.seat ~= nil and session.seat.Occupant ~= nil)
	then
		return false
	end
	ejectSeat(session)
	session.autopilotLocked = true
	setNativeSeatAutomationLocked(session, true)
	session.model:SetAttribute("ListingTransport", "SalesmanDriving")
	return true
end

function ListingTransport.endAutopilot(player: Player, car: any, model: Model)
	local session = sessionFor(player, car, model)
	if session == nil
		or not sameTrade(session.car, car)
		or session.model ~= model
		or session.finishing
		or not session.autopilot
	then
		return
	end
	session.autopilot = false
	session.finishing = false
	setNativeSeatAutomationLocked(session, false)
	local active = DealerCar.active(session.player, session.workingIndex)
	if active ~= nil then
		session.car = active
	end
	session.model:SetAttribute("DealerSlot", "working")
	session.model:SetAttribute("State", "Ready")
	session.model:SetAttribute("WorkingSlotIndex", session.workingIndex)
	session.model:SetAttribute("ListingWorkingIndex", session.workingIndex)
	session.model:SetAttribute("ListingDisplayIndex", session.displayIndex)
	session.model:SetAttribute("ListingAutopilot", nil)
	session.model:SetAttribute("ListingTransport", "Ready")
	if session.target == nil or session.target.Parent == nil then
		session.target = createTarget(session)
	end
	ejectSeat(session)
end

function ListingTransport.completeAutopilot(player: Player, record: Record, car: any, model: Model)
	local session = sessionFor(player, car, model)
	if session == nil
		or session.record ~= record
		or not sameTrade(session.car, car)
		or session.model ~= model
		or not session.autopilot
		or session.finishing
		or not valid(session)
	then
		return
	end
	snapToSale(session)
	if isInsideTarget(session) then
		finish(session)
	end
end

function ListingTransport.isAtTarget(player: Player, record: Record, car: any, model: Model): boolean
	local session = sessionFor(player, car, model)
	return session ~= nil
		and session.record == record
		and sameTrade(session.car, car)
		and session.model == model
		and session.finishing
		and valid(session)
		and isInsideTarget(session)
end

function ListingTransport.prepareCommit(
	player: Player,
	record: Record,
	car: any,
	model: Model
): (boolean, number?, number?)
	if not ListingTransport.isAtTarget(player, record, car, model) then
		return false
	end
	local session = sessionFor(player, car, model)
	if session == nil then
		return false
	end
	local listingSeat = session.seat
	local character = player.Character
	local ownerHumanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	local ownerSeat = if ownerHumanoid ~= nil then ownerHumanoid.SeatPart else nil
	-- Native drivable rigs can replace the temporary listing seat. Remember whether the
	-- owner was attached to any seat in this exact car before ejectSeat clears the session.
	local ownerWasDriving = ownerSeat ~= nil and ownerSeat:IsDescendantOf(model)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local trappedInside = false
	if character ~= nil then
		local localPosition = boxCFrame:PointToObjectSpace(character:GetPivot().Position)
		local half = boxSize * 0.5 + Vector3.new(2.5, 3.5, 2.5)
		trappedInside = math.abs(localPosition.X) <= half.X
			and math.abs(localPosition.Y) <= half.Y
			and math.abs(localPosition.Z) <= half.Z
	end
	local ejectedOwner = ejectSeat(session)
	local shouldMoveOwner = session.warnReason ~= "abandoned"
		and (ejectedOwner or ownerWasDriving or trappedInside)
	if shouldMoveOwner and character ~= nil then
		local sale = LotSlots.saleCFrame(record, session.displayIndex)
		-- Every P slot uses the proven P1 local exit: driver's side of the parked car,
		-- facing back toward it. This remains stable across both rows and all rotated tycoons.
		local sideDistance = math.max(6.5, boxSize.X * 0.5 + 2.5)
		local exitPosition = (sale * CFrame.new(-sideDistance, 3.5, 0)).Position
		local facePosition = Vector3.new(sale.Position.X, exitPosition.Y, sale.Position.Z)
		local exitFrame = CFrame.lookAt(exitPosition, facePosition)

		local function forceExit()
			if player.Character ~= character or character.Parent == nil then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				local currentSeat = humanoid.SeatPart
				humanoid.Sit = false
				if currentSeat ~= nil then
					local currentWeld = currentSeat:FindFirstChild("SeatWeld")
					if currentWeld ~= nil then
						currentWeld:Destroy()
					end
				end
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			if listingSeat ~= nil and listingSeat.Parent ~= nil then
				local seatWeld = listingSeat:FindFirstChild("SeatWeld")
				if seatWeld ~= nil then
					seatWeld:Destroy()
				end
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if root ~= nil and root:IsA("BasePart") then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			character:PivotTo(exitFrame)
		end

		forceExit()
		for _, delaySeconds in { 0.05, 0.15, 0.35, 0.7 } do
			task.delay(delaySeconds, forceExit)
		end
	end
	destroyTarget(session)
	return true, session.displayIndex, session.workingIndex
end

local function ejectOwnerBeforeRecovery(session: Session)
	local character = session.player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if character == nil or humanoid == nil then
		return
	end
	local seat = session.seat
	local seatPart = humanoid.SeatPart
	local attached = (seat ~= nil and seat.Parent ~= nil and seat.Occupant == humanoid)
		or (seatPart ~= nil and seatPart:IsDescendantOf(session.model))
	local boxCFrame, boxSize = session.model:GetBoundingBox()
	local localPosition = boxCFrame:PointToObjectSpace(character:GetPivot().Position)
	local half = boxSize * 0.5 + Vector3.new(1.5, 2.5, 1.5)
	local trappedInside = math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Y) <= half.Y
		and math.abs(localPosition.Z) <= half.Z
	if not attached and not trappedInside then
		return
	end

	-- Recovery moves the listing car back to its authoritative Used Cars working spot.
	-- Keep its driver with it instead of leaving the avatar stranded where the timeout fired.
	local parked = LotSlots.parkedCFrame(session.record, session.workingIndex)
	local _, modelSize = session.model:GetBoundingBox()
	local sideDistance = math.max(6.5, modelSize.X * 0.5 + 2.5)
	local exitPosition = (parked * CFrame.new(-sideDistance, 3.5, 0)).Position
	local facePosition = Vector3.new(parked.Position.X, exitPosition.Y, parked.Position.Z)
	local recoveryFrame = CFrame.lookAt(exitPosition, facePosition)

	local function forceExit()
		if session.player.Character ~= character or character.Parent == nil then
			return
		end
		humanoid.Sit = false
		local currentSeat = humanoid.SeatPart
		if currentSeat ~= nil then
			local currentWeld = currentSeat:FindFirstChild("SeatWeld")
			if currentWeld ~= nil then
				currentWeld:Destroy()
			end
		end
		if seat ~= nil and seat.Parent ~= nil then
			local seatWeld = seat:FindFirstChild("SeatWeld")
			if seatWeld ~= nil then
				seatWeld:Destroy()
			end
		end
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root ~= nil and root:IsA("BasePart") then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		character:PivotTo(recoveryFrame)
	end

	forceExit()
	for _, delaySeconds in { 0.05, 0.15, 0.35, 0.7 } do
		task.delay(delaySeconds, forceExit)
	end
end

recoverForSalesman = function(session: Session, silent: boolean?)
	if not authoritativeWorking(session) then
		return
	end
	local ejected, ejectError = pcall(ejectOwnerBeforeRecovery, session)
	if not ejected then
		warn(`[ListingTransport] owner eject failed before recovery: {ejectError}`)
	end
	local inputs = session.model:FindFirstChild("Inputs")
	if inputs ~= nil then
		inputs:SetAttribute("throttleInput", 0)
		inputs:SetAttribute("steeringInput", 0)
		inputs:SetAttribute("handBrakeInput", true)
	end
	for _, descendant in session.model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			descendant.Anchored = true
		end
	end
	local parked = LotSlots.parkedCFrame(session.record, session.workingIndex)
	session.model:PivotTo(parked)
	local visualOk, visualError = pcall(function()
		CarVisuals.settle(
			session.model,
			LotSlots.platformTop(session.record, session.workingIndex),
			DealerCarConfig.PARK_CLEARANCE
		)
		CarVisuals.resetWheels(session.model, session.wheels)
		CarVisuals.setRunningLights(session.model, false)
	end)
	if not visualOk then
		warn(`[ListingTransport] recovery visuals failed after car return: {visualError}`)
		session.model:PivotTo(parked)
	end
	session.throttle = 0
	session.steer = 0
	session.speed = 0
	session.wasDriven = false
	session.manualStarted = false
	session.manualStartedAt = 0
	session.longTestDrive = false
	session.claimAnnounced = false
	session.assistOffered = false
	session.unoccupiedSince = 0
	session.recoveryDeadline = 0
	session.recoveryStage = 0
	session.warnReason = nil
	session.autopilot = false
	session.finishing = false
	setNativeSeatAutomationLocked(session, true)
	local active = DealerCar.active(session.player, session.workingIndex)
	if active ~= nil then
		session.car = active
	end
	session.model:SetAttribute("DealerSlot", "working")
	session.model:SetAttribute("State", "Ready")
	session.model:SetAttribute("WorkingSlotIndex", session.workingIndex)
	session.model:SetAttribute("ListingWorkingIndex", session.workingIndex)
	session.model:SetAttribute("ListingDisplayIndex", session.displayIndex)
	session.model:SetAttribute("ListingAutopilot", nil)
	session.model:SetAttribute("ListingTransport", "Ready")
	if session.target == nil or session.target.Parent == nil then
		session.target = createTarget(session)
	end
	ejectSeat(session)
	if silent ~= true then
		notify(session, "Boss, I recovered the car. I'll take it to " .. saleSpotName(session.displayIndex) .. ".", 5)
	end
	DealerCar.publish(session.player)
	DealerCar.stateChanged:Fire(session.player, "Ready", "working", session.workingIndex)
end

-- Public idempotent recovery hook for the automation watchdog. A stale staff coroutine must
-- never keep a Ready W car leased forever; either restore the authoritative session or cancel
-- a session whose exact W identity no longer exists.
function ListingTransport.recoverNow(player: Player, silent: boolean?): boolean
	local session = automationSessions[player] or sessions[player]
	if session == nil then
		return false
	end
	if not authoritativeWorking(session) then
		cancelSession(session)
		return false
	end
	local recover = recoverForSalesman
	if recover == nil then
		cancelSession(session)
		return false
	end
	local ok, err = pcall(recover, session, silent)
	if not ok then
		warn(`[ListingTransport] watchdog recovery failed: {err}`)
		cancelSession(session)
		return false
	end
	return registered(session) and valid(session)
end

local function monitorManualRecovery(session: Session, seated: boolean): boolean
	if not session.manualStarted then
		return false
	end
	if isInsideTarget(session) then
		return false
	end
	local now = os.clock()
	local position = session.model:GetPivot().Position
	local repair = LotSlots.parkedCFrame(session.record, session.workingIndex).Position
	local sale = LotSlots.saleCFrame(session.record, session.displayIndex).Position
	local nearest = math.min(horizontalDistance(position, repair), horizontalDistance(position, sale))
	local far = nearest > OUT_OF_BOUNDS_RADIUS or position.Y < -20 or position.Y > 120
	local manualAge = if session.manualStartedAt > 0 then now - session.manualStartedAt else 0
	local timeoutSeconds = if session.longTestDrive then NO_MECHANIC_MANUAL_TIMEOUT else MANUAL_TIMEOUT
	local graceElapsed = manualAge >= timeoutSeconds

	if seated then
		session.unoccupiedSince = 0
	else
		if session.unoccupiedSince == 0 then
			session.unoccupiedSince = now
		end
	end

	if session.recoveryDeadline > 0 then
		local corrected = if session.warnReason == "abandoned"
			then seated
			else session.warnReason ~= "timeout" and ((seated and not far) or nearest <= ABANDON_DISTANCE)
		if corrected then
			session.recoveryDeadline = 0
			session.recoveryStage = 0
			session.warnReason = nil
		elseif now >= session.recoveryDeadline then
			if session.warnReason == "abandoned" then
				-- An abandoned-car recovery never teleports the owner. The car completes its
				-- reserved listing, then an optional Home control appears in the existing HUD.
				finish(session)
				offerReturnHome(session)
				return true
			elseif session.warnReason == "timeout" and session.longTestDrive then
				if session.recoveryStage < #REX_WARNING_LINES then
					session.recoveryStage += 1
					session.recoveryDeadline = now + REX_WARNING_INTERVAL
					notifyRex(session, session.recoveryStage)
				else
					finish(session)
					return true
				end
			elseif session.recoveryStage == 1 then
				session.recoveryStage = 2
				session.recoveryDeadline = now + WARNING_INTERVAL
				notify(session, recoveryWarningLine(session), 9, true)
			elseif session.recoveryStage == 2 then
				session.recoveryStage = 3
				session.recoveryDeadline = now + WARNING_INTERVAL
				notify(session, recoveryWarningLine(session), 9, true)
			else
				-- The display slot was reserved before manual driving began, so a timeout can
				-- complete the listing safely. If that commit is rejected because the slot
				-- changed, finish()'s watchdog falls back to the Used Cars working spot and
				-- ejectOwnerBeforeRecovery keeps the player beside the recovered car.
				finish(session)
				return true
			end
		end
	elseif not seated and session.unoccupiedSince > 0 then
		local seconds = if far then FAR_ABANDON_SECONDS else NEAR_ABANDON_SECONDS
		session.warnReason = "abandoned"
		session.recoveryStage = 1
		session.recoveryDeadline = session.unoccupiedSince + seconds
		notifyAbandonCountdown(session, seconds)
	elseif far and graceElapsed then
		session.warnReason = "far"
		session.recoveryStage = 1
		session.recoveryDeadline = now + WARNING_INTERVAL
		notify(session, recoveryWarningLine(session), 9, true)
	elseif graceElapsed then
		session.warnReason = "timeout"
		session.recoveryStage = 1
		if session.longTestDrive then
			session.recoveryDeadline = now + REX_WARNING_INTERVAL
			notifyRex(session, 1)
		else
			session.recoveryDeadline = now + WARNING_INTERVAL
			notify(session, recoveryWarningLine(session), 9, true)
		end
	end
	return false
end

Remotes.ParkAssist.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if session == nil
		or not session.assistOffered
		or not session.manualStarted
		or session.autopilot
		or session.finishing
		or not valid(session)
		or player:GetAttribute("TutorialComplete") == true
	then
		return
	end
	session.assistOffered = false
	Remotes.ListingNotice:FireClient(player, { clearGuide = true, duration = 2 })
	finish(session)
end)

Remotes.ListingDriveInput.OnServerEvent:Connect(function(player: Player, throttle: unknown, steer: unknown)
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	local session = sessions[player]
	if session == nil or not valid(session) or session.autopilot or session.finishing then
		return
	end
	local now = os.clock()
	if now - session.lastPacket < PACKET_INTERVAL then
		return
	end
	local seat = session.seat
	if seat == nil or seat.Occupant ~= ownerHumanoid(session) then
		return
	end
	session.lastPacket = now
	session.lastInput = now
	session.throttle = math.clamp(throttle, -1, 1)
	session.steer = math.clamp(steer, -1, 1)
	session.wasDriven = true
end)

local returnHomeAt: { [Player]: number } = {}
Remotes.ReturnHome.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (returnHomeAt[player] or 0) < 1 then
		return
	end
	returnHomeAt[player] = now
	if returnHomeAvailable[player] ~= true then
		return
	end
	local record = TycoonService.getForPlayer(player)
	if record == nil or record.owner ~= player then
		return
	end
	returnHomeAvailable[player] = nil
	TycoonService.moveToTycoon(player, record, player.Character)
end)

RunService.Heartbeat:Connect(function(delta: number)
	-- Salesman motion is owned by StaffDirector, but its exact W→P lease still needs
	-- validation and cleanup while the player drives a different session.
	for _, session in automationSessions do
		if not valid(session) then
			local recovered = false
			local recover = recoverForSalesman
			if authoritativeWorking(session) and recover ~= nil then
				local ok, err = pcall(recover, session)
				if not ok then
					warn(`[ListingTransport] invalid automation-session recovery failed: {err}`)
				end
				recovered = ok and registered(session) and valid(session)
			end
			if registered(session) and not recovered then
				cancelSession(session)
			end
		end
	end

	for player, session in sessions do
		if not valid(session) then
			local recovered = false
			local recover = recoverForSalesman
			if authoritativeWorking(session) and recover ~= nil then
				local ok, err = pcall(recover, session)
				if not ok then
					warn(`[ListingTransport] invalid-session recovery failed: {err}`)
				end
				recovered = ok and registered(session) and valid(session)
			end
			if registered(session) and not recovered then
				cancelSession(session)
			end
			continue
		end
		if session.autopilot or session.finishing then
			continue
		end

		local seat = session.seat
		local seated = seat ~= nil and seat.Occupant == ownerHumanoid(session)
		if monitorManualRecovery(session, seated) then
			continue
		end
		if session.nativeRig then
			if seated then
				session.wasDriven = true
			end
			if session.wasDriven and isInsideTarget(session) then
				finish(session)
			end
			continue
		end
		local throttle = if seated and os.clock() - session.lastInput <= INPUT_TIMEOUT then session.throttle else 0
		local steer = if seated and os.clock() - session.lastInput <= INPUT_TIMEOUT then session.steer else 0
		local desired = if throttle >= 0 then throttle * MAX_FORWARD_SPEED else throttle * MAX_REVERSE_SPEED
		local changingDirection = desired ~= 0 and session.speed ~= 0 and math.sign(desired) ~= math.sign(session.speed)
		local slowing = math.abs(desired) < math.abs(session.speed)
		local rate = if changingDirection or slowing then BRAKING else ACCELERATION
		local difference = desired - session.speed
		session.speed += math.clamp(difference, -rate * delta, rate * delta)
		if math.abs(session.speed) < 0.03 then
			session.speed = 0
		end

		if session.speed ~= 0 then
			local frame = session.model:GetPivot()
			local speedFactor = math.clamp(math.abs(session.speed) / 8, 0.18, 1)
			local yaw = -steer * TURN_RATE * speedFactor * math.sign(session.speed) * delta
			local turned = frame * CFrame.Angles(0, yaw, 0)
			local nextPosition = turned.Position + turned.LookVector * session.speed * delta
			local repair = LotSlots.parkedCFrame(session.record, session.workingIndex).Position
			local sale = LotSlots.saleCFrame(session.record, session.displayIndex).Position
			if math.min(horizontalDistance(nextPosition, repair), horizontalDistance(nextPosition, sale)) <= MAX_ROUTE_RADIUS then
				local flatLook = Vector3.new(turned.LookVector.X, 0, turned.LookVector.Z)
				local nextFrame = CFrame.lookAt(nextPosition, nextPosition + flatLook.Unit)
				session.model:PivotTo(nextFrame)
				local radius = (session.model:GetAttribute("WheelRadius") :: number?) or 1.2
				session.spin = (session.spin + session.speed / radius * delta) % (math.pi * 2)
				CarVisuals.applyWheels(nextFrame, session.wheels, steer * 0.42, session.spin)
			else
				session.speed = 0
			end
		end

		if session.wasDriven and isInsideTarget(session) then
			finish(session)
		end
	end
end)

return ListingTransport
