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
        ["name"] = "items/skills/radar_pulse_item",
        ["floats"] = {

            ["radius"] = 200.0,
        },
    },

    {
        ["name"] = "items/skills/radar_pulse_advanced_item",
        ["floats"] = {

            ["radius"] = 250.0,
        },
    },

    {
        ["name"] = "items/skills/radar_pulse_superior_item",
        ["floats"] = {

            ["radius"] = 300.0,
        },
    },

    {
        ["name"] = "items/skills/radar_pulse_extreme_item",
        ["floats"] = {

            ["radius"] = 350.0,
        },
    },

    {
        ["name"] = "items/interactive/drill_item",
        ["floats"] = {

            ["amount"] = 5.0,
        },
    },
}

InjectChangeResourceBuildingBlueprintDatabaseComponent(supported_item_blueprints)
