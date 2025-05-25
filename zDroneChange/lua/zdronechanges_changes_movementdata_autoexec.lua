require("lua/utils/reflection.lua")

local InjectChangeDronesMovementDataValues = function(blueprintName, acceleration, deacceleration, maxSpeed)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local movementDataComponent = blueprint:GetComponent("MovementDataComponent")
    if ( movementDataComponent == nil ) then
        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' MovementDataComponent NOT EXISTS.")
        return
    end

    local movementDataComponentAcceleration = movementDataComponent:GetField("acceleration")
    if ( movementDataComponentAcceleration == nil ) then

        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('acceleration') NOT EXISTS.")
    else

        movementDataComponentAcceleration:SetRealSelfAwareType()

        movementDataComponentAcceleration:GetField('base'):SetValue(acceleration)
    end

    local movementDataComponentDeacceleration = movementDataComponent:GetField("deacceleration")
    if ( movementDataComponentDeacceleration == nil ) then

        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('deacceleration') NOT EXISTS.")
    else

        movementDataComponentDeacceleration:SetRealSelfAwareType()

        movementDataComponentDeacceleration:GetField('base'):SetValue(deacceleration)
    end

    local movementDataComponentMaxSpeed = movementDataComponent:GetField("max_speed")
    if ( movementDataComponentMaxSpeed == nil ) then

        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('max_speed') NOT EXISTS.")
    else

        movementDataComponentMaxSpeed:SetRealSelfAwareType()

        movementDataComponentMaxSpeed:GetField('base'):SetValue(maxSpeed)
    end
end

local InjectChangeListDronesMovementDataValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        InjectChangeDronesMovementDataValues(configObject.name, configObject.acceleration, configObject.deacceleration, configObject.max_speed)
    end
end

local new_values = {

    {
        ["name"] = "units/drones/drone_flora_collector",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_resource_collector",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_repair_facility_base",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_repair_facility_lvl_1",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_repair_facility_lvl_2",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_repair_facility_lvl_3",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_repair_standard",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_repair_advanced",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_repair_superior",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_repair_extreme",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_loot_collector_standard",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_loot_collector_advanced",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_loot_collector_superior",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_player_loot_collector_extreme",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_loot_collector",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },

    {
        ["name"] = "units/drones/drone_flora_cultivator",

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },
}

InjectChangeListDronesMovementDataValues(new_values)