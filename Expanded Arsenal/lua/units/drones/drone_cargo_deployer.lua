require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'drone_cargo_deployer' ( LuaEntityObject )

function drone_cargo_deployer:__init()
	LuaEntityObject.__init(self, self)
end

function drone_cargo_deployer:init()
	self:RegisterHandler( self.entity, "AmmoRemoveRequest",  "OnAmmoRemoveRequest" )

	self.eggBp	  = self.data:GetString( "egg_spawn_on_destroy" )
	self.eggCount = self.data:GetInt( "egg_spawn_count" )
end

function drone_cargo_deployer:OnAmmoRemoveRequest()
	EntityService:RequestDestroyPattern( self.entity, "wreck" )	

	local origin = EntityService:GetPosition( self.entity )

	for i = 1, self.eggCount do			
		local egg = EntityService:SpawnEntity( self.eggBp, origin.x, origin.y, origin.z, "" )
		EntityService:SetTeam( egg, "player" )
		EntityService:PhysicsSleepNotify( egg, true )
		UnitService:AddDynamicForce( egg, 1500, 2500 )
	end
end


function drone_cargo_deployer:OnRelease()


end

return drone_cargo_deployer
