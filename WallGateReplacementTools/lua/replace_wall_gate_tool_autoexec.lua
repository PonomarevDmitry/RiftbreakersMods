RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_1_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_2_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_3_small")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_replacer_from_2_to_1")
end)