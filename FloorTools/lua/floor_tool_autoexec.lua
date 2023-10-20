RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_1")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_2")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_3")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_4")
end)