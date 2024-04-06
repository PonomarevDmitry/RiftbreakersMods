RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/resources/factory_mini")
    BuildingService:UnlockBuilding("buildings/resources/factory_mini_lvl_2")
    BuildingService:UnlockBuilding("buildings/resources/factory_mini_lvl_3")

end)