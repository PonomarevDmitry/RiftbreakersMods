local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'fungor_wreck' ( wreck_ground_unit )

function fungor_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function fungor_wreck:initParams()
end

return fungor_wreck