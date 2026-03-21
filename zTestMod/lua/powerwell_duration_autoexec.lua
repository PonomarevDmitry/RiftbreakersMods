local InjectChangeBlueprintLifeTimeDescStorageLimit = function(blueprintsList, newLifeTimeValue)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint ~= nil ) then

            local lifeTimeDesc = blueprint:GetComponent("LifeTimeDesc")

            if lifeTimeDesc ~= nil then
    
                lifeTimeDesc:GetField("time"):SetValue(newLifeTimeValue)
            else
                
                LogService:Log("InjectChangeBlueprintLifeTimeDescStorageLimit Blueprint " .. blueprintName .. " LifeTimeDesc NOT EXISTS.")
            end
        else

            LogService:Log("InjectChangeBlueprintLifeTimeDescStorageLimit Blueprint " .. blueprintName .. " NOT EXISTS.")
        end
    end
end

local supported_item_blueprintsLimit = {

    "props/special/power_wells/power_well_all",
    "props/special/power_wells/power_well_health",
    "props/special/power_wells/power_well_forcefield",

    "props/special/power_wells/power_well_resist_all",
    "props/special/power_wells/power_well_resist_physical",
    "props/special/power_wells/power_well_resist_area",
    "props/special/power_wells/power_well_resist_fire",
    "props/special/power_wells/power_well_resist_cryo",
    "props/special/power_wells/power_well_resist_energy",
    "props/special/power_wells/power_well_resist_acid",

    "props/special/power_wells/power_well_cooldowns",
    "props/special/power_wells/power_well_speed",
    "props/special/power_wells/power_well_radar",
    "props/special/power_wells/power_well_building",
    "props/special/power_wells/power_well_loot",
    "props/special/power_wells/power_well_reflect_damage",
    "props/special/power_wells/power_well_drones",
    "props/special/power_wells/power_well_ammo",
    "props/special/power_wells/power_well_firerate",
    "props/special/power_wells/power_well_damage",
}

local newLifeTimeValue = "600"

InjectChangeBlueprintLifeTimeDescStorageLimit(supported_item_blueprintsLimit, newLifeTimeValue)





local InjectChangePowerWellBlueprintDatabaseComponent = function(blueprintsList)

    for _,configObject in ipairs(blueprintsList) do

        local blueprintName = configObject.name

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then

            LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local databaseComponent = blueprint:GetComponent("DatabaseComponent")
        if ( databaseComponent == nil ) then

            LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " DatabaseComponent NOT EXISTS.")
            goto continue
        end
    
        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
        if ( blueprintDatabase == nil ) then

            LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase NOT EXISTS.")
            goto continue
        end

        if ( configObject.floats ) then

            for fieldName,fieldValue in pairs(configObject.floats) do

                if ( not blueprintDatabase:HasFloat(fieldName) ) then

                    LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Float '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetFloat(fieldName, tonumber( fieldValue ))
            end
        end

        if ( configObject.strings ) then

            for fieldName,fieldValue in pairs(configObject.strings) do

                if ( not blueprintDatabase:HasString(fieldName) ) then

                    LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase String '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetString(fieldName, tostring( fieldValue ))
            end
        end

        if ( configObject.ints ) then

            for fieldName,fieldValue in pairs(configObject.ints) do

                if ( not blueprintDatabase:HasInt(fieldName) ) then

                    LogService:Log("InjectChangePowerWellBlueprintDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase Int '" .. fieldName .. "' NEW in blueprintDatabase.")
                end

                blueprintDatabase:SetInt(fieldName, tonumber( fieldValue ))
            end
        end

        ::continue::
    end
end

local supported_item_blueprints = {

    {
        ["name"] = "props/special/power_wells/power_well_all",
        ["floats"] = {

            ["drone_lifetime"] = 600.0,
        },
    },

    {
        ["name"] = "props/special/power_wells/power_well_drones",
        ["floats"] = {

            ["drone_lifetime"] = 600.0,
        },
    },
}

InjectChangePowerWellBlueprintDatabaseComponent(supported_item_blueprints)