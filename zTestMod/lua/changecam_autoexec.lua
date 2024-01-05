g_pitch_angle = -1.0471976995468

RegisterGlobalEventHandler("EnterBuildMenuEvent", function(arg)

    return

    local entity = CameraService:GetActiveCamera()
    if entity == INVALID_ID then
        return
    end

    local cameraOwner = EntityService:GetParent(entity)
    if cameraOwner == INVALID_ID then
        return
    end

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    followCameraComponent.pitch_angle.radian = 30

end)

RegisterGlobalEventHandler("EnterFighterModeEvent", function(arg)

    return

    local entity = CameraService:GetActiveCamera()
    if entity == INVALID_ID then
        return
    end

    local cameraOwner = EntityService:GetParent(entity)
    if cameraOwner == INVALID_ID then
        return
    end

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    followCameraComponent.pitch_angle.radian = g_pitch_angle

end)