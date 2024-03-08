require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = {}

LastSelectedBlueprintsListUtils.maxBlueprints = 20

function LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end



    local campaignDatabase = CampaignService:GetCampaignData()
    local selectorDB = nil
    if (selector) then
        selectorDB = EntityService:GetDatabase( selector )
    end


    local currentListArray = LastSelectedBlueprintsListUtils:GetCurrentList(parameterName, selectorDB, campaignDatabase)

    LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(currentListArray, blueprintName)


    Insert( currentListArray, blueprintName )

    while ( #currentListArray > LastSelectedBlueprintsListUtils.maxBlueprints ) do

        table.remove( currentListArray, 1 )
    end

    LastSelectedBlueprintsListUtils:SaveCurrentList(parameterName, selectorDB, campaignDatabase, currentListArray)
end

function LastSelectedBlueprintsListUtils:GetCurrentList(parameterName, selectorDB, campaignDatabase)

    local currentListString = LastSelectedBlueprintsListUtils:GetParameterString(parameterName, selectorDB, campaignDatabase)

    local currentListArray = Split( currentListString, "|" )

    return currentListArray
end

function LastSelectedBlueprintsListUtils:GetParameterString(parameterName, selectorDB, campaignDatabase)

    local currentList = ""

    if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
        currentList = campaignDatabase:GetString( parameterName ) or ""
    end

    if ( currentList ~= nil and currentList ~= "" ) then

        return currentList
    end

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetString( parameterName ) or ""
    end

    return currentList
end

function LastSelectedBlueprintsListUtils:SaveCurrentList(parameterName, selectorDB, campaignDatabase, currentListArray)

    local currentListString = table.concat( currentListArray, "|" )

    if ( selectorDB ) then
        selectorDB:SetString(parameterName, currentListString)
    end

    if ( campaignDatabase ) then
        campaignDatabase:SetString( parameterName, currentListString )
    end
end

function LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(currentListArray, blueprintName)

    if ( IndexOf( currentListArray, blueprintName ) ~= nil ) then
        Remove( currentListArray, blueprintName )
    end

    local firstLevelBlueprint = LastSelectedBlueprintsListUtils:GetFirstLevelBuilding(blueprintName)

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
end

function LastSelectedBlueprintsListUtils:GetFirstLevelBuilding(blueprintName)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then

        return blueprintName
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef.level == 1 ) then

        return buildingDescRef.bp
    end

    blueprintName = buildingDescRef.bp

    local suffix = "_lvl_" .. tostring(buildingDescRef.level)

    if ( blueprintName:sub(-#suffix) == suffix ) then

        local result = blueprintName:sub(1,-#suffix-1)

        if ( ResourceManager:ResourceExists( "EntityBlueprint", result )  ) then

            local buildingDesc = BuildingService:GetBuildingDesc( result )
            if ( buildingDesc ~= nil ) then

                return result
            end
        end
    end

    return blueprintName
end

function LastSelectedBlueprintsListUtils:AddStringToList(parameterName, selector, stringValue)

    if ( stringValue == "" or stringValue == nil ) then
        return
    end



    local campaignDatabase = CampaignService:GetCampaignData()
    local selectorDB = nil
    if (selector) then
        selectorDB = EntityService:GetDatabase( selector )
    end


    local currentListArray = LastSelectedBlueprintsListUtils:GetCurrentList(parameterName, selectorDB, campaignDatabase)

    if ( IndexOf( currentListArray, stringValue ) ~= nil ) then
        Remove( currentListArray, stringValue )
    end

    Insert( currentListArray, stringValue )



    LastSelectedBlueprintsListUtils:SaveCurrentList(parameterName, selectorDB, campaignDatabase, currentListArray)
end

return LastSelectedBlueprintsListUtils