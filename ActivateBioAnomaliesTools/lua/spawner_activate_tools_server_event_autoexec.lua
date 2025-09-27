if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    if ( mapperName == "ActivateBioAnomaliesToolsSingleRequest" ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
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

        return
    end

    local stringNumber = string.find( mapperName, "ActivateBioAnomaliesToolsAllRequest" )

    if ( stringNumber == 1 ) then

        local splitArray = Split( mapperName, "|" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        if ( #PlayerService:GetConnectedPlayers() > 1) then

            if ( PlayerService:IsPlayerVoteInProgress()) then
                return		
            end

            local playerName = PlayerService:GetPlayerName( playerId )

            local voteParams =
            {
                localization = "gui/vote/spawner_activate_tools/activate_all_bioanomalies",

                timeout = 30.0,

                gui_id = "gui/popup/popup_vote_planetaryscanner",

                default_action = "button_no",

                start_action = "button_yes",

                win_label = "gui/vote/spawner_activate_tools/activating",

                player = playerName,

                actions = 
                {
                    button_yes = 
                    { 
                        localization = "gui/hud/vote_accepted" ,
                        event_name	 = "LuaGlobalEvent",
                        event_params = { argName1 = event_sink, argName2 = "spawner_activate_tools_event" }
                    },

                    button_no =
                    {
                        localization = "gui/hud/vote_negative" ,
                        event_name = "",
                        event_params = {}
                    }
                }
            }

            GameStreamingService:StartPlayerVote( playerId, voteParams, false )

        else

            QueueEvent( "LuaGlobalEvent", event_sink, "spawner_activate_tools_event", {} )
        end

        return
    end
end)

RegisterGlobalEventHandler("LuaGlobalEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventName ~= "spawner_activate_tools_event" ) then
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