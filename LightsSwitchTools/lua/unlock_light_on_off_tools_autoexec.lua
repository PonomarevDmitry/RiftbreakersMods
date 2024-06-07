local unlock_light_on_off_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/light_1_on")
    BuildingService:UnlockBuilding("buildings/tools/light_2_off")

    BuildingService:UnlockBuilding("buildings/tools/light_switcher_all_map")
    BuildingService:UnlockBuilding("buildings/tools/light_switcher_mech")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", unlock_light_on_off_tools_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", unlock_light_on_off_tools_autoexec)