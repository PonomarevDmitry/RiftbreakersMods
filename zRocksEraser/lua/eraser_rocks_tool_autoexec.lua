local eraser_rocks_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_rocks")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", eraser_rocks_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", eraser_rocks_tool_autoexec)