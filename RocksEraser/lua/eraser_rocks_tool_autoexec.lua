local eraser_rocks_tool_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_rocks")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    eraser_rocks_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    eraser_rocks_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    eraser_rocks_tool_autoexec(evt)
end)