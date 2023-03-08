ConsoleService:RegisterCommand( "activate_slot_request", function( args )

    if not Assert( #args == 1, "Command requires one argument! [slot_name]" ) then
        return 
    end

    if ( PlayerService == nil or ItemService == nil ) then
        return
    end
    
    local player = PlayerService:GetPlayerControlledEnt(0)

    if ( player == nil ) then
        return
    end

    local slotName = args[1]

    local slotItem = ItemService:GetEquippedItem( player, slotName )

    if ( slotItem == nil ) then
        return
    end

    local slotItemType = ItemService:GetItemType( slotItem )
    
    if ( not ItemService:CanActivateItemSlot( player, slotName, slotItemType ) ) then
        return
    end
    
    ItemService:UseEquippedItem( player, slotName )
    ItemService:StopUsingEquippedItem( player, slotName )
    
end)

--JUMP_SKILL
--DODGE_ROLL_SKILL
--TELEPORT_SKILL
ConsoleService:ExecuteCommand('bind key_20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind #20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind 20 "activate_slot_request JUMP_SKILL"')
ConsoleService:ExecuteCommand('bind lcontrol "activate_slot_request DODGE_ROLL_SKILL"')
ConsoleService:ExecuteCommand('bind lalt "activate_slot_request TELEPORT_SKILL"')

ConsoleService:ExecuteCommand('bind 9 "activate_slot_request USABLE_9"')
ConsoleService:ExecuteCommand('bind 0 "activate_slot_request USABLE_10"')