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
    if ( selector ) then

        local selectorDB = EntityService:GetDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase ) then
        campaignDatabase:SetString( parameterName, blueprintName )
    end
end)