RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_small")
end)

