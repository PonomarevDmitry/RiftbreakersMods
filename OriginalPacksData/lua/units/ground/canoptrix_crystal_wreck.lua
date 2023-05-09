local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'canoptrix_crystal_wreck' ( wreck_ground_unit )

function canoptrix_crystal_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function canoptrix_crystal_wreck:initParams()
	self.normalExplodeProbability = 1
	self.leaveBodyProbability = 0
end

return canoptrix_crystal_wreck