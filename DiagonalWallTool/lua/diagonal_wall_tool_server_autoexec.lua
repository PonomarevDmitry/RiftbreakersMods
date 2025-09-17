if ( not is_server ) then
    return
end

local diagonal_wall_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/diagonal_wall_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    diagonal_wall_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    diagonal_wall_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    diagonal_wall_tool_autoexec(evt)
end)