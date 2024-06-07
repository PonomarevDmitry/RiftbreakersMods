local eraser_wrecks_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_wrecks")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    eraser_wrecks_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    eraser_wrecks_tool_autoexec(evt)
end)