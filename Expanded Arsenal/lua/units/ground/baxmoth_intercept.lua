require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'baxmoth_intercept' ( alien_intercept )

function baxmoth_intercept:__init()
	alien_intercept.__init(self, self)
end

function baxmoth_intercept:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	alien_intercept.OnInit(self)
end

return baxmoth_intercept
