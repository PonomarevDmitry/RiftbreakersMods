------ #warning Commented Local ------
do return end

local InjectChangeGameplayResourceDefValues = function(resource, hudVisible)

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resource)
    if ( resourceDef == nil ) then
        LogService:Log("InjectChangeGameplayResourceDefValues GameplayResourceDef '" .. resource .. "' NOT EXISTS.")
        return
    end

    resourceDef:GetField("hud_visible"):SetValue(hudVisible)
end

local InjectChangeListGameplayResourceDefValues = function(blueprintResourceConverterValues)

    for _, configObject in ipairs(blueprintResourceConverterValues) do

        InjectChangeGameplayResourceDefValues(configObject.name, configObject.hud_visible)
    end
end

local new_resource_values = {
    
    {
        ["name"] = "cobalt",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
    },
    
    {
        ["name"] = "palladium",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
    },
    
    {
        ["name"] = "titanium",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
    },
    
    {
        ["name"] = "uranium_ore",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
    },
    
    {
        ["name"] = "uranium",
        ["hud_visible"] = "1", -- ResourceHudVisible.always
    },
}

InjectChangeListGameplayResourceDefValues(new_resource_values)