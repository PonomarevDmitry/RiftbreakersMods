class 'event_start' ( LuaGraphNode )

function event_start:__init()
	LuaGraphNode.__init(self,self)
end

function event_start:init()
end

function event_start:Activated()
    self:SetFinished()
end

return event_start