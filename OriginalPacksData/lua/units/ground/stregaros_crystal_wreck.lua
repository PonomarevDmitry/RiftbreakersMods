local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stregaros_crystal_wreck' ( wreck_ground_unit )

function stregaros_crystal_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stregaros_crystal_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0.5
	self.leaveBodyProbability = 0.5
end

return stregaros_crystal_wreck