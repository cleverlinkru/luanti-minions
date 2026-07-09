local S = minions.S

function minions.register_minion(name, def)
	minetest.register_entity(minions.modname .. ":" .. name, def)
end