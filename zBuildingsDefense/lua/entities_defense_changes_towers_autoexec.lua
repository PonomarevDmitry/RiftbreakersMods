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