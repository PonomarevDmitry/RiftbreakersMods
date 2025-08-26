local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'octabit_wreck' ( wreck_ground_unit )

function octabit_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function octabit_wreck:initParams()

end

return octabit_wreck