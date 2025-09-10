if ( not is_server ) then
    return
end

local sell_by_type_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_picker")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_group")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin_group")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    sell_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    sell_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    sell_by_type_tools_autoexec(evt)
end)