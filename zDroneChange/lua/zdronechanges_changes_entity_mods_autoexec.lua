require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeDronesEntityModDescValues = function(blueprintName, hashChanges)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeDronesEntityModDescValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local entityModDesc = blueprint:GetComponent("EntityModDesc")
    if ( entityModDesc == nil ) then
        LogService:Log("InjectChangeDronesEntityModDescValues Blueprint '" .. blueprintName .. "' EntityModDesc NOT EXISTS.")
        return
    end

    local entity_modsContainer = entityModDesc:GetField("entity_mods"):ToContainer()
    if ( entity_modsContainer == nil ) then
        LogService:Log("InjectChangeDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModDesc:GetField('entity_mods'):ToContainer() NOT EXISTS.")
        return
    end

    for i=0,entity_modsContainer:GetItemCount()-1 do

        local entityModTypeEntityMod = entity_modsContainer:GetItem(i)

        if ( entityModTypeEntityMod == nil ) then
            LogService:Log("InjectChangeDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModTypeEntityMod == nil")

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

        entityModTypeEntityModRef.value.mod_value = hashChanges[keyValue]

        --LogService:Log("InjectChangeDronesEntityModDescValues Blueprint '" .. blueprintName .. "' entityModTypeEntityMod " .. tostring(entityModTypeEntityModRef))

        ::continue::
    end
end

local InjectChangeListDronesEntityModDescValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        local list = configObject.list
        local hashChanges = configObject.changes

        for _, blueprintName in ipairs(list) do

            InjectChangeDronesEntityModDescValues(blueprintName, hashChanges)
        end
    end
end

local new_values = {

    {
        ["list"] = {
            "items/upgrades/attack_gear_advanced_item",
            "items/upgrades/offensive_equipment_advanced_item",
        },

        ["changes"] = {
            [EntityModType.attack_drone] = "2",
        },
    },

    {
        ["list"] = {
            "items/upgrades/attack_gear_superior_item",
            "items/upgrades/offensive_equipment_superior_item",
        },

        ["changes"] = {
            [EntityModType.attack_drone] = "4",
        },
    },

    {
        ["list"] = {
            "items/upgrades/attack_gear_extreme_item",
            "items/upgrades/offensive_equipment_extreme_item",
        },

        ["changes"] = {
            [EntityModType.attack_drone] = "8",
        },
    },



    {
        ["list"] = {
            "items/upgrades/defense_gear_advanced_item",
            "items/upgrades/defensive_equipment_advanced_item",
        },

        ["changes"] = {
            [EntityModType.defense_drone] = "2",
        },
    },

    {
        ["list"] = {
            "items/upgrades/defense_gear_superior_item",
            "items/upgrades/defensive_equipment_superior_item",
        },

        ["changes"] = {
            [EntityModType.defense_drone] = "4",
        },
    },

    {
        ["list"] = {
            "items/upgrades/defense_gear_extreme_item",
            "items/upgrades/defensive_equipment_extreme_item",
        },

        ["changes"] = {
            [EntityModType.defense_drone] = "8",
        },
    },



    {
        ["list"] = {
            "items/upgrades/discovery_tools_advanced_item",
            "items/upgrades/gathering_tools_advanced_item",
        },

        ["changes"] = {
            [EntityModType.loot_drone] = "2",
        },
    },

    {
        ["list"] = {
            "items/upgrades/discovery_tools_superior_item",
            "items/upgrades/gathering_tools_superior_item",
        },

        ["changes"] = {
            [EntityModType.loot_drone] = "4",
        },
    },

    {
        ["list"] = {
            "items/upgrades/discovery_tools_extreme_item",
            "items/upgrades/gathering_tools_extreme_item",
        },

        ["changes"] = {
            [EntityModType.loot_drone] = "8",
        },
    },



    {
        ["list"] = {
            "items/upgrades/maintenance_tools_advanced_item",
            "items/upgrades/repair_tools_advanced_item",
        },

        ["changes"] = {
            [EntityModType.repair_drone] = "2",
        },
    },

    {
        ["list"] = {
            "items/upgrades/maintenance_tools_superior_item",
            "items/upgrades/repair_tools_superior_item",
        },

        ["changes"] = {
            [EntityModType.repair_drone] = "4",
        },
    },

    {
        ["list"] = {
            "items/upgrades/maintenance_tools_extreme_item",
            "items/upgrades/repair_tools_extreme_item",
        },

        ["changes"] = {
            [EntityModType.repair_drone] = "8",
        },
    },





    {
        ["list"] = {
            "items/upgrades/attack_gear_standard_item",
            "items/upgrades/defensive_equipment_standard_item",
            "items/upgrades/discovery_tools_standard_item",

            "items/upgrades/energy_sensors_standard_item",
            "items/upgrades/gathering_tools_standard_item",
            "items/upgrades/sonic_sensors_standard_item",
        },

        ["changes"] = {
            [EntityModType.loot_mods_chance] = "1.6",
            [EntityModType.loot_resources_chance] = "1.6",
        },
    },

    {
        ["list"] = {
            "items/upgrades/attack_gear_advanced_item",
            "items/upgrades/defensive_equipment_advanced_item",
            "items/upgrades/discovery_tools_advanced_item",

            "items/upgrades/energy_sensors_advanced_item",
            "items/upgrades/gathering_tools_advanced_item",
            "items/upgrades/sonic_sensors_advanced_item",
        },

        ["changes"] = {
            [EntityModType.loot_mods_chance] = "1.9",
            [EntityModType.loot_resources_chance] = "1.9",
        },
    },

    {
        ["list"] = {
            "items/upgrades/attack_gear_superior_item",
            "items/upgrades/defensive_equipment_superior_item",
            "items/upgrades/discovery_tools_superior_item",

            "items/upgrades/energy_sensors_superior_item",
            "items/upgrades/gathering_tools_superior_item",
            "items/upgrades/sonic_sensors_superior_item",
        },

        ["changes"] = {
            [EntityModType.loot_mods_chance] = "2.2",
            [EntityModType.loot_resources_chance] = "2.2",
        },
    },

    {
        ["list"] = {
            "items/upgrades/attack_gear_extreme_item",
            "items/upgrades/defensive_equipment_extreme_item",
            "items/upgrades/discovery_tools_extreme_item",

            "items/upgrades/energy_sensors_extreme_item",
            "items/upgrades/gathering_tools_extreme_item",
            "items/upgrades/sonic_sensors_extreme_item",
        },

        ["changes"] = {
            [EntityModType.loot_mods_chance] = "2.5",
            [EntityModType.loot_resources_chance] = "2.5",
        },
    },
}

InjectChangeListDronesEntityModDescValues(new_values)