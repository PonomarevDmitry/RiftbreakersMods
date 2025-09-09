if ( not is_server ) then
    return
end

local sell_energy_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_3_energy")
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    sell_energy_tool_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    sell_energy_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    sell_energy_tool_autoexec(evt)
end)