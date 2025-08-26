require ("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'moltug' ( base_unit )

function moltug:__init()
	base_unit.__init(self, self)
end

function moltug:OnInit()
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 0
    self.normalExplodeProbability = 5
	self.leaveBodyProbability = 1
end

return moltug
