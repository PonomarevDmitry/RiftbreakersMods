if ( not is_server ) then
    return
end

local loot_collecting_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting")

    BuildingService:UnlockBuilding("buildings/tools/loot_collecting_all_map")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    loot_collecting_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    loot_collecting_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    loot_collecting_tools_autoexec(evt)
end)