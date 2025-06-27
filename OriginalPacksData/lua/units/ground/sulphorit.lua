require ("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'sulphorit' ( base_unit )

function sulphorit:__init()
	base_unit.__init(self, self)
end

function sulphorit:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 4
end

return sulphorit
