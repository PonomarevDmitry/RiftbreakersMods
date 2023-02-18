ConsoleService:RegisterCommand( "debug_spawn_entity", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end

    if #args == 1 then
        local player = PlayerService:GetPlayerControlledEnt(0)
        local position = EntityService:GetPosition( player )
        EntityService:SpawnEntity( args[ 1], position.x, position.y, position.z, "" )
    elseif #args == 4 then
        EntityService:SpawnEntity( args[ 1 ], tonumber(args[ 2 ]), tonumber(args[ 3 ]), tonumber(args[ 4 ]) , "" )
    end
end)

ConsoleService:RegisterCommand( "debug_get_familiarity_level", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end
    local species = args[1]
    local subspecies = args[2] or ""
    local lvl = PlayerService:GetFamiliarityLevel(args[1],subspecies)
    LogService:Log( args[1] .. " familiarity lvl: " .. tostring(lvl) )
end)

ConsoleService:RegisterCommand( "cheat_spawn_meteor", function( args )
    MeteorService:SpawnMeteorInFrustum( "weather/meteor_medium", 50, 140 )
end)

ConsoleService:RegisterCommand( "cheat_set_player_health", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end
    local entity = FindService:FindEntityByType( "player" )

    local value = tonumber(args[ 1 ])
    if Assert( value ~= nil, "ERROR: argument must be a value!" ) then
	    HealthService:SetHealth( entity, value )
    end
end)

ConsoleService:RegisterCommand( "cheat_add_all_player_items", function( args )
    if #args == 1 then
		ConsoleService:ExecuteCommand("cheat_add_items_by_type misc " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type range_weapon " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type melee_weapon " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type shield " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type equipment " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type movement_skill " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type skill " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type dash_skill " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type consumable " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type passive " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type upgrade " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type defensive_mech_upgrade " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type support_mech_upgrade " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type upgrade_parts " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type misc " .. tostring(args[1]))
        ConsoleService:ExecuteCommand("cheat_add_items_by_type interactive " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type weapon_mod " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type saplings " .. tostring(args[1]))
	end
end)

ConsoleService:RegisterCommand( "cheat_win_game", function( args )
	MissionService:FinishCurrentMission( MISSION_STATUS_WIN )
end)

ConsoleService:RegisterCommand( "cheat_lose_game", function( args )
	MissionService:FinishCurrentMission( MISSION_STATUS_LOSE )
end)

ConsoleService:RegisterCommand( "cheat_increase_family_info_lvl", function( args )
    if not Assert( #args == 2, "Command requires two arguments <species_name> <subspecies_name>!" ) then return end
	PlayerService:IncreaseFamilyInfoLvl( args[ 1 ], args[ 2 ]  )
end)

ConsoleService:RegisterCommand( "cheat_remove_entities_by_type", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    local objectId = FindService:FindEntitiesByType( args[ 1 ] )       
    if #objectId > 0 then                               
        for i = 1, #objectId do             
            EntityService:RemoveEntity( objectId[i] )                               
        end
    end     
end)

ConsoleService:RegisterCommand( "cheat_destroy_entities_by_type", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    local objectId = FindService:FindEntitiesByType( args[ 1 ] )       
    if #objectId > 0 then                               
        for i = 1, #objectId do             
            QueueEvent("DamageRequest", objectId[i], 99999, "", 0, 0)
        end
    end     
end)

ConsoleService:RegisterCommand( "cheat_remove_entities_by_blueprint", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    local objectId = FindService:FindEntitiesByBlueprint( args[ 1 ] )       
    if #objectId > 0 then                               
        for i = 1, #objectId do             
            EntityService:RemoveEntity( objectId[i] )                               
        end
    end     
end)

ConsoleService:RegisterCommand( "cheat_remove_entity", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    
    if EntityService:IsAlive( tonumber(args[1]) ) then                               
            EntityService:RemoveEntity( tonumber(args[1]) )                               
    end     
end)
ConsoleService:RegisterCommand( "cheat_full_loadout", function( args )
    MissionService:ActivateMissionFlow("logic/loadout/player_loadout_full.logic")
end)


ConsoleService:RegisterCommand( "debug_minimap_interference", function( args )
    if not Assert( #args == 1, "Command requires one argument: 0/1!" ) then return end

    if args[ 1 ] == "1" then
        GuiService:EnableMinimapInterference()
    else
        GuiService:DisableMinimapInterference()
    end
end)

ConsoleService:RegisterCommand( "cheat_set_player_invisibility", function( args )
    if not Assert( #args == 1, "Command requires one argument: 0/1!" ) then return end
    local entity = FindService:FindEntityByType( "player" )
    if args[ 1 ] == "1" then
		ItemService:SetInvisible(entity, true)
    else
		ItemService:SetInvisible(entity, false)
    end
end)

ConsoleService:RegisterCommand( "cheat_enable_research", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
	PlayerService:EnableResearch( args[ 1 ] )
end)

ConsoleService:RegisterCommand( "cheat_unlock_research", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
	PlayerService:UnlockResearch( args[ 1 ] )
end)

ConsoleService:RegisterCommand( "cheat_enable_discoverable_system", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
    BuildingService:EnableDiscoverableSystem( args[1] == "1" )
end)

ConsoleService:RegisterCommand( "cheat_unlock_award", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    QueueEvent("NewAwardEvent", INVALID_ID, args[1], false )	
end)


ConsoleService:RegisterCommand( "cheat_add_resource", function( args )
    if not Assert( #args == 2, "Command requires two argument! [resource] [amonut]" ) then return end	
    local resourceName = args[1]
    if( resourceName == "ironium" ) then
        resourceName = "steel"
    end

    local value = tonumber(args[ 2 ])
    if Assert( value ~= nil, "ERROR: argument must be a number!" ) then
        PlayerService:AddResourceAmount( resourceName, value )
    end
end)