local loot_collecting_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting")

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting_all_map")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    loot_collecting_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    loot_collecting_tools_autoexec(evt)
end)