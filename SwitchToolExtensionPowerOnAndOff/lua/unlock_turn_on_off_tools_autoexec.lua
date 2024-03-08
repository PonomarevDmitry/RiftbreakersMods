RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/turn_1_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_2_off")

    BuildingService:UnlockBuilding("buildings/tools/turn_8_switch_all_by_type")
    BuildingService:UnlockBuilding("buildings/tools/turn_9_switch_all_by_group")
end)