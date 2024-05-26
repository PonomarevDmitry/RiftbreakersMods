require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/replace_wall_tool_last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_1_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_2_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_3_small")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_4_vine")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_2_to_1")
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local selector = evt:GetEntity()

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(selector, "PlayerReferenceComponent") )
    local playerId = playerReferenceComponent.player_id

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName == "wall_small_floor" ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper(buildingDesc)
    if ( buildingDescRef.category == "tools" ) then
        return
    end

    if ( buildingDescRef.type ~= "wall" or buildingDescRef.category == "decorations" ) then
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

    local parameterName = "$replace_wall_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)