require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/turn_by_type_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

local unlock_turn_by_type_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_1_picker")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_2_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_3_off")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_4_on_group")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_5_off_group")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

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

    if ( not PowerUtils:BlueprintCanChangePower(blueprintName)) then
        return
    end

    local parameterName = "$turn_by_type_picker_tool.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)