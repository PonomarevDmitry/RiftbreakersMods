local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'vesaurus_wreck' ( wreck_ground_unit )

function vesaurus_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function vesaurus_wreck:initParams()
	self.wreckLifetime = 10
	self.normalExplodeProbability = 40
	self.leaveBodyProbability = 10	
end

return vesaurus_wreck