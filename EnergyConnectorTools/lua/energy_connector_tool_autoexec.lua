local energy_connector_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_1")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_2")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_3")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", energy_connector_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", energy_connector_tool_autoexec)