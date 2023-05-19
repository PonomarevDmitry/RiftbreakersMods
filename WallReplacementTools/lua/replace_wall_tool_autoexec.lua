RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_small")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_2_to_1")
end)