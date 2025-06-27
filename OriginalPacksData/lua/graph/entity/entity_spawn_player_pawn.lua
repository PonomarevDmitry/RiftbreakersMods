require("lua/utils/data_flow.lua")
require("lua/utils/table_utils.lua")

class 'entity_spawn_player_pawn' ( LuaGraphNode )

function entity_spawn_player_pawn:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_player_pawn:GetRequestedPlayerIds()
	if self.data:HasString("in_players") then
		return GetEntitiesFromString(self.data:GetString("in_players"))
	end

	if self.data:HasString("in_entities") then
		local players = {}
		local entities = GetEntitiesFromString(self.data:GetString("in_entities"))
		for entity in Iter(entities) do
			table.insert(players, PlayerService:GetPlayerForEntity(entity))
		end

		return players;
	end

	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
	return { playerId };
end

function entity_spawn_player_pawn:init()
end

function entity_spawn_player_pawn:OnLoad()
	if self.with_portal_sequence == nil then
		self.with_portal_sequence = true
	end

	self.wait_for_players = self.wait_for_players or self:GetRequestedPlayerIds()
	if self.wait_for_portal == nil then
		self.wait_for_portal = true
	end
end

function entity_spawn_player_pawn:Activated()
	self.unregister_handler = false
	self.wait_for_players = self:GetRequestedPlayerIds()
	self.with_portal_sequence = self.data:GetStringOrDefault("with_portal_sequence", "true") == "true"
	self.wait_for_portal = self.with_portal_sequence and self.data:GetStringOrDefault("wait_for_portal", "true") == "true"

	if #self.wait_for_players == 0 then
		return self:SetFinished()
	end

	for player_id in Iter(self.wait_for_players) do
		MissionService:SpawnSelectedPlayer( player_id, self.with_portal_sequence )
	end

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
	local index = IndexOf(self.wait_for_players, evt:GetPlayerId() )
	if index == nil then
		return
	end

	local playerId = evt:GetPlayerId()

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

	table.remove(self.wait_for_players, index)

	local database = EntityService:GetDatabase( self.controlledEntity )
	if ( self.wait_for_portal and database:GetIntOrDefault( "initial_spawn", 0 ) == 1 ) then
		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "portal_open", {enter="OnPortalOpenEnter", exit="OnPortalOpenExit"} )
		self.fsm:ChangeState("portal_open")
	elseif #self.wait_for_players == 0 then
		self:SetFinished()
	end

	if ( PlayerService:GetItemNumber( playerId, "items/special/multiplayer_boost" ) == 0 ) then
		local itemEnt = PlayerService:AddItemToInventory( playerId, "items/special/multiplayer_boost" )
		PlayerService:EquipItemInSlot( playerId, itemEnt, "SPECIAL" )
	end
end

function entity_spawn_player_pawn:OnPortalOpenEnter( state )
	state:SetDurationLimit( 2 )
end

function entity_spawn_player_pawn:OnPortalOpenExit( state )
	if #self.wait_for_players == 0 then
		self:SetFinished()
	end
end

return entity_spawn_player_pawn