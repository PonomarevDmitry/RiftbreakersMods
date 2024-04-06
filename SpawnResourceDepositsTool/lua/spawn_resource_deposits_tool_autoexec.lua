RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_1_carbonium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_2_steel")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_3_cobalt")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_4_palladium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_5_titanium")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_6_uranium_ore")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_7_uranium")
end)