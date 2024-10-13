require("lua/utils/reflection.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

local InjectChangeBlueprintStorageValues = function(blueprintName, newStorageValues, newStorageGroupsValues)

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

        local groupId = storageObjectRef.group

        --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' groupId = " .. tostring(groupId))

        if ( groupId == 12 ) then

            if ( storageObjectRef.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource == nil")

                goto continue
            end

            if ( storageObjectRef.resource.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource.resource == nil")

                goto continue
            end

            local resourceId = storageObjectRef.resource.resource.id

            --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId  = " .. tostring(resourceId) .. " groupId = " .. tostring(groupId))

            if ( resourceId ~= nil and resourceId ~= "" ) then

                local resourceIdString = tostring(resourceId)

                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId ~= nil or resourceId ~= '' " .. resourceIdString)

                if ( newStorageValues and newStorageValues[resourceIdString] ~= nil ) then
                    --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' newStorageValues[resourceId] ~= nil " .. tostring(newStorageValues[resourceIdString]))

                    storageObject:GetField("max"):SetValue(newStorageValues[resourceIdString])
                end

                goto continue
            end
        else

            if ( groupId ~= nil and groupId ~= "" ) then

                local groupIdString = tostring(groupId)

                if ( newStorageGroupsValues and newStorageGroupsValues[groupIdString] ~= nil ) then
                    --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' newStorageGroupsValues[groupIdString] ~= nil " .. tostring(newStorageGroupsValues[groupIdString]))

                    storageObject:GetField("max"):SetValue(newStorageGroupsValues[groupIdString])
                end

                goto continue
            end
        end

        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId == nil and groupId == ''\n" .. tostring(storageObjectRef))

        ::continue::
    end
end

local InjectChangeListBlueprintStorageValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeBlueprintStorageValues(configObject.name, configObject.storages, configObject.groups)
    end
end

local new_storage_values = {

    {
        ["name"] = "player/player",
        ["storages"] = {

            ["carbonium"] = "1200",
            ["steel"] = "1200",

            ["uranium_ore"] = "1200",
            ["uranium"] = "1200",
            ["palladium"] = "1200",
            ["titanium"] = "1200",
            ["cobalt"] = "1200",
            
            ["voidinite_ore"] = "1200",
            ["cosmonite_ore"] = "1200",

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
    },
    
    {
        ["name"] = "buildings/main/headquarters",
        ["storages"] = {

            ["energy"] = "4000",

            ["carbonium"] = "200",
            ["steel"] = "200",

            ["uranium_ore"] = "200",
            ["uranium"] = "200",
            ["palladium"] = "200",
            ["titanium"] = "200",
            ["cobalt"] = "200",

            ["voidinite_ore"] = "200",
            ["cosmonite_ore"] = "200",

            ["ammo_tower_explosive"] = "4",
            ["ammo_tower_liquid"] = "4",
            ["ammo_tower_low_caliber"] = "4",
            ["ammo_tower_high_caliber"] = "4",

            ["ai"] = "16",
        },

        ["groups"] = {

            ["0"] = "200", -- global
        },
    },
    
    {
        ["name"] = "buildings/main/outpost",
        ["storages"] = {

            ["energy"] = "4000",

            ["carbonium"] = "200",
            ["steel"] = "200",

            ["uranium_ore"] = "200",
            ["uranium"] = "200",
            ["palladium"] = "200",
            ["titanium"] = "200",
            ["cobalt"] = "200",
            
            ["voidinite_ore"] = "200",
            ["cosmonite_ore"] = "200",

            ["ammo_tower_explosive"] = "4",
            ["ammo_tower_liquid"] = "4",
            ["ammo_tower_low_caliber"] = "4",
            ["ammo_tower_high_caliber"] = "4",

            ["ai"] = "16",
        },

        ["groups"] = {

            ["0"] = "200", -- global
        },
    },
    
    {
        ["name"] = "buildings/defense/ai_hub",
        ["storages"] = {

            ["ai"] = "8",
        },
    },
    
    {
        ["name"] = "buildings/defense/ai_hub_lvl_2",
        ["storages"] = {

            ["ai"] = "16",
        },
    },
    
    {
        ["name"] = "buildings/defense/ai_hub_lvl_3",
        ["storages"] = {

            ["ai"] = "32",
        },
    },


    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant",
        ["storages"] = {

            ["energy"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "600",
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "800",
        },
    },


    
    {
        ["name"] = "buildings/energy/nuclear_powerplant",
        ["storages"] = {

            ["energy"] = "6000",
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "9000",
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "12000",
        },
    },


    
    {
        ["name"] = "buildings/energy/morphium_powerplant",
        ["storages"] = {

            ["energy"] = "2000",
        },
    },
    
    {
        ["name"] = "buildings/energy/morphium_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "3000",
        },
    },
    
    {
        ["name"] = "buildings/energy/morphium_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "4000",
        },
    },


    
    {
        ["name"] = "buildings/energy/magma_powerplant",
        ["storages"] = {

            ["energy"] = "2000",
        },
    },
    
    {
        ["name"] = "buildings/energy/magma_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "3000",
        },
    },
    
    {
        ["name"] = "buildings/energy/magma_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "4000",
        },
    },


    
    {
        ["name"] = "buildings/energy/geothermal_powerplant",
        ["storages"] = {

            ["energy"] = "800",
            ["mud"] = "1600",
        },
    },
    
    {
        ["name"] = "buildings/energy/geothermal_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "1600",
            ["mud"] = "2400",
        },
    },
    
    {
        ["name"] = "buildings/energy/geothermal_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "3200",
            ["mud"] = "3200",
        },
    },


    
    {
        ["name"] = "buildings/energy/gas_powerplant",
        ["storages"] = {

            ["energy"] = "2000",
        },
    },
    
    {
        ["name"] = "buildings/energy/gas_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "3000",
        },
    },
    
    {
        ["name"] = "buildings/energy/gas_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "4000",
        },
    },


    
    {
        ["name"] = "buildings/energy/fusion_powerplant",
        ["storages"] = {

            ["energy"] = "14000",
            ["plasma"] = "1600",
        },
    },
    
    {
        ["name"] = "buildings/energy/fusion_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "20000",
            ["plasma"] = "2400",
        },
    },
    
    {
        ["name"] = "buildings/energy/fusion_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "28000",
            ["plasma"] = "3200",
        },
    },


    
    {
        ["name"] = "buildings/energy/energy_storage",
        ["storages"] = {

            ["energy"] = "40000",
        },
    },
    
    {
        ["name"] = "buildings/energy/energy_storage_lvl_2",
        ["storages"] = {

            ["energy"] = "80000",
        },
    },
    
    {
        ["name"] = "buildings/energy/energy_storage_lvl_3",
        ["storages"] = {

            ["energy"] = "160000",
        },
    },


    
    {
        ["name"] = "buildings/energy/carbonium_powerplant",
        ["storages"] = {

            ["energy"] = "240",
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "480",
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "960",
        },
    },


    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant",
        ["storages"] = {

            ["energy"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_2",
        ["storages"] = {

            ["energy"] = "1200",
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_3",
        ["storages"] = {

            ["energy"] = "1600",
        },
    },


    
    {
        ["name"] = "buildings/resources/bio_condenser",
        ["storages"] = {

            ["sludge"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_condenser_lvl_2",
        ["storages"] = {

            ["sludge"] = "1600",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_condenser_lvl_3",
        ["storages"] = {

            ["sludge"] = "2400",
        },
    },


    
    {
        ["name"] = "buildings/resources/ammunition_storage",
        ["groups"] = {

            ["9"] = "4", -- ammo_mech
            ["10"] = "4", -- ammo_tower
        },
    },
    
    {
        ["name"] = "buildings/resources/ammunition_storage_lvl_2",
        ["groups"] = {

            ["9"] = "8", -- ammo_mech
            ["10"] = "8", -- ammo_tower
        },
    },
    
    {
        ["name"] = "buildings/resources/ammunition_storage_lvl_3",
        ["groups"] = {

            ["9"] = "16", -- ammo_mech
            ["10"] = "16", -- ammo_tower
        },
    },


    
    {
        ["name"] = "buildings/resources/bio_composter",
        ["storages"] = {

            ["flammable_gas"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_2",
        ["storages"] = {

            ["flammable_gas"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_3",
        ["storages"] = {

            ["flammable_gas"] = "1200",
        },
    },


    
    {
        ["name"] = "buildings/resources/gas_extractor",
        ["storages"] = {

            ["flammable_gas"] = "1200",
        },
    },
    
    {
        ["name"] = "buildings/resources/gas_extractor_lvl_2",
        ["storages"] = {

            ["flammable_gas"] = "1200",
        },
    },
    
    {
        ["name"] = "buildings/resources/gas_extractor_lvl_3",
        ["storages"] = {

            ["flammable_gas"] = "1200",
        },
    },


    
    {
        ["name"] = "buildings/resources/gas_filtering_plant",
        ["storages"] = {

            ["flammable_gas"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/resources/gas_filtering_plant_lvl_2",
        ["storages"] = {

            ["flammable_gas"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/gas_filtering_plant_lvl_3",
        ["storages"] = {

            ["flammable_gas"] = "1200",
        },
    },


    
    {
        ["name"] = "buildings/resources/ionizer",
        ["storages"] = {

            ["plasma"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_2",
        ["storages"] = {

            ["plasma"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_3",
        ["storages"] = {

            ["plasma"] = "1600",
        },
    },


    
    {
        ["name"] = "buildings/resources/plasma_converter",
        ["storages"] = {

            ["plasma_charged"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/resources/plasma_converter_lvl_2",
        ["storages"] = {

            ["plasma_charged"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/plasma_converter_lvl_3",
        ["storages"] = {

            ["plasma_charged"] = "1200",
        },
    },


    
    {
        ["name"] = "buildings/resources/supercoolant_refinery",
        ["storages"] = {

            ["supercoolant"] = "400",
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_2",
        ["storages"] = {

            ["supercoolant"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_3",
        ["storages"] = {

            ["supercoolant"] = "1600",
        },
    },


    
    {
        ["name"] = "buildings/resources/water_filtering_plant",
        ["storages"] = {

            ["water"] = "800",
        },
    },
    
    {
        ["name"] = "buildings/resources/water_filtering_plant_lvl_2",
        ["storages"] = {

            ["water"] = "1200",
        },
    },
    
    {
        ["name"] = "buildings/resources/water_filtering_plant_lvl_3",
        ["storages"] = {

            ["water"] = "1600",
        },
    },


    
    {
        ["name"] = "buildings/resources/liquid_decompressor",
        ["groups"] = {

            ["1"] = "200", -- local
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_decompressor_lvl_2",
        ["groups"] = {

            ["1"] = "600", -- local
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_decompressor_lvl_3",
        ["groups"] = {

            ["1"] = "800", -- local
        },
    },


    
    {
        ["name"] = "buildings/resources/liquid_material_storage",
        ["groups"] = {

            ["1"] = "12000", -- local
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_material_storage_lvl_2",
        ["groups"] = {

            ["1"] = "18000", -- local
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_material_storage_lvl_3",
        ["groups"] = {

            ["1"] = "24000", -- local
        },
    },


    
    {
        ["name"] = "buildings/resources/pipe_junction",
        ["groups"] = {

            ["1"] = "100", -- local
        },
    },


    
    {
        ["name"] = "buildings/resources/solid_material_storage",
        ["groups"] = {

            ["0"] = "800", -- global
        },
    },
    
    {
        ["name"] = "buildings/resources/solid_material_storage_lvl_2",
        ["groups"] = {

            ["0"] = "1600", -- global
        },
    },
    
    {
        ["name"] = "buildings/resources/solid_material_storage_lvl_3",
        ["groups"] = {

            ["0"] = "3200", -- global
        },
    },
}

InjectChangeListBlueprintStorageValues(new_storage_values)