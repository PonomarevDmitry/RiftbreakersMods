local rift_portal_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/rift_portal_tool_green")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    rift_portal_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    rift_portal_tools_autoexec(evt)
end)