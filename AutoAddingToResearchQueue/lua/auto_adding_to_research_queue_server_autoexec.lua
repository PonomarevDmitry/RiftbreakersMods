if ( not is_server ) then
    return
end

RegisterGlobalEventHandler("NewResearchAvailableEvent", function(evt)

    if ( not is_server ) then
        return
    end

    if (evt == nil) then
        return
    end

    local hubsNamesArray = {

        "communications_hub",
        "communications_hub_lvl_2",
        "communications_hub_lvl_3",
        "communications_hub_lvl_4",
        "communications_hub_lvl_5",
    }

    local buildingBuild = false

    for index=1,#hubsNamesArray do

        local name = hubsNamesArray[index]

        local blueprintName = "buildings/main/" .. name

        local hasBuilding = BuildingService:HasBuildingWithBp(blueprintName)

        local buildingCount = BuildingService:GetBuildingByBpCount(blueprintName)

        local globalBuildingCount = BuildingService:GetGlobalBuildingByNameCount(name)

        --LogService:Log("blueprintName " .. blueprintName .. " hasBuilding " .. tostring(hasBuilding) .. " buildingCount " .. tostring(buildingCount) .. " globalBuildingCount " .. tostring(globalBuildingCount))

        if ( hasBuilding or ( buildingCount > 0 ) or ( globalBuildingCount > 0 ) ) then

            buildingBuild = true

            break
        end
    end 

    --LogService:Log("buildingBuild " .. tostring(buildingBuild))

    if ( not buildingBuild ) then
        return
    end

    local researchName = evt:GetName()

    if ( researchName == nil or researchName == "" ) then
        return
    end



    local leadingPlayer = PlayerService:GetLeadingPlayer()

    QueueEvent( "AddToResearchRequest", INVALID_ID, researchName, leadingPlayer )
end)