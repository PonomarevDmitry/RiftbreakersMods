class 'camera_teleport' ( LuaGraphNode )

function camera_teleport:__init()
    LuaGraphNode.__init(self, self)
end

function camera_teleport:init()
end

function camera_teleport:Activated()		
	SoundService:SetEarsMode( "3rd_person" )
	
	self.targetName = self.data:GetString("target_name")	
	self.targetGroup = self.data:GetString("target_group")	
	self.targetType = self.data:GetString("target_type")	
	self.targetBlueprint = self.data:GetString("target_blueprint")	
	
	self.camera = CameraService:GetActiveCamera()
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

	CameraService:SetFollowTarget( self.camera, self.target )
	EntityService:Teleport( self.camera, self.target )	
		
	self:SetFinished()
end

	


return camera_teleport