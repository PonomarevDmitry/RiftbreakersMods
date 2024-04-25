RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/main/artificial_spawner")

    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_picker")
    BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer")
end)