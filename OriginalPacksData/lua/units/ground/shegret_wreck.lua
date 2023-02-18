local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'shegret_wreck' ( wreck_ground_unit )

function shegret_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function shegret_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return shegret_wreck