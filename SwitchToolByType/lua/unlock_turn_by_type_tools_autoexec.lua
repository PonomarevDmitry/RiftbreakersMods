require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/turn_by_type_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_1_picker")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_2_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_3_on_group")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_4_off")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_5_off_group")
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

    local buildingType = buildingComponent:GetField("type"):GetValue()
    if ( buildingType == "floor" ) then
        return
    end

    local list = BuildingService:GetBuildCosts( blueprintName, playerId )
    if ( #list == 0 ) then
        return
    end

    if ( not PowerUtils:BlueprintCanChangePower(blueprintName)) then
        return
    end

    local parameterName = "$turn_on_off_by_type_picker_tool.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)