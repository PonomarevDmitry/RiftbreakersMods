require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

-- save_equipment upgrade upgrade_standart
-- save_equipment upgrade upgrade_standart2

-- save_equipment usable usable_standart
-- save_equipment left_hand left_hand_standart
-- save_equipment right_hand right_hand_standart

ConsoleService:RegisterCommand( "save_equipment", function( args )

    if not Assert( #args == 2, "Command save_equipment requires two arguments! [slot_name_prefix] [configname] " .. tostring(#args) ) then
        return 
    end

    local slotNamePrefix = args[1]
    local configName = args[2]

    LogService:Log("save_equipment " .. slotNamePrefix .. " " .. configName )
    
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

    local keyName = "$save_equipment." .. configName

    LogService:Log("save_equipment key " .. keyName .. " configContent " .. configContent )

    campaignDatabase:SetString( keyName, configContent )
    
end)

-- load_equipment upgrade upgrade_standart
-- load_equipment usable usable_standart
-- load_equipment left_hand left_hand_standart
-- load_equipment right_hand right_hand_standart

ConsoleService:RegisterCommand( "load_equipment", function( args )

    if not Assert( #args == 1, "Command load_equipment requires one arguments! [configname] " .. tostring(#args) ) then
        return 
    end

    local configName = args[1]

    LogService:Log("load_equipment " .. configName )
    
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

    local keyName = "$save_equipment." .. configName

    local configContent = campaignDatabase:GetStringOrDefault( keyName, "" )

    LogService:Log("load_equipment key " .. keyName .. " configContent " .. configContent )

    local configContentArray = Split( configContent, "|" )

    for template in Iter( configContentArray ) do

        local slotValuesArray = Split( template, ":" )

        if ( #slotValuesArray ~= 2 ) then
            goto continue
        end

        local slotName = slotValuesArray[1]

        local subSlotsConfig = slotValuesArray[2]

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

            local subSlotStringArray = Split( subSlotString, "," )

            if ( #subSlotStringArray == 2 ) then

                local subSlotNumber = tonumber(subSlotStringArray[1])
                local subSlotEntityId = tonumber(subSlotStringArray[2])

                if ( subSlotNumber ~= nil and subSlotEntityId ~= nil ) then

                    if ( 1 <= subSlotNumber and subSlotNumber <= selectedSlot.subslots_count ) then

                        local blueprintName = EntityService:GetBlueprintName( subSlotEntityId )

                        LogService:Log("#blueprintName subSlotEntityId " .. tostring(subSlotEntityId) .. " blueprintName " .. tostring(blueprintName) )

                        if ( blueprintName ~= nil and blueprintName ~= "") then

                            LogService:Log("TryEquipItemInSlot slotName " .. slotName .. " subSlotNumber " .. tostring(subSlotNumber) .. " subSlotEntityId " .. tostring(subSlotEntityId) )

                            ItemService:TryEquipItemInSlot( player, subSlotEntityId, slotName, subSlotNumber - 1 )
                        else
                            LogService:Log("#blueprintName == nil " )
                        end
                    end
                end
            end
        end

        ::continue::
    end
end)