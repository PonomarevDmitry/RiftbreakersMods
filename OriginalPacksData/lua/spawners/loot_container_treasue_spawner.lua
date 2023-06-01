
class 'loot_container_treasue_spawner' ( LuaEntityObject )

function loot_container_treasue_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function loot_container_treasue_spawner:init()	

	self.rarity = self.data:GetIntOrDefault( "rarity", 0 );
	SetupUnitScale( self.entity, self.data )
    EntityService:MarkEntityAsLootContainer( self.entity, self.rarity )
    QueueEvent("SpawnFromLootContainerRequest", self.entity, self.rarity, EntityService:GetTeam(self.entity) )
	QueueEvent("DestroyRequest", self.entity, "default", 100 )
end

return loot_container_treasue_spawner