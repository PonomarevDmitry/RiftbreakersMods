if ( not is_server ) then
    return
end

local buildings_templates_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local toolBlueprint = ""

    for number = 1, 60 do

        toolBlueprint = "buildings/tools/buildings_picker_" .. string.format( "%02d", number )

        if ( ResourceManager:ResourceExists( "EntityBlueprint", toolBlueprint ) ) then

            BuildingService:UnlockBuilding(toolBlueprint)
        end



        toolBlueprint = "buildings/tools/buildings_builder_" .. string.format( "%02d", number )

        if ( ResourceManager:ResourceExists( "EntityBlueprint", toolBlueprint ) ) then

            BuildingService:UnlockBuilding(toolBlueprint)
        end



        toolBlueprint = "buildings/tools/buildings_builder_mass_" .. string.format( "%02d", number )

        if ( ResourceManager:ResourceExists( "EntityBlueprint", toolBlueprint ) ) then

            BuildingService:UnlockBuilding(toolBlueprint)
        end
    end





    BuildingService:UnlockBuilding("buildings/tools/buildings_upgrader")
    BuildingService:UnlockBuilding("buildings/tools/buildings_eraser")
    BuildingService:UnlockBuilding("buildings/tools/buildings_swap_templates")

    BuildingService:UnlockBuilding("buildings/tools/buildings_database_select")
    BuildingService:UnlockBuilding("buildings/tools/buildings_database_exporter")
    BuildingService:UnlockBuilding("buildings/tools/buildings_database_importer")
    BuildingService:UnlockBuilding("buildings/tools/buildings_database_eraser")
    BuildingService:UnlockBuilding("buildings/tools/buildings_database_swap_templates")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    buildings_templates_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    buildings_templates_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    buildings_templates_autoexec(evt)
end)