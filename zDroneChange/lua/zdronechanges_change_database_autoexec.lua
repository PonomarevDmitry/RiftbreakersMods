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
        ["name"] = "units/drones/drone_resource_collector",
        ["floats"] = {

            ["harvest_storage"] = 450.0,
        },
    },

    {
        ["name"] = "units/drones/drone_flora_collector",
        ["floats"] = {

            ["harvest_storage"] = 450.0,
        },
    },



    {
        ["name"] = "items/upgrades/scanner_equipment_advanced_item",
        ["ints"] = {

            ["drone_count"] = 2,
        },
    },

    {
        ["name"] = "items/upgrades/scanner_equipment_superior_item",
        ["ints"] = {

            ["drone_count"] = 4,
        },
    },

    {
        ["name"] = "items/upgrades/scanner_equipment_extreme_item",
        ["ints"] = {

            ["drone_count"] = 8,
        },
    },



    {
        ["name"] = "items/upgrades/detector_equipment_advanced_item",
        ["ints"] = {

            ["drone_count"] = 2,
        },
    },

    {
        ["name"] = "items/upgrades/detector_equipment_superior_item",
        ["ints"] = {

            ["drone_count"] = 3,
        },
    },

    {
        ["name"] = "items/upgrades/detector_equipment_extreme_item",
        ["ints"] = {

            ["drone_count"] = 4,
        },
    },
}

InjectChangeResourceBuildingBlueprintDatabaseComponent(supported_item_blueprints)
