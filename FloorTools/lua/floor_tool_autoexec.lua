local floor_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_1")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_2")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_3")
    BuildingService:UnlockBuilding("buildings/decorations/floor_tool_4")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", floor_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", floor_tool_autoexec)