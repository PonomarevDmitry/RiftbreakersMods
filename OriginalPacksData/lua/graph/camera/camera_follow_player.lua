class 'camera_follow_player' ( LuaGraphNode )

function camera_follow_player:__init()
    LuaGraphNode.__init(self, self)
end

function camera_follow_player:init()
end

function camera_follow_player:Activated()		
	
	self.instant = self.data:GetInt("instant") == 1

	self.camera = CameraService:GetLeadingPlayerCamera()
	self.player = PlayerService:GetPlayerControlledEnt( 0 )

	if ( self.instant ) then
		CameraService:SetFollowTarget( self.camera, self.player )

		self:SetFinished()
	else
		self.speed = self.data:GetFloat( "speed" )
		self.acceleration = self.data:GetFloatOrDefault( "acceleration", 0.0 )
		self.oldTargetPos = CameraService:GetLookAtPosition( self.camera )
		self.currentTarget = EntityService:SpawnEntity( self.oldTargetPos )

		CameraService:SetFollowTarget( self.camera, self.currentTarget )
		MoveService:MoveToTarget( self.currentTarget, self.player, self.speed, self.acceleration )

		self:RegisterHandler( self.currentTarget , "MoveEndEvent", "OnMoveEnd")
	end
end

function camera_follow_player:OnMoveEnd( event )
	self:UnregisterHandler( self.currentTarget, "MoveEndEvent", "OnMoveEnd" )

	EntityService:RemoveEntity( self.currentTarget )
	CameraService:SetFollowTarget( self.camera, self.player )
	
	self:SetFinished()
end

return camera_follow_player