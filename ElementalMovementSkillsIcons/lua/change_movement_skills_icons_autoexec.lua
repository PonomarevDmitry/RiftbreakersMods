local InjectChangeBlueprintInventoryItemComponentIcons = function(blueprintsList)

    for _,configObj in ipairs(blueprintsList) do

        local icon = configObj.icon
        local biggerIcon = configObj.bigger_icon

        local list = configObj.list

        for _,blueprintName in ipairs(list) do

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint == nil ) then

                LogService:Log("InjectChangeBlueprintInventoryItemComponentIcons Blueprint " .. blueprintName .. " NOT EXISTS.")
                goto continue
            end

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
            if inventoryItemComponent == nil then
                
                LogService:Log("InjectChangeBlueprintInventoryItemComponentIcons Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
                goto continue
            end
    
            inventoryItemComponent:GetField("icon"):SetValue(icon)
            inventoryItemComponent:GetField("bigger_icon"):SetValue(biggerIcon)

            ::continue::
        end
    end
end

local supported_item_blueprints = {

    {
        ["icon"] = "gui/hud/items_icons/skills/invisibility",
        ["bigger_icon"] = "gui/menu/items_icons/skills/invisibility",
        ["list"] = {

            "items/skills/invisibility_short_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/teleport",
        ["bigger_icon"] = "gui/menu/items_icons/skills/teleport",
        ["list"] = {

            "items/skills/teleport_item",
            "items/skills/teleport_short_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/dodge_roll",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dodge_roll",
        ["list"] = {

            "items/skills/dodge_roll_item",
        },
    },




    {
        ["icon"] = "gui/hud/items_icons/skills/dash_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_acid",
        ["list"] = {

            "items/skills/dash_acid_item",
            "items/skills/dash_acid_advanced_item",
            "items/skills/dash_acid_superior_item",
            "items/skills/dash_acid_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/dash_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_energy",
        ["list"] = {

            "items/skills/dash_energy_item",
            "items/skills/dash_energy_advanced_item",
            "items/skills/dash_energy_superior_item",
            "items/skills/dash_energy_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/dash_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_fire",
        ["list"] = {

            "items/skills/dash_fire_item",
            "items/skills/dash_fire_advanced_item",
            "items/skills/dash_fire_superior_item",
            "items/skills/dash_fire_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/dash_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_cryo",
        ["list"] = {

            "items/skills/dash_cryo_item",
            "items/skills/dash_cryo_advanced_item",
            "items/skills/dash_cryo_superior_item",
            "items/skills/dash_cryo_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/jump_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_acid",
        ["list"] = {

            "items/skills/jump_acid_item",
            "items/skills/jump_acid_advanced_item",
            "items/skills/jump_acid_superior_item",
            "items/skills/jump_acid_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/jump_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_energy",
        ["list"] = {

            "items/skills/jump_energy_item",
            "items/skills/jump_energy_advanced_item",
            "items/skills/jump_energy_superior_item",
            "items/skills/jump_energy_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/jump_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_fire",
        ["list"] = {

            "items/skills/jump_fire_item",
            "items/skills/jump_fire_advanced_item",
            "items/skills/jump_fire_superior_item",
            "items/skills/jump_fire_extreme_item",
        },
    },

    {
        ["icon"] = "gui/hud/items_icons/skills/jump_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_cryo",
        ["list"] = {

            "items/skills/jump_cryo_item",
            "items/skills/jump_cryo_advanced_item",
            "items/skills/jump_cryo_superior_item",
            "items/skills/jump_cryo_extreme_item",
        },
    },
}

InjectChangeBlueprintInventoryItemComponentIcons(supported_item_blueprints)