local InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown = function(blueprintsList, cooldownValue)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")

        if inventoryItemComponent == nil then

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
            goto continue
        end
    
        inventoryItemComponent:GetField("cooldown"):SetValue(cooldownValue)

        ::continue::
    end
end

local supported_item_blueprints = {

    "items/skills/time_warp",

    "items/skills/invisibility_item",
    "items/skills/invisibility_short_item",

    "items/skills/teleport_item",
    "items/skills/teleport_short_item",

    "items/skills/dash_acid_item",
    "items/skills/dash_acid_advanced_item",
    "items/skills/dash_acid_superior_item",
    "items/skills/dash_acid_extreme_item",

    "items/skills/dash_energy_item",
    "items/skills/dash_energy_advanced_item",
    "items/skills/dash_energy_superior_item",
    "items/skills/dash_energy_extreme_item",

    "items/skills/dash_fire_item",
    "items/skills/dash_fire_advanced_item",
    "items/skills/dash_fire_superior_item",
    "items/skills/dash_fire_extreme_item",

    "items/skills/dash_cryo_item",
    "items/skills/dash_cryo_advanced_item",
    "items/skills/dash_cryo_superior_item",
    "items/skills/dash_cryo_extreme_item",



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

InjectChangeBlueprintInventoryItemComponentCooldown(supported_item_blueprints, "0.5")
