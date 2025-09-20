------ #warning Commented Local ------
do return end

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
        ["hud_visible"] = "1", -- ResourceHudVisible.always
        ["order"] = "9",
    },
    
    {
        ["name"] = "tanzanite",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
        ["order"] = "9",
    },
    
    {
        ["name"] = "rhodonite",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
        ["order"] = "9",
    },
    
    {
        ["name"] = "ferdonite",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
        ["order"] = "9",
    },
}

InjectChangeListGameplayResourceDefValues(new_resource_values)