local S = minions.S

local BrainIdle = {}
BrainIdle.__index = BrainIdle
BrainIdle.THINK_PERIOD = 1
BrainIdle.GROUND_SCAN_DEPTH = 32
BrainIdle.WANDER_RADIUS = 12

function BrainIdle.new(minion, brain)
	local self = setmetatable({}, BrainIdle)
	self.minion = minion
	self._brain = brain
	self._timer = 0
	return self
end

function BrainIdle:get_staticdata()
	return {timer = self._timer}
end

function BrainIdle:restore(data)
	if data and data.timer then
		self._timer = data.timer
	end
end

function BrainIdle:think(dtime)
	self._timer = self._timer + dtime
	if self._timer < BrainIdle.THINK_PERIOD then
		return
	end
	self._timer = self._timer - BrainIdle.THINK_PERIOD

	local pos = self.minion.object:get_pos()
	if not pos then return end
	local target = self:_random_target(pos)
	if not target then return end
	self._brain._brain_moving:set_target(target)
	self._brain._state:set(minions.State.MOVING)
end

function BrainIdle:_random_target(pos)
	local player = self:_nearest_player(pos)
	local origin = player and player:get_pos() or pos
	local angle = math.random() * 2 * math.pi
	local dist = math.random() * BrainIdle.WANDER_RADIUS
	local candidate = {
		x = origin.x + math.cos(angle) * dist,
		y = origin.y,
		z = origin.z + math.sin(angle) * dist,
	}
	return self:_ground_under(candidate)
end

function BrainIdle:_nearest_player(pos)
	local nearest, nearest_dist_sq = nil, math.huge
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local dx = ppos.x - pos.x
		local dy = ppos.y - pos.y
		local dz = ppos.z - pos.z
		local dist_sq = dx * dx + dy * dy + dz * dz
		if dist_sq < nearest_dist_sq then
			nearest_dist_sq = dist_sq
			nearest = player
		end
	end
	return nearest
end

function BrainIdle:_ground_under(pos)
	local nx = math.floor(pos.x + 0.5)
	local nz = math.floor(pos.z + 0.5)
	local start_y = math.floor(pos.y)
	for dy = 0, BrainIdle.GROUND_SCAN_DEPTH do
		local check_y = start_y - dy
		local node = minetest.get_node({x = nx, y = check_y, z = nz})
		local def = minetest.registered_nodes[node.name]
		if def and def.walkable then
			return {x = pos.x, y = check_y + 1, z = pos.z}
		end
	end
	return nil
end

minions.BrainIdle = BrainIdle
return BrainIdle