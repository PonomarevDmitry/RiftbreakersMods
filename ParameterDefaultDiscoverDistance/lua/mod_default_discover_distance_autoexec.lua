mod_default_discover_distance = 30

local mod_default_discover_distance_autoexec = function(evt)

    mod_default_discover_distance = 30
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    mod_default_discover_distance_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    mod_default_discover_distance_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    mod_default_discover_distance_autoexec(evt)
end)