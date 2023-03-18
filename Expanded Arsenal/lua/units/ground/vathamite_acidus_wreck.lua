local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'vathamite_acidus_wreck' ( wreck_ground_unit )

function vathamite_acidus_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function vathamite_acidus_wreck:initParams()
	self.normalExplodeProbability = 70
	self.leaveBodyProbability = 0	
end

return vathamite_acidus_wreck