local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'kermon_ice_wreck' ( wreck_ground_unit )

function kermon_ice_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function kermon_ice_wreck:initParams()

end

return kermon_ice_wreck