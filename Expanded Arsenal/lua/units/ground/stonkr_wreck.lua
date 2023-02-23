local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stonkr_wreck' ( wreck_ground_unit )

function stonkr_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stonkr_wreck:initParams()
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 0
end

return stonkr_wreck