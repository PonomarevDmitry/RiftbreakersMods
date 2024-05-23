local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'spawner_swamp_wreck' ( wreck_ground_unit )

function spawner_swamp_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function spawner_swamp_wreck:initParams()
	self.wreckLifetime = 10
	self.normalExplodeProbability = 10
	self.leaveBodyProbability = 0	
end

return spawner_swamp_wreck