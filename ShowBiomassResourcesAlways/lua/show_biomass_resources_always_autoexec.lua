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
        ["name"] = "biomass_plant",
        ["hud_visible"] = "4", -- ResourceHudVisible.always_short
    },
    
    {
        ["name"] = "biomass_animal",
        ["hud_visible"] = "4", -- ResourceHudVisible.always_short
    },
}

InjectChangeListGameplayResourceDefValues(new_resource_values)