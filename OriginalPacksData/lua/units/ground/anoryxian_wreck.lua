local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'anoryxian_wreck' ( wreck_ground_unit )

function anoryxian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function anoryxian_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 10
end

return anoryxian_wreck