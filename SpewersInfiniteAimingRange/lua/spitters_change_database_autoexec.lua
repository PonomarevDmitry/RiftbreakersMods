require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local supported_item_blueprints = {

    {
        ["name"] = "items/weapons/acid_spitter_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/acid_spitter_advanced_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/acid_spitter_superior_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/acid_spitter_extreme_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },



    {
        ["name"] = "items/weapons/cryo_spitter_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/cryo_spitter_advanced_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/cryo_spitter_superior_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/cryo_spitter_extreme_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },



    {
        ["name"] = "items/weapons/fire_spitter_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/fire_spitter_advanced_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/fire_spitter_superior_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },

    {
        ["name"] = "items/weapons/fire_spitter_extreme_item",
        ["floats"] = {

            ["aim_max_distance"] = 0.0,
        },
    },
}

local InjectChangeSpitterBlueprintDatabaseComponent = function(blueprintsList)

    for _,configObject in ipairs(blueprintsList) do

        local blueprintName = configObject.name

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then

            LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local databaseComponent = blueprint:GetComponent("DatabaseComponent")
        if ( databaseComponent == nil ) then

            LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " DatabaseComponent NOT EXISTS.")
            goto continue
        end
    
        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
        if ( blueprintDatabase == nil ) then

            LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase NOT EXISTS.")
            goto continue
        end

        if ( configObject.floats ) then

            for fieldName,fieldValue in pairs(configObject.floats) do

                if ( not blueprintDatabase:HasFloat(fieldName) ) then

                    LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Float '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetFloat(fieldName, tonumber( fieldValue ))
            end
        end

        if ( configObject.strings ) then

            for fieldName,fieldValue in pairs(configObject.strings) do

                if ( not blueprintDatabase:HasString(fieldName) ) then

                    LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase String '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetString(fieldName, tostring( fieldValue ))
            end
        end

        if ( configObject.ints ) then

            for fieldName,fieldValue in pairs(configObject.ints) do

                if ( not blueprintDatabase:HasInt(fieldName) ) then

                    LogService:Log("InjectChangeSpitterBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Int '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetInt(fieldName, tonumber( fieldValue ))
            end
        end

        ::continue::
    end
end

InjectChangeSpitterBlueprintDatabaseComponent(supported_item_blueprints)





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

    local databaseEntity = EntityService:GetDatabase( entity )
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