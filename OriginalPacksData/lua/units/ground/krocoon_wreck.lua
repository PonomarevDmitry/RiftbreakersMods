local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'krocoon_wreck' ( wreck_ground_unit )

function krocoon_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function krocoon_wreck:initParams()
	self.deathAnimationStates[1] = "death_2"
end

return krocoon_wreck