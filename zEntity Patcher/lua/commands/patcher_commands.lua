require( "lua/utils/divergent.lua" )

ConsoleService:RegisterCommand( "ep_debug_vegetation_cache", function( args )
    if not Assert( #args == 1, "Command requires one argument! [0 or 1]" ) then
        return
    end

    if Assert( VegetationCacheDump ~= nil, "It needs active Harvest Drones" ) then
        VegetationCacheDump( args[1] )
    end

end )

ConsoleService:RegisterCommand( "ep_debug_resource_drones", function( args )
    if not Assert( #args == 1, "Command requires one argument! [0 or 1]" ) then
        return
    end

    if Assert( g_allocated_resource_drones ~= nil, "It needs active Resource Drones" ) then
        for target, t in pairs( g_allocated_resource_drones ) do
            if #t == 0 then
                LogService:Log( ("*target: %d, "):format( target ) )
                for drones in pairs( t ) do
                    LogService:Log( ("\t\t drone: %d"):format( drones ) )
                end
            else
                for i, drones in ipairs( t ) do
                    LogService:Log( ("\t\ti: %d ,drone: %d"):format( i, drones ) )
                end
            end
        end
    end

end )

ConsoleService:RegisterCommand( "ep_player_equipment", function( args )
    ConsoleService:Write( "Entity Patch Player Equipment" )

    local players = PlayerService:GetAllPlayers()

    if #players == 0 then
        ConsoleService:Write( "Unable to find Players" )
        return
    end

    local mechs = {}
    for i = 1, #players do
        local player = players[i]
        if player == INVALID_ID then
            goto continue
        end

        local mech = PlayerService:GetGlobalPlayerEntity( player )
        if mech == INVALID_ID then
            goto continue
        end

        mechs[mech] = PlayerService:GetPlayerName( player )

        ::continue::
    end

    local ep = require( "lua/entity_patcher.lua" )
    ep:AddToMechCheck( mechs )

    for _, player_name in pairs( mechs ) do
        ConsoleService:Write( (">> %s's equipment patched "):format( player_name ) )
    end

end )

ConsoleService:RegisterCommand( "ep_log_entity_component", function( args )
    if not Assert( #args == 2, "Command requires one argument! [entity_id and component]" ) then
        return
    end

    LogService:Log( "args1 " .. args[1] )
    LogService:Log( "args2 " .. args[2] )

    local entity = tonumber( args[1] )
    if not Assert( type( entity ) == "number", "ERROR: failed to convert entity to number" ) then
        return
    end

    LogService:Log( "Before Getting Component" )

    local component = EntityService:GetComponent( entity, args[2] )
    if not component then
        component = EntityService:GetConstComponent( entity, args[2] )
        if not component then
            LogService:Log( "Fail to get component " .. args[2] )
            return
        end
    end

    LogService:Log( "Going to EP" )

    local ep = require( "lua/entity_patcher.lua" )
    ep:LogComponent( component, true, args[2] )

end )

