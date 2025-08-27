require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeMovingSkillBlueprintJumpDatabaseComponent = function(blueprintsList, newDatabaseValues)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintJumpDatabaseComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local databaseComponent = blueprint:GetComponent("DatabaseComponent")
        if ( databaseComponent == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintJumpDatabaseComponent Blueprint " .. blueprintName .. " DatabaseComponent NOT EXISTS.")
            goto continue
        end
    
        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )
        if ( blueprintDatabase == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintJumpDatabaseComponent Blueprint " .. blueprintName .. " blueprintDatabase NOT EXISTS.")
            goto continue
        end

        for fieldName,fieldValue in pairs(newDatabaseValues) do

            blueprintDatabase:SetFloat(fieldName, fieldValue)
        end

        ::continue::
    end
end

local new_database_values = {

    ["jump_speed"] = 5,

    ["jump_distance"] = 75,

    ["max_height"] = 40,

    ["min_distance"] = 0.25,
}

local supported_item_blueprints = {

    "items/skills/jump_splash_standard_item",
    "items/skills/jump_splash_advanced_item",
    "items/skills/jump_splash_superior_item",
    "items/skills/jump_splash_extreme_item",

    "items/skills/jump_acid_item",
    "items/skills/jump_acid_advanced_item",
    "items/skills/jump_acid_superior_item",
    "items/skills/jump_acid_extreme_item",

    "items/skills/jump_energy_item",
    "items/skills/jump_energy_advanced_item",
    "items/skills/jump_energy_superior_item",
    "items/skills/jump_energy_extreme_item",

    "items/skills/jump_fire_item",
    "items/skills/jump_fire_advanced_item",
    "items/skills/jump_fire_superior_item",
    "items/skills/jump_fire_extreme_item",

    "items/skills/jump_cryo_item",
    "items/skills/jump_cryo_advanced_item",
    "items/skills/jump_cryo_superior_item",
    "items/skills/jump_cryo_extreme_item",
}

InjectChangeMovingSkillBlueprintJumpDatabaseComponent(supported_item_blueprints, new_database_values)
