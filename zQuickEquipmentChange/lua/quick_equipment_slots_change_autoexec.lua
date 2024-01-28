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

mod_quick_equipment_mode_save = 0



ConsoleService:ExecuteCommand('bind num_0 "change_quick_equipment_mode_save"')

ConsoleService:ExecuteCommand('bind num_1 "operate_eq_usable QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_2 "operate_eq_usable QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_3 "operate_eq_usable QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_4 "operate_eq_upgrade QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_5 "operate_eq_upgrade QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_6 "operate_eq_upgrade QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_7 "operate_eq_weapon QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_8 "operate_eq_weapon QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_9 "operate_eq_weapon QuickConfig03"')

ConsoleService:ExecuteCommand('bind / "operate_eq_dash_skill QuickConfig01"')
ConsoleService:ExecuteCommand('bind * "operate_eq_dash_skill QuickConfig02"')
ConsoleService:ExecuteCommand('bind - "operate_eq_dash_skill QuickConfig03"')



ConsoleService:RegisterCommand( "change_quick_equipment_mode_save", function( args )

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    mod_quick_equipment_mode_save = 1 - mod_quick_equipment_mode_save

    if ( mod_quick_equipment_mode_save == 1 ) then

        SoundService:Play( "items/weapons/bullet/small_machinegun_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/quick_equipment_mode_save", 0 )
    else

        SoundService:Play( "items/weapons/energy/blaster_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/quick_equipment_mode_load", 0 )
    end
end)



ConsoleService:RegisterCommand( "operate_eq_usable", function( args )

    if not Assert( #args >= 1, "Command operate_eq_usable requires 1 arguments! [configname] " .. tostring(#args) ) then
        return
    end

    local configName = args[1]

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    if ( mod_quick_equipment_mode_save == 1 ) then

        QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( "usable", "usable", configName )
    else
        local loadResult = QuickEquipmentSlotsUtils:LoadEquipment( "usable", configName )

        local sound, fullAnnouncement = QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound(loadResult, "usable", configName)

        SoundService:Play( sound )
        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end
end)



ConsoleService:RegisterCommand( "operate_eq_upgrade", function( args )

    if not Assert( #args >= 1, "Command operate_eq_upgrade requires 1 arguments! [configname] " .. tostring(#args) ) then
        return
    end

    local configName = args[1]

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    if ( mod_quick_equipment_mode_save == 1 ) then

        QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( "upgrade", "upgrade", configName )
    else
        local loadResult = QuickEquipmentSlotsUtils:LoadEquipment( "upgrade", configName )

        local sound, fullAnnouncement = QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound(loadResult, "upgrade", configName)

        SoundService:Play( sound )
        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end
end)



ConsoleService:RegisterCommand( "operate_eq_weapon", function( args )

    if not Assert( #args >= 1, "Command operate_eq_weapon requires 1 arguments! [configname] " .. tostring(#args) ) then
        return
    end

    local configName = args[1]

    if ( mod_quick_equipment_mode_save == 1 ) then

        QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( "left_hand,right_hand", "weapon", configName )
    else
        local loadResult1 = QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
        local loadResult2 = QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )

        local loadResult = QuickEquipmentSlotsUtils:CombineResults(loadResult1, loadResult2)

        local sound, fullAnnouncement = QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound(loadResult, "weapon", configName)

        SoundService:Play( sound )
        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end
end)



ConsoleService:RegisterCommand( "operate_eq_dash_skill", function( args )

    if not Assert( #args >= 1, "Command operate_eq_dash_skill requires 1 arguments! [configname] " .. tostring(#args) ) then
        return
    end

    local configName = args[1]

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    if ( mod_quick_equipment_mode_save == 1 ) then

        QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( "dash_skill", "dash_skill", configName )
    else
        local loadResult = QuickEquipmentSlotsUtils:LoadEquipment( "dash_skill", configName )

        local sound, fullAnnouncement = QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound(loadResult, "dash_skill", configName)

        SoundService:Play( sound )
        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end
end)
























--ConsoleService:RegisterCommand( "save_eq_upgrade", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_upgrade requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_upgrade " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "upgrade", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_upgrade", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_upgrade requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_upgrade " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "upgrade", configName )
--
--end)
--
--
--
--
--
--
--
--ConsoleService:RegisterCommand( "save_eq_usable", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_usable requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_usable " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "usable", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_usable", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_usable requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_usable " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "usable", configName )
--
--end)
--
--
--
--
--
--
--
--ConsoleService:RegisterCommand( "save_eq_left", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_left requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_left " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_left", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_left requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_left " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
--
--end)
--
--
--
--
--
--
--
--ConsoleService:RegisterCommand( "save_eq_right", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_right requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_right " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_right", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_right requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_right " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )
--
--end)
--
--
--
--
--
--
--
--ConsoleService:RegisterCommand( "save_eq_weapon", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_weapon requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_weapon " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
--    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_weapon", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_weapon requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_weapon " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
--    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )
--
--end)
--
--
--
--
--
--
--
--ConsoleService:RegisterCommand( "save_eq_all", function( args )
--
--    if not Assert( #args == 1, "Command save_eq_all requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("save_eq_all " .. configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "upgrade", configName )
--    QuickEquipmentSlotsUtils:SaveEquipment( "usable", configName )
--
--    QuickEquipmentSlotsUtils:SaveEquipment( "left_hand", configName )
--    QuickEquipmentSlotsUtils:SaveEquipment( "right_hand", configName )
--end)
--
--ConsoleService:RegisterCommand( "load_eq_all", function( args )
--
--    if not Assert( #args == 1, "Command load_eq_all requires one arguments! [configname] " .. tostring(#args) ) then
--        return
--    end
--
--    local configName = args[1]
--
--    LogService:Log("load_eq_all " .. configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "upgrade", configName )
--    QuickEquipmentSlotsUtils:LoadEquipment( "usable", configName )
--
--    QuickEquipmentSlotsUtils:LoadEquipment( "left_hand", configName )
--    QuickEquipmentSlotsUtils:LoadEquipment( "right_hand", configName )
--
--end)