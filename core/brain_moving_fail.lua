local S = minions.S

local BrainMovingFail = {}
BrainMovingFail.__index = BrainMovingFail
BrainMovingFail.THINK_PERIOD = 3

function BrainMovingFail.new(minion, brain)
	local self = setmetatable({}, BrainMovingFail)
	self.minion = minion
	self._brain = brain
	self._timer = 0
	return self
end

function BrainMovingFail:get_staticdata()
	return {timer = self._timer}
end

function BrainMovingFail:restore(data)
	if data and data.timer then
		self._timer = data.timer
	end
end

function BrainMovingFail:think(dtime)
	self._timer = self._timer + dtime
	if self._timer >= BrainMovingFail.THINK_PERIOD then
		self._timer = self._timer - BrainMovingFail.THINK_PERIOD
		self._brain._state:set(minions.State.IDLE)
	end
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

minions.BrainMovingFail = BrainMovingFail
return BrainMovingFail