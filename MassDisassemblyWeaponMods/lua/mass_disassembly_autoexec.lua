RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/main/mass_disassembly")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_by_rarity")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_enable_mods")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_equal_and_lower")
end)