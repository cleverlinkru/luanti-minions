local S = minions.S

local BrainVision = {}
BrainVision.__index = BrainVision

function BrainVision.new(minion)
	local self = setmetatable({}, BrainVision)
	self.minion = minion
	return self
end

function BrainVision:think(dtime)
end

minions.BrainVision = BrainVision
return BrainVision