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
}

InjectChangeBlueprintInventoryItemComponentIcons(supported_item_blueprints)