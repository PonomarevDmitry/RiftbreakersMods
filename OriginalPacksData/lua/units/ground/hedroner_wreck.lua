local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'hedroner_wreck' ( wreck_ground_unit )

function hedroner_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function hedroner_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1
end

return hedroner_wreck