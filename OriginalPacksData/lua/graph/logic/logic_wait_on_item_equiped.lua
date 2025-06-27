require("lua/utils/string_utils.lua")

class 'logic_wait_on_item_equiped' ( LuaGraphNode )

function logic_wait_on_item_equiped:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_item_equiped:init()
	--self.eventName = self.data:GetString("event_name")
	self.eventName = "EquipmentChangeRequest"
end

function logic_wait_on_item_equiped:Activated()
	--self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self:RegisterHandler( event_sink, self.eventName, "OnEquipItemEvent" )
	LogService:Log("Registered on Entity event: " .. self.eventName)	

	LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_item_equiped:Deactivated()
	--self:UnregisterHandler( event_sink, self.eventName, "OnLuaGlobalEvent" )
	self:UnregisterHandler( event_sink, self.eventName, "OnEquipItemEvent" )
	LogService:Log("Deactivated on event: " .. self.eventName)
end

--function logic_wait_on_item_equiped:OnLuaGlobalEvent( event )
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

function logic_wait_on_item_equiped:OnEquipItemEvent( event )
    local mech = PlayerService:GetPlayerControlledEnt(0) --#TODO: fix player id
	local equippedId = event:GetEntity()
	
	LogService:Log( tostring(mech) .. ":" .. tostring(equippedId) )
	if mech == equippedId then
		LogService:Log("PLAYER EQUIPED AN ITEM" )
		self:SetFinished()	
	else
		LogService:Log("ITEM EQUIPED BY NOT THE PLAYER" )
	end
end

return logic_wait_on_item_equiped