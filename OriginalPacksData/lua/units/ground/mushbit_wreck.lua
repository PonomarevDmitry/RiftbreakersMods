local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'mushbit_wreck' ( wreck_ground_unit )

function mushbit_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function mushbit_wreck:initParams()
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10
end

return mushbit_wreck