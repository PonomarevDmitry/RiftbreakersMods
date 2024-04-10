local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'krocoon_boss_intercept_wreck' ( wreck_ground_unit )

function krocoon_boss_intercept_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function krocoon_boss_intercept_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 7

	self.deathAnimationStates[1] = "death_2"
end

return krocoon_boss_intercept_wreck