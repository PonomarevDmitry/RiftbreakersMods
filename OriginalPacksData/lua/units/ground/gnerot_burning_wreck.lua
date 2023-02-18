local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'gnerot_wreck' ( wreck_ground_unit )

function gnerot_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function gnerot_wreck:initParams()
	self.wreckLifetime = 30
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 5
	self.deathAnimationStates[1] = "death_2"
	--self.deathAnimationStates[2] = "death_3"
	
	--self.deathAnimationMarkers[1] = "death_1"
end

return gnerot_wreck