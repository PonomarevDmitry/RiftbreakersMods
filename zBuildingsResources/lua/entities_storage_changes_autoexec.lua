require("lua/utils/reflection.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

local InjectChangeBlueprintStorageValues = function(blueprintName, newStorageValues)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local resourceStorageComponent = blueprint:GetComponent("ResourceStorageComponent")
    if ( resourceStorageComponent == nil ) then
        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' ResourceStorageComponent NOT EXISTS.")
        return
    end

    local storagesArray = resourceStorageComponent:GetField("Storages"):ToContainer()
    if ( storagesArray == nil ) then
        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceStorageComponent:GetField('Storages'):ToContainer() NOT EXISTS.")
        return
    end
        
    for i=0,storagesArray:GetItemCount()-1 do

        local storageObject = storagesArray:GetItem(i)
            
        if ( storageObject == nil ) then
            LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' storageObject == nil")

            goto continue
        end

        local storageObjectRef = reflection_helper(storageObject)

        if ( storageObjectRef.resource == nil ) then
            LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource == nil")

            goto continue
        end

        if ( storageObjectRef.resource.resource == nil ) then
            LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource.resource == nil")

            goto continue
        end

        local resourceId = storageObjectRef.resource.resource.id

        if ( resourceId == nil or resourceId == "" ) then
            LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId == nil or resourceId == ''")

            goto continue
        end

        if ( newStorageValues[resourceId] == nil ) then
            LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' newStorageValues[resourceId] == nil")

            goto continue
        end

        storageObject:GetField("max"):SetValue(newStorageValues[resourceId])

        ::continue::
    end
end

local InjectChangeListBlueprintStorageValues = function(blueprintStorageValues)

    for blueprintName, newStorageValues in pairs(blueprintStorageValues) do

        InjectChangeBlueprintStorageValues(blueprintName, newStorageValues)
    end
end

local new_storage_values = {

    ["player/player"] = {

        ["carbonium"] = "1200",
        ["steel"] = "1200",

        ["uranium_ore"] = "1200",
        ["uranium"] = "1200",
        ["palladium"] = "1200",
        ["titanium"] = "1200",
        ["cobalt"] = "1200",

        ["voidinite_ore"] = "1200",
        ["rift_energy"] = "400",

        ["ammo_mech_low_caliber"] = "16",
        ["ammo_mech_high_caliber"] = "16",
        ["ammo_mech_liquid"] = "16",
        ["ammo_mech_explosive"] = "16",
        ["ammo_mech_energy_cell"] = "16",
    
        ["crystal_dna"] = "16",
        ["ammo_mech_medium_caliber"] = "16",
        ["ammo_mech_acid_cells"] = "16",
        ["ammo_mech_cryo_cells"] = "16",
        ["ammo_mech_gravity_matrix"] = "16",
        ["ammo_mech_magma_cells"] = "16",

        ["ammo_mech_morphium_canister"] = "16",
        ["ammo_mech_plasma_cells"] = "16",
        ["ammo_mech_radio_cells"] = "16",
        ["ammo_mech_rift_charge"] = "16",
    },

    ["buildings/main/headquarters"] = {

        ["energy"] = "4000",

        ["carbonium"] = "200",
        ["steel"] = "200",

        ["uranium_ore"] = "200",
        ["uranium"] = "200",
        ["palladium"] = "200",
        ["titanium"] = "200",
        ["cobalt"] = "200",

        ["voidinite_ore"] = "200",

        ["ammo_tower_explosive"] = "4",
        ["ammo_tower_liquid"] = "4",
        ["ammo_tower_low_caliber"] = "4",
        ["ammo_tower_high_caliber"] = "4",

        ["ai"] = "16",
    },

    ["buildings/main/outpost"] = {

        ["energy"] = "4000",

        ["carbonium"] = "200",
        ["steel"] = "200",

        ["uranium_ore"] = "200",
        ["uranium"] = "200",
        ["palladium"] = "200",
        ["titanium"] = "200",
        ["cobalt"] = "200",

        ["voidinite_ore"] = "200",

        ["ammo_tower_explosive"] = "4",
        ["ammo_tower_liquid"] = "4",
        ["ammo_tower_low_caliber"] = "4",
        ["ammo_tower_high_caliber"] = "4",

        ["ai"] = "16",
    },

    ["buildings/defense/ai_hub"] = {

        ["ai"] = "8",
    },

    ["buildings/defense/ai_hub_lvl_2"] = {

        ["ai"] = "16",
    },

    ["buildings/defense/ai_hub_lvl_3"] = {

        ["ai"] = "32",
    },



    ["buildings/energy/plant_biomass_powerplant"] = {

        ["energy"] = "400",
    },

    ["buildings/energy/plant_biomass_powerplant_lvl_2"] = {

        ["energy"] = "600",
    },

    ["buildings/energy/plant_biomass_powerplant_lvl_3"] = {

        ["energy"] = "800",
    },



    ["buildings/energy/nuclear_powerplant"] = {

        ["energy"] = "6000",
    },

    ["buildings/energy/nuclear_powerplant_lvl_2"] = {

        ["energy"] = "9000",
    },

    ["buildings/energy/nuclear_powerplant_lvl_3"] = {

        ["energy"] = "12000",
    },



    ["buildings/energy/morphium_powerplant"] = {

        ["energy"] = "2000",
    },

    ["buildings/energy/morphium_powerplant_lvl_2"] = {

        ["energy"] = "3000",
    },

    ["buildings/energy/morphium_powerplant_lvl_3"] = {

        ["energy"] = "4000",
    },



    ["buildings/energy/magma_powerplant"] = {

        ["energy"] = "2000",
    },

    ["buildings/energy/magma_powerplant_lvl_2"] = {

        ["energy"] = "3000",
    },

    ["buildings/energy/magma_powerplant_lvl_3"] = {

        ["energy"] = "4000",
    },



    ["buildings/energy/geothermal_powerplant"] = {

        ["energy"] = "800",
        ["mud"] = "1600",
    },

    ["buildings/energy/geothermal_powerplant_lvl_2"] = {

        ["energy"] = "1600",
        ["mud"] = "2400",
    },

    ["buildings/energy/geothermal_powerplant_lvl_3"] = {

        ["energy"] = "3200",
        ["mud"] = "3200",
    },



    ["buildings/energy/gas_powerplant"] = {

        ["energy"] = "2000",
    },

    ["buildings/energy/gas_powerplant_lvl_2"] = {

        ["energy"] = "3000",
    },

    ["buildings/energy/gas_powerplant_lvl_3"] = {

        ["energy"] = "4000",
    },



    ["buildings/energy/fusion_powerplant"] = {

        ["energy"] = "14000",
        ["plasma"] = "1600",
    },

    ["buildings/energy/fusion_powerplant_lvl_2"] = {

        ["energy"] = "20000",
        ["plasma"] = "2400",
    },

    ["buildings/energy/fusion_powerplant_lvl_3"] = {

        ["energy"] = "28000",
        ["plasma"] = "3200",
    },



    ["buildings/energy/energy_storage"] = {

        ["energy"] = "40000",
    },

    ["buildings/energy/energy_storage_lvl_2"] = {

        ["energy"] = "80000",
    },

    ["buildings/energy/energy_storage_lvl_3"] = {

        ["energy"] = "160000",
    },



    ["buildings/energy/carbonium_powerplant"] = {

        ["energy"] = "240",
    },

    ["buildings/energy/carbonium_powerplant_lvl_2"] = {

        ["energy"] = "480",
    },

    ["buildings/energy/carbonium_powerplant_lvl_3"] = {

        ["energy"] = "960",
    },



    ["buildings/energy/animal_biomass_powerplant"] = {

        ["energy"] = "800",
    },

    ["buildings/energy/animal_biomass_powerplant_lvl_2"] = {

        ["energy"] = "1200",
    },

    ["buildings/energy/animal_biomass_powerplant_lvl_3"] = {

        ["energy"] = "1600",
    },



    ["buildings/resources/bio_condenser"] = {

        ["sludge"] = "800",
    },

    ["buildings/resources/bio_condenser_lvl_2"] = {

        ["sludge"] = "1600",
    },

    ["buildings/resources/bio_condenser_lvl_3"] = {

        ["sludge"] = "2400",
    },



    ["buildings/resources/ammunition_storage"] = {

        ["ammo_mech"] = "4",
        ["ammo_tower"] = "4",
    },

    ["buildings/resources/ammunition_storage_lvl_2"] = {

        ["ammo_mech"] = "8",
        ["ammo_tower"] = "8",
    },

    ["buildings/resources/ammunition_storage_lvl_3"] = {

        ["ammo_mech"] = "16",
        ["ammo_tower"] = "16",
    },



    ["buildings/resources/bio_composter"] = {

        ["flammable_gas"] = "400",
    },

    ["buildings/resources/bio_composter_lvl_2"] = {

        ["flammable_gas"] = "800",
    },

    ["buildings/resources/bio_composter_lvl_3"] = {

        ["flammable_gas"] = "1200",
    },



    ["buildings/resources/gas_extractor"] = {

        ["flammable_gas"] = "1200",
    },

    ["buildings/resources/gas_extractor_lvl_2"] = {

        ["flammable_gas"] = "1200",
    },

    ["buildings/resources/gas_extractor_lvl_3"] = {

        ["flammable_gas"] = "1200",
    },



    ["buildings/resources/gas_filtering_plant"] = {

        ["flammable_gas"] = "400",
    },

    ["buildings/resources/gas_filtering_plant_lvl_2"] = {

        ["flammable_gas"] = "800",
    },

    ["buildings/resources/gas_filtering_plant_lvl_3"] = {

        ["flammable_gas"] = "1200",
    },



    ["buildings/resources/ionizer"] = {

        ["plasma"] = "400",
    },



    ["buildings/resources/plasma_converter"] = {

        ["plasma_charged"] = "400",
    },

    ["buildings/resources/plasma_converter_lvl_2"] = {

        ["plasma_charged"] = "800",
    },

    ["buildings/resources/plasma_converter_lvl_3"] = {

        ["plasma_charged"] = "1200",
    },



    ["buildings/resources/supercoolant_refinery"] = {

        ["supercoolant"] = "400",
    },



    ["buildings/resources/water_filtering_plant"] = {

        ["water"] = "800",
    },

    ["buildings/resources/water_filtering_plant_lvl_2"] = {

        ["water"] = "1200",
    },

    ["buildings/resources/water_filtering_plant_lvl_3"] = {

        ["water"] = "1600",
    },



    ["buildings/resources/plant_biomass_powerplant"] = {

        ["energy"] = "400",
    },

    ["buildings/resources/plant_biomass_powerplant_lvl_2"] = {

        ["energy"] = "600",
    },

    ["buildings/resources/plant_biomass_powerplant_lvl_3"] = {

        ["energy"] = "800",
    },



    ["buildings/resources/plant_biomass_powerplant"] = {

        ["energy"] = "400",
    },

    ["buildings/resources/plant_biomass_powerplant_lvl_2"] = {

        ["energy"] = "600",
    },

    ["buildings/resources/plant_biomass_powerplant_lvl_3"] = {

        ["energy"] = "800",
    },
}

InjectChangeListBlueprintStorageValues(new_storage_values)