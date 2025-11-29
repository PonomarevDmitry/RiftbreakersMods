require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeResourceBuildingBlueprintDatabaseComponent = function(blueprintsList)

    for _,configObject in ipairs(blueprintsList) do

        local blueprintName = configObject.name

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then

            LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local databaseComponent = blueprint:GetComponent("DatabaseComponent")
        if ( databaseComponent == nil ) then

            LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " DatabaseComponent NOT EXISTS.")
            goto continue
        end
    
        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
        if ( blueprintDatabase == nil ) then

            LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase NOT EXISTS.")
            goto continue
        end

        if ( configObject.floats ) then

            for fieldName,fieldValue in pairs(configObject.floats) do

                if ( not blueprintDatabase:HasFloat(fieldName) ) then

                    LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Float '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetFloat(fieldName, tonumber( fieldValue ))
            end
        end

        if ( configObject.strings ) then

            for fieldName,fieldValue in pairs(configObject.strings) do

                if ( not blueprintDatabase:HasString(fieldName) ) then

                    LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase String '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetString(fieldName, tostring( fieldValue ))
            end
        end

        if ( configObject.ints ) then

            for fieldName,fieldValue in pairs(configObject.ints) do

                if ( not blueprintDatabase:HasInt(fieldName) ) then

                    LogService:Log("InjectChangeResourceBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Int '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetInt(fieldName, tonumber( fieldValue ))
            end
        end

        ::continue::
    end
end

local supported_item_blueprints = {

    {
        ["name"] = "items/skills/dodge_roll_item",
        ["floats"] = {

            ["roll_cooldown"] = 0.5,
        },
    },

    {
        ["name"] = "items/skills/dodge_roll_advanced_item",
        ["floats"] = {

            ["roll_cooldown"] = 0.5,
        },
    },

    {
        ["name"] = "items/skills/dodge_roll_superior_item",
        ["floats"] = {

            ["roll_cooldown"] = 0.5,
        },
    },

    {
        ["name"] = "items/skills/dodge_roll_extreme_item",
        ["floats"] = {

            ["roll_cooldown"] = 0.5,
        },
    },
}

InjectChangeResourceBuildingBlueprintDatabaseComponent(supported_item_blueprints)





local supported_item_blueprintsDict = {}

for _,configObject in ipairs(supported_item_blueprints) do

    local blueprintName = configObject.name

    supported_item_blueprintsDict[blueprintName] = configObject
end



RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID) then
        return
    end

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local entityBlueprintName = EntityService:GetBlueprintName(entity)
    if ( supported_item_blueprintsDict[entityBlueprintName] == nil ) then
        return
    end

    local configObject = supported_item_blueprintsDict[entityBlueprintName]

    local databaseEntity = EntityService:GetOrCreateDatabase( entity )
    if ( databaseEntity == nil ) then
        return
    end

    if ( configObject.floats ) then

        for fieldName,fieldValue in pairs(configObject.floats) do

            databaseEntity:SetFloat(fieldName, tonumber( fieldValue ))
        end
    end

    if ( configObject.strings ) then

        for fieldName,fieldValue in pairs(configObject.strings) do

            databaseEntity:SetString(fieldName, tostring( fieldValue ))
        end
    end

    if ( configObject.ints ) then

        for fieldName,fieldValue in pairs(configObject.ints) do

            databaseEntity:SetInt(fieldName, tonumber( fieldValue ))
        end
    end
end)