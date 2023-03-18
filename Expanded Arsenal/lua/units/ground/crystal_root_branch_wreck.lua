local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'crystal_root_branch_wreck' ( wreck_ground_unit )

function crystal_root_branch_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function crystal_root_branch_wreck:initParams()
	self.wreckLifetime = 3
	self.normalExplodeProbability = 1
	self.leaveBodyProbability = 0
end

return crystal_root_branch_wreck