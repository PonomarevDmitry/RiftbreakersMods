local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'carnicinth_wreck' ( wreck_ground_unit )

function carnicinth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function carnicinth_wreck:initParams()
	--self.wreckLifetime = 600
	self.wreckLifetime = 10
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1
end

return carnicinth_wreck