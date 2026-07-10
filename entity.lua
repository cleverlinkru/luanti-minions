minions.register_minion("minion", {
	initial_properties = {
		physical = true,
		collide_with_objects = true,
		collisionbox = {-0.35, -0.7, -0.35, 0.35, 0.7, 0.35},
		selectionbox = {-0.35, -0.7, -0.35, 0.35, 0.7, 0.35},
		visual = "cube",
		visual_size = {x = 0.7, y = 1.4, z = 0.7},
		hp_max = 10,
		static_save = true,
		stepheight = 0.6,
	},
})