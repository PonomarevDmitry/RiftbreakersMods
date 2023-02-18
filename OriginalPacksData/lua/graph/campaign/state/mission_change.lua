class 'mission_change' ( LuaGraphNode )

function mission_change:__init()
	LuaGraphNode.__init(self,self)
end

function mission_change:init()		
end

function mission_change:Activated()							
	local name = self.data:GetString("mission_name")
	CampaignService:ChangeCurrentMission( name )
	self:SetFinished()	
end

return mission_change