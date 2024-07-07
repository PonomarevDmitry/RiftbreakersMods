local artificial_spawners_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_picker")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer_all_map")

    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate_all_map")
end

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    artificial_spawners_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    artificial_spawners_autoexec(evt)
end)