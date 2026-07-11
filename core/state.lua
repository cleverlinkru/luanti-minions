local S = minions.S

local State = {}
State.__index = State

State.IDLE = "idle"
State.MOVING = "moving"
State.MOVING_FAIL = "moving_fail"

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

function State:get_staticdata()
	return {current = self._current}
end

function State:restore(data)
	if data and data.current then
		self._current = data.current
	end
end

minions.State = State
return State