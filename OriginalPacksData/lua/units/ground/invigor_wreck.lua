local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'invigor_wreck' ( wreck_ground_unit )

function invigor_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function invigor_wreck:initParams()
	self.wreckLifetime = 10
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 10
end

return invigor_wreck