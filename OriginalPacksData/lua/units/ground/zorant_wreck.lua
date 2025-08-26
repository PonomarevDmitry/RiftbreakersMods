local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'zorant_wreck' ( wreck_ground_unit )

function zorant_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function zorant_wreck:initParams()

end

return zorant_wreck