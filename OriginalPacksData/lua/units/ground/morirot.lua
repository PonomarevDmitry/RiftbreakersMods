require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'morirot' ( base_unit )

function morirot:__init()
	base_unit.__init(self, self)
end

function morirot:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
end

return morirot
