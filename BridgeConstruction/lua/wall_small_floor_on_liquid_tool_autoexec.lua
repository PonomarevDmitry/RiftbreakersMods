if ( not is_server ) then
    return
end

local wall_obstacles_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/defense/wall_small_floor_on_liquid_tool")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    wall_obstacles_tool_autoexec(evt)
end)