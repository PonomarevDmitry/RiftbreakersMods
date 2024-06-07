require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/switch_all_map_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

local switch_all_map_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/switch_all_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/switch_all_map_1_switcher")

    BuildingService:UnlockBuilding("buildings/tools/switch_all_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/switch_all_map_2_cat_switcher")

    BuildingService:UnlockBuilding("buildings/tools/switch_all_map_3")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    switch_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    switch_all_map_tools_autoexec(evt)
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
        local parameterName = "$switch_all_map_cat_picker_tool.last_selected_categories"

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

    local list = BuildingService:GetBuildCosts( blueprintName, playerId )
    if ( #list == 0 ) then
        return
    end

    if ( PowerUtils:BlueprintCanChangePower(blueprintName)) then

        local parameterName = "$switch_all_map_picker_tool.last_selected_buildings"
    
        LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
    end
end)