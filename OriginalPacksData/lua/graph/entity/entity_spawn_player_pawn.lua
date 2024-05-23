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
	MissionService:SpawnSelectedPlayer( playerId )
	self.unregister_handler = true
	self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent" )
end

function entity_spawn_player_pawn:Deactivated()
	if self.unregister_handler then
		self.unregister_handler = false
		self:UnregisterHandler( event_sink, "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent" )
	end

	--ConsoleService:ExecuteCommand("debug_respawn_campaign_bots")
end

function entity_spawn_player_pawn:OnPlayerControlledEntityChangeEvent( evt )
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
	if ( evt:GetPlayerId() ~= playerId ) then
		return
	end

	if g_skins == nil or #g_skins == 0 then
		g_skins = ItemService:GetAllItemsBlueprintsByType("skin")
	end

	self.controlledEntity = evt:GetControlledEntity()
	if playerId ~= 0 and #g_skins > 0 then
		local index = RandInt( 1, #g_skins )
		LogService:Log("Selected player skin: " .. g_skins[ index ])

		local itemEnt = PlayerService:AddItemToInventory( playerId, g_skins[ index ] )
		PlayerService:EquipItemInSlot( playerId, itemEnt, "SKIN_1" )

		table.remove( g_skins, index)
	end

	local database = EntityService:GetDatabase( self.controlledEntity )
	if ( database:GetIntOrDefault( "initial_spawn", 0 ) == 1 ) then
		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "portal_open", {enter="OnPortalOpenEnter", exit="OnPortalOpenExit"} )
		self.fsm:ChangeState("portal_open")
	else
		self:SetFinished()
	end
end

function entity_spawn_player_pawn:OnPortalOpenEnter( state )
	state:SetDurationLimit( 2 )
end

function entity_spawn_player_pawn:OnPortalOpenExit( state )
	self:SetFinished()
end

return entity_spawn_player_pawn