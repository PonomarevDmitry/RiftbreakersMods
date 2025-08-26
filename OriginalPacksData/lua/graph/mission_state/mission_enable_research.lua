class 'mission_enable_research' ( LuaGraphNode )

function mission_enable_research:__init()
	LuaGraphNode.__init(self,self)
end

function mission_enable_research:init()		
end

function mission_enable_research:Activated()							
	self.research = self.data:GetString("research_name")
	LogService:Log( "Unlock research = " .. self.research )
	PlayerService:EnableResearch(PlayerService:GetLeadingPlayer(), self.research )
	self:SetFinished()	
end

return mission_enable_research