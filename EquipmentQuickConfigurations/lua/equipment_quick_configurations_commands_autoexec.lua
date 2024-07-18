require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

globalEquipmentQuickConfigurationsUtilsEntitiesCache = globalEquipmentQuickConfigurationsUtilsEntitiesCache or {}

mod_quick_equipment_mode_save = 0
mod_quick_equipment_mode_announcements = 1



ConsoleService:RegisterCommand( "change_quick_equipment_mode_save", function( args )

    mod_quick_equipment_mode_save = mod_quick_equipment_mode_save or 0

    mod_quick_equipment_mode_save = 1 - mod_quick_equipment_mode_save

    if ( mod_quick_equipment_mode_save == 1 ) then

        SoundService:Play( "items/weapons/bullet/small_machinegun_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_mode_save", 0 )
    else

        SoundService:Play( "items/weapons/energy/blaster_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_mode_load", 0 )
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

        EquipmentQuickConfigurationsUtils:ShowPopupToSaveConfig( slotsName, slotsName, configName )
    else
        local loadResult, slotsHash = EquipmentQuickConfigurationsUtils:ReadSavedEquipmentInfoAndQuipItems( slotsName, slotsName, configName, true )

        EquipmentQuickConfigurationsUtils:PlayLoadAnnouncementAndSound(loadResult, slotsName, configName, slotsHash)
    end
end)



ConsoleService:RegisterCommand( "operate_eq_weapon", function( args )

    if not Assert( #args >= 1, "Command operate_eq_weapon requires 1 arguments! [configname] " .. tostring(#args) ) then
        return
    end

    local configName = args[1]

    if ( mod_quick_equipment_mode_save == 1 ) then

        EquipmentQuickConfigurationsUtils:ShowPopupToSaveConfig( "left_hand,right_hand", "weapon", configName )
    else

        local loadResult, slotsHash = EquipmentQuickConfigurationsUtils:ReadSavedEquipmentInfoAndQuipItems( "left_hand,right_hand", "weapon", configName, true )

        EquipmentQuickConfigurationsUtils:PlayLoadAnnouncementAndSound(loadResult, "weapon", configName, slotsHash)
    end
end)



ConsoleService:RegisterCommand( "change_quick_equipment_mode_announcement", function( args )

    mod_quick_equipment_mode_announcements = mod_quick_equipment_mode_announcements or 1

    mod_quick_equipment_mode_announcements = 1 - mod_quick_equipment_mode_announcements

    if ( mod_quick_equipment_mode_announcements == 1 ) then

        SoundService:Play( "items/weapons/bullet/small_machinegun_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_announcement_on", 0 )
    else

        SoundService:Play( "items/weapons/energy/blaster_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_announcement_off", 0 )
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

    local isRightType = EquipmentQuickConfigurationsUtils:IsRightType(itemType)
    if ( not isRightType ) then
        return
    end

    local itemDatabaseKey = EquipmentQuickConfigurationsUtils:GetOrCreateItemKey( entity )
    if ( itemDatabaseKey == "" or itemDatabaseKey == nil ) then
        return
    end

    globalEquipmentQuickConfigurationsUtilsEntitiesCache[itemDatabaseKey] = entity
end)
