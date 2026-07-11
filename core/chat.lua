local S = minions.S

local Chat = {}
Chat.__index = Chat

Chat.HEAR_RADIUS = 8
Chat.SAY_DURATION = 3.0

Chat.MESSAGES = {
	hello    = "Bello!",
	bye      = "Poopaye!",
	thanks   = "Tank yu!",
	yes      = "Poulet tiki masala!",
	no       = "Tulaliloo ti amo!",
	banana   = "BANANA!",
	happy    = "Papoy!",
	confused = "Whaaat?",
	hungry   = "Me want banana!",
	laugh    = "Hehehe!",
	sing     = "La la la!",
	work     = "Me go work!",
	sorry    = "Bapples...",
	wow      = "Bee do bee do!",
	heard    = "услышал",
}

function Chat.new(minion)
	local self = setmetatable({}, Chat)
	self.minion = minion
	self._inbox = {}
	self._current_code = nil
	self._current_text = nil
	self._current_time = 0
	return self
end

function Chat:say(code, opts)
	local text = Chat.MESSAGES[code]
	if not text then return false end
	local to = opts and opts.to or nil
	local display = text
	if to and to._name then
		display = to._name:get() .. ", " .. text
	end
	local msg = minions.Message.new(code, {
		from = self.minion,
		to = to,
	})
	self._current_code = code
	self._current_text = display
	self._current_time = Chat.SAY_DURATION
	self:_broadcast(msg)
	return true
end

function Chat:current_text()
	return self._current_text
end

function Chat:has_incoming()
	return #self._inbox > 0
end

function Chat:pop_incoming()
	return table.remove(self._inbox, 1)
end

function Chat:hear(msg)
	table.insert(self._inbox, msg)
end

function Chat:update(dtime)
	if self._current_time > 0 then
		self._current_time = self._current_time - dtime
		if self._current_time <= 0 then
			self._current_code = nil
			self._current_text = nil
		end
	end
end

function Chat:_broadcast(msg)
	local pos = self.minion.object:get_pos()
	if not pos then return end
	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, Chat.HEAR_RADIUS)) do
		local ent = obj:get_luaentity()
		if ent and ent.minion and ent.minion ~= self.minion and ent.minion._chat then
			ent.minion._chat:hear(msg)
		end
	end
end

minions.Chat = Chat
return Chat