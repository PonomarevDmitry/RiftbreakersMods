local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'bitrid_wreck' ( wreck_ground_unit )

function bitrid_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function bitrid_wreck:initParams()
	self.wreckLifetime = 10
	self.normalExplodeProbability = 40
	self.leaveBodyProbability = 10	
end

return bitrid_wreck