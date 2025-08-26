local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'viremoth_wreck' ( wreck_ground_unit )

function viremoth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function viremoth_wreck:initParams()

end

return viremoth_wreck