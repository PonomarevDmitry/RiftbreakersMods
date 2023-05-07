RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_obstacles_stairs_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_area_tool")
    BuildingService:UnlockBuilding("buildings/defense/wall_perimeter_tool")
end)