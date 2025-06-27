local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'arachnoid_boss_wreck' ( wreck_ground_unit )

function arachnoid_boss_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function arachnoid_boss_wreck:initParams()

end

return arachnoid_boss_wreck