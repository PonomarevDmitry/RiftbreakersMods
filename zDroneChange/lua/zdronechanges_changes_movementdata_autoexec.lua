require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

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

        --LogService:Log("InjectChangeDronesMovementDataValues Setting Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('acceleration') = " .. tostring(acceleration))
    end

    local movementDataComponentDeacceleration = movementDataComponent:GetField("deacceleration")
    if ( movementDataComponentDeacceleration == nil ) then

        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('deacceleration') NOT EXISTS.")
    else

        movementDataComponentDeacceleration:SetRealSelfAwareType()

        movementDataComponentDeacceleration:GetField('base'):SetValue(deacceleration)

        --LogService:Log("InjectChangeDronesMovementDataValues Setting Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('deacceleration') = " .. tostring(deacceleration))
    end

    local movementDataComponentMaxSpeed = movementDataComponent:GetField("max_speed")
    if ( movementDataComponentMaxSpeed == nil ) then

        LogService:Log("InjectChangeDronesMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('max_speed') NOT EXISTS.")
    else

        movementDataComponentMaxSpeed:SetRealSelfAwareType()

        movementDataComponentMaxSpeed:GetField('base'):SetValue(maxSpeed)

        --LogService:Log("InjectChangeDronesMovementDataValues Setting Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('max_speed') = " .. tostring(maxSpeed))
    end
end

local InjectChangeListDronesMovementDataValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        if ( configObject.name ~= nil and configObject.name ~= "" ) then
            InjectChangeDronesMovementDataValues(configObject.name, configObject.acceleration, configObject.deacceleration, configObject.max_speed)
        end

        if ( configObject.list ~= nil ) then

            for _, blueprintName in ipairs(configObject.list) do

                InjectChangeDronesMovementDataValues(blueprintName, configObject.acceleration, configObject.deacceleration, configObject.max_speed)
            end
        end
    end
end

local new_values = {

    {
        ["list"] = {
            "units/drones/drone_flora_collector",
            "units/drones/drone_resource_collector",

            "units/drones/drone_repair_facility_base",

            "units/drones/drone_repair_facility_lvl_1",
            "units/drones/drone_repair_facility_lvl_2",
            "units/drones/drone_repair_facility_lvl_3",

            "units/drones/drone_player_repair_standard",
            "units/drones/drone_player_repair_advanced",
            "units/drones/drone_player_repair_superior",
            "units/drones/drone_player_repair_extreme",

            "units/drones/drone_player_loot_collector_standard",
            "units/drones/drone_player_loot_collector_advanced",
            "units/drones/drone_player_loot_collector_superior",
            "units/drones/drone_player_loot_collector_extreme",

            "units/drones/drone_loot_collector",
            "units/drones/drone_flora_cultivator",
        },

        ["acceleration"] = "100",
        ["deacceleration"] = "100",
        ["max_speed"] = "250",
    },
}

InjectChangeListDronesMovementDataValues(new_values)