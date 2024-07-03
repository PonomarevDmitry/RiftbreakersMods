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
}

InjectChangeListBlueprintStorageValues(new_storage_values)