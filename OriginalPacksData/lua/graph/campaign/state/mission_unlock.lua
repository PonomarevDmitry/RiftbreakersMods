class 'mission_unlock' ( LuaGraphNode )

function mission_unlock:__init()
	LuaGraphNode.__init(self,self)
end

function mission_unlock:init()		
end

function mission_unlock:Activated()							
	local name = self.data:GetString("mission_name")
	local def  = self.data:GetString("mission_def")
	CampaignService:UnlockMission( name, def )
	self:SetFinished()	
end

return mission_unlock