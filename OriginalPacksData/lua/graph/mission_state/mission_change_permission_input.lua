class 'mission_change_permissions' ( LuaGraphNode )

function mission_change_permissions:__init()
	LuaGraphNode.__init(self,self)
end

function mission_change_permissions:init()		
end

function mission_change_permissions:Activated()							
	self.inputMask = self.data:GetString("input_mask")
	self.inputStatus = self.data:GetString("input_status")	
	LogService:Log( "INPUT MASK = " .. self.inputMask )
	if self.inputStatus == "false" then
		PlayerService:BlockAction( self.inputMask )
	elseif self.inputStatus == "true" then
		PlayerService:UnBlockAction( self.inputMask )
	end
	self:SetFinished()	
end

return mission_change_permissions