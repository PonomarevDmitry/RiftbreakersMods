local activate_all_bioanomalies_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillName = "items/skills/activate_all_bioanomalies_item"

    local itemCount = ItemService:GetItemCount( player, skillName )

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", activate_all_bioanomalies_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", activate_all_bioanomalies_autoexec)