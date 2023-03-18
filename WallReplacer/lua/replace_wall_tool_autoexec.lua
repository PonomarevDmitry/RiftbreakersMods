RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_01")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_02")
end)

