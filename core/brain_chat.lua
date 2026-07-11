local S = minions.S

local BrainChat = {}
BrainChat.__index = BrainChat

function BrainChat.new(minion)
	local self = setmetatable({}, BrainChat)
	self.minion = minion
	return self
end

function BrainChat:think(dtime)
end

minions.BrainChat = BrainChat
return BrainChat