if ( not is_server ) then
    return
end

local switch_all_map_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
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

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    switch_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    switch_all_map_tools_autoexec(evt)
end)