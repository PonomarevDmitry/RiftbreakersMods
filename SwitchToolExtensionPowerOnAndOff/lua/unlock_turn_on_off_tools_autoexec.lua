RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/turn_1_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_2_off")

    BuildingService:UnlockBuilding("buildings/tools/turn_3_picker")

    BuildingService:UnlockBuilding("buildings/tools/turn_4_by_type_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_5_by_group_on")

    BuildingService:UnlockBuilding("buildings/tools/turn_6_by_type_off")
    BuildingService:UnlockBuilding("buildings/tools/turn_7_by_group_off")
end)