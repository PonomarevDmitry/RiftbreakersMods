local eraser_flora_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_flora")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", eraser_flora_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", eraser_flora_tool_autoexec)