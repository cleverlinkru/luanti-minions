local S = minions.S

local ChatBrain = {}
ChatBrain.__index = ChatBrain

function ChatBrain.new(minion)
	local self = setmetatable({}, ChatBrain)
	self.minion = minion
	return self
end

function ChatBrain:think(dtime)
end

minions.ChatBrain = ChatBrain
return ChatBrain