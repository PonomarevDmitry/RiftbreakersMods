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

    local firstLevelBlueprint = LastSelectedBlueprintsListUtils:GetFirstLevelBuilding(blueprintName)

    LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(currentListArray, firstLevelBlueprint)


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

function LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(list, blueprintName, seenBlueprintList)

    if ( IndexOf( list, blueprintName ) ~= nil ) then
        Remove( list, blueprintName )
    end

    seenBlueprintList = seenBlueprintList or {}

    if ( seenBlueprintList[blueprintName] == true ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then

        local buildingDescRef = reflection_helper( buildingDesc )

        LastSelectedBlueprintsListUtils:RemoveFromListByBuildingDescRef( list, buildingDescRef )

        seenBlueprintList[blueprintName] = true

        if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

            self:RemoveBuildingAndUpgradesFromList( list, buildingDescRef.upgrade, seenBlueprintList )
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                self:RemoveBuildingAndUpgradesFromList( list, connectBlueprintName, seenBlueprintList )
            end
        end
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:RemoveBuildingAndUpgradesFromList( list, baseBuildingDescRef.bp, seenBlueprintList )
        end
    end
end

function LastSelectedBlueprintsListUtils:RemoveFromListByBuildingDescRef( list, buildingDescRef )

    if ( IndexOf( list, buildingDescRef.bp ) ~= nil ) then

        Remove( list, buildingDescRef.bp )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( IndexOf( list, connectBlueprintName ) ~= nil ) then

                Remove( list, connectBlueprintName )
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