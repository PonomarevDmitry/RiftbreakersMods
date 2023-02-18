require("lua/units/units_utils.lua")

class 'egg' ( LuaEntityObject )

function egg:__init()
	LuaEntityObject.__init(self, self)
end

function egg:init()
	SetupUnitScale( self.entity, self.data )
	EntityService:Rotate( self.entity, 0, 1, 0, RandFloat( 0, 360) )
	self:RegisterHandler( self.entity, "HatchedEvent",  "OnHatchedEvent" )
end

function egg:OnHatchedEvent( evt )	
	EntityService:RequestDestroyPattern( self.entity, "spawn" )
end

return egg
