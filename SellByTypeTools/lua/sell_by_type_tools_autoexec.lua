require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/sell_by_type_tools_last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_picker")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_group")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin_group")
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

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return
    end

    local buildingComponent = blueprint:GetComponent("BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    local buildingComponentRef = reflection_helper(buildingComponent)
    if ( buildingComponentRef.type == "floor" ) then
        return
    end

    if ( buildingComponentRef.m_isSellable == false ) then
        return
    end

    local list = BuildingService:GetBuildCosts( blueprintName, playerId )
    if ( #list == 0 ) then
        return
    end

    local parameterName = "$sell_by_type_picker_tool.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)