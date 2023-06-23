
class 'loot_spawner' ( LuaEntityObject )

function loot_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function loot_spawner:init()	
	-- cleanup this, resource_spawner.lua derives from it

	self.blueprint = self.data:GetString( "blueprint");
	local minAmount = self.data:GetIntOrDefault( "min", 1);
	local maxAmount = self.data:GetIntOrDefault( "max", 1);
	self.time = self.data:GetFloatOrDefault( "time", 1);
	self.packageSize = self.data:GetIntOrDefault( "package_size", 1);
	self.spawnCount = RandInt( minAmount, maxAmount )
	self.removeEntity = self.removeEntity or true
	local count = self.spawnCount / self.packageSize 
	self.instant = false
	if ( count > 30 ) then
		self.lootSpawn = self:CreateStateMachine()
		self.lootSpawn:AddState( "spawn", { from="*", enter="OnSpawnEnter", exit="OnSpawnExit", execute="OnSpawnExecute" } )
		self.lootSpawn:ChangeState("spawn")
	else
		self.instant = true
		self:SpawnLoot()
		if self.removeEntity then
			EntityService:RemoveEntity( self.entity )
		end
	end

end

function loot_spawner:OnSpawnEnter(state)
	state:SetDurationLimit( self.time )
end

function loot_spawner:OnSpawnExecute()
	self:SpawnLoot()
end

function loot_spawner:OnSpawnExit()
	if self.removeEntity then
		EntityService:RemoveEntity( self.entity )
	end
end
function loot_spawner:SpawnLoot()
	local toSpawn = self.spawnCount
	if ( self.instant == false ) then
		toSpawn =  self.spawnCount / ( self.time * 30 )
	end
	while ( toSpawn > 0 )
	do
		local count = math.min( toSpawn, self.packageSize );
		toSpawn = toSpawn - count;

		ItemService:SpawnLoot( self.entity, self.blueprint, count, self.data )
	end
end

return loot_spawner