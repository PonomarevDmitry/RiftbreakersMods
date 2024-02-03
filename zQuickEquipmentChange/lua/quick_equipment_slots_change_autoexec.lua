require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

QuickEquipmentSlotsUtils = require("lua/utils/quick_equipment_slots_utils.lua")

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



ConsoleService:RegisterCommand( "operate_quick_equipment", function( args )

    if not Assert( #args >= 2, "Command operate_eq_usable requires 2 arguments! [configname] " .. tostring(#args) ) then
        return
    end
    
    local slotsName = args[1]
    local configName = args[2]

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    if ( mod_quick_equipment_mode_save == 1 ) then

        QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( slotsName, slotsName, configName )
    else
        local loadResult, slotsHash = QuickEquipmentSlotsUtils:ReadSavedEquipmentInfoAndQuipItems( slotsName, slotsName, configName, true )

        QuickEquipmentSlotsUtils:PlayLoadAnnouncementAndSound(loadResult, slotsName, configName, slotsHash)
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

        local loadResult, slotsHash = QuickEquipmentSlotsUtils:ReadSavedEquipmentInfoAndQuipItems( "left_hand,right_hand", "weapon", configName, true )

        QuickEquipmentSlotsUtils:PlayLoadAnnouncementAndSound(loadResult, "weapon", configName, slotsHash)
    end
end)


RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local itemType = ItemService:GetItemType(entity)

    local isRightType = QuickEquipmentSlotsUtils:IsRightType(itemType)
    if ( not isRightType ) then
        return
    end

    local itemDatabaseKey = QuickEquipmentSlotsUtils:GetOrCreateItemKey( entity )
    if ( itemDatabaseKey == "" or itemDatabaseKey == nil ) then
        return
    end

    QuickEquipmentSlotsUtils.EntitiesCache[itemDatabaseKey] = entity

    LogService:Log("InventoryItemCreatedEvent entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity) .. " itemType " .. tostring(itemType) .. " quickItemKey " .. tostring(itemDatabaseKey))
end)
