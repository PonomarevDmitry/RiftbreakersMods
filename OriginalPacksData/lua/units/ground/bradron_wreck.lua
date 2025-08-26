local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'bradron_wreck' ( wreck_ground_unit )

function bradron_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function bradron_wreck:initParams()

end

return bradron_wreck