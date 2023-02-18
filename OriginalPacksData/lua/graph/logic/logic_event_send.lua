class 'logic_event_send' ( LuaGraphNode )

function logic_event_send:__init()
    LuaGraphNode.__init(self, self)
end

function logic_event_send:init()
	self.eventName = self.data:GetString("event_name")

	local isEventForGraphOnly = self.data:GetIntOrDefault("is_event_local", 0);
	if isEventForGraphOnly == 1 then
		self.eventName = self.parent:CreateGraphUniqueString( self.eventName );
	end
end

function logic_event_send:Activated()
	QueueEvent( "LuaGlobalEvent", event_sink, self.eventName, self.data )

	self:SetFinished()
end

return logic_event_send