RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if	( player == nil ) then
        return
    end

    local skillName = "items/skills/spawn_temporary_portal"

    local itemCount = ItemService:GetItemCount( player, skillName )

    if ( itemCount > 0 ) then
        return
    end

    PlayerService:AddItemToInventory( playerId, skillName )
end)