RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName ~= "floor_1x1" ) then
        return
    end

    local parameterName = "$selected_" .. lowName .. "_blueprint"

    local selector = evt:GetEntity()
    if ( selector and selector ~= INVALID_ID ) then

        local selectorDB = EntityService:GetOrCreateDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end
    end

    if ( CampaignService.GetCampaignData ) then
    
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase ) then
            campaignDatabase:SetString( parameterName, blueprintName )
        end
    end
end)