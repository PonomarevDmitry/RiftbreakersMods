local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'moltug_wreck' ( wreck_ground_unit )

function moltug_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function moltug_wreck:initParams()

end

return moltug_wreck