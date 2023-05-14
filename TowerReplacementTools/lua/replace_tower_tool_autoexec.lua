RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_2_to_1")
end)