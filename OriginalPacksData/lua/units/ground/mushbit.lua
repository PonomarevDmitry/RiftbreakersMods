require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'mushbit' ( base_unit )

function mushbit:__init()
	base_unit.__init(self, self)
end

function mushbit:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 6
end

return mushbit
