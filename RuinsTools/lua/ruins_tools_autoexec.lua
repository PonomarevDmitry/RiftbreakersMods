local ruins_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_1_place_ruins")
    BuildingService:UnlockBuilding("buildings/tools/sell_2_ruins_eraser")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    ruins_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    ruins_tools_autoexec(evt)
end)