if ( not is_server ) then
    return
end

local ruins_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_1_place_ruins")
    BuildingService:UnlockBuilding("buildings/tools/sell_2_ruins_eraser")
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    ruins_tools_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    ruins_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    ruins_tools_autoexec(evt)
end)