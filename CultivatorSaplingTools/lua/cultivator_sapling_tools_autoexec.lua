local cultivator_sapling_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sapling_picker")
    BuildingService:UnlockBuilding("buildings/tools/sapling_replacer")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    cultivator_sapling_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    cultivator_sapling_tools_autoexec(evt)
end)