local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'lesigian_wreck' ( wreck_ground_unit )

function lesigian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function lesigian_wreck:initParams()

end

return lesigian_wreck