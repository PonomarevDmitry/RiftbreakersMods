
class 'loot_spawner' ( LuaEntityObject )

function loot_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function loot_spawner:init()	

	self:SpawnLoot();

	EntityService:RemoveEntity( self.entity )
end

function loot_spawner:SpawnLoot()
	local blueprint = self.data:GetString( "blueprint");
	local minAmount = self.data:GetIntOrDefault( "min", 1);
	local maxAmount = self.data:GetIntOrDefault( "max", 1);
	local packageSize = self.data:GetIntOrDefault( "package_size", 1);

	local spawnCount = RandInt( minAmount, maxAmount )

	while ( spawnCount > 0 )
	do
		local count = math.min( spawnCount, packageSize );
		spawnCount = spawnCount - count;

		ItemService:SpawnLoot( self.entity, blueprint, count )
	end
end

return loot_spawner