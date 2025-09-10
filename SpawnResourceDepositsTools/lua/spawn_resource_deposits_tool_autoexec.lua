if ( not is_server ) then
    return
end

local spawn_resource_deposits_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_1_carbonium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_2_steel")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_3_cobalt")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_4_palladium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_5_titanium")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_6_uranium_ore")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_7_uranium")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    spawn_resource_deposits_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    spawn_resource_deposits_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    spawn_resource_deposits_tool_autoexec(evt)
end)