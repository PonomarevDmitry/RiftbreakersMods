if ( not is_server ) then
    return
end

local provoke_creatures_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/provoke_creatures")
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    provoke_creatures_tool_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    provoke_creatures_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    provoke_creatures_tool_autoexec(evt)
end)