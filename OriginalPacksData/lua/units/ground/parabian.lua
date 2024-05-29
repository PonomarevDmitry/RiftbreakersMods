require("lua/units/units_utils.lua")

class 'parabian' ( LuaEntityObject )

function parabian:__init()
	LuaEntityObject.__init(self, self)
end

function parabian:init()
	SetupUnitScale( self.entity, self.data )
end


return parabian
