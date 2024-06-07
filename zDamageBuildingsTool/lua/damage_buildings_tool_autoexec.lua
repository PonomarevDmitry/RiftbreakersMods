local damage_buildings_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/damage_buildings")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", damage_buildings_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", damage_buildings_tool_autoexec)