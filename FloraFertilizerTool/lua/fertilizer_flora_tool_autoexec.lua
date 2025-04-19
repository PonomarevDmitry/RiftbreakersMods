local fertilizer_flora_tool_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/fertilizer_flora")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    fertilizer_flora_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    fertilizer_flora_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    fertilizer_flora_tool_autoexec(evt)
end)