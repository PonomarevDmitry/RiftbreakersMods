require("lua/units/units_utils.lua")

class 'scale' ( LuaEntityObject )

function scale:__init()
	LuaEntityObject.__init(self, self)
end

function scale:init()
	SetupUnitScale( self.entity, self.data )
end
return scale
