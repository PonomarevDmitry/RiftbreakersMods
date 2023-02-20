ConsoleService:RegisterCommand( "activate_slot_request", function( args )

    LogService:Log("Command activate_slot_request " .. tostring(args[1]) )

    if not Assert( #args == 1, "Command requires one argument! [slot_name]" ) then
        return 
    end
    
    LogService:Log("Command activate_slot_request " .. tostring(args[1]) .. " ItemService:UseEquippedItem" )
    
    local player = PlayerService:GetPlayerControlledEnt(0)
    
    ItemService:UseEquippedItem(player ,args[1])
    ItemService:StopUsingEquippedItem(player ,args[1])

    
end)

ConsoleService:ExecuteCommand('bind 9 "activate_slot_request USABLE_9"')
ConsoleService:ExecuteCommand('bind 0 "activate_slot_request USABLE_10"')