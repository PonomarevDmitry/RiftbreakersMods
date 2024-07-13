require("lua/utils/reflection.lua")

local InjectChangeScannerTurretValues = function(blueprintName, rangeMax, aimingRange)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeScannerTurretValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local turretDesc = blueprint:GetComponent("TurretDesc")
    if ( turretDesc == nil ) then
        LogService:Log("InjectChangeScannerTurretValues Blueprint '" .. blueprintName .. "' TurretDesc NOT EXISTS.")
        return
    end

    local aim_volumeField = turretDesc:GetField("aim_volume")
    if ( aim_volumeField == nil ) then
        LogService:Log("InjectChangeScannerTurretValues Blueprint '" .. blueprintName .. "' turretDesc:GetField('aim_volume') NOT EXISTS.")
        return
    end

    aim_volumeField:SetRealSelfAwareType()

    aim_volumeField:GetField("range_max"):SetValue(rangeMax)
    aim_volumeField:GetField("aiming_range"):SetValue(aimingRange)

    --aim_volumeFieldRef.range_max = rangeMax
    --aim_volumeFieldRef.aiming_range = aimingRange

    --LogService:Log("InjectChangeScannerTurretValues Blueprint '" .. blueprintName .. "' turretDesc:GetField('aim_volume') " .. tostring(reflection_helper(aim_volumeField)))
end

local InjectChangeListScannerTurretValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeScannerTurretValues(configObject.name, configObject.range_max, configObject.aiming_range)
    end
end

local new_values = {

    {
        ["name"] = "items/consumables/scanner_turret",

        ["range_max"] = "70",
        ["aiming_range"] = "80",
    },

    {
        ["name"] = "items/consumables/scanner_turret_advanced",

        ["range_max"] = "80",
        ["aiming_range"] = "90",
    },

    {
        ["name"] = "items/consumables/scanner_turret_superior",

        ["range_max"] = "90",
        ["aiming_range"] = "100",
    },

    {
        ["name"] = "items/consumables/scanner_turret_extreme",

        ["range_max"] = "100",
        ["aiming_range"] = "110",
    },
}

InjectChangeListScannerTurretValues(new_values)