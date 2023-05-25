ConsoleService:RegisterCommand( "activate_slot_request", function( args )

    if not Assert( #args == 1, "Command requires one argument! [slot_name]" ) then
        return
    end

    local slotName = args[1]

    LogService:Log("ExecuteCommand activate_slot_request " .. tostring(slotName) )

    if ( PlayerService == nil or ItemService == nil ) then
        return
    end

    local player = PlayerService:GetPlayerControlledEnt(0)

    if ( player == nil ) then
        LogService:Log("activate_slot_request " .. tostring(slotName) .. " player nil" )
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

--JUMP_SKILL
ConsoleService:ExecuteCommand('bind key_20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind #20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind 20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind capslock "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind caps "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind KEY_CAPSLOCK "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind KEY_CAPS "activate_slot_request JUMP_SKILL"')

--DODGE_ROLL_SKILL
ConsoleService:ExecuteCommand('bind lcontrol "activate_slot_request DODGE_ROLL_SKILL"')

--TELEPORT_SKILL
ConsoleService:ExecuteCommand('bind lalt "activate_slot_request TELEPORT_SKILL"')

ConsoleService:ExecuteCommand('bind 9 "activate_slot_request USABLE_9"')

ConsoleService:ExecuteCommand('bind 0 "activate_slot_request USABLE_10"')

ConsoleService:ExecuteCommand('bind "-" "activate_slot_request USABLE_11"')

ConsoleService:ExecuteCommand('bind "=" "activate_slot_request USABLE_12"')