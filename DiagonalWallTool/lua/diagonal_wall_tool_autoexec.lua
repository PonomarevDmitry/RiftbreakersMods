RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/defense/diagonal_wall_tool")
end)