class 'mission_grant_award' ( LuaGraphNode )

function mission_grant_award:__init()
	LuaGraphNode.__init(self,self)
end

function mission_grant_award:init()		
end

function mission_grant_award:Activated()							
	local awards = self.data:GetStringKeys()
    for award in Iter(awards ) do
	    LogService:Log( "Grant award = " .. award )
        QueueEvent("NewAwardEvent", INVALID_ID, award, true, EntityService:GetTeam( "player") )
    end
	self:SetFinished()	
end

return mission_grant_award