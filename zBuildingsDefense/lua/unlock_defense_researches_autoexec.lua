if ( not is_server ) then
    return
end

local unlock_defense_researches_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    if ( researchComponent == nil ) then
        return
    end

    --PlayerService:UnlockResearch( "gui/menu/research/name/towers_morphium_lvl1" )

    PlayerService:UnhideResearch( "gui/menu/research/name/towers_morphium_lvl1" )

    PlayerService:EnableResearch( "gui/menu/research/name/towers_morphium_lvl1" )
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    unlock_defense_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    unlock_defense_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    unlock_defense_researches_autoexec(evt)
end)