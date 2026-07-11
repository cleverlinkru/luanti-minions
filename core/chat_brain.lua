local S = minions.S

local ChatBrain = {}
ChatBrain.__index = ChatBrain

ChatBrain.SAY_MIN_INTERVAL = 6
ChatBrain.SAY_MAX_INTERVAL = 18
ChatBrain.ADDRESS_CHANCE = 0.4

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
	local should_respond = false
	while chat:has_incoming() do
		local msg = chat:pop_incoming()
		if msg.code ~= "heard" then
			if msg:is_broadcast() or msg:is_for(self.minion) then
				should_respond = true
			end
		end
	end
	if should_respond then
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
	local to = nil
	if math.random() < ChatBrain.ADDRESS_CHANCE then
		to = self:_pick_nearby_minion()
	end
	self.minion._chat:say(code, {to = to})
end

function ChatBrain:_pick_nearby_minion()
	local pos = self.minion.object:get_pos()
	if not pos then return nil end
	local candidates = {}
	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, minions.Chat.HEAR_RADIUS)) do
		local ent = obj:get_luaentity()
		if ent and ent.minion and ent.minion ~= self.minion then
			table.insert(candidates, ent.minion)
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(#candidates)]
end

minions.ChatBrain = ChatBrain
return ChatBrain