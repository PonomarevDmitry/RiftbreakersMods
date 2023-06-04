RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint()

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName ~= "wall_small" ) then
        return
    end

    local parameterName = "$selected_wall_small_blueprint"

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