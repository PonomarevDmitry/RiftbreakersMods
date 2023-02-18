require("lua/utils/string_utils.lua")

class 'logic_wait_on_ammo_empty' ( LuaGraphNode )

function logic_wait_on_ammo_empty:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_ammo_empty:init()
	--self.eventName = self.data:GetString("event_name")
	self.eventName = "MissingMechAmmoEvent"	
end

function logic_wait_on_ammo_empty:Activated()
	--self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self:RegisterHandler( event_sink, self.eventName, "OnMissingMechAmmoEvent" )
	LogService:Log("Registered on Entity event: " .. self.eventName)	

	LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_ammo_empty:Deactivated()
	--self:UnregisterHandler( event_sink, self.eventName, "OnLuaGlobalEvent" )
	self:UnregisterHandler( event_sink, self.eventName, "OnMissingMechAmmoEvent" )
	LogService:Log("Deactivated on event: " .. self.eventName)
end

--function logic_wait_on_ammo_empty:OnLuaGlobalEvent( event )
--	--LogService:Log("Reacted on Global event: " .. event:GetEvent() .. " " .. event:GetId())
--	LogService:Log("Reacted on Global event: " .. event:GetEvent())
--	if self.eventName == event:GetEvent() then
--		local hudId = event:GetId()
--		if hudId == "empty_ammo" then
--			LogService:Log("Reacted on Global event: " .. self.eventName .. " " .. hudId)
--			self:SetFinished()
--		end
--	end
--end

function logic_wait_on_ammo_empty:OnMissingMechAmmoEvent( event )
	--local hudId = event:GetId()
	--if hudId == "empty_ammo" then
		LogService:Log("Reacted on event: " .. self.eventName )
		self:SetFinished()
	--end
end

return logic_wait_on_ammo_empty