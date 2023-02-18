local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'bomogan_wreck' ( wreck_ground_unit )

function bomogan_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function bomogan_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return bomogan_wreck