local rift_portal_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/portal_chain_tool")
    BuildingService:UnlockBuilding("buildings/defense/portal_builder_tool")
    BuildingService:UnlockBuilding("buildings/defense/portal_builder_tool2")
    BuildingService:UnlockBuilding("buildings/defense/rift_portal_tool_green")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    rift_portal_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    rift_portal_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    rift_portal_tools_autoexec(evt)
end)