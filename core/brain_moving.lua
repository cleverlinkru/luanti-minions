local S = minions.S

local BrainMoving = {}
BrainMoving.__index = BrainMoving

function BrainMoving.new(minion)
	local self = setmetatable({}, BrainMoving)
	self.minion = minion
	return self
end

function BrainMoving:think(dtime)
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

minions.BrainMoving = BrainMoving
return BrainMoving