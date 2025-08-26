local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'necrodon_wreck' ( wreck_ground_unit )

function necrodon_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function necrodon_wreck:initParams()

end

return necrodon_wreck