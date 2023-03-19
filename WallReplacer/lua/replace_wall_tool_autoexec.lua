RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_energy")
    BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_small")

    if ( ResourceManager:ResourceExists( "EntityBlueprint", "buildings/defense/wall_kinetic_straight_01" ) ) then
        BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_kinetic")
    end

    if ( ResourceManager:ResourceExists( "EntityBlueprint", "buildings/defense/wall_radio_straight_01" ) ) then
        BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_radio")
    end

    if ( ResourceManager:ResourceExists( "EntityBlueprint", "buildings/defense/wall_ion_straight_01" ) ) then
        BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_ion")
    end

    if ( ResourceManager:ResourceExists( "EntityBlueprint", "buildings/defense/wall_gravity_straight_01" ) ) then
        BuildingService:UnlockBuilding("buildings/tools/replace_wall_to_gravity")
    end
end)

