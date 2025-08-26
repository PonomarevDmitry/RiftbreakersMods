class 'camera_change_pitch' ( LuaGraphNode )

function camera_change_pitch:__init()
    LuaGraphNode.__init(self, self)
end

function camera_change_pitch:init()
end

function camera_change_pitch:Activated()		
	self.duration = self.data:GetFloat("duration")	
	local targetPitch = self.data:GetFloat("target_pitch")	
	
	self.camera = CameraService:GetActiveCamera()
    if not EntityService:IsAlive( self.camera) then
        self:SetFinished()
        return
    end

    self.cameraFollower = EntityService:GetParent( self.camera)
    if not EntityService:IsAlive( self.cameraFollower) then
        self:SetFinished()
        return
    end

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "change", {enter="OnChangeEnter", execute="OnChangeExecute", exit="OnChangeExit"} )

    local cameraFollowComponent = EntityService:GetComponent( self.cameraFollower, "FollowCameraControllerComponent" )
    if ( cameraFollowComponent == nil ) then
        self:SetFinished()
        return
    end
	local helper = reflection_helper(cameraFollowComponent)
    local startPitch = helper.pitch_angle.radian
    LogService:Log(tostring( helper.pitch_angle))
    local endPitch = math.rad(targetPitch)
    LogService:Log(tostring( targetPitch))
    LogService:Log(tostring( endPitch))

    self.change = ( endPitch - startPitch ) / self.duration 
	
    self.fsm:ChangeState("change")
end

function camera_change_pitch:OnChangeEnter( state )
    state:SetDurationLimit( self.duration)
end
	
function camera_change_pitch:OnChangeExecute( state, dt )
    local cameraFollowComponent = EntityService:GetComponent( self.cameraFollower, "FollowCameraControllerComponent" )
    if ( cameraFollowComponent == nil ) then
        state:Exit()
        return
    end
	local helper = reflection_helper(cameraFollowComponent)
    helper.pitch_angle.radian = helper.pitch_angle.radian + (self.change * dt)
end
	
function camera_change_pitch:OnChangeExit( state )
	self:SetFinished()
end
	


return camera_change_pitch