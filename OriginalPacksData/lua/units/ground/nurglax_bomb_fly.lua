require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'nurglax_bomb_fly' ( LuaEntityObject )

function nurglax_bomb_fly:__init()
	LuaEntityObject.__init(self, self)
end

function nurglax_bomb_fly:init()
	self:RegisterHandler( self.entity, "AmmoRemoveRequest",  "OnAmmoRemoveRequest" )

	self.eggBp	  = self.data:GetString( "egg_spawn_on_destroy" )
	self.eggCount = self.data:GetInt( "egg_spawn_count" )
end

function nurglax_bomb_fly:OnAmmoRemoveRequest()
	EntityService:RequestDestroyPattern( self.entity, "wreck" )	

	local origin = EntityService:GetPosition( self.entity )

	for i = 1, self.eggCount do			
		local egg = EntityService:SpawnEntity( self.eggBp, origin.x, origin.y, origin.z, "" )
		EntityService:SetTeam( egg, "wave_enemy" )
		EntityService:PhysicsSleepNotify( egg, true )
		UnitService:AddDynamicForce( egg, 1500, 2500 )
	end
end


function nurglax_bomb_fly:OnRelease()


end

return nurglax_bomb_fly
