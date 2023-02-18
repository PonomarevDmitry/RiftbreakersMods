require("lua/units/units_utils.lua")

class 'venomine' ( LuaEntityObject )

function venomine:__init()
	LuaEntityObject.__init(self, self)
end

function venomine:init()
	SetupUnitScale( self.entity, self.data )
end

	
return venomine
