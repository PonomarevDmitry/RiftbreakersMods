local InjectChangeBlueprintInventoryItemComponentStorageLimit = function(blueprintsList, storageLimit)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint ~= nil ) then

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")

            if inventoryItemComponent ~= nil then
    
                inventoryItemComponent:GetField("storage_limit"):SetValue(storageLimit)
            else
                
                LogService:Log("InjectChangeBlueprintInventoryItemComponentStorageLimit Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
            end
        else

            LogService:Log("InjectChangeBlueprintInventoryItemComponentStorageLimit Blueprint " .. blueprintName .. " NOT EXISTS.")
        end
    end
end

local InjectChangeBlueprintInventoryItemComponentCooldown = function(blueprintsList)

    for blueprintName,cooldownValue in pairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint ~= nil ) then

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")

            if inventoryItemComponent ~= nil then
    
                inventoryItemComponent:GetField("cooldown"):SetValue(cooldownValue)
            else
                
                LogService:Log("InjectChangeBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
            end
        else

            LogService:Log("InjectChangeBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " NOT EXISTS.")
        end
    end
end

local supported_item_blueprints = {

    "items/consumables/cluster_grenade_acid_standard_item",
    "items/consumables/cluster_grenade_acid_advanced_item",
    "items/consumables/cluster_grenade_acid_superior_item",
    "items/consumables/cluster_grenade_acid_extreme_item",

    "items/consumables/cryo_sentry_standard_item",
    "items/consumables/cryo_sentry_advanced_item",
    "items/consumables/cryo_sentry_superior_item",
    "items/consumables/cryo_sentry_extreme_item",

    "items/consumables/drone_swarm_item",
    "items/consumables/drone_swarm_advanced_item",
    "items/consumables/drone_swarm_superior_item",
    "items/consumables/drone_swarm_extreme_item",

    "items/consumables/flare_standard_item",

    "items/consumables/gas_grenade_item",
    "items/consumables/gas_grenade_advanced_item",
    "items/consumables/gas_grenade_superior_item",
    "items/consumables/gas_grenade_extreme_item",

    "items/consumables/grenade_standard_item",
    "items/consumables/grenade_advanced_item",
    "items/consumables/grenade_superior_item",
    "items/consumables/grenade_extreme_item",

    "items/consumables/grenade_gravity_standard_item",
    "items/consumables/grenade_gravity_advanced_item",
    "items/consumables/grenade_gravity_superior_item",
    "items/consumables/grenade_gravity_extreme_item",

    "items/consumables/grenade_sonic_standard_item",
    "items/consumables/grenade_sonic_advanced_item",
    "items/consumables/grenade_sonic_superior_item",
    "items/consumables/grenade_sonic_extreme_item",

    "items/consumables/holo_decoy_standard_item",
    "items/consumables/holo_decoy_advanced_item",
    "items/consumables/holo_decoy_superior_item",
    "items/consumables/holo_decoy_extreme_item",

    "items/consumables/mini_miner_standard_item",
    "items/consumables/mini_miner_advanced_item",
    "items/consumables/mini_miner_superior_item",
    "items/consumables/mini_miner_extreme_item",

    "items/consumables/mobile_turret_standard_item",
    "items/consumables/mobile_turret_advanced_item",
    "items/consumables/mobile_turret_superior_item",
    "items/consumables/mobile_turret_extreme_item",

    "items/consumables/mortar_sentry_item",
    "items/consumables/mortar_sentry_advanced_item",
    "items/consumables/mortar_sentry_superior_item",
    "items/consumables/mortar_sentry_extreme_item",

    "items/consumables/proximity_mine_standard_item",
    "items/consumables/proximity_mine_advanced_item",
    "items/consumables/proximity_mine_superior_item",
    "items/consumables/proximity_mine_extreme_item",

    "items/consumables/proximity_mine_cryogenic_standard_item",
    "items/consumables/proximity_mine_cryogenic_advanced_item",
    "items/consumables/proximity_mine_cryogenic_superior_item",
    "items/consumables/proximity_mine_cryogenic_extreme_item",

    "items/consumables/proximity_mine_gravity_standard_item",
    "items/consumables/proximity_mine_gravity_advanced_item",
    "items/consumables/proximity_mine_gravity_superior_item",
    "items/consumables/proximity_mine_gravity_extreme_item",

    "items/consumables/proximity_mine_nuclear_standard_item",
    "items/consumables/proximity_mine_nuclear_advanced_item",
    "items/consumables/proximity_mine_nuclear_superior_item",
    "items/consumables/proximity_mine_nuclear_extreme_item",

    "items/consumables/repair_standard",
    "items/consumables/repair_advanced",
    "items/consumables/repair_superior",
    "items/consumables/repair_extreme",

    "items/consumables/scanner_turret_standard_item",
    "items/consumables/scanner_turret_advanced_item",
    "items/consumables/scanner_turret_superior_item",
    "items/consumables/scanner_turret_extreme_item",

    "items/consumables/tesla_turret_standard_item",
    "items/consumables/tesla_turret_advanced_item",
    "items/consumables/tesla_turret_superior_item",
    "items/consumables/tesla_turret_extreme_item",
}

InjectChangeBlueprintInventoryItemComponentStorageLimit(supported_item_blueprints, "100")

local supported_item_blueprints = {

    ["items/consumables/cluster_grenade_acid_standard_item"] = "0.05",
    ["items/consumables/cluster_grenade_acid_advanced_item"] = "0.05",
    ["items/consumables/cluster_grenade_acid_superior_item"] = "0.05",
    ["items/consumables/cluster_grenade_acid_extreme_item"] = "0.05",
     
    ["items/consumables/flare_standard_item"] = "0.05",
     
    ["items/consumables/gas_grenade_item"] = "0.05",
    ["items/consumables/gas_grenade_advanced_item"] = "0.05",
    ["items/consumables/gas_grenade_superior_item"] = "0.05",
    ["items/consumables/gas_grenade_extreme_item"] = "0.05",
     
    ["items/consumables/grenade_standard_item"] = "0.05",
    ["items/consumables/grenade_advanced_item"] = "0.05",
    ["items/consumables/grenade_superior_item"] = "0.05",
    ["items/consumables/grenade_extreme_item"] = "0.05",
     
    ["items/consumables/grenade_gravity_standard_item"] = "0.05",
    ["items/consumables/grenade_gravity_advanced_item"] = "0.05",
    ["items/consumables/grenade_gravity_superior_item"] = "0.05",
    ["items/consumables/grenade_gravity_extreme_item"] = "0.05",
     
    ["items/consumables/grenade_sonic_standard_item"] = "0.05",
    ["items/consumables/grenade_sonic_advanced_item"] = "0.05",
    ["items/consumables/grenade_sonic_superior_item"] = "0.05",
    ["items/consumables/grenade_sonic_extreme_item"] = "0.05",

    ["items/consumables/repair_standard"] = "0.05",
    ["items/consumables/repair_advanced"] = "0.05",
    ["items/consumables/repair_superior"] = "0.05",
    ["items/consumables/repair_extreme"] = "0.05",

    ["items/consumables/mini_miner_standard_item"] = "0.05",
    ["items/consumables/mini_miner_advanced_item"] = "0.05",
    ["items/consumables/mini_miner_superior_item"] = "0.05",
    ["items/consumables/mini_miner_extreme_item"] = "0.05",

    ["items/consumables/cryo_sentry_standard_item"] = "0.05",
    ["items/consumables/cryo_sentry_advanced_item"] = "0.05",
    ["items/consumables/cryo_sentry_superior_item"] = "0.05",
    ["items/consumables/cryo_sentry_extreme_item"] = "0.05",

    ["items/consumables/mobile_turret_standard_item"] = "0.05",
    ["items/consumables/mobile_turret_advanced_item"] = "0.05",
    ["items/consumables/mobile_turret_superior_item"] = "0.05",
    ["items/consumables/mobile_turret_extreme_item"] = "0.05",

    ["items/consumables/mortar_sentry_item"] = "0.05",
    ["items/consumables/mortar_sentry_advanced_item"] = "0.05",
    ["items/consumables/mortar_sentry_superior_item"] = "0.05",
    ["items/consumables/mortar_sentry_extreme_item"] = "0.05",

    ["items/consumables/scanner_turret_standard_item"] = "0.05",
    ["items/consumables/scanner_turret_advanced_item"] = "0.05",
    ["items/consumables/scanner_turret_superior_item"] = "0.05",
    ["items/consumables/scanner_turret_extreme_item"] = "0.05",

    ["items/consumables/tesla_turret_standard_item"] = "0.05",
    ["items/consumables/tesla_turret_advanced_item"] = "0.05",
    ["items/consumables/tesla_turret_superior_item"] = "0.05",
    ["items/consumables/tesla_turret_extreme_item"] = "0.05",
     
    ["items/skills/radar_pulse_item"] = "0.05",
    ["items/skills/radar_pulse_advanced_item"] = "0.05",
    ["items/skills/radar_pulse_superior_item"] = "0.05",
    ["items/skills/radar_pulse_extreme_item"] = "0.05",
     
    ["items/interactive/drill_item"] = "0.02",

    ["items/skills/generator_overcharge_standard_item"] = "1",
    ["items/skills/generator_overcharge_advanced_item"] = "1",
    ["items/skills/generator_overcharge_superior_item"] = "1",
    ["items/skills/generator_overcharge_extreme_item"] = "1",

    ["items/skills/flamewave_standard_item"] = "1",
    ["items/skills/flamewave_advanced_item"] = "1",
    ["items/skills/flamewave_superior_item"] = "1",
    ["items/skills/flamewave_extreme_item"] = "1",

    ["items/skills/emergency_explosion_standard_item"] = "1",
    ["items/skills/emergency_explosion_advanced_item"] = "1",
    ["items/skills/emergency_explosion_superior_item"] = "1",
    ["items/skills/emergency_explosion_extreme_item"] = "1",

    ["items/skills/antimatter_ball_standard_item"] = "1",
    ["items/skills/antimatter_ball_advanced_item"] = "1",
    ["items/skills/antimatter_ball_superior_item"] = "1",
    ["items/skills/antimatter_ball_extreme_item"] = "1",

    ["items/skills/orbital_bombardment_standard_item"] = "10",
    ["items/skills/orbital_bombardment_advanced_item"] = "10",
    ["items/skills/orbital_bombardment_superior_item"] = "10",
    ["items/skills/orbital_bombardment_extreme_item"] = "10",

    ["items/skills/orbital_laser_standard_item"] = "10",
    ["items/skills/orbital_laser_advanced_item"] = "10",
    ["items/skills/orbital_laser_superior_item"] = "10",
    ["items/skills/orbital_laser_extreme_item"] = "10",
}

InjectChangeBlueprintInventoryItemComponentCooldown(supported_item_blueprints)