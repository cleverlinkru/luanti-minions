local S = minions.S

local Vision = {}
Vision.__index = Vision

Vision.RANGE = 30
Vision.FOV = math.pi * 1 / 2
Vision.UPDATE_INTERVAL = 0.4
Vision.EYE_OFFSET = 0.5

Vision.DEBUG = false
Vision.DEBUG_STEP = 0.6
Vision.DEBUG_RAYS = 9
Vision.DEBUG_TEXTURE = "minions_minion_top.png"
Vision.DEBUG_SIZE = 0.5

function Vision.new(minion)
	local self = setmetatable({}, Vision)
	self.minion = minion
	self._cd = 0
	self._visible = {}
	return self
end

function Vision:visible()
	return self._visible
end

function Vision:update(dtime)
	self._cd = self._cd - dtime
	if self._cd > 0 then return end
	self._cd = Vision.UPDATE_INTERVAL
	self._visible = self:_scan()
	if Vision.DEBUG then
		self:_debug_visualize()
	end
end

function Vision:_scan()
	local pos = self.minion.object:get_pos()
	if not pos then return {} end
	local eye = {x = pos.x, y = pos.y + Vision.EYE_OFFSET, z = pos.z}
	local forward = minetest.yaw_to_dir(self.minion._facing)
	local cos_half = math.cos(Vision.FOV / 2)

	local result = {}
	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, Vision.RANGE)) do
		local item = nil
		if obj:is_player() then
			item = {type = "player", target = obj}
		else
			local ent = obj:get_luaentity()
			if ent and ent.minion and ent.minion ~= self.minion then
				item = {type = "minion", target = ent.minion}
			end
		end
		if item and self:_in_cone(eye, forward, cos_half, obj) and self:_has_line_of_sight(eye, obj) then
			table.insert(result, item)
		end
	end
	return result
end

function Vision:_in_cone(eye, forward, cos_half, target_obj)
	local tpos = target_obj:get_pos()
	local dx = tpos.x - eye.x
	local dy = (tpos.y + Vision.EYE_OFFSET) - eye.y
	local dz = tpos.z - eye.z
	local len = math.sqrt(dx * dx + dy * dy + dz * dz)
	if len < 0.01 then return true end
	local dot = (forward.x * dx + forward.z * dz) / len
	return dot >= cos_half
end

function Vision:_debug_visualize()
	local pos = self.minion.object:get_pos()
	if not pos then return end
	local eye = {x = pos.x, y = pos.y + Vision.EYE_OFFSET, z = pos.z}
	local axis = minetest.yaw_to_dir(self.minion._facing)
	local side = {x = -axis.z, y = 0, z = axis.x}
	local half = Vision.FOV / 2
	local cos_a = math.cos(half)
	local sin_a = math.sin(half)
	local rays = math.max(3, Vision.DEBUG_RAYS)
	local expiration = Vision.UPDATE_INTERVAL + 0.1
	for i = 0, rays - 1 do
		local theta = (i / rays) * 2 * math.pi
		local ct, st = math.cos(theta), math.sin(theta)
		local dir = {
			x = axis.x * cos_a + side.x * ct * sin_a,
			y = st * sin_a,
			z = axis.z * cos_a + side.z * ct * sin_a,
		}
		local d = Vision.DEBUG_STEP
		while d <= Vision.RANGE do
			minetest.add_particle({
				pos = {
					x = eye.x + dir.x * d,
					y = eye.y + dir.y * d,
					z = eye.z + dir.z * d,
				},
				expirationtime = expiration,
				size = Vision.DEBUG_SIZE,
				texture = Vision.DEBUG_TEXTURE,
				glow = 10,
			})
			d = d + Vision.DEBUG_STEP
		end
	end
end

function Vision:_has_line_of_sight(eye, target_obj)
	local tpos = target_obj:get_pos()
	local target_eye = {x = tpos.x, y = tpos.y + Vision.EYE_OFFSET, z = tpos.z}
	local ray = minetest.raycast(eye, target_eye, false, false)
	for _ in ray do
		return false
	end
	return true
end

minions.Vision = Vision
return Vision