if ( not is_server ) then
    return
end

local Research = require("lua/utils/researches_unlock_custom_trees_utils.lua")

local researches_unlock_custom_trees_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    Research:CheckResearches()
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    researches_unlock_custom_trees_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    researches_unlock_custom_trees_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    researches_unlock_custom_trees_autoexec(evt)
end)