local S = minions.S

local Animator = {}
Animator.__index = Animator

Animator.WALK_FRAME_TIME = 0.22

Animator.FRAME_IDLE = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side.png",
	"minions_minion_side.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}

Animator.FRAME_WALK1 = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side_walk1.png",
	"minions_minion_side_walk2.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}

Animator.FRAME_WALK2 = {
	"minions_minion_top.png",
	"minions_minion_bottom.png",
	"minions_minion_side_walk2.png",
	"minions_minion_side_walk1.png",
	"minions_minion_back.png",
	"minions_minion_front.png",
}

Animator.STEP_SOUND1 = "minions_step1"
Animator.STEP_SOUND2 = "minions_step2"

function Animator.new(object)
	local self = setmetatable({}, Animator)
	self.object = object
	self._state = nil
	self._t = 0
	self._walk_toggle = false
	self._moving = false
	self:_apply("idle")
	return self
end

function Animator:set_moving(moving)
	self._moving = moving and true or false
end

function Animator:update(dtime)
	if not self._moving then
		self:_apply("idle")
		return
	end

	self._t = self._t + dtime

	if self._state == "idle" then
		self:_apply("walk1")
		self._walk_toggle = false
		self._t = 0
	elseif self._t >= self.WALK_FRAME_TIME then
		self._t = 0
		self._walk_toggle = not self._walk_toggle
		self:_apply(self._walk_toggle and "walk2" or "walk1")
	end
end

function Animator:_apply(state)
	if self._state == state then return end
	self._state = state

	local frames
	if state == "idle" then
		frames = self.FRAME_IDLE
	elseif state == "walk1" then
		frames = self.FRAME_WALK1
	elseif state == "walk2" then
		frames = self.FRAME_WALK2
	end
	if frames then
		self.object:set_properties({textures = frames})
	end

	if state == "walk1" or state == "walk2" then
		local sound = state == "walk1" and self.STEP_SOUND1 or self.STEP_SOUND2
		minetest.sound_play(sound, {
			object = self.object,
			gain = 0.5,
			max_hear_distance = 12,
			pitch = 0.9 + math.random() * 0.2,
		}, true)
	end
end

minions.Animator = Animator
return Animator