require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local QuickEquipmentSlotsUtils = {}

function QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( slotNamePrefixArray, slotName, configName )

    local entity = EntityService:SpawnEntity( "misc/quick_equipment_slots_save_entity", 0, 0, 0, "" )

    local database = EntityService:GetDatabase( entity )
    if ( database == nil ) then
        return
    end

    database:SetString("slotNamePrefixArray", slotNamePrefixArray)
    database:SetString("slotName", slotName)
    database:SetString("configName", configName)
end

function QuickEquipmentSlotsUtils:SaveEquipment( slotNamePrefix, configName )

    local player_id = 0

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID
    end

    --LogService:Log( "QuickEquipmentSlotsUtils equipment " .. tostring(equipment) )

    slotNamePrefix = string.lower(slotNamePrefix)

    local configContent = ""

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        local slotName = string.lower(slot.name)

        if ( string.find( slotName, slotNamePrefix ) == nil ) then
            goto continue
        end

        local subSlotsConfig = ""

        for subSlotNumber=1,slot.subslots.count do

            local entities = slot.subslots[subSlotNumber]

            local subSlotEntityId = entities[1]

            if (subSlotEntityId) then

                if subSlotEntityId.id then
                    subSlotEntityId = subSlotEntityId.id
                end

                local subSlotEntityBlueprintName = EntityService:GetBlueprintName( subSlotEntityId ) or ""

                if ( subSlotEntityBlueprintName ~= "" ) then

                    if ( string.len( subSlotsConfig ) > 0 ) then
                        subSlotsConfig = subSlotsConfig .. ";"
                    end

                    subSlotsConfig = subSlotsConfig .. tostring(subSlotNumber) .. "," .. tostring(subSlotEntityId) .. "," .. tostring(subSlotEntityBlueprintName)
                end
            end
        end

        if ( string.len( subSlotsConfig ) == 0 ) then
            goto continue
        end

        if ( string.len( configContent ) > 0 ) then
            configContent = configContent .. "|"
        end

        configContent = configContent .. slot.name .. ":" .. subSlotsConfig

        ::continue::
    end

    if ( configContent == "" ) then
        return LOAD_RESULT_EMPTY
    end

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    --LogService:Log("save_equipment key " .. keyName .. " configContent " .. configContent )

    campaignDatabase:SetString( keyName, configContent )

    return LOAD_RESULT_SUCCESS
end

function QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local keyName = "$QuickEquipmentSlotsUtils." .. slotNamePrefix .. "." .. configName

    return keyName
end

local LOAD_RESULT_FAIL    = 1
local LOAD_RESULT_EMPTY   = 2
local LOAD_RESULT_INVALID = 3
local LOAD_RESULT_SUCCESS = 4

function QuickEquipmentSlotsUtils:LoadEquipment( slotNamePrefix, configName )

    local player_id = 0

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID
    end

    local slots = equipment.slots

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local configContent = campaignDatabase:GetStringOrDefault( keyName, "" )

    configContent = configContent or ""

    LogService:Log("load_equipment key " .. keyName .. " configContent " .. configContent )

    if ( configContent == "" ) then
        return LOAD_RESULT_EMPTY
    end

    local result = false

    local configContentArray = Split( configContent, "|" )

    for template in Iter( configContentArray ) do

        local slotValuesArray = Split( template, ":" )

        if ( #slotValuesArray ~= 2 ) then
            goto continue
        end

        local slotName = slotValuesArray[1]

        local subSlotsConfig = slotValuesArray[2]

        if ( string.find( slotName, slotNamePrefix ) ~= nil ) then
            goto continue
        end

        local slotExists = false

        local selectedSlot = nil

        for slotNumber=1,slots.count do

            selectedSlot = slots[slotNumber]

            if selectedSlot.name == slotName then
                slotExists = true
                break
            end
        end

        if ( not slotExists ) then
            goto continue
        end

        -- Split array of coordinates by ";"
        local subSlotsConfigArray = Split( subSlotsConfig, ";" )

        for subSlotString in Iter( subSlotsConfigArray ) do

            local subSlotResult = QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, player_id, equipment, slotName, selectedSlot.subslots_count, subSlotString )

            result = result or subSlotResult
        end

        ::continue::
    end

    if ( result ) then
        return LOAD_RESULT_SUCCESS
    else
        return LOAD_RESULT_FAIL
    end
end

function QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, player_id, equipment, slotName, subslots_count, subSlotString )

    local subSlotStringArray = Split( subSlotString, "," )

    if ( #subSlotStringArray ~= 3 ) then
        return false
    end

    local subSlotNumber = tonumber(subSlotStringArray[1])
    local subSlotEntityId = tonumber(subSlotStringArray[2])
    local subSlotEntityBlueprintName = tostring(subSlotStringArray[3])

    if ( subSlotNumber == nil or subSlotEntityId == nil or subSlotEntityBlueprintName == "" or subSlotEntityBlueprintName == nil ) then
        return false
    end

    if ( subSlotNumber <= 0 or subSlotNumber > subslots_count ) then
        LogService:Log("subSlotNumber <= 0 or subSlotNumber > subslots_count " )
        return false
    end

    if ( not EntityService:IsAlive( subSlotEntityId ) ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( subSlotEntityId ) or ""

    LogService:Log("#blueprintName subSlotEntityId " .. tostring(subSlotEntityId) .. " blueprintName " .. tostring(blueprintName) )

    if ( blueprintName == "") then
        LogService:Log("#blueprintName == nil " )
        return false
    end

    if ( blueprintName ~= subSlotEntityBlueprintName) then
        LogService:Log("#blueprintName ~= subSlotEntityBlueprintName " )
        return false
    end



    if ( subslots_count > 1 ) then

        local equipedItemInSlot = self:GetEquipedItemInSlot(equipment, slotName, subSlotNumber)

        if ( equipedItemInSlot ~= nil ) then

            LogService:Log("UnequipItemRequest player " .. tostring(player) .. " playerEntityName " .. tostring(EntityService:GetBlueprintName( player )) .. " slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " equipedItemInSlot " .. tostring(equipedItemInSlot) .. " equipedItemInSlotBlueprintName " .. tostring(EntityService:GetBlueprintName( equipedItemInSlot )) .. " subslots_count " .. tostring(subslots_count) )
            QueueEvent("UnequipItemRequest", player, equipedItemInSlot, slotName )
        end

        LogService:Log("TryEquipItemInSlot player " .. tostring(player) .. " playerEntityName " .. tostring(EntityService:GetBlueprintName( player )) .. " slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) .. " subSlotEntityBlueprintName " .. tostring(subSlotEntityBlueprintName) .. " subslots_count " .. tostring(subslots_count) )

        ItemService:TryEquipItemInSlot( player, subSlotEntityId, slotName, subSlotNumber - 1)

        return true
    else
        LogService:Log("EquipItemInSlot slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) .. " subSlotEntityBlueprintName " .. tostring(subSlotEntityBlueprintName) .. " subslots_count " .. tostring(subslots_count) )

        PlayerService:EquipItemInSlot( player_id, subSlotEntityId, slotName )
        return true
    end

    return false
end

function QuickEquipmentSlotsUtils:GetEquipedItemInSlot( equipment, slotName, subSlotNumber )

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        if ( slot.name == slotName ) then

            local entities = slot.subslots[subSlotNumber]
            if ( entities == nil ) then
                return nil
            end

            local subSlotEntityId = entities[1]
            if (subSlotEntityId == nil) then
                return nil
            end

            if subSlotEntityId.id then
                subSlotEntityId = subSlotEntityId.id
            end

            return subSlotEntityId
        end
    end

    return nil
end

function QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound( loadResult, slotName, configName )

    local configNameLocal = "quick_equipment_slots_change/configs/name/" .. configName
    local slotNameLocal = "quick_equipment_slots_change/slots/" .. slotName

    local fullAnnouncement = ""

    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        fullAnnouncement = '<style="header_35">${' .. slotNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/load/load_from} <style="header_35">${' .. configNameLocal .. '} ${voice_over/announcement/quick_equipment_slots_change/load/success/loaded}</style>'
    elseif ( loadResult == LOAD_RESULT_FAIL ) then
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/fail/fail} <style="header_35">${' .. slotNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/load/load_from} ${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/fail/fail_end}</style>'
    elseif ( loadResult == LOAD_RESULT_EMPTY ) then
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/load/empty} <style="header_35">${' .. slotNameLocal .. '} ${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/load/empty_end}</style>'
    else
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/invalid/invalid} <style="header_35">${' .. slotNameLocal .. '} ${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/invalid/invalid_end}</style>'
    end

    local sound = ""
    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        sound = "items/item_equipped_default"
    else
        sound = "gui/cannot_use_item"
    end

    return sound, fullAnnouncement
end

function QuickEquipmentSlotsUtils:CombineResults(loadResult1, loadResult2 )

    if ( loadResult1 == LOAD_RESULT_SUCCESS or loadResult2 == LOAD_RESULT_SUCCESS ) then
        return LOAD_RESULT_SUCCESS
    end

    if ( loadResult1 == LOAD_RESULT_EMPTY and loadResult2 == LOAD_RESULT_EMPTY ) then
        return LOAD_RESULT_EMPTY
    end

    if ( loadResult1 == LOAD_RESULT_EMPTY ) then
        return loadResult2
    end

    if ( loadResult2 == LOAD_RESULT_EMPTY ) then
        return loadResult1
    end

    if ( loadResult1 == LOAD_RESULT_FAIL or loadResult2 == LOAD_RESULT_FAIL ) then
        return LOAD_RESULT_FAIL
    end

    if ( loadResult1 == LOAD_RESULT_INVALID and loadResult2 == LOAD_RESULT_INVALID ) then
        return LOAD_RESULT_INVALID
    end

    return LOAD_RESULT_FAIL
end

return QuickEquipmentSlotsUtils;