RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_picker")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer_all_map")

    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate_all_map")
end)