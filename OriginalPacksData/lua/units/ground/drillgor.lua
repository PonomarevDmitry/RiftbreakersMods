require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'drillgor' ( base_unit )

function drillgor:__init()
	base_unit.__init(self, self)
end

function drillgor:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
end

return drillgor
