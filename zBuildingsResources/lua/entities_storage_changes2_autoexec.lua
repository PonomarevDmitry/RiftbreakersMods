require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
--local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

globalChangedStorages = globalChangedStorages or {}
globalOriginalStorages = globalOriginalStorages or {}

local InjectChangeBlueprintStorageValues = function(blueprintName, configObj, newStorageGroupsValues)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end



    local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
    if ( blueprintDatabase ~= nil ) then
        if ( blueprintDatabase:HasInt("$entities_storage_changes2_autoexec") ) then
            return
        end

        blueprintDatabase:SetInt("$entities_storage_changes2_autoexec", 1)
    end
    
    if ( configObj.database_blueprint ~= nil ) then

        local blueprintDatabase = EntityService:GetBlueprintDatabase( configObj.database_blueprint )
        if ( blueprintDatabase ~= nil ) then

            --LogService:Log("InjectChangeBlueprintStorageValues blueprintDatabase EXISTS configObj.database_blueprint = '" .. configObj.database_blueprint)

            if ( blueprintDatabase:HasInt("$entities_storage_changes2_autoexec") ) then
                return
            end

            blueprintDatabase:SetInt("$entities_storage_changes2_autoexec", 1)
        end
    end
    

    local resourceStorageComponent = blueprint:GetComponent("ResourceStorageComponent")
    if ( resourceStorageComponent == nil ) then
        --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' ResourceStorageComponent NOT EXISTS.")
        return
    end

    local storagesArray = resourceStorageComponent:GetField("Storages"):ToContainer()
    if ( storagesArray == nil ) then
        --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceStorageComponent:GetField('Storages'):ToContainer() NOT EXISTS.")
        return
    end

    globalChangedStorages[blueprintName] = globalChangedStorages[blueprintName] or {}

    local hashGlobalChanges = globalChangedStorages[blueprintName]

    globalOriginalStorages[blueprintName] = globalOriginalStorages[blueprintName] or {}

    local hashGlobalOriginal = globalOriginalStorages[blueprintName]
        
    for i=0,storagesArray:GetItemCount()-1 do

        local storageObject = storagesArray:GetItem(i)
            
        if ( storageObject == nil ) then
            --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' storageObject == nil")

            goto labelContinue
        end

        local storageObjectRef = reflection_helper(storageObject)

        local groupId = storageObjectRef.group

        --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' groupId = " .. tostring(groupId))

        local maxField = storageObject:GetField("max")

        if ( groupId == 12 ) then

            if ( storageObjectRef.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource == nil")

                goto labelContinue
            end

            if ( storageObjectRef.resource.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint 'player/player' storageObjectRef.resource.resource == nil")

                goto labelContinue
            end

            local resourceId = storageObjectRef.resource.resource.id

            --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId  = " .. tostring(resourceId) .. " groupId = " .. tostring(groupId))

            if ( resourceId ~= nil and resourceId ~= "" ) then

                local resourceIdString = tostring(resourceId)

                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId ~= nil or resourceId ~= '' " .. resourceIdString)

                local cacheKey = resourceIdString

                if ( hashGlobalChanges[cacheKey] == nil ) then

                    local newValue = tonumber( maxField:GetValue() )

                    hashGlobalOriginal[cacheKey] = newValue

                    if ( resourceIdString == "energy" ) then

                        newValue = newValue * configObj.energy_coef
                    else

                        newValue = newValue * configObj.other_coef
                    end

                    hashGlobalChanges[cacheKey] = newValue
                end
                
                maxField:SetValue( tostring(hashGlobalChanges[cacheKey]) )

                --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId " .. resourceIdString .. " new Value " .. tostring(hashGlobalChanges[cacheKey]))

                goto labelContinue
            end
        else

            if ( groupId ~= nil and groupId ~= "" ) then

                local groupIdString = tostring(groupId)

                if ( configObj.group_coef and configObj.group_coef[groupIdString] ~= nil ) then

                    local cacheKey = "group_" .. groupIdString

                    if ( hashGlobalChanges[cacheKey] == nil ) then

                        local newValue = tonumber( maxField:GetValue() )

                        hashGlobalOriginal[cacheKey] = newValue

                        newValue = newValue * configObj.group_coef[groupIdString]

                        hashGlobalChanges[cacheKey] = newValue
                    end

                    --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' groupId " .. groupIdString .. " new Value " .. tostring(hashGlobalChanges[cacheKey]))
                
                    maxField:SetValue( tostring(hashGlobalChanges[cacheKey]) )
                end

                goto labelContinue
            end
        end

        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId == nil and groupId == ''\n" .. tostring(storageObjectRef))

        ::labelContinue::
    end
end

local InjectChangeListBlueprintStorageValues = function(blueprintStorageValues)

    globalOriginalStorages = globalOriginalStorages or {}
    globalChangedStorages = globalChangedStorages or {}

    for _,configObj in ipairs(blueprintStorageValues) do

        local list = configObj.list

        for _,blueprintName in ipairs(list) do

            InjectChangeBlueprintStorageValues(blueprintName, configObj)
        end
    end

    --LogService:Log("globalOriginalStorages " .. debug_serialize_utils:SerializeObject(globalOriginalStorages))

    --LogService:Log("globalChangedStorages " .. debug_serialize_utils:SerializeObject(globalChangedStorages))
end

local new_storage_values = {

    {
        ["energy_coef"] = 4,

        ["other_coef"] = 4,

        ["group_coef"] = {

            ["0"] = 4, -- global
            ["1"] = 4, -- local

            ["9"] = 4, -- ammo_mech
            ["10"] = 4, -- ammo_tower
        },

        ["list"] = {

            "buildings/main/headquarters",
            "buildings/main/outpost",

            "buildings/defense/ai_hub",
            "buildings/defense/ai_hub_lvl_2",
            "buildings/defense/ai_hub_lvl_3",

            "buildings/energy/plant_biomass_powerplant",
            "buildings/energy/plant_biomass_powerplant_lvl_2",
            "buildings/energy/plant_biomass_powerplant_lvl_3",

            "buildings/energy/nuclear_powerplant",
            "buildings/energy/nuclear_powerplant_lvl_2",
            "buildings/energy/nuclear_powerplant_lvl_3",

            "buildings/energy/morphium_powerplant",
            "buildings/energy/morphium_powerplant_lvl_2",
            "buildings/energy/morphium_powerplant_lvl_3",

            "buildings/energy/magma_powerplant",
            "buildings/energy/magma_powerplant_lvl_2",
            "buildings/energy/magma_powerplant_lvl_3",

            "buildings/energy/geothermal_powerplant",
            "buildings/energy/geothermal_powerplant_lvl_2",
            "buildings/energy/geothermal_powerplant_lvl_3",

            "buildings/energy/gas_powerplant",
            "buildings/energy/gas_powerplant_lvl_2",
            "buildings/energy/gas_powerplant_lvl_3",

            "buildings/energy/fusion_powerplant",
            "buildings/energy/fusion_powerplant_lvl_2",
            "buildings/energy/fusion_powerplant_lvl_3",

            "buildings/energy/energy_storage",
            "buildings/energy/energy_storage_lvl_2",
            "buildings/energy/energy_storage_lvl_3",

            "buildings/energy/large_energy_storage",
            "buildings/energy/large_energy_storage_lvl_2",
            "buildings/energy/large_energy_storage_lvl_3",

            "buildings/energy/animal_biomass_powerplant",
            "buildings/energy/animal_biomass_powerplant_lvl_2",
            "buildings/energy/animal_biomass_powerplant_lvl_3",

            "buildings/resources/bio_condenser",
            "buildings/resources/bio_condenser_lvl_2",
            "buildings/resources/bio_condenser_lvl_3",

            "buildings/resources/ammunition_storage",
            "buildings/resources/ammunition_storage_lvl_2",
            "buildings/resources/ammunition_storage_lvl_3",

            "buildings/resources/bio_composter",
            "buildings/resources/bio_composter_lvl_2",
            "buildings/resources/bio_composter_lvl_3",

            "buildings/resources/gas_extractor",
            "buildings/resources/gas_extractor_lvl_2",
            "buildings/resources/gas_extractor_lvl_3",

            "buildings/resources/gas_filtering_plant",
            "buildings/resources/gas_filtering_plant_lvl_2",
            "buildings/resources/gas_filtering_plant_lvl_3",

            "buildings/resources/ionizer",
            "buildings/resources/ionizer_lvl_2",
            "buildings/resources/ionizer_lvl_3",

            "buildings/resources/plasma_converter",
            "buildings/resources/plasma_converter_lvl_2",
            "buildings/resources/plasma_converter_lvl_3",

            "buildings/resources/supercoolant_refinery",
            "buildings/resources/supercoolant_refinery_lvl_2",
            "buildings/resources/supercoolant_refinery_lvl_3",

            "buildings/resources/water_filtering_plant",
            "buildings/resources/water_filtering_plant_lvl_2",
            "buildings/resources/water_filtering_plant_lvl_3",

            "buildings/resources/liquid_material_storage",
            "buildings/resources/liquid_material_storage_lvl_2",
            "buildings/resources/liquid_material_storage_lvl_3",

            "buildings/resources/pipe_junction",

            "buildings/resources/solid_material_storage",
            "buildings/resources/solid_material_storage_lvl_2",
            "buildings/resources/solid_material_storage_lvl_3",

            "buildings/resources/large_solid_material_storage",
            "buildings/resources/large_solid_material_storage_lvl_2",
            "buildings/resources/large_solid_material_storage_lvl_3",
        },
    },

    {
        ["database_blueprint"] = "player/character_base",

        ["energy_coef"] = 4,

        ["other_coef"] = 4,

        ["group_coef"] = {

            ["0"] = 4, -- global
            ["1"] = 4, -- local

            ["9"] = 4, -- ammo_mech
            ["10"] = 4, -- ammo_tower
        },

        ["list"] = {

            "player/player",
        },
    },
}

InjectChangeListBlueprintStorageValues(new_storage_values)

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    InjectChangeListBlueprintStorageValues(new_storage_values)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    InjectChangeListBlueprintStorageValues(new_storage_values)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    InjectChangeListBlueprintStorageValues(new_storage_values)
end)