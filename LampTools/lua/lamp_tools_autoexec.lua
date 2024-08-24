require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/replace_lamp_tool_last_selected_blueprints_utils.lua")

local lamp_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_1")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_2")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_3")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_4_sell")

    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_to_1_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_to_2_base")

    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_all_replacer")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_all_replacer_base")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_all_replacer_crystal")

    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_lamp_replacer_from_2_to_1")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    lamp_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    lamp_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    lamp_tools_autoexec(evt)
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

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
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

    local parameterName = "$selected_lamp_blueprint"

    if ( selector ) then

        local selectorDB = EntityService:GetDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase ) then
        campaignDatabase:SetString( parameterName, blueprintName )
    end

    local parameterName = "$replace_lamp_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)