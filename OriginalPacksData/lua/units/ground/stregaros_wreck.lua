local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stregaros_wreck' ( wreck_ground_unit )

function stregaros_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stregaros_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 5
end

return stregaros_wreck