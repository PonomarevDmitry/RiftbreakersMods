if ( not is_server ) then
    return
end

local free_roam_camera_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/free_roam_camera")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    free_roam_camera_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    free_roam_camera_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    free_roam_camera_tool_autoexec(evt)
end)