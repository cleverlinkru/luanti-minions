local S = minions.S

local Brain = {}
Brain.__index = Brain

function Brain.new(minion)
	local self = setmetatable({}, Brain)
	self.minion = minion
	return self
end

function Brain:think(dtime)
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

function Brain:on_punch(puncher, time_from_last_punch, tool_capabilities)
end

function Brain:on_rightclick(clicker)
end

minions.Brain = Brain
return Brain