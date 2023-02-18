class 'mission_timeout_unlock' ( LuaGraphNode )

function mission_timeout_unlock:__init()
	LuaGraphNode.__init(self,self)
end

function mission_timeout_unlock:init()		
end

function mission_timeout_unlock:Activated()							
	local name = self.data:GetString("mission_name")
	local def  = self.data:GetString("mission_def")
	local timeout  = self.data:GetFloat("mission_timeout")
	CampaignService:UnlockTimedMission( name, def, timeout )
	self:SetFinished()	
end

return mission_timeout_unlock