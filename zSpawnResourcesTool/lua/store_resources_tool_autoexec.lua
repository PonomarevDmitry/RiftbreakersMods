RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/store_resources_1_carbonium")
    BuildingService:UnlockBuilding("buildings/tools/store_resources_2_steel")

    BuildingService:UnlockBuilding("buildings/tools/store_resources_3_cobalt")
    BuildingService:UnlockBuilding("buildings/tools/store_resources_4_palladium")
    BuildingService:UnlockBuilding("buildings/tools/store_resources_5_titanium")

    BuildingService:UnlockBuilding("buildings/tools/store_resources_6_uranium_ore")
    BuildingService:UnlockBuilding("buildings/tools/store_resources_7_uranium")
end)