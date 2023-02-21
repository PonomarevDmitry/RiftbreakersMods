ConsoleService:RegisterCommand( "activate_slot_request", function( args )

    if not Assert( #args == 1, "Command requires one argument! [slot_name]" ) then
        return 
    end
    
    local player = PlayerService:GetPlayerControlledEnt(0)
    
    ItemService:UseEquippedItem(player ,args[1])
    ItemService:StopUsingEquippedItem(player ,args[1])

    
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