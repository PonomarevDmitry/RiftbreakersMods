if ( not is_server ) then
    return
end

local floor_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end
    
    BuildingService:UnlockBuilding("buildings/decorations/floor_center_tool")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_1")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_2")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_3")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_4")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    floor_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_tool_autoexec(evt)
end)