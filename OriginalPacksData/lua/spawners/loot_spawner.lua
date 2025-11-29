require("lua/utils/reflection.lua")

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
	self.addLifetime = minAmount > 1 or maxAmount > 1
	local count = self.spawnCount / self.packageSize 
	self.instant = false
	if ( count > 30 ) then
		self.lootSpawn = self:CreateStateMachine()
		self.lootSpawn:AddState( "spawn", { from="*", enter="OnSpawnEnter", exit="OnSpawnExit", execute="OnSpawnExecute" } )
		self.lootSpawn:ChangeState("spawn")
	else
		if ( self.data:GetIntOrDefault( "force_add", 0 ) == 1 ) then
			self.playerId  = PlayerService:GetPlayerForEntity( self.entity )
			self.playerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )
		end
		self.instant = true
		self:SpawnLoot()
		if self.removeEntity then
			EntityService:RemoveEntity( self.entity )
		end
	end
	self.loot_award_handled = false

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
		
		local lifeTime =  0
		if ( EntityService:HasComponent( self.entity, "LifeTimeComponent") ) then
			lifeTime = EntityService:GetLifeTime( self.entity )
		end

		if ( self.addLifetime ) then
			lifeTime = -1
		end

		if ( self.playerEntity ~= INVALID_ID and self.playerEntity ~= nil) then
			QueueEvent("CreateItemInInventoryRequest", self.playerEntity, self.blueprint,2,self.playerId)
		else
			ItemService:SpawnLoot( self.entity, self.blueprint, count, lifeTime, self.data )
		end
	end

	if not self.loot_award_handled then
		self.loot_award_handled = true
		
		local loot_component = EntityService:GetConstComponent(self.entity, "LootComponent")
		if loot_component ~= nil then
			local refl_loot_component = reflection_helper( loot_component )
			if refl_loot_component.loot_award ~= "" then
				QueueEvent("SpawnFromLootContainerRequest", self.entity, EntityService:GetWorldTransform( self.entity), refl_loot_component.loot_award, 0)
			end
		end
	end
end

return loot_spawner