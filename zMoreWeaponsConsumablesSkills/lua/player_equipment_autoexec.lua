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
        ["name"] = "USABLE_9",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
        },
    },

    {
        ["name"] = "USABLE_10",
        ["subslots_count"] = "1",
        ["allow_types"] = {

            "skill",
            "consumable",
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

    
}

InjectChangePlayerBlueprintEquipmentItemComponent(new_equipment_slots)