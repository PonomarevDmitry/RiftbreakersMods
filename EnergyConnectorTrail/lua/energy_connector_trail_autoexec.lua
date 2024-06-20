local energy_connector_trail_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local skillName = "items/skills/energy_connector_trail"

    local itemCount = ItemService:GetItemCount( player, skillName )

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    energy_connector_trail_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    energy_connector_trail_autoexec(evt)
end)