local floor_rebuilder_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/floor_rebuilder")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", floor_rebuilder_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", floor_rebuilder_tool_autoexec)