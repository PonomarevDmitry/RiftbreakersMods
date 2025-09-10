if ( not is_server ) then
    return
end

local upgrade_all_map_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/upgrade_all_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_all_map_1_upgrader")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_all_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/upgrade_all_map_2_cat_upgrader")

    BuildingService:UnlockBuilding("buildings/tools/upgrade_all_map_3")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    upgrade_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    upgrade_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    upgrade_all_map_tools_autoexec(evt)
end)