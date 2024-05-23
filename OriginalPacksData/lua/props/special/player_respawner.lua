class 'player_spawner' ( LuaEntityObject )

function player_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function player_spawner:init()	
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent" )
end

function player_spawner:OnPlayerControlledEntityChangeEvent( evt )
    local player_id = PlayerService:GetPlayerForEntity( self.entity )
    if evt:GetPlayerId() == player_id then
        EntityService:RemoveEntity( self.entity )
    end
end

function player_spawner:OnInteractWithEntityRequest( evt )
    local player_id = PlayerService:GetPlayerForEntity( self.entity )
    QueueEvent( "PlayerSpawnRequest", INVALID_ID, player_id, self.entity )

    local entities = EntityService:GetChildren( self.entity, true )
    table.insert(entities, self.entity)

    for entity in Iter(entities) do
        QueueEvent( "FadeEntityOutRequest", entity, 1 )
    end
end

return player_spawner
