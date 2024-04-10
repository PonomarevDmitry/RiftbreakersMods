local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'nurglax_boss_intercept_wreck' ( wreck_ground_unit )

function nurglax_boss_intercept_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function nurglax_boss_intercept_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return nurglax_boss_intercept_wreck