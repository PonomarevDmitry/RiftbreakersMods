local base_unit = require("lua/units/base_unit.lua")
class 'granan' ( base_unit )

function granan:__init()
	base_unit.__init(self, self)
end

function granan:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 4
end

return granan
