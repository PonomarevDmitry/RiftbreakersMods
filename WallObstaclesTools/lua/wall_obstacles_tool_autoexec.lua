RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/defense/wall_area_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_borders_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_diagonal_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_stairs_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_thorns_tool")

end)