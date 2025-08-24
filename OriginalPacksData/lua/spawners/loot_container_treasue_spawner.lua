
class 'loot_container_treasue_spawner' ( LuaEntityObject )

function loot_container_treasue_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function loot_container_treasue_spawner:init()	

	self.rarity = self.data:GetIntOrDefault( "rarity", 0 );
	SetupUnitScale( self.entity, self.data )

	EntityService:DestroyEntity( self.entity, "default" )
end

return loot_container_treasue_spawner