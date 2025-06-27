local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'wingmite_wreck' ( wreck_ground_unit )

function wingmite_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function wingmite_wreck:initParams()

end

return wingmite_wreck