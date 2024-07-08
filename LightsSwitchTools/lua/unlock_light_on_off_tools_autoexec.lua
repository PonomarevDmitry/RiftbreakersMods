local unlock_light_on_off_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/light_1_on")
    BuildingService:UnlockBuilding("buildings/tools/light_2_off")

    BuildingService:UnlockBuilding("buildings/tools/light_switcher_all_map")
    BuildingService:UnlockBuilding("buildings/tools/light_switcher_mech")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    unlock_light_on_off_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    unlock_light_on_off_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    unlock_light_on_off_tools_autoexec(evt)
end)