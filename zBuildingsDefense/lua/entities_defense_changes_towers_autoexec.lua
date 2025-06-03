require("lua/utils/reflection.lua")

local InjectChangeTowersValues = function(blueprintName, rangeMax, aimingRange)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local turretDesc = blueprint:GetComponent("TurretDesc")
    if ( turretDesc == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' TurretDesc NOT EXISTS.")
        return
    end

    local aim_volumeField = turretDesc:GetField("aim_volume")
    if ( aim_volumeField == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' turretDesc:GetField('aim_volume') NOT EXISTS.")
        return
    end

    aim_volumeField:SetRealSelfAwareType()

    aim_volumeField:GetField("range_max"):SetValue(rangeMax)
    aim_volumeField:GetField("aiming_range"):SetValue(aimingRange)

    --aim_volumeFieldRef.range_max = rangeMax
    --aim_volumeFieldRef.aiming_range = aimingRange

    --LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' turretDesc:GetField('aim_volume') " .. tostring(reflection_helper(aim_volumeField)))
end

local InjectChangeListTowersValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeTowersValues(configObject.name, configObject.range_max, configObject.aiming_range)
    end
end

local new_values = {

    {
        ["name"] = "buildings/defense/tower_gatling_laser",

        ["range_max"] = "60",
        ["aiming_range"] = "70",
    },
}

InjectChangeListTowersValues(new_values)



local InjectChangeTowersGhostValues = function(blueprintName, rangeMax, aimingRange)

    blueprintName = blueprintName .. "_ghost"

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local displayRadiusComponent = blueprint:GetComponent("DisplayRadiusComponent")
    if ( displayRadiusComponent == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' DisplayRadiusComponent NOT EXISTS.")
        return
    end

    local max_radiusField = displayRadiusComponent:GetField("max_radius")
    if ( max_radiusField == nil ) then
        LogService:Log("InjectChangeTowersValues Blueprint '" .. blueprintName .. "' displayRadiusComponent:GetField('max_radius') NOT EXISTS.")
        return
    end

    max_radiusField:SetValue(rangeMax)
end

local new_ghost_values = {

    {
        ["list"] = { 
            "buildings/defense/tower_gatling_laser",
            "buildings/defense/tower_gatling_laser_lvl_2",
            "buildings/defense/tower_gatling_laser_lvl_3"
        },

        ["range_max"] = "60",
    },
}

local InjectChangeListTowersGhostValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        for _, blueprintName in ipairs(configObject.list) do

            InjectChangeTowersGhostValues(blueprintName, configObject.range_max)
        end
    end
end

InjectChangeListTowersGhostValues(new_ghost_values)