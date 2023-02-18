require("lua/utils/string_utils.lua")

class 'logic_wait_on_first_encounter' ( LuaGraphNode )

function logic_wait_on_first_encounter:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_first_encounter:init()
	self.eventName = "FirstTimeDiscoveredEvent"	
	self.familyName = self.data:GetStringOrDefault("family_name", "")
	Assert( self.familyName ~= "", "ERROR: Family Name is empty in the Logic Wait On First Encounter logic block")
end

function logic_wait_on_first_encounter:Activated()
	self:RegisterHandler( event_sink, self.eventName, "OnEntityEvent" )	
	--LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_first_encounter:Deactivated()
	self:UnregisterHandler( event_sink, self.eventName, "OnEntityEvent" )	
	--LogService:Log("Deactivated on event: " .. self.eventName)
end

function logic_wait_on_first_encounter:OnEntityEvent( event )
	--LogService:Log("Reacted on event: " .. self.eventName)
	if event:GetFamily() == self.familyName then
		self:SetFinished()
	end
end

return logic_wait_on_first_encounter