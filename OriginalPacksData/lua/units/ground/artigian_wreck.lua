local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'artigian_wreck' ( wreck_ground_unit )

function artigian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function artigian_wreck:initParams()
	--self.wreckLifetime = 600
	self.wreckLifetime = 10
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1
end

return artigian_wreck