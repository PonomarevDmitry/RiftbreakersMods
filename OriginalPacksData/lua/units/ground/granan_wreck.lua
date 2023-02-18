local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'granan_wreck' ( wreck_ground_unit )

function granan_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function granan_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return granan_wreck