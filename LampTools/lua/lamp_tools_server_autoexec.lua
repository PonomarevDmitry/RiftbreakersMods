if ( not is_server ) then
    return
end

local lamp_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_1")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_2")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_3")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_4_sell")
    BuildingService:UnlockBuilding("buildings/decorations/lamp_tool_5_sell_place_ruins")

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