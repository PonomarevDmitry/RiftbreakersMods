local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'poogret_wreck' ( wreck_ground_unit )

function poogret_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function poogret_wreck:initParams()
	--self.wreckLifetime = 600

end

return poogret_wreck