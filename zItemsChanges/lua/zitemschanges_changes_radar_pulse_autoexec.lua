require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeRadarPulseValues = function(blueprintName, radius, time)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeRadarPulseValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local fogOfWarRevealerComponent = blueprint:GetComponent("FogOfWarRevealerComponent")
    if ( fogOfWarRevealerComponent == nil ) then
        LogService:Log("InjectChangeRadarPulseValues Blueprint '" .. blueprintName .. "' FogOfWarRevealerComponent NOT EXISTS.")
    else

        fogOfWarRevealerComponent:GetField("radius"):SetValue(radius)
    end

    local lifeTimeDesc = blueprint:GetComponent("LifeTimeDesc")
    if ( lifeTimeDesc == nil ) then
        LogService:Log("InjectChangeRadarPulseValues Blueprint '" .. blueprintName .. "' LifeTimeDesc NOT EXISTS.")
    else

        lifeTimeDesc:GetField("time"):SetValue(time)
    end

    local lifeTimeComponent = blueprint:GetComponent("LifeTimeComponent")
    if ( lifeTimeComponent == nil ) then
        LogService:Log("InjectChangeRadarPulseValues Blueprint '" .. blueprintName .. "' LifeTimeComponent NOT EXISTS.")
    else

        lifeTimeComponent:GetField("time"):GetField("timeLimit"):SetValue(time)
    end
end

local InjectChangeListRadarPulseValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeRadarPulseValues(configObject.name, configObject.radius, configObject.time)
    end
end

local new_storage_values = {

    {
        ["name"] = "items/consumables/radar_pulse",

        ["radius"] = "200",
        ["time"] = "20",
    },

    {
        ["name"] = "items/consumables/radar_pulse_advanced",

        ["radius"] = "250",
        ["time"] = "24",
    },

    {
        ["name"] = "items/consumables/radar_pulse_superior",

        ["radius"] = "300",
        ["time"] = "28",
    },

    {
        ["name"] = "items/consumables/radar_pulse_extreme",

        ["radius"] = "350",
        ["time"] = "32",
    },
}

InjectChangeListRadarPulseValues(new_storage_values)