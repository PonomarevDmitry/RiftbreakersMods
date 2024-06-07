local floor_rebuilder_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/floor_rebuilder")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_rebuilder_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_rebuilder_tool_autoexec(evt)
end)