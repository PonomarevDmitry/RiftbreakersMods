if ( not is_server ) then
    return
end

local unlock_turn_by_type_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_1_picker")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_2_on")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_3_off")

    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_4_on_group")
    BuildingService:UnlockBuilding("buildings/tools/turn_by_type_5_off_group")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    unlock_turn_by_type_tools_autoexec(evt)
end)