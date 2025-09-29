require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeDefenseBuildingBlueprintDatabaseComponent = function(blueprintsList)

    for _,configObject in ipairs(blueprintsList) do

        local blueprintName = configObject.name

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then

            LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local databaseComponent = blueprint:GetComponent("DatabaseComponent")
        if ( databaseComponent == nil ) then

            LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " DatabaseComponent NOT EXISTS.")
            goto continue
        end
    
        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
        if ( blueprintDatabase == nil ) then

            LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase NOT EXISTS.")
            goto continue
        end

        if ( configObject.floats ) then

            for fieldName,fieldValue in pairs(configObject.floats) do

                if ( not blueprintDatabase:HasFloat(fieldName) ) then

                    LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Float '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetFloat(fieldName, tonumber( fieldValue ))
            end
        end

        if ( configObject.strings ) then

            for fieldName,fieldValue in pairs(configObject.strings) do

                if ( not blueprintDatabase:HasString(fieldName) ) then

                    LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase String '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetString(fieldName, tostring( fieldValue ))
            end
        end

        if ( configObject.ints ) then

            for fieldName,fieldValue in pairs(configObject.ints) do

                if ( not blueprintDatabase:HasInt(fieldName) ) then

                    LogService:Log("InjectChangeDefenseBuildingBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Int '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetInt(fieldName, tonumber( fieldValue ))
            end
        end

        ::continue::
    end
end

local supported_item_blueprints = {

    {
        ["name"] = "buildings/defense/short_range_radar_lvl_2",
        ["floats"] = {

            ["range"] = 240.0,
        },
    },

    {
        ["name"] = "buildings/defense/short_range_radar_lvl_3",
        ["floats"] = {

            ["range"] = 320.0,
        },
    },

    {
        ["name"] = "buildings/defense/repair_facility",
        ["ints"] = {

            ["drone_per_spot"] = 10,
        },
    },

    {
        ["name"] = "buildings/defense/repair_facility_lvl_2",
        ["floats"] = {

            ["drone_search_radius"] = 35.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 30,
        },
    },

    {
        ["name"] = "buildings/defense/repair_facility_lvl_3",
        ["floats"] = {

            ["drone_search_radius"] = 45.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 50,
        },
    },
}

InjectChangeDefenseBuildingBlueprintDatabaseComponent(supported_item_blueprints)





local InjectChangeDefenseBuildingGhostValues = function(blueprintName, rangeMax)

    blueprintName = blueprintName .. "_ghost"

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local displayRadiusComponent = blueprint:GetComponent("DisplayRadiusComponent")
    if ( displayRadiusComponent == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' DisplayRadiusComponent NOT EXISTS.")
        return
    end

    local max_radiusField = displayRadiusComponent:GetField("max_radius")
    if ( max_radiusField == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' displayRadiusComponent:GetField('max_radius') NOT EXISTS.")
        return
    end

    max_radiusField:SetValue(rangeMax)
end

local new_ghost_values = {

    {
        ["name"] = "buildings/defense/short_range_radar_lvl_2",
        ["range_max"] = "240",
    },

    {
        ["name"] = "buildings/defense/short_range_radar_lvl_3",
        ["range_max"] = "320",
    },

    {
        ["name"] = "buildings/defense/repair_facility_lvl_2",
        ["range_max"] = "35",
    },

    {
        ["name"] = "buildings/defense/repair_facility_lvl_3",
        ["range_max"] = "45",
    },
}

local InjectChangeListDefenseBuildingValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeDefenseBuildingGhostValues(configObject.name, configObject.range_max)
    end
end

InjectChangeListDefenseBuildingValues(new_ghost_values)
