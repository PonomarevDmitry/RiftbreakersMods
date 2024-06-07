local free_roam_camera_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/free_roam_camera")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", free_roam_camera_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", free_roam_camera_tool_autoexec)