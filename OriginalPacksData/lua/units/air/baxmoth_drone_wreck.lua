local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'baxmoth_drone' ( wreck_ground_unit )

function baxmoth_drone:__init()
	wreck_ground_unit.__init(self,self)
end

function baxmoth_drone:initParams()
	self.wreckLifetime = 10
	self.normalExplodeProbability = 1
	self.leaveBodyProbability = 0	
end

return baxmoth_drone