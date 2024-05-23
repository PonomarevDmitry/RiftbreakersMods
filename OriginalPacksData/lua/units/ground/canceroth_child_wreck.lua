local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'canceroth_child_wreck' ( wreck_ground_unit )

function canceroth_child_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function canceroth_child_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 10
	self.leaveBodyProbability = 0
end

return canceroth_child_wreck