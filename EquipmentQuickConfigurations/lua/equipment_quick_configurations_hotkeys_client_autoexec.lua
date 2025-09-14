LogService:Log("is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

if ( not is_client ) then
    return
end

ConsoleService:ExecuteCommand('bind / "operate_quick_equipment dash_skill QuickConfig01"')
ConsoleService:ExecuteCommand('bind * "operate_quick_equipment dash_skill QuickConfig02"')
ConsoleService:ExecuteCommand('bind - "operate_quick_equipment dash_skill QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_7 "operate_quick_equipment upgrade QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_8 "operate_quick_equipment upgrade QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_9 "operate_quick_equipment upgrade QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_4 "operate_eq_weapon QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_5 "operate_eq_weapon QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_6 "operate_eq_weapon QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_1 "operate_quick_equipment usable QuickConfig01"')
ConsoleService:ExecuteCommand('bind num_2 "operate_quick_equipment usable QuickConfig02"')
ConsoleService:ExecuteCommand('bind num_3 "operate_quick_equipment usable QuickConfig03"')

ConsoleService:ExecuteCommand('bind num_0 "change_quick_equipment_mode_save"')

ConsoleService:ExecuteCommand('bind . "change_quick_equipment_mode_announcement"')
