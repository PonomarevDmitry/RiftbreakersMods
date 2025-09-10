if ( not is_server ) then
    return
end

local replace_wall_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_1_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_2_crystal")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_3_small")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_4_vine")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_picker")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_all_replacer")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_1")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_picker_2")

    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_1_to_2")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_replacer_from_2_to_1")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    replace_wall_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    replace_wall_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    replace_wall_tool_autoexec(evt)
end)