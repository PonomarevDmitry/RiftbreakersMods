local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'plutrodon_wreck' ( wreck_ground_unit )

function plutrodon_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function plutrodon_wreck:initParams()

end

return plutrodon_wreck