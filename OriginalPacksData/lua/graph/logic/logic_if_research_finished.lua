class 'logic_if_research_finished' ( LuaGraphNodeSelector )

function logic_if_research_finished:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_research_finished:Activated()		
   
	local researchId = self.data:GetString("research_id")    
	local finished = PlayerService:IsResearchUnlocked( researchId )
	
	if ( finished ) then
		return self:SetFinished("true")
	else
		return self:SetFinished("false")
	end
end

return logic_if_research_finished