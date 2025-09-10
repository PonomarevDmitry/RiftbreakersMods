if ( not is_server ) then
    return
end

local building_search_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/building_search_1_select")

    BuildingService:UnlockBuilding("buildings/tools/building_search_2_clear")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    building_search_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    building_search_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    building_search_tools_autoexec(evt)
end)