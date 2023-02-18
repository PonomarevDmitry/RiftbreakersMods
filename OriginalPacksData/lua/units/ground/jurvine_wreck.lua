local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'jurvine_wreck' ( wreck_ground_unit )

function jurvine_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function jurvine_wreck:initParams()
	--self.wreckLifetime = 600
end

return jurvine_wreck