if ( not is_server ) then
    return
end

local replace_tower_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
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

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    replace_tower_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    replace_tower_tool_autoexec(evt)
end)