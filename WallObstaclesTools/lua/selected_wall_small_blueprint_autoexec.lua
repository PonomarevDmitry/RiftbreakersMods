require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName == "wall_small_floor" ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper(buildingDesc)
    if ( buildingDescRef.type ~= "wall" or buildingDescRef.category == "decorations" ) then
        return
    end



    local parameterName = "$selected_wall_small_blueprint"

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