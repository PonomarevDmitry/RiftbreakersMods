local InjectChangeMovingSkillBlueprintInventoryItemComponentSubtype = function(blueprintsList, subtypeValue)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentSubtype Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
        if ( inventoryItemComponent ~= nil ) then

            inventoryItemComponent:GetField("subtype"):SetValue(subtypeValue)
        else

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentSubtype Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
        end

        ::continue::
    end
end

local supported_item_blueprints = {

    "items/skills/teleport_item",
    "items/skills/teleport_short_item",
}

InjectChangeMovingSkillBlueprintInventoryItemComponentSubtype(supported_item_blueprints, "teleport")
