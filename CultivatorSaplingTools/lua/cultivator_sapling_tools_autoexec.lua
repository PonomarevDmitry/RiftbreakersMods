RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/sapling_picker")
    BuildingService:UnlockBuilding("buildings/tools/sapling_replacer")
end)

