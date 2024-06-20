local grenades_pack_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local skillList = {

        "items/skills/grenades_pack_1_item",
        "items/skills/grenades_pack_2_item",
        "items/skills/grenades_pack_3_item"
    }

    for skillName in Iter( skillList ) do

        local itemCount = ItemService:GetItemCount( player, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    grenades_pack_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    grenades_pack_autoexec(evt)
end)