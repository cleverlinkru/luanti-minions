local S = minions.S

local Minion = {}
Minion.__index = Minion

Minion.FORWARD_SPEED = 3.5
Minion.BACKWARD_SPEED = 2.0
Minion.TURN_SPEED = 3.0
Minion.JUMP_VEL = 5.0
Minion.JUMP_COOLDOWN = 0.5
Minion.WALK_FRAME_TIME = 0.22
Minion.FACING_OFFSET = math.pi
Minion.LABEL_RANGE = 30

function Minion:on_activate(staticdata, dtime_s)
	self._facing = 0
	self._name = nil
	if staticdata and staticdata ~= "" then
		local data = minetest.deserialize(staticdata)
		if type(data) == "table" then
			self._facing = data.facing or 0
			if data.name then
				self._name = minions.Name.from(data.name)
			end
		end
	end
	if not self._name then
		self._name = minions.Name.new()
	end

	self.object:set_acceleration({x = 0, y = -9.81, z = 0})
	self.object:set_yaw(self._facing + self.FACING_OFFSET)

	self._jump_cd = 0
	self._locked_player_name = nil
	self._locked_pos = nil

	self.object:set_nametag_attributes({
		text = "",
		color = {r = 255, g = 255, b = 255, a = 255},
		bgcolor = {r = 0, g = 0, b = 0, a = 128},
	})
	self._label_visible = false

	self._animator = minions.Animator.new(self.object)
	self._brain = minions.Brain.new(self)
	self._player_brain = nil
end

function Minion:get_staticdata()
	return minetest.serialize({
		facing = self._facing,
		name = self._name and self._name:get() or nil,
	})
end

function Minion:on_step(dtime)
	self:_update_label()

	local cmd = self:_active_brain():think(dtime)

	if cmd.sneak and self._player_brain then
		self:_unlock_player()
		self._player_brain = nil
		cmd = self._brain:think(dtime)
	end

	self:_clamp_locked_player()

	self._jump_cd = math.max(0, self._jump_cd - dtime)

	if cmd.turn_left then self._facing = self._facing + self.TURN_SPEED * dtime end
	if cmd.turn_right then self._facing = self._facing - self.TURN_SPEED * dtime end
	self.object:set_yaw(self._facing + self.FACING_OFFSET)

	local fwd = minetest.yaw_to_dir(self._facing)
	local vx, vz = 0, 0
	if cmd.forward then
		vx = fwd.x * self.FORWARD_SPEED
		vz = fwd.z * self.FORWARD_SPEED
	elseif cmd.backward then
		vx = -fwd.x * self.BACKWARD_SPEED
		vz = -fwd.z * self.BACKWARD_SPEED
	end
	local vel = self.object:get_velocity()
	local vy = vel.y
	if cmd.jump and self._jump_cd <= 0 and math.abs(vy) < 0.5 then
		vy = self.JUMP_VEL
		self._jump_cd = self.JUMP_COOLDOWN
	end
	self.object:set_velocity({x = vx, y = vy, z = vz})

	self._animator:set_moving(cmd.forward or cmd.backward)

	self._animator:update(dtime)
end

function Minion:on_punch(puncher, time_from_last_punch, tool_capabilities)
	self:_active_brain():on_punch(puncher, time_from_last_punch, tool_capabilities)
end

function Minion:on_rightclick(clicker)
	if clicker and clicker:is_player() then
		self:_unlock_player()
		self:_lock_player(clicker)
		self._player_brain = minions.PlayerBrain.new(self, clicker)
	end
	self:_active_brain():on_rightclick(clicker)
end

function Minion:_active_brain()
	return self._player_brain or self._brain
end

function Minion:_update_label()
	local pos = self.object:get_pos()
	if not pos then return end
	local range_sq = self.LABEL_RANGE * self.LABEL_RANGE
	local visible = false
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local dx, dy, dz = ppos.x - pos.x, ppos.y - pos.y, ppos.z - pos.z
		if dx * dx + dy * dy + dz * dz <= range_sq then
			visible = true
			break
		end
	end
	if visible ~= self._label_visible then
		self._label_visible = visible
		self.object:set_nametag_attributes({
			text = visible and self._name:get() or "",
		})
	end
end

function Minion:_lock_player(player)
	self._locked_player_name = player:get_player_name()
	self._locked_pos = player:get_pos()
	player:set_physics_override({
		speed = 0,
		speed_walk = 0,
		speed_climb = 0,
		speed_crouch = 0,
		speed_fast = 0,
		speed_fly = 0,
		jump = 0,
	})
end

function Minion:_unlock_player()
	if not self._locked_player_name then return end
	local player = minetest.get_player_by_name(self._locked_player_name)
	if player then
		player:set_physics_override({
			speed = 1,
			speed_walk = 1,
			speed_climb = 1,
			speed_crouch = 1,
			speed_fast = 1,
			speed_fly = 1,
			jump = 1,
		})
	end
	self._locked_player_name = nil
	self._locked_pos = nil
end

function Minion:_clamp_locked_player()
	if not self._locked_player_name or not self._locked_pos then return end
	local player = minetest.get_player_by_name(self._locked_player_name)
	if not player then return end
	if vector.distance(player:get_pos(), self._locked_pos) > 0.05 then
		player:set_pos(self._locked_pos)
	end
end

minions.Minion = Minion
return Minion