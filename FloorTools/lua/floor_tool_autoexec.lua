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

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_tool_autoexec(evt)
end)