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

	if ( self.instant == true ) then
		CameraService:SetFollowTarget( self.camera , self.player )
		 SoundService:SetEarsMode( "1st_person" )
	else
	
		self.speed = self.data:GetFloat("speed")
		self.oldTarget = CameraService:GetFollowTarget( self.camera  )
		if ( EntityService:IsAlive( self.oldTarget ) ) then
			self.currentTarget = EntityService:SpawnEntity( self.oldTarget )
			CameraService:SetFollowTarget( self.camera , self.currentTarget )
			MoveService:MoveToTarget( self.currentTarget, self.player, self.speed )
			self:RegisterHandler( self.currentTarget , "MoveEndEvent", "OnMoveEnd")
		end
	end		
end

function camera_follow_player:OnMoveEnd( event )
	EntityService:RemoveEntity( self.currentTarget )
	CameraService:SetFollowTarget( self.camera , self.player )
	self:UnregisterHandler( self.currentTarget, "MoveEndEvent", "OnMoveEnd" )
	SoundService:SetEarsMode( "1st_person" )
	self:SetFinished()
end

return camera_follow_player