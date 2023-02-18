local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'morirot_wreck' ( wreck_ground_unit )

function morirot_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function morirot_wreck:initParams()
    self.normalExplodeProbability = 4
	self.leaveBodyProbability = 10
end

return morirot_wreck