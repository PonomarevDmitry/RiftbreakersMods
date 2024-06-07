local replace_carbonium_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_1_powerplant")
    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_2_factory")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    replace_carbonium_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    replace_carbonium_tool_autoexec(evt)
end)