require("lua/utils/reflection.lua")

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

                blueprintDatabase:SetFloat(fieldName, tonumber( fieldValue ))
            end
        end

        if ( configObject.strings ) then

            for fieldName,fieldValue in pairs(configObject.strings) do

                blueprintDatabase:SetString(fieldName, tostring( fieldValue ))
            end
        end

        if ( configObject.ints ) then

            for fieldName,fieldValue in pairs(configObject.ints) do

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
