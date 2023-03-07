RegisterGlobalEventHandler("EnterBuildMenuEvent", function(arg)

    QueueEvent( "LuaGlobalEvent", event_sink, "CultivatorShowPlantIcon", {} )
end)

RegisterGlobalEventHandler("EnterFighterModeEvent", function(arg)

    QueueEvent( "LuaGlobalEvent", event_sink, "CultivatorHidePlantIcon", {} )
end)