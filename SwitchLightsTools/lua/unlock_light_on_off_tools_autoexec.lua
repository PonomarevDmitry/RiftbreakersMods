RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/light_1_on")
    BuildingService:UnlockBuilding("buildings/tools/light_2_off")

    BuildingService:UnlockBuilding("buildings/tools/light_switcher_all_map")
end)