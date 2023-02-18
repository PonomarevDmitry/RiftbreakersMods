require("lua/utils/string_utils.lua")

class 'logic_wait_on_player_damage_type' ( LuaGraphNode )

function logic_wait_on_player_damage_type:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_player_damage_type:init()
	self.damage_type = self.data:GetStringOrDefault("damage_type", "")
	Assert( self.damage_type ~= "", "ERROR: Damage type is empty!")
end

function logic_wait_on_player_damage_type:Activated()
	self.entity = PlayerService:GetPlayerControlledEnt(0)
	self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent",  "OnPlayerControlledEntityChangeEvent" )
	if ( self.entity ~= INVALID_ID ) then
		self:RegisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )
	end
		--LogService:Log("Activated on event: " .. self.eventName)
end

function logic_wait_on_player_damage_type:Deactivated()
	self:UnregisterHandler( event_sink, "PlayerControlledEntityChangeEvent",  "OnPlayerControlledEntityChangeEvent" )
	self:UnregisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )	
	--LogService:Log("Deactivated on event: " .. self.eventName)
end

function logic_wait_on_player_damage_type:OnDamageEvent( event )
	--LogService:Log("Reacted on event: " .. self.eventName)
	if event:GetDamageType() == self.damage_type then
		self:SetFinished()
	end
end

function logic_wait_on_player_damage_type:OnPlayerControlledEntityChangeEvent( event )
	if ( self.entity ~= INVALID_ID ) then
		self:UnregisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )	
	end
	self.entity = event.GetControlledEntity()
	self:RegisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )
end

return logic_wait_on_player_damage_type