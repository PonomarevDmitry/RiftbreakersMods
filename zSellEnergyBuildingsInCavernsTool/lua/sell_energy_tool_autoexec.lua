local sell_energy_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_3_energy")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    sell_energy_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    sell_energy_tool_autoexec(evt)
end)