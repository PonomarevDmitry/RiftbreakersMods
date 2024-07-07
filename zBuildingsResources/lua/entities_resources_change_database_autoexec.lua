require("lua/utils/reflection.lua")

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
        ["name"] = "buildings/resources/drone_mine_lvl_2",
        ["floats"] = {

            ["drone_harvest_factor"] = 2.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 3,
        },
    },

    {
        ["name"] = "buildings/resources/drone_mine_lvl_3",
        ["floats"] = {

            ["drone_harvest_factor"] = 4.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 9,
        },
    },

    {
        ["name"] = "buildings/resources/flora_collector",
        ["floats"] = {

            ["drone_harvest_factor"] = 1.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 10,
            ["drone_visible_on_spot"] = 0,
        },
    },

    {
        ["name"] = "buildings/resources/flora_collector_lvl_2",
        ["floats"] = {

            ["drone_harvest_factor"] = 2.0,
            ["drone_search_radius"] = 30.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 15,
            ["drone_visible_on_spot"] = 0,
        },
    },

    {
        ["name"] = "buildings/resources/flora_collector_lvl_3",
        ["floats"] = {

            ["drone_harvest_factor"] = 4.0,
            ["drone_search_radius"] = 35.0,
        },
        ["ints"] = {

            ["drone_per_spot"] = 20,
            ["drone_visible_on_spot"] = 0,
        },
    },
}

InjectChangeResourceBuildingBlueprintDatabaseComponent(supported_item_blueprints)
