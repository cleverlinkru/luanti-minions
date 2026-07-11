local S = minions.S

local State = {}
State.__index = State

State.IDLE = "idle"
State.MOVING = "moving"

function State.new(minion)
	local self = setmetatable({}, State)
	self.minion = minion
	self._current = State.IDLE
	return self
end

function State:get()
	return self._current
end

function State:set(state)
	self._current = state
end

function State:is(state)
	return self._current == state
end

minions.State = State
return State