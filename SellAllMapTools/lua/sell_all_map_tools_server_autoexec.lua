if ( not is_server ) then
    return
end

local sell_all_map_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_all_map_1_picker")
    BuildingService:UnlockBuilding("buildings/tools/sell_all_map_1_seller")

    BuildingService:UnlockBuilding("buildings/tools/sell_all_map_2_cat_picker")
    BuildingService:UnlockBuilding("buildings/tools/sell_all_map_2_cat_seller")

    BuildingService:UnlockBuilding("buildings/tools/sell_all_map_3")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    sell_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    sell_all_map_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    sell_all_map_tools_autoexec(evt)
end)