require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local supported_item_hashs = {

    ["items/skills/dash_acid_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_acid",
    },

    ["items/skills/dash_acid_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_acid",
    },

    ["items/skills/dash_acid_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_acid",
    },

    ["items/skills/dash_acid_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_acid",
    },



    

    ["items/skills/dash_energy_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_energy",
    },

    ["items/skills/dash_energy_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_energy",
    },

    ["items/skills/dash_energy_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_energy",
    },

    ["items/skills/dash_energy_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_energy",
    },





    ["items/skills/dash_fire_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_fire",
    },

    ["items/skills/dash_fire_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_fire",
    },

    ["items/skills/dash_fire_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_fire",
    },

    ["items/skills/dash_fire_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_fire",
    },





    ["items/skills/dash_cryo_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_cryo",
    },

    ["items/skills/dash_cryo_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_cryo",
    },

    ["items/skills/dash_cryo_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_cryo",
    },

    ["items/skills/dash_cryo_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/dash_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/dash_cryo",
    },





    ["items/skills/jump_acid_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_acid",
    },

    ["items/skills/jump_acid_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_acid",
    },

    ["items/skills/jump_acid_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_acid",
    },

    ["items/skills/jump_acid_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_acid",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_acid",
    },





    ["items/skills/jump_energy_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_energy",
    },

    ["items/skills/jump_energy_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_energy",
    },

    ["items/skills/jump_energy_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_energy",
    },

    ["items/skills/jump_energy_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_energy",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_energy",
    },





    ["items/skills/jump_fire_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_fire",
    },

    ["items/skills/jump_fire_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_fire",
    },

    ["items/skills/jump_fire_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_fire",
    },

    ["items/skills/jump_fire_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_fire",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_fire",
    },





    ["items/skills/jump_cryo_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_cryo",
    },

    ["items/skills/jump_cryo_advanced_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_cryo",
    },

    ["items/skills/jump_cryo_superior_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_cryo",
    },

    ["items/skills/jump_cryo_extreme_item"] = 
    {
        ["icon"] = "gui/hud/items_icons/skills/jump_cryo",
        ["bigger_icon"] = "gui/menu/items_icons/skills/jump_cryo",
    },
}

RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID) then
        return
    end

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local entityBlueprintName = EntityService:GetBlueprintName(entity)
    if ( supported_item_hashs[entityBlueprintName] == nil ) then
        return
    end

    local itemConfig = supported_item_hashs[entityBlueprintName]

    local inventoryItemComponent = EntityService:GetConstComponent( entity, "InventoryItemComponent" )
    if ( inventoryItemComponent ~= nil ) then

        local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )

        if ( inventoryItemComponentRef.icon ~= itemConfig.icon ) then
            inventoryItemComponentRef.icon = itemConfig.icon
        end

        if ( inventoryItemComponentRef.bigger_icon ~= itemConfig.bigger_icon ) then
            inventoryItemComponentRef.bigger_icon = itemConfig.bigger_icon
        end
    end
end)
