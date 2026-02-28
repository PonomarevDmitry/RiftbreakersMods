local base_unit = require("lua/units/base_unit.lua")
class 'kermon_ice' ( base_unit )

function kermon_ice:__init()
	base_unit.__init(self, self)
end

function kermon_ice:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 8
	self.disallowDeathAnim = "death_running_3"
end

return kermon_ice
