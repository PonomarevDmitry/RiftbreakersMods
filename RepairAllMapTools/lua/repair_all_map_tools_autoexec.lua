require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/repair_all_map_tools_last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_1_repairer")

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_2_cat_repairer")

    BuildingService:UnlockBuilding("buildings/tools/repair_all_map_3")
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

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



    local category = buildingDescRef.category or ""
    if ( category ~= "" ) then
        local parameterName = "$repair_all_map_cat_picker_tool.last_selected_categories"

        LastSelectedBlueprintsListUtils:AddStringToList(parameterName, selector, category)
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

    local parameterName = "$repair_all_map_picker_tool.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)