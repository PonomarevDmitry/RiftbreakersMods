local thorns_walls_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/thorns_walls_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    thorns_walls_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    thorns_walls_tool_autoexec(evt)
end)