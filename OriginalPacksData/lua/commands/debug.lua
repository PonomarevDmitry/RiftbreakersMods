ConsoleService:RegisterCommand( "debug_crash_game", function( args )
    self:CrashGame() -- non existing func
end)

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