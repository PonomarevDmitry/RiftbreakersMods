if ( not is_server ) then
    return
end

local eraser_mines_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/eraser_mines")
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    eraser_mines_tool_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    eraser_mines_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    eraser_mines_tool_autoexec(evt)
end)