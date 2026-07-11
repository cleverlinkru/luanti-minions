local S = minions.S

local ChatBrain = {}
ChatBrain.__index = ChatBrain

ChatBrain.SAY_MIN_INTERVAL = 6
ChatBrain.SAY_MAX_INTERVAL = 18

function ChatBrain.new(minion)
	local self = setmetatable({}, ChatBrain)
	self.minion = minion
	self._speak_cd = self:_next_speak_cd()
	self._codes = {}
	for code in pairs(minions.Chat.MESSAGES) do
		if code ~= "heard" then
			table.insert(self._codes, code)
		end
	end
	return self
end

function ChatBrain:think(dtime)
	local chat = self.minion._chat
	local heard_something = false
	while chat:has_incoming() do
		local msg = chat:pop_incoming()
		if msg.code ~= "heard" then
			heard_something = true
		end
	end
	if heard_something then
		chat:say("heard")
		return
	end
	self._speak_cd = self._speak_cd - dtime
	if self._speak_cd <= 0 then
		self:_say_random()
		self._speak_cd = self:_next_speak_cd()
	end
end

function ChatBrain:_next_speak_cd()
	return self.SAY_MIN_INTERVAL + math.random() * (self.SAY_MAX_INTERVAL - self.SAY_MIN_INTERVAL)
end

function ChatBrain:_say_random()
	if #self._codes == 0 then return end
	local code = self._codes[math.random(#self._codes)]
	self.minion._chat:say(code)
end

minions.ChatBrain = ChatBrain
return ChatBrain