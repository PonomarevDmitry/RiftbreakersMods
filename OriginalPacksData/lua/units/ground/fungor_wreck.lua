local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'fungor_wreck' ( wreck_ground_unit )

function fungor_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function fungor_wreck:initParams()

    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 7

end

return fungor_wreck