local S = minions.S

local Brain = {}
Brain.__index = Brain

function Brain.new(minion)
	local self = setmetatable({}, Brain)
	self.minion = minion
	self._state = minions.State.new(minion)
	self._brain_idle = minions.BrainIdle.new(minion, self)
	self._brain_moving = minions.BrainMoving.new(minion, self)
	self._brain_moving_fail = minions.BrainMovingFail.new(minion, self)
	self._brain_chat = minions.BrainChat.new(minion)
	self._brain_vision = minions.BrainVision.new(minion)
	self._command = {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
	return self
end

function Brain:think(dtime)
	local command
	if self._state:is(minions.State.IDLE) then
		command = self._brain_idle:think(dtime)
	elseif self._state:is(minions.State.MOVING) then
		command = self._brain_moving:think(dtime)
	elseif self._state:is(minions.State.MOVING_FAIL) then
		command = self._brain_moving_fail:think(dtime)
	end
	if command then
		self._command = command
	end
	return self._command
end

function Brain:get_staticdata()
	return {
		state = self._state:get_staticdata(),
		idle = self._brain_idle:get_staticdata(),
		moving = self._brain_moving:get_staticdata(),
		moving_fail = self._brain_moving_fail:get_staticdata(),
	}
end

function Brain:restore(data)
	if not data then return end
	if data.state then self._state:restore(data.state) end
	if data.idle then self._brain_idle:restore(data.idle) end
	if data.moving then self._brain_moving:restore(data.moving) end
	if data.moving_fail then self._brain_moving_fail:restore(data.moving_fail) end
end

minions.Brain = Brain
return Brain