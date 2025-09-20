if ( not is_client ) then
    return
end

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local selectedBluprintsNames = {

        "wind_turbine",
        "solar_panels",

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "bio_condenser",

        "liquid_pump",

        "geothermal_powerplant",
        "gas_extractor",

        "acid_refinery",
        "magma_lifter",
        "supercoolant_siphon",

        "morphium_extractor",

        "survival_acid_refinery",
        "survival_magma_lifter",
        "survival_supercoolant_siphon",
    }

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( IndexOf( selectedBluprintsNames, lowName ) == nil ) then
        return
    end

    local parameterName = "$selected_" .. lowName .. "_blueprint"

    local selector = evt:GetEntity()
    if ( selector and selector ~= INVALID_ID ) then

        local selectorDB = EntityService:GetOrCreateDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end

        local playerId = PlayerService:GetPlayerForEntity( selector )

        if ( playerId ~= nil and playerId ~= -1 ) then

            local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )

            if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

                if ( globalPlayerEntityDB ) then
                    globalPlayerEntityDB:SetString( parameterName, blueprintName )
                end
            end
        end
    end
end)