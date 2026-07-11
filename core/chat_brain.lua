local S = minions.S

local ChatBrain = {}
ChatBrain.__index = ChatBrain

ChatBrain.GREET_MIN_INTERVAL = 2
ChatBrain.GREET_MAX_INTERVAL = 3
ChatBrain.NO_PLAYER_RETRY = 1.0

function ChatBrain.new(minion)
	local self = setmetatable({}, ChatBrain)
	self.minion = minion
	self._cd = self:_next_greet_cd()
	return self
end

function ChatBrain:think(dtime)
	local chat = self.minion._chat
	while chat:has_incoming() do
		chat:pop_incoming()
	end
	self._cd = self._cd - dtime
	if self._cd <= 0 then
		if self:_sees_player() then
			chat:say("hello")
			self._cd = self:_next_greet_cd()
		else
			self._cd = ChatBrain.NO_PLAYER_RETRY
		end
	end
end

function ChatBrain:_next_greet_cd()
	return ChatBrain.GREET_MIN_INTERVAL + math.random() * (ChatBrain.GREET_MAX_INTERVAL - ChatBrain.GREET_MIN_INTERVAL)
end

function ChatBrain:_sees_player()
	for _, seen in ipairs(self.minion._vision:visible()) do
		if seen.type == "player" then
			return true
		end
	end
	return false
end

minions.ChatBrain = ChatBrain
return ChatBrain