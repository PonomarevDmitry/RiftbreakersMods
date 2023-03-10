local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'nerilian_wreck' ( wreck_ground_unit )

function nerilian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function nerilian_wreck:initParams()
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return nerilian_wreck