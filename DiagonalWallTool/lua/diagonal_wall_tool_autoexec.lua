local diagonal_wall_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/diagonal_wall_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", diagonal_wall_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", diagonal_wall_tool_autoexec)