class 'entity_spawn_player_pawn' ( LuaGraphNode )

function entity_spawn_player_pawn:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_player_pawn:init()
end

function entity_spawn_player_pawn:Activated()
	self.unregister_handler = false
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
    LogService:Log("Spawn player: " .. tostring(playerId))
	if MissionService:SpawnSelectedPlayer(playerId) then 
		self:SetFinished()
	else
		self.unregister_handler = true
		self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent" )
	end
end

function entity_spawn_player_pawn:Deactivated()
	if self.unregister_handler then
		self.unregister_handler = false
		self:UnregisterHandler( event_sink, "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent" )
	end
end

function entity_spawn_player_pawn:OnPlayerControlledEntityChangeEvent( evt )
	local playerId = self.data:GetIntOrDefault("player_id", 0 )
	if ( evt:GetPlayerId() ~= playerId ) then
		return
	end

	self.controlledEntity = evt:GetControlledEntity()
	local database = EntityService:GetDatabase( self.controlledEntity )
	if ( database:GetIntOrDefault( "initial_spawn", 0 ) == 1 ) then
		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "portal_open", {enter="OnPortalOpenEnter", exit="OnPortalOpenExit"} )
		self.fsm:ChangeState("portal_open")
	end
end

function entity_spawn_player_pawn:OnPortalOpenEnter( state )
	state:SetDurationLimit( 2 )
end

function entity_spawn_player_pawn:OnPortalOpenExit( state )
	self:SetFinished()
end

return entity_spawn_player_pawn