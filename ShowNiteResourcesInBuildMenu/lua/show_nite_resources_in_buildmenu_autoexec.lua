local InjectChangeGameplayResourceDefValues = function(resource, hudVisible, order)

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resource)
    if ( resourceDef == nil ) then
        LogService:Log("InjectChangeGameplayResourceDefValues GameplayResourceDef '" .. resource .. "' NOT EXISTS.")
        return
    end

    resourceDef:GetField("order"):SetValue(order)
    resourceDef:GetField("hud_visible"):SetValue(hudVisible)
end

local InjectChangeListGameplayResourceDefValues = function(blueprintResourceConverterValues)

    for _, configObject in ipairs(blueprintResourceConverterValues) do

        InjectChangeGameplayResourceDefValues(configObject.name, configObject.hud_visible, configObject.order)
    end
end

local new_resource_values = {
    
    {
        ["name"] = "hazenite",
        ["hud_visible"] = "2", -- ResourceHudVisible.build_menu
        ["order"] = "37",
    },
    
    {
        ["name"] = "tanzanite",
        ["hud_visible"] = "2", -- ResourceHudVisible.build_menu
        ["order"] = "38",
    },
    
    {
        ["name"] = "rhodonite",
        ["hud_visible"] = "2", -- ResourceHudVisible.build_menu
        ["order"] = "39",
    },
    
    {
        ["name"] = "ferdonite",
        ["hud_visible"] = "2", -- ResourceHudVisible.build_menu
        ["order"] = "40",
    },
}

InjectChangeListGameplayResourceDefValues(new_resource_values)