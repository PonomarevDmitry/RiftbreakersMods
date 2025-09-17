if ( not is_server ) then
    return
end

local floor_rebuilder_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/floor_rebuilder")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_rebuilder_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    floor_rebuilder_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_rebuilder_tool_autoexec(evt)
end)