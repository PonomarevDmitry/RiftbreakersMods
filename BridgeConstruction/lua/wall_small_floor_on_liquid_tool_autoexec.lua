local wall_obstacles_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/wall_small_floor_on_liquid_tool")
end

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)