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

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "SetGlobalPlayerEntityDatabaseString" )

    if ( stringNumber == 1 ) then

        --LogService:Log("SetGlobalPlayerEntityDatabaseString entity " .. tostring(entity) .. " mapperName " .. tostring(mapperName))

        local splitArray = Split( mapperName, "|" )
        if ( #splitArray < 2 ) then
            return
        end

        local parameterName = splitArray[2]

        --LogService:Log("SetGlobalPlayerEntityDatabaseString entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName))

        if ( parameterName == nil or parameterName == "" ) then
            return
        end
        
        local subString = "SetGlobalPlayerEntityDatabaseString|" .. parameterName .. "|"

        --LogService:Log("SetGlobalPlayerEntityDatabaseString subString " .. tostring(subString))

        local newValue = string.sub( mapperName, string.len(subString) + 1, string.len(mapperName) )

        --LogService:Log("SetGlobalPlayerEntityDatabaseString entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName) .. " newValue " .. tostring(newValue))

        -- ConsoleService:ExecuteCommand("dump_entity " .. tostring(entity))
        
        local globalPlayerEntityDB = EntityService:GetDatabase( entity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetString( parameterName, newValue )
        end

        return
    end



    local stringNumber = string.find( mapperName, "SetGlobalPlayerEntityDatabaseInt" )

    if ( stringNumber == 1 ) then

        --LogService:Log("SetGlobalPlayerEntityDatabaseInt entity " .. tostring(entity) .. " mapperName " .. tostring(mapperName))

        local splitArray = Split( mapperName, "|" )
        if ( #splitArray < 2 ) then
            return
        end

        local parameterName = splitArray[2]

        --LogService:Log("SetGlobalPlayerEntityDatabaseInt entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName))

        if ( parameterName == nil or parameterName == "" ) then
            return
        end
        
        local subString = "SetGlobalPlayerEntityDatabaseInt|" .. parameterName .. "|"

        --LogService:Log("SetGlobalPlayerEntityDatabaseInt subString " .. tostring(subString))

        local newValue = string.sub( mapperName, string.len(subString) + 1, string.len(mapperName) )

        --LogService:Log("SetGlobalPlayerEntityDatabaseInt entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName) .. " newValue " .. tostring(newValue))

        -- ConsoleService:ExecuteCommand("dump_entity " .. tostring(entity))

        local newValueNumber = tonumber(newValue)

        if ( newValueNumber == nil ) then
            return
        end
        
        local globalPlayerEntityDB = EntityService:GetDatabase( entity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetInt( parameterName, newValueNumber )
        end

        return
    end



    local stringNumber = string.find( mapperName, "SetGlobalPlayerEntityDatabaseFloat" )

    if ( stringNumber == 1 ) then

        --LogService:Log("SetGlobalPlayerEntityDatabaseFloat entity " .. tostring(entity) .. " mapperName " .. tostring(mapperName))

        local splitArray = Split( mapperName, "|" )
        if ( #splitArray < 2 ) then
            return
        end

        local parameterName = splitArray[2]

        --LogService:Log("SetGlobalPlayerEntityDatabaseFloat entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName))

        if ( parameterName == nil or parameterName == "" ) then
            return
        end
        
        local subString = "SetGlobalPlayerEntityDatabaseFloat|" .. parameterName .. "|"

        --LogService:Log("SetGlobalPlayerEntityDatabaseFloat subString " .. tostring(subString))

        local newValue = string.sub( mapperName, string.len(subString) + 1, string.len(mapperName) )

        --LogService:Log("SetGlobalPlayerEntityDatabaseFloat entity " .. tostring(entity) .. " parameterName " .. tostring(parameterName) .. " newValue " .. tostring(newValue))

        -- ConsoleService:ExecuteCommand("dump_entity " .. tostring(entity))

        local newValueNumber = tonumber(newValue)

        if ( newValueNumber == nil ) then
            return
        end
        
        local globalPlayerEntityDB = EntityService:GetDatabase( entity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetFloat( parameterName, newValueNumber )
        end

        return
    end
end)



local global_player_entity_database_server_event_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local databaseEntity = EntityService:GetOrCreateDatabase( player )
end



RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    global_player_entity_database_server_event_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    global_player_entity_database_server_event_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    global_player_entity_database_server_event_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)