RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil ) then
        return
    end

    local skillName = "items/skills/wall_breaker_item"

    local itemCount = ItemService:GetItemCount( player, skillName )

    --LogService:Log("skillName " .. skillName .. " itemCount " .. tostring(itemCount))

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end)