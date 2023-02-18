class 'mission_unlock_research' ( LuaGraphNode )

function mission_unlock_research:__init()
	LuaGraphNode.__init(self,self)
end

function mission_unlock_research:init()		
end

function mission_unlock_research:Activated()							
	self.research = self.data:GetString("research_name")
	LogService:Log( "Unlock research = " .. self.research )
	PlayerService:UnlockResearch( self.research )
	self:SetFinished()	
end

return mission_unlock_research