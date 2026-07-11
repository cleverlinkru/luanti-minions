local S = minions.S

local BrainIdle = {}
BrainIdle.__index = BrainIdle

function BrainIdle.new(minion)
	local self = setmetatable({}, BrainIdle)
	self.minion = minion
	return self
end

function BrainIdle:think(dtime)
end

minions.BrainIdle = BrainIdle
return BrainIdle