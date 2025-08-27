require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
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
}

InjectChangeListBlueprintStorageValues(new_storage_values)