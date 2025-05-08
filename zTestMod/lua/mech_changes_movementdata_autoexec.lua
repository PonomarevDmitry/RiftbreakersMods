require("lua/utils/reflection.lua")

local InjectChangeMechMovementDataValues = function(blueprintName, acceleration, deacceleration)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeMechMovementDataValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local movementDataComponent = blueprint:GetComponent("MovementDataComponent")
    if ( movementDataComponent == nil ) then
        LogService:Log("InjectChangeMechMovementDataValues Blueprint '" .. blueprintName .. "' MovementDataComponent NOT EXISTS.")
        return
    end

    local movementDataComponentAcceleration = movementDataComponent:GetField("acceleration")
    if ( movementDataComponentAcceleration == nil ) then

        LogService:Log("InjectChangeMechMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('acceleration') NOT EXISTS.")
    else

        movementDataComponentAcceleration:SetRealSelfAwareType()

        movementDataComponentAcceleration:GetField('base'):SetValue(acceleration)
    end

    local movementDataComponentDeacceleration = movementDataComponent:GetField("deacceleration")
    if ( movementDataComponentDeacceleration == nil ) then

        LogService:Log("InjectChangeMechMovementDataValues Blueprint '" .. blueprintName .. "' movementDataComponent:GetField('deacceleration') NOT EXISTS.")
    else

        movementDataComponentDeacceleration:SetRealSelfAwareType()

        movementDataComponentDeacceleration:GetField('base'):SetValue(deacceleration)
    end
end

local accelerationValue = "100"
local deaccelerationValue = "150"

InjectChangeMechMovementDataValues("player/character_base", accelerationValue, deaccelerationValue)

local mech_changes_movementdata_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )
    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local movementDataComponent = EntityService:GetComponent(player, "MovementDataComponent")
    if ( movementDataComponent == nil ) then
        LogService:Log("mech_changes_movementdata_autoexec Entity '" .. tostring(player) .. "' MovementDataComponent NOT EXISTS.")
        return
    end

    local movementDataComponentAcceleration = movementDataComponent:GetField("acceleration")
    if ( movementDataComponentAcceleration == nil ) then

        LogService:Log("mech_changes_movementdata_autoexec Entity '" .. tostring(player) .. "' movementDataComponent:GetField('acceleration') NOT EXISTS.")
    else

        movementDataComponentAcceleration:SetRealSelfAwareType()

        movementDataComponentAcceleration:GetField('base'):SetValue(accelerationValue)
    end

    local movementDataComponentDeacceleration = movementDataComponent:GetField("deacceleration")
    if ( movementDataComponentDeacceleration == nil ) then

        LogService:Log("mech_changes_movementdata_autoexec Entity '" .. tostring(player) .. "' movementDataComponent:GetField('deacceleration') NOT EXISTS.")
    else

        movementDataComponentDeacceleration:SetRealSelfAwareType()

        movementDataComponentDeacceleration:GetField('base'):SetValue(deaccelerationValue)
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    InjectChangeMechMovementDataValues("player/character_base", accelerationValue, deaccelerationValue)

    mech_changes_movementdata_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    InjectChangeMechMovementDataValues("player/character_base", accelerationValue, deaccelerationValue)

    mech_changes_movementdata_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    InjectChangeMechMovementDataValues("player/character_base", accelerationValue, deaccelerationValue)

    mech_changes_movementdata_autoexec(evt)
end)