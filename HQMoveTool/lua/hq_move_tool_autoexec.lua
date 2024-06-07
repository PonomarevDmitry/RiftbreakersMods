local hq_move_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/main/hq_move_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    hq_move_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    hq_move_tool_autoexec(evt)
end)