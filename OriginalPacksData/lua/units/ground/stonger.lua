require("lua/units/units_utils.lua")

class 'stonger' ( LuaEntityObject )

function stonger:__init()
	LuaEntityObject.__init(self, self)
end

function stonger:init()
	SetupUnitScale( self.entity, self.data )
end

	
return stonger
