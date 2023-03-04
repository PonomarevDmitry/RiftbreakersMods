RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker")
    BuildingService:UnlockBuilding("buildings/tools/buildings_saver")
end)

