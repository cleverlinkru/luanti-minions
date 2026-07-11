local S = minions.S

local BrainMoving = {}
BrainMoving.__index = BrainMoving
BrainMoving.ARRIVE_DISTANCE = 1.5
BrainMoving.LOOKAHEAD = 3.0
BrainMoving.WAYPOINT_ADVANCE = 0.6
BrainMoving.PATH_SEARCH_DISTANCE = 40
BrainMoving.PATH_MAX_JUMP = 1
BrainMoving.PATH_MAX_DROP = 2
BrainMoving.PATH_ALGORITHM = "A*_noprefetch"
BrainMoving.REPLAN_INTERVAL = 2.0
BrainMoving.STUCK_CHECK_INTERVAL = 1.0
BrainMoving.STUCK_MIN_MOVE = 0.3
BrainMoving.ESCAPE_DURATION = 0.8
BrainMoving.WHISKER_DISTANCE = 0.8
BrainMoving.DEBUG = true
BrainMoving.DEBUG_TEXTURE = "minions_spawn_egg.png"
BrainMoving.DEBUG_LINE_STEP = 0.3

function BrainMoving.new(minion, brain)
	local self = setmetatable({}, BrainMoving)
	self.minion = minion
	self._brain = brain
	self._target = nil
	self._path = nil
	self._path_index = 1
	self._replan_timer = 0
	self._stuck_timer = 0
	self._last_pos = nil
	self._escape_timer = 0
	self._escape_dir = 1
	self._last_turn = 0
	return self
end

function BrainMoving:get_staticdata()
	return {target = self._target}
end

function BrainMoving:restore(data)
	if data then
		self._target = data.target
	end
end

function BrainMoving:set_target(target)
	self._target = target
	self._path = nil
	self._path_index = 1
	self._replan_timer = 0
	self._stuck_timer = 0
	self._last_pos = nil
	self._escape_timer = 0
	self:_replan()
end

function BrainMoving:think(dtime)
	if not self._target then return end
	local pos = self.minion.object:get_pos()
	if not pos then return end

	local dx = self._target.x - pos.x
	local dz = self._target.z - pos.z
	if math.sqrt(dx * dx + dz * dz) < BrainMoving.ARRIVE_DISTANCE then
		return self:_finish()
	end

	if self._escape_timer > 0 then
		self._escape_timer = self._escape_timer - dtime
		if self._escape_timer <= 0 then
			self._replan_timer = 0
			self._stuck_timer = 0
			self._last_pos = nil
			self:_replan()
		end
		return {
			forward = false,
			backward = true,
			turn_left = self._escape_dir > 0,
			turn_right = self._escape_dir < 0,
			jump = false,
			sneak = false,
		}
	end

	self._replan_timer = self._replan_timer + dtime
	if self._replan_timer >= BrainMoving.REPLAN_INTERVAL then
		self._replan_timer = 0
		self:_replan()
	end

	self._stuck_timer = self._stuck_timer + dtime
	if self._stuck_timer >= BrainMoving.STUCK_CHECK_INTERVAL then
		self._stuck_timer = 0
		if self._last_pos then
			local sdx = pos.x - self._last_pos.x
			local sdz = pos.z - self._last_pos.z
			if math.sqrt(sdx * sdx + sdz * sdz) < BrainMoving.STUCK_MIN_MOVE then
				return self:_start_escape()
			end
		end
		self._last_pos = {x = pos.x, y = pos.y, z = pos.z}
	end

	local aim = self:_pursuit_point(pos)
	local adx = aim.x - pos.x
	local adz = aim.z - pos.z
	local aim_dist = math.sqrt(adx * adx + adz * adz)
	local desired_yaw = minetest.dir_to_yaw({x = adx, y = 0, z = adz})
	local delta = desired_yaw - self.minion._facing
	while delta > math.pi do delta = delta - 2 * math.pi end
	while delta < -math.pi do delta = delta + 2 * math.pi end
	self._last_turn = delta

	local blocked, jumpable = self:_whisker(pos)
	if blocked and not jumpable then
		return self:_start_escape()
	end

	local r_min = self.minion.FORWARD_SPEED / self.minion.TURN_SPEED
	local turn_step = self.minion.TURN_SPEED * dtime
	local orbit_risk = aim_dist < 2 * r_min * math.abs(math.sin(delta))
	local final_turn = aim_dist < 2 * r_min and math.abs(delta) > turn_step

	return {
		forward = not orbit_risk and not final_turn,
		backward = false,
		turn_left = delta > turn_step,
		turn_right = delta < -turn_step,
		jump = (blocked and jumpable) or (aim.y > pos.y + 0.5),
		sneak = false,
	}
end

function BrainMoving:_replan()
	if not self._target then return end
	local pos = self.minion.object:get_pos()
	if not pos then return end
	local start = {
		x = math.floor(pos.x + 0.5),
		y = math.floor(pos.y),
		z = math.floor(pos.z + 0.5),
	}
	local goal = {
		x = math.floor(self._target.x + 0.5),
		y = math.floor(self._target.y),
		z = math.floor(self._target.z + 0.5),
	}
	self._path = minetest.find_path(
		start, goal,
		BrainMoving.PATH_SEARCH_DISTANCE,
		BrainMoving.PATH_MAX_JUMP,
		BrainMoving.PATH_MAX_DROP,
		BrainMoving.PATH_ALGORITHM
	)
	self._path_index = 1
	if not self._path then
		self._target = nil
		self._brain._state:set(minions.State.MOVING_FAIL)
		return
	end
	self:_debug_visualize()
end

function BrainMoving:_pursuit_point(pos)
	if not self._path or #self._path == 0 then
		return self._target
	end
	while self._path_index < #self._path do
		local wp = self._path[self._path_index]
		local dx = wp.x - pos.x
		local dz = wp.z - pos.z
		if math.sqrt(dx * dx + dz * dz) > BrainMoving.WAYPOINT_ADVANCE then break end
		self._path_index = self._path_index + 1
	end
	for i = self._path_index, #self._path do
		local wp = self._path[i]
		local dx = wp.x - pos.x
		local dz = wp.z - pos.z
		if math.sqrt(dx * dx + dz * dz) >= BrainMoving.LOOKAHEAD then
			return wp
		end
	end
	return self._path[#self._path]
end

function BrainMoving:_whisker(pos)
	local fwd = minetest.yaw_to_dir(self.minion._facing)
	local wx = math.floor(pos.x + fwd.x * BrainMoving.WHISKER_DISTANCE + 0.5)
	local wz = math.floor(pos.z + fwd.z * BrainMoving.WHISKER_DISTANCE + 0.5)
	local wy = math.floor(pos.y)
	local front = minetest.get_node({x = wx, y = wy, z = wz})
	local fdef = minetest.registered_nodes[front.name]
	if not (fdef and fdef.walkable) then return false, false end
	local above = minetest.get_node({x = wx, y = wy + 1, z = wz})
	local adef = minetest.registered_nodes[above.name]
	local jumpable = not (adef and adef.walkable)
	return true, jumpable
end

function BrainMoving:_start_escape()
	self._escape_timer = BrainMoving.ESCAPE_DURATION
	self._escape_dir = self._last_turn >= 0 and -1 or 1
	return {
		forward = false,
		backward = true,
		turn_left = self._escape_dir > 0,
		turn_right = self._escape_dir < 0,
		jump = false,
		sneak = false,
	}
end

function BrainMoving:_debug_visualize()
	if not BrainMoving.DEBUG then return end
	if not self._path or #self._path < 2 then return end
	local expirationtime = BrainMoving.REPLAN_INTERVAL + 0.2
	local step = BrainMoving.DEBUG_LINE_STEP
	for i = 1, #self._path - 1 do
		local a = self._path[i]
		local b = self._path[i + 1]
		local dx = b.x - a.x
		local dy = b.y - a.y
		local dz = b.z - a.z
		local len = math.sqrt(dx * dx + dy * dy + dz * dz)
		local n = math.max(1, math.floor(len / step))
		for j = 0, n do
			local t = j / n
			minetest.add_particle({
				pos = {x = a.x + dx * t, y = a.y + dy * t + 0.3, z = a.z + dz * t},
				velocity = {x = 0, y = 0, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = expirationtime,
				size = 1.5,
				collisiondetection = false,
				vertical = false,
				glow = 14,
				texture = BrainMoving.DEBUG_TEXTURE,
			})
		end
	end
end

function BrainMoving:_finish()
	self._target = nil
	self._path = nil
	self._path_index = 1
	self._brain._state:set(minions.State.IDLE)
	return {
		forward = false,
		backward = false,
		turn_left = false,
		turn_right = false,
		jump = false,
		sneak = false,
	}
end

minions.BrainMoving = BrainMoving
return BrainMoving