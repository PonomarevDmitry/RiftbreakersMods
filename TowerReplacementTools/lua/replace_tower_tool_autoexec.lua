require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_2_to_1")
end)

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

    local buildingComponentRef = reflection_helper(buildingComponent)
    if ( buildingDescRef.type ~= "tower" ) then
        return
    end

    local list = BuildingService:GetBuildCosts( blueprintName, playerId )
    if ( #list == 0 ) then
        return
    end

    local parameterName = "$replace_tower_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)