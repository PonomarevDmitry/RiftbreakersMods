RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_1_repairer")

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_2_cat_repairer")

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_3")
end)