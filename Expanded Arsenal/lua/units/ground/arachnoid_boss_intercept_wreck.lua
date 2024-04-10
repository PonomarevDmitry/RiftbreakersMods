local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'arachnoid_boss_intercept_wreck' ( wreck_ground_unit )

function arachnoid_boss_intercept_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function arachnoid_boss_intercept_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 100
end

return arachnoid_boss_intercept_wreck