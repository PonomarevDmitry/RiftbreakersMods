local hq_move_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/main/hq_move_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", hq_move_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", hq_move_tool_autoexec)