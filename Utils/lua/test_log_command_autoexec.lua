require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

ConsoleService:RegisterCommand( "test_log_command", function( args )

    local list = {

        "items/weapons/floating_mines_acid_item",
        "items/weapons/floating_mines_acid_advanced_item",
        "items/weapons/floating_mines_acid_superior_item",
        "items/weapons/floating_mines_acid_extreme_item",

        "items/weapons/floating_mines_cryo_item",
        "items/weapons/floating_mines_cryo_advanced_item",
        "items/weapons/floating_mines_cryo_superior_item",
        "items/weapons/floating_mines_cryo_extreme_item",

        "items/weapons/floating_mines_gravity_item",
        "items/weapons/floating_mines_gravity_advanced_item",
        "items/weapons/floating_mines_gravity_superior_item",
        "items/weapons/floating_mines_gravity_extreme_item",

        "items/weapons/floating_mines_incendiary_item",
        "items/weapons/floating_mines_incendiary_advanced_item",
        "items/weapons/floating_mines_incendiary_superior_item",
        "items/weapons/floating_mines_incendiary_extreme_item",

        "items/weapons/floating_mines_item",
        "items/weapons/floating_mines_advanced_item",
        "items/weapons/floating_mines_superior_item",
        "items/weapons/floating_mines_extreme_item",
    }

    local componentName = "WeaponItemDesc"

    for i,blueprintName in ipairs(list) do

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

            LogService:Log("test_log_command EntityBlueprint NOT EXISTS " .. blueprintName )
            goto continue
        end

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        local component = blueprint:GetComponent(componentName)
        if ( component == nil ) then

            LogService:Log("test_log_command EntityBlueprint " .. blueprintName .. " componentName " .. componentName .. " NOT EXISTS" )
            goto continue
        end

        local componentRef = reflection_helper(component)

        LogService:Log("test_log_command " .. blueprintName .. " " .. componentName .. " " .. tostring(componentRef) )

        ::continue::
    end
end)