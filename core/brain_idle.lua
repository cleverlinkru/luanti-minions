local S = minions.S

local BrainIdle = {}
BrainIdle.__index = BrainIdle

function BrainIdle.new(minion)
	local self = setmetatable({}, BrainIdle)
	self.minion = minion
	return self
end

function BrainIdle:think(dtime)
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

minions.BrainIdle = BrainIdle
return BrainIdle