require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangePlayerBlueprintEquipmentItemComponent = function(newEquipmentSlots)

    local blueprint = ResourceManager:GetBlueprint( "player/player" )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangePlayerBlueprintEquipmentItemComponent Blueprint 'player/player' NOT EXISTS.")
        return
    end

    local equipmentComponent = blueprint:GetComponent("EquipmentComponent")
    if ( equipmentComponent == nil ) then
        LogService:Log("InjectChangePlayerBlueprintEquipmentItemComponent Blueprint 'player/player' EquipmentComponent NOT EXISTS.")
        return
    end

    local equipment = equipmentComponent:GetField("equipment"):ToContainer()
    if ( equipment == nil ) then
        LogService:Log("InjectChangePlayerBlueprintEquipmentItemComponent Blueprint 'player/player' equipmentComponent:GetField('equipment'):ToContainer() NOT EXISTS.")
        return
    end

    local equipmentItem = equipment:GetItem(0)
    if ( equipmentItem == nil ) then
        LogService:Log("InjectChangePlayerBlueprintEquipmentItemComponent Blueprint 'player/player' equipment:GetItem(0) NOT EXISTS.")
        return
    end

    local slotsArray = equipmentItem:GetField("slots"):ToContainer()
    if ( slotsArray == nil ) then
        LogService:Log("InjectChangePlayerBlueprintEquipmentItemComponent Blueprint 'player/player' equipmentItem:GetField('slots'):ToContainer() NOT EXISTS.")
        return
    end
    
    for _,configObj in ipairs(newEquipmentSlots) do

        local name = configObj.name
        local subslotsCount = configObj.subslots_count
        
        local allowTypes = configObj.allow_types

        local slotItem = nil
        
        for i=0,slotsArray:GetItemCount()-1 do

            local tempObject = slotsArray:GetItem(i)
            
            if ( tempObject:GetField("name"):GetValue() == name ) then

                slotItem = tempObject
                break
            end
        end

        if ( slotItem == nil ) then

            slotItem = slotsArray:CreateItem()

            slotItem:GetField("name"):SetValue(name)
            slotItem:GetField("subslots_count"):SetValue(subslotsCount)

            local allowTypesArray = slotItem:GetField("allow_types"):ToContainer()

            for _,typeName in ipairs(allowTypes) do

                local allowTypesObject = allowTypesArray:CreateItem()

                allowTypesObject:SetValue(typeName)
            end
        else

            slotItem:GetField("subslots_count"):SetValue(subslotsCount)

            local allowTypesArray = slotItem:GetField("allow_types"):ToContainer()

            for _,typeName in ipairs(allowTypes) do

                for j=0,allowTypesArray:GetItemCount()-1 do

                    local tempObject = allowTypesArray:GetItem(j)
            
                    if ( tempObject:GetValue() == typeName ) then

                        goto continue
                    end
                end

                local allowTypesObject = allowTypesArray:CreateItem()

                allowTypesObject:SetValue(typeName)

                ::continue::
            end
        end
    end
end

local new_equipment_slots = {

    {
        ["name"] = "LEFT_HAND",
        ["subslots_count"] = "6",
        ["allow_types"] = {

            "range_weapon",
            "melee_weapon",
            "shield",
            "enemy_range_weapon",
        },
    },

    {
        ["name"] = "RIGHT_HAND",
        ["subslots_count"] = "6",
        ["allow_types"] = {

            "range_weapon",
            "melee_weapon",
            "shield",
            "enemy_range_weapon",
        },
    },

    {
        ["name"] = "USABLE_1",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_2",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_3",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_4",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_5",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_6",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_7",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_8",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_9",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },

    {
        ["name"] = "USABLE_10",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
            "dash_skill",
            "movement_skill",
            "invisible_skill",
        },
    },





    {
        ["name"] = "UPGRADE_5",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_6",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_7",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_8",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_9",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_10",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_11",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_12",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_13",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_14",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_15",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },

    {
        ["name"] = "UPGRADE_16",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "upgrade",
        },
    },
}

InjectChangePlayerBlueprintEquipmentItemComponent(new_equipment_slots)



local player_equipment_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )
    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local equipmentComponent = EntityService:GetComponent(player, "EquipmentComponent")
    if ( equipmentComponent == nil ) then
        LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' EquipmentComponent NOT EXISTS.")
        return
    end

    --LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' EquipmentComponent " .. tostring(reflection_helper( equipmentComponent )))

    local equipment = equipmentComponent:GetField("equipment"):ToContainer()
    if ( equipment == nil ) then
        LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' equipmentComponent:GetField('equipment'):ToContainer() NOT EXISTS.")
        return
    end

    local equipmentItem = equipment:GetItem(0)
    if ( equipmentItem == nil ) then
        LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' equipment:GetItem(0) NOT EXISTS.")
        return
    end

    local slotsField = equipmentItem:GetField("slots")
    if ( slotsField == nil ) then

        local idField = equipmentItem:GetField("id")
        if ( idField ~= nil ) then

            local refEntity = tonumber( idField:GetValueAsNumber() )

            if ( refEntity ~= nil ) then

                --LogService:Log("player_equipment_autoexec Entity refEntity = " .. tostring(refEntity) .. " " .. idField:GetTypeName() .. " " .. type(refEntity))

                equipmentComponent = EntityService:GetComponent(refEntity, "EquipmentComponent")
                if ( equipmentComponent == nil ) then
                    LogService:Log("player_equipment_autoexec Entity '" .. tostring(refEntity) .. "' EquipmentComponent NOT EXISTS.")
                    return
                end

                --LogService:Log("player_equipment_autoexec Entity '" .. tostring(refEntity) .. "' EquipmentComponent " .. tostring(reflection_helper( equipmentComponent )))

                equipment = equipmentComponent:GetField("equipment"):ToContainer()
                if ( equipment == nil ) then
                    LogService:Log("player_equipment_autoexec Entity '" .. tostring(refEntity) .. "' equipmentComponent:GetField('equipment'):ToContainer() NOT EXISTS.")
                    return
                end

                equipmentItem = equipment:GetItem(0)
                if ( equipmentItem == nil ) then
                    LogService:Log("player_equipment_autoexec Entity '" .. tostring(refEntity) .. "' equipment:GetItem(0) NOT EXISTS.")
                    return
                end

                slotsField = equipmentItem:GetField("slots")
                if ( slotsField == nil ) then
            
                    LogService:Log("player_equipment_autoexec Entity '" .. tostring(refEntity) .. "' equipmentItem:GetField('slots') NOT EXISTS.")
                    return
                end

                goto continueSlotsArray
            end
            
            LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' equipmentItem:GetField('slots') and equipmentItem:GetField('id') NOT EXISTS.")
            return
        end
        
        LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' equipmentItem:GetField('slots') and equipmentItem:GetField('id') NOT EXISTS.")
        return
    end

    ::continueSlotsArray::

    local slotsArray = slotsField:ToContainer()
    if ( slotsArray == nil ) then
        LogService:Log("player_equipment_autoexec Entity '" .. tostring(player) .. "' equipmentItem:GetField('slots'):ToContainer() NOT EXISTS.")
        return
    end
    
    for _,configObj in ipairs(new_equipment_slots) do

        local name = configObj.name
        local subslotsCount = configObj.subslots_count
        
        local allowTypes = configObj.allow_types

        local slotItem = nil
        
        for i=0,slotsArray:GetItemCount()-1 do

            local tempObject = slotsArray:GetItem(i)
            
            if ( tempObject:GetField("name"):GetValue() == name ) then

                slotItem = tempObject
                break
            end
        end

        if ( slotItem == nil ) then

            slotItem = slotsArray:CreateItem()

            slotItem:GetField("name"):SetValue(name)
            slotItem:GetField("subslots_count"):SetValue(subslotsCount)

            local allowTypesArray = slotItem:GetField("allow_types"):ToContainer()

            for _,typeName in ipairs(allowTypes) do

                local allowTypesObject = allowTypesArray:CreateItem()

                allowTypesObject:SetValue(typeName)
            end
        else

            slotItem:GetField("subslots_count"):SetValue(subslotsCount)

            local allowTypesArray = slotItem:GetField("allow_types"):ToContainer()

            for _,typeName in ipairs(allowTypes) do

                for j=0,allowTypesArray:GetItemCount()-1 do

                    local tempObject = allowTypesArray:GetItem(j)
            
                    if ( tempObject:GetValue() == typeName ) then

                        goto continue
                    end
                end

                local allowTypesObject = allowTypesArray:CreateItem()

                allowTypesObject:SetValue(typeName)

                ::continue::
            end
        end
    end 
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    player_equipment_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    player_equipment_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    player_equipment_autoexec(evt)
end)