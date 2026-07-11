local S = minions.S

local BrainMoving = {}
BrainMoving.__index = BrainMoving

function BrainMoving.new(minion)
	local self = setmetatable({}, BrainMoving)
	self.minion = minion
	return self
end

function BrainMoving:think(dtime)
end

minions.BrainMoving = BrainMoving
return BrainMoving