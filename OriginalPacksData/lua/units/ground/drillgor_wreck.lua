local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'drillgor_wreck' ( wreck_ground_unit )

function drillgor_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function drillgor_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1
end

return drillgor_wreck