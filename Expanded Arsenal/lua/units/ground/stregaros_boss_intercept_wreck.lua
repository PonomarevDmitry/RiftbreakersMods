local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stregaros_boss_intercept_wreck' ( wreck_ground_unit )

function stregaros_boss_intercept_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stregaros_boss_intercept_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 5
end

return stregaros_boss_intercept_wreck