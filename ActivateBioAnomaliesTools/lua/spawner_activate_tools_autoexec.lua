if ( not is_server ) then
    return
end

local spawners_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/spawner_activate")
    BuildingService:UnlockBuilding("buildings/tools/spawner_activate_all_map")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    spawners_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    spawners_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    spawners_autoexec(evt)
end)