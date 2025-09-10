if ( not is_server ) then
    return
end

local energy_connector_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_1")

    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_2")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_3")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_4")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    energy_connector_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    energy_connector_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    energy_connector_tool_autoexec(evt)
end)