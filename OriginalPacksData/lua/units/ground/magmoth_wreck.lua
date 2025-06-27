local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'magmoth_wreck' ( wreck_ground_unit )

function magmoth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function magmoth_wreck:initParams()

end

return magmoth_wreck