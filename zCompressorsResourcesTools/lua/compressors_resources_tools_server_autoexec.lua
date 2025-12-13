if ( not is_server ) then
    return
end

local compressors_resources_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/compressors_resources_picker")
    BuildingService:UnlockBuilding("buildings/tools/compressors_resources_replacer")
    BuildingService:UnlockBuilding("buildings/tools/compressors_resources_replacer_all")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    compressors_resources_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    compressors_resources_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    compressors_resources_tools_autoexec(evt)
end)