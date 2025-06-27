local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'canceroth_wreck' ( wreck_ground_unit )

function canceroth_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function canceroth_wreck:initParams()

end

return canceroth_wreck