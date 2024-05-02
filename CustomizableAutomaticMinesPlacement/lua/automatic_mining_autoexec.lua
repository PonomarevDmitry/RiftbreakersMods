RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/automatic_mining_1_item",
        "items/skills/automatic_mining_2_item",
        "items/skills/automatic_mining_3_item"
    }

    for skillName in Iter( skillList ) do

        local itemCount = ItemService:GetItemCount( player, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/automatic_mining_1_item",
        "items/skills/automatic_mining_2_item",
        "items/skills/automatic_mining_3_item"
    }

    for skillName in Iter( skillList ) do

        local itemCount = ItemService:GetItemCount( player, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end)