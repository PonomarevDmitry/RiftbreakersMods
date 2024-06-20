local auto_mines_laying_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/auto_mines_laying_1_item",
        "items/skills/auto_mines_laying_2_item",
        "items/skills/auto_mines_laying_3_item"
    }

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent ~= nil ) then

        for skillName in Iter( skillList ) do

            local itemCount = ItemService:GetItemCount( player, skillName )

            if ( itemCount == 0 ) then
                PlayerService:AddItemToInventory( playerId, skillName )
            end
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    auto_mines_laying_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    auto_mines_laying_autoexec(evt)
end)