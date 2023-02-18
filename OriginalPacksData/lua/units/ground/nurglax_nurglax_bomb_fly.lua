require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'nurglax_bomb_fly' ( LuaEntityObject )

function nurglax_bomb_fly:__init()
	LuaEntityObject.__init(self, self)
end

function nurglax_bomb_fly:init()
	self:RegisterHandler( self.entity, "AmmoRemoveRequest",  "OnAmmoRemoveRequest" )
end

function nurglax_bomb_fly:OnAmmoRemoveRequest()

	--LogService:Log( "nurglax_artillery_projectile_destroyed:OnRelease()" )
	--local parts = EntityService:SpawnEntity( "units/ground/nurglax/artillery_projectile_destroyed", self.entity, "none" )	
	EntityService:RequestDestroyPattern( self.entity, "wreck" )	
end


function nurglax_bomb_fly:OnRelease()


end

return nurglax_artillery_projectile
