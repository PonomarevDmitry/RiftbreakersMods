if ( not is_server ) then
    return
end

local equipment_quick_configurations_load_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/equipment_quick_configurations_load")
    BuildingService:UnlockBuilding("buildings/tools/equipment_quick_configurations_save")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    equipment_quick_configurations_load_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    equipment_quick_configurations_load_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    equipment_quick_configurations_load_tool_autoexec(evt)
end)