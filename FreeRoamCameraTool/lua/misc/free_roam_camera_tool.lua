require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'free_roam_camera_tool' ( LuaEntityObject )

function free_roam_camera_tool:__init()
    LuaEntityObject.__init(self,self)
end

function free_roam_camera_tool:init()
    self:InitializeValues()
end

function free_roam_camera_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest", "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest", "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.action = self.data:GetStringOrDefault( "action", "" )

    local orientation = { x=0, y=0, z=0, w=1 }
    EntityService:SetOrientation( self.entity, orientation )

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_free_roam_camera_tool", self.entity)

    self.cameraEnt = CameraService:GetLeadingPlayerCamera()

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    self.yaw_angle = followCameraComponent.yaw_angle.radian

    --LogService:Log("self.yaw_angle " .. tostring(self.yaw_angle))

    self.oldTargetEnt = CameraService:GetFollowTarget( self.cameraEnt )

    self.currentAngle = 0

    self.stepAngle = 5
    --self.stepAngle = 1
end

function free_roam_camera_tool:OnActivateSelectorRequest()

    local position = EntityService:GetPosition( self.entity )

    if ( self.tempEntity == nil ) then
        self.tempEntity = EntityService:SpawnEntity( position )
    end

    EntityService:SetPosition( self.tempEntity, position )

    CameraService:SetFollowTarget( self.cameraEnt, self.tempEntity )
end

function free_roam_camera_tool:OnDeactivateSelectorRequest()
end

function free_roam_camera_tool:OnRotateSelectorRequest( evt )

    local degree = evt:GetDegree()



    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end



    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    self.currentAngle = self.currentAngle + change * self.stepAngle

    while (self.currentAngle >= 360) do
        self.currentAngle = self.currentAngle - 360
    end

    while (self.currentAngle < 0) do
        self.currentAngle = self.currentAngle + 360
    end

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )

    local additionalAngleRadian = math.pi * self.currentAngle / 180

    followCameraComponent.yaw_angle.radian = self.yaw_angle + additionalAngleRadian

    --LogService:Log("self.currentAngle " .. tostring(self.currentAngle) .. " followCameraComponent.yaw_angle.radian " .. tostring(followCameraComponent.yaw_angle.radian))
end

function free_roam_camera_tool:OnRelease()

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

return free_roam_camera_tool
