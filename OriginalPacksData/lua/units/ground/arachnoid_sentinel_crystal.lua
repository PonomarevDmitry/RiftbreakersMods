require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/ground/arachnoid_sentinel_base.lua")
class 'arachnoid_sentinel_crystal' ( arachnoid_sentinel_base )

function arachnoid_sentinel_crystal:__init()
	arachnoid_sentinel_base.__init(self,self)
end

return arachnoid_sentinel_crystal
