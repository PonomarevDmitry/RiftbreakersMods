local wall_obstacles_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/wall_area_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_borders_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_diagonal_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_stairs_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_thorns_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_pencil_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)