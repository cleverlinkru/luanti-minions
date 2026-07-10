local S = minions.S

local PlayerBrain = setmetatable({}, {__index = minions.Brain})
PlayerBrain.__index = PlayerBrain

function PlayerBrain.new(minion, player)
	local self = setmetatable(minions.Brain.new(minion), PlayerBrain)
	self.player_name = player:get_player_name()
	return self
end

function PlayerBrain:think(dtime)
	local player = minetest.get_player_by_name(self.player_name)
	if not player then
		return {
			forward = false,
			backward = false,
			turn_left = false,
			turn_right = false,
			jump = false,
			sneak = false,
		}
	end
	local ctrl = player:get_player_control()
	return {
		forward = ctrl.up,
		backward = ctrl.down,
		turn_left = ctrl.left,
		turn_right = ctrl.right,
		jump = ctrl.jump or ctrl.aux1,
		sneak = ctrl.sneak,
	}
end

minions.PlayerBrain = PlayerBrain
return PlayerBrain