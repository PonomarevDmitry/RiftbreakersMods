local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'flurian_boss_intercept_wreck' ( wreck_ground_unit )

function flurian_boss_intercept_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function flurian_boss_intercept_wreck:initParams()
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 8
end

return flurian_boss_intercept_wreck