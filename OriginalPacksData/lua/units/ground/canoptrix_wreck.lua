local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'canoptrix_wreck' ( wreck_ground_unit )

function canoptrix_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function canoptrix_wreck:initParams()
	--self.wreckLifetime = 600
end

return canoptrix_wreck