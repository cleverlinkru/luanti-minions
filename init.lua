minions = {}

minions.modname = minetest.get_current_modname()
minions.modpath = minetest.get_modpath(minions.modname)

local S = minetest.get_translator(minions.modname)
minions.S = S

dofile(minions.modpath .. "/api.lua")

minetest.log("action", "[" .. minions.modname .. "] loaded")