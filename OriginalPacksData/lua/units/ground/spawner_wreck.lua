local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'spawner_wreck' ( wreck_ground_unit )

function spawner_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function spawner_wreck:initParams()
	self.wreckLifetime = 10
	self.normalExplodeProbability = 0
	self.leaveBodyProbability = 10	
end

return spawner_wreck