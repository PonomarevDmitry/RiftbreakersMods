
class 'random_spawner' ( LuaEntityObject )

function random_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function random_spawner:init()	
	local blueprint = self.data:GetString( "blueprint");
	local minAmount = self.data:GetIntOrDefault( "min", 1);
	local maxAmount = self.data:GetIntOrDefault( "max", 1);

	local count = RandInt( minAmount, maxAmount )
	local result = FindService:FindSpotsInBounds( self.entity,"","" )
	
    for i = 1,count do
		EntityService:SpawnEntity( blueprint, result[i], EntityService:GetTeam(self.entity) )
	end
	EntityService:RemoveEntity( self.entity )
end

return random_spawner