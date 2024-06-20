local wall_breaker_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local skillName = "items/skills/wall_breaker_item"

    local itemCount = ItemService:GetItemCount( player, skillName )

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    wall_breaker_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    wall_breaker_autoexec(evt)
end)