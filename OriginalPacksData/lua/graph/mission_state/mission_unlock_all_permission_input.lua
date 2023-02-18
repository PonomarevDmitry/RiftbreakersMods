class 'mission_unblock_all_actions' ( LuaGraphNode )

function mission_unblock_all_actions:__init()
	LuaGraphNode.__init(self,self)
end

function mission_unblock_all_actions:init()		
end

function mission_unblock_all_actions:Activated()							
	PlayerService:UnBlockAllActions()
	self:SetFinished()	
end

return mission_unblock_all_actions