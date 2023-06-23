local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'baxmoth_wreck' ( wreck_ground_unit )

function baxmoth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function baxmoth_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1
	self.resurrectCooldown = 2
end

return baxmoth_wreck