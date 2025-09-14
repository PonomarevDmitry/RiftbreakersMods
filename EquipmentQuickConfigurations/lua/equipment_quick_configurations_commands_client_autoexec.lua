LogService:Log("Autoexec Load is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

--if ( not is_client ) then
--    return
--end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

globalEquipmentQuickConfigurationsUtilsEntitiesCache = globalEquipmentQuickConfigurationsUtilsEntitiesCache or {}

mod_quick_equipment_mode_save = 1



ConsoleService:RegisterCommand( "change_quick_equipment_mode_save", function( args )

    LogService:Log("change_quick_equipment_mode_save is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))



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

    LogService:Log("operate_quick_equipment is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

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

    LogService:Log("operate_eq_weapon is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

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

    LogService:Log("change_quick_equipment_mode_announcement is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))



    if ( CampaignService.GetCampaignData == nil ) then
        return
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end

    local configKey = "$EquipmentQuickConfigurationsUtils.mod_quick_equipment_mode_announcements"

    local mod_quick_equipment_mode_announcements = campaignDatabase:GetIntOrDefault(configKey, 1) or 1

    mod_quick_equipment_mode_announcements = 1 - mod_quick_equipment_mode_announcements

    campaignDatabase:SetInt(configKey, mod_quick_equipment_mode_announcements)

    if ( mod_quick_equipment_mode_announcements == 1 ) then

        SoundService:Play( "items/weapons/bullet/small_machinegun_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_announcement_on", 0 )
    else

        SoundService:Play( "items/weapons/energy/blaster_equipped" )
        SoundService:PlayAnnouncement( "voice_over/announcement/equipment_quick_configurations_announcement_off", 0 )
    end
end)
