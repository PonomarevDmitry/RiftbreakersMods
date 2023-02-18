class 'camera_zoom_out' ( LuaEntityObject )

function camera_zoom_out:__init()
	LuaEntityObject.__init(self,self)
end

function camera_zoom_out:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "zoom", { from="*", enter="OnEnter", execute="OnExecute", exit="OnExit" } )
	self.sm:ChangeState( "zoom" )
end

function camera_zoom_out:OnEnter( state )
	local cameraId = CameraService:GetActiveCamera()
	self.initialTargetDistance = CameraService:GetTargetDistance( cameraId )
	self.zommOutDistance = self.data:GetFloatOrDefault( "zoom_out_distance", 10.0 )
	self.zoomOutTime = self.data:GetFloatOrDefault( "zoom_out_time", 3.0 )
	state:SetDurationLimit( self.zoomOutTime )

	local targetId = CameraService:GetFollowTarget( cameraId )
	local newTargetId = EntityService:SpawnEntity( "debug/empty", targetId, "" )
	CameraService:SetFollowTarget( cameraId, newTargetId )
end

function camera_zoom_out:OnExecute( state )
	local currentProgress = state:GetDuration() / self.zoomOutTime
	local cameraId = CameraService:GetActiveCamera()
	local distance = self.initialTargetDistance + self.zommOutDistance * currentProgress * currentProgress * currentProgress * currentProgress * currentProgress * currentProgress * currentProgress * currentProgress
	CameraService:SetTargetDistance( cameraId, distance )
end

function camera_zoom_out:OnExit( state )
	EntityService:RemoveEntity( self.entity )
end

return camera_zoom_out
 