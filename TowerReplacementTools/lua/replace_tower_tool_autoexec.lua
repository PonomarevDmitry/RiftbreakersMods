require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/replace_tower_tool_last_selected_blueprints_utils.lua")

local replace_tower_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_tower_replacer_from_2_to_1")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    replace_tower_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    replace_tower_tool_autoexec(evt)
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

    if ( buildingDescRef.type ~= "tower" ) then
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

    local parameterName = "$replace_tower_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)