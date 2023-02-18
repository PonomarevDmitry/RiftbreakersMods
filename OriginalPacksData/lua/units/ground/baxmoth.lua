require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'baxmoth' ( base_unit )

function baxmoth:__init()
	base_unit.__init(self, self)
end

function baxmoth:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
end

return baxmoth
