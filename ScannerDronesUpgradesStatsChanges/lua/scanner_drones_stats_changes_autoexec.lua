------ #warning Commented Local ------
do return end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeScannerDronesEntityModDescValues = function(blueprintName, hashChanges)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeScannerDronesEntityModDescValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local entityModDesc = blueprint:GetComponent("EntityModDesc")
    if ( entityModDesc == nil ) then
        LogService:Log("InjectChangeScannerDronesEntityModDescValues Blueprint '" .. blueprintName .. "' EntityModDesc NOT EXISTS.")
        return
    end

    local mod_flagsContainer = entityModDesc:GetField("mod_flags"):ToContainer()
    if ( mod_flagsContainer == nil ) then
        LogService:Log("InjectChangeScannerDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModDesc:GetField('mod_flags'):ToContainer() NOT EXISTS.")
        return
    end

    for i=0,mod_flagsContainer:GetItemCount()-1 do

        local entityModTypeEntityMod = mod_flagsContainer:GetItem(i)

        if ( entityModTypeEntityMod == nil ) then
            LogService:Log("InjectChangeScannerDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModTypeEntityMod == nil")

            goto continue
        end

        local entityModTypeEntityModRef = reflection_helper(entityModTypeEntityMod)
        if ( entityModTypeEntityModRef.key == nil or entityModTypeEntityModRef.value == nil ) then

            goto continue
        end

        local keyValue = tonumber(entityModTypeEntityModRef.key)

        if ( hashChanges[keyValue] == nil ) then

            goto continue
        end

        entityModTypeEntityModRef.value = hashChanges[keyValue]

        --LogService:Log("InjectChangeScannerDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModTypeEntityMod " .. tostring(entityModTypeEntityModRef))

        ::continue::
    end
end

local InjectChangeListScannerDronesEntityModDescValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        local list = configObject.list
        local hashChanges = configObject.changes

        for _, blueprintName in ipairs(list) do

            InjectChangeScannerDronesEntityModDescValues(blueprintName, hashChanges)
        end
    end
end

local new_values = {

    {
        ["list"] = {
            "items/upgrades/scanner_equipment_standard_item",
            "items/upgrades/scanner_equipment_advanced_item",
            "items/upgrades/scanner_equipment_superior_item",
            "items/upgrades/scanner_equipment_extreme_item",
        },

        ["changes"] = {
            [EntityModType.health_regen] = "0",         -- base
            [EntityModType.movement_speed] = "1",       -- random
        },
    },

    {
        ["list"] = {

            "items/upgrades/detector_equipment_standard_item",
            "items/upgrades/detector_equipment_advanced_item",
            "items/upgrades/detector_equipment_superior_item",
            "items/upgrades/detector_equipment_extreme_item",
        },

        ["changes"] = {
            [EntityModType.forcefield_regen_cooldown] = "0",         -- base
            [EntityModType.movement_speed] = "1",       -- random
        },
    },
}

InjectChangeListScannerDronesEntityModDescValues(new_values)

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    InjectChangeListScannerDronesEntityModDescValues(new_values)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    InjectChangeListScannerDronesEntityModDescValues(new_values)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    InjectChangeListScannerDronesEntityModDescValues(new_values)
end)