local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'kafferroceros_wreck' ( wreck_ground_unit )

function kafferroceros_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function kafferroceros_wreck:initParams()

end

return kafferroceros_wreck