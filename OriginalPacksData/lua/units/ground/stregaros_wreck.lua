local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'stregaros_wreck' ( wreck_ground_unit )

function stregaros_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function stregaros_wreck:initParams()

end

return stregaros_wreck