require("lua/utils/string_utils.lua")

class 'logic_wait_on_event' ( LuaGraphNode )

function logic_wait_on_event:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_event:init()
	self.eventName = self.data:GetString("event_name")
	self.isEntityEvent = IsEntityEvent( self.eventName );

	if not self.isEntityEvent then
		local isEventForGraphOnly = self.data:GetIntOrDefault("is_event_local", 0);
		if isEventForGraphOnly == 1 then
			self.eventName = self.parent:CreateGraphUniqueString( self.eventName );
		end
	end
end

function logic_wait_on_event:Activated()
	if self.isEntityEvent then
		self:RegisterHandler( event_sink, self.eventName, "OnEntityEvent" )
	else
		self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	end

	LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_event:Deactivated()
	if self.isEntityEvent then
		self:UnregisterHandler( event_sink, self.eventName, "OnEntityEvent" )
	else
		self:UnregisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	end

	LogService:Log("Deactivated on event: " .. self.eventName)
end

function logic_wait_on_event:OnLuaGlobalEvent( event )
	if self.eventName == event:GetEvent() then
		LogService:Log("Reacted on event: " .. self.eventName)
		self:SetFinished()
	end
end

function logic_wait_on_event:OnEntityEvent( event )
	LogService:Log("Reacted on event: " .. self.eventName)
	self:SetFinished()
end

return logic_wait_on_event