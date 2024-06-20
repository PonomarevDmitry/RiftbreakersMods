local turrets_cluster_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/turrets_cluster_1_item",
        "items/skills/turrets_cluster_2_item",
        "items/skills/turrets_cluster_3_item"
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

    turrets_cluster_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    turrets_cluster_autoexec(evt)
end)