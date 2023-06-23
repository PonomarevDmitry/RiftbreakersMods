local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'anoryxian_boss_tower_wreck' ( wreck_ground_unit )

function anoryxian_boss_tower_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function anoryxian_boss_tower_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 10
	self.leaveBodyProbability = 0
end

return anoryxian_boss_tower_wreck