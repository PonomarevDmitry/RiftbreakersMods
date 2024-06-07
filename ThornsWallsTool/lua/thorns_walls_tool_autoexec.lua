local thorns_walls_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/thorns_walls_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", thorns_walls_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", thorns_walls_tool_autoexec)