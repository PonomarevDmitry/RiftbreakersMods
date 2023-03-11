RegisterGlobalEventHandler("EnterBuildMenuEvent", function(arg)

    QueueEvent( "LuaGlobalEvent", event_sink, "CompressorsShowLiquidIcon", {} )
end)

RegisterGlobalEventHandler("EnterFighterModeEvent", function(arg)

    QueueEvent( "LuaGlobalEvent", event_sink, "CompressorsHideLiquidIcon", {} )
end)