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

                    newStorageValues[resourceIdString] = nil
                end

                goto continue
            end
        else

            if ( groupId ~= nil and groupId ~= "" ) then

                local groupIdString = tostring(groupId)

                if ( newStorageGroupsValues and newStorageGroupsValues[groupIdString] ~= nil ) then
                    --LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' newStorageGroupsValues[groupIdString] ~= nil " .. tostring(newStorageGroupsValues[groupIdString]))

                    storageObject:GetField("max"):SetValue(newStorageGroupsValues[groupIdString])

                    newStorageGroupsValues[groupIdString] = nil
                end

                goto continue
            end
        end

        LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resourceId == nil and groupId == ''\n" .. tostring(storageObjectRef))

        ::continue::
    end

    if ( newStorageValues ) then

        for resource, storageValue in pairs(newStorageValues) do

            local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resource)
            if ( resourceDef ~= nil ) then

                LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' resource " .. tostring(resource) .. " storageValue " .. tostring(storageValue))

                LogService:Log("InjectChangeBlueprintStorageValues resourceDef " .. tostring(reflection_helper(resourceDef)))

                local storageObject = storagesArray:CreateItem()

                LogService:Log("InjectChangeBlueprintStorageValues storageObject " .. tostring(reflection_helper(storageObject)))
                
                storageObject:GetField("group"):SetValue("12")
                storageObject:GetField("max"):SetValue(storageValue)

                local resourceResourceField = storageObject:GetField("resource"):GetField("resource")

                --rawset(resourceResourceField, "__ptr", resourceDef)

                resourceResourceField:SetValue(tostring(resourceDef))

                LogService:Log("InjectChangeBlueprintStorageValues changed storageObject " .. tostring(reflection_helper(storageObject)))
            end
        end
    end

    if ( newStorageGroupsValues ) then

        for group, storageValue in pairs(newStorageGroupsValues) do

            LogService:Log("InjectChangeBlueprintStorageValues Blueprint '" .. blueprintName .. "' group " .. tostring(group) .. " storageValue " .. tostring(storageValue))
            local storageObject = storagesArray:CreateItem()
                
            storageObject:GetField("group"):SetValue(group)
            storageObject:GetField("max"):SetValue(storageValue)
        end
    end
end

local InjectChangeListBlueprintStorageValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        --InjectChangeBlueprintStorageValues(configObject.name, configObject.storages, configObject.groups)
    end
end

local new_storage_values = {

    {
        ["name"] = "buildings/energy/energy_storage",
        ["storages"] = {

            ["voidinite_ore"] = "300",
            ["rift_energy"] = "100",

            ["crystal_dna"] = "4",
            ["ammo_mech_medium_caliber"] = "4",
            ["ammo_mech_acid_cells"] = "4",
            ["ammo_mech_cryo_cells"] = "4",
            ["ammo_mech_gravity_matrix"] = "4",
            ["ammo_mech_magma_cells"] = "4",

            ["ammo_mech_morphium_canister"] = "4",
            ["ammo_mech_plasma_cells"] = "4",
            ["ammo_mech_radio_cells"] = "4",
            ["ammo_mech_rift_charge"] = "4",
        },

        --["groups"] = {
        --
        --    ["9"] = "16", -- ammo_mech
        --    ["10"] = "16", -- ammo_tower
        --},
    },
}

InjectChangeListBlueprintStorageValues(new_storage_values)