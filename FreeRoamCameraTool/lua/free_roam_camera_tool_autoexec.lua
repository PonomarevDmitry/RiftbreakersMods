local free_roam_camera_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/free_roam_camera")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    free_roam_camera_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    free_roam_camera_tool_autoexec(evt)
end)