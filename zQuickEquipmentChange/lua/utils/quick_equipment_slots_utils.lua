require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

local LOAD_RESULT_FAIL    = 1
local LOAD_RESULT_EMPTY   = 2
local LOAD_RESULT_INVALID = 3
local LOAD_RESULT_SUCCESS = 4

local QuickEquipmentSlotsUtils = {}

function QuickEquipmentSlotsUtils:ShowPopupToSaveConfig( slotNamePrefixArray, slotLocalizationName, configName )

    local entity = EntityService:SpawnEntity( "misc/quick_equipment_slots_save_entity", 0, 0, 0, "" )

    local database = EntityService:GetDatabase( entity )
    if ( database == nil ) then
        return
    end

    database:SetString("slotNamePrefixArray", slotNamePrefixArray)
    database:SetString("slotLocalizationName", slotLocalizationName)
    database:SetString("configName", configName)
end

function QuickEquipmentSlotsUtils:GetSaveEquipmentInfo( slotNamePrefix, configName )

    local player_id = 0
    local slotsHash = {}

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID, slotsHash, ""
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, ""
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, ""
    end

    --LogService:Log( "QuickEquipmentSlotsUtils equipment " .. tostring(equipment) )

    slotNamePrefix = string.lower(slotNamePrefix)

    local configContent = ""

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        if ( string.find( string.lower(slot.name), slotNamePrefix ) == nil ) then
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

                    local slotDesc = QuickEquipmentSlotsUtils:GetSlotDesc( subSlotEntityBlueprintName, subSlotEntityId )

                    slotsHash[slot.name] = slotsHash[slot.name] or {}

                    local slotConfig = slotsHash[slot.name]

                    slotConfig.Name = slot.name
                    slotConfig.Number = slotNumber
                    slotConfig.SubSlotsCount = slot.subslots.count

                    slotConfig.SubSlots = slotConfig.SubSlots or {}

                    slotConfig.SubSlots[subSlotNumber] = slotDesc

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

    if ( configContent ~= "" and configContent ~= nil and string.len( configContent ) > 0 ) then
        return LOAD_RESULT_SUCCESS, slotsHash, configContent
    else
        return LOAD_RESULT_EMPTY, slotsHash, configContent
    end
end

function QuickEquipmentSlotsUtils:GetPlayerSlotsEquipment( slotNamePrefix )

    local player_id = 0

    local slotsArray = {}

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return slotsArray
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return slotsArray
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return slotsArray
    end

    slotNamePrefix = string.lower(slotNamePrefix)

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        if ( string.find( string.lower(slot.name), slotNamePrefix ) == nil ) then
            goto continue
        end

        local slotConfig = {}

        slotConfig.Name = slot.name
        slotConfig.Number = slotNumber
        slotConfig.SubSlotsCount = slot.subslots.count

        Insert( slotsArray, slotConfig )

        ::continue::
    end

    return slotsArray
end

function QuickEquipmentSlotsUtils:SaveSettingKeyName( slotNamePrefix, configName, configContent )

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    LogService:Log("save_equipment key " .. keyName .. " configContent " .. configContent )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID
    end

    campaignDatabase:SetString( keyName, configContent )
end

function QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local keyName = "$QuickEquipmentSlotsUtils." .. slotNamePrefix .. "." .. configName

    return keyName
end

function QuickEquipmentSlotsUtils:LoadEquipment( slotNamePrefix, configName )

    local slotsHash = {}
    local slotsNamesArray = {}

    local player_id = 0

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID, slotsHash, slotsNamesArray
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, slotsNamesArray
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, slotsNamesArray
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, slotsNamesArray
    end

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local configContent = campaignDatabase:GetStringOrDefault( keyName, "" )

    configContent = configContent or ""

    LogService:Log("load_equipment key " .. keyName .. " configContent " .. configContent )

    if ( configContent == "" ) then
        return LOAD_RESULT_EMPTY, slotsHash, slotsNamesArray
    end

    local result = false

    local slots = equipment.slots

    slotNamePrefix = string.lower(slotNamePrefix)

    local configContentArray = Split( configContent, "|" )

    for template in Iter( configContentArray ) do

        --LogService:Log("load_equipment template " .. template )

        local slotValuesArray = Split( template, ":" )

        if ( #slotValuesArray ~= 2 ) then
            --LogService:Log("#slotValuesArray ~= 2 " )
            goto continue
        end

        local slotName = slotValuesArray[1]
        local subSlotsConfig = slotValuesArray[2]

        if ( string.find( string.lower(slotName), slotNamePrefix ) == nil ) then
            --LogService:Log("string.find( string.lower(slotName), slotNamePrefix ) ~= nil slotName " .. slotName ..  " slotNamePrefix " .. slotNamePrefix  )
            goto continue
        end

        local slotExists = false

        local selectedSlot = nil
        local selectedSlotNumber = nil

        for slotNumber=1,slots.count do

            selectedSlot = slots[slotNumber]

            if string.lower(selectedSlot.name) == string.lower(slotName) then
                slotExists = true
                selectedSlotNumber = slotNumber
                break
            end
        end

        if ( not slotExists ) then
            --LogService:Log("not slotExists " )
            goto continue
        end


        -- Split array of coordinates by ";"
        local subSlotsConfigArray = Split( subSlotsConfig, ";" )

        for subSlotString in Iter( subSlotsConfigArray ) do

            local subSlotResult, slotDesc, subSlotNumber, subSlotEntityId = QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, selectedSlot.name, selectedSlot.subslots_count, subSlotString )

            if ( subSlotResult ) then

                QueueEvent( "EquipmentChangeRequest", player, slotName, subSlotNumber-1, subSlotEntityId )

                if ( IndexOf(slotsNamesArray, slotName) == nil ) then
                    Insert( slotsNamesArray, slotName )
                end

                slotsHash[slotName] = slotsHash[slotName] or {}

                local slotConfig = slotsHash[slotName]

                slotConfig.Number = selectedSlotNumber
                slotConfig.SubSlotsCount = selectedSlot.subslots_count

                slotConfig.SubSlots = slotConfig.SubSlots or {}

                slotConfig.SubSlots[subSlotNumber] = slotDesc
            end

            result = result or subSlotResult
        end

        ::continue::
    end

    if ( result ) then
        return LOAD_RESULT_SUCCESS, slotsHash, slotsNamesArray
    else
        return LOAD_RESULT_FAIL, slotsHash, slotsNamesArray
    end
end

function QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, slotName, subslots_count, subSlotString )

    local subSlotStringArray = Split( subSlotString, "," )

    if ( #subSlotStringArray ~= 3 ) then
        --LogService:Log("#subSlotStringArray ~= 3 " )
        return false
    end

    local subSlotNumber = tonumber(subSlotStringArray[1])
    local subSlotEntityId = tonumber(subSlotStringArray[2])
    local subSlotEntityBlueprintName = tostring(subSlotStringArray[3])

    --LogService:Log("EquipItemInSlot slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) .. " subSlotEntityBlueprintName " .. tostring(subSlotEntityBlueprintName) .. " subslots_count " .. tostring(subslots_count) )

    if ( subSlotNumber == nil or subSlotEntityId == nil or subSlotEntityBlueprintName == "" or subSlotEntityBlueprintName == nil ) then
        --LogService:Log("subSlotNumber == nil or subSlotEntityId == nil or subSlotEntityBlueprintName == nil" )
        return false
    end

    if ( subSlotNumber <= 0 or subSlotNumber > subslots_count ) then
        --LogService:Log("subSlotNumber <= 0 or subSlotNumber > subslots_count " )
        return false
    end

    if ( not EntityService:IsAlive( subSlotEntityId ) ) then
        LogService:Log("not EntityService:IsAlive( subSlotEntityId ) " )
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

    local slotDesc = QuickEquipmentSlotsUtils:GetSlotDesc( blueprintName, subSlotEntityId )

    return true, slotDesc, subSlotNumber, subSlotEntityId
end

function QuickEquipmentSlotsUtils:GetSlotDesc( blueprintName, subSlotEntityId )

    local slotDesc = {}

    slotDesc.rarity = 0
    slotDesc.blueprintName = blueprintName
    slotDesc.entityId = subSlotEntityId

    local inventoryItemComponent = EntityService:GetComponent(subSlotEntityId, "InventoryItemComponent")
    if ( inventoryItemComponent ~= nil ) then

        local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )
        
        slotDesc.name = inventoryItemComponentRef.name
        slotDesc.icon = inventoryItemComponentRef.bigger_icon
        slotDesc.rarity = inventoryItemComponentRef.rarity
    end

    local modComponent = EntityService:GetComponent(subSlotEntityId, "EntityModComponent")
    if ( modComponent ~= nil ) then
        slotDesc.rarity = reflection_helper( modComponent ).rarity
    end

    return slotDesc
end

function QuickEquipmentSlotsUtils:PlayLoadAnnouncementAndSound( loadResult, slotName, configName, slotsHash, slotsNamesArray )

    local configNameLocal = "quick_equipment_slots_change/configs/name/" .. configName
    local slotNameLocal = "quick_equipment_slots_change/slots/" .. slotName

    local fullAnnouncement = ""

    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        fullAnnouncement = '<style="header_24">${' .. slotNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/load/load_from} <style="header_24">${' .. configNameLocal .. '} ${voice_over/announcement/quick_equipment_slots_change/load/success/loaded}</style>'
    elseif ( loadResult == LOAD_RESULT_FAIL ) then
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/fail/fail} <style="header_24">${' .. slotNameLocal .. '}</style><style="header_24">${voice_over/announcement/quick_equipment_slots_change/load/load_from} ${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/fail/fail_end}</style>'
    elseif ( loadResult == LOAD_RESULT_EMPTY ) then
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/load/empty} <style="header_24">${' .. slotNameLocal .. '}</style> <style="header_24">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/load/empty_end}</style>'
    else
        fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/invalid/invalid} <style="header_24">${' .. slotNameLocal .. '}</style> <style="header_24">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/invalid/invalid_end}</style>'
    end

    local sound = ""
    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        sound = "items/item_equipped_default"
    else
        sound = "gui/cannot_use_item"
    end

    SoundService:Play( sound )
    SoundService:PlayAnnouncement( fullAnnouncement, 0 )

    if ( loadResult == LOAD_RESULT_SUCCESS ) then

        if ( slotsHash ) then

            local slotsIcons = QuickEquipmentSlotsUtils:GetSlotsIcons(slotsHash, slotsNamesArray)

            if ( slotsIcons ~= "" ) then
                SoundService:PlayAnnouncement( slotsIcons, 0 )
            end
        end
    end
end

function QuickEquipmentSlotsUtils:GetSlotsIcons(slotsHash, slotsNamesArray)
    
    local listBlueprint = {}
    local hashBlueprint = {}

    for slotName in Iter( slotsNamesArray ) do

        local slotConfig = slotsHash[slotName]

        local keys = {}
        for subSlotNumber,_ in pairs(slotConfig.SubSlots) do 
            Insert( keys, subSlotNumber ) 
        end

        table.sort(keys)

        for subSlotNumber in Iter( keys ) do
            
            local slotDesc = slotConfig.SubSlots[subSlotNumber]

            if ( hashBlueprint[slotDesc.blueprintName] == nil ) then

                Insert( listBlueprint, slotDesc.blueprintName )

                hashBlueprint[slotDesc.blueprintName] = {}
                hashBlueprint[slotDesc.blueprintName].count = 0
                hashBlueprint[slotDesc.blueprintName].slotDesc = slotDesc
            end

            hashBlueprint[slotDesc.blueprintName].count = hashBlueprint[slotDesc.blueprintName].count + 1
        end
    end

    local resultText = ""
    local resultIcons = ""

    for blueprintName in Iter( listBlueprint ) do

        local count = hashBlueprint[blueprintName].count
        local slotDesc = hashBlueprint[blueprintName].slotDesc

        local rarityStyle = QuickEquipmentSlotsUtils:GetRaritySmallStyle( slotDesc.rarity )

        local slotStr = '${' .. slotDesc.name .. '}'

        local iconStr = '<style="inventory_stats_icon">' .. '<img="' .. slotDesc.icon .. '">' .. '</style>'
        --local iconStr = '<img="' .. slotDesc.icon .. '">'

        local slotStr = '<style="' .. rarityStyle .. '">${' .. slotDesc.name .. '}</style>'
        --local slotStr = '<img="' .. slotDesc.icon .. '"> ${' .. slotDesc.name .. '}'

        if ( count > 1 ) then
            slotStr = slotStr .. ' x' .. tostring(count)
            iconStr = tostring(count) .. 'x' .. iconStr
        end

        if ( string.len(resultText) > 0 ) then
            resultText = resultText .. ", "
            resultIcons = resultIcons .. ", "
        end

        --resultText = resultText .. '<style="inventory_stats_icon">' .. slotStr .. '</style>'

        resultText = resultText .. '' .. slotStr .. ''
        resultIcons = resultIcons .. '' .. iconStr .. ''
    end

    local result = resultText .. " " .. resultIcons

    LogService:Log("slotsHash " .. debug_serialize_utils:SerializeObject(slotsHash))
    LogService:Log("result " .. result)

    return result
end

function QuickEquipmentSlotsUtils:GetRarityStyle( rarity )

    -- 0 "item_level_0"
    -- 1 "item_level_1"
    -- 2 "item_level_2"
    -- 3 "item_level_3"

    if ( 0 <= rarity and rarity <= 3) then
        return "item_level_" .. tostring(rarity)
    end

    return "item_level_0"
end

function QuickEquipmentSlotsUtils:GetRaritySmallStyle( rarity )

    -- 0 "smallest_item_level_0"
    -- 1 "smallest_item_level_1"
    -- 2 "smallest_item_level_2"
    -- 3 "smallest_item_level_3"

    if ( 0 <= rarity and rarity <= 3) then
        return "smallest_item_level_" .. tostring(rarity)
    end

    return "smallest_item_level_0"
end

function QuickEquipmentSlotsUtils:CombineSlotsNamesArrays( slotsNamesArray1, slotsNamesArray2 )

    for slotName in Iter( slotsNamesArray2 ) do

        if ( IndexOf(slotsNamesArray1, slotName) == nil ) then
            Insert( slotsNamesArray1, slotName )
        end
    end

    return slotsNamesArray1
end

function QuickEquipmentSlotsUtils:CombineSlotsHashs( slotsHash1, slotsHash2 )

    for key,value in pairs(slotsHash2) do
        slotsHash1[key] = value
    end

    return slotsHash1
end

function QuickEquipmentSlotsUtils:CombineResults( loadResult1, loadResult2 )

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