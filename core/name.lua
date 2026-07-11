local S = minions.S

local Name = {}
Name.__index = Name

Name.FIRST_NAMES = {
	"Kevin", "Stuart", "Bob", "Dave", "Jerry", "Phil", "Tim", "Carl",
	"Mark", "Tom", "John", "Steve", "Mike", "Paul", "Ken", "Ron",
	"Joe", "Jim", "Larry", "Gary", "Frank", "Harry", "Eric", "Roy",
	"Norbert", "Otto", "Chuck", "Randy", "Wayne", "Stan", "Neil", "Ollie",
}

Name.LAST_NAMES = {
	"Banana", "Bello", "Poopaye", "Tulaliloo", "Bapple", "Papoy",
	"Gelato", "Butterscotch", "Nougat", "Muffin", "Pickle", "Waffle",
	"Buttercup", "Cornflake", "Sprinkle", "Twinkle", "Doodle", "Noodle",
	"Puddle", "Bumble", "Wobble", "Wiggles", "Snickers", "Bonkers",
	"McFlurry", "McGoggles", "Von Bob", "Van Kevin", "Junior", "the Third",
}

function Name.new()
	local self = setmetatable({}, Name)
	local first = Name.FIRST_NAMES[math.random(#Name.FIRST_NAMES)]
	local last = Name.LAST_NAMES[math.random(#Name.LAST_NAMES)]
	self.value = first .. " " .. last
	return self
end

function Name:get()
	return self.value
end

function Name:get_staticdata()
	return {value = self.value}
end

function Name:restore(data)
	if data and data.value then
		self.value = data.value
	end
end

minions.Name = Name
return Name