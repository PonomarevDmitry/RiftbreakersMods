local temporary_rift_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillName = "items/skills/temporary_rift_portal"

    local itemCount = ItemService:GetItemCount( player, skillName )

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", temporary_rift_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", temporary_rift_autoexec)