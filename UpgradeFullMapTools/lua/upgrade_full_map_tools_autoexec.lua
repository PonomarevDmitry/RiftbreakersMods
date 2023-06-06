RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_1_upgrader")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_3")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_2_main")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_3_energy")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_4_resources")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_full_map_5_defense")
end)