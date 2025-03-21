local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'gnerot_intercept_wreck' ( wreck_ground_unit )

function gnerot_intercept_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function gnerot_intercept_wreck:initParams()
	self.wreckLifetime = 30
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 5
	self.deathAnimationStates[1] = "death_2"
end

return gnerot_intercept_wreck