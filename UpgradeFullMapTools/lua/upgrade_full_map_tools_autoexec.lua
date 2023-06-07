RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_1_upgrader")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_2_cat_upgrader")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_3")
end)