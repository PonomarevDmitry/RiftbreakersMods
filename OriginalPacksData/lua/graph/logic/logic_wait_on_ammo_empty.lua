require("lua/utils/string_utils.lua")

class 'logic_wait_on_ammo_empty' ( LuaGraphNode )

function logic_wait_on_ammo_empty:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_ammo_empty:init()
	self.eventName = "ShootingEmptyStartWeaponEvent"	
end

function logic_wait_on_ammo_empty:Activated()
	self:RegisterHandler( event_sink, self.eventName, "OnMissingMechAmmoEvent" )
	LogService:Log("Registered on Entity event: " .. self.eventName)	
	LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_ammo_empty:Deactivated()
	self:UnregisterHandler( event_sink, self.eventName, "OnMissingMechAmmoEvent" )
	LogService:Log("Deactivated on event: " .. self.eventName)
end

function logic_wait_on_ammo_empty:OnMissingMechAmmoEvent( event )
	local playerReferenceComponent = EntityService:GetComponent(event:GetEntity(), "PlayerReferenceComponent")
	if playerReferenceComponent then
		local playerReference = reflection_helper(playerReferenceComponent)            
        local internalEnum = playerReference.reference_type.internal_enum 
        if ( internalEnum == 5 ) then -- PlayerReferenceType::RT_ITEM
			LogService:Log("Reacted on event: " .. self.eventName )
			self:SetFinished()
		end
	end
end

return logic_wait_on_ammo_empty
