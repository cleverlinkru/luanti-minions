local S = minions.S

local Brain = {}
Brain.__index = Brain

function Brain.new(minion)
	local self = setmetatable({}, Brain)
	self.minion = minion
	self._state = minions.State.new(minion)
	self._brain_chat = minions.BrainChat.new(minion)
	self._brain_idle = minions.BrainIdle.new(minion)
	return self
end

function Brain:think(dtime)
	self._brain_chat:think(dtime)
	self._brain_idle:think(dtime)
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

function Brain:on_punch(puncher, time_from_last_punch, tool_capabilities)
end

function Brain:on_rightclick(clicker)
end

function Brain:get_staticdata()
	return {state = self._state:get_staticdata()}
end

function Brain:restore(data)
	if data and data.state then
		self._state:restore(data.state)
	end
end

minions.Brain = Brain
return Brain