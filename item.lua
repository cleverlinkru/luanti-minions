local S = minions.S

minetest.register_craftitem("minions:spawn_egg", {
	description = S("Minion Spawn Egg"),
	inventory_image = "minions_spawn_egg.png",
	stack_max = 99,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local pos = vector.offset(pointed_thing.above, 0, 0.5, 0)
		local staticdata = ""
		if placer and placer:is_player() then
			local dir = vector.subtract(placer:get_pos(), pos)
			staticdata = minetest.serialize({facing = minetest.dir_to_yaw(dir)})
		end
		minetest.add_entity(pos, "minions:minion", staticdata)
		local name = placer and placer:is_player() and placer:get_player_name() or ""
		if not minetest.is_creative_enabled(name) then
			itemstack:take_item()
		end
		return itemstack
	end,
})

minetest.register_craft({
	output = "minions:spawn_egg",
	recipe = {
		{"", "default:mese_crystal_fragment", ""},
		{"default:mese_crystal_fragment", "default:diamond", "default:mese_crystal_fragment"},
		{"", "default:mese_crystal_fragment", ""},
	},
})