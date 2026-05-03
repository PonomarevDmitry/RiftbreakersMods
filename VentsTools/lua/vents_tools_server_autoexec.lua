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

    BuildingService:UnlockBuilding("buildings/tools/vents_preserve")
    BuildingService:UnlockBuilding("buildings/tools/vents_respawn")
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