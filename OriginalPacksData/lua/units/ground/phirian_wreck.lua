local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'phirian_wreck' ( wreck_ground_unit )

function phirian_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function phirian_wreck:initParams()

end

return phirian_wreck