ConsoleService:RegisterCommand( "activate_slot_request", function( args )

    if not Assert( #args == 1, "Command requires one argument! [slot_name]" ) then
        return
    end

    local slotName = args[1]

    LogService:Log("ExecuteCommand activate_slot_request " .. tostring(slotName) )

    if ( PlayerService == nil or ItemService == nil ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " PlayerService == nil or ItemService == nil" )
        return
    end

    local playerId = PlayerService:GetCurrentPlayer()

    if ( playerId == nil or playerId == -1 ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " playerId == nil or playerId == -1" )
        return
    end

    local player = PlayerService:GetPlayerControlledEnt(playerId)

    if ( player == nil or player == INVALID_ID ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " player == nil or player == INVALID_ID" )
        return
    end

    if ( not EntityService:IsAlive( player ) ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " not EntityService:IsAlive( player )" )
        return
    end

    local slotItem = ItemService:GetEquippedItem( player, slotName )

    if ( slotItem == nil ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " slotItem nil" )
        return
    end

    local slotItemType = ItemService:GetItemType( slotItem )

    if ( not ItemService:CanActivateItemSlot( player, slotName, slotItemType ) ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " CanActivateItemSlot false" )
        return
    end

    --LogService:Log("activate_slot_request " .. tostring(slotName) .. " ActivateEquipmentSlotRequest" )
    --QueueEvent("ActivateEquipmentSlotRequest", player, slotName, "" )
    --QueueEvent("DeactivateEquipmentSlotRequest", player, slotName, true )


    LogService:Log("activate_slot_request " .. tostring(slotName) .. " UseEquippedItem" )

    ItemService:UseEquippedItem( player, slotName )
    ItemService:StopUsingEquippedItem( player, slotName )

end)

ConsoleService:ExecuteCommand('bind 9 "activate_slot_request USABLE_9"')

ConsoleService:ExecuteCommand('bind 0 "activate_slot_request USABLE_10"')