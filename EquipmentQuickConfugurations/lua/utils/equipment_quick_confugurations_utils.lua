require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
local EquipmentQuickConfugurationsSerializeUtils = require("lua/utils/equipment_quick_confugurations_serialize_utils.lua")
--local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

local LOAD_RESULT_FAIL    = 1
local LOAD_RESULT_EMPTY   = 2
local LOAD_RESULT_INVALID = 3
local LOAD_RESULT_SUCCESS = 4

local EquipmentQuickConfugurationsUtils = {}

function EquipmentQuickConfugurationsUtils:ShowPopupToSaveConfig( slotNamePrefixArray, slotLocalizationName, configName )

    local entity = EntityService:SpawnEntity( "misc/equipment_quick_confugurations_save_entity", 0, 0, 0, "" )

    local database = EntityService:GetDatabase( entity )
    if ( database == nil ) then
        return
    end

    database:SetString("slotNamePrefixArray", slotNamePrefixArray)
    database:SetString("slotLocalizationName", slotLocalizationName)
    database:SetString("configName", configName)
end

function EquipmentQuickConfugurationsUtils:GetSaveEquipmentInfo( slotNamePrefixArray, configName )

    local player_id = 0
    local slotsHash = {}
    local configContent = {}

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID, slotsHash, configContent
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, configContent
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash, configContent
    end

    --LogService:Log( "EquipmentQuickConfugurationsUtils equipment " .. tostring(equipment) )

    slotNamePrefixArray = string.lower(slotNamePrefixArray)

    local slotNamesArray = Split( slotNamePrefixArray, "," )

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        if ( not EquipmentQuickConfugurationsUtils:IsSlotFits(string.lower(slot.name), slotNamesArray) ) then
            goto continue
        end

        local slotConfig = nil

        for subSlotNumber=1,slot.subslots.count do

            local entities = slot.subslots[subSlotNumber]

            local subSlotEntityId = entities[1]

            if (subSlotEntityId) then

                if subSlotEntityId.id then
                    subSlotEntityId = subSlotEntityId.id
                end

                local subSlotEntityBlueprintName = EntityService:GetBlueprintName( subSlotEntityId ) or ""

                if ( subSlotEntityBlueprintName ~= "" ) then

                    local itemKey = EquipmentQuickConfugurationsUtils:GetOrCreateItemKey(subSlotEntityId)

                    if ( itemKey ) then

                        local slotDesc = EquipmentQuickConfugurationsUtils:GetSlotDesc( subSlotEntityBlueprintName, subSlotEntityId )

                        local slotHashConfig = slotsHash[slot.name]

                        if ( slotHashConfig == nil ) then
                            slotHashConfig = {}

                            slotHashConfig.Name = slot.name
                            slotHashConfig.Number = slotNumber
                            slotHashConfig.SubSlotsCount = slot.subslots.count

                            slotHashConfig.SubSlots = {}

                            slotsHash[slot.name] = slotHashConfig
                        end

                        slotHashConfig.SubSlots[subSlotNumber] = slotDesc

                        if ( slotConfig == nil ) then

                            slotConfig = {}

                            slotConfig.Name = slot.name
                            slotConfig.Number = slotNumber
                            slotConfig.SubSlotsCount = slot.subslots.count
                            slotConfig.SubSlots = {}
                        end

                        local subSlotConfig = {}

                        EquipmentQuickConfugurationsUtils:UpdateSubSlotConfig(subSlotConfig, subSlotEntityId, subSlotEntityBlueprintName, itemKey)

                        slotConfig.SubSlots[subSlotNumber] = subSlotConfig
                    end
                end
            end
        end

        if ( slotConfig == nil ) then
            goto continue
        end

        Insert(configContent, slotConfig)

        ::continue::
    end

    --LogService:Log("GetSaveEquipmentInfo slotsHash " .. debug_serialize_utils:SerializeObject(slotsHash))
    --LogService:Log("GetSaveEquipmentInfo configContent " .. debug_serialize_utils:SerializeObject(configContent))

    if ( #configContent > 0 ) then
        return LOAD_RESULT_SUCCESS, slotsHash, configContent
    else
        return LOAD_RESULT_EMPTY, slotsHash, configContent
    end
end

function EquipmentQuickConfugurationsUtils:IsSlotFits( slotName, slotNamesArray )

    for slotNamePrefix in Iter( slotNamesArray ) do

        if ( string.find( slotName, slotNamePrefix ) ~= nil ) then
            return true
        end
    end

    return false
end

function EquipmentQuickConfugurationsUtils:UpdateSubSlotConfig(subSlotConfig, subSlotEntityId, subSlotEntityBlueprintName, itemKey)

    subSlotConfig.quickItemKey = itemKey
    subSlotConfig.blueprintName = subSlotEntityBlueprintName
    subSlotConfig.entityId = subSlotEntityId
    subSlotConfig.itemName = ItemService:GetItemName(subSlotEntityId)
    subSlotConfig.itemType = ItemService:GetItemType(subSlotEntityId)
    subSlotConfig.itemSubType = ItemService:GetItemSubType(subSlotEntityId)
    subSlotConfig.itemRarity = EquipmentQuickConfugurationsUtils:GetItemRarity(subSlotEntityId)
    subSlotConfig.itemUnique = false
    subSlotConfig.replaceLowerQuality = false

    local costComponent = EntityService:GetComponent( subSlotEntityId, "CostComponent" )
    if ( costComponent ~= nil ) then
        subSlotConfig.itemUnique = reflection_helper( costComponent ).is_unique
    end

    local inventoryItemComponent = EntityService:GetComponent( subSlotEntityId, "InventoryItemComponent" )
    if ( inventoryItemComponent ~= nil ) then
        subSlotConfig.replaceLowerQuality = reflection_helper( inventoryItemComponent ).replace_lower_quality
    end
end

function EquipmentQuickConfugurationsUtils:ReadSavedEquipmentInfoAndQuipItems( slotNamePrefixArray, slotLocalizationName, configName, equipItems )

    equipItems = equipItems or false

    local slotsHash = {}

    local player_id = 0

    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if player == INVALID_ID then
        return LOAD_RESULT_INVALID, slotsHash
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID, slotsHash
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash
    end

    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return LOAD_RESULT_INVALID, slotsHash
    end

    local keyName = EquipmentQuickConfugurationsUtils:GetSettingKeyName( slotLocalizationName, configName )

    local configContentString = campaignDatabase:GetStringOrDefault( keyName, "" )

    configContentString = configContentString or ""

    --LogService:Log("GetLoadEquipmentInfo equipItems " .. tostring(equipItems) .. " configContentString " .. configContentString)

    if ( configContentString == "" ) then
        return LOAD_RESULT_EMPTY, slotsHash
    end

    local configContent = EquipmentQuickConfugurationsSerializeUtils:DeserializeObject(configContentString)
    if ( configContent == nil ) then
        return LOAD_RESULT_FAIL, slotsHash
    end

    --LogService:Log("GetLoadEquipmentInfo equipItems " .. tostring(equipItems) .. " configContent " .. debug_serialize_utils:SerializeObject(configContent))

    slotNamePrefixArray = string.lower(slotNamePrefixArray)

    local slotNamesArray = Split( slotNamePrefixArray, "," )

    local result = false

    local slots = equipment.slots

    local needConfigUpdate = false

    for slotTemplate in Iter( configContent ) do

        local slotName = slotTemplate.Name

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
            goto continue
        end

        if ( not EquipmentQuickConfugurationsUtils:IsSlotFits(string.lower(selectedSlot.name), slotNamesArray) ) then
            goto continue
        end

        for subSlotNumber, subSlotConfig in pairs( slotTemplate.SubSlots ) do

            if ( 1 <= subSlotNumber and subSlotNumber <= selectedSlot.subslots_count ) then

                local subSlotResult, slotDesc, subSlotEntityId, itemUpdated = EquipmentQuickConfugurationsUtils:LoadItemToSlot( player, subSlotConfig )

                if ( subSlotResult ) then

                    needConfigUpdate = needConfigUpdate or itemUpdated

                    if ( equipItems ) then
                        QueueEvent( "EquipmentChangeRequest", player, slotName, subSlotNumber-1, subSlotEntityId )
                    end

                    slotsHash[slotName] = slotsHash[slotName] or {}

                    local slotConfig = slotsHash[slotName]

                    slotConfig.Number = selectedSlotNumber
                    slotConfig.SubSlotsCount = selectedSlot.subslots_count

                    slotConfig.SubSlots = slotConfig.SubSlots or {}

                    slotConfig.SubSlots[subSlotNumber] = slotDesc

                    result = true
                end
            end
        end

        ::continue::
    end

    if ( needConfigUpdate ) then
        EquipmentQuickConfugurationsUtils:SaveSettingKeyName( slotLocalizationName, configName, configContent )
    end

    if ( result ) then
        return LOAD_RESULT_SUCCESS, slotsHash
    else
        return LOAD_RESULT_FAIL, slotsHash
    end
end

function EquipmentQuickConfugurationsUtils:LoadItemToSlot( player, subSlotConfig )

    local subSlotEntityId, itemUpdated = EquipmentQuickConfugurationsUtils:FindItemByKey( player, subSlotConfig )

    if ( subSlotEntityId == nil or subSlotEntityId == INVALID_ID ) then
        return false
    end

    if ( not EntityService:IsAlive( subSlotEntityId ) ) then
        return false
    end

    local inventoryItemComponent = EntityService:GetComponent(subSlotEntityId, "InventoryItemComponent")
    if ( inventoryItemComponent == nil ) then
        return false
    end

    local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )
    if ( inventoryItemComponentRef.owner == nil or inventoryItemComponentRef.owner.id == nil or inventoryItemComponentRef.owner.id == INVALID_ID ) then
        return false
    end

    if ( inventoryItemComponentRef.owner.id ~= player ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( subSlotEntityId ) or ""

    local slotDesc = EquipmentQuickConfugurationsUtils:GetSlotDesc( blueprintName, subSlotEntityId )

    return true, slotDesc, subSlotEntityId, itemUpdated
end

function EquipmentQuickConfugurationsUtils:FindItemByKey( player, subSlotConfig )

    local itemKeyConfigName = "$EquipmentQuickConfugurationsUtils_KeyId"

    local itemKey = subSlotConfig.quickItemKey

    if ( globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemKey] ~= nil ) then

        local entityId = globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemKey]

        if ( EntityService:IsAlive( entityId ) ) then
            return entityId, false
        else
            globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemKey] = nil
        end
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return INVALID_ID, false
    end

    local inventoryComponentRef = reflection_helper( inventoryComponent )

    while ( inventoryComponentRef.reference_entity ~= nil and inventoryComponentRef.reference_entity.id ~= INVALID_ID ) do

        inventoryComponent = EntityService:GetComponent(inventoryComponentRef.reference_entity.id, "InventoryComponent")

        if ( inventoryComponent == nil ) then
            inventoryComponentRef = nil
            break
        end

        inventoryComponentRef = reflection_helper( inventoryComponent )
    end

    if ( inventoryComponentRef == nil or inventoryComponentRef.inventory == nil or inventoryComponentRef.inventory.items == nil ) then
        return INVALID_ID, false
    end

    local itemsByName = {}

    local inventoryItems = inventoryComponentRef.inventory.items

    for itemNumber=1,inventoryItems.count do

        local itemEntity = inventoryItems[itemNumber]

        if ( itemEntity == nil or itemEntity.id == nil) then
            goto continue
        end

        if ( not EntityService:IsAlive( itemEntity.id )) then
            goto continue
        end

        local itemType = ItemService:GetItemType(itemEntity.id)

        local isRightType = EquipmentQuickConfugurationsUtils:IsRightType(itemType)

        if ( not isRightType ) then
            goto continue
        end

        local database = EntityService:GetDatabase( itemEntity.id )
        if ( database ~= nil ) then

            if ( database:HasString(itemKeyConfigName) ) then

                local itemDatabaseKey = database:GetString(itemKeyConfigName) or ""
                if ( itemDatabaseKey ~= "" and itemDatabaseKey ~= nil ) then

                    globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemDatabaseKey] = itemEntity.id

                    if ( itemDatabaseKey == itemKey ) then
                        return itemEntity.id, false
                    end
                end
            end
        end

        if ( subSlotConfig.replaceLowerQuality ) then
            
            local itemName = ItemService:GetItemName(itemEntity.id)
            if ( itemName == subSlotConfig.itemName ) then
                Insert( itemsByName, itemEntity.id )
            end
        end

        ::continue::
    end

    if ( subSlotConfig.replaceLowerQuality and #itemsByName > 0 ) then

        local maxEntityId = nil
        local maxRarity = subSlotConfig.itemRarity
            
        for entityId in Iter( itemsByName ) do

            local itemRarity = EquipmentQuickConfugurationsUtils:GetItemRarity(entityId)

            if ( maxEntityId == nil or itemRarity >= maxRarity ) then

                maxEntityId = entityId
                maxRarity = itemRarity
            end
        end

        if ( maxEntityId ~= nil ) then

            local itemDatabaseKey = EquipmentQuickConfugurationsUtils:GetOrCreateItemKey( maxEntityId )
            if ( itemDatabaseKey ~= "" or itemDatabaseKey ~= nil ) then
                globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemDatabaseKey] = maxEntityId

                EquipmentQuickConfugurationsUtils:UpdateSubSlotConfig(subSlotConfig, maxEntityId, EntityService:GetBlueprintName( maxEntityId ), itemDatabaseKey)

                return maxEntityId, true
            end
        end
    end

    return INVALID_ID, false
end

function EquipmentQuickConfugurationsUtils:GetOrCreateItemKey( subSlotEntityId )

    local database = EntityService:GetDatabase( subSlotEntityId )
    if ( database == nil ) then
        return nil
    end

    local itemKeyConfigName = "$EquipmentQuickConfugurationsUtils_KeyId"

    local itemKey = ""

    if ( database:HasString(itemKeyConfigName) ) then

        itemKey = database:GetString(itemKeyConfigName)
    else

        itemKey = EquipmentQuickConfugurationsUtils:GenerateGuid()

        database:SetString(itemKeyConfigName, itemKey)
    end

    globalEquipmentQuickConfugurationsUtilsEntitiesCache[itemKey] = subSlotEntityId

    return itemKey
end

function EquipmentQuickConfugurationsUtils:GenerateGuid()
    local template ='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[x]', function (c)
        local v = math.random(0, 0xf)
        return string.format('%x', v)
    end)
end

function EquipmentQuickConfugurationsUtils:GetPlayerSlotsEquipmentInfo()

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

    local slots = equipment.slots

    for slotNumber=1,slots.count do

        local slot = slots[slotNumber]

        local slotConfig = {}

        slotConfig.Name = slot.name
        slotConfig.Number = slotNumber
        slotConfig.SubSlotsCount = slot.subslots.count

        Insert( slotsArray, slotConfig )

        ::continue::
    end

    return slotsArray
end

function EquipmentQuickConfugurationsUtils:SaveSettingKeyName( slotLocalizationName, configName, configContent )

    local keyName = EquipmentQuickConfugurationsUtils:GetSettingKeyName( slotLocalizationName, configName )

    local configContentString = EquipmentQuickConfugurationsSerializeUtils:SerializeObject(configContent)

    --LogService:Log("SaveSettingKeyName key " .. keyName .. " configContent " .. debug_serialize_utils:SerializeObject(configContent) )
    --LogService:Log("SaveSettingKeyName key " .. keyName .. " configContentString " .. configContentString )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return LOAD_RESULT_INVALID
    end

    campaignDatabase:SetString( keyName, configContentString )
end

function EquipmentQuickConfugurationsUtils:GetSettingKeyName( slotLocalizationName, configName )

    local keyName = "$EquipmentQuickConfugurationsUtils." .. slotLocalizationName .. "." .. configName

    return keyName
end

function EquipmentQuickConfugurationsUtils:GetSlotDesc( blueprintName, subSlotEntityId )

    local slotDesc = {}

    slotDesc.rarity = EquipmentQuickConfugurationsUtils:GetItemRarity( subSlotEntityId )
    slotDesc.blueprintName = blueprintName
    slotDesc.entityId = subSlotEntityId

    local inventoryItemComponent = EntityService:GetComponent(subSlotEntityId, "InventoryItemComponent")
    if ( inventoryItemComponent ~= nil ) then

        local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )

        slotDesc.name = inventoryItemComponentRef.name
        slotDesc.icon = inventoryItemComponentRef.bigger_icon
    end

    return slotDesc
end

function EquipmentQuickConfugurationsUtils:GetItemRarity( subSlotEntityId )

    local entityModComponent = EntityService:GetComponent(subSlotEntityId, "EntityModComponent")
    if ( entityModComponent ~= nil ) then
        return reflection_helper( entityModComponent ).rarity
    end

    local inventoryItemComponent = EntityService:GetComponent(subSlotEntityId, "InventoryItemComponent")
    if ( inventoryItemComponent ~= nil ) then
        return reflection_helper( inventoryItemComponent ).rarity
    end

    return 0
end

function EquipmentQuickConfugurationsUtils:PlayLoadAnnouncementAndSound( loadResult, slotName, configName, slotsHash )

    local configNameLocal = "${equipment_quick_confugurations/configs/name/" .. configName .. '}'
    local slotLocalizationNameFull = "${equipment_quick_confugurations/slots/" .. slotName .. '}'

    local localizationUnited = slotLocalizationNameFull .. ' - ' .. configNameLocal

    local fullAnnouncement = ""

    if ( loadResult == LOAD_RESULT_SUCCESS ) then
        fullAnnouncement = '<style="header_24">${voice_over/announcement/equipment_quick_confugurations/load/success/loaded} ' .. localizationUnited .. '${voice_over/announcement/equipment_quick_confugurations/load/success/loaded_end}</style>'
    elseif ( loadResult == LOAD_RESULT_FAIL ) then
        fullAnnouncement = '${voice_over/announcement/equipment_quick_confugurations/fail/fail} <style="header_24">' .. localizationUnited .. '${voice_over/announcement/equipment_quick_confugurations/fail/fail_end}</style>'
    elseif ( loadResult == LOAD_RESULT_EMPTY ) then
        fullAnnouncement = '${voice_over/announcement/equipment_quick_confugurations/load/empty} <style="header_24">' .. localizationUnited .. '${voice_over/announcement/equipment_quick_confugurations/load/empty_end}</style>'
    else
        fullAnnouncement = '${voice_over/announcement/equipment_quick_confugurations/invalid/invalid} <style="header_24">' .. localizationUnited .. '${voice_over/announcement/equipment_quick_confugurations/invalid/invalid_end}</style>'
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

            local slotsIcons = EquipmentQuickConfugurationsUtils:GetSlotsIcons(slotsHash)

            if ( slotsIcons ~= "" ) then
                SoundService:PlayAnnouncement( slotsIcons, 0 )
            end
        end
    end
end

function EquipmentQuickConfugurationsUtils:GetSlotsIcons(slotsHash)

    local playerSlotsArrayEquipment = EquipmentQuickConfugurationsUtils:GetPlayerSlotsEquipmentInfo()

    local listBlueprint = {}
    local hashBlueprint = {}

    for slotConfig in Iter( playerSlotsArrayEquipment ) do

        local slotConfigToLoad = slotsHash[slotConfig.Name]
        if ( slotConfigToLoad ~= nil ) then

            for subSlotNumber=1,slotConfig.SubSlotsCount do

                local slotDesc = slotConfigToLoad.SubSlots[subSlotNumber]
                if ( slotDesc ~= nil ) then

                    if ( hashBlueprint[slotDesc.blueprintName] == nil ) then

                        Insert( listBlueprint, slotDesc.blueprintName )

                        hashBlueprint[slotDesc.blueprintName] = {}
                        hashBlueprint[slotDesc.blueprintName].count = 0
                        hashBlueprint[slotDesc.blueprintName].slotDesc = slotDesc
                    end

                    hashBlueprint[slotDesc.blueprintName].count = hashBlueprint[slotDesc.blueprintName].count + 1
                end
            end
        end
    end

    local resultText = ""
    local resultIcons = ""

    for blueprintName in Iter( listBlueprint ) do

        local count = hashBlueprint[blueprintName].count
        local slotDesc = hashBlueprint[blueprintName].slotDesc

        local rarityStyle = EquipmentQuickConfugurationsUtils:GetRaritySmallStyle( slotDesc.rarity )

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

    --LogService:Log("slotsHash " .. debug_serialize_utils:SerializeObject(slotsHash))
    --LogService:Log("result " .. result)

    return result
end

function EquipmentQuickConfugurationsUtils:GetRarityStyle( rarity )

    -- 0 "item_level_0"
    -- 1 "item_level_1"
    -- 2 "item_level_2"
    -- 3 "item_level_3"

    if ( 0 <= rarity and rarity <= 3) then
        return "item_level_" .. tostring(rarity)
    end

    return "item_level_0"
end

function EquipmentQuickConfugurationsUtils:GetRaritySmallStyle( rarity )

    -- 0 "smallest_item_level_0"
    -- 1 "smallest_item_level_1"
    -- 2 "smallest_item_level_2"
    -- 3 "smallest_item_level_3"

    if ( 0 <= rarity and rarity <= 3) then
        return "smallest_item_level_" .. tostring(rarity)
    end

    return "smallest_item_level_0"
end

function EquipmentQuickConfugurationsUtils:IsRightType( itemType )

    local isRightType = (
        itemType == "range_weapon"
        or itemType == "melee_weapon"

        or itemType == "upgrade"

        or itemType == "skill"
        or itemType == "consumable"

        or itemType == "dash_skill"
        or itemType == "movement_skill"

        -- or itemType == "barrier"
        -- or itemType == "shield"
        -- or itemType == "equipment"
        -- or itemType == "passive"
        -- or itemType == "upgrade_parts"
        -- or itemType == "misc"
        -- or itemType == "interactive"
    );

    return isRightType
end

return EquipmentQuickConfugurationsUtils;