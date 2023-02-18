class 'camera_move_at_target' ( LuaGraphNode )

function camera_move_at_target:__init()
    LuaGraphNode.__init(self, self)
end

function camera_move_at_target:init()
end

function camera_move_at_target:Activated()		
	SoundService:SetEarsMode( "3rd_person" )
	
	self.targetName = self.data:GetString("target_name")	
	self.targetGroup = self.data:GetString("target_group")	
	self.targetType = self.data:GetString("target_type")	
	self.targetBlueprint = self.data:GetString("target_blueprint")	
	
	self.camera = CameraService:GetLeadingPlayerCamera()
	self.target = nil
	
	if self.targetName ~= "" then
		self.target = FindService:FindEntityByName(self.targetName)
	elseif self.targetGroup ~= "" then
		self.target = FindService:FindEntityByGroup(self.targetGroup)
	elseif self.targetType ~= "" then
		self.target = FindService:FindEntityByType(self.targetType)
	elseif self.targetBlueprint ~= "" then
		self.target = FindService:FindEntityByBlueprint(self.targetBlueprint)
	end
	
	self.oldTarget = CameraService:GetFollowTarget( self.camera  )
	self.currentTarget = EntityService:SpawnEntity( self.oldTarget )

	self.speed = self.data:GetFloat("speed")
	self.back_to_player = self.data:GetInt("lock_camera") == 1
	
	MoveService:MoveToTarget( self.currentTarget, self.target, self.speed )
	CameraService:SetFollowTarget( self.camera , self.currentTarget )

	self:RegisterHandler( self.currentTarget , "MoveEndEvent", "OnMoveEnd")	
end

function camera_move_at_target:OnMoveEnd( event )
	EntityService:RemoveEntity( self.currentTarget )
	if ( self.back_to_player == true ) then
		CameraService:SetFollowTarget( self.camera , self.target )
	end
	self:UnregisterHandler( self.currentTarget, "MoveEndEvent", "OnMoveEnd" )
	self:SetFinished()
end

return camera_move_at_target