minions = {}

minions.modname = minetest.get_current_modname()
minions.modpath = minetest.get_modpath(minions.modname)

local S = minetest.get_translator(minions.modname)
minions.S = S

dofile(minions.modpath .. "/core/animator.lua")
dofile(minions.modpath .. "/core/name.lua")
dofile(minions.modpath .. "/core/message.lua")
dofile(minions.modpath .. "/core/chat.lua")
dofile(minions.modpath .. "/core/chat_brain.lua")
dofile(minions.modpath .. "/core/vision.lua")
dofile(minions.modpath .. "/core/state.lua")
dofile(minions.modpath .. "/core/brain.lua")
dofile(minions.modpath .. "/core/player_brain.lua")
dofile(minions.modpath .. "/core/minion.lua")
dofile(minions.modpath .. "/api.lua")
dofile(minions.modpath .. "/entity.lua")
dofile(minions.modpath .. "/item.lua")

minetest.log("action", "[" .. minions.modname .. "] loaded")