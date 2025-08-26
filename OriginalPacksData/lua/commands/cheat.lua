ConsoleService:RegisterCommand( "debug_spawn_entity", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end

    if #args == 1 then
        local player = PlayerService:GetPlayerControlledEnt(0)
        local position = EntityService:GetPosition( player )
        local ent = EntityService:SpawnEntity( args[ 1], position.x, position.y, position.z, "" )
        EntityService:EnableVegetationChain( ent )
    elseif #args == 2 then
        local player = PlayerService:GetPlayerControlledEnt(0)
        local position = EntityService:GetPosition( player )
        local ent = EntityService:SpawnEntity( args[ 1], position.x, position.y, position.z, args[2] )
        EntityService:EnableVegetationChain( ent )
    elseif #args == 4 then
        local ent = EntityService:SpawnEntity( args[ 1 ], tonumber(args[ 2 ]), tonumber(args[ 3 ]), tonumber(args[ 4 ]) , "" )
        EntityService:EnableVegetationChain( ent )
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

ConsoleService:RegisterCommand( "debug_start_vote", function( args )
	QueueEvent( "LuaGlobalEvent", event_sink, "DebugStartVote", {} )
end)

ConsoleService:RegisterCommand( "cheat_unlock_all_biomes_to_scan", function( args )
    CampaignService:UnlockBiome("jungle")
    CampaignService:UnlockBiome("desert")
    CampaignService:UnlockBiome("acid")
    CampaignService:UnlockBiome("magma")
    CampaignService:UnlockBiome("metallic")
    CampaignService:UnlockBiome("caverns")
    CampaignService:UnlockBiome("swamp")
end)



ConsoleService:RegisterCommand( "debug_build_buildings_around_player", function( args )
    if not Assert( #args >= 3, "Command requires at least three arguments! [radius] [count] [bluperint1 ] [blueprint2] ..."  ) then return end
    local radius = tonumber(args[1])
    local count = tonumber(args[2])
    local player = PlayerService:GetLeadingPlayer();
    local mech = PlayerService:GetPlayerControlledEnt(player )

    local transform = EntityService:GetWorldTransform(mech)
    for i=3,#args do
        local spots = FindService:FindEmptySpotsInRadius(mech, 0, radius, "", "");
        local blueprint = args[i]
        for j=1,count do
            while( #spots > 0) do
                local index = RandInt(1, #spots)
                transform.scale = {x=1,y=1,z=1}
                transform.orientation = {x=0,y=0,z=0,w=1}
                transform.position = spots[index]
                table.remove(spots, index)
                
                if ( BuildingService:CanBuildBuildingAtSpot( transform, player, blueprint, 1  )) then
                    QueueEvent("BuildBuildingRequest", INVALID_ID, player, blueprint, transform, true, {} )
                    break
                end
            end
        end
    end

end)


ConsoleService:RegisterCommand( "cheat_set_player_health", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end
    local entity = FindService:FindEntityByType( "player" )

    local value = tonumber(args[ 1 ])
    if Assert( value ~= nil, "ERROR: argument must be a value!" ) then
	    HealthService:SetHealth( entity, value )
    end
end)

ConsoleService:RegisterCommand( "cheat_drop_item_to_inventory", function( args )
    if not Assert( #args >= 1, "Command requires at least one arguments! [item] [amount]" ) then return end
    local count = args[2] or 1
    ConsoleService:ExecuteCommand("cheat_add_item " .. tostring(args[1]) .. " " .. tostring(count) .. " 0")
end)

ConsoleService:RegisterCommand( "cheat_craft_item_to_inventory", function( args )
    if not Assert( #args >= 1, "Command requires at least two arguments! [item] [amount]" ) then return end
    local count = args[2] or 1
    ConsoleService:ExecuteCommand("cheat_add_item " .. tostring(args[1]) .. " " .. tostring(count) .. " 1")
end)
 

ConsoleService:RegisterCommand( "cheat_add_all_player_items", function( args )
    if #args == 1 then
		ConsoleService:ExecuteCommand("cheat_add_items_by_type misc " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type range_weapon " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type melee_weapon " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type shield " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type equipment " .. tostring(args[1]))
		ConsoleService:ExecuteCommand("cheat_add_items_by_type movement_skill " .. tostring(args[1]))
        ConsoleService:ExecuteCommand("cheat_add_items_by_type invisible_skill " .. tostring(args[1]))
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


ConsoleService:RegisterCommand( "cheat_craft_all_player_items", function( args )
    if #args == 1 then
		ConsoleService:ExecuteCommand("cheat_add_items_by_type misc " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type range_weapon " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type melee_weapon " .. tostring(args[1]).. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type shield " .. tostring(args[1]).. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type equipment " .. tostring(args[1]) ..  " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type movement_skill " .. tostring(args[1]) .. " 1" )
        ConsoleService:ExecuteCommand("cheat_add_items_by_type invisible_skill " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type skill " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type dash_skill " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type consumable " .. tostring(args[1]) ..  " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type passive " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type upgrade " .. tostring(args[1]) .. " 1" )
		ConsoleService:ExecuteCommand("cheat_add_items_by_type defensive_mech_upgrade " .. tostring(args[1]) .. " 1")
		ConsoleService:ExecuteCommand("cheat_add_items_by_type support_mech_upgrade " .. tostring(args[1]) .. " 1")
		ConsoleService:ExecuteCommand("cheat_add_items_by_type upgrade_parts " .. tostring(args[1]) .. " 1")
		ConsoleService:ExecuteCommand("cheat_add_items_by_type misc " .. tostring(args[1]) .. " 1")
        ConsoleService:ExecuteCommand("cheat_add_items_by_type interactive " .. tostring(args[1]) .. " 1")
		ConsoleService:ExecuteCommand("cheat_add_items_by_type weapon_mod " .. tostring(args[1]) .. " 1")
		ConsoleService:ExecuteCommand("cheat_add_items_by_type saplings " .. tostring(args[1]) .. " 1")
	end
end)ConsoleService:RegisterCommand( "cheat_increase_family_info_lvl", function( args )
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

ConsoleService:RegisterCommand( "cheat_destroy_random_entities_by_type", function( args )
    if not Assert( #args == 2, "Command requires two arguments!" ) then return end
    local objectId = FindService:FindEntitiesByType( args[ 1 ] )    
    local count = tonumber(args[2])   

    if #objectId > 0 then    
        count = math.min(count, #objectId)     
        for i = 1, count do             
            local idx = RandInt(1, #objectId)                      
            QueueEvent("DamageRequest", objectId[idx], 99999, "", 0, 0)
            table.remove( objectId, idx )
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
    local mech = PlayerService:GetPlayerControlledEnt( 0 )
    local debugName = "##developerska_niewidzialna##"
    local child = EntityService:GetChildByName(mech, debugName)
    if args[ 1 ] == "1" then
        if ( child == INVALID_ID) then
			local invisbilityEnt = EntityService:SpawnAndAttachEntity( "logic/spawn_health_item", mech)    
            EntityService:SetName( invisbilityEnt, debugName )
        end
        EntityService:SetMaterial( mech, "player/mech_distortion", "1_invisiblity" )
	    EffectService:AttachEffects( mech, "invisiblity" )
        EntityService:SetGraphicsUniform( mech, "cDistortionFactor", 1.0 )
        EntityService:SetGraphicsUniform( mech, "cDissolveAmount", 1.0 )
		ItemService:SetInvisible( mech, true)
	    local children = EntityService:GetChildren( mech, false )
	    for child in Iter(children) do
	    	local itemType =ItemService:GetItemType(child);
	    	if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "") then
	    		local meshChildren =  EntityService:GetChildren( child, true )
	    		for meshChild in Iter(meshChildren) do
	    			if ( EntityService:IsSkinned( meshChild )) then
	    				EntityService:SetMaterial( meshChild, "player/item_distortion_skinned", "1_invisiblity" )
    else
	    				EntityService:SetMaterial( meshChild, "player/item_distortion", "1_invisiblity" )
    end
                    
				    EntityService:SetGraphicsUniform( meshChild, "cDistortionFactor", 1.0 )
				    EntityService:SetGraphicsUniform( meshChild, "cDissolveAmount", 1.0 )
	    		end
	    	end
	    end
    else
        if ( child ~= INVALID_ID) then
			ItemService:SetInvisible( mech, false)
            EntityService:DissolveEntity( child, 0.5 )   

        end
        EffectService:DestroyEffectsByGroup( mech, "invisiblity" )
        EntityService:RemoveMaterial( mech, "1_invisiblity" )
        EntityService:SetGraphicsUniform( mech, "cDistortionFactor", 0.0 )
        EntityService:SetGraphicsUniform( mech, "cDissolveAmount", 0.0 )
        local children =  EntityService:GetChildren( mech, false )
        for child in Iter(children) do
            local itemType =ItemService:GetItemType(child);
            if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "" ) then
                local meshChildren =  EntityService:GetChildren( child, true )
                for meshChild in Iter(meshChildren) do
                    EntityService:RemoveMaterial( meshChild, "1_invisiblity" )
				EntityService:SetGraphicsUniform( meshChild, "cDistortionFactor", 0 )
				EntityService:SetGraphicsUniform( meshChild, "cDissolveAmount", 0 )
                end
            end
        end
    end
end)

ConsoleService:RegisterCommand( "cheat_enable_research", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end	
	PlayerService:EnableResearch(PlayerService:GetLeadingPlayer(), args[ 1 ] )
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
    QueueEvent("NewAwardEvent", INVALID_ID, args[1], false, EntityService:GetTeam( "player") )	
end)

ConsoleService:RegisterCommand( "cheat_unlock_global_award", function( args )
    if not Assert( #args == 1, "Command requires one argument!" ) then return end
    PlayerService:AddGlobalAward( args[1], false, INVALID_ID )
end)

ConsoleService:RegisterCommand( "cheat_add_resource", function( args )
    if not Assert( #args == 2, "Command requires two argument! [resource] [amonut]" ) then return end	
    local resourceName = args[1]
    if( resourceName == "ironium" ) then
        resourceName = "steel"
    end

    local value = tonumber(args[ 2 ])
    if Assert( value ~= nil, "ERROR: argument must be a number!" ) then
        PlayerService:AddResourceAmount(PlayerService:GetLeadingPlayer(), resourceName, value, false )
    end
end)

ConsoleService:RegisterCommand( "cheat_reset_skill_cooldowns", function( args )
    for item_type in Iter({"consumable", "skill"}) do
        local blueprints = ItemService:GetAllItemsBlueprintsByType(item_type)
        for blueprint in Iter(blueprints) do
            local entities = FindService:FindEntitiesByBlueprint(blueprint)
            for entity in Iter(entities) do
                ItemService:ResetCooldown(entity, 0.0)
            end
        end
    end
end)

ConsoleService:RegisterCommand( "cheat_remove_all_cultivator_plants", function( args )
    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local predicate = {
        signature="VegetationLifecycleEnablerComponent",
    };
	local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );

    LogService:Log(tostring( CalcHash("cultivator")))
    for entity in Iter(entities) do
        
        local component = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( component ~= nil ) then
            
            local componentHelper = reflection_helper(component)
            LogService:Log( tostring( componentHelper.chain_data) )
            if ( componentHelper.chain_data.hash == CalcHash("cultivator")) then
                local propsInPlace = FindService:FindEntitiesByTypeInRadius( entity, "prop", 0.05 )
                for prop in Iter(propsInPlace) do
                    EntityService:RemoveEntity( prop )
                end
            end

        end
    end
end)
