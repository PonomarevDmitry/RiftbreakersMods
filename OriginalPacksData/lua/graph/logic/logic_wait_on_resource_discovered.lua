require("lua/utils/string_utils.lua")

class 'logic_wait_on_resource_discovered' ( LuaGraphNode )

function logic_wait_on_resource_discovered:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_resource_discovered:init()
	--self.eventName = self.data:GetString("event_name")
	self.eventName = "ResourceDiscoveredEvent"	
end

function logic_wait_on_resource_discovered:Activated()
	self:RegisterHandler( event_sink, self.eventName, "OnResourceDiscoveredEvent" )
	LogService:Log("Registered on Entity event: " .. self.eventName)	

	LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_resource_discovered:Deactivated()
	self:UnregisterHandler( event_sink, self.eventName, "OnResourceDiscoveredEvent" )
	LogService:Log("Deactivated on event: " .. self.eventName)
end

function logic_wait_on_resource_discovered:OnResourceDiscoveredEvent( event )
	local resourceName = event:GetResourceName()
	LogService:Log("Reacted on Global event: " .. self.eventName .. " " .. resourceName)
	self:SetFinished()	
end

return logic_wait_on_resource_discovered