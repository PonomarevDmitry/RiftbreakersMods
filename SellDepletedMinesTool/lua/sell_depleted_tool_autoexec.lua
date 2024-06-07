local sell_depleted_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_depleted")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", sell_depleted_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", sell_depleted_tool_autoexec)