------ #warning Commented Local ------
do return end

require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local InjectChangeBlueprintDistributionRadiusValues = function(blueprintName, newDistributionRadius)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local resourceStorageComponent = blueprint:GetComponent("ResourceStorageComponent")
    if ( resourceStorageComponent == nil ) then
        LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' ResourceStorageComponent NOT EXISTS.")
        return
    end

    local storagesArray = resourceStorageComponent:GetField("Storages"):ToContainer()
    if ( storagesArray == nil ) then
        LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' resourceStorageComponent:GetField('Storages'):ToContainer() NOT EXISTS.")
        return
    end
        
    for i=0,storagesArray:GetItemCount()-1 do

        local storageObject = storagesArray:GetItem(i)
            
        if ( storageObject == nil ) then
            LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' storageObject == nil")

            goto continue
        end

        local storageObjectRef = reflection_helper(storageObject)

        local groupId = storageObjectRef.group

        --LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' groupId = " .. tostring(groupId))

        if ( groupId == 12 ) then

            if ( storageObjectRef.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint 'player/player' storageObjectRef.resource == nil")

                goto continue
            end

            if ( storageObjectRef.resource.resource == nil ) then
                --LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint 'player/player' storageObjectRef.resource.resource == nil")

                goto continue
            end

            local resourceId = storageObjectRef.resource.resource.id

            --LogService:Log("InjectChangeBlueprintDistributionRadiusValues Blueprint '" .. blueprintName .. "' resourceId  = " .. tostring(resourceId) .. " groupId = " .. tostring(groupId))

            if ( resourceId ~= nil and resourceId ~= "" and resourceId == "energy" ) then

                storageObject:GetField("distribution_radius"):SetValue(newDistributionRadius)
            end
        end

        ::continue::
    end
end

local InjectChangeListBlueprintDistributionRadiusValues = function(blueprintStorageList)

    for _, blueprintName in ipairs(blueprintStorageList) do

        InjectChangeBlueprintDistributionRadiusValues(blueprintName, "10")
    end
end

local new_storage_list = {

    "buildings/decorations/base_lamp",
    "buildings/decorations/base_lamp_blue",
    "buildings/decorations/base_lamp_cyan",
    "buildings/decorations/base_lamp_green",

    "buildings/decorations/base_lamp_orange",
    "buildings/decorations/base_lamp_red",
    "buildings/decorations/base_lamp_violet",
    "buildings/decorations/base_lamp_yellow",
    
    "buildings/decorations/crystal_lamp",
    "buildings/decorations/crystal_lamp_blue",
    "buildings/decorations/crystal_lamp_cyan",
    "buildings/decorations/crystal_lamp_green",

    "buildings/decorations/crystal_lamp_orange",
    "buildings/decorations/crystal_lamp_red",
    "buildings/decorations/crystal_lamp_violet",
    "buildings/decorations/crystal_lamp_yellow",
}

InjectChangeListBlueprintDistributionRadiusValues(new_storage_list)