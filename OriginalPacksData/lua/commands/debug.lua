ConsoleService:RegisterCommand( "debug_unlock_mission", function( args )
    if not Assert( #args == 2, "Command requires two argument! [resource] [amonut]" ) then return end   
    CampaignService:UnlockMission( args[1], args[2])
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