require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'move_camera_tool' ( LuaEntityObject )

function move_camera_tool:__init()
    LuaEntityObject.__init(self,self)
end

function move_camera_tool:init()

    self:InitializeValues()
end

function move_camera_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest", "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest", "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.action = self.data:GetStringOrDefault( "action", "")
    if ( self.action == "") then
        local buildingComponent = reflection_helper(EntityService:GetComponent(self.entity, "BuildingComponent") )
        self.action = buildingComponent.type
    end

    local orientation = {x=0,y=0,z=0,w=1}
    EntityService:SetOrientation( self.entity, orientation )

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_move_camera_tool", self.entity)

    self.cameraEnt = CameraService:GetLeadingPlayerCamera()

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    self.yaw_angle = followCameraComponent.yaw_angle.radian

    LogService:Log("self.yaw_angle " .. tostring(self.yaw_angle))

    self.oldTargetEnt = CameraService:GetFollowTarget( self.cameraEnt )

    self.currentSteps = 0
end

function move_camera_tool:OnActivateSelectorRequest()

    local position = EntityService:GetPosition( self.entity )

    if ( self.tempEntity == nil ) then
        self.tempEntity = EntityService:SpawnEntity( position )
    end

    EntityService:SetPosition( self.tempEntity, position )

    CameraService:SetFollowTarget( self.cameraEnt, self.tempEntity )
end

function move_camera_tool:OnDeactivateSelectorRequest()
end

function move_camera_tool:OnRotateSelectorRequest( evt )

    local degree = evt:GetDegree()



    local invertRotationConfig = mod_invert_rotation or 0

    invertRotationConfig = tonumber(invertRotationConfig)

    -- Inverting rotation
    if ( invertRotationConfig == 1 ) then
        degree = -degree
    end



    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    self.currentSteps = self.currentSteps + change

    while (self.currentSteps > 360) do
        self.currentSteps = self.currentSteps - 360
    end

    while (self.currentSteps < 0) do
        self.currentSteps = self.currentSteps + 360
    end

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )

    --local stepAngle = 5

    local stepAngle = 1

    local stepsCount = 180 / stepAngle

    local additionalAngleRadian = math.pi * self.currentSteps / stepsCount

    followCameraComponent.yaw_angle.radian = self.yaw_angle + additionalAngleRadian

    LogService:Log("self.currentSteps " .. tostring(self.currentSteps) .. " followCameraComponent.yaw_angle.radian " .. tostring(followCameraComponent.yaw_angle.radian))
end

function move_camera_tool:OnRelease()

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    followCameraComponent.yaw_angle.radian = self.yaw_angle

    CameraService:SetFollowTarget( self.cameraEnt, self.oldTargetEnt )

    if ( self.childEntity ~= nil ) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.tempEntity ~= nil ) then
        EntityService:RemoveEntity(self.tempEntity)
        self.tempEntity = nil
    end
end

return move_camera_tool
