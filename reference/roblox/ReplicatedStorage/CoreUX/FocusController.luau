local FocusController = {}
FocusController.__index = FocusController

function FocusController.new(onChanged)
	return setmetatable({
		claims = {},
		activeOwner = nil,
		activePriority = -math.huge,
		onChanged = onChanged,
	}, FocusController)
end

function FocusController:_resolve()
	local owner
	local priority = -math.huge
	for candidate, candidatePriority in pairs(self.claims) do
		if candidatePriority > priority then
			owner = candidate
			priority = candidatePriority
		end
	end

	if owner ~= self.activeOwner or priority ~= self.activePriority then
		local previous = self.activeOwner
		self.activeOwner = owner
		self.activePriority = priority
		if self.onChanged then
			self.onChanged(owner, previous, priority)
		end
	end
end

function FocusController:Acquire(owner, priority)
	assert(type(owner) == "string", "Focus owner must be a string")
	self.claims[owner] = priority or 0
	self:_resolve()
	return self.activeOwner == owner
end

function FocusController:Release(owner)
	self.claims[owner] = nil
	self:_resolve()
end

function FocusController:IsActive(owner)
	return self.activeOwner == owner
end

function FocusController:CanShow(priority)
	return self.activeOwner == nil or priority >= self.activePriority
end

function FocusController:Clear()
	table.clear(self.claims)
	self:_resolve()
end

return FocusController


