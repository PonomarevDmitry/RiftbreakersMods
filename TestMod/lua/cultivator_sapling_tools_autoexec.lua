RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/cultivator_sapling_picker_tool")
    BuildingService:UnlockBuilding("buildings/tools/cultivator_sapling_inserter_tool")
end)

