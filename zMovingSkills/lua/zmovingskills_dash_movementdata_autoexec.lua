require("lua/utils/reflection.lua")

local InjectChangeMovingSkillBlueprintSpecialMovementDataComponent = function(blueprintsList)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintSpecialMovementDataComponent Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local specialMovementDataComponent = blueprint:GetComponent("SpecialMovementDataComponent")
        if specialMovementDataComponent == nil then

            LogService:Log("InjectChangeMovingSkillBlueprintSpecialMovementDataComponent Blueprint " .. blueprintName .. " SpecialMovementDataComponent NOT EXISTS.")
            goto continue
        end
    
        local specialMovementDataComponentRef = reflection_helper(specialMovementDataComponent)

        specialMovementDataComponentRef.max_speed.base = "75"
        specialMovementDataComponentRef.max_time = "0.5"

        --LogService:Log(tostring(specialMovementDataComponentRef))

        --specialMovementDataComponentRef.acceleration_function.points[1].y = "1000"

        --specialMovementDataComponentRef.acceleration_function.points[2].x = "0.6"
        --specialMovementDataComponentRef.acceleration_function.points[2].y = "1000"

        --specialMovementDataComponentRef.acceleration_function.points[3].x = "1"
        --specialMovementDataComponentRef.acceleration_function.points[3].y = "-1000"

        ::continue::
    end
end

local supported_item_blueprints = {

    "items/skills/dash_effects",

    "items/skills/dash_acid_effects",

    "items/skills/dash_energy_effects",

    "items/skills/dash_fire_effects",

    "items/skills/dash_cryo_effects",

    "items/skills/dodge_roll_effects",
}

InjectChangeMovingSkillBlueprintSpecialMovementDataComponent(supported_item_blueprints)
