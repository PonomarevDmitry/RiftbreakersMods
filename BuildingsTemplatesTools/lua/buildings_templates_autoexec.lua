local buildings_templates_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_01")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_02")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_03")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_04")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_05")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_06")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_07")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_08")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_09")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_10")

    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_11")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_12")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_13")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_14")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_15")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_16")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_17")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_18")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_19")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_20")

    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_21")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_22")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_23")
    BuildingService:UnlockBuilding("buildings/tools/buildings_picker_24")





    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_01")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_02")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_03")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_04")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_05")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_06")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_07")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_08")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_09")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_10")

    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_11")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_12")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_13")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_14")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_15")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_16")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_17")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_18")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_19")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_20")

    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_21")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_22")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_23")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_24")





    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_01")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_02")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_03")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_04")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_05")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_06")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_07")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_08")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_09")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_10")

    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_11")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_12")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_13")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_14")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_15")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_16")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_17")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_18")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_19")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_20")

    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_21")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_22")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_23")
    BuildingService:UnlockBuilding("buildings/tools/buildings_builder_mass_24")





    BuildingService:UnlockBuilding("buildings/tools/buildings_upgrader")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    buildings_templates_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    buildings_templates_autoexec(evt)
end)