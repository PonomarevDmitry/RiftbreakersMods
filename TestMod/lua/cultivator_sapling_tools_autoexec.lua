RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/cultivator_sapling_picker")
    BuildingService:UnlockBuilding("buildings/tools/cultivator_sapling_saver")
end)

