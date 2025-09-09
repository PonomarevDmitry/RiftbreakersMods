require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/replace_wall_gate_tool_last_selected_blueprints_utils.lua")

local replace_wall_gate_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_1_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_2_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_3_small")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_to_4_vine")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_gate_replacer_from_2_to_1")
end

if ( is_server ) then

    --RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    --
    --    replace_wall_gate_tool_autoexec(evt)
    --end)

    RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

        replace_wall_gate_tool_autoexec(evt)
    end)

    RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

        replace_wall_gate_tool_autoexec(evt)
    end)
end

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

    if ( buildingDescRef.type ~= "gate" or buildingDescRef.category == "decorations" ) then
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

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return
    end

    local parameterName = "$replace_wall_gate_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)