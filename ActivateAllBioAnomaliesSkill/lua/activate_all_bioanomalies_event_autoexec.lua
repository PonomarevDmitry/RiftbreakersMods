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

        if ( entity == nil or entity == INVALID_ID ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        if ( IndexOf( activatedEntities, entity ) ~= nil ) then
            goto labelContinue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
            goto labelContinue
        end

        local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
        if ( interactiveComponent == nil ) then
            goto labelContinue
        end

        local interactiveComponentRef = reflection_helper( interactiveComponent )
        if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
            goto labelContinue
        end

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity ~= nil ) then
            
            if ( not databaseEntity:HasString("wave_logic_file") and not databaseEntity:HasString("boss_logic_file") ) then

                goto labelContinue
            end

            if ( databaseEntity:HasString("forced_group") ) then

                goto labelContinue
            end
        end



        local minimapItemComponent = EntityService:GetComponent( entity, "MinimapItemComponent" )
        if ( minimapItemComponent ~= nil ) then
            local minimapItemComponentRef = reflection_helper( minimapItemComponent )
            minimapItemComponentRef.unknown_until_visible = false
        end

        if ( databaseEntity ~= nil ) then
            databaseEntity:SetFloat( "harvest_duration", 2.5 )
        end

        QueueEvent( "HarvestStartEvent", entity )

        EntityService:SpawnEntity( "items/consumables/radar_pulse", entity, "" )

        Insert( activatedEntities, entity )

        ::labelContinue::
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