require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local QuickEquipmentSlotsUtils = {}

function QuickEquipmentSlotsUtils:SaveEquipment( slotNamePrefix, configName )

    local player = PlayerService:GetPlayerControlledEnt(0)
    if player == INVALID_ID then
        return
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end

    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return
    end

    --LogService:Log( "QuickEquipmentSlotsUtils equipment " .. tostring(equipment) )

    slotNamePrefix = string.lower(slotNamePrefix)

    local configContent = ""

    local slots = equipment.slots

    for i=1,slots.count do

        local slot = slots[i]

        local slotName = string.lower(slot.name)

        if ( string.find( slotName, slotNamePrefix ) ~= nil ) then

            local subSlotsConfig = ""

            for j=1,slot.subslots.count do

                local entities = slot.subslots[j]

                local entity = entities[1]

                if (entity) then

                    if entity.id then
                        entity = entity.id
                    end

                    if ( string.len( subSlotsConfig ) > 0 ) then
                        subSlotsConfig = subSlotsConfig .. ";"
                    end

                    subSlotsConfig = subSlotsConfig .. tostring(j) .. "," .. tostring(entity)
                end
            end

            if ( string.len( subSlotsConfig ) > 0 ) then

                if ( string.len( configContent ) > 0 ) then
                    configContent = configContent .. "|"
                end

                configContent = configContent .. slot.name .. ":" .. subSlotsConfig
            end            
        end
    end

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    LogService:Log("save_equipment key " .. keyName .. " configContent " .. configContent )

    campaignDatabase:SetString( keyName, configContent )
end

function QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local keyName = "$QuickEquipmentSlotsUtils." .. slotNamePrefix .. "." .. configName

    return keyName
end

function QuickEquipmentSlotsUtils:LoadEquipment( slotNamePrefix, configName )
    
    local player = PlayerService:GetPlayerControlledEnt(0)
    if player == INVALID_ID then
        return
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end
    
    local equipment = reflection_helper( EntityService:GetComponent(player, "EquipmentComponent") ).equipment[1]
    if equipment.id then
        equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
    end

    if ( equipment == nil ) then
        return
    end

    local slots = equipment.slots

    local keyName = QuickEquipmentSlotsUtils:GetSettingKeyName( slotNamePrefix, configName )

    local configContent = campaignDatabase:GetStringOrDefault( keyName, "" )

    configContent = configContent or ""

    LogService:Log("load_equipment key " .. keyName .. " configContent " .. configContent )

    if ( configContent == "" ) then

        return
    end

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

        for i=1,slots.count do

            selectedSlot = slots[i]

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

            QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, slotName, selectedSlot.subslots_count, subSlotString )
        end

        ::continue::
    end
end

function QuickEquipmentSlotsUtils:LoadEquipmentToSlot( player, slotName, subslots_count, subSlotString )

    local subSlotStringArray = Split( subSlotString, "," )

    if ( #subSlotStringArray ~= 2 ) then
        return
    end

    local subSlotNumber = tonumber(subSlotStringArray[1])
    local subSlotEntityId = tonumber(subSlotStringArray[2])

    if ( subSlotNumber == nil or subSlotEntityId == nil ) then
        return
    end

    if ( subslots_count < subSlotNumber or subSlotNumber <= 0 ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( subSlotEntityId )
    blueprintName = blueprintName or ""

    LogService:Log("#blueprintName subSlotEntityId " .. tostring(subSlotEntityId) .. " blueprintName " .. tostring(blueprintName) )

    if ( blueprintName == "") then
        LogService:Log("#blueprintName == nil " )
        return
    end

    LogService:Log("TryEquipItemInSlot slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) )

    --ItemService:TryEquipItemInSlot( player, subSlotEntityId, slotName, subSlotNumber - 1 )

    --QueueEvent("UnequipItemRequest", player, subSlotEntityId, slotName )

    --QueueEvent("EquipItemRequest", player, subSlotEntityId, slotName )

    PlayerService:EquipItemInSlot( 0, subSlotEntityId, slotName )
end

return QuickEquipmentSlotsUtils;