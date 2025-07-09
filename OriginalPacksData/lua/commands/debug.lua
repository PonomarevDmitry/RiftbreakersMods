ConsoleService:RegisterCommand( "debug_remove_mission", function( args )
    if not Assert( #args == 1, "Command requires one argument! [mission_name]" ) then return end   
    CampaignService:RemoveMission( args[1], MISSION_STATUS_WIN )
end)

ConsoleService:RegisterCommand( "debug_unlock_mission", function( args )
    if not Assert( #args == 2, "Command requires two argument! [mission_name] [mission_def]" ) then return end   
    CampaignService:UnlockMission( args[1], args[2])
end)

local g_generator_index = 1
ConsoleService:RegisterCommand( "debug_unlock_generator_mission", function( args )
    if not Assert( #args == 1, "Command requires two argument! [mission_def]" ) then return end

    local GetMissionName = function()
        return "generator_" .. tostring(g_generator_index) 
    end

    if CampaignService.IsMissionUnlocked then
        g_generator_index = 1
        while CampaignService:IsMissionUnlocked( GetMissionName() ) do
            g_generator_index = g_generator_index + 1
        end
    end

    CampaignService:UnlockMission( GetMissionName(), args[1])
    g_generator_index = g_generator_index + 1

end)

ConsoleService:RegisterCommand( "debug_send_lua_event", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
	LogService:Log("Sending event: " .. args[1] )
	QueueEvent( "LuaGlobalEvent", event_sink, args[1], {} )
end)

g_debug_resource_harvester = false

ConsoleService:RegisterCommand( "debug_resource_harvester", function( args )
    if not Assert( #args == 1, "Command requires one argument! [bool]" ) then return end

    g_debug_resource_harvester = args[1] == "1"
end)

g_debug_dom_manager = false

ConsoleService:RegisterCommand( "debug_dom_manager", function( args )
    if not Assert( #args == 1, "Command requires one argument! [bool]" ) then return end

    g_debug_dom_manager = args[1] == "1"
end)

g_verbose_dom_manager = false

ConsoleService:RegisterCommand( "verbose_dom_manager", function( args )
    if not Assert( #args == 1, "Command requires one argument! [bool]" ) then return end

    g_verbose_dom_manager = args[1] == "1"
end)

g_debug_dom_manager_spawn_wave_levels = {}

ConsoleService:RegisterCommand( "debug_dom_manager_spawn_wave_level", function( args )
    if not Assert( #args == 1, "Command requires one argument! [level]" ) then return end

    table.insert(g_debug_dom_manager_spawn_wave_levels, tonumber( args[1] ) )
end)

ConsoleService:RegisterCommand( "debug_dom_finish", function( args )
	QueueEvent( "LuaGlobalEvent", event_sink, "FinishSurvival", {} )
end)

ConsoleService:RegisterCommand( "debug_dom_pause", function( args )
	QueueEvent( "LuaGlobalEvent", event_sink, "PauseDOM", {} )
end)

ConsoleService:RegisterCommand( "debug_dom_resume", function( args )
	QueueEvent( "LuaGlobalEvent", event_sink, "ResumeDOM", {} )
end)

ConsoleService:RegisterCommand( "debug_spawn_resource_loot", function( args )
    if not Assert( #args == 2, "Command requires one argument! [resource] [count]" ) then return end

    local pawn = PlayerService:GetPlayerControlledEnt(0)

    for i=1,tonumber( args[2] ) do
        ItemService:SpawnLoot(pawn,"items/loot/resources/shard_" .. tostring( args[1] ) .. "_item", 5)
    end
end)

ConsoleService:RegisterCommand( "debug_remove_by_blueprint_count", function( args )
    if not Assert( #args == 2, "Command requires two arguments! [blueprint] [count]" ) then return end

    local entities = FindService:FindEntitiesByBlueprint( args[1] )

    local counter = math.min( tonumber(args[2]), #entities)
    for i=1,counter do
        EntityService:RemoveEntity(entities[i])
    end
end)

function SpawnPlayerBot( hostile )
    local EquipRandomItem = function( player_id, items, slot )
        if #items <= 0 then return end

        local item_entity = PlayerService:AddItemToInventory(player_id, items[RandInt(1, #items)])
        PlayerService:EquipItemInSlot(player_id, item_entity, slot)
    end

    local player_id = PlayerService:CreateFakePlayer();

    local player_team = EntityService:GetTeam("player")
    if hostile then
        player_team = PlayerService:CreatePlayerTeam("bot_" .. tostring(player_id), hostile)
    end

    PlayerService:CreatePlayerBot("player/character_bot", player_id, player_team )

    local skins = ItemService:GetAllItemsBlueprintsByType("skin")
    EquipRandomItem( player_id, skins, "SKIN_1")

    EquipRandomItem( player_id,
    {
		"items/weapons/laser_sword_item"
    }, "LEFT_HAND")

    EquipRandomItem( player_id,
	{
		--"items/weapons/minigun_item",
		--"items/weapons/railgun_item",
		--"items/weapons/bouncing_blades_item",
		--"items/weapons/acid_spitter_item",
		"items/weapons/grenade_launcher_item"
	}, "RIGHT_HAND")

    local data = CampaignService:GetCampaignData()
    data:SetInt("player_bot." .. tostring(player_id), player_team )
end

ConsoleService:RegisterCommand( "debug_spawn_hostile_player_bot", function( args )
    SpawnPlayerBot( true )
end)

ConsoleService:RegisterCommand( "debug_spawn_friendly_player_bot", function( args )
    SpawnPlayerBot( false )
end)

ConsoleService:RegisterCommand( "debug_respawn_campaign_bots", function( args )
    local data = CampaignService:GetCampaignData()

    local players = PlayerService:GetAllPlayers()
    for player_id in Iter(players) do
        if data:HasInt("player_bot." .. tostring(player_id)) then
            local player_team = data:GetInt("player_bot." .. tostring(player_id))
            PlayerService:CreatePlayerBot("player/character_bot", player_id, player_team )
        end
    end
end)

ConsoleService:RegisterCommand( "debug_remove_campaign_bot", function( args )
    if not Assert( #args == 1, "Command requires two arguments! [player_id]" ) then return end

    local data = CampaignService:GetCampaignData()

    local player_id = tonumber( args[1] )
    if data:HasInt("player_bot." .. tostring(player_id)) then
        data:RemoveKey("player_bot." .. tostring(player_id))
    end

    PlayerService:RemovePlayerBot( player_id )
end)

ConsoleService:RegisterCommand( "debug_change_mission", function( args )
    if not Assert( #args == 1, "Command requires two arguments! [mission_id]" ) then return end

    if ( CampaignService ~= nil and CampaignService.ChangeCurrentMission ~= nil ) then
        CampaignService:ChangeCurrentMission( args[1] )
    end
end)

ConsoleService:RegisterCommand( "debug_change_world_bounds", function( args )
    if not Assert( #args == 2, "Command requires two arguments! [min_x,min_y] [max_x,max_y]" ) then return end

    local min = Split( args[1], "," )
    if not Assert( #min == 2, "Command requires two arguments! [min_x,min_y] [max_x,max_y]" ) then return end

    local max = Split( args[2], "," )
    if not Assert( #max == 2, "Command requires two arguments! [min_x,min_y] [max_x,max_y]" ) then return end

    local params = {
        min = args[1],
        max = args[2],
    }
	QueueEvent( "LuaGlobalEvent", event_sink, "change_world_bounds", params )
end)

ConsoleService:RegisterCommand( "debug_set_creatures_difficulty_level", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
    CampaignService:SetCreaturesBaseDifficulty( tonumber( args[1] ) )
end)

g_debug_change_biome_for_skill_overrides = ""
ConsoleService:RegisterCommand( "debug_change_biome_for_skill_overrides", function( args )
    if not Assert( #args == 1, "Command requires two arguments! [biome_name]" ) then return end

    g_debug_change_biome_for_skill_overrides = args[1]
end)

ConsoleService:RegisterCommand( "debug_win_game", function( args )
    QueueEvent( "LuaGlobalEvent", event_sink, "win_game", {} )
end)

ConsoleService:RegisterCommand( "debug_lose_game", function( args )
    QueueEvent( "LuaGlobalEvent", event_sink, "lose_game", {} )
end)

ConsoleService:RegisterCommand("debug_end_game", function( args )
    QueueEvent( "ShowEndGameRequest", event_sink, MISSION_STATUS_WIN )
end)

ConsoleService:RegisterCommand( "debug_cleanup_invalid_pawn_entities", function( args )

    local player_pawns = {}
    local predicate = {
        signature = "PlayerReferenceComponent",
        filter = function(entity)
            local component = reflection_helper( EntityService:GetConstComponent( entity,"PlayerReferenceComponent" ) )

            local player_id = component.player_id
            player_pawns[ player_id ] = player_pawns[ player_id ] or PlayerService:GetPlayerControlledEnt( player_id )
            if entity == player_pawns[ player_id ] then
                return false
            end
            return component.reference_type.internal_enum == 0
        end
    };
    
    LogService:Log( "-- Start removing entities considered as pawns:");
    local entities = FindService:FindEntitiesByPredicateInBox( { x = -10000, y = -10000, z = -10000 }, { x = 10000, y = 10000, z = 10000 }, predicate);
    for entity in Iter(entities) do
        local blueprint_name = EntityService:GetBlueprintName(entity)
        LogService:Log("  - " .. tostring(entity) .. " " .. blueprint_name );
        EntityService:RemoveEntity(entity)
    end
    LogService:Log( "-- End removing entities considered as pawns");
end )

ConsoleService:RegisterCommand( "debug_unlock_planetary_scanner", function()
	CampaignService:OperatePlanetaryJump( true )
	CampaignService:OperateDOMPlanetaryJump( true )

end)

