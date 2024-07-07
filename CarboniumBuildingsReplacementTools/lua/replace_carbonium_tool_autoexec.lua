local replace_carbonium_tool_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_1_powerplant")
    BuildingService:UnlockBuilding("buildings/tools/replace_carbonium_to_2_factory")
end

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    replace_carbonium_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    replace_carbonium_tool_autoexec(evt)
end)