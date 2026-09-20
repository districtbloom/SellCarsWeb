-- Server-authoritative boundary between the core loop and Gio's negotiation layer.
-- No RemoteEvent can resolve a trade or choose a payout.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayEvents = require(script.Parent.GameplayEvents)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local TownsfolkConfig = require(ReplicatedStorage.TownsfolkConfig)

local TradeContract = {}

-- One player can have one authoritative ticket per displayed car. Purchase and sale
-- callbacks are still keyed by immutable tradeId, but display lanes no longer overwrite one
-- another when several buyers arrive together.
local pending = {}
local resolver = nil

local function pendingBucket(player, create)
	local bucket = pending[player.UserId]
	if bucket == nil and create then
		bucket = {}
		pending[player.UserId] = bucket
	end
	return bucket
end

local function pendingEntry(player, tradeId)
	local bucket = pendingBucket(player, false)
	return if bucket ~= nil then bucket[tradeId] else nil
end

local function removeEntry(player, tradeId)
	local bucket = pendingBucket(player, false)
	if bucket == nil then return end
	bucket[tradeId] = nil
	if next(bucket) == nil then pending[player.UserId] = nil end
end

local function finiteNumber(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function authoritativeFixedOffer(payload)
	local fixed = payload.fixedOffer
	if finiteNumber(fixed) and fixed > 0 then
		return math.floor(fixed)
	end
	return nil
end

local function fallbackOffer(payload)
	local fixed = authoritativeFixedOffer(payload)
	if fixed ~= nil then
		return fixed
	end
	local listed = math.max(1, math.floor(tonumber(payload.listedPrice) or 1))
	local deal = math.floor(tonumber(payload.tutorialDealIndex) or 0)
	if deal == 1 then
		return 210
	elseif deal == 2 then
		-- Covers the $44 worst-case seller ask without inventing a client-side amount.
		return math.max(259, math.floor(listed * 0.95))
	elseif deal == 3 then
		-- Compatibility for an older caller that has not forwarded fixedOffer yet.
		return 5000
	end
	local person = TownsfolkConfig.get(payload.personId)
	local wealthMultiplier = TownsfolkConfig.offerMultiplier(person)
	local oneInN = if finiteNumber(payload.rarityOneInN) then payload.rarityOneInN else select(1, DealerCarConfig.rarityOf(payload.carId))
	local rarity = DealerCarConfig.rarityTier(oneInN)
	return math.max(1, math.floor(listed * 0.92 * wealthMultiplier * (1 + rarity.offerBonus)))
end

local function copyPayload(payload)
	local copy = {}
	for key, value in payload do
		copy[key] = value
	end
	return copy
end

function TradeContract.newTradeId(player, templateId)
	return ("%d:%s:%s"):format(player.UserId, tostring(templateId), HttpService:GenerateGUID(false))
end

-- Resolver signature:
-- resolver(player, immutablePayload, resolveCallback) -> true when Gio owns the request.
function TradeContract.setResolver(callback)
	assert(callback == nil or typeof(callback) == "function", "resolver must be a function or nil")
	resolver = callback
end

function TradeContract.request(player, payload, onOffer, onResolved)
	assert(typeof(payload) == "table", "trade payload must be a table")
	assert(typeof(payload.tradeId) == "string" and payload.tradeId ~= "", "tradeId is required")
	assert(typeof(onOffer) == "function", "onOffer callback is required")
	assert(typeof(onResolved) == "function", "onResolved callback is required")

	local entry = {
		tradeId = payload.tradeId,
		payload = copyPayload(payload),
		onOffer = onOffer,
		onResolved = onResolved,
		mode = "pending",
		offer = nil,
	}
	pendingBucket(player, true)[entry.tradeId] = entry
	GameplayEvents.emit("OfferRequested", player, copyPayload(payload))

	if resolver ~= nil then
		local ok, handled = pcall(resolver, player, copyPayload(payload), function(result)
			TradeContract.resolve(player, payload.tradeId, result)
		end)
		if ok and handled == true then
			entry.mode = "gio"
			return
		elseif not ok then
			warn(("[TradeContract] Gio resolver failed for %s: %s"):format(player.Name, tostring(handled)))
		end
	end

	entry.mode = "fallback"
	entry.offer = fallbackOffer(payload)
	task.defer(function()
		if pendingEntry(player, entry.tradeId) == entry then
			GameplayEvents.emit("OfferReceived", player, {
				tradeId = entry.tradeId,
				currentOffer = entry.offer,
				carId = entry.payload.carId,
				tutorialDealIndex = entry.payload.tutorialDealIndex,
			})
			onOffer(entry.offer)
		end
	end)
end

-- Rebuilds a server-only fallback ticket for a saved Offer after rejoin.
function TradeContract.restoreFallback(player, payload, savedOffer, onResolved)
	if not finiteNumber(savedOffer) or savedOffer <= 0 then
		return false, nil
	end
	-- Rolling compatibility: an in-flight tutorial deal from an older server may have saved
	-- the former fallback amount. The new server-authored fixed offer replaces it on restore.
	local restoredOffer = authoritativeFixedOffer(payload) or math.floor(savedOffer)
	pendingBucket(player, true)[payload.tradeId] = {
		tradeId = payload.tradeId,
		payload = copyPayload(payload),
		onOffer = function() end,
		onResolved = onResolved,
		mode = "fallback",
		offer = restoredOffer,
	}
	-- The caller owns the saved car and uses this canonical amount to update its DTO before
	-- rendering. Returning it also keeps rolling fixed offers honest on Accept and Ask More.
	return true, restoredOffer
end

-- Raises the active server fallback offer exactly once through the authoritative ticket.
-- Gio-owned trades remain immutable here and must be handled by Gio's resolver.
function TradeContract.raiseFallback(player, tradeId, newOffer)
	if not finiteNumber(newOffer) or newOffer <= 0 then
		return false
	end
	local entry = pendingEntry(player, tradeId)
	if entry == nil or entry.mode ~= "fallback" or entry.offer == nil then
		return false
	end
	if authoritativeFixedOffer(entry.payload) ~= nil then
		return false
	end
	entry.offer = math.floor(newOffer)
	GameplayEvents.emit("OfferReceived", player, {
		tradeId = entry.tradeId,
		currentOffer = entry.offer,
		carId = entry.payload.carId,
		tutorialDealIndex = entry.payload.tutorialDealIndex,
	})
	return true
end

function TradeContract.resolve(player, tradeId, result)
	local entry = pendingEntry(player, tradeId)
	if entry == nil or typeof(result) ~= "table" then
		return false
	end

	local status = result.result or result.status
	if status ~= "Accepted" and status ~= "Walked" and status ~= "Declined" then
		return false
	end

	local finalOffer = 0
	if status == "Accepted" then
		local fixed = authoritativeFixedOffer(entry.payload)
		if fixed ~= nil then
			-- A resolver may decide whether the deal is accepted, but never the authored tutorial
			-- payout. Canonicalize here so neither client nor integration can alter the $5,000.
			finalOffer = fixed
		elseif not finiteNumber(result.finalOffer) then
			return false
		else
			finalOffer = math.floor(result.finalOffer)
		end
		local listed = math.max(1, math.floor(tonumber(entry.payload.listedPrice) or 1))
		local calculated = math.max(1, math.floor(tonumber(entry.payload.calculatedValue) or 1))
		local maxOffer = math.max(1000, listed * 4, calculated * 4)
		if finalOffer < 1 or finalOffer > maxOffer then
			return false
		end
		if entry.mode == "fallback" and finalOffer ~= entry.offer then
			return false
		end
	end

	-- Consume before firing callbacks: duplicate Gio callbacks and double-clicks are no-ops.
	removeEntry(player, tradeId)
	local canonical = {
		result = status,
		status = status,
		finalOffer = finalOffer,
		currentOffer = if status == "Accepted" and authoritativeFixedOffer(entry.payload) ~= nil
			then finalOffer
			elseif finiteNumber(result.currentOffer) then math.floor(result.currentOffer)
			else finalOffer,
		customerId = result.customerId,
		wealthTier = result.wealthTier,
		carRarity = result.carRarity,
		negotiationState = result.negotiationState,
		tradeId = tradeId,
		source = entry.mode,
	}
	if entry.mode ~= "fallback" then
		GameplayEvents.emit("OfferReceived", player, {
			tradeId = tradeId,
			currentOffer = canonical.currentOffer,
			carId = entry.payload.carId,
			tutorialDealIndex = entry.payload.tutorialDealIndex,
		})
	end
	GameplayEvents.emit("TradeResolved", player, canonical)
	task.spawn(entry.onResolved, canonical)
	return true
end

function TradeContract.acceptFallback(player, tradeId)
	local entry = pendingEntry(player, tradeId)
	if entry == nil or entry.mode ~= "fallback" or entry.offer == nil then
		return false
	end
	return TradeContract.resolve(player, tradeId, {
		status = "Accepted",
		finalOffer = entry.offer,
	})
end

function TradeContract.walkFallback(player, tradeId)
	local entry = pendingEntry(player, tradeId)
	if entry == nil or entry.mode ~= "fallback" then
		return false
	end
	return TradeContract.resolve(player, tradeId, { status = "Walked" })
end

function TradeContract.cancel(player, tradeId)
	if tradeId == nil then
		pending[player.UserId] = nil
	else
		removeEntry(player, tradeId)
	end
end

function TradeContract.pendingFor(player, tradeId)
	local bucket = pendingBucket(player, false)
	if bucket == nil then return nil end
	if tradeId ~= nil then
		local exact = bucket[tradeId]
		return if exact ~= nil then copyPayload(exact.payload) else nil
	end
	-- Compatibility for callers that only need to know whether anything is pending.
	local _, entry = next(bucket)
	return if entry ~= nil then copyPayload(entry.payload) else nil
end

function TradeContract.pendingAllFor(player)
	local result = {}
	local bucket = pendingBucket(player, false)
	if bucket ~= nil then
		for _, entry in pairs(bucket) do
			table.insert(result, copyPayload(entry.payload))
		end
	end
	return result
end

return TradeContract
