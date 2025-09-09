if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("LuaGlobalEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventName ~= "activate_all_bioanomalies_event" ) then
        return
    end

    if ( eventEntity ~= event_sink ) then
        return
    end

    local activatedEntities = {}

    local entities = FindService:FindEntitiesByGroup( "loot_container" )

    for entity in Iter( entities ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto continue
        end

        if ( IndexOf( activatedEntities, entity ) ~= nil ) then
            goto continue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
            goto continue
        end

        local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
        if ( interactiveComponent == nil ) then
            goto continue
        end

        local interactiveComponentRef = reflection_helper( interactiveComponent )
        if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
            goto continue
        end

        local minimapItemComponent = EntityService:GetComponent( entity, "MinimapItemComponent" )
        if ( minimapItemComponent ~= nil ) then
            local minimapItemComponentRef = reflection_helper( minimapItemComponent )
            minimapItemComponentRef.unknown_until_visible = false
        end

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity ~= nil ) then
            databaseEntity:SetFloat( "harvest_duration", 2.5 )
        end

        QueueEvent( "HarvestStartEvent", entity )

        EntityService:SpawnEntity( "items/consumables/radar_pulse", entity, "" )

        Insert( activatedEntities, entity )

        ::continue::
    end

    local players = PlayerService:GetConnectedPlayers()

    for player in Iter(players) do

        local pawn = PlayerService:GetPlayerControlledEnt( player )

        if ( pawn ~= nil and pawn ~= INVALID_ID ) then

            EffectService:SpawnEffect( pawn, "effects/enemies_generic/wave_start" )

            local lootContainerDelayer = EntityService:SpawnEntity( "props/special/loot_containers/loot_container_delayer", pawn, "" )

            local dbLootContainerDelayer = EntityService:GetOrCreateDatabase( lootContainerDelayer )
            dbLootContainerDelayer:SetFloat( "delay", 0.2 )
            dbLootContainerDelayer:SetFloat( "aggressive_radius", 100 )
        end
    end
end)