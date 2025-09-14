if ( not is_client ) then
    return
end

require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/building_search_tools_last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local selector = evt:GetEntity()
    if ( selector == nil or selector == INVALID_ID ) then
        return
    end

    local playerReferenceComponent = EntityService:GetComponent(selector, "PlayerReferenceComponent")
    if ( playerReferenceComponent == nil ) then
        return
    end

    local playerReferenceComponent = reflection_helper( playerReferenceComponent )
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

    local buildingType = buildingComponent:GetField("type"):GetValue()
    if ( buildingType == "floor" ) then
        return
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return
    end

    local parameterName = "$last_selected_blueprint"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)