require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/ground/stregaros.lua")
class 'stregaros_crystal' ( stregaros )

function stregaros_crystal:__init()
	stregaros.__init(self,self)
end

return stregaros_crystal