local fertilizer_flora_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/fertilizer_flora")
end

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    fertilizer_flora_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    fertilizer_flora_tool_autoexec(evt)
end)