class 'mission_unhide_research' ( LuaGraphNode )

function mission_unhide_research:__init()
	LuaGraphNode.__init(self,self)
end

function mission_unhide_research:init()		
end

function mission_unhide_research:Activated()							
	self.research = self.data:GetString("research_name")
	LogService:Log( "Unlock research = " .. self.research )
	PlayerService:UnhideResearch(PlayerService:GetLeadingPlayer(), self.research )
	self:SetFinished()	
end

return mission_unhide_research