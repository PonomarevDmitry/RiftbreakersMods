------ #warning Commented Local ------
do return end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeBlueprintMinimapItemComponentIcons = function(blueprintsList)

    for _,configObj in ipairs(blueprintsList) do

        local icon = configObj.icon
        local biggerIcon = configObj.bigger_icon

        local list = configObj.list

        for _,blueprintName in ipairs(list) do

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint == nil ) then

                LogService:Log("InjectChangeBlueprintMinimapItemComponentIcons Blueprint " .. blueprintName .. " NOT EXISTS.")
                goto continue
            end

            local minimapItemComponent = blueprint:GetComponent("MinimapItemComponent")
            if ( minimapItemComponent == nil ) then
                
                LogService:Log("InjectChangeBlueprintMinimapItemComponentIcons Blueprint " .. blueprintName .. " MinimapItemComponent NOT EXISTS.")
                goto continue
            end
    
            minimapItemComponent:GetField("icon_material"):SetValue(icon)
            minimapItemComponent:GetField("type"):SetValue("1")
            minimapItemComponent:GetField("big_minimap_scale"):SetValue("2")

            local minimapItemComponentRef = reflection_helper(minimapItemComponent)

            minimapItemComponentRef.color.x = 0
            minimapItemComponentRef.color.y = 0
            minimapItemComponentRef.color.z = 0
            minimapItemComponentRef.color.w = 0

            minimapItemComponentRef.size.x = 0.5
            minimapItemComponentRef.size.y = 0.5

            --LogService:Log("InjectChangeBlueprintMinimapItemComponentIcons Blueprint " .. blueprintName .. " minimapItemComponentRef " .. tostring(minimapItemComponentRef))

            ::continue::
        end
    end
end

local supported_item_blueprints = {

    {
        ["icon"] = "gui/hud/minimap_icons/mining_carbonium",
        ["list"] = {

            "buildings/resources/carbonium_factory",
        },
    },

    {
        ["icon"] = "gui/hud/minimap_icons/mining_ironium",
        ["list"] = {

            "buildings/resources/steel_factory",
        },
    },

    {
        ["icon"] = "gui/hud/minimap_icons/mining_rare",
        ["list"] = {
    
            "buildings/resources/rare_element_mine",
        },
    },
}

InjectChangeBlueprintMinimapItemComponentIcons(supported_item_blueprints)