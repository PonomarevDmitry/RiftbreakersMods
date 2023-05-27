RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/resource_miner_picker")
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local selectedBluprintsNames = {

        "wind_turbine",
        "solar_panels",

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "liquid_pump",

        "geothermal_powerplant",

        "acid_refinery",
        "magma_lifter",
        "supercoolant_siphon",

        "survival_acid_refinery",
        "survival_magma_lifter",
        "survival_supercoolant_siphon",
    }

    local blueprintName = evt:GetBlueprint()

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( IndexOf( selectedBluprintsNames, lowName ) == nil ) then
        return
    end

    local selector = evt:GetEntity()

    if ( selector == nil ) then
        return
    end

    local selectorDB = EntityService:GetDatabase( selector )

    local parameterName = "$selected_" .. lowName .. "_blueprint"

    selectorDB:SetString( parameterName, blueprintName )
end)