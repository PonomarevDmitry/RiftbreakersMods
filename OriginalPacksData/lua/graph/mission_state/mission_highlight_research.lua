class 'mission_highlight_research' ( LuaGraphNode )

function mission_highlight_research:__init()
	LuaGraphNode.__init(self,self)
end

function mission_highlight_research:init()		
end

function mission_highlight_research:Activated()							
	self.research = self.data:GetString("research_name")
	self.highlight = self.data:GetString("highlight")
	--LogService:Log( "Highlight research = " .. self.research .. " : " .. self.highlight )
	PlayerService:HighlightResearch( self.research, self.highlight == "true"  )
	self:SetFinished()	
end

return mission_highlight_research