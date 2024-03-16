RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting")

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting_all_map")
end)