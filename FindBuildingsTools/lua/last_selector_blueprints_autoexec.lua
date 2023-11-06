require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint()
    local selector = evt:GetEntity()

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(selector, "PlayerReferenceComponent") )
    local playerId = playerReferenceComponent.player_id

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper(buildingDesc)
    if ( buildingDescRef.category == "tools" ) then
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return
    end

    local buildingComponent = blueprint:GetComponent("BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    local list = BuildingService:GetBuildCosts( blueprintName, playerId )
    if ( #list == 0 ) then
        return
    end





    local parameterName = "$last_selected_blueprint"

    local currentList = ""

    local campaignDatabase = CampaignService:GetCampaignData()

    local selectorDB = EntityService:GetDatabase( selector )

    if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
        currentList = campaignDatabase:GetString( parameterName ) or ""
    end

    if ( currentList ~= "" ) then

        if ( selectorDB and selectorDB:HasString(parameterName) ) then

            currentList = selectorDB:GetString( parameterName ) or ""
        end
    end

    local currentListArray = Split( currentList, "|" )

    if ( IndexOf( currentListArray, blueprintName ) ~= nil ) then
        Remove( currentListArray, blueprintName )
    end

    local firstLevelBlueprint = blueprintName

    if ( buildingDescRef.level ~= 1 ) then

        local suffix = "_lvl_" .. tostring(buildingDescRef.level)

        if ( blueprintName:sub(-#suffix) == suffix ) then

            firstLevelBlueprint = blueprintName:sub(1,-#suffix-1)
        end
    end

    if ( ResourceManager:ResourceExists( "EntityBlueprint", firstLevelBlueprint )  ) then

        local firstBuildingDesc = BuildingService:GetBuildingDesc( firstLevelBlueprint )
        if ( firstBuildingDesc ~= nil ) then

            local varBuildingDescRef = reflection_helper(firstBuildingDesc)

            while ( varBuildingDescRef ~= nil ) do

                if ( IndexOf( currentListArray, varBuildingDescRef.bp ) ~= nil ) then
                    Remove( currentListArray, varBuildingDescRef.bp )
                end

                local upgradeBlueprintName = varBuildingDescRef.upgrade
                varBuildingDescRef = nil

                if ( upgradeBlueprintName ~= "" and upgradeBlueprintName ~= nil and ResourceManager:ResourceExists( "EntityBlueprint", upgradeBlueprintName )  ) then

                    local upgradeBuildingDesc = BuildingService:GetBuildingDesc( upgradeBlueprintName )
                    if ( upgradeBuildingDesc ~= nil ) then

                        varBuildingDescRef = reflection_helper(upgradeBuildingDesc)
                    end
                end

            end
        end
    end




    Insert( currentListArray, blueprintName )

    local maxBlueprints = 10

    while ( #currentListArray > maxBlueprints ) do

        table.remove( currentListArray, 1 )
    end

    currentList = table.concat( currentListArray, "|" )

    if ( selectorDB ) then
        selectorDB:SetString(parameterName, currentList)
    end

    if ( campaignDatabase ) then
        campaignDatabase:SetString( parameterName, currentList )
    end
end)