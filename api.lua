local S = minions.S

local Minion = minions.Minion

local function new_minion(entity, def)
	local m = setmetatable({object = entity.object}, {__index = Minion})
	for k, v in pairs(def) do
		if k ~= "initial_properties" then
			m[k] = v
		end
	end
	return m
end

function minions.register_minion(name, def)
	def = def or {}

	minetest.register_entity(minions.modname .. ":" .. name, {
		initial_properties = def.initial_properties,

		on_activate = function(self, staticdata, dtime_s)
			self.minion = new_minion(self, def)
			if self.minion.on_activate then
				self.minion:on_activate(staticdata, dtime_s)
			end
		end,

		get_staticdata = function(self)
			if self.minion and self.minion.get_staticdata then
				return self.minion:get_staticdata()
			end
			return ""
		end,

		on_step = function(self, dtime, moveresult)
			if self.minion and self.minion.on_step then
				self.minion:on_step(dtime, moveresult)
			end
		end,

		on_punch = function(self, puncher, tflp, caps, dir, dmg)
			if self.minion and self.minion.on_punch then
				self.minion:on_punch(puncher, tflp, caps, dir, dmg)
			end
		end,

		on_rightclick = function(self, clicker)
			if self.minion and self.minion.on_rightclick then
				self.minion:on_rightclick(clicker)
			end
		end,
	})
end