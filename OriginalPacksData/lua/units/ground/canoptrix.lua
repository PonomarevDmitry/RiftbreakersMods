require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'canoptrix' ( base_unit )

function canoptrix:__init()
	base_unit.__init(self, self)
end

function canoptrix:OnInit()
	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 8
end

return canoptrix
