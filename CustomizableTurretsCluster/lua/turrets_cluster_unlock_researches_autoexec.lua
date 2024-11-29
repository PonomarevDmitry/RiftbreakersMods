require("lua/utils/reflection.lua")

local turrets_cluster_unlock_researches_autoexec = function(evt)

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    if ( researchComponent == nil ) then
        return nodes
    end

    local researchComponentRef = reflection_helper( researchComponent )

    --PlayerService:UnhideResearch( "gui/menu/research/name/turrets_cluster_mods_scanner_turret_standard_item" )
    --PlayerService:EnableResearch( "gui/menu/research/name/turrets_cluster_mods_scanner_turret_standard_item" )
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)