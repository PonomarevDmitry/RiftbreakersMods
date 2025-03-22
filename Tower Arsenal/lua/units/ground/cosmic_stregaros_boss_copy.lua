require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'cosmic_stregaros_boss_copy' ( base_unit )

function cosmic_stregaros_boss_copy:__init()
	base_unit.__init(self, self)
end

function cosmic_stregaros_boss_copy:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
end

return cosmic_stregaros_boss_copy
