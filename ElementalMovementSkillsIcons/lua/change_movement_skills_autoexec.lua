require("lua/utils/reflection.lua")

RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local inventoryItemComponent = EntityService:GetConstComponent( entity, "InventoryItemComponent" )
    if ( inventoryItemComponent ~= nil ) then

        local itemName = ItemService:GetItemName(entity)

        local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )

        if ( itemName == "gui/menu/inventory/skill_name/dash_acid" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/dash_acid" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/dash_acid"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/dash_acid" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/dash_acid"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/dash_energy" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/dash_energy" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/dash_energy"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/dash_energy" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/dash_energy"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/dash_fire" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/dash_fire" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/dash_fire"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/dash_fire" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/dash_fire"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/dash_cryo" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/dash_cryo" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/dash_cryo"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/dash_cryo" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/dash_cryo"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/jump_acid" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/jump_acid" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/jump_acid"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/jump_acid" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/jump_acid"
            end
        elseif ( itemName == "gui/menu/inventory/skill_name/jump_energy" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/jump_energy" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/jump_energy"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/jump_energy" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/jump_energy"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/jump_fire" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/jump_fire" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/jump_fire"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/jump_fire" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/jump_fire"
            end

        elseif ( itemName == "gui/menu/inventory/skill_name/jump_cryo" ) then

            if ( inventoryItemComponentRef.icon ~= "gui/hud/items_icons/skills/jump_cryo" ) then
                inventoryItemComponentRef.icon = "gui/hud/items_icons/skills/jump_cryo"
            end

            if ( inventoryItemComponentRef.bigger_icon ~= "gui/menu/items_icons/skills/jump_cryo" ) then
                inventoryItemComponentRef.bigger_icon = "gui/menu/items_icons/skills/jump_cryo"
            end
        end
    end
end)
