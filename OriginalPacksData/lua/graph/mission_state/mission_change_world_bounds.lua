class 'mission_change_world_bounds' ( LuaGraphNode )

function mission_change_world_bounds:__init()
    LuaGraphNode.__init(self, self)
end

function mission_change_world_bounds:init()
end

function mission_change_world_bounds:Activated()	
	QueueEvent( "LuaGlobalEvent", event_sink, "change_world_bounds", self.data )

    self:SetFinished()
end

return mission_change_world_bounds