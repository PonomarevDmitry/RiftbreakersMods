require ("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'brabit' ( base_unit )

function brabit:__init()
	base_unit.__init(self, self)
end

function brabit:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 0
end

return brabit
