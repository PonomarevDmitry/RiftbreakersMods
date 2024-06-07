local eraser_resources_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_resources")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", eraser_resources_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", eraser_resources_tool_autoexec)