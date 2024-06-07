local spawn_resource_deposits_tool_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_1_carbonium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_2_steel")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_3_cobalt")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_4_palladium")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_5_titanium")

    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_6_uranium_ore")
    BuildingService:UnlockBuilding("buildings/tools/spawn_resource_deposits_7_uranium")
end

RegisterGlobalEventHandler("PlayerCreatedEvent", spawn_resource_deposits_tool_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", spawn_resource_deposits_tool_autoexec)