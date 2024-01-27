require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local QuickEquipmentSlotsUtils = {}

function QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( slotNamePrefix, configName, announcement, confirm )

    local entity = EntityService:SpawnEntity( "misc/quick_equipment_slots_save_entity", 0, 0, 0, "" )

    local database = EntityService:GetDatabase( entity )
    if ( database == nil ) then
        return
    end

    database:SetString("slotNamePrefix", slotNamePrefix)
    database:SetString("configName", configName)
    database:SetString("announcement", announcement)
    database:SetString("confirm", confirm)
end

function QuickEquipmentSlotsUtils:SaveEquipment( slotNamePrefix, configName )

    local player = PlayerService:GetPlayerControlledEnt(0)
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
    
    local player = PlayerService:GetPlayerControlledEnt(0)
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

    --LogService:Log("load_equipment key " .. keyName .. " configContent " .. configContent )

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

            local subSlotResult = QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, slotName, selectedSlot.subslots_count, subSlotString )

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

function QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, slotName, subslots_count, subSlotString )

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

    if ( subslots_count < subSlotNumber or subSlotNumber <= 0 ) then
        return false
    end

    if ( not EntityService:IsAlive( subSlotEntityId ) ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( subSlotEntityId ) or ""

    --LogService:Log("#blueprintName subSlotEntityId " .. tostring(subSlotEntityId) .. " blueprintName " .. tostring(blueprintName) )

    if ( blueprintName == "") then
        --LogService:Log("#blueprintName == nil " )
        return false
    end

    if ( blueprintName ~= subSlotEntityBlueprintName) then
        --LogService:Log("#blueprintName ~= subSlotEntityBlueprintName " )
        return false
    end

    --LogService:Log("EquipItemInSlot slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) )

    PlayerService:EquipItemInSlot( 0, subSlotEntityId, slotName )

    return true
end

function QuickEquipmentSlotsUtils:GetLoadAnnouncementAndSound( loadResult, announcement )

    local fullAnnouncement = "voice_over/announcement/load/"

    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        fullAnnouncement = fullAnnouncement .. "success/"
    elseif ( loadResult == LOAD_RESULT_FAIL ) then
        fullAnnouncement = fullAnnouncement .. "fail/"
    elseif ( loadResult == LOAD_RESULT_EMPTY ) then
        fullAnnouncement = fullAnnouncement .. "empty/"
    else
        fullAnnouncement = fullAnnouncement .. "invalid/"
    end

    fullAnnouncement = fullAnnouncement .. announcement
    
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