local S = minions.S

local Message = {}
Message.__index = Message

function Message.new(code, opts)
	opts = opts or {}
	local self = setmetatable({}, Message)
	self.code = code
	self.from = opts.from
	self.to = opts.to
	return self
end

function Message:is_broadcast()
	return self.to == nil
end

function Message:is_for(minion)
	return self.to == minion
end

minions.Message = Message
return Message