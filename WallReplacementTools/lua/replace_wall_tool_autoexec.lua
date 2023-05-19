RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_small")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_from_to_replacer_1_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_from_to_replacer_2_1")
end)