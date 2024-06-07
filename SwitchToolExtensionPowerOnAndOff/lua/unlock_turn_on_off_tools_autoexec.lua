local unlock_turn_on_off_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/turn_1_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_2_off")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", unlock_turn_on_off_tools_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", unlock_turn_on_off_tools_autoexec)