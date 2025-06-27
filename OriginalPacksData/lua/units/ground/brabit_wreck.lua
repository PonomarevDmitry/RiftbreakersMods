local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'brabit_wreck' ( wreck_ground_unit )

function brabit_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function brabit_wreck:initParams()

end

return brabit_wreck