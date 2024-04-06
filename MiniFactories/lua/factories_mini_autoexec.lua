RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/resources/carbonium_factory_mini")
    BuildingService:UnlockBuilding("buildings/resources/carbonium_factory_mini_lvl_2")
    BuildingService:UnlockBuilding("buildings/resources/carbonium_factory_mini_lvl_3")

    BuildingService:UnlockBuilding("buildings/resources/steel_factory_mini")
    BuildingService:UnlockBuilding("buildings/resources/steel_factory_mini_lvl_2")
    BuildingService:UnlockBuilding("buildings/resources/steel_factory_mini_lvl_3")

    BuildingService:UnlockBuilding("buildings/resources/rare_element_mine_mini")
    BuildingService:UnlockBuilding("buildings/resources/rare_element_mine_mini_lvl_2")
    BuildingService:UnlockBuilding("buildings/resources/rare_element_mine_mini_lvl_3")

end)