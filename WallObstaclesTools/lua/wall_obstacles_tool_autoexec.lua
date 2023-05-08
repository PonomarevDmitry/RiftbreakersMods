RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/defense/wall_area_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_borders_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_stairs_tool")

end)