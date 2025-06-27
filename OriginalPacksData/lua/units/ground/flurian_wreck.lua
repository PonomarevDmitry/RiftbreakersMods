local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'flurian_wreck' ( wreck_ground_unit )

function flurian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function flurian_wreck:initParams()

end

return flurian_wreck