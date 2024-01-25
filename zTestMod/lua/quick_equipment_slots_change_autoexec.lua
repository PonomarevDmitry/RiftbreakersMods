local QuickEquipmentSlotsUtils = require("lua/utils/quick_equipment_slots_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

-- save_eq_upgrade standart
-- save_eq_upgrade standart2

-- save_eq_usable standart
-- save_eq_left standart
-- save_eq_right standart

-- load_eq_upgrade standart
-- load_eq_upgrade standart2

-- load_eq_usable standart
-- load_eq_left standart
-- load_eq_right standart

ConsoleService:ExecuteCommand('bind num_1 "load_eq_usable usableConfig1"')

ConsoleService:ExecuteCommand('bind num_2 "load_eq_usable usableConfig2"')

ConsoleService:ExecuteCommand('bind num_3 "load_eq_usable usableConfig3"')

ConsoleService:ExecuteCommand('bind num_7 "save_eq_usable usableConfig1"')

ConsoleService:ExecuteCommand('bind num_8 "save_eq_usable usableConfig2"')

ConsoleService:ExecuteCommand('bind num_9 "save_eq_usable usableConfig3"')

ConsoleService:RegisterCommand( "save_eq_upgrade", function( args )

    if not Assert( #args == 1, "Command save_eq_upgrade requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_upgrade " .. configName )

    QuickEquipmentSlotsUtils:SaveEquipment( "upgrade", configName )
end)

ConsoleService:RegisterCommand( "save_eq_usable", function( args )

    if not Assert( #args == 1, "Command save_eq_usable requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_usable " .. configName )

    QuickEquipmentSlotsUtils:SaveEquipment( "usable", configName )
end)

ConsoleService:RegisterCommand( "save_eq_left", function( args )

    if not Assert( #args == 1, "Command save_eq_left requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_left " .. configName )

    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
end)

ConsoleService:RegisterCommand( "save_eq_right", function( args )

    if not Assert( #args == 1, "Command save_eq_right requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_right " .. configName )

    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
end)

ConsoleService:RegisterCommand( "save_eq_weapon", function( args )

    if not Assert( #args == 1, "Command save_eq_weapon requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_weapon " .. configName )
    
    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
end)

ConsoleService:RegisterCommand( "save_eq_all", function( args )

    if not Assert( #args == 1, "Command save_eq_all requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("save_eq_all " .. configName )
    
    QuickEquipmentSlotsUtils:SaveEquipment( "upgrade", configName )
    QuickEquipmentSlotsUtils:SaveEquipment( "usable", configName )

    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
end)








ConsoleService:RegisterCommand( "load_eq_upgrade", function( args )

    if not Assert( #args == 1, "Command load_eq_upgrade requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_upgrade " .. configName )

    QuickEquipmentSlotsUtils:LoadEquipment( "upgrade", configName )

end)

ConsoleService:RegisterCommand( "load_eq_usable", function( args )

    if not Assert( #args == 1, "Command load_eq_usable requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_usable " .. configName )

    QuickEquipmentSlotsUtils:LoadEquipment( "usable", configName )

end)

ConsoleService:RegisterCommand( "load_eq_left", function( args )

    if not Assert( #args == 1, "Command load_eq_left requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_left " .. configName )

    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )

end)

ConsoleService:RegisterCommand( "load_eq_right", function( args )

    if not Assert( #args == 1, "Command load_eq_right requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_right " .. configName )

    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )

end)

ConsoleService:RegisterCommand( "load_eq_weapon", function( args )

    if not Assert( #args == 1, "Command load_eq_weapon requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_weapon " .. configName )
    
    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )

end)

ConsoleService:RegisterCommand( "load_eq_all", function( args )

    if not Assert( #args == 1, "Command load_eq_all requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_eq_all " .. configName )
    
    QuickEquipmentSlotsUtils:LoadEquipment( "upgrade", configName )
    QuickEquipmentSlotsUtils:LoadEquipment( "usable", configName )

    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )

end)