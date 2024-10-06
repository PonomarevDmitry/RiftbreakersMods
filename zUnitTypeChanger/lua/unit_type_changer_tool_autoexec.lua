local unit_type_changer_tool_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/unit_type_add_invisible")
    BuildingService:UnlockBuilding("buildings/tools/unit_type_remove_invisible")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    unit_type_changer_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    unit_type_changer_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    unit_type_changer_tool_autoexec(evt)
end)