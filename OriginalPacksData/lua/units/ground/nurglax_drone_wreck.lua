local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'nurglax_drone_wreck' ( wreck_ground_unit )

function nurglax_drone_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function nurglax_drone_wreck:initParams()
	self.wreckLifetime = 10
end

return nurglax_drone_wreck