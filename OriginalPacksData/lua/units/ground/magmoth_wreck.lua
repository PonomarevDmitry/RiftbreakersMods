local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'magmoth_wreck' ( wreck_ground_unit )

function magmoth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function magmoth_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 0
end

return magmoth_wreck