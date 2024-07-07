local cultivator_sapling_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/sapling_picker")
    BuildingService:UnlockBuilding("buildings/tools/sapling_replacer")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    cultivator_sapling_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    cultivator_sapling_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    cultivator_sapling_tools_autoexec(evt)
end)