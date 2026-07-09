local S = minions.S

minions.drivers = minions.drivers or {}

local FORWARD_SPEED = 3.5
local BACKWARD_SPEED = 2.0
local TURN_SPEED = 3.0
local JUMP_VEL = 6.5
local JUMP_COOLDOWN = 0.5
local DRIVER_MAX_DIST = 30
local WALK_FRAME_TIME = 0.22

-- offset between _facing (world yaw the front should point to) and object yaw.
local FACING_OFFSET = math.pi

local FRAME_IDLE = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side.png",
	"minions_minion_side.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}
local FRAME_WALK1 = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side_walk1.png",
	"minions_minion_side_walk2.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}
local FRAME_WALK2 = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side_walk2.png",
	"minions_minion_side_walk1.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}

minetest.register_entity("minions:minion", {
	initial_properties = {
		physical = true,
		collide_with_objects = true,
		collisionbox = {-0.35, -0.7, -0.35, 0.35, 0.7, 0.35},
		selectionbox = {-0.35, -0.7, -0.35, 0.35, 0.7, 0.35},
		visual = "cube",
		visual_size = {x = 0.7, y = 1.4, z = 0.7},
		textures = {
			"minions_minion_top.png",
			"minions_minion_bottom.png",
			"minions_minion_side.png",
			"minions_minion_side.png",
			"minions_minion_back.png",
			"minions_minion_front.png",
		},
		hp_max = 10,
		static_save = true,
		stepheight = 1.1,
	},
	_driver = nil,
	_facing = 0,

	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			if type(data) == "table" then
				self._facing = data.facing or 0
			end
		end
		self.object:set_acceleration({x = 0, y = -9.81, z = 0})
		self.object:set_yaw(self._facing + FACING_OFFSET)
		self._anim_state = "idle"
		self._anim_t = 0
		self._walk_toggle = false
		self._jump_cd = 0
	end,

	_set_anim = function(self, state)
		if self._anim_state == state then return end
		self._anim_state = state
		if state == "idle" then
			self.object:set_properties({textures = FRAME_IDLE})
		elseif state == "walk1" then
			self.object:set_properties({textures = FRAME_WALK1})
			minetest.sound_play("minions_step1", {
				object = self.object,
				gain = 0.5,
				max_hear_distance = 12,
				pitch = 0.9 + math.random() * 0.2,
			}, true)
		elseif state == "walk2" then
			self.object:set_properties({textures = FRAME_WALK2})
			minetest.sound_play("minions_step2", {
				object = self.object,
				gain = 0.5,
				max_hear_distance = 12,
				pitch = 0.9 + math.random() * 0.2,
			}, true)
		end
	end,

	get_staticdata = function(self)
		return minetest.serialize({facing = self._facing})
	end,

	_grab = function(self, player)
		local name = player:get_player_name()
		self._driver = name
		minions.drivers[name] = self
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
		minetest.chat_send_player(name,
			S("Controlling minion. WASD/Arrows: move / turn. Jump: hop. Sneak: release."))
	end,

	_release = function(self, player)
		local name = self._driver
		self._driver = nil
		self._locked_pos = nil
		if name then
			minions.drivers[name] = nil
		end
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
		if name then
			minetest.chat_send_player(name, S("Minion released."))
		end
	end,

	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local name = clicker:get_player_name()
		if self._driver == name then
			self:_release(clicker)
		elseif self._driver then
			minetest.chat_send_player(name, S("Minion is already controlled by @1.", self._driver))
		else
			self:_grab(clicker)
		end
	end,

	on_punch = function(self, puncher, _, tool_capabilities)
		local dmg = 1
		if tool_capabilities and tool_capabilities.damage_groups then
			dmg = tool_capabilities.damage_groups.fleshy or 1
		end
		local hp = self.object:get_hp() - dmg
		self.object:set_hp(hp)
		if hp <= 0 then
			self.object:remove()
		end
	end,

	on_step = function(self, dtime)
		self._jump_cd = math.max(0, (self._jump_cd or 0) - dtime)

		local vel = self.object:get_velocity()
		local driver
		if self._driver then
			driver = minetest.get_player_by_name(self._driver)
		end
		if driver then
			local d = vector.distance(driver:get_pos(), self.object:get_pos())
			if d > DRIVER_MAX_DIST then
				driver = nil
				self._driver = nil
			end
		end

		if not driver then
			self.object:set_velocity({x = 0, y = vel.y, z = 0})
			self:_set_anim("idle")
			return
		end

		local ctrl = driver:get_player_control()

		if ctrl.sneak then
			self:_release(driver)
			return
		end

		if self._locked_pos then
			local pos = driver:get_pos()
			if vector.distance(pos, self._locked_pos) > 0.05 then
				driver:set_pos(self._locked_pos)
			end
		end

		if ctrl.left then self._facing = self._facing + TURN_SPEED * dtime end
		if ctrl.right then self._facing = self._facing - TURN_SPEED * dtime end
		self.object:set_yaw(self._facing + FACING_OFFSET)

		local fwd = minetest.yaw_to_dir(self._facing)
		local vx, vz = 0, 0
		if ctrl.up then
			vx = fwd.x * FORWARD_SPEED
			vz = fwd.z * FORWARD_SPEED
		elseif ctrl.down then
			vx = -fwd.x * BACKWARD_SPEED
			vz = -fwd.z * BACKWARD_SPEED
		end

		local vy = vel.y
		if (ctrl.jump or ctrl.aux1) and self._jump_cd <= 0 and math.abs(vy) < 0.5 then
			vy = JUMP_VEL
			self._jump_cd = JUMP_COOLDOWN
		end

		self.object:set_velocity({x = vx, y = vy, z = vz})

		local moving = ctrl.up or ctrl.down
		if not moving then
			self:_set_anim("idle")
		else
			self._anim_t = (self._anim_t or 0) + dtime
			if self._anim_state == "idle" then
				self:_set_anim("walk1")
				self._walk_toggle = false
				self._anim_t = 0
			elseif self._anim_t >= WALK_FRAME_TIME then
				self._anim_t = 0
				self._walk_toggle = not self._walk_toggle
				self:_set_anim(self._walk_toggle and "walk2" or "walk1")
			end
		end
	end,
})

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local ent = minions.drivers[name]
	if ent then
		ent._driver = nil
		minions.drivers[name] = nil
	end
end)

local function reset_physics(player)
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

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	if minions.drivers[name] then
		local ent = minions.drivers[name]
		if ent and ent.object and ent.object:get_pos() then
			ent:_release(player)
		else
			reset_physics(player)
			minions.drivers[name] = nil
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if minions.drivers[name] then
		minions.drivers[name] = nil
	end
	reset_physics(player)
end)