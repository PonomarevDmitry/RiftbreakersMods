local wall_obstacles_tool_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/wall_area_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_borders_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_borders_center_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_diagonal_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_stairs_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_thorns_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_pencil_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)