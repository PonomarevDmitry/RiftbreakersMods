class 'baxmoth_drone' ( LuaEntityObject )
require("lua/units/units_utils.lua")

function baxmoth_drone:__init()
	LuaEntityObject.__init(self, self)
end

function baxmoth_drone:init()
	SetupUnitScale( self.entity, self.data )
	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
end

function baxmoth_drone:OnDestroyRequest( evt )
	--AnimationService:StopAnim( self.entity , "working" )	
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), "wreck_air", 0 )
end


return baxmoth_drone