local mass_disassembly_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/main/mass_disassembly")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_by_rarity")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_enable_mods")
    BuildingService:UnlockBuilding("buildings/main/mass_disassembly_equal_and_lower")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", mass_disassembly_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", mass_disassembly_autoexec)