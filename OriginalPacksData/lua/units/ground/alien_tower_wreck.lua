local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'alien_tower_plasma_wreck' ( wreck_ground_unit )

function alien_tower_plasma_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function alien_tower_plasma_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 10
	self.leaveBodyProbability = 0
end

return alien_tower_plasma_wreck