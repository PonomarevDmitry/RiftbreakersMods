RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    LogService:Log("Unlocking")

    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_1_powerplant")
    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_2_factory")
end)