local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stickrid_wreck' ( wreck_ground_unit )

function stickrid_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stickrid_wreck:initParams()
	if ( UnitService:IsOnHeightGround( self.entity ) == true ) then
		self.normalExplodeProbability = 1
		self.leaveBodyProbability = 0
	else

	end

end

return stickrid_wreck