local damage_buildings_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/damage_buildings")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    damage_buildings_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    damage_buildings_tool_autoexec(evt)
end)