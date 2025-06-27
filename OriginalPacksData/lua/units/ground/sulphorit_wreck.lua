local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'sulphorit_wreck' ( wreck_ground_unit )

function sulphorit_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function sulphorit_wreck:initParams()

end

return sulphorit_wreck